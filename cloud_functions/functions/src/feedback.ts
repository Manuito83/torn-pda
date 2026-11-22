import { onCall, HttpsError, CallableOptions, CallableRequest } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import * as admin from "firebase-admin";
import { returnRateLimitSlot, takeRateLimitSlot } from "./rate_limit";
import { aDayInMilliseconds, anHourInMilliseconds } from "./time";
import { allSubsRef, subscribersOf, subscription } from "./feedback_notifications";
import { touchUser } from "./feedback_users";
import { Author, actsAsModerator, asModerator, findAuthor, isModerator, requireAuthor } from "./feedback_author";
import { cleanText, docId, invalid, notFound } from "./feedback_input";

export const OPTIONS = { region: "us-east4", timeoutSeconds: 60 };
export const MAX_IDS_PER_CALL = 50;
const VISIBLE_CHAR = /[\p{L}\p{N}]/u;
const DISCORD_URL = /^https:\/\/(ptb\.|canary\.)?discord(app)?\.com\/channels\/\d{1,20}\/\d{1,20}(\/\d{1,20})?$/;
const TYPES = ["suggestion", "bug"];
export const STATUSES = ["open", "planned", "started", "completed", "declined", "duplicate"];

export type Slot = [id: string, limit: number, windowMs: number];

export const feedbackRef = () => admin.firestore().collection("feedback");
export const privateRef = (feedbackId: string) => admin.firestore().collection("feedback_private").doc(feedbackId);
export const configRef = () => admin.firestore().collection("feedback_meta").doc("config");
export const counterRef = () => admin.firestore().collection("feedback_meta").doc("counter");

export function byNumber(number: number) {
  return feedbackRef().where("number", "==", number).limit(1).get();
}

// Exactly one of feedbackId or number
export async function feedbackIdOf(data: any): Promise<string> {
  const { feedbackId, number } = data;
  if ((feedbackId === undefined) === (number === undefined)) invalid("feedbackId or number");
  if (number === undefined) return docId(feedbackId, "feedbackId");
  if (!Number.isSafeInteger(number) || number < 1) invalid("number");
  const found = await byNumber(number);
  return found.empty ? notFound() : found.docs[0].id;
}

export function signedIn(request: CallableRequest): string {
  if (!request.auth) throw new HttpsError("unauthenticated", "The user is not authenticated");
  return request.auth.uid;
}

export function isPublic(feedback: admin.firestore.DocumentSnapshot) {
  return feedback.exists && feedback.get("visibility") === "public";
}

export async function visibleTo(feedback: admin.firestore.DocumentSnapshot, viewer?: Author) {
  return isPublic(feedback) || (feedback.exists && await actsAsModerator(viewer));
}

// Slots go back if the write fails
export async function withSlots<T>(slots: Slot[], write: () => Promise<T>): Promise<T> {
  const taken: { id: string; windowStart: number; windowMs: number }[] = [];
  try {
    for (const [id, limit, windowMs] of slots) {
      const windowStart = await takeRateLimitSlot(id, limit, windowMs);
      if (windowStart === undefined) throw new HttpsError("resource-exhausted", "Too many requests");
      taken.push({ id, windowStart, windowMs });
    }
    return await write();
  } catch (e) {
    await Promise.all(taken.map(({ id, windowStart, windowMs }) => returnRateLimitSlot(id, windowStart, windowMs)
      .catch((error) => logger.warn(`Feedback: slot ${id} not returned: ${error}`))));
    throw e;
  }
}

// Callables resolve the player from the session
export function forPlayer(handler: (author: Author, data: any, uid: string) => Promise<unknown>,
  options: CallableOptions = OPTIONS) {
  return onCall(options, async (request) => {
    const uid = signedIn(request);
    const author = await requireAuthor(uid);
    const touched = touchUser(author.playerId, "app");
    try {
      return await handler(author, request.data ?? {}, uid);
    } finally {
      await touched;
    }
  });
}

