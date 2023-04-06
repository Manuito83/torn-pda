// To parse this JSON data, do
//
//     final appWidgetApiModel = appWidgetApiModelFromJson(jsonString);

import 'dart:convert';

import 'package:torn_pda/models/profile/own_profile_model.dart';

AppWidgetApiModel appWidgetApiModelFromJson(String str) => AppWidgetApiModel.fromJson(json.decode(str));

String appWidgetApiModelToJson(AppWidgetApiModel data) => json.encode(data.toJson());

class AppWidgetApiModel {
  AppWidgetApiModel({
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
    this.revivable,
    this.serverTime,
    this.events,
    this.points,
    this.caymanBank,
    this.vaultAmount,
    this.companyFunds,
    this.dailyNetworth,
    this.moneyOnhand,
    this.life,
    this.status,
    this.job,
    this.faction,
    this.married,
    this.states,
    this.lastAction,
    this.icons,
    this.happy,
    this.energy,
    this.nerve,
    this.chain,
    this.cooldowns,
    this.messages,
    this.travel,
    this.cityBank,
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
  dynamic competition;
  int revivable;
  int serverTime;
  int points;
  int caymanBank;
  int vaultAmount;
  int companyFunds;
  int dailyNetworth;
  int moneyOnhand;
  Energy life;
  Status status;
  Job job;
  Faction faction;
  Married married;
  States states;
  LastAction lastAction;
  TornIcons icons;
  Energy happy;
  Energy energy;
  Energy nerve;
  Chain chain;
  Cooldowns cooldowns;
  dynamic messages;
  dynamic events;
  Travel travel;
  CityBank cityBank;

  factory AppWidgetApiModel.fromJson(Map<String, dynamic> json) => AppWidgetApiModel(
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
        competition: json["competition"],
        revivable: json["revivable"],
        serverTime: json["server_time"],
        points: json["points"],
        caymanBank: json["cayman_bank"],
        vaultAmount: json["vault_amount"],
        companyFunds: json["company_funds"],
        dailyNetworth: json["daily_networth"],
        moneyOnhand: json["money_onhand"],
        life: Energy.fromJson(json["life"]),
        status: Status.fromJson(json["status"]),
        job: Job.fromJson(json["job"]),
        faction: Faction.fromJson(json["faction"]),
        married: Married.fromJson(json["married"]),
        states: States.fromJson(json["states"]),
        lastAction: LastAction.fromJson(json["last_action"]),
        // If it's List<dynamic>, it's empty [], so we initialise values to null (there is a null check
        // afterwards in Profile). Otherwise, it's a map that can be generated from the class.
        // For some reason this is the only place where this happens if user is idle for some days
        icons: json["icons"] is List<dynamic>
            ? json["icons"] = TornIcons()
            : json["icons"] == null
                ? null
                : TornIcons.fromJson(json["icons"]),
        happy: Energy.fromJson(json["happy"]),
        energy: Energy.fromJson(json["energy"]),
        nerve: Energy.fromJson(json["nerve"]),
        chain: Chain.fromJson(json["chain"]),
        cooldowns: Cooldowns.fromJson(json["cooldowns"]),
        events: json["events"],
        messages: json["messages"],
        travel: Travel.fromJson(json["travel"]),
        cityBank: CityBank.fromJson(json["city_bank"]),
      );

  Map<String, dynamic> toJson() => {
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
        "competition": competition,
        "revivable": revivable,
        "server_time": serverTime,
        "points": points,
        "cayman_bank": caymanBank,
        "vault_amount": vaultAmount,
        "company_funds": companyFunds,
        "daily_networth": dailyNetworth,
        "money_onhand": moneyOnhand,
        "life": life.toJson(),
        "status": status.toJson(),
        "job": job.toJson(),
        "faction": faction.toJson(),
        "married": married.toJson(),
        "states": states.toJson(),
        "last_action": lastAction.toJson(),
        "icons": icons.toJson(),
        "happy": happy.toJson(),
        "energy": energy.toJson(),
        "nerve": nerve.toJson(),
        "chain": chain.toJson(),
        "cooldowns": cooldowns.toJson(),
        "events": events,
        "messages": messages,
        "travel": travel.toJson(),
        "city_bank": cityBank.toJson(),
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
  int modifier;
  int cooldown;

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

class CityBank {
  CityBank({
    this.amount,
    this.timeLeft,
  });

  int amount;
  int timeLeft;

  factory CityBank.fromJson(Map<String, dynamic> json) => CityBank(
        amount: json["amount"],
        timeLeft: json["time_left"],
      );

  Map<String, dynamic> toJson() => {
        "amount": amount,
        "time_left": timeLeft,
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

  int current;
  int maximum;
  int increment;
  int interval;
  int ticktime;
  int fulltime;

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

class Events {
  Events();

  factory Events.fromJson(Map<String, dynamic> json) => Events();

  Map<String, dynamic> toJson() => {};
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
        position: json["position"],
        companyId: json["company_id"],
        companyName: json["company_name"],
        companyType: json["company_type"],
      );

  Map<String, dynamic> toJson() => {
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

  String status;
  int timestamp;
  String relative;

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

  int spouseId;
  String spouseName;
  int duration;

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

  int hospitalTimestamp;
  int jailTimestamp;

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

  String description;
  String details;
  String state;
  String color;
  int until;

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
    this.method,
    this.timestamp,
    this.departed,
    this.timeLeft,
  });

  String destination;
  String method;
  int timestamp;
  int departed;
  int timeLeft;

  factory Travel.fromJson(Map<String, dynamic> json) => Travel(
        destination: json["destination"],
        method: json["method"],
        timestamp: json["timestamp"],
        departed: json["departed"],
        timeLeft: json["time_left"],
      );

  Map<String, dynamic> toJson() => {
        "destination": destination,
        "method": method,
        "timestamp": timestamp,
        "departed": departed,
        "time_left": timeLeft,
      };
}
