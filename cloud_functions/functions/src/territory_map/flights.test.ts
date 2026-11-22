import { test } from "node:test";
import * as assert from "node:assert/strict";
import {
  FAILED_KEY_WAIT_MS,
  FlightTime,
  FlightsDeps,
  Grant,
  MAX_FOREIGN_KEYS,
  SHARE_PLAYER_EVERY_MS,
  SavedAnswer,
  SavedFlights,
  ShareDeps,
  SharerDoc,
  Verification,
  buildFactionFlights,
  keyHash,
  logSharedFlight,
  readFlightSharing,
  readMembers,
  readTravelAnswer,
  readVerification,
  setFlightSharing,
} from "./flights";

const NOW_SEC = 1_794_000_000;
const FACTION = 777;
const OTHER_FACTION = 888;

const TOKENS: Record<string, Verification> = {
  viewer: { playerId: 1, factionId: FACTION },
  outsider: { playerId: 2, factionId: OTHER_FACTION },
  loner: { playerId: 3, factionId: 0 },
  p5: { playerId: 5, factionId: FACTION },
  p6: { playerId: 6, factionId: FACTION },
  broken: "error",
  down: "down",
};

interface World {
  nowMs: number;
  turns: Record<string, number>;
  answers: Record<number, SavedAnswer>;
  grants: Record<string, Grant>;
  docs: Record<string, SharerDoc & { playerId?: unknown; shareFlights?: boolean }>;
  saved: SavedFlights;
  members: any[];
  // Key to faction, when not FACTION
  keyFaction: Record<string, number>;
  travel: Record<string, { owner: number; time: FlightTime | null } | null | "down">;
  calls: string[];
}

function world(more: Partial<World> = {}): World {
  return {
    nowMs: NOW_SEC * 1000,
    turns: {},
    answers: {},
    grants: {},
    docs: { viewer: { apiKey: "viewer-key" } },
    saved: { times: {}, failed: {} },
    members: [],
    keyFaction: {},
    travel: {},
    calls: [],
    ...more,
  };
}

async function claimIn(w: World, turn: string, nowMs: number, everyMs: number) {
  const last = w.turns[turn];
  if (last && nowMs - last < everyMs) return Math.ceil((everyMs - (nowMs - last)) / 1000);
  w.turns[turn] = nowMs;
  return 0;
}

function turnDeps(w: World) {
  return {
    nowMs: () => w.nowMs,
    rtdbWaitMs: 5,
    verify: async (token: string) => {
      w.calls.push("verify");
      return TOKENS[token] ?? "invalid";
    },
    claimTurn: async (turn: string, nowMs: number, everyMs: number) => claimIn(w, turn, nowMs, everyMs),
    setTurn: async (turn: string, _: number, lastMs: number | null) => {
      if (lastMs === null) delete w.turns[turn];
      else w.turns[turn] = lastMs;
    },
    markDoc: async (doc: string, share: boolean) => {
      if (w.docs[doc]) w.docs[doc].shareFlights = share;
    },
    warn: () => {},
  };
}

function flightsDeps(w: World, more: Partial<FlightsDeps> = {}): FlightsDeps {
  return {
    ...turnDeps(w),
    readAnswer: async (factionId) => w.answers[factionId] ?? null,
    writeAnswer: async (factionId, answer) => {
      w.answers[factionId] = answer;
    },
    readKey: async (uid) => w.docs[uid]?.apiKey,
    readFaction: async (key) => {
      w.calls.push(`faction ${key}`);
      if (key === "down-key") return "error";
      return { id: w.keyFaction[key] ?? FACTION, members: w.members };
    },
    readGrants: async (ids) => Object.fromEntries(ids.filter((id) => w.grants[id]).map((id) => [id, w.grants[id]])),
    readDocs: async (ids) => Object.fromEntries(ids.filter((id) => w.docs[id]).map((id) => [id, w.docs[id]])),
    readSaved: async () => w.saved,
    writeSaved: async (_, times, failed, revoked) => {
      for (const [id, time] of Object.entries(times)) {
        if (time) w.saved.times[id] = time;
        else delete w.saved.times[id];
      }
      for (const [hash, until] of Object.entries(failed)) {
        if (until) w.saved.failed[hash] = until;
        else delete w.saved.failed[hash];
      }
      for (const id of revoked) delete w.grants[id];
    },
    readTravel: async (key) => {
      w.calls.push(`travel ${key}`);
      const read = w.travel[key];
      if (read === "down") throw new Error("Torn down");
      return read ?? null;
    },
    ...more,
  };
}

