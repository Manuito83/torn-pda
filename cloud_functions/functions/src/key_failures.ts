import * as admin from "firebase-admin";
import { logger } from "firebase-functions/v2";
import { sendNotificationToUser } from "./notification";
import { aDayInMilliseconds } from "./time";

export interface KeyTracking {
  failingSince: Map<string, number>;
  responses: number;
  rejected: FirebaseFirestore.DocumentData[];
  deleted: number;
}

function keyFailures() {
  return admin.firestore().collection("key_failures");
}

// Undefined if unreadable
export async function readKeyTracking(): Promise<KeyTracking | undefined> {
  try {
    const snapshot = await keyFailures().where("expireAt", ">", admin.firestore.Timestamp.now()).get();
    return { failingSince: new Map(snapshot.docs.map((d) => [d.id, d.get("since")])), responses: 0, rejected: [], deleted: 0 };
  } catch (e) {
    logger.warn(`Key failures unreadable, not tracked this pass: ${e}`);
    return undefined;
  }
}

// Only Torn's incorrect key counts
export async function trackKeyResult(subscriber: any, userStats: any, tracking: KeyTracking) {
  tracking.responses++;
  if (userStats.error) {
    if (userStats.error.code === 2) tracking.rejected.push(subscriber);
    return;
  }
  if (!tracking.failingSince.has(subscriber.uid)) return;
  try {
    await keyFailures().doc(subscriber.uid).delete();
    tracking.deleted++;
  } catch (e) {
    logger.warn(`ERROR KEY FAILURES \n${subscriber.uid} \n${e}`);
  }
}

export async function settleKeyFailures(tracking: KeyTracking, pass: string) {
  const { responses, rejected } = tracking;
  const braked = responses >= 50 && rejected.length > responses * 0.1;
  let outcomes: (string | undefined)[] = [];
  if (braked) {
    logger.warn(`${pass}: ${rejected.length} of ${responses} keys rejected, key failures not counted this pass`);
  } else {
    outcomes = await Promise.all(rejected.map((subscriber) => countRejectedKey(subscriber, tracking.failingSince.get(subscriber.uid))));
  }
  const count = (outcome: string) => outcomes.filter((o) => o === outcome).length;
  logger.info(
    `${pass} key failures: ${responses} responses, ${rejected.length} incorrect key, ` +
    `${tracking.failingSince.size} marks read, ${count("created")} created, ` +
    `${tracking.deleted + count("cleared")} deleted, ${count("deactivated")} deactivated, brake ${braked ? "on" : "off"}`
  );
}

async function countRejectedKey(subscriber: any, failingSince: number | undefined) {
  const now = Date.now();
  const markRef = keyFailures().doc(subscriber.uid);
  try {
    if (failingSince === undefined) {
      await markRef.set({
        since: now,
        expireAt: admin.firestore.Timestamp.fromMillis(now + aDayInMilliseconds * 3),
      });
      return "created";
    }
    if (now - failingSince < aDayInMilliseconds) return undefined;

    const playerRef = admin.firestore().collection("players").doc(subscriber.uid);
    const outcome = await admin.firestore().runTransaction(async (t) => {
      const [player, mark] = await t.getAll(playerRef, markRef);
      if (!mark.exists) return undefined;
      t.delete(markRef);
      // Key changed since this pass read it
      if (!player.exists || player.get("apiKey") !== subscriber.apiKey) return "cleared";
      t.update(playerRef, { active: false });
      return "deactivated";
    });
    if (outcome !== "deactivated") return outcome;
    logger.warn(`Staled: ${subscriber.playerId} with UID ${subscriber.uid} after a day of incorrect key`);

    await sendNotificationToUser({
      token: subscriber.token,
      title: "Automatic alerts have been paused!",
      body: "Torn rejected your API key: alerts, assists and retals are paused until you update it in Settings.",
      icon: "notification_icon",
      color: "#FFFFFF",
      channelId: "Alerts stale user",
      vibration: "medium",
    }).catch((e) => logger.warn(`ERROR KEY FAILURES \n${subscriber.uid} \n${e}`));
    return outcome;
  } catch (e) {
    logger.warn(`ERROR KEY FAILURES \n${subscriber.uid} \n${e}`);
    return undefined;
  }
}
