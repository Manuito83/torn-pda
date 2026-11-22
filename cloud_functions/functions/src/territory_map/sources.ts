import { logger } from "firebase-functions/v2";
import { gunzipSync } from "zlib";
import { TickFacts } from "./alerts";
import {
  WAR_MAX_SECONDS, irradiationsFrom, isComplete, keepWar, linkBombTerritories, matchIrradiations, mergeBombs,
  ownershipChanges, ownershipRemoved, parseFactionCsv, racketChanges, recentDetonations, takeSample, warChanges,
} from "./compare";
import {
  LOG_MAX_DAYS, addRows, bombRows, ownershipRows, pruneLog, racketRows, rowFactionIds, warRows,
} from "./day_changes";
import { keepForHistory } from "./history";
import { R2Files } from "./r2";
import { GEOMETRY_EVERY, GEOMETRY_PAGE, TerritoriesFile, newScan, scanPage, territoriesKey } from "./territories";
import { MAX_CALLS_PER_TICK, TornClient, TornError, pauseFor } from "./torn";
import {
  Control, Faction, MapState, POINT_ID, Source, Task, TornItem, TornOwnership, TornWar, utcDay,
} from "./types";
import { NOT_READY, REPORTS_PER_TICK, dueReports, queueReports, reportFrom, reportMissed } from "./war_files";

export const TICK = 120;
// the scheduler drifts a few seconds
const EARLY = 30;
const MAX_BACKOFF = 15 * 60;
const RACKETS_EVERY = 16 * 60;
const BOMBS_EVERY = 3600;
const STALE_FACTS = 30 * 60;
const WAR_PAGE = 100;
const WAR_MAX_PAGES = 3;
const OWNERSHIP_PAGE = 500;
const OWNERSHIP_GROUP = 3;
const OWNERSHIP_MAX_PAGES = 12;
const BOMB_KEEP = 7 * 86400;
const MATCH_LOOKBACK = 3 * 3600;
const IRRADIATION_KEEP = MATCH_LOOKBACK + 3600;
const FACTIONS_AFTER = 10 * 60;
const MIN_FACTION_ROWS = 1000;
const PRICES_AFTER = 30 * 60;
const ITEMS_PER_CALL = 100;
const MAX_NEW_VERSIONS = 5;
const GEOMETRY_PAGES_PER_TICK = 4;

export interface SourceDeps {
  torn: TornClient;
  r2: R2Files | null;
}

export interface Collected {
  facts: TickFacts;
  changes: number;
}

// Next due time, doubled wait after failures
export async function run(state: MapState, task: Task, every: number, now: number,
  fn: () => Promise<number | void>) {
  const offline = task === "territories" || task === "close" || task === "shapes";
  if ((state.due[task] ?? 0) > now || (!offline && state.pause_until > now)) return;
  try {
    const wait = await fn();
    state.failures[task] = 0;
    state.due[task] = now + (typeof wait === "number" ? wait : every) - EARLY;
  } catch (error) {
    const failures = (state.failures[task] ?? 0) + 1;
    state.failures[task] = failures;
    const wait = Math.min(every * 2 ** (failures - 1), Math.max(every, MAX_BACKOFF));
    state.due[task] = now + wait - EARLY;
    logger.warn(`territoryMapTick: ${task} failed (${failures} in a row), retry in ${wait} s: ${error}`);
  }
}

