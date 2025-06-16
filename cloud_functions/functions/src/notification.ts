import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

// Using non-ESM string-strip-html@8.5.0
import { stripHtml } from "string-strip-html";

export interface NotificationParams {
  token: string;
  title: string;
  body: string;
  icon?: string;
  color?: string;
  channelId?: string;
  tornMessageId?: string;
  tornTradeId?: string;
  assistId?: string;
  bulkDetails?: string;
  vibration: string;
  sound?: string;
}

export interface NotificationCheckResult {
  notification?: NotificationParams; // Optional: If a notification should be sent
  firestoreUpdate?: { [key: string]: any }; // Optional: Fields to update in Firestore
}

export function sendEnergyNotification(userStats: any, subscriber: any) {
  const energy = userStats.energy;
  const result: NotificationCheckResult = {};

  try {
    if (
      energy.maximum === energy.current &&
      (subscriber.energyLastCheckFull === false)
    ) {

      let title = `Full Energy Bar`;
      let body = `Your energy is full, go spend it on something!`;
      if (subscriber.discrete) {
        title = `E`;
        body = `Full`;
      }

      result.notification = {
        token: subscriber.token,
        title: title,
        body: body,
        icon: "notification_energy",
        color: "#00FF00",
        channelId: "Alerts energy",
        vibration: subscriber.vibration,
      }

      result.firestoreUpdate = { energyLastCheckFull: true };
    }

    if (
      energy.current < energy.maximum &&
      (subscriber.energyLastCheckFull === true)
    ) {
      result.firestoreUpdate = { energyLastCheckFull: false };
    }

  } catch (error) {
    functions.logger.warn(`ERROR ENERGY \n${subscriber.uid} \n${error}`);
  }

  return result;
}

export function sendNerveNotification(userStats: any, subscriber: any) {
  const nerve = userStats.nerve;
  const result: NotificationCheckResult = {};

  try {
    if (
      nerve.maximum === nerve.current &&
      (subscriber.nerveLastCheckFull === false)
    ) {

      let title = `Full Nerve Bar`;
      let body = `Your nerve is full, go crazy!`;
      if (subscriber.discrete) {
        title = `N`;
        body = `Full`;
      }


      result.notification = {
        token: subscriber.token,
        title: title,
        body: body,
        icon: "notification_nerve",
        color: "#FF0000",
        channelId: "Alerts nerve",
        vibration: subscriber.vibration,
      }
      result.firestoreUpdate = {
        nerveLastCheckFull: true,
      }
    }

    if (
      nerve.current < nerve.maximum &&
      (subscriber.nerveLastCheckFull === true)
    ) {
      result.firestoreUpdate = {
        nerveLastCheckFull: false,
      }
    }

  } catch (error) {
    functions.logger.warn(`ERROR NERVE \n${subscriber.uid} \n${error}`);
  }

  return result;
}

export function sendLifeNotification(userStats: any, subscriber: any) {
  const life = userStats.life;
  const result: NotificationCheckResult = {};

  try {
    if (
      life.maximum === life.current &&
      (subscriber.lifeLastCheckFull === false)
    ) {

      let title = `Full Life Bar`;
      let body = `Your life is full, unstoppable!`;
      if (subscriber.discrete) {
        title = `Lf`;
        body = `Full`;
      }


      result.notification = {
        token: subscriber.token,
        title: title,
        body: body,
        icon: "notification_life",
        color: "#FF0000",
        channelId: "Alerts life",
        vibration: subscriber.vibration,
      }
      result.firestoreUpdate = {
        lifeLastCheckFull: true,
      }
    }

    if (
      life.current < life.maximum &&
      (subscriber.lifeLastCheckFull === true)
    ) {
      result.firestoreUpdate = {
        lifeLastCheckFull: false,
      }
    }

  } catch (error) {
    functions.logger.warn(`ERROR LIFE \n${subscriber.uid} \n${error}`);
  }

  return result;
}

// This will log the travel at first opportunity (in case the API cannot be contacted later)
// when it detects we have a new timestamp and are on the air. Then, the TravelGroup function
// will sort users and send relevant notifications
export function logTravelArrival(userStats: any, subscriber: any) {
  const travel = userStats.travel;
  const result: NotificationCheckResult = {};

  const travelTimeArrival = subscriber.travelTimeArrival || 0;

  try {

    // We are flying register planned landing time ASAP
    // unless the current arrival was already in the DB
    if (travel.time_left > 0 && travel.timestamp !== travelTimeArrival) {
      result.firestoreUpdate = {
        travelTimeArrival: travel.timestamp,
        travelTimeNotification: travel.timestamp,
        travelDestination: travel.destination,
      }
    }

  } catch (error) {
    functions.logger.warn(`ERROR TRAVEL LOG\n${subscriber.uid} \n${error}`);
  }

  return result;
}

