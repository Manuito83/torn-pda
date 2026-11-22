import { createHash } from "crypto";
import { gzipSync } from "zlib";
import { RECENT_WINDOW, WAR_MAX_SECONDS } from "./compare";
import { MapState, POINT_ID, Price, Racket, Sample, Source, War } from "./types";

export const FORMAT = 1;
export const REVISION = 2;
export const STATE_CACHE = "public, max-age=60, must-revalidate";
export const HEARTBEAT_CACHE = "no-store";
export const TODAY_CACHE = "public, max-age=60";
export const OPEN_WAR_CACHE = "public, max-age=300";
export const YEAR_CACHE = "public, max-age=3600";
export const FOREVER_CACHE = "public, max-age=31536000, immutable";
export const GZIP = "application/gzip";
const READ_SOURCES: Source[] = ["ownership", "wars", "rackets", "bombs", "factions"];
const BOMB_WINDOW = 7 * 86400;
const RATE_MIN_GAP = 300;

export function readAt(state: MapState): Partial<Record<Source, number>> {
  const out: Partial<Record<Source, number>> = {};
  for (const k of READ_SOURCES) if (state.read_at[k] !== undefined) out[k] = state.read_at[k];
  return out;
}

// Against a sample 5+ min older
export function warRate(war: War) {
  let last: Sample | null = null;
  for (const s of war.samples) {
    if (war.updated_at - s[0] >= RATE_MIN_GAP && (last === null || s[0] > last[0])) last = s;
  }
  if (last === null) return { aggressor: 0, defender: 0 };
  const minutes = (war.updated_at - last[0]) / 60;
  return {
    aggressor: Math.round((war.aggressor.score - last[1]) / minutes),
    defender: Math.round((war.defender.score - last[4]) / minutes),
  };
}

// No attackers since, and score unchanged since
export function warIdle(war: War) {
  const samples = [...war.samples].sort((a, b) => a[0] - b[0]);
  let changedAt = war.start;
  let score = 0;
  const firstScore = samples.length ? samples[0][1] : war.aggressor.score;
  // with points there were attackers before
  let noAttackers: number | null = firstScore ? null : war.start;
  for (const s of samples) {
    if (s[1] !== score) {
      changedAt = s[0];
      score = s[1];
    }
    if (s[2]) noAttackers = null;
    else if (noAttackers === null) noAttackers = s[0];
  }
  if (war.aggressor.score !== score) changedAt = war.updated_at;
  if (war.aggressor.wall) noAttackers = null;
  else if (noAttackers === null) noAttackers = war.updated_at;
  return { no_attackers_since: noAttackers, score_changed_at: changedAt };
}

export function scheduledEnd(war: War): number {
  return war.scheduled_end || war.start + WAR_MAX_SECONDS;
}

// Without a stored price, null
export function rewardItem(racket: Racket, prices: Record<string, Price>) {
  const reward = racket.reward;
  const quantity = reward?.quantity;
  if (!reward || typeof quantity !== "number" || !Number.isInteger(quantity) || quantity <= 0) return null;
  if (reward.type === "Money") {
    return { type: "money", id: 0, name: "Money", quantity, price: 1, priced_at: null };
  }
  const id = reward.type === "Item" ? reward.id : reward.type === "Points" ? POINT_ID : undefined;
  if (id === undefined) return null;
  const row = prices[`${reward.type}:${id}`];
  if (!row || !row.name) return null;
  return { type: reward.type.toLowerCase(), id, name: row.name, quantity, price: row.price, priced_at: row.day };
}

function sideOut(war: War, key: "aggressor" | "defender") {
  const s = war[key];
  return { id: s.id, score: s.score, chain: s.chain, wall: s.wall };
}

function sortedEntries<T>(record: Record<string, T>): Array<[string, T]> {
  return Object.entries(record).sort(([a], [b]) => (a < b ? -1 : a > b ? 1 : 0));
}

