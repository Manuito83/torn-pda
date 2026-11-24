import { HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { subscribersOf, subscription } from "./feedback_notifications";
import { anHourInMilliseconds } from "./time";
import { feedbackIdOf, feedbackRef, forPlayer, visibleTo, withSlots } from "./feedback";
import { Author, actsAsModerator } from "./feedback_author";
import { cleanText, docId, invalid, notFound } from "./feedback_input";

// Own deletes pass onlyAuthor
export async function removeComment(feedbackId: string, commentId: string, onlyAuthor?: number) {
  const ref = feedbackRef().doc(feedbackId);
  const commentRef = ref.collection("comments").doc(commentId);
  await admin.firestore().runTransaction(async (t) => {
    const [feedback, comment] = await t.getAll(ref, commentRef);
    if (!feedback.exists || !comment.exists) notFound();
    if (onlyAuthor !== undefined && comment.get("authorPlayerId") !== onlyAuthor) {
      throw new HttpsError("permission-denied", "Not your comment");
    }
    t.delete(commentRef);
    t.update(ref, { commentsCount: Math.max(0, (feedback.get("commentsCount") ?? 1) - 1) });
  });
}

export async function addComment(author: Author, data: any) {
  const body = cleanText(data.body, 1, 2000, true) ?? invalid("body");
  const moderator = await actsAsModerator(author);
  return withSlots([[`feedback_comment_${author.playerId}`, 20, anHourInMilliseconds]], async () => {
    const ref = feedbackRef().doc(await feedbackIdOf(data));
    const subRef = subscribersOf(ref).doc(`${author.playerId}`);
    return admin.firestore().runTransaction(async (t) => {
      const [feedback, subscribed] = await t.getAll(ref, subRef);
      if (!await visibleTo(feedback, author)) notFound();
      const now = admin.firestore.Timestamp.now();
      const commentRef = ref.collection("comments").doc();
      t.create(commentRef, {
        body,
        authorName: author.name,
        authorPlayerId: author.playerId,
        createdAt: now,
        isModerator: moderator,
      });
      t.update(ref, { commentsCount: (feedback.get("commentsCount") ?? 0) + 1, lastActivityAt: now });
      if (!subscribed.exists) t.create(subRef, subscription("comment", author.playerId));
      else if (subscribed.get("reason") === "manual") t.update(subRef, { reason: "comment", playerId: author.playerId });
      return { commentId: commentRef.id };
    });
  });
}

export async function deleteOwn(author: Author, data: any) {
  const commentId = docId(data.commentId, "commentId");
  const feedbackId = await feedbackIdOf(data);
  if (!await visibleTo(await feedbackRef().doc(feedbackId).get(), author)) notFound();
  await removeComment(feedbackId, commentId, author.playerId);
}

export const comment = forPlayer(addComment);
export const deleteOwnComment = forPlayer(deleteOwn);
