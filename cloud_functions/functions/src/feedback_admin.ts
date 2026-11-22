import * as admin from "firebase-admin";
import { aDayInMilliseconds } from "./time";
import { feedbackRef } from "./feedback";
import { Author, modsRef } from "./feedback_author";
import { deny } from "./feedback_input";
import { pinRef } from "./feedback_pin_hash";
import { usersRef } from "./feedback_users";

const LOG_DAYS = 7;
// Each document read is billed
const LOG_DOCS_READ = 5000;

// Set by alta-moderador only, never by clients
export async function isOwner(author?: Author): Promise<boolean> {
  return author !== undefined && !author.asPlayer && (await modsRef().doc(`${author.playerId}`).get()).get("owner") === true;
}

export async function requireOwner(author: Author) {
  if (!await isOwner(author)) deny("owner_only", author);
}

export async function adminMods() {
  const docs = (await modsRef().get()).docs;
  const pins = await admin.firestore().getAll(...docs.map((doc) => pinRef(Number(doc.id))));
  const moderators = docs.map((doc, i) => ({
    playerId: Number(doc.id),
    name: doc.get("name") ?? null,
    owner: doc.get("owner") === true,
    hasPin: pins[i].get("hash") !== undefined,
  }));
  return { moderators: moderators.sort((a, b) => a.playerId - b.playerId) };
}

// Aggregate counts, no documents read
export async function adminStats() {
  const count = async (query: admin.firestore.Query) => (await query.count().get()).data().count;
  const now = Date.now();
  const users = usersRef();
  const active = (days: number) => users.where("lastSeen", ">=", admin.firestore.Timestamp.fromMillis(now - days * aDayInMilliseconds));
  const group = (name: string) => admin.firestore().collectionGroup(name);
  const legacy = (query: admin.firestore.Query) => query.where("legacy", "!=", null);
  const [registered, web, app, bot, active7d, active30d, suggestions, oldSuggestions, comments, oldComments, votes] = await Promise.all([
    count(users), count(users.where("via.web", "==", true)), count(users.where("via.app", "==", true)),
    count(users.where("via.bot", "==", true)), count(active(7)), count(active(30)),
    count(feedbackRef().where("type", "==", "suggestion")), count(legacy(feedbackRef())),
    count(group("comments")), count(legacy(group("comments"))), count(group("votes")),
  ]);
  return {
    users: { registered, web, app, bot, active7d, active30d },
    sinceLaunch: { suggestions: suggestions - oldSuggestions, comments: comments - oldComments, votes },
  };
}

// Counts per day, client, result, reason
export async function adminLogSummary() {
  const now = Date.now();
  const since = now - LOG_DAYS * aDayInMilliseconds;
  const snap = await admin.firestore().collection("feedback_api_log")
    .where("at", ">=", admin.firestore.Timestamp.fromMillis(since)).orderBy("at", "desc")
    .select("at", "client", "result", "reason").limit(LOG_DOCS_READ).get();
  const counts = new Map<string, number>();
  let oldest = now;
  for (const doc of snap.docs) {
    const at: number = doc.get("at").toMillis();
    oldest = Math.min(oldest, at);
    const key = JSON.stringify([new Date(at).toISOString().slice(0, 10), doc.get("client"), doc.get("result"), doc.get("reason") ?? ""]);
    counts.set(key, (counts.get(key) ?? 0) + 1);
  }
  const rows = [...counts].map(([key, count]) => {
    const [day, client, result, reason] = JSON.parse(key);
    return { day, client, result, reason, count };
  }).sort((a, b) => b.day.localeCompare(a.day) || a.client.localeCompare(b.client) || a.result.localeCompare(b.result) ||
    a.reason.localeCompare(b.reason));
  const truncated = snap.size === LOG_DOCS_READ;
  // Older lines were not read
  return { rows, read: snap.size, limit: LOG_DOCS_READ, truncated, since: truncated ? oldest : since };
}
