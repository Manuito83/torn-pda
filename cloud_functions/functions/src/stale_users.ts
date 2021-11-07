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

      // This pull the users who haven't open the app for 7 days
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
            "Your alerts have been turned off due to inactivity, please use Torn PDA again to reactivate! If you think this is an error, contact us!",
            "notification_icon",
            "#FFFFFF",
            "Alerts stale user",
            "",
            "",
            "",
            "medium",
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
        
        functions.logger.warn(`Staled: ${user.playerId.toString()} with UID ${user.uid}`);
      });
      
      return Promise.all(promises);
  }),

  deleteStale: functions.region('us-east4').pubsub
    .schedule("0 0 15 * *")
    .onRun(async () => {
      const promises: Promise<any>[] = [];
      
      const currentDateInMillis = Date.now();

      // This pull the users who havent open the app for 30 days
      const totalUsers = (
        await admin
          .firestore()
          .collection("players")
          .get()
      ).docs.map((d) => d.data());

      functions.logger.warn(`Total users: ${totalUsers.length}`);

      // This pull the users who haven't open the app for 60 days
      const usersWhoUninstalled = (
        await admin
          .firestore()
          .collection("players")
          .where("active", "==", false)
          .where("lastActive", "<=", currentDateInMillis - aDayInMilliseconds * 60)
          .get()
      ).docs.map((d) => d.data());

      functions.logger.warn(`Users to delete: ${usersWhoUninstalled.length}`);

      // *******
      // CAUTION
      // *******
      usersWhoUninstalled.map((user) => {
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
