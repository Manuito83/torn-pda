// la_travel_handler.ts

import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import { FieldValue } from "firebase-admin/firestore";
import { sendTravelPushToStart } from "./la_apns_helper";

// NOTE: Travel Live Activities only use a push-to-start token (no updates)

/**
 * Checks a user's travel status and decides whether to start a Live Activity
 * @param userStats - Torn API
 * @param subscriber - Firestore
 */
export async function handleTravelLiveActivity(
  userStats: any,
  subscriber: any
) {
  const travel = userStats.travel;
  const uid = subscriber.uid;

  // If API shows no travel, clean up the stored timestamp and exit
  const laStatusRef = admin.database().ref(`live_activities/travel_status/${uid}`);
  const laStatusSnapshot = await laStatusRef.once("value");
  const activeLA = laStatusSnapshot.val(); // Null or { arrivalTimestamp }

  // If we are not travelling (Torn API)
  if (!travel || !travel.destination || travel.time_left <= 0) {
    // ... and RTDB has active LA, we remove it
    if (activeLA) {
      //functions.logger.info(`API travel ended for user ${uid}. Cleaning up RTDB state.`);
      await laStatusRef.remove();
    }
    return;
  }

  // If user is traveling, check if we need to start a new LA
  try {
    const lastLAArrivalTimestamp = activeLA?.arrivalTimestamp || 0;

    // Only start a new LA if the current travel's arrival time is different
    // from the one we last started an LA for. This prevents duplicate pushes
    if (travel.timestamp !== lastLAArrivalTimestamp) {
      /*
      functions.logger.info(
        `New travel detected for user ${uid}. (API: ${travel.timestamp}, RTDB: ${lastLAArrivalTimestamp}). Starting Live Activity.`
      );
      */

      const pushToStartToken = subscriber.la_travel_push_token;
      if (!pushToStartToken) {
        return;
      }

      const contentState = {
        currentDestinationDisplayName: travel.destination,
        currentDestinationFlagAsset: travel.destination === "Torn" ? "ball_torn" : `ball_${normalizeCountryNameForAsset(travel.destination)}`,
        originDisplayName: travel.destination === "Torn" ? "Abroad" : "Torn",
        originFlagAsset: travel.destination === "Torn" ? "world_origin_icon" : "ball_torn",
        arrivalTimeTimestamp: travel.timestamp,
        departureTimeTimestamp: travel.departed,
        currentServerTimestamp: Math.floor(Date.now() / 1000),
        vehicleAssetName: isChristmasTime() ? "sleigh" : (travel.destination === "Torn" ? "plane_left" : "plane_right"),
        earliestReturnTimestamp: travel.destination === "Torn" ? null : travel.timestamp + (travel.timestamp - travel.departed),
        activityStateTitle: travel.destination === "Torn" ? "Returning to" : "Traveling to",
        showProgressBar: true,
        hasArrived: false,
      };

      const pushSentSuccessfully = await sendTravelPushToStart(pushToStartToken, contentState);

      if (pushSentSuccessfully) {
        // If successful, store the new arrival timestamp to prevent future duplicates
        await laStatusRef.set({
          "arrivalTimestamp": travel.timestamp,
        });
      } else {
        // Handle push notification failure.
        const FAILURE_GRACE_PERIOD_SECONDS = 48 * 60 * 60;
        const firstFailureTimestamp = subscriber.la_travel_push_start_first_failure_ts;
        const nowInSeconds = Math.floor(Date.now() / 1000);

        if (firstFailureTimestamp) {
          if (nowInSeconds - firstFailureTimestamp >= FAILURE_GRACE_PERIOD_SECONDS) {
            // If failures persist for 48h, delete the token.
            await admin.firestore().collection("players").doc(uid).update({
              la_travel_push_token: FieldValue.delete(),
              la_travel_push_start_first_failure_ts: FieldValue.delete(),
            });
          }
        } else {
          // First failure, start tracking.
          await admin.firestore().collection("players").doc(uid).update({
            la_travel_push_start_first_failure_ts: nowInSeconds,
          });
        }
      }
    } else {
      /*
      functions.logger.info(
        `Travel for user ${uid} already has an active LA in RTDB (Timestamp: ${lastLAArrivalTimestamp}). No action taken.`
      );
      */
    }
  } catch (error) {
    functions.logger.error(`ERROR in handleTravelLiveActivity for user ${subscriber.uid}:`, error);
  }
}

function isChristmasTime(): boolean {
  const now = new Date();
  const year = now.getFullYear();
  const christmasStart = new Date(year, 11, 19);
  const christmasEnd = new Date(year, 11, 31, 23, 59, 59);
  return now >= christmasStart && now <= christmasEnd;
}

function normalizeCountryNameForAsset(countryName: string): string {
  const normalized = countryName.toLowerCase().replace(/ /g, "-");
  switch (normalized) {
    case "united-kingdom": return "uk";
    case "cayman-islands": return "cayman";
    case "united-arab-emirates": return "uae";
    case "south-africa": return "south-africa";
    default: return normalized;
  }
}