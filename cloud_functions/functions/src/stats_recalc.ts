import { onSchedule } from "firebase-functions/v2/scheduler";
import { logger } from "firebase-functions/v2";
import * as admin from "firebase-admin";

// Boolean flags on the player document that are mirrored as counters in RTDB /stats.
// Keep in sync with the manageStats() calls in players.ts
const booleanStats = [
  "alertsEnabled",
  "energyNotification",
  "nerveNotification",
  "lifeNotification",
  "travelNotification",
  "foreignRestockNotification",
  "hospitalNotification",
  "drugsNotification",
  "medicalNotification",
  "boosterNotification",
  "racingNotification",
  "messagesNotification",
  "eventsNotification",
  "refillsNotification",
  "stockMarketNotification",
  "factionAssistMessage",
  "retalsNotification",
  "forumsSubscriptionsNotification",
];

// The counters are kept by adding deltas from the player triggers, which drifts
export const recalculateStats = onSchedule(
  {
    schedule: "0 5 * * 0",
    region: "us-east4",
    memory: "512MiB",
    timeoutSeconds: 540,
  },
  async () => {
    const players = admin.firestore().collection("players");
    const countOf = async (query: FirebaseFirestore.Query) => (await query.count().get()).data().count;

    const stats: { [key: string]: number } = {};

    stats.totalUsers = await countOf(players);
    stats.activeUsers = await countOf(players.where("active", "==", true));
    stats.android = await countOf(players.where("platform", "==", "android"));
    stats.ios = await countOf(players.where("platform", "==", "ios"));
    stats.la_travel_enabled = await countOf(players.where("la_travel_push_token", ">", ""));
    stats.la_racing_enabled = await countOf(players.where("la_racing_push_token", ">", ""));

    for (const field of booleanStats) {
      stats[field] = await countOf(players.where(field, "==", true));
    }

    await admin.database().ref("stats").update(stats);

    logger.info(`Stats recalculated: ${JSON.stringify(stats)}`);
  }
);
