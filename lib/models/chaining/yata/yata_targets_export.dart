// To parse this JSON data, do
//
//     final yataTargetsExportModel = yataTargetsExportModelFromJson(jsonString);

import 'dart:convert';

YataTargetsExportModel yataTargetsExportModelFromJson(String str) => YataTargetsExportModel.fromJson(json.decode(str));

String yataTargetsExportModelToJson(YataTargetsExportModel data) => json.encode(data.toJson());

class YataTargetsExportModel {
  YataTargetsExportModel({
    this.targets,
    this.key,
  });

  Map<String, String> targets;
  String key;

  factory YataTargetsExportModel.fromJson(Map<String, dynamic> json) => YataTargetsExportModel(
    targets: json["targets"] == null ? null : Map.from(json["targets"]).map((k, v) => MapEntry<String, String>(k, v)),
    key: json["key"] == null ? null : json["key"],
  );

  Map<String, dynamic> toJson() => {
    "targets": targets == null ? null : Map.from(targets).map((k, v) => MapEntry<String, dynamic>(k, v)),
    "key": key == null ? null : key,
  };
}
