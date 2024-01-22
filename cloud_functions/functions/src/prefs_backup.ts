import * as functions from "firebase-functions";
import { checkUserIdKey } from "./torn_api";
import admin from "firebase-admin";

class UserPrefsSaveInput {
    key: string;
    id: number;
    prefs: Map<string, string>;
    constructor(key: string, id: number, prefs: Map<string, string>) {
        this.key = key;
        this.id = id;
        this.prefs = prefs;
    }
}

class UserPrefsGetInput {
    key: string;
    id: number;
    constructor(key: string, id: number) {
        this.key = key;
        this.id = id;
    }
}

class UserPrefsOutput {
    success: boolean;
    message: string;
    prefs: { [k: string]: string; };
    constructor(success: boolean, message: string, prefs: { [k: string]: string; }) {
        this.success = success;
        this.message = message;
        this.prefs = prefs;
    }
}

export const prefsBackupGroup = {

    saveUserPrefs: functions.region('us-east4').https.onCall(async (data, context) => {
        try {
            const inputJson = JSON.parse(data);
            const inputDetails = new UserPrefsSaveInput(inputJson.key, inputJson.id, inputJson.prefs);

            // Parameters check
            if (inputDetails.key === undefined || inputDetails.id === undefined || inputJson.prefs === undefined) {
                return JSON.stringify(new UserPrefsOutput(false, 'Invalid input', null));
            }

            // User authentication 
            const failReason = await validateUserAuthAndReturnError(inputJson.key, inputJson.id);
            if (failReason !== null) {
                return JSON.stringify(new UserPrefsOutput(false, failReason, null));
            }

            // Add data to database
            const db = admin.firestore();
            const promises: Promise<any>[] = [];

            // Check if player backup document exists
            const playerBackupRef = db.collection('player_backup').doc(String(inputDetails.id));
            const playerBackupDoc = await playerBackupRef.get();

            if (!playerBackupDoc.exists) {
                // If the document doesn't exist, create it
                promises.push(playerBackupRef.set({ last_saved: Date.now() }));
            } else {
                promises.push(playerBackupRef.update({ last_saved: Date.now() }));
            }

            // Get preferences collection reference
            const prefsRef = playerBackupRef.collection('prefs');

            // Iterate through input preferences and add / update them
            for (const prefKey in inputDetails.prefs) {
                const prefValue = inputDetails.prefs[prefKey];

                // Check if preference exists in preferences collection
                const prefDoc = await prefsRef.doc(prefKey).get();

                if (!prefDoc.exists) {
                    // If the preference doesn't exist, create a new document
                    promises.push(prefsRef.doc(prefKey).set({ prefKey: prefValue }));
                } else {
                    // If the preference exists, update the document
                    promises.push(prefsRef.doc(prefKey).update({ prefKey: prefValue }));
                }
            }

            // Return UserPrefsOutput object
            await Promise.all(promises);
            return JSON.stringify(new UserPrefsOutput(true, 'Successfully stored user preferences', null));
        } catch (e) {
            return JSON.stringify(new UserPrefsOutput(false, `Error: ${e}`, null));
        }
    }),

    getUserPrefs: functions.region('us-east4').https.onCall(async (data, context) => {
        try {

            const inputJson = JSON.parse(data);
            const inputDetails = new UserPrefsGetInput(inputJson.key, inputJson.id);

            // Parameters check
            if (inputDetails.key === undefined || inputDetails.id === undefined) {
                return JSON.stringify(new UserPrefsOutput(false, 'Invalid input', null));
            }

            // User authentication
            const failReason = await validateUserAuthAndReturnError(inputJson.key, inputJson.id);
            if (failReason !== null) {
                return JSON.stringify(new UserPrefsOutput(false, failReason, null));
            }

            // Get data from database
            const db = admin.firestore();
            const promises: Promise<any>[] = [];

            // Initialize dbPrefs as an empty object (not a map, since it needs to be converted to JSON)
            let dbPrefs: { [k: string]: string; } = {};

            // Check if player backup document exists
            const playerBackupRef = db.collection('player_backup').doc(String(inputDetails.id));
            const playerBackupDoc = await playerBackupRef.get();

            if (!playerBackupDoc.exists) {
                // If the document doesn't exist, create it
                return JSON.stringify(new UserPrefsOutput(true, 'No user preferences found', dbPrefs));
            }

            // Get user preferences from Firestore
            const userPrefsRef = db.collection('player_backup').doc(String(inputDetails.id)).collection('prefs');
            const userPrefsSnapshot = await userPrefsRef.get();
            for (const doc of userPrefsSnapshot.docs) {
                dbPrefs[doc.id] = doc.data().prefKey;
            }

            // Update last retrieved timestamp
            promises.push(db.collection('player_backup').doc(String(inputDetails.id)).update({ last_retrieved: Date.now() }));

            // Return UserPrefsOutput object
            await Promise.all(promises);
            return JSON.stringify(new UserPrefsOutput(true, 'Successfully retrieved user preferences', dbPrefs));

        } catch (e) {
            return JSON.stringify(new UserPrefsOutput(false, `Error: ${e}`, null));
        }
    }),

    deleteUserPrefs: functions.region('us-east4').https.onCall(async (data, context) => {
        try {

            const inputJson = JSON.parse(data);
            const inputDetails = new UserPrefsGetInput(inputJson.key, inputJson.id);

            // Parameters check
            if (inputDetails.key === undefined || inputDetails.id === undefined) {
                return JSON.stringify(new UserPrefsOutput(false, 'Invalid input', null));
            }

            // User authentication
            const failReason = await validateUserAuthAndReturnError(inputJson.key, inputJson.id);
            if (failReason !== null) {
                return JSON.stringify(new UserPrefsOutput(false, failReason, null));
            }

            // Get data from database
            const db = admin.firestore();
            const promises: Promise<any>[] = [];

            // Check if player backup document exists
            const playerBackupRef = db.collection('player_backup').doc(String(inputDetails.id));
            const playerBackupDoc = await playerBackupRef.get();

            // If the document doesn't exist, return an error
            if (!playerBackupDoc.exists) {
                return JSON.stringify(new UserPrefsOutput(false, 'User preferences not found', null));
            }

            // Delete the document (fields) and subcollections (prefs)
            promises.push((async () => {
                await playerBackupRef.delete();

                // Delete the "prefs" subcollection
                const prefsCollectionRef = playerBackupRef.collection('prefs');
                const prefsSnapshot = await prefsCollectionRef.get();
                const batch = db.batch();

                prefsSnapshot.docs.forEach(doc => batch.delete(doc.ref));
                await batch.commit();
            })());

            // Return UserPrefsOutput object
            await Promise.all(promises);
            return JSON.stringify(new UserPrefsOutput(true, 'Successfully removed user preferences', null));

        } catch (e) {
            return JSON.stringify(new UserPrefsOutput(false, `Error: ${e}`, null));
        }
    }),

};

async function validateUserAuthAndReturnError(key: string, id: number): Promise<string> {
    // Check for proper key / id match with Torn
    const userCheck = await checkUserIdKey(key, id);
    if (!userCheck) {
        return `User id & key mismatch`;
    }

    return null;
}