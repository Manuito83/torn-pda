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
    
  getForeignStocks: functions.region('us-east4').pubsub
    .schedule("*/3 * * * *")
    .onRun(async () => {
    
    const promises: Promise<any>[] = [];
    
    try {
      
      // Get existing stocks from Firestore
      const dbStocks = (
        await admin
          .firestore()
          .collection("stocks")
          .get()
      ).docs.map((d) => d.data());

      // Get the stocks
      let json = await getStocks();
          
      for (const countryName in json.stocks) {
        const countryStocks = json.stocks[countryName].stocks;
        const countryTimestamp = json.stocks[countryName].update;
        for (const item of countryStocks) {

          const codeName = `${countryName}-${item.name}`;

          let emptyTimes: any[] = [];
          let fullTimes: any[] = [];
          // Match new and saved for several checks
          for (let dbStock of dbStocks) {
            if (dbStock.codeName === codeName) {

              // Check if item has reached zero.
              if (item.quantity === 0) {
                if (dbStock.quantity > 0) {
                  emptyTimes = dbStock.emptyTimes || [];
                  emptyTimes.push(countryTimestamp);
                  if (emptyTimes.length > 5) emptyTimes.splice(0, 1);
                }
              }

              if (item.quantity > 0) {
                if (dbStock.quantity === 0) {
                  fullTimes = dbStock.emptyTimes || [];
                  fullTimes.push(countryTimestamp);
                  if (fullTimes.length > 5) fullTimes.splice(0, 1);
                }
              }
            }
          }

          // Update Firestore
          promises.push(
            admin
              .firestore()
              .collection("stocks")
              .doc(codeName)
              .set({
                id: item.id,
                country: countryName,
                name: item.name,
                codeName: codeName,
                cost: item.cost,
                quantity: item.quantity,
                update: countryTimestamp,
                emptyTimes: emptyTimes,
                fullTimes: fullTimes,
              }, {merge: true})
          );
        }
      }

    } catch (e) {
      console.log("ERROR STOCKS");
      console.log(e);
    }

    return Promise.all(promises);

  }),
};
