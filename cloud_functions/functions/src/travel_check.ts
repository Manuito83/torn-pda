import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { sendNotificationToUser } from "./notification";

export const travelGroup = {

  sendTravelNotifications: functions.region('us-east4')
  .pubsub
  .schedule("*/3 * * * *")
  .onRun(async () => {
    
    const promises: Promise<any>[] = [];

    try {
      const currentDateInSeconds = Date.now() / 1000;
      const nextFiveMinutes = currentDateInSeconds + 300;
  
      // Get the list of subscribers
      const response = await admin
        .firestore()
        .collection("players")
        .where("active", "==", true)
        .where("travelNotification", "==", true)
        .where("travelTimeNotification", ">", 0)
        .where("travelTimeNotification", "<", nextFiveMinutes)
        .get();
      
      const subscribers = response.docs.map((d) => d.data());
      
      console.log("Sending travel to: " + subscribers.length + " users");
      
      for(const key of Array.from(subscribers.keys()) ) {
        const thisUser = subscribers[key];
        const minutesRemaining = Math.round((thisUser.travelTimeArrival - currentDateInSeconds) / 60);
  
        promises.push(
          sendNotificationToUser(
            thisUser.token,
            `Approaching ${thisUser.travelDestination}!`,
            `You will land in ${thisUser.travelDestination} in about ${minutesRemaining} minutes!`,
            "notification_travel",
            "#0000FF",
            "Alerts travel",
            "",
            "",
            thisUser.vibration,
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
      functions.logger.warn(`ERROR TRAVEL SEND \n${e}`);
    }
    
  }),

};  