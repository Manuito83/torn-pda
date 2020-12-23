import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:torn_pda/models/firebase_user_model.dart';
import 'package:torn_pda/models/profile/own_profile_model.dart';

final firestore = _FirestoreHelper();

class _FirestoreHelper {
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  FirebaseMessaging _messaging = FirebaseMessaging();
  bool _alreadyUploaded = false;
  FirebaseUserModel _firebaseUserModel;

  String _uid;
  void setUID(String userUID) {
    _uid = userUID;
  }

  // Settings, when user initialized after API key validated
  Future<void> uploadUsersProfileDetail(OwnProfileModel profile, {bool forceUpdate = false}) async {
    if (_alreadyUploaded && !forceUpdate) return;
    _alreadyUploaded = true;
    _firebaseUserModel = FirebaseUserModel();
    var platform = Platform.isAndroid ? "android" : "ios";
    var token = await _messaging.getToken();
    await _firestore.collection("players").doc(_uid).set(
      {
        "uid": _uid,
        "name": profile.name,
        "level": profile.level,
        "apiKey": profile.userApiKey,
        "life": profile.life.current,
        "playerId": profile.playerId,
        "energyLastCheckFull": true,
        "nerveLastCheckFull": true,
        "drugsInfluence": false,
        "racingSent": true,
        "platform": platform,

        /// This is a unique identifier to identify this user and target notification
        "token": token,
      },
      SetOptions(merge: true),
    );
  }

  Future<void> subscribeToTravelNotification(bool subscribe) async {
    await _firestore.collection("players").doc(_uid).update({
      "travelNotification": subscribe,
    });
  }

  Future<void> subscribeToEnergyNotification(bool subscribe) async {
    await _firestore.collection("players").doc(_uid).update({
      "energyNotification": subscribe,
    });
  }

  Future<void> subscribeToNerveNotification(bool subscribe) async {
    await _firestore.collection("players").doc(_uid).update({
      "nerveNotification": subscribe,
      // Nerve was implemented in v1.8.7, so we need to manually create this field and set it
      // to TRUE for users that were already in the DB. New users (or upon API reload) will have
      // the field created normally
      "nerveLastCheckFull": true,
    });
  }

  Future<void> subscribeToDrugsNotification(bool subscribe) async {
    await _firestore.collection("players").doc(_uid).update({
      "drugsNotification": subscribe,
      // Same reason for this than in Nerve (see comment)
      "drugsInfluence": false,
    });
  }

  Future<void> subscribeToRacingNotification(bool subscribe) async {
    await _firestore.collection("players").doc(_uid).update({
      "racingNotification": subscribe,
      // Same reason for this than in Nerve (see comment)
      "racingSent": true,
    });
  }

  Future<void> subscribeToMessagesNotification(bool subscribe) async {
    await _firestore.collection("players").doc(_uid).update({
      "messagesNotification": subscribe,
    });
  }

  Future<void> subscribeToHospitalNotification(bool subscribe) async {
    await _firestore.collection("players").doc(_uid).update({
      "hospitalNotification": subscribe,
    });
  }

  Future<void> uploadLastActiveTime(int timeStamp) async {
    if (_uid == null) return;
    await _firestore.collection("players").doc(_uid).update({
      "lastActive": timeStamp,
      "active": true,
    });
  }

  // Init State in alerts
  Future<FirebaseUserModel> getUserProfile() async {
    if (_firebaseUserModel != null) return _firebaseUserModel;
    return _firebaseUserModel =
        FirebaseUserModel.fromMap((await _firestore.collection("players").doc(_uid).get()).data());
  }

  Future deleteUserProfile() async {
    _alreadyUploaded = false;
    await _firestore.collection("players").doc(_uid).delete();
  }
}
