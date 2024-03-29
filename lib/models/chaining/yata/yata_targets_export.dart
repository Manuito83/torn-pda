// To parse this JSON data, do
//
//     final yataTargetsExportModel = yataTargetsExportModelFromJson(jsonString);

// Dart imports:
import 'dart:convert';

YataTargetsExportModel yataTargetsExportModelFromJson(String str) => YataTargetsExportModel.fromJson(json.decode(str));

String yataTargetsExportModelToJson(YataTargetsExportModel data) => json.encode(data.toJson());

class YataTargetsExportModel {
  YataTargetsExportModel({
    this.targets,
    this.key,
    //this.user,
  });

  Map<String?, YataExportTarget>? targets;
  String? key;
  //String user;

  factory YataTargetsExportModel.fromJson(Map<String, dynamic> json) => YataTargetsExportModel(
    targets: json["targets"] == null ? null : Map.from(json["targets"]).map((k, v) => MapEntry<String, YataExportTarget>(k, YataExportTarget.fromJson(v))),
    key: json["key"],
    //user: json["user"] == null ? null : json["user"],
  );

  Map<String, dynamic> toJson() => {
    "targets": targets == null ? null : Map.from(targets!).map((k, v) => MapEntry<String, dynamic>(k, v.toJson())),
    "key": key,
    //"user": user == null ? null : user,
  };
}

class YataExportTarget {
  YataExportTarget({
    this.note,
    this.color,
  });

  String? note;
  int? color;

  factory YataExportTarget.fromJson(Map<String, dynamic> json) => YataExportTarget(
    note: json["note"],
    color: json["color"],
  );

  Map<String, dynamic> toJson() => {
    "note": note,
    "color": color,
  };
}

