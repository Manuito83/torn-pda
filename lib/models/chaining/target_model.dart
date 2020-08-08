// To parse this JSON data, do
//
//     final targetModel = targetModelFromJson(jsonString);

import 'dart:convert';

TargetModel targetModelFromJson(String str) => TargetModel.fromJson(json.decode(str));

String targetModelToJson(TargetModel data) => json.encode(data.toJson());

class TargetModel {
  // For state management
  bool isUpdating = false;
  bool justUpdatedWithError = false;
  bool justUpdatedWithSuccess = false;

  // External, exported/imported to Shared Preferences!
  double respectGain;
  bool userWonOrDefended;
  String personalNote;
  String personalNoteColor;
  DateTime lastUpdated;
  bool hasFaction;


  // Internal from API profiles
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
  Life life;
  Status status;
  Job job;
  Faction faction;
  Married married;
  States states;
  LastAction lastAction;
  Discord discord;


  TargetModel({
    // This first batch is here to export/import from SharedPreferences,
    // so we also have to initialize them below
    this.respectGain,
    this.userWonOrDefended,
    this.personalNote,
    this.personalNoteColor,
    this.lastUpdated,
    this.hasFaction,
    /////////////////

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
    this.life,
    this.status,
    this.job,
    this.faction,
    this.married,
    this.states,
    this.lastAction,
    this.discord,
  });

  factory TargetModel.fromJson(Map<String, dynamic> json) => TargetModel(
    // respectGain can't be null to allow sorting targets, so if it stays
    // at -1, it's because the target has unknown respect (new target)
    respectGain: json["respectGain"] == null ? -1 : json["respectGain"],
    userWonOrDefended: json["userWonOrDefended"] == null ? false : json["userWonOrDefended"],
    personalNote: json["personalNote"] == null ? '' : json["personalNote"],
    personalNoteColor: json["personalNoteColor"] == null ? '' : json["personalNoteColor"],
    lastUpdated: json["lastUpdated"] == null ? DateTime.now() : DateTime.parse(json["lastUpdated"]),
    hasFaction: json["hasFaction"] == null ? false : json["hasFaction"],

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
    life: Life.fromJson(json["life"]),
    status: Status.fromJson(json["status"]),
    job: Job.fromJson(json["job"]),
    faction: Faction.fromJson(json["faction"]),
    married: Married.fromJson(json["married"]),
    states: States.fromJson(json["states"]),
    lastAction: LastAction.fromJson(json["last_action"]),
    discord: json["discord"] == null ? null : Discord.fromJson(json["discord"]),
  );

  Map<String, dynamic> toJson() => {
    "respectGain": respectGain,
    "userWonOrDefended": userWonOrDefended,
    "personalNote": personalNote,
    "personalNoteColor": personalNoteColor,
    "lastUpdated": lastUpdated.toIso8601String(),
    "hasFaction": hasFaction,

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
    "life": life.toJson(),
    "status": status.toJson(),
    "job": job.toJson(),
    "faction": faction.toJson(),
    "married": married.toJson(),
    "states": states.toJson(),
    "last_action": lastAction.toJson(),
    "discord": discord == null ? null : discord.toJson(),
  };
}

class Discord {
  Discord({
    this.userId,
    this.discordId,
  });

  int userId;
  String discordId;

  factory Discord.fromJson(Map<String, dynamic> json) => Discord(
    userId: json["userID"] == null ? null : json["userID"],
    discordId: json["discordID"] == null ? null : json["discordID"],
  );

  Map<String, dynamic> toJson() => {
    "userID": userId == null ? null : userId,
    "discordID": discordId == null ? null : discordId,
  };
}

class Faction {
  String position;
  int factionId;
  int daysInFaction;
  String factionName;

  Faction({
    this.position,
    this.factionId,
    this.daysInFaction,
    this.factionName,
  });

  factory Faction.fromJson(Map<String, dynamic> json) => Faction(
    position: json["position"],
    factionId: json["faction_id"],
    daysInFaction: json["days_in_faction"],
    factionName: json["faction_name"],
  );

  Map<String, dynamic> toJson() => {
    "position": position,
    "faction_id": factionId,
    "days_in_faction": daysInFaction,
    "faction_name": factionName,
  };
}

class Job {
  String position;
  int companyId;
  String companyName;

  Job({
    this.position,
    this.companyId,
    this.companyName,
  });

  factory Job.fromJson(Map<String, dynamic> json) => Job(
    position: json["position"],
    companyId: json["company_id"],
    companyName: json["company_name"],
  );

  Map<String, dynamic> toJson() => {
    "position": position,
    "company_id": companyId,
    "company_name": companyName,
  };
}

class LastAction {
  String status;
  int timestamp;
  String relative;

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

class Life {
  int current;
  int maximum;
  int increment;
  int interval;
  int ticktime;
  int fulltime;

  Life({
    this.current,
    this.maximum,
    this.increment,
    this.interval,
    this.ticktime,
    this.fulltime,
  });

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
  int spouseId;
  String spouseName;
  int duration;

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
  int hospitalTimestamp;
  int jailTimestamp;

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
  String description;
  String details;
  String state;
  String color;
  int until;

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