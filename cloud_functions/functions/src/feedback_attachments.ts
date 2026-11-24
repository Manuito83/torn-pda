import { HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { aDayInMilliseconds, anHourInMilliseconds } from "./time";
import { MAX_IDS_PER_CALL, Slot, feedbackIdOf, feedbackRef, forPlayer, visibleTo, withSlots } from "./feedback";
import { Author, actsAsModerator } from "./feedback_author";
import { cleanText, docId, invalid, notFound } from "./feedback_input";
import { plain } from "./feedback_reads";
import { deleteObjects, signDownload, signUpload, statObject } from "./feedback_storage";

const MB = 1024 * 1024;
const MAX_ATTACHMENTS = 5;
const MAX_IMAGE_BYTES = 10 * MB;
const MAX_VIDEO_BYTES = 50 * MB;
const UPLOADS_PER_HOUR = 15;
const IMAGES_PER_DAY = 30;
const VIDEOS_PER_DAY = 4;
const UPLOAD_VALID_MS = anHourInMilliseconds / 4;
const LINK_VALID_MS = anHourInMilliseconds / 4;
const TICKET_TTL_MS = 2 * anHourInMilliseconds;

const bytesAre = (head: Buffer, bytes: number[], at = 0) => bytes.every((byte, i) => head[at + i] === byte);
const ascii = (text: string) => [...text].map((char) => char.charCodeAt(0));

// First bytes must match the type
const ALLOWED = new Map<string, { video: boolean; ext: string; matches: (head: Buffer) => boolean }>([
  ["image/png", { video: false, ext: "png", matches: (head) => bytesAre(head, [0x89, 0x50, 0x4e, 0x47]) }],
  ["image/jpeg", { video: false, ext: "jpg", matches: (head) => bytesAre(head, [0xff, 0xd8, 0xff]) }],
  ["image/webp", { video: false, ext: "webp", matches: (head) => bytesAre(head, ascii("RIFF")) && bytesAre(head, ascii("WEBP"), 8) }],
  ["image/gif", { video: false, ext: "gif", matches: (head) => bytesAre(head, ascii("GIF8")) }],
  ["video/mp4", { video: true, ext: "mp4", matches: (head) => bytesAre(head, ascii("ftyp"), 4) }],
  ["video/quicktime", { video: true, ext: "mov", matches: (head) => bytesAre(head, ascii("ftyp"), 4) }],
  ["video/webm", { video: true, ext: "webm", matches: (head) => bytesAre(head, [0x1a, 0x45, 0xdf, 0xa3]) }],
]);

type Snapshot = admin.firestore.DocumentSnapshot;

// Pending uploads, closed to clients
export const ticketsRef = () => admin.firestore().collection("feedback_uploads");

function tooMany(): never {
  throw new HttpsError("failed-precondition", "Too many attachments", { reason: "too_many_attachments" });
}

// Item or comment, if visible
async function targetOf(viewer: Author | undefined, feedbackId: string, commentId?: string) {
  const feedback = await feedbackRef().doc(feedbackId).get();
  if (!await visibleTo(feedback, viewer)) notFound();
  const target = commentId === undefined ? feedback : await feedback.ref.collection("comments").doc(commentId).get();
  if (!target.exists) notFound();
  return target;
}

function mustBeAuthor(author: Author, target: Snapshot) {
  if (target.get("authorPlayerId") !== author.playerId) throw new HttpsError("permission-denied", "Not yours");
}

const optionalCommentId = (data: any) => data.commentId === undefined ? undefined : docId(data.commentId, "commentId");

export async function requestAttachment(author: Author, data: any) {
  const contentType: string = typeof data.contentType === "string" ? data.contentType : invalid("contentType");
  const allowed = ALLOWED.get(contentType) ?? invalid("contentType");
  const size = data.size;
  if (!Number.isSafeInteger(size) || size < 1 || size > (allowed.video ? MAX_VIDEO_BYTES : MAX_IMAGE_BYTES)) invalid("size");
  const name = data.name === undefined ? `${allowed.video ? "video" : "image"}.${allowed.ext}`
    : cleanText(data.name, 1, 100, false) ?? invalid("name");
  const commentId = optionalCommentId(data);
  const kind = allowed.video ? "video" : "image";
  const slots: Slot[] = [
    [`feedback_attach_h_${author.playerId}`, UPLOADS_PER_HOUR, anHourInMilliseconds],
    [`feedback_attach_${kind}_d_${author.playerId}`, allowed.video ? VIDEOS_PER_DAY : IMAGES_PER_DAY, aDayInMilliseconds],
  ];
  return withSlots(slots, async () => {
    const feedbackId = await feedbackIdOf(data);
    const target = await targetOf(author, feedbackId, commentId);
    mustBeAuthor(author, target);
    const key = commentId === undefined ? feedbackId : `${feedbackId}/${commentId}`;
    const now = Date.now();
    const pending = (await ticketsRef().where("target", "==", key).get()).docs.filter((doc) => doc.get("createdAt").toMillis() > now - UPLOAD_VALID_MS);
    if ((target.get("attachments") ?? []).length + pending.length >= MAX_ATTACHMENTS) tooMany();
    const ticket = ticketsRef().doc();
    await ticket.create({
      playerId: author.playerId,
      feedbackId,
      commentId: commentId ?? null,
      target: key,
      contentType,
      size,
      name,
      createdAt: admin.firestore.Timestamp.fromMillis(now),
      expireAt: admin.firestore.Timestamp.fromMillis(now + TICKET_TTL_MS),
    });
    const { url, headers } = await signUpload(feedbackId, ticket.id, contentType, size, UPLOAD_VALID_MS);
    return { attachmentId: ticket.id, uploadUrl: url, method: "PUT", headers, expiresAt: now + UPLOAD_VALID_MS };
  });
}

// Single use: confirming spends it
export async function confirmAttachment(author: Author, data: any) {
  const attachmentId = docId(data.attachmentId, "attachmentId");
  const ticketRef = ticketsRef().doc(attachmentId);
  const ticket = await ticketRef.get();
  if (!ticket.exists || ticket.get("playerId") !== author.playerId) notFound();
  const { feedbackId, commentId, contentType, size, name } = ticket.data() as any;
  const discard = () => Promise.all([deleteObjects(feedbackId, [attachmentId]), ticketRef.delete()]);
  if (ticket.get("expireAt").toMillis() <= Date.now()) {
    await discard();
    throw new HttpsError("failed-precondition", "Upload expired", { reason: "expired" });
  }
  const stored = await statObject(feedbackId, attachmentId);
  if (stored === undefined) throw new HttpsError("failed-precondition", "Not uploaded", { reason: "not_uploaded" });
  if (stored.size !== size || stored.contentType !== contentType || !ALLOWED.get(contentType)?.matches(stored.head)) {
    await discard();
    invalid("attachment");
  }
  const attachment = { id: attachmentId, name, contentType, size, at: admin.firestore.Timestamp.now() };
  // Spent ticket: object already in use
  let spent = false;
  try {
    await admin.firestore().runTransaction(async (t) => {
      const targetRef = commentId === null ? feedbackRef().doc(feedbackId) : feedbackRef().doc(feedbackId).collection("comments").doc(commentId);
      const [current, target, item] = await t.getAll(ticketRef, targetRef, feedbackRef().doc(feedbackId));
      spent = !current.exists;
      if (spent || !target.exists || !await visibleTo(item, author)) notFound();
      mustBeAuthor(author, target);
      const attachments: unknown[] = target.get("attachments") ?? [];
      if (attachments.length >= MAX_ATTACHMENTS) tooMany();
      t.update(targetRef, { attachments: [...attachments, attachment] });
      t.delete(ticketRef);
    });
  } catch (e) {
    if (e instanceof HttpsError && !spent) await discard();
    throw e;
  }
  return { feedbackId, ...(commentId === null ? {} : { commentId }), attachment: plain(attachment) };
}

// Author or a moderator who sees it
export async function deleteAttachment(author: Author, data: any) {
  const attachmentId = docId(data.attachmentId, "attachmentId");
  const commentId = optionalCommentId(data);
  const feedbackId = await feedbackIdOf(data);
  const moderator = await actsAsModerator(author);
  const locate = async (t: admin.firestore.Transaction) => {
    const itemRef = feedbackRef().doc(feedbackId);
    const [feedback, comment] = await t.getAll(itemRef, ...(commentId === undefined ? [] : [itemRef.collection("comments").doc(commentId)]));
    const target = comment ?? feedback;
    if (!await visibleTo(feedback, author) || !target.exists) notFound();
    if (!moderator) mustBeAuthor(author, target);
    const attachments: { id: string }[] = target.get("attachments") ?? [];
    if (!attachments.some((attachment) => attachment.id === attachmentId)) notFound();
    return { target, attachments };
  };
  await admin.firestore().runTransaction(async (t) => { await locate(t); });
  await deleteObjects(feedbackId, [attachmentId]);
  await admin.firestore().runTransaction(async (t) => {
    const { target, attachments } = await locate(t);
    t.update(target.ref, { attachments: attachments.filter((attachment) => attachment.id !== attachmentId) });
  });
  return { feedbackId };
}

// Short lived links for item and comments
export async function attachmentLinks(actor: Author | undefined, data: any) {
  const ids = data.commentIds ?? [];
  if (!Array.isArray(ids) || ids.length > MAX_IDS_PER_CALL) invalid("commentIds");
  const commentIds = ids.map((id: unknown) => docId(id, "commentIds"));
  const ref = feedbackRef().doc(await feedbackIdOf(data));
  const commentRefs = commentIds.map((id: string) => ref.collection("comments").doc(id));
  const [feedback, ...comments] = await admin.firestore().getAll(ref, ...commentRefs);
  if (!await visibleTo(feedback, actor)) notFound();
  const expiresAt = Date.now() + LINK_VALID_MS;
  const linked = (target: Snapshot) => Promise.all(((target.get("attachments") ?? []) as { id: string }[]).map(async (attachment) =>
    ({ ...plain(attachment), url: await signDownload(ref.id, attachment.id, LINK_VALID_MS), expiresAt })));
  const existing = comments.filter((comment) => comment.exists);
  const lists = await Promise.all(existing.map(linked));
  return { attachments: await linked(feedback), comments: Object.fromEntries(existing.map((comment, i) => [comment.id, lists[i]])) };
}

export const attachmentRequest = forPlayer(requestAttachment);
export const attachmentConfirm = forPlayer((author, data) =>
  withSlots([[`feedback_confirm_${author.playerId}`, 30, anHourInMilliseconds]], () => confirmAttachment(author, data)));
export const attachmentDelete = forPlayer(deleteAttachment);
export const attachmentUrls = forPlayer((author, data) =>
  withSlots([[`feedback_links_${author.playerId}`, 300, anHourInMilliseconds]], () => attachmentLinks(author, data)));
