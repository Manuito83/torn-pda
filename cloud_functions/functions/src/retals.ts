import { onSchedule } from "firebase-functions/v2/scheduler";
import { logger } from "firebase-functions/v2";
import * as admin from "firebase-admin";
import { FactionModel, Attack, State } from "./interfaces/faction_interface";
import { sendNotificationToUser } from "./notification";
import { isDiscreetNow } from "./discreet";
import { RECIPIENT_FACTION_FIELD } from "./verified_players";
import { getFactionSelections, INVALID_KEY_ERRORS, isApiKey } from "./torn_api";
import { createHash } from "crypto";

const maxKeysPerCycle = 5;
const tornTimeoutMs = 60 * 1000;
const rejectedRetryMs = 60 * 60 * 1000;

export const evaluateRetals = onSchedule(
    {
        schedule: "*/2 * * * *",
        region: "us-east4",
        memory: "512MiB",
        timeoutSeconds: 120,
    },
    async () => {
        const promisesGlobal: Promise<any>[] = [];

        // Get factions that have at least one member signed-up for retals
        const firebaseAdmin = require("firebase-admin");
        const db = firebaseAdmin.database();
        const refFactions = db.ref("retals/factions");

        let factionsList;
        await refFactions.once("value", async function (snapshot: admin.database.DataSnapshot) {
            factionsList = snapshot.val() || "";
        });

        // Get recent attacks for each faction
        for (const id in factionsList) {
            promisesGlobal.push(checkFaction(id, factionsList, db, refFactions));
        }

        await Promise.all(promisesGlobal);
    }
);

