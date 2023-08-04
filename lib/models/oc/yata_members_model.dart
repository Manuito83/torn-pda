// To parse this JSON data, do
//
//     final yataMembersModel = yataMembersModelFromJson(jsonString);

import 'dart:convert';

YataMembersModel yataMembersModelFromJson(String str) => YataMembersModel.fromJson(json.decode(str));

String yataMembersModelToJson(YataMembersModel data) => json.encode(data.toJson());

class YataMembersModel {
  YataMembersModel({
    this.members,
    this.timestamp,
  });

  Map<String, Member>? members;
  int? timestamp;

  factory YataMembersModel.fromJson(Map<String, dynamic> json) => YataMembersModel(
        members: Map.from(json["members"]).map((k, v) => MapEntry<String, Member>(k, Member.fromJson(v))),
        timestamp: json["timestamp"],
      );

  Map<String, dynamic> toJson() => {
        "members": Map.from(members!).map((k, v) => MapEntry<String, dynamic>(k, v.toJson())),
        "timestamp": timestamp,
      };
}

class Member {
  Member({
    this.id,
    this.name,
    this.status,
    this.lastAction,
    this.dif,
    this.crimesRank,
    this.bonusScore,
    this.nnbShare,
    this.nnb,
    this.energyShare,
    this.energy,
    this.refill,
    this.drugCd,
    this.revive,
    this.carnage,
    this.statsShare,
    this.statsDexterity,
    this.statsDefense,
    this.statsSpeed,
    this.statsStrength,
    this.statsTotal,
  });

  int? id;
  String? name;
  Status? status;
  int? lastAction;
  int? dif;
  int? crimesRank;
  int? bonusScore;
  int? nnbShare;
  int? nnb;
  int? energyShare;
  int? energy;
  bool? refill;
  int? drugCd;
  bool? revive;
  int? carnage;
  int? statsShare;
  int? statsDexterity;
  int? statsDefense;
  int? statsSpeed;
  int? statsStrength;
  int? statsTotal;

  factory Member.fromJson(Map<String, dynamic> json) => Member(
        id: json["id"],
        name: json["name"],
        status: statusValues.map[json["status"]],
        lastAction: json["last_action"],
        dif: json["dif"],
        crimesRank: json["crimes_rank"],
        bonusScore: json["bonus_score"],
        nnbShare: json["nnb_share"],
        nnb: json["nnb"],
        energyShare: json["energy_share"],
        energy: json["energy"],
        refill: json["refill"],
        drugCd: json["drug_cd"],
        revive: json["revive"],
        carnage: json["carnage"],
        statsShare: json["stats_share"],
        statsDexterity: json["stats_dexterity"],
        statsDefense: json["stats_defense"],
        statsSpeed: json["stats_speed"],
        statsStrength: json["stats_strength"],
        statsTotal: json["stats_total"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "status": statusValues.reverse![status],
        "last_action": lastAction,
        "dif": dif,
        "crimes_rank": crimesRank,
        "bonus_score": bonusScore,
        "nnb_share": nnbShare,
        "nnb": nnb,
        "energy_share": energyShare,
        "energy": energy,
        "refill": refill,
        "drug_cd": drugCd,
        "revive": revive,
        "carnage": carnage,
        "stats_share": statsShare,
        "stats_dexterity": statsDexterity,
        "stats_defense": statsDefense,
        "stats_speed": statsSpeed,
        "stats_strength": statsStrength,
        "stats_total": statsTotal,
      };
}

enum Status { OFFLINE, IDLE, ONLINE }

final statusValues = EnumValues({"Idle": Status.IDLE, "Offline": Status.OFFLINE, "Online": Status.ONLINE});

class EnumValues<T> {
  Map<String, T> map;
  Map<T, String>? reverseMap;

  EnumValues(this.map);

  Map<T, String>? get reverse {
    reverseMap ??= map.map((k, v) => MapEntry(v, k));
    return reverseMap;
  }
}
