// To parse this JSON data, do
//
//     final ownPersonalStatsModel = ownPersonalStatsModelFromJson(jsonString);

import 'dart:convert';

OwnPersonalStatsModel ownPersonalStatsModelFromJson(String str) => OwnPersonalStatsModel.fromJson(json.decode(str));

String ownPersonalStatsModelToJson(OwnPersonalStatsModel data) => json.encode(data.toJson());

class OwnPersonalStatsModel {
  Personalstats? personalstats;

  OwnPersonalStatsModel({
    this.personalstats,
  });

  factory OwnPersonalStatsModel.fromJson(Map<String, dynamic> json) => OwnPersonalStatsModel(
        personalstats: json["personalstats"] == null ? null : Personalstats.fromJson(json["personalstats"]),
      );

  Map<String, dynamic> toJson() => {
        "personalstats": personalstats?.toJson(),
      };
}

class Personalstats {
  int? statenhancersused;
  int? exttaken;
  int? lsdtaken;
  int? xantaken;
  int? networth;
  int? energydrinkused;
  int? refills;

  Personalstats({
    this.statenhancersused,
    this.exttaken,
    this.lsdtaken,
    this.xantaken,
    this.networth,
    this.energydrinkused,
    this.refills,
  });

  factory Personalstats.fromJson(Map<String, dynamic> json) => Personalstats(
        statenhancersused: json["statenhancersused"],
        exttaken: json["exttaken"],
        lsdtaken: json["lsdtaken"],
        xantaken: json["xantaken"],
        networth: json["networth"],
        energydrinkused: json["energydrinkused"],
        refills: json["refills"],
      );

  Map<String, dynamic> toJson() => {
        "statenhancersused": statenhancersused,
        "exttaken": exttaken,
        "lsdtaken": lsdtaken,
        "xantaken": xantaken,
        "networth": networth,
        "energydrinkused": energydrinkused,
        "refills": refills,
      };
}