export function sendHospitalNotification(userStats: any, subscriber: any) {
  const result: NotificationCheckResult = {};

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
      result.firestoreUpdate = {
        hospitalLastStatus: 'in',
      }

      if (status !== 'Online') {

        let title = `Hospital admission`;
        let body = `You have been hospitalised!`;
        if (subscriber.discrete) {
          title = `H`;
          body = `Adm`;
        }


        result.notification = {
          token: subscriber.token,
          title,
          body,
          icon: 'notification_hospital',
          color: '#FFFF00',
          channelId: "Alerts hospital",
          vibration: subscriber.vibration,
        }
      }
    }

    // If we are about to be released and last time we checked we were in hospital
    else if (
      hospitalTimeToRelease > 0 && hospitalTimeToRelease <= 240 &&
      hospitalLastStatus === 'in'
    ) {

      // Change last status so that we don't notify more than once
      result.firestoreUpdate = {
        hospitalLastStatus: 'notified',
      }

      if (status !== 'Online') {

        let title = `Hospital time ending`;
        let body = `You are about to be released from the hospital, grab your things!`;
        if (subscriber.discrete) {
          title = `H`;
          body = `End`;
        }


        result.notification = {
          token: subscriber.token,
          title,
          body,
          icon: 'notification_hospital',
          color: '#FFFF00',
          channelId: "Alerts hospital",
          vibration: subscriber.vibration,
        }
      }
    }

    // If we are out and did not anticipate this, we have been revived  
    else if (
      hospitalTimeToRelease === 0 &&
      hospitalLastStatus === 'in'
    ) {

      result.firestoreUpdate = {
        hospitalLastStatus: 'out',
      }

      if (status !== 'Online') {

        let title = `You are out of hospital!`;
        let body = `You left hospital earlier than expected!`;
        if (subscriber.discrete) {
          title = `H`;
          body = `Out`;
        }


        result.notification = {
          token: subscriber.token,
          title,
          body,
          icon: 'notification_hospital',
          color: '#FFFF00',
          channelId: "Alerts hospital",
          vibration: subscriber.vibration,
        }
      }
    }

    // If we are out and already sent the notification, just update the status
    else if (
      hospitalTimeToRelease === 0 &&
      hospitalLastStatus === 'notified'
    ) {
      result.firestoreUpdate = {
        hospitalLastStatus: 'out',
      }
    }

  } catch (error) {
    functions.logger.warn(`ERROR HOSPITAL \n${subscriber.uid} \n${error}`);
  }

  return result;
}

export function sendDrugsNotification(userStats: any, subscriber: any) {
  const cooldowns = userStats.cooldowns;
  const result: NotificationCheckResult = {};

  try {
    if (
      cooldowns.drug === 0 &&
      (subscriber.drugsInfluence === true)
    ) {

      let title = `Drug cooldown expired`;
      let body = `Hey junkie! Your drugs cooldown has expired, go get some more!`;
      if (subscriber.discrete) {
        title = `D`;
        body = `Exp`;
      }


      result.notification = {
        token: subscriber.token,
        title: title,
        body: body,
        icon: "notification_drugs",
        color: "#FF00c3",
        channelId: "Alerts drugs",
        vibration: subscriber.vibration,
      }
      result.firestoreUpdate = {
        drugsInfluence: false,
      }
    }

    if (
      cooldowns.drug > 0 &&
      (subscriber.drugsInfluence === false)
    ) {
      result.firestoreUpdate = {
        drugsInfluence: true,
      }
    }

  } catch (error) {
    functions.logger.warn(`ERROR DRUGS \n${subscriber.uid} \n${error}`);
  }

  return result;
}

export function sendMedicalNotification(userStats: any, subscriber: any) {
  const cooldowns = userStats.cooldowns;
  const result: NotificationCheckResult = {};

  try {
    if (
      cooldowns.medical === 0 &&
      (subscriber.medicalInfluence === true)
    ) {

      let title = `Medical cooldown expired`;
      let body = `Your medical cooldown has expired, are you feeling better now?!`;
      if (subscriber.discrete) {
        title = `Med`;
        body = `Exp`;
      }


      result.notification = {
        token: subscriber.token,
        title: title,
        body: body,
        icon: "notification_medical",
        color: "#FF00c3",
        channelId: "Alerts medical",
        vibration: subscriber.vibration,
      }
      result.firestoreUpdate = {
        medicalInfluence: false,
      }
    }

    if (
      cooldowns.medical > 0 &&
      (subscriber.medicalInfluence === false)
    ) {
      result.firestoreUpdate = {
        medicalInfluence: true,
      }
    }

  } catch (error) {
    functions.logger.warn(`ERROR MEDICAL \n${subscriber.uid} \n${error}`);
  }

  return result;
}

