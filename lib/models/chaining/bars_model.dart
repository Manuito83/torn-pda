// To parse this JSON data, do
//
//     final barsAndStatusModel = barsAndStatusModelFromJson(jsonString);

import 'dart:convert';

BarsStatusCooldownsModel barsAndStatusModelFromJson(String str) => BarsStatusCooldownsModel.fromJson(json.decode(str));

String barsAndStatusModelToJson(BarsStatusCooldownsModel data) => json.encode(data.toJson());

class BarsStatusCooldownsModel {
  int? serverTime;
  String? rank;
  int? level;
  int? honor;
  String? gender;
  String? property;
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
  int? revivable;
  String? profileImage;
  PersonalBars? happy;
  PersonalBars? life;
  PersonalBars? energy;
  PersonalBars? nerve;
  Chain? chain;
  Status? status;
  Job? job;
  Faction? faction;
  Married? married;
  dynamic basicicons;
  States? states;
  LastAction? lastAction;
  Competition? competition;
  Travel? travel;
  Cooldowns? cooldowns;

  BarsStatusCooldownsModel({
    this.serverTime,
    this.rank,
    this.level,
    this.honor,
    this.gender,
    this.property,
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
    this.revivable,
    this.profileImage,
    this.happy,
    this.life,
    this.energy,
    this.nerve,
    this.chain,
    this.status,
    this.job,
    this.faction,
    this.married,
    this.basicicons,
    this.states,
    this.lastAction,
    this.competition,
    this.travel,
    this.cooldowns,
  });

  factory BarsStatusCooldownsModel.fromJson(Map<String, dynamic> json) => BarsStatusCooldownsModel(
        serverTime: json["server_time"],
        rank: json["rank"],
        level: json["level"],
        honor: json["honor"],
        gender: json["gender"],
        property: json["property"],
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
        revivable: json["revivable"],
        profileImage: json["profile_image"],
        happy: json["happy"] == null ? null : PersonalBars.fromJson(json["happy"]),
        life: json["life"] == null ? null : PersonalBars.fromJson(json["life"]),
        energy: json["energy"] == null ? null : PersonalBars.fromJson(json["energy"]),
        nerve: json["nerve"] == null ? null : PersonalBars.fromJson(json["nerve"]),
        chain: json["chain"] == null ? null : Chain.fromJson(json["chain"]),
        status: json["status"] == null ? null : Status.fromJson(json["status"]),
        job: json["job"] == null ? null : Job.fromJson(json["job"]),
        faction: json["faction"] == null ? null : Faction.fromJson(json["faction"]),
        married: json["married"] == null ? null : Married.fromJson(json["married"]),
        basicicons: json["icons"] is List<dynamic>
            ? json["icons"] = Basicicons()
            : json["icons"] == null
                ? null
                : Basicicons.fromJson(json["icons"]),
        states: json["states"] == null ? null : States.fromJson(json["states"]),
        lastAction: json["last_action"] == null ? null : LastAction.fromJson(json["last_action"]),
        competition: json["competition"] == null ? null : Competition.fromJson(json["competition"]),
        travel: json["travel"] == null ? null : Travel.fromJson(json["travel"]),
        cooldowns: Cooldowns.fromJson(json["cooldowns"]),
      );

  Map<String, dynamic> toJson() => {
        "server_time": serverTime,
        "rank": rank,
        "level": level,
        "honor": honor,
        "gender": gender,
        "property": property,
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
        "revivable": revivable,
        "profile_image": profileImage,
        "happy": happy?.toJson(),
        "life": life?.toJson(),
        "energy": energy?.toJson(),
        "nerve": nerve?.toJson(),
        "chain": chain?.toJson(),
        "status": status?.toJson(),
        "job": job?.toJson(),
        "faction": faction?.toJson(),
        "married": married?.toJson(),
        "basicicons": basicicons?.toJson(),
        "states": states?.toJson(),
        "last_action": lastAction?.toJson(),
        "competition": competition?.toJson(),
        "travel": travel?.toJson(),
        "cooldowns": cooldowns?.toJson(),
      };
}

class Basicicons {
  String? icon6;
  String? icon4;
  String? icon10;
  String? icon8;
  String? icon27;
  String? icon9;
  String? icon35;

  Basicicons({
    this.icon6,
    this.icon4,
    this.icon10,
    this.icon8,
    this.icon27,
    this.icon9,
    this.icon35,
  });

