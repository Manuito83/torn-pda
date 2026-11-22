import { HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import * as admin from "firebase-admin";
import { isApiKey } from "./torn_api";
import { returnRateLimitSlot, takeRateLimitSlot } from "./rate_limit";
import { CHECKS_PER_HOUR, MAX_RECHECK_MS, verifyPlayer } from "./verified_players";
import { anHourInMilliseconds } from "./time";
import { modSessionUntil } from "./feedback_mod_session";
import { cleanText, deny, invalid } from "./feedback_input";

const VERIFIES_PER_HOUR = 600;

export interface Author {
  playerId: number;
  name: string;
  // Moderator without PIN or app session
  asPlayer?: boolean;
  modUntil?: number;
}

type Reason = "no_player" | "no_key" | "not_verified" | "verify_busy";

export const modsRef = () => admin.firestore().collection("feedback_mods");

// Server written fields only, never players.name
function verifiedAuthor(player: any, now: number): Author | undefined {
  const { verifiedPlayerId, verifiedName, verifiedAt } = player;
  if (typeof verifiedAt !== "number" || now - verifiedAt >= MAX_RECHECK_MS) return undefined;
  if (!Number.isSafeInteger(verifiedPlayerId) || verifiedPlayerId <= 0) return undefined;
  if (typeof verifiedName !== "string" || verifiedName === "") return undefined;
  return { playerId: verifiedPlayerId, name: verifiedName };
}

// Per uid first, then the global cap
async function takeVerifySlot(uid: string): Promise<"taken" | "limited" | "busy"> {
  const id = `verify_${uid}`;
  const windowStart = await takeRateLimitSlot(id, CHECKS_PER_HOUR, anHourInMilliseconds);
  if (windowStart === undefined) return "limited";
  if (await takeRateLimitSlot("feedback_verify_total", VERIFIES_PER_HOUR, anHourInMilliseconds) !== undefined) return "taken";
  logger.warn(`Feedback: verify cap reached, ${uid} not verified`);
  await returnRateLimitSlot(id, windowStart, anHourInMilliseconds).catch((e) => logger.warn(`Feedback: slot ${id} not returned: ${e}`));
  return "busy";
}

// Asks Torn now, undefined if unconfirmed
async function verifyAuthorNow(uid: string, apiKey: string): Promise<Author | undefined | "busy"> {
  const slot = await takeVerifySlot(uid);
  if (slot !== "taken") return slot === "busy" ? slot : undefined;
  const outcome = await verifyPlayer(uid, apiKey, 1);
  logger.info(`Feedback: verify ${uid} ${outcome}`);
  if (outcome !== "verified" && outcome !== "unchanged") return undefined;
  const fresh = (await admin.firestore().collection("players").doc(uid).get()).data();
  return fresh === undefined ? undefined : verifiedAuthor(fresh, Date.now());
}

// Moderators act as players without a session
export async function findAuthor(uid: string, verifyNow = true, recheckAfterMs?: number): Promise<Author | Reason> {
  const player = (await admin.firestore().collection("players").doc(uid).get()).data();
  if (player === undefined) return "no_player";
  const now = Date.now();
  let author = verifiedAuthor(player, now);
  if (recheckAfterMs !== undefined && now - player.verifiedAt >= recheckAfterMs) author = undefined;
  if (author === undefined && verifyNow && isApiKey(player.apiKey)) {
    const checked = await verifyAuthorNow(uid, player.apiKey);
    if (checked === "busy") return "verify_busy";
    author = checked;
  }
  if (author === undefined) return isApiKey(player.apiKey) ? "not_verified" : "no_key";
  const modUntil = await modSessionUntil(uid, author.playerId);
  return modUntil === undefined ? { ...author, asPlayer: true } : { ...author, modUntil };
}

// Older verifications are asked again
export async function requireAuthor(uid: string, recheckAfterMs?: number): Promise<Author> {
  const author = await findAuthor(uid, true, recheckAfterMs);
  if (typeof author === "string") throw new HttpsError("failed-precondition", author, { reason: author });
  return author;
}

export async function isModerator(playerId: number): Promise<boolean> {
  return (await modsRef().doc(`${playerId}`).get()).exists;
}

// Saved by alta-moderador, never by clients
export async function moderatorName(playerId: number): Promise<string | undefined> {
  const name = (await modsRef().doc(`${playerId}`).get()).get("name");
  return typeof name === "string" && name !== "" ? name : undefined;
}

export async function moderatorIds(): Promise<Set<number>> {
  return new Set((await modsRef().get()).docs.map((doc) => Number(doc.id)));
}

export async function actsAsModerator(author?: Author): Promise<boolean> {
  return author !== undefined && !author.asPlayer && await isModerator(author.playerId);
}

export async function asModerator(author: Author): Promise<Author> {
  if (await actsAsModerator(author)) return author;
  if (author.asPlayer && await isModerator(author.playerId)) deny("mod_locked");
  throw new HttpsError("permission-denied", "Not a moderator");
}

export async function requireModerator(uid: string): Promise<Author> {
  return asModerator(await requireAuthor(uid));
}

// Named by an API client or moderator
export function givenPlayer(value: any, what: string): Author {
  const playerId = value?.playerId;
  const name = cleanText(value?.name, 1, 32, false);
  if (!Number.isSafeInteger(playerId) || playerId <= 0 || name === undefined) invalid(what);
  return { playerId, name };
}
