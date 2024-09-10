// To parse this JSON data, do
//
//     final ownProfileBasic = ownProfileBasicFromJson(jsonString);

// Dart imports:
import 'dart:convert';

import 'package:torn_pda/models/chaining/bars_model.dart';

OwnProfileBasic ownProfileBasicFromJson(String str) => OwnProfileBasic.fromJson(json.decode(str));

String ownProfileBasicToJson(OwnProfileBasic data) => json.encode(data.toJson());

class OwnProfileBasic {
  OwnProfileBasic({
    // For state management
    this.userApiKey = '',
    this.userApiKeyValid = false,
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
    this.strength,
    this.speed,
    this.dexterity,
    this.defense,
    this.total,
    this.strengthModifier,
    this.defenseModifier,
    this.speedModifier,
    this.dexterityModifier,
    this.status,
    this.job,
    this.faction,
    this.married,
    this.basicIcons,
    this.states,
    this.lastAction,
    this.strengthInfo,
    this.defenseInfo,
    this.speedInfo,
    this.dexterityInfo,
    this.happy,
    this.life,
    this.energy,
    this.nerve,
  });

  // For state management
  String? userApiKey;
  bool? userApiKeyValid;

  String? rank;
  int? level;
  String? gender;
  String? property;
  String? signup;
  int? awards;
  int? friends;
  int? enemies;
  int? forumPosts;
  int? karma;
  int? age;
  String? role;
  int? donator;
  int? playerId;
  String? name;
  int? propertyId;
  dynamic competition;
  int? strength;
  int? speed;
  int? dexterity;
  int? defense;
  int? total;
  int? strengthModifier;
  int? defenseModifier;
  int? speedModifier;
  int? dexterityModifier;
  Status? status;
  Job? job;
  Faction? faction;
  Married? married;
  dynamic basicIcons;
  States? states;
  LastAction? lastAction;
  List<String>? strengthInfo;
  List<String>? defenseInfo;
  List<String>? speedInfo;
  List<String>? dexterityInfo;
  PersonalBars? happy;
  PersonalBars? life;
  PersonalBars? energy;
  PersonalBars? nerve;

  factory OwnProfileBasic.fromJson(Map<String, dynamic> json) => OwnProfileBasic(
        userApiKey: json["userApiKey"] ?? '',
        userApiKeyValid: json["userApiKeyValid"] ?? false,

        rank: json["rank"],
        level: json["level"],
        gender: json["gender"],
        property: json["property"],
        signup: json["signup"],
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
        strength: json["strength"],
        speed: json["speed"],
        dexterity: json["dexterity"],
        defense: json["defense"],
        total: json["total"],
        strengthModifier: json["strength_modifier"],
        defenseModifier: json["defense_modifier"],
        speedModifier: json["speed_modifier"],
        dexterityModifier: json["dexterity_modifier"],
        status: json["status"] == null ? null : Status.fromJson(json["status"]),
        job: json["job"] == null ? null : Job.fromJson(json["job"]),
        faction: json["faction"] == null ? null : Faction.fromJson(json["faction"]),
        married: json["married"] == null ? null : Married.fromJson(json["married"]),
        // If it's List<dynamic>, it's empty [], so we initialise values to null (there is a null check
        // afterwards in Profile). Otherwise, it's a map that can be generated from the class.
        // For some reason this is the only place where this happens if user is idle for some days
        basicIcons: json["basicicons"] is List<dynamic>
            ? json["basicicons"] = BasicIcons()
            : json["basicicons"] == null
                ? null
                : BasicIcons.fromJson(json["basicicons"]),
        states: json["states"] == null ? null : States.fromJson(json["states"]),
        lastAction: json["last_action"] == null ? null : LastAction.fromJson(json["last_action"]),
        strengthInfo: json["strength_info"] == null ? null : List<String>.from(json["strength_info"].map((x) => x)),
        defenseInfo: json["defense_info"] == null ? null : List<String>.from(json["defense_info"].map((x) => x)),
        speedInfo: json["speed_info"] == null ? null : List<String>.from(json["speed_info"].map((x) => x)),
        dexterityInfo: json["dexterity_info"] == null ? null : List<String>.from(json["dexterity_info"].map((x) => x)),
        happy: json["happy"] == null ? null : PersonalBars.fromJson(json["happy"]),
        life: json["life"] == null ? null : PersonalBars.fromJson(json["life"]),
        energy: json["energy"] == null ? null : PersonalBars.fromJson(json["energy"]),
        nerve: json["nerve"] == null ? null : PersonalBars.fromJson(json["nerve"]),
      );

