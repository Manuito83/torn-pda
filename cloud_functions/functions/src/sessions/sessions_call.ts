import { randomBytes } from "crypto";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import * as admin from "firebase-admin";
import { Author, requireAuthor } from "../feedback_author";
import { withSlots } from "../feedback";
import { takeRateLimitSlot } from "../rate_limit";
import { aDayInMilliseconds } from "../time";
import { readTake, takeRejection, answerRejection } from "./take";
import { CHECKER_DIR, CheckerFiles, Checked, cachedChecker, runChecker } from "./checker";
import {
  BASIC_LEVEL, StoredToken, effectiveLevel, levelFrom, levelOfTask, missingTasks, tokenFrom, tokenIsValid, withResult,
} from "./badges";

const LEVEL_KEY = "badge_level";
const TOKEN_TTL_MS = 7 * aDayInMilliseconds;
const BEGINS_PER_DAY = 100;
const ENDS_PER_DAY = 20;
const REFRESHES_PER_DAY = 20;
const ACCESS_PER_DAY = 300;
const REMOTE_CACHE_MS = 60 * 1000;

const options = { region: "us-east4", memory: "256MiB", timeoutSeconds: 30, maxInstances: 5 } as const;
// One check per instance at once
const endOptions = {
  region: "us-east4", memory: "1GiB", cpu: 1, concurrency: 1, timeoutSeconds: 60, maxInstances: 5,
} as const;

const loadedChecker = cachedChecker(CHECKER_DIR);

function checkerOrLog(): CheckerFiles | undefined {
  const checker = loadedChecker();
  if (typeof checker !== "string") return checker;
  logger.error(`checker missing: ${checker}`);
  return undefined;
}

// Logged at cold start if missing
if (process.env.FUNCTION_TARGET === "endSession") checkerOrLog();

const checkerMissing = () => new HttpsError("unavailable", "checker missing", { reason: "checker_missing" });

const tickets = () => admin.firestore().collection("session_tickets");
const badgeDocs = () => admin.firestore().collection("badges");

// Shut if unreadable
async function readRemoteLevel(): Promise<number> {
  try {
    const value = (await admin.remoteConfig().getTemplate()).parameters?.[LEVEL_KEY]?.defaultValue;
    return value !== undefined && "value" in value ? levelFrom(Number(value.value)) : 0;
  } catch (e) {
    logger.warn(`badges: Remote Config unreadable: ${e}`);
    return 0;
  }
}

function cachedLevel(ttlMs: number, read: () => Promise<number>): () => Promise<number> {
  let cache: { level: number; until: number } | undefined;
  return async () => {
    const now = Date.now();
    if (cache !== undefined && cache.until > now) return cache.level;
    const level = await read();
    cache = { level, until: now + ttlMs };
    return level;
  };
}

// Kept per instance
const remoteLevel = cachedLevel(REMOTE_CACHE_MS, readRemoteLevel);

async function listedLevel(playerId: unknown): Promise<number> {
  if (!Number.isSafeInteger(playerId) || (playerId as number) <= 0) return 0;
  return levelFrom((await admin.firestore().collection("badge_access").doc(`${playerId}`).get()).get("level"));
}

// Verified, open, within limits
async function asPlayer<T>(uid: string, action: string, perDay: number, write: (player: Author) => Promise<T>): Promise<T> {
  const closed = new HttpsError("failed-precondition", "closed", { reason: "closed" });
  if ((await takeRateLimitSlot(`badge_access_${uid}`, ACCESS_PER_DAY, aDayInMilliseconds)) === undefined) {
    throw new HttpsError("resource-exhausted", "limit", { reason: "limit" });
  }
  const remote = await remoteLevel();
  // Level read once per player id
  let lastRead: { playerId: unknown; level: number } | undefined;
  const levelOf = async (playerId: unknown) => {
    if (lastRead === undefined || lastRead.playerId !== playerId) lastRead = { playerId, level: await listedLevel(playerId) };
    return lastRead.level;
  };
  if (remote < BASIC_LEVEL) {
    // Shut for all, listed players only
    const saved = (await admin.firestore().collection("players").doc(uid).get()).get("verifiedPlayerId");
    if (effectiveLevel(remote, await levelOf(saved)) < BASIC_LEVEL) throw closed;
  }
  const player = await requireAuthor(uid);
  if (effectiveLevel(remote, await levelOf(player.playerId)) < BASIC_LEVEL) throw closed;
  return withSlots([[`session_${action}_${player.playerId}`, perDay, aDayInMilliseconds]], () => write(player));
}

