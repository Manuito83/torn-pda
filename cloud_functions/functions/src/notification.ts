import * as admin from "firebase-admin";
import stripHtml from "string-strip-html";
import * as functions from "firebase-functions";

export async function sendEnergyNotification(userStats: any, subscriber: any) {
  const energy = userStats.energy;
  const promises: Promise<any>[] = [];

  try {
    if (
      energy.maximum === energy.current &&
      (subscriber.energyLastCheckFull === false)
    ) {
      promises.push(
        sendNotificationToUser(
          subscriber.token,
          "Full Energy Bar",
          "Your energy is full, go spend on something!",
          "notification_energy",
          "#00FF00",
          "Alerts energy",
          "",
          "",
          subscriber.vibration,
        )
      );
      promises.push(
        admin
          .firestore()
          .collection("players")
          .doc(subscriber.uid)
          .update({
            energyLastCheckFull: true,
          })
      );
    }

    if (
      energy.current < energy.maximum &&
      (subscriber.energyLastCheckFull === true)
    ) {
      promises.push(
        admin
          .firestore()
          .collection("players")
          .doc(subscriber.uid)
          .update({
            energyLastCheckFull: false,
          })
      );
    }

  } catch (error) {
    functions.logger.warn(`ERROR ENERGY \n${subscriber.uid} \n${error}`);
  }

  return Promise.all(promises);
}

export async function sendNerveNotification(userStats: any, subscriber: any) {
  const nerve = userStats.nerve;
  const promises: Promise<any>[] = [];

  try {
    if (
      nerve.maximum === nerve.current &&
      (subscriber.nerveLastCheckFull === false)
    ) {
      promises.push(
        sendNotificationToUser(
          subscriber.token,
          "Full Nerve Bar",
          "Your nerve is full, go crazy!",
          "notification_nerve",
          "#FF0000",
          "Alerts nerve",
          "",
          "",
          subscriber.vibration,
        )
      );
      promises.push(
        admin
          .firestore()
          .collection("players")
          .doc(subscriber.uid)
          .update({
            nerveLastCheckFull: true,
          })
      );
    }

    if (
      nerve.current < nerve.maximum &&
      (subscriber.nerveLastCheckFull === true)
    ) {
      promises.push(
        admin
          .firestore()
          .collection("players")
          .doc(subscriber.uid)
          .update({
            nerveLastCheckFull: false,
          })
      );
    }

  } catch (error) {
    functions.logger.warn(`ERROR NERVE \n${subscriber.uid} \n${error}`);
  }

  return Promise.all(promises);
}

// This will log the travel at first opportunity (in case the API cannot be contacted later)
// when it detects we have a new timestamp and are on the air. Then, the TravelGroup function
// will sort users and send relevant notifications
export async function logTravelArrival(userStats: any, subscriber: any) {
  const travel = userStats.travel;
  const promises: Promise<any>[] = [];

  const travelTimeArrival = subscriber.travelTimeArrival || 0;

  try {

    // We are flying register planned landing time ASAP
    // unless the current arrival was already in the DB
    if (travel.time_left > 0 && travel.timestamp !== travelTimeArrival) {
      promises.push(
        admin
          .firestore()
          .collection("players")
          .doc(subscriber.uid)
          .update({
            travelTimeArrival: travel.timestamp,
            travelTimeNotification: travel.timestamp,
            travelDestination: travel.destination,
          })
      );
    }

  } catch (error) {
    functions.logger.warn(`ERROR TRAVEL LOG\n${subscriber.uid} \n${error}`);
  }

  return Promise.all(promises);
}

