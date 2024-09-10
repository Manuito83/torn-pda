import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { sendNotificationToUser } from "./notification";

export const travelGroup = {

  sendTravelNotifications: functions.region('us-east4')
    .pubsub
    .schedule("*/2 * * * *")
    .onRun(async () => {

      const promises: Promise<any>[] = [];
      let errorUID = "";

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

        const subscribers = response.docs.map((d) => d.data());

        console.log("Sending travel to: " + subscribers.length + " users");

        for (const key of Array.from(subscribers.keys())) {
          const thisUser = subscribers[key];
          errorUID = thisUser.uid;
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
              .doc(thisUser.uid)
              .update({
                travelTimeNotification: 0
              })
          );

        }

        await Promise.all(promises);

      } catch (e) {
        functions.logger.warn(`ERROR TRAVEL SEND for ${errorUID}\n${e}`);
      }

    }),

};  