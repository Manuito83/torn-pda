// Dart imports:
import 'dart:convert';
import 'dart:io';

// Package imports:
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:torn_pda/main.dart';

// Project imports:
import 'package:torn_pda/models/firebase_user_model.dart';
import 'package:torn_pda/models/profile/own_profile_basic.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

final firestore = _FirestoreHelper();

class _FirestoreHelper {
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _alreadyUploaded = false;
  FirebaseUserModel _firebaseUserModel;

  String _uid;
  void setUID(String userUID) {
    _uid = userUID;
  }

  // Settings, when user initialized after API key validated
  Future<void> uploadUsersProfileDetail(
    OwnProfileBasic profile, {
    bool userTriggered = false,
  }) async {
    if (_alreadyUploaded && !userTriggered) return;
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
        "version": appVersion,

        /// This is a unique identifier to identify this user and target notification
        "token": token,
      },
      SetOptions(merge: true),
    );

    // Gets current alerts in case this user was already existing (after uninstall/reinstall
    // with saved settings for Android)
    await getUserProfile(force: true);
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

  Future<void> subscribeToForeignRestockNotification(bool subscribe) async {
    // If we had already foreign stocks chosen as alerts, we need to update them to the
    // current timestamp, so that alerts are not sent on first pass (if restocks alerts were off)
    Map<String, dynamic> previous = await json.decode(await Prefs().getActiveRestocks());
    var now = DateTime.now().millisecondsSinceEpoch;
    previous.forEach((key, value) {
      previous[key] = now;
    });

    _firestore.collection("players").doc(_uid).update({
      "foreignRestockNotification": subscribe,
      "restockActiveAlerts": previous,
    }).then((value) {
      Prefs().setRestocksNotificationEnabled(subscribe);
    });
  }

  Future<DocumentSnapshot> getStockInformation(String codeName) async {
    return await _firestore.collection("stocks-main").doc(codeName).get();
  }

  Future<bool> updateActiveRestockAlerts(Map restockMap) async {
    return _firestore.collection("players").doc(_uid).update({
      "restockActiveAlerts": restockMap,
    }).then((value) {
      return true;
    }).catchError((e) {
      return false;
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

  Future<void> subscribeToEventsNotification(bool subscribe) async {
    await _firestore.collection("players").doc(_uid).update({
      "eventsNotification": subscribe,
    });
  }

  Future<void> addToEventsFilter(String filter) async {
    List currentFilter = _firebaseUserModel.eventsFilter;
    currentFilter.add(filter);
    await _firestore.collection("players").doc(_uid).update({
      "eventsFilter": currentFilter,
    });
  }

  Future<void> removeFromEventsFilter(String filter) async {
    List currentFilter = _firebaseUserModel.eventsFilter;
    currentFilter.remove(filter);
    await _firestore.collection("players").doc(_uid).update({
      "eventsFilter": currentFilter,
    });
  }

  Future<void> subscribeToRefillsNotification(bool subscribe) async {
    await _firestore.collection("players").doc(_uid).update({
      "refillsNotification": subscribe,
    });
  }

  Future<void> addToRefillsRequested(String request) async {
    List currentRequests = _firebaseUserModel.refillsRequested;
    currentRequests.add(request);
    await _firestore.collection("players").doc(_uid).update({
      "refillsRequested": currentRequests,
    });
  }

  Future<void> removeFromRefillsRequested(String request) async {
    List currentRequests = _firebaseUserModel.refillsRequested;
    currentRequests.remove(request);
    await _firestore.collection("players").doc(_uid).update({
      "refillsRequested": currentRequests,
    });
  }

  Future<void> subscribeToHospitalNotification(bool subscribe) async {
    await _firestore.collection("players").doc(_uid).update({
      "hospitalNotification": subscribe,
    });
  }

  Future<bool> uploadLastActiveTime(int timeStamp) async {
    if (_uid == null) return false;
    return _firestore.collection("players").doc(_uid).update({
      "lastActive": timeStamp,
      "active": true,
    }).then((value) {
      return true;
    }).catchError((error) {
      return false;
    });
  }

  // Init State in alerts
  Future<FirebaseUserModel> getUserProfile({bool force = false}) async {
    if (_firebaseUserModel != null && !force) return _firebaseUserModel;
    var firestoreUser = await _firestore.collection("players").doc(_uid).get();
    return _firebaseUserModel = FirebaseUserModel.fromMap(firestoreUser.data());
  }

  Future deleteUserProfile() async {
    _alreadyUploaded = false;
    await _firestore.collection("players").doc(_uid).delete();
  }

  Future<void> setVibrationPattern(String pattern) async {
    await _firestore.collection("players").doc(_uid).update({
      "vibration": pattern,
    });
  }

  Future<void> subscribeToStockMarketNotification(bool subscribe) async {
    await _firestore.collection("players").doc(_uid).update({
      "stockMarketNotification": subscribe,
    });
  }

  Future<bool> addStockMarketShare(String ticker, String action) async {
    List currentStocks = _firebaseUserModel.stockMarketShares;
    // Code is ticker-gain-price-loss-price. 'n' for empty.
    // Example: YAZ-G-840-L-n
    // Example to delete: YAZ-remove
    currentStocks.removeWhere((element) => element.contains(ticker));
    if (!action.contains("remove")) {
      currentStocks.add(action);
    }

    return _firestore.collection("players").doc(_uid).update({
      "stockMarketShares": currentStocks,
    }).then((value) {
      return true;
    }).catchError((error) {
      return false;
    });
  }
}
