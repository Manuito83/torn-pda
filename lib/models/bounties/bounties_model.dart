// To parse this JSON data, do
//
//     final bountiesModel = bountiesModelFromJson(jsonString);

import 'dart:convert';

BountiesModel bountiesModelFromJson(String str) => BountiesModel.fromJson(json.decode(str));

String bountiesModelToJson(BountiesModel data) => json.encode(data.toJson());

class BountiesModel {
  BountiesModel({
    this.levelMax,
    this.removeRed,
  });

  int levelMax;
  bool removeRed;

  factory BountiesModel.fromJson(Map<String, dynamic> json) => BountiesModel(
        levelMax: json["levelMax"] ?? 100,
        removeRed: json["removeRed"] ?? false,
      );

  Map<String, dynamic> toJson() => {
        "levelMax": levelMax == null ? null : levelMax,
        "removeRed": removeRed == null ? null : removeRed,
      };
}
