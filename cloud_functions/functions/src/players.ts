import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

export const playersGroup = {
  onPlayerAdded: functions.firestore
    .document("players/{playerId}")
    .onCreate(async (snap, context) => {
      await manageStats("totalUsers", 1);
    }),

  onPlayerUpdated: functions.firestore
    .document("players/{playerId}")
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
          manageStats(
            "energyNotification",
            afterStat.energyNotification ? 1 : -1
          )
        );
      if (beforeStat.travelNotification !== afterStat.travelNotification)
        promises.push(
          manageStats(
            "travelNotification",
            afterStat.travelNotification ? 1 : -1
          )
        );

      if (
        !afterStat.energyNotification &&
        !afterStat.travelNotification &&
        afterStat.alertsEnabled
      )
        promises.push(
          admin
            .firestore()
            .collection("players")
            .doc(context.params.playerId)
            .update({
              alertsEnabled: false,
            })
        );

      if (
        (afterStat.energyNotification || afterStat.travelNotification) &&
        !afterStat.alertsEnabled
      )
        promises.push(
          admin
            .firestore()
            .collection("players")
            .doc(context.params.playerId)
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