export async function sendHospitalNotification(userStats: any, subscriber: any) {
  const promises: Promise<any>[] = [];

  const currentDateInMillis = Math.floor(Date.now() / 1000);

  let hospitalTimeToRelease = userStats.states.hospital_timestamp - currentDateInMillis;
  if (hospitalTimeToRelease < 0)
    hospitalTimeToRelease = 0;

  const hospitalLastStatus = subscriber.hospitalLastStatus || 'out';
  const status = userStats.last_action.status;

  try {

    // If we have just been hospitalised (stay > 180 seconds)
    if (
      hospitalTimeToRelease > 240 && hospitalLastStatus !== 'in'
    ) {
      promises.push(
        admin
          .firestore()
          .collection("players")
          .doc(subscriber.uid)
          .update({
            hospitalLastStatus: 'in',
          })
      );

      if (status !== 'Online') {
        promises.push(
          sendNotificationToUser(
            subscriber.token,
            `Hospital admission`,
            `You have been hospitalised!`,
            'notification_hospital',
            '#FFFF00',
            "Alerts hospital",
            "",
            "",
            subscriber.vibration,
          )
        );
      }
    }

    // If we are about to be released and last time we checked we were in hospital
    else if (
      hospitalTimeToRelease > 0 && hospitalTimeToRelease <= 240 &&
      hospitalLastStatus === 'in'
    ) {

      // Change last status so that we don't notify more than once
      promises.push(
        admin
          .firestore()
          .collection("players")
          .doc(subscriber.uid)
          .update({
            hospitalLastStatus: 'notified',
          })
      );

      if (status !== 'Online') {
        promises.push(
          sendNotificationToUser(
            subscriber.token,
            `Hospital time ending`,
            `You are about to be released from the hospital, grab your things!`,
            'notification_hospital',
            '#FFFF00',
            "Alerts hospital",
            "",
            "",
            subscriber.vibration,
          )
        );
      }
    }

    // If we are out and did not anticipate this, we have been revived  
    else if (
      hospitalTimeToRelease === 0 &&
      hospitalLastStatus === 'in'
    ) {

      promises.push(
        admin
          .firestore()
          .collection("players")
          .doc(subscriber.uid)
          .update({
            hospitalLastStatus: 'out',
          })
      );

      if (status !== 'Online') {
        promises.push(
          sendNotificationToUser(
            subscriber.token,
            `You are out of hospital!`,
            `You left hospital earlier than expected!`,
            'notification_hospital',
            '#FFFF00',
            "Alerts hospital",
            "",
            "",
            subscriber.vibration,
          )
        );
      }
    }

    // If we are out and already sent the notification, just update the status
    else if (
      hospitalTimeToRelease === 0 &&
      hospitalLastStatus === 'notified'
    ) {
      promises.push(
        admin
          .firestore()
          .collection("players")
          .doc(subscriber.uid)
          .update({
            hospitalLastStatus: 'out',
          })
      );
    }

  } catch (error) {
    functions.logger.warn(`ERROR HOSPITAL \n${subscriber.uid} \n${error}`);
  }

  return Promise.all(promises);
}

export async function sendDrugsNotification(userStats: any, subscriber: any) {
  const cooldowns = userStats.cooldowns;
  const promises: Promise<any>[] = [];

  try {
    if (
      cooldowns.drug === 0 &&
      (subscriber.drugsInfluence === true)
    ) {
      promises.push(
        sendNotificationToUser(
          subscriber.token,
          "Drug cooldown expired",
          "Hey junkie! Your drugs cooldown has expired, go get some more!",
          "notification_drugs",
          "#FF00c3",
          "Alerts drugs",
          "",
          "",
          subscriber.vibration,
        )
      );
      promises.push(
        admin
          .firestore()
          .collection("players")
          .doc(subscriber.uid)
          .update({
            drugsInfluence: false,
          })
      );
    }

    if (
      cooldowns.drug > 0 &&
      (subscriber.drugsInfluence === false)
    ) {
      promises.push(
        admin
          .firestore()
          .collection("players")
          .doc(subscriber.uid)
          .update({
            drugsInfluence: true,
          })
      );
    }

  } catch (error) {
    functions.logger.warn(`ERROR DRUGS \n${subscriber.uid} \n${error}`);
  }

  return Promise.all(promises);
}

