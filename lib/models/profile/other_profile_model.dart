// To parse this JSON data, do
//
//     final otherProfileModel = otherProfileModelFromJson(jsonString);

import 'dart:convert';

OtherProfileModel otherProfileModelFromJson(String str) => OtherProfileModel.fromJson(json.decode(str));

String otherProfileModelToJson(OtherProfileModel data) => json.encode(data.toJson());

class OtherProfileModel {
  String? rank;
  int? level;
  int? honor;
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
  int? revivable;
  String? profileImage;
  Life? life;
  Status? status;
  Job? job;
  Faction? faction;
  Married? married;
  TargetBasicIcons? basicicons;
  States? states;
  LastAction? lastAction;
  Competition? competition;
  Criminalrecord? criminalrecord;
  List<dynamic>? bazaar;
  Personalstats? personalstats;

  OtherProfileModel({
    this.rank,
    this.level,
    this.honor,
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
    this.revivable,
    this.profileImage,
    this.life,
    this.status,
    this.job,
    this.faction,
    this.married,
    this.basicicons,
    this.states,
    this.lastAction,
    this.competition,
    this.criminalrecord,
    this.bazaar,
    this.personalstats,
  });

  factory OtherProfileModel.fromJson(Map<String, dynamic> json) => OtherProfileModel(
        rank: json["rank"],
        level: json["level"],
        honor: json["honor"],
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
        revivable: json["revivable"],
        profileImage: json["profile_image"],
        life: json["life"] == null ? null : Life.fromJson(json["life"]),
        status: json["status"] == null ? null : Status.fromJson(json["status"]),
        job: json["job"] == null ? null : Job.fromJson(json["job"]),
        faction: json["faction"] == null ? null : Faction.fromJson(json["faction"]),
        married: json["married"] == null ? null : Married.fromJson(json["married"]),
        basicicons: json["basicicons"] == null ? null : TargetBasicIcons.fromJson(json["basicicons"]),
        states: json["states"] == null ? null : States.fromJson(json["states"]),
        lastAction: json["last_action"] == null ? null : LastAction.fromJson(json["last_action"]),
        competition: json["competition"] == null ? null : Competition.fromJson(json["competition"]),
        criminalrecord: json["criminalrecord"] == null ? null : Criminalrecord.fromJson(json["criminalrecord"]),
        bazaar: json["bazaar"] == null ? [] : List<dynamic>.from(json["bazaar"]!.map((x) => x)),
        personalstats: json["personalstats"] == null ? null : Personalstats.fromJson(json["personalstats"]),
      );

  Map<String, dynamic> toJson() => {
        "rank": rank,
        "level": level,
        "honor": honor,
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
        "revivable": revivable,
        "profile_image": profileImage,
        "life": life?.toJson(),
        "status": status?.toJson(),
        "job": job?.toJson(),
        "faction": faction?.toJson(),
        "married": married?.toJson(),
        "basicicons": basicicons?.toJson(),
        "states": states?.toJson(),
        "last_action": lastAction?.toJson(),
        "competition": competition?.toJson(),
        "criminalrecord": criminalrecord?.toJson(),
        "bazaar": bazaar == null ? [] : List<dynamic>.from(bazaar!.map((x) => x)),
        "personalstats": personalstats?.toJson(),
      };
}

class TargetBasicIcons {
  String? icon13; // Bounties

  TargetBasicIcons({
    this.icon13 = "",
  });

  factory TargetBasicIcons.fromJson(Map<String, dynamic> json) => TargetBasicIcons(
        icon13: json["icon13"],
      );

  Map<String, dynamic> toJson() => {
        "icon13": icon13,
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

class Criminalrecord {
  dynamic vandalism;
  dynamic theft;
  dynamic counterfeiting;
  dynamic fraud;
  dynamic illicitservices;
  dynamic cybercrime;
  dynamic extortion;
  dynamic illegalproduction;
  dynamic total;

  Criminalrecord({
    this.vandalism,
    this.theft,
    this.counterfeiting,
    this.fraud,
    this.illicitservices,
    this.cybercrime,
    this.extortion,
    this.illegalproduction,
    this.total,
  });

  factory Criminalrecord.fromJson(Map<String, dynamic> json) => Criminalrecord(
        vandalism: json["vandalism"],
        theft: json["theft"],
        counterfeiting: json["counterfeiting"],
        fraud: json["fraud"],
        illicitservices: json["illicitservices"],
        cybercrime: json["cybercrime"],
        extortion: json["extortion"],
        illegalproduction: json["illegalproduction"],
        total: json["total"],
      );

  Map<String, dynamic> toJson() => {
        "vandalism": vandalism,
        "theft": theft,
        "counterfeiting": counterfeiting,
        "fraud": fraud,
        "illicitservices": illicitservices,
        "cybercrime": cybercrime,
        "extortion": extortion,
        "illegalproduction": illegalproduction,
        "total": total,
      };
}

class Faction {
  String? position;
  int? factionId;
  int? daysInFaction;
  String? factionName;
  String? factionTag;
  String? factionTagImage;

  Faction({
    this.position,
    this.factionId,
    this.daysInFaction,
    this.factionName,
    this.factionTag,
    this.factionTagImage,
  });

  factory Faction.fromJson(Map<String, dynamic> json) => Faction(
        position: json["position"],
        factionId: json["faction_id"],
        daysInFaction: json["days_in_faction"],
        factionName: json["faction_name"],
        factionTag: json["faction_tag"],
        factionTagImage: json["faction_tag_image"],
      );

  Map<String, dynamic> toJson() => {
        "position": position,
        "faction_id": factionId,
        "days_in_faction": daysInFaction,
        "faction_name": factionName,
        "faction_tag": factionTag,
        "faction_tag_image": factionTagImage,
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

class Life {
  int? current;
  int? maximum;
  int? increment;
  int? interval;
  int? ticktime;
  int? fulltime;

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

class Personalstats {
  int? statenhancersused;
  int? exttaken;
  int? lsdtaken;
  int? xantaken;
  int? networth;
  int? energydrinkused;
  int? refills;
  int? criminaloffenses;

  Personalstats({
    this.statenhancersused,
    this.exttaken,
    this.lsdtaken,
    this.xantaken,
    this.networth,
    this.energydrinkused,
    this.refills,
    this.criminaloffenses,
  });

  factory Personalstats.fromJson(Map<String, dynamic> json) => Personalstats(
        statenhancersused: json["statenhancersused"],
        exttaken: json["exttaken"],
        lsdtaken: json["lsdtaken"],
        xantaken: json["xantaken"],
        networth: json["networth"],
        energydrinkused: json["energydrinkused"],
        refills: json["refills"],
        criminaloffenses: json["criminaloffenses"],
      );

  Map<String, dynamic> toJson() => {
        "statenhancersused": statenhancersused,
        "exttaken": exttaken,
        "lsdtaken": lsdtaken,
        "xantaken": xantaken,
        "networth": networth,
        "energydrinkused": energydrinkused,
        "refills": refills,
        "criminaloffenses": criminaloffenses,
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
