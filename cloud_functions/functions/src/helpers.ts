// import { onSchedule } from "firebase-functions/v2/scheduler";
// import * as admin from "firebase-admin";
// 
// export const changeField = onSchedule({
//   schedule: "* * 1 1 1",
//   region: 'us-east4',
//   memory: "512MiB",
//   timeoutSeconds: 540
// }, async () => {
// 
//       const promises: Promise<any>[] = [];
// 
//       const allUsers = (
//         await admin
//           .firestore()
//           .collection("players")
//           .get()
//       ).docs.map((d) => d.data());
// 
//       allUsers.map((user) => {
//         promises.push(
//           admin
//             .firestore()
//             .collection("players")
//             .doc(user.uid)
//             .update({
//               // WARNING
//               factionAssistMessage: false,
//             })
//         );
//       });
// 
//       return Promise.all(promises);
// });
// 
// export const deleteField = onSchedule({
//   schedule: "* * 1 1 1",
//   region: 'us-east4',
//   memory: "512MiB",
//   timeoutSeconds: 540
// }, async () => {
// 
//       const promises: Promise<any>[] = [];
// 
//       const allUsers = (
//         await admin
//           .firestore()
//           .collection("players")
//           .get()
//       ).docs.map((d) => d.data());
// 
//       allUsers.map((user) => {
//         promises.push(
//           admin
//             .firestore()
//             .collection("players")
//             .doc(user.uid)
//             .update({
//               // WARNING
//               //lastTravelNotified: admin.firestore.FieldValue.delete(),
//             })
//         );
// 
//       });
// 
//       return Promise.all(promises);
// });
