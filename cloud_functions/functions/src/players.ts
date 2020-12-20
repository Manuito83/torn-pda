import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

export const playersGroup = {
  onPlayerAdded: functions.region('us-east4').firestore
    .document("players/{uid}")
    .onCreate(async (snap, context) => {
      const promises: Promise<any>[] = [];
      const beforeStat = snap.data();
      
      promises.push(manageStats("totalUsers", 1));

      if (beforeStat.platform === "ios") {
        promises.push(manageStats("ios", 1));
      }

      if (beforeStat.platform === "android") {
        promises.push(manageStats("android", 1));
      }

      await Promise.all(promises);
    }),

  onPlayerDeleted: functions.region('us-east4').firestore
    .document("players/{uid}")
    .onDelete(async (snap, context) => {
      const promises: Promise<any>[] = [];
      const beforeStat = snap.data();
      
      promises.push(manageStats("totalUsers", -1));
      
      if (beforeStat.active) {
        promises.push(manageStats("activeUsers", -1));
      }

      if (beforeStat.alertsEnabled) {
        promises.push(manageStats("alertsEnabled", -1));
      }

      if (beforeStat.energyNotification) {
        promises.push(manageStats("energyNotification", -1));
      }

      if (beforeStat.nerveNotification) {
        promises.push(manageStats("nerveNotification", -1));
      }

      if (beforeStat.travelNotification) {
        promises.push(manageStats("travelNotification", -1));
      }

      if (beforeStat.hospitalNotification) {
        promises.push(manageStats("hospitalNotification", -1));
      }

      if (beforeStat.drugsNotification) {
        promises.push(manageStats("drugsNotification", -1));
      }

      if (beforeStat.racingNotification) {
        promises.push(manageStats("racingNotification", -1));
      }

      if (beforeStat.messagesNotification) {
        promises.push(manageStats("messagesNotification", -1));
      }

      if (beforeStat.platform === "android") {
        promises.push(manageStats("android", -1));
      }

      if (beforeStat.platform === "ios") {
        promises.push(manageStats("ios", -1));
      }

      await Promise.all(promises);

    }),

  onPlayerUpdated: functions.region('us-east4').firestore
    .document("players/{uid}")
    .onUpdate(async (snap, context) => {
      const promises: Promise<any>[] = [];
      const beforeStat = snap.before.data();
      const afterStat = snap.after.data();

      if (beforeStat.active !== afterStat.active)
        promises.push(manageStats("activeUsers", afterStat.active ? 1 : -1));

      if (beforeStat.alertsEnabled !== afterStat.alertsEnabled)
        promises.push(
          manageStats("alertsEnabled", afterStat.alertsEnabled ? 1 : -1)
      );

      if (beforeStat.energyNotification !== afterStat.energyNotification)
        promises.push(
          manageStats("energyNotification", afterStat.energyNotification ? 1 : -1
        )
      );

      if (beforeStat.nerveNotification !== afterStat.nerveNotification)
        promises.push(
          manageStats("nerveNotification", afterStat.nerveNotification ? 1 : -1
        )
      );
      
      if (beforeStat.travelNotification !== afterStat.travelNotification)
        promises.push(
          manageStats("travelNotification", afterStat.travelNotification ? 1 : -1
        )
      );

      if (beforeStat.hospitalNotification !== afterStat.hospitalNotification)
        promises.push(
          manageStats("hospitalNotification", afterStat.hospitalNotification ? 1 : -1
        )
      );

      if (beforeStat.drugsNotification !== afterStat.drugsNotification)
        promises.push(
          manageStats("drugsNotification", afterStat.drugsNotification ? 1 : -1
        )
      );

      if (beforeStat.racingNotification !== afterStat.racingNotification)
        promises.push(
          manageStats("racingNotification", afterStat.racingNotification ? 1 : -1
        )
      );

      if (beforeStat.messagesNotification !== afterStat.messagesNotification)
        promises.push(
          manageStats("messagesNotification", afterStat.messagesNotification ? 1 : -1
        )
      );

      if (
        !afterStat.energyNotification &&
        !afterStat.nerveNotification &&
        !afterStat.travelNotification &&
        !afterStat.hospitalNotification &&
        !afterStat.drugsNotification &&
        !afterStat.racingNotification &&
        !afterStat.messagesNotification &&
        afterStat.alertsEnabled
      )
        promises.push(
          admin
            .firestore()
            .collection("players")
            .doc(context.params.uid)
            .update({
              alertsEnabled: false,
            })
        );

      if (
        (afterStat.energyNotification
         || afterStat.nerveNotification 
         || afterStat.travelNotification
         || afterStat.hospitalNotification
         || afterStat.drugsNotification
         || afterStat.racingNotification
         || afterStat.messagesNotification) 
         && !afterStat.alertsEnabled
      )
        promises.push(
          admin
            .firestore()
            .collection("players")
            .doc(context.params.uid)
            .update({
              alertsEnabled: true,
            })
        );

      await Promise.all(promises);
    }),
};

async function manageStats(statName: string, changeInValue: number) {
  const totalUserRef = admin.database().ref().child("stats").child(statName);

  let totalUsers = parseInt((await totalUserRef.once("value")).val() || "0");
  totalUsers = totalUsers + changeInValue;
  await totalUserRef.set(totalUsers);
}
