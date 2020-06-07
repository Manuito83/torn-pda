import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { sendEnergyNotificaion, sendTravelNotification } from "./notification";
import { getUsersStat } from "./torn_api";

export const alertsGroup = {
  runEveryMinute: functions.pubsub
    // This is something called cron expression check https://crontab.guru/ for more details
    .schedule("* * * * *")
    .onRun(async () => {
      // get the list of subscribers
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
  // Follow the similar step to notify about the energy increase
  if (subscriber.energyNotification)
    promises.push(sendEnergyNotificaion(userStats, subscriber));
  if (subscriber.travelNotification)
    promises.push(sendTravelNotification(userStats, subscriber));

  await Promise.all(promises);
}

//
function getEstimatedPrice(estimatedWeeklyActiveUsers: number) {
  const numberOfExecutionsPerDay = 1440; //  Minutes in a day
  const totalDocumentReadsPerDay =
    estimatedWeeklyActiveUsers * numberOfExecutionsPerDay;

  const paidDocumentReadsPerDay = totalDocumentReadsPerDay - 50000; // 50k per day is free
  const pricePer100KRead = 0.06;
  const paidDocumentKReadsPerDay = paidDocumentReadsPerDay / 100000;
  const priceOfNotificationSender = paidDocumentKReadsPerDay * pricePer100KRead;
  const estimatedBillForCloudFunction = 5; // 5$ per month as of my estimation, can be optimized;
  return {
    estimatedWeeklyActiveUsers,
    estimatedDailyBill: priceOfNotificationSender,
    estimatedMonthlyBill: priceOfNotificationSender * 30,
    estimatedBillForCloudFunction,
  };
}
