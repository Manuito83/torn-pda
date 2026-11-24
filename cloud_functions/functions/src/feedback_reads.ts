import { HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { MAX_IDS_PER_CALL, STATUSES, byNumber, configRef, feedbackIdOf, feedbackRef, forPlayer, isPublic, privateRef, visibleTo, withSlots, Slot } from "./feedback";
import { anHourInMilliseconds } from "./time";
import { Author, actsAsModerator } from "./feedback_author";
import { docId, invalid, notFound } from "./feedback_input";

const DEFAULT_PAGE = 20;
const LISTED = ["open", "planned", "started", "completed", "declined"];
const ORDERS = new Map([["votes", "votesCount"], ["recent", "createdAt"], ["activity", "lastActivityAt"]]);

// Timestamps as milliseconds for clients
export function plain(value: any): any {
  if (value instanceof admin.firestore.Timestamp) return value.toMillis();
  if (Array.isArray(value)) return value.map(plain);
  if (value !== null && typeof value === "object") {
    return Object.fromEntries(Object.entries(value).map(([key, inner]) => [key, plain(inner)]));
  }
  return value;
}

export const item = (doc: admin.firestore.DocumentSnapshot) => ({ id: doc.id, ...plain(doc.data()) });

// Cursor is the last document id
export async function pageOf(collection: { doc(id: string): admin.firestore.DocumentReference }, query: admin.firestore.Query,
  limit: unknown, cursor: unknown) {
  const size = limit ?? DEFAULT_PAGE;
  if (!Number.isSafeInteger(size) || (size as number) < 1 || (size as number) > MAX_IDS_PER_CALL) invalid("limit");
  if (cursor !== undefined) {
    const start = await collection.doc(docId(cursor, "cursor")).get();
    if (!start.exists) invalid("cursor");
    query = query.startAfter(start);
  }
  const page = await query.limit(size as number).get();
  return { docs: page.docs, nextCursor: page.size === size ? page.docs[page.size - 1].id : null };
}

export async function listFeedback(actor: Author | undefined, data: any) {
  const order = ORDERS.get(data.order ?? "votes") ?? invalid("order");
  let statuses = data.status === undefined ? LISTED : [STATUSES.includes(data.status) ? data.status : invalid("status")];
  if (data.statuses !== undefined) {
    if (data.status !== undefined) invalid("statuses");
    const valid = Array.isArray(data.statuses) && data.statuses.length > 0 && data.statuses.length <= STATUSES.length &&
      data.statuses.every((status: unknown) => STATUSES.includes(status as any));
    statuses = valid ? [...new Set(data.statuses as string[])] : invalid("statuses");
  }
  const tag = data.tag === undefined ? undefined : docId(data.tag, "tag");
  if (![undefined, true, false].includes(data.includePrivate)) invalid("includePrivate");
  if (data.includePrivate && !await actsAsModerator(actor)) {
    throw new HttpsError("permission-denied", "Not a moderator");
  }
  if (data.search !== undefined) {
    const found = /^#?(\d{1,9})$/.exec(typeof data.search === "string" ? data.search.trim() : "") ?? invalid("search");
    const hit = await byNumber(Number(found[1]));
    const seen = await Promise.all(hit.docs.map(async (doc) => isPublic(doc) || (data.includePrivate === true && await visibleTo(doc, actor))));
    return { items: hit.docs.filter((_, i) => seen[i]).map(item), cursor: null };
  }
  let query = feedbackRef()
    .where("visibility", "in", data.includePrivate ? ["public", "private"] : ["public"])
    .where("status", "in", statuses);
  if (tag !== undefined) query = query.where("tags", "array-contains", tag);
  const { docs, nextCursor } = await pageOf(feedbackRef(), query.orderBy(order, "desc"), data.limit, data.cursor);
  return { items: docs.map(item), cursor: nextCursor };
}

export async function getFeedback(actor: Author | undefined, data: any) {
  const feedback = await feedbackRef().doc(await feedbackIdOf(data)).get();
  if (!await visibleTo(feedback, actor)) notFound();
  return { feedback: item(feedback) };
}

export async function listComments(actor: Author | undefined, data: any) {
  if (data.limit !== undefined && (!Number.isSafeInteger(data.limit) || data.limit < 1 || data.limit > MAX_IDS_PER_CALL)) invalid("limit");
  if (data.cursor !== undefined) docId(data.cursor, "cursor");
  const ref = feedbackRef().doc(await feedbackIdOf(data));
  if (!await visibleTo(await ref.get(), actor)) notFound();
  const comments = ref.collection("comments");
  const { docs, nextCursor } = await pageOf(comments, comments.orderBy("createdAt", "asc"), data.limit, data.cursor);
  return { items: docs.map(item), cursor: nextCursor };
}

// Bugs and reports, caller checks moderator
export async function listPrivateBugs(data: any) {
  const query = feedbackRef().where("visibility", "in", ["private", "report"]).orderBy("createdAt", "desc");
  const { docs, nextCursor } = await pageOf(feedbackRef(), query, data.limit, data.cursor);
  const extras = docs.length === 0 ? [] : await admin.firestore().getAll(...docs.map((doc) => privateRef(doc.id)));
  return { items: docs.map((doc, i) => ({ ...item(doc), ...plain(extras[i].data() ?? {}) })), cursor: nextCursor };
}

// App reads, inside the slot
const readSlot = (author: Author) => [[`feedback_read_${author.playerId}`, 300, anHourInMilliseconds]] as Slot[];
export const get = forPlayer((author, data) => withSlots(readSlot(author), () => getFeedback(author, data)));
export const comments = forPlayer((author, data) => withSlots(readSlot(author), () => listComments(author, data)));

export async function readConfig() {
  return { tags: (await configRef().get()).get("tags") ?? [] };
}
