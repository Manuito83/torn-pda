// To parse this JSON data, do
//
//     final factionAttacksModel = factionAttacksModelFromJson(jsonString);

import 'dart:convert';

FactionAttacksModel factionAttacksModelFromJson(String str) => FactionAttacksModel.fromJson(json.decode(str));

String factionAttacksModelToJson(FactionAttacksModel data) => json.encode(data.toJson());

class FactionAttacksModel {
  FactionAttacksModel({
    this.attacks,
  });

  Map<String, Attack> attacks;

  factory FactionAttacksModel.fromJson(Map<String, dynamic> json) => FactionAttacksModel(
        attacks: json["attacks"] == null
            ? null
            : Map.from(json["attacks"]).map((k, v) => MapEntry<String, Attack>(k, Attack.fromJson(v))),
      );

  Map<String, dynamic> toJson() => {
        "attacks": attacks == null ? null : Map.from(attacks).map((k, v) => MapEntry<String, dynamic>(k, v.toJson())),
      };
}

class Attack {
  Attack({
    this.code,
    this.timestampStarted,
    this.timestampEnded,
    this.attackerId,
    this.attackerName,
    this.attackerFaction,
    this.attackerFactionname,
    this.defenderId,
    this.defenderName,
    this.defenderFaction,
    this.defenderFactionname,
    this.result,
    this.stealthed,
    this.respect,
    this.chain,
    this.raid,
    this.rankedWar,
    this.respectGain,
    this.respectLoss,
    this.modifiers,
  });

  String code;
  int timestampStarted;
  int timestampEnded;
  dynamic attackerId;
  String attackerName;
  dynamic attackerFaction;
  String attackerFactionname;
  int defenderId;
  String defenderName;
  int defenderFaction;
  String defenderFactionname;
  Result result;
  int stealthed;
  double respect;
  int chain;
  int raid;
  int rankedWar;
  double respectGain;
  double respectLoss;
  Modifiers modifiers;

  factory Attack.fromJson(Map<String, dynamic> json) => Attack(
        code: json["code"] == null ? null : json["code"],
        timestampStarted: json["timestamp_started"] == null ? null : json["timestamp_started"],
        timestampEnded: json["timestamp_ended"] == null ? null : json["timestamp_ended"],
        attackerId: json["attacker_id"],
        attackerName: json["attacker_name"] == null ? null : json["attacker_name"],
        attackerFaction: json["attacker_faction"],
        attackerFactionname: json["attacker_factionname"] == null ? null : json["attacker_factionname"],
        defenderId: json["defender_id"] == null ? null : json["defender_id"],
        defenderName: json["defender_name"] == null ? null : json["defender_name"],
        defenderFaction: json["defender_faction"] == null ? null : json["defender_faction"],
        defenderFactionname: json["defender_factionname"] == null ? null : json["defender_factionname"],
        result: json["result"] == null ? null : resultValues.map[json["result"]],
        stealthed: json["stealthed"] == null ? null : json["stealthed"],
        respect: json["respect"] == null ? null : json["respect"].toDouble(),
        chain: json["chain"] == null ? null : json["chain"],
        raid: json["raid"] == null ? null : json["raid"],
        rankedWar: json["ranked_war"] == null ? null : json["ranked_war"],
        respectGain: json["respect_gain"] == null ? null : json["respect_gain"].toDouble(),
        respectLoss: json["respect_loss"] == null ? null : json["respect_loss"].toDouble(),
        modifiers: json["modifiers"] == null ? null : Modifiers.fromJson(json["modifiers"]),
      );

  Map<String, dynamic> toJson() => {
        "code": code == null ? null : code,
        "timestamp_started": timestampStarted == null ? null : timestampStarted,
        "timestamp_ended": timestampEnded == null ? null : timestampEnded,
        "attacker_id": attackerId,
        "attacker_name": attackerName == null ? null : attackerName,
        "attacker_faction": attackerFaction,
        "attacker_factionname": attackerFactionname == null ? null : attackerFactionname,
        "defender_id": defenderId == null ? null : defenderId,
        "defender_name": defenderName == null ? null : defenderName,
        "defender_faction": defenderFaction == null ? null : defenderFaction,
        "defender_factionname": defenderFactionname == null ? null : defenderFactionname,
        "result": result == null ? null : resultValues.reverse[result],
        "stealthed": stealthed == null ? null : stealthed,
        "respect": respect == null ? null : respect,
        "chain": chain == null ? null : chain,
        "raid": raid == null ? null : raid,
        "ranked_war": rankedWar == null ? null : rankedWar,
        "respect_gain": respectGain == null ? null : respectGain,
        "respect_loss": respectLoss == null ? null : respectLoss,
        "modifiers": modifiers == null ? null : modifiers.toJson(),
      };
}

class Modifiers {
  Modifiers({
    this.fairFight,
    this.war,
    this.retaliation,
    this.groupAttack,
    this.overseas,
    this.chainBonus,
  });

  double fairFight;
  double war;
  double retaliation;
  double groupAttack;
  double overseas;
  double chainBonus;

  factory Modifiers.fromJson(Map<String, dynamic> json) => Modifiers(
        fairFight: json["fair_fight"] == null ? null : json["fair_fight"].toDouble(),
        war: json["war"] == null ? null : json["war"].toDouble(),
        retaliation: json["retaliation"] == null ? null : json["retaliation"].toDouble(),
        groupAttack: json["group_attack"] == null ? null : json["group_attack"].toDouble(),
        overseas: json["overseas"] == null ? null : json["overseas"].toDouble(),
        chainBonus: json["chain_bonus"] == null ? null : json["chain_bonus"].toDouble(),
      );

  Map<String, dynamic> toJson() => {
        "fair_fight": fairFight == null ? null : fairFight,
        "war": war == null ? null : war,
        "retaliation": retaliation == null ? null : retaliation,
        "group_attack": groupAttack == null ? null : groupAttack,
        "overseas": overseas == null ? null : overseas,
        "chain_bonus": chainBonus == null ? null : chainBonus,
      };
}

enum Result { MUGGED, HOSPITALIZED, STALEMATE, LOST, ATTACKED, ESCAPE, ARRESTED, SPECIAL, ASSIST }

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
  Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    if (reverseMap == null) {
      reverseMap = map.map((k, v) => new MapEntry(v, k));
    }
    return reverseMap;
  }
}
