import { onSchedule } from "firebase-functions/v2/scheduler";
import { onRequest, onCall, HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
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

export async function getStockMarket(apiKey: string) {
  const response = await fetch(
    `https://api.torn.com/torn/?selections=stocks&key=${apiKey}`
  );
  return response.json();
}

//****************************//
//*********** iOS ************//
//****************************//
export const checkIOS = onSchedule(
  {
    schedule: "0,3,6,9,12,15,18,21,24,27,30,33,36,39,42,45,48,51,54,57 * * * *",
    region: "us-east4",
    memory: "2GiB",
    timeoutSeconds: 180,
  },
  async () => {
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

    async function checkIOSInternal() {
      // Get the list of subscribers
      const alertsUsersQuery = admin
        .firestore()
        .collection("players")
        .where("active", "==", true)
        .where("platform", "==", "ios")
        .where("alertsEnabled", "==", true)
        .get();

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

      const batchSize = 500;
      for (let i = 0; i < subscribers.length; i += batchSize) {
        const batch = subscribers.slice(i, i + batchSize);
        const promises = batch.map((subscriber) =>
          sendNotificationForProfile(
            subscriber,
            foreignStocks,
            stockMarket
          ).then(function (value) {
            if (value === "ip-block") {
              iOSBlocks++;
            }
          })
        );
        await Promise.all(promises);
        logger.info(`iOS Batch ${i / batchSize + 1} of ${Math.ceil(subscribers.length / batchSize)} processed.`);

        if (i + batchSize < subscribers.length) {
          await new Promise(resolve => setTimeout(resolve, 1000)); // Pausa de 1000ms = 1 segundo
        }
      }

      const millisAfterFinish = Date.now();
      const difference = (millisAfterFinish - millisAtStart) / 1000;

      logger.info(
        `Processing ${subscribers.length} iOS users (${alertsUsers.length} with alerts, ${laOnlyUsers.length} with LA only). Blocks: ${iOSBlocks}. Time: ${difference}s`
      );
    }

    promisesGlobal.push(checkIOSInternal());
    await Promise.all(promisesGlobal);
  }
);

//****************************//
//******* ANDROID LOW ********//
//****************************//
export const checkAndroidLow = onSchedule(
  {
    schedule: "1,4,7,10,13,16,19,22,25,28,31,34,37,40,43,46,49,52,55,58 * * * *",
    region: "us-east4",
    memory: "1GiB",
    timeoutSeconds: 120,
  },
  async () => {
    const promisesGlobal: Promise<any>[] = [];

    const millisAtStart = Date.now();

    const stockMarket = await getStockMarket(privateKey.tornKey);

    const firebaseAdmin = require("firebase-admin");
    const db = firebaseAdmin.database();
    const stocksDB = db.ref("stocks/restocks");
    const foreignStocks = {};
    await stocksDB.once("value", function (snapshot) {
      snapshot.forEach(function (childSnapshot) {
        foreignStocks[childSnapshot.val().codeName] = childSnapshot.val();
      });
    });

    async function checkAndroidLowInternal() {
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

      const batchSize = 500;
      for (let i = 0; i < subscribers.length; i += batchSize) {
        const batch = subscribers.slice(i, i + batchSize);
        const promises = batch.map((subscriber) =>
          sendNotificationForProfile(
            subscriber,
            foreignStocks,
            stockMarket
          ).then(function (value) {
            if (value === "ip-block") {
              androidLow++;
            }
          })
        );
        await Promise.all(promises);
        logger.info(`Android Low Batch ${i / batchSize + 1} of ${Math.ceil(subscribers.length / batchSize)} processed.`);

        if (i + batchSize < subscribers.length) {
          await new Promise(resolve => setTimeout(resolve, 1000)); // Pausa de 1000ms = 1 segundo
        }
      }

      const millisAfterFinish = Date.now();
      const difference = (millisAfterFinish - millisAtStart) / 1000;
      logger.info(
        `Android Low: ${subscribers.length}. Blocks: ${androidLow}. Time: ${difference}s`
      );
    }

    promisesGlobal.push(checkAndroidLowInternal());
    await Promise.all(promisesGlobal);
  }
);

//****************************//
//******* ANDROID HIGH *******//
//****************************//
export const checkAndroidHigh = onSchedule(
  {
    schedule: "2,5,8,11,14,17,20,23,26,29,32,35,38,41,44,47,50,53,56,59 * * * *",
    region: "us-east4",
    memory: "1GiB",
    timeoutSeconds: 120,
  },
  async () => {
    const promisesGlobal: Promise<any>[] = [];

    const millisAtStart = Date.now();

    const stockMarket = await getStockMarket(privateKey.tornKey);

    const firebaseAdmin = require("firebase-admin");
    const db = firebaseAdmin.database();
    const stocksDB = db.ref("stocks/restocks");
    const foreignStocks = {};
    await stocksDB.once("value", function (snapshot) {
      snapshot.forEach(function (childSnapshot) {
        foreignStocks[childSnapshot.val().codeName] = childSnapshot.val();
      });
    });

    async function checkAndroidHighInternal() {
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

      const batchSize = 500;
      for (let i = 0; i < subscribers.length; i += batchSize) {
        const batch = subscribers.slice(i, i + batchSize);
        const promises = batch.map((subscriber) =>
          sendNotificationForProfile(
            subscriber,
            foreignStocks,
            stockMarket
          ).then(function (value) {
            if (value === "ip-block") {
              androidHigh++;
            }
          })
        );
        await Promise.all(promises);
        logger.info(`Android High Batch ${i / batchSize + 1} of ${Math.ceil(subscribers.length / batchSize)} processed.`);

        if (i + batchSize < subscribers.length) {
          await new Promise(resolve => setTimeout(resolve, 1000)); // Pausa de 1000ms = 1 segundo
        }
      }

      const millisAfterFinish = Date.now();
      const difference = (millisAfterFinish - millisAtStart) / 1000;
      logger.info(
        `Android High: ${subscribers.length}. Blocks: ${androidHigh}. Time: ${difference}s`
      );
    }

    promisesGlobal.push(checkAndroidHighInternal());
    await Promise.all(promisesGlobal);
  }
);

async function sendNotificationForProfile(
  subscriber: any,
  foreignStocks: any,
  stockMarket: any,
  _forceTest: boolean = false
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

      if (subscriber.energyNotification) {
        checkResults.push(sendEnergyNotification(userStats, subscriber));
      }
      if (subscriber.nerveNotification) {
        checkResults.push(sendNerveNotification(userStats, subscriber));
      }
      if (subscriber.lifeNotification) {
        checkResults.push(sendLifeNotification(userStats, subscriber));
      }
      if (subscriber.travelNotification) {
        checkResults.push(logTravelArrival(userStats, subscriber));
      }
      if (subscriber.hospitalNotification) {
        checkResults.push(sendHospitalNotification(userStats, subscriber));
      }
      if (subscriber.drugsNotification) {
        checkResults.push(sendDrugsNotification(userStats, subscriber));
      }
      if (subscriber.medicalNotification) {
        checkResults.push(sendMedicalNotification(userStats, subscriber));
      }
      if (subscriber.boosterNotification) {
        checkResults.push(sendBoosterNotification(userStats, subscriber));
      }
      if (subscriber.racingNotification) {
        checkResults.push(sendRacingNotification(userStats, subscriber));
      }
      if (subscriber.messagesNotification) {
        checkResults.push(sendMessagesNotification(userStats, subscriber));
      }
      if (subscriber.eventsNotification) {
        checkResults.push(sendEventsNotification(userStats, subscriber));
      }
      if (subscriber.foreignRestockNotification) {
        checkResults.push(
          sendForeignRestockNotification(userStats, foreignStocks, subscriber)
        );
      }
      if (subscriber.stockMarketNotification) {
        checkResults.push(sendStockMarketNotification(stockMarket, subscriber));
      }

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
        allPromises.push(
          admin
            .firestore()
            .collection("players")
            .doc(subscriber.uid)
            .update(firestoreUpdates)
        );
      }

      // 5. Send all collected notifications in parallel
      if (notificationsToSend.length > 0) {
        allPromises.push(
          ...notificationsToSend.map((params) => sendNotificationToUser(params))
        );
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
    logger.warn(`ERROR ALERTS \n${subscriber.uid} \n${e}`);

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
          logger.warn(
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
          .update({ tokenErrors: 1 });
      }
    }
  }
}

