/**
 * This script manages and updates stock and restock information from two providers: YATA and Prometheus
 * 
 * 1. Retrieves stock data from both YATA and Prometheus APIs
 * 2. Determines most recent source: for each country, it compares the timestamps from YATA and Prometheus to determine which provider has the most up-to-date data
 * 3. Updates Stocks/Restocks
 *    - It updates stocks in Firestore and restocks in Realtime Database using the data from the most recent source
 *    - It only updates an item if the incoming timestamp is newer than the existing timestamp in the databas
 * 4. Adds Missing Items: after processing the most recent source, it checks the less recent source for any missing items (items not present in the database). 
 *    It then adds these missing items to the database.
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
const fetch = require("node-fetch");

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

// Function to get data from YATA API
async function getYataStocks() {
  try {
    const response = await fetch(YATA_API_URL);
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
    const response = await fetch(PROMETHEUS_API_URL);
    const data = await response.json();
    return data.stocks;
  } catch (e) {
    functions.logger.warn(`ERROR fetching from Prometheus API: \n${e}`);
    return null;
  }
}

// Function to update a stock in Firestore
async function updateStock(stockData: any, timestamp: number, source: string) {
  const codeName = `${stockData.country}-${stockData.name}`;
  const docRef = admin.firestore().collection("stocks-main").doc(codeName);

  try {
    // Get existing stock data 
    const dbStockSnapshot = await docRef.get();
    const dbStockData = dbStockSnapshot.exists ? dbStockSnapshot.data() : {};

    // Update only if the timestamp is more recent
    if (timestamp >= (dbStockData.update || 0)) {

      debugLog(`Updating stock in Firestore: ${codeName} from ${source}`);

      let newPeriodicMap = dbStockData.periodicMap || {};
      newPeriodicMap[timestamp] = stockData.quantity;

      // If more than 1.5 day has passed (216 iterations each 10 minutes, delete oldest)
      if (Object.keys(newPeriodicMap).length > 216) {
        const sortedKeys = Object.keys(newPeriodicMap).map(Number).sort((a, b) => a - b);
        delete newPeriodicMap[sortedKeys[0]];
      }

      // Save timestamp of last empty value so that elapsed times
      // from empty to restock can be calculated later
      // 1000 in 10 minutes to avoid false positives (people filtering out)
      let lastEmpty = dbStockData.lastEmpty || 0;
      if (stockData.quantity === 0 && (dbStockData.quantity || 0) > 0 && (dbStockData.quantity || 0) < 1000) {
        lastEmpty = timestamp;
      }

      // Get the last array for restocked timestamps
      let restockElapsed = dbStockData.restockElapsed || [];
      // If item has been restocked or if there is also an existing lastEmpty
      if ((dbStockData.quantity || 0) === 0 && stockData.quantity > 0 && dbStockData.lastEmpty) {
        restockElapsed.push(timestamp - dbStockData.lastEmpty);
        // Allow maximum of 15 restocks
        if (restockElapsed.length > 15) {
          restockElapsed.shift();
        }
      }

      // Update the stock in Firestore
      await docRef.set({
        id: stockData.id,
        country: stockData.country,
        name: stockData.name,
        codeName: codeName,
        cost: stockData.cost,
        quantity: stockData.quantity,
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
async function updateRestock(stockData: any, timestamp: number, source: string) {
  const codeName = `${stockData.country}-${stockData.name}`;
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
      if (savedData.quantity === 0 && stockData.quantity > 0) {
        restockTimestamp = timestamp;
        debugLog(`Restock detected for ${codeName} at ${restockTimestamp}`);
      } else {
        debugLog(`Restock for item ${codeName} already was already up-to-date`);
        return;
      }
    }
    // If the stock is not known yet (new stock), register it for the first time 
    else {
      debugLog(`New stock found: ${codeName} from ${source}`);
      restockTimestamp = timestamp;
    }

    let country = "";
    switch (stockData.country) {
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
      name: stockData.name,
      codeName: codeName,
      restock: restockTimestamp,
      quantity: stockData.quantity,
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

  checkStocks: functions.region('us-east4').pubsub
    .schedule("*/10 * * * *")
    .onRun(async () => {
      try {
        debugLog("----- Starting checkStocks -----");

        const yataStocks = await getYataStocks();
        const prometheusStocks = await getPrometheusStocks();

        // 1. Process each country
        for (const countryName in yataStocks) {
          const yataCountryData = yataStocks[countryName];
          const prometheusCountryData = prometheusStocks[countryName];

          // 2. Determine the most recent source for the country
          let mostRecentSource = null;
          let mostRecentData = null;

          if (yataCountryData.update > prometheusCountryData.update) {
            mostRecentSource = 'YATA';
            mostRecentData = yataCountryData;
          } else {
            mostRecentSource = 'Prometheus';
            mostRecentData = prometheusCountryData;
          }

          debugLog(`Most recent data source for ${countryName}: ${mostRecentSource}`);

          // 3. Process data from the most recent source
          const updatePromises = [];
          for (const stock of mostRecentData.stocks) {
            stock.country = countryName;
            updatePromises.push(updateStock(stock, mostRecentData.update, mostRecentSource));
          }
          await Promise.all(updatePromises);

          // 4. Process data from the less recent source to add any missing items
          debugLog(`----- Checking for missing stocks in ${mostRecentSource === 'YATA' ? 'Prometheus' : 'YATA'} -----`);
          let itemsAdded = 0;

          if (mostRecentSource === 'YATA') {
            for (const stock of prometheusCountryData.stocks) {
              const codeName = `${countryName}-${stock.name}`;
              const existingData = await getExistingStockData(codeName, 'Firestore');
              if (!existingData) {
                stock.country = countryName;
                await updateStock(stock, prometheusCountryData.update, 'Prometheus');
                itemsAdded++;
                debugLog(`Added missing stock ${codeName} from Prometheus`);
              }
            }

          } else {
            for (const stock of yataCountryData.stocks) {
              const codeName = `${countryName}-${stock.name}`;
              const existingData = await getExistingStockData(codeName, 'Firestore');
              if (!existingData) {
                stock.country = countryName;
                await updateStock(stock, yataCountryData.update, 'YATA');
                itemsAdded++;
                debugLog(`Added missing stock ${codeName} from YATA`);
              }
            }
          }
          if (itemsAdded === 0) {
            debugLog(`No new items found`);
          }
        }

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

        // 1. Process each country
        for (const countryName in yataStocks) {
          const yataCountryData = yataStocks[countryName];
          const prometheusCountryData = prometheusStocks[countryName];

          // 2. Determine the most recent source for the country
          let mostRecentSource = null;
          let mostRecentData = null;

          if (yataCountryData.update > prometheusCountryData.update) {
            mostRecentSource = 'YATA';
            mostRecentData = yataCountryData;
          } else {
            mostRecentSource = 'Prometheus';
            mostRecentData = prometheusCountryData;
          }

          debugLog(`Most recent data source for ${countryName}: ${mostRecentSource}`);

          // 3. Process data from the most recent source
          const updatePromises = [];
          for (const stock of mostRecentData.stocks) {
            stock.country = countryName;
            updatePromises.push(updateRestock(stock, mostRecentData.update, mostRecentSource));
          }
          await Promise.all(updatePromises);

          // 4. Process data from the less recent source to add any missing items
          debugLog(`----- Checking for missing restocks in ${mostRecentSource === 'YATA' ? 'Prometheus' : 'YATA'} -----`);
          let itemsAdded = 0;

          if (mostRecentSource === 'YATA') {
            for (const stock of prometheusCountryData.stocks) {
              const codeName = `${countryName}-${stock.name}`;
              const existingData = await getExistingStockData(codeName, 'RealtimeDB');
              if (!existingData) {
                stock.country = countryName;
                await updateRestock(stock, prometheusCountryData.update, 'Prometheus');
                itemsAdded++;
                debugLog(`Added missing restock ${codeName} from Prometheus`);
              }
            }
          } else {
            for (const stock of yataCountryData.stocks) {
              const codeName = `${countryName}-${stock.name}`;
              const existingData = await getExistingStockData(codeName, 'RealtimeDB');
              if (!existingData) {
                stock.country = countryName;
                await updateRestock(stock, yataCountryData.update, 'YATA');
                itemsAdded++;
                debugLog(`Added missing restock ${codeName} from YATA`);
              }
            }
          }
          if (itemsAdded === 0) {
            debugLog(`No new items found`);
          }
        }

      } catch (e) {
        functions.logger.warn(`ERROR STOCKS FILL \n${e}`);
      }
    }),
};