import { OwnershipChange, RacketChange, WarEvent } from "./compare";
import { FORMAT, REVISION, warNames } from "./exports";
import { Bomb, ChangeLog, ChangeRow, DAY, MapState, Source, War, dayStart, nextDay, utcDay } from "./types";

// a late bomb still changes the day
export const CLOSE_AFTER = 3 * 3600;
export const CHANGES_EVERY = 8 * 60;
export const LOG_DAYS = 7;
export const LOG_MAX_DAYS = 21;
const CONQUEST_BEFORE = 15 * 60;
const CONQUEST_AFTER = 5 * 60;

export interface EndedWar {
  id: number;
  territory: string;
  result: string;
  ended_at: number;
}

export interface RowContext {
  wars: EndedWar[];
  // bomb id -> [territory, at]
  bombTerritories: Record<string, Array<[string, number]>>;
  respectLost: Map<number, number>;
}

export type NameTag = { name: string | null; tag: string | null };

// No faction is null, never 0
function idOrNull(id: number | null | undefined): number | null {
  return id ? id : null;
}

export function ownershipRows(changes: OwnershipChange[], now: number): ChangeRow[] {
  return changes.map((c): ChangeRow => [now, "ownership", c.territory, c.kind, idOrNull(c.faction_id),
    idOrNull(c.previous_faction_id), null, null, null]);
}

export function warRows(events: WarEvent[], wars: Record<string, War>, now: number): ChangeRow[] {
  const rows: ChangeRow[] = [];
  for (const e of events) {
    const w = wars[String(e.war_id)];
    if (!w) continue;
    const extra = e.kind === "end" ? { score: w.aggressor.score, target: w.target ?? 0 } : null;
    rows.push([now, "war", w.territory, `${e.kind}:${e.result}`, idOrNull(w.aggressor.id), idOrNull(w.defender.id),
      e.war_id, null, extra]);
  }
  return rows;
}

export function racketRows(changes: RacketChange[], now: number): ChangeRow[] {
  return changes.map((c): ChangeRow => [now, "racket", c.territory, c.kind, idOrNull(c.faction_id),
    idOrNull(c.previous_faction_id), null, null,
    { level: c.kind === "removed" ? null : c.level, previous_level: c.previous_level, name: c.name }]);
}

// Dated at detonation
export function bombRows(bombs: Bomb[], now: number): ChangeRow[] {
  return bombs.map((b): ChangeRow => [b.detonated_at ?? now, "bomb", null, "new", idOrNull(b.faction_id), null,
    null, b.id, null]);
}

export function addRows(log: ChangeLog, rows: ChangeRow[]) {
  for (const row of rows) (log.days[utcDay(row[0])] ??= []).push(row);
}

// First full day after the first read
export function firstFullDay(since: number): string {
  const day = utcDay(since);
  return since === dayStart(day) ? day : nextDay(day);
}

// Still to close under this prefix
export function pendingDay(log: ChangeLog, prefix: string, day: string): boolean {
  return day >= firstFullDay(log.since) && day > (log.closed[prefix] ?? "");
}

// Closed days 7 days, open ones 21
export function pruneLog(log: ChangeLog, prefix: string, now: number): string[] {
  const oldest = utcDay(now - LOG_DAYS * DAY);
  const limit = utcDay(now - LOG_MAX_DAYS * DAY);
  const dropped: string[] = [];
  for (const day of Object.keys(log.days)) {
    const pending = pendingDay(log, prefix, day);
    if (day >= oldest || (pending && day >= limit)) continue;
    if (pending) dropped.push(day);
    delete log.days[day];
  }
  log.dropped = [...new Set([...(log.dropped ?? []), ...dropped])].sort();
  return dropped;
}

// Today and, early on, yesterday
export function openDays(now: number): string[] {
  return [...new Set([utcDay(now - CLOSE_AFTER), utcDay(now)])];
}

// Waits for fresh bombs and owners too
export function lastClosableDay(readAt: Partial<Record<Source, number>>, now: number): string {
  return utcDay(Math.min(now, readAt.bombs ?? 0, readAt.ownership ?? 0) - CLOSE_AFTER - DAY);
}

