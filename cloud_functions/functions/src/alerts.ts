import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {
  sendTestNotification,
  sendEnergyNotification,
  sendNerveNotification,
  sendLifeNotification,
  logTravelArrival,
  sendHospitalNotification,
  sendDrugsNotification,
  sendMedicalNotification,
  sendBoosterNotification,
  sendRacingNotification,
  sendMessagesNotification,
  sendEventsNotification,
  sendForeignRestockNotification,
  sendStockMarketNotification,
} from "./notification";
import { getUsersStat } from "./torn_api";

const privateKey = require("../key/torn_key");
import fetch from "node-fetch";

import { handleTravelLiveActivity } from "./la_travel_handler";

const runtimeOpts512 = {
  timeoutSeconds: 120,
  memory: "512MB" as "512MB",
};

const runtimeOpts1024 = {
  timeoutSeconds: 120,
  memory: "1GB" as "1GB",
};

export async function getStockMarket(apiKey: string) {
  const response = await fetch(
    `https://api.torn.com/torn/?selections=stocks&key=${apiKey}`
  );
  return response.json();
}

export const alertsGroup = {
  //****************************//
  //*********** iOS ************//
  //****************************//
  checkIOS: functions
    .region("us-east4")
    .runWith(runtimeOpts1024)
    .pubsub.schedule(
      "0,3,6,9,12,15,18,21,24,27,30,33,36,39,42,45,48,51,54,57 * * * *"
    )
    .onRun(async () => {
      const promisesGlobal: Promise<any>[] = [];

      const millisAtStart = Date.now();

      // Get stock market
      const stockMarket = await getStockMarket(privateKey.tornKey);

      // Get existing stocks from Realtime DB
      const firebaseAdmin = require("firebase-admin");
      const db = firebaseAdmin.database();
      const stocksDB = db.ref("stocks/restocks");
      const foreignStocks = {};
      await stocksDB.once("value", function (snapshot) {
        snapshot.forEach(function (childSnapshot) {
          foreignStocks[childSnapshot.val().codeName] = childSnapshot.val();
        });
      });

      async function checkIOS() {
        const promises: Promise<any>[] = [];

        // Get the list of subscribers
        const alertsUsersQuery = admin
          .firestore()
          .collection("players")
          .where("active", "==", true)
          .where("platform", "==", "ios")
          .where("alertsEnabled", "==", true)
          .get();

        // Live activities only
        const laOnlyUsersQuery = admin
          .firestore()
          .collection("players")
          .where("active", "==", true)
          .where("platform", "==", "ios")
          .where("alertsEnabled", "==", false)
          .where("la_travel_push_token", ">", "")
          .get();

        const [alertsUsersSnapshot, laOnlyUsersSnapshot] = await Promise.all([
          alertsUsersQuery,
          laOnlyUsersQuery,
        ]);

        const alertsUsers = alertsUsersSnapshot.docs.map((d) => d.data());
        const laOnlyUsers = laOnlyUsersSnapshot.docs.map((d) => d.data());

        const subscribers = [...alertsUsers, ...laOnlyUsers];
        let iOSBlocks = 0;
        for (const key of Array.from(subscribers.keys())) {
          promises.push(
            sendNotificationForProfile(
              subscribers[key],
              foreignStocks,
              stockMarket
            ).then(function (value) {
              if (value === "ip-block") {
                iOSBlocks++;
              }
            })
          );
        }

        return Promise.all(promises).then(function (value) {
          const millisAfterFinish = Date.now();
          const difference = (millisAfterFinish - millisAtStart) / 1000;
          functions.logger.info(
            `Processing ${subscribers.length} iOS users (${alertsUsers.length} with alerts, ${laOnlyUsers.length} with LA only). Time: ${difference}`
          );
          return value;
        });
      }

      promisesGlobal.push(checkIOS());
      await Promise.all(promisesGlobal);
    }),

  //****************************//
  //******* ANDROID LOW ********//
  //****************************//
  checkAndroidLow: functions
    .region("us-east4")
    .runWith(runtimeOpts1024)
    .pubsub.schedule(
      "1,4,7,10,13,16,19,22,25,28,31,34,37,40,43,46,49,52,55,58 * * * *"
    )
    .onRun(async () => {
      const promisesGlobal: Promise<any>[] = [];

      const millisAtStart = Date.now();

      // Get stock market
      const stockMarket = await getStockMarket(privateKey.tornKey);

      // Get existing stocks from Realtime DB
      const firebaseAdmin = require("firebase-admin");
      const db = firebaseAdmin.database();
      const stocksDB = db.ref("stocks/restocks");
      const foreignStocks = {};
      await stocksDB.once("value", function (snapshot) {
        snapshot.forEach(function (childSnapshot) {
          foreignStocks[childSnapshot.val().codeName] = childSnapshot.val();
        });
      });

      async function checkAndroidLow() {
        const promises: Promise<any>[] = [];

        // Get the list of subscribers
        const response = await admin
          .firestore()
          .collection("players")
          .where("active", "==", true)
          .where("alertsEnabled", "==", true)
          .where("platform", "==", "android")
          .where("level", "<", 42)
          .get();

        const subscribers = response.docs.map((d) => d.data());
        let androidLow = 0;
        for (const key of Array.from(subscribers.keys())) {
          promises.push(
            sendNotificationForProfile(
              subscribers[key],
              foreignStocks,
              stockMarket
            ).then(function (value) {
              if (value === "ip-block") {
                androidLow++;
              }
            })
          );
        }

        return Promise.all(promises).then(function (value) {
          const millisAfterFinish = Date.now();
          const difference = (millisAfterFinish - millisAtStart) / 1000;
          functions.logger.info(
            `Android Low: ${subscribers.length}. Blocks: ${androidLow}. Time: ${difference}`
          );
          return value;
        });
      }

      promisesGlobal.push(checkAndroidLow());
      await Promise.all(promisesGlobal);
    }),

  //****************************//
  //******* ANDROID HIGH *******//
  //****************************//
  checkAndroidHigh: functions
    .region("us-east4")
    .runWith(runtimeOpts1024)
    .pubsub.schedule(
      "2,5,8,11,14,17,20,23,26,29,32,35,38,41,44,47,50,53,56,59 * * * *"
    )
    .onRun(async () => {
      const promisesGlobal: Promise<any>[] = [];

      const millisAtStart = Date.now();

      // Get stock market
      const stockMarket = await getStockMarket(privateKey.tornKey);

      // Get existing stocks from Realtime DB
      const firebaseAdmin = require("firebase-admin");
      const db = firebaseAdmin.database();
      const stocksDB = db.ref("stocks/restocks");
      const foreignStocks = {};
      await stocksDB.once("value", function (snapshot) {
        snapshot.forEach(function (childSnapshot) {
          foreignStocks[childSnapshot.val().codeName] = childSnapshot.val();
        });
      });

      async function checkAndroidHigh() {
        const promises: Promise<any>[] = [];

        // Get the list of subscribers
        const response = await admin
          .firestore()
          .collection("players")
          .where("active", "==", true)
          .where("alertsEnabled", "==", true)
          .where("platform", "==", "android")
          .where("level", ">=", 42)
          .get();

        const subscribers = response.docs.map((d) => d.data());
        let androidHigh = 0;
        for (const key of Array.from(subscribers.keys())) {
          promises.push(
            sendNotificationForProfile(
              subscribers[key],
              foreignStocks,
              stockMarket
            ).then(function (value) {
              if (value === "ip-block") {
                androidHigh++;
              }
            })
          );
        }

        return Promise.all(promises).then(function (value) {
          const millisAfterFinish = Date.now();
          const difference = (millisAfterFinish - millisAtStart) / 1000;
          functions.logger.info(
            `Android High: ${subscribers.length}. Blocks: ${androidHigh}. Time: ${difference}`
          );
          return value;
        });
      }

      // FOR TESTING
      promisesGlobal.push(checkAndroidHigh());
      await Promise.all(promisesGlobal);
    }),
};

