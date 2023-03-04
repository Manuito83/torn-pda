import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { sendNotificationToUser } from "./notification";
const rp = require("request-promise");

export const lootRangersGroup = {

  sendLootRangersNotification: functions.region('us-east4')
    .pubsub
    .schedule("*/2 * * * *")
    .onRun(async () => {

      const promises: Promise<any>[] = [];
      let errorUID = "";

      const firebaseAdmin = require("firebase-admin");
      const db = firebaseAdmin.database();

      function getLootRangersApi() {
        return rp({
          uri: `https://api.lzpt.io/loot`,
          json: true,
        });
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
        let orderArray = [];
        const npcArray = lrJson.order;
        for (var id of npcArray) {
          orderArray.push(`${lrJson.npcs[id].name}[${id}]`);
        }

        let title = `Loot Rangers attack shortly: ${timeString} TCT!`;
        console.log(title);

        let subtitle = `Attack order: ${orderArray.join(', ')}`;
        console.log(subtitle);

        let attackTime = `${hours}:${minutes}`;

        for (const key of Array.from(subscribers.keys())) {
          promises.push(
            sendNotificationToUser(
              subscribers[key].token,
              title,
              subtitle,
              "notification_loot",
              "#FF0000",
              "Alerts loot",
              "",
              "",
              orderArray.join(","),
              attackTime,
              subscribers[key].vibration,
              "sword_clash.aiff"
            )
          );
        }

        await Promise.all(promises);

      } catch (e) {
        functions.logger.warn(`ERROR LOOT RANGERS SEND for ${errorUID}\n${e}`);
      }

    }),

};  