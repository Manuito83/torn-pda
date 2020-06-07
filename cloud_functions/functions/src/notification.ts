import * as admin from "firebase-admin";

export async function sendEnergyNotificaion(userStats: any, subscriber: any) {
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

export async function sendTravelNotification(userStats: any, subscriber: any) {
  //TODO:
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

export async function sendNotificaionToUser(
  token: string,
  title: string,
  body: string
): Promise<any> {
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
