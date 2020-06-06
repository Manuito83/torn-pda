// To parse this JSON data, do
//
//     final ownProfileModel = ownProfileModelFromJson(jsonString);

import 'dart:convert';

OwnProfileModel ownProfileModelFromJson(String str) => OwnProfileModel.fromJson(json.decode(str));

String ownProfileModelToJson(OwnProfileModel data) => json.encode(data.toJson());

class OwnProfileModel {
  OwnProfileModel({
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
    this.basicicons,
    this.states,
    this.lastAction,
    this.serverTime,
    this.happy,
    this.energy,
    this.nerve,
    this.chain,
    this.networth,
    this.cooldowns,
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
  Energy life;
  Status status;
  Job job;
  Faction faction;
  Married married;
  Basicicons basicicons;
  States states;
  LastAction lastAction;
  int serverTime;
  Energy happy;
  Energy energy;
  Energy nerve;
  Chain chain;
  Map<String, double> networth;
  Cooldowns cooldowns;

  factory OwnProfileModel.fromJson(Map<String, dynamic> json) => OwnProfileModel(
    rank: json["rank"] == null ? null : json["rank"],
    level: json["level"] == null ? null : json["level"],
    gender: json["gender"] == null ? null : json["gender"],
    property: json["property"] == null ? null : json["property"],
    signup: json["signup"] == null ? null : DateTime.parse(json["signup"]),
    awards: json["awards"] == null ? null : json["awards"],
    friends: json["friends"] == null ? null : json["friends"],
    enemies: json["enemies"] == null ? null : json["enemies"],
    forumPosts: json["forum_posts"] == null ? null : json["forum_posts"],
    karma: json["karma"] == null ? null : json["karma"],
    age: json["age"] == null ? null : json["age"],
    role: json["role"] == null ? null : json["role"],
    donator: json["donator"] == null ? null : json["donator"],
    playerId: json["player_id"] == null ? null : json["player_id"],
    name: json["name"] == null ? null : json["name"],
    propertyId: json["property_id"] == null ? null : json["property_id"],
    life: json["life"] == null ? null : Energy.fromJson(json["life"]),
    status: json["status"] == null ? null : Status.fromJson(json["status"]),
    job: json["job"] == null ? null : Job.fromJson(json["job"]),
    faction: json["faction"] == null ? null : Faction.fromJson(json["faction"]),
    married: json["married"] == null ? null : Married.fromJson(json["married"]),
    basicicons: json["basicicons"] == null ? null : Basicicons.fromJson(json["basicicons"]),
    states: json["states"] == null ? null : States.fromJson(json["states"]),
    lastAction: json["last_action"] == null ? null : LastAction.fromJson(json["last_action"]),
    serverTime: json["server_time"] == null ? null : json["server_time"],
    happy: json["happy"] == null ? null : Energy.fromJson(json["happy"]),
    energy: json["energy"] == null ? null : Energy.fromJson(json["energy"]),
    nerve: json["nerve"] == null ? null : Energy.fromJson(json["nerve"]),
    chain: json["chain"] == null ? null : Chain.fromJson(json["chain"]),
    networth: json["networth"] == null ? null : Map.from(json["networth"]).map((k, v) => MapEntry<String, double>(k, v.toDouble())),
    cooldowns: json["cooldowns"] == null ? null : Cooldowns.fromJson(json["cooldowns"]),
  );

  Map<String, dynamic> toJson() => {
    "rank": rank == null ? null : rank,
    "level": level == null ? null : level,
    "gender": gender == null ? null : gender,
    "property": property == null ? null : property,
    "signup": signup == null ? null : signup.toIso8601String(),
    "awards": awards == null ? null : awards,
    "friends": friends == null ? null : friends,
    "enemies": enemies == null ? null : enemies,
    "forum_posts": forumPosts == null ? null : forumPosts,
    "karma": karma == null ? null : karma,
    "age": age == null ? null : age,
    "role": role == null ? null : role,
    "donator": donator == null ? null : donator,
    "player_id": playerId == null ? null : playerId,
    "name": name == null ? null : name,
    "property_id": propertyId == null ? null : propertyId,
    "life": life == null ? null : life.toJson(),
    "status": status == null ? null : status.toJson(),
    "job": job == null ? null : job.toJson(),
    "faction": faction == null ? null : faction.toJson(),
    "married": married == null ? null : married.toJson(),
    "basicicons": basicicons == null ? null : basicicons.toJson(),
    "states": states == null ? null : states.toJson(),
    "last_action": lastAction == null ? null : lastAction.toJson(),
    "server_time": serverTime == null ? null : serverTime,
    "happy": happy == null ? null : happy.toJson(),
    "energy": energy == null ? null : energy.toJson(),
    "nerve": nerve == null ? null : nerve.toJson(),
    "chain": chain == null ? null : chain.toJson(),
    "networth": networth == null ? null : Map.from(networth).map((k, v) => MapEntry<String, dynamic>(k, v)),
    "cooldowns": cooldowns == null ? null : cooldowns.toJson(),
  };
}

class Basicicons {
  Basicicons({
    this.icon6,
    this.icon4,
    this.icon8,
    this.icon27,
    this.icon9,
    this.icon15,
    this.icon7,
    this.icon3,
    this.icon35,
    this.icon16,
    this.icon71,
  });

  String icon6;
  String icon4;
  String icon8;
  String icon27;
  String icon9;
  String icon15;
  String icon7;
  String icon3;
  String icon35;
  String icon16;
  String icon71;

  factory Basicicons.fromJson(Map<String, dynamic> json) => Basicicons(
    icon6: json["icon6"] == null ? null : json["icon6"],
    icon4: json["icon4"] == null ? null : json["icon4"],
    icon8: json["icon8"] == null ? null : json["icon8"],
    icon27: json["icon27"] == null ? null : json["icon27"],
    icon9: json["icon9"] == null ? null : json["icon9"],
    icon15: json["icon15"] == null ? null : json["icon15"],
    icon7: json["icon7"] == null ? null : json["icon7"],
    icon3: json["icon3"] == null ? null : json["icon3"],
    icon35: json["icon35"] == null ? null : json["icon35"],
    icon16: json["icon16"] == null ? null : json["icon16"],
    icon71: json["icon71"] == null ? null : json["icon71"],
  );

  Map<String, dynamic> toJson() => {
    "icon6": icon6 == null ? null : icon6,
    "icon4": icon4 == null ? null : icon4,
    "icon8": icon8 == null ? null : icon8,
    "icon27": icon27 == null ? null : icon27,
    "icon9": icon9 == null ? null : icon9,
    "icon15": icon15 == null ? null : icon15,
    "icon7": icon7 == null ? null : icon7,
    "icon3": icon3 == null ? null : icon3,
    "icon35": icon35 == null ? null : icon35,
    "icon16": icon16 == null ? null : icon16,
    "icon71": icon71 == null ? null : icon71,
  };
}

class Chain {
  Chain({
    this.current,
    this.maximum,
    this.timeout,
    this.modifier,
    this.cooldown,
  });

  int current;
  int maximum;
  int timeout;
  double modifier;
  int cooldown;

  factory Chain.fromJson(Map<String, dynamic> json) => Chain(
    current: json["current"] == null ? null : json["current"],
    maximum: json["maximum"] == null ? null : json["maximum"],
    timeout: json["timeout"] == null ? null : json["timeout"],
    modifier: json["modifier"] == null ? null : json["modifier"].toDouble(),
    cooldown: json["cooldown"] == null ? null : json["cooldown"],
  );

  Map<String, dynamic> toJson() => {
    "current": current == null ? null : current,
    "maximum": maximum == null ? null : maximum,
    "timeout": timeout == null ? null : timeout,
    "modifier": modifier == null ? null : modifier,
    "cooldown": cooldown == null ? null : cooldown,
  };
}

class Cooldowns {
  Cooldowns({
    this.drug,
    this.medical,
    this.booster,
  });

  int drug;
  int medical;
  int booster;

  factory Cooldowns.fromJson(Map<String, dynamic> json) => Cooldowns(
    drug: json["drug"] == null ? null : json["drug"],
    medical: json["medical"] == null ? null : json["medical"],
    booster: json["booster"] == null ? null : json["booster"],
  );

  Map<String, dynamic> toJson() => {
    "drug": drug == null ? null : drug,
    "medical": medical == null ? null : medical,
    "booster": booster == null ? null : booster,
  };
}

class Energy {
  Energy({
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

  factory Energy.fromJson(Map<String, dynamic> json) => Energy(
    current: json["current"] == null ? null : json["current"],
    maximum: json["maximum"] == null ? null : json["maximum"],
    increment: json["increment"] == null ? null : json["increment"],
    interval: json["interval"] == null ? null : json["interval"],
    ticktime: json["ticktime"] == null ? null : json["ticktime"],
    fulltime: json["fulltime"] == null ? null : json["fulltime"],
  );

  Map<String, dynamic> toJson() => {
    "current": current == null ? null : current,
    "maximum": maximum == null ? null : maximum,
    "increment": increment == null ? null : increment,
    "interval": interval == null ? null : interval,
    "ticktime": ticktime == null ? null : ticktime,
    "fulltime": fulltime == null ? null : fulltime,
  };
}

class Faction {
  Faction({
    this.position,
    this.factionId,
    this.daysInFaction,
    this.factionName,
  });

  String position;
  int factionId;
  int daysInFaction;
  String factionName;

  factory Faction.fromJson(Map<String, dynamic> json) => Faction(
    position: json["position"] == null ? null : json["position"],
    factionId: json["faction_id"] == null ? null : json["faction_id"],
    daysInFaction: json["days_in_faction"] == null ? null : json["days_in_faction"],
    factionName: json["faction_name"] == null ? null : json["faction_name"],
  );

  Map<String, dynamic> toJson() => {
    "position": position == null ? null : position,
    "faction_id": factionId == null ? null : factionId,
    "days_in_faction": daysInFaction == null ? null : daysInFaction,
    "faction_name": factionName == null ? null : factionName,
  };
}

class Job {
  Job({
    this.position,
    this.companyId,
    this.companyName,
  });

  String position;
  int companyId;
  String companyName;

  factory Job.fromJson(Map<String, dynamic> json) => Job(
    position: json["position"] == null ? null : json["position"],
    companyId: json["company_id"] == null ? null : json["company_id"],
    companyName: json["company_name"] == null ? null : json["company_name"],
  );

  Map<String, dynamic> toJson() => {
    "position": position == null ? null : position,
    "company_id": companyId == null ? null : companyId,
    "company_name": companyName == null ? null : companyName,
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
    status: json["status"] == null ? null : json["status"],
    timestamp: json["timestamp"] == null ? null : json["timestamp"],
    relative: json["relative"] == null ? null : json["relative"],
  );

  Map<String, dynamic> toJson() => {
    "status": status == null ? null : status,
    "timestamp": timestamp == null ? null : timestamp,
    "relative": relative == null ? null : relative,
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
    spouseId: json["spouse_id"] == null ? null : json["spouse_id"],
    spouseName: json["spouse_name"] == null ? null : json["spouse_name"],
    duration: json["duration"] == null ? null : json["duration"],
  );

  Map<String, dynamic> toJson() => {
    "spouse_id": spouseId == null ? null : spouseId,
    "spouse_name": spouseName == null ? null : spouseName,
    "duration": duration == null ? null : duration,
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
    hospitalTimestamp: json["hospital_timestamp"] == null ? null : json["hospital_timestamp"],
    jailTimestamp: json["jail_timestamp"] == null ? null : json["jail_timestamp"],
  );

  Map<String, dynamic> toJson() => {
    "hospital_timestamp": hospitalTimestamp == null ? null : hospitalTimestamp,
    "jail_timestamp": jailTimestamp == null ? null : jailTimestamp,
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
    description: json["description"] == null ? null : json["description"],
    details: json["details"] == null ? null : json["details"],
    state: json["state"] == null ? null : json["state"],
    color: json["color"] == null ? null : json["color"],
    until: json["until"] == null ? null : json["until"],
  );

  Map<String, dynamic> toJson() => {
    "description": description == null ? null : description,
    "details": details == null ? null : details,
    "state": state == null ? null : state,
    "color": color == null ? null : color,
    "until": until == null ? null : until,
  };
}