//****************************//
//******* TEST EXPORT* *******//
//****************************//
//  See index.ts for details  //
//****************************//
export const alertsTestGroup = {
  runForUser: functions
    .region("us-east4")
    .runWith(runtimeOpts512)
    .https.onCall(async (data, context) => {
      const userName = data.userName;
      const forceTest = data.forceTest || false;


      if (!userName) {
        functions.logger.error("Error: no username");
        throw new functions.https.HttpsError(
          "invalid-argument",
          "No username"
        );
      }

      functions.logger.info(`Test check: ${userName}`);
      const millisAtStart = Date.now();

      const stockMarket = await getStockMarket(privateKey.tornKey);
      const db = admin.database();
      const stocksDB = db.ref("stocks/restocks");
      const foreignStocks = {};
      await stocksDB.once("value", (snapshot) => {
        snapshot.forEach((childSnapshot) => {
          foreignStocks[childSnapshot.val().codeName] = childSnapshot.val();
        });
      });

      const response = await admin
        .firestore()
        .collection("players")
        .where("active", "==", true)
        .where("name", "==", userName)
        .get();

      const subscribers = response.docs.map((d) => d.data());

      if (subscribers.length === 0) {
        const message = `No player found with name: ${userName}`;
        functions.logger.warn(message);
        return { success: false, message: message };
      }

      let blocks = 0;
      const promises: Promise<any>[] = [];
      for (const subscriber of subscribers) {
        promises.push(
          sendNotificationForProfile(subscriber, foreignStocks, stockMarket, forceTest)
            .then((value) => {
              if (value === "ip-block") {
                blocks++;
              }
            })
        );
      }

      await Promise.all(promises);

      const millisAfterFinish = Date.now();
      const difference = (millisAfterFinish - millisAtStart) / 1000;
      const successMessage = `Test for '${userName}' completed. Users: ${subscribers.length}. Blocked: ${blocks}. Time: ${difference}s`;
      functions.logger.info(successMessage);

      return { success: true, message: successMessage };
    }),
};

