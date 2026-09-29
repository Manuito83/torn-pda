// Dart imports:
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

// Package imports:
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:torn_pda/main.dart';

// Project imports:
import 'package:torn_pda/models/cityshops/city_shop_item_model.dart';
import 'package:torn_pda/models/firebase_user_model.dart';
import 'package:torn_pda/models/profile/own_profile_basic.dart';
import 'package:torn_pda/providers/api/api_v1_calls.dart';
import 'package:torn_pda/utils/live_activities/live_activity_bridge.dart';
import 'package:torn_pda/utils/notification.dart';
import 'package:torn_pda/utils/sembast_db.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/utils/user_helper.dart';

class FirestoreHelper {
  static final FirestoreHelper _instance = FirestoreHelper._internal();
  FirestoreHelper._internal();

  factory FirestoreHelper() {
    return _instance;
  }

  final Completer uidCompleter = Completer();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _alreadyUploaded = false;
  FirebaseUserModel? _firebaseUserModel;

  String? _uid;
  Future setUID(String userUID) async {
    _uid = userUID;
    if (!uidCompleter.isCompleted) {
      uidCompleter.complete();
    }
  }

  Future<bool> _updateAlertField(String fieldName, Map<String, Object?> update) async {
    if (_uid == null) return false;
    try {
      await _firestore.collection("players").doc(_uid).update(update);
      return true;
    } catch (e, s) {
      logErrorToCrashlytics("Alert field update failed: $fieldName", e, s);
      return false;
    }
  }

  // Settings, when user initialized after API key validated
  Future<FirebaseUserModel?> uploadUsersProfileDetail(OwnProfileBasic profile, {bool userTriggered = false}) async {
    if (_alreadyUploaded && !userTriggered) return null;
    _alreadyUploaded = true;

    final platform = Platform.isAndroid
        ? "android"
        : Platform.isIOS
        ? "ios"
        : "windows";

    // Generate or replace token if it already exists
    String token = "";
    if (!Platform.isWindows) {
      token = await _getMessagingToken();
      // A failed fetch returns "error"; fall back to the last known good token
      if (token == "error") token = await Prefs().getFCMToken();
    } else {
      token = "windows";
    }
    log("FCM token: $token");

    final bool validToken = token.isNotEmpty && token != "error";

    // Fetch existing Firebase profile or return a default empty model
    _firebaseUserModel = await getUserProfile(force: true);

    final payload = {
      "uid": _uid,
      "name": profile.name,
      "level": profile.level,
      "apiKey": profile.userApiKey,
      "life": profile.life!.current,
      "playerId": profile.playerId,
      "energyLastCheckFull": _firebaseUserModel!.energyLastCheckFull, // Defaults
      "nerveLastCheckFull": _firebaseUserModel!.nerveLastCheckFull, // Defaults
      "drugsInfluence": _firebaseUserModel!.drugsInfluence, // Defaults
      "medicalInfluence": _firebaseUserModel!.medicalInfluence, // Defaults
      "boosterInfluence": _firebaseUserModel!.boosterInfluence, // Defaults
      "racingSent": _firebaseUserModel!.racingSent, // Defaults
      "platform": platform,
      "version": appVersion,
      "faction": profile.faction!.factionId,
      // Ensure all users have a refill time set
      "refillsTime": _firebaseUserModel!.refillsTime, // Defaults to 22 if null (new user)
      "factionAssistMessage": _firebaseUserModel!.factionAssistMessage, // Defaults to true
    };

    // This is a unique identifier to identify this user and target notification.
    // Only write it when we have a real one, so a failed fetch doesn't overwrite
    // a valid token already stored in Firestore
    if (validToken) {
      payload["token"] = token;
      payload["tokenErrors"] = 0;
    }

    await _firestore.collection("players").doc(_uid).set(payload, SetOptions(merge: true));

    // Mark synced only after a successful write (windows uses a placeholder token)
    if (validToken && !Platform.isWindows) {
      Prefs().setFCMTokenSynced(token);
    }

    return _firebaseUserModel;
  }

