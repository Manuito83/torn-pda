// To parse this JSON data, do
//
//     final factionModel = factionModelFromJson(jsonString);

// Dart imports:
import 'dart:convert';

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
  bool hidden = false;

  int id;
  String name;
  String tag;
  int leader;
  int coLeader;
  int respect;
  int age;
  int bestChain;
  // If we want to use these in the future, make sure to find good example to build the classes, otherwise
  // we'll get API errors if they are empty
  //TerritoryWars territoryWars;
  //RaidWars raidWars;
  //Peace peace;
  Map<String, Member> members;

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
        "members": Map.from(members).map((k, v) => MapEntry<String, dynamic>(k, v.toJson())),
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
    this.statsExactTotal,
    this.statsExactTotalKnown,
    this.statsExactUpdated,
    this.statsStr,
    this.statsSpd,
    this.statsDef,
    this.statsDex,
    this.statsSort,
    this.lifeSort,
    //
    this.name,
    this.level,
    this.daysInFaction,
    this.lastAction,
    this.status,
    this.position,
  });

  // State for wars
  int memberId = 0;
  bool isUpdating = false;
  String factionName = "";
  int factionLeader = 0;
  int factionColeader = 0;
  int lifeCurrent = -1;
  int lifeMaximum = -1;
  DateTime lastUpdated;
  bool justUpdatedWithSuccess = false;
  bool justUpdatedWithError = false;
  double respectGain = -1;
  double fairFight = -1;
  bool userWonOrDefended = false;
  String personalNote = "";
  String personalNoteColor = "";
  bool hidden = false;
  String statsEstimated = "";
  int statsExactTotal = -1;
  int statsExactTotalKnown = -1;
  int statsExactUpdated = 0;
  int statsStr = -1;
  int statsSpd = -1;
  int statsDef = -1;
  int statsDex = -1;
  int statsSort = 0; // Mixed estimates and exacts so that members can be sorted
  int lifeSort = 0;

  String name;
  int level;
  int daysInFaction;
  LastAction lastAction;
  Status status;
  String position;

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
        justUpdatedWithSuccess: json["justUpdatedWithSuccess"] == null ? false : json["justUpdatedWithSuccess"],
        justUpdatedWithError: json["justUpdatedWithSuccess"] == null ? false : json["justUpdatedWithSuccess"],
        respectGain: json["respectGain"] == null ? -1 : json["respectGain"],
        fairFight: json["fairFight"] == null ? -1 : json["fairFight"],
        userWonOrDefended: json["userWonOrDefended"] == null ? false : json["userWonOrDefended"],
        personalNote: json["personalNotes"] ?? "",
        personalNoteColor: json["personalNoteColor"] ?? "",
        hidden: json["hidden"] ?? false,
        statsEstimated: json["statsEstimated"] ?? "",
        statsExactTotal: json["statsExactTotal"] ?? -1,
        statsExactTotalKnown: json["statsExactTotalKnown"] ?? -1,
        statsExactUpdated: json["statsExactUpdated"] ?? 0,
        statsStr: json["statsStr"] ?? -1,
        statsSpd: json["statsSpd"] ?? -1,
        statsDef: json["statsDef"] ?? -1,
        statsDex: json["statsDex"] ?? -1,
        statsSort: json["statsSort"] ?? 0,
        lifeSort: json["lifeSort"] == null ? json["lifeCurrent"] ?? 0 : json["lifeSort"],
        //
        name: json["name"],
        level: json["level"] == null ? null : json["level"],
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
        "lastUpdated": lastUpdated.millisecondsSinceEpoch,
        "respectGain": respectGain,
        "fairFight": fairFight,
        "userWonOrDefended": userWonOrDefended,
        "personalNotes": personalNote,
        "personalNoteColor": personalNoteColor,
        "hidden": hidden,
        "statsEstimated": statsEstimated,
        "statsExactTotal": statsExactTotal,
        "statsExactTotalKnown": statsExactTotalKnown,
        "statsExactUpdated": statsExactUpdated,
        "statsStr": statsStr,
        "statsSpd": statsSpd,
        "statsDef": statsDef,
        "statsDex": statsDex,
        "statsSort": statsSort,
        "lifeSort": lifeSort,
        //
        "name": name,
        "level": level == null ? null : level,
        "days_in_faction": daysInFaction,
        "last_action": lastAction.toJson(),
        "status": status.toJson(),
        "position": position,
      };
}

class LastAction {
  LastAction({
    this.status,
    this.timestamp,
    this.relative,
  });

  String status;
  int timestamp;
  String relative;

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

class Status {
  Status({
    this.description,
    this.details,
    this.state,
    this.color,
    this.until,
  });

  String description;
  String details;
  String state;
  String color;
  int until;

  factory Status.fromJson(Map<String, dynamic> json) => Status(
        description: json["description"],
        details: json["details"],
        state: json["state"],
        color: json["color"],
        until: json["until"],
      );

  Map<String, dynamic> toJson() => {
        "description": description,
        "details": details,
        "state": state,
        "color": color,
        "until": until,
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
