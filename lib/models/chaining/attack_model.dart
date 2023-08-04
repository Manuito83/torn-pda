// To parse this JSON data, do
//
//     final attackModel = attackModelFromJson(jsonString);

// Dart imports:
import 'dart:convert';

AttackModel attackModelFromJson(String str) => AttackModel.fromJson(json.decode(str));

String attackModelToJson(AttackModel data) => json.encode(data.toJson());

/// This attack model has 100 results and is used to get more details. It is
/// used in the Attacks Page to build the cards
class AttackModel {
  Map<String, Attack>? attacks;

  AttackModel({
    this.attacks,
  });

  factory AttackModel.fromJson(Map<String, dynamic> json) => AttackModel(
        attacks: json["attacks"] == null
            ? null
            : Map.from(json["attacks"]).map((k, v) => MapEntry<String, Attack>(k, Attack.fromJson(v))),
      );

  Map<String, dynamic> toJson() => {
        "attacks": attacks == null ? null : Map.from(attacks!).map((k, v) => MapEntry<String, dynamic>(k, v.toJson())),
      };
}

class Attack {
  // External (caution: not in 'toJson')
  String? targetName;
  String? targetId;
  late int targetLevel;
  late bool attackWon;
  late bool attackInitiated;
  List<bool> attackSeriesGreen = <bool>[];

  // From Torn API
  String? code;
  int? timestampStarted;
  int? timestampEnded;
  dynamic attackerId;
  String? attackerName;
  dynamic attackerFaction;
  String? attackerFactionname;
  int? defenderId;
  String? defenderName;
  int? defenderFaction;
  String? defenderFactionname;
  Result? result;
  int? stealthed;
  dynamic respectGain;
  int? chain;
  Modifiers? modifiers;

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
    this.respectGain,
    this.chain,
    this.modifiers,
  });

  factory Attack.fromJson(Map<String, dynamic> json) => Attack(
        code: json["code"] == null ? null : json["code"].toString(), // If code is all number, it comes as double
        timestampStarted: json["timestamp_started"],
        timestampEnded: json["timestamp_ended"],
        attackerId: json["attacker_id"],
        attackerName: json["attacker_name"],
        attackerFaction: json["attacker_faction"],
        attackerFactionname: json["attacker_factionname"],
        defenderId: json["defender_id"],
        defenderName: json["defender_name"],
        defenderFaction: json["defender_faction"],
        defenderFactionname: json["defender_factionname"],
        result: json["result"] == null ? null : resultValues.map[json["result"]],
        stealthed: json["stealthed"],
        respectGain: json["respect_gain"],
        chain: json["chain"],
        modifiers: json["modifiers"] == null ? null : Modifiers.fromJson(json["modifiers"]),
      );

  Map<String, dynamic> toJson() => {
        "code": code,
        "timestamp_started": timestampStarted,
        "timestamp_ended": timestampEnded,
        "attacker_id": attackerId,
        "attacker_name": attackerName,
        "attacker_faction": attackerFaction,
        "attacker_factionname": attackerFactionname,
        "defender_id": defenderId,
        "defender_name": defenderName,
        "defender_faction": defenderFaction,
        "defender_factionname": defenderFactionname,
        "result": result == null ? null : resultValues.reverse![result],
        "stealthed": stealthed,
        "respect_gain": respectGain,
        "chain": chain,
        "modifiers": modifiers == null ? null : modifiers!.toJson(),
      };
}

class Modifiers {
  double? fairFight;
  double? war;
  double? retaliation;
  double? groupAttack;
  double? overseas;
  double? chainBonus;
  double? warlordBonus;

  Modifiers({
    this.fairFight,
    this.war,
    this.retaliation,
    this.groupAttack,
    this.overseas,
    this.chainBonus,
    this.warlordBonus,
  });

  double get getTotalModifier => _calculateTotalModifier();

  double _calculateTotalModifier() {
    return 1.0 * fairFight! * war! * retaliation! * groupAttack! * overseas! * chainBonus! * warlordBonus!;
  }

  factory Modifiers.fromJson(Map<String, dynamic> json) => Modifiers(
        // Make sure everything is a double
        fairFight: json["fair_fight"] is String
            ? double.parse(json["fair_fight"])
            : json["fair_fight"] is int
                ? json["fair_fight"].toDouble()
                : json["fair_fight"] ?? 1,
        war: json["war"] is String
            ? double.parse(json["war"])
            : json["war"] is int
                ? json["war"].toDouble()
                : json["war"] ?? 1,
        retaliation: json["retaliation"] is String
            ? double.parse(json["retaliation"])
            : json["retaliation"] is int
                ? json["retaliation"].toDouble()
                : json["retaliation"] ?? 1,
        groupAttack: json["group_attack"] is String
            ? double.parse(json["group_attack"])
            : json["group_attack"] is int
                ? json["group_attack"].toDouble()
                : json["group_attack"] ?? 1,
        overseas: json["overseas"] is String
            ? double.parse(json["overseas"])
            : json["overseas"] is int
                ? json["overseas"].toDouble()
                : json["overseas"] ?? 1,
        chainBonus: json["chain_bonus"] is String
            ? double.parse(json["chain_bonus"])
            : json["chain_bonus"] is int
                ? json["chain_bonus"].toDouble()
                : json["chain_bonus"] ?? 1,
        warlordBonus: json["warlord_bonus"] is String
            ? double.parse(json["warlord_bonus"])
            : json["warlord_bonus"] is int
                ? json["warlord_bonus"].toDouble()
                : json["warlord_bonus"] ?? 1,
      );

  Map<String, dynamic> toJson() => {
        "fair_fight": fairFight,
        "war": war,
        "retaliation": retaliation,
        "group_attack": groupAttack,
        "overseas": overseas,
        "chain_bonus": chainBonus,
        "warlord_bonus": warlordBonus
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
    reverseMap ??= map.map((k, v) => MapEntry(v, k));
    return reverseMap;
  }
}
