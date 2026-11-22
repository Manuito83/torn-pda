import { logger } from "firebase-functions/v2";
import * as admin from "firebase-admin";
import { sendNotificationToUser } from "./notification";
import { isDiscreetNow } from "./discreet";
import { aDayInMilliseconds } from "./time";

// Off until the app ships "Alerts feedback"
export const FEEDBACK_PUSH_ENABLED = false;
export const SEND_CONCURRENCY = 10;
const TITLE_LENGTH = 60;
const BODY_LENGTH = 200;
const IDS_PER_QUERY = 30;
const WRITES_PER_BATCH = 500;
const KEEP_INACTIVE_MS = 60 * aDayInMilliseconds;
const EVENT_TTL_MS = 7 * aDayInMilliseconds;
const PLAYER_FIELDS = ["verifiedPlayerId", "token", "active", "lastActive", "vibration", "discrete", "discreetSchedule"];
const STATUS_TEXT: Record<string, string> = {
  open: "reopened",
  planned: "planned",
  started: "started",
  completed: "completed",
  declined: "declined",
  duplicate: "marked as duplicate",
};

type SubscribeReason = "author" | "comment" | "manual";

interface FeedbackPush {
  title: string;
  body: string;
}

type Ref = admin.firestore.DocumentReference;

export const subscribersOf = (feedback: Ref) => feedback.collection("subscribers");
export const allSubsRef = () => admin.firestore().collection("feedback_all_subs");
export const eventsRef = () => admin.firestore().collection("feedback_events");

export function subscription(reason: SubscribeReason, playerId: number) {
  return { since: admin.firestore.Timestamp.now(), reason, playerId };
}

// Status or response change to push
export function feedbackEvent(feedbackId: string, actor: number, status?: string, response?: string) {
  const now = Date.now();
  return {
    type: status === undefined ? "response" : "status",
    feedbackId,
    actorPlayerId: actor,
    ...(status === undefined ? {} : { status }),
    ...(response === undefined ? {} : { response }),
    at: admin.firestore.Timestamp.fromMillis(now),
    expireAt: admin.firestore.Timestamp.fromMillis(now + EVENT_TTL_MS),
  };
}

function shorten(text: string, max: number): string {
  return text.length > max ? `${text.slice(0, max).trimEnd()}...` : text;
}

export function commentPush(feedbackTitle: string, authorName: string, body: string): FeedbackPush {
  return {
    title: `New comment on ${shorten(feedbackTitle, TITLE_LENGTH)}`,
    body: `${authorName}: ${shorten(body, BODY_LENGTH)}`,
  };
}

export function statusPush(feedbackTitle: string, status: string | undefined, response: string | undefined): FeedbackPush {
  return {
    title: `${shorten(feedbackTitle, TITLE_LENGTH)}: ${status === undefined ? "new response" : STATUS_TEXT[status]}`,
    body: response === undefined ? " " : shorten(response, BODY_LENGTH),
  };
}

export function newFeedbackPush(feedbackTitle: string, authorName: string): FeedbackPush {
  return { title: `New feedback: ${shorten(feedbackTitle, TITLE_LENGTH)}`, body: `By ${authorName}` };
}

function pickRecipients(subscribers: number[], general: number[], actor: number,
  moderators: Set<number>, isPrivate: boolean): number[] {
  const ids = new Set([...general, ...subscribers]);
  ids.delete(actor);
  return [...ids].filter((id) => !isPrivate || moderators.has(id));
}

// Every device, active or not
async function playersOf(playerIds: number[]) {
  const players: admin.firestore.DocumentData[] = [];
  for (let i = 0; i < playerIds.length; i += IDS_PER_QUERY) {
    const page = await admin.firestore().collection("players")
      .where("verifiedPlayerId", "in", playerIds.slice(i, i + IDS_PER_QUERY))
      .select(...PLAYER_FIELDS)
      .get();
    players.push(...page.docs.map((doc) => doc.data()));
  }
  return players;
}

async function send(players: admin.firestore.DocumentData[], push: FeedbackPush, feedbackId: string) {
  const reached = new Set<number>();
  let failed = 0;
  for (let i = 0; i < players.length; i += SEND_CONCURRENCY) {
    const batch = players.slice(i, i + SEND_CONCURRENCY);
    const results = await Promise.allSettled(batch.map((player) => {
      const discreet = isDiscreetNow(player);
      return sendNotificationToUser({
        token: player.token,
        title: discreet ? "F" : push.title,
        body: discreet ? " " : push.body,
        icon: "notification_icon",
        color: "#2196F3",
        channelId: "Alerts feedback",
        vibration: player.vibration ?? "",
        extraData: { feedbackId },
      });
    }));
    // Fulfilled null: dead token
    results.forEach((result, j) => {
      if (result.status === "rejected") failed++;
      if (result.status === "rejected" || result.value !== null) reached.add(batch[j].verifiedPlayerId);
    });
  }
  return { reached, failed };
}

async function dropAllSubs(playerIds: number[]) {
  for (let i = 0; i < playerIds.length; i += WRITES_PER_BATCH) {
    const batch = admin.firestore().batch();
    playerIds.slice(i, i + WRITES_PER_BATCH).forEach((id) => batch.delete(allSubsRef().doc(`${id}`)));
    await batch.commit();
  }
}

// Best effort: never throws
export async function notifySubscribers(feedback: Ref, actor: number, isPrivate: boolean, isNew: boolean,
  push: FeedbackPush, moderators: Set<number>) {
  try {
    const modRefs = [...moderators].map((id) => allSubsRef().doc(`${id}`));
    // Players' general only covers new public items
    const [subscribers, general] = await Promise.all([
      subscribersOf(feedback).select().get().then((page) => page.docs),
      isNew && !isPrivate ? allSubsRef().select().get().then((page) => page.docs)
        : modRefs.length === 0 ? [] : admin.firestore().getAll(...modRefs),
    ]);
    const asIds = (docs: admin.firestore.DocumentSnapshot[]) => docs.filter((doc) => doc.exists).map((doc) => Number(doc.id));
    const generalIds = asIds(general);
    const recipients = pickRecipients(asIds(subscribers), generalIds, actor, moderators, isPrivate);
    if (recipients.length === 0) return;
    const players = await playersOf(recipients);
    const { reached, failed } = await send(players.filter((player) => player.active === true), push, feedback.id);
    if (failed > 0) logger.warn(`Feedback ${feedback.id}: ${failed} pushes failed`);
    const since = Date.now() - KEEP_INACTIVE_MS;
    // Recently inactive devices keep it
    const resting = players.filter((player) => player.active !== true && player.lastActive > since);
    const kept = new Set([...reached, ...resting.map((player) => player.verifiedPlayerId)]);
    const isGeneral = new Set(generalIds);
    const dead = recipients.filter((id) => isGeneral.has(id) && !kept.has(id));
    if (dead.length > 0) {
      await dropAllSubs(dead);
      logger.info(`Feedback: dropped general subscription of ${dead.join(", ")}`);
    }
  } catch (e) {
    logger.warn(`Feedback ${feedback.id}: push failed: ${e}`);
  }
}
