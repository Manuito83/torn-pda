import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { sendEnergyNotification, sendNerveNotification, 
  sendTravelNotification, sendHospitalNotification } from "./notification";
import { getUsersStat } from "./torn_api";

export const alertsGroup = {
  runEveryMinute: functions.region('us-east4').pubsub
    .schedule("*/3 * * * *")
    .onRun(async () => {
      // Get the list of subscribers
      // TODO: Research on possibility to change this to realtime database
      const response = await admin
        .firestore()
        .collection("players")
        .where("active", "==", true)
        .where("alertsEnabled", "==", true)
        .get();

      const subscribers = response.docs.map((d) => d.data());
      await Promise.all(subscribers.map(sendNotificationForProfile));
    }),
};

async function sendNotificationForProfile(subscriber: any): Promise<any> {
  const promises: Promise<any>[] = [];
  const userStats = await getUsersStat(subscriber.apiKey);
  
  try {
    if (!userStats.error) {
      if (subscriber.energyNotification)
        promises.push(sendEnergyNotification(userStats, subscriber));
      if (subscriber.nerveNotification)
        promises.push(sendNerveNotification(userStats, subscriber));
      if (subscriber.travelNotification)
        promises.push(sendTravelNotification(userStats, subscriber));
      if (subscriber.hospitalNotification)
        promises.push(sendHospitalNotification(userStats, subscriber));
    }
  } catch (e) {
    console.log("ERROR ALERTS");
    console.log(subscriber.uid);
    console.log(e);
  }

  await Promise.all(promises);
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
