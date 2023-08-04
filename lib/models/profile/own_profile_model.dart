// To parse this JSON data, do
//
//     final ownProfileModel = ownProfileModelFromJson(jsonString);

// Dart imports:
import 'dart:convert';

import 'package:torn_pda/models/profile/own_profile_basic.dart';

OwnProfileExtended ownProfileExtendedFromJson(String str) => OwnProfileExtended.fromJson(json.decode(str));
String ownProfileExtendedToJson(OwnProfileExtended data) => json.encode(data.toJson());

Event eventFromJson(String str) => Event.fromJson(json.decode(str));
String eventToJson(Event data) => json.encode(data.toJson());

class OwnProfileExtended {
  OwnProfileExtended({
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
    this.serverTime,
    this.moneyOnHand,
    this.life,
    this.status,
    this.job,
    this.faction,
    this.married,
    this.states,
    this.lastAction,
    this.happy,
    this.energy,
    this.nerve,
    this.chain,
    this.networth,
    this.cooldowns,
    this.events,
    this.messages,
    this.notifications,
    this.travel,
    this.icons,
  });

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
  int? serverTime;
  int? moneyOnHand;
  Life? life;
  Status? status;
  Job? job;
  Faction? faction;
  Married? married;
  States? states;
  LastAction? lastAction;
  Happy? happy;
  Energy? energy;
  Nerve? nerve;
  Chain? chain;
  Map<String, double?>? networth;
  Cooldowns? cooldowns;
  List<Event>? events;
  dynamic messages;
  Notifications? notifications;
  Travel? travel;
  dynamic icons;

  factory OwnProfileExtended.fromJson(Map<String, dynamic> json) {
    return OwnProfileExtended(
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
      serverTime: json["server_time"],
      moneyOnHand: json["money_onhand"] ?? 0,
      life: json["life"] == null ? null : Life.fromJson(json["life"]),
      status: json["status"] == null ? null : Status.fromJson(json["status"]),
      job: json["job"] == null ? null : Job.fromJson(json["job"]),
      faction: json["faction"] == null ? null : Faction.fromJson(json["faction"]),
      married: json["married"] == null ? null : Married.fromJson(json["married"]),
      states: json["states"] == null ? null : States.fromJson(json["states"]),
      lastAction: json["last_action"] == null ? null : LastAction.fromJson(json["last_action"]),
      happy: json["happy"] == null ? null : Happy.fromJson(json["happy"]),
      energy: json["energy"] == null ? null : Energy.fromJson(json["energy"]),
      nerve: json["nerve"] == null ? null : Nerve.fromJson(json["nerve"]),
      chain: json["chain"] == null ? null : Chain.fromJson(json["chain"]),
      networth: json["networth"] == null
          ? null
          : Map.from(json["networth"]).map((k, v) => MapEntry<String, double?>(k, v.toDouble())),
      cooldowns: json["cooldowns"] == null ? null : Cooldowns.fromJson(json["cooldowns"]),
      events: json["events"],
      messages: json["messages"],
      notifications: json["notifications"] == null ? null : Notifications.fromJson(json["notifications"]),
      travel: json["travel"] == null ? null : Travel.fromJson(json["travel"]),
      // If it's List<dynamic>, it's empty [], so we initialise values to null (there is a null check
      // afterwards in Profile). Otherwise, it's a map that can be generated from the class.
      // For some reason this is the only place where this happens if user is idle for some days
      icons: json["icons"] is List<dynamic>
          ? json["icons"] = TornIcons()
          : json["icons"] == null
              ? null
              : TornIcons.fromJson(json["icons"]),
    );
  }

