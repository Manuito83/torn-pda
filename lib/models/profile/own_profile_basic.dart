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

  factory OwnProfileBasic.fromJson(Map<String, dynamic> json) {
    try {
      return OwnProfileBasic(
        userApiKey: json["userApiKey"] ?? '',
        userApiKeyValid: json["userApiKeyValid"] ?? false,
        rank: json["rank"] is String ? json["rank"] : null,
        level: json["level"] is int ? json["level"] : null,
        gender: json["gender"] is String ? json["gender"] : null,
        property: json["property"] is String ? json["property"] : null,
        signup: json["signup"] is String ? json["signup"] : null,
        awards: json["awards"] is int ? json["awards"] : null,
        friends: json["friends"] is int ? json["friends"] : null,
        enemies: json["enemies"] is int ? json["enemies"] : null,
        forumPosts: json["forum_posts"] is int ? json["forum_posts"] : null,
        karma: json["karma"] is int ? json["karma"] : null,
        age: json["age"] is int ? json["age"] : null,
        role: json["role"] is String ? json["role"] : null,
        donator: json["donator"] is int ? json["donator"] : null,
        playerId: json["player_id"] is int ? json["player_id"] : null,
        name: json["name"] is String ? json["name"] : null,
        propertyId: json["property_id"] is int ? json["property_id"] : null,
        competition: json["competition"],
        strength: json["strength"] is int ? json["strength"] : null,
        speed: json["speed"] is int ? json["speed"] : null,
        dexterity: json["dexterity"] is int ? json["dexterity"] : null,
        defense: json["defense"] is int ? json["defense"] : null,
        total: json["total"] is int ? json["total"] : null,
        strengthModifier: json["strength_modifier"] is int ? json["strength_modifier"] : null,
        defenseModifier: json["defense_modifier"] is int ? json["defense_modifier"] : null,
        speedModifier: json["speed_modifier"] is int ? json["speed_modifier"] : null,
        dexterityModifier: json["dexterity_modifier"] is int ? json["dexterity_modifier"] : null,
        status: json["status"] == null ? null : Status.fromJson(json["status"]),
        job: json["job"] == null ? null : Job.fromJson(json["job"]),
        faction: json["faction"] == null ? null : Faction.fromJson(json["faction"]),
        married: json["married"] == null ? null : Married.fromJson(json["married"]),
        basicIcons: json["basicicons"] is List<dynamic>
            ? json["basicicons"] = BasicIcons()
            : json["basicicons"] == null
                ? null
                : BasicIcons.fromJson(json["basicicons"]),
        states: json["states"] == null ? null : States.fromJson(json["states"]),
        lastAction: json["last_action"] == null ? null : LastAction.fromJson(json["last_action"]),
        strengthInfo: json["strength_info"] == null || json["strength_info"] is! List
            ? null
            : List<String>.from(json["strength_info"].where((x) => x is String)),
        defenseInfo: json["defense_info"] == null || json["defense_info"] is! List
            ? null
            : List<String>.from(json["defense_info"].where((x) => x is String)),
        speedInfo: json["speed_info"] == null || json["speed_info"] is! List
            ? null
            : List<String>.from(json["speed_info"].where((x) => x is String)),
        dexterityInfo: json["dexterity_info"] == null || json["dexterity_info"] is! List
            ? null
            : List<String>.from(json["dexterity_info"].where((x) => x is String)),
        happy: json["happy"] == null ? null : PersonalBars.fromJson(json["happy"]),
        life: json["life"] == null ? null : PersonalBars.fromJson(json["life"]),
        energy: json["energy"] == null ? null : PersonalBars.fromJson(json["energy"]),
        nerve: json["nerve"] == null ? null : PersonalBars.fromJson(json["nerve"]),
      );
    } catch (e) {
      return OwnProfileBasic();
    }
  }

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

  factory BasicIcons.fromJson(Map<String, dynamic> json) {
    try {
      return BasicIcons(
        icon6: json["icon6"] is String ? json["icon6"] : null,
        icon4: json["icon4"] is String ? json["icon4"] : null,
        icon8: json["icon8"] is String ? json["icon8"] : null,
        icon27: json["icon27"] is String ? json["icon27"] : null,
        icon81: json["icon81"] is String ? json["icon81"] : null,
      );
    } catch (e) {
      return BasicIcons();
    }
  }

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

  factory Faction.fromJson(Map<String, dynamic> json) {
    try {
      return Faction(
        position: json["position"] is String ? json["position"] : null,
        factionId: json["faction_id"] is int ? json["faction_id"] : null,
        daysInFaction: json["days_in_faction"] is int ? json["days_in_faction"] : null,
        factionName: json["faction_name"] is String ? json["faction_name"] : null,
        factionTag: json["faction_tag"]?.toString(),
      );
    } catch (e) {
      return Faction();
    }
  }

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

  factory Job.fromJson(Map<String, dynamic> json) {
    try {
      return Job(
        job: json["job"] is String ? json["job"] : null,
        position: json["position"] is String ? json["position"] : null,
        companyId: json["company_id"] is int ? json["company_id"] : null,
        companyName: json["company_name"]?.toString(),
        companyType: json["company_type"] is int ? json["company_type"] : null,
      );
    } catch (e) {
      return Job();
    }
  }

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

  factory LastAction.fromJson(Map<String, dynamic> json) {
    try {
      return LastAction(
        status: json["status"] is String ? json["status"] : null,
        timestamp: json["timestamp"] is int ? json["timestamp"] : null,
        relative: json["relative"] is String ? json["relative"] : null,
      );
    } catch (e) {
      return LastAction();
    }
  }

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

  factory Life.fromJson(Map<String, dynamic> json) {
    try {
      return Life(
        current: json["current"] is int ? json["current"] : null,
        maximum: json["maximum"] is int ? json["maximum"] : null,
        increment: json["increment"] is int ? json["increment"] : null,
        interval: json["interval"] is int ? json["interval"] : null,
        ticktime: json["ticktime"] is int ? json["ticktime"] : null,
        fulltime: json["fulltime"] is int ? json["fulltime"] : null,
      );
    } catch (e) {
      return Life();
    }
  }

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

  factory Married.fromJson(Map<String, dynamic> json) {
    try {
      return Married(
        spouseId: json["spouse_id"] is int ? json["spouse_id"] : null,
        spouseName: json["spouse_name"] is String ? json["spouse_name"] : null,
        duration: json["duration"] is int ? json["duration"] : null,
      );
    } catch (e) {
      return Married();
    }
  }

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

  factory States.fromJson(Map<String, dynamic> json) {
    try {
      return States(
        hospitalTimestamp: json["hospital_timestamp"] is int ? json["hospital_timestamp"] : null,
        jailTimestamp: json["jail_timestamp"] is int ? json["jail_timestamp"] : null,
      );
    } catch (e) {
      return States();
    }
  }

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

  factory Status.fromJson(Map<String, dynamic> json) {
    try {
      return Status(
        description: json["description"] is String ? json["description"] : null,
        details: json["details"] is String ? json["details"] : null,
        state: json["state"] is String ? json["state"] : null,
        color: json["color"] is String ? json["color"] : null,
        until: json["until"] is int ? json["until"] : null,
      );
    } catch (e) {
      return Status();
    }
  }

  Map<String, dynamic> toJson() => {
        "description": description,
        "details": details,
        "state": state,
        "color": color,
        "until": until,
      };
}
