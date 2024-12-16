/**
 * This script manages and updates stock and restock information from two providers: YATA and Prometheus
 * 
 * 1. Retrieves stock data from both YATA and Prometheus APIs
 * 2. Determines most recent source: for each country, it compares the timestamps from YATA and Prometheus to determine which provider has the most up-to-date data
 * 3. Updates Stocks/Restocks
 *    - It updates stocks in Firestore and restocks in Realtime Database using the data from the most recent source
 *    - It only updates an item if the incoming timestamp is newer than the existing timestamp in the database
 * 4. Adds Missing Items: after processing the most recent source, it checks the less recent source for any missing items (items not present in the database). 
 *    It then adds these missing items to the database.
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
const fetch = require("node-fetch");

const runtimeOpts1024 = {
  timeoutSeconds: 240,
  memory: "1GB" as "1GB",
}

// API URLs
const YATA_API_URL = 'https://yata.yt/api/v1/travel/export/';
const PROMETHEUS_API_URL = 'https://api.prombot.co.uk/api/travel';

// Enable/disable debug logs
const DEBUG_MODE = false;

function debugLog(message: string) {
  if (DEBUG_MODE) {
    console.log(message);
  }
}

// Define max entries allowed in periodicMap
const MAX_ENTRIES = 216;

// Helper function to perform fetch with a timeout
async function fetchWithTimeout(url, options = {}, timeout = 8000) {
  const controller = new AbortController();
  const id = setTimeout(() => controller.abort(), timeout);
  const response = await fetch(url, {
    ...options,
    signal: controller.signal
  }).finally(() => clearTimeout(id));
  return response;
}

// Function to get data from YATA API
async function getYataStocks() {
  try {
    const response = await fetchWithTimeout(YATA_API_URL, {}, 8000);
    const data = await response.json();
    return data.stocks;
  } catch (e) {
    functions.logger.warn(`ERROR fetching from YATA API: \n${e}`);
    return null;
  }
}

// Function to get data from Prometheus API
async function getPrometheusStocks() {
  try {
    const response = await fetchWithTimeout(PROMETHEUS_API_URL, {}, 5000);
    const data = await response.json();
    return data.stocks;
  } catch (e) {
    functions.logger.warn(`ERROR fetching from Prometheus API: \n${e}`);
    return null;
  }
}

// Function to update a stock in Firestore
async function updateStock(currentStockData: any, timestamp: number, source: string) {
  const codeName = `${currentStockData.country}-${currentStockData.name}`;
  const docRef = admin.firestore().collection("stocks-main").doc(codeName);

  try {
    // Get existing stock data
    const dbStockSnapshot = await docRef.get();
    const dbStockData = dbStockSnapshot.exists ? dbStockSnapshot.data() : {};

    // Update only if the timestamp is more recent
    if (timestamp >= (dbStockData.update || 0)) {

      debugLog(`Updating stock in Firestore: ${codeName} from ${source}`);

      let newPeriodicMap = dbStockData.periodicMap || {};
      newPeriodicMap[timestamp] = currentStockData.quantity;

      // Clean up periodicMap to keep only the 216 most recent entries
      let allKeys = Object.keys(newPeriodicMap)
        .map(Number)
        .filter(key => !isNaN(key))
        .sort((a, b) => b - a); // sort by timestamp desc (newest first)

      if (allKeys.length > MAX_ENTRIES) {
        const keysToKeep = allKeys.slice(0, MAX_ENTRIES);
        const filteredMap: { [key: number]: number } = {};
        for (const k of keysToKeep) {
          filteredMap[k] = newPeriodicMap[k];
        }
        newPeriodicMap = filteredMap;
        debugLog(`PeriodicMap for ${codeName} trimmed to ${MAX_ENTRIES} entries`);
      }

      // Save timestamp of last empty value so that elapsed times
      // from empty to restock can be calculated later
      // 1000 in 10 minutes to avoid false positives (people filtering out)
      let lastEmpty = dbStockData.lastEmpty || 0;
      if (currentStockData.quantity === 0 && (dbStockData.quantity || 0) > 0 && (dbStockData.quantity || 0) < 1000) {
        lastEmpty = timestamp;
      }

      // Get the last array for restocked timestamps
      let restockElapsed = dbStockData.restockElapsed || [];
      // If item has been restocked or if there is also an existing lastEmpty
      if ((dbStockData.quantity || 0) === 0 && currentStockData.quantity > 0 && dbStockData.lastEmpty) {
        restockElapsed.push(timestamp - dbStockData.lastEmpty);
        // Allow maximum of 15 restocks
        if (restockElapsed.length > 15) {
          restockElapsed.shift();
        }
      }

      // Update the stock in Firestore
      await docRef.set({
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
      }, { merge: true });

    } else {
      // Log if the stock already has the same or newer timestamp
      debugLog(`Stock ${codeName} already has this or a newer timestamp`);
    }

  } catch (e) {
    functions.logger.warn(`ERROR updating stock ${codeName}: \n${e}`);
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
      // but we continue the xecution since it will be necessary to update the current quantity in any case (so that
      // we can detect restocks in the next calls in the future)
      if (savedData.quantity === 0 && currentStockData.quantity > 0) {
        restockTimestamp = timestamp;
        debugLog(`Restock detected for ${codeName} at ${restockTimestamp}`);
      } else {
        debugLog(`Restock for item ${codeName} already was already up-to-date (at ${restockTimestamp})`);
      }
    }
    // If the stock is not known yet (new stock), register it for the first time 
    else {
      debugLog(`New stock found: ${codeName} from ${source}`);
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
      restock: restockTimestamp,
      quantity: currentStockData.quantity,
      source: source,
    };

    // Update Realtime DB
    await db.ref(`stocks/restocks/${codeName}`).set(stock);

  } catch (e) {
    functions.logger.warn(`ERROR updating restock data for ${codeName}: \n${e}`);
  }
}

// Helper function to get existing stock data
async function getExistingStockData(codeName: string, database: string) {
  try {
    if (database === 'Firestore') {
      const docRef = admin.firestore().collection("stocks-main").doc(codeName);
      const docSnapshot = await docRef.get();
      return docSnapshot.exists ? docSnapshot.data() : null;
    } else if (database === 'RealtimeDB') {
      const firebaseAdmin = require("firebase-admin");
      const db = firebaseAdmin.database();
      const ref = db.ref(`stocks/restocks/${codeName}`);
      const snapshot = await ref.get();
      return snapshot.exists() ? snapshot.val() : null;
    }
  } catch (e) {
    functions.logger.warn(`ERROR getting existing stock data for ${codeName}: \n${e}`);
  }
  return null;
}

export const foreignStocksGroup = {

  checkStocks: functions.region('us-east4')
    .runWith(runtimeOpts1024)
    .pubsub
    .schedule("*/10 * * * *")
    .onRun(async () => {
      try {
        debugLog("----- Starting checkStocks -----");

        const yataStocks = await getYataStocks();
        const prometheusStocks = await getPrometheusStocks();

        // 1. Process each country concurrently
        const countryPromises = Object.keys(yataStocks).map(async (countryName) => {
          const yataCountryData = yataStocks[countryName];
          const prometheusCountryData = prometheusStocks[countryName];

          if (!yataCountryData && !prometheusCountryData) {
            debugLog(`No data for ${countryName} from either source.`);
            return;
          }

          let mostRecentSource: string;
          let mostRecentData: any;
          let lessRecentSource: string | null = null;
          let lessRecentData: any = null;

          if (yataCountryData && prometheusCountryData) {
            mostRecentSource = yataCountryData.update > prometheusCountryData.update ? 'YATA' : 'Prometheus';
            mostRecentData = (mostRecentSource === 'YATA') ? yataCountryData : prometheusCountryData;
            lessRecentSource = (mostRecentSource === 'YATA') ? 'Prometheus' : 'YATA';
            lessRecentData = (lessRecentSource === 'YATA') ? yataCountryData : prometheusCountryData;
          } else if (yataCountryData) {
            mostRecentSource = 'YATA';
            mostRecentData = yataCountryData;
          } else {
            mostRecentSource = 'Prometheus';
            mostRecentData = prometheusCountryData;
          }

          debugLog(`Most recent data source for ${countryName}: ${mostRecentSource}`);

          // 3. Process data from the most recent source
          const updatePromises = mostRecentData.stocks.map((stock: any) => {
            stock.country = countryName;
            return updateStock(stock, mostRecentData.update, mostRecentSource);
          });
          await Promise.all(updatePromises);

          // 4. Process data from the less recent source to add any missing items
          if (lessRecentData && lessRecentData.stocks && lessRecentSource) {
            debugLog(`----- Checking for missing stocks in ${lessRecentSource} -----`);
            let itemsAdded = 0;

            const missingPromises = lessRecentData.stocks.map(async (stock: any) => {
              const codeName = `${countryName}-${stock.name}`;
              const existingData = await getExistingStockData(codeName, 'Firestore');
              if (!existingData) {
                stock.country = countryName;
                await updateStock(stock, lessRecentData.update, lessRecentSource!);
                itemsAdded++;
                debugLog(`Added missing stock ${codeName} from ${lessRecentSource}`);
              }
            });
            await Promise.all(missingPromises);
            if (itemsAdded === 0) {
              debugLog(`No new items found`);
            }
          }
        });

        await Promise.all(countryPromises);

      } catch (e) {
        functions.logger.warn(`ERROR in checkStocks: \n${e}`);
      }
    }),

  fillRestocks: functions.region('us-east4').pubsub
    .schedule("*/3 * * * *")
    .onRun(async () => {
      try {
        debugLog("----- Starting fillRestocks -----");

        const yataStocks = await getYataStocks();
        const prometheusStocks = await getPrometheusStocks();

        // 1. Process each country concurrently
        const countryPromises = Object.keys(yataStocks).map(async (countryName) => {
          const yataCountryData = yataStocks[countryName];
          const prometheusCountryData = prometheusStocks[countryName];

          if (!yataCountryData && !prometheusCountryData) {
            debugLog(`No data for ${countryName} from either source.`);
            return;
          }

          let mostRecentSource: string;
          let mostRecentData: any;
          let lessRecentSource: string | null = null;
          let lessRecentData: any = null;

          if (yataCountryData && prometheusCountryData) {
            mostRecentSource = yataCountryData.update > prometheusCountryData.update ? 'YATA' : 'Prometheus';
            mostRecentData = (mostRecentSource === 'YATA') ? yataCountryData : prometheusCountryData;
            lessRecentSource = (mostRecentSource === 'YATA') ? 'Prometheus' : 'YATA';
            lessRecentData = (lessRecentSource === 'YATA') ? yataCountryData : prometheusCountryData;
          } else if (yataCountryData) {
            mostRecentSource = 'YATA';
            mostRecentData = yataCountryData;
          } else {
            mostRecentSource = 'Prometheus';
            mostRecentData = prometheusCountryData;
          }

          debugLog(`Most recent data source for ${countryName}: ${mostRecentSource}`);

          // 3. Process data from the most recent source
          const updatePromises = mostRecentData.stocks.map((stock: any) => {
            stock.country = countryName;
            return updateRestock(stock, mostRecentData.update, mostRecentSource);
          });
          await Promise.all(updatePromises);

          // 4. Process data from the less recent source to add any missing items
          if (lessRecentData && lessRecentData.stocks && lessRecentSource) {
            debugLog(`----- Checking for missing restocks in ${lessRecentSource} -----`);
            let itemsAdded = 0;

            const missingPromises = lessRecentData.stocks.map(async (stock: any) => {
              const codeName = `${countryName}-${stock.name}`;
              const existingData = await getExistingStockData(codeName, 'RealtimeDB');
              if (!existingData) {
                stock.country = countryName;
                await updateRestock(stock, lessRecentData.update, lessRecentSource!);
                itemsAdded++;
                debugLog(`Added missing restock ${codeName} from ${lessRecentSource}`);
              }
            });
            await Promise.all(missingPromises);
            if (itemsAdded === 0) {
              debugLog(`No new items found`);
            }
          }
        });

        await Promise.all(countryPromises);

      } catch (e) {
        functions.logger.warn(`ERROR STOCKS FILL \n${e}`);
      }
    }),

  // UTIL FUNCTION
  // Cleans up any periodicMap with more than 200 entries in case we have a leak in any other methods
  // oneTimeClean: functions.region('us-east4').pubsub
  //   .schedule("*/3 * * * *")
  //   .onRun(async () => {

  //     const db = admin.firestore();
  //     const snapshot = await db.collection("stocks-main").get();

  //     const cleanupPromises = snapshot.docs.map(async doc => {
  //       const docData = doc.data();
  //       if (docData.periodicMap && typeof docData.periodicMap === 'object') {
  //         const bigMap = docData.periodicMap;
  //         const allKeys = Object.keys(bigMap)
  //           .map(Number)
  //           .filter(k => !isNaN(k))
  //           .sort((a, b) => b - a);

  //         if (allKeys.length > 200) {
  //           const keysToKeep = allKeys.slice(0, 200);
  //           const filteredMap: { [key: number]: number } = {};
  //           for (const k of keysToKeep) {
  //             filteredMap[k] = bigMap[k];
  //           }

  //           await doc.ref.set({ periodicMap: {} }, { merge: true });
  //           await doc.ref.set({ periodicMap: filteredMap }, { merge: true });

  //           functions.logger.info(`Document ${doc.id}: reduced periodicMap to 200 entries`);
  //         } else {
  //           functions.logger.info(`Document ${doc.id}: periodicMap has ${allKeys.length} entries, no cleanup needed`);
  //         }
  //       } else {
  //         functions.logger.info(`Document ${doc.id}: No periodicMap or not an object, no cleanup needed`);
  //       }
  //     });

  //     await Promise.all(cleanupPromises);

  //     return { status: 'cleanup_completed' };
  //   }),

};
