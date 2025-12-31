import { onSchedule } from "firebase-functions/v2/scheduler";
import { logger } from "firebase-functions/v2";
import * as admin from "firebase-admin";
import { sendNotificationToUser } from "./notification";
const privateKey = require("../key/torn_key");

const LOOT_DEFAULT_AHEAD = 360; // default before v3.10.1 (6 minutes)
const LOOT_BUCKETS = [180, 360, 600];


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
                const nowSeconds = Math.floor(Date.now() / 1000);

                for (const npcId of Object.keys(npcHospitalJSON)) {
                    const npcTimeHospital = npcHospitalJSON[npcId];
                    const levels = [
                        { level: 4, ts: npcTimeHospital + 210 * 60 },
                        { level: 5, ts: npcTimeHospital + 450 * 60 },
                    ];

                    // Track pending buckets per level
                    const pendingByLevel: { level: number; ts: number; remaining: number; buckets: number[] }[] = [];

                    for (const lvl of levels) {
                        const remaining = lvl.ts - nowSeconds;
                        if (remaining <= 0) continue;

                        // RTDB per NPC/level:
                        //   key   = bucketSeconds (e.g. 300/600/900)
                        //   value = hosp+delay timestamp for which we already notified
                        // This prevents re-sending the same bucket for the same level
                        const refTimestamp = db.ref(`loot/alertsTimestamp/${npcId}/${lvl.level}`);
                        let bucketMap: Record<string, number> = {};
                        await refTimestamp.once("value", function (snapshot) {
                            bucketMap = snapshot.val() ?? {};
                        });

                        // Legacy numeric value handling (older structure)
                        if (typeof bucketMap === "number") {
                            bucketMap = { legacy: bucketMap as any };
                        }

                        // Buckets are pending only when BOTH are true:
                        //   1) Window started: remaining <= bucket (we are inside its lead time)
                        //   2) Not marked: bucketMap[bucket] !== lvl.ts (we haven't sent this bucket for this level ts)
                        const pendingBuckets = LOOT_BUCKETS.filter((bucket) => {
                            const sentForThis = bucketMap[bucket] === lvl.ts;
                            const inWindow = remaining <= bucket;
                            return inWindow && !sentForThis;
                        });

                        if (pendingBuckets.length > 0) {
                            pendingByLevel.push({ level: lvl.level, ts: lvl.ts, remaining: remaining, buckets: pendingBuckets });
                        }
                    }

                    if (pendingByLevel.length === 0) {
                        continue;
                    }

                    // Fetch NPC details once per NPC
                    const npcApi = await getNpcHospital(npcId, privateKey.tornKey);
                    const npcName = npcApi.name;

                    for (const pending of pendingByLevel) {
                        const warnLevel = pending.level;
                        const minutesRemaining = Math.round(pending.remaining / 60);
                        const warnMessage = `${npcName} will reach level ${warnLevel} in about ${minutesRemaining} minutes!`;

                        // Notify users subscribed to this NPC/level
                        const response = await admin
                            .firestore()
                            .collection("players")
                            .where("active", "==", true)
                            .where("lootAlerts", "array-contains", `${npcId}:${warnLevel}`)
                            .get();

                        const subscribers = response.docs.map((d) => d.data());
                        let usersNotified = 0;

                        const bucketMapRef = db.ref(`loot/alertsTimestamp/${npcId}/${warnLevel}`);
                        let bucketMap: Record<string, number> = {};
                        await bucketMapRef.once("value", function (snapshot) {
                            bucketMap = snapshot.val() ?? {};
                        });
                        if (typeof bucketMap === "number") {
                            bucketMap = { legacy: bucketMap as any };
                        }

                        for (const key of Array.from(subscribers.keys())) {
                            const sub = subscribers[key];
                            const ahead = typeof sub.lootAlertAheadSeconds === "number" ? sub.lootAlertAheadSeconds : LOOT_DEFAULT_AHEAD;

                            if (!pending.buckets.includes(ahead)) {
                                continue;
                            }

                            let title = `${npcName} level ${warnLevel}!`;
                            let body = warnMessage;
                            if (sub.discrete) {
                                title = `L`;
                                body = `${npcName} - ${warnLevel}`;
                            }

                            promises.push(
                                sendNotificationToUser({
                                    token: sub.token,
                                    title: title,
                                    body: body,
                                    icon: "notification_loot",
                                    color: "#FF0000",
                                    channelId: "Alerts loot",
                                    assistId: npcId,
                                    vibration: sub.vibration,
                                    sound: "sword_clash.aiff"
                                })
                            );

                            bucketMap[ahead] = pending.ts;
                            usersNotified++;
                        }

                        if (usersNotified > 0) {
                            promises.push(bucketMapRef.set(bucketMap));
                            logger.info(`Loot alert for ${npcId} level ${warnLevel}: ${usersNotified} players`);
                        }
                    }
                }
            }

        } catch (e) {
            logger.warn(`ERROR ALERTS NPCS\n${e}`);
        }

        await Promise.all(promises);
    }
);