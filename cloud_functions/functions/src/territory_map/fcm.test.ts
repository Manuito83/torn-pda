import { test } from "node:test";
import * as assert from "node:assert/strict";
import * as admin from "firebase-admin";
import { AlertMessage, buildFcmMessages } from "./fcm";

function message(key: string): AlertMessage {
  return {
    key, topics: ["tmap.f.14821.war", "tmap.f.26312.war", "tmap.t.RCD.war"], kind: "assault_started",
    title: "Assault on RCD", body: "Envy is attacking RCD", territory: "RCD", factionId: "26312", warId: "46843",
  };
}

const collapse = (m: admin.messaging.Message) => [
  (m as admin.messaging.TopicMessage).android?.notification?.tag,
  (m as admin.messaging.TopicMessage).apns?.headers?.["apns-collapse-id"],
];

test("fcm: one alert to several topics collapses into one notification", () => {
  const out = buildFcmMessages([message("war:46843:start"), message("war:46843:end")], 0);
  assert.deepEqual(out.map(collapse), [
    ...Array(3).fill(["war:46843:start", "war:46843:start"]),
    ...Array(3).fill(["war:46843:end", "war:46843:end"]),
  ]);
});

test("fcm: a key over 64 bytes still gives a valid APNs collapse id", () => {
  const [tag, id] = collapse(buildFcmMessages([message("k".repeat(200))], 0)[0]);
  assert.equal(Buffer.byteLength(id as string), 64);
  assert.equal(tag, id);
});
