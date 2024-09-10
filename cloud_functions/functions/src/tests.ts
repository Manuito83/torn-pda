import * as functions from "firebase-functions";
//import * as admin from "firebase-admin";
import { sendNotificationToUser } from "./notification";

export const testGroup = {
  testNotification: functions.region('us-east4').pubsub
    .schedule("* * 1 1 1")
    .onRun(async () => {
      const promises: Promise<any>[] = [];

      try {

        // Actual production function
        // Comment as necessary if using the other function below
        promises.push(
          sendNotificationToUser({
            token: '### TOKEN HERE ###', // Then call as "tests.testNotification()" in shell
            title: 'Approaching Torn',
            body: 'You will land...',
            icon: "notification_travel",
            color: "#2196F3",
            channelId: "Alerts travel",
            vibration: "medium",
            sound: "aircraft_seatbelt.aiff"
          })
        );

        // Template
        /*
        promises.push(
          sendNotificationToUser({
            token: '### TOKEN HERE ###', // Then call as "tests.testNotification()" in shell
            title: 'Approaching Torn',
            body: 'You will land...',
            icon: "notification_travel",
            color: "#2196F3",
            channelId: "Alerts travel",
            vibration: "medium",
            sound: "aircraft_seatbelt.aiff"
          })
        );
        */

      } catch (e) {
        console.log(`ERROR TEST \n${e}`)
      }

      await Promise.all(promises);

    }),
};
