import { onSchedule } from "firebase-functions/v2/scheduler";
import { logger } from "firebase-functions/v2";
import * as admin from "firebase-admin";
import { sendNotificationToUser } from "./notification";

const aDayInMilliseconds = 24 * 60 * 60 * 1000;

export const deactivateStale = onSchedule(
  {
    schedule: "0 0 * * *",
    region: "us-east4",
    memory: "512MiB",
    timeoutSeconds: 120,
  },
  async () => {
    const currentDateInMillis = Date.now();
    const batchSize = 500;
    let lastDoc: FirebaseFirestore.QueryDocumentSnapshot | null = null;
    let totalProcessed = 0;

    // This pull the users who haven't open the app for 10 days
    while (true) {
      let query = admin
        .firestore()
        .collection("players")
        .where("active", "==", true)
        .where("lastActive", "<=", currentDateInMillis - aDayInMilliseconds * 9)
        .orderBy("lastActive")
        .limit(batchSize);

      if (lastDoc) {
        query = query.startAfter(lastDoc);
      }

      const snapshot = await query.get();
      if (snapshot.empty) {
        break;
      }

      const batch = admin.firestore().batch();
      const notificationPromises: Promise<any>[] = [];

      snapshot.docs.forEach((doc) => {
        const user = doc.data();
        notificationPromises.push(
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
        batch.update(doc.ref, { active: false });
        logger.warn(`Staled: ${user.playerId.toString()} with UID ${user.uid}`);
      });

      await Promise.all([batch.commit(), ...notificationPromises]);

      totalProcessed += snapshot.size;
      lastDoc = snapshot.docs[snapshot.docs.length - 1];
    }

    logger.info(`Deactivate stale users completed: ${totalProcessed}`);
  }
);

export const deleteStale = onSchedule(
  {
    schedule: "0 0 15 * *",
    region: "us-east4",
    memory: "512MiB",
    timeoutSeconds: 120,
  },
  async () => {
    const currentDateInMillis = Date.now();
    const batchSize = 500;
    let lastDoc: FirebaseFirestore.QueryDocumentSnapshot | null = null;
    let totalDeleted = 0;

    // This pull the total users
    const totalUsersSnapshot = await admin
      .firestore()
      .collection("players")
      .count()
      .get();
    const totalUsers = totalUsersSnapshot.data().count;

    logger.warn(`Total app users: ${totalUsers}`);

    // This pull the users who haven't open the app for 60 days
    const usersToDeleteSnapshot = await admin
      .firestore()
      .collection("players")
      .where("active", "==", false)
      .where("lastActive", "<=", currentDateInMillis - aDayInMilliseconds * 60)
      .count()
      .get();
    const usersToDelete = usersToDeleteSnapshot.data().count;

    logger.warn(`Active users: ${totalUsers - usersToDelete}`);
    logger.warn(`Users to delete: ${usersToDelete}`);

    // *******
    // CAUTION
    // *******
    while (true) {
      let query = admin
        .firestore()
        .collection("players")
        .where("active", "==", false)
        .where("lastActive", "<=", currentDateInMillis - aDayInMilliseconds * 60)
        .orderBy("lastActive")
        .limit(batchSize);

      if (lastDoc) {
        query = query.startAfter(lastDoc);
      }

      const snapshot = await query.get();
      if (snapshot.empty) {
        break;
      }

      const batch = admin.firestore().batch();
      snapshot.docs.forEach((doc) => {
        batch.delete(doc.ref);
      });

      await batch.commit();
      totalDeleted += snapshot.size;
      lastDoc = snapshot.docs[snapshot.docs.length - 1];
    }

    logger.info(`Delete stale users completed: ${totalDeleted}`);
  }
);
