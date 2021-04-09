import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

export const testGroup = {
  testNotification: functions.region('us-east4').pubsub
  .schedule("* * 1 1 1")
  .onRun(async () => {
    const promises: Promise<any>[] = [];
    
    try {
      
      promises.push(sendTestNotification(
        '### TOKEN HERE ###', // Then call as "tests.testNotification()" in shell
        'Full Energy Bar', 
        'Your energy is full, go spend on something!',
        "notification_energy",
        "#00FF00",
        "Alerts energy",
        "",
        "",
        "medium",
        )
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
  body: string,
  icon: string,
  color: string,
  channelId: string,
  tornMessageId: string = "",
  tornTradeId: string = "",
  vibration: string,
): Promise<any> {
  
  // Give a space to mach channel ids in the app
  let vibrationPattern = vibration;
  if (vibrationPattern !== "") {
    vibrationPattern = ` ${vibrationPattern}`;
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
        channelId: `${channelId}${vibrationPattern}`,
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
      channelId: channelId,
      tornMessageId: tornMessageId,
      tornTradeId: tornTradeId,
    },
  };

  return admin.messaging().send(payload);
}