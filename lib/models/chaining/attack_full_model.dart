// To parse this JSON data, do
//
//     final attackFullModel = attackFullModelFromJson(jsonString);

// Dart imports:
import 'dart:convert';

AttackFullModel attackFullModelFromJson(String str) => AttackFullModel.fromJson(json.decode(str));

String attackFullModelToJson(AttackFullModel data) => json.encode(data.toJson());

/// This attack model has 1000 results and is used to get a full history
/// of attacks (for example, to get respect from someone who has not been
/// attacked in the last few weeks)
class AttackFullModel {
  Map<String, AttackFull>? attacks;

  AttackFullModel({
    this.attacks,
  });

  factory AttackFullModel.fromJson(Map<String, dynamic> json) => AttackFullModel(
    attacks: json["attacks"] == null ? null : Map.from(json["attacks"]).map((k, v) => MapEntry<String, AttackFull>(k, AttackFull.fromJson(v))),
  );

  Map<String, dynamic> toJson() => {
    "attacks": attacks == null ? null : Map.from(attacks!).map((k, v) => MapEntry<String, dynamic>(k, v.toJson())),
  };
}

class AttackFull {
  String? code;
  int? timestampStarted;
  int? timestampEnded;
  dynamic attackerId;
  dynamic attackerFaction;
  int? defenderId;
  int? defenderFaction;
  Result? result;
  int? stealthed;
  dynamic respect;

  AttackFull({
    this.code,
    this.timestampStarted,
    this.timestampEnded,
    this.attackerId,
    this.attackerFaction,
    this.defenderId,
    this.defenderFaction,
    this.result,
    this.stealthed,
    this.respect,
  });

  factory AttackFull.fromJson(Map<String, dynamic> json) => AttackFull(
    code: json["code"] == null ? null : json["code"],
    timestampStarted: json["timestamp_started"] == null ? null : json["timestamp_started"],
    timestampEnded: json["timestamp_ended"] == null ? null : json["timestamp_ended"],
    attackerId: json["attacker_id"],
    attackerFaction: json["attacker_faction"],
    defenderId: json["defender_id"] == null ? null : json["defender_id"],
    defenderFaction: json["defender_faction"] == null ? null : json["defender_faction"],
    result: json["result"] == null ? null : resultValues.map[json["result"]],
    stealthed: json["stealthed"] == null ? null : json["stealthed"],
    respect: json["respect"],
  );

  Map<String, dynamic> toJson() => {
    "code": code == null ? null : code,
    "timestamp_started": timestampStarted == null ? null : timestampStarted,
    "timestamp_ended": timestampEnded == null ? null : timestampEnded,
    "attacker_id": attackerId,
    "attacker_faction": attackerFaction,
    "defender_id": defenderId == null ? null : defenderId,
    "defender_faction": defenderFaction == null ? null : defenderFaction,
    "result": result == null ? null : resultValues.reverse![result],
    "stealthed": stealthed == null ? null : stealthed,
    "respect": respect,
  };
}

enum Result { ATTACKED, HOSPITALIZED, LOST, MUGGED, SPECIAL, STALEMATE, ARRESTED, ESCAPE, ASSIST }

final resultValues = EnumValues({
  "Arrested": Result.ARRESTED,
  "Assist": Result.ASSIST,
  "Attacked": Result.ATTACKED,
  "Escape": Result.ESCAPE,
  "Hospitalized": Result.HOSPITALIZED,
  "Lost": Result.LOST,
  "Mugged": Result.MUGGED,
  "Special": Result.SPECIAL,
  "Stalemate": Result.STALEMATE
});

class EnumValues<T> {
  Map<String, T> map;
  Map<T, String>? reverseMap;

  EnumValues(this.map);

  Map<T, String>? get reverse {
    if (reverseMap == null) {
      reverseMap = map.map((k, v) => new MapEntry(v, k));
    }
    return reverseMap;
  }
}
