// index.ts

import * as admin from "firebase-admin";

const serviceAccount = require("../key/serviceAccountKey.json");
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://torn-pda-manuito.firebaseio.com",
});

import {
  checkIOS,
  checkAndroidLow,
  checkAndroidHigh,
  runForUser,
  sendTestNotification,
  sendMassNotification
} from "./alerts";
import { updateNpcs, lootAlerts } from "./loot";
import { deactivateStale, deleteStale } from "./stale_users";
import { sendTravelNotifications } from "./travel_check";
import { sendRefillNotifications } from "./refills";
import { evaluateRetals } from "./retals";
import { checkStocks, fillRestocks, oneTimeClean, deleteOldStocks, cleanupObsoleteRestocks } from "./foreign_stocks";
import { sendLootRangersNotification } from "./loot_rangers";
import { sendAssistMessage } from "./faction_assist";
import {
  saveUserPrefs,
  getUserPrefs,
  deleteUserPrefs,
  setOwnSharePrefs,
  getImportShare,
  // migrateLegacyUserscripts,
} from "./prefs_backup";
import { sendTroubleshootingAutoNotification } from "./troubleshooting_notification";
import { sendForumsSubscription } from "./forums";
import { registerPushToStartToken, sendTestTravelPushToManuito } from "./la_functions";

export const alerts = {
  checkIOS: checkIOS,
  checkAndroidLow: checkAndroidLow,
  checkAndroidHigh: checkAndroidHigh
};

export const alertsTest = {
  runForUser: runForUser,
  sendTestNotification: sendTestNotification,
  sendMassNotification: sendMassNotification
};

export const loot = {
  updateNpcs: updateNpcs,
  lootAlerts: lootAlerts
};

export const stale = {
  deactivateStale: deactivateStale,
  deleteStale: deleteStale
};

export const travel = {
  sendTravelNotifications: sendTravelNotifications
};

export const refills = {
  sendRefillNotifications: sendRefillNotifications
};

export const retals = {
  evaluateRetals: evaluateRetals
};

export * from "./players";

export const stocks = {
  checkStocks: checkStocks,
  fillRestocks: fillRestocks,
  oneTimeClean: oneTimeClean,
  deleteOldStocks: deleteOldStocks,
  cleanupObsoleteRestocks: cleanupObsoleteRestocks
};

export const lootRangers = {
  sendLootRangersNotification: sendLootRangersNotification
};

export const factionAssist = {
  sendAssistMessage: sendAssistMessage
};

export const prefsBackup = {
  saveUserPrefs: saveUserPrefs,
  getUserPrefs: getUserPrefs,
  deleteUserPrefs: deleteUserPrefs,
  setOwnSharePrefs: setOwnSharePrefs,
  getImportShare: getImportShare,
  //migrateLegacyUserscripts: migrateLegacyUserscripts
};

export const troubleshooting = {
  sendTroubleshootingAutoNotification: sendTroubleshootingAutoNotification
};

export const forums = {
  sendForumsSubscription: sendForumsSubscription
};

export const liveActivities = {
  registerPushToStartToken: registerPushToStartToken,
  sendTestTravelPushToManuito: sendTestTravelPushToManuito,
};