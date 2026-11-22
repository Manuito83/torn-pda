import {
  Bomb, Faction, Owner, Racket, Sample, TornBomb, TornOwnership, TornRacket, TornWar, TornWarSide, War, WarSide,
} from "./types";

export const WAR_MAX_SECONDS = 72 * 3600;
export const RECENT_WINDOW = 72 * 3600 + 600;
export const SAMPLE_EVERY = 600;
const COMPLETE_SHARE = 0.9;
const BOMB_AFTER = 15 * 60;
const BOMB_BEFORE = 2 * 60;

export type OwnershipKind = "added" | "owner" | "reacquired" | "irradiated" | "removed";

export interface OwnershipChange {
  territory: string;
  kind: OwnershipKind;
  faction_id: number;
  previous_faction_id: number | null;
  irradiated: number;
}

export interface WarEvent {
  war_id: number;
  kind: "start" | "end" | "reopen" | "result";
  result: string;
}

export interface RacketChange {
  territory: string;
  kind: "new" | "owner" | "level" | "removed";
  faction_id: number;
  previous_faction_id: number | null;
  level: number;
  previous_level: number | null;
  name: string;
}

// Owners

export function ownerRow(api: TornOwnership): Owner {
  return [api.owned_by ?? 0, api.acquired_at ?? 0, api.irradiated ? 1 : 0];
}

export function ownershipChanges(known: Record<string, Owner>, page: TornOwnership[], baseline: boolean) {
  const changes: OwnershipChange[] = [];
  const rows: Record<string, Owner> = {};
  for (const item of page) {
    const row = ownerRow(item);
    rows[item.id] = row;
    if (baseline) continue;
    const old = known[item.id];
    const base = { territory: item.id, faction_id: row[0], irradiated: row[2] };
    if (old === undefined) {
      changes.push({ ...base, kind: "added", previous_faction_id: null });
      continue;
    }
    let kind: OwnershipKind;
    if (old[0] !== row[0]) kind = "owner";
    else if (old[1] !== row[1]) kind = "reacquired";
    else if (old[2] !== row[2]) kind = "irradiated";
    else continue;
    changes.push({ ...base, kind, previous_faction_id: old[0] });
  }
  return { changes, rows };
}

// A list under 90 % removes nothing
export function isComplete(seen: number, known: number): boolean {
  return seen >= COMPLETE_SHARE * known;
}

export function ownershipRemoved(known: Record<string, Owner>, seen: Set<string>): OwnershipChange[] {
  return Object.keys(known)
    .filter((code) => !seen.has(code))
    .map((code) => ({
      territory: code, kind: "removed" as const, faction_id: 0, previous_faction_id: known[code][0],
      irradiated: known[code][2],
    }));
}

// Territories turned irradiated
export function irradiationsFrom(changes: OwnershipChange[], at: number): Array<[string, number]> {
  return changes
    .filter((c) => c.irradiated === 1 && (c.kind === "irradiated" || c.kind === "added" ||
      (c.kind === "owner" && c.previous_faction_id !== 0)))
    .map((c) => [c.territory, at]);
}

// Assaults

function side(api: TornWarSide | null | undefined, old: WarSide | undefined): WarSide {
  const a = api ?? {};
  return {
    id: a.id ?? old?.id ?? 0,
    name: a.name ?? old?.name ?? null,
    score: a.score ?? old?.score ?? 0,
    chain: a.chain ?? old?.chain ?? 0,
    wall: (a.players_on_wall ?? []).length,
  };
}

export function warRow(api: TornWar, old: War | undefined, now: number): War {
  return {
    territory: api.territory,
    start: api.start,
    scheduled_end: api.end ?? null,
    target: api.target ?? null,
    aggressor: side(api.aggressor, old?.aggressor),
    defender: side(api.defender, old?.defender),
    result: api.result || "unknown",
    ended_at: null,
    updated_at: now,
    ending_sent: old?.ending_sent ?? false,
    samples: old?.samples ?? [],
  };
}

