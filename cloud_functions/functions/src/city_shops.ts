import { onSchedule } from "firebase-functions/v2/scheduler";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import * as admin from "firebase-admin";
import { FieldPath, FieldValue, Timestamp } from "firebase-admin/firestore";
import type {
  CityShopItem,
  CityShopNotice,
  CityShopsApiResponse,
  CityShopsSample,
  CityShopState,
  CityShopsSeed,
  CityShopsTickResult,
} from "./interfaces/city_shops_interface";
import { sendNotificationToUser, type NotificationCheckResult } from "./notification";
const { tornKey } = require("../key/torn_key.js");

// Interval between scheduled API samples
export const CADENCE_MS = 60000;
// Two samples further apart than this count as a gap (missed tick)
const GAP_MS = CADENCE_MS + 45000;
// Observed cycles needed before they override the seeded base
const MIN_CYCLES = 3;
// Cycles after which the youth penalty on reliability stops
const MATURE_CYCLES = 6;
// Most recent cycles kept per item
const MAX_CYCLES = 40;
// Absent from the API this long: flagged as gone
export const GONE_AFTER_MS = 24 * 60 * 60 * 1000;
// Absent from the API this long: removed from state
export const PURGE_AFTER_MS = 30 * 24 * 60 * 60 * 1000;
// Observed this long without ever having stock: flagged as never stocked
export const NEVER_STOCKED_AFTER_MS = 7 * 24 * 60 * 60 * 1000;
// Fraction of fast sales above which reliability is penalised
const FAST_SALE_THRESHOLD = 0.1;
// Sold out within this many minutes of restock counts as a fast sale
const FAST_SALE_MIN = 2;
// Learned stock periods needed before the stats become available
const MIN_STOCK_PERIODS = 5;
// Minimum reliability to send a heads-up before the restock
const HEADS_UP_MIN_RELIABILITY = 95;
// Base cycle (minutes) where the 240+ bracket starts, reported as a long cycle
const SLOW_BASE_MIN = 180;
// Window before the predicted restock in which the notice is sent
const NOTICE_LEAD_MIN_MS = 2 * 60000;
const NOTICE_LEAD_MAX_MS = 6 * 60000;

const BRACKET_TOP: Record<string, number> = { "15": 97.0, "30": 96.8, "60": 96.3, "120": 95.9, "240+": 81.2 };
const YOUNG_FACTOR: Record<string, number> = { "15": 0.894, "30": 0.942, "60": 0.997, "120": 0.826, "240+": 1.0 };

export function estimateReliability(baseMin: number, n: number, fastSellFraction: number | null): number {
  const bracket = baseMin < 22 ? "15" : baseMin < 45 ? "30" : baseMin < 90 ? "60" : baseMin < SLOW_BASE_MIN ? "120" : "240+";
  const factor = n >= MATURE_CYCLES ? 1.0 : YOUNG_FACTOR[bracket];
  const penalty = fastSellFraction == null || fastSellFraction > FAST_SALE_THRESHOLD ? 3.0 : 0.0;
  return Math.round(Math.max(5.0, Math.min(97.0, BRACKET_TOP[bracket] * factor - penalty)));
}

// The base backed by more cycles wins, the seed on a tie; a full learned history beats any seed
export function effectiveBase(seedBaseMin: number | null, seedCycles: number, cycles: number[]) {
  let base: number | null = null;
  let n = 0;
  if (seedBaseMin != null) {
    base = seedBaseMin;
    n = seedCycles;
  }
  if (cycles.length >= MIN_CYCLES && (base === null || cycles.length > Math.min(n, MAX_CYCLES - 1))) {
    base = median([...cycles].sort((a, b) => a - b));
    n = cycles.length;
  }
  return { base, n };
}

function median(sorted: number[]): number {
  const mid = Math.floor(sorted.length / 2);
  return sorted.length % 2 === 1 ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2;
}

