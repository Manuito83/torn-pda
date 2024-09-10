import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { sendNotificationToUser } from "./notification";
import { aDayInMilliseconds } from "./constants";

export const staleGroup = {
  deactivateStale: functions.region('us-east4').pubsub
    .schedule("0 0 * * *")
    .onRun(async () => {
      const promises: Promise<any>[] = [];

      const currentDateInMillis = Date.now();

      // This pull the users who haven't open the app for 10 days
      const usersWhoAreStale = (
        await admin
          .firestore()
          .collection("players")
          .where("active", "==", true)
          .where("lastActive", "<=", currentDateInMillis - aDayInMilliseconds * 9)
          .get()
      ).docs.map((d) => d.data());

      usersWhoAreStale.map((user) => {
        promises.push(
          sendNotificationToUser({
            token: user.token,
            title: "Automatic alerts have been deactivated!",
            body: "Your alerts have been turned off due to inactivity, please use Torn PDA again to reactivate! If you think this is an error, contact us!",
            icon: "notification_icon",
            color: "#FFFFFF",
            channelId: "Alerts stale user",
            vibration: "medium",
          })
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

        functions.logger.warn(`Staled: ${user.playerId.toString()} with UID ${user.uid}`);
      });

      return Promise.all(promises);
    }),

  deleteStale: functions.region('us-east4').pubsub
    .schedule("0 0 15 * *")
    .onRun(async () => {
      const promises: Promise<any>[] = [];

      const currentDateInMillis = Date.now();

      // This pull the total users
      const totalUsers = (
        await admin
          .firestore()
          .collection("players")
          .get()
      ).docs.map((d) => d.data());

      functions.logger.warn(`Total app users: ${totalUsers.length}`);

      // This pull the users who haven't open the app for 60 days
      const usersWithNoUse60Days = (
        await admin
          .firestore()
          .collection("players")
          .where("active", "==", false)
          .where("lastActive", "<=", currentDateInMillis - aDayInMilliseconds * 60)
          .get()
      ).docs.map((d) => d.data());

      functions.logger.warn(`Active users: ${totalUsers.length - usersWithNoUse60Days.length}`);
      functions.logger.warn(`Users to delete: ${usersWithNoUse60Days.length}`);

      // *******
      // CAUTION
      // *******
      usersWithNoUse60Days.map((user) => {
        promises.push(
          admin
            .firestore()
            .collection("players")
            .doc(user.uid)
            .delete()
        );
        // functions.logger.warn(`Removed: ${user.name.toString()}[${user.playerId.toString()}] with UID ${user.uid}`);
      });

      return Promise.all(promises);
    }),

};
