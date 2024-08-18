import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { sendNotificationToUser } from "./notification";

export const troubleshootingGroup = {

    sendTroubleshootingAutoNotification: functions.region('us-east4').https.onCall(async (data, context) => {

        let success = true;
        let name = "";
        let id = 0;

        const promises: Promise<any>[] = [];

        try {

            // Get user's faction from Firestore
            const callingUser = await admin
                .firestore()
                .collection("players")
                .doc(context.auth.uid)
                .get();

            const userData = callingUser.data();
            name = userData.name;
            id = userData.id;

            promises.push(
                sendNotificationToUser(
                    userData.token,
                    "Test notification",
                    "This is a test from the server to assess if Torn PDA alerts can reach you",
                    "notification_icon",
                    "#FFFFFF",
                    "Alerts test",
                    "",
                    "",
                    "",
                    "",
                    "medium",
                )
            );

            functions.logger.info(`Test notification sent to ${name} [${callingUser.data().playerId}]`);

        } catch (e) {
            success = false;
            functions.logger.info(`Test notification error to ${name} [${id}]: ${e}`);
        }

        await Promise.all(promises);

        return success;

    }),
};