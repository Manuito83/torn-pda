import { createHash } from "node:crypto";
import { KEY_ERRORS } from "./torn";

export const MAX_FOREIGN_KEYS = 10;
export const OPEN_EVERY_MS = 60_000;
export const REJECTED_WAIT_MS = 10_000;
export const SHARE_EVERY_MS = 5_000;
export const SHARE_PLAYER_EVERY_MS = 60_000;
export const FAILED_KEY_WAIT_MS = 30 * 60_000;
export const STALE_ANSWER_MS = 5 * 60_000;
const MAX_TOKEN_LENGTH = 4096;

export interface FlyingMember {
  id: number;
  name: string;
  from: string;
  to: string;
}

export interface AbroadMember {
  id: number;
  name: string;
  at: string;
}

export interface FlightTime {
  arrival: number;
  departed?: number;
  destination: string;
}

export interface FlightRow extends FlyingMember {
  arrival?: number;
  departed?: number;
}

export interface Verified {
  playerId: number;
  factionId: number;
}

// "error" is a bad answer, "down" none
export type Verification = Verified | "invalid" | "error" | "down";

// Server-written, one per player
export interface Grant {
  doc: string;
  keyHash: string;
}

export interface SharerDoc {
  apiKey?: string;
  active?: boolean;
  flightArrival?: number;
  flightDestination?: string;
  flightDeparted?: number;
}

interface Sharer extends SharerDoc {
  playerId: number;
  apiKey: string;
  keyHash: string;
}

export interface SavedAnswer {
  at: number;
  flying: FlightRow[];
  abroad: AbroadMember[];
}

export type FlightsAnswer =
  | { status: "no_login" | "no_key" | "no_faction" | "torn_error" | "unavailable" }
  | { status: "limited"; retryIn: number }
  | {
      status: "ok";
      flying: FlightRow[];
      abroad: AbroadMember[];
      counts: { flying: number; withTime: number; abroad: number; noInfo: number };
    };

export interface SavedFlights {
  times: Record<string, FlightTime>;
  // Key hash to retry time
  failed: Record<string, number>;
}

interface VerifyDeps {
  nowMs(): number;
  rtdbWaitMs: number;
  verify(apiToken: string): Promise<Verification>;
  // Seconds to wait, 0 when allowed
  claimTurn(turn: string, nowMs: number, everyMs: number): Promise<number>;
  // Null gives the turn back
  setTurn(turn: string, nowMs: number, lastMs: number | null): Promise<void>;
  // Hint for the alerts pass only
  markDoc(docId: string, share: boolean): Promise<void>;
  warn(message: string): void;
}

export interface FlightsDeps extends VerifyDeps {
  readAnswer(factionId: number): Promise<SavedAnswer | null>;
  writeAnswer(factionId: number, answer: SavedAnswer): Promise<void>;
  readKey(uid: string): Promise<string | undefined>;
  // "error" means Torn didn't answer
  readFaction(apiKey: string): Promise<{ id: number; members: any[] } | "no_faction" | "error" | "refused">;
  readGrants(playerIds: number[]): Promise<Record<string, Grant>>;
  readDocs(docIds: string[]): Promise<Record<string, SharerDoc>>;
  readSaved(factionId: number): Promise<SavedFlights>;
  // Null entries are removed
  writeSaved(
    factionId: number,
    times: Record<string, FlightTime | null>,
    failed: Record<string, number | null>,
    revoked: number[]
  ): Promise<void>;
  // Null when Torn refuses the key
  readTravel(apiKey: string): Promise<{ owner: number; time: FlightTime | null } | null>;
}

function inTime<T>(call: Promise<T>, waitMs: number): Promise<T> {
  let timer: NodeJS.Timeout;
  const cut = new Promise<never>((_, reject) => {
    timer = setTimeout(() => reject(new Error("RTDB timeout")), waitMs);
  });
  return Promise.race([call, cut]).finally(() => clearTimeout(timer));
}

function wholeId(value: unknown): number | null {
  const id = typeof value === "number" || (typeof value === "string" && /^\d+$/.test(value)) ? Number(value) : NaN;
  return Number.isSafeInteger(id) && id >= 0 ? id : null;
}

