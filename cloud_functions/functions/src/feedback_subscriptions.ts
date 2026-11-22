import { HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { allSubsRef, subscribersOf, subscription } from "./feedback_notifications";
import { anHourInMilliseconds } from "./time";
import { feedbackIdOf, feedbackRef, forPlayer, visibleTo, withSlots } from "./feedback";
import { Author } from "./feedback_author";
import { invalid, notFound } from "./feedback_input";

export async function subscribeTo(author: Author, data: any) {
  const on = data.on;
  if (typeof on !== "boolean") invalid("on");
  return withSlots([[`feedback_subscribe_${author.playerId}`, 60, anHourInMilliseconds]], async () => {
    const ref = feedbackRef().doc(await feedbackIdOf(data));
    const subRef = subscribersOf(ref).doc(`${author.playerId}`);
    return admin.firestore().runTransaction(async (t) => {
      const [feedback, current] = await t.getAll(ref, subRef);
      if (!await visibleTo(feedback, author)) notFound();
      if (on && !current.exists) t.create(subRef, subscription("manual", author.playerId));
      if (!on && current.exists) {
        if (current.get("reason") === "author") throw new HttpsError("permission-denied", "Authors stay subscribed");
        t.delete(subRef);
      }
      return { subscribed: on };
    });
  });
}

export async function subscribeToAll(author: Author, data: any) {
  const on = data.on;
  if (typeof on !== "boolean") invalid("on");
  const ref = allSubsRef().doc(`${author.playerId}`);
  return withSlots([[`feedback_subscribe_all_${author.playerId}`, 60, anHourInMilliseconds]], async () => {
    if (!on) await ref.delete();
    else if (!(await ref.get()).exists) await ref.set({ since: admin.firestore.Timestamp.now() });
    return { subscribed: on };
  });
}

export const subscribe = forPlayer(subscribeTo);
export const subscribeAll = forPlayer(subscribeToAll);