export function sendBoosterNotification(userStats: any, subscriber: any) {
  const cooldowns = userStats.cooldowns;
  const result: NotificationCheckResult = {};

  try {
    if (
      cooldowns.booster === 0 &&
      (subscriber.boosterInfluence === true)
    ) {

      let title = `Booster cooldown expired`;
      let body = `Your booster cooldown has expired, you are not special anymore!`;
      if (subscriber.discrete) {
        title = `B`;
        body = `Exp`;
      }


      result.notification = {
        token: subscriber.token,
        title: title,
        body: body,
        icon: "notification_booster",
        color: "#FF00c3",
        channelId: "Alerts booster",
        vibration: subscriber.vibration,
      }
      result.firestoreUpdate = {
        boosterInfluence: false,
      }
    }

    if (
      cooldowns.booster > 0 &&
      (subscriber.boosterInfluence === false)
    ) {
      result.firestoreUpdate = {
        boosterInfluence: true,
      }
    }

  } catch (error) {
    functions.logger.warn(`ERROR BOOSTER \n${subscriber.uid} \n${error}`);
  }

  return result;
}

export function sendRacingNotification(userStats: any, subscriber: any) {
  const icons = userStats.icons;
  const result: NotificationCheckResult = {};

  try {
    if (
      icons.icon18 &&
      subscriber.racingSent === false
    ) {

      let title = `Race finished`;
      let body = `Get in there ${userStats.name}!`;
      if (subscriber.discrete) {
        title = `R`;
        body = `End`;
      }


      result.notification = {
        token: subscriber.token,
        title: title,
        body: body,
        icon: "notification_racing",
        color: "#FF9900",
        channelId: "Alerts racing",
        vibration: subscriber.vibration,
      }
      result.firestoreUpdate = {
        racingSent: true,
      }
    }

    if (
      !icons.icon18 &&
      (subscriber.racingSent === true)
    ) {
      result.firestoreUpdate = {
        racingSent: false,
      }
    }

  } catch (error) {
    functions.logger.warn(`ERROR RACING \n${subscriber.uid} \n${error}`);
  }

  return result;
}

export function sendMessagesNotification(userStats: any, subscriber: any) {
  const result: NotificationCheckResult = {};

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
      result.firestoreUpdate = {
        knownMessages: knownMessages,
      }
    }

    if (newMessages > 0) {
      let notificationTitle = "";
      let notificationSubtitle = "";
      let tornMessageId = "";

      if (newMessages === 1) {
        notificationTitle = "Message from " + newMessagesSenders[0];
        notificationSubtitle = `Subject: "${newMessagesSubjects[0]}"`;
        tornMessageId = knownMessages[0];
      }
      else if (newMessages > 1 && newMessagesSenders.length === 1) {
        notificationTitle = `${newMessages} new messages from ${newMessagesSenders[0]}`;
        notificationSubtitle = `Subjects: "${newMessagesSubjects.join('", "')}"`;
      }
      else if (newMessages > 1 && newMessagesSenders.length > 1) {
        notificationTitle = `${newMessages} new messages from ${newMessagesSenders.join(", ")}`;
        notificationSubtitle = `Subjects: "${newMessagesSubjects.join('", "')}"`;
      }

      let title = notificationTitle;
      let body = notificationSubtitle;
      if (subscriber.discrete) {
        title = `M`;
        let sender = "";
        if (newMessages === 1) {
          sender = `${newMessagesSubjects[0]}`;
        }
        else if (newMessages > 1 && newMessagesSenders.length === 1) {
          sender = `${newMessagesSenders[0]}`;
        }
        else if (newMessages > 1 && newMessagesSenders.length > 1) {
          sender = `${newMessagesSenders.join(", ")}`;
        }
        body = `${sender}`;
      }


      result.notification = {
        token: subscriber.token,
        title: title,
        body: body,
        icon: "notification_messages",
        color: "#7B1FA2",
        channelId: "Alerts messages",
        tornMessageId: tornMessageId,
        vibration: subscriber.vibration,
      }
    }

  } catch (error) {
    functions.logger.warn(`ERROR MESSAGES \n${subscriber.uid} \n${error}`);
  }

  return result;
}