export const beginSession = onCall(options, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in first");
  const checker = checkerOrLog();
  if (checker === undefined) throw checkerMissing();
  const task = request.data?.task;
  if (typeof task !== "string" || levelOfTask(checker.levels, task) === undefined) {
    throw new HttpsError("invalid-argument", "task is unknown");
  }
  const uid = request.auth.uid;
  return asPlayer(uid, "begin", BEGINS_PER_DAY, async (player) => {
    const token = randomBytes(24).toString("base64url");
    const seed = randomBytes(4).readUInt32LE(0);
    const now = Date.now();
    await tickets().doc(token).set({
      uid,
      playerId: player.playerId,
      task,
      seed,
      issuedAt: now,
      expireAt: admin.firestore.Timestamp.fromMillis(now + TOKEN_TTL_MS),
    });
    return { token, seed };
  });
});

export const endSession = onCall(endOptions, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in first");
  const uid = request.auth.uid;
  const token = tokenFrom(request.data?.token);
  const task = request.data?.task;
  const checker = checkerOrLog();
  if (checker === undefined) throw checkerMissing();
  const take = readTake(request.data?.recording, checker.header);
  if (token === undefined || typeof task !== "string" || take === undefined) {
    throw new HttpsError("invalid-argument", "token, task or recording malformed");
  }
  if (take.format > checker.format) throw checkerMissing();
  const level = levelOfTask(checker.levels, task);
  if (level === undefined) throw new HttpsError("invalid-argument", "token, task or recording malformed");
  if (take.format < checker.format) throw new HttpsError("failed-precondition", "update the app", { reason: "update_app" });
  const result = await asPlayer(uid, "end", ENDS_PER_DAY, async (player) => {
    const tokenRef = tickets().doc(token);
    const badgeRef = badgeDocs().doc(`${player.playerId}`);
    const saved = (await tokenRef.get()).data() as StoredToken | undefined;
    if (!tokenIsValid(saved, uid, player.playerId, task, Date.now())) {
      logger.info(`session ${task} rejected: token`);
      return { status: "rejected" };
    }
    let reason = takeRejection(take, saved.seed, saved.issuedAt, Date.now());
    let checked: Checked | undefined;
    if (reason === undefined) {
      const started = Date.now();
      const answer = await runChecker(checker, task, take.bytes, saved.seed);
      logger.info(`session ${task} checked in ${Date.now() - started} ms`);
      if ("unavailable" in answer) {
        // Slot spent, token kept
        logger.error(`session ${task} worker did not start: ${answer.unavailable}`);
        return { status: "unavailable" };
      }
      reason = answerRejection(answer, take, level);
      if (reason === "checker" && "error" in answer) logger.warn(`session ${task} checker: ${answer.error}`);
      if (reason === undefined && "checked" in answer) checked = answer.checked;
    }

    // The token is spent whatever the answer
    const rejected = await admin.firestore().runTransaction(async (transaction) => {
      const [again, badge] = await transaction.getAll(tokenRef, badgeRef);
      const now = Date.now();
      if (!tokenIsValid(again.data() as StoredToken | undefined, uid, player.playerId, task, now)) return "token";
      transaction.delete(tokenRef);
      if (reason !== undefined || checked === undefined) return reason ?? "checker";
      const stored = {
        score: checked.score, end: take.steps, extra: checked.extra, mark: checked.mark,
        format: checked.format, at: now,
      };
      transaction.set(
        badgeRef,
        { playerId: player.playerId, name: player.name, tasks: withResult(badge.get("tasks"), task, stored), updatedAt: now },
        { merge: true }
      );
      return undefined;
    });
    if (rejected !== undefined) {
      logger.info(`session ${task} rejected: ${rejected}`);
      return { status: "rejected" };
    }
    return { status: "ok" };
  });
  // Thrown after the slot is spent
  if (result.status === "unavailable") throw new HttpsError("unavailable", "checker did not start", { reason: "checker_down" });
  return result;
});

export const refreshBadges = onCall(options, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in first");
  const checker = checkerOrLog();
  if (checker === undefined) throw checkerMissing();
  return asPlayer(request.auth.uid, "refresh", REFRESHES_PER_DAY, async (player) => {
    const ref = badgeDocs().doc(`${player.playerId}`);
    return admin.firestore().runTransaction(async (transaction) => {
      const data = (await transaction.get(ref)).data();
      const missing = missingTasks(checker.levels, data?.tasks);
      if (missing.length > 0) return { status: "missing", missing };
      if (data?.basic === undefined) transaction.update(ref, { basic: { at: Date.now() } });
      return { status: "ok", missing: [] as string[] };
    });
  });
});
