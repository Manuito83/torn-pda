import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
var rp = require("request-promise");

export const runEveryMinute = functions.pubsub
  .schedule("every minute")
  .onRun(async () => {
    // get the list of subscribers
    const subscribers = await admin.firestore().collection("players").get();

    await Promise.all(
      subscribers.docs
        .map((d) => d.data())
        .map((sub) => checkAndSendNotification)
    );
    console.log("send notificaions for energy");
  });

async function checkAndSendNotification(subscriber: any) {
  const userStats = await getUsersStat(subscriber.apiKey);
  const energy = userStats.energy;
  if (energy.maximum == energy.current) {
    return sendNotificaionToUser(
      subscriber.token,
      "Full Energy Bar",
      "You have got full Energy bar, go spend on something."
    );
  }
  return null;
}

async function getUsersStat(apiKey: string) {
  return rp(`https://api.torn.com/user/?selections=bars&key=${apiKey}`);
}

async function sendNotificaionToUser(
  token: string,
  title: string,
  body: string
) {
  return admin.messaging().send({
    token: token,
    notification: {
      title: title,
      body: body,
    },
  });
}
