import { onCall, HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
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
    configuration: { [k: string]: string; };
    constructor(success: boolean, message: string, prefs: { [k: string]: string; }, configuration: { [k: string]: string; }) {
        this.success = success;
        this.message = message;
        this.prefs = prefs;
        this.configuration = configuration;
    }
}

class OwnSharePrefsSaveInput {
    ownShareEnabled: boolean;
    ownSharePassword: string;
    ownSharePrefs: string[];
    key: string;
    id: number;

    constructor(
        ownShareEnabled: boolean,
        ownSharePassword: string,
        ownSharePrefs: string[],
        key: string,
        id: number
    ) {
        this.ownShareEnabled = ownShareEnabled;
        this.ownSharePassword = ownSharePassword;
        this.ownSharePrefs = ownSharePrefs;
        this.key = key;
        this.id = id;
    }
}

class ImportGetInput {
    importId: number;
    importPassword: string;
    constructor(importId: number, importPassword: string) {
        this.importId = importId;
        this.importPassword = importPassword;
    }
}

export const saveUserPrefs = onCall({
    region: 'us-east4',
    memory: "512MiB",
    timeoutSeconds: 540
}, async (request) => {
    try {

        if (!request.auth) {
            throw new HttpsError('unauthenticated', 'The user is not authenticated');
        }

        const inputJson = JSON.parse(request.data);
        const inputDetails = new UserPrefsSaveInput(inputJson.key, inputJson.id, inputJson.prefs);

        // Parameters check
        if (inputDetails.key === undefined || inputDetails.id === undefined || inputJson.prefs === undefined) {
            return JSON.stringify(new UserPrefsOutput(false, 'Invalid input', null, null));
        }

        // User authentication 
        const failReason = await validateUserAuthAndReturnError(inputJson.key, inputJson.id);
        if (failReason !== null) {
            return JSON.stringify(new UserPrefsOutput(false, failReason, null, null));
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
        return JSON.stringify(new UserPrefsOutput(true, 'Successfully stored user preferences', null, null));
    } catch (e) {
        return JSON.stringify(new UserPrefsOutput(false, `Error: ${e}`, null, null));
    }
});

export const getUserPrefs = onCall({
    region: 'us-east4',
    memory: "512MiB",
    timeoutSeconds: 540
}, async (request) => {
    try {

        if (!request.auth) {
            throw new HttpsError('unauthenticated', 'The user is not authenticated');
        }

        // Parse the incoming data
        const inputJson = JSON.parse(request.data);
        const inputDetails = new UserPrefsGetInput(inputJson.key, inputJson.id);

        // Validate the inputs
        if (inputDetails.key === undefined || inputDetails.id === undefined) {
            return JSON.stringify(new UserPrefsOutput(false, 'Invalid input', null, null));
        }            // Authenticate the user
        const failReason = await validateUserAuthAndReturnError(inputJson.key, inputJson.id);
        if (failReason !== null) {
            return JSON.stringify(new UserPrefsOutput(false, failReason, null, null));
        }

        // Initialize Firestore
        const db = admin.firestore();
        const dbPrefs: { [k: string]: string; } = {};
        let dbConfiguration: { [k: string]: string; } = {};

        // Reference to the player backup document
        const playerBackupRef = db.collection('player_backup').doc(String(inputDetails.id));
        const playerBackupDoc = await playerBackupRef.get();

        // If the document doesn't exist, return with success (it's not an error per se)
        if (!playerBackupDoc.exists) {
            return JSON.stringify(new UserPrefsOutput(true, 'No user preferences found', dbPrefs, dbConfiguration));
        }

        // Fetch the data from the parent document and store it in dbConfiguration
        dbConfiguration = playerBackupDoc.data();
        // Remove the prefs field from dbConfiguration as it will be handled separately
        delete dbConfiguration.prefs;

        // Reference to the prefs subcollection
        const userPrefsRef = playerBackupDoc.ref.collection('prefs');
        const userPrefsSnapshot = await userPrefsRef.get();

        // Loop through the documents in the prefs subcollection and store them in dbPrefs
        for (const doc of userPrefsSnapshot.docs) {
            dbPrefs[doc.id] = doc.data().prefKey;
        }

        // Update the last_retrieved field in the parent document
        await playerBackupDoc.ref.update({ last_retrieved: Date.now() });

        // Return UserPrefsOutput object
        return JSON.stringify(new UserPrefsOutput(true, 'Successfully retrieved user preferences', dbPrefs, dbConfiguration));

    } catch (e) {
        return JSON.stringify(new UserPrefsOutput(false, `Error: ${e}`, null, null));
    }
});

export const deleteUserPrefs = onCall({
    region: 'us-east4',
    memory: "512MiB",
    timeoutSeconds: 540
}, async (request) => {
    try {

        if (!request.auth) {
            throw new HttpsError('unauthenticated', 'The user is not authenticated');
        }

        const inputJson = JSON.parse(request.data);
        const inputDetails = new UserPrefsGetInput(inputJson.key, inputJson.id);

        // Parameters check
        if (inputDetails.key === undefined || inputDetails.id === undefined) {
            return JSON.stringify(new UserPrefsOutput(false, 'Invalid input', null, null));
        }

        // User authentication
        const failReason = await validateUserAuthAndReturnError(inputJson.key, inputJson.id);
        if (failReason !== null) {
            return JSON.stringify(new UserPrefsOutput(false, failReason, null, null));
        }

        // Get data from database
        const db = admin.firestore();
        const promises: Promise<any>[] = [];

        // Check if player backup document exists
        const playerBackupRef = db.collection('player_backup').doc(String(inputDetails.id));
        const playerBackupDoc = await playerBackupRef.get();

        // If the document doesn't exist, return an error
        if (!playerBackupDoc.exists) {
            return JSON.stringify(new UserPrefsOutput(false, 'User preferences not found', null, null));
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
        return JSON.stringify(new UserPrefsOutput(true, 'Successfully removed user preferences', null, null));

    } catch (e) {
        return JSON.stringify(new UserPrefsOutput(false, `Error: ${e}`, null, null));
    }
});

export const setOwnSharePrefs = onCall({
    region: 'us-east4',
    memory: "512MiB",
    timeoutSeconds: 540
}, async (request) => {
    try {

        if (!request.auth) {
            throw new HttpsError('unauthenticated', 'The user is not authenticated');
        }

        // Parse the incoming data
        const inputJson = JSON.parse(request.data);
        const inputDetails = new OwnSharePrefsSaveInput(
            inputJson.ownShareEnabled,
            inputJson.ownSharePassword,
            inputJson.ownSharePrefs,
            inputJson.key,
            inputJson.id,
        );

        // Validate the inputs
        if (
            inputDetails.ownShareEnabled === undefined ||
            inputDetails.ownSharePassword === undefined ||
            inputDetails.ownSharePrefs === undefined ||
            inputDetails.key === undefined ||
            inputDetails.id === undefined
        ) {
            return JSON.stringify(
                new UserPrefsOutput(false, 'Invalid input', null, null)
            );
        }

        // Authenticate the user
        const failReason = await validateUserAuthAndReturnError(inputJson.key, inputJson.id);
        if (failReason !== null) {
            return JSON.stringify(
                new UserPrefsOutput(false, failReason, null, null)
            );
        }

        // Initialize Firestore
        const db = admin.firestore();

        // Reference to the player document
        const playerRef = db.collection('player_backup').doc(String(inputDetails.id));

        // Fetch the existing player data
        const playerDoc = await playerRef.get();
        let existingData: any = {};
        if (playerDoc.exists) {
            existingData = playerDoc.data();
        }

        // Update the existing player data using the input data
        existingData.ownShareEnabled = inputDetails.ownShareEnabled;
        existingData.ownSharePassword = inputDetails.ownSharePassword;
        existingData.ownSharePrefs = inputDetails.ownSharePrefs;
        if (!existingData.ownSharePrefs) {
            existingData.ownSharePrefs = [];
        }

        // Directly update the player document with the updated data
        await playerRef.set(existingData, { merge: false });

        // Return success response
        return JSON.stringify(
            new UserPrefsOutput(true, 'Successfully updated user share configuration', null, null)
        );

    } catch (e) {
        logger.error(`Failed to parse input data: ${e}`);
        return JSON.stringify(
            new UserPrefsOutput(false, `Error: ${e}`, null, null)
        );
    }
});

export const getImportShare = onCall({
    region: 'us-east4',
    memory: "512MiB",
    timeoutSeconds: 540
}, async (request) => {
    try {

        if (!request.auth) {
            throw new HttpsError('unauthenticated', 'The user is not authenticated');
        }

        // Parse the incoming data
        const inputJson = JSON.parse(request.data);
        const inputDetails = new ImportGetInput(inputJson.shareId, inputJson.sharePassword);

        // Validate the inputs
        if (inputDetails.importId === undefined || inputDetails.importPassword === undefined) {
            return JSON.stringify(new UserPrefsOutput(false, 'Invalid input', null, null));
        }

        // Initialize Firestore
        const db = admin.firestore();

        // Reference to the player backup document
        const mainImportBackupRef = db.collection('player_backup').doc(String(inputJson.shareId));
        const mainImportBackupDoc = await mainImportBackupRef.get();

        // If the document doesn't exist, return a failure response
        let importConfiguration: any = {};
        if (!mainImportBackupDoc.exists) {
            return JSON.stringify(new UserPrefsOutput(false, 'No backup found with the provided details!', null, null));
        } else {
            importConfiguration = mainImportBackupDoc.data();
            if (!importConfiguration.ownShareEnabled
                || importConfiguration.ownSharePassword !== inputDetails.importPassword
                || importConfiguration.ownSharePrefs.length === 0) {
                return JSON.stringify(new UserPrefsOutput(false, 'No backup found with the provided details!', null, null));
            }
        }

        // Reference to the prefs subcollection
        const userPrefsRef = mainImportBackupDoc.ref.collection('prefs');
        const userPrefsSnapshot = await userPrefsRef.get();

        const dbPrefs: { [k: string]: string; } = {};

        const preferencesMapping = {
            shortcuts: ['pda_activeShortcutsList', 'pda_shortcutMenu', 'pda_shortcutTile'],
            userscripts: ['pda_userScriptsList'],
            targets: ['pda_targetsList'],
        };

        for (const [preferenceCategory, categoryKeys] of Object.entries(preferencesMapping)) {
            if (mainImportBackupDoc.data().ownSharePrefs.includes(preferenceCategory)) {
                for (const preference of userPrefsSnapshot.docs) {
                    if (categoryKeys.includes(preference.id)) {
                        dbPrefs[preference.id] = preference.data().prefKey;
                    }
                }
            }
        }

        // Return UserPrefsOutput object
        return JSON.stringify(new UserPrefsOutput(true, 'Successfully retrieved user preferences', dbPrefs, null));

    } catch (e) {
        return JSON.stringify(new UserPrefsOutput(false, `Error: ${e}`, null, null));
    }
});

async function validateUserAuthAndReturnError(key: string, id: number): Promise<string> {
    // Check for proper key / id match with Torn
    const userCheck = await checkUserIdKey(key, id);
    if (!userCheck) {
        return `User id & key mismatch`;
    }

    return null;
}