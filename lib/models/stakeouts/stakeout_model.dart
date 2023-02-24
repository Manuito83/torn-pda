// To parse this JSON data, do
//
//     final stakeout = stakeoutFromJson(jsonString);

import 'dart:convert';

import 'package:flutter/material.dart';
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
  int lastFetch;

  String id;
  String name;
  Status status;
  LastAction lastAction;
  String personalNote;

  bool okayLast;
  bool okayEnabled;

  bool hospitalLast;
  bool hospitalEnabled;

  Stakeout({
    this.cardExpanded = false,
    this.lastPass = 0,
    this.lastFetch = 0,

    // Main
    @required this.id,
    @required this.name,
    @required this.status,
    @required this.lastAction,
    this.personalNote = "",

    // Okay
    this.okayLast = false,
    this.okayEnabled = false,

    // Hospital
    this.hospitalLast = false,
    this.hospitalEnabled = false,
  });

  factory Stakeout.fromJson(Map<String, dynamic> json) => Stakeout(
        lastFetch: json["lastFetch"],
        id: json["id"],
        name: json["name"],
        status: Status.fromJson(json["status"]),
        lastAction: LastAction.fromJson(json["lastAction"]),
        okayLast: json["okayLast"],
        okayEnabled: json["okayEnabled"],
        hospitalLast: json["hospitalLast"],
        hospitalEnabled: json["hospitalEnabled"],
      );

  Map<String, dynamic> toJson() => {
        "lastFetch": lastFetch,
        "id": id,
        "name": name,
        "status": status.toJson(),
        "lastAction": lastAction.toJson(),
        "okayLast": okayLast,
        "okayEnabled": okayEnabled,
        "hospitalLast": hospitalLast,
        "hospitalEnabled": hospitalEnabled,
      };
}
