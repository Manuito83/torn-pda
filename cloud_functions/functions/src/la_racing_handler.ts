import * as admin from "firebase-admin";
import { logger } from "firebase-functions/v2";
import { FieldValue } from "firebase-admin/firestore";
import { sendRacingPushToStart } from "./la_apns_helper";

type RacingPhase = "waiting" | "waitingUnknown" | "racing" | "finished" | "none";

interface ParsedRacingState {
    phase: RacingPhase;
    stateIdentifier?: string;
    titleText?: string;
    bodyText?: string;
    targetTimestamp?: number;
}

export async function handleRacingLiveActivity(userStats: any, subscriber: any) {
    const uid = subscriber.uid;
    const icons = userStats.icons || {};
    const currentTimestamp = userStats.timestamp || Math.floor(Date.now() / 1000);

    const laStatusRef = admin.database().ref(`live_activities/racing_status/${uid}`);
    const laStatusSnapshot = await laStatusRef.once("value");
    const activeLA = laStatusSnapshot.val();

    try {
        const parsed = parseRacingState({
            icon17: icons.icon17,
            icon18: icons.icon18,
            currentTimestamp,
        });

        if (parsed.phase === "none" || parsed.phase === "finished") {
            if (activeLA) {
                await laStatusRef.remove();
            }
            return;
        }

        // If there's already an active local or remote racing Live Activity, avoid starting duplicates.
        if (activeLA) {
            return;
        }

        // Remote push-to-start only supports the active-race countdown reliably.
        if (parsed.phase !== "racing" || !parsed.stateIdentifier || !parsed.titleText || !parsed.bodyText) {
            return;
        }

        const pushToStartToken = subscriber.la_racing_push_token;
        if (!pushToStartToken) {
            return;
        }

        const pushSentSuccessfully = await sendRacingPushToStart(pushToStartToken, {
            stateIdentifier: parsed.stateIdentifier,
            phase: parsed.phase,
            titleText: parsed.titleText,
            bodyText: parsed.bodyText,
            targetTimeTimestamp: parsed.targetTimestamp,
            currentServerTimestamp: currentTimestamp,
            showTimer: parsed.targetTimestamp != null,
        });

        if (pushSentSuccessfully) {
            await laStatusRef.set({
                stateIdentifier: parsed.stateIdentifier,
                phase: parsed.phase,
                targetTimestamp: parsed.targetTimestamp,
            });

            if (subscriber.la_racing_push_start_first_failure_ts) {
                await admin.firestore().collection("players").doc(uid).update({
                    la_racing_push_start_first_failure_ts: FieldValue.delete(),
                });
            }
        } else {
            const FAILURE_GRACE_PERIOD_SECONDS = 48 * 60 * 60;
            const firstFailureTimestamp = subscriber.la_racing_push_start_first_failure_ts;

            if (firstFailureTimestamp) {
                if (currentTimestamp - firstFailureTimestamp >= FAILURE_GRACE_PERIOD_SECONDS) {
                    await admin.firestore().collection("players").doc(uid).update({
                        la_racing_push_token: FieldValue.delete(),
                        la_racing_push_start_first_failure_ts: FieldValue.delete(),
                    });
                }
            } else {
                await admin.firestore().collection("players").doc(uid).update({
                    la_racing_push_start_first_failure_ts: currentTimestamp,
                });
            }
        }
    } catch (error) {
        logger.error(`ERROR in handleRacingLiveActivity for user ${uid}:`, error);
    }
}

function parseRacingState({
    icon17,
    icon18,
    currentTimestamp,
}: {
    icon17?: string;
    icon18?: string;
    currentTimestamp: number;
}): ParsedRacingState {
    const normalizedIcon17 = icon17?.trim();
    const normalizedIcon18 = icon18?.trim();

    if (normalizedIcon17) {
        if (normalizedIcon17.includes("Currently racing")) {
            const detail = stripRacingPrefix(normalizedIcon17);
            const remainingSeconds = parseRelativeSeconds(detail);
            const targetTimestamp = remainingSeconds == null ? undefined : currentTimestamp + remainingSeconds;
            return {
                phase: "racing",
                stateIdentifier: targetTimestamp == null ? "racing-unknown" : `racing-${targetTimestamp}`,
                titleText: "Currently racing",
                bodyText: detail,
                targetTimestamp,
            };
        }

        if (normalizedIcon17.includes("Waiting for a race to start")) {
            const detail = stripRacingPrefix(normalizedIcon17);
            const remainingSeconds = parseRelativeSeconds(detail);
            if (remainingSeconds != null) {
                return {
                    phase: "waiting",
                    stateIdentifier: `waiting-${currentTimestamp + remainingSeconds}`,
                    titleText: "Waiting to race",
                    bodyText: detail,
                    targetTimestamp: currentTimestamp + remainingSeconds,
                };
            }

            return {
                phase: "waitingUnknown",
                stateIdentifier: "waiting-unknown",
                titleText: "Waiting to race",
                bodyText: "Start time pending",
            };
        }
    }

    if (normalizedIcon18) {
        return {
            phase: "finished",
            stateIdentifier: `finished-${sanitizeIdentifier(stripRacingPrefix(normalizedIcon18))}`,
            titleText: "Race finished",
            bodyText: stripRacingPrefix(normalizedIcon18),
        };
    }

    return { phase: "none" };
}

function parseRelativeSeconds(input: string): number | null {
    const matches = [...input.matchAll(/(\d+)\s+(day|days|hour|hours|minute|minutes|second|seconds)/gi)];
    if (matches.length === 0) {
        return null;
    }

    let total = 0;
    for (const match of matches) {
        const value = Number(match[1] || 0);
        const unit = (match[2] || "").toLowerCase();
        if (unit.startsWith("day")) {
            total += value * 24 * 60 * 60;
        } else if (unit.startsWith("hour")) {
            total += value * 60 * 60;
        } else if (unit.startsWith("minute")) {
            total += value * 60;
        } else if (unit.startsWith("second")) {
            total += value;
        }
    }

    return total;
}

function stripRacingPrefix(input: string): string {
    return input.replace(/^Racing\s*-\s*/i, "").trim();
}

function sanitizeIdentifier(input: string): string {
    return input.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/-+/g, "-").replace(/(^-|-$)/g, "").slice(0, 80);
}
