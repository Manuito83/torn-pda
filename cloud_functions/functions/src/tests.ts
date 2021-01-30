import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

export const testGroup = {
  testNotification: functions.region('us-east4').pubsub
  .schedule("* * 1 1 1")
  .onRun(async () => {
    const promises: Promise<any>[] = [];
    
    try {
      
      promises.push(sendTestNotification(
        '', // Then call as "tests.testNotification()" in shell
        'Test', 
        'test notification')
      );
    
    } catch (e) {
      console.log(`ERROR TEST \n${e}`)
    }

    await Promise.all(promises);

  }),
};

// *************************
// FOR TESTING NOTIFICATION
// *************************
async function sendTestNotification(
    token: string,
    title: string,
    body: string
  ): Promise<any> {
    
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
        channelId: `Test Channel`,
        //color: color,
        //icon: icon,
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
          sound: "default",
          badge: 1,
        }
      },
    },
    data: {
      // This are needed so that the information is contained 
      // in onLaundh/onResume message information
      title: title,
      body: body, 
      channelId: "Test Channel",
      tornMessageId: "",
      tornTradeId: "",
    },
  };

  return admin
    .messaging().send(payload)
    .catch((error) => {
      if (error.toString().includes("Requested entity was not found")) {
        functions.logger.warn(`USER NOT FOUND & STALED`);
      }
    });
}