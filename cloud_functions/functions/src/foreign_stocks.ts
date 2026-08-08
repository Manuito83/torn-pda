/**
 * This script manages and updates stock and restock information from two providers: YATA and Prometheus
 *
 * 1. Retrieves stock data from both YATA and Prometheus APIs
 * 2. Determines the most recent source for each country by comparing timestamps
 * 3. Updates Stocks/Restocks
 *    - Uses transactions to ensure concurrency safety when updating stocks in Firestore
 *    - Updates restocks in Realtime Database
 * 4. Adds Missing Items: after processing the most recent source, it checks the less recent source for any missing items and adds them.
 */

import { onSchedule } from "firebase-functions/v2/scheduler";
import { logger } from "firebase-functions/v2";
import * as admin from "firebase-admin";
import { FieldPath, FieldValue } from "firebase-admin/firestore";

// API URLs
const YATA_API_URL = "https://yata.yt/api/v1/travel/export/";
const PROMETHEUS_API_URL = "https://api.prombot.co.uk/api/travel";

// Define max entries allowed in periodicMap
const MAX_ENTRIES = 216;

// Helper function to perform fetch with a timeout
async function fetchWithTimeout(url, options = {}, timeout = 15000) {
  const controller = new AbortController();
  const id = setTimeout(() => controller.abort(), timeout);

  try {
    const response = await fetch(url, { ...options, signal: controller.signal });
    clearTimeout(id);
    return response;
  } catch (error) {
    clearTimeout(id);
    throw error;
  }
}

// Function to get data from YATA API
async function getYataStocks() {
  try {
    const response = await fetchWithTimeout(YATA_API_URL, {}, 15000);
    const data = await response.json() as any;
    return data.stocks;
  } catch (e) {
    logger.warn(`⚠️ YATA API failed: ${e.message || e}`);
    return null;
  }
}

// Function to get data from Prometheus API
async function getPrometheusStocks() {
  try {
    const response = await fetchWithTimeout(PROMETHEUS_API_URL, {}, 12000);
    const data = await response.json() as any;
    return data.stocks;
  } catch (e) {
    logger.warn(`⚠️ Prometheus API failed: ${e.message || e}`);
    return null;
  }
}

/**
 * Updates a stock in Firestore using a transaction to avoid concurrency issues.
 * @param currentStockData The stock object containing country, name, cost, quantity, etc.
 * @param timestamp The "update" timestamp from the most recent data source.
 * @param source A string indicating which provider the data came from (e.g. "YATA" or "Prometheus").
 */
async function updateStock(currentStockData: any, timestamp: number, source: string) {
  const codeName = `${currentStockData.country}-${currentStockData.name}`;
  const docRef = admin.firestore().collection("stocks-main").doc(codeName);

  try {
    await admin.firestore().runTransaction(async (transaction) => {
      // Read the existing document inside the transaction
      const docSnapshot = await transaction.get(docRef);
      const dbStockData = docSnapshot.exists ? docSnapshot.data() : {};

      // Update only if the new timestamp is more recent
      if (timestamp < (dbStockData.update || 0)) {
        return;
      }

      // Retrieve or initialize the periodicMap
      let newPeriodicMap = dbStockData.periodicMap || {};
      newPeriodicMap[timestamp] = currentStockData.quantity;

      // Sort all keys (timestamps) in descending order to keep only the MAX_ENTRIES most recent
      const allKeys = Object.keys(newPeriodicMap)
        .map(Number)
        .filter((key) => !isNaN(key))
        .sort((a, b) => b - a);

      if (allKeys.length > MAX_ENTRIES) {
        const keysToKeep = allKeys.slice(0, MAX_ENTRIES);
        const filteredMap: { [key: number]: number } = {};
        for (const k of keysToKeep) {
          filteredMap[k] = newPeriodicMap[k];
        }
        newPeriodicMap = filteredMap;
      }

      // Save the timestamp of lastEmpty if this item just transitioned to 0 quantity
      let lastEmpty = dbStockData.lastEmpty || 0;
      if (
        currentStockData.quantity === 0 &&
        (dbStockData.quantity || 0) > 0 &&
        (dbStockData.quantity || 0) < 1000
      ) {
        lastEmpty = timestamp;
      }

      // Update restockElapsed if an item was restocked
      const restockElapsed = dbStockData.restockElapsed || [];
      if (
        (dbStockData.quantity || 0) === 0 &&
        currentStockData.quantity > 0 &&
        dbStockData.lastEmpty
      ) {
        restockElapsed.push(timestamp - dbStockData.lastEmpty);
        // Keep only the last 15 restocks
        if (restockElapsed.length > 15) {
          restockElapsed.shift();
        }
      }

      // Construct the new data payload
      const newData = {
        ...dbStockData, // preserve other fields
        id: currentStockData.id,
        country: currentStockData.country,
        name: currentStockData.name,
        codeName: codeName,
        cost: currentStockData.cost,
        quantity: currentStockData.quantity,
        update: timestamp,
        source: source,
        periodicMap: newPeriodicMap,
        lastEmpty: lastEmpty,
        restockElapsed: restockElapsed,
      };

      transaction.set(docRef, newData);
    });
  } catch (e) {
    logger.warn(`ERROR updating stock ${codeName}: \n${e}`);
  }
}

