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
  // Must be true in production (set both to false only for local debug builds)
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

interface RacingLAContentState {
  stateIdentifier: string;
  phase: string;
  titleText: string;
  bodyText: string;
  targetTimeTimestamp?: number;
  startTimeTimestamp?: number;
  currentServerTimestamp: number;
  showTimer: boolean;
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
      logger.warn(
        `@parse/node-apn - APNs push failed (reason: ${result.failed[0].response?.reason || "unknown"})`,
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

export async function sendRacingPushToStart(
  pushToStartToken: string,
  contentState: RacingLAContentState
): Promise<boolean> {
  const topic = `${apnsConfig.bundleId}.push-type.liveactivity`;

  const notification = new apn.Notification();
  notification.topic = topic;
  notification.pushType = "liveactivity";

  const staleDate = contentState.targetTimeTimestamp
    ? contentState.targetTimeTimestamp + 2 * 60
    : Math.floor(Date.now() / 1000) + 15 * 60;

  notification.aps = {
    timestamp: Math.floor(Date.now() / 1000),
    event: "start",
    "relevance-score": 1.0,
    "stale-date": staleDate,
    "content-state": contentState,
    "attributes-type": "RacingActivityAttributes",
    "attributes": {
      activityName: "Torn PDA Racing",
    },
    alert: {
      title: contentState.titleText,
      body: contentState.bodyText,
    }
  };

  notification.payload = {};

  try {
    logger.info(
      `Sending racing LA push via @parse/node-apn to token: ${pushToStartToken.substring(0, 10)}...`,
      { payload: notification.payload }
    );

    const result = await apnProvider.send(notification, pushToStartToken);

    if (result.failed.length > 0) {
      logger.warn(
        `@parse/node-apn - Racing APNs push failed (reason: ${result.failed[0].response?.reason || "unknown"})`,
      );
      return false;
    }

    if (result.sent.length > 0) {
      logger.info(`@parse/node-apn - Successfully sent racing push`);
      return true;
    }

    return false;
  } catch (error) {
    logger.error("@parse/node-apn - An unexpected error occurred while sending racing push:", error);
    return false;
  }
}

export async function sendRacingEnd(
  activityPushToken: string,
  contentState: RacingLAContentState
): Promise<boolean> {
  const topic = `${apnsConfig.bundleId}.push-type.liveactivity`;

  const notification = new apn.Notification();
  notification.topic = topic;
  notification.pushType = "liveactivity";

  notification.aps = {
    timestamp: Math.floor(Date.now() / 1000),
    event: "end",
    "relevance-score": 0.1,
    "dismissal-date": Math.floor(Date.now() / 1000),
    "stale-date": Math.floor(Date.now() / 1000),
    "content-state": contentState,
    alert: {
      title: contentState.titleText,
      body: contentState.bodyText,
    }
  };

  notification.payload = {};

  try {
    logger.info(
      `Sending racing LA end via @parse/node-apn to token: ${activityPushToken.substring(0, 10)}...`,
      { payload: notification.payload }
    );

    const result = await apnProvider.send(notification, activityPushToken);

    if (result.failed.length > 0) {
      logger.warn(
        `@parse/node-apn - Racing LA end failed (reason: ${result.failed[0].response?.reason || "unknown"})`,
      );
      return false;
    }

    if (result.sent.length > 0) {
      logger.info(`@parse/node-apn - Successfully sent racing end push`);
      return true;
    }

    return false;
  } catch (error) {
    logger.error("@parse/node-apn - An unexpected error occurred while sending racing end push:", error);
    return false;
  }
}

export type WidgetPushResult = "sent" | "invalid-token" | "failed";

export async function sendWidgetPush(widgetPushToken: string): Promise<WidgetPushResult> {
  const notification = new apn.Notification();
  notification.topic = `${apnsConfig.bundleId}.push-type.widgets`;
  notification.pushType = "widgets" as apn.NotificationPushType;
  notification.expiry = Math.floor(Date.now() / 1000) + 60 * 60;
  notification.rawPayload = { aps: { "content-changed": true } };

  try {
    const result = await apnProvider.send(notification, widgetPushToken);

    if (result.failed.length > 0) {
      const failure = result.failed[0];
      const reason = failure.response?.reason || failure.error?.message || "unknown";
      logger.warn(`@parse/node-apn - Widget push failed (status: ${failure.status}, reason: ${reason})`);
      const invalidReasons = ["BadDeviceToken", "Unregistered", "DeviceTokenNotForTopic"];
      if (Number(failure.status) === 410 || invalidReasons.includes(reason)) {
        return "invalid-token";
      }
      return "failed";
    }

    return result.sent.length > 0 ? "sent" : "failed";
  } catch (error) {
    logger.error("@parse/node-apn - An unexpected error occurred while sending widget push:", error);
    return "failed";
  }
}