// Success there, 15 min before, 5 after
export function conquestWarId(at: number, territory: string, wars: EndedWar[]): number | null {
  let best: EndedWar | null = null;
  for (const w of wars) {
    if (w.territory !== territory || w.result !== "success_assault") continue;
    if (w.ended_at < at - CONQUEST_BEFORE || w.ended_at > at + CONQUEST_AFTER) continue;
    const gap = Math.abs(w.ended_at - at);
    if (!best || gap < Math.abs(best.ended_at - at) || (gap === Math.abs(best.ended_at - at) && w.id > best.id)) {
      best = w;
    }
  }
  return best ? best.id : null;
}

function compareCells(a: unknown, b: unknown): number {
  if (a === b) return 0;
  if (a === null || a === undefined) return -1;
  if (b === null || b === undefined) return 1;
  return (a as number | string) < (b as number | string) ? -1 : 1;
}

// at, source, territory, kind, war_id, bomb_id
export function sortRows(rows: ChangeRow[]): ChangeRow[] {
  const order = [0, 1, 2, 3, 6, 7];
  return [...rows].sort((a, b) => {
    for (const i of order) {
      const c = compareCells(a[i], b[i]);
      if (c) return c;
    }
    return 0;
  });
}

// Conquests, bomb links and bomb extras
export function finishRows(rows: ChangeRow[], ctx: RowContext): ChangeRow[] {
  const bombAt = new Map<string, number>();
  for (const [id, list] of Object.entries(ctx.bombTerritories)) {
    for (const [code, at] of list) bombAt.set(`${code}:${at}`, Number(id));
  }
  return sortRows(rows.map((r) => {
    const row = [...r] as ChangeRow;
    if (row[1] === "ownership" && row[2]) {
      row[6] = row[3] === "owner" ? conquestWarId(row[0], row[2], ctx.wars) : null;
      row[7] = bombAt.get(`${row[2]}:${row[0]}`) ?? null;
    } else if (row[1] === "bomb" && row[7] !== null) {
      const territories = (ctx.bombTerritories[String(row[7])] ?? []).map(([code]) => code);
      row[8] = { respect_lost: ctx.respectLost.get(row[7]) ?? 0, territories: [...new Set(territories)].sort() };
    }
    return row;
  }));
}

export function rowFactionIds(rows: ChangeRow[]): number[] {
  const ids = new Set<number>();
  for (const r of rows) for (const id of [r[4], r[5]]) if (id) ids.add(id);
  return [...ids].sort((a, b) => a - b);
}

export function buildDayChanges(day: string, rows: ChangeRow[], names: (id: number) => NameTag, now: number) {
  const factions: Record<string, NameTag> = {};
  for (const id of rowFactionIds(rows)) factions[String(id)] = names(id);
  return { format: FORMAT, revision: REVISION, day, generated_at: now, factions, changes: rows };
}

export function rowContext(state: MapState): RowContext {
  const wars: EndedWar[] = [];
  for (const [id, w] of Object.entries(state.wars)) {
    if (w.result !== "in_progress" && w.ended_at !== null) {
      wars.push({ id: Number(id), territory: w.territory, result: w.result, ended_at: w.ended_at });
    }
  }
  return {
    wars,
    bombTerritories: state.bomb_territories,
    respectLost: new Map(state.bombs.map((b) => [b.id, b.respect_lost])),
  };
}

// Snapshot name, else the war's
export function factionNames(state: MapState): (id: number) => NameTag {
  const fromWars = warNames(state);
  return (id) => {
    const f = state.factions[String(id)];
    return f ? { name: f.name, tag: f.tag } : { name: fromWars.get(id) ?? null, tag: null };
  };
}

export function dayChangesFor(state: MapState, day: string, now: number) {
  const rows = finishRows(state.log.days[day] ?? [], rowContext(state));
  return buildDayChanges(day, rows, factionNames(state), now);
}
