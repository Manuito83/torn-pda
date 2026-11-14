// widget_push.ts

import * as admin from "firebase-admin";
import { logger } from "firebase-functions/v2";
import { sendWidgetPush } from "./la_apns_helper";

const TIME_TOLERANCE_SECONDS = 120;
const MIN_MILLIS_BETWEEN_PUSHES = 10 * 60 * 1000;

interface WidgetBar {
  fullAt: number;
  overMax: number;
}

interface WidgetSnapshot {
  state: string;
  until: number;
  destination: string;
  arrival: number;
  energy: WidgetBar;
  nerve: WidgetBar;
  happy: WidgetBar;
  life: WidgetBar;
  chainCooldownEnd: number;
  drugEnd: number;
  boosterEnd: number;
  medicalEnd: number;
  messages: number;
  events: number;
}

function buildWidgetSnapshot(userStats: any, now: number): WidgetSnapshot {
  const bar = (b: any): WidgetBar => {
    const current = b?.current || 0;
    const maximum = b?.maximum || 0;
    return {
      fullAt: current < maximum ? now + (b?.fulltime || 0) : 0,
      overMax: Math.max(0, current - maximum),
    };
  };
  const endOf = (seconds: number) => (seconds > 0 ? now + seconds : 0);
  const cooldowns = userStats.cooldowns || {};

  return {
    state: userStats.status?.state || "",
    until: userStats.status?.until || 0,
    destination: userStats.travel?.destination || "",
    arrival: userStats.travel?.timestamp || 0,
    energy: bar(userStats.energy),
    nerve: bar(userStats.nerve),
    // Happy over max decays every tick
    happy: { ...bar(userStats.happy), overMax: 0 },
    life: bar(userStats.life),
    chainCooldownEnd: endOf(userStats.chain?.cooldown || 0),
    drugEnd: endOf(cooldowns.drug || 0),
    boosterEnd: endOf(cooldowns.booster || 0),
    medicalEnd: endOf(cooldowns.medical || 0),
    messages: Object.keys(userStats.messages || {}).length,
    events: Object.keys(userStats.events || {}).length,
  };
}

// Expired timers are not a change
function sameTime(a: number, b: number, now: number) {
  if (Math.abs(a - b) <= TIME_TOLERANCE_SECONDS) return true;
  return (a === 0 && b <= now + TIME_TOLERANCE_SECONDS) || (b === 0 && a <= now + TIME_TOLERANCE_SECONDS);
}

function sameStatus(last: WidgetSnapshot, current: WidgetSnapshot, now: number) {
  if (last.state === current.state) return sameTime(last.until, current.until, now);
  const lastTimerEnd = last.state === "Traveling" ? last.arrival : last.until;
  const timerEnded = lastTimerEnd > 0 && lastTimerEnd <= now + TIME_TOLERANCE_SECONDS;
  return timerEnded && (current.state === "Okay" || current.state === "Abroad");
}

function widgetDataChanged(last: WidgetSnapshot, current: WidgetSnapshot, now: number): boolean {
  const bars = ["energy", "nerve", "happy", "life"] as const;
  const timers = ["chainCooldownEnd", "drugEnd", "boosterEnd", "medicalEnd"] as const;

  if (!sameStatus(last, current, now)) return true;
  if (last.destination !== current.destination || !sameTime(last.arrival, current.arrival, now)) return true;
  for (const key of bars) {
    const lastBar = last[key];
    const currentBar = current[key];
    if (lastBar.overMax !== currentBar.overMax || !sameTime(lastBar.fullAt, currentBar.fullAt, now)) return true;
  }
  for (const key of timers) {
    if (!sameTime(last[key], current[key], now)) return true;
  }
  return last.messages !== current.messages || last.events !== current.events;
}

export async function handleWidgetPush(userStats: any, subscriber: any) {
  try {
    const now = Math.floor(Date.now() / 1000);
    const snapshot = buildWidgetSnapshot(userStats, now);
    const stateRef = admin.database().ref(`widget_push/${subscriber.uid}`);
    const state = (await stateRef.once("value")).val();

    if (state?.sig && !widgetDataChanged(state.sig, snapshot, now)) return;
    if (Date.now() - (state?.last || 0) < MIN_MILLIS_BETWEEN_PUSHES) return;

    const result = await sendWidgetPush(subscriber.widget_push_token);
    if (result === "sent") {
      await stateRef.set({ sig: snapshot, last: Date.now() });
    } else if (result === "invalid-token") {
      await stateRef.remove();
      await admin.firestore().collection("players").doc(subscriber.uid).update({
        widget_push_bad_token: subscriber.widget_push_token,
      });
    }
  } catch (e) {
    logger.warn(`ERROR WIDGET PUSH \n${subscriber.uid} \n${e}`);
  }
}