//****************************//
//******* TEST GROUP *********//
//****************************//

/**
 * Runs a full alert check for a specific user
 * Default to Manuito
 */
export const runForUser = onCall(
  {
    region: "us-east4",
    memory: "512MiB",
    timeoutSeconds: 120,
  },
  async (request) => {
    const userName = request.data.userName || "Manuito";

    if (!userName) {
      throw new HttpsError(
        "invalid-argument",
        "No username provided."
      );
    }
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Authentication required."
      );
    }

    logger.info(`Running full alert check for: ${userName}`);
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
      logger.warn(message);
      return { success: false, message: message };
    }

    let blocks = 0;
    for (const subscriber of subscribers) {
      const result = await sendNotificationForProfile(
        subscriber,
        foreignStocks,
        stockMarket
      );
      if (result === "ip-block") {
        blocks++;
      }
    }

    const millisAfterFinish = Date.now();
    const difference = (millisAfterFinish - millisAtStart) / 1000;
    const successMessage = `Full alert check for '${userName}' completed. Users: ${subscribers.length}. Blocks: ${blocks}. Time: ${difference}s`;
    logger.info(successMessage);

    return { success: true, message: successMessage, blocks: blocks };
  }
);

/**
 * Sends a specific test notification to a user
 * Default to Manuito
 */
