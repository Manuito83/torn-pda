import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { getUsersRefills } from "./torn_api";
import { sendNotificationToUser } from "./notification";

const runtimeOpts = {
    timeoutSeconds: 120,
    memory: "512MB" as "512MB",
  }

export const refillsGroup = {

  sendRefillNotifications: functions.region('us-east4')
  .runWith(runtimeOpts)
  .pubsub
  .schedule("58 21 * * *")
  .timeZone('Etc/UTC')
  .onRun(async () => {
    
    const promises: Promise<any>[] = [];
    let errorUID = "";

    try {
  
      // Get the list of subscribers
      const response = await admin
        .firestore()
        .collection("players")
        .where("active", "==", true)
        .where("refillsNotification", "==", true)
        .get();
      
      const subscribers = response.docs.map((d) => d.data());
      let ipBlocks = 0;
      let sent = 0;
      
      for(const key of Array.from(subscribers.keys()) ) {
        const thisUser = subscribers[key];
        errorUID = thisUser.uid;
        
        const userRefills = await getUsersRefills(thisUser.apiKey);

        // If API does not return error and refillsRequested field exists
        if (!userRefills.error && thisUser.refillsRequested) {
          let refillsToSend = [];

          if (thisUser.refillsRequested.includes("energy") && !userRefills.refills.energy_refill_used) {
              refillsToSend.push("energy");
          }
  
          if (thisUser.refillsRequested.includes("nerve") && !userRefills.refills.nerve_refill_used) {
              refillsToSend.push("nerve");
          }
  
          if (thisUser.refillsRequested.includes("token") && !userRefills.refills.token_refill_used) {
              refillsToSend.push("casino tokens");
          }
  
          let sendNotification = false;
          let notificationTitle = "";
          let notificationBody = "";
          if (refillsToSend.length > 0) {
              sendNotification = true;
              if (refillsToSend.length === 1) {
                  notificationTitle = "1 refill still available!";
                  notificationBody = `You haven't used your ${refillsToSend} refill today. The day is almost over!`;
              } else {
                  notificationTitle = `${refillsToSend.length} refills still available!`;
                  const last = refillsToSend.pop();
                  const finalString = refillsToSend.join(', ') + ' and ' + last;
                  notificationBody = `You haven't used your ${finalString} refills today. The day is almost over!`;
              }
          }
  
          if (sendNotification) {
            promises.push(
              sendNotificationToUser(
                  thisUser.token,
                  notificationTitle,
                  notificationBody,
                  "notification_refills",
                  "#0000FF",
                  "Alerts refills",
                  "",
                  "",
                  thisUser.vibration,
              )
            );
            
            sent++;
          }

        } else if (userRefills.error) {
          // Return API errors for certain statistics
          if (userRefills.error.error.includes("IP block")) {
            ipBlocks++;
          }
        }
      }

      functions.logger.info(`Refills: ${subscribers.length} users, ${sent} sent, ${ipBlocks} blocks`);
  
      await Promise.all(promises);
    
    } catch (e) {
      functions.logger.warn(`ERROR REFILL for ${errorUID}\n${e}`);
    }
    
  }),

};  