function traveling(id: number, description: string) {
  return { id, name: `P${id}`, status: { state: "Traveling", description } };
}

const toJapan = traveling(10, "Traveling from Torn to Japan");
const flight = (arrival: number, destination = "Japan"): FlightTime => ({
  arrival,
  destination,
  departed: NOW_SEC - 100,
});

// Server-side permission, as setShareFlights leaves it
function sharing(w: World, playerId: number, more: SharerDoc = {}) {
  const doc = `uid${playerId}`;
  const apiKey = `key${playerId}`;
  w.docs[doc] = { apiKey, active: true, playerId, shareFlights: true, ...more };
  w.grants[playerId] = { doc, keyHash: keyHash(apiKey) };
}

async function open(w: World, token: unknown = "viewer", uid = "viewer", more: Partial<FlightsDeps> = {}) {
  return buildFactionFlights(uid, token, flightsDeps(w, more));
}

async function rows(w: World, token: unknown = "viewer", uid = "viewer") {
  const answer = await open(w, token, uid);
  if (answer.status !== "ok") throw new Error(`not ok: ${answer.status}`);
  return answer;
}

const arrivalOf = (answer: { flying: { id: number; arrival?: number }[] }, id: number) =>
  answer.flying.find((row) => row.id === id)?.arrival;

const never = <T>() => new Promise<T>(() => {});

test("reads routes in both Torn wordings and everyone abroad", () => {
  const { flying, abroad } = readMembers([
    traveling(1, "Traveling from UAE to Torn"),
    traveling(2, "Traveling to Mexico"),
    traveling(3, "Returning to Torn from Canada"),
    traveling(4, "Traveling from Torn to UK"),
    { id: 5, name: "P5", status: { state: "Abroad", description: "In South Africa" } },
    { id: 6, name: "P6", status: { state: "Okay", description: "Okay" } },
  ]);
  assert.deepEqual(
    flying.map((f) => [f.id, f.from, f.to]),
    [
      [1, "UAE", "Torn"],
      [2, "Torn", "Mexico"],
      [3, "Canada", "Torn"],
      [4, "Torn", "United Kingdom"],
    ]
  );
  assert.deepEqual(abroad, [{ id: 5, name: "P5", at: "South Africa" }]);
});

test("Torn's verification counts only with valid true", () => {
  assert.deepEqual(readVerification({ player_id: 2043727, valid: true, factionId: 40029 }), {
    playerId: 2043727,
    factionId: 40029,
  });
  assert.deepEqual(readVerification({ playerId: "12", valid: true, faction_id: 0 }), { playerId: 12, factionId: 0 });
  assert.deepEqual(readVerification({ player_id: 12, valid: true }), { playerId: 12, factionId: 0 });
  assert.equal(readVerification({ player_id: 2043727, valid: false, factionId: 40029 }), "invalid");
  assert.equal(readVerification({ player_id: 2043727, valid: "true", factionId: 40029 }), "invalid");
  assert.equal(readVerification({ player_id: 2043727, factionId: 40029 }), "invalid");
  assert.equal(readVerification({ valid: true, factionId: 40029 }), "invalid");
  assert.equal(readVerification({ player_id: -4, valid: true }), "invalid");
  assert.equal(readVerification(null), "invalid");
});

