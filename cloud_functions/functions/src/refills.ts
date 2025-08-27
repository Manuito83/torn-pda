import { onSchedule } from "firebase-functions/v2/scheduler";
import { logger } from "firebase-functions/v2";
import * as admin from "firebase-admin";
import { getUsersRefills } from "./torn_api";
import { sendNotificationToUser } from "./notification";

export const sendRefillNotifications = onSchedule(
  {
    schedule: "58 15,16,17,18,19,20,21,22 * * *",
    timeZone: "Etc/UTC",
    region: "us-east4",
    memory: "512MiB",
    timeoutSeconds: 120,
  },
  async () => {
    const promises: Promise<any>[] = [];
    let errorUID = "";

    // Get the list of subscribers
    // NOTE Torn PDA v2.6.0 introduces refillsTime. Instead of adding the time here
    // which might be possible in the future, we get all users subscribes 6 times per day and compare with desired time
    // TODO: v2.6.0 uploads refillsTime every 48 hours. When all users contain "refillsTime" (defaulted to 22), introduce it as a condition below
    const response = await admin
      .firestore()
      .collection("players")
      .where("active", "==", true)
      .where("refillsNotification", "==", true)
      .get();

    const subscribers = response.docs.map((d) => d.data());
    let ipBlocks = 0;
    let subscribersThisTime = 0;
    let sent = 0;
    let nothingSelected = 0;

    const serverTime = new Date().getHours() + 1;

    // Loop all subscribers
    for (const key of Array.from(subscribers.keys())) {

      // Try is inside the for loop so that individual issues does not throw the entire function
      try {
        const thisUser = subscribers[key];
        errorUID = thisUser.uid;

        // Because we are launching at 21:58, for example, we add one hour for 22:00 to match the app
        const desiredTime = thisUser.refillsTime || 22;
        if (serverTime !== desiredTime) {
          continue;
        }
        subscribersThisTime++;

        const apiRefills: any = await getUsersRefills(thisUser.apiKey);

        // If API returns an error, will log it below (probably IP block?)
        if (!apiRefills.error) {

          // Users that have not selected refills for the first time will have no refillsRequested array in Firestore
          // Those that deselect all of them, will end up with an empty array
          // In all these cases, we send a notification to remind them that they have nothing selected
          if (!thisUser.refillsRequested || thisUser.refillsRequested.length === 0) {

            const emptyTitle = "No refills selected!";
            const emptyBody = "You have activated your refills alerts but did not select which refills you would like to be notified about!"

            let title = emptyTitle;
            let body = emptyBody;
            if (thisUser.discrete) {
              title = `Refill`;
              body = ` `;
            }

            promises.push(
              sendNotificationToUser({
                token: thisUser.token,
                title: title,
                body: body,
                icon: "notification_refills",
                color: "#0000FF",
                channelId: "Alerts refills",
                vibration: thisUser.vibration,
              })
            );

            nothingSelected++;

            // This covers the normal case. User with an existing refillsRequested array that that is not empty 
            // (the user has chosen at least 1 refill)
          } else {

            const refillsToSend = [];

            if (thisUser.refillsRequested.includes("energy") && !apiRefills.refills.energy_refill_used) {
              refillsToSend.push("energy");
            }

            if (thisUser.refillsRequested.includes("nerve") && !apiRefills.refills.nerve_refill_used) {
              refillsToSend.push("nerve");
            }

            if (thisUser.refillsRequested.includes("token") && !apiRefills.refills.token_refill_used) {
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
                sendNotificationToUser({
                  token: thisUser.token,
                  title: notificationTitle,
                  body: notificationBody,
                  icon: "notification_refills",
                  color: "#0000FF",
                  channelId: "Alerts refills",
                  vibration: thisUser.vibration,
                })
              );
              sent++;
            }
          }

        } else if (apiRefills.error) {
          // Return API errors for certain statistics
          if (apiRefills.error.error.includes("IP block")) {
            ipBlocks++;
          }
        }

      } catch (e) {
        logger.warn(`ERROR REFILL for ${errorUID}\n${e}`);
      }
    }

    logger.info(`Refills ${serverTime} TCT: ${subscribersThisTime} subscribed. ${sent} sent (+${nothingSelected} with no refills selected). ${ipBlocks} IP blocks.`);
    await Promise.all(promises);

  }
);