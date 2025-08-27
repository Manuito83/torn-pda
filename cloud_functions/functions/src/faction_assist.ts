import { onCall } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import * as admin from "firebase-admin";
import { sendNotificationToUser } from "./notification";

export const sendAssistMessage = onCall({
    region: 'us-east4',
    memory: "512MiB",
    timeoutSeconds: 540
}, async (request) => {

    const promises: Promise<any>[] = [];

    // Get user's faction from Firestore
    const callingUser = await admin
        .firestore()
        .collection("players")
        .doc(request.auth.uid)
        .get();

    // Return error code if user or faction is not found
    if (callingUser.data() === undefined) {
        logger.info(`User not found`);
        return -1;
    }
    const faction = (callingUser.data().faction);
    if (callingUser.data().faction === undefined || callingUser.data().faction === 0) {
        logger.info(`Call from ${callingUser.data().name} [${callingUser.data().playerId}]: faction not found`);
        return -1;
    }

    // Get all faction members that allow messages to be received
    const response = await admin
        .firestore()
        .collection("players")
        .where("active", "==", true)
        .where("faction", "==", faction)
        .where("factionAssistMessage", "==", true)
        //.where("name", "==", `Manuito`)  // DEBUG (change also 'main.dart' to redirect functions)
        .where("name", "!=", `${callingUser.data().name}`) // Not the requestor's own name
        .get();

    const factionMembers = response.docs.map((d) => d.data());
    if (factionMembers.length === 0) {
        logger.info(`Call from ${callingUser.data().name} [${callingUser.data().playerId}]: 0 receptors`);
        // No one to notify
        return 0;
    };

    // Retrieve data from app call
    const attackId = request.data["attackId"].toString();

    let attackName = request.data["attackName"];
    if (attackName === "" || attackName === undefined) {
        attackName = `ID ${attackId}`;
    } else {
        attackName = `${request.data["attackName"]}`;
    }

    let attackLevelAge = request.data["attackLevel"];
    const attackAge = request.data["attackAge"];
    if (attackLevelAge === "" || attackLevelAge === undefined || attackAge === "" || attackAge === undefined) {
        attackLevelAge = "";
    } else {
        attackLevelAge = `\n- Level ${attackLevelAge} (${attackAge} days old)`;
    }

    let attackLife = request.data["attackLife"];
    if (attackLife === "" || attackLife === undefined) {
        attackLife = "";
    } else {
        attackLife = `\n- Life ${attackLife}`;
    }

    let estimatedStats = request.data["estimatedStats"];
    let exactStats = request.data["exactStats"];
    let bulkDetails = "";
    if (exactStats === "" || exactStats === undefined) {
        exactStats = "";
        // If exact stats are not available, add estimated
        if (estimatedStats === "" || estimatedStats === undefined) {
            estimatedStats = "";
        } else {
            estimatedStats = `\n- Estimated stats: ${estimatedStats}`;
            const xanax = request.data["xanax"];
            const refills = request.data["refills"];
            const drinks = request.data["drinks"];
            bulkDetails = `xanax:${xanax}#refills:${refills}#drinks:${drinks}`;
        }

    } else {
        exactStats = `\n- Spied stats: ${exactStats}`;
    }

    let membersNotified = 0;
    for (const key of Array.from(factionMembers.keys())) {
        const thisMember = factionMembers[key];

        let title = `Attack assist request!`;
        let body = `${callingUser.data().name} (level ${callingUser.data().level}) needs help attacking ${attackName}!` +
            `${attackLevelAge}${attackLife}${estimatedStats}${exactStats}`;
        if (thisMember.discrete) {
            title = `Assist`;
            body = `${attackLevelAge}`;
        }

        promises.push(
            sendNotificationToUser({
                token: thisMember.token,
                title: title,
                body: body,
                icon: "notification_assists",
                color: "#FF0000",
                channelId: "Alerts assists",
                assistId: attackId,
                bulkDetails: bulkDetails,
                vibration: thisMember.vibration,
                sound: "sword_clash.aiff",
            })
        );

        membersNotified++;
    }

    logger.info(`Call from ${callingUser.data().name} [${callingUser.data().playerId}]: ${membersNotified} receptors`);

    await Promise.all(promises);

    return membersNotified;

});