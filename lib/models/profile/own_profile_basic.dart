// To parse this JSON data, do
//
//     final ownProfileBasic = ownProfileBasicFromJson(jsonString);

// Dart imports:
import 'dart:convert';

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
    this.life,
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
  });

  // For state management
  String userApiKey;
  bool userApiKeyValid;

  String rank;
  int level;
  String gender;
  String property;
  String signup;
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
  int strength;
  int speed;
  int dexterity;
  int defense;
  int total;
  int strengthModifier;
  int defenseModifier;
  int speedModifier;
  int dexterityModifier;
  Life life;
  Status status;
  Job job;
  Faction faction;
  Married married;
  dynamic basicIcons;
  States states;
  LastAction lastAction;
  List<String> strengthInfo;
  List<String> defenseInfo;
  List<String> speedInfo;
  List<String> dexterityInfo;

  factory OwnProfileBasic.fromJson(Map<String, dynamic> json) => OwnProfileBasic(
        userApiKey: json["userApiKey"] == null ? '' : json["userApiKey"],
        userApiKeyValid: json["userApiKeyValid"] == null ? false : json["userApiKeyValid"],

        rank: json["rank"] == null ? null : json["rank"],
        level: json["level"] == null ? null : json["level"],
        gender: json["gender"] == null ? null : json["gender"],
        property: json["property"] == null ? null : json["property"],
        signup: json["signup"] == null ? null : json["signup"],
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
        competition: json["competition"],
        strength: json["strength"] == null ? null : json["strength"],
        speed: json["speed"] == null ? null : json["speed"],
        dexterity: json["dexterity"] == null ? null : json["dexterity"],
        defense: json["defense"] == null ? null : json["defense"],
        total: json["total"] == null ? null : json["total"],
        strengthModifier: json["strength_modifier"] == null ? null : json["strength_modifier"],
        defenseModifier: json["defense_modifier"] == null ? null : json["defense_modifier"],
        speedModifier: json["speed_modifier"] == null ? null : json["speed_modifier"],
        dexterityModifier: json["dexterity_modifier"] == null ? null : json["dexterity_modifier"],
        life: json["life"] == null ? null : Life.fromJson(json["life"]),
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
        strengthInfo: json["strength_info"] == null
            ? null
            : List<String>.from(json["strength_info"].map((x) => x)),
        defenseInfo: json["defense_info"] == null
            ? null
            : List<String>.from(json["defense_info"].map((x) => x)),
        speedInfo:
            json["speed_info"] == null ? null : List<String>.from(json["speed_info"].map((x) => x)),
        dexterityInfo: json["dexterity_info"] == null
            ? null
            : List<String>.from(json["dexterity_info"].map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "userApiKey": userApiKey == null ? null : userApiKey,
        "userApiKeyValid": userApiKeyValid == null ? null : userApiKeyValid,
        "rank": rank == null ? null : rank,
        "level": level == null ? null : level,
        "gender": gender == null ? null : gender,
        "property": property == null ? null : property,
        "signup": signup == null ? null : signup,
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
        "competition": competition,
        "strength": strength == null ? null : strength,
        "speed": speed == null ? null : speed,
        "dexterity": dexterity == null ? null : dexterity,
        "defense": defense == null ? null : defense,
        "total": total == null ? null : total,
        "strength_modifier": strengthModifier == null ? null : strengthModifier,
        "defense_modifier": defenseModifier == null ? null : defenseModifier,
        "speed_modifier": speedModifier == null ? null : speedModifier,
        "dexterity_modifier": dexterityModifier == null ? null : dexterityModifier,
        "life": life == null ? null : life.toJson(),
        "status": status == null ? null : status.toJson(),
        "job": job == null ? null : job.toJson(),
        "faction": faction == null ? null : faction.toJson(),
        "married": married == null ? null : married.toJson(),
        "basicicons": basicIcons == null ? null : basicIcons.toJson(),
        "states": states == null ? null : states.toJson(),
        "last_action": lastAction == null ? null : lastAction.toJson(),
        "strength_info":
            strengthInfo == null ? null : List<dynamic>.from(strengthInfo.map((x) => x)),
        "defense_info": defenseInfo == null ? null : List<dynamic>.from(defenseInfo.map((x) => x)),
        "speed_info": speedInfo == null ? null : List<dynamic>.from(speedInfo.map((x) => x)),
        "dexterity_info":
            dexterityInfo == null ? null : List<dynamic>.from(dexterityInfo.map((x) => x)),
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

  String icon6;
  String icon4;
  String icon8;
  String icon27;
  String icon81;

  factory BasicIcons.fromJson(Map<String, dynamic> json) => BasicIcons(
        icon6: json["icon6"] == null ? null : json["icon6"],
        icon4: json["icon4"] == null ? null : json["icon4"],
        icon8: json["icon8"] == null ? null : json["icon8"],
        icon27: json["icon27"] == null ? null : json["icon27"],
        icon81: json["icon81"] == null ? null : json["icon81"],
      );

  Map<String, dynamic> toJson() => {
        "icon6": icon6 == null ? null : icon6,
        "icon4": icon4 == null ? null : icon4,
        "icon8": icon8 == null ? null : icon8,
        "icon27": icon27 == null ? null : icon27,
        "icon81": icon81 == null ? null : icon81,
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
        position: json["position"] == null ? null : json["position"],
        factionId: json["faction_id"] == null ? null : json["faction_id"],
        daysInFaction: json["days_in_faction"] == null ? null : json["days_in_faction"],
        factionName: json["faction_name"] == null ? null : json["faction_name"],
        // API sometimes converts to INT if tag is numbers
        factionTag: json["faction_tag"] == null ? null : json["faction_tag"].toString(),
      );

  Map<String, dynamic> toJson() => {
        "position": position == null ? null : position,
        "faction_id": factionId == null ? null : factionId,
        "days_in_faction": daysInFaction == null ? null : daysInFaction,
        "faction_name": factionName == null ? null : factionName,
        "faction_tag": factionTag == null ? null : factionTag,
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
        position: json["position"] == null ? null : json["position"],
        companyId: json["company_id"] == null ? null : json["company_id"],
        companyName: json["company_name"] == null ? null : json["company_name"],
        companyType: json["company_type"] == null ? null : json["company_type"],
      );

  Map<String, dynamic> toJson() => {
        "position": position == null ? null : position,
        "company_id": companyId == null ? null : companyId,
        "company_name": companyName == null ? null : companyName,
        "company_type": companyType == null ? null : companyType,
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
