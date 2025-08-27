import { onCall } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import * as admin from "firebase-admin";
import { sendNotificationToUser } from "./notification";

export const sendTroubleshootingAutoNotification = onCall({
    region: 'us-east4',
    memory: "512MiB",
    timeoutSeconds: 540
}, async (request) => {

    let success = true;
    let name = "";
    let id = 0;

    const promises: Promise<any>[] = [];

    try {

        // Get user's faction from Firestore
        const callingUser = await admin
            .firestore()
            .collection("players")
            .doc(request.auth.uid)
            .get();

        const userData = callingUser.data();
        name = userData.name;
        id = userData.id;

        promises.push(
            sendNotificationToUser({
                token: userData.token,
                title: "Test notification",
                body: "This is a test from the server to assess if Torn PDA alerts can reach you",
                icon: "notification_icon",
                color: "#FFFFFF",
                channelId: "Alerts test",
                vibration: "medium",
            })
        );

        logger.info(`Test notification sent to ${name} [${callingUser.data().playerId}]`);

    } catch (e) {
        success = false;
        logger.info(`Test notification error to ${name} [${id}]: ${e}`);
    }

    await Promise.all(promises);

    return success;

});