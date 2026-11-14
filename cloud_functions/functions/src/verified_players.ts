import * as admin from "firebase-admin";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { logger } from "firebase-functions/v2";
import { getUserSelections, INVALID_KEY_ERRORS, isApiKey } from "./torn_api";
import { takeRateLimitSlot } from "./rate_limit";
import { aDayInMilliseconds } from "./time";

// Assist and retals members by verifiedFaction
const VERIFIED_RECIPIENTS = true;
export const RECIPIENT_FACTION_FIELD = VERIFIED_RECIPIENTS ? "verifiedFaction" : "faction";

const BACKFILL_ENABLED = false;
// Same Torn calls, nothing written to players
const BACKFILL_DRY_RUN = true;
const DRY_RUN_BATCH = 1000;

export interface BackfillLimits {
  batch: number;
  dailyCap: number;
  pageSize: number;
  pagesPerRun: number;
  concurrency: number;
  maxRunMs: number;
}

const BACKFILL_LIMITS: BackfillLimits = {
  batch: 30000,
  dailyCap: 60000,
  pageSize: 1000,
  pagesPerRun: 100,
  concurrency: 50,
  maxRunMs: 500 * 1000,
};

const RECHECK_AFTER_MS = 30 * aDayInMilliseconds;
const RECHECK_SPREAD_MINUTES = 7 * 24 * 60;
export const MAX_RECHECK_MS = RECHECK_AFTER_MS + RECHECK_SPREAD_MINUTES * 60 * 1000;
export const CHECKS_PER_HOUR = 10;
const UNAVAILABLE_STREAK = 3;
const RETRY_PAUSE_MS = 2000;
const TORN_TIMEOUT_MS = 10 * 1000;
const VERIFIED_FIELDS = ["verifiedPlayerId", "verifiedFaction", "verifiedAt", "verifiedName"];

const pause = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

// Stable 0 to 7 day offset
function checkedRecently(uid: string, verifiedAt: unknown, now: number) {
  let minutes = 0;
  for (const char of uid) minutes = (minutes * 31 + char.charCodeAt(0)) % RECHECK_SPREAD_MINUTES;
  return typeof verifiedAt === "number" && now - verifiedAt < RECHECK_AFTER_MS + minutes * 60 * 1000;
}

function profileIds(profile: any) {
  const playerId = profile?.player_id;
  const faction = profile?.faction?.faction_id;
  if (!Number.isSafeInteger(playerId) || playerId <= 0 || !Number.isSafeInteger(faction) || faction < 0) {
    return undefined;
  }
  const name = typeof profile?.name === "string" && profile.name !== "" ? profile.name as string : undefined;
  return { playerId: playerId as number, faction: faction as number, name };
}

function needsVerifiedName(player: any) {
  return typeof player.verifiedAt === "number" && !(typeof player.verifiedName === "string" && player.verifiedName !== "");
}

// Undefined when nothing to write
export function verifiedUpdate(uid: string, player: any, profile: any, now: number): Record<string, number | string> | undefined {
  const ids = profileIds(profile);
  if (!ids) return undefined;
  const { playerId, faction, name } = ids;
  if (player.verifiedPlayerId === playerId && player.verifiedFaction === faction &&
    (name === undefined || player.verifiedName === name) &&
    checkedRecently(uid, player.verifiedAt, now)) return undefined;
  const update: Record<string, number | string> = { verifiedPlayerId: playerId, verifiedFaction: faction, verifiedAt: now };
  if (name !== undefined) update.verifiedName = name;
  return update;
}

function wantsVerification(player: any) {
  return player.factionAssistMessage === true || player.retalsNotification === true;
}

// "key" also clears when Torn is down
export function verifyReason(uid: string, before: any, after: any): "key" | "check" | undefined {
  if (after.active === false) return undefined;
  if (before.apiKey !== after.apiKey) return "key";
  if (before.playerId !== after.playerId || before.faction !== after.faction || before.active === false) return "check";
  if (before.lastActive !== after.lastActive && wantsVerification(after) &&
    !checkedRecently(uid, after.verifiedAt, Date.now())) return "check";
  return undefined;
}

