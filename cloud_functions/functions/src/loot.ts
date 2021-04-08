import * as functions from "firebase-functions";
const rp = require("request-promise");
const privateKey = require("../key/torn_key");


async function getNpcHospital(npc: String, key: String) {
    return rp({
        uri: `https://api.torn.com/user/${npc}?selections=&key=${key}`,
        json: true,
    });
}


export const lootGroup = {
    
    updateNpcs: functions.region('us-east4').pubsub
        .schedule("*/10 * * * *")
        .onRun(async () => {

        const promises: Promise<any>[] = [];

        try {
            
            // Get active npcs from Realtime DB
            const firebaseAdmin = require("firebase-admin");
            const db = firebaseAdmin.database();
            const refNpcs = db.ref("loot/npcs");

            let activeNpcs = [];
            await refNpcs.once("value", function(snapshot) {
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
            functions.logger.warn(`ERROR NPCS\n${e}`);
        }

        await Promise.all(promises);
    
    }),

};