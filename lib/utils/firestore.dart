import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:torn_pda/models/profile_model.dart';

class FirestoreHelper {
  Firestore _firestore = Firestore.instance;
  FirebaseMessaging _messaging = FirebaseMessaging();
  Future<void> uploadUsersProfileDetail(
    String apiKey,
    ProfileModel profile,
  ) async {
    await _firestore
        .collection("players")
        .document(profile.playerId.toString())
        .setData({
      "name": profile.name,
      "gender": profile.gender,
      "level": profile.level,
      "rank": profile.rank,
      "life": profile.life,
      "status": profile.status,
      "lastAction": profile.lastAction,
      "playerId": profile.playerId,

      /// This is a unique identifier to identify this user and target notification
      "token": await _messaging.getToken(),
    });
  }

  subscribeToEnergyNotificaion(bool subscribe) {}
}