test("only key errors blame the key, other Torn errors throw", () => {
  assert.equal(readTravelAnswer({ error: { code: 2, error: "Incorrect key" } }), null);
  assert.equal(readTravelAnswer({ error: { code: 13, error: "Key disabled" } }), null);
  for (const code of [5, 8, 9, 14, 17]) assert.throws(() => readTravelAnswer({ error: { code } }), /Torn error/);
  assert.throws(() => readTravelAnswer({}), /without a player/);
  assert.deepEqual(readTravelAnswer({ profile: { id: 10 }, travel: {} }), { owner: 10, time: null });
  assert.deepEqual(
    readTravelAnswer({
      profile: { id: 10 },
      travel: { destination: "Japan", departed_at: NOW_SEC - 100, arrival_at: NOW_SEC + 600 },
    }),
    { owner: 10, time: flight(NOW_SEC + 600) }
  );
});

test("no usable token asks to log in and calls nobody", async () => {
  for (const token of [undefined, "", 42, "x".repeat(5000)]) {
    const w = world();
    assert.deepEqual(await buildFactionFlights("viewer", token, flightsDeps(w)), { status: "no_login" });
    assert.deepEqual(w.calls, []);
  }
});

test("a token Torn rejects gets nothing, even with a player id", async () => {
  const w = world({ members: [toJapan] });
  sharing(w, 10, { flightArrival: NOW_SEC + 600, flightDestination: "Japan" });
  const answer = await open(w, "rejected", "viewer", {
    verify: async () => readVerification({ player_id: 1, valid: false, factionId: FACTION }),
  });
  assert.deepEqual(answer, { status: "no_login" });
  assert.deepEqual(w.answers, {});
});

test("the faction comes from the token, never from the player's key", async () => {
  const w = world({ members: [toJapan] });
  sharing(w, 10, { flightArrival: NOW_SEC + 600, flightDestination: "Japan" });
  w.answers[FACTION] = { at: w.nowMs - 1000, flying: [{ ...toJapan, from: "Torn", to: "Japan", arrival: NOW_SEC + 600 }], abroad: [] };

  assert.deepEqual(await open(w, "outsider"), { status: "torn_error" });
  assert.deepEqual(w.calls, ["verify", "faction viewer-key"]);
  assert.equal(w.turns[`faction_${OTHER_FACTION}`], undefined);
  assert.equal(w.answers[OTHER_FACTION], undefined);

  assert.deepEqual(await open(world(), "loner"), { status: "no_faction" });
});

test("a document that sets shareFlights itself gets no hour", async () => {
  const w = world({ members: [toJapan] });
  w.docs.uid10 = {
    apiKey: "key10",
    active: true,
    playerId: 10,
    shareFlights: true,
    flightArrival: NOW_SEC + 600,
    flightDestination: "Japan",
  };
  w.saved.times["10"] = flight(NOW_SEC + 600);
  w.travel.key10 = { owner: 10, time: flight(NOW_SEC + 650) };
  const answer = await rows(w);
  assert.equal(arrivalOf(answer, 10), undefined);
  assert.ok(!w.calls.includes("travel key10"));
});

test("a granted document's hour needs no key", async () => {
  const w = world({ members: [toJapan] });
  sharing(w, 10, { flightArrival: NOW_SEC + 600, flightDestination: "Japan", flightDeparted: NOW_SEC - 60 });
  const answer = await rows(w);
  assert.equal(arrivalOf(answer, 10), NOW_SEC + 600);
  assert.deepEqual(answer.counts, { flying: 1, withTime: 1, abroad: 0, noInfo: 0 });
  assert.ok(!w.calls.some((call) => call.startsWith("travel")));
});