export function usableToken(token: unknown): token is string {
  return typeof token === "string" && token.length > 0 && token.length <= MAX_TOKEN_LENGTH;
}

// Only valid true counts, whatever else comes
export function readVerification(data: any): Verified | "invalid" {
  if (data?.valid !== true) return "invalid";
  const playerId = wholeId(data.player_id ?? data.playerId);
  const factionId = wholeId(data.factionId ?? data.faction_id ?? 0);
  if (!playerId || factionId === null) return "invalid";
  return { playerId, factionId };
}

export function keyHash(apiKey: string): string {
  return createHash("sha256").update(apiKey).digest("hex");
}

// RTDB silent means no limit, so refuse
async function takeTurn(turn: string, nowMs: number, everyMs: number, deps: VerifyDeps): Promise<number | "unavailable"> {
  try {
    return await inTime(deps.claimTurn(turn, nowMs, everyMs), deps.rtdbWaitMs);
  } catch (e: any) {
    deps.warn(`flights: limit unreadable: ${e?.message}`);
    return "unavailable";
  }
}

function putTurn(turn: string, nowMs: number, lastMs: number | null, deps: VerifyDeps) {
  return inTime(deps.setTurn(turn, nowMs, lastMs), deps.rtdbWaitMs).catch((e: any) =>
    deps.warn(`flights: turn not reset: ${e?.message}`)
  );
}

const _sameName: Record<string, string> = { "UK": "United Kingdom", "United Arab Emirates": "UAE" };

function country(name: string): string {
  return _sameName[name] ?? name;
}

export function readMembers(members: any[]): { flying: FlyingMember[]; abroad: AbroadMember[] } {
  const flying: FlyingMember[] = [];
  const abroad: AbroadMember[] = [];
  for (const member of members ?? []) {
    const text = String(member?.status?.description ?? "").trim();
    if (member?.status?.state === "Traveling") {
      const both = /^Traveling from (.+) to (.+)$/.exec(text);
      const out = /^Traveling to (.+)$/.exec(text);
      const back = /^Returning to Torn from (.+)$/.exec(text);
      const from = both?.[1] ?? back?.[1] ?? (out ? "Torn" : null);
      const to = both?.[2] ?? out?.[1] ?? (back ? "Torn" : null);
      if (from && to) flying.push({ id: member.id, name: member.name, from: country(from), to: country(to) });
    } else if (member?.status?.state === "Abroad") {
      const place = /^In (.+)$/.exec(text);
      if (place) abroad.push({ id: member.id, name: member.name, at: country(place[1]) });
    }
  }
  return { flying, abroad };
}

// Old flights or another destination don't count
export function validTime(time: FlightTime | null | undefined, to: string, nowSec: number): boolean {
  return !!time && time.arrival > nowSec && country(time.destination) === to;
}

// Null only when Torn refuses the key
export function readTravelAnswer(data: any): { owner: number; time: FlightTime | null } | null {
  if (data?.error) {
    const code = Number(data.error.code);
    if (KEY_ERRORS.has(code)) return null;
    throw new Error(`Torn error ${code}`);
  }
  const owner = data?.profile?.id;
  if (typeof owner !== "number") throw new Error("Torn answer without a player");
  const travel = data.travel;
  if (!travel?.destination || !travel?.arrival_at) return { owner, time: null };
  return { owner, time: { arrival: travel.arrival_at, departed: travel.departed_at, destination: travel.destination } };
}

function sharerTime(sharer: Sharer): FlightTime | null {
  if (!sharer.flightArrival || !sharer.flightDestination) return null;
  return { arrival: sharer.flightArrival, departed: sharer.flightDeparted, destination: sharer.flightDestination };
}

function pickTime(found: Map<number, FlightTime>, id: number, time: FlightTime) {
  const known = found.get(id);
  if (!known || (!known.departed && time.departed)) found.set(id, time);
}

