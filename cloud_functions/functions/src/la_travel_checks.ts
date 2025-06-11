// la_travel_checks.ts

import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import { FieldValue } from "firebase-admin/firestore";
import { sendTravelPushToStart } from "./la_apns_helper";

export async function handleTravelLiveActivity(
  userStats: any,
  subscriber: any
) {
  const travel = userStats.travel;

  const pushToStartToken = subscriber.la_travel_push_token;
  if (!pushToStartToken) {
    return;
  }

  if (!travel || !travel.destination || travel.time_left <= 0) {
    if (subscriber.la_travel_active_arrival_timestamp) {
      try {
        await admin
          .firestore()
          .collection("players")
          .doc(subscriber.uid)
          .update({
            la_travel_active_arrival_timestamp: FieldValue.delete(),
          });
      } catch (error) {
        functions.logger.error(
          `Failed to clean up active LA timestamp for user ${subscriber.uid}`,
          error
        );
      }
    }
    return;
  }

  try {
    const lastLAArrivalTimestamp =
      subscriber.la_travel_active_arrival_timestamp || 0;

    // New travel
    if (travel.timestamp !== lastLAArrivalTimestamp) {
      functions.logger.info(
        `New travel detected for Live Activity. User: ${subscriber.uid}, Destination: ${travel.destination}`
      );

      const isReturningToTorn = travel.destination === "Torn";
      const isChristmas = isChristmasTime();
      const contentState = {
        currentDestinationDisplayName: travel.destination,
        currentDestinationFlagAsset: isReturningToTorn
          ? "ball_torn"
          : `ball_${normalizeCountryNameForAsset(travel.destination)}`,
        originDisplayName: isReturningToTorn ? "Abroad" : "Torn",
        originFlagAsset: isReturningToTorn ? "world_origin_icon" : "ball_torn",
        arrivalTimeTimestamp: travel.timestamp,
        departureTimeTimestamp: travel.departed,
        currentServerTimestamp: Math.floor(Date.now() / 1000),
        vehicleAssetName: isChristmas
          ? "sleigh"
          : isReturningToTorn
            ? "plane_left"
            : "plane_right",
        earliestReturnTimestamp: isReturningToTorn
          ? null
          : travel.timestamp + (travel.timestamp - travel.departed),
        activityStateTitle: isReturningToTorn ? "Returning to" : "Traveling to",
        showProgressBar: true,
        hasArrived: false,
      };

      const pushSentSuccessfully = await sendTravelPushToStart(
        pushToStartToken,
        contentState
      );

      if (pushSentSuccessfully) {
        await admin
          .firestore()
          .collection("players")
          .doc(subscriber.uid)
          .update({
            la_travel_active_arrival_timestamp: travel.timestamp,
            // Delete failure case
            la_travel_push_start_first_failure_ts: FieldValue.delete(),
          });
      } else {
        // Failure... try 48 hours
        const FAILURE_GRACE_PERIOD_SECONDS = 48 * 60 * 60;

        const firstFailureTimestamp = subscriber.la_travel_push_start_first_failure_ts;
        const nowInSeconds = Math.floor(Date.now() / 1000);

        if (firstFailureTimestamp) {
          const elapsedTime = nowInSeconds - firstFailureTimestamp;

          if (elapsedTime >= FAILURE_GRACE_PERIOD_SECONDS) {
            functions.logger.warn(
              `Push-to-start failed for user ${subscriber.uid} for 48 hours. Deleting the token!`
            );
            await admin
              .firestore()
              .collection("players")
              .doc(subscriber.uid)
              .update({
                la_travel_push_token: FieldValue.delete(),
                la_travel_push_start_first_failure_ts: FieldValue.delete(),
              });
          } else {
            functions.logger.warn(
              `Push-to-start failed again for user ${subscriber.uid}. Still within 48 hours.`
            );
          }
        } else {
          functions.logger.warn(
            `Push-to-start failed for user ${subscriber.uid} for the first time in a sequence. Starting 48 hours count.`
          );
          await admin
            .firestore()
            .collection("players")
            .doc(subscriber.uid)
            .update({
              la_travel_push_start_first_failure_ts: nowInSeconds,
            });
        }
      }
    }
  } catch (error) {
    functions.logger.error(
      `ERROR in handleTravelLiveActivity for user ${subscriber.uid}:`,
      error
    );
  }
}

function isChristmasTime(): boolean {
  const now = new Date();
  const year = now.getFullYear();

  // Month 11 is December in JS... wtf!
  const christmasStart = new Date(year, 11, 19);
  const christmasEnd = new Date(year, 11, 31, 23, 59, 59);
  return now >= christmasStart && now <= christmasEnd;
}

function normalizeCountryNameForAsset(countryName: string): string {
  const normalized = countryName.toLowerCase().replace(/ /g, "-");
  switch (normalized) {
    case "united-kingdom":
      return "uk";
    case "cayman-islands":
      return "cayman";
    case "united-arab-emirates":
      return "uae";
    case "south-africa":
      return "south-africa";
    default:
      return normalized;
  }
}
