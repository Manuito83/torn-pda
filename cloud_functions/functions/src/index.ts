import * as admin from "firebase-admin";
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
import { onPlayerAdded, onPlayerDeleted, onPlayerUpdated } from "./players";
import { checkStocks, fillRestocks, oneTimeClean, deleteOldStocks } from "./foreign_stocks";
import { sendLootRangersNotification } from "./loot_rangers";
import { sendAssistMessage } from "./faction_assist";
import { saveUserPrefs, getUserPrefs, deleteUserPrefs, setOwnSharePrefs, getImportShare } from "./prefs_backup";
import { sendTroubleshootingAutoNotification } from "./troubleshooting_notification";
import { sendForumsSubscription } from "./forums";
import { registerPushToStartToken, sendTestTravelPushToManuito } from "./la_functions";

//import { helperGroup } from "./helpers";

const serviceAccount = require("../key/serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://torn-pda-manuito.firebaseio.com",
});

// Export individual alert functions instead of groups
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

export const players = {
  onPlayerAdded: onPlayerAdded,
  onPlayerDeleted: onPlayerDeleted,
  onPlayerUpdated: onPlayerUpdated
};

export const stocks = {
  checkStocks: checkStocks,
  fillRestocks: fillRestocks,
  oneTimeClean: oneTimeClean,
  deleteOldStocks: deleteOldStocks
};

export const lootRangers = {
  sendLootRangersNotification: sendLootRangersNotification
};
// Faction Assist group
export const factionAssist = {
  sendAssistMessage: sendAssistMessage
};

// Prefs Backup group
export const prefsBackup = {
  saveUserPrefs: saveUserPrefs,
  getUserPrefs: getUserPrefs,
  deleteUserPrefs: deleteUserPrefs,
  setOwnSharePrefs: setOwnSharePrefs,
  getImportShare: getImportShare
};

// Troubleshooting group
export const troubleshooting = {
  sendTroubleshootingAutoNotification: sendTroubleshootingAutoNotification
};

// Forums group  
export const forums = {
  sendForumsSubscription: sendForumsSubscription
};

export const liveActivities = {
  registerPushToStartToken: registerPushToStartToken,
  sendTestTravelPushToManuito: sendTestTravelPushToManuito,
};

//export const helper = helperGroup;
