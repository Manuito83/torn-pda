import { logger } from "firebase-functions/v2";
import * as admin from "firebase-admin";
import { anHourInMilliseconds } from "./time";

const WRITE_EVERY_MS = anHourInMilliseconds;

export type Via = "web" | "app" | "bot";

export const usersRef = () => admin.firestore().collection("feedback_users");

// One write per player and hour
export async function touchUser(playerId: number, via: Via) {
  try {
    const ref = usersRef().doc(`${playerId}`);
    const saved = await ref.get();
    const now = Date.now();
    if (saved.exists && saved.get(`via.${via}`) === true && now - (saved.get("lastSeen")?.toMillis() ?? 0) < WRITE_EVERY_MS) return;
    const at = admin.firestore.Timestamp.fromMillis(now);
    await ref.set({ ...(saved.exists ? {} : { firstSeen: at }), lastSeen: at, via: { [via]: true } }, { merge: true });
  } catch (e) {
    logger.warn(`Feedback: user ${playerId} not registered: ${e}`);
  }
}