export async function readSources(state: MapState, deps: SourceDeps, control: Control, now: number,
  quiet: boolean): Promise<Collected> {
  const facts: TickFacts = { warsRead: false, warEvents: [], ownership: [], rackets: [] };
  let changes = 0;
  // events older than 30 min are stale
  const fresh = (source: Source) => {
    const last = state.read_at[source];
    return !quiet && last !== undefined && now - last <= STALE_FACTS;
  };
  const torn = deps.torn;
  const day = utcDay(now);
  const intoDay = now % 86400;
  if (!state.log.since) state.log.since = now;
  // a quiet day is still a day
  state.log.days[day] ??= [];

  await run(state, "wars", TICK, now, async () => {
    const events = await readWars(state, torn, control.publish_prefix, now);
    addRows(state.log, warRows(events, state.wars, now));
    queueReports(state.reports, events.filter((e) => e.kind === "end" || e.kind === "result").map((e) => e.war_id),
      now);
    changes += events.length;
    if (fresh("wars")) facts.warEvents = events;
    facts.warsRead = true;
    state.read_at.wars = now;
  });
  await run(state, "ownership", control.ownership_every_ticks * TICK, now, async () => {
    const found = await readOwnership(state, torn, now);
    addRows(state.log, ownershipRows(found, now));
    changes += found.length;
    if (fresh("ownership")) facts.ownership = found;
    state.read_at.ownership = now;
  });
  await run(state, "rackets", RACKETS_EVERY, now, async () => {
    const rackets = (await torn.get("faction/rackets")).rackets ?? [];
    if (!rackets.length && Object.keys(state.rackets).length) throw new Error("empty rackets, not applied");
    const found = racketChanges(state.rackets, rackets);
    const next = { ...state.rackets, ...found.rows };
    for (const c of found.changes) if (c.kind === "removed") delete next[c.territory];
    state.rackets = next;
    addRows(state.log, racketRows(found.changes, now));
    changes += found.changes.length;
    if (fresh("rackets")) facts.rackets = found.changes;
    state.read_at.rackets = now;
  });
  await run(state, "bombs", BOMBS_EVERY, now, async () => {
    const found = await readBombs(state, torn, now);
    addRows(state.log, bombRows(found, now));
    changes += found.length;
    state.read_at.bombs = now;
  });
  await run(state, "factions", TICK, now, async () => {
    if (state.factions_day === day || intoDay < FACTIONS_AFTER) return;
    await readFactions(state, torn);
    state.factions_day = day;
    state.read_at.factions = now;
  });
  await run(state, "prices", TICK, now, async () => {
    if (state.prices_day === day || intoDay < PRICES_AFTER) return;
    await readPrices(state, torn, day);
    state.prices_day = day;
  });
  await run(state, "reports", TICK, now, () => readReports(state, torn, now));
  const r2 = deps.r2;
  if (r2) {
    await run(state, "territories", TICK, now, async () => {
      if (state.territories_checked_day === day) return;
      for (let i = 0; i < MAX_NEW_VERSIONS; i++) {
        if (torn.outOfTime()) return;
        const status = await r2.headPublic(territoriesKey(state.territories_version + 1));
        if (status === 404) break;
        if (status !== 200) throw new Error(`HEAD territories: HTTP ${status}`);
        state.territories_version++;
      }
      state.territories_checked_day = day;
    });
    await run(state, "geometry", TICK, now, () => readGeometry(state, torn, r2));
  }
  const dropped = pruneLog(state.log, control.publish_prefix, now);
  if (dropped.length) {
    logger.error(`territoryMapTick: days ${dropped.join(", ")} dropped unclosed after ${LOG_MAX_DAYS} days`);
  }
  return { facts, changes };
}

// Two at most, with the calls left
async function readReports(state: MapState, torn: TornClient, now: number) {
  const room = Math.min(REPORTS_PER_TICK, MAX_CALLS_PER_TICK - torn.tickCalls);
  for (const id of dueReports(state.reports, now, room)) {
    if (torn.outOfTime()) return;
    const old = state.reports[id];
    try {
      const data = await torn.get(`faction/${id}/territorywarreport`);
      const report = reportFrom(data.territorywarreport, now, old.attempts + 1);
      state.reports[id] = report;
      const war = state.wars[id];
      // the real end, not the read
      if (war && typeof report.ended_at === "number" && report.ended_at > 0) war.ended_at = report.ended_at;
    } catch (error) {
      const refused = error instanceof TornError && !pauseFor(error.code);
      if (!refused && !(error instanceof TypeError)) throw error;
      state.reports[id] = reportMissed(old, now);
      if (!(error instanceof TornError && error.code === NOT_READY)) {
        logger.warn(`territoryMapTick: report of war ${id}: ${error}`);
      }
    }
  }
}