  Future<FirebaseUserModel?> softReset() async {
    try {
      final savedKey = UserHelper.apiKey;

      final dynamic myProfile = await ApiCallsV1.getOwnProfileBasic();
      if (myProfile is! OwnProfileBasic) return null;

      myProfile
        ..userApiKey = savedKey
        ..userApiKeyValid = true;

      final fb = await uploadUsersProfileDetail(myProfile, userTriggered: true);
      await uploadLastActiveTimeAndTokensToFirebase(DateTime.now().millisecondsSinceEpoch);

      if (Platform.isAndroid) {
        final alertsVibration = await Prefs().getVibrationPattern();
        reconfigureNotificationChannels(mod: alertsVibration);
        setVibrationPattern(alertsVibration);
      }

      return fb;
    } catch (e) {
      return null;
    }
  }

  Future<bool> toggleDiscreet(bool discreet) {
    return _updateAlertField("discrete", {
      "discrete": discreet, // Legacy field name (typo kept for compatibility)
    });
  }

  Future<bool> subscribeToTravelNotification(bool? subscribe) {
    return _updateAlertField("travelNotification", {"travelNotification": subscribe});
  }

  Future<bool> subscribeToEnergyNotification(bool? subscribe) {
    return _updateAlertField("energyNotification", {"energyNotification": subscribe});
  }

  Future<bool> subscribeToForeignRestockNotification(bool? subscribe) async {
    // Reset existing stock alert timestamps to now so alerts are not
    // triggered on the first pass after enabling
    Map<String, dynamic> previous = await json.decode(await Prefs().getActiveRestocks());
    final now = DateTime.now().millisecondsSinceEpoch;
    previous.forEach((key, value) {
      previous[key] = now;
    });

    final success = await _updateAlertField("foreignRestockNotification", {
      "foreignRestockNotification": subscribe,
      "restockActiveAlerts": previous,
    });
    if (success) {
      Prefs().setRestocksNotificationEnabled(subscribe!);
    }
    return success;
  }

  Future<bool> changeForeignRestockNotificationOnlyCurrentCountry(bool enabled) {
    // Waiting for the landing only makes sense while limited to the current country
    return _updateAlertField("foreignRestockNotificationOnlyCurrentCountry", {
      "foreignRestockNotificationOnlyCurrentCountry": enabled,
      if (!enabled) "foreignRestockNotificationOnlyLanded": false,
    });
  }

  Future<bool> changeForeignRestockNotificationOnlyLanded(bool enabled) {
    return _updateAlertField("foreignRestockNotificationOnlyLanded", {
      "foreignRestockNotificationOnlyLanded": enabled,
    });
  }

  Future<bool> changeForeignRestockSellout(bool enabled) async {
    final Map<String, Object?> update = {"foreignRestockNotificationSellout": enabled};

    // Reset existing stock alert timestamps to now, so that old sellouts are not
    // notified on the first pass after enabling
    if (enabled) {
      final Map<String, dynamic> previous = await json.decode(await Prefs().getActiveRestocks());
      if (previous.isNotEmpty) {
        final now = DateTime.now().millisecondsSinceEpoch;
        previous.forEach((key, value) {
          previous[key] = now;
        });
        update["restockActiveAlerts"] = previous;
      }
    }

    return _updateAlertField("foreignRestockNotificationSellout", update);
  }

  Future<bool> changeTravelStocksInNotification(bool enabled) {
    return _updateAlertField("travelStocksInNotification", {"travelStocksInNotification": enabled});
  }

  Future<bool> subscribeToAbroadStayNotification(bool? subscribe) {
    final Map<String, Object?> update = {"abroadStayNotification": subscribe};
    // When disabling, also clear the per-stay tracking so the next activation
    // starts fresh instead of resuming from a stale landing timestamp
    if (subscribe != true) {
      update["abroadLandingTs"] = 0;
      update["abroadIntervalsSent"] = <int>[];
    }
    return _updateAlertField("abroadStayNotification", update);
  }

  Future<bool> setAbroadStayIntervals(List<int> intervalsMinutes) {
    return _updateAlertField("abroadStayIntervals", {
      "abroadStayIntervals": intervalsMinutes,
      // A change to the interval list invalidates any previously-sent flags
      // for the current stay so the user gets the new schedule from now on
      "abroadIntervalsSent": <int>[],
    });
  }

  Future<bool> setAbroadStayIncludeHospital(bool include) {
    return _updateAlertField("abroadStayIncludeHospital", {"abroadStayIncludeHospital": include});
  }

  Future<DocumentSnapshot> getStockInformation(String codeName) async {
    return _firestore.collection("stocks-main").doc(codeName).get();
  }