// Function to update restock information in Realtime DB
async function updateRestock(currentStockData: any, timestamp: number, source: string) {
  const codeName = `${currentStockData.country}-${currentStockData.name}`;
  const firebaseAdmin = require("firebase-admin");
  const db = firebaseAdmin.database();

  try {

    // Get existing stock data from Realtime DB
    const ref = db.ref(`stocks/restocks/${codeName}`);
    const savedData = (await ref.get()).val();

    let restockTimestamp = 0;

    // If this is a known stock (the codeName key exists)
    if (savedData) {
      restockTimestamp = savedData.restock || 0;

      // We will only update the restock timestamp if we have a restock otherwise, we leave the last known restock time
      // but we continue the execution since it will be necessary to update the current quantity in any case (so that
      // we can detect restocks in the next calls in the future)
      if (savedData.quantity === 0 && currentStockData.quantity > 0) {
        restockTimestamp = timestamp;
      }
    }
    // If the stock is not known yet (new stock)
    else {
      restockTimestamp = timestamp;
    }

    let country = "";
    switch (currentStockData.country) {
      case "arg":
        country = "Argentina";
        break;
      case "can":
        country = "Canada";
        break;
      case "cay":
        country = "Cayman Islands";
        break;
      case "chi":
        country = "China";
        break;
      case "haw":
        country = "Hawaii";
        break;
      case "jap":
        country = "Japan";
        break;
      case "mex":
        country = "Mexico";
        break;
      case "sou":
        country = "South Africa";
        break;
      case "swi":
        country = "Switzerland";
        break;
      case "uae":
        country = "UAE";
        break;
      case "uni":
        country = "UK";
        break;
    }

    const stock: any = {
      country: country,
      name: currentStockData.name,
      codeName: codeName,
      id: currentStockData.id,
      cost: currentStockData.cost,
      restock: restockTimestamp,
      quantity: currentStockData.quantity,
      lastUpdated: timestamp,
      source: source,
    };

    // Update Realtime DB
    await db.ref(`stocks/restocks/${codeName}`).set(stock);

  } catch (e) {
    logger.warn(`ERROR updating restock data for ${codeName}: \n${e}`);
  }
}

// Helper function to get existing stock data
async function getExistingStockData(codeName: string, database: string) {
  try {
    if (database === "Firestore") {
      const docRef = admin.firestore().collection("stocks-main").doc(codeName);
      const docSnapshot = await docRef.get();
      return docSnapshot.exists ? docSnapshot.data() : null;
    } else if (database === "RealtimeDB") {
      const firebaseAdmin = require("firebase-admin");
      const db = firebaseAdmin.database();
      const ref = db.ref(`stocks/restocks/${codeName}`);
      const snapshot = await ref.get();
      return snapshot.exists() ? snapshot.val() : null;
    }
  } catch (e) {
    logger.warn(`ERROR getting existing stock data for ${codeName}: \n${e}`);
  }
  return null;
}