test("hours come from the document, then RTDB, then the key, and land once", async () => {
  const w = world({
    members: [toJapan, traveling(11, "Traveling from Torn to China"), traveling(12, "Traveling from UAE to Torn")],
  });
  sharing(w, 10, { flightArrival: NOW_SEC + 600, flightDestination: "Japan", flightDeparted: NOW_SEC - 60 });
  sharing(w, 11);
  sharing(w, 12);
  w.saved.times = { "12": flight(NOW_SEC + 300, "Torn"), "99": flight(NOW_SEC - 5) };
  w.travel.key11 = { owner: 11, time: flight(NOW_SEC + 700, "China") };

  const answer = await rows(w);
  assert.equal(arrivalOf(answer, 10), NOW_SEC + 600);
  assert.equal(arrivalOf(answer, 11), NOW_SEC + 700);
  assert.equal(arrivalOf(answer, 12), NOW_SEC + 300);
  assert.deepEqual(
    w.calls.filter((call) => call.startsWith("travel")),
    ["travel key11"]
  );
  assert.deepEqual(Object.keys(w.saved.times).sort(), ["11", "12"]);
});

test("a key changed after sharing is not used and the permission goes", async () => {
  const w = world({ members: [toJapan] });
  sharing(w, 10, { flightArrival: NOW_SEC + 600, flightDestination: "Japan" });
  w.docs.uid10.apiKey = "someone-elses-key";
  w.travel["someone-elses-key"] = { owner: 10, time: flight(NOW_SEC + 650) };
  const answer = await rows(w);
  assert.equal(arrivalOf(answer, 10), undefined);
  assert.ok(!w.calls.includes("travel someone-elses-key"));
  assert.equal(w.grants[10], undefined);
  assert.equal(w.docs.uid10.shareFlights, false);
});

test("an inactive device shares no saved hour", async () => {
  const w = world({ members: [toJapan] });
  w.saved.times["10"] = flight(NOW_SEC + 600);
  sharing(w, 10, { active: false });
  assert.equal(arrivalOf(await rows(w), 10), undefined);
});

test("a failing key waits before being tried again, Torn down doesn't count", async () => {
  const w = world({ members: [toJapan, traveling(11, "Traveling from Torn to China")] });
  sharing(w, 10);
  sharing(w, 11);
  w.travel.key11 = "down";
  await rows(w);
  assert.deepEqual(Object.keys(w.saved.failed), [keyHash("key10")]);

  w.answers = {};
  w.turns = {};
  w.calls = [];
  w.nowMs += 10 * 60_000;
  await rows(w);
  assert.deepEqual(
    w.calls.filter((call) => call.startsWith("travel")),
    ["travel key11"]
  );

  w.answers = {};
  w.turns = {};
  w.calls = [];
  w.nowMs += FAILED_KEY_WAIT_MS;
  await rows(w);
  assert.ok(w.calls.includes("travel key10"));
});

test("no more than the cap of other keys in one open", async () => {
  const members = Array.from({ length: 25 }, (_, i) => traveling(100 + i, "Traveling from Torn to Japan"));
  const w = world({ members });
  for (const member of members) sharing(w, member.id);
  await rows(w);
  assert.equal(w.calls.filter((call) => call.startsWith("travel")).length, MAX_FOREIGN_KEYS);
});

test("many accounts of one faction make one faction call a minute", async () => {
  const w = world({ members: [toJapan] });
  sharing(w, 10);
  w.travel.key10 = { owner: 10, time: flight(NOW_SEC + 600) };
  for (const uid of ["a", "b", "c"]) w.docs[uid] = { apiKey: `${uid}-key` };

  const first = await rows(w);
  const others = await Promise.all([rows(w, "p5", "a"), rows(w, "p6", "b")]);
  for (const answer of others) assert.deepEqual(answer, first);
  assert.deepEqual(
    w.calls.filter((call) => !call.startsWith("verify")),
    ["faction viewer-key", "travel key10"]
  );

  w.nowMs += 61_000;
  w.calls = [];
  await rows(w, "p5", "c");
  assert.deepEqual(
    w.calls.filter((call) => call.startsWith("faction")),
    ["faction c-key"]
  );
});

