// To parse this JSON data, do
//
//     final barsAndStatusModel = barsAndStatusModelFromJson(jsonString);

import 'dart:convert';

BarsAndStatusModel barsAndStatusModelFromJson(String str) => BarsAndStatusModel.fromJson(json.decode(str));

String barsAndStatusModelToJson(BarsAndStatusModel data) => json.encode(data.toJson());

class BarsAndStatusModel {
  int serverTime;
  String rank;
  int level;
  int honor;
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
  int revivable;
  String profileImage;
  PersonalBars happy;
  PersonalBars life;
  PersonalBars energy;
  PersonalBars nerve;
  Chain chain;
  Status status;
  Job job;
  Faction faction;
  Married married;
  Basicicons basicicons;
  States states;
  LastAction lastAction;
  Competition competition;
  Travel travel;

  BarsAndStatusModel({
    required this.serverTime,
    required this.rank,
    required this.level,
    required this.honor,
    required this.gender,
    required this.property,
    required this.signup,
    required this.awards,
    required this.friends,
    required this.enemies,
    required this.forumPosts,
    required this.karma,
    required this.age,
    required this.role,
    required this.donator,
    required this.playerId,
    required this.name,
    required this.propertyId,
    required this.revivable,
    required this.profileImage,
    required this.happy,
    required this.life,
    required this.energy,
    required this.nerve,
    required this.chain,
    required this.status,
    required this.job,
    required this.faction,
    required this.married,
    required this.basicicons,
    required this.states,
    required this.lastAction,
    required this.competition,
    required this.travel,
  });

  factory BarsAndStatusModel.fromJson(Map<String, dynamic> json) => BarsAndStatusModel(
        serverTime: json["server_time"],
        rank: json["rank"],
        level: json["level"],
        honor: json["honor"],
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
        revivable: json["revivable"],
        profileImage: json["profile_image"],
        happy: PersonalBars.fromJson(json["happy"]),
        life: PersonalBars.fromJson(json["life"]),
        energy: PersonalBars.fromJson(json["energy"]),
        nerve: PersonalBars.fromJson(json["nerve"]),
        chain: Chain.fromJson(json["chain"]),
        status: Status.fromJson(json["status"]),
        job: Job.fromJson(json["job"]),
        faction: Faction.fromJson(json["faction"]),
        married: Married.fromJson(json["married"]),
        basicicons: Basicicons.fromJson(json["basicicons"]),
        states: States.fromJson(json["states"]),
        lastAction: LastAction.fromJson(json["last_action"]),
        competition: Competition.fromJson(json["competition"]),
        travel: Travel.fromJson(json["travel"]),
      );

  Map<String, dynamic> toJson() => {
        "server_time": serverTime,
        "rank": rank,
        "level": level,
        "honor": honor,
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
        "revivable": revivable,
        "profile_image": profileImage,
        "happy": happy.toJson(),
        "life": life.toJson(),
        "energy": energy.toJson(),
        "nerve": nerve.toJson(),
        "chain": chain.toJson(),
        "status": status.toJson(),
        "job": job.toJson(),
        "faction": faction.toJson(),
        "married": married.toJson(),
        "basicicons": basicicons.toJson(),
        "states": states.toJson(),
        "last_action": lastAction.toJson(),
        "competition": competition.toJson(),
        "travel": travel.toJson(),
      };
}

class Basicicons {
  String icon6;
  String icon4;
  String icon10;
  String icon8;
  String icon27;
  String icon9;
  String icon35;

  Basicicons({
    required this.icon6,
    required this.icon4,
    required this.icon10,
    required this.icon8,
    required this.icon27,
    required this.icon9,
    required this.icon35,
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
  int current;
  int maximum;
  int timeout;
  int modifier;
  int cooldown;

  Chain({
    required this.current,
    required this.maximum,
    required this.timeout,
    required this.modifier,
    required this.cooldown,
  });

  factory Chain.fromJson(Map<String, dynamic> json) => Chain(
        current: json["current"],
        maximum: json["maximum"],
        timeout: json["timeout"],
        modifier: json["modifier"],
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
  String name;
  String status;

  Competition({
    required this.name,
    required this.status,
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
  int current;
  int maximum;
  int increment;
  int interval;
  int ticktime;
  int fulltime;

  PersonalBars({
    required this.current,
    required this.maximum,
    required this.increment,
    required this.interval,
    required this.ticktime,
    required this.fulltime,
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
  String position;
  int factionId;
  int daysInFaction;
  String factionName;
  String factionTag;

  Faction({
    required this.position,
    required this.factionId,
    required this.daysInFaction,
    required this.factionName,
    required this.factionTag,
  });

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
  String job;
  String position;
  int companyId;
  String companyName;
  int companyType;

  Job({
    required this.job,
    required this.position,
    required this.companyId,
    required this.companyName,
    required this.companyType,
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
  String status;
  int timestamp;
  String relative;

  LastAction({
    required this.status,
    required this.timestamp,
    required this.relative,
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
  int spouseId;
  String spouseName;
  int duration;

  Married({
    required this.spouseId,
    required this.spouseName,
    required this.duration,
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
  int hospitalTimestamp;
  int jailTimestamp;

  States({
    required this.hospitalTimestamp,
    required this.jailTimestamp,
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
  String description;
  String details;
  String state;
  String color;
  int until;

  Status({
    required this.description,
    required this.details,
    required this.state,
    required this.color,
    required this.until,
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
