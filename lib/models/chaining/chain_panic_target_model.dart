// To parse this JSON data, do
//
//     final chainPanicTarget = chainPanicTargetFromJson(jsonString);

import 'dart:convert';

PanicTargetModel panicTargetModelFromJson(String str) => PanicTargetModel.fromJson(json.decode(str));

String panicTargetModelToJson(PanicTargetModel data) => json.encode(data.toJson());

class PanicTargetModel {
  PanicTargetModel({
    this.name,
    this.id,
    this.level,
    this.factionName,
  });

  String? name;
  int? id;
  int? level;
  String? factionName;

  factory PanicTargetModel.fromJson(Map<String, dynamic> json) => PanicTargetModel(
        name: json["name"] == null ? null : json["name"],
        id: json["id"] == null ? null : json["id"],
        level: json["level"] == null ? null : json["level"],
        factionName: json["factionName"] == null ? null : json["factionName"],
      );

  Map<String, dynamic> toJson() => {
        "name": name == null ? null : name,
        "id": id == null ? null : id,
        "level": level == null ? null : level,
        "factionName": factionName == null ? null : factionName,
      };
}
