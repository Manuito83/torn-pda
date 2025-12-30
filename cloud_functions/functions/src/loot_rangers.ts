import { onSchedule } from "firebase-functions/v2/scheduler";
import { logger } from "firebase-functions/v2";
import * as admin from "firebase-admin";
import { sendNotificationToUser } from "./notification";

const LOOT_RANGERS_DEFAULT_AHEAD = 180; // seconds (3 minutes)
const LOOT_RANGERS_BUCKETS = [180, 360, 600, 900, 1200];

export const sendLootRangersNotification = onSchedule({
  schedule: "*/2 * * * *",
  region: 'us-east4',
  memory: "512MiB",
  timeoutSeconds: 540
}, async () => {

  const promises: Promise<any>[] = [];

  const firebaseAdmin = require("firebase-admin");
  const db = firebaseAdmin.database();

  async function getLootRangersApi() {
    const response = await fetch(`https://api.lzpt.io/loot`);
    return response.json();
  }

  try {
    const currentDateInSeconds = Date.now() / 1000;
    const maxBucket = Math.max(...LOOT_RANGERS_BUCKETS);
    const nextWindow = currentDateInSeconds + maxBucket;

    // Get LootRangers last timestamp
    const lrJson = await getLootRangersApi();
    const nextAttackLR = lrJson.time.clear;

    let timeString = "";
    const date = new Date(nextAttackLR * 1000);
    const hours = date.getUTCHours().toString().padStart(2, '0');
    const minutes = date.getUTCMinutes().toString().padStart(2, '0');
    timeString = `${hours}:${minutes}`;
    console.log(`Next attack at ${timeString}`);

    // Return if we have no time or if it has already passed
    if (nextAttackLR < currentDateInSeconds) {
      console.log("Attack is in the past!");
      return;
    }
    if (nextAttackLR === 0) {
      console.log("Attack not set (ts = 0)!");
      return;
    }

    // Return if we are not inside of the largest bucket window
    if (nextWindow - nextAttackLR > maxBucket || nextWindow - nextAttackLR < 0) {
      console.log("Not inside alert window!");
      return;
    }

    // Read bucket map for this attack
    // Per-attack: one entry per bucket (seconds) marked with this attack ts once sent
    const refBuckets = db.ref(`lootRangers/lastAlertedBuckets/${nextAttackLR}`);
    let bucketMap: Record<string, number> = {};
    await refBuckets.once("value", function (snapshot) {
      bucketMap = snapshot.val() ?? {};
    });

    const pendingBuckets = LOOT_RANGERS_BUCKETS.filter((bucket) => {
      const sentForThis = bucketMap[bucket] === nextAttackLR;
      const inWindow = currentDateInSeconds >= nextAttackLR - bucket;
      return inWindow && !sentForThis;
    });

    if (pendingBuckets.length === 0) {
      console.log("No buckets pending, exit.");
      return;
    }

    // Get the list of subscribers (single query)
    const response = await admin
      .firestore()
      .collection("players")
      .where("active", "==", true)
      .where("lootRangersNotification", "==", true)
      .get();

    const subscribers = response.docs.map((d) => d.data());

    console.log("Sending Loot Rangers to: " + subscribers.length + " users");

    // Build name order
    const orderArray = [];
    const npcArray = lrJson.order;
    for (const id of npcArray) {
      // If [clear] is false, the NPC won't participate in this attack
      if (lrJson.npcs[id].clear) {
        orderArray.push(`${lrJson.npcs[id].name}[${id}]`);
      }
    }

    if (orderArray.length === 0) {
      console.log("No NPCs cleared to attack!");
      return;
    }

    const fullTitle = `Loot Rangers attack shortly: ${timeString} TCT!`;
    console.log(fullTitle);

    const fullSubtitle = `Attack order: ${orderArray.join(', ')}`;
    console.log(fullSubtitle);

    const discreetTitle = "LR";
    const discreetSubtitle = "";

    const attackTime = `${hours}:${minutes}`;

    for (const key of Array.from(subscribers.keys())) {
      const sub = subscribers[key];
      const ahead = typeof sub.lootRangersAheadSeconds === "number" ? sub.lootRangersAheadSeconds : LOOT_RANGERS_DEFAULT_AHEAD;

      if (!pendingBuckets.includes(ahead)) {
        continue;
      }

      promises.push(
        sendNotificationToUser({
          token: sub.token,
          title: sub.discrete ? discreetTitle : fullTitle,
          body: sub.discrete ? discreetSubtitle : fullSubtitle,
          icon: "notification_loot",
          color: "#FF0000",
          channelId: "Alerts loot",
          assistId: orderArray.join(","),
          bulkDetails: attackTime,
          vibration: sub.vibration,
          sound: "sword_clash.aiff"
        }).catch((e) => {
          logger.warn(`ERROR LOOT RANGERS SEND for ${sub.uid}\n${e}`);
        })
      );

      bucketMap[ahead] = nextAttackLR;
    }

    // Persist dedupe map after processing
    promises.push(refBuckets.set(bucketMap));

    await Promise.all(promises);

  } catch (e) {
    logger.warn(`ERROR LOOT RANGERS GENERAL CATCH: ${e}`);
  }

});  