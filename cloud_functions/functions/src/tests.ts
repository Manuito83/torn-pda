import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

export const testGroup = {
  testNotification: functions.region('us-east4').pubsub
  .schedule("* * 1 1 1")
  .onRun(async () => {
    const promises: Promise<any>[] = [];
    
    try {
      
      promises.push(sendTestNotification(
        'd_Zx2OGPt70:APA91bHP_iNW8qgYg55RWwuqq9c9TpFuJ7h0NGfHxKmJZ0WQ515r1IcLP7HV2kZLDU10TN96eTRvBo-j6Oad8KwVIY-AYtyeLA1OatKLE2P0nkGjER6Xazf2sxbZYIvd0VxXGFMkvBiT', // Then call as "tests.testNotification()" in shell
        'Test', 
        'test notification')
      );
      await Promise.all(promises);
    
    } catch (e) {
      console.log(`ERROR TEST \n${e}`)
    }

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