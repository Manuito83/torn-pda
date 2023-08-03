import 'package:torn_pda/models/profile/own_profile_basic.dart';

class Retal {
  Retal({
    //State for retals
    int this.retalExpiry = 0,
    int this.retalId = 0,
    bool this.isUpdating = false,
    String this.factionName = "",
    int this.factionLeader = 0,
    int this.factionColeader = 0,
    int this.lifeCurrent = -1,
    int this.lifeMaximum = -1,
    DateTime? this.lastUpdated,
    bool? this.justUpdatedWithSuccess = false,
    bool? this.justUpdatedWithError = false,
    double? this.respectGain = -1,
    double? this.fairFight = -1,
    bool? this.userWonOrDefended = false,
    String this.personalNote = "",
    String this.personalNoteColor = "",
    String this.statsEstimated = "",
    String this.spiesSource = "yata",
    int this.statsExactTotal = -1,
    int this.statsExactTotalKnown = -1,
    int this.statsExactUpdated = 0,
    int this.statsStr = -1,
    int this.statsSpd = -1,
    int this.statsDef = -1,
    int this.statsDex = -1,
    int this.statsSort = 0, // Mixed estimates and exacts so that retals can be sorted
    int? this.lifeSort = 0,
    bool this.overrideEasyLife = false,
    // For stats estimates calculation
    bool this.statsComparisonSuccess = false,
    int this.retalXanax = 0,
    int this.myXanax = 0,
    int this.retalRefill = 0,
    int this.myRefill = 0,
    int this.retalEnhancement = 0,
    int this.myEnhancement = 0,
    int this.retalEcstasy = 0,
    int this.retalLsd = 0,
    int this.retalCans = 0,
    int this.myCans = 0,
    String? this.name,
    int? this.level,
    int? this.daysInFaction,
    required this.lastAction,
    required this.status,
    String? this.position,
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
  int statsExactTotalKnown;
  int? statsExactUpdated;
  int? statsStr;
  int? statsSpd;
  int? statsDef;
  int? statsDex;
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
        justUpdatedWithSuccess: json["justUpdatedWithSuccess"] == null ? false : json["justUpdatedWithSuccess"],
        justUpdatedWithError: json["justUpdatedWithSuccess"] == null ? false : json["justUpdatedWithSuccess"],
        respectGain: json["respectGain"] == null ? -1 : json["respectGain"],
        fairFight: json["fairFight"] == null ? -1 : json["fairFight"],
        userWonOrDefended: json["userWonOrDefended"] == null ? false : json["userWonOrDefended"],
        personalNote: json["personalNotes"] ?? "",
        personalNoteColor: json["personalNoteColor"] ?? "",
        statsEstimated: json["statsEstimated"] ?? "",
        spiesSource: json["spiesSource"] ?? "yata",
        statsExactTotal: json["statsExactTotal"] ?? -1,
        statsExactTotalKnown: json["statsExactTotalKnown"] ?? -1,
        statsExactUpdated: json["statsExactUpdated"] ?? 0,
        statsStr: json["statsStr"] ?? -1,
        statsSpd: json["statsSpd"] ?? -1,
        statsDef: json["statsDef"] ?? -1,
        statsDex: json["statsDex"] ?? -1,
        statsSort: json["statsSort"] ?? 0,
        lifeSort: json["lifeSort"] == null ? json["lifeCurrent"] ?? 0 : json["lifeSort"],
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
        level: json["level"] == null ? null : json["level"],
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
        "statsExactTotalKnown": statsExactTotalKnown,
        "statsExactUpdated": statsExactUpdated,
        "statsStr": statsStr,
        "statsSpd": statsSpd,
        "statsDef": statsDef,
        "statsDex": statsDex,
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
        "level": level == null ? null : level,
        "days_in_faction": daysInFaction,
        "last_action": lastAction.toJson(),
        "status": status.toJson(),
        "position": position,
      };
}
