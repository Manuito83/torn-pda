import * as admin from "firebase-admin";
import { alertsGroup } from "./alerts";
import { staleGroup } from "./stale_users"
import { playersGroup } from "./players";
import { testGroup } from "./tests";

const serviceAccount = require("../key/serviceAccountKey.json");

admin.initializeApp({
credential: admin.credential.cert(serviceAccount),
databaseURL: "https://torn-pda-manuito.firebaseio.com"
});

export const alerts = alertsGroup;
export const stale = staleGroup;
export const players = playersGroup;
export const tests = testGroup;
