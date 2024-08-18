import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { sendNotificationToUser } from "./notification";

export const troubleshootingGroup = {

    sendTroubleshootingAutoNotification: functions.region('us-east4').https.onCall(async (data, context) => {

        const promises: Promise<any>[] = [];

        // Get user's faction from Firestore
        const callingUser = await admin
            .firestore()
            .collection("players")
            .doc(context.auth.uid)
            .get();

        const userData = callingUser.data();

        promises.push(
            sendNotificationToUser(
                userData.token,
                "Test notification",
                "This is a test from the server to assess if Torn PDA alerts can reach you",
                "",
                "",
                "",
                "",
                "",
                "",
                "",
                userData.vibration,
                "sword_clash.aiff"
            )
        );


        functions.logger.info(`Test notification send to ${callingUser.data().name} [${callingUser.data().playerId}]`);

        await Promise.all(promises);

    }),
};