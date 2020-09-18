// To parse this JSON data, do
//
//     final yataTargetsExport = yataTargetsExportFromJson(jsonString);

import 'dart:convert';

YataTargetsImportModel yataTargetsImportModelFromJson(String str) => YataTargetsImportModel.fromJson(json.decode(str));

String yataTargetsImportModelToJson(YataTargetsImportModel data) => json.encode(data.toJson());

class YataTargetsImportModel {
  YataTargetsImportModel({
    this.targets,
  });

  // State
  bool errorConnection = false;
  bool errorPlayer = false;

  Map<String, YataTarget> targets;

  factory YataTargetsImportModel.fromJson(Map<String, dynamic> json) => YataTargetsImportModel(
    targets: json["targets"] == null ? null : Map.from(json["targets"]).map((k, v) => MapEntry<String, YataTarget>(k, YataTarget.fromJson(v))),
  );

  Map<String, dynamic> toJson() => {
    "targets": targets == null ? null : Map.from(targets).map((k, v) => MapEntry<String, dynamic>(k, v.toJson())),
  };
}

class YataTarget {
  YataTarget({
    this.name,
    this.note,
  });

  String name;
  String note;

  factory YataTarget.fromJson(Map<String, dynamic> json) => YataTarget(
    name: json["name"] == null ? null : json["name"],
    note: json["note"] == null ? null : json["note"],
  );

  Map<String, dynamic> toJson() => {
    "name": name == null ? null : name,
    "note": note == null ? null : note,
  };
}