// To parse this JSON data, do
//
//     final stakeout = stakeoutFromJson(jsonString);

import 'dart:convert';

import 'package:torn_pda/models/profile/basic_profile_model.dart';

Stakeout stakeoutFromJson(String str) => Stakeout.fromJson(json.decode(str));

String stakeoutToJson(Stakeout data) => json.encode(data.toJson());

class Stakeout {
  // @Only state
  bool cardExpanded;

  // @Only state
  /// [lastPass] is updated whenever the timer checks a stakeouts, independently of it gets fetched or not
  int lastPass;

  /// [lastFetch] is updated when we fetched the stakeout from Torn for the last time
  int? lastFetch;

  String? id;
  String? name;
  Status? status;
  LastAction? lastAction;
  @Deprecated('Use PlayerNotesController instead')
  String personalNote;
  @Deprecated('Use PlayerNotesController instead')
  String? personalNoteColor;

  bool okayLast;
  bool okayEnabled;

  bool hospitalLast;
  bool hospitalEnabled;

  bool revivableLast;
  bool revivableEnabled;

  bool landedLast;
  bool landedEnabled;

  bool onlineLast;
  bool onlineEnabled;

  bool lifeBelowPercentageLast;
  bool lifeBelowPercentageEnabled;
  int? lifeBelowPercentageLimit;

  bool offlineLongerThanLast;
  bool offlineLongerThanEnabled;
  int? offlineLongerThanLimit;

  Stakeout({
    this.cardExpanded = false,
    this.lastPass = 0,
    this.lastFetch = 0,

    // Main
    required this.id,
    required this.name,
    required this.status,
    required this.lastAction,
    this.personalNote = "",
    this.personalNoteColor = "",

    // Okay
    this.okayLast = false,
    this.okayEnabled = false,

    // Hospital
    this.hospitalLast = false,
    this.hospitalEnabled = false,

    // Revivable
    this.revivableLast = false,
    this.revivableEnabled = false,

    // Has landed
    this.landedLast = false,
    this.landedEnabled = false,

    // Comes online
    this.onlineLast = false,
    this.onlineEnabled = false,

    // Life below percentage
    this.lifeBelowPercentageLast = false,
    this.lifeBelowPercentageEnabled = false,
    this.lifeBelowPercentageLimit = 50,

    // Offline time
    this.offlineLongerThanLast = false,
    this.offlineLongerThanEnabled = false,
    this.offlineLongerThanLimit = 2,
  });

  factory Stakeout.fromJson(Map<String, dynamic> json) => Stakeout(
        lastFetch: json["lastFetch"],
        id: json["id"],
        name: json["name"],
        personalNote: json["personalNote"] ?? "",
        personalNoteColor: json["personalNoteColor"] ?? "",
        status: Status.fromJson(json["status"]),
        lastAction: LastAction.fromJson(json["lastAction"]),
        okayLast: json["okayLast"] ?? false,
        okayEnabled: json["okayEnabled"] ?? false,
        hospitalLast: json["hospitalLast"] ?? false,
        hospitalEnabled: json["hospitalEnabled"] ?? false,
        revivableLast: json["revivableLast"] ?? false,
        revivableEnabled: json["revivableEnabled"] ?? false,
        landedLast: json["landedLast"] ?? false,
        landedEnabled: json["landedEnabled"] ?? false,
        onlineLast: json["onlineLast"] ?? false,
        onlineEnabled: json["onlineEnabled"] ?? false,
        lifeBelowPercentageLast: json["lifeBelowPercentageLast"] ?? false,
        lifeBelowPercentageEnabled: json["lifeBelowPercentageEnabled"] ?? false,
        lifeBelowPercentageLimit: json["lifePercentageLimit"] ?? 50,
        offlineLongerThanLast: json["offlineTimeLast"] ?? false,
        offlineLongerThanEnabled: json["offlineTimeEnabled"] ?? false,
        offlineLongerThanLimit: json["offlineTimeLimit"] ?? 50,
      );

  Map<String, dynamic> toJson() => {
        "lastFetch": lastFetch,
        "id": id,
        "name": name,
        "personalNote": personalNote,
        "personalNoteColor": personalNoteColor,
        "status": status!.toJson(),
        "lastAction": lastAction!.toJson(),
        "okayLast": okayLast,
        "okayEnabled": okayEnabled,
        "hospitalLast": hospitalLast,
        "hospitalEnabled": hospitalEnabled,
        "revivableLast": revivableLast,
        "revivableEnabled": revivableEnabled,
        "landedLast": landedLast,
        "landedEnabled": landedEnabled,
        "onlineLast": onlineLast,
        "onlineEnabled": onlineEnabled,
        "lifeBelowPercentageLast": lifeBelowPercentageLast,
        "lifeBelowPercentageEnabled": lifeBelowPercentageEnabled,
        "lifePercentageLimit": lifeBelowPercentageLimit,
        "offlineTimeLast": offlineLongerThanLast,
        "offlineTimeEnabled": offlineLongerThanEnabled,
        "offlineTimeLimit": offlineLongerThanLimit,
      };
}
