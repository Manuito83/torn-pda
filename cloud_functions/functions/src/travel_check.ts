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
      // 4 minutes and 20 seconds (240 + 60 = 260), so that earliest rounded notification is 4 minutes
      // while we still allow for 2 passes leaving a 20 second margin in the worst-case scenario
      const nextFourMinutes = currentDateInSeconds + 260;
  
      // Get the list of subscribers
      const response = await admin
        .firestore()
        .collection("players")
        .where("active", "==", true)
        .where("travelNotification", "==", true)
        .where("travelTimeNotification", ">", 0)
        .where("travelTimeNotification", "<", nextFourMinutes)
        .get();
      
      const subscribers = response.docs.map((d) => d.data());
      
      console.log("Sending travel to: " + subscribers.length + " users");
      
      for(const key of Array.from(subscribers.keys()) ) {
        const thisUser = subscribers[key];
        errorUID = thisUser.uid;
        const minutesRemaining = Math.round((thisUser.travelTimeArrival - currentDateInSeconds) / 60);
  
        let landingBody = "";
        if (minutesRemaining <= 0) {
          landingBody = `You have landed in ${thisUser.travelDestination}!`;
        } else if (minutesRemaining === 1) {
          landingBody = `You are on final approach to ${thisUser.travelDestination}, landing in one minute or less!`;
        } else {
          landingBody = `You are descending towards ${thisUser.travelDestination}, landing in about ${minutesRemaining} minutes!`
        }

        promises.push(
          sendNotificationToUser(
            thisUser.token,
            `Approaching ${thisUser.travelDestination}!`,
            landingBody,
            "notification_travel",
            "#2196F3",
            "Alerts travel",
            "",
            "",
            "",
            "",
            thisUser.vibration,
            "aircraft_seatbelt.aiff"
          )
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