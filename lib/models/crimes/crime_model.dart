// To parse this JSON data, do
//
//     final crime = crimeFromJson(jsonString);

import 'dart:convert';
import 'package:flutter/material.dart';

Crime crimeFromJson(String str) => Crime.fromJson(json.decode(str));

String crimeToJson(Crime data) => json.encode(data.toJson());

class Crime {
  Crime({
    @required this.nerve,
    @required this.fullName,
    @required this.shortName,
    @required this.action,
    @required this.active,
  });

  int nerve;
  String fullName;
  String shortName;
  String action;
  bool active;

  factory Crime.fromJson(Map<String, dynamic> json) => Crime(
    nerve: json["nerve"] == null ? null : json["nerve"],
    fullName: json["fullName"] == null ? null : json["fullName"],
    shortName: json["shortName"] == null ? null : json["shortName"],
    action: json["action"] == null ? null : json["action"],
    active: json["active"] == null ? null : json["active"],
  );

  Map<String, dynamic> toJson() => {
    "nerve": nerve == null ? null : nerve,
    "fullName": fullName == null ? null : fullName,
    "shortName": shortName == null ? null : shortName,
    "action": action == null ? null : action,
    "active": active == null ? null : active,
  };
}