export const checkStocks = onSchedule({
  schedule: "*/10 * * * *",
  region: "us-east4",
  memory: "1GiB",
  timeoutSeconds: 240
}, async () => {
  logger.info("🔍 CHECKSTOCKS STARTING");

  try {
    const yataStocks = await getYataStocks();
    const prometheusStocks = await getPrometheusStocks();

    logger.info(`📊 Data sources - YATA: ${!!yataStocks}, Prometheus: ${!!prometheusStocks}`);

    if (!yataStocks && !prometheusStocks) {
      logger.warn("❌ No data available from either YATA or Prometheus");
      return;
    }

    // Collect all countries
    const allCountries = new Set<string>();
    if (yataStocks) Object.keys(yataStocks).forEach((c) => allCountries.add(c));
    if (prometheusStocks) Object.keys(prometheusStocks).forEach((c) => allCountries.add(c));

    logger.info(`🌍 Processing ${allCountries.size} countries: ${Array.from(allCountries).join(', ')}`);

    // Counters for summary
    let totalStocksProcessed = 0;
    let newItemsAdded = 0;
    let countriesFromYATA = 0;
    let countriesFromPrometheus = 0;

    const countryPromises = Array.from(allCountries).map(async (countryName) => {
      const yataCountryData = yataStocks ? yataStocks[countryName] : null;
      const prometheusCountryData = prometheusStocks ? prometheusStocks[countryName] : null;

      if (!yataCountryData && !prometheusCountryData) return { processed: 0, newItems: 0 };

      let mostRecentSource: string;
      let mostRecentData: any;
      let lessRecentSource: string | null = null;
      let lessRecentData: any = null;

      if (yataCountryData && prometheusCountryData) {
        mostRecentSource = yataCountryData.update > prometheusCountryData.update ? "YATA" : "Prometheus";
        mostRecentData = mostRecentSource === "YATA" ? yataCountryData : prometheusCountryData;
        lessRecentSource = mostRecentSource === "YATA" ? "Prometheus" : "YATA";
        lessRecentData = lessRecentSource === "YATA" ? yataCountryData : prometheusCountryData;
      } else if (yataCountryData) {
        mostRecentSource = "YATA";
        mostRecentData = yataCountryData;
      } else {
        mostRecentSource = "Prometheus";
        mostRecentData = prometheusCountryData;
      }

      // Count by source
      if (mostRecentSource === "YATA") countriesFromYATA++;
      if (mostRecentSource === "Prometheus") countriesFromPrometheus++;

      let countryProcessed = 0;
      let countryNewItems = 0;

      // Process most recent data (Firestore updates)
      if (mostRecentData && mostRecentData.stocks) {
        countryProcessed += mostRecentData.stocks.length;
        const updatePromises = mostRecentData.stocks.map((stock: any) => {
          stock.country = countryName;
          return updateStock(stock, mostRecentData.update, mostRecentSource);
        });
        await Promise.all(updatePromises);
      }

      // Process less recent data for missing items
      if (lessRecentData && lessRecentData.stocks && lessRecentSource) {
        const missingPromises = lessRecentData.stocks.map(async (stock: any) => {
          const codeName = `${countryName}-${stock.name}`;
          const existingData = await getExistingStockData(codeName, "Firestore");
          if (!existingData) {
            stock.country = countryName;
            await updateStock(stock, lessRecentData.update, lessRecentSource!);
            countryNewItems++;
          }
        });
        await Promise.all(missingPromises);
      }

      return { processed: countryProcessed, newItems: countryNewItems };
    });

    // Wait for all countries and sum up results
    const results = await Promise.all(countryPromises);
    results.forEach(result => {
      totalStocksProcessed += result.processed;
      newItemsAdded += result.newItems;
    });

    // Summary log
    logger.info(`✅ Completed: ${totalStocksProcessed} stocks processed across ${allCountries.size} countries. Sources: YATA(${countriesFromYATA}), Prometheus(${countriesFromPrometheus}). New items: ${newItemsAdded}`);

  } catch (e) {
    logger.error(`❌ ERROR in checkStocks: ${e}`);
    logger.error(`❌ Stack trace: ${e.stack}`);
  }
});

