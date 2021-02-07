import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
const rp = require("request-promise");

async function getStocks() {
    return rp({
        uri: `https://yata.yt/api/v1/travel/export/`,
        json: true,
    });
  }

export const foreignStocksGroup = {
    
  checkStocks: functions.region('us-east4').pubsub
    .schedule("*/10 * * * *")
    .onRun(async () => {
    
    const promises: Promise<any>[] = [];

    try {
      
      // Get existing stocks from Firestore
      const dbStocksMain = (
        await admin
          .firestore()
          .collection("stocks-main")
          .get()
      ).docs.map((d) => d.data());

      // Get the stocks
      const yata = await getStocks();
          
      // Get countries from YATA object
      for (const countryName in yata.stocks) {
        const yataCountry = yata.stocks[countryName].stocks;
        const yataCountryTimestamp = yata.stocks[countryName].update;
        
        // For each item in each country
        for (const yataItem of yataCountry) {

          // Common denominator (e.g.: "can-Vicondin")
          const codeName = `${countryName}-${yataItem.name}`;

          let newPeriodicMap = {};
          let restockElapsed: any[] = [];
          let lastEmpty = 0;
          
          // Main stocks colletion
          for (const dbStock of dbStocksMain) {
            // Find its counterpart in YATA
            if (dbStock.codeName === codeName) {
              
              // Retrieve the item form Firestore
              const savedMainMap = dbStock['periodicMap'] || new Map<number, number>();
              // Add new timestamp + quantity to the map
              savedMainMap[yataCountryTimestamp] = yataItem.quantity;
              // If more than 1.5 day has passed (216 iterations each 10 minutes, delete oldest)
              if (Object.keys(savedMainMap).length > 216) {
                // For that purpose, we create an array with keys (timestamps), sort 
                // and delete the oldest from the "saveMainMap" object
                const keys = [];
                for(const key in savedMainMap){
                  if(savedMainMap.hasOwnProperty(key)){
                      keys.push(key);
                  }
                }
                keys.sort();
                const oldest: number = +keys.slice(0, 1);
                delete savedMainMap[oldest];
              }
              // Parse map into object to upload to Firestore
              newPeriodicMap = JSON.parse(JSON.stringify(savedMainMap));


              // Save timestamp of last empty value so that elapsed times
              // from empty to restock can be calculated later
              // 1000 in 10 minutes to avoid falase positives (people filtering out)
              lastEmpty = dbStock['lastEmpty'] || 0;
              if (dbStock['quantity'] > 0 && dbStock['quantity'] < 1000 && yataItem.quantity === 0) {
                lastEmpty = yataCountryTimestamp;
              }

              // Get the last array for restocked timestamps
              restockElapsed = dbStock['restockElapsed'] || [];
              // If item has been restocked
              if (dbStock['quantity'] === 0 && yataItem.quantity > 0) {
                // If there is also an existing lastEmpty
                if (dbStock['lastEmpty'] !== 0) {
                  const elapsed = yataCountryTimestamp - dbStock['lastEmpty'];
                  restockElapsed.push(elapsed);
                  // Allow maximum of 15 restocks
                  if (restockElapsed.length > 15) {
                    restockElapsed.splice(0, 1);
                  }
                }
              }

              break;
            }
          }

          // Update main stocks for each item
          promises.push(
            admin
              .firestore()
              .collection("stocks-main")
              .doc(codeName)
              .set({
                id: yataItem.id,
                country: countryName,
                name: yataItem.name,
                codeName: codeName,
                cost: yataItem.cost,
                quantity: yataItem.quantity,
                update: yataCountryTimestamp,
                periodicMap: newPeriodicMap,
                restockElapsed: restockElapsed,
                lastEmpty: lastEmpty,
              }, {merge: false})
          );
        }
      }

    } catch (e) {
      functions.logger.warn(`ERROR STOCKS CHECK \n${e}`);
    }

    await Promise.all(promises);

  }),


  fillRestocks: functions.region('us-east4').pubsub
    .schedule("*/3 * * * *")
    .onRun(async () => {
    
    const promises: Promise<any>[] = [];

    try {
      
      // Get existing stocks from Realtime DB
      const firebaseAdmin = require("firebase-admin");
      const db = firebaseAdmin.database();

      const ref = db.ref("stocks/restocks");

      const savedData = {};
      await ref.once("value", function(snapshot) {
        snapshot.forEach(function(childSnapshot) {
          savedData[childSnapshot.val().codeName] = childSnapshot.val();
        });
      });

      // Get the stocks from YATA
      const yata = await getStocks();

      // Get countries from YATA object
      for (const countryName in yata.stocks) {
        const yataCountry = yata.stocks[countryName].stocks;
        const yataCountryTimestamp = yata.stocks[countryName].update;
        
        // For each item in each country
        for (const yataItem of yataCountry) {

          // Common denominator (e.g.: "can-Vicondin")
          const codeName = `${countryName}-${yataItem.name}`;

          let timestamp = 0;
          // If this is known stock
          if (`${codeName}`in savedData) {
            // Quantity and last restock time in the database
            const savedQty = savedData[`${codeName}`].quantity;
            timestamp = savedData[`${codeName}`].restock;
          
            // We will only update the restock timestamp if we have a restock, 
            // otherwise we leave the last known restock time
            if (savedQty === 0 && yataItem.quantity > 0) {
              timestamp = yataCountryTimestamp;
            }
          } 
          // If the stock is not known yet, register it for the first time
          else {
            timestamp = yataCountryTimestamp;
          }
          
          let country = "";
          switch (countryName) {
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
            name: yataItem.name,
            codeName: codeName,
            restock: timestamp,
            quantity: yataItem.quantity,
          }

          promises.push(
            db.ref(`stocks/restocks/${codeName}`).set(stock)
          );

        }
      }

    } catch (e) {
      functions.logger.warn(`ERROR STOCKS FILL \n${e}`);
    }

    await Promise.all(promises);

  }),

};

