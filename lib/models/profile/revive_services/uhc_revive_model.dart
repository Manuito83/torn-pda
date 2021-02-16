// To parse this JSON data, do
//
//     final uhcReviveModel = uhcReviveModelFromJson(jsonString);

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

  int userID;
  String userName;
  String factionName;
  int factionID;
  String source;

  factory UhcReviveModel.fromJson(Map<String, dynamic> json) => UhcReviveModel(
    userID: json["userID"] == null ? null : json["userID"],
    userName: json["userName"] == null ? null : json["userName"],
    factionName: json["factionName"] == null ? null : json["factionName"],
    factionID: json["factionID"] == null ? null : json["factionID"],
    source: json["source"] == null ? null : json["source"],
  );

  Map<String, dynamic> toJson() => {
    "userID": userID == null ? null : userID,
    "userName": userName == null ? null : userName,
    "factionName": factionName == null ? null : factionName,
    "factionID": factionID == null ? null : factionID,
    "source": source == null ? null : source,
  };
}
