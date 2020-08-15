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
    this.networth,
    this.moneyOnhand,
    this.educationCurrent,
    this.educationTimeleft,
    this.cityBank,
    this.educationCompleted,
  });

  int points;
  int caymanBank;
  int vaultAmount;
  int networth;
  int moneyOnhand;
  int educationCurrent;
  int educationTimeleft;
  CityBank cityBank;
  List<int> educationCompleted;

  factory OwnProfileMiscModel.fromJson(Map<String, dynamic> json) => OwnProfileMiscModel(
    points: json["points"] == null ? null : json["points"],
    caymanBank: json["cayman_bank"] == null ? null : json["cayman_bank"],
    vaultAmount: json["vault_amount"] == null ? null : json["vault_amount"],
    networth: json["networth"] == null ? null : json["networth"],
    moneyOnhand: json["money_onhand"] == null ? null : json["money_onhand"],
    educationCurrent: json["education_current"] == null ? null : json["education_current"],
    educationTimeleft: json["education_timeleft"] == null ? null : json["education_timeleft"],
    cityBank: json["city_bank"] == null ? null : CityBank.fromJson(json["city_bank"]),
    educationCompleted: json["education_completed"] == null ? null : List<int>.from(json["education_completed"].map((x) => x)),
  );

  Map<String, dynamic> toJson() => {
    "points": points == null ? null : points,
    "cayman_bank": caymanBank == null ? null : caymanBank,
    "vault_amount": vaultAmount == null ? null : vaultAmount,
    "networth": networth == null ? null : networth,
    "money_onhand": moneyOnhand == null ? null : moneyOnhand,
    "education_current": educationCurrent == null ? null : educationCurrent,
    "education_timeleft": educationTimeleft == null ? null : educationTimeleft,
    "city_bank": cityBank == null ? null : cityBank.toJson(),
    "education_completed": educationCompleted == null ? null : List<dynamic>.from(educationCompleted.map((x) => x)),
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
