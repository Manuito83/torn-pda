import * as admin from "firebase-admin";
import { anHourInMilliseconds } from "./time";
import { feedbackRef, forPlayer, visibleTo, withSlots } from "./feedback";
import { Author } from "./feedback_author";
import { item, pageOf } from "./feedback_reads";
import { subscribersOf } from "./feedback_notifications";

// Created or commented, newest first
export async function mineOf(author: Author, data: any) {
  const subscription = (feedbackId: string) => subscribersOf(feedbackRef().doc(feedbackId)).doc(`${author.playerId}`);
  const query = admin.firestore().collectionGroup("subscribers").where("playerId", "==", author.playerId)
    .where("reason", "in", ["author", "comment"]).orderBy("since", "desc");
  return withSlots([[`feedback_mine_${author.playerId}`, 60, anHourInMilliseconds]], async () => {
    const page = await pageOf({ doc: subscription }, query, data.limit, data.cursor);
    // Group query also matches foreign collections
    const docs = page.docs.filter((doc) => doc.ref.parent.parent?.parent.path === feedbackRef().path);
    const parents = docs.map((doc) => doc.ref.parent.parent as admin.firestore.DocumentReference);
    const found = parents.length === 0 ? [] : await admin.firestore().getAll(...parents);
    const items = [];
    for (const [i, feedback] of found.entries()) {
      // Private only for moderators with PIN
      if (!feedback.exists || !await visibleTo(feedback, author)) continue;
      items.push({ ...item(feedback), role: docs[i].get("reason") });
    }
    // Short pages still move the cursor
    return { items, cursor: page.nextCursor === null || parents.length === 0 ? null : parents[parents.length - 1].id };
  });
}

export const mine = forPlayer(mineOf);
