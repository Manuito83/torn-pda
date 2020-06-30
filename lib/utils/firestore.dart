import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:torn_pda/models/firebase_user_model.dart';
import 'package:torn_pda/models/own_profile_model.dart';

final firestore = _FirestoreHelper();

class _FirestoreHelper {
  Firestore _firestore = Firestore.instance;
  FirebaseMessaging _messaging = FirebaseMessaging();
  bool _uploaded = false;
  FirebaseUserModel _firebaseUserModel;

  String _playerId;
  void setUserKey (String inputKey) {
    _playerId = inputKey;
  }

  Future<void> uploadUsersProfileDetail(
    String apiKey,
    OwnProfileModel profile,
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
        "life": profile.life.current,
        "status": profile.status.description,
        "lastAction": profile.lastAction.relative,
        "playerId": profile.playerId,

        /// This is a unique identifier to identify this user and target notification
        "token": await _messaging.getToken(),
      },
      merge: true,
    );
  }

  Future<void> subscribeToEnergyNotification(bool subscribe) async {
    await _firestore.collection("players").document(_playerId).updateData({
      "energyNotification": subscribe,
    });
  }

  Future<void> subscribeToTravelNotification(bool subscribe) async {
    await _firestore.collection("players").document(_playerId).updateData({
      "travelNotification": subscribe,
    });
  }

  Future<void> uploadLastActiveTime() async {
    if (_playerId == null) return;
    await _firestore.collection("players").document(_playerId).updateData({
      "lastActive": DateTime.now().millisecondsSinceEpoch,
      "active": true,
    });
  }

  Future<FirebaseUserModel> getUserProfile() async {
    if (_firebaseUserModel != null) return _firebaseUserModel;
    return _firebaseUserModel = FirebaseUserModel.fromMap(
        (await _firestore.collection("players").document(_playerId).get()).data);
  }
}


