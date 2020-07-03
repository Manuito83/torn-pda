import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:torn_pda/models/firebase_user_model.dart';
import 'package:torn_pda/models/own_profile_model.dart';

final firestore = _FirestoreHelper();

class _FirestoreHelper {
  Firestore _firestore = Firestore.instance;
  FirebaseMessaging _messaging = FirebaseMessaging();
  bool _uploaded = false;
  FirebaseUserModel _firebaseUserModel;

  String _uid;
  void setUID (String userUID) {
    _uid = userUID;
  }

  // Settings, when user initialized after API key validated
  Future<void> uploadUsersProfileDetail(OwnProfileModel profile) async {
    if (_uploaded) return;
    _uploaded = true;
    await _firestore
        .collection("players")
        .document(_uid)
        .setData(
      {
        "name": profile.name,
        "level": profile.level,
        "apiKey": profile.userApiKey,
        "life": profile.life.current,
        "playerId": profile.playerId,

        /// This is a unique identifier to identify this user and target notification
        "token": await _messaging.getToken(),
      },
      merge: true,
    );
  }

  Future<void> subscribeToEnergyNotification(bool subscribe) async {
    await _firestore.collection("players").document(_uid).updateData({
      "energyNotification": subscribe,
    });
  }

  Future<void> subscribeToTravelNotification(bool subscribe) async {
    await _firestore.collection("players").document(_uid).updateData({
      "travelNotification": subscribe,
    });
  }

  Future<void> uploadLastActiveTime(int timeStamp) async {
    if (_uid == null) return;
    await _firestore.collection("players").document(_uid).updateData({
      "lastActive": timeStamp,
      "active": true,
    });
  }

  // Init State in alerts
  Future<FirebaseUserModel> getUserProfile() async {
    if (_firebaseUserModel != null) return _firebaseUserModel;
    return _firebaseUserModel = FirebaseUserModel.fromMap(
        (await _firestore.collection("players").document(_uid).get()).data);
  }

  Future deleteUserProfile() async {
    _uploaded = false;
    await _firestore.collection("players").document(_uid).delete();

  }
}


