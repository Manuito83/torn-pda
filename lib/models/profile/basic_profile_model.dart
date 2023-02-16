// To parse this JSON data, do
//
//     final basicProfileModel = basicProfileModelFromJson(jsonString);

import 'dart:convert';

BasicProfileModel basicProfileModelFromJson(String str) => BasicProfileModel.fromJson(json.decode(str));

String basicProfileModelToJson(BasicProfileModel data) => json.encode(data.toJson());

class BasicProfileModel {
  BasicProfileModel({
    this.rank,
    this.level,
    this.gender,
    this.property,
    this.signup,
    this.awards,
    this.friends,
    this.enemies,
    this.forumPosts,
    this.karma,
    this.age,
    this.role,
    this.donator,
    this.playerId,
    this.name,
    this.propertyId,
    this.competition,
    this.revivable,
    this.life,
    this.status,
    this.job,
    this.faction,
    this.married,
    this.basicicons,
    this.states,
    this.lastAction,
  });

  String rank;
  int level;
  String gender;
  String property;
  DateTime signup;
  int awards;
  int friends;
  int enemies;
  int forumPosts;
  int karma;
  int age;
  String role;
  int donator;
  int playerId;
  String name;
  int propertyId;
  dynamic competition;
  int revivable;
  Life life;
  Status status;
  Job job;
  Faction faction;
  Married married;
  Basicicons basicicons;
  States states;
  LastAction lastAction;

  factory BasicProfileModel.fromJson(Map<String, dynamic> json) => BasicProfileModel(
        rank: json["rank"],
        level: json["level"],
        gender: json["gender"],
        property: json["property"],
        signup: DateTime.parse(json["signup"]),
        awards: json["awards"],
        friends: json["friends"],
        enemies: json["enemies"],
        forumPosts: json["forum_posts"],
        karma: json["karma"],
        age: json["age"],
        role: json["role"],
        donator: json["donator"],
        playerId: json["player_id"],
        name: json["name"],
        propertyId: json["property_id"],
        competition: json["competition"],
        revivable: json["revivable"],
        life: Life.fromJson(json["life"]),
        status: Status.fromJson(json["status"]),
        job: Job.fromJson(json["job"]),
        faction: Faction.fromJson(json["faction"]),
        married: Married.fromJson(json["married"]),
        basicicons: Basicicons.fromJson(json["basicicons"]),
        states: States.fromJson(json["states"]),
        lastAction: LastAction.fromJson(json["last_action"]),
      );

  Map<String, dynamic> toJson() => {
        "rank": rank,
        "level": level,
        "gender": gender,
        "property": property,
        "signup": signup.toIso8601String(),
        "awards": awards,
        "friends": friends,
        "enemies": enemies,
        "forum_posts": forumPosts,
        "karma": karma,
        "age": age,
        "role": role,
        "donator": donator,
        "player_id": playerId,
        "name": name,
        "property_id": propertyId,
        "competition": competition,
        "revivable": revivable,
        "life": life.toJson(),
        "status": status.toJson(),
        "job": job.toJson(),
        "faction": faction.toJson(),
        "married": married.toJson(),
        "basicicons": basicicons.toJson(),
        "states": states.toJson(),
        "last_action": lastAction.toJson(),
      };
}

class Basicicons {
  Basicicons({
    this.icon5,
    this.icon6,
    this.icon3,
    this.icon8,
    this.icon27,
    this.icon9,
    this.icon35,
  });

  String icon5;
  String icon6;
  String icon3;
  String icon8;
  String icon27;
  String icon9;
  String icon35;

  factory Basicicons.fromJson(Map<String, dynamic> json) => Basicicons(
        icon5: json["icon5"],
        icon6: json["icon6"],
        icon3: json["icon3"],
        icon8: json["icon8"],
        icon27: json["icon27"],
        icon9: json["icon9"],
        icon35: json["icon35"],
      );

  Map<String, dynamic> toJson() => {
        "icon5": icon5,
        "icon6": icon6,
        "icon3": icon3,
        "icon8": icon8,
        "icon27": icon27,
        "icon9": icon9,
        "icon35": icon35,
      };
}

class Faction {
  Faction({
    this.position,
    this.factionId,
    this.daysInFaction,
    this.factionName,
    this.factionTag,
  });

  String position;
  int factionId;
  int daysInFaction;
  String factionName;
  String factionTag;

  factory Faction.fromJson(Map<String, dynamic> json) => Faction(
        position: json["position"],
        factionId: json["faction_id"],
        daysInFaction: json["days_in_faction"],
        factionName: json["faction_name"],
        factionTag: json["faction_tag"],
      );

  Map<String, dynamic> toJson() => {
        "position": position,
        "faction_id": factionId,
        "days_in_faction": daysInFaction,
        "faction_name": factionName,
        "faction_tag": factionTag,
      };
}

class Job {
  Job({
    this.position,
    this.companyId,
    this.companyName,
    this.companyType,
  });

  String position;
  int companyId;
  String companyName;
  int companyType;

  factory Job.fromJson(Map<String, dynamic> json) => Job(
        position: json["position"],
        companyId: json["company_id"],
        companyName: json["company_name"],
        companyType: json["company_type"],
      );

  Map<String, dynamic> toJson() => {
        "position": position,
        "company_id": companyId,
        "company_name": companyName,
        "company_type": companyType,
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

class Life {
  Life({
    this.current,
    this.maximum,
    this.increment,
    this.interval,
    this.ticktime,
    this.fulltime,
  });

  int current;
  int maximum;
  int increment;
  int interval;
  int ticktime;
  int fulltime;

  factory Life.fromJson(Map<String, dynamic> json) => Life(
        current: json["current"],
        maximum: json["maximum"],
        increment: json["increment"],
        interval: json["interval"],
        ticktime: json["ticktime"],
        fulltime: json["fulltime"],
      );

  Map<String, dynamic> toJson() => {
        "current": current,
        "maximum": maximum,
        "increment": increment,
        "interval": interval,
        "ticktime": ticktime,
        "fulltime": fulltime,
      };
}

class Married {
  Married({
    this.spouseId,
    this.spouseName,
    this.duration,
  });

  int spouseId;
  String spouseName;
  int duration;

  factory Married.fromJson(Map<String, dynamic> json) => Married(
        spouseId: json["spouse_id"],
        spouseName: json["spouse_name"],
        duration: json["duration"],
      );

  Map<String, dynamic> toJson() => {
        "spouse_id": spouseId,
        "spouse_name": spouseName,
        "duration": duration,
      };
}

class States {
  States({
    this.hospitalTimestamp,
    this.jailTimestamp,
  });

  int hospitalTimestamp;
  int jailTimestamp;

  factory States.fromJson(Map<String, dynamic> json) => States(
        hospitalTimestamp: json["hospital_timestamp"],
        jailTimestamp: json["jail_timestamp"],
      );

  Map<String, dynamic> toJson() => {
        "hospital_timestamp": hospitalTimestamp,
        "jail_timestamp": jailTimestamp,
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
