import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

export const helperGroup = {
  
  deactivateField: functions.region('us-east4').pubsub
    .schedule("* * 1 1 1")
    .onRun(async () => {
      
      const promises: Promise<any>[] = [];
      
      const allUsers = (
        await admin
          .firestore()
          .collection("players")
          .get()
      ).docs.map((d) => d.data());

      allUsers.map((user) => {
        promises.push(
          admin
            .firestore()
            .collection("players")
            .doc(user.uid)
            .update({
              // fieldToDelete: admin.firestore.FieldValue.delete(),
              lastTravelNotified: admin.firestore.FieldValue.delete(),
            })
        );

      });
      
      return Promise.all(promises);
  }),
  
};
