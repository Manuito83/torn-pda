import { keepWar } from "./compare";
import { FORMAT, scheduledEnd } from "./exports";
import { MapState, Published, Report, ReportSide, TornReport, War } from "./types";

export const NOT_READY = 6;
export const REPORTS_PER_TICK = 2;
export const WAR_FILES_PER_TICK = 20;
const LIVE_RETRIES = [60, 120, 300, 600, 1800, 3600, 3 * 3600, 12 * 3600];
const CLOSE_AFTER = 86400;
const REWRITE_EVERY = 600;

export function warKey(id: number | string): string {
  return `wars/${id}.json.gz`;
}

// Seen ending again: attempts start over
export function queueReports(reports: Record<string, Report>, ids: number[], now: number) {
  for (const id of ids) {
    const old = reports[String(id)];
    if (old?.fetched_at) continue;
    reports[String(id)] = {
      attempts: 0, next_try_at: now, fetched_at: null, ended_at: null, winner: null, aggressor: null, defender: null,
    };
  }
}

export function dueReports(reports: Record<string, Report>, now: number, n: number): string[] {
  return Object.entries(reports)
    .filter(([, r]) => r.fetched_at === null && r.next_try_at !== null && r.next_try_at <= now)
    .sort(([a, ra], [b, rb]) => (ra.next_try_at as number) - (rb.next_try_at as number) || Number(b) - Number(a))
    .slice(0, n)
    .map(([id]) => id);
}

// Null when no retries are left
export function nextTry(attempts: number, now: number): number | null {
  return attempts <= LIVE_RETRIES.length ? now + LIVE_RETRIES[attempts - 1] : null;
}

function sideFrom(f: { score?: number | null; joins?: number | null; clears?: number | null } | undefined) {
  return { score: f?.score ?? 0, joins: f?.joins ?? 0, clears: f?.clears ?? 0 };
}

// Per faction, no members
export function reportFrom(api: TornReport, now: number, attempts: number): Report {
  if (!api || typeof api !== "object") throw new TypeError("report without body");
  const factions = api.factions ?? [];
  if (!Array.isArray(factions)) throw new TypeError("report factions not a list");
  const aggressor = factions.find((f) => f.is_aggressor);
  const defender = factions.find((f) => !f.is_aggressor);
  return {
    attempts, next_try_at: null, fetched_at: now, ended_at: api.ended_at ?? null, winner: api.winner || null,
    aggressor: aggressor ? sideFrom(aggressor) : null, defender: defender ? sideFrom(defender) : null,
  };
}

export function reportMissed(old: Report, now: number): Report {
  const attempts = old.attempts + 1;
  return { ...old, attempts, next_try_at: nextTry(attempts, now) };
}

// One rule: war file, year, seed
export function hasReport(fetchedAt: number | null, hasSides: boolean, endedAt: number | null): boolean {
  return fetchedAt !== null && hasSides && endedAt !== null;
}

function reportOut(war: War, report: Report | undefined) {
  if (!report || !hasReport(report.fetched_at, Boolean(report.aggressor || report.defender), war.ended_at)) {
    return null;
  }
  const zero: ReportSide = { score: 0, joins: 0, clears: 0 };
  return {
    winner: report.winner, ended_at: war.ended_at, aggressor: report.aggressor ?? zero,
    defender: report.defender ?? zero,
  };
}

export function buildWarFile(state: MapState, id: string, now: number) {
  const w = state.wars[id];
  const open = w.result === "in_progress";
  return {
    format: FORMAT, generated_at: now,
    war: {
      id: Number(id), territory: w.territory, start: w.start, scheduled_end: scheduledEnd(w), target: w.target ?? 0,
      aggressor: w.aggressor.id, defender: w.defender.id, result: w.result, ended_at: open ? null : w.ended_at,
    },
    samples: w.samples.map((s) => [s[0], s[1], s[2], s[3]]),
    report: open ? null : reportOut(w, state.reports[id]),
  };
}

// Report, no retries left or 24 h
export function isClosed(war: War, report: Report | undefined, now: number): boolean {
  if (war.result === "in_progress") return false;
  const gaveUp = report !== undefined && report.fetched_at === null && report.next_try_at === null;
  const ended = war.ended_at ?? scheduledEnd(war);
  return Boolean(report?.fetched_at) || gaveUp || now - ended >= CLOSE_AFTER;
}

// Changed, and 10 min since last write
export function isDue(last: Published | undefined, digest: string, now: number): boolean {
  if (last?.digest === digest) return false;
  return !last || now - last.at >= REWRITE_EVERY;
}

// Not closed, in progress first, then newest
export function warFileCandidates(state: MapState, prefix: string, now: number): string[] {
  return Object.entries(state.wars)
    .filter(([id, w]) => keepWar(w, now) && !state.published[prefix + warKey(id)]?.closed)
    .sort(([a, wa], [b, wb]) => Number(wb.result === "in_progress") - Number(wa.result === "in_progress") ||
      Number(b) - Number(a))
    .map(([id]) => id);
}