export const fillRestocks = onSchedule({
  schedule: "*/3 * * * *",
  region: "us-east4",
  memory: "512MiB",
  timeoutSeconds: 540
}, async () => {
  logger.info("🚀 FILLRESTOCKS STARTING");

  try {
    const yataStocks = await getYataStocks();
    const prometheusStocks = await getPrometheusStocks();

    logger.info(`📊 Data sources - YATA: ${!!yataStocks}, Prometheus: ${!!prometheusStocks}`);

    if (!yataStocks && !prometheusStocks) {
      logger.warn("❌ No data available from either YATA or Prometheus");
      return;
    }    // Collect all countries
    const allCountries = new Set<string>();
    if (yataStocks) Object.keys(yataStocks).forEach((c) => allCountries.add(c));
    if (prometheusStocks) Object.keys(prometheusStocks).forEach((c) => allCountries.add(c));

    logger.info(`🌍 Processing ${allCountries.size} countries: ${Array.from(allCountries).join(', ')}`);

    // Counters for summary
    let totalStocksProcessed = 0;
    let newItemsAdded = 0;
    let countriesFromYATA = 0;
    let countriesFromPrometheus = 0;

    const countryPromises = Array.from(allCountries).map(async (countryName) => {
      const yataCountryData = yataStocks ? yataStocks[countryName] : null;
      const prometheusCountryData = prometheusStocks ? prometheusStocks[countryName] : null;

      if (!yataCountryData && !prometheusCountryData) return { processed: 0, restocks: 0, newItems: 0 };

      let mostRecentSource: string;
      let mostRecentData: any;
      let lessRecentSource: string | null = null;
      let lessRecentData: any = null;

      if (yataCountryData && prometheusCountryData) {
        mostRecentSource = yataCountryData.update > prometheusCountryData.update ? "YATA" : "Prometheus";
        mostRecentData = mostRecentSource === "YATA" ? yataCountryData : prometheusCountryData;
        lessRecentSource = mostRecentSource === "YATA" ? "Prometheus" : "YATA";
        lessRecentData = lessRecentSource === "YATA" ? yataCountryData : prometheusCountryData;
      } else if (yataCountryData) {
        mostRecentSource = "YATA";
        mostRecentData = yataCountryData;
      } else {
        mostRecentSource = "Prometheus";
        mostRecentData = prometheusCountryData;
      }

      // Count by source
      if (mostRecentSource === "YATA") countriesFromYATA++;
      if (mostRecentSource === "Prometheus") countriesFromPrometheus++;

      let countryProcessed = 0;
      const countryRestocks = 0;
      let countryNewItems = 0;

      // Process most recent data
      if (mostRecentData && mostRecentData.stocks) {
        countryProcessed += mostRecentData.stocks.length;
        const updatePromises = mostRecentData.stocks.map((stock: any) => {
          stock.country = countryName;
          return updateRestock(stock, mostRecentData.update, mostRecentSource);
        });
        await Promise.all(updatePromises);
      }

      // Process less recent data for missing items
      if (lessRecentData && lessRecentData.stocks && lessRecentSource) {
        const missingPromises = lessRecentData.stocks.map(async (stock: any) => {
          const codeName = `${countryName}-${stock.name}`;
          const existingData = await getExistingStockData(codeName, "RealtimeDB");
          if (!existingData) {
            stock.country = countryName;
            await updateRestock(stock, lessRecentData.update, lessRecentSource!);
            countryNewItems++;
          }
        });
        await Promise.all(missingPromises);
      }

      return { processed: countryProcessed, restocks: countryRestocks, newItems: countryNewItems };
    });

    // Wait for all countries and sum up results
    const results = await Promise.all(countryPromises);
    results.forEach(result => {
      totalStocksProcessed += result.processed;
      newItemsAdded += result.newItems;
    });

    // Summary log
    logger.info(`✅ Completed: ${totalStocksProcessed} stocks processed across ${allCountries.size} countries. Sources: YATA(${countriesFromYATA}), Prometheus(${countriesFromPrometheus}). New items: ${newItemsAdded}`);

  } catch (e) {
    logger.error(`❌ ERROR in fillRestocks: ${e}`);
    logger.error(`❌ Stack trace: ${e.stack}`);
  }
});

