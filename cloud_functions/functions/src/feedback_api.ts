import { onRequest, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { logger } from "firebase-functions/v2";
import * as admin from "firebase-admin";
import { createHash, timingSafeEqual } from "crypto";
import { aDayInMilliseconds, anHourInMilliseconds } from "./time";
import { takeRateLimitSlot } from "./rate_limit";
import { moderateAs } from "./feedback_moderation";
import { getFeedback, listComments, listFeedback, listReports, readConfig } from "./feedback_reads";
import { attachmentLinks, confirmAttachment, deleteAttachment, requestAttachment } from "./feedback_attachments";
import { subscribeTo, subscribeToAll } from "./feedback_subscriptions";
import { addComment, deleteOwn } from "./feedback_comments";
import { adminLogSummary, adminMods, adminStats } from "./feedback_admin";
import { mineOf } from "./feedback_mine";
import { touchUser } from "./feedback_users";
import { keyed, login, pinSecrets, readPass, removePin, resetPin, setPin, tokenSecret, tornKey } from "./feedback_auth";
import { Slot, castVote, createFeedback, stateOf, withSlots } from "./feedback";
import { Author, asModerator, givenPlayer, isOwner, moderatorName, requireOwner } from "./feedback_author";
import { deny, invalid } from "./feedback_input";

const KEYS = [["web", defineSecret("FEEDBACK_API_KEY_WEB")], ["bot", defineSecret("FEEDBACK_API_KEY_BOT")]] as const;
const WRITES_PER_CLIENT = 3000;
const READS_PER_CLIENT: Record<Client, number> = { web: 30000, bot: 6000 };
const READ_SHARDS = 50;
const LOGINS_PER_CLIENT = 600;
const LOGINS_PER_IP = 30;
const LOGINS_TOTAL_WEB = 3000;
const REJECTIONS_PER_CLIENT = 600;
const LOG_TTL_MS = 90 * aDayInMilliseconds;
const MODERATION = ["moderate", "createBug", "resetPin"];
const BOT_MODERATION = ["setStatus", "setTags"];
const LOGGED_REASONS = ["no_actor", "not_allowed", "not_moderator", "pin_needed_for_moderation", "pin_wrong", "pin_locked",
  "mod_first_pin_admin", "mod_pin_remove_admin", "mod_pin_reset_admin_only", "owner_only"];
const ERRORS: Record<string, string> = {
  "invalid-argument": "invalid",
  "not-found": "not_found",
  "resource-exhausted": "rate_limited",
  "permission-denied": "forbidden",
  "failed-precondition": "precondition",
};

type Client = "web" | "bot";

interface Caller {
  client: Client;
  actor?: Author;
  ip?: string;
}

type Reader = (actor: Author | undefined, data: any) => Promise<unknown>;
type Writer = (actor: Author, data: any) => Promise<unknown>;

function forbidden(): never {
  throw new HttpsError("permission-denied", "No actor");
}

const READS = new Map<string, Reader>([
  ["list", listFeedback],
  ["get", getFeedback],
  ["comments", listComments],
  ["config", readConfig],
  ["attachmentLinks", attachmentLinks],
  ["listReports", (actor, data) => listReports(actor ?? forbidden(), data)],
  ["myState", async (actor, data) => ({ ...await stateOf(actor ?? forbidden(), data), isOwner: await isOwner(actor) })],
  ["mine", (actor, data) => mineOf(actor ?? forbidden(), data)],
]);
// Reads that need the signed player
const PLAYER_READS = ["myState", "mine", "listReports"];

// Owner only, for the web's Admin page
const ADMIN = new Map<string, () => Promise<unknown>>([
  ["adminMods", adminMods],
  ["adminLogSummary", adminLogSummary],
  ["adminStats", adminStats],
]);

const WRITES = new Map<string, Writer>([
  ["create", (actor, data) => createFeedback(actor, { ...data, type: "suggestion" })],
  ["createBug", (actor, data) => createFeedback(actor, { ...data, type: "bug" })],
  ["createReport", (actor, data) => createFeedback(actor, { ...data, type: "bug" }, true)],
  ["vote", castVote],
  ["comment", addComment],
  ["deleteOwnComment", deleteOwn],
  ["requestAttachment", requestAttachment],
  ["confirmAttachment", confirmAttachment],
  ["deleteAttachment", deleteAttachment],
  ["subscribe", subscribeTo],
  ["subscribeAll", subscribeToAll],
  ["moderate", async (actor, data) => moderateAs(await asModerator(actor), { ...data, action: data.moderation })],
  ["setPin", setPin],
  ["removePin", removePin],
  ["resetPin", async (actor, data) => {
    await requireOwner(actor);
    return resetPin(data);
  }],
]);

const digest = (text: string) => createHash("sha256").update(text).digest();
const text = (value: unknown) => typeof value === "string" ? value.slice(0, 64) : null;

function clientOf(key: string | undefined): Client | undefined {
  if (key === undefined) return undefined;
  const given = digest(key);
  const matches = KEYS.filter(([, secret]) => secret.value() !== "" && timingSafeEqual(given, digest(secret.value())));
  return matches.length === 1 ? matches[0][0] : undefined;
}

// Bot names the actor, web signs it
async function callerOf(client: Client, action: unknown, actor: unknown, token: unknown): Promise<Caller> {
  if (client === "bot") {
    if (token !== undefined) invalid("token");
    return { client, actor: actor === undefined ? undefined : { ...givenPlayer(actor, "actor"), bot: true } };
  }
  if (actor !== undefined) invalid("actor");
  if (token === undefined || action === "login") return { client };
  const pass = await readPass(token, client);
  return { client, actor: { playerId: pass.p, name: pass.n, ...(pass.pin ? {} : { asPlayer: true }) } };
}

function botAllows(action: unknown, data: any) {
  return (READS.has(action as string) && !PLAYER_READS.includes(action as string)) || action === "createBug" ||
    (action === "moderate" && BOT_MODERATION.includes(data.moderation));
}

// The bot's actor name is not trusted
async function mustModerate(caller: Caller): Promise<Author> {
  if (caller.actor === undefined) deny("no_actor");
  const name = await moderatorName(caller.actor.playerId);
  if (name === undefined) deny("not_moderator");
  if (caller.actor.asPlayer) deny("pin_needed_for_moderation");
  return caller.client === "bot" ? { ...caller.actor, name } : caller.actor;
}

async function takeSlot(id: string, limit: number) {
  if (await takeRateLimitSlot(id, limit, anHourInMilliseconds) === undefined) {
    throw new HttpsError("resource-exhausted", "Too many requests", { reason: "rate_limited" });
  }
}

// Shards keep one document from getting hot
const shard = () => Math.floor(Math.random() * READ_SHARDS);
const ipKey = (ip: string) => keyed(tokenSecret, ip).toString("hex").slice(0, 32);

// No IP slot: the web limits visitors
function readSlots({ client }: Caller): Slot[] {
  return [[`feedback_api_read_${client}_${shard()}`, READS_PER_CLIENT[client] / READ_SHARDS, anHourInMilliseconds]];
}

function loginSlots({ client, ip }: Caller): [string, number][] {
  return ip === undefined ? [[`feedback_api_login_${client}`, LOGINS_PER_CLIENT]]
    : [[`feedback_api_login_ip_${ipKey(ip)}`, LOGINS_PER_IP], ["feedback_api_login_web_total", LOGINS_TOTAL_WEB]];
}

function logLine(client: Client, actor: Author | undefined, action: unknown, data: any, fields: Record<string, unknown>) {
  const now = Date.now();
  return admin.firestore().collection("feedback_api_log").add({
    at: admin.firestore.Timestamp.fromMillis(now),
    client,
    actorPlayerId: actor?.playerId ?? null,
    actorName: actor?.name ?? null,
    action: action === "moderate" ? `moderate:${text(data.moderation)}` : text(action),
    feedbackId: text(data.feedbackId),
    number: Number.isSafeInteger(data.number) ? data.number : null,
    ...(action === "resetPin" && Number.isSafeInteger(data.playerId) ? { targetPlayerId: data.playerId } : {}),
    ...fields,
    expireAt: admin.firestore.Timestamp.fromMillis(now + LOG_TTL_MS),
  }).catch((e) => logger.warn(`Feedback API: log not written: ${e}`));
}

// False once the hourly limit is spent
async function logRejection(client: Client, actor: Author | undefined, body: any, reason: string) {
  const slot = await takeRateLimitSlot(`feedback_api_rejected_${client}`, REJECTIONS_PER_CLIENT, anHourInMilliseconds)
    .catch((e) => {
      logger.warn(`Feedback API: rejection slot failed: ${e}`);
      return 0;
    });
  if (slot === undefined) return false;
  await logLine(client, actor, body.action, body, { result: "rejected", reason });
  return true;
}

async function run(caller: Caller, action: unknown, data: any) {
  if (caller.client === "bot" && !botAllows(action, data)) deny("not_allowed");
  if (action === "login") {
    const apiKey = tornKey(data.apiKey);
    for (const slot of loginSlots(caller)) await takeSlot(...slot);
    const pass = await login(apiKey, data.pin);
    await touchUser(pass.playerId, "web");
    return pass;
  }
  const adminRead = ADMIN.get(action as string);
  if (adminRead !== undefined) {
    const owner = await mustModerate(caller);
    await requireOwner(owner);
    const result = await withSlots(readSlots(caller), adminRead);
    await logLine(caller.client, owner, action, data, { result: "ok" });
    return result;
  }
  const read = READS.get(action as string);
  if (read !== undefined) {
    // Bot actor counts only for private reads
    if (data.includePrivate !== true) {
      const reader = caller.client === "bot" ? undefined : caller.actor;
      return withSlots(readSlots(caller), () => read(reader, data));
    }
    const moderator = await mustModerate(caller);
    const result = await withSlots(readSlots(caller), () => read(moderator, data));
    await logLine(caller.client, moderator, action, data, { result: "ok" });
    if (caller.client === "bot") await touchUser(moderator.playerId, "bot");
    return result;
  }
  const write = WRITES.get(action as string) ?? invalid("action");
  const actor = MODERATION.includes(action as string) ? await mustModerate(caller) : caller.actor ?? forbidden();
  const slots: Slot[] = action === "moderate" && data.moderation === "getSource" ? readSlots(caller)
    : [[`feedback_api_${caller.client}`, WRITES_PER_CLIENT, anHourInMilliseconds]];
  const result: any = await withSlots(slots, () => write(actor, data));
  await logLine(caller.client, actor, action, { ...data, feedbackId: result?.feedbackId ?? data.feedbackId, number: result?.number ?? data.number }, { result: "ok" });
  if (caller.client === "bot") await touchUser(actor.playerId, "bot");
  return result;
}

// For the Discord bot and the web
export const api = onRequest({ region: "us-east4", timeoutSeconds: 60, maxInstances: 2,
  secrets: [...KEYS.map(([, secret]) => secret), tokenSecret, ...pinSecrets] }, async (request, response) => {
  const client = clientOf(request.get("X-Feedback-Key"));
  if (client === undefined) {
    response.status(401).end();
    return;
  }
  const ip = client === "web" ? request.get("X-Feedback-Client-IP")?.slice(0, 64) || undefined : undefined;
  let caller: Caller = { client, ip };
  let body: any = {};
  try {
    if (request.method !== "POST" || typeof request.body !== "object" || request.body === null) invalid("request");
    body = request.body;
    const { action, actor, token, ...data } = body;
    caller = { ...await callerOf(client, action, actor, token), ip };
    response.json({ ok: true, ...(await run(caller, action, data) as object) });
  } catch (e) {
    if (!(e instanceof HttpsError)) {
      logger.error(`Feedback API: ${e}`);
      response.status(500).json({ ok: false, error: "internal" });
      return;
    }
    const { reason, player } = (e.details ?? {}) as { reason?: string; player?: Author };
    if (reason !== undefined && LOGGED_REASONS.includes(reason) &&
      !await logRejection(client, player ?? caller.actor, body, reason)) {
      response.status(429).json({ ok: false, error: "rate_limited", reason: "rate_limited" });
      return;
    }
    response.status(e.httpErrorCode.status).json({ ok: false, error: ERRORS[e.code] ?? e.code, reason });
  }
});
