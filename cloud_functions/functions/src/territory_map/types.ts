// [faction_id, acquired_at, irradiated], 0 when unknown
export type Owner = [number, number, number];

// [at, scoreA, wallA, wallD, scoreD]
export type Sample = [number, number, number, number, number];

export const POINT_ID = 0;

export function utcDay(ts: number): string {
  return new Date(ts * 1000).toISOString().slice(0, 10);
}

export type Source = "ownership" | "wars" | "rackets" | "bombs" | "factions";
export type Task = Source | "prices" | "territories" | "reports" | "geometry" | "close" | "shapes";

export const DAY = 86400;

export function dayStart(day: string): number {
  return Date.parse(`${day}T00:00:00Z`) / 1000;
}

export function nextDay(day: string): string {
  return utcDay(dayStart(day) + DAY);
}

// [at, source, territory, kind, faction_id, previous_faction_id, war_id, bomb_id, extra]
export type ChangeRow = [number, string, string | null, string, number | null, number | null, number | null,
  number | null, Record<string, unknown> | null];

export interface ChangeLog {
  // first read, days before it are partial
  since: number;
  days: Record<string, ChangeRow[]>;
  changes_at: number;
  // prefix -> last day the history covers
  closed: Record<string, string>;
  // open days lost to the size limit
  dropped?: string[];
}

export interface ReportSide {
  score: number;
  joins: number;
  clears: number;
}

export interface Report {
  attempts: number;
  next_try_at: number | null;
  fetched_at: number | null;
  ended_at: number | null;
  winner: number | null;
  aggressor: ReportSide | null;
  defender: ReportSide | null;
}

export interface Geometry {
  sector: number | null;
  size: number | null;
  density: number | null;
  slots: number | null;
  respect: number | null;
  neighbors: string[];
}

export interface GeometryScan {
  version: number;
  offset: number;
  seen: string[];
  changed: Record<string, Geometry>;
  missing: string[];
  // read whole, waiting to publish
  done?: boolean;
}

export interface Published {
  digest: string;
  at: number;
  closed?: boolean;
}

export interface WarSide {
  id: number;
  name: string | null;
  score: number;
  chain: number;
  wall: number;
}

export interface War {
  territory: string;
  start: number;
  scheduled_end: number | null;
  target: number | null;
  aggressor: WarSide;
  defender: WarSide;
  result: string;
  ended_at: number | null;
  updated_at: number;
  ending_sent: boolean;
  samples: Sample[];
}

export interface Racket {
  faction_id: number;
  name: string;
  level: number;
  description: string;
  reward: TornReward | null;
  changed_at: number;
}

export interface Faction {
  name: string | null;
  tag: string | null;
  tag_image: string | null;
  respect: number | null;
  rank: number | null;
  members: number | null;
}

export interface Bomb {
  id: number;
  detonated_at: number | null;
  faction_id: number;
  respect_lost: number;
  first_seen_at: number;
}

export interface Price {
  name: string;
  price: number;
  day: string;
}

export interface MapState {
  ownership: Record<string, Owner>;
  read_at: Partial<Record<Source, number>>;
  wars: Record<string, War>;
  rackets: Record<string, Racket>;
  factions: Record<string, Faction>;
  factions_day: string;
  bombs: Bomb[];
  // bomb id -> [territory, at]
  bomb_territories: Record<string, Array<[string, number]>>;
  // [territory, at] of recent irradiations
  irradiations: Array<[string, number]>;
  prices: Record<string, Price>;
  prices_day: string;
  territories_version: number;
  territories_checked_day: string;
  due: Partial<Record<Task, number>>;
  failures: Partial<Record<Task, number>>;
  pause_until: number;
  calls: { day: string; n: number };
  slow_ticks: number[];
  published: Record<string, Published>;
  log: ChangeLog;
  reports: Record<string, Report>;
  geometry: GeometryScan | null;
}

export interface Control {
  enabled: boolean;
  publish_prefix: string;
  send_alerts: boolean;
  ownership_every_ticks: number;
  paused_until: number;
  off_reason: string;
  // one sample/ copy, then back to false
  sample: boolean;
  // close lost days empty, set by hand
  close_missing: boolean;
}

export interface SavedState {
  saved_at: number;
  state: MapState;
}

// Torn v2 rows, used fields only

export interface TornWallPlayer {
  id: number;
}

export interface TornWarSide {
  id?: number;
  name?: string;
  score?: number | null;
  chain?: number | null;
  players_on_wall?: TornWallPlayer[] | null;
}

export interface TornWar {
  id: number;
  territory: string;
  start: number;
  end?: number | null;
  target?: number | null;
  aggressor?: TornWarSide | null;
  defender?: TornWarSide | null;
  result?: string | null;
}

export interface TornOwnership {
  id: string;
  owned_by?: number | null;
  acquired_at?: number | null;
  irradiated?: boolean | null;
}

export interface TornReward {
  type?: string;
  quantity?: number;
  id?: number;
}

export interface TornRacket {
  territory: string;
  faction_id?: number | null;
  name?: string | null;
  level?: number | null;
  description?: string | null;
  reward?: TornReward | null;
  changed_at?: number | null;
}

export interface TornBomb {
  id: number;
  detonated_at?: number | null;
  faction?: { id?: number | null; respect_lost?: number | null } | null;
}

export interface TornItem {
  id: number;
  name?: string | null;
  value?: { market_price?: number | null } | null;
}

export interface TornReportFaction {
  id: number;
  is_aggressor?: boolean | null;
  score?: number | null;
  joins?: number | null;
  clears?: number | null;
}

export interface TornReport {
  ended_at?: number | null;
  winner?: number | null;
  factions?: TornReportFaction[] | null;
}

export interface TornTerritory {
  id: string;
  sector?: number | null;
  size?: number | null;
  density?: number | null;
  slots?: number | null;
  respect?: number | null;
  neighbors?: string[] | null;
}

export function emptyState(): MapState {
  return {
    ownership: {},
    read_at: {},
    wars: {},
    rackets: {},
    factions: {},
    factions_day: "",
    bombs: [],
    bomb_territories: {},
    irradiations: [],
    prices: {},
    prices_day: "",
    territories_version: 1,
    territories_checked_day: "",
    due: {},
    failures: {},
    pause_until: 0,
    calls: { day: "", n: 0 },
    slow_ticks: [],
    published: {},
    log: { since: 0, days: {}, changes_at: 0, closed: {} },
    reports: {},
    geometry: null,
  };
}