// coveredFrom: oldest start the read covers
export function warChanges(known: Record<string, War>, wars: TornWar[], coveredFrom: number, baseline: boolean,
  now: number) {
  const rows: Record<string, War> = {};
  const events: WarEvent[] = [];
  const seen = new Set<string>();
  for (const api of wars) {
    const id = String(api.id);
    const old = known[id];
    const row = warRow(api, old, now);
    const inProgress = row.result === "in_progress";
    seen.add(id);
    if (old?.result === "in_progress") {
      if (!inProgress) {
        row.ended_at = now;
        events.push({ war_id: api.id, kind: "end", result: row.result });
      }
      rows[id] = row;
    } else if (old?.result === "unknown") {
      if (row.result === "unknown") continue;
      row.ended_at = inProgress ? null : old.ended_at;
      rows[id] = row;
      events.push({ war_id: api.id, kind: inProgress ? "reopen" : "result", result: row.result });
    } else if (old === undefined && inProgress) {
      // already over when first seen: not kept
      rows[id] = row;
      if (!baseline) events.push({ war_id: api.id, kind: "start", result: "in_progress" });
    }
  }
  for (const [id, old] of Object.entries(known)) {
    if (old.result !== "in_progress" || seen.has(id)) continue;
    if (old.start >= coveredFrom || old.start + WAR_MAX_SECONDS < now) {
      rows[id] = { ...old, result: "unknown", ended_at: now };
      events.push({ war_id: Number(id), kind: "end", result: "unknown" });
    }
  }
  return { rows, events };
}

// Every 10 min, only if changed
export function takeSample(war: War, now: number): Sample | null {
  if (war.result !== "in_progress") return null;
  const sample: Sample = [now, war.aggressor.score, war.aggressor.wall, war.defender.wall, war.defender.score];
  const last = war.samples[war.samples.length - 1];
  if (last && (now - last[0] < SAMPLE_EVERY || sample.slice(1).every((v, i) => v === last[i + 1]))) return null;
  return sample;
}

// Active or recently over
export function keepWar(war: War, now: number): boolean {
  if (war.result === "in_progress") return true;
  return war.ended_at !== null && war.ended_at >= now - RECENT_WINDOW;
}

// Rackets

export function racketRow(api: TornRacket): Racket {
  return {
    faction_id: api.faction_id ?? 0,
    name: api.name ?? "",
    level: api.level ?? 0,
    description: api.description ?? "",
    reward: api.reward ?? null,
    changed_at: api.changed_at ?? 0,
  };
}

export function racketChanges(known: Record<string, Racket>, rackets: TornRacket[]) {
  const rows: Record<string, Racket> = {};
  for (const r of rackets) rows[r.territory] = racketRow(r);
  const changes: RacketChange[] = [];
  if (Object.keys(known).length === 0) return { changes, rows };
  for (const [code, row] of Object.entries(rows)) {
    const old = known[code];
    let kind: RacketChange["kind"];
    if (old === undefined) kind = "new";
    else if (old.faction_id !== row.faction_id) kind = "owner";
    else if (old.level !== row.level || old.name !== row.name) kind = "level";
    else continue;
    changes.push({
      territory: code, kind, faction_id: row.faction_id, previous_faction_id: old?.faction_id ?? null,
      level: row.level, previous_level: old?.level ?? null, name: row.name,
    });
  }
  if (!isComplete(Object.keys(rows).length, Object.keys(known).length)) return { changes, rows };
  for (const [code, old] of Object.entries(known)) {
    if (rows[code]) continue;
    changes.push({
      territory: code, kind: "removed", faction_id: 0, previous_faction_id: old.faction_id, level: 0,
      previous_level: old.level, name: old.name,
    });
  }
  return { changes, rows };
}

// Dirty bombs

// Empty fields keep what was stored
export function mergeBombs(known: Bomb[], api: TornBomb[], since: number, now: number): Bomb[] {
  const old = new Map(known.map((b) => [b.id, b]));
  const out: Bomb[] = [];
  for (const item of api) {
    const prev = old.get(item.id);
    const bomb: Bomb = {
      id: item.id,
      detonated_at: item.detonated_at ?? prev?.detonated_at ?? null,
      faction_id: item.faction?.id ?? prev?.faction_id ?? 0,
      respect_lost: item.faction?.respect_lost ?? prev?.respect_lost ?? 0,
      first_seen_at: prev?.first_seen_at ?? now,
    };
    if (bomb.detonated_at !== null && bomb.detonated_at > since) out.push(bomb);
  }
  return out;
}

