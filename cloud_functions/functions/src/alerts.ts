import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {
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
  sendNotificationToUser,
  NotificationParams,
  NotificationCheckResult,
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

async function sendNotificationForProfile(
  subscriber: any,
  foreignStocks: any,
  stockMarket: any,
  forceTest: boolean = false,
): Promise<any> {
  const notificationsToSend: NotificationParams[] = [];
  const firestoreUpdates: { [key: string]: any } = {};
  const allPromises: Promise<any>[] = [];

  try {
    const userStats: any = await getUsersStat(subscriber.apiKey);

    if (!userStats.error) {

      // 1. Live Activities: Call handleTravelLiveActivity (it handles its own RTDB writes)
      // This is a direct async call, independent of other alerts.
      if (subscriber.la_travel_push_token) {
        allPromises.push(handleTravelLiveActivity(userStats, subscriber));
      }

      // 2. Prepare an array to collect results conditionally
      const checkResults: NotificationCheckResult[] = [];

      if (subscriber.energyNotification) { checkResults.push(sendEnergyNotification(userStats, subscriber)); }
      if (subscriber.nerveNotification) { checkResults.push(sendNerveNotification(userStats, subscriber)); }
      if (subscriber.lifeNotification) { checkResults.push(sendLifeNotification(userStats, subscriber)); }
      if (subscriber.travelNotification) { checkResults.push(logTravelArrival(userStats, subscriber)); }
      if (subscriber.hospitalNotification) { checkResults.push(sendHospitalNotification(userStats, subscriber)); }
      if (subscriber.drugsNotification) { checkResults.push(sendDrugsNotification(userStats, subscriber)); }
      if (subscriber.medicalNotification) { checkResults.push(sendMedicalNotification(userStats, subscriber)); }
      if (subscriber.boosterNotification) { checkResults.push(sendBoosterNotification(userStats, subscriber)); }
      if (subscriber.racingNotification) { checkResults.push(sendRacingNotification(userStats, subscriber)); }
      if (subscriber.messagesNotification) { checkResults.push(sendMessagesNotification(userStats, subscriber)); }
      if (subscriber.eventsNotification) { checkResults.push(sendEventsNotification(userStats, subscriber)); }
      if (subscriber.foreignRestockNotification) { checkResults.push(sendForeignRestockNotification(userStats, foreignStocks, subscriber)); }
      if (subscriber.stockMarketNotification) { checkResults.push(sendStockMarketNotification(stockMarket, subscriber)); }

      // 3. Process collected results, both notifications and Firestore updates
      for (const result of checkResults) {
        if (result.notification) {
          notificationsToSend.push(result.notification);
        }
        if (result.firestoreUpdate) {
          Object.assign(firestoreUpdates, result.firestoreUpdate);
        }
      }

      // 4. Perform a single Firestore update for this user
      if (Object.keys(firestoreUpdates).length > 0) {
        allPromises.push(admin.firestore().collection("players").doc(subscriber.uid).update(firestoreUpdates));
      }

      // 5. Send all collected notifications in parallel
      if (notificationsToSend.length > 0) {
        allPromises.push(...notificationsToSend.map(params => sendNotificationToUser(params)));
      }

      // 6. Wait for all concurrent operations to complete
      await Promise.all(allPromises);

    } else {
      // Return API errors for certain statistics
      if (userStats.error.error.includes("IP block")) {
        return "ip-block";
      }
    }
  } catch (e: any) {
    functions.logger.warn(`ERROR ALERTS \n${subscriber.uid} \n${e}`);

    // If users uninstall without removing API Key, this error will trigger
    // because the token is not known. In this case, stale the user
    // We allow up to 10 tries (will be reverted by the app later)
    if (e.toString().includes("Requested entity was not found")) {
      if (subscriber.tokenErrors !== undefined) {
        const errors = subscriber.tokenErrors + 1;
        if (errors >= 10) {
          await admin.firestore().collection("players").doc(subscriber.uid).update({
            active: false,
            tokenErrors: errors,
          });
          functions.logger.warn(
            `Staled: ${subscriber.name}[${subscriber.playerId}] with UID ${subscriber.uid} after ${errors} token errors`
          );
        } else {
          await admin.firestore().collection("players").doc(subscriber.uid).update({
            tokenErrors: errors,
          });
        }
      } else {
        await admin.firestore().collection("players").doc(subscriber.uid).update({ tokenErrors: 1 });
      }
    }
  }
}

//****************************//
//******* TEST GROUP *********//
//****************************//
export const alertsTestGroup = {
  /**
   * Runs a full alert check for a specific user
   * Default to Manuito
   */
  runForUser: functions
    .region("us-east4")
    .runWith(runtimeOpts512)
    .https.onCall(async (data, context) => {
      const userName = data.userName || "Manuito";

      if (!userName) {
        throw new functions.https.HttpsError("invalid-argument", "No username provided.");
      }
      if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Authentication required.");
      }

      functions.logger.info(`Running full alert check for: ${userName}`);
      const millisAtStart = Date.now();

      const stockMarket = await getStockMarket(privateKey.tornKey);
      const db = admin.database();
      const stocksDB = db.ref("stocks/restocks");
      const foreignStocks = {};
      await stocksDB.once("value", (snapshot) => {
        snapshot.forEach(function (childSnapshot) {
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
      for (const subscriber of subscribers) {
        const result = await sendNotificationForProfile(subscriber, foreignStocks, stockMarket);
        if (result === "ip-block") { blocks++; }
      }

      const millisAfterFinish = Date.now();
      const difference = (millisAfterFinish - millisAtStart) / 1000;
      const successMessage = `Full alert check for '${userName}' completed. Users: ${subscribers.length}. Blocks: ${blocks}. Time: ${difference}s`;
      functions.logger.info(successMessage);

      return { success: true, message: successMessage, blocks: blocks };
    }),

  /**
   * Sends a specific test notification to a user
   * Default to 'Manuito
   */
  sendTestNotification: functions
    .region("us-east4")
    .runWith(runtimeOpts512)
    .https.onCall(async (data, context) => {
      const userName = data.userName || "Manuito";

      if (!userName) {
        throw new functions.https.HttpsError("invalid-argument", "No username provided.");
      }
      if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Authentication required.");
      }

      functions.logger.info(`Sending hardcoded test notification to ${userName}.`);

      const userDoc = await admin.firestore().collection("players").where("name", "==", userName).get();
      if (userDoc.empty) {
        throw new functions.https.HttpsError("not-found", `User '${userName}' not found.`);
      }
      const subscriber = userDoc.docs[0].data();
      const token = subscriber.token;
      const vibration = subscriber.vibration || "";

      if (!token || token === "windows") {
        throw new functions.https.HttpsError("failed-precondition", `User '${userName}' has no valid FCM token.`);
      }

      const defaultTestParams: NotificationParams = {
        token: token,
        title: "Test title",
        body: "Test body",
        icon: "notification_energy",
        color: "#00FF00",
        channelId: "Alerts energy",
        vibration: vibration,
        sound: "aircraft_seatbelt.aiff",
      };

      try {
        await sendNotificationToUser(defaultTestParams);
        functions.logger.info(`Successfully sent hardcoded test notification to ${userName}.`);
        return { success: true, message: `Test notification sent.` };
      } catch (error: any) {
        functions.logger.error(`Failed to send test notification to ${userName}:`, error);
        throw new functions.https.HttpsError("internal", `Failed to send notification: ${error.message}`);
      }
    }),

  /**
   * Sends a mass notification to all active players
   * Ignores user's alertsEnabled preference
   */
  sendMassNotification: functions
    .region("us-east4")
    .runWith(runtimeOpts1024)
    .https.onCall(async (data, context) => {

      // ####### WARNING!! ########
      const active = false;
      if (!active) {
        functions.logger.warn("MASS NOTIFICATION NOT ACTIVE!!!!");
        return null;
      }

      const defaultContentParams = {
        title: "TORN PDA INFO",
        body: "TEST",
        icon: "notification_icon",
        color: "#00FF00",
        channelId: "Alerts information",
        sound: "aircraft_seatbelt.aiff",
      };

      if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Authentication required.");
      }

      functions.logger.info(`Sending mass notification: "${defaultContentParams.title}" - "${defaultContentParams.body}"`);

      // Query all active players
      const activePlayersSnapshot = await admin
        .firestore()
        .collection("players")
        .where("active", "==", true)
        .get();

      const notificationsPromises: Promise<any>[] = [];
      let sentCount = 0;
      let failedCount = 0;

      // Iterate through each active player
      for (const doc of activePlayersSnapshot.docs) {
        const subscriber = doc.data();
        const token = subscriber.token;
        const vibration = subscriber.vibration || "";

        if (token && token !== "windows") {
          const userNotificationParams: NotificationParams = {
            token: token,
            title: defaultContentParams.title,
            body: defaultContentParams.body,
            icon: defaultContentParams.icon,
            color: defaultContentParams.color,
            channelId: defaultContentParams.channelId,
            vibration: vibration,
            sound: defaultContentParams.sound,
          };

          notificationsPromises.push(
            sendNotificationToUser(userNotificationParams)
              .then(() => {
                sentCount++;
              }).catch((e: any) => {
                functions.logger.warn(`Failed to send mass notification to ${doc.id}: ${e.message}`);
                failedCount++;
              })
          );
        }
      }

      // Wait for all individual notification sends to complete
      await Promise.all(notificationsPromises);

      functions.logger.info(`Mass notification completed. Sent: ${sentCount}, Failed: ${failedCount}.`);
      return { success: true, message: `Mass notification sent. Sent: ${sentCount}, Failed: ${failedCount}.` };
    }),
};