export function learnedStockStats(periods: number[]) {
  if (periods.length < MIN_STOCK_PERIODS) return null;
  const sorted = [...periods].sort((a, b) => a - b);
  const k = (sorted.length - 1) * 10 / 100;
  const lo = Math.floor(k);
  const p10 = sorted[lo] + (sorted[Math.min(lo + 1, sorted.length - 1)] - sorted[lo]) * (k - lo);
  return {
    stockP10Min: Math.round(p10 * 10) / 10,
    stockMedianMin: Math.round(median(sorted) * 10) / 10,
    fastSellFraction: Math.round((periods.filter((m) => m <= FAST_SALE_MIN).length / periods.length) * 100) / 100,
  };
}

export function lastSampleTime(state: Record<string, any> | null): number | null {
  let last: number | null = null;
  for (const raw of Object.values(state ?? {})) {
    if (typeof raw?.lastSeen === "number" && (last === null || raw.lastSeen > last)) last = raw.lastSeen;
  }
  return last;
}

export function buildCityShopItem(key: string, st: CityShopState, now: number): CityShopItem {
  const [shopId, itemId] = key.split("-").map(Number);
  const reliability = st.baseMin === null ? null : estimateReliability(st.baseMin, st.n, st.fastSellFraction);
  let mode: CityShopItem["mode"];
  let reason: CityShopItem["reason"];
  if (reliability === null) {
    mode = "no_data";
    reason = st.neverStocked ? "never_stocked" : "learning";
  } else if (reliability >= HEADS_UP_MIN_RELIABILITY) {
    mode = "heads_up";
    reason = "reliable";
  } else {
    mode = "on_restock";
    reason = st.baseMin! >= SLOW_BASE_MIN ? "slow_item" : "low_reliability";
  }
  return {
    shop: st.shop,
    item: st.item,
    shopId,
    itemId,
    mode,
    reason,
    reliability,
    baseMin: st.baseMin,
    cycles: st.n,
    stockP10Min: st.stockP10Min,
    stockMedianMin: st.stockMedianMin,
    fastSellFraction: st.fastSellFraction,
    window: st.window,
    lastWindow: st.lastWindow,
    lastEmpty: st.lastEmpty,
    lastRestock: st.lastRestock,
    lastEmptyRestock: st.lastEmptyRestock,
    stock: st.stock,
    gone: st.gone,
    updated: now,
  };
}

// Older state or seed may lack fields
function normalizeState(raw: any): CityShopState {
  return {
    stock: raw.stock ?? 0,
    lastEmpty: raw.lastEmpty ?? null,
    lastRestock: raw.lastRestock ?? null,
    lastEmptyRestock: raw.lastEmptyRestock ?? null,
    baseMin: raw.baseMin ?? null,
    cycles: raw.cycles ? Object.values(raw.cycles) : [],
    n: raw.n ?? 0,
    seedBaseMin: raw.seedBaseMin ?? null,
    seedCycles: raw.seedCycles ?? 0,
    stockP10Min: raw.stockP10Min ?? null,
    stockMedianMin: raw.stockMedianMin ?? null,
    fastSellFraction: raw.fastSellFraction ?? null,
    stockPeriods: raw.stockPeriods ? Object.values(raw.stockPeriods) : [],
    seedVersion: raw.seedVersion ?? null,
    window: raw.window ? { start: raw.window.start, end: raw.window.end } : null,
    lastWindow: raw.lastWindow ? { start: raw.lastWindow.start, end: raw.lastWindow.end } : null,
    neverStocked: raw.neverStocked ?? false,
    lastSeen: raw.lastSeen ?? 0,
    firstSeen: raw.firstSeen ?? null,
    emptyAfterGap: raw.emptyAfterGap ?? false,
    stockAfterGap: raw.stockAfterGap ?? false,
    gone: raw.gone ?? false,
    shop: raw.shop ?? "",
    item: raw.item ?? "",
  };
}

