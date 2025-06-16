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

      if (beforeStat.lifeNotification) {
        promises.push(manageStats("lifeNotification", -1));
      }

      if (beforeStat.travelNotification) {
        promises.push(manageStats("travelNotification", -1));
      }

      if (beforeStat.foreignRestockNotification) {
        promises.push(manageStats("foreignRestockNotification", -1));
      }

      if (beforeStat.hospitalNotification) {
        promises.push(manageStats("hospitalNotification", -1));
      }

      if (beforeStat.drugsNotification) {
        promises.push(manageStats("drugsNotification", -1));
      }

      if (beforeStat.medicalNotification) {
        promises.push(manageStats("medicalNotification", -1));
      }

      if (beforeStat.boosterNotification) {
        promises.push(manageStats("boosterNotification", -1));
      }

      if (beforeStat.racingNotification) {
        promises.push(manageStats("racingNotification", -1));
      }

      if (beforeStat.messagesNotification) {
        promises.push(manageStats("messagesNotification", -1));
      }

      if (beforeStat.eventsNotification) {
        promises.push(manageStats("eventsNotification", -1));
      }

      if (beforeStat.refillsNotification) {
        promises.push(manageStats("refillsNotification", -1));
      }

      if (beforeStat.stockMarketNotification) {
        promises.push(manageStats("stockMarketNotification", -1));
      }

      if (beforeStat.factionAssistMessage) {
        promises.push(manageStats("factionAssistMessage", -1));
      }

      if (beforeStat.retalsNotification) {
        promises.push(manageStats("retalsNotification", -1));
      }

      if (beforeStat.forumsSubscriptionsNotification) {
        promises.push(manageStats("forumsSubscriptionsNotification", -1));
      }

      if (beforeStat.la_travel_push_token) {
        promises.push(manageStats("la_travel_enabled", -1));
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

      if (beforeStat.lifeNotification !== afterStat.lifeNotification)
        promises.push(
          manageStats("lifeNotification", afterStat.lifeNotification ? 1 : -1
          )
        );

      if (beforeStat.travelNotification !== afterStat.travelNotification)
        promises.push(
          manageStats("travelNotification", afterStat.travelNotification ? 1 : -1
          )
        );

      if (beforeStat.foreignRestockNotification !== afterStat.foreignRestockNotification)
        promises.push(
          manageStats("foreignRestockNotification", afterStat.foreignRestockNotification ? 1 : -1
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

      if (beforeStat.medicalNotification !== afterStat.medicalNotification)
        promises.push(
          manageStats("medicalNotification", afterStat.medicalNotification ? 1 : -1
          )
        );

      if (beforeStat.boosterNotification !== afterStat.boosterNotification)
        promises.push(
          manageStats("boosterNotification", afterStat.boosterNotification ? 1 : -1
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

      if (beforeStat.eventsNotification !== afterStat.eventsNotification)
        promises.push(
          manageStats("eventsNotification", afterStat.eventsNotification ? 1 : -1
          )
        );

      if (beforeStat.refillsNotification !== afterStat.refillsNotification)
        promises.push(
          manageStats("refillsNotification", afterStat.refillsNotification ? 1 : -1
          )
        );

      if (beforeStat.stockMarketNotification !== afterStat.stockMarketNotification)
        promises.push(
          manageStats("stockMarketNotification", afterStat.stockMarketNotification ? 1 : -1
          )
        );

      if (beforeStat.factionAssistMessage !== afterStat.factionAssistMessage)
        promises.push(
          manageStats("factionAssistMessage", afterStat.factionAssistMessage ? 1 : -1
          )
        );

      if (beforeStat.retalsNotification !== afterStat.retalsNotification)
        promises.push(
          manageStats("retalsNotification", afterStat.retalsNotification ? 1 : -1
          )
        );

      if (beforeStat.forumsSubscriptionsNotification !== afterStat.forumsSubscriptionsNotification)
        promises.push(
          manageStats("forumsSubscriptionsNotification", afterStat.forumsSubscriptionsNotification ? 1 : -1
          )
        );

      const wasLaEnabled = beforeStat.la_travel_push_token ? true : false;
      const isLaEnabled = afterStat.la_travel_push_token ? true : false;
      if (wasLaEnabled !== isLaEnabled) {
        promises.push(
          manageStats("la_travel_enabled", isLaEnabled ? 1 : -1)
        );
      }

      if (
        !afterStat.energyNotification &&
        !afterStat.nerveNotification &&
        !afterStat.lifeNotification &&
        !afterStat.travelNotification &&
        !afterStat.foreignRestockNotification &&
        !afterStat.hospitalNotification &&
        !afterStat.drugsNotification &&
        !afterStat.medicalNotification &&
        !afterStat.boosterNotification &&
        !afterStat.racingNotification &&
        !afterStat.messagesNotification &&
        !afterStat.eventsNotification &&
        !afterStat.refillsNotification &&
        !afterStat.stockMarketNotification &&
        !afterStat.forumsSubscriptionsNotification &&
        // NOTE: do NOT include here notifications that are outside of the main notification loop
        // (e.g. retals, assists, loot), as they don't take into account the "alertsEnabled", but just their own parameter
        // Adding them here would cause unnecessary reads for people with "alertsEnabled" if no other specific alerts are active
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
          || afterStat.lifeNotification
          || afterStat.travelNotification
          || afterStat.foreignRestockNotification
          || afterStat.hospitalNotification
          || afterStat.drugsNotification
          || afterStat.medicalNotification
          || afterStat.boosterNotification
          || afterStat.racingNotification
          || afterStat.messagesNotification
          || afterStat.eventsNotification
          || afterStat.refillsNotification
          || afterStat.stockMarketNotification
          || afterStat.forumsSubscriptionsNotification
          // NOTE: do NOT include here notifications that are outside of the main notification loop
          // (e.g. retals, assists, loot), as they don't take into account the "alertsEnabled", but just their own parameter
          // Adding them here would cause unnecessary reads for people with "alertsEnabled" if no other specific alerts are active
        )
        && !afterStat.alertsEnabled
      ) {
        promises.push(
          admin
            .firestore()
            .collection("players")
            .doc(context.params.uid)
            .update({
              alertsEnabled: true,
            })
        );
      }

      if (afterStat.retalsNotification) {
        const firebaseAdmin = require("firebase-admin");
        const db = firebaseAdmin.database();
        db.ref(`retals/factions/${afterStat.faction}`).once("value", snapshot => {
          if (!snapshot.exists()) {
            db.ref(`retals/factions/${afterStat.faction}`).set("");
          }
        });;
      }

      await Promise.all(promises);
    }),
};

async function manageStats(statName: string, changeInValue: number) {
  const totalUserRef = admin.database().ref().child("stats").child(statName);

  let totalUsers = parseInt((await totalUserRef.once("value")).val() || "0");
  totalUsers = totalUsers + changeInValue;
  await totalUserRef.set(totalUsers);
}
