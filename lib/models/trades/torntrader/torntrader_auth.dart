// To parse this JSON data, do
//
//     final tornTraderAuthModel = tornTraderAuthModelFromJson(jsonString);

import 'dart:convert';

TornTraderAuthModel tornTraderAuthModelFromJson(String str) => TornTraderAuthModel.fromJson(json.decode(str));

String tornTraderAuthModelToJson(TornTraderAuthModel data) => json.encode(data.toJson());

class TornTraderAuthModel {
  TornTraderAuthModel({
    //State
    this.error,

    this.message,
    this.allowed,
    this.token,
  });

  // State
  bool error = false;

  String message;
  bool allowed;
  String token;

  factory TornTraderAuthModel.fromJson(Map<String, dynamic> json) => TornTraderAuthModel(
    message: json["message"] == null ? null : json["message"],
    allowed: json["allowed"] == null ? null : json["allowed"],
    token: json["token"] == null ? null : json["token"],
  );

  Map<String, dynamic> toJson() => {
    "message": message == null ? null : message,
    "allowed": allowed == null ? null : allowed,
    "token": token == null ? null : token,
  };
}
