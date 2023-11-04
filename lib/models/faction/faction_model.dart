// To parse this JSON data, do
//
//     final factionModel = factionModelFromJson(jsonString);

// Dart imports:
import 'dart:convert';

import 'package:torn_pda/models/profile/own_profile_basic.dart';

FactionModel factionModelFromJson(String str) => FactionModel.fromJson(json.decode(str));
String factionModelToJson(FactionModel data) => json.encode(data.toJson());

class FactionModel {
  FactionModel({
    this.hidden,
    //
    this.id,
    this.name,
    this.tag,
    this.leader,
    this.coLeader,
    this.respect,
    this.age,
    this.bestChain,
    //this.territoryWars,
    //this.raidWars,
    //this.peace,
    this.members,
  });

  // War state
  bool? hidden = false;

  int? id;
  String? name;
  dynamic tag;
  int? leader;
  int? coLeader;
  int? respect;
  int? age;
  int? bestChain;
  // If we want to use these in the future, make sure to find good example to build the classes, otherwise
  // we'll get API errors if they are empty
  //TerritoryWars territoryWars;
  //RaidWars raidWars;
  //Peace peace;
  Map<String, Member?>? members;

  factory FactionModel.fromJson(Map<String, dynamic> json) => FactionModel(
        hidden: json["hidden"] ?? false,
        //
        id: json["ID"],
        name: json["name"],
        tag: json["tag"],
        leader: json["leader"],
        coLeader: json["co-leader"],
        respect: json["respect"],
        age: json["age"],
        bestChain: json["best_chain"],
        //territoryWars: TerritoryWars.fromJson(json["territory_wars"]),
        //raidWars: RaidWars.fromJson(json["raid_wars"]),
        //peace: Peace.fromJson(json["peace"]),
        members: Map.from(json["members"]).map((k, v) => MapEntry<String, Member>(k, Member.fromJson(v))),
      );

  Map<String, dynamic> toJson() => {
        "hidden": hidden,
        //
        "ID": id,
        "name": name,
        "tag": tag,
        "leader": leader,
        "co-leader": coLeader,
        "respect": respect,
        "age": age,
        "best_chain": bestChain,
        //"territory_wars": territoryWars.toJson(),
        //"raid_wars": raidWars.toJson(),
        //"peace": peace.toJson(),
        "members": Map.from(members!).map((k, v) => MapEntry<String, dynamic>(k, v.toJson())),
      };
}

class Member {
  Member({
    this.memberId,
    this.isUpdating,
    this.factionName,
    this.factionLeader,
    this.factionColeader,
    this.lifeCurrent,
    this.lifeMaximum,
    this.lastUpdated,
    this.justUpdatedWithSuccess,
    this.justUpdatedWithError,
    this.respectGain,
    this.fairFight,
    this.userWonOrDefended,
    this.personalNote,
    this.personalNoteColor,
    this.hidden,
    this.statsEstimated,
    this.spiesSource,
    this.statsExactTotal,
    this.statsExactTotalUpdated,
    this.statsExactTotalKnown,
    this.statsExactUpdated,
    this.statsStr,
    this.statsStrUpdated,
    this.statsSpd,
    this.statsSpdUpdated,
    this.statsDef,
    this.statsDefUpdated,
    this.statsDex,
    this.statsDexUpdated,
    this.statsSort,
    this.lifeSort,
    this.overrideEasyLife,
    //
    this.statsComparisonSuccess,
    this.memberXanax,
    this.myXanax,
    this.memberRefill,
    this.myRefill,
    this.memberEnhancement,
    this.myEnhancement,
    this.memberEcstasy,
    this.memberLsd,
    this.memberCans,
    this.myCans,
    //
    this.name,
    this.level,
    this.daysInFaction,
    this.lastAction,
    this.status,
    this.position,
  });

