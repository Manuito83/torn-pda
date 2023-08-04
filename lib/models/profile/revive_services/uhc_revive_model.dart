// To parse this JSON data, do
//
//     final uhcReviveModel = uhcReviveModelFromJson(jsonString);

// Dart imports:
import 'dart:convert';

UhcReviveModel uhcReviveModelFromJson(String str) => UhcReviveModel.fromJson(json.decode(str));

String uhcReviveModelToJson(UhcReviveModel data) => json.encode(data.toJson());

class UhcReviveModel {
  UhcReviveModel({
    this.userID,
    this.userName,
    this.factionName,
    this.factionID,
    this.source,
  });

  int? userID;
  String? userName;
  String? factionName;
  int? factionID;
  String? source;

  factory UhcReviveModel.fromJson(Map<String, dynamic> json) => UhcReviveModel(
    userID: json["userID"],
    userName: json["userName"],
    factionName: json["factionName"],
    factionID: json["factionID"],
    source: json["source"],
  );

  Map<String, dynamic> toJson() => {
    "userID": userID,
    "userName": userName,
    "factionName": factionName,
    "factionID": factionID,
    "source": source,
  };
}
