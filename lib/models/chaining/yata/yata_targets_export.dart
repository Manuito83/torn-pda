// To parse this JSON data, do
//
//     final yataTargetsExportModel = yataTargetsExportModelFromJson(jsonString);

import 'dart:convert';

YataTargetsExportModel yataTargetsExportModelFromJson(String str) => YataTargetsExportModel.fromJson(json.decode(str));

String yataTargetsExportModelToJson(YataTargetsExportModel data) => json.encode(data.toJson());

class YataTargetsExportModel {
  YataTargetsExportModel({
    this.targets,
    this.api,
  });

  Map<String, String> targets;
  String api;

  factory YataTargetsExportModel.fromJson(Map<String, dynamic> json) => YataTargetsExportModel(
    targets: json["targets"] == null ? null : Map.from(json["targets"]).map((k, v) => MapEntry<String, String>(k, v)),
    api: json["api"] == null ? null : json["api"],
  );

  Map<String, dynamic> toJson() => {
    "targets": targets == null ? null : Map.from(targets).map((k, v) => MapEntry<String, dynamic>(k, v)),
    "api": api == null ? null : api,
  };
}