async function checkFaction(id: any, factionsList: any, db: any, refFactions: any) {
    const promisesFaction: Promise<any>[] = [];

    let ownFactionId = 0;
    let lastSubscriber = "";
    try {
        // Placeholder in the db, skip
        if (id === "0") return;
        if (!/^[1-9]\d*$/.test(id) || !Number.isSafeInteger(+id)) {
            await refFactions.child(id).remove();
            return;
        }
        ownFactionId = +id;

        const originalNoHostWarning = factionsList[id].noHostWarning;

        // DEBUG!
        //if (ownFactionId !== 33241) return;

        if (factionsList[id].timestamp === undefined) {
            promisesFaction.push(db.ref(`retals/factions/${ownFactionId}/api`).set(""));
        }

        if (factionsList[id].api === undefined) {
            promisesFaction.push(db.ref(`retals/factions/${ownFactionId}/timestamp`).set(0));
        }

        const currentDateInMillis = Math.floor(Date.now() / 1000);
        const factionTimeUpdated = factionsList[id].timestamp;

        let subscribers: any[] = [];

        // Is any API key available?
        let savedApi = isApiKey(factionsList[id].api) ? factionsList[id].api : "";
        let apiKey = savedApi;
        const now = Date.now();
        const savedRejected = factionsList[id].rejected;
        const rejected = recentRejections(savedRejected, now);
        let tries = 0;
        let apiAttacks: any = null;

        if (apiKey !== "") {
            tries++;
            apiAttacks = await getFactionAttacks(ownFactionId, apiKey);
            if (await isUnusableKey(apiAttacks, apiKey)) {
                rejected[keyHash(apiKey)] = now;
                apiAttacks = null;
                savedApi = "";
                promisesFaction.push(db.ref(`retals/factions/${ownFactionId}/api`).set(""));
            }
        }

        if (apiAttacks === null) {
            // There might not be anything on first execution

            // Get all members subscribed from this faction and get the API key of the last active
            // Later we can use this same subscribers if needed (if there are retals)
            const factionsSubscribers = await admin
                .firestore()
                .collection("players")
                .where("active", "==", true)
                .where(RECIPIENT_FACTION_FIELD, "==", ownFactionId)  // Parsed id
                .where("retalsNotification", "==", true)
                .get();

            subscribers = factionsSubscribers.docs.map((d) => ({ ...d.data(), uid: d.id }));

            // If there are no subscribers, get rid of this faction in the database
            if (subscribers.length === 0) {
                promisesFaction.push(refFactions.child(ownFactionId).remove());
                return;
            }

            // Newest hosts first, skip recently rejected keys
            const hosts = subscribers
                .filter((s) => s.retalsNotificationHost && isApiKey(s.apiKey))
                .sort((a, b) => (b.lastActive || 0) - (a.lastActive || 0));

            apiKey = "";
            for (const host of hosts) {
                if (rejected[keyHash(host.apiKey)] !== undefined) continue;
                if (tries >= maxKeysPerCycle) break;
                tries++;
                apiAttacks = await getFactionAttacks(ownFactionId, host.apiKey);
                if (await isUnusableKey(apiAttacks, host.apiKey)) {
                    rejected[keyHash(host.apiKey)] = now;
                    apiAttacks = null;
                    continue;
                }
                apiKey = host.apiKey;
                break;
            }

            // Update the faction apiKey and rejected hosts
            const hostHashes = new Set(hosts.map((host) => keyHash(host.apiKey)));
            const rejectedHosts = Object.fromEntries(Object.entries(rejected).filter(([hash]) => hostHashes.has(hash)));
            if (apiKey !== savedApi) {
                promisesFaction.push(db.ref(`retals/factions/${ownFactionId}/api`).set(apiKey));
            }
            if (!sameRejected(rejectedHosts, savedRejected)) {
                promisesFaction.push(db.ref(`retals/factions/${ownFactionId}/rejected`).set(rejectedHosts));
            }

            if (apiAttacks === null) {
                // No usable key left, warn once
                if (!originalNoHostWarning && hosts.every((host) => rejected[keyHash(host.apiKey)] !== undefined)) {
                    promisesFaction.push(...warnNoHost(subscribers));
                    promisesFaction.push(db.ref(`retals/factions/${ownFactionId}/noHostWarning`).set(true));
                }
                await Promise.all(promisesFaction);
                return;
            }
        }

        // Torn did not answer, keep the timestamp
        if (apiAttacks.error) {
            await Promise.all(promisesFaction);
            return;
        }

        // Rearm the no-hosts warning
        if (originalNoHostWarning) {
            promisesFaction.push(db.ref(`retals/factions/${ownFactionId}/noHostWarning`).set(false));
        }

        // Update the faction timestamp
        promisesFaction.push(db.ref(`retals/factions/${ownFactionId}/timestamp`).set(currentDateInMillis));

        const factionModel: FactionModel = apiAttacks;

        let notificationTitle = "";
        let notificationBody = ""
        let numberOrRetals = 0;
        let lastRetalAttackerId = "";
        let lastRetalName = "";
        let lastRetalTargetId = 0;
        const allRetalNames = [];
        const allRetalNamesTrimmed: string[] = [];
        let retalMinutesRemaining = 0;
        let totalRetalsAbroad = 0;

        // Get all susceptible attacks (5 minutes)
        const lastFiveMinutes: Attack[] = [];

        for (const attackId in factionModel.attacks) {
            if (factionModel.attacks[attackId].attacker_name !== "" &&
                currentDateInMillis - factionModel.attacks[attackId].timestamp_ended < 300 &&
                factionModel.attacks[attackId].timestamp_ended > factionTimeUpdated
            ) {
                lastFiveMinutes.push(factionModel.attacks[attackId]);
            }
        }

        for (const incomingId in lastFiveMinutes) {
            // This is a valid incoming won attack in the last five minutes
            if (lastFiveMinutes[incomingId].attacker_faction !== ownFactionId &&
                lastFiveMinutes[incomingId].respect > 0) {

                let alreadyRetaliated = false;
                // Ensure that we have not retaliated already
                for (const outgoingId in lastFiveMinutes) {
                    if (lastFiveMinutes[outgoingId].timestamp_started > lastFiveMinutes[incomingId].timestamp_ended &&
                        lastFiveMinutes[outgoingId].defender_name === lastFiveMinutes[incomingId].attacker_name &&
                        lastFiveMinutes[outgoingId].respect > 0) {
                        alreadyRetaliated = true;
                    }
                }
                if (alreadyRetaliated) continue;

                // Discard duplicated names (successive attacks)
                if (allRetalNamesTrimmed.includes(lastFiveMinutes[incomingId].attacker_name)) {
                    continue;
                }

                // If we reached here, it's a valid retal
                numberOrRetals++;
                lastRetalAttackerId = lastFiveMinutes[incomingId].attacker_id.toString();
                lastRetalTargetId = lastFiveMinutes[incomingId].defender_id;
                lastRetalName = lastFiveMinutes[incomingId].attacker_name;

                if (lastFiveMinutes[incomingId].modifiers.overseas > 1) {
                    totalRetalsAbroad++;
                }

                allRetalNamesTrimmed.push(lastRetalName);
                if (allRetalNames.length === 0) {
                    allRetalNames.push(lastRetalName);
                } else {
                    allRetalNames.push(` ${lastRetalName}`);
                }
                retalMinutesRemaining = Math.round((lastFiveMinutes[incomingId].timestamp_ended + 300 - currentDateInMillis) / 60);

                // DEBUG
                /*
                functions.logger.warn(`Retal CODE: ${lastFiveMinutes[incomingId].code}`);
                functions.logger.warn(`Retal time_stamp: ${lastFiveMinutes[incomingId].timestamp_ended}`);
                functions.logger.warn(`CurrentDateInMillis: ${currentDateInMillis}`);
                functions.logger.warn(`Minutes notified: ${retalMinutesRemaining}`);
                console.log("________________");
                console.log(`Code: ${lastFiveMinutes[incomingId].code}`);
                console.log(`Retal number: ${numberOrRetals}`);
                console.log(`Retal player id: ${lastRetalAttackerId}`);
                console.log(`Retal player name: ${lastRetalName}`);
                console.log(`Retal minutes: ${retalMinutesRemaining}`);
                */
            }
        }

        if (numberOrRetals === 0) return;

        if (numberOrRetals === 1) {
            notificationTitle = `Retal on ${lastRetalName}`;
            notificationBody = `Expires in ${retalMinutesRemaining} minutes`;
        } else {
            notificationTitle = `${numberOrRetals} retals active!`;
            notificationBody = `${allRetalNames}`;
        }

        // If we didn't fill the subscribers before, do it now and also update the apiKey
        if (subscribers.length === 0) {
            const refillSubscribers = await admin
                .firestore()
                .collection("players")
                .where("active", "==", true)
                .where(RECIPIENT_FACTION_FIELD, "==", ownFactionId)  // Parsed id
                .where("retalsNotification", "==", true)
                .get();

            subscribers = refillSubscribers.docs.map((d) => ({ ...d.data(), uid: d.id }));

            // If there are no subscribers, get rid of this faction in the database
            if (subscribers.length === 0) {
                promisesFaction.push(refFactions.child(ownFactionId).remove());
                return;
            }

            // Update with the most recent updated subscriber
            // (to ensure that the apiKey is valid)
            let lastActiveUserTime = 0;
            let lastActiveUserApiKey = "";

            for (const key of Array.from(subscribers.keys())) {
                if (!subscribers[key].retalsNotificationHost) continue;
                if (!isApiKey(subscribers[key].apiKey) || rejected[keyHash(subscribers[key].apiKey)] !== undefined) continue;

                if (subscribers[key].lastActive > lastActiveUserTime) {
                    lastActiveUserTime = subscribers[key].lastActive;
                    lastActiveUserApiKey = subscribers[key].apiKey;
                }
            }

            // Update the faction apiKey
            promisesFaction.push(db.ref(`retals/factions/${ownFactionId}/api`).set(lastActiveUserApiKey));
        }

        for (const key of Array.from(subscribers.keys())) {
            // DEBUG
            /*
            console.log(`############`);
            console.log(`Notification title: ${notificationTitle}`);
            console.log(`Notification body: ${notificationBody}`);
            console.log(`Subscriber's ID: ${subscribers[key].playerId}`);
            console.log(`Retal attacker's ID: ${lastRetalAttackerId}`);
            console.log(`Retal target's ID: ${lastRetalTargetId}`);
            console.log(`Retals abroad: ${totalRetalsAbroad}`);
            */

            if (numberOrRetals === 1 && subscribers[key].playerId === lastRetalTargetId) {
                // Avoid notifying about own retaliations suffered by one self
                // (limited to when there is only one retal to notify)
                continue;
            }

            // Find out where our subscriber is
            let subscriberState = "";
            for (const memberId in factionModel.members) {
                if (factionModel.members[memberId].name === subscribers[key].name) {
                    subscriberState = factionModel.members[memberId].status.state.toString();
                }
            }

            // CASES WHEN TRAVELING
            // If subscriber is traveling, do not disturb
            if (subscriberState === State.Traveling) {
                continue;
            }
            // If he is in Torn and all retals are abroad, don't notify
            else if (subscriberState === State.Okay) {
                if (totalRetalsAbroad === numberOrRetals) {
                    continue;
                }
            }
            // If he is abroad and all retals took place in Torn, don't notify
            else if (subscriberState === State.Abroad) {
                if (totalRetalsAbroad === 0) {
                    continue;
                }
            }

            // API FACTION PERMISSION DONOR
            // (this user chose to serve as a host, but not to be notified)
            if (subscribers[key].retalsNotificationDonor) {
                continue;
            }

            // DEBUG! 
            // DEBUG! 
            // DEBUG! 
            //if (subscribers[key].name !== "Manuito") continue;

            let title = notificationTitle;
            let body = notificationBody;
            if (isDiscreetNow(subscribers[key])) {
                title = `Retal`;
                body = ` `;
            }

            lastSubscriber = subscribers[key].uid;

            promisesFaction.push(
                sendNotificationToUser({
                    token: subscribers[key].token,
                    title: title,
                    body: body,
                    icon: "notification_retals",
                    color: "#FF0000",
                    channelId: "Alerts retals",
                    assistId: lastRetalAttackerId,
                    bulkDetails: numberOrRetals.toString(),
                    vibration: subscribers[key].vibration,
                    sound: "sword_clash.aiff"
                })
            );
        }

        logger.info(`Retals faction ${ownFactionId}: ${subscribers.length} players`);
        await Promise.all(promisesFaction);

    } catch (e) {

        logger.warn(`Subscriber ${lastSubscriber}\nERROR RETALS:\n${e}`);
        if (e.toString().includes("Requested entity was not found")) {
            /*
            await admin
                .firestore()
                .collection("players")
                .doc(lastSubscriber)
                .delete();
            functions.logger.warn(`Staled: ${lastSubscriber}`);
            */
        }

        return;
    }
}