export function runCityShopsTick(
  prevState: Record<string, any> | null,
  sample: CityShopsSample,
  prevSampleTime: number | null,
): CityShopsTickResult {
  const now = sample.time;
  const gap = prevSampleTime !== null && now - prevSampleTime > GAP_MS;
  // One missed sample
  const shortGap = gap && now - prevSampleTime! <= GAP_MS + CADENCE_MS;
  const state: Record<string, CityShopState> = {};
  const items: Record<string, CityShopItem> = {};

  for (const [key, raw] of Object.entries(prevState ?? {})) {
    state[key] = normalizeState(raw);
  }

  const observedKeys = new Set<string>();
  for (const [key, stock] of Object.entries(sample.stocks)) {
    if (stock == null) continue;
    observedKeys.add(key);
    const prev = state[key] as CityShopState | undefined;
    const st: CityShopState = prev
      ? { ...prev, cycles: [...prev.cycles] }
      : normalizeState({ stock });
    const names = sample.names?.[key];
    st.shop = names?.shop || st.shop;
    st.item = names?.item || st.item;

    // lastSeen 0 means never observed (fresh key, or a seed): first sample just sets stock, no transition
    if (prev && prev.lastSeen !== 0 && prev.stock > 0 && stock === 0) {
      const { base } = effectiveBase(st.seedBaseMin, st.seedCycles, st.cycles);
      // Missing from earlier global samples too, not only from a gap
      const itemAbsent = prevSampleTime !== null && prev.lastSeen < prevSampleTime && now - prev.lastSeen > GAP_MS;
      st.lastEmpty = shortGap && !itemAbsent ? prev.lastSeen : now;
      st.emptyAfterGap = gap || now - prev.lastSeen > GAP_MS;
      if (prev.lastRestock !== null && !prev.stockAfterGap && !st.emptyAfterGap) {
        const minutes = (st.lastEmpty - prev.lastRestock) / 60000;
        if (minutes > 0) st.stockPeriods = [...st.stockPeriods, Math.round(minutes * 100) / 100].slice(-MAX_CYCLES);
      }
      st.window = base === null || itemAbsent ? null : {
        start: st.lastEmpty + Math.floor(base * 0.9 * 60) * 1000 - CADENCE_MS,
        end: (shortGap && !itemAbsent ? now : st.lastEmpty) + Math.floor(base * 1.1 * 60) * 1000 + CADENCE_MS,
      };
    } else if (prev && prev.lastSeen !== 0 && prev.stock === 0 && stock > 0) {
      const cleanRestock = !prev.emptyAfterGap && !gap && now - prev.lastSeen <= GAP_MS;
      if (prev.lastEmpty !== null && cleanRestock) {
        const minutes = (now - prev.lastEmpty) / 60000;
        if (minutes > 0) st.cycles = [...st.cycles, Math.round(minutes * 100) / 100].slice(-MAX_CYCLES);
      }
      st.lastRestock = now;
      st.lastWindow = prev.window;
      st.lastEmptyRestock = prev.lastEmpty;
      st.emptyAfterGap = false;
      st.stockAfterGap = gap || now - prev.lastSeen > GAP_MS;
      st.window = null;
    } else if (prev && prev.lastSeen !== 0 && (gap || now - prev.lastSeen > GAP_MS)) {
      // A restock and sellout may have fallen inside the gap
      if (stock === 0) st.emptyAfterGap = true;
      else st.stockAfterGap = true;
    }

    const stats = learnedStockStats(st.stockPeriods);
    if (stats) Object.assign(st, stats);
    const { base, n } = effectiveBase(st.seedBaseMin, st.seedCycles, st.cycles);
    st.stock = stock;
    st.lastSeen = now;
    st.firstSeen = st.firstSeen ?? now;
    st.baseMin = base;
    st.n = base === null ? st.cycles.length : n;
    const neverHadStock = st.lastEmpty === null && st.lastRestock === null;
    st.neverStocked = stock === 0 && (st.neverStocked || (neverHadStock && now - st.firstSeen >= NEVER_STOCKED_AFTER_MS));
    st.gone = false;

    if (!prev || JSON.stringify({ ...prev, lastSeen: 0 }) !== JSON.stringify({ ...st, lastSeen: 0 })) {
      items[key] = buildCityShopItem(key, st, now);
    }
    state[key] = st;
  }

  // Items absent from this sample: mark gone once past 24h, purge past 30 days
  const purge: string[] = [];
  for (const [key, st] of Object.entries(state)) {
    if (observedKeys.has(key) || st.lastSeen === 0) continue;
    const staleFor = now - st.lastSeen;
    if (staleFor > PURGE_AFTER_MS) {
      purge.push(key);
      delete state[key];
    } else if (staleFor > GONE_AFTER_MS && !st.gone) {
      st.gone = true;
      items[key] = buildCityShopItem(key, st, now);
    }
  }

  return { state, items, purge };
}