  Map<String, dynamic> toJson() => {
        "rank": rank,
        "level": level,
        "gender": gender,
        "property": property,
        "signup": signup == null ? null : signup!.toIso8601String(),
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
        "server_time": serverTime,
        "money_onhand": moneyOnHand,
        "life": life == null ? null : life!.toJson(),
        "status": status == null ? null : status!.toJson(),
        "job": job == null ? null : job!.toJson(),
        "faction": faction == null ? null : faction!.toJson(),
        "married": married == null ? null : married!.toJson(),
        "states": states == null ? null : states!.toJson(),
        "last_action": lastAction == null ? null : lastAction!.toJson(),
        "happy": happy == null ? null : happy!.toJson(),
        "energy": energy == null ? null : energy!.toJson(),
        "nerve": nerve == null ? null : nerve!.toJson(),
        "chain": chain == null ? null : chain!.toJson(),
        "networth": networth == null ? null : Map.from(networth!).map((k, v) => MapEntry<String, dynamic>(k, v)),
        "cooldowns": cooldowns == null ? null : cooldowns!.toJson(),
        "events": events,
        "messages": messages,
        "notifications": notifications,
        "travel": travel == null ? null : travel!.toJson(),
        "icons": icons == null ? null : icons.toJson(),
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

  int? current;
  int? maximum;
  int? timeout;
  double? modifier;
  int? cooldown;

  factory Chain.fromJson(Map<String, dynamic> json) => Chain(
        current: json["current"],
        maximum: json["maximum"],
        timeout: json["timeout"],
        modifier: json["modifier"] == null ? null : json["modifier"].toDouble(),
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

class Energy {
  Energy({
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

  factory Energy.fromJson(Map<String, dynamic> json) => Energy(
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

class Nerve {
  Nerve({
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

  factory Nerve.fromJson(Map<String, dynamic> json) => Nerve(
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

class Happy {
  Happy({
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

  factory Happy.fromJson(Map<String, dynamic> json) => Happy(
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

class Event {
  Event({
    this.timestamp,
    this.event,
  });

  int? timestamp;
  String? event;

  factory Event.fromJson(Map<String, dynamic> json) => Event(
        timestamp: json["timestamp"],
        event: json["event"],
      );

  Map<String, dynamic> toJson() => {
        "timestamp": timestamp,
        "event": event,
      };
}

class TornMessage {
  TornMessage({
    this.timestamp,
    this.id,
    this.name,
    this.type,
    this.title,
    this.seen,
    this.read,
  });

  int? timestamp;
  int? id;
  String? name;
  String? type;
  dynamic title;
  int? seen;
  int? read;

  factory TornMessage.fromJson(Map<String, dynamic> json) => TornMessage(
        timestamp: json["timestamp"],
        id: json["ID"],
        name: json["name"],
        type: json["type"],
        title: json["title"],
        seen: json["seen"],
        read: json["read"],
      );

  Map<String, dynamic> toJson() => {
        "timestamp": timestamp,
        "ID": id,
        "name": name,
        "type": type,
        "title": title,
        "seen": seen,
        "read": read,
      };
}

class Notifications {
  Notifications({
    this.messages,
    this.events,
    this.awards,
    this.competition,
  });

  int? messages;
  int? events;
  int? awards;
  int? competition;

  factory Notifications.fromJson(Map<String, dynamic> json) => Notifications(
        messages: json["messages"],
        events: json["events"],
        awards: json["awards"],
        competition: json["competition"],
      );

  Map<String, dynamic> toJson() => {
        "messages": messages,
        "events": events,
        "awards": awards,
        "competition": competition,
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
        companyName: json["company_name"] == null ? null : json["company_name"].toString(),
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

class TornIcons {
  TornIcons({
    this.icon3,
    this.icon4,
    this.icon12,
    this.icon13,
    this.icon15,
    this.icon16,
    this.icon17,
    this.icon18,
    this.icon20,
    this.icon29,
    this.icon30,
    this.icon31,
    this.icon32,
    this.icon33,
    this.icon37,
    this.icon39,
    this.icon40,
    this.icon41,
    this.icon42,
    this.icon43,
    this.icon44,
    this.icon45,
    this.icon46,
    this.icon47,
    this.icon48,
    this.icon49,
    this.icon50,
    this.icon51,
    this.icon52,
    this.icon53,
    this.icon57,
    this.icon58,
    this.icon59,
    this.icon60,
    this.icon61,
    this.icon63,
    this.icon64,
    this.icon65,
    this.icon66,
    this.icon67,
    this.icon68,
    this.icon75,
    this.icon76,
    this.icon78,
    this.icon79,
    this.icon80,
    this.icon81,
    this.icon83,
    this.icon84,
    this.icon85,
    this.icon86,
  });

  String? icon3;
  String? icon4;
  String? icon12;
  String? icon13;
  String? icon15;
  String? icon16;
  String? icon17;
  String? icon18;
  String? icon20;
  String? icon29;
  String? icon30;
  String? icon31;
  String? icon32;
  String? icon33;
  String? icon37;
  String? icon39;
  String? icon40;
  String? icon41;
  String? icon42;
  String? icon43;
  String? icon44;
  String? icon45;
  String? icon46;
  String? icon47;
  String? icon48;
  String? icon49;
  String? icon50;
  String? icon51;
  String? icon52;
  String? icon53;
  String? icon57;
  String? icon58;
  String? icon59;
  String? icon60;
  String? icon61;
  String? icon63;
  String? icon64;
  String? icon65;
  String? icon66;
  String? icon67;
  String? icon68;
  String? icon75;
  String? icon76;
  String? icon78;
  String? icon79;
  String? icon80;
  String? icon81;
  String? icon83;
  String? icon84;
  String? icon85;
  String? icon86;

  factory TornIcons.fromJson(Map<String, dynamic> json) => TornIcons(
        icon3: json["icon3"],
        icon4: json["icon4"],
        icon12: json["icon12"],
        icon13: json["icon13"],
        icon15: json["icon15"],
        icon16: json["icon16"],
        icon17: json["icon17"],
        icon18: json["icon18"],
        icon20: json["icon20"],
        icon29: json["icon29"],
        icon30: json["icon30"],
        icon31: json["icon31"],
        icon32: json["icon32"],
        icon33: json["icon33"],
        icon37: json["icon37"],
        icon39: json["icon39"],
        icon40: json["icon40"],
        icon41: json["icon41"],
        icon42: json["icon42"],
        icon43: json["icon43"],
        icon44: json["icon44"],
        icon45: json["icon45"],
        icon46: json["icon46"],
        icon47: json["icon47"],
        icon48: json["icon48"],
        icon49: json["icon49"],
        icon50: json["icon50"],
        icon51: json["icon51"],
        icon52: json["icon52"],
        icon53: json["icon53"],
        icon57: json["icon57"],
        icon58: json["icon58"],
        icon59: json["icon59"],
        icon60: json["icon60"],
        icon61: json["icon61"],
        icon63: json["icon63"],
        icon64: json["icon64"],
        icon65: json["icon65"],
        icon66: json["icon66"],
        icon67: json["icon67"],
        icon68: json["icon68"],
        icon75: json["icon75"],
        icon76: json["icon76"],
        icon78: json["icon78"],
        icon79: json["icon79"],
        icon80: json["icon80"],
        icon81: json["icon81"],
        icon83: json["icon83"],
        icon84: json["icon84"],
        icon85: json["icon85"],
        icon86: json["icon86"],
      );

  Map<String, dynamic> toJson() => {
        "icon3": icon3,
        "icon4": icon4,
        "icon12": icon12,
        "icon13": icon13,
        "icon15": icon15,
        "icon16": icon16,
        "icon17": icon17,
        "icon18": icon18,
        "icon20": icon20,
        "icon29": icon29,
        "icon30": icon30,
        "icon31": icon31,
        "icon32": icon32,
        "icon33": icon33,
        "icon37": icon37,
        "icon39": icon39,
        "icon40": icon40,
        "icon41": icon41,
        "icon42": icon42,
        "icon43": icon43,
        "icon44": icon44,
        "icon45": icon45,
        "icon46": icon46,
        "icon47": icon47,
        "icon48": icon48,
        "icon49": icon49,
        "icon50": icon50,
        "icon51": icon51,
        "icon52": icon52,
        "icon53": icon53,
        "icon57": icon57,
        "icon58": icon58,
        "icon59": icon59,
        "icon60": icon60,
        "icon61": icon61,
        "icon63": icon63,
        "icon64": icon64,
        "icon65": icon65,
        "icon66": icon66,
        "icon67": icon67,
        "icon68": icon68,
        "icon75": icon75,
        "icon76": icon76,
        "icon78": icon78,
        "icon79": icon79,
        "icon80": icon80,
        "icon81": icon81,
        "icon83": icon83,
        "icon84": icon85 == null ? null : icon84,
        "icon85": icon85,
        "icon86": icon86,
      };
}