// Undefined if Torn gave no clear answer
async function askTorn(apiKey: string, attempts: number) {
  for (let attempt = 1; attempt <= attempts; attempt++) {
    try {
      const profile = await getUserSelections(apiKey, "profile", "PDA-Profile", TORN_TIMEOUT_MS);
      if (!profile.error || INVALID_KEY_ERRORS.includes(profile.error.code)) return profile;
    } catch (e) {
      logger.warn(`Profile check failed: ${e}`);
    }
    if (attempt < attempts) await pause(RETRY_PAUSE_MS);
  }
  return undefined;
}

interface Probe {
  outcome: "good" | "no_faction" | "rejected" | "unavailable";
  ms: number;
  code?: number;
}

// Asks Torn and writes nothing
async function probePlayer(apiKey: string): Promise<Probe> {
  const start = Date.now();
  const profile = await askTorn(apiKey, 1);
  const ms = Date.now() - start;
  if (profile === undefined) return { outcome: "unavailable", ms };
  if (profile.error) return { outcome: "rejected", ms, code: profile.error.code };
  return { outcome: profileIds(profile) ? "good" : "no_faction", ms };
}

// Only numbers
function dryRunSummary(probes: Probe[], seconds: number) {
  const count = (outcome: Probe["outcome"]) => probes.filter((probe) => probe.outcome === outcome).length;
  const rejectedByCode: Record<string, number> = {};
  for (const probe of probes) {
    if (probe.code !== undefined) rejectedByCode[probe.code] = (rejectedByCode[probe.code] ?? 0) + 1;
  }
  const times = probes.map((probe) => probe.ms);
  return {
    asked: probes.length,
    good: count("good"),
    noFaction: count("no_faction"),
    rejected: count("rejected"),
    rejectedByCode,
    unavailable: count("unavailable"),
    meanMs: times.length > 0 ? Math.round(times.reduce((a, b) => a + b, 0) / times.length) : 0,
    maxMs: times.length > 0 ? Math.max(...times) : 0,
    seconds: Math.round(seconds * 10) / 10,
    callsPerMinute: seconds > 0 ? Math.round(probes.length / seconds * 60) : 0,
  };
}

export async function verifyPlayer(uid: string, apiKey: unknown, attempts = 2, clearIfUnavailable = false): Promise<string> {
  const profile = isApiKey(apiKey) ? await askTorn(apiKey, attempts) : { error: { code: 2 } };
  if (profile === undefined && !clearIfUnavailable) return "unavailable";

  const db = admin.firestore();
  const ref = db.collection("players").doc(uid);
  return db.runTransaction(async (t) => {
    const snap = await t.get(ref);
    // Key changed while asking
    if (!snap.exists || snap.get("apiKey") !== apiKey) return "stale";
    const player = snap.data();
    if (profile === undefined || profile.error) {
      const outcome = profile === undefined ? "unavailable" : "rejected";
      if (!VERIFIED_FIELDS.some((field) => player[field] !== undefined)) return outcome;
      const remove = admin.firestore.FieldValue.delete();
      t.update(ref, Object.fromEntries(VERIFIED_FIELDS.map((field) => [field, remove])));
      return outcome === "rejected" ? "cleared" : outcome;
    }
    const update = verifiedUpdate(uid, player, profile, Date.now());
    if (!update) return "unchanged";
    t.update(ref, update);
    return "verified";
  });
}

export async function verifyAfterWrite(uid: string, before: any, after: any) {
  const reason = verifyReason(uid, before, after);
  if (reason === undefined) return undefined;
  const hasKey = isApiKey(after.apiKey);
  const limited = hasKey && !await takeRateLimitSlot(`verify_${uid}`, CHECKS_PER_HOUR, 60 * 60 * 1000);
  if (limited) logger.info(`Verify ${uid}: hourly limit reached`);
  if (limited && reason !== "key") return "limited";
  // Over the limit only clears
  return verifyPlayer(uid, after.apiKey, limited ? 0 : 2, reason === "key");
}