  // State for wars
  int? memberId = 0;
  bool? isUpdating = false;
  String? factionName = "";
  int? factionLeader = 0;
  int? factionColeader = 0;
  int? lifeCurrent = -1;
  int? lifeMaximum = -1;
  DateTime? lastUpdated;
  bool? justUpdatedWithSuccess = false;
  bool? justUpdatedWithError = false;
  double? respectGain = -1;
  double? fairFight = -1;
  bool? userWonOrDefended = false;
  String? personalNote = "";
  String? personalNoteColor = "";
  bool? hidden = false;
  String? statsEstimated = "";
  String? spiesSource = "yata";
  int? statsExactTotal = -1;
  int? statsExactTotalUpdated;
  int? statsExactTotalKnown = -1;
  int? statsExactUpdated;
  int? statsStr = -1;
  int? statsStrUpdated;
  int? statsSpd = -1;
  int? statsSpdUpdated;
  int? statsDef = -1;
  int? statsDefUpdated;
  int? statsDex = -1;
  int? statsDexUpdated;
  int? statsSort = 0; // Mixed estimates and exacts so that members can be sorted
  int? lifeSort = 0;
  bool? overrideEasyLife = false;
  // For stats estimates calculation
  bool? statsComparisonSuccess = false;
  int? memberXanax = 0;
  int? myXanax = 0;
  int? memberRefill = 0;
  int? myRefill = 0;
  int? memberEnhancement = 0;
  int? myEnhancement = 0;
  int? memberEcstasy = 0;
  int? memberLsd = 0;
  int? memberCans = 0;
  int? myCans = 0;

  String? name;
  int? level;
  int? daysInFaction;
  LastAction? lastAction;
  Status? status;
  String? position;

  factory Member.fromJson(Map<String, dynamic> json) => Member(
        memberId: json["memberId"] ?? 0,
        isUpdating: json["isUpdating"] ?? false,
        factionName: json["factionName"] ?? "",
        factionLeader: json["factionLeader"] ?? 0,
        factionColeader: json["factionColeader"] ?? 0,
        lifeCurrent: json["lifeCurrent"] ?? -1,
        lifeMaximum: json["lifeMaximum"] ?? -1,
        lastUpdated:
            json["lastUpdated"] == null ? DateTime.now() : DateTime.fromMillisecondsSinceEpoch(json["lastUpdated"]),
        justUpdatedWithSuccess: json["justUpdatedWithSuccess"] ?? false,
        justUpdatedWithError: json["justUpdatedWithSuccess"] ?? false,
        respectGain: json["respectGain"] ?? -1,
        fairFight: json["fairFight"] ?? -1,
        userWonOrDefended: json["userWonOrDefended"] ?? false,
        personalNote: json["personalNotes"] ?? "",
        personalNoteColor: json["personalNoteColor"] ?? "",
        hidden: json["hidden"] ?? false,
        statsEstimated: json["statsEstimated"] ?? "",
        spiesSource: json["spiesSource"] ?? "yata",
        statsExactTotal: json["statsExactTotal"] ?? -1,
        statsExactTotalUpdated: json["statsExactTotalUpdated"],
        statsExactTotalKnown: json["statsExactTotalKnown"] ?? -1,
        statsExactUpdated: json["statsExactUpdated"] ?? 0,
        statsStr: json["statsStr"] ?? -1,
        statsStrUpdated: json["statsStrUpdated"],
        statsSpd: json["statsSpd"] ?? -1,
        statsSpdUpdated: json["statsSpdUpdated"],
        statsDef: json["statsDef"] ?? -1,
        statsDefUpdated: json["statsDefUpdated"],
        statsDex: json["statsDex"] ?? -1,
        statsDexUpdated: json["statsDexUpdated"],
        statsSort: json["statsSort"] ?? 0,
        lifeSort: json["lifeSort"] ?? json["lifeCurrent"] ?? 0,
        overrideEasyLife: json["overrideEasyLife"] ?? false,
        statsComparisonSuccess: json["statsComparisonSuccess"] ?? false,
        memberXanax: json["memberXanax"] ?? 0,
        myXanax: json["myXanax"] ?? 0,
        memberRefill: json["memberRefill"] ?? 0,
        myRefill: json["myRefill"] ?? 0,
        memberEnhancement: json["memberEnhancement"] ?? 0,
        myEnhancement: json["myEnhancement"] ?? 0,
        memberEcstasy: json["memberEcstasy"] ?? 0,
        memberLsd: json["memberLsd"] ?? 0,
        memberCans: json["memberCans"] ?? 0,
        myCans: json["myCans"] ?? 0,
        //
        name: json["name"],
        level: json["level"],
        daysInFaction: json["days_in_faction"],
        lastAction: LastAction.fromJson(json["last_action"]),
        status: Status.fromJson(json["status"]),
        position: json["position"],
      );