export async function sendRacingNotification(userStats: any, subscriber: any) {
  const icons = userStats.icons;
  const promises: Promise<any>[] = [];

  try {
    if (
      icons.icon18 &&
      subscriber.racingSent === false
    ) {
      promises.push(
        sendNotificationToUser(
          subscriber.token,
          "Race finished",
          `Get in there ${userStats.name}!`,
          "notification_racing",
          "#FF9900",
          "Alerts racing",
          "",
          "",
          subscriber.vibration,
        )
      );
      promises.push(
        admin
          .firestore()
          .collection("players")
          .doc(subscriber.uid)
          .update({
            racingSent: true,
          })
      );
    }

    if (
      !icons.icon18 &&
      (subscriber.racingSent === true)
    ) {
      promises.push(
        admin
          .firestore()
          .collection("players")
          .doc(subscriber.uid)
          .update({
            racingSent: false,
          })
      );
    }

  } catch (error) {
    functions.logger.warn(`ERROR RACING \n${subscriber.uid} \n${error}`);
  }

  return Promise.all(promises);
}

export async function sendMessagesNotification(userStats: any, subscriber: any) {
  const promises: Promise<any>[] = [];

  try {
    let changes = false;
    let newMessages = 0;
    const newMessagesSenders: any[] = [];
    const newMessagesSubjects: any[] = [];
    const knownMessages = subscriber.knownMessages || [];
    const allTornKeys: any[] = [];

    Object.keys(userStats.messages).forEach(function (key) {
      allTornKeys.push(key);
      if (userStats.messages[key].seen === 0 &&
        userStats.messages[key].read === 0 &&
        !knownMessages.includes(key)) {
        changes = true;
        newMessages++;
        knownMessages.push(key);
        newMessagesSubjects.push(userStats.messages[key].title);
        if (!newMessagesSenders.includes(userStats.messages[key].name)) {
          newMessagesSenders.push(userStats.messages[key].name);
        }
      }
      // From v2.5.1, using 'new', this should in theory not be applicable
      else if ((userStats.messages[key].seen === 1 ||
        userStats.messages[key].read === 1) &&
        knownMessages.includes(key)) {
        changes = true;
        for (let i = 0; i < knownMessages.length; i++) {
          if (knownMessages[i] === key) {
            knownMessages.splice(i, 1);
            break;
          }
        }
      }
    });

    // Ensure that deleted messages are deleted from the database, as they
    // won't be caught by the conditions above if they get deleted immediately

    // Note: for messages & events we've changed to 'new' in v2.5.1, so this
    // will theoretically be the only way of removing them from the db
    for (const key of knownMessages) {
      if (!allTornKeys.includes(key)) {
        changes = true;
        for (let i = 0; i < knownMessages.length; i++) {
          if (knownMessages[i] === key) {
            knownMessages.splice(i, 1);
            break;
          }
        }
      }
    }

    if (changes) {
      promises.push(
        admin
          .firestore()
          .collection("players")
          .doc(subscriber.uid)
          .update({
            knownMessages: knownMessages,
          })
      );
    }

    if (newMessages > 0) {
      let notificationTitle = "";
      let notificationSubtitle = "";
      let tornMessageId = "";

      if (newMessages === 1) {
        notificationTitle = "You have a new message from " + newMessagesSenders[0];
        notificationSubtitle = `Subject: "${newMessagesSubjects[0]}"`;
        tornMessageId = knownMessages[0];
      }
      else if (newMessages > 1 && newMessagesSenders.length === 1) {
        notificationTitle = `You have ${newMessages} new messages from ${newMessagesSenders[0]}`;
        notificationSubtitle = `Subjects: "${newMessagesSubjects.join('", "')}"`;
      }
      else if (newMessages > 1 && newMessagesSenders.length > 1) {
        notificationTitle = `You have ${newMessages} new messages from ${newMessagesSenders.join(", ")}`;
        notificationSubtitle = `Subjects: "${newMessagesSubjects.join('", "')}"`;
      }

      promises.push(
        sendNotificationToUser(
          subscriber.token,
          notificationTitle,
          notificationSubtitle,
          "notification_messages",
          "#7B1FA2",
          "Alerts messages",
          tornMessageId,
          "",
          subscriber.vibration,
        )
      );
    }

  } catch (error) {
    functions.logger.warn(`ERROR MESSAGES \n${subscriber.uid} \n${error}`);
  }

  return Promise.all(promises);
}

