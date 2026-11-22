import { HttpsError, onCall } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import * as admin from "firebase-admin";
import {
  FlightTime,
  FlightsDeps,
  Grant,
  SavedAnswer,
  ShareDeps,
  SharerDoc,
  Verification,
  buildFactionFlights,
  readFlightSharing,
  readTravelAnswer,
  readVerification,
  setFlightSharing,
} from "./flights";

const TORN_TIMEOUT_MS = 10_000;
const RTDB_WAIT_MS = 3_000;
const ARRIVALS_PATH = "factionFlights/arrivals";
const FAILED_PATH = "factionFlights/failedKeys";
const ANSWERS_PATH = "factionFlights/answers";
const GRANTS_PATH = "factionFlights/grants";
const TURNS_PATH = "factionFlights/turns";
const HOUR_MS = 3_600_000;

async function tornGet(path: string, apiKey: string): Promise<any> {
  const response = await fetch(`https://api.torn.com/v2/${path}`, {
    headers: { Authorization: `ApiKey ${apiKey}`, "User-Agent": "PDA-Flights/1.0" },
    signal: AbortSignal.timeout(TORN_TIMEOUT_MS),
  });
  if (!response.ok) throw new Error(`HTTP ${response.status}`);
  return response.json();
}

// The token is never kept nor logged
async function verify(apiToken: string): Promise<Verification> {
  let response: Response;
  try {
    response = await fetch("https://www.torn.com/page.php?sid=TornMobileApp", {
      method: "POST",
      headers: { "Content-Type": "application/json", "User-Agent": "PDA-Flights/1.0" },
      body: JSON.stringify({ step: "verifyApiToken", api_token: apiToken }),
      signal: AbortSignal.timeout(TORN_TIMEOUT_MS),
    });
  } catch (e: any) {
    logger.warn(`flights: verify got no answer: ${e?.name}`);
    return "down";
  }
  try {
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    return readVerification(await response.json());
  } catch (e: any) {
    logger.warn(`flights: verify failed: ${response.status} ${e?.name}`);
    return e?.name === "TimeoutError" ? "down" : "error";
  }
}

// One node per hour, removed whole later
const turnsOf = (nowMs: number, hoursAgo = 0) =>
  admin.database().ref(`${TURNS_PATH}/${Math.floor(nowMs / HOUR_MS) - hoursAgo}`);

async function claimTurn(turn: string, nowMs: number, everyMs: number): Promise<number> {
  const waitFor = (last: number | null) =>
    last && nowMs - last < everyMs ? Math.max(1, Math.ceil((everyMs - (nowMs - last)) / 1000)) : 0;
  if (nowMs % HOUR_MS < everyMs) {
    const wait = waitFor((await turnsOf(nowMs, 1).child(turn).get()).val());
    if (wait > 0) return wait;
  }
  const result = await turnsOf(nowMs)
    .child(turn)
    .transaction((last) => (waitFor(last) > 0 ? undefined : nowMs));
  if (!result.committed) return waitFor(result.snapshot.val());
  await turnsOf(nowMs, 2)
    .remove()
    .catch((e: any) => logger.warn(`flights: old turns not removed: ${e?.message}`));
  return 0;
}

async function setTurn(turn: string, nowMs: number, lastMs: number | null) {
  await turnsOf(nowMs).child(turn).set(lastMs);
}

async function markDoc(docId: string, share: boolean) {
  await admin.firestore().collection("players").doc(docId).update({ shareFlights: share });
}

async function readGrant(playerId: number): Promise<Grant | null> {
  return (await admin.database().ref(`${GRANTS_PATH}/${playerId}`).get()).val();
}

const turnDeps = {
  nowMs: () => Date.now(),
  rtdbWaitMs: RTDB_WAIT_MS,
  verify,
  claimTurn,
  setTurn,
  markDoc,
  warn: (message: string) => logger.warn(message),
};

