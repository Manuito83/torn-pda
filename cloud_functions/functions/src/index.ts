import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
var rp = require("request-promise");

admin.initializeApp();

export const runEveryMinute = functions.pubsub
  // This is something called cron expression check https://crontab.guru/ for more details
  .schedule("15 * * * *")
  .onRun(async () => {
    // get the list of subscribers
    /// HERE: If we have 2000+ users, it will fetch 2000K users every minute and loop over them, causing high change of
    /// resource usage. We must filter out users using some flags. Like not pulling users who have been updated 5 mins ago etc.
    const response = await admin.firestore().collection("players").get();
    const subscribers = response.docs.map((d) => d.data());

    await Promise.all(subscribers.map(checkAndSendNotification));
    console.log("send notificaions for energy");
  });

async function checkAndSendNotification(subscriber: any): Promise<any> {
  const promises: Promise<any>[] = [];
  const userStats = await getUsersStat(subscriber.apiKey);

  if (subscriber.energyNotification)
    promises.push(sendEnergyNotificaion(userStats, subscriber));

  /// TODO: Similarly split tasks for other parameters by creating similar functions like `sendEnergyNotificaion`
  await Promise.all(promises);
}

async function sendEnergyNotificaion(userStats: any, subscriber: any) {
  const energy = userStats.energy;
  const promises: Promise<any>[] = [];

  if (
    energy.maximum == energy.current &&
    subscriber.lastEnergyValue != energy.current
  ) {
    promises.push(
      sendNotificaionToUser(
        subscriber.token,
        "Full Energy Bar",
        "You have got full Energy bar, go spend on something."
      )
    );
    promises.push(
      admin
        .firestore()
        .collection("players")
        .doc(subscriber.playerId.toString())
        .update({
          lastEnergyValue: energy.current,
        })
    );
  }
  return Promise.all(promises);
}

async function getUsersStat(apiKey: string) {
  return rp({
    uri: `https://api.torn.com/user/?selections=bars&key=${apiKey}`,
    json: true,
  });
}

async function sendNotificaionToUser(
  token: string,
  title: string,
  body: string
) {
  // This will send notificiaon to the registered user, notificaion will only be shown if the app is on background or terminated, when the app is on screen
  // Notification will come as a callback, letting you do whatever we want with noticaion.
  // If you still wanna send notificion when app is open use localNotificaion to do so. More details on https://pub.dev/packages/firebase_messaging
  return admin.messaging().send({
    token: token,
    notification: {
      title: title,
      body: body,
    },
  });
}