// App writes a server timestamp, the notifier writes a number
function markToMillis(value: unknown): number {
  if (typeof value === "number") return value;
  if (value instanceof Timestamp) return value.toMillis();
  return 0;
}

// Players may not have the city shop maps yet
export function decideCityShopAlerts(
  items: Record<string, CityShopItem>,
  subscriber: any,
  nowMs: number,
): CityShopNotice[] {
  const activeAlerts = subscriber.cityShopActiveAlerts || {};
  // Sellout each heads-up was sent for, per key
  const headsUps = subscriber.cityShopHeadsUp || {};
  const onlyConfirmed = subscriber.cityShopOnlyConfirmed === true;
  const notices: CityShopNotice[] = [];

  for (const [key, value] of Object.entries(activeAlerts)) {
    const item = items[key];
    if (!item) continue;

    // Old marks came from the phone clock, which may run ahead
    const lastNotified = Math.min(markToMillis(value), nowMs);
    const notifiedThisCycle = item.lastEmpty != null && headsUps[key] === item.lastEmpty;

    if (item.mode === "heads_up" && item.stock === 0 && item.window && !onlyConfirmed && !notifiedThisCycle) {
      const lead = item.window.start - nowMs;
      if (lead >= NOTICE_LEAD_MIN_MS && lead < NOTICE_LEAD_MAX_MS) {
        const mark = Math.max(lastNotified, item.lastRestock ?? 0);
        notices.push({ kind: "heads_up", key, shop: item.shop, item: item.item, window: item.window, mark });
      }
    }

    if (item.lastRestock != null && item.lastRestock > lastNotified) {
      const w = item.lastWindow;
      const outsideWindow = !w || item.lastRestock < w.start || item.lastRestock > w.end;
      const headsUpSentForRestock = item.lastEmptyRestock != null && headsUps[key] === item.lastEmptyRestock;
      if (!headsUpSentForRestock || onlyConfirmed || outsideWindow) {
        notices.push({ kind: "on_restock", key, shop: item.shop, item: item.item, window: w ?? null, mark: item.lastRestock });
      }
    }
  }

  return notices;
}

// Rounded up, minimum 1, so a window that already started never reads "0 min" or negative
export function minutesFromNow(ms: number, nowMs: number): number {
  return Math.max(1, Math.ceil((ms - nowMs) / 60000));
}

const DAY_MIN = 1440;

function tctMinuteOfDay(nowMs: number): number {
  return Math.floor(nowMs / 60000) % DAY_MIN;
}

export function isInTorn(userStats: any): boolean {
  const travel = userStats?.travel;
  if (!travel) return true;
  const inTransit = (travel.time_left ?? 0) > 0;
  return !inTransit && (!travel.destination || travel.destination === "Torn");
}

// True when the player asked not to be alerted right now: away from Torn, or outside the chosen hours
// A missing cityShopOnlyInTorn counts as enabled; from == to means the whole day
export function cityShopAlertsMuted(subscriber: any, userStats: any, nowMs: number): boolean {
  // Set by the app when the daily purchase limit is reached, expires at 00:00 TCT
  if (nowMs < Number(subscriber.cityShopMutedUntil ?? 0)) return true;

  if (subscriber.cityShopOnlyInTorn !== false && !isInTorn(userStats)) return true;

  if (subscriber.cityShopHoursEnabled === true) {
    const from = Number(subscriber.cityShopHoursFrom ?? 0);
    const to = Number(subscriber.cityShopHoursTo ?? 0);
    if (from !== to) {
      const tct = tctMinuteOfDay(nowMs);
      const inside = from < to ? tct >= from && tct < to : tct >= from || tct < to;
      if (!inside) return true;
    }
  }

  return false;
}