export async function sendEventsNotification(userStats: any, subscriber: any) {
  const promises: Promise<any>[] = [];

  try {
    let changes = false;
    let newGeneralEvents = 0;
    const newEventsDescriptions: any[] = [];
    const knownEvents = subscriber.knownEvents || [];
    const allTornKeys: any[] = [];

    Object.keys(userStats.events).forEach(function (key) {
      allTornKeys.push(key);
      if (userStats.events[key].seen === 0 &&
        !knownEvents.includes(key)) {
        changes = true;
        newGeneralEvents++;
        knownEvents.push(key);
        newEventsDescriptions.push(userStats.events[key].event);
      }
      // From v2.5.1, using 'new', this should in theory not be applicable
      else if (userStats.events[key].seen === 1 &&
        knownEvents.includes(key)) {
        changes = true;
        for (let i = 0; i < knownEvents.length; i++) {
          if (knownEvents[i] === key) {
            knownEvents.splice(i, 1);
            break;
          }
        }
      }
    });

    // Ensure that deleted messages are deleted from the database, as they
    // won't be caught by the conditions above if they get deleted immediately

    // Note: for messages & events we've changed to 'new' in v2.5.1, so this
    // will theoretically be the only way of removing them from the db
    for (const key of knownEvents) {
      if (!allTornKeys.includes(key)) {
        changes = true;
        for (let i = 0; i < knownEvents.length; i++) {
          if (knownEvents[i] === key) {
            knownEvents.splice(i, 1);
            break;
          }
        }
      }
    }

    if (changes) {
      promises.push(
        admin
          .firestore()
          .collection("players")
          .doc(subscriber.uid)
          .update({
            knownEvents: knownEvents,
          })
      );
    }

    // We will separate the trades notification from the rest of events
    let newTradesEvents = 0;
    const newTradesDescriptions: any[] = [];

    // We send the notification if new events are found
    if (newGeneralEvents > 0) {
      let notificationTitle = "";
      let notificationSubtitle = "";

      // If the user has pre-defined filters, we will remove the events
      // matching those filters, so that the notification is not sent
      const filters = subscriber.eventsFilter || [];
      for (let i = 0; i < newGeneralEvents; i++) {

        // Change trades notification from one list to another
        const tradeCheck = stripHtml(newEventsDescriptions[i]).result;
        if (tradeCheck.includes('has initiated a trade titled') ||
          tradeCheck.includes('has accepted the trade') ||
          tradeCheck.includes('has canceled the trade') ||
          tradeCheck.includes('commented on your pending trade')
        ) {
          newTradesEvents++;
          newTradesDescriptions.push(newEventsDescriptions[i]);
          newEventsDescriptions.splice(i--, 1);
          newGeneralEvents--;
          continue;
        }

        if (filters.length > 0) {

          // Avoid personal messages with giveaways triggering other filter
          if (newEventsDescriptions[i].includes('with the message:')) {
            continue;
          }

          if (filters.includes('crimes')) {
            if (newEventsDescriptions[i].includes('You have been selected by') ||
              newEventsDescriptions[i].includes('You and your team') ||
              newEventsDescriptions[i].includes('canceled the ')) {
              newEventsDescriptions.splice(i--, 1);
              newGeneralEvents--;
              continue;
            }
          }

          if (filters.includes('trains')) {
            if (newEventsDescriptions[i].includes('the director of')) {
              newEventsDescriptions.splice(i--, 1);
              newGeneralEvents--;
              continue;
            }
          }

          if (filters.includes('racing')) {
            if (newEventsDescriptions[i].includes('You came') ||
              newEventsDescriptions[i].includes('race.') ||
              newEventsDescriptions[i].includes('Your best lap was') ||
              newEventsDescriptions[i].includes('race and have received ')) {
              newEventsDescriptions.splice(i--, 1);
              newGeneralEvents--;
              continue;
            }
          }

          if (filters.includes('bazaar')) {
            if (newEventsDescriptions[i].includes('from your bazaar for')) {
              newEventsDescriptions.splice(i--, 1);
              newGeneralEvents--;
              continue;
            }
          }

          if (filters.includes('attacks')) {
            if (newEventsDescriptions[i].includes('attacked you') ||
              newEventsDescriptions[i].includes('mugged you and stole') ||
              newEventsDescriptions[i].includes('attacked and hospitalized')) {
              newEventsDescriptions.splice(i--, 1);
              newGeneralEvents--;
              continue;
            }
          }

          if (filters.includes('revives')) {
            if (newEventsDescriptions[i].includes('revive')) {
              newEventsDescriptions.splice(i--, 1);
              newGeneralEvents--;
              continue;
            }
          }
        }
      }

      // Checking again if any new events remain after filtering
      if (newGeneralEvents > 0) {
        if (newGeneralEvents === 1) {
          notificationTitle = "You have a new event!";
          notificationSubtitle = `${newEventsDescriptions[0]}`;
        }
        else if (newGeneralEvents > 1) {
          notificationTitle = `You have ${newGeneralEvents} new events!`;
          notificationSubtitle = `- ${newEventsDescriptions.join('\n- ')}`.trim();
        }

        // Fix notification text
        notificationSubtitle = stripHtml(notificationSubtitle).result;
        notificationSubtitle = notificationSubtitle.replace(/View the details here!/g, '');
        notificationSubtitle = notificationSubtitle.replace(/Please click here to continue./g, '');
        notificationSubtitle = notificationSubtitle.replace(/ \[view\]/g, '.');
        notificationSubtitle = notificationSubtitle.replace(/ \[ view \]/g, '.');
        notificationSubtitle = notificationSubtitle.replace(/ \[View\]/g, '.');
        notificationSubtitle = notificationSubtitle.replace(/ \[ View \]/g, '.');
        notificationSubtitle = notificationSubtitle.replace(/Please click here to collect your funds./g, '');
        notificationSubtitle = notificationSubtitle.replace(/Please click here./g, '');

        promises.push(
          sendNotificationToUser(
            subscriber.token,
            notificationTitle,
            notificationSubtitle,
            "notification_events",
            "#5B1FA2",
            "Alerts events",
            "",
            "",
            subscriber.vibration,
          )
        );
      }

      if (newTradesEvents > 0) {
        if (newTradesEvents === 1) {
          notificationTitle = "Trade update!";
          notificationSubtitle = `${newTradesDescriptions[0]}`;
        }
        else if (newTradesEvents > 1) {
          notificationTitle = `${newTradesEvents} trade updates!`;
          notificationSubtitle = `- ${newTradesDescriptions.join('\n- ')}`.trim();
        }

        // We'll use this later in case of trade
        const originalSubtitle = notificationSubtitle;

        let tradeId = '';

        // Fix notification text
        notificationSubtitle = stripHtml(notificationSubtitle).result;
        notificationSubtitle = notificationSubtitle.replace(/View the details here!/g, '');
        notificationSubtitle = notificationSubtitle.replace(/Please click here to continue./g, '');
        notificationSubtitle = notificationSubtitle.replace(/ \[view\]/g, '.');
        notificationSubtitle = notificationSubtitle.replace(/ \[ view \]/g, '.');
        notificationSubtitle = notificationSubtitle.replace(/ \[View\]/g, '.');
        notificationSubtitle = notificationSubtitle.replace(/ \[ View \]/g, '.');
        notificationSubtitle = notificationSubtitle.replace(/Please click here./g, '');


        // If exactly one trade update, change title accordingly and add tradeId
        if (newTradesEvents === 1) {
          if (notificationSubtitle.includes("has initiated a trade titled")) {
            notificationTitle = "New trade!";
          } else if (notificationSubtitle.includes("has accepted the trade. The trade is now complete.")) {
            notificationTitle = "Trade completed!";
          } else if (notificationSubtitle.includes("has canceled the trade")) {
            notificationTitle = "Trade canceled!";
          } else if (notificationSubtitle.includes("commented on your pending trade")) {
            notificationTitle = "Trade commented!";
          }

          const regex = new RegExp(`(?:trade.php#step=view&ID=)([0-9]+)`);
          const matches = regex.exec(originalSubtitle);
          if (matches !== null) tradeId = matches[1];

          // If more than one trade update, don't change title but add tradeIid only if new trade is detected
        } else if (newTradesEvents > 1) {
          const regex = new RegExp(`(?:trade.php#step=view&ID=)([0-9]+)`);
          const matches = regex.exec(originalSubtitle);
          if (matches !== null) tradeId = matches[1];
        }

        promises.push(
          sendNotificationToUser(
            subscriber.token,
            notificationTitle,
            notificationSubtitle,
            "notification_trades",
            "#389500",
            "Alerts trades",
            "",
            tradeId,
            subscriber.vibration,
          )
        );
      }

    }

  } catch (error) {
    functions.logger.warn(`ERROR EVENTS \n${subscriber.uid} \n${error}`);
  }

  return Promise.all(promises);
}