  factory Basicicons.fromJson(Map<String, dynamic> json) => Basicicons(
        icon6: json["icon6"],
        icon4: json["icon4"],
        icon10: json["icon10"],
        icon8: json["icon8"],
        icon27: json["icon27"],
        icon9: json["icon9"],
        icon35: json["icon35"],
      );

  Map<String, dynamic> toJson() => {
        "icon6": icon6,
        "icon4": icon4,
        "icon10": icon10,
        "icon8": icon8,
        "icon27": icon27,
        "icon9": icon9,
        "icon35": icon35,
      };
}

class Chain {
  int? current;
  int? maximum;
  int? timeout;
  double? modifier;
  int? cooldown;

  Chain({
    this.current,
    this.maximum,
    this.timeout,
    this.modifier,
    this.cooldown,
  });

  factory Chain.fromJson(Map<String, dynamic> json) => Chain(
        current: json["current"],
        maximum: json["maximum"],
        timeout: json["timeout"],
        modifier: json["modifier"]?.toDouble(),
        cooldown: json["cooldown"],
      );

  Map<String, dynamic> toJson() => {
        "current": current,
        "maximum": maximum,
        "timeout": timeout,
        "modifier": modifier,
        "cooldown": cooldown,
      };
}

class Competition {
  String? name;
  String? status;

  Competition({
    this.name,
    this.status,
  });

  factory Competition.fromJson(Map<String, dynamic> json) => Competition(
        name: json["name"],
        status: json["status"],
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "status": status,
      };
}

class PersonalBars {
  int? current;
  int? maximum;
  int? increment;
  int? interval;
  int? ticktime;
  int? fulltime;

  PersonalBars({
    this.current,
    this.maximum,
    this.increment,
    this.interval,
    this.ticktime,
    this.fulltime,
  });

  factory PersonalBars.fromJson(Map<String, dynamic> json) => PersonalBars(
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

class Faction {
  String? position;
  int? factionId;
  int? daysInFaction;
  String? factionName;
  String? factionTag;

  Faction({
    this.position,
    this.factionId,
    this.daysInFaction,
    this.factionName,
    this.factionTag,
  });

  factory Faction.fromJson(Map<String, dynamic> json) => Faction(
        position: json["position"],
        factionId: json["faction_id"],
        daysInFaction: json["days_in_faction"],
        factionName: json["faction_name"],
        factionTag: json["faction_tag"] ?? "",
      );

  Map<String, dynamic> toJson() => {
        "position": position,
        "faction_id": factionId,
        "days_in_faction": daysInFaction,
        "faction_name": factionName,
        "faction_tag": factionTag ?? "",
      };
}

class Job {
  String? job;
  String? position;
  int? companyId;
  String? companyName;
  int? companyType;

  Job({
    this.job,
    this.position,
    this.companyId,
    this.companyName,
    this.companyType,
  });

  factory Job.fromJson(Map<String, dynamic> json) => Job(
        job: json["job"],
        position: json["position"],
        companyId: json["company_id"],
        companyName: json["company_name"],
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
  String? status;
  int? timestamp;
  String? relative;

  LastAction({
    this.status,
    this.timestamp,
    this.relative,
  });

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

class Married {
  int? spouseId;
  String? spouseName;
  int? duration;

  Married({
    this.spouseId,
    this.spouseName,
    this.duration,
  });

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
  int? hospitalTimestamp;
  int? jailTimestamp;

  States({
    this.hospitalTimestamp,
    this.jailTimestamp,
  });

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
  String? description;
  String? details;
  String? state;
  String? color;
  int? until;

  Status({
    this.description,
    this.details,
    this.state,
    this.color,
    this.until,
  });

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

class Travel {
  Travel({
    this.destination,
    this.timestamp,
    this.departed,
    this.timeLeft,
  });

  String? destination;
  int? timestamp;
  int? departed;
  int? timeLeft;

  factory Travel.fromJson(Map<String, dynamic> json) => Travel(
        destination: json["destination"],
        timestamp: json["timestamp"],
        departed: json["departed"],
        timeLeft: json["time_left"],
      );

  Map<String, dynamic> toJson() => {
        "destination": destination,
        "timestamp": timestamp,
        "departed": departed,
        "time_left": timeLeft,
      };
}

class Cooldowns {
  Cooldowns({
    this.drug,
    this.medical,
    this.booster,
  });

  int? drug;
  int? medical;
  int? booster;

  factory Cooldowns.fromJson(Map<String, dynamic> json) => Cooldowns(
        drug: json["drug"],
        medical: json["medical"],
        booster: json["booster"],
      );

  Map<String, dynamic> toJson() => {
        "drug": drug,
        "medical": medical,
        "booster": booster,
      };
}