export const sendTestNotification = onCall(
  {
    region: "us-east4",
    memory: "512MiB",
    timeoutSeconds: 120,
  },
  async (request) => {
    const userName = request.data.userName || "Manuito";

    if (!userName) {
      throw new HttpsError(
        "invalid-argument",
        "No username provided."
      );
    }
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Authentication required."
      );
    }

    logger.info(
      `Sending hardcoded test notification to ${userName}.`
    );

    const userDoc = await admin
      .firestore()
      .collection("players")
      .where("name", "==", userName)
      .get();
    if (userDoc.empty) {
      throw new HttpsError(
        "not-found",
        `User '${userName}' not found.`
      );
    }
    const subscriber = userDoc.docs[0].data();
    const token = subscriber.token;
    const vibration = subscriber.vibration || "";

    if (!token || token === "windows") {
      throw new HttpsError(
        "failed-precondition",
        `User '${userName}' has no valid FCM token.`
      );
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
      logger.info(
        `Successfully sent hardcoded test notification to ${userName}.`
      );
      return { success: true, message: `Test notification sent.` };
    } catch (error: any) {
      logger.error(
        `Failed to send test notification to ${userName}:`,
        error
      );
      throw new HttpsError(
        "internal",
        `Failed to send notification: ${error.message}`
      );
    }
  }
);

export const sendMassNotification = onRequest(
  {
    region: "us-east4",
    memory: "1GiB",
    timeoutSeconds: 540,
  },
  async (_request, response) => {

    // --- WARNING CONFIG ---
    const IS_ACTIVE = false;   // FALSE is SECURED
    const IS_TEST_MODE = true; // TRUE is TEST MODE (only sends to TEST_USER_NAME - active neeeds to be true anyway)
    const TEST_USER_NAME = "Manuito";
    // ---------------------------------

    if (!IS_ACTIVE) {
      response
        .status(403)
        .json({ success: false, message: "Inactive function!" });
      return;
    }

    const notificationContent = {
      title: "TORN PDA INFO - Profile Bug 🐞",
      body:
        "As some of you have let us know, there's a bug in several sections of the Profile page in the app. " +
        "We are fully aware and working on it. There's more information in the Torn PDA official forum thread if you are interested.",
      icon: "notification_icon",
      color: "#00FF00",
      channelId: "Alerts information",
      sound: "aircraft_seatbelt.aiff",
    };

    logger.info(
      `Starting mass notification. Test Mode: ${IS_TEST_MODE}`
    );

    try {
      let playersSnapshot;
      if (IS_TEST_MODE) {
        playersSnapshot = await admin
          .firestore()
          .collection("players")
          .where("name", "==", TEST_USER_NAME)
          .where("active", "==", true)
          .get();
      } else {
        playersSnapshot = await admin
          .firestore()
          .collection("players")
          .where("active", "==", true)
          .get();
      }

      const allTokens: string[] = [];
      for (const doc of playersSnapshot.docs) {
        const token = doc.data().token;
        if (
          token &&
          typeof token === "string" &&
          token.length > 10 &&
          token !== "windows"
        ) {
          allTokens.push(token);
        }
      }

      if (allTokens.length === 0) {
        response
          .status(200)
          .json({ success: true, message: "No valid tokens found." });
        return;
      }

      const chunkSize = 1000;
      const totalChunks = Math.ceil(allTokens.length / chunkSize);

      logger.info(
        `Found ${allTokens.length} tokens. Will be processed in ${totalChunks} chunks of ${chunkSize}.`
      );

      let failedCount = 0;
      let tokenNotFoundCount = 0;

      for (let i = 0; i < allTokens.length; i += chunkSize) {
        const currentChunkNumber = i / chunkSize + 1;
        const chunk = allTokens.slice(i, i + chunkSize);

        const promises = chunk.map((token) => {
          const payload: admin.messaging.Message = {
            token: token,
            notification: {
              title: notificationContent.title,
              body: notificationContent.body,
            },
            android: {
              priority: "high",
              notification: {
                channelId: notificationContent.channelId,
                color: notificationContent.color,
                icon: notificationContent.icon,
                sound: "default",
              },
            },
            apns: {
              headers: { "apns-priority": "10" },
              payload: {
                aps: { sound: notificationContent.sound, badge: 1 },
              },
            },
          };

          return admin
            .messaging()
            .send(payload)
            .then(() => ({ success: true }))
            .catch((error) => ({ success: false, error: error }));
        });

        const results = await Promise.all(promises);

        for (const result of results) {
          if (!result.success) {
            failedCount++;
            if (
              "error" in result &&
              result.error &&
              result.error
                .toString()
                .includes("Requested entity was not found")
            ) {
              tokenNotFoundCount++;
            }
          }
        }

        logger.info(
          `Processed chunk ${currentChunkNumber}/${totalChunks}. Total failures so far: ${failedCount}`
        );

        if (i + chunkSize < allTokens.length) {
          await new Promise((resolve) => setTimeout(resolve, 1000));
        }
      }

      const sentCount = allTokens.length - failedCount;
      const finalMessage = `Mass notification completed. Total Sent: ${sentCount}, Total Failed: ${failedCount} (of which ${tokenNotFoundCount} were invalid tokens).`;
      logger.info(finalMessage);
      response.status(200).json({ success: true, message: finalMessage });

    } catch (error) {
      logger.error("A critical error occurred:", error);
      response
        .status(500)
        .json({
          success: false,
          message: "An internal server error occurred.",
        });
    }

  }
);