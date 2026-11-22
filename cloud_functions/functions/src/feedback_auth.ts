import { HttpsError, onCall } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as admin from "firebase-admin";
import { timingSafeEqual } from "crypto";
import { INVALID_KEY_ERRORS, getUserBasic } from "./torn_api";
import { anHourInMilliseconds } from "./time";
import { OPTIONS, forPlayer, signedIn } from "./feedback";
import { Author, isModerator, requireAuthor } from "./feedback_author";
import { deny, invalid } from "./feedback_input";
import { openModSession } from "./feedback_mod_session";
import { FIRST_PIN_VERSION, PIN_SECRET_NAMES, PIN_VERSION, hashPinWith, keyedWith, pinRecord, pinRef } from "./feedback_pin_hash";

export const tokenSecret = defineSecret("FEEDBACK_TOKEN_SECRET");
export const pinSecrets = PIN_SECRET_NAMES.map((name) => defineSecret(name));
const PASS_MS = 12 * anHourInMilliseconds;
const MOD_RECHECK_MS = anHourInMilliseconds;
const LOCK_MS = 15 * 60 * 1000;
const MAX_FAILURES = 5;
const TORN_TIMEOUT_MS = 8000;
const TORN_KEY = /^[A-Za-z0-9]{16}$/;
const PIN = /^\d{6,12}$/;
const PIN_OPTIONS = { ...OPTIONS, secrets: pinSecrets };

export interface Pass {
  p: number;
  n: string;
  c: string;
  pin: boolean;
  iat: number;
  exp: number;
}

type PinCheck = "none" | "ok" | "pin_required" | "pin_wrong" | "pin_locked";

function badPass(reason = "bad_token"): never {
  throw new HttpsError("unauthenticated", "Bad token", { reason });
}

export const keyed = (secret: { value(): string }, text: string) => keyedWith(secret.value(), text);

function pinKey(version: number) {
  const secret = pinSecrets[version - 1];
  if (secret === undefined) throw new Error(`No PIN secret v${version}`);
  return secret.value();
}

const newPinRecord = (pin: string) => pinRecord(pinKey(PIN_VERSION), pin);

async function passFor(player: Author, pin: boolean, cutAt = 0) {
  const iat = Math.max(Date.now(), cutAt + 1);
  const exp = iat + PASS_MS;
  const body = Buffer.from(JSON.stringify({ p: player.playerId, n: player.name, c: "web", pin, iat, exp }))
    .toString("base64url");
  return { token: `${body}.${keyed(tokenSecret, body).toString("base64url")}`, playerId: player.playerId,
    name: player.name, hasPin: pin, isModerator: await isModerator(player.playerId), expiresAt: exp };
}

// Passes issued until now stop working
async function cutPasses(playerId: number, fields: Record<string, unknown> = {}) {
  const now = admin.firestore.Timestamp.now();
  await pinRef(playerId).set({ ...fields, tokensValidAfter: now });
  return now.toMillis();
}

export async function readPass(token: unknown, client: string): Promise<Pass> {
  const [body, mac, rest] = typeof token === "string" ? token.split(".") : [];
  if (body === undefined || mac === undefined || rest !== undefined) badPass();
  const given = Buffer.from(mac, "base64url");
  const expected = keyed(tokenSecret, body);
  if (given.length !== expected.length || !timingSafeEqual(given, expected)) badPass();
  let pass: any;
  try {
    pass = JSON.parse(Buffer.from(body, "base64url").toString());
  } catch {
    badPass();
  }
  if (pass?.c !== client || typeof pass.exp !== "number" || typeof pass.iat !== "number") badPass();
  if (!Number.isSafeInteger(pass.p) || typeof pass.n !== "string" || typeof pass.pin !== "boolean") badPass();
  if (pass.exp <= Date.now()) badPass("token_expired");
  const validAfter = (await pinRef(pass.p).get()).get("tokensValidAfter")?.toMillis() ?? 0;
  if (pass.iat <= validAfter) badPass("token_expired");
  return pass;
}

// Torn says who owns the key
async function tornPlayer(apiKey: string): Promise<Author> {
  const answer = await getUserBasic(apiKey, TORN_TIMEOUT_MS).catch((): undefined => undefined);
  if (INVALID_KEY_ERRORS.includes(answer?.error?.code)) deny("bad_key");
  const { id, name } = answer?.profile ?? {};
  if (!Number.isSafeInteger(id) || id <= 0 || typeof name !== "string" || name === "") {
    throw new HttpsError("unavailable", "Torn unavailable", { reason: "torn_unavailable" });
  }
  return { playerId: id, name };
}

