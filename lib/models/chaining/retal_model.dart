import 'package:torn_pda/models/profile/own_profile_basic.dart';

class Retal {
  Retal({
    //State for retals
    this.retalExpiry = 0,
    this.retalId = 0,
    this.isUpdating = false,
    this.factionName = "",
    this.factionLeader = 0,
    this.factionColeader = 0,
    this.lifeCurrent = -1,
    this.lifeMaximum = -1,
    this.lastUpdated,
    this.justUpdatedWithSuccess = false,
    this.justUpdatedWithError = false,
    this.respectGain = -1,
    this.fairFight = -1,
    this.userWonOrDefended = false,
    this.personalNote = "",
    this.personalNoteColor = "",
    this.statsEstimated = "",
    this.spiesSource = "yata",
    this.statsExactTotal = -1,
    this.statsExactTotalUpdated,
    this.statsExactTotalKnown = -1,
    this.statsExactUpdated = 0,
    this.statsStr = -1,
    this.statsStrUpdated,
    this.statsSpd = -1,
    this.statsSpdUpdated,
    this.statsDef = -1,
    this.statsDefUpdated,
    this.statsDex = -1,
    this.statsDexUpdated,
    this.statsSort = 0, // Mixed estimates and exacts so that retals can be sorted
    this.lifeSort = 0,
    this.overrideEasyLife = false,
    // For stats estimates calculation
    this.statsComparisonSuccess = false,
    this.retalXanax = 0,
    this.myXanax = 0,
    this.retalRefill = 0,
    this.myRefill = 0,
    this.retalEnhancement = 0,
    this.myEnhancement = 0,
    this.retalEcstasy = 0,
    this.retalLsd = 0,
    this.retalCans = 0,
    this.myCans = 0,
    this.name,
    this.level,
    this.daysInFaction,
    required this.lastAction,
    required this.status,
    this.position,
  });

  // State for retals
  int retalExpiry;
  int? retalId;
  bool isUpdating;
  String? factionName;
  int factionLeader;
  int factionColeader;
  int? lifeCurrent;
  int? lifeMaximum;
  DateTime? lastUpdated;
  bool? justUpdatedWithSuccess;
  bool? justUpdatedWithError;
  double? respectGain;
  double? fairFight;
  bool? userWonOrDefended;
  String personalNote;
  String personalNoteColor;
  String statsEstimated;
  String spiesSource;
  int? statsExactTotal;
  int? statsExactTotalUpdated;
  int statsExactTotalKnown;
  int? statsExactUpdated;
  int? statsStr;
  int? statsStrUpdated;
  int? statsSpd;
  int? statsSpdUpdated;
  int? statsDef;
  int? statsDefUpdated;
  int? statsDex;
  int? statsDexUpdated;
  int? statsSort; // Mixed estimates and exacts so that retals can be sorted
  int? lifeSort;
  bool overrideEasyLife;
  // For stats estimates calculation
  bool statsComparisonSuccess;
  int? retalXanax;
  int? myXanax;
  int? retalRefill;
  int? myRefill;
  int? retalEnhancement;
  int? myEnhancement;
  int? retalEcstasy;
  int? retalLsd;
  int? retalCans;
  int? myCans;

  String? name;
  int? level;
  int? daysInFaction;
  LastAction lastAction = LastAction();
  Status status = Status();
  String? position;

  factory Retal.fromJson(Map<String, dynamic> json) => Retal(
        retalExpiry: json["retalExpiry"] ?? 0,
        retalId: json["retalId"] ?? 0,
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
        retalXanax: json["retalXanax"] ?? 0,
        myXanax: json["myXanax"] ?? 0,
        retalRefill: json["retalRefill"] ?? 0,
        myRefill: json["myRefill"] ?? 0,
        retalEnhancement: json["retalEnhancement"] ?? 0,
        myEnhancement: json["myEnhancement"] ?? 0,
        retalEcstasy: json["retalEcstasy"] ?? 0,
        retalLsd: json["retalLsd"] ?? 0,
        retalCans: json["retalCans"] ?? 0,
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
        "retalExpiry": retalExpiry,
        "retalId": retalId,
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
        "statsEstimated": statsEstimated,
        "spiesSource": spiesSource,
        "statsExactTotal": statsExactTotal,
        "statsExactTotalUpdated": statsExactTotalUpdated,
        "statsExactTotalKnown": statsExactTotalKnown,
        "statsExactUpdated": statsExactUpdated,
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
        "retalXanax": retalXanax,
        "myXanax": myXanax,
        "retalRefill": retalRefill,
        "myRefill": myRefill,
        "retalEnhancement": retalEnhancement,
        "myEnhancement": myEnhancement,
        "retalEcstasy": retalEcstasy,
        "retalLsd": retalLsd,
        "retalCans": retalCans,
        "myCans": myCans,
        //
        "name": name,
        "level": level,
        "days_in_faction": daysInFaction,
        "last_action": lastAction.toJson(),
        "status": status.toJson(),
        "position": position,
      };
}
