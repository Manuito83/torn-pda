import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { sendEnergyNotification, sendNerveNotification, 
  logTravelArrival, sendHospitalNotification, 
  sendDrugsNotification, sendRacingNotification, 
  sendMessagesNotification, sendEventsNotification, 
  sendForeignRestockNotification } from "./notification";
import { getUsersStat } from "./torn_api";

const runtimeOpts = {
  timeoutSeconds: 120,
  memory: "512MB" as "512MB",
}

export const alertsGroup = {

  //****************************//
  //*********** iOS ************//
  //****************************//
  checkIOS: functions.region('us-east4')
  .runWith(runtimeOpts)
  .pubsub
  .schedule("0,3,6,9,12,15,18,21,24,27,30,33,36,39,42,45,48,51,54,57 * * * *")
  .onRun(async () => {

    const promisesGlobal: Promise<any>[] = [];

    const millisAtStart = Date.now();

    // Get existing stocks from Realtime DB
    const firebaseAdmin = require("firebase-admin");
    const db = firebaseAdmin.database();
    const stocksDB = db.ref("stocks/restocks");
    const foreignStocks = {};
    await stocksDB.once("value", function(snapshot) {
      snapshot.forEach(function(childSnapshot) {
        foreignStocks[childSnapshot.val().codeName] = childSnapshot.val();
      });
    });

    async function checkIOS() {
      const promises: Promise<any>[] = [];

      // Get the list of subscribers
      const response = await admin
        .firestore()
        .collection("players")
        .where("active", "==", true)
        .where("alertsEnabled", "==", true)
        .where("platform", "==", "ios")
        .get();

      const subscribers = response.docs.map((d) => d.data());
      let iOSBlocks = 0;
      for(const key of Array.from(subscribers.keys()) ) {
        promises.push(
          sendNotificationForProfile(subscribers[key], foreignStocks).then(function(value) {
            if (value === "ip-block") {
              iOSBlocks++;
            }
          })
        );
      }

      return Promise.all(promises).then(function(value) {
        const millisAfterFinish = Date.now();
        const difference = (millisAfterFinish - millisAtStart) / 1000;
        functions.logger.info(`iOS: ${subscribers.length}. Blocks: ${iOSBlocks}. Time: ${difference}`);
        return value;
      });
    }

    promisesGlobal.push(checkIOS());
    await Promise.all(promisesGlobal);
  }),


  //****************************//
  //******* ANDROID LOW ********//
  //****************************//
  checkAndroidLow: functions.region('us-east4')
  .runWith(runtimeOpts)
  .pubsub
  .schedule("1,4,7,10,13,16,19,22,25,28,31,34,37,40,43,46,49,52,55,58 * * * *")
  .onRun(async () => {

    const promisesGlobal: Promise<any>[] = [];

    const millisAtStart = Date.now();

    // Get existing stocks from Realtime DB
    const firebaseAdmin = require("firebase-admin");
    const db = firebaseAdmin.database();
    const stocksDB = db.ref("stocks/restocks");
    const foreignStocks = {};
    await stocksDB.once("value", function(snapshot) {
      snapshot.forEach(function(childSnapshot) {
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
        .where("level", "<", 35)
        .get();
      
      const subscribers = response.docs.map((d) => d.data());
      let androidLow = 0;
      for(const key of Array.from(subscribers.keys()) ) {
        promises.push(
          sendNotificationForProfile(subscribers[key], foreignStocks).then(function(value) {
            if (value === "ip-block") {
              androidLow++;
            }
          })
        );
      }
  
      return Promise.all(promises).then(function(value) {
        const millisAfterFinish = Date.now();
        const difference = (millisAfterFinish - millisAtStart) / 1000;
        functions.logger.info(`Android Low: ${subscribers.length}. Blocks: ${androidLow}. Time: ${difference}`);
        return value;
      });
    }

    promisesGlobal.push(checkAndroidLow());
    await Promise.all(promisesGlobal);
  }),


  //****************************//
  //******* ANDROID HIGH *******//
  //****************************//
  checkAndroidHigh: functions.region('us-east4')
  .runWith(runtimeOpts)
  .pubsub
  .schedule("2,5,8,11,14,17,20,23,26,29,32,35,38,41,44,47,50,53,56,59 * * * *")
  .onRun(async () => {

    const promisesGlobal: Promise<any>[] = [];

    const millisAtStart = Date.now();

    // Get existing stocks from Realtime DB
    const firebaseAdmin = require("firebase-admin");
    const db = firebaseAdmin.database();
    const stocksDB = db.ref("stocks/restocks");
    const foreignStocks = {};
    await stocksDB.once("value", function(snapshot) {
      snapshot.forEach(function(childSnapshot) {
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
        .where("level", ">=", 35)
        .get();
        
      const subscribers = response.docs.map((d) => d.data());
      let androidHigh = 0;
      for(const key of Array.from(subscribers.keys()) ) {
        promises.push(
          sendNotificationForProfile(subscribers[key], foreignStocks).then(function(value) {
            if (value === "ip-block") {
              androidHigh++;
            }
          })
        );
      }
  
      return Promise.all(promises).then(function(value) {
        const millisAfterFinish = Date.now();
        const difference = (millisAfterFinish - millisAtStart) / 1000;
        functions.logger.info(`Android High: ${subscribers.length}. Blocks: ${androidHigh}. Time: ${difference}`);
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
export const alertsTestGroup = {

  checkManuito: functions.region('us-east4')
  .runWith(runtimeOpts)
  .pubsub
  .schedule("*/3 * * * *")
  .onRun(async () => {

    const promisesGlobal: Promise<any>[] = [];

    const millisAtStart = Date.now();

    // Get existing stocks from Realtime DB
    const firebaseAdmin = require("firebase-admin");
    const db = firebaseAdmin.database();
    const stocksDB = db.ref("stocks/restocks");
    const foreignStocks = {};
    await stocksDB.once("value", function(snapshot) {
      snapshot.forEach(function(childSnapshot) {
        foreignStocks[childSnapshot.val().codeName] = childSnapshot.val();
      });
    });

    async function checkManuito() {
      const promises: Promise<any>[] = [];

      // Get the list of subscribers
      const response = await admin
        .firestore()
        .collection("players")
        .where("active", "==", true)
        .where("alertsEnabled", "==", true)
        .where("name", "==", "Manuito")
        .get();

      const subscribers = response.docs.map((d) => d.data());
      let manuitoBlocks = 0;
      for(const key of Array.from(subscribers.keys()) ) {
        promises.push(
          sendNotificationForProfile(subscribers[key], foreignStocks).then(function(value) {
            if (value === "ip-block") {
              manuitoBlocks++;
            }
          })
        );
      }

      return Promise.all(promises).then(function(value) {
        const millisAfterFinish = Date.now();
        const difference = (millisAfterFinish - millisAtStart) / 1000;
        functions.logger.info(`Manuito: ${subscribers.length}. Blocks: ${manuitoBlocks}. Time: ${difference}`);
        return value;
      });
    }
    
    promisesGlobal.push(checkManuito());
    await Promise.all(promisesGlobal);
  }),
};

async function sendNotificationForProfile(subscriber: any, stocks: any): Promise<any> {
  const promises: Promise<any>[] = [];

  try {

    const userStats = await getUsersStat(subscriber.apiKey);

    if (!userStats.error) {

      if (subscriber.energyNotification)
        promises.push(sendEnergyNotification(userStats, subscriber));
      if (subscriber.nerveNotification)
        promises.push(sendNerveNotification(userStats, subscriber));
      if (subscriber.travelNotification)
        promises.push(logTravelArrival(userStats, subscriber));
      if (subscriber.hospitalNotification)
        promises.push(sendHospitalNotification(userStats, subscriber));
      if (subscriber.drugsNotification)
        promises.push(sendDrugsNotification(userStats, subscriber));
      if (subscriber.racingNotification)
        promises.push(sendRacingNotification(userStats, subscriber));
      if (subscriber.messagesNotification)
        promises.push(sendMessagesNotification(userStats, subscriber));
      if (subscriber.eventsNotification)
        promises.push(sendEventsNotification(userStats, subscriber));
      if (subscriber.foreignRestockNotification)
        promises.push(sendForeignRestockNotification(userStats, stocks, subscriber));

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
    if (e.toString().includes("Requested entity was not found")) {
      await admin
        .firestore()
        .collection("players")
        .doc(subscriber.uid)
        .update({
          active: false,
        });
      functions.logger.warn(`Staled: ${subscriber.name}[${subscriber.playerId}] with UID ${subscriber.uid}`);
    }
  }

}

// Helper function to calculate estimated billing amount, commented because cloud functions wouldnt allow to deploy
// function getEstimatedPrice(estimatedWeeklyActiveUsers: number) {
//   const numberOfExecutionsPerDay = 1440; //  Minutes in a day
//   const totalDocumentReadsPerDay =
//     estimatedWeeklyActiveUsers * numberOfExecutionsPerDay;

//   const paidDocumentReadsPerDay = totalDocumentReadsPerDay - 50000; // 50k per day is free
//   const pricePer100KRead = 0.06;
//   const paidDocumentKReadsPerDay = paidDocumentReadsPerDay / 100000;
//   const priceOfNotificationSender = paidDocumentKReadsPerDay * pricePer100KRead;
//   const estimatedBillForCloudFunction = 5; // 5$ per month as of my estimation, can be optimized;
//   return {
//     estimatedWeeklyActiveUsers,
//     estimatedDailyBill: priceOfNotificationSender,
//     estimatedMonthlyBill: priceOfNotificationSender * 30,
//     estimatedBillForCloudFunction,
//   };
// }
