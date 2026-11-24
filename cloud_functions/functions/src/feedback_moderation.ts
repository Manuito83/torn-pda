import { onCall, HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import * as admin from "firebase-admin";
import { eventsRef, feedbackEvent } from "./feedback_notifications";
import { listComments, listPrivateBugs } from "./feedback_reads";
import { removeComment } from "./feedback_comments";
import { OPTIONS, STATUSES, configRef, feedbackIdOf, feedbackRef, isPublic, privateRef, signedIn, visibleTo } from "./feedback";
import { Author, requireModerator } from "./feedback_author";
import { cleanText, docId, invalid, notFound } from "./feedback_input";

const MAX_TAGS = 30;
const VISIBILITIES = ["public", "private", "report"];

async function setStatus(moderator: Author, data: any) {
  const status: string = STATUSES.includes(data.status) ? data.status : invalid("status");
  const responseText = data.responseText === undefined ? undefined
    : cleanText(data.responseText, 0, 2000, true) ?? invalid("responseText");
  const duplicateOf = status === "duplicate" ? docId(data.duplicateOf, "duplicateOf") : undefined;
  if (status !== "duplicate" && data.duplicateOf !== undefined) invalid("duplicateOf");
  const feedbackId = await feedbackIdOf(data);
  if (duplicateOf === feedbackId) invalid("duplicateOf");

  const ref = feedbackRef().doc(feedbackId);
  await admin.firestore().runTransaction(async (t) => {
    const [feedback, original] = await t.getAll(ref, ...(duplicateOf ? [feedbackRef().doc(duplicateOf)] : []));
    if (!await visibleTo(feedback, moderator)) notFound();
    if (original !== undefined && !isPublic(original)) invalid("duplicateOf");
    const now = admin.firestore.Timestamp.now();
    const remove = admin.firestore.FieldValue.delete();
    const update: Record<string, unknown> = { status, duplicateOf: duplicateOf ?? remove, updatedAt: now, lastActivityAt: now };
    if (responseText !== undefined) {
      update.response = responseText === "" ? remove : { text: responseText, authorName: moderator.name, at: now };
    }
    t.update(ref, update);
    const newStatus = feedback.get("status") !== status ? status : undefined;
    const newResponse = responseText && responseText !== feedback.get("response.text") ? responseText : undefined;
    if (newStatus || newResponse) {
      t.create(eventsRef().doc(), feedbackEvent(feedbackId, moderator.playerId, newStatus, newResponse));
    }
  });
}

async function setVisibility(data: any) {
  const visibility = VISIBILITIES.includes(data.visibility) ? data.visibility : invalid("visibility");
  const ref = feedbackRef().doc(await feedbackIdOf(data));
  const publicDuplicates = feedbackRef().where("duplicateOf", "==", ref.id).where("visibility", "==", "public").limit(1);
  await admin.firestore().runTransaction(async (t) => {
    const [feedback, duplicates] = await Promise.all([t.get(ref), t.get(publicDuplicates)]);
    if (!feedback.exists) notFound();
    // Reports never become private
    const hidden = feedback.get("report") === true ? "report" : "private";
    if (visibility !== "public" && (visibility !== hidden || feedback.get("type") !== "bug")) invalid("visibility");
    if (visibility !== "public" && !duplicates.empty) {
      throw new HttpsError("failed-precondition", "Has public duplicates", { reason: "has_public_duplicates" });
    }
    t.update(ref, { visibility, updatedAt: admin.firestore.Timestamp.now() });
  });
}

async function setTags(moderator: Author, data: any) {
  const tags = data.tags;
  if (!Array.isArray(tags) || tags.length > MAX_TAGS || new Set(tags).size !== tags.length) invalid("tags");
  const ref = feedbackRef().doc(await feedbackIdOf(data));
  await admin.firestore().runTransaction(async (t) => {
    const [feedback, config] = await t.getAll(ref, configRef());
    if (!await visibleTo(feedback, moderator)) notFound();
    const known = new Set((config.get("tags") ?? []).map((tag: any) => tag.id));
    if (!tags.every((tag: unknown) => known.has(tag))) invalid("tags");
    t.update(ref, { tags, updatedAt: admin.firestore.Timestamp.now() });
  });
}

async function setConfigTags(data: any) {
  const tags = data.tags;
  if (!Array.isArray(tags) || tags.length > MAX_TAGS) invalid("tags");
  const clean = tags.map((tag: any) => ({
    id: typeof tag?.id === "string" && /^[a-z0-9-]{1,30}$/.test(tag.id) ? tag.id : invalid("tag id"),
    name: cleanText(tag?.name, 1, 30, false) ?? invalid("tag name"),
    color: typeof tag?.color === "string" && /^#[0-9A-Fa-f]{6}$/.test(tag.color) ? tag.color : invalid("tag color"),
  }));
  if (new Set(clean.map((tag) => tag.id)).size !== clean.length) invalid("tags");
  await configRef().set({ tags: clean });
}

export const listPrivate = onCall(OPTIONS, async (request) => {
  const moderator = await requireModerator(signedIn(request));
  const data = request.data ?? {};
  if (data.commentsOf !== undefined) {
    const { items, cursor } = await listComments(moderator, { feedbackId: data.commentsOf, limit: data.limit, cursor: data.startAfter });
    return { items, nextCursor: cursor };
  }
  const { items, cursor } = await listPrivateBugs({ limit: data.limit, cursor: data.startAfter });
  return { items, nextCursor: cursor };
});

export async function moderateAs(moderator: Author, data: any) {
  logger.info(`Feedback: ${data.action} by ${moderator.name} [${moderator.playerId}]`);
  switch (data.action) {
    case "setStatus":
      return setStatus(moderator, data);
    case "setVisibility":
      return setVisibility(data);
    case "setTags":
      return setTags(moderator, data);
    case "setConfigTags":
      return setConfigTags(data);
    case "deleteComment": {
      const commentId = docId(data.commentId, "commentId");
      return removeComment(await feedbackIdOf(data), commentId);
    }
    case "deleteFeedback": {
      const ref = feedbackRef().doc(await feedbackIdOf(data));
      if (!(await ref.get()).exists) notFound();
      await admin.firestore().recursiveDelete(ref);
      await privateRef(ref.id).delete();
      return;
    }
    case "getSource": {
      const ref = feedbackRef().doc(await feedbackIdOf(data));
      const [feedback, extra] = await admin.firestore().getAll(ref, privateRef(ref.id));
      if (!feedback.exists) notFound();
      return { source: extra.get("source") ?? null };
    }
    default:
      invalid("action");
  }
}

export const moderate = onCall(OPTIONS, async (request) =>
  moderateAs(await requireModerator(signedIn(request)), request.data ?? {}));