export async function createFeedback(actor: Author, data: any) {
  const title = cleanText(data.title, 3, 120, false);
  if (title === undefined || !VISIBLE_CHAR.test(title)) invalid("title");
  const body = cleanText(data.body ?? "", 0, 4000, true) ?? invalid("body");
  const type: string = TYPES.includes(data.type ?? "suggestion") ? data.type ?? "suggestion" : invalid("type");
  let source: { kind: string; url: string; excerpt: string } | undefined;
  if (data.source !== undefined) {
    const { kind, url, excerpt } = data.source ?? {};
    if (type !== "bug" || kind !== "discord" || typeof url !== "string" || !DISCORD_URL.test(url)) invalid("source");
    source = { kind, url, excerpt: cleanText(excerpt ?? "", 0, 1000, true) ?? invalid("source excerpt") };
  }
  if (type === "bug") await asModerator(actor);
  const ref = feedbackRef().doc();
  const write = () => admin.firestore().runTransaction(async (t) => {
    const last = (await t.get(counterRef())).get("last");
    if (!Number.isSafeInteger(last)) throw new HttpsError("internal", "Counter missing");
    const number: number = last + 1;
    t.set(counterRef(), { last: number });
    const now = admin.firestore.Timestamp.now();
    t.create(ref, {
      number,
      title,
      body,
      type,
      visibility: type === "bug" ? "private" : "public",
      status: "open",
      tags: [],
      authorName: actor.name,
      authorPlayerId: actor.playerId,
      ...(type === "bug" ? { createdByPlayerId: actor.playerId } : {}),
      votesCount: 0,
      commentsCount: 0,
      createdAt: now,
      updatedAt: now,
      lastActivityAt: now,
    });
    // Discord links stay out of public docs
    if (source !== undefined) t.create(privateRef(ref.id), { source });
    t.create(subscribersOf(ref).doc(`${actor.playerId}`), subscription("author", actor.playerId));
    return number;
  });
  // Moderators file bugs without limits
  const number = type === "bug" ? await write() : await withSlots([
    [`feedback_create_h_${actor.playerId}`, 3, anHourInMilliseconds],
    [`feedback_create_d_${actor.playerId}`, 10, aDayInMilliseconds],
  ], write);
  logger.info(`Feedback #${number} ${ref.id} (${type}) created by ${actor.name} [${actor.playerId}]`);
  return { feedbackId: ref.id, number };
}

export async function castVote(author: Author, data: any) {
  const wanted = data.vote;
  if (typeof wanted !== "boolean") invalid("vote");
  return withSlots([[`feedback_vote_${author.playerId}`, 60, anHourInMilliseconds]], async () => {
    const feedbackId = await feedbackIdOf(data);
    const ref = feedbackRef().doc(feedbackId);
    const voteRef = ref.collection("votes").doc(`${author.playerId}`);
    return admin.firestore().runTransaction(async (t) => {
      const [feedback, current] = await t.getAll(ref, voteRef);
      if (!await visibleTo(feedback, author)) notFound();
      const before: number = feedback.get("votesCount") ?? 0;
      let votesCount = before;
      if (wanted && !current.exists) {
        t.create(voteRef, { createdAt: admin.firestore.Timestamp.now() });
        votesCount++;
      } else if (!wanted && current.exists) {
        t.delete(voteRef);
        votesCount = Math.max(0, votesCount - 1);
      }
      if (votesCount !== before) t.update(ref, { votesCount });
      return { votesCount, voted: wanted };
    });
  });
}

export async function stateOf(author: Author, data: any) {
  const ids = data.feedbackIds ?? [];
  if (!Array.isArray(ids) || ids.length > MAX_IDS_PER_CALL) invalid("feedbackIds");
  const feedbackIds = ids.map((id: unknown) => docId(id, "feedbackIds"));
  const player = `${author.playerId}`;
  const own = (name: string) => feedbackIds.map((id: string) => feedbackRef().doc(id).collection(name).doc(player));
  const refs = [...own("votes"), ...own("subscribers")];
  const [docs, moderator, all] = await Promise.all([
    refs.length === 0 ? [] : admin.firestore().getAll(...refs),
    actsAsModerator(author),
    allSubsRef().doc(player).get(),
  ]);
  const parentId = (doc: admin.firestore.DocumentSnapshot) => doc.ref.parent.parent.id;
  const subscribed = docs.slice(feedbackIds.length).filter((doc) => doc.exists);
  return {
    canWrite: true,
    playerId: author.playerId,
    playerName: author.name,
    isModerator: moderator,
    votedIds: docs.slice(0, feedbackIds.length).filter((doc) => doc.exists).map(parentId),
    subscribedIds: subscribed.map(parentId),
    // Authors can never unsubscribe
    lockedIds: subscribed.filter((doc) => doc.get("reason") === "author").map(parentId),
    subscribedToAll: all.exists,
  };
}

export const create = forPlayer(createFeedback);
export const vote = forPlayer(castVote);

// Never calls Torn; app asks PIN
export const myState = onCall(OPTIONS, async (request) => {
  const author = await findAuthor(signedIn(request), false);
  if (typeof author !== "string") {
    return { ...await stateOf(author, request.data ?? {}), isModerator: await isModerator(author.playerId),
      modUnlockedUntil: author.modUntil ?? null };
  }
  const none: string[] = [];
  return { canWrite: false, reason: author, isModerator: false, modUnlockedUntil: null as number | null, votedIds: none,
    subscribedIds: none, lockedIds: none, subscribedToAll: false };
});