// Spread over ticks, with the calls left
async function readGeometry(state: MapState, torn: TornClient, r2: R2Files) {
  const room = Math.min(GEOMETRY_PAGES_PER_TICK, MAX_CALLS_PER_TICK - torn.tickCalls);
  // a finished scan waits for publish
  if (room < 1 || torn.outOfTime() || state.geometry?.done) return TICK;
  const version = state.territories_version;
  const raw = await r2.get(territoriesKey(version));
  if (!raw) throw new Error(`${territoriesKey(version)} is not in the bucket`);
  const file: TerritoriesFile = JSON.parse(gunzipSync(raw).toString());
  if (state.geometry?.version !== version) state.geometry = newScan(version);
  const scan = state.geometry;
  for (let i = 0; i < room; i++) {
    const page = (await torn.get("torn/territory", { limit: GEOMETRY_PAGE, offset: scan.offset })).territory ?? [];
    scanPage(scan, page, file);
    if (page.length < GEOMETRY_PAGE) break;
    if (i === room - 1) return TICK;
  }
  scan.done = true;
  return GEOMETRY_EVERY;
}

async function readWars(state: MapState, torn: TornClient, prefix: string, now: number) {
  const items = new Map<number, TornWar>();
  let params: Record<string, string | number> = { limit: WAR_PAGE, sort: "DESC" };
  let exhausted = false;
  for (let i = 0; i < WAR_MAX_PAGES; i++) {
    const page: TornWar[] = (await torn.get("faction/warfareterritory", params)).warfareterritory ?? [];
    const added = page.filter((w) => !items.has(w.id));
    page.forEach((w) => items.set(w.id, w));
    if (page.length < WAR_PAGE) {
      exhausted = true;
      break;
    }
    const oldest = Math.min(...page.map((w) => w.start));
    if (!added.length || oldest < now - WAR_MAX_SECONDS - 3600) break;
    params = { ...params, to: oldest };
  }
  const wars = [...items.values()];
  if (!wars.length) throw new Error("empty wars, not applied");
  const coveredFrom = exhausted ? 0 : Math.min(...wars.map((w) => w.start));
  const { rows, events } = warChanges(state.wars, wars, coveredFrom, state.read_at.wars === undefined, now);
  for (const war of Object.values(rows)) {
    const sample = takeSample(war, now);
    if (sample) war.samples = [...war.samples, sample];
  }
  Object.assign(state.wars, rows);
  for (const [id, war] of Object.entries(state.wars)) {
    if (!keepForHistory(state.log, prefix, war, now)) delete state.wars[id];
    // kept for the year only
    else if (!keepWar(war, now)) war.samples = [];
  }
  for (const id of Object.keys(state.reports)) if (!state.wars[id]) delete state.reports[id];
  return events;
}

// All pages or nothing
async function readOwnership(state: MapState, torn: TornClient, now: number) {
  const items: TornOwnership[] = [];
  let done = false;
  for (let offset = 0; !done; offset += OWNERSHIP_PAGE * OWNERSHIP_GROUP) {
    if (offset >= OWNERSHIP_PAGE * OWNERSHIP_MAX_PAGES) throw new Error("too many ownership pages");
    const offsets = Array.from({ length: OWNERSHIP_GROUP }, (_, i) => offset + i * OWNERSHIP_PAGE);
    const pages = await Promise.all(offsets.map((o) =>
      torn.get("faction/territoryownership", { limit: OWNERSHIP_PAGE, offset: o })));
    for (const data of pages) {
      const page: TornOwnership[] = data.territoryOwnership ?? [];
      items.push(...page);
      if (page.length < OWNERSHIP_PAGE || !data._metadata?.links?.next) {
        done = true;
        break;
      }
    }
  }
  const known = state.ownership;
  const baseline = Object.keys(known).length === 0;
  const { changes, rows } = ownershipChanges(known, items, baseline);
  const seen = new Set(Object.keys(rows));
  const removed = !baseline && isComplete(seen.size, Object.keys(known).length) ? ownershipRemoved(known, seen) : [];
  const next = { ...known, ...rows };
  for (const c of removed) delete next[c.territory];
  state.ownership = next;
  state.irradiations = [...state.irradiations.filter(([, at]) => at >= now - IRRADIATION_KEEP),
    ...irradiationsFrom(changes, now)];
  return [...changes, ...removed];
}

