// la_functions.ts

import { onCall, HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import * as admin from "firebase-admin";
import { sendTravelPushToStart } from "./la_apns_helper";

/*
 * Registers a Push-to-Start token for a specific Live Activity type
 */
export const registerPushToStartToken = onCall({
    region: "us-east4",
    memory: "512MiB",
    timeoutSeconds: 540
}, async (request) => {
    // Check for authentication
    if (!request.auth) {
        throw new HttpsError(
            "unauthenticated",
            "The function must be called while authenticated."
        );
    }

    // Validate input data
    const { token, activityType } = request.data;
    if (!token || !activityType || typeof token !== "string" || typeof activityType !== "string") {
        throw new HttpsError(
            "invalid-argument",
            'The function must be called with a "token" and "activityType".'
        );
    }
    if (activityType !== "travel") {
        throw new HttpsError(
            "invalid-argument",
            `Activity type "${activityType}" is not supported.`
        );
    }

    // Update the token in Firestore
    const uid = request.auth.uid;
    const userDocRef = admin.firestore().collection("players").doc(uid);

    try {
        const tokenFieldName = `la_${activityType}_push_token`;
        await userDocRef.update({
            [tokenFieldName]: token,
        });

        logger.info(`Successfully registered token for user ${uid}, field: ${tokenFieldName}`);
        return {
            success: true,
            message: `Token for ${activityType} registered.`,
        };
    } catch (error) {
        logger.error(`Error registering push-to-start token for user ${uid}:`, error);
        throw new HttpsError(
            "internal",
            "Failed to save push-to-start token."
        );
    }
});

/*
 * DEBUG, see readme
 */
export const sendTestTravelPushToManuito = onCall({
    region: "us-east4",
    memory: "512MiB",
    timeoutSeconds: 540
}, async () => {
    logger.info("--- DEBUG LA TEST ---");

    try {
        const playersRef = admin.firestore().collection("players");
        const snapshot = await playersRef
            .where("name", "==", "Manuito")
            .where("la_travel_push_token", ">", "")
            .get();

        if (snapshot.empty) {
            const message = "No Manuito found with a travel LA token";
            logger.info(message);
            return { error: message };
        }

        const manuitoDocs = snapshot.docs;
        logger.info(`--- DEBUG LA: Found ${manuitoDocs.length} Manuitos with LA enabled ---`);

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
        logger.info(responseMessage);
        return { message: responseMessage, successes, failures };

    } catch (error: any) {
        const errorMessage = "An internal error occurred during the test.";
        logger.error("--- DEBUG LA: An unexpected error occurred ---", error);
        return { error: errorMessage };
    }
});