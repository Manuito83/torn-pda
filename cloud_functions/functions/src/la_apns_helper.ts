// la_apns_helper.ts

import { logger } from "firebase-functions/v2";
import * as apn from "@parse/node-apn";

const apnsConfig = require("../key/apns_key");

const options = {
  token: {
    key: apnsConfig.privateKey,
    keyId: apnsConfig.keyId,
    teamId: apnsConfig.teamId,
  },
  // TODO: if testing locally with debug device > false x 2!
  // but DO NOT DEPLOY AS FALSE!
  production: true,
  rejectUnauthorized: true,
};

const apnProvider = new apn.Provider(options);

interface TravelLAContentState {
  currentDestinationDisplayName: string;
  currentDestinationFlagAsset: string;
  originDisplayName: string;
  originFlagAsset: string;
  arrivalTimeTimestamp: number;
  departureTimeTimestamp: number;
  currentServerTimestamp: number;
  vehicleAssetName: string;
  earliestReturnTimestamp?: number;
  activityStateTitle: string;
  showProgressBar: boolean;
  hasArrived: boolean;
}

export async function sendTravelPushToStart(
  pushToStartToken: string,
  contentState: TravelLAContentState
): Promise<boolean> {
  const topic = `${apnsConfig.bundleId}.push-type.liveactivity`;

  const notification = new apn.Notification();
  notification.topic = topic;
  notification.pushType = "liveactivity";

  notification.aps = {
    timestamp: Math.floor(Date.now() / 1000),
    event: "start",
    "relevance-score": 1.0,
    "stale-date": contentState.arrivalTimeTimestamp + 2 * 60,
    "content-state": contentState,
    "attributes-type": "TravelActivityAttributes",
    "attributes": {
      activityName: "Torn PDA Travel",
    },
    // Required as well by Apple
    "alert": {
      "title": "Travel started",
      "body": `You are now traveling to ${contentState.currentDestinationDisplayName}!`,
    }
  };

  notification.payload = {};

  try {
    logger.info(
      `Sending LA push via @parse/node-apn to token: ${pushToStartToken.substring(0, 10)}...`,
      { payload: notification.payload }
    );

    const result = await apnProvider.send(notification, pushToStartToken);

    if (result.failed.length > 0) {
      logger.error(
        `@parse/node-apn - APNs push failed`,
        result.failed[0].response
      );
      return false;
    }

    if (result.sent.length > 0) {
      logger.info(`@parse/node-apn - Successfully sent push`);
      return true;
    }

    return false;
  } catch (error) {
    logger.error("@parse/node-apn - An unexpected error occurred:", error);
    return false;
  }
}