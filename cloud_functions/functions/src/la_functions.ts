// la_functions.ts

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { sendTravelPushToStart } from "./la_apns_helper";

/*
 * Registers a Push-to-Start token for a specific Live Activity type
 */
export const registerPushToStartToken = functions
    .region("us-east4")
    .https.onCall(async (data, context) => {
        // Check for authentication
        if (!context.auth) {
            throw new functions.https.HttpsError(
                "unauthenticated",
                "The function must be called while authenticated."
            );
        }

        // Validate input data
        const { token, activityType } = data;
        if (!token || !activityType || typeof token !== "string" || typeof activityType !== "string") {
            throw new functions.https.HttpsError(
                "invalid-argument",
                'The function must be called with a "token" and "activityType".'
            );
        }
        if (activityType !== "travel") {
            throw new functions.https.HttpsError(
                "invalid-argument",
                `Activity type "${activityType}" is not supported.`
            );
        }

        // Update the token in Firestore
        const uid = context.auth.uid;
        const userDocRef = admin.firestore().collection("players").doc(uid);

        try {
            const tokenFieldName = `la_${activityType}_push_token`;
            await userDocRef.update({
                [tokenFieldName]: token,
            });

            functions.logger.info(`Successfully registered token for user ${uid}, field: ${tokenFieldName}`);
            return {
                success: true,
                message: `Token for ${activityType} registered.`,
            };
        } catch (error) {
            functions.logger.error(`Error registering push-to-start token for user ${uid}:`, error);
            throw new functions.https.HttpsError(
                "internal",
                "Failed to save push-to-start token."
            );
        }
    });

/*
 * DEBUG, see readme
 */
export const sendTestTravelPushToManuito = functions
    .region("us-east4")
    .https.onRequest(async (request, response) => {
        functions.logger.info("--- DEBUG LA TEST ---");

        try {
            const playersRef = admin.firestore().collection("players");
            const snapshot = await playersRef
                .where("name", "==", "Manuito")
                .where("la_travel_push_token", ">", "")
                .get();

            if (snapshot.empty) {
                const message = "No Manuito found with a travel LA token";
                functions.logger.info(message);
                response.status(404).json({ error: message });
                return;
            }

            const manuitoDocs = snapshot.docs;
            functions.logger.info(`--- DEBUG LA: Found ${manuitoDocs.length} Manuitos with LA enabled ---`);

            const now = Math.floor(Date.now() / 1000);
            const testContentState = {
                currentDestinationDisplayName: "Mexico",
                currentDestinationFlagAsset: "ball_mexico",
                originDisplayName: "Torn",
                originFlagAsset: "ball_torn",
                vehicleAssetName: "plane_right",
                activityStateTitle: "Manuito",
                departureTimeTimestamp: now,
                arrivalTimeTimestamp: now + 600,
                currentServerTimestamp: now,
                earliestReturnTimestamp: now + 60000,
                showProgressBar: true,
                hasArrived: false,
            };

            const promises = manuitoDocs.map(doc => {
                const pushToStartToken = doc.data().la_travel_push_token;
                return sendTravelPushToStart(pushToStartToken, testContentState);
            });

            const results = await Promise.all(promises);
            const successes = results.filter(r => r).length;
            const failures = results.length - successes;

            const responseMessage = `Sent to ${results.length} users. Successes: ${successes}, Failures: ${failures}.`;
            functions.logger.info(responseMessage);
            response.status(200).json({ message: responseMessage, successes, failures });

        } catch (error: any) {
            const errorMessage = "An internal error occurred during the test.";
            functions.logger.error("--- DEBUG LA: An unexpected error occurred ---", error);
            response.status(500).json({ error: errorMessage });
        }
    });