function okAnswer(saved: SavedAnswer): FlightsAnswer {
  const flying = saved.flying ?? [];
  const abroad = saved.abroad ?? [];
  const withTime = flying.filter((row) => row.arrival).length;
  return {
    status: "ok",
    flying,
    abroad,
    counts: { flying: flying.length, withTime, abroad: abroad.length, noInfo: flying.length - withTime },
  };
}

export async function buildFactionFlights(uid: string, apiToken: unknown, deps: FlightsDeps): Promise<FlightsAnswer> {
  if (!usableToken(apiToken)) return { status: "no_login" };
  const nowMs = deps.nowMs();
  const taken: string[] = [];

  const claim = async (turn: string): Promise<FlightsAnswer | null> => {
    const wait = await takeTurn(turn, nowMs, OPEN_EVERY_MS, deps);
    if (wait === "unavailable") return { status: "unavailable" };
    if (wait > 0) return { status: "limited", retryIn: wait };
    taken.push(turn);
    return null;
  };
  const giveBack = (turns: string[]) => Promise.all(turns.map((turn) => putTurn(turn, nowMs, null, deps)));

  const accountTurn = `account_${uid}`;
  const accountWait = await claim(accountTurn);
  if (accountWait) return accountWait;

  const apiKey = await deps.readKey(uid);
  if (!apiKey) return { status: "no_key" };

  const verified = await deps.verify(apiToken);
  if (verified === "down") {
    await giveBack(taken);
    return { status: "torn_error" };
  }
  if (verified === "error") return { status: "torn_error" };
  if (verified === "invalid") {
    // A fresh login can try again soon
    await putTurn(accountTurn, nowMs, nowMs - OPEN_EVERY_MS + REJECTED_WAIT_MS, deps);
    return { status: "no_login" };
  }
  if (verified.factionId === 0) return { status: "no_faction" };
  const factionId = verified.factionId;

  const playerWait = await claim(`player_${verified.playerId}`);
  if (playerWait) return playerWait;

  let cached: SavedAnswer | null;
  try {
    cached = await inTime(deps.readAnswer(factionId), deps.rtdbWaitMs);
  } catch (e: any) {
    deps.warn(`flights: saved answer unreadable: ${e?.message}`);
    return { status: "unavailable" };
  }
  if (cached && nowMs - cached.at < OPEN_EVERY_MS) return okAnswer(cached);

  const factionTurn = `faction_${factionId}`;
  const factionWait = await claim(factionTurn);
  // Another member is asking Torn right now
  if (factionWait?.status === "limited" && cached && nowMs - cached.at < STALE_ANSWER_MS) return okAnswer(cached);
  if (factionWait) return factionWait;

  const faction = await deps.readFaction(apiKey);
  if (faction === "error") {
    await giveBack(taken);
    return { status: "torn_error" };
  }
  if (faction === "no_faction" || faction === "refused" || faction.id !== factionId) {
    await giveBack([factionTurn]);
    return { status: "torn_error" };
  }

  const { flying, abroad } = readMembers(faction.members);
  const times = flying.length > 0 ? await readTimes(factionId, flying, nowMs, deps) : new Map<number, FlightTime>();
  const rows: FlightRow[] = flying.map((member) => {
    const time = times.get(member.id);
    return time ? { ...member, arrival: time.arrival, departed: time.departed } : member;
  });
  const answer: SavedAnswer = { at: nowMs, flying: rows, abroad };
  await inTime(deps.writeAnswer(factionId, answer), deps.rtdbWaitMs).catch((e: any) =>
    deps.warn(`flights: answer not saved: ${e?.message}`)
  );
  return okAnswer(answer);
}

