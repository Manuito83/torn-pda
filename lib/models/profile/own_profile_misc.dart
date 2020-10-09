// To parse this JSON data, do
//
//     final ownProfileMisc = ownProfileMiscFromJson(jsonString);

import 'dart:convert';

/// This exists because if we mix some requests in Torn (e.g.: money and networth), there is
/// some data that does not show up. So this complements.
OwnProfileMiscModel ownProfileMiscFromJson(String str) => OwnProfileMiscModel.fromJson(json.decode(str));

String ownProfileMiscToJson(OwnProfileMiscModel data) => json.encode(data.toJson());

class OwnProfileMiscModel {
  OwnProfileMiscModel({
    this.points,
    this.caymanBank,
    this.vaultAmount,
    this.dailyNetworth,
    this.moneyOnhand,
    this.educationCurrent,
    this.educationTimeleft,
    this.manualLabor,
    this.intelligence,
    this.endurance,
    this.strength,
    this.speed,
    this.dexterity,
    this.defense,
    this.total,
    this.strengthModifier,
    this.defenseModifier,
    this.speedModifier,
    this.dexterityModifier,
    this.cityBank,
    this.educationCompleted,
    this.strengthInfo,
    this.defenseInfo,
    this.speedInfo,
    this.dexterityInfo,
  });

  int points;
  int caymanBank;
  int vaultAmount;
  int dailyNetworth;
  int moneyOnhand;
  int educationCurrent;
  int educationTimeleft;
  int manualLabor;
  int intelligence;
  int endurance;
  int strength;
  int speed;
  int dexterity;
  int defense;
  int total;
  int strengthModifier;
  int defenseModifier;
  int speedModifier;
  int dexterityModifier;
  CityBank cityBank;
  List<int> educationCompleted;
  List<String> strengthInfo;
  List<String> defenseInfo;
  List<String> speedInfo;
  List<String> dexterityInfo;

  factory OwnProfileMiscModel.fromJson(Map<String, dynamic> json) => OwnProfileMiscModel(
    points: json["points"] == null ? null : json["points"],
    caymanBank: json["cayman_bank"] == null ? null : json["cayman_bank"],
    vaultAmount: json["vault_amount"] == null ? null : json["vault_amount"],
    dailyNetworth: json["daily_networth"] == null ? null : json["daily_networth"],
    moneyOnhand: json["money_onhand"] == null ? null : json["money_onhand"],
    educationCurrent: json["education_current"] == null ? null : json["education_current"],
    educationTimeleft: json["education_timeleft"] == null ? null : json["education_timeleft"],
    manualLabor: json["manual_labor"] == null ? null : json["manual_labor"],
    intelligence: json["intelligence"] == null ? null : json["intelligence"],
    endurance: json["endurance"] == null ? null : json["endurance"],
    strength: json["strength"] == null ? null : json["strength"],
    speed: json["speed"] == null ? null : json["speed"],
    dexterity: json["dexterity"] == null ? null : json["dexterity"],
    defense: json["defense"] == null ? null : json["defense"],
    total: json["total"] == null ? null : json["total"],
    strengthModifier: json["strength_modifier"] == null ? null : json["strength_modifier"],
    defenseModifier: json["defense_modifier"] == null ? null : json["defense_modifier"],
    speedModifier: json["speed_modifier"] == null ? null : json["speed_modifier"],
    dexterityModifier: json["dexterity_modifier"] == null ? null : json["dexterity_modifier"],
    cityBank: json["city_bank"] == null ? null : CityBank.fromJson(json["city_bank"]),
    educationCompleted: json["education_completed"] == null ? null : List<int>.from(json["education_completed"].map((x) => x)),
    strengthInfo: json["strength_info"] == null ? null : List<String>.from(json["strength_info"].map((x) => x)),
    defenseInfo: json["defense_info"] == null ? null : List<String>.from(json["defense_info"].map((x) => x)),
    speedInfo: json["speed_info"] == null ? null : List<String>.from(json["speed_info"].map((x) => x)),
    dexterityInfo: json["dexterity_info"] == null ? null : List<String>.from(json["dexterity_info"].map((x) => x)),
  );

  Map<String, dynamic> toJson() => {
    "points": points == null ? null : points,
    "cayman_bank": caymanBank == null ? null : caymanBank,
    "vault_amount": vaultAmount == null ? null : vaultAmount,
    "daily_networth": dailyNetworth == null ? null : dailyNetworth,
    "money_onhand": moneyOnhand == null ? null : moneyOnhand,
    "education_current": educationCurrent == null ? null : educationCurrent,
    "education_timeleft": educationTimeleft == null ? null : educationTimeleft,
    "manual_labor": manualLabor == null ? null : manualLabor,
    "intelligence": intelligence == null ? null : intelligence,
    "endurance": endurance == null ? null : endurance,
    "strength": strength == null ? null : strength,
    "speed": speed == null ? null : speed,
    "dexterity": dexterity == null ? null : dexterity,
    "defense": defense == null ? null : defense,
    "total": total == null ? null : total,
    "strength_modifier": strengthModifier == null ? null : strengthModifier,
    "defense_modifier": defenseModifier == null ? null : defenseModifier,
    "speed_modifier": speedModifier == null ? null : speedModifier,
    "dexterity_modifier": dexterityModifier == null ? null : dexterityModifier,
    "city_bank": cityBank == null ? null : cityBank.toJson(),
    "education_completed": educationCompleted == null ? null : List<dynamic>.from(educationCompleted.map((x) => x)),
    "strength_info": strengthInfo == null ? null : List<dynamic>.from(strengthInfo.map((x) => x)),
    "defense_info": defenseInfo == null ? null : List<dynamic>.from(defenseInfo.map((x) => x)),
    "speed_info": speedInfo == null ? null : List<dynamic>.from(speedInfo.map((x) => x)),
    "dexterity_info": dexterityInfo == null ? null : List<dynamic>.from(dexterityInfo.map((x) => x)),
  };
}

class CityBank {
  CityBank({
    this.amount,
    this.timeLeft,
  });

  int amount;
  int timeLeft;

  factory CityBank.fromJson(Map<String, dynamic> json) => CityBank(
    amount: json["amount"] == null ? null : json["amount"],
    timeLeft: json["time_left"] == null ? null : json["time_left"],
  );

  Map<String, dynamic> toJson() => {
    "amount": amount == null ? null : amount,
    "time_left": timeLeft == null ? null : timeLeft,
  };
}