export function sendCityShopRestockNotification(
  items: Record<string, CityShopItem>,
  subscriber: any,
  nowMs: number,
  userStats: any = null,
) {
  const result: NotificationCheckResult = {};

  try {
    let toNotify = decideCityShopAlerts(items, subscriber, nowMs);

    // Muted: restocks seen now are marked so they are not reported later
    const muted = cityShopAlertsMuted(subscriber, userStats, nowMs);
    if (muted) {
      toNotify = toNotify.filter((a) => a.kind === "on_restock");
      if (toNotify.length > 0) {
        result.firestoreUpdate = {};
        for (const alert of toNotify) {
          result.firestoreUpdate[`cityShopActiveAlerts.${alert.key}`] = alert.mark;
        }
      }
      return result;
    }

    if (toNotify.length === 0) return result;

    const kinds = new Set(toNotify.map((a) => a.kind));
    let title = "City shop restocks";
    if (kinds.size === 1) {
      title = kinds.has("heads_up") ? "City shop restock soon" : "City shop restock";
    }

    const formatLine = (alert: CityShopNotice): string => {
      if (alert.kind === "heads_up" && alert.window) {
        const from = minutesFromNow(alert.window.start, nowMs);
        const to = minutesFromNow(alert.window.end, nowMs);
        return `${alert.item} at ${alert.shop}, restock expected in ${from} to ${to} min`;
      }
      const item = items[alert.key];
      const soldOut = item.stock === 0 ? " and sold out again" : "";
      return `${alert.item} restocked at ${alert.shop}${soldOut}`;
    };
    let body = toNotify.map(formatLine).join("\n");

    result.firestoreUpdate = {};
    for (const alert of toNotify) {
      result.firestoreUpdate[`cityShopActiveAlerts.${alert.key}`] = alert.mark;
      if (alert.kind === "heads_up") {
        result.firestoreUpdate[`cityShopHeadsUp.${alert.key}`] = items[alert.key].lastEmpty;
      }
    }

    if (subscriber.discrete) {
      title = "Shops";
      body = " ";
    }

    result.notification = {
      token: subscriber.token,
      title: title,
      body: body,
      icon: "notification_city_shops",
      color: "#389500",
      channelId: "Alerts city shops",
      vibration: subscriber.vibration,
      extraData: {
        shopId: toNotify.map((a) => a.key.split("-")[0]).join(","),
        itemId: toNotify.map((a) => a.key.split("-")[1]).join(","),
        key: toNotify.map((a) => a.key).join(","),
        kind: toNotify.map((a) => a.kind).join(","),
      },
    };
  } catch (error) {
    logger.warn(`ERROR CITY SHOPS \n${subscriber.uid} \n${error}`);
  }

  return result;
}

async function fetchCityShops(): Promise<CityShopsSample | null> {
  try {
    const response = await fetch(`https://api.torn.com/v2/torn?selections=cityshops&key=${tornKey}`, {
      signal: AbortSignal.timeout(25000),
    });
    if (!response.ok) {
      logger.warn(`CityShops: HTTP ${response.status}, state untouched`);
      return null;
    }
    const time = Date.parse(response.headers.get("date") ?? "");
    if (isNaN(time)) {
      logger.warn("CityShops: response without a valid Date header, state untouched");
      return null;
    }
    const data = await response.json() as CityShopsApiResponse;
    if (data.error || !Array.isArray(data.cityshops)) {
      logger.warn(`CityShops: API error or no cityshops (${JSON.stringify(data.error ?? null)}), state untouched`);
      return null;
    }

    const sample: CityShopsSample = { time, stocks: {}, names: {} };
    for (const shop of data.cityshops) {
      for (const item of shop.items ?? []) {
        const key = `${shop.id}-${item.id}`;
        sample.stocks[key] = item.stock?.current ?? null;
        sample.names![key] = { shop: shop.name ?? "", item: item.name ?? "" };
      }
    }
    return sample;
  } catch (e: any) {
    logger.warn(`CityShops: fetch failed, state untouched: ${e.message || e}`);
    return null;
  }
}

// Every city shops document keeps its payload as a JSON string in a single field
function parseJsonDoc(doc: FirebaseFirestore.DocumentSnapshot): any {
  const json = doc.get("json");
  return typeof json === "string" ? JSON.parse(json) : null;
}