// Bombs recent by detonation or first read
export function recentDetonations(bombs: Bomb[], since: number): Map<number, number> {
  const out = new Map<number, number>();
  for (const b of bombs) {
    if (b.detonated_at !== null && (b.detonated_at >= since || b.first_seen_at >= since)) out.set(b.id, b.detonated_at);
  }
  return out;
}

// Each irradiation to nearest bomb
export function matchIrradiations(detonations: Map<number, number>, irradiations: Array<[string, number]>) {
  const links: Array<[number, string, number]> = [];
  for (const [code, at] of irradiations) {
    let best: [number, number] | null = null;
    for (const [id, det] of detonations) {
      if (at < det - BOMB_BEFORE || at > det + BOMB_AFTER) continue;
      const near: [number, number] = [Math.abs(at - det), id];
      if (best === null || near[0] < best[0] || (near[0] === best[0] && near[1] < best[1])) best = near;
    }
    if (best) links.push([best[1], code, at]);
  }
  return links;
}

// A closer bomb takes over a link
export function linkBombTerritories(current: Record<string, Array<[string, number]>>,
  links: Array<[number, string, number]>, bombs: Bomb[]) {
  const detonated = new Map(bombs.map((b) => [b.id, b.detonated_at ?? 0]));
  const byPlace = new Map<string, [number, string, number]>();
  for (const [id, list] of Object.entries(current)) {
    for (const [code, at] of list) byPlace.set(`${code}:${at}`, [Number(id), code, at]);
  }
  for (const link of links) {
    const key = `${link[1]}:${link[2]}`;
    const old = byPlace.get(key);
    const distance = (l: [number, string, number]) => Math.abs(l[2] - (detonated.get(l[0]) ?? Infinity));
    if (!old || distance(link) < distance(old)) byPlace.set(key, link);
  }
  const out: Record<string, Array<[string, number]>> = {};
  for (const [id, code, at] of byPlace.values()) {
    if (!detonated.has(id)) continue;
    (out[String(id)] ??= []).push([code, at]);
  }
  return out;
}

// Faction snapshot (CSV with quotes)

export function parseCsv(text: string): string[][] {
  const rows: string[][] = [];
  let row: string[] = [];
  let field = "";
  let quoted = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (quoted) {
      if (c !== '"') field += c;
      else if (text[i + 1] === '"') { field += '"'; i++; }
      else quoted = false;
    } else if (c === '"') quoted = true;
    else if (c === ",") { row.push(field); field = ""; }
    else if (c === "\n" || c === "\r") {
      if (c === "\r" && text[i + 1] === "\n") i++;
      row.push(field);
      rows.push(row);
      row = [];
      field = "";
    } else field += c;
  }
  if (field !== "" || row.length > 0) { row.push(field); rows.push(row); }
  return rows;
}

function intOrNull(text: string | undefined): number | null {
  const t = (text ?? "").trim();
  return t === "" ? null : parseInt(t, 10);
}

export function parseFactionCsv(text: string): Record<string, Faction> {
  const [header, ...rows] = parseCsv(text);
  const col = new Map((header ?? []).map((name, i) => [name, i]));
  const get = (r: string[], name: string) => r[col.get(name) ?? -1];
  const out: Record<string, Faction> = {};
  for (const r of rows) {
    const id = intOrNull(get(r, "id"));
    if (id === null) continue;
    out[String(id)] = {
      name: get(r, "name") ?? null,
      tag: get(r, "tag") || null,
      tag_image: get(r, "tag_image") || null,
      respect: intOrNull(get(r, "respect")),
      rank: intOrNull(get(r, "rank")),
      members: intOrNull(get(r, "members")),
    };
  }
  return out;
}
