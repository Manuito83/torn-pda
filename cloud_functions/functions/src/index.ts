import * as admin from "firebase-admin";
import { alertsGroup } from "./alerts";
import { alertsTestGroup } from "./alerts";
import { travelGroup } from "./travel_check";
import { staleGroup } from "./stale_users";
import { playersGroup } from "./players";
import { foreignStocksGroup } from "./foreign_stocks";
import { lootGroup } from "./loot";
import { lootRangersGroup } from "./loot_rangers";
import { refillsGroup } from "./refills";
import { factionAssistGroup } from "./faction_assist";
import { retalsGroup } from "./retals";
import { prefsBackupGroup } from "./prefs_backup";
import { troubleshootingGroup } from "./troubleshooting_notification";
import { forumsGroup } from "./forums";
import { registerPushToStartToken, sendTestTravelPushToManuito } from "./la_functions";

//import { testGroup } from "./tests";
//import { helperGroup } from "./helpers";

const serviceAccount = require("../key/serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://torn-pda-manuito.firebaseio.com",
});

export const alerts = alertsGroup;
export const alertsTest = alertsTestGroup;
export const travel = travelGroup;
export const stale = staleGroup;
export const players = playersGroup;
export const stocks = foreignStocksGroup;
export const loot = lootGroup;
export const lootRangers = lootRangersGroup;
export const refills = refillsGroup;
export const factionAssist = factionAssistGroup;
export const retals = retalsGroup;
export const prefsBackup = prefsBackupGroup;
export const troubleshooting = troubleshootingGroup;
export const forums = forumsGroup;
export const liveActivities = {
  registerPushToStartToken: registerPushToStartToken,
  sendTestTravelPushToManuito: sendTestTravelPushToManuito,
};
//export const tests = testGroup;
//export const helper = helperGroup;
