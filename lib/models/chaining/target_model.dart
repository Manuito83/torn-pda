// To parse this JSON data, do
//
//     final targetModel = targetModelFromJson(jsonString);

// Dart imports:
import 'dart:convert';
import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:torn_pda/main.dart';

import 'package:torn_pda/models/profile/own_profile_basic.dart';

TargetModel targetModelFromJson(String str) => TargetModel.fromJson(json.decode(str));

String targetModelToJson(TargetModel data) => json.encode(data.toJson());

class TargetModel {
  // For state management
  bool isUpdating = false;
  bool justUpdatedWithError = false;
  bool justUpdatedWithSuccess = false;

  // External, exported/imported to Shared Preferences!
  double? respectGain;
  double? fairFight;
  bool? userWonOrDefended;
  @Deprecated('Use PlayerNotesController instead')
  String? personalNote;
  @Deprecated('Use PlayerNotesController instead')
  String? personalNoteColor;
  String? noteBackup;
  String? colorBackup;
  DateTime? lastUpdated;
  bool? hasFaction;
  int? hospitalSort;
  int timeAdded;

  // Internal from API profiles
  String? rank;
  int? level;
  String? gender;
  String? property;
  DateTime? signup;
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
  Life? life;
  Status? status;
  Job? job;
  Faction? faction;
  Married? married;
  States? states;
  LastAction? lastAction;
  Discord? discord;
  Competition? competition;
  TargetBasicIcons? basicicons;
  int? bountyAmount;

  TargetModel({
    // This first batch is here to export/import from SharedPreferences,
    // so we also have to initialize them below
    this.respectGain,
    this.fairFight,
    this.userWonOrDefended,
    this.personalNote,
    this.personalNoteColor,
    this.noteBackup,
    this.colorBackup,
    this.lastUpdated,
    this.hasFaction,
    this.hospitalSort = 0,
    this.timeAdded = 0,
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
    this.competition,
    this.basicicons,
    this.bountyAmount,
  });

  factory TargetModel.fromJson(Map<String, dynamic> json) => TargetModel(
        // respectGain can't be null to allow sorting targets, so if it stays
        // at -1, it's because the target has unknown respect (new target)
        respectGain: json["respectGain"] ?? -1,
        fairFight: json["fairFight"] ?? -1,
        userWonOrDefended: json["userWonOrDefended"] ?? false,
        personalNote: json["personalNote"] ?? '',
        personalNoteColor: json["personalNoteColor"] ?? '',
        noteBackup: json["noteBackup"],
        colorBackup: json["colorBackup"],
        lastUpdated: json["lastUpdated"] == null ? DateTime.now() : DateTime.parse(json["lastUpdated"]),
        hasFaction: json["hasFaction"] ?? false,
        hospitalSort: json["hospitalSort"] ?? 0,
        timeAdded: json["timeAdded"] ?? 0,
        rank: json["rank"],
        level: json["level"],
        gender: json["gender"],
        property: json["property"],
        signup: json["signup"] == null ? null : DateTime.parse(json["signup"]),
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
        life: json["life"] == null ? null : Life.fromJson(json["life"]),
        status: json["status"] == null ? null : Status.fromJson(json["status"]),
        job: json["job"] == null ? null : Job.fromJson(json["job"]),
        faction: json["faction"] == null ? null : Faction.fromJson(json["faction"]),
        married: json["married"] == null ? null : Married.fromJson(json["married"]),
        states: json["states"] == null ? null : States.fromJson(json["states"]),
        lastAction: json["last_action"] == null ? null : LastAction.fromJson(json["last_action"]),
        discord: json["discord"] == null ? null : Discord.fromJson(json["discord"]),
        competition: json["competition"] == null ? null : Competition.fromJson(json["competition"]),
        basicicons: json["basicicons"] == null ? null : TargetBasicIcons.fromJson(json["basicicons"]),
        bountyAmount: json["bountyAmount"],
      );

  Map<String, dynamic> toJson() => {
        "respectGain": respectGain,
        "fairFight": fairFight,
        "userWonOrDefended": userWonOrDefended,
        "personalNote": personalNote,
        "personalNoteColor": personalNoteColor,
        "noteBackup": noteBackup,
        "colorBackup": colorBackup,
        "lastUpdated": lastUpdated!.toIso8601String(),
        "hasFaction": hasFaction,
        "hospitalSort": hospitalSort,
        "timeAdded": timeAdded,
        "rank": rank,
        "level": level,
        "gender": gender,
        "property": property,
        "signup": signup!.toIso8601String(),
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
        "life": life!.toJson(),
        "status": status!.toJson(),
        "job": job!.toJson(),
        "faction": faction!.toJson(),
        "married": married!.toJson(),
        "states": states!.toJson(),
        "last_action": lastAction!.toJson(),
        "discord": discord?.toJson(),
        "competition": competition?.toJson(),
        "basicicons": basicicons?.toJson(),
        "bountyAmount": bountyAmount,
      };
}

class Discord {
  Discord({
    this.userId,
    this.discordId,
  });

  int? userId;
  String? discordId;

  factory Discord.fromJson(Map<String, dynamic> json) => Discord(
        userId: json["userID"],
        discordId: json["discordID"],
      );

  Map<String, dynamic> toJson() => {
        "userID": userId,
        "discordID": discordId,
      };
}

class Faction {
  String? position;
  int? factionId;
  int? daysInFaction;
  String? factionName;

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

class Competition {
  int? attacks;
  String? image;
  String? name;
  double? score;
  dynamic team;
  String? text;
  int? total;
  int? treatsCollectedTotal;
  int? votes;
  dynamic position;

  Competition({
    this.attacks,
    this.image,
    this.name,
    this.score,
    this.team,
    this.text,
    this.total,
    this.treatsCollectedTotal,
    this.votes,
    this.position,
  });

  factory Competition.fromJson(Map<String, dynamic> json) {
    try {
      return Competition(
        attacks: json["attacks"],
        image: json["image"],
        name: json["name"],
        score: json["score"]?.toDouble(),
        team: json["team"],
        text: json["text"],
        total: json["total"],
        treatsCollectedTotal: json["treats_collected_total"],
        votes: json["votes"],
        position: json["position"]?.toString(),
      );
    } catch (e, trace) {
      if (!Platform.isWindows) FirebaseCrashlytics.instance.log("PDA Crash at Competition model");
      if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError("PDA Error: $e", trace);
      logToUser("PDA Error at Competition model: $e, $trace");
      throw ArgumentError("PDA Crash at Competition model");
    }
  }

  Map<String, dynamic> toJson() => {
        "attacks": attacks,
        "image": image,
        "name": name,
        "score": score,
        "team": team,
        "text": text,
        "total": total,
        "treats_collected_total": treatsCollectedTotal,
        "votes": votes,
        "position": position,
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