async function getFactionAttacks(factionId: number, apiKey: string) {
    return getFactionSelections(factionId, "basic,attacks", apiKey, "PDA-App", tornTimeoutMs);
}

// Stored instead of the key
function keyHash(apiKey: string) {
    return createHash("sha256").update(apiKey).digest("hex").slice(0, 16);
}

function recentRejections(saved: any, now: number): Record<string, number> {
    if (typeof saved !== "object" || saved === null) return {};
    return Object.fromEntries(Object.entries(saved)
        .filter(([, at]) => typeof at === "number" && now - at < rejectedRetryMs)) as Record<string, number>;
}

function sameRejected(current: Record<string, number>, saved: any) {
    const sorted = (rejected: any) => JSON.stringify(Object.entries(rejected ?? {}).sort());
    return sorted(current) === sorted(typeof saved === "object" ? saved : {});
}

function warnNoHost(subscribers: any[]) {
    return subscribers.map((subscriber) => {
        let title = "Retaliation notifications inactive";
        let body = "No users in this faction detected with faction API access permits " +
            "and retaliation notifications active in Torn PDA.\n\n" +
            "Retaliation notifications might not work!";
        if (isDiscreetNow(subscriber)) {
            title = `Retals`;
            body = `Inactive`;
        }
        return sendNotificationToUser({
            token: subscriber.token,
            title: title,
            body: body,
            icon: "notification_retals",
            color: "#FF0000",
            channelId: "Alerts retals",
            assistId: "-1",
            bulkDetails: "-1",
            vibration: subscriber.vibration,
            sound: "sword_clash.aiff"
        }).catch((e) => logger.warn(`ERROR RETALS NO HOST\n${e}`));
    });
}

// Skip unusable keys, demote only 7
async function isUnusableKey(apiAttacks: any, apiKey: string) {
    const code = apiAttacks?.error?.code;
    if (INVALID_KEY_ERRORS.includes(code)) return true;
    if (code !== 7) return false;

    const sameKeyUsers = await admin
        .firestore()
        .collection("players")
        .where("apiKey", "==", apiKey)
        .get();
    await Promise.all(sameKeyUsers.docs.map((d) => d.ref.update({ retalsNotificationHost: false })));
    return true;
}