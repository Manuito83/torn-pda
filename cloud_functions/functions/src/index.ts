import * as admin from "firebase-admin";
import { alertsGroup } from "./alerts";
import { staleGroup } from "./stale_users";
import { playersGroup } from "./players";

admin.initializeApp();

export const alerts = alertsGroup;
export const stale = staleGroup;
export const players = playersGroup;