async function sendNotificationForProfile(
  subscriber: any,
  foreignStocks: any,
  stockMarket: any,
  forceTest: boolean = false,
): Promise<any> {
  const promises: Promise<any>[] = [];

  try {
    const userStats: any = await getUsersStat(subscriber.apiKey);

    if (!userStats.error) {

      // Force test regarless of notification
      if (forceTest) {
        promises.push(sendTestNotification(userStats, subscriber));
      }

      // Live Activities
      if (subscriber.la_travel_push_token) {
        promises.push(handleTravelLiveActivity(userStats, subscriber));
      }

      if (subscriber.energyNotification)
        promises.push(sendEnergyNotification(userStats, subscriber));
      if (subscriber.nerveNotification)
        promises.push(sendNerveNotification(userStats, subscriber));
      if (subscriber.lifeNotification)
        promises.push(sendLifeNotification(userStats, subscriber));
      if (subscriber.travelNotification)
        promises.push(logTravelArrival(userStats, subscriber));
      if (subscriber.hospitalNotification)
        promises.push(sendHospitalNotification(userStats, subscriber));
      if (subscriber.drugsNotification)
        promises.push(sendDrugsNotification(userStats, subscriber));
      if (subscriber.medicalNotification)
        promises.push(sendMedicalNotification(userStats, subscriber));
      if (subscriber.boosterNotification)
        promises.push(sendBoosterNotification(userStats, subscriber));
      if (subscriber.racingNotification)
        promises.push(sendRacingNotification(userStats, subscriber));
      if (subscriber.messagesNotification)
        promises.push(sendMessagesNotification(userStats, subscriber));
      if (subscriber.eventsNotification)
        promises.push(sendEventsNotification(userStats, subscriber));
      if (subscriber.foreignRestockNotification)
        promises.push(
          sendForeignRestockNotification(userStats, foreignStocks, subscriber)
        );
      if (subscriber.stockMarketNotification)
        promises.push(sendStockMarketNotification(stockMarket, subscriber));

      await Promise.all(promises);
    } else {
      // Return API errors for certain statistics
      if (userStats.error.error.includes("IP block")) {
        return "ip-block";
      }
    }
  } catch (e) {
    functions.logger.warn(`ERROR ALERTS \n${subscriber.uid} \n${e}`);

    // If users uninstall without removing API Key, this error will trigger
    // because the token is not known. In this case, stale the user
    // We allow up to 10 tries (will be reverted by the app later)
    if (e.toString().includes("Requested entity was not found")) {
      if (subscriber.tokenErrors !== undefined) {
        const errors = subscriber.tokenErrors + 1;
        if (errors >= 10) {
          await admin
            .firestore()
            .collection("players")
            .doc(subscriber.uid)
            .update({
              active: false,
              tokenErrors: errors,
            });
          functions.logger.warn(
            `Staled: ${subscriber.name}[${subscriber.playerId}] with UID ${subscriber.uid} after ${errors} token errors`
          );
        } else {
          await admin
            .firestore()
            .collection("players")
            .doc(subscriber.uid)
            .update({
              tokenErrors: errors,
            });
        }
      } else {
        await admin
          .firestore()
          .collection("players")
          .doc(subscriber.uid)
          .update({
            tokenErrors: 1,
          });
      }
    }
  }
}