export async function sendForeignRestockNotification(dbStocks: any, subscriber: any) {
  const promises: Promise<any>[] = [];

  try {

    let updates = 0;
    const stocksUpdated: any[] = [];

    const userStocks = subscriber.restockActiveAlerts;
    for (const [userCodeName, userTime] of Object.entries(userStocks)) {

      if (userCodeName in dbStocks) {
        const dbTime = dbStocks[userCodeName].restock;

        const timeDifference = <number>userTime - dbTime * 1000;
        if (timeDifference < 0) {
          updates++;
          stocksUpdated.push(`${dbStocks[userCodeName].name} (${dbStocks[userCodeName].country})`)
          userStocks[userCodeName] = dbTime * 1000;
        }
      }
    }

    if (updates > 0) {
      const notificationTitle = "Foreign items restocked!";
      const notificationSubtitle = stocksUpdated.join(', ');

      promises.push(
        admin
          .firestore()
          .collection("players")
          .doc(subscriber.uid)
          .update({
            restockActiveAlerts: userStocks,
          })
      );

      promises.push(
        sendNotificationToUser(
          subscriber.token,
          notificationTitle,
          notificationSubtitle,
          "notification_travel",
          "#389500",
          "Alerts restocks",
          "",
          "",
          subscriber.vibration,
        )
      );
    }

  } catch (error) {
    functions.logger.warn(`ERROR RESTOCKS \n${subscriber.uid} \n${error}`);
  }

  return Promise.all(promises);
}