// Copies the seed fields into known or sampled items not yet on this seed version, so purged items stay out
// Returns the keys it seeded, so the caller can rebuild their cards even without an engine transition
export function applyCityShopsSeed(
  state: Record<string, any>,
  seed: CityShopsSeed | null,
  sample: CityShopsSample,
): string[] {
  if (!seed || typeof seed.version !== "number" || !seed.items) return [];
  const applied: string[] = [];
  for (const [key, entry] of Object.entries(seed.items)) {
    if (!entry || typeof entry !== "object") continue;
    if (state[key] === undefined && sample.stocks[key] == null) continue;
    const prev = state[key] ?? {};
    if (prev.seedVersion === seed.version) continue;
    state[key] = {
      ...prev,
      seedBaseMin: entry.seedBaseMin ?? null,
      seedCycles: entry.seedCycles ?? 0,
      // Never override a neverStocked the engine already set; it only clears it once it sees stock
      neverStocked: (entry.neverStocked ?? false) || (prev.neverStocked ?? false),
      shop: entry.shop || prev.shop || "",
      item: entry.item || prev.item || "",
      seedVersion: seed.version,
    };
    applied.push(key);
  }
  return applied;
}

export const updateCityShops = onSchedule({
  schedule: "* * * * *",
  region: "us-east4",
  memory: "512MiB",
  timeoutSeconds: 55
}, async () => {
  try {
    const sample = await fetchCityShops();
    if (!sample) return;

    const firestore = admin.firestore();
    const docs = firestore.collection("cityshops");
    const [stateDoc, seedDoc, itemsDoc] = await firestore.getAll(
      docs.doc("state"),
      docs.doc("seed"),
      docs.doc("items"),
    );
    let prevState: Record<string, any>;
    try {
      prevState = parseJsonDoc(stateDoc) ?? {};
    } catch (e: any) {
      throw new Error(`state doc unreadable, refusing to overwrite it: ${e.message || e}`);
    }

    // A broken seed document must not stop the tick from writing state and items
    let seededKeys: string[] = [];
    try {
      const seed: CityShopsSeed | null = parseJsonDoc(seedDoc);
      seededKeys = applyCityShopsSeed(prevState, seed, sample);
      if (seededKeys.length > 0) {
        logger.info(`CityShops: seed ${seed!.version} applied to ${seededKeys.length} items`);
      }
    } catch (e: any) {
      logger.warn(`CityShops: seed read/apply failed, running without it: ${e.message || e}`);
    }

    const { state, items, purge } = runCityShopsTick(prevState, sample, lastSampleTime(prevState));

    // Reseeding alone may not produce an engine transition, so rebuild those cards directly
    for (const key of seededKeys) {
      if (key in state) items[key] ??= buildCityShopItem(key, state[key], sample.time);
    }

    // The tick only returns the cards that changed; without a readable items doc, rebuild them all
    let storedItems: Record<string, CityShopItem> | null = null;
    if (itemsDoc.exists) {
      try {
        storedItems = parseJsonDoc(itemsDoc);
      } catch (e: any) {
        logger.warn(`CityShops: items doc unreadable, rebuilding all cards: ${e.message || e}`);
      }
    }
    let allItems: Record<string, CityShopItem>;
    if (storedItems) {
      allItems = { ...storedItems, ...items };
    } else {
      allItems = {};
      for (const [key, st] of Object.entries(state)) allItems[key] = buildCityShopItem(key, st, sample.time);
    }
    for (const key of purge) delete allItems[key];

    const updated = Date.now();
    const batch = firestore.batch();
    batch.set(docs.doc("state"), { json: JSON.stringify(state), updated });
    batch.set(docs.doc("items"), { json: JSON.stringify(allItems), updated });
    await batch.commit();

    if (purge.length > 0) {
      try {
        await cleanupOrphanedCityShopAlerts(purge);
      } catch (e: any) {
        logger.error(`CityShops: orphaned alert cleanup failed (purge still succeeded): ${e}`);
      }
    }

    logger.info(`CityShops: ${Object.keys(sample.stocks).length} items, ${Object.keys(items).length} changed, ${purge.length} purged`);
  } catch (e: any) {
    logger.error(`CityShops: tick failed: ${e}`);
  }
});

