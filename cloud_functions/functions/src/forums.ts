import { onSchedule } from "firebase-functions/v2/scheduler";
import { logger } from "firebase-functions/v2";
import * as admin from "firebase-admin";
import { getUsersForums } from "./torn_api";
import { sendNotificationToUser } from "./notification";
import { ForumsApiResponse } from "./interfaces/forums_interface";

export const sendForumsSubscription = onSchedule({
  schedule: "0,15,30,45 * * * *",
  timeZone: "Etc/UTC",
  region: "us-east4",
  memory: "512MiB",
  timeoutSeconds: 120
}, async () => {
  try {
    // Get the list of subscribers
    const response = await admin
      .firestore()
      .collection("players")
      .where("active", "==", true)
      .where("forumsSubscriptionsNotification", "==", true)
      //.where("name", "==", "Manuito")
      .get();

    const subscribers = response.docs.map((d) => d.data());

    let ipBlocks = 0;
    let sent = 0;

    const promises = subscribers.map(async (thisUser) => {
      const errorUID = thisUser.uid;
      try {
        // Fetch user forum subscriptions
        const apiResponse: ForumsApiResponse = await getUsersForums(thisUser.apiKey);

        if (apiResponse.error) {
          // Handle API errors
          if (apiResponse.error.error.includes("IP block")) {
            ipBlocks++;
          }
          return;
        }

        // Get the user's current notified threads
        const previouslyNotifiedThreads: Record<string, number> = thisUser.forumsSubscriptionsNotified || {};

        // Create a map to track updates
        const updatedNotifiedThreads = { ...previouslyNotifiedThreads };
        let hasUpdates = false;

        // Check threads in the API response
        const newThreads = apiResponse.forumSubscribedThreads.filter((thread) => {
          const lastNotifiedCount = previouslyNotifiedThreads[thread.id] || 0;

          if (!previouslyNotifiedThreads[thread.id]) {
            // If the thread is new, add it to the map
            updatedNotifiedThreads[thread.id] = thread.posts.total;
            hasUpdates = true; // Mark that we need to update Firestore
            return false; // Do not notify for new subscriptions
          }

          // Notify if there are new posts
          return thread.posts.total > lastNotifiedCount;
        });

        // Generate the URL for bulkDetails
        let bulkDetails: string;

        if (newThreads.length === 1) {
          // Single thread updated
          const thread = newThreads[0];
          const totalPosts = thread.posts.total;
          const start = totalPosts - (totalPosts % 20); // Round down to the nearest 20
          bulkDetails = `https://www.torn.com/forums.php#p=threads&f=${thread.forum_id}&t=${thread.id}&start=${start}`;
        } else if (newThreads.length > 1) {
          // Multiple threads updated, we just go to the main forums page
          bulkDetails = `https://www.torn.com/forums.php`;
        }

        // Send notifications if there are new posts
        if (newThreads.length > 0) {
          let notificationTitle = "";
          let notificationBody = "";

          if (newThreads.length === 1) {
            // Single thread updated
            const thread = newThreads[0];
            const newPosts = thread.posts.total - (previouslyNotifiedThreads[thread.id] || 0);

            notificationTitle = `${newPosts} new post${newPosts === 1 ? "" : "s"}`;
            notificationBody = `${newPosts} new post${newPosts === 1 ? "" : "s"} in ${thread.title}`;
          } else {
            // Multiple threads updated
            notificationTitle = `${newThreads.length} forum threads updated`;
            notificationBody = newThreads.map((thread) => thread.title).join(", ");
          }

          // DEBUG!
          //logger.debug(`### ${notificationTitle} \n\n ${notificationBody}`);

          // Push notification to the user
          await sendNotificationToUser({
            token: thisUser.token,
            title: notificationTitle,
            body: notificationBody,
            icon: "notification_forums",
            color: "#00FF00", // green
            channelId: "Alerts forums",
            vibration: thisUser.vibration,
            bulkDetails: bulkDetails,
          });

          sent++;

          // Update the last notified counts for threads with new posts
          newThreads.forEach((thread) => {
            updatedNotifiedThreads[thread.id] = thread.posts.total;
          });

          hasUpdates = true;
        }

        // Remove threads that no longer exist in the API response
        // ONLY if there is already an update to Firestore
        if (hasUpdates) {
          Object.keys(updatedNotifiedThreads).forEach((threadId) => {
            if (
              !apiResponse.forumSubscribedThreads.some((thread) => thread.id === parseInt(threadId))
            ) {
              delete updatedNotifiedThreads[threadId];
            }
          });
        }

        // Update Firestore only if there are changes
        if (hasUpdates) {
          await admin.firestore().collection("players").doc(thisUser.uid).update({
            forumsSubscriptionsNotified: updatedNotifiedThreads,
          });
        }
      } catch (e) {
        logger.warn(`ERROR FORUM SUBSCRIPTIONS for ${errorUID}\n${e}`);
      }
    });

    // Wait for all promises to complete
    await Promise.all(promises);

    // Log summary
    logger.info(
      `Forums Subscription: ${subscribers.length} subscribed. ${sent} sent. ${ipBlocks} IP blocks.`
    );
  } catch (e) {
    logger.error(`Critical error in forums subscription function: ${e}`);
  }
});

