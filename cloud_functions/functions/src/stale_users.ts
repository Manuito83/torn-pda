import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { sendNotificationToUser } from "./notification";
import { aDayInMilliseconds } from "./constants";

export const staleGroup = {
  runEveryDay: functions.region('us-east4').pubsub
    .schedule("0 0 * * *")
    .onRun(async () => {
      const promises: Promise<any>[] = [];
      
      const currentDateInMillis = Date.now();

      // This pull the users who havent open the app for 7 days
      const usersWhoAreStale = (
        await admin
          .firestore()
          .collection("players")
          .where("active", "==", true)
          .where("lastActive", "<=", currentDateInMillis - aDayInMilliseconds * 6)
          .get()
      ).docs.map((d) => d.data());

      usersWhoAreStale.map((user) => {
        promises.push(
          sendNotificationToUser(
            user.token,
            "Automatic alerts have been deactivated!",
            "Due to inactivity, your alerts have been turned off, please use Torn PDA again to reactivate!",
            "notification_icon",
            "#FFFFFF"
          )
        );
        promises.push(
          admin
            .firestore()
            .collection("players")
            .doc(user.uid)
            .update({
              active: false,
            })
        );
        
        //console.log(usersWhoAreStale.length);
        console.log(`Staled: ${user.playerId.toString()} with UID ${user.uid}`);
      });
      
      return Promise.all(promises);
  }),

  // This pull the users who are about to go stale
  /*
  const usersWhoAreAboutToGoStale = (
    await admin
      .firestore()
      .collection("players")
      .where("active", "==", true)
      .where("lastActive", "<=", currentDateInMillis - aDayInMiliseconds * 7)
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
  */

};
