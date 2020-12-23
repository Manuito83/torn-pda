import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

export const testGroup = {
  testNotification: functions.region('us-east4').pubsub
  .schedule("* * 1 1 1")
  .onRun(async () => {
    const promises: Promise<any>[] = [];
    
    promises.push(sendTestNotification(
        'PUT TEST TOKEN HERE', // Then call as "tests.testNotification()" in shell
        'Test', 
        'test left hospital earlier test')
    );
    
    await Promise.all(promises);
  }),
};

// ***********
// FOR TESTING
// ***********
async function sendTestNotification(
    token: string,
    title: string,
    body: string
  ): Promise<any> {
    
    const payload = {
      notification: {
        title: title,
        body: body,
        // There two might be overriden in Torn PDA when opened (via incoming notifications plugin)
        icon: "notification_hospital",
        color: "#FFA200",
        sound: "default",
        badge: "1",
        priority: "high",
      },
      data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        message: body, 
      },
    };
  
    const options = {
      priority: 'high',
      timeToLive: 60 * 60 * 5
    };
  
    return admin.messaging()
      .sendToDevice(token, payload, options);
  }