  Map<String, dynamic> toJson() => {
        "userApiKey": userApiKey,
        "userApiKeyValid": userApiKeyValid,
        "rank": rank,
        "level": level,
        "gender": gender,
        "property": property,
        "signup": signup,
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
        "strength": strength,
        "speed": speed,
        "dexterity": dexterity,
        "defense": defense,
        "total": total,
        "strength_modifier": strengthModifier,
        "defense_modifier": defenseModifier,
        "speed_modifier": speedModifier,
        "dexterity_modifier": dexterityModifier,
        "status": status?.toJson(),
        "job": job?.toJson(),
        "faction": faction?.toJson(),
        "married": married?.toJson(),
        "basicicons": basicIcons?.toJson(),
        "states": states?.toJson(),
        "last_action": lastAction?.toJson(),
        "strength_info": strengthInfo == null ? null : List<dynamic>.from(strengthInfo!.map((x) => x)),
        "defense_info": defenseInfo == null ? null : List<dynamic>.from(defenseInfo!.map((x) => x)),
        "speed_info": speedInfo == null ? null : List<dynamic>.from(speedInfo!.map((x) => x)),
        "dexterity_info": dexterityInfo == null ? null : List<dynamic>.from(dexterityInfo!.map((x) => x)),
        "happy": happy?.toJson(),
        "life": life?.toJson(),
        "energy": energy?.toJson(),
        "nerve": nerve?.toJson(),
      };
}

class BasicIcons {
  BasicIcons({
    this.icon6,
    this.icon4,
    this.icon8,
    this.icon27,
    this.icon81,
  });

  String? icon6;
  String? icon4;
  String? icon8;
  String? icon27;
  String? icon81;

  factory BasicIcons.fromJson(Map<String, dynamic> json) => BasicIcons(
        icon6: json["icon6"],
        icon4: json["icon4"],
        icon8: json["icon8"],
        icon27: json["icon27"],
        icon81: json["icon81"],
      );

  Map<String, dynamic> toJson() => {
        "icon6": icon6,
        "icon4": icon4,
        "icon8": icon8,
        "icon27": icon27,
        "icon81": icon81,
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

  String? position;
  int? factionId;
  int? daysInFaction;
  String? factionName;
  String? factionTag;

  factory Faction.fromJson(Map<String, dynamic> json) => Faction(
        position: json["position"],
        factionId: json["faction_id"],
        daysInFaction: json["days_in_faction"],
        factionName: json["faction_name"],
        // API sometimes converts to INT if tag is numbers
        factionTag: json["faction_tag"]?.toString(),
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
    this.job,
    this.position,
    this.companyId,
    this.companyName,
    this.companyType,
  });

  String? job;
  String? position;
  int? companyId;
  String? companyName;
  int? companyType;

  factory Job.fromJson(Map<String, dynamic> json) => Job(
        job: json["job"],
        position: json["position"],
        companyId: json["company_id"],
        companyName: json["company_name"]?.toString(),
        companyType: json["company_type"],
      );

  Map<String, dynamic> toJson() => {
        "job": job,
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

class Life {
  Life({
    this.current,
    this.maximum,
    this.increment,
    this.interval,
    this.ticktime,
    this.fulltime,
  });

  int? current;
  int? maximum;
  int? increment;
  int? interval;
  int? ticktime;
  int? fulltime;

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

  int? spouseId;
  String? spouseName;
  int? duration;

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

  int? hospitalTimestamp;
  int? jailTimestamp;

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

  String? description;
  String? details;
  String? state;
  String? color;
  int? until;

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