// Removes purged keys from cityShopActiveAlerts and cityShopHeadsUp on subscribed players
async function cleanupOrphanedCityShopAlerts(purgedKeys: string[]) {
  const fields = ["cityShopActiveAlerts", "cityShopHeadsUp"];
  const pageSize = 500;
  let lastDoc: FirebaseFirestore.QueryDocumentSnapshot | null = null;
  let affected = 0;

  while (true) {
    let query: FirebaseFirestore.Query = admin
      .firestore()
      .collection("players")
      .where("active", "==", true)
      .where("cityShopRestockNotification", "==", true)
      .select(...fields)
      .orderBy(FieldPath.documentId())
      .limit(pageSize);
    if (lastDoc) query = query.startAfter(lastDoc);

    const snapshot = await query.get();
    if (snapshot.empty) break;

    const updates = snapshot.docs.map((doc) => {
      const payload: Record<string, FirebaseFirestore.FieldValue> = {};
      for (const field of fields) {
        const map = doc.get(field);
        if (!map) continue;
        for (const key of purgedKeys) {
          if (key in map) payload[`${field}.${key}`] = FieldValue.delete();
        }
      }
      return Object.keys(payload).length > 0 ? doc.ref.update(payload) : null;
    }).filter((update) => update !== null);
    await Promise.all(updates);
    affected += updates.length;

    lastDoc = snapshot.docs[snapshot.docs.length - 1];
    if (snapshot.size < pageSize) break;
  }
  logger.info(`CityShops: removed orphaned alerts (${purgedKeys.join(", ")}) from ${affected} players`);
}

// Test send to the caller, needs a real ID token (functions:shell can't fake request.auth)
export const cityShopsTest = onCall(
  {
    region: "us-east4",
    memory: "512MiB",
    timeoutSeconds: 120,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }
    const uid = request.auth.uid;

    const doc = await admin.firestore().collection("players").doc(uid).get();
    if (!doc.exists) {
      throw new HttpsError("not-found", `Player '${uid}' not found.`);
    }
    // Subscribe the player to both test keys
    const subscriber = {
      ...doc.data(),
      uid: doc.id,
      cityShopActiveAlerts: { "101-310": 0, "103-172": 0 },
      cityShopOnlyConfirmed: false,
      cityShopOnlyInTorn: false,
      cityShopHoursEnabled: false,
      cityShopMutedUntil: 0,
    };

    const now = Date.now();
    const common = {
      baseMin: 15,
      cycles: 10,
      stockP10Min: null as number | null,
      stockMedianMin: null as number | null,
      fastSellFraction: 0,
      gone: false,
      updated: now,
    };
    const items: Record<string, CityShopItem> = {
      "101-310": {
        ...common,
        shop: "Sally's Sweet Shop",
        item: "Lollipop",
        shopId: 101,
        itemId: 310,
        mode: "heads_up",
        reason: "reliable",
        reliability: 97,
        stock: 0,
        window: { start: now + 3.5 * 60000, end: now + 12 * 60000 },
        lastWindow: { start: now + 3.5 * 60000, end: now + 12 * 60000 },
        lastEmpty: now - 10 * 60000,
        lastRestock: null,
        lastEmptyRestock: null,
      },
      "103-172": {
        ...common,
        shop: "Bits 'n' Bobs",
        item: "Gasoline",
        shopId: 103,
        itemId: 172,
        mode: "on_restock",
        reason: "low_reliability",
        reliability: 80,
        stock: 12,
        window: null,
        lastWindow: null,
        lastEmpty: now - 20 * 60000,
        lastRestock: now - 60000,
        lastEmptyRestock: now - 20 * 60000,
      },
    };

    const result = sendCityShopRestockNotification(items, subscriber, now);
    let sent = false;
    if (result.notification) {
      sent = (await sendNotificationToUser(result.notification)) !== null;
    }

    return { success: true, sent, kinds: result.notification?.extraData?.kind ?? "" };
  }
);