export async function sendStockMarketNotification(tornStocks: any, subscriber: any) {
  const promises: Promise<any>[] = [];

  try {

    let updates = 0;
    const stocksMarketUpdates: any[] = [];
    const newUserAlerts: any[] = [];

    // Loop user selected alerts
    const userAlerts = subscriber.stockMarketShares || [];
    for (const alert of userAlerts) {

      const regexp = /[A-Z]+-G-((?:\d+(?:\.)?(?:\d{1,2})?)|n)-L-((?:\d+(?:\.)?(?:\d{1,2})?)|n)/;
      const match = alert.match(regexp);

      if (match === null) {
        functions.logger.warn(`Stock Market regex error \n${subscriber.uid}`);
        continue;
      }

      const acronym = alert.substring(0, 3);
      let alertHigh = match[1];
      let alertLow = match[2];

      // Locate the share in Torn's stock market
      for (const value of Object.values(tornStocks.stocks)) {
        if (value["acronym"] === acronym) {

          if (alertHigh !== "n") {
            alertHigh = +alertHigh; // Parse to int
            if (value["current_price"] > alertHigh) {
              stocksMarketUpdates.push(`${acronym} above \$${alertHigh}!`);
              alertHigh = "n";
              updates++;
            }
          }

          if (alertLow !== "n") {
            alertLow = +alertLow; // Parse to int
            if (value["current_price"] < alertLow) {
              stocksMarketUpdates.push(`${acronym} below \$${alertLow}!`);
              alertLow = "n";
              updates++;
            }
          }
        }
      }

      // Rebuild user alerts only if there is still gain or loss valid
      // Otherwise skip it, so that it get deleted
      if (alertHigh !== "n" || alertLow !== "n") {
        newUserAlerts.push(`${acronym}-G-${alertHigh}-L-${alertLow}`);
      }
    }

    if (updates > 0) {
      let notificationTitle = "";
      let notificationSubtitle = "";

      if (updates === 1) {
        notificationTitle = "Stock market alert!";
        notificationSubtitle = `${stocksMarketUpdates[0]}`;
      }
      else if (updates > 1) {
        notificationTitle = `Stock market alerts!`;
        notificationSubtitle = `- ${stocksMarketUpdates.join('\n- ')}`.trim();
      }

      promises.push(
        admin
          .firestore()
          .collection("players")
          .doc(subscriber.uid)
          .update({
            stockMarketShares: newUserAlerts,
          })
      );

      promises.push(
        sendNotificationToUser(
          subscriber.token,
          notificationTitle,
          notificationSubtitle,
          "notification_stock_market",
          "#389500",
          "Alerts stocks",
          "",
          "",
          subscriber.vibration,
        )
      );

    }

  } catch (error) {
    functions.logger.warn(`ERROR STOCK MARKET \n${subscriber.uid} \n${error}`);
  }

  return Promise.all(promises);
}

