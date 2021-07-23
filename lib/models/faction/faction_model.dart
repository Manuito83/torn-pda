// To parse this JSON data, do
//
//     final factionModel = factionModelFromJson(jsonString);

// Dart imports:
import 'dart:convert';

FactionModel factionModelFromJson(String str) => FactionModel.fromJson(json.decode(str));

String factionModelToJson(FactionModel data) => json.encode(data.toJson());

class FactionModel {
  FactionModel({
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
    this.name,
    this.daysInFaction,
    this.lastAction,
    this.status,
    this.position,
  });

  String name;
  int daysInFaction;
  LastAction lastAction;
  Status status;
  String position;

  factory Member.fromJson(Map<String, dynamic> json) => Member(
    name: json["name"],
    daysInFaction: json["days_in_faction"],
    lastAction: LastAction.fromJson(json["last_action"]),
    status: Status.fromJson(json["status"]),
    position: json["position"],
  );

  Map<String, dynamic> toJson() => {
    "name": name,
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