// Wrong guesses count, five lock it
async function checkPin(playerId: number, pin: unknown): Promise<PinCheck> {
  const ref = pinRef(playerId);
  return admin.firestore().runTransaction(async (t) => {
    const saved = await t.get(ref);
    if (saved.get("hash") === undefined) return "none";
    const now = Date.now();
    if ((saved.get("lockedUntil")?.toMillis() ?? 0) > now) return "pin_locked";
    if (pin === undefined) return "pin_required";
    const expected = Buffer.from(saved.get("hash"), "base64");
    const key = pinKey(saved.get("v") ?? FIRST_PIN_VERSION);
    const given = typeof pin === "string" && PIN.test(pin)
      ? await hashPinWith(key, pin, Buffer.from(saved.get("salt"), "base64"), expected.length) : undefined;
    if (given !== undefined && timingSafeEqual(given, expected)) {
      // Older secret version: hash it again
      if (saved.get("v") !== PIN_VERSION) t.update(ref, await newPinRecord(pin as string));
      else if (saved.get("failures") > 0) t.update(ref, { failures: 0 });
      return "ok";
    }
    const failures = (saved.get("failures") ?? 0) + 1;
    if (failures < MAX_FAILURES) {
      t.update(ref, { failures });
      return "pin_wrong";
    }
    t.update(ref, { failures: 0, lockedUntil: admin.firestore.Timestamp.fromMillis(now + LOCK_MS) });
    return "pin_locked";
  });
}

async function requirePin(player: Author, pin: unknown): Promise<boolean> {
  const check = await checkPin(player.playerId, pin);
  if (check !== "none" && check !== "ok") deny(check, player);
  return check === "ok";
}

// Checked before spending a login slot
export function tornKey(value: unknown): string {
  return typeof value === "string" && TORN_KEY.test(value) ? value : deny("bad_key");
}

export async function login(apiKey: string, pin: unknown) {
  const player = await tornPlayer(apiKey);
  return passFor(player, await requirePin(player, pin));
}

// A moderator's first PIN needs the script
async function savePin(player: Author, data: any) {
  const newPin = typeof data.newPin === "string" && PIN.test(data.newPin) ? data.newPin : invalid("newPin");
  const hadPin = await requirePin(player, data.currentPin);
  if (!hadPin && await isModerator(player.playerId)) deny("mod_first_pin_admin", player);
  return cutPasses(player.playerId, { ...await newPinRecord(newPin), setAt: admin.firestore.Timestamp.now() });
}

async function dropPin(player: Author, data: any) {
  if (await isModerator(player.playerId)) deny("mod_pin_remove_admin", player);
  await requirePin(player, data.currentPin);
  return cutPasses(player.playerId);
}

export async function setPin(player: Author, data: any) {
  return passFor(player, true, await savePin(player, data));
}

export async function removePin(player: Author, data: any) {
  return passFor(player, false, await dropPin(player, data));
}

export async function resetPin(data: any) {
  const playerId = data.playerId;
  if (!Number.isSafeInteger(playerId) || playerId <= 0) invalid("playerId");
  if (await isModerator(playerId)) deny("mod_pin_reset_admin_only");
  await cutPasses(playerId);
}

export const setPinFromApp = forPlayer(async (player, data) => {
  await savePin(player, data);
  return { hasPin: true };
}, PIN_OPTIONS);

export const removePinFromApp = forPlayer(async (player, data) => {
  await dropPin(player, data);
  return { hasPin: false };
}, PIN_OPTIONS);

// Moderation from the app needs the PIN
export const modUnlock = onCall(PIN_OPTIONS, async (request) => {
  const uid = signedIn(request);
  const quick = await requireAuthor(uid);
  const player = await isModerator(quick.playerId) ? await requireAuthor(uid, MOD_RECHECK_MS) : quick;
  if (!await isModerator(player.playerId)) deny("not_moderator");
  if (!await requirePin(player, request.data?.pin)) deny("mod_first_pin_admin");
  return { unlockedUntil: await openModSession(uid, player.playerId) };
});
