import { onSchedule } from "firebase-functions/v2/scheduler";
import { logger } from "firebase-functions/v2";
import * as admin from "firebase-admin";

export const WINDOW_DAYS = 30;

// Snapped to the month boundary so scheduler jitter cannot move the window
export function resolveWindow(now: Date) {
  const cutoff = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1));
  const from = new Date(cutoff.getTime() - WINDOW_DAYS * 24 * 60 * 60 * 1000);
  const last = new Date(cutoff.getTime() - 1);
  const label = `${last.getUTCFullYear()}-${String(last.getUTCMonth() + 1).padStart(2, "0")}`;
  return { cutoff, from, label };
}

// Lower bound only, so dates in the future are counted and reported apart
export async function computeSummary(db: admin.firestore.Firestore, from: Date, now: Date) {
  const query = db
    .collection("players")
    .where("lastActive", ">=", from.getTime())
    // select() keeps API keys and tokens out of memory
    .select("playerId", "platform", "lastActive");

  const players = new Set<unknown>();
  const platformDocs: Record<string, number> = {};
  const platformPlayers: Record<string, Set<unknown>> = {};
  let documents = 0;
  let futureDated = 0;

  for await (const doc of query.stream() as AsyncIterable<admin.firestore.QueryDocumentSnapshot>) {
    const data = doc.data();
    documents++;
    if (data.lastActive > now.getTime()) futureDated++;
    const platform = data.platform || "unknown";
    platformDocs[platform] = (platformDocs[platform] ?? 0) + 1;
    platformPlayers[platform] ??= new Set();
    if (data.playerId != null) {
      players.add(data.playerId);
      platformPlayers[platform].add(data.playerId);
    }
  }

  const byPlatform: Record<string, { documents: number; playerIds: number }> = {};
  for (const [platform, count] of Object.entries(platformDocs)) {
    byPlatform[platform] = { documents: count, playerIds: platformPlayers[platform].size };
  }

  return { playerIds: players.size, documents, byPlatform, futureDated };
}

export const countActives = onSchedule(
  {
    schedule: "0 0 1 * *",
    timeZone: "UTC",
    region: "us-east4",
    memory: "512MiB",
    timeoutSeconds: 540,
    retryCount: 3,
  },
  async () => {
    const now = new Date();
    const { cutoff, from, label } = resolveWindow(now);
    const db = admin.firestore();
    const summary = await computeSummary(db, from, now);

    await db.collection("metrics").doc(label).set({
      ...summary,
      windowFrom: admin.firestore.Timestamp.fromDate(from),
      windowTo: admin.firestore.Timestamp.fromDate(cutoff),
      windowDays: WINDOW_DAYS,
      computedAt: admin.firestore.Timestamp.fromDate(now),
    });

    logger.info(`metrics/${label}: ${summary.playerIds} distinct playerIds out of ${summary.documents} documents`);
  }
);
