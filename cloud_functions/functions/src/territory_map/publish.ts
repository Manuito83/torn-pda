import { logger } from "firebase-functions/v2";
import { gunzipSync } from "zlib";
import {
  CHANGES_EVERY, LOG_DAYS, buildDayChanges, dayChangesFor, factionNames, finishRows, firstFullDay, lastClosableDay,
  openDays, rowContext,
} from "./day_changes";
import {
  FOREVER_CACHE, GZIP, HEARTBEAT_CACHE, OPEN_WAR_CACHE, STATE_CACHE, TODAY_CACHE, buildHeartbeat, buildState,
  digest, encodeGzip,
} from "./exports";
import { HistoryDoc, addDay, emptyHistory, historyCache, historyKey, stateWars, yearOf } from "./history";
import { R2Files } from "./r2";
import { TerritoriesFile, nextTerritories, territoriesKey } from "./territories";
import { Control, DAY, MapState, Published, dayStart, nextDay, utcDay } from "./types";
import { WAR_FILES_PER_TICK, buildWarFile, isClosed, isDue, warFileCandidates, warKey } from "./war_files";

// a failed upload is retried this late
const REFRESH_AFTER = 10 * 60;
const DAYS_PER_CLOSE = 2;
// retry a missing history file
const HISTORY_WAIT = 15 * 60;

export interface Upload {
  key: string;
  body: Buffer;
  contentType: string;
  cacheControl: string;
  // forgets the record if the upload fails
  undo?: () => void;
  // after the upload, saved later
  done?: () => void;
}

function gzipUpload(state: MapState, key: string, doc: Record<string, unknown>, cacheControl: string,
  record: Published): Upload {
  const before = state.published[key];
  state.published[key] = record;
  return {
    key, body: encodeGzip(doc), contentType: GZIP, cacheControl,
    undo: () => {
      if (before) state.published[key] = before;
      else delete state.published[key];
    },
  };
}

// State only if it changed, heartbeat always
export function planUploads(state: MapState, control: Control, now: number): Upload[] {
  const uploads: Upload[] = [];
  const key = `${control.publish_prefix}state.json.gz`;
  const doc = buildState(state, now);
  const hash = digest(doc, STATE_CACHE);
  const last = state.published[key];
  if (Object.keys(doc.ownership).length && (!last || last.digest !== hash || now - last.at >= REFRESH_AFTER)) {
    uploads.push(gzipUpload(state, key, doc, STATE_CACHE, { digest: hash, at: now }));
  }
  uploads.push({
    key: `${control.publish_prefix}heartbeat.json`, body: Buffer.from(JSON.stringify(buildHeartbeat(state, now))),
    contentType: "application/json", cacheControl: HEARTBEAT_CACHE,
  });
  return [...uploads, ...planChanges(state, control.publish_prefix, now),
    ...planWarFiles(state, control.publish_prefix, now)];
}

function forget(state: MapState, pattern: RegExp, keep: (match: string) => boolean) {
  for (const key of Object.keys(state.published)) {
    const match = pattern.exec(key)?.[1];
    if (match !== undefined && !keep(match)) delete state.published[key];
  }
}

// Open days, every 4 ticks, if changed
export function planChanges(state: MapState, prefix: string, now: number): Upload[] {
  const open = openDays(now);
  forget(state, /changes\/(\d{4}-\d\d-\d\d)\.json\.gz$/, (day) => open.includes(day));
  const before = state.log.changes_at;
  if (now - before < CHANGES_EVERY) return [];
  state.log.changes_at = now;
  const uploads: Upload[] = [];
  for (const day of open) {
    const key = `${prefix}changes/${day}.json.gz`;
    const doc = dayChangesFor(state, day, now);
    const hash = digest(doc, TODAY_CACHE);
    if (state.published[key]?.digest === hash) continue;
    const upload = gzipUpload(state, key, doc, TODAY_CACHE, { digest: hash, at: now });
    const forget = upload.undo;
    // not up: try again next tick
    upload.undo = () => {
      forget?.();
      state.log.changes_at = before;
    };
    uploads.push(upload);
  }
  return uploads;
}

// Twenty at most, closed ones once
export function planWarFiles(state: MapState, prefix: string, now: number): Upload[] {
  forget(state, /wars\/(\d+)\.json\.gz$/, (id) => id in state.wars);
  const uploads: Upload[] = [];
  for (const id of warFileCandidates(state, prefix, now)) {
    if (uploads.length >= WAR_FILES_PER_TICK) break;
    const key = prefix + warKey(id);
    const closed = isClosed(state.wars[id], state.reports[id], now);
    const cache = closed ? FOREVER_CACHE : OPEN_WAR_CACHE;
    const doc = buildWarFile(state, id, now);
    const hash = digest(doc, cache);
    if (!closed && !isDue(state.published[key], hash, now)) continue;
    const upload = gzipUpload(state, key, doc, cache, { digest: hash, at: now });
    if (closed) upload.done = () => { state.published[key] = { digest: hash, at: now, closed: true }; };
    uploads.push(upload);
  }
  return uploads;
}

