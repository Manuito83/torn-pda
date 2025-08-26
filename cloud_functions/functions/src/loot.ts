import { onSchedule } from "firebase-functions/v2/scheduler";
import { logger } from "firebase-functions/v2";
import * as admin from "firebase-admin";
import { sendNotificationToUser } from "./notification";
const fetch = require("node-fetch");
const privateKey = require("../key/torn_key");


async function getNpcHospital(npc: String, key: String) {
    const response = await fetch(`https://api.torn.com/user/${npc}?selections=&key=${key}`);
    return response.json();
}

export const updateNpcs = onSchedule(
    {
        schedule: "*/10 * * * *",
        region: "us-east4",
        memory: "512MiB",
        timeoutSeconds: 120,
    },
    async () => {
        const promises: Promise<any>[] = [];

        try {

            // Get active npcs from Realtime DB
            const firebaseAdmin = require("firebase-admin");
            const db = firebaseAdmin.database();
            const refNpcs = db.ref("loot/npcs");

            let activeNpcs = [];
            await refNpcs.once("value", function (snapshot) {
                const npcList = snapshot.val() || "";
                if (npcList.length > 0) {
                    activeNpcs = snapshot.val().split(',').map(item => item.trim());
                }

            });

            for (const id of activeNpcs) {
                const npcApi = await getNpcHospital(id, privateKey.tornKey);
                if (npcApi.status.state === "Hospital") {
                    const newHospital: any = npcApi.status.until;
                    promises.push(
                        db.ref(`loot/hospital/${id}`).set(newHospital)
                    );
                }
            }

        } catch (e) {
            logger.warn(`ERROR ACTIVE NPCS\n${e}`);
        }

        await Promise.all(promises);
    }
);

export const lootAlerts = onSchedule(
    {
        schedule: "*/1 * * * *",
        region: "us-east4",
        memory: "512MiB",
        timeoutSeconds: 120,
    },
    async () => {
        const promises: Promise<any>[] = [];

        try {

            let npcHospitalJSON = "";

            // Get NPCs one by one together with hospitalization time
            const firebaseAdmin = require("firebase-admin");
            const db = firebaseAdmin.database();

            const refNpcs = db.ref("loot/hospital");
            await refNpcs.once("value", function (snapshot) {
                const dbArray = snapshot.val() || [];
                npcHospitalJSON = JSON.parse(JSON.stringify(dbArray))
            });

            // For each NPC in the DB, see if it's approaching level 4 or 5
            if (Object.keys(npcHospitalJSON).length > 0) {
                for (const npcId of Object.keys(npcHospitalJSON)) {
                    let warnLevel = 0;
                    let warnMessage = "";
                    let npcName = "";

                    const npcTimeHospital = npcHospitalJSON[npcId];
                    const npcTimeLevel4 = npcTimeHospital + 210 * 60;
                    const npcTimeLevel5 = npcTimeHospital + 450 * 60;

                    const currentDateInMillis = Math.floor(Date.now() / 1000);
                    const timeToLevel4 = npcTimeLevel4 - currentDateInMillis;
                    const timeToLevel5 = npcTimeLevel5 - currentDateInMillis;

                    if (timeToLevel4 > 0 && timeToLevel4 < 360) {
                        const minutesRemaining = Math.round((timeToLevel4) / 60);
                        warnLevel = 4;
                        const npcApi = await getNpcHospital(npcId, privateKey.tornKey);
                        npcName = npcApi.name;
                        warnMessage = `${npcName} will reach level ${warnLevel} in about ${minutesRemaining} minutes!`;
                    }
                    else if (timeToLevel5 > 0 && timeToLevel5 < 360) {
                        const minutesRemaining = Math.round((timeToLevel5) / 60);
                        warnLevel = 5;
                        const npcApi = await getNpcHospital(npcId, privateKey.tornKey);
                        npcName = npcApi.name;
                        warnMessage = `${npcName} will reach level ${warnLevel} in about ${minutesRemaining} minutes!`;
                    } else {
                        continue;
                    }

                    // Once positive level 4/5, get last time we alerted about this (so to avoid alerting several times in a row)
                    // Then pass if last alert was less than 10 minutes ago
                    const refTimestamp = db.ref(`loot/alertsTimestamp/${npcId}`);
                    let timestamp = 0;
                    await refTimestamp.once("value", function (snapshot) {
                        const lastAlerted = snapshot.val() || 0;
                        timestamp = JSON.parse(JSON.stringify(lastAlerted));
                    });

                    const lastAlertedInSeconds = currentDateInMillis - timestamp;
                    console.log(lastAlertedInSeconds);
                    if (lastAlertedInSeconds < 600) {
                        continue;
                    }

                    // Notify users
                    let usersNotified = 0;
                    const response = await admin
                        .firestore()
                        .collection("players")
                        .where("active", "==", true)
                        .where("lootAlerts", "array-contains", `${npcId}:${warnLevel}`)
                        .get();

                    const subscribers = response.docs.map((d) => d.data());
                    for (const key of Array.from(subscribers.keys())) {
                        //console.log(subscribers[key].name);

                        let title = `${npcName} level ${warnLevel}!`;
                        let body = warnMessage;
                        if (subscribers[key].discrete) {
                            title = `L`;
                            body = `${npcName} - ${warnLevel}`;
                        }

                        promises.push(
                            sendNotificationToUser({
                                token: subscribers[key].token,
                                title: title,
                                body: body,
                                icon: "notification_loot",
                                color: "#FF0000",
                                channelId: "Alerts loot",
                                assistId: npcId,
                                vibration: subscribers[key].vibration,
                                sound: "sword_clash.aiff"
                            })
                        );

                        usersNotified++;
                        logger.info(`Loot alert for ${npcId} level ${warnLevel}: ${usersNotified} players`);

                    }

                    // And add the timestamp of the last notification, so that users are not notified twice
                    db.ref(`loot/alertsTimestamp/${npcId}`).set(currentDateInMillis);

                }
            }

        } catch (e) {
            logger.warn(`ERROR ALERTS NPCS\n${e}`);
        }

        await Promise.all(promises);
    }
);