// UTIL FUNCTION
// Safety net for periodicMap leaks
export const oneTimeClean = onSchedule({
  schedule: "0 3 * * *", // At 03:00 every day
  region: "us-east4",
  memory: "512MiB",
  timeoutSeconds: 540
}, async () => {
  logger.info("🧹 ONETIMECLEAN STARTING");

  const db = admin.firestore();

  const CONCURRENCY = 5;

  const idsSnapshot = await db.collection("stocks-main")
    .select()
    .orderBy(FieldPath.documentId())
    .get();

  const docIds = idsSnapshot.docs.map((d) => d.id);
  logger.info(`📊 Analyzing ${docIds.length} stock documents for periodicMap cleanup`);

  let numberCleared = 0;
  let totalProcessed = 0;

  const cleanOne = async (docId: string) => {
    const docRef = db.collection("stocks-main").doc(docId);
    const snapshot = await docRef.get();
    totalProcessed++;

    const bigMap = snapshot.get("periodicMap");
    if (!bigMap || typeof bigMap !== "object") return;

    const allKeys = Object.keys(bigMap)
      .map(Number)
      .filter((k) => !isNaN(k))
      .sort((a, b) => b - a);

    if (allKeys.length <= MAX_ENTRIES) return;

    const filteredMap: { [key: number]: number } = {};
    for (const k of allKeys.slice(0, MAX_ENTRIES)) {
      filteredMap[k] = bigMap[k];
    }

    await docRef.update({ periodicMap: filteredMap });
    numberCleared++;
    logger.info(`🔧 Cleaned ${docId}: reduced from ${allKeys.length} to ${MAX_ENTRIES} entries`);
  };

  for (let i = 0; i < docIds.length; i += CONCURRENCY) {
    const group = docIds.slice(i, i + CONCURRENCY);
    await Promise.all(group.map(async (docId) => {
      try {
        await cleanOne(docId);
      } catch (e) {
        logger.warn(`⚠️ Could not clean ${docId}: ${e}`);
      }
    }));
  }

  logger.info(`✅ Cleanup completed: ${numberCleared} documents cleaned out of ${totalProcessed} total`);
});