// Granted documents, then RTDB, then their keys
async function readTimes(
  factionId: number,
  flying: FlyingMember[],
  nowMs: number,
  deps: FlightsDeps
): Promise<Map<number, FlightTime>> {
  const nowSec = Math.floor(nowMs / 1000);
  const found = new Map<number, FlightTime>();
  const byId = new Map(flying.map((member) => [member.id, member]));

  const sharers: Sharer[] = [];
  const revoked: number[] = [];
  const unmarked: string[] = [];
  try {
    const grants = await inTime(deps.readGrants([...byId.keys()]), deps.rtdbWaitMs);
    const docs = await deps.readDocs([...new Set(Object.values(grants).map((grant) => grant.doc))]);
    for (const [id, grant] of Object.entries(grants)) {
      const playerId = Number(id);
      if (!byId.has(playerId)) continue;
      const doc = docs[grant.doc];
      const hash = doc?.apiKey ? keyHash(doc.apiKey) : null;
      // Key changed since sharing began
      if (hash !== grant.keyHash) {
        revoked.push(playerId);
        if (doc) unmarked.push(grant.doc);
        continue;
      }
      if (doc.active === true) sharers.push({ ...doc, playerId, apiKey: doc.apiKey!, keyHash: hash });
    }
  } catch (e: any) {
    deps.warn(`flights: sharers unreadable: ${e?.code} ${e?.message}`);
    return found;
  }

  let saved: SavedFlights = { times: {}, failed: {} };
  if (sharers.length > 0) {
    try {
      saved = await inTime(deps.readSaved(factionId), deps.rtdbWaitMs);
    } catch (e: any) {
      deps.warn(`flights: saved times unreadable: ${e?.message}`);
    }
  }

  for (const sharer of sharers) {
    const time = sharerTime(sharer);
    if (validTime(time, byId.get(sharer.playerId)!.to, nowSec)) pickTime(found, sharer.playerId, time!);
  }

  const times: Record<string, FlightTime | null> = {};
  const failed: Record<string, number | null> = {};
  for (const [id, time] of Object.entries(saved.times ?? {})) {
    // Low ids can return an array
    if (!time) continue;
    if (time.arrival <= nowSec) {
      times[id] = null;
      continue;
    }
    const member = byId.get(Number(id));
    if (member && sharers.some((sharer) => sharer.playerId === member.id) && validTime(time, member.to, nowSec)) {
      pickTime(found, member.id, time);
    }
  }
  for (const [hash, until] of Object.entries(saved.failed ?? {})) {
    if (until <= nowMs) failed[hash] = null;
  }

  // Random, so dead keys don't block
  const toFetch = sharers
    .filter((sharer) => !found.get(sharer.playerId)?.departed && !(saved.failed?.[sharer.keyHash] > nowMs))
    .sort(() => Math.random() - 0.5)
    .slice(0, MAX_FOREIGN_KEYS);
  await Promise.all(
    toFetch.map(async (sharer) => {
      const read = await deps.readTravel(sharer.apiKey).catch((): undefined => undefined);
      // Torn down is not the key's fault
      if (read === undefined) return;
      if (read?.owner !== sharer.playerId) {
        failed[sharer.keyHash] = nowMs + FAILED_KEY_WAIT_MS;
        return;
      }
      if (!validTime(read.time, byId.get(sharer.playerId)!.to, nowSec)) return;
      pickTime(found, sharer.playerId, read.time!);
      times[String(sharer.playerId)] = read.time!;
    })
  );

  if (Object.keys(times).length > 0 || Object.keys(failed).length > 0 || revoked.length > 0) {
    await inTime(deps.writeSaved(factionId, times, failed, revoked), deps.rtdbWaitMs).catch((e: any) =>
      deps.warn(`flights: times not saved: ${e?.message}`)
    );
  }
  await Promise.all(
    unmarked.map((doc) => deps.markDoc(doc, false).catch((e: any) => deps.warn(`flights: mark failed: ${e?.code}`)))
  );
  return found;
}

export interface ShareDeps extends VerifyDeps {
  readPlayer(uid: string): Promise<{ playerId?: unknown; apiKey?: string } | null>;
  // Null when Torn doesn't confirm it
  keyOwner(apiKey: string): Promise<number | null>;
  readGrant(playerId: number): Promise<Grant | null>;
  writeGrant(playerId: number, grant: Grant | null): Promise<void>;
}

export type ShareAnswer =
  | { status: "ok"; share: boolean }
  | { status: "no_player" | "no_login" | "not_owner" | "pending" | "limited" | "torn_error" | "unavailable" };