  Future<bool> updateActiveRestockAlerts(Map restockMap) async {
    return _firestore
        .collection("players")
        .doc(_uid)
        .update({"restockActiveAlerts": restockMap})
        .then((value) {
          return true;
        })
        .catchError((e) {
          return false;
        });
  }

  // Returns false without writing anything if the update fails
  Future<bool> subscribeToCityShopRestockNotification(bool? subscribe) async {
    final Map<String, Object?> update = {"cityShopRestockNotification": subscribe};
    if (subscribe == true) {
      return _updateWithCityShopMarksNow("cityShopRestockNotification", update);
    }
    return _updateAlertField("cityShopRestockNotification", update);
  }

  // Returns false without writing anything if the update fails
  Future<bool> setCityShopOnlyConfirmed(bool enabled) async {
    final Map<String, Object?> update = {"cityShopOnlyConfirmed": enabled};
    if (enabled) {
      return _updateWithCityShopMarksNow("cityShopOnlyConfirmed", update);
    }
    return _updateAlertField("cityShopOnlyConfirmed", update);
  }

  // Returns false without writing anything if the update fails
  Future<bool> setCityShopOnlyInTorn(bool enabled) {
    return _updateAlertField("cityShopOnlyInTorn", {"cityShopOnlyInTorn": enabled});
  }

  // ms until which the server skips city shop alerts; 0 clears it
  // Returns false without writing anything if the update fails
  Future<bool> setCityShopMutedUntil(int untilMs) async {
    final success = await _updateAlertField("cityShopMutedUntil", {"cityShopMutedUntil": untilMs});
    if (success) {
      _firebaseUserModel?.cityShopMutedUntil = untilMs;
    }
    return success;
  }

  // Hours are TCT minutes of the day
  // Returns false without writing anything if the update fails
  Future<bool> setCityShopHours({required bool enabled, required int fromMin, required int toMin}) {
    return _updateAlertField("cityShopHoursEnabled", {
      "cityShopHoursEnabled": enabled,
      "cityShopHoursFrom": fromMin,
      "cityShopHoursTo": toMin,
    });
  }

  // Sets every followed key to now, so restocks already seen are not notified
  // Returns false without writing anything if the current alerts can't be read
  Future<bool> _updateWithCityShopMarksNow(String fieldName, Map<String, Object?> update) async {
    Map<String, dynamic> alerts;
    try {
      final doc = await _firestore.collection("players").doc(_uid).get();
      final remote = doc.data()?["cityShopActiveAlerts"];
      alerts = remote is Map ? Map<String, dynamic>.from(remote) : <String, dynamic>{};
    } catch (e, s) {
      logErrorToCrashlytics("Alert field update failed: $fieldName", e, s);
      return false;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final key in alerts.keys) {
      alerts[key] = now;
      update["cityShopActiveAlerts.$key"] = FieldValue.serverTimestamp();
    }
    final success = await _updateAlertField(fieldName, update);
    if (success) {
      _firebaseUserModel?.cityShopActiveAlerts = alerts;
    }
    return success;
  }

  // Single key, the server writes the others
  Future<bool> setCityShopActiveAlert(String key, bool active) async {
    return _firestore
        .collection("players")
        .doc(_uid)
        .update({
          "cityShopActiveAlerts.$key": active ? FieldValue.serverTimestamp() : FieldValue.delete(),
          if (!active) "cityShopHeadsUp.$key": FieldValue.delete(),
        })
        .then((value) {
          final alerts = _firebaseUserModel?.cityShopActiveAlerts;
          if (active) {
            alerts?[key] = DateTime.now().millisecondsSinceEpoch;
          } else {
            alerts?.remove(key);
          }
          return true;
        })
        .catchError((e) {
          return false;
        });
  }

  // Read from the player document, marks as milliseconds; null without a user
  Future<Map<String, dynamic>?> getCityShopActiveAlerts() async {
    if (_uid == null) return null;
    final doc = await _firestore.collection("players").doc(_uid).get();
    final remote = doc.data()?["cityShopActiveAlerts"];
    if (remote is! Map) return <String, dynamic>{};
    return remote.map(
      (key, value) => MapEntry(key.toString(), value is Timestamp ? value.millisecondsSinceEpoch : value),
    );
  }

