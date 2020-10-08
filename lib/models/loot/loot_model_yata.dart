// To parse this JSON data, do
//
//     final yataLootModel = yataLootModelFromJson(jsonString);

import 'dart:convert';

YataLootModel yataLootModelFromJson(String str) => YataLootModel.fromJson(json.decode(str));

String yataLootModelToJson(YataLootModel data) => json.encode(data.toJson());

class YataLootModel {
  YataLootModel({
    this.hospOut,
    this.nextUpdate,
  });

  Map<String, int> hospOut;
  int nextUpdate;

  factory YataLootModel.fromJson(Map<String, dynamic> json) => YataLootModel(
    hospOut: json["hosp_out"] == null ? null : Map.from(json["hosp_out"]).map((k, v) => MapEntry<String, int>(k, v)),
    nextUpdate: json["next_update"] == null ? null : json["next_update"],
  );

  Map<String, dynamic> toJson() => {
    "hosp_out": hospOut == null ? null : Map.from(hospOut).map((k, v) => MapEntry<String, dynamic>(k, v)),
    "next_update": nextUpdate == null ? null : nextUpdate,
  };
}