export function buildState(state: MapState, now: number) {
  const ownership = Object.fromEntries(sortedEntries(state.ownership));
  const all = Object.entries(state.wars).map(([id, w]) => ({ id: Number(id), w }));
  const wars = all
    .filter(({ w }) => w.result === "in_progress")
    .sort((a, b) => a.id - b.id)
    .map(({ id, w }) => ({
      id, territory: w.territory, start: w.start, scheduled_end: scheduledEnd(w), target: w.target ?? 0,
      aggressor: sideOut(w, "aggressor"), defender: sideOut(w, "defender"), score_at: w.updated_at,
      rate: warRate(w), idle: warIdle(w),
    }));
  const recent = all
    .filter(({ w }) => w.result !== "in_progress" && w.ended_at !== null && w.ended_at >= now - RECENT_WINDOW)
    .sort((a, b) => (b.w.ended_at as number) - (a.w.ended_at as number) || b.id - a.id)
    .map(({ id, w }) => ({
      id, territory: w.territory, start: w.start, ended_at: w.ended_at as number, result: w.result,
      aggressor: w.aggressor.id, defender: w.defender.id, score: w.aggressor.score, target: w.target ?? 0,
    }));
  const rackets = Object.fromEntries(sortedEntries(state.rackets).map(([code, r]) => [code, {
    faction_id: r.faction_id, name: r.name, level: r.level, reward: r.description, changed_at: r.changed_at,
    reward_item: rewardItem(r, state.prices),
  }]));
  const ids = new Set<number>();
  for (const o of Object.values(ownership)) ids.add(o[0]);
  for (const r of Object.values(state.rackets)) ids.add(r.faction_id);
  for (const w of wars) ids.add(w.aggressor.id).add(w.defender.id);
  for (const w of recent) ids.add(w.aggressor).add(w.defender);
  ids.delete(0);
  return {
    format: FORMAT, revision: REVISION, generated_at: now, territories_version: state.territories_version,
    read_at: readAt(state), ownership, wars, recent_wars: recent, rackets,
    factions: factionsOut(state, ids), bombs: bombsOut(state, now),
  };
}

export function warNames(state: MapState): Map<number, string | null> {
  const names = new Map<number, string | null>();
  for (const w of Object.values(state.wars)) {
    for (const s of [w.aggressor, w.defender]) if (!names.has(s.id)) names.set(s.id, s.name);
  }
  return names;
}

// Without a snapshot row, the war's name
function factionsOut(state: MapState, ids: Set<number>) {
  const names = warNames(state);
  const out: Record<string, unknown> = {};
  for (const id of [...ids].sort((a, b) => a - b)) {
    out[String(id)] = state.factions[String(id)] ?? {
      name: names.get(id) ?? null, tag: null, tag_image: null, respect: null, rank: null, members: null,
    };
  }
  return out;
}

function bombsOut(state: MapState, now: number) {
  return state.bombs
    .filter((b) => b.detonated_at !== null && b.detonated_at > now - BOMB_WINDOW)
    .sort((a, b) => (b.detonated_at as number) - (a.detonated_at as number) || b.id - a.id)
    .map((b) => ({
      id: b.id, detonated_at: b.detonated_at, faction_id: b.faction_id, respect_lost: b.respect_lost,
      territories: [...new Set((state.bomb_territories[String(b.id)] ?? []).map(([code]) => code))].sort(),
    }));
}

export function buildHeartbeat(state: MapState, now: number) {
  return { format: FORMAT, source: "function", at: now, read_at: readAt(state) };
}

// Without generated_at, which always changes
export function digest(doc: Record<string, unknown>, cacheControl: string): string {
  const rest = Object.fromEntries(Object.entries(doc).filter(([k]) => k !== "generated_at"));
  return createHash("sha256").update(cacheControl + JSON.stringify(rest)).digest("hex");
}

export function encodeGzip(doc: unknown): Buffer {
  return gzipSync(Buffer.from(JSON.stringify(doc)), { level: 9 });
}
