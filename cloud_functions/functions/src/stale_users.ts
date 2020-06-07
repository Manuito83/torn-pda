import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { sendNotificaionToUser } from "./notification";

export const staleGroup = {
  runEveryDay: functions.pubsub.schedule("0 0 * * *").onRun(async () => {
    const promises: Promise<any>[] = [];
    // This pull the users who havent open the app for 6 days
    const usersWhoAreAboutToGoStale = (
      await admin
        .firestore()
        .collection("players")
        .where("active", "==", true)
        .where("lastActive", "<=", currentDateInMillis - aDayInMiliseconds * 6)
        .get()
    ).docs.map((d) => d.data());

    usersWhoAreAboutToGoStale.map((user) =>
      promises.push(
        sendNotificaionToUser(
          user.token,
          user.playerId,
          "Please come back",
          "You have not been active recently, please come back to continue your notification subscription."
        )
      )
    );

    // This pull the users who havent open the app for 7 days
    const usersWhoAreStale = (
      await admin
        .firestore()
        .collection("players")
        .where("active", "==", true)
        .where("lastActive", "<=", currentDateInMillis - aDayInMiliseconds * 7)
        .get()
    ).docs.map((d) => d.data());

    usersWhoAreStale.map((user) => {
      promises.push(
        sendNotificaionToUser(
          user.token,
          user.playerId,
          "We are sorry!!!",
          "Your notification has been turned off, please open the app back again to get notification."
        )
      );
      promises.push(
        admin
          .firestore()
          .collection("players")
          .doc(user.playerId.toString())
          .update({
            active: false,
          })
      );
    });
    return Promise.all(promises);
  }),
};
