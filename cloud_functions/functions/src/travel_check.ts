import { onSchedule } from "firebase-functions/v2/scheduler";
import { logger } from "firebase-functions/v2";
import * as admin from "firebase-admin";
import { sendNotificationToUser } from "./notification";

export const sendTravelNotifications = onSchedule(
  {
    schedule: "*/2 * * * *",
    region: "us-east4",
    memory: "512MiB",
    timeoutSeconds: 120,
  },
  async () => {
    const promises: Promise<any>[] = [];

    try {
      const currentDateInSeconds = Date.now() / 1000;
      // 2 minutes and 20 seconds (120 + 20 = 140)
      // 20 second margin in the worst-case scenario
      const nextTwoMinutes = currentDateInSeconds + 140;

      // Get the list of subscribers
      const response = await admin
        .firestore()
        .collection("players")
        .where("active", "==", true)
        .where("travelNotification", "==", true)
        .where("travelTimeNotification", ">", 0)
        .where("travelTimeNotification", "<", nextTwoMinutes)
        .get();

      const docs = response.docs;
      console.log("Sending travel to: " + docs.length + " users");

      for (const doc of docs) {
        const thisUser = doc.data();
        const docId = doc.id; // Always valid — this is the Firestore document ID

        try {
          // Skip users without a valid FCM token
          if (!thisUser.token) {
            logger.warn(`Skipping travel notification: missing token for doc ${docId}`);
            // Still reset travelTimeNotification so this user doesn't block future runs
            promises.push(
              admin.firestore().collection("players").doc(docId).update({ travelTimeNotification: 0 })
            );
            continue;
          }

          const minutesRemaining = Math.round((thisUser.travelTimeArrival - currentDateInSeconds) / 60);
          const secondsRemaining = Math.round(thisUser.travelTimeArrival - currentDateInSeconds);

          let landingBody = "";
          if (secondsRemaining <= 0) {
            landingBody = `You have landed in ${thisUser.travelDestination}!`;
          } else if (secondsRemaining > 0 && secondsRemaining <= 60) {
            landingBody = `You are on final approach to ${thisUser.travelDestination}, landing in less than a minute!`;
          } else if (secondsRemaining > 60 && minutesRemaining <= 1) {
            landingBody = `You are descending towards ${thisUser.travelDestination}, landing in one minute!`
          } else {
            landingBody = `You are descending towards ${thisUser.travelDestination}, landing in about ${minutesRemaining} minutes!`
          }

          let title = `Approaching ${thisUser.travelDestination}!`;
          let body = landingBody;
          if (thisUser.discrete) {
            title = `T`;
            body = ` `;
          }

          promises.push(
            sendNotificationToUser({
              token: thisUser.token,
              title: title,
              body: body,
              icon: "notification_travel",
              color: "#2196F3",
              channelId: "Alerts travel",
              vibration: thisUser.vibration,
              sound: "aircraft_seatbelt.aiff"
            })
          );

          promises.push(
            admin
              .firestore()
              .collection("players")
              .doc(docId)
              .update({
                travelTimeNotification: 0
              })
          );
        } catch (userError) {
          logger.warn(`Error processing travel for ${docId}: ${userError}`);
        }
      }

      await Promise.all(promises);

    } catch (e) {
      logger.warn(`ERROR TRAVEL SEND\n${e}`);
    }

  }
);  