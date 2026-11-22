import { logger } from "firebase-functions/v2";
import * as admin from "firebase-admin";
import { createHash } from "crypto";

export const CHANNEL_ID = "Alerts territory";
const COLOR = "#7B1FA2";
// FCM sendEach limit
const SEND_CHUNK = 500;
const TTL_MS = 30 * 60 * 1000;
const COLLAPSE_BYTES = 64;

export const TOPIC_REGEX = /^tmap\.(f\.[0-9]+|t\.[A-Z]{3})\.(war|ending|owner|racket)$/;

export interface AlertMessage {
  key: string;
  topics: string[];
  kind: string;
  title: string;
  body: string;
  territory: string;
  factionId: string;
  warId: string;
}

export type Sender = (messages: admin.messaging.Message[]) => Promise<admin.messaging.BatchResponse>;

// APNs allows 64 bytes
export function collapseId(key: string): string {
  return Buffer.byteLength(key) <= COLLAPSE_BYTES ? key : createHash("sha256").update(key).digest("hex");
}

// One FCM message per (message, topic)
export function buildFcmMessages(messages: AlertMessage[], nowMs: number): admin.messaging.Message[] {
  const expirySeconds = Math.floor((nowMs + TTL_MS) / 1000);
  const out: admin.messaging.Message[] = [];
  for (const m of messages) {
    // same key, one notification on the phone
    const collapse = collapseId(m.key);
    for (const topic of m.topics) {
      out.push({
        topic,
        notification: { title: m.title, body: m.body },
        android: {
          priority: "high",
          ttl: TTL_MS,
          notification: {
            channelId: CHANNEL_ID,
            icon: "notification_icon",
            color: COLOR,
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
            sound: "default",
            tag: collapse,
          },
        },
        apns: {
          headers: { "apns-priority": "10", "apns-expiration": String(expirySeconds), "apns-collapse-id": collapse },
          payload: { aps: { sound: "default" } },
        },
        data: {
          channelId: CHANNEL_ID,
          title: m.title,
          body: m.body,
          kind: m.kind,
          territory: m.territory,
          faction_id: m.factionId,
          war_id: m.warId,
        },
      });
    }
  }
  return out;
}

export async function sendAll(fcm: admin.messaging.Message[], send: Sender, label: string) {
  let sent = 0;
  let failed = 0;
  for (let i = 0; i < fcm.length; i += SEND_CHUNK) {
    const chunk = fcm.slice(i, i + SEND_CHUNK);
    try {
      const result = await send(chunk);
      sent += result.successCount;
      failed += result.failureCount;
      result.responses.forEach((r, j) => {
        if (!r.success) {
          const topic = (chunk[j] as { topic?: string }).topic;
          logger.error(`${label}: send to ${topic} failed`, r.error?.code, r.error?.message);
        }
      });
    } catch (error) {
      failed += chunk.length;
      logger.error(`${label}: sendEach threw`, error);
    }
  }
  return { sent, failed };
}