export async function sendNotificationToUser(
  token: string,
  title: string,
  body: string,
  icon: string,
  color: string,
  channelId: string,
  tornMessageId: string = "",
  tornTradeId: string = "",
  vibration: string,
  sound: string = "slow_spring_board.aiff",
): Promise<any> {

  // Give a space to mach channel ids in the app
  let vibrationPattern = vibration;
  if (vibrationPattern !== "") {
    vibrationPattern = ` ${vibrationPattern}`;
  }

  // Android custom sounds
  // NOTE: if applied during beta testing, existing production apps will revert to 
  // the default sound, as the new channel name won't be found on their devices
  // (TODO: record app version in the future)
  let customSound = "";
  if (channelId.includes("travel")) {
    customSound = ` s`;
  }

  const payload: admin.messaging.Message = {
    token: token,
    notification: {
      title: title,
      body: body,
    },
    android: {
      priority: 'high',
      ttl: 18000000,
      notification: {
        channelId: `${channelId}${vibrationPattern}${customSound}`,
        color: color,
        icon: icon,
        sound: "default",
        clickAction: "FLUTTER_NOTIFICATION_CLICK",
      },
    },
    apns: {
      headers: {
        "apns-priority": "10"
      },
      payload: {
        aps: {
          sound: sound,
          badge: 1,
        }
      },
    },
    data: {
      // This are needed so that the information is contained 
      // in onLaundh/onResume message information
      title: title,
      body: body,
      channelId: channelId,
      tornMessageId: tornMessageId,
      tornTradeId: tornTradeId,
    },
  };

  return admin.messaging().send(payload);

}