// UTIL FUNCTION
// Cleans stocks that have not been updated in 3 months (dissapeared from YATA and Prometheus)
export const deleteOldStocks = onSchedule({
  schedule: "0 4 * * 0",
  region: "us-east4",
  memory: "512MiB",
  timeoutSeconds: 540
}, async () => {
  logger.info("🗑️ DELETEOLDSTOCKS STARTING");

  // DEBUG
  // true: only prints
  // false: will delete
  const IS_DRY_RUN = false;

  if (IS_DRY_RUN) {
    logger.warn("⚠️ Running in DRY RUN mode - no deletions will be performed");
  } else {
    logger.info("🔥 Running in DELETION mode - old stocks will be removed");
  }

  const db = admin.firestore();
  const stocksRef = db.collection("stocks-main");

  const totalStocksSnapshot = await stocksRef.select().get();
  const totalStocksCount = totalStocksSnapshot.size;

  const daysThreshold = 90;
  const secondsInADay = 24 * 60 * 60;
  const nowTimestamp = Math.floor(Date.now() / 1000);
  const cutoffTimestamp = nowTimestamp - (daysThreshold * secondsInADay);

  logger.info(`📊 Searching for stocks older than ${daysThreshold} days (${totalStocksCount} total stocks)`);

  const oldStocksQuery = stocksRef.where("update", "<", cutoffTimestamp);

  try {
    const snapshot = await oldStocksQuery.get();

    if (snapshot.empty) {
      logger.info("✅ No old stocks found to delete - task completed");
      return null;
    }

    logger.info(`📋 Found ${snapshot.size} old stocks to process`);

    // --- DRY RUN ---
    if (IS_DRY_RUN) {
      for (const doc of snapshot.docs) {
        const data = doc.data();
        const updateTimestamp = data.update || 0;
        const ageInSeconds = nowTimestamp - updateTimestamp;
        const ageInMonths = (ageInSeconds / (secondsInADay * 30.44)).toFixed(1);

        logger.info(`Would delete: ${doc.id} (${ageInMonths} months old)`);
      }
      logger.info(`✅ Dry run completed - would delete ${snapshot.size} out of ${totalStocksCount} stocks`);
      return null;
    }

    // --- DELETIONS ---
    const MAX_WRITES_PER_BATCH = 500;
    const batches: admin.firestore.WriteBatch[] = [];
    let currentBatch = db.batch();
    let writeCount = 0;

    for (const doc of snapshot.docs) {
      currentBatch.delete(doc.ref);
      writeCount++;

      if (writeCount === MAX_WRITES_PER_BATCH) {
        batches.push(currentBatch);
        currentBatch = db.batch();
        writeCount = 0;
      }
    }

    if (writeCount > 0) {
      batches.push(currentBatch);
    }

    await Promise.all(batches.map(batch => batch.commit()));

    logger.info(`✅ Successfully deleted ${snapshot.size} old stocks (${totalStocksCount - snapshot.size} remaining)`);

    const deletedCodeNames = snapshot.docs.map(doc => doc.id);
    try {
      await cleanupOrphanedUserAlerts(deletedCodeNames, IS_DRY_RUN);
    } catch (cleanupError) {
      logger.error(`❌ Error during user alert cleanup (stock deletion still succeeded): ${cleanupError}`);
    }

  } catch (error) {
    logger.error(`❌ Error during deleteOldStocks: ${error}`);
    logger.error(`❌ Stack trace: ${error.stack}`);
    throw new Error("Failed to delete old stocks.");
  }

  return null;
});

/**
 * Removes orphaned codeNames from players `restockActiveAlerts` map field
 * After `deleteOldStocks` removes a batch of stocks that have been
 * forgotten for 90+ days, so users no longer hold subscriptions to items that
 * no longer exist in the providers
 */
