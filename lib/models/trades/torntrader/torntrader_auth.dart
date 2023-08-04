// To parse this JSON data, do
//
//     final tornTraderAuthModel = tornTraderAuthModelFromJson(jsonString);

// Dart imports:
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
  bool? error = false;

  String? message;
  bool? allowed;
  String? token;

  factory TornTraderAuthModel.fromJson(Map<String, dynamic> json) => TornTraderAuthModel(
    message: json["message"],
    allowed: json["allowed"],
    token: json["token"],
  );

  Map<String, dynamic> toJson() => {
    "message": message,
    "allowed": allowed,
    "token": token,
  };
}
