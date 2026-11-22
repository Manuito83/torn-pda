import { onSchedule } from "firebase-functions/v2/scheduler";
import { logger } from "firebase-functions/v2";
import * as admin from "firebase-admin";
import { buildAlerts } from "./alerts";
import { Sender, buildFcmMessages, sendAll } from "./fcm";
import { Upload, closeDays, planUploads, publishTerritories, sampleUploads } from "./publish";
import { R2Client, R2Config, R2Files } from "./r2";
import { TICK, readSources, run } from "./sources";
import { Store, firestoreStore } from "./store";
import { TornClient } from "./torn";
import { MapState, emptyState } from "./types";

const QUIET_GAP = 30 * 60;
const CALL_BUDGET_MS = 40000;
const SLOW_TICK_MS = 45000;
const SLOW_WINDOW = 3600;
const SLOW_LIMIT = 10;
// no upload starts after this
const UPLOAD_UNTIL_MS = 45000;

export interface TickDeps {
  store: Store;
  makeTorn: (state: MapState, now: number, deadlineMs: number) => TornClient;
  r2: R2Files | null;
  send: Sender;
  clockMs: () => number;
}

// Failed or out of time
async function putAll(r2: R2Files, uploads: Upload[], hasTime: () => boolean): Promise<Upload[]> {
  const failed: Upload[] = [];
  for (const u of uploads) {
    if (!hasTime()) {
      failed.push(u);
      continue;
    }
    try {
      await r2.put(u.key, u.body, u.contentType, u.cacheControl);
      u.done?.();
    } catch (error) {
      failed.push(u);
      logger.error(`territoryMapTick: upload of ${u.key} failed`, error);
    }
  }
  return failed;
}

// True when it must switch off
function noteSlowTick(state: MapState, now: number, elapsedMs: number): boolean {
  state.slow_ticks = state.slow_ticks.filter((at) => at > now - SLOW_WINDOW);
  if (elapsedMs > SLOW_TICK_MS) state.slow_ticks.push(now);
  if (state.slow_ticks.length < SLOW_LIMIT) return false;
  state.slow_ticks = [];
  return true;
}

export async function runTick(deps: TickDeps): Promise<void> {
  const startMs = deps.clockMs();
  const now = Math.floor(startMs / 1000);
  let read;
  try {
    read = await deps.store.read();
  } catch (error) {
    logger.error("territoryMapTick: state read failed, nothing done", error);
    return;
  }
  const { control, saved } = read;
  if (!control || !control.enabled || control.paused_until > now) {
    logger.info(`territoryMapTick: off (${control ? control.off_reason || "disabled or paused" : "no control document"})`);
    return;
  }

  const state = saved?.state ?? emptyState();
  const quiet = !saved || now - saved.saved_at > QUIET_GAP;
  const torn = deps.makeTorn(state, now, startMs + CALL_BUDGET_MS);
  const r2 = deps.r2;
  const { facts, changes } = await readSources(state, { torn, r2 }, control, now, quiet);
  const { messages, endings } = quiet ? { messages: [], endings: [] } : buildAlerts(state, facts, now);
  for (const id of endings) state.wars[id].ending_sent = true;
  const hasTime = () => deps.clockMs() - startMs < UPLOAD_UNTIL_MS;
  // first start publishes nothing
  if (saved && r2 && !torn.outOfTime()) {
    const prefix = control.publish_prefix;
    await run(state, "shapes", TICK, now, () => publishTerritories(state, prefix, now, r2, hasTime));
    await run(state, "close", TICK, now,
      () => closeDays(state, prefix, now, r2, hasTime, control.close_missing));
  }
  const uploads = saved && r2 ? planUploads(state, control, now) : [];
  const elapsedMs = deps.clockMs() - startMs;
  const turnOff = noteSlowTick(state, now, elapsedMs);

  try {
    await deps.store.writeState(state, now, elapsedMs);
  } catch (error) {
    logger.error("territoryMapTick: state write failed, nothing published or sent", error);
    return;
  }
  if (turnOff) {
    const reason = `${SLOW_LIMIT} ticks over ${SLOW_TICK_MS / 1000} s in the last hour`;
    await deps.store.writeControl({ enabled: false, off_reason: reason });
    logger.error(`territoryMapTick: OFF, ${reason}`);
  }

  const failed = r2 ? await putAll(r2, uploads, hasTime) : [];
  if (failed.length) logger.warn(`territoryMapTick: ${failed.length} of ${uploads.length} uploads left for later`);
  const undo = failed.filter((u) => u.undo);
  const closedUp = uploads.some((u) => u.done && !failed.includes(u));
  if (undo.length || closedUp) {
    undo.forEach((u) => u.undo?.());
    // after failures or closed war files
    await deps.store.writeState(state, now, elapsedMs).catch((error) =>
      logger.error("territoryMapTick: state rewrite after uploads failed", error));
  }
  if (r2 && saved && control.sample) {
    try {
      const sample = await sampleUploads(state, control.publish_prefix, now, r2);
      if (!(await putAll(r2, sample, hasTime)).length) await deps.store.writeControl({ sample: false });
      logger.info(`territoryMapTick: sample/ with ${sample.length} files`);
    } catch (error) {
      logger.error("territoryMapTick: sample/ failed", error);
    }
  }

  let sent = 0;
  if (messages.length && control.send_alerts) {
    sent = (await sendAll(buildFcmMessages(messages, startMs), deps.send, "territoryMapTick")).sent;
  } else {
    for (const m of messages) logger.info(`territoryMapTick: would send ${m.key} to ${m.topics.join(" ")}: ${m.title} | ${m.body}`);
  }
  const seconds = ((deps.clockMs() - startMs) / 1000).toFixed(1);
  logger.info(`territoryMapTick: ${torn.tickCalls} calls, ${changes} changes, ${messages.length} alerts ` +
    `(${sent} sent), ${uploads.length} uploads${quiet ? ", quiet" : ""}, ${seconds} s`);
}

function r2Client(config: Partial<R2Config>): R2Client | null {
  const fields: Array<keyof R2Config> = ["r2AccountId", "r2AccessKeyId", "r2SecretAccessKey", "r2Bucket",
    "publicBaseUrl", "mapHeader"];
  const missing = fields.filter((f) => !config[f]);
  if (missing.length) {
    logger.error(`territoryMapTick: key/territory_map_key.js lacks ${missing.join(", ")}, nothing is published`);
    return null;
  }
  return new R2Client(config as R2Config);
}

function loadKeys() {
  try {
    return { torn: require("../../key/torn_key.js"), map: require("../../key/territory_map_key.js") };
  } catch (error) {
    logger.error("territoryMapTick: key files missing, tick skipped", error);
    return null;
  }
}

export const territoryMapTick = onSchedule(
  {
    schedule: "*/2 * * * *",
    region: "us-east4",
    memory: "512MiB",
    timeoutSeconds: 60,
    maxInstances: 1,
    concurrency: 1,
    retryCount: 0,
    minInstances: 0,
  },
  async () => {
    const keys = loadKeys();
    if (!keys) return;
    const { tornKey, tornParam } = keys.torn;
    await runTick({
      store: firestoreStore(admin.firestore()),
      makeTorn: (state, now, deadlineMs) => new TornClient(tornKey, tornParam ?? "", state, now, deadlineMs),
      r2: r2Client(keys.map),
      send: (messages) => admin.messaging().sendEach(messages),
      clockMs: Date.now,
    });
  }
);
