import { onSchedule } from "firebase-functions/v2/scheduler";
import { logger } from "firebase-functions/v2";
import * as admin from "firebase-admin";
import { aDayInMilliseconds } from "./time";
import { feedbackRef } from "./feedback";
import { ticketsRef } from "./feedback_attachments";
import { deleteObjects, listObjects } from "./feedback_storage";

// Longer than any permission lives
const ORPHAN_MARGIN_MS = aDayInMilliseconds;
const ORPHAN_LOOKBACK_MS = 3 * aDayInMilliseconds;
const TICKETS_PER_BATCH = 400;

// Deletes uploads never confirmed and expired permissions
export async function sweepAttachments(now = Date.now()) {
  const byItem = new Map<string, string[]>();
  for (const { feedbackId, attachmentId, createdAt } of await listObjects()) {
    const age = now - createdAt;
    if (age > ORPHAN_MARGIN_MS && age <= ORPHAN_LOOKBACK_MS) byItem.set(feedbackId, [...byItem.get(feedbackId) ?? [], attachmentId]);
  }
  let objects = 0;
  for (const [feedbackId, ids] of byItem) {
    const ref = feedbackRef().doc(feedbackId);
    const [item, comments] = await Promise.all([ref.get(), ref.collection("comments").select("attachments").get()]);
    const used = new Set(item.exists ? [item, ...comments.docs].flatMap((doc) =>
      ((doc.get("attachments") ?? []) as { id: string }[]).map((attachment) => attachment.id)) : []);
    const orphans = ids.filter((id) => !used.has(id));
    if (orphans.length === 0) continue;
    await deleteObjects(feedbackId, orphans);
    objects += orphans.length;
  }
  let tickets = 0;
  for (;;) {
    const expired = await ticketsRef().where("expireAt", "<", admin.firestore.Timestamp.fromMillis(now)).limit(TICKETS_PER_BATCH).get();
    if (expired.empty) break;
    const batch = admin.firestore().batch();
    expired.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
    tickets += expired.size;
  }
  return { objects, tickets };
}

export const sweepFeedbackAttachments = onSchedule({ schedule: "17 4 * * *", timeZone: "Etc/UTC", region: "us-east4",
  timeoutSeconds: 300 }, async () => {
  const { objects, tickets } = await sweepAttachments();
  logger.info(`Feedback: swept ${objects} orphan files and ${tickets} expired permissions`);
});
