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

  String id;
  String name;
  String personalNote;

  bool okayNow;
  bool okayLast;
  bool okayEnabled;

  Stakeout({
    this.cardExpanded = false,

    // Main
    @required this.id,
    @required this.name,
    this.personalNote = "",

    // Okay
    @required this.okayNow,
    this.okayLast = false,
    this.okayEnabled = false,
  });

  factory Stakeout.fromJson(Map<String, dynamic> json) => Stakeout(
        id: json["id"],
        name: json["name"],
        okayNow: json["okayNow"],
        okayLast: json["okayLast"],
        okayEnabled: json["okayEnabled"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "okayNow": okayNow,
        "okayLast": okayLast,
        "okayEnabled": okayEnabled,
      };
}