export async function runVerifyBackfill(requested: BackfillLimits = BACKFILL_LIMITS, dryRun = BACKFILL_DRY_RUN) {
  const db = admin.firestore();
  const batch = dryRun ? Math.min(requested.batch, DRY_RUN_BATCH) : requested.batch;
  const limits = dryRun ? { ...requested, batch, dailyCap: batch } : requested;
  const probes: Probe[] = [];
  const stateRef = db.collection("verified_backfill").doc(dryRun ? "dry_run" : "state");
  const state = (await stateRef.get()).data() ?? {};
  const day = new Date().toISOString().slice(0, 10);
  const started = Date.now();
  let today: number = state.day === day ? state.today ?? 0 : 0;
  let cursor: string = state.cursor ?? "";
  // One lap per day at most
  if (state.lapDay === day && cursor === "") {
    logger.info("Verify backfill: lap already done today");
    return { asked: 0, today, pages: 0, lapDone: false, stopped: false, lapUnanswered: 0, outcomes: {} };
  }
  let unanswered: number = state.lapUnanswered ?? 0;
  let stopped = false;
  let cutTimes = 0;
  let cutAt = "";
  let asked = 0;
  let pages = 0;
  let lapDone = false;
  const outcomes: Record<string, number> = {};
  const block: { id: string; apiKey: string }[] = [];
  let blockStart = cursor;
  const canAsk = () => !stopped && asked + block.length < limits.batch && today + block.length < limits.dailyCap &&
    Date.now() - started < limits.maxRunMs;

  // Asks the block; half down cuts
  const askBlock = async () => {
    if (block.length === 0) return;
    const results = dryRun
      ? (await Promise.all(block.map(({ apiKey }) => probePlayer(apiKey)))).map((probe) => {
        probes.push(probe);
        return probe.outcome;
      })
      : await Promise.all(block.map(({ id, apiKey }) => verifyPlayer(id, apiKey, 1).catch((e) => {
        logger.warn(`Backfill call failed: ${e}`);
        return "error";
      })));
    asked += block.length;
    today += block.length;
    for (const outcome of results) outcomes[outcome] = (outcomes[outcome] ?? 0) + 1;
    const down = results.filter((outcome) => outcome === "unavailable").length;
    const unknown = down + results.filter((outcome) => outcome === "error").length;
    if (block.length < UNAVAILABLE_STREAK || down * 2 < block.length) {
      unanswered += unknown;
    } else if ((state.cutTimes ?? 0) > 0 && state.cutAt === blockStart) {
      // Second cut here: skip the block
      stopped = true;
      unanswered += unknown;
    } else {
      stopped = true;
      cutTimes = 1;
      cutAt = blockStart;
      cursor = blockStart;
    }
    block.length = 0;
  };

  while (pages < limits.pagesPerRun && canAsk() && !lapDone) {
    let query = db.collection("players")
      .where("active", "==", true)
      .orderBy(admin.firestore.FieldPath.documentId())
      .select("apiKey", "verifiedAt", "verifiedName")
      .limit(limits.pageSize);
    if (cursor !== "") query = query.startAfter(cursor);
    const page = await query.get();
    pages++;

    for (const doc of page.docs) {
      if (!canAsk()) break;
      const previous = cursor;
      cursor = doc.id;
      const player = doc.data();
      if (!needsVerifiedName(player) || !isApiKey(player.apiKey)) continue;
      if (block.length === 0) blockStart = previous;
      block.push({ id: doc.id, apiKey: player.apiKey });
      if (block.length >= limits.concurrency) await askBlock();
    }
    await askBlock();
    const last = page.docs[page.size - 1];
    if (!stopped && page.size < limits.pageSize && (last === undefined || cursor === last.id)) {
      lapDone = true;
      cursor = "";
    }
  }

  logger.info(`Verify backfill${dryRun ? " DRY RUN" : ""}: ${asked} asked, ${today} today, ${pages} pages, ` +
    `${stopped ? "stopped by Torn errors, " : ""}lap ${lapDone ? `done with ${unanswered} unanswered` : "open"}, ` +
    JSON.stringify(outcomes));
  const summary = dryRun ? dryRunSummary(probes, (Date.now() - started) / 1000) : undefined;
  if (summary) logger.info(`Verify backfill DRY RUN summary: ${JSON.stringify(summary)}`);
  await stateRef.set({
    cursor, day, today, cutTimes,
    cutAt: cutTimes > 0 ? cutAt : null,
    lapUnanswered: lapDone ? 0 : unanswered,
    lapDay: lapDone ? day : state.lapDay ?? "",
    updatedAt: Date.now(),
  });
  return { asked, today, pages, lapDone, stopped, lapUnanswered: unanswered, outcomes, summary };
}

export const verifyPlayersBackfill = onSchedule(
  {
    schedule: "*/10 * * * *",
    region: "us-east4",
    memory: "1GiB",
    timeoutSeconds: 540,
  },
  async () => {
    if (!BACKFILL_ENABLED) return;
    await runVerifyBackfill();
  }
);