async function cleanupOrphanedUserAlerts(deletedCodeNames: string[], isDryRun: boolean) {
  if (deletedCodeNames.length === 0) {
    logger.info("No deleted stocks to propagate to user alerts, skipping");
    return;
  }

  logger.info(`Starting user alert cleanup for ${deletedCodeNames.length} deleted stocks (dryRun=${isDryRun})`);
  const startMs = Date.now();

  const deletedSet = new Set(deletedCodeNames);
  const db = admin.firestore();
  const playersRef = db.collection("players");
  const batchSize = 500;
  const MAX_WRITES_PER_BATCH = 500;

  let lastDoc: FirebaseFirestore.QueryDocumentSnapshot | null = null;
  let playersScanned = 0;
  let playersUpdated = 0;
  let keysRemoved = 0;

  let currentBatch = db.batch();
  let writeCount = 0;
  const pendingCommits: Promise<any>[] = [];

  while (true) {
    let query: FirebaseFirestore.Query = playersRef
      .select("restockActiveAlerts")
      .orderBy(FieldPath.documentId())
      .limit(batchSize);

    if (lastDoc) {
      query = query.startAfter(lastDoc);
    }

    const snapshot = await query.get();
    if (snapshot.empty) break;

    for (const doc of snapshot.docs) {
      playersScanned++;
      const alerts = doc.get("restockActiveAlerts");
      if (!alerts || typeof alerts !== "object") continue;

      const matched: string[] = [];
      for (const key of Object.keys(alerts)) {
        if (deletedSet.has(key)) matched.push(key);
      }
      if (matched.length === 0) continue;

      playersUpdated++;
      keysRemoved += matched.length;

      if (isDryRun) {
        logger.info(`Would remove ${matched.length} keys from player ${doc.id}: ${matched.join(", ")}`);
        continue;
      }

      const updatePayload: { [path: string]: FirebaseFirestore.FieldValue } = {};
      for (const key of matched) {
        updatePayload[`restockActiveAlerts.${key}`] = FieldValue.delete();
      }
      currentBatch.update(doc.ref, updatePayload);
      writeCount++;

      if (writeCount === MAX_WRITES_PER_BATCH) {
        pendingCommits.push(currentBatch.commit());
        currentBatch = db.batch();
        writeCount = 0;
      }
    }

    lastDoc = snapshot.docs[snapshot.docs.length - 1];
  }

  if (!isDryRun && writeCount > 0) {
    pendingCommits.push(currentBatch.commit());
  }

  if (pendingCommits.length > 0) {
    await Promise.all(pendingCommits);
  }

  const durationSec = ((Date.now() - startMs) / 1000).toFixed(1);
  logger.info(
    `✅ User alert cleanup completed in ${durationSec}s — scanned ${playersScanned} players, ` +
    `${isDryRun ? "would update" : "updated"} ${playersUpdated} players, ${isDryRun ? "would remove" : "removed"} ${keysRemoved} keys`
  );
}

// Scheduled function to clean up obsolete restock entries
export const cleanupObsoleteRestocks = onSchedule("0 2 * * *", async () => {
  logger.info("🧹 Starting cleanup of obsolete restock entries...");

  const firebaseAdmin = require("firebase-admin");
  const db = firebaseAdmin.database();

  try {
    const ref = db.ref('stocks/restocks');
    const snapshot = await ref.get();

    if (!snapshot.exists()) {
      logger.info("No restock data found in Realtime Database");
      return null;
    }

    const restockData = snapshot.val();
    const now = Math.floor(Date.now() / 1000);
    const fifteenDaysAgo = now - (15 * 24 * 60 * 60);

    const keysToDelete: string[] = [];
    let totalEntries = 0;
    let obsoleteEntries = 0;

    Object.keys(restockData).forEach(codeNameKey => {
      totalEntries++;
      const stockData = restockData[codeNameKey];

      // Delete if: no lastUpdated field OR lastUpdated is older than 15 days
      if (!stockData.lastUpdated ||
        typeof stockData.lastUpdated !== 'number' ||
        stockData.lastUpdated < fifteenDaysAgo) {
        keysToDelete.push(codeNameKey);
        obsoleteEntries++;
      }
    });

    if (keysToDelete.length > 0) {
      const updates: { [key: string]: null } = {};
      keysToDelete.forEach(key => {
        updates[`stocks/restocks/${key}`] = null;
      });

      await db.ref().update(updates);

      logger.info(`🧹 Cleanup completed: Deleted ${obsoleteEntries} obsolete entries out of ${totalEntries} total entries`);
      logger.info(`📊 Remaining entries: ${totalEntries - obsoleteEntries}`);
    } else {
      logger.info(`✅ No obsolete entries found. All ${totalEntries} entries are up to date.`);
    }

    logger.info("✅ Cleanup completed successfully");
  } catch (error) {
    logger.error(`❌ Error during Realtime Database cleanup: ${error}`);
    throw error;
  }

  return null;
});