  Map<String, dynamic> toJson() => {
        "memberId": memberId,
        "isUpdating": isUpdating,
        "factionName": factionName,
        "factionLeader": factionLeader,
        "factionColeader": factionColeader,
        "lifeCurrent": lifeCurrent,
        "lifeMaximum": lifeMaximum,
        "lastUpdated": lastUpdated!.millisecondsSinceEpoch,
        "respectGain": respectGain,
        "fairFight": fairFight,
        "userWonOrDefended": userWonOrDefended,
        "personalNotes": personalNote,
        "personalNoteColor": personalNoteColor,
        "hidden": hidden,
        "statsEstimated": statsEstimated,
        "spiesSource": spiesSource,
        "statsExactTotal": statsExactTotal,
        "statsExactTotalUpdated": statsExactTotalUpdated,
        "statsExactTotalKnown": statsExactTotalKnown,
        "statsExactUpdated": statsExactUpdated,
        "statsStr": statsStr,
        "statsStrUpdated": statsStrUpdated,
        "statsSpd": statsSpd,
        "statsSpdUpdated": statsSpdUpdated,
        "statsDef": statsDef,
        "statsDefUpdated": statsDefUpdated,
        "statsDex": statsDex,
        "statsDexUpdated": statsDexUpdated,
        "statsSort": statsSort,
        "lifeSort": lifeSort,
        "overrideEasyLife": overrideEasyLife,
        "statsComparisonSuccess": statsComparisonSuccess,
        "memberXanax": memberXanax,
        "myXanax": myXanax,
        "memberRefill": memberRefill,
        "myRefill": myRefill,
        "memberEnhancement": memberEnhancement,
        "myEnhancement": myEnhancement,
        "memberEcstasy": memberEcstasy,
        "memberLsd": memberLsd,
        "memberCans": memberCans,
        "myCans": myCans,
        //
        "name": name,
        "level": level,
        "days_in_faction": daysInFaction,
        "last_action": lastAction!.toJson(),
        "status": status!.toJson(),
        "position": position,
      };
}

class LastAction {
  LastAction({
    this.status,
    this.timestamp,
    this.relative,
  });

  String? status;
  int? timestamp;
  String? relative;

  factory LastAction.fromJson(Map<String, dynamic> json) => LastAction(
        status: json["status"],
        timestamp: json["timestamp"],
        relative: json["relative"],
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "timestamp": timestamp,
        "relative": relative,
      };
}

/*
class TerritoryWars {
  TerritoryWars();

  factory TerritoryWars.fromJson(Map<String, dynamic> json) => TerritoryWars(
  );

  Map<String, dynamic> toJson() => {
  };
}

class RaidWars {
  RaidWars();

  factory RaidWars.fromJson(Map<String, dynamic> json) => RaidWars(
  );

  Map<String, dynamic> toJson() => {
  };
}

class Peace {
  Peace();

  factory Peace.fromJson(Map<String, dynamic> json) => Peace(
  );

  Map<String, dynamic> toJson() => {
  };
}
*/
