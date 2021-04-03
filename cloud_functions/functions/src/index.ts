import * as admin from "firebase-admin";
import { alertsGroup } from "./alerts";
import { travelGroup } from "./travel_check";
import { staleGroup } from "./stale_users"
import { playersGroup } from "./players";
import { foreignStocksGroup } from "./foreign_stocks";
import { lootGroup } from "./loot";
// import { testGroup } from "./tests";
// import { helperGroup } from "./helpers";

const serviceAccount = require("../key/serviceAccountKey.json");

admin.initializeApp({
credential: admin.credential.cert(serviceAccount),
databaseURL: "https://torn-pda-manuito.firebaseio.com"
});

export const alerts = alertsGroup;
export const travel = travelGroup
export const stale = staleGroup;
export const players = playersGroup;
export const stocks = foreignStocksGroup;
export const loot = lootGroup;
// export const tests = testGroup;
// export const helper = helperGroup;
