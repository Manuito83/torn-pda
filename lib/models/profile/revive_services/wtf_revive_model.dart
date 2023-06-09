// To parse this JSON data, do
//
//     final wtfReviveModel = wtfReviveModelFromJson(jsonString);

import 'dart:convert';

WtfReviveModel wtfReviveModelFromJson(String str) => WtfReviveModel.fromJson(json.decode(str));

String wtfReviveModelToJson(WtfReviveModel data) => json.encode(data.toJson());

class WtfReviveModel {
  String userId;
  String userName;
  String faction;
  String country;
  String requestChannel;

  WtfReviveModel({
    this.userId,
    this.userName,
    this.faction,
    this.country,
    this.requestChannel,
  });

  factory WtfReviveModel.fromJson(Map<String, dynamic> json) => WtfReviveModel(
        userId: json["userID"],
        userName: json["userName"],
        faction: json["Faction"],
        country: json["Country"],
        requestChannel: json["requestChannel"],
      );

  Map<String, dynamic> toJson() => {
        "userID": userId,
        "userName": userName,
        "Faction": faction,
        "Country": country,
        "requestChannel": requestChannel,
      };
}
