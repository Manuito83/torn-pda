// To parse this JSON data, do
//
//     final yataTargetsExport = yataTargetsExportFromJson(jsonString);

// Dart imports:
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

  Map<String, YataImportTarget>? targets;

  factory YataTargetsImportModel.fromJson(Map<String, dynamic> json) => YataTargetsImportModel(
    targets: json["targets"] == null ? null : Map.from(json["targets"]).map((k, v) => MapEntry<String, YataImportTarget>(k, YataImportTarget.fromJson(v))),
  );

  Map<String, dynamic> toJson() => {
    "targets": targets == null ? null : Map.from(targets!).map((k, v) => MapEntry<String, dynamic>(k, v.toJson())),
  };
}

class YataImportTarget {
  YataImportTarget({
    this.name,
    this.note,
    this.color,
  });

  String? name;
  String? note;
  int? color;

  factory YataImportTarget.fromJson(Map<String, dynamic> json) => YataImportTarget(
    name: json["name"],
    note: json["note"],
    color: json["color"],
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "note": note,
    "color": color,
  };
}