// Year of the first open day
async function historyToExtend(state: MapState, prefix: string, first: string, last: string,
  r2: R2Files): Promise<{ key: string; doc: HistoryDoc } | null> {
  const done = state.log.closed[prefix];
  for (let year = yearOf(done ? nextDay(done) : first); ; year++) {
    const key = prefix + historyKey(year);
    const raw = await r2.get(key);
    if (raw) {
      const doc: HistoryDoc = JSON.parse(gunzipSync(raw).toString());
      if (done && year <= yearOf(done) && doc.through < done) {
        logger.error(`territoryMapTick: ${key} ends on ${doc.through || "nothing"} but ${done} was closed, ` +
          "someone wrote an older year over it");
        return null;
      }
      if (doc.through) state.log.closed[prefix] = doc.through;
      // a finished year: on to the next
      if (doc.through === `${year}-12-31` && year < yearOf(last)) continue;
      return { key, doc };
    }
    const after = state.log.closed[prefix];
    // new year starts after 31 December
    if (after && yearOf(after) === year - 1) {
      return { key, doc: { ...emptyHistory(year, dayStart(`${year}-01-01`)), through: after } };
    }
    if (prefix) return { key, doc: emptyHistory(year, dayStart(first)) };
    logger.error(`territoryMapTick: ${key} is missing, days are not closed until the one-shot upload runs`);
    return null;
  }
}

// The history file says what is closed
export async function closeDays(state: MapState, prefix: string, now: number, r2: R2Files,
  hasTime: () => boolean = () => true, closeMissing = false): Promise<number | undefined> {
  const last = lastClosableDay(state.read_at, now);
  const done = state.log.closed[prefix];
  const first = firstFullDay(state.log.since);
  if ((done && done >= last) || last < first || !hasTime()) return undefined;
  const found = await historyToExtend(state, prefix, first, last, r2);
  if (!found) return HISTORY_WAIT;
  const key = found.key;
  let doc = found.doc;
  let day = doc.through ? nextDay(doc.through) : first;
  if (day < first) {
    logger.error(`territoryMapTick: ${key} ends on ${doc.through}, the function holds days from ${first} only`);
    return HISTORY_WAIT;
  }
  const closing: string[] = [];
  const stale = utcDay(now - LOG_DAYS * DAY);
  for (; closing.length < DAYS_PER_CLOSE && day <= last && yearOf(day) === doc.year; day = nextDay(day)) {
    const lost = state.log.dropped?.includes(day) || (!state.log.days[day] && day < stale);
    if (lost && !closeMissing) {
      logger.error(`territoryMapTick: ${day} is not in the diary, ${key} stays on ${doc.through} ` +
        "until close_missing is set");
      break;
    }
    closing.push(day);
  }
  // stopped on a lost day
  if (!closing.length) return day <= last ? HISTORY_WAIT : undefined;
  const ctx = rowContext(state);
  const names = factionNames(state);
  const wars = stateWars(state);
  for (const d of closing) {
    if (!hasTime()) return undefined;
    const rows = finishRows(state.log.days[d] ?? [], ctx);
    await r2.put(`${prefix}changes/${d}.json.gz`, encodeGzip(buildDayChanges(d, rows, names, now)), GZIP,
      FOREVER_CACHE);
    doc = addDay(doc, d, rows, wars, names, now);
  }
  if (!hasTime()) return undefined;
  await r2.put(key, encodeGzip(doc), GZIP, historyCache(doc.through));
  state.log.closed[prefix] = doc.through;
  state.log.dropped = state.log.dropped?.filter((d) => !closing.includes(d));
  logger.info(`territoryMapTick: closed ${closing.join(", ")} into ${key}`);
  return undefined;
}

// Shapes go up before the state
export async function publishTerritories(state: MapState, prefix: string, now: number, r2: R2Files,
  hasTime: () => boolean = () => true) {
  const scan = state.geometry;
  if (!scan?.done || !hasTime()) return;
  const version = state.territories_version;
  if (scan.version === version) {
    const raw = await r2.get(territoriesKey(version));
    if (!raw) throw new Error(`${territoriesKey(version)} is not in the bucket`);
    const file: TerritoriesFile = JSON.parse(gunzipSync(raw).toString());
    if (scan.missing.length) {
      logger.error(`territoryMapTick: territories without a shape (${scan.missing.slice(0, 10).join(", ")}), ` +
        `staying on v${version} until v${version + 1} is made by hand`);
    }
    const next = nextTerritories(file, scan, now);
    if (next && prefix) {
      logger.info(`territoryMapTick: geometry changed, live would publish ${territoriesKey(next.version)}`);
    } else if (next) {
      // the scan waits for the next tick
      if (!hasTime()) return;
      await r2.put(territoriesKey(next.version), encodeGzip(next), GZIP, FOREVER_CACHE);
      state.territories_version = next.version;
      logger.info(`territoryMapTick: geometry changed, ${territoriesKey(next.version)} published`);
    }
  }
  state.geometry = null;
}

// Files for sample/, on demand
export async function sampleUploads(state: MapState, prefix: string, now: number, r2: R2Files): Promise<Upload[]> {
  const version = state.territories_version;
  const territories = await r2.get(territoriesKey(version));
  if (!territories) throw new Error(`${territoriesKey(version)} is not in the bucket`);
  const doc = buildState(state, now);
  const files: Record<string, Buffer> = {
    "state.json.gz": encodeGzip(doc),
    [territoriesKey(version)]: territories,
  };
  for (const day of [utcDay(now - 86400), utcDay(now)]) {
    files[`changes/${day}.json.gz`] = encodeGzip(dayChangesFor(state, day, now));
  }
  for (const w of [...doc.wars, ...doc.recent_wars]) {
    if (state.wars[w.id]) files[warKey(w.id)] = encodeGzip(buildWarFile(state, String(w.id), now));
  }
  return Object.entries(files).map(([key, body]) => ({
    key: `${prefix}sample/${key}`, body, contentType: GZIP, cacheControl: TODAY_CACHE,
  }));
}