const liveDeps: FlightsDeps = {
  ...turnDeps,

  async readAnswer(factionId) {
    return (await admin.database().ref(`${ANSWERS_PATH}/${factionId}`).get()).val();
  },

  async writeAnswer(factionId, answer) {
    // RTDB refuses undefined fields
    await admin.database().ref(`${ANSWERS_PATH}/${factionId}`).set(JSON.parse(JSON.stringify(answer)) as SavedAnswer);
  },

  async readKey(uid) {
    return (await admin.firestore().collection("players").doc(uid).get()).get("apiKey") || undefined;
  },

  async readFaction(apiKey) {
    try {
      const data = await tornGet("faction?selections=basic,members&striptags=true&comment=PDA-Flights", apiKey);
      const code = Number(data?.error?.code);
      if (code === 6 || code === 7) return "no_faction";
      if (data?.error) return "refused";
      if (!data?.basic?.id) return "no_faction";
      return { id: data.basic.id, members: data.members ?? [] };
    } catch (e: any) {
      logger.warn(`flights: Torn failed: ${e?.name}`);
      return "error";
    }
  },

  async readGrants(playerIds) {
    const grants: Record<string, Grant> = {};
    await Promise.all(
      playerIds.map(async (id) => {
        const grant = await readGrant(id);
        if (grant?.doc && grant?.keyHash) grants[id] = grant;
      })
    );
    return grants;
  },

  async readDocs(docIds) {
    if (docIds.length === 0) return {};
    const players = admin.firestore().collection("players");
    const snapshots = await admin.firestore().getAll(...docIds.map((id) => players.doc(id)), {
      fieldMask: ["apiKey", "active", "flightArrival", "flightDestination", "flightDeparted"],
    });
    const docs: Record<string, SharerDoc> = {};
    for (const snapshot of snapshots) if (snapshot.exists) docs[snapshot.id] = snapshot.data() as SharerDoc;
    return docs;
  },

  async readSaved(factionId) {
    const database = admin.database();
    const [times, failed] = await Promise.all([
      database.ref(`${ARRIVALS_PATH}/${factionId}`).get(),
      database.ref(`${FAILED_PATH}/${factionId}`).get(),
    ]);
    return { times: times.val() ?? {}, failed: failed.val() ?? {} };
  },

  async writeSaved(factionId, times, failed, revoked) {
    const changes: Record<string, FlightTime | number | null> = {};
    for (const [id, time] of Object.entries(times)) changes[`${ARRIVALS_PATH}/${factionId}/${id}`] = time;
    for (const [hash, until] of Object.entries(failed)) changes[`${FAILED_PATH}/${factionId}/${hash}`] = until;
    for (const id of revoked) changes[`${GRANTS_PATH}/${id}`] = null;
    await admin.database().ref().update(JSON.parse(JSON.stringify(changes)));
  },

  async readTravel(apiKey) {
    return readTravelAnswer(await tornGet("user?selections=basic,travel&comment=PDA-Flights", apiKey));
  },
};

const shareDeps: ShareDeps = {
  ...turnDeps,
  readGrant,

  async readPlayer(uid) {
    const data = (await admin.firestore().collection("players").doc(uid).get()).data();
    return data ? { playerId: data.playerId, apiKey: data.apiKey } : null;
  },

  async keyOwner(apiKey) {
    try {
      const id = (await tornGet("user/basic?comment=PDA-Flights", apiKey))?.profile?.id;
      return typeof id === "number" ? id : null;
    } catch (e: any) {
      logger.warn(`flights: owner unknown: ${e?.name}`);
      return null;
    }
  },

  async writeGrant(playerId, grant) {
    await admin.database().ref(`${GRANTS_PATH}/${playerId}`).set(grant);
  },
};

export const setShareFlights = onCall(
  { region: "us-east4", memory: "256MiB", timeoutSeconds: 30, maxInstances: 5 },
  async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Sign in first");
    const share = request.data?.share;
    if (typeof share !== "boolean") throw new HttpsError("invalid-argument", "share must be a boolean");
    const answer = await setFlightSharing(request.auth.uid, share, request.data?.apiToken, shareDeps);
    logger.info(`flights share: ${share} ${answer.status}`);
    return answer;
  }
);

export const getShareFlights = onCall(
  { region: "us-east4", memory: "256MiB", timeoutSeconds: 30, maxInstances: 5 },
  async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Sign in first");
    return readFlightSharing(request.auth.uid, request.data?.apiToken, shareDeps);
  }
);

export const getFactionFlights = onCall(
  { region: "us-east4", memory: "256MiB", timeoutSeconds: 60, maxInstances: 5 },
  async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Sign in first");
    const answer = await buildFactionFlights(request.auth.uid, request.data?.apiToken, liveDeps);
    logger.info(answer.status === "ok" ? `flights: ok ${JSON.stringify(answer.counts)}` : `flights: ${answer.status}`);
    return answer;
  }
);