export function sendEventsNotification(userStats: any, subscriber: any) {
  const result: NotificationCheckResult = {};

  try {
    let changes = false;
    let newGeneralEvents = 0;
    const newEventsDescriptions: any[] = [];
    let knownEvents = subscriber.knownEvents || [];
    const allTornKeys: any[] = [];

    Object.keys(userStats.events).forEach(function (key) {
      allTornKeys.push(key);
      if (!knownEvents.includes(key)) {
        // Event not yet notified (known), notify!
        changes = true;
        newGeneralEvents++;
        knownEvents.push(key);
        newEventsDescriptions.push(userStats.events[key].event);
      }
    });

    // Ensure that deleted events are deleted from the database!
    // Creates a set tornKeySet an array and filters knownEvents by checking
    // if its elements exist in the set, removing any that do not exist
    const tornKeySet = new Set(allTornKeys);
    const filteredEvents = knownEvents.filter(event => tornKeySet.has(event));
    if (knownEvents.length !== filteredEvents.length) {
      changes = true;
      knownEvents = filteredEvents;
    }

    if (changes) {
      result.firestoreUpdate = {
        knownEvents: knownEvents,
      }
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
        // as trades events come with a different icon and color
        const tradeCheck = stripHtml(newEventsDescriptions[i]).result;
        if (tradeCheck.includes('has initiated a trade titled') ||
          tradeCheck.includes('has accepted the trade') ||
          tradeCheck.includes('has canceled the trade') ||
          tradeCheck.includes('commented on your pending trade')
        ) {

          // But change to the other list only if we are not filtering them outs
          if (!filters.includes('trades')) {
            newTradesEvents++;
            newTradesDescriptions.push(newEventsDescriptions[i]);
          }

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

          if (filters.includes('market_sales')) {
            if (newEventsDescriptions[i].includes('You sold') &&
              newEventsDescriptions[i].includes('on the Item Market to')) {
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

          if (filters.includes('bounty_claims')) {
            if (newEventsDescriptions[i].includes('earned your') &&
              newEventsDescriptions[i].includes('bounty reward')) {
              newEventsDescriptions.splice(i--, 1);
              newGeneralEvents--;
              continue;
            }
          }

          if (filters.includes('referrals')) {
            if (newEventsDescriptions[i].includes('You have successfully referred')) {
              newEventsDescriptions.splice(i--, 1);
              newGeneralEvents--;
              continue;
            }
          }

          if (filters.includes('faction_applications')) {
            if (newEventsDescriptions[i].includes('has applied to join your faction')) {
              newEventsDescriptions.splice(i--, 1);
              newGeneralEvents--;
              continue;
            }
          }

          if (filters.includes('rental')) {
            if (newEventsDescriptions[i].includes('extension offer on the rental of your') ||
              newEventsDescriptions[i].includes('finished renting') ||
              newEventsDescriptions[i].includes('started renting')) {
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
        notificationSubtitle = notificationSubtitle.replace(/ View the details here!/g, '');
        notificationSubtitle = notificationSubtitle.replace(/ Please click here to continue./g, '');
        notificationSubtitle = notificationSubtitle.replace(/ to continue./g, '');
        notificationSubtitle = notificationSubtitle.replace(/ \[view\]/g, '.');
        notificationSubtitle = notificationSubtitle.replace(/ \[ view \]/g, '.');
        notificationSubtitle = notificationSubtitle.replace(/ \[View\]/g, '.');
        notificationSubtitle = notificationSubtitle.replace(/ \[ View \]/g, '.');
        notificationSubtitle = notificationSubtitle.replace(/ Please click here to collect your funds./g, '');
        notificationSubtitle = notificationSubtitle.replace(/ to collect your funds./g, '');
        notificationSubtitle = notificationSubtitle.replace(/ Please click here./g, '');

        let title = notificationTitle;
        let body = notificationSubtitle;
        if (subscriber.discrete) {
          title = `Event`;
          body = ` `;
        }


        result.notification = {
          token: subscriber.token,
          title,
          body,
          icon: "notification_events",
          color: "#5B1FA2",
          channelId: "Alerts events",
          vibration: subscriber.vibration,
        }
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

        let title = notificationTitle;
        let body = notificationSubtitle;
        if (subscriber.discrete) {
          title = `Trade`;
          body = ` `;
        }


        result.notification = {
          token: subscriber.token,
          title,
          body,
          icon: "notification_trades",
          color: "#389500",
          channelId: "Alerts trades",
          tornTradeId: tradeId,
          vibration: subscriber.vibration,
        }
      }

    }

  } catch (error) {
    functions.logger.warn(`ERROR EVENTS \n${subscriber.uid} \n${error}`);
  }

  return result;
}

export function sendForeignRestockNotification(userStats: any, dbStocks: any, subscriber: any) {
  const result: NotificationCheckResult = {};

  try {

    let updates = 0;
    const stocksUpdated: any[] = [];

    const userStocks = subscriber.restockActiveAlerts || {};

    for (const [userCodeName, userTime] of Object.entries(userStocks)) {

      /*
      console.log("User stocks: " + userCodeName + " - " + userStocks[userCodeName]);
      console.log("Stock country: " + dbStocks[userCodeName].country);
      console.log("User travel or destination: " + userStats.travel.destination);
      console.log("Only current country alerts: " + subscriber.foreignRestockNotificationOnlyCurrentCountry);
      */

      let databaseCountryName = dbStocks[userCodeName].country;
      let playerDestination = userStats.travel.destination;

      // If the user has activated the option in Torn PDA only to be notified if the restock is happening
      // in the country he is flying to / staying in, we need to check whether they match before proceeding
      if (subscriber.foreignRestockNotificationOnlyCurrentCountry) {
        // We are looking for the SPECIFIC country of the item here

        if (userStats.travel.destination === "United Kingdom") {
          // Standardize with values in the database and API
          playerDestination = "UK";
        }

        if (playerDestination !== databaseCountryName) {
          // No country coincidence, continue with the next stock
          continue;
        }

        //console.log("Country matched, continue to notification!")
      }

      if (userCodeName in dbStocks) {
        const dbTime = dbStocks[userCodeName].restock;
        const timeDifference = <number>userTime - dbTime * 1000;

        if (timeDifference < 0) {
          // Note: we already have a method in Torn PDA [subscribeToForeignRestockNotification()] that ensures that
          //the timestamp values of Firestore's [restockActiveAlerts] are updated to DateTime.now() when this notifications 
          // are enabled after certain time, so that we avoid sending old and expiry notifications in a after activation

          updates++;
          stocksUpdated.push(`${dbStocks[userCodeName].name} (${databaseCountryName})`)
          userStocks[userCodeName] = dbTime * 1000;
        }
      }
    }

    if (updates > 0) {
      const notificationTitle = "Foreign items restocked!";
      const notificationSubtitle = stocksUpdated.join(', ');

      result.firestoreUpdate = {
        restockActiveAlerts: userStocks,
      }

      let title = notificationTitle;
      let body = notificationSubtitle;
      if (subscriber.discrete) {
        title = `Stock`;
        body = ` `;
      }


      result.notification = {
        token: subscriber.token,
        title: title,
        body: body,
        icon: "notification_travel",
        color: "#389500",
        channelId: "Alerts restocks",
        vibration: subscriber.vibration,
      }
    }

  } catch (error) {
    functions.logger.warn(`ERROR RESTOCKS \n${subscriber.uid} \n${error}`);
  }

  return result;
}

export function sendStockMarketNotification(tornStocks: any, subscriber: any) {
  const result: NotificationCheckResult = {};

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

      result.firestoreUpdate = {
        stockMarketShares: newUserAlerts,
      }

      let title = notificationTitle;
      let body = notificationSubtitle;
      if (subscriber.discrete) {
        title = `Shares`;
        body = ` `;
      }

      result.notification = {
        token: subscriber.token,
        title: title,
        body: body,
        icon: "notification_stock_market",
        color: "#389500",
        channelId: "Alerts stocks",
        vibration: subscriber.vibration,
      }

    }

  } catch (error) {
    functions.logger.warn(`ERROR STOCK MARKET \n${subscriber.uid} \n${error}`);
  }

  return result;
}

export async function sendNotificationToUser({
  token,
  title,
  body,
  icon,
  color,
  channelId,
  tornMessageId = "",
  tornTradeId = "",
  assistId = "",
  bulkDetails = "",
  vibration,
  sound = "slow_spring_board.aiff",
}: NotificationParams): Promise<any> {

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
      // in onLaunch/onResume message information
      title: title,
      body: body,
      channelId: channelId,
      tornMessageId: tornMessageId,
      tornTradeId: tornTradeId,
      assistId: assistId,
      bulkDetails: bulkDetails,
    },
  };

  return admin.messaging().send(payload);

}