test("one open a minute per verified player, whatever the account", async () => {
  const w = world();
  w.docs.second = { apiKey: "viewer-key" };
  assert.equal((await open(w)).status, "ok");
  const again = await open(w, "viewer", "second");
  assert.equal(again.status, "limited");
  assert.ok(again.status === "limited" && again.retryIn > 0 && again.retryIn <= 60);
  assert.equal((await open(w)).status, "limited");
});

test("while a member asks Torn, the others get the last answer", async () => {
  const w = world();
  w.docs.a = { apiKey: "a-key" };
  w.answers[FACTION] = { at: w.nowMs - 90_000, flying: [], abroad: [{ id: 15, name: "P15", at: "Hawaii" }] };
  w.turns[`faction_${FACTION}`] = w.nowMs - 2000;
  const answer = await rows(w, "p5", "a");
  assert.equal(answer.abroad.length, 1);
  assert.deepEqual(w.calls, ["verify"]);
});

test("RTDB that doesn't answer refuses instead of skipping the limit", async () => {
  const w = world();
  assert.deepEqual(await open(w, "viewer", "viewer", { claimTurn: never }), { status: "unavailable" });
  assert.deepEqual(w.calls, []);
  assert.deepEqual(await open(w, "viewer", "viewer", { readAnswer: never }), { status: "unavailable" });
  assert.ok(!w.calls.some((call) => call.startsWith("faction")));
});

test("an account with no document of its own never reaches Torn", async () => {
  const w = world({ docs: {} });
  assert.deepEqual(await open(w, "x"), { status: "no_key" });
  assert.deepEqual(w.calls, []);
});

test("only Torn not answering gives the turns back", async () => {
  const w = world();
  assert.deepEqual(await open(w, "down"), { status: "torn_error" });
  assert.deepEqual(w.turns, {});

  w.docs.viewer.apiKey = "down-key";
  assert.deepEqual(await open(w), { status: "torn_error" });
  assert.deepEqual(w.turns, {});

  assert.deepEqual(await open(w, "broken"), { status: "torn_error" });
  assert.deepEqual(await open(w, "broken"), { status: "limited", retryIn: 60 });
});

test("a rejected token waits seconds, not a minute", async () => {
  const w = world();
  assert.deepEqual(await open(w, "expired"), { status: "no_login" });
  w.nowMs += 5000;
  assert.deepEqual(await open(w, "viewer"), { status: "limited", retryIn: 5 });
  w.nowMs += 6000;
  assert.equal((await open(w, "viewer")).status, "ok");
});

test("many failed checks from other accounts don't block a valid token", async () => {
  const w = world();
  for (let i = 0; i < 150; i++) {
    w.docs[`bot${i}`] = { apiKey: "bot-key" };
    await open(w, i % 2 ? "garbage" : "broken", `bot${i}`);
  }
  assert.equal(w.calls.length, 150);
  assert.equal((await open(w, "viewer")).status, "ok");
});

test("no key or token leaves the function in the answer", async () => {
  const w = world({ members: [toJapan] });
  sharing(w, 10);
  w.travel.key10 = { owner: 10, time: flight(NOW_SEC + 500) };
  const answer = await rows(w);
  const text = JSON.stringify([answer, w.answers]);
  assert.ok(!text.includes("key10") && !text.includes("viewer") && !text.includes(keyHash("key10")));
});

function shareDeps(w: World, more: Partial<ShareDeps> = {}): ShareDeps {
  return {
    ...turnDeps(w),
    readPlayer: async (uid) => w.docs[uid] ?? null,
    keyOwner: async (key) => {
      w.calls.push(`owner ${key}`);
      const owner = /^key(\d+)$/.exec(key)?.[1];
      return owner ? Number(owner) : null;
    },
    readGrant: async (playerId) => w.grants[playerId] ?? null,
    writeGrant: async (playerId, grant) => {
      if (grant) w.grants[playerId] = grant;
      else delete w.grants[playerId];
    },
    ...more,
  };
}

