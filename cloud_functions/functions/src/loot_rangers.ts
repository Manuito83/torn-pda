import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { sendNotificationToUser } from "./notification";
const fetch = require("node-fetch");

export const lootRangersGroup = {

  sendLootRangersNotification: functions.region('us-east4')
    .pubsub
    .schedule("*/2 * * * *")
    .onRun(async () => {

      const promises: Promise<any>[] = [];

      const firebaseAdmin = require("firebase-admin");
      const db = firebaseAdmin.database();

      async function getLootRangersApi() {
        const response = await fetch(`https://api.lzpt.io/loot`);
        return response.json();
      }

      try {
        const currentDateInSeconds = Date.now() / 1000;
        const timeMargin = 150; // 2,5 minutes-margin in the worst-case scenario
        const nextTwoMinutes = currentDateInSeconds + timeMargin;

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

        // Return if we are not inside of 2 minutes-ish to the attack
        if (nextTwoMinutes - nextAttackLR > timeMargin
          || nextTwoMinutes - nextAttackLR < 0) {
          console.log("Not inside 2.5 minutes!");
          return;
        }

        // Return if we have tried to alert twice
        let lastAlertedTs = 0;
        const refSavedTime = db.ref("lootRangers/lastAlerted");
        await refSavedTime.once("value", function (snapshot) {
          lastAlertedTs = snapshot.val() ?? 0;
        });

        if (lastAlertedTs === nextAttackLR) {
          console.log("Skipping alert, already sent!");
          return;
        }

        // Get the list of subscribers
        const response = await admin
          .firestore()
          .collection("players")
          .where("active", "==", true)
          .where("lootRangersNotification", "==", true)
          .get();

        const subscribers = response.docs.map((d) => d.data());

        console.log("Sending Loot Rangers to: " + subscribers.length + " users");

        // Store our last alerted time
        promises.push(
          db.ref(`lootRangers/lastAlerted`).set(nextAttackLR)
        );

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

        let fullTitle = `Loot Rangers attack shortly: ${timeString} TCT!`;
        console.log(fullTitle);

        let fullSubtitle = `Attack order: ${orderArray.join(', ')}`;
        console.log(fullSubtitle);

        let discreetTitle = "LR";
        let discreetSubtitle = "";

        const attackTime = `${hours}:${minutes}`;

        for (const key of Array.from(subscribers.keys())) {
          promises.push(
            sendNotificationToUser(
              subscribers[key].token,
              subscribers[key].discrete ? discreetTitle : fullTitle,
              subscribers[key].discrete ? discreetSubtitle : fullSubtitle,
              "notification_loot",
              "#FF0000",
              "Alerts loot",
              "",
              "",
              orderArray.join(","),
              attackTime,
              subscribers[key].vibration,
              "sword_clash.aiff"
            ).catch((e) => {
              functions.logger.warn(`ERROR LOOT RANGERS SEND for ${subscribers[key].uid}\n${e}`);
            })
          );
        }

        await Promise.all(promises);

      } catch (e) {
        functions.logger.warn(`ERROR LOOT RANGERS GENERAL CATCH: ${e}`);
      }

    }),

};  