  // Null on failure, empty when the document doesn't exist yet
  Future<List<CityShopItemModel>?> getCityShopItems() async {
    try {
      final doc = await _firestore
          .collection("cityshops")
          .doc("items")
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 8));
      final raw = doc.data()?["json"];
      if (raw is! String) return [];
      final data = json.decode(raw);
      if (data is! Map) return [];
      return [
        for (final value in data.values)
          if (value is Map) CityShopItemModel.fromJson(Map<String, dynamic>.from(value)),
      ];
    } catch (e) {
      log("City shop items fetch failed: $e");
      return null;
    }
  }

  Future<bool> subscribeToNerveNotification(bool? subscribe) {
    return _updateAlertField("nerveNotification", {
      "nerveNotification": subscribe,
      // Initialize field for existing users who might not have nerve notifications
      "nerveLastCheckFull": true,
    });
  }

  Future<bool> subscribeToLifeNotification(bool? subscribe) {
    return _updateAlertField("lifeNotification", {
      "lifeNotification": subscribe,
      // Initialize field for existing users who predate life notifications
      "lifeLastCheckFull": true,
    });
  }

  Future<bool> subscribeToDrugsNotification(bool? subscribe) {
    return _updateAlertField("drugsNotification", {
      "drugsNotification": subscribe,
      // Initialize field for existing users who predate drugs notifications
      "drugsInfluence": false,
    });
  }

  Future<bool> subscribeToMedicalNotification(bool? subscribe) {
    return _updateAlertField("medicalNotification", {
      "medicalNotification": subscribe,
      // Initialize field for existing users who predate medical notifications
      "medicalInfluence": false,
    });
  }

  Future<bool> subscribeToBoosterNotification(bool? subscribe) {
    return _updateAlertField("boosterNotification", {
      "boosterNotification": subscribe,
      // Initialize field for existing users who predate booster notifications
      "boosterInfluence": false,
    });
  }

  Future<bool> subscribeToRacingNotification(bool? subscribe) {
    return _updateAlertField("racingNotification", {
      "racingNotification": subscribe,
      // Initialize field for existing users who predate racing notifications
      "racingSent": true,
    });
  }

  Future<bool> subscribeToMessagesNotification(bool? subscribe) {
    return _updateAlertField("messagesNotification", {"messagesNotification": subscribe});
  }

  Future<bool> subscribeToEventsNotification(bool? subscribe) {
    return _updateAlertField("eventsNotification", {"eventsNotification": subscribe});
  }

  Future<void> addToEventsFilter(String filter) async {
    final List currentFilter = _firebaseUserModel!.eventsFilter;
    currentFilter.add(filter);
    await _firestore.collection("players").doc(_uid).update({"eventsFilter": currentFilter});
  }

  Future<void> removeFromEventsFilter(String filter) async {
    final List currentFilter = _firebaseUserModel!.eventsFilter;
    // Avoid duplicities by removing more than one item if they exist
    currentFilter.removeWhere((element) => element == filter);
    await _firestore.collection("players").doc(_uid).update({"eventsFilter": currentFilter});
  }

  Future<bool> subscribeToRefillsNotification(bool? subscribe) {
    int? currentRefillsTime = _firebaseUserModel!.refillsTime;
    return _updateAlertField("refillsNotification", {
      "refillsNotification": subscribe,
      "refillsTime": currentRefillsTime,
    });
  }

  Future<bool> setRefillTime(int? time) {
    return _updateAlertField("refillsTime", {"refillsTime": time});
  }

  Future<void> addToRefillsRequested(String request) async {
    final List currentRequests = _firebaseUserModel!.refillsRequested;
    if (!currentRequests.contains(request)) {
      currentRequests.add(request);
    }
    await _firestore.collection("players").doc(_uid).update({"refillsRequested": currentRequests});
  }

  Future<void> removeFromRefillsRequested(String request) async {
    final List currentRequests = _firebaseUserModel!.refillsRequested;
    // Avoid duplicities by removing more than one item if they exist
    currentRequests.removeWhere((element) => element == request);
    await _firestore.collection("players").doc(_uid).update({"refillsRequested": currentRequests});
  }

  Future<bool> subscribeToHospitalNotification(bool? subscribe) {
    return _updateAlertField("hospitalNotification", {"hospitalNotification": subscribe});
  }

  Future<bool> uploadLastActiveTimeAndTokensToFirebase(int timeStamp) async {
    if (_uid == null) return false;

    try {
      final Map<String, dynamic> updatePayload = {"lastActive": timeStamp, "active": true};

      final apiKey = UserHelper.apiKey;
      if (apiKey.isNotEmpty) {
        updatePayload["apiKey"] = apiKey;
      }

      if (Platform.isIOS && kSdkIos >= 17.2) {
        final laTravelEnabled = await Prefs().getIosLiveActivityTravelEnabled();
        final laRacingEnabled = await Prefs().getIosLiveActivityRacingEnabled();
        if (laTravelEnabled || laRacingEnabled) {
          final bridgeController = Get.find<LiveActivityBridgeController>();

          if (laTravelEnabled) {
            final String? tokenToUpdate = await bridgeController.getPushToStartTokenOnly(
              activityType: LiveActivityType.travel,
            );

            if (tokenToUpdate != null) {
              updatePayload['la_travel_push_token'] = tokenToUpdate;
              await Prefs().setLaPushToken(token: tokenToUpdate, activityType: LiveActivityType.travel);
            }
          }

          if (laRacingEnabled) {
            final String? tokenToUpdate = await bridgeController.getPushToStartTokenOnly(
              activityType: LiveActivityType.racing,
            );

            if (tokenToUpdate != null) {
              updatePayload['la_racing_push_token'] = tokenToUpdate;
              await Prefs().setLaPushToken(token: tokenToUpdate, activityType: LiveActivityType.racing);
            }
          }
        }
      }

      log("Uploading data to Firestore: $updatePayload");
      await _firestore.collection("players").doc(_uid).update(updatePayload);
      return true;
    } catch (error) {
      log("Error in uploadLastActiveTime: $error");
      return false;
    }
  }

  // Init State in alerts
  Future<FirebaseUserModel?> getUserProfile({bool force = false, bool fromServer = false}) async {
    if (_firebaseUserModel != null && !force) return _firebaseUserModel;
    final docRef = _firestore.collection("players").doc(_uid);
    DocumentSnapshot<Map<String, dynamic>> userReceived;
    if (fromServer) {
      try {
        userReceived = await docRef.get(const GetOptions(source: Source.server)).timeout(const Duration(seconds: 8));
      } catch (e) {
        userReceived = await docRef.get();
      }
    } else {
      userReceived = await docRef.get();
    }
    if (userReceived.data() == null) {
      // New user returns nothing, so use default model fields
      return FirebaseUserModel();
    }
    _firebaseUserModel = FirebaseUserModel.fromMap(userReceived.data()!);
    // Persist a local snapshot for auth-recovery fallback
    persistLocalSnapshot();
    return _firebaseUserModel;
  }

  Future<String?> findMostRecentUidByApiKey(String apiKey) async {
    try {
      final query = await _firestore
          .collection("players")
          .where("apiKey", isEqualTo: apiKey)
          .orderBy("lastActive", descending: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;
      return query.docs.first.id;
    } catch (e, s) {
      log("Error finding UID by apiKey: $e", stackTrace: s);
      return null;
    }
  }

  Future<Map<String, dynamic>?> cloneUserProfileFromPayload(Map<String, dynamic> payload) async {
    if (_uid == null) return null;

    try {
      final cloned = Map<String, dynamic>.from(payload);
      cloned.remove("uid");
      cloned.remove("token");
      cloned.remove("tokenErrors");

      await _firestore.collection("players").doc(_uid).set(cloned);

      cloned["uid"] = _uid;
      _firebaseUserModel = FirebaseUserModel.fromMap(cloned);
      return cloned;
    } catch (e, s) {
      log("Error cloning profile from payload into $_uid: $e", stackTrace: s);
      return null;
    }
  }

  Future<bool> applyAlertsFromPayload(Map<String, dynamic> payload, {bool resetRestockTimestamps = false}) async {
    if (_uid == null) return false;

    final now = DateTime.now().millisecondsSinceEpoch;

    Map<String, dynamic> restocks = {};
    if (payload.containsKey("restockActiveAlerts") && payload["restockActiveAlerts"] is Map) {
      restocks = Map<String, dynamic>.from(payload["restockActiveAlerts"] as Map);
      if (resetRestockTimestamps) {
        restocks = restocks.map((k, _) => MapEntry(k.toString(), now));
      }
    }

    Map<String, dynamic> cityShopAlerts = {};
    if (payload.containsKey("cityShopActiveAlerts") && payload["cityShopActiveAlerts"] is Map) {
      cityShopAlerts = Map<String, dynamic>.from(payload["cityShopActiveAlerts"] as Map);
      if (resetRestockTimestamps) {
        cityShopAlerts = cityShopAlerts.map((k, _) => MapEntry(k.toString(), now));
      }
    }

    final Map<String, dynamic> updates = {};
    void addIfPresent(String key) {
      if (payload.containsKey(key)) updates[key] = payload[key];
    }

    // Use centralized list from main.dart
    for (final field in kAlertFirestoreFields) {
      addIfPresent(field);
    }

    if (restocks.isNotEmpty) {
      updates["restockActiveAlerts"] = restocks;
    }

    if (cityShopAlerts.isNotEmpty) {
      updates["cityShopActiveAlerts"] = cityShopAlerts;
    }

    if (updates.isEmpty) return false;

    await _firestore.collection("players").doc(_uid).set(updates, SetOptions(merge: true));
    return true;
  }

  Future deleteUserProfile() async {
    _alreadyUploaded = false;
    await _firestore.collection("players").doc(_uid).delete();
  }

  Future<void> setVibrationPattern(String? pattern) async {
    await _firestore.collection("players").doc(_uid).update({"vibration": pattern});
  }

  // --- Local Snapshot Logic ---
  static const String _kLocalUserSnapshot = "_local_user_model_snapshot";

  Future<void> persistLocalSnapshot() async {
    if (_firebaseUserModel == null) return;
    try {
      final jsonStr = jsonEncode(
        _firebaseUserModel!.toMap(),
        toEncodable: (value) => value is Timestamp ? value.millisecondsSinceEpoch : value,
      );
      await PrefsDatabase.setString(_kLocalUserSnapshot, jsonStr);
    } catch (e) {
      log("Snapshot save failed: $e");
    }
  }

  Future<FirebaseUserModel?> loadLocalSnapshot() async {
    try {
      final jsonStr = await PrefsDatabase.getString(_kLocalUserSnapshot, "");
      if (jsonStr.isEmpty) return null;
      final map = jsonDecode(jsonStr);
      return FirebaseUserModel.fromMap(map);
    } catch (e) {
      log("Snapshot load failed: $e");
      return null;
    }
  }
  // ----------------------------

  Future<void> subscribeToStockMarketNotification(bool? subscribe) async {
    await _firestore.collection("players").doc(_uid).update({"stockMarketNotification": subscribe});
  }

  Future<bool> addStockMarketShare(String? ticker, String action) async {
    final List currentStocks = _firebaseUserModel!.stockMarketShares;
    // Format: ticker-gain-price-loss-price ('n' for empty)
    // Example: YAZ-G-840-L-n
    // Example to delete: YAZ-remove
    currentStocks.removeWhere((element) => element.contains(ticker));
    if (!action.contains("remove")) {
      currentStocks.add(action);
    }

    return _firestore
        .collection("players")
        .doc(_uid)
        .update({"stockMarketShares": currentStocks})
        .then((value) {
          return true;
        })
        .catchError((error) {
          return false;
        });
  }

  Future<bool> toggleFactionAssistMessage(bool? active) {
    return _updateAlertField("factionAssistMessage", {"factionAssistMessage": active});
  }

  /// [host] stands for someone that does not have proper Faction API permissions
  Future<bool> toggleRetaliationNotification(bool active, {bool host = true}) {
    bool isHost = host;
    if (!active) isHost = false;

    return _updateAlertField("retalsNotification", {
      "retalsNotification": active,
      "retalsNotificationHost": isHost,
    });
  }

  /// [host] stands for someone that does not have proper Faction API permissions
  Future<bool> toggleRetaliationDonor(bool donor) {
    return _updateAlertField("retalsNotificationDonor", {"retalsNotificationDonor": donor});
  }

  Future<void> toggleNpcAlert({required String id, required int level, required bool active}) async {
    if (active) {
      if (!_firebaseUserModel!.lootAlerts.contains("$id:$level")) {
        _firebaseUserModel!.lootAlerts.add("$id:$level");
        await _firestore.collection("players").doc(_uid).update({"lootAlerts": _firebaseUserModel!.lootAlerts});
      }
    } else {
      _firebaseUserModel!.lootAlerts.remove("$id:$level");
      await _firestore.collection("players").doc(_uid).update({"lootAlerts": _firebaseUserModel!.lootAlerts});
    }
  }

  Future<bool> subscribeToLootRangersNotification(bool? subscribe) {
    return _updateAlertField("lootRangersNotification", {"lootRangersNotification": subscribe});
  }

  Future<bool> setLootAlertAheadSeconds(int seconds) {
    return _updateAlertField("lootAlertAheadSeconds", {"lootAlertAheadSeconds": seconds});
  }

  Future<bool> setLootRangersAheadSeconds(int seconds) {
    return _updateAlertField("lootRangersAheadSeconds", {"lootRangersAheadSeconds": seconds});
  }

  Future<bool> subscribeToForumsSubcriptionsNotification(bool? subscribe) {
    return _updateAlertField("forumsSubscriptionsNotification", {
      "forumsSubscriptionsNotification": subscribe,
      "forumsSubscriptionsNotified": [],
    });
  }

  Future<String> _getMessagingToken() async {
    // On iOS, ensure the APNS token exists before getting the FCM one
    if (Platform.isIOS) {
      await FirebaseMessaging.instance.getAPNSToken();
    }

    final String? currentToken = await _messaging.getToken().onError((error, stackTrace) {
      log("TOKEN ERROR!");
      return "error";
    });

    if (currentToken != null) {
      Prefs().setFCMToken(currentToken);
      return currentToken;
    }
    return "error";
  }

  // FCM only fires onTokenRefresh when the token rotates, so tokens that rotated
  // before we had a listener stay stale in Firestore (server sees NotRegistered)
  Future<void> reconcileMessagingToken() async {
    if (Platform.isWindows) return;
    try {
      await uidCompleter.future;
      if (_uid == null) return;

      final token = await _getMessagingToken();
      if (token == "error") return;
      if (token == await Prefs().getFCMTokenSynced()) return;

      await _writeMessagingToken(token);
    } catch (e, s) {
      log("Failed to reconcile FCM token: $e");
      logErrorToCrashlytics("Failed to reconcile FCM token", e, s);
    }
  }

  // Called from the onTokenRefresh stream when FCM rotates the token
  Future<void> onMessagingTokenRefreshed(String newToken) async {
    if (Platform.isWindows || newToken.isEmpty) return;
    try {
      await uidCompleter.future;
      if (_uid == null) return;

      Prefs().setFCMToken(newToken);
      await _writeMessagingToken(newToken);
    } catch (e, s) {
      log("Failed to handle FCM token refresh: $e");
      logErrorToCrashlytics("Failed to handle FCM token refresh", e, s);
    }
  }

  // Writes the token and marks it synced only on success
  Future<void> _writeMessagingToken(String token) async {
    try {
      await _firestore.collection("players").doc(_uid).set({"token": token, "tokenErrors": 0}, SetOptions(merge: true));
      Prefs().setFCMTokenSynced(token);
    } catch (e, s) {
      log("Failed to sync FCM token: $e");
      logErrorToCrashlytics("Failed to sync FCM token", e, s);
    }
  }

  Future<void> disableLiveActivityTravel() async {
    if (_uid == null) return;

    log("Disabling Live Activities for travel. Deleting token from Firestore");
    await _firestore.collection("players").doc(_uid).update({
      "la_travel_push_token": FieldValue.delete(),
      "la_travel_activity_push_token": FieldValue.delete(),
    });
  }

  Future<void> disableLiveActivityRacing() async {
    if (_uid == null) return;

    log("Disabling Live Activities for racing. Deleting token from Firestore");
    await _firestore.collection("players").doc(_uid).update({
      "la_racing_push_token": FieldValue.delete(),
      "la_racing_activity_push_token": FieldValue.delete(),
    });
  }

  Future<bool> subscribeToWorkStatsNotification(bool? subscribe) {
    return _updateAlertField("workStatsNotification", {"workStatsNotification": subscribe});
  }

  Future<void> setWorkStatsTargets({
    required int manualLabor,
    required int intelligence,
    required int endurance,
  }) async {
    await _firestore.collection("players").doc(_uid).update({
      "workStatsManualLaborTarget": manualLabor,
      "workStatsIntelligenceTarget": intelligence,
      "workStatsEnduranceTarget": endurance,
    });
  }
}