// Past every share limit
async function later<T>(w: World, call: () => Promise<T>): Promise<T> {
  w.nowMs += SHARE_PLAYER_EVERY_MS;
  return call();
}

test("sharing needs the player's token and their own key", async () => {
  const w = world();
  w.docs.phone = { apiKey: "key5", playerId: 5 };
  w.docs.forged = { apiKey: "key9", playerId: 5 };
  const set = (uid: string, token: unknown) => later(w, () => setFlightSharing(uid, true, token, shareDeps(w)));

  assert.deepEqual(await set("phone", undefined), { status: "no_login" });
  assert.deepEqual(await set("phone", "down"), { status: "torn_error" });
  assert.deepEqual(await set("forged", "p5"), { status: "not_owner" });
  assert.deepEqual(await set("phone", "viewer"), { status: "not_owner" });
  assert.deepEqual(w.grants, {});

  assert.deepEqual(await set("phone", "p5"), { status: "ok", share: true });
  assert.deepEqual(w.grants[5], { doc: "phone", keyHash: keyHash("key5") });
  assert.equal(w.docs.phone.shareFlights, true);
});

test("a player tries other keys once a minute, whatever the account", async () => {
  const w = world();
  for (const uid of ["a", "b"]) w.docs[uid] = { apiKey: "stolen-key", playerId: 5 };
  assert.deepEqual(await setFlightSharing("a", true, "p5", shareDeps(w)), { status: "not_owner" });
  assert.deepEqual(await setFlightSharing("b", true, "p5", shareDeps(w)), { status: "limited" });
  assert.deepEqual(
    w.calls.filter((call) => call.startsWith("owner")),
    ["owner stolen-key"]
  );
});

test("sharing from a new device moves the permission there", async () => {
  const w = world();
  w.docs.phone = { apiKey: "key5", playerId: 5, shareFlights: true };
  w.docs.tablet = { apiKey: "key5", playerId: 5 };
  w.grants[5] = { doc: "phone", keyHash: keyHash("key5") };
  assert.deepEqual(await setFlightSharing("tablet", true, "p5", shareDeps(w)), { status: "ok", share: true });
  assert.equal(w.grants[5].doc, "tablet");
  assert.equal(w.docs.phone.shareFlights, false);
});

test("stopping with the token clears it from any device", async () => {
  const w = world();
  w.docs.phone = { apiKey: "key5", playerId: 5 };
  w.docs.laptop = { apiKey: "other-key" };
  w.grants[5] = { doc: "phone", keyHash: keyHash("key5") };
  assert.deepEqual(await setFlightSharing("laptop", false, "p5", shareDeps(w)), { status: "ok", share: false });
  assert.equal(w.grants[5], undefined);
});

test("the device that turned sharing on can stop it without a login", async () => {
  const w = world();
  w.docs.phone = { apiKey: "new-key", playerId: 5, shareFlights: true };
  w.grants[5] = { doc: "phone", keyHash: keyHash("key5") };
  assert.deepEqual(await setFlightSharing("phone", false, undefined, shareDeps(w)), { status: "ok", share: false });
  assert.equal(w.grants[5], undefined);
  assert.equal(w.docs.phone.shareFlights, false);
  assert.deepEqual(w.calls, []);
});

