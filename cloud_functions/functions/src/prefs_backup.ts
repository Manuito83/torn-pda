import { onCall, HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import { checkUserIdKey } from "./torn_api";
import admin from "firebase-admin";

/*
 * USERSCRIPTS BACKUP MIGRATION
 * ============================
 * 
 * PROBLEM: 
 * - Original userscripts backup stores all scripts in single field: /prefs/pda_userScriptsList/prefKey
 * - This can exceed Firestore's 1MB limit per field, causing backup failures
 * 
 * SOLUTION:
 * - Migrate to subcollection: /userscripts/{scriptId}/scriptJson
 * - Each script becomes individual document, no size limits
 * 
 * MIGRATION STRATEGY:
 * 
 * 1. LEGACY STRUCTURE (original):
 *    /player_backup/{userId}/prefs/pda_userScriptsList/
 *      └── prefKey: "[{script1}, {script2}, ...]" (single huge JSON string)
 * 
 * 2. NEW STRUCTURE (target):
 *    /player_backup/{userId}/userscripts/
 *      │   └── scriptJson: "{stringified individual script object}"
 *      ├── script_1_SecondScript/
 *      │   └── scriptJson: "{stringified individual script object}"
 *      └── ...
 * 
 * 3. AUTOMATIC MIGRATION:
 *    - saveUserPrefs: When receiving pda_userScriptsList → save to new subcollection
 *    - getUserPrefs: Read from new subcollection first, fallback to legacy
 *    - Gradual migration as users backup/restore
 * 
 * 4. MANUAL MIGRATION (future):
 *    - migrateLegacyUserscripts() function available via functions:shell
 */

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

            // Special handling for userscripts - save to subcollection instead
            if (prefKey === 'pda_userScriptsList') {
                try {
                    // Parse the userscripts JSON
                    const userscripts = JSON.parse(prefValue);
                    const scriptNames = userscripts.map((script: any) => script.name);

                    // Reference to userscripts subcollection directly under player document
                    const userscriptsRef = playerBackupRef.collection('userscripts');

                    // Delete all existing userscripts first
                    const existingScripts = await userscriptsRef.get();
                    const deleteBatch = db.batch();
                    existingScripts.docs.forEach(doc => deleteBatch.delete(doc.ref));
                    await deleteBatch.commit();

                    // Add each script as individual document (as JSON string)
                    for (let i = 0; i < userscripts.length; i++) {
                        const script = userscripts[i];
                        const scriptId = `script_${i}_${script.name.replace(/[^a-zA-Z0-9]/g, '_')}`;
                        await userscriptsRef.doc(scriptId).set({
                            scriptJson: JSON.stringify(script)
                        });
                    }

                    // Delete legacy pda_userScriptsList if it exists
                    const legacyDoc = await prefsRef.doc(prefKey).get();
                    if (legacyDoc.exists) {
                        await prefsRef.doc(prefKey).delete();
                    }

                    logger.info(`Userscripts migration: ${userscripts.length} scripts [${scriptNames.join(', ')}] → subcollection (user: ${inputDetails.id})`);
                } catch (parseError) {
                    logger.warn(`Userscripts migration failed, using legacy (user: ${inputDetails.id}): ${parseError}`);
                    // Fallback to legacy storage if parsing fails
                    const prefDoc = await prefsRef.doc(prefKey).get();
                    if (!prefDoc.exists) {
                        promises.push(prefsRef.doc(prefKey).set({ prefKey: prefValue }));
                    } else {
                        promises.push(prefsRef.doc(prefKey).update({ prefKey: prefValue }));
                    }
                }
            } else {
                // Normal handling for other preferences
                const prefDoc = await prefsRef.doc(prefKey).get();

                if (!prefDoc.exists) {
                    // If the preference doesn't exist, create a new document
                    promises.push(prefsRef.doc(prefKey).set({ prefKey: prefValue }));
                } else {
                    // If the preference exists, update the document
                    promises.push(prefsRef.doc(prefKey).update({ prefKey: prefValue }));
                }
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

        // Special handling for migration: try new structure first, then fallback to legacy
        try {
            const userscriptsRef = playerBackupDoc.ref.collection('userscripts');
            const userscriptsSnapshot = await userscriptsRef.get();

            if (!userscriptsSnapshot.empty) {
                // New structure exists - reconstruct userscripts array
                const userscripts = [];
                userscriptsSnapshot.docs.forEach(doc => {
                    const scriptJson = doc.data().scriptJson;
                    if (scriptJson) {
                        const scriptData = JSON.parse(scriptJson);
                        userscripts.push(scriptData);
                    }
                });

                // Store as JSON string in dbPrefs (same format as legacy)
                dbPrefs['pda_userScriptsList'] = JSON.stringify(userscripts);

                // Remove legacy entry if it exists (cleanup)
                delete dbPrefs['pda_userScriptsList'];
                dbPrefs['pda_userScriptsList'] = JSON.stringify(userscripts);

                logger.info(`Retrieved ${userscripts.length} userscripts from new structure for user ${inputDetails.id}`);
            } else if (dbPrefs['pda_userScriptsList']) {
                // No new structure, but legacy exists - use legacy
                logger.info(`Using legacy userscripts structure for user ${inputDetails.id}`);
            }
        } catch (userscriptsError) {
            logger.warn(`Error retrieving userscripts for user ${inputDetails.id}: ${userscriptsError}`);
            // If there's an error with new structure, legacy will be used automatically
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

        // Delete the document (fields) and subcollections (prefs and userscripts)
        promises.push((async () => {
            await playerBackupRef.delete();

            // Delete the "prefs" subcollection
            const prefsCollectionRef = playerBackupRef.collection('prefs');
            const prefsSnapshot = await prefsCollectionRef.get();
            const prefsBatch = db.batch();

            prefsSnapshot.docs.forEach(doc => prefsBatch.delete(doc.ref));
            await prefsBatch.commit();

            // Delete the "userscripts" subcollection
            const userscriptsCollectionRef = playerBackupRef.collection('userscripts');
            const userscriptsSnapshot = await userscriptsCollectionRef.get();
            const userscriptsBatch = db.batch();

            userscriptsSnapshot.docs.forEach(doc => userscriptsBatch.delete(doc.ref));
            await userscriptsBatch.commit();
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

        const ownSharePrefs: string[] = Array.isArray(importConfiguration.ownSharePrefs)
            ? importConfiguration.ownSharePrefs
            : [];

        for (const [preferenceCategory, categoryKeys] of Object.entries(preferencesMapping)) {
            if (!ownSharePrefs.includes(preferenceCategory)) {
                continue;
            }

            if (preferenceCategory === 'userscripts') {
                // Share import mirrors getUserPrefs: prefer new subcollection storage, fallback to legacy field
                const userscriptsKey = categoryKeys[0];
                let userscriptsPayload: string | null = null;

                try {
                    const userscriptsRef = mainImportBackupDoc.ref.collection('userscripts');
                    const userscriptsSnapshot = await userscriptsRef.get();

                    if (!userscriptsSnapshot.empty) {
                        // New structure exists – rebuild the serialized array used by the client
                        const reconstructedScripts: any[] = [];
                        for (const scriptDoc of userscriptsSnapshot.docs) {
                            const scriptJson = scriptDoc.data().scriptJson;
                            if (!scriptJson) {
                                continue;
                            }
                            try {
                                reconstructedScripts.push(JSON.parse(scriptJson));
                            } catch (parseError) {
                                logger.warn(`Failed to parse shared userscript for user ${inputJson.shareId}: ${parseError}`);
                            }
                        }

                        if (reconstructedScripts.length > 0) {
                            // Keep output identical to legacy format: JSON string keyed by pda_userScriptsList
                            userscriptsPayload = JSON.stringify(reconstructedScripts);
                        }
                    }
                } catch (userscriptsError) {
                    logger.warn(`Error retrieving shared userscripts for user ${inputJson.shareId}: ${userscriptsError}`);
                }

                if (!userscriptsPayload) {
                    // No new structure available (or failed to parse): try legacy document stored under prefs
                    const legacyUserscriptsDoc = await userPrefsRef.doc(userscriptsKey).get();
                    if (legacyUserscriptsDoc.exists) {
                        userscriptsPayload = legacyUserscriptsDoc.data().prefKey;
                    }
                }

                if (userscriptsPayload) {
                    dbPrefs[userscriptsKey] = userscriptsPayload;
                }

                continue;
            }

            for (const preference of userPrefsSnapshot.docs) {
                if (categoryKeys.includes(preference.id)) {
                    dbPrefs[preference.id] = preference.data().prefKey;
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

// Migration for Torn PDA v3.9.3
// Call: prefsBackup.migrateLegacyUserscripts({"dryRun": true})
// Uncomment in index.ts before use
export const migrateLegacyUserscripts = onCall({
    region: 'us-east4',
    memory: "1GiB",
    timeoutSeconds: 540
}, async (request) => {
    try {
        const inputJson = JSON.parse(request.data);
        const dryRun = inputJson.dryRun || false;

        logger.info(`Starting legacy userscripts migration (dry-run: ${dryRun})`);

        const db = admin.firestore();
        let processedUsers = 0;
        let migratedUsers = 0;
        let errorUsers = 0;
        let skippedUsers = 0;
        const migrationResults: any[] = [];

        // Get all player backup documents
        const allPlayersSnapshot = await db.collection('player_backup').get();
        logger.info(`Found ${allPlayersSnapshot.docs.length} total users to check`);

        for (const playerDoc of allPlayersSnapshot.docs) {
            const userId = playerDoc.id;
            processedUsers++;

            try {
                // Check if user has legacy userscripts
                const legacyUserscriptsDoc = await playerDoc.ref
                    .collection('prefs')
                    .doc('pda_userScriptsList')
                    .get();

                if (!legacyUserscriptsDoc.exists) {
                    skippedUsers++;
                    continue;
                }

                // Check if already migrated (has userscripts subcollection)
                const userscriptsSubcollection = await playerDoc.ref.collection('userscripts').get();
                if (!userscriptsSubcollection.empty) {
                    logger.info(`User ${userId} already migrated, skipping`);
                    skippedUsers++;
                    continue;
                }

                // Parse legacy userscripts
                const legacyData = legacyUserscriptsDoc.data().prefKey;
                const userscripts = JSON.parse(legacyData);
                const scriptNames = userscripts.map((script: any) => script.name);

                const result = {
                    userId,
                    scriptCount: userscripts.length,
                    scriptNames,
                    migrated: false,
                    error: null
                };

                if (!dryRun) {
                    // Perform actual migration
                    const userscriptsRef = playerDoc.ref.collection('userscripts');

                    // Add each script as individual document (as JSON string)
                    for (let i = 0; i < userscripts.length; i++) {
                        const script = userscripts[i];
                        const scriptId = `script_${i}_${script.name.replace(/[^a-zA-Z0-9]/g, '_')}`;
                        await userscriptsRef.doc(scriptId).set({
                            scriptJson: JSON.stringify(script)
                        });
                    }

                    // Delete legacy document
                    await legacyUserscriptsDoc.ref.delete();

                    result.migrated = true;
                    migratedUsers++;

                    logger.info(`Migrated user ${userId}: ${userscripts.length} scripts [${scriptNames.join(', ')}]`);
                } else {
                    logger.info(`[DRY-RUN] Would migrate user ${userId}: ${userscripts.length} scripts [${scriptNames.join(', ')}]`);
                }

                migrationResults.push(result);

            } catch (error) {
                errorUsers++;
                logger.error(`Error processing user ${userId}: ${error}`);
                migrationResults.push({
                    userId,
                    migrated: false,
                    error: error.toString()
                });
            }
        }

        const summary = {
            totalUsers: allPlayersSnapshot.docs.length,
            processedUsers,
            migratedUsers,
            skippedUsers,
            errorUsers,
            dryRun,
            results: migrationResults
        };

        logger.info(`Migration ${dryRun ? '[DRY-RUN] ' : ''}completed: ${migratedUsers} migrated, ${skippedUsers} skipped, ${errorUsers} errors`);

        return JSON.stringify({
            success: true,
            message: `Migration ${dryRun ? '[DRY-RUN] ' : ''}completed successfully`,
            summary
        });

    } catch (e) {
        logger.error(`Migration failed: ${e}`);
        return JSON.stringify({
            success: false,
            message: `Migration failed: ${e}`,
            summary: null
        });
    }
});