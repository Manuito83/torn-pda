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
        name: json["name"],
        id: json["id"],
        level: json["level"],
        factionName: json["factionName"],
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "id": id,
        "level": level,
        "factionName": factionName,
      };
}
