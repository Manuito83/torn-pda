import { onDocumentCreated, onDocumentDeleted } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions/v2";
import * as admin from "firebase-admin";
import { aDayInMilliseconds } from "./time";
import { feedbackRef, isPublic } from "./feedback";
import { moderatorIds } from "./feedback_author";
import { deleteObjects } from "./feedback_storage";
import {
  FEEDBACK_PUSH_ENABLED,
  commentPush,
  newFeedbackPush,
  notifySubscribers,
  statusPush,
} from "./feedback_notifications";

const TRIGGER = { region: "us-east4", timeoutSeconds: 540 };
const SENT_TTL_MS = 7 * aDayInMilliseconds;
const ALREADY_EXISTS = 6;

// False when an earlier delivery already sent
async function firstDelivery(key: string): Promise<boolean> {
  const now = Date.now();
  try {
    await admin.firestore().collection("feedback_sent").doc(key).create({
      at: admin.firestore.Timestamp.fromMillis(now),
      expireAt: admin.firestore.Timestamp.fromMillis(now + SENT_TTL_MS),
    });
    return true;
  } catch (e: any) {
    if (e?.code === ALREADY_EXISTS) return false;
    throw e;
  }
}

// Who may hear about a private item
async function audienceOf(feedback: admin.firestore.DocumentSnapshot): Promise<Set<number>> {
  const moderators = await moderatorIds();
  return feedback.get("report") === true ? moderators.add(feedback.get("authorPlayerId")) : moderators;
}

// Legacy imports stay silent
export const onFeedbackCreated = onDocumentCreated({ ...TRIGGER, document: "feedback/{feedbackId}" }, async (event) => {
  const feedback = event.data?.data();
  if (!FEEDBACK_PUSH_ENABLED || feedback === undefined || feedback.legacy !== undefined) return;
  if (!await firstDelivery(`feedback_${event.params.feedbackId}`)) return;
  await notifySubscribers(event.data.ref, feedback.createdByPlayerId ?? feedback.authorPlayerId,
    feedback.visibility !== "public", true, newFeedbackPush(feedback.title, feedback.authorName), await audienceOf(event.data));
});

export const onCommentCreated = onDocumentCreated({ ...TRIGGER, document: "feedback/{feedbackId}/comments/{commentId}" },
  async (event) => {
    const comment = event.data?.data();
    if (!FEEDBACK_PUSH_ENABLED || comment === undefined || comment.legacy !== undefined) return;
    const feedback = await feedbackRef().doc(event.params.feedbackId).get();
    if (!feedback.exists || !await firstDelivery(`comment_${feedback.id}_${event.params.commentId}`)) return;
    await notifySubscribers(feedback.ref, comment.authorPlayerId, !isPublic(feedback), false,
      commentPush(feedback.get("title"), comment.authorName, comment.body), await audienceOf(feedback));
  });

export const onFeedbackEvent = onDocumentCreated({ ...TRIGGER, document: "feedback_events/{eventId}" }, async (event) => {
  const change = event.data?.data();
  if (!FEEDBACK_PUSH_ENABLED || change === undefined) return;
  const feedback = await feedbackRef().doc(change.feedbackId).get();
  if (!feedback.exists || !await firstDelivery(`event_${event.params.eventId}`)) return;
  await notifySubscribers(feedback.ref, change.actorPlayerId, !isPublic(feedback), false,
    statusPush(feedback.get("title"), change.status, change.response), await audienceOf(feedback));
});

// Files go with their item or comment
export const onFeedbackDeleted = onDocumentDeleted({ ...TRIGGER, document: "feedback/{feedbackId}" }, async (event) => {
  await deleteObjects(event.params.feedbackId).catch((e) => logger.warn(`Feedback ${event.params.feedbackId}: files not deleted: ${e}`));
});

export const onCommentDeleted = onDocumentDeleted({ ...TRIGGER, document: "feedback/{feedbackId}/comments/{commentId}" }, async (event) => {
  const ids: string[] = (event.data?.get("attachments") ?? []).map((attachment: { id: string }) => attachment.id);
  if (ids.length === 0) return;
  await deleteObjects(event.params.feedbackId, ids).catch((e) => logger.warn(`Feedback ${event.params.feedbackId}: files not deleted: ${e}`));
});
