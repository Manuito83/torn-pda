import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:torn_pda/models/firebase_user_model.dart';
import 'package:torn_pda/models/profile_model.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class _FirestoreHelper {
  Firestore _firestore = Firestore.instance;
  FirebaseMessaging _messaging = FirebaseMessaging();
  bool _uploaded = false;
  FirebaseUserModel _firebaseUserModel;
  Future<void> uploadUsersProfileDetail(
    String apiKey,
    ProfileModel profile,
  ) async {
    if (_uploaded) return;
    _uploaded = true;
    await _firestore
        .collection("players")
        .document(profile.playerId.toString())
        .setData(
      {
        "name": profile.name,
        "gender": profile.gender,
        "level": profile.level,
        "apiKey": apiKey,
        "rank": profile.rank,
        "life": profile.life,
        "status": profile.status,
        "lastAction": profile.lastAction,
        "playerId": profile.playerId,

        /// This is a unique identifier to identify this user and target notification
        "token": await _messaging.getToken(),
      },
      merge: true,
    );
  }

  Future<void> subscribeToEnergyNotificaion(bool subscribe) async {
    String playerId = await SharedPreferencesModel().getOwnId();
    await _firestore.collection("players").document(playerId).updateData({
      "energyNotification": subscribe,
    });
  }

  Future<void> uploadLastActiveTime() async {
    String playerId = await SharedPreferencesModel().getOwnId();
    if (playerId == null) return;
    await _firestore.collection("players").document(playerId).updateData({
      "lastActive": DateTime.now().millisecondsSinceEpoch,
      "active": true,
    });
  }

  Future<FirebaseUserModel> getUserProfile() async {
    if (_firebaseUserModel != null) return _firebaseUserModel;
    String playerId = await SharedPreferencesModel().getOwnId();
    return _firebaseUserModel = FirebaseUserModel.fromMap(
        (await _firestore.collection("players").document(playerId).get()).data);
  }
}

final firestore = _FirestoreHelper();