async function readBombs(state: MapState, torn: TornClient, now: number) {
  const items = (await torn.get("faction/dirtybombs")).dirtybombs ?? [];
  if (!items.length) throw new Error("empty bombs, not applied");
  const baseline = state.read_at.bombs === undefined;
  const known = new Set(state.bombs.map((b) => b.id));
  state.bombs = mergeBombs(state.bombs, items, now - BOMB_KEEP, now);
  const found = baseline ? [] : state.bombs.filter((b) => !known.has(b.id));
  const detonations = recentDetonations(state.bombs, now - MATCH_LOOKBACK);
  let links: Array<[number, string, number]> = [];
  if (detonations.size) {
    const first = Math.min(...detonations.values()) - 2 * 60;
    links = matchIrradiations(detonations, state.irradiations.filter(([, at]) => at >= first));
  }
  state.bomb_territories = linkBombTerritories(state.bomb_territories, links, state.bombs);
  return found;
}

// Only the factions the map cites
async function readFactions(state: MapState, torn: TornClient) {
  const text = await torn.get("faction/snapshot", {}, true);
  if (typeof text !== "string") throw new Error("faction snapshot without CSV");
  const all = parseFactionCsv(text);
  const count = Object.keys(all).length;
  if (count < MIN_FACTION_ROWS) throw new Error(`short faction snapshot: ${count} rows`);
  const ids = new Set<number>();
  Object.values(state.ownership).forEach((o) => ids.add(o[0]));
  Object.values(state.rackets).forEach((r) => ids.add(r.faction_id));
  Object.values(state.wars).forEach((w) => ids.add(w.aggressor.id).add(w.defender.id));
  // names for the diary days held
  Object.values(state.log.days).forEach((rows) => rowFactionIds(rows).forEach((id) => ids.add(id)));
  const picked: Record<string, Faction> = {};
  for (const id of ids) if (all[String(id)]) picked[String(id)] = all[String(id)];
  state.factions = picked;
}

async function readPrices(state: MapState, torn: TornClient, day: string) {
  const rewards = Object.values(state.rackets).map((r) => r.reward);
  const ids = [...new Set(rewards.filter((r) => r?.type === "Item" && r.id).map((r) => r?.id as number))]
    .sort((a, b) => a - b);
  const points = rewards.some((r) => r?.type === "Points");
  if (!ids.length && !points) return;
  const found: TornItem[] = [];
  for (let i = 0; i < ids.length; i += ITEMS_PER_CALL) {
    found.push(...((await torn.get(`torn/${ids.slice(i, i + ITEMS_PER_CALL).join(",")}/items`)).items ?? []));
  }
  for (const item of found) {
    const price = item.value?.market_price;
    if (typeof price === "number" && item.name) state.prices[`Item:${item.id}`] = { name: item.name, price, day };
  }
  if (!points) return;
  const listings: Array<{ cost?: number }> = (await torn.get("market/pointsmarket")).pointsmarket ?? [];
  const costs = listings.map((p) => p.cost).filter((c): c is number => typeof c === "number" && c > 0);
  if (costs.length) state.prices[`Points:${POINT_ID}`] = { name: "Points", price: Math.min(...costs), day };
}