export type ShareReading = { share: boolean } | { status: "no_login" | "limited" | "torn_error" | "unavailable" };

async function shareTurn(turn: string, everyMs: number, deps: ShareDeps): Promise<"limited" | "unavailable" | null> {
  const wait = await takeTurn(turn, deps.nowMs(), everyMs, deps);
  return wait === "unavailable" ? wait : wait > 0 ? "limited" : null;
}

function refusedToken(verified: Exclude<Verification, Verified>) {
  return verified === "invalid" ? "no_login" : "torn_error";
}

export async function setFlightSharing(uid: string, share: boolean, apiToken: unknown, deps: ShareDeps): Promise<ShareAnswer> {
  const refused = await shareTurn(`share_${uid}`, SHARE_EVERY_MS, deps);
  if (refused) return { status: refused };
  const player = await deps.readPlayer(uid);
  if (!player) return { status: "no_player" };
  const verified = usableToken(apiToken) ? await deps.verify(apiToken) : "invalid";

  if (share) {
    if (typeof verified !== "object") return { status: refusedToken(verified) };
    // Each try calls Torn with that key
    const tooSoon = await shareTurn(`sharePlayer_${verified.playerId}`, SHARE_PLAYER_EVERY_MS, deps);
    if (tooSoon) return { status: tooSoon };
    if (!player.apiKey || (await deps.keyOwner(player.apiKey)) !== verified.playerId) return { status: "not_owner" };
    const old = await inTime(deps.readGrant(verified.playerId), deps.rtdbWaitMs);
    await inTime(deps.writeGrant(verified.playerId, { doc: uid, keyHash: keyHash(player.apiKey) }), deps.rtdbWaitMs);
    if (old && old.doc !== uid) await deps.markDoc(old.doc, false).catch((e: any) => deps.warn(`flights: mark failed: ${e?.code}`));
    await deps.markDoc(uid, true);
    return { status: "ok", share: true };
  }

  // Without a token, only this document's own
  const proven = typeof verified === "object";
  const playerId = proven ? verified.playerId : wholeId(player.playerId);
  let ownGrant = false;
  if (playerId) {
    const grant = await inTime(deps.readGrant(playerId), deps.rtdbWaitMs);
    ownGrant = grant?.doc === uid;
    if (grant && (proven || ownGrant)) {
      await inTime(deps.writeGrant(playerId, null), deps.rtdbWaitMs);
      await deps.markDoc(grant.doc, false).catch((e: any) => deps.warn(`flights: mark failed: ${e?.code}`));
    }
  }
  return proven || ownGrant ? { status: "ok", share: false } : { status: "pending" };
}

export async function readFlightSharing(uid: string, apiToken: unknown, deps: ShareDeps): Promise<ShareReading> {
  const refused = await shareTurn(`shareRead_${uid}`, SHARE_EVERY_MS, deps);
  if (refused) return { status: refused };
  const player = await deps.readPlayer(uid);
  if (!player) return { share: false };

  const hinted = wholeId(player.playerId);
  if (hinted && (await inTime(deps.readGrant(hinted), deps.rtdbWaitMs))?.doc === uid) return { share: true };

  const verified = usableToken(apiToken) ? await deps.verify(apiToken) : "invalid";
  if (typeof verified !== "object") return { status: refusedToken(verified) };
  const tooSoon = await shareTurn(`shareReadPlayer_${verified.playerId}`, SHARE_EVERY_MS, deps);
  if (tooSoon) return { status: tooSoon };
  return { share: (await inTime(deps.readGrant(verified.playerId), deps.rtdbWaitMs)) !== null };
}

// Alerts pass, one write per flight
export function logSharedFlight(userStats: any, subscriber: any): { firestoreUpdate?: Record<string, any> } {
  if (subscriber.shareFlights !== true) return {};
  const travel = userStats?.travel;
  if (!(travel?.time_left > 0) || travel.timestamp === subscriber.flightArrival) return {};
  return {
    firestoreUpdate: {
      flightArrival: travel.timestamp,
      flightDestination: travel.destination,
      flightDeparted: travel.departed,
    },
  };
}
