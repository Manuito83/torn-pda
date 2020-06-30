import * as admin from "firebase-admin";
import { currentDateInMillis } from "./constants";

export async function sendEnergyNotificaion(userStats: any, subscriber: any) {
  const energy = userStats.energy;
  const promises: Promise<any>[] = [];

  if (
    energy.maximum === energy.current &&
    subscriber.lastEnergyValue !== energy.current
  ) {
    promises.push(
      sendNotificaionToUser(
        subscriber.token,
        subscriber.playerId,
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
  const travel = userStats.travel;
  const promises: Promise<any>[] = [];
  const lastTravelNotificaionSent = subscriber.lastTravelNotified || 0;
  if (
    travel.time_left > 0 &&
    travel.time_left <= 90 &&
    currentDateInMillis - lastTravelNotificaionSent > 90
  ) {
    promises.push(
      sendNotificaionToUser(
        subscriber.token,
        subscriber.playerId,
        "Your travel is about to complete",
        `You will arrive at ${travel.destination} in ${travel.time_left} seconds.`
      )
    );
    promises.push(
      admin
        .firestore()
        .collection("players")
        .doc(subscriber.playerId.toString())
        .update({
          lastTravelNotified: currentDateInMillis,
        })
    );
  }
  return Promise.all(promises);
}

export async function sendNotificaionToUser(
  token: string,
  playerId: string,
  title: string,
  body: string
): Promise<any> {
  // This will send notificiaon to the registered user, notificaion will only be shown if the app is on background or terminated, when the app is on screen
  // Notification will come as a callback, letting you do whatever we want with noticaion.
  // If you still wanna send notificion when app is open use localNotificaion to do so. More details on https://pub.dev/packages/firebase_messaging
  return admin
    .messaging()
    .send({
      token: token,
      notification: {
        title: title,
        body: body,
      },
    })
    .catch((error) => {
      return admin
        .firestore()
        .collection("players")
        .doc(playerId.toString())
        .update({
          active: false,
        });
    });
}
