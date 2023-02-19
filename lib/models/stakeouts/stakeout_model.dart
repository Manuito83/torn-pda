// To parse this JSON data, do
//
//     final stakeout = stakeoutFromJson(jsonString);

import 'dart:convert';

import 'package:flutter/material.dart';

Stakeout stakeoutFromJson(String str) => Stakeout.fromJson(json.decode(str));

String stakeoutToJson(Stakeout data) => json.encode(data.toJson());

class Stakeout {
  // Only state
  bool cardExpanded;
  int lastUpdate;

  String id;
  String name;
  String personalNote;

  bool okayLast;
  bool okayEnabled;

  bool hospitalLast;
  bool hospitalEnabled;

  Stakeout({
    this.cardExpanded = false,
    this.lastUpdate = 0,

    // Main
    @required this.id,
    @required this.name,
    this.personalNote = "",

    // Okay
    this.okayLast = false,
    this.okayEnabled = false,

    // Hospital
    this.hospitalLast = false,
    this.hospitalEnabled = false,
  });

  factory Stakeout.fromJson(Map<String, dynamic> json) => Stakeout(
        id: json["id"],
        name: json["name"],
        okayLast: json["okayLast"],
        okayEnabled: json["okayEnabled"],
        hospitalLast: json["hospitalLast"],
        hospitalEnabled: json["hospitalEnabled"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "okayLast": okayLast,
        "okayEnabled": okayEnabled,
        "hospitalLast": hospitalLast,
        "hospitalEnabled": hospitalEnabled,
      };
}
