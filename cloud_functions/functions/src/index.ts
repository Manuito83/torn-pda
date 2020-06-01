import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
var rp = require("request-promise");

admin.initializeApp();

export const runEveryMinute = functions.pubsub
  .schedule("* * * * *")
  .onRun(async () => {
    // get the list of subscribers
    //HERE: If we have 2000+ users, it will fetch 2000K users
    const response = await admin.firestore().collection("players").get();
    const subscribers = response.docs.map((d) => d.data());
    console.log(subscribers);

    await Promise.all(subscribers.map(checkAndSendNotification));
    console.log("send notificaions for energy");
  });

async function checkAndSendNotification(subscriber: any): Promise<any> {
  console.log(subscriber);

  const promises: Promise<any>[] = [];
  const userStats = await getUsersStat(subscriber.apiKey);

  if (subscriber.energyNotification)
    promises.push(sendEnergyNotificaion(userStats, subscriber));

  /// TODO: Similarly split tasks for other parameters by creating similar functions like `sendEnergyNotificaion`
  await Promise.all(promises);
}

async function sendEnergyNotificaion(userStats: any, subscriber: any) {
  const energy = userStats.energy;
  console.log(userStats);
  console.log(userStats.energy);
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
  return admin.messaging().send({
    token: token,
    notification: {
      title: title,
      body: body,
    },
  });
}
