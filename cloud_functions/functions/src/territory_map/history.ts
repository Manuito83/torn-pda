import { keepWar } from "./compare";
import { LOG_MAX_DAYS, NameTag, pendingDay } from "./day_changes";
import { FOREVER_CACHE, FORMAT, YEAR_CACHE } from "./exports";
import { ChangeLog, ChangeRow, DAY, MapState, War, utcDay } from "./types";
import { hasReport } from "./war_files";

// [id, territory, start, ended_at, result, aggressor, defender, score, target, has_report]
export type HistoryWar = [number, string, number, number | null, string, number, number, number, number, number];

export interface HistoryDoc {
  format: number;
  year: number;
  generated_at: number;
  complete_from: number;
  // last UTC day in the file
  through: string;
  wars: HistoryWar[];
  owners: unknown[][];
  rackets: unknown[][];
  bombs: unknown[][];
  factions: Record<string, NameTag>;
}

export interface DatedWar {
  row: HistoryWar;
  // counted by end, else start
  day: string;
}

export function historyKey(year: number | string): string {
  return `history/${year}.json.gz`;
}

export function yearOf(day: string): number {
  return Number(day.slice(0, 4));
}

export function emptyHistory(year: number, completeFrom: number): HistoryDoc {
  return {
    format: FORMAT, year, generated_at: completeFrom, complete_from: completeFrom, through: "", wars: [], owners: [],
    rackets: [], bombs: [], factions: {},
  };
}

export function historyCache(through: string): string {
  return through.endsWith("-12-31") ? FOREVER_CACHE : YEAR_CACHE;
}

// Day rows, plus wars ended by then
export function addDay(doc: HistoryDoc, day: string, rows: ChangeRow[], wars: DatedWar[],
  names: (id: number) => NameTag, now: number): HistoryDoc {
  const ids = new Set<number>();
  const cite = (...list: Array<number | null>) => list.forEach((id) => id && ids.add(id));
  const owners = [...doc.owners];
  const rackets = [...doc.rackets];
  const bombs = new Map(doc.bombs.map((b) => [b[0] as number, b]));
  for (const r of rows) {
    const extra = (r[8] ?? {}) as Record<string, unknown>;
    if (r[1] === "ownership") {
      owners.push([r[0], r[2], r[3], r[4], r[5], r[6]]);
      cite(r[4], r[5]);
    } else if (r[1] === "racket") {
      rackets.push([r[0], r[2], r[3], r[4], extra.level ?? null, extra.previous_level ?? null, extra.name ?? null]);
      cite(r[4]);
    } else if (r[1] === "bomb" && r[3] === "new" && r[7] !== null) {
      bombs.set(r[7], [r[7], r[0], r[4] ?? 0, extra.respect_lost ?? 0, extra.territories ?? []]);
      cite(r[4]);
    }
  }
  const byId = new Map(doc.wars.map((w) => [w[0], w]));
  for (const w of wars) {
    if (w.day > day || yearOf(w.day) !== doc.year) continue;
    byId.set(w.row[0], w.row);
    cite(w.row[5], w.row[6]);
  }
  const factions = { ...doc.factions };
  for (const id of ids) {
    const found = names(id);
    if (found.name !== null || !factions[String(id)]) factions[String(id)] = found;
  }
  return {
    ...doc, generated_at: now, through: day, owners, rackets,
    wars: [...byId.values()].sort((a, b) => a[0] - b[0]),
    bombs: [...bombs.values()].sort((a, b) => (a[0] as number) - (b[0] as number)),
    factions: Object.fromEntries(Object.entries(factions).sort(([a], [b]) => Number(a) - Number(b))),
  };
}

// Ended wars the state still holds
export function stateWars(state: MapState): DatedWar[] {
  const out: DatedWar[] = [];
  for (const [id, w] of Object.entries(state.wars)) {
    if (w.result === "in_progress" || w.ended_at === null) continue;
    const r = state.reports[id];
    const reported = hasReport(r?.fetched_at ?? null, Boolean(r?.aggressor || r?.defender), w.ended_at);
    const row: HistoryWar = [Number(id), w.territory, w.start, w.ended_at, w.result, w.aggressor.id, w.defender.id,
      w.aggressor.score, w.target ?? 0, reported ? 1 : 0];
    out.push({ row, day: utcDay(w.ended_at) });
  }
  return out;
}

// Ended wars wait for their close
export function keepForHistory(log: ChangeLog, prefix: string, war: War, now: number): boolean {
  if (keepWar(war, now)) return true;
  return war.ended_at !== null && war.ended_at >= now - LOG_MAX_DAYS * DAY &&
    pendingDay(log, prefix, utcDay(war.ended_at));
}