test("stopping without the token clears only this document's permission", async () => {
  const stop = (w: World, uid: string) => setFlightSharing(uid, false, undefined, shareDeps(w));

  const sameKey = world();
  sameKey.docs.tablet = { apiKey: "key5", playerId: 5 };
  sameKey.docs.phone = { apiKey: "key5", playerId: 5, shareFlights: true };
  sameKey.grants[5] = { doc: "phone", keyHash: keyHash("key5") };
  assert.deepEqual(await stop(sameKey, "tablet"), { status: "pending" });
  assert.deepEqual(sameKey.grants[5], { doc: "phone", keyHash: keyHash("key5") });
  assert.equal(sameKey.docs.phone.shareFlights, true);

  const forged = world();
  forged.docs.forged = { apiKey: "key9", playerId: 5 };
  forged.grants[5] = { doc: "phone", keyHash: keyHash("key5") };
  const answer = await stop(forged, "forged");
  assert.ok(forged.grants[5]);
  delete forged.grants[5];
  forged.nowMs += 6000;
  assert.deepEqual(await stop(forged, "forged"), answer);
});

test("reading the setting", async () => {
  const w = world();
  w.docs.phone = { apiKey: "key5", playerId: 5 };
  w.docs.tablet = { apiKey: "key5", playerId: 5 };
  w.docs.forged = { apiKey: "key9", playerId: 5, shareFlights: true };
  w.grants[5] = { doc: "phone", keyHash: keyHash("key5") };
  const read = (uid: string, token: unknown) => later(w, () => readFlightSharing(uid, token, shareDeps(w)));

  assert.deepEqual(await read("phone", undefined), { share: true });
  assert.deepEqual(w.calls, []);
  assert.deepEqual(await read("tablet", "p5"), { share: true });
  assert.deepEqual(await read("tablet", undefined), { status: "no_login" });
  assert.deepEqual(await read("forged", undefined), { status: "no_login" });
  assert.deepEqual(await read("forged", "viewer"), { share: false });
  assert.deepEqual(await read("tablet", "down"), { status: "torn_error" });
  assert.deepEqual(await read("nobody", "p5"), { share: false });
});

test("the share functions have their own limit and refuse without RTDB", async () => {
  const w = world();
  w.docs.phone = { apiKey: "key5", playerId: 5 };
  assert.deepEqual(await setFlightSharing("phone", true, "p5", shareDeps(w)), { status: "ok", share: true });
  assert.deepEqual(await setFlightSharing("phone", false, "p5", shareDeps(w)), { status: "limited" });
  assert.ok(w.grants[5]);
  assert.deepEqual(await readFlightSharing("phone", "p5", shareDeps(w)), { share: true });
  assert.deepEqual(await readFlightSharing("phone", "p5", shareDeps(w)), { status: "limited" });

  const silent = shareDeps(world(), { claimTurn: never });
  assert.deepEqual(await setFlightSharing("phone", false, "p5", silent), { status: "unavailable" });
  assert.deepEqual(await readFlightSharing("phone", "p5", silent), { status: "unavailable" });
});

test("the alerts pass writes once per flight and only while flying", () => {
  const stats = { travel: { time_left: 300, timestamp: NOW_SEC + 300, destination: "Japan", departed: NOW_SEC - 900 } };
  assert.deepEqual(logSharedFlight(stats, { shareFlights: true, flightArrival: 0 }).firestoreUpdate, {
    flightArrival: NOW_SEC + 300,
    flightDestination: "Japan",
    flightDeparted: NOW_SEC - 900,
  });
  assert.equal(logSharedFlight(stats, { shareFlights: true, flightArrival: NOW_SEC + 300 }).firestoreUpdate, undefined);
  const landed = { travel: { time_left: 0, timestamp: 1 } };
  assert.equal(logSharedFlight(landed, { shareFlights: true }).firestoreUpdate, undefined);
});

test("the alerts pass leaves whoever does not share as they were", () => {
  const stats = { travel: { time_left: 300, timestamp: NOW_SEC + 300, destination: "Japan", departed: NOW_SEC - 900 } };
  assert.deepEqual(logSharedFlight(stats, { shareFlights: false }), {});
  assert.deepEqual(logSharedFlight(stats, {}), {});
});
