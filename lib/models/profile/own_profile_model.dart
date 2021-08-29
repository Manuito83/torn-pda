// To parse this JSON data, do
//
//     final ownProfileModel = ownProfileModelFromJson(jsonString);

// Dart imports:
import 'dart:convert';

OwnProfileExtended ownProfileExtendedFromJson(String str) =>
    OwnProfileExtended.fromJson(json.decode(str));

String ownProfileExtendedToJson(OwnProfileExtended data) => json.encode(data.toJson());

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
    this.travel,
    this.icons,
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
  int serverTime;
  Life life;
  Status status;
  Job job;
  Faction faction;
  Married married;
  States states;
  LastAction lastAction;
  Happy happy;
  Energy energy;
  Nerve nerve;
  Chain chain;
  Map<String, double> networth;
  Cooldowns cooldowns;
  dynamic events;
  dynamic messages;
  Travel travel;
  dynamic icons;

  factory OwnProfileExtended.fromJson(Map<String, dynamic> json) {
    return OwnProfileExtended(
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
      serverTime: json["server_time"] == null ? null : json["server_time"],
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
          : Map.from(json["networth"]).map((k, v) => MapEntry<String, double>(k, v.toDouble())),
      cooldowns: json["cooldowns"] == null ? null : Cooldowns.fromJson(json["cooldowns"]),
      events: json["events"],
      messages: json["messages"],
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
        "server_time": serverTime == null ? null : serverTime,
        "life": life == null ? null : life.toJson(),
        "status": status == null ? null : status.toJson(),
        "job": job == null ? null : job.toJson(),
        "faction": faction == null ? null : faction.toJson(),
        "married": married == null ? null : married.toJson(),
        "states": states == null ? null : states.toJson(),
        "last_action": lastAction == null ? null : lastAction.toJson(),
        "happy": happy == null ? null : happy.toJson(),
        "energy": energy == null ? null : energy.toJson(),
        "nerve": nerve == null ? null : nerve.toJson(),
        "chain": chain == null ? null : chain.toJson(),
        "networth": networth == null
            ? null
            : Map.from(networth).map((k, v) => MapEntry<String, dynamic>(k, v)),
        "cooldowns": cooldowns == null ? null : cooldowns.toJson(),
        "events": events,
        "messages": messages,
        "travel": travel == null ? null : travel.toJson(),
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

class Nerve {
  Nerve({
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

  factory Nerve.fromJson(Map<String, dynamic> json) => Nerve(
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

class Happy {
  Happy({
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

  factory Happy.fromJson(Map<String, dynamic> json) => Happy(
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

class Event {
  Event({
    this.timestamp,
    this.event,
    this.seen,
  });

  int timestamp;
  String event;
  int seen;

  factory Event.fromJson(Map<String, dynamic> json) => Event(
        timestamp: json["timestamp"] == null ? null : json["timestamp"],
        event: json["event"] == null ? null : json["event"],
        seen: json["seen"] == null ? null : json["seen"],
      );

  Map<String, dynamic> toJson() => {
        "timestamp": timestamp == null ? null : timestamp,
        "event": event == null ? null : event,
        "seen": seen == null ? null : seen,
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

  int timestamp;
  int id;
  String name;
  String type;
  dynamic title;
  int seen;
  int read;

  factory TornMessage.fromJson(Map<String, dynamic> json) => TornMessage(
        timestamp: json["timestamp"] == null ? null : json["timestamp"],
        id: json["ID"] == null ? null : json["ID"],
        name: json["name"] == null ? null : json["name"],
        type: json["type"] == null ? null : json["type"],
        title: json["title"],
        seen: json["seen"] == null ? null : json["seen"],
        read: json["read"] == null ? null : json["read"],
      );

  Map<String, dynamic> toJson() => {
        "timestamp": timestamp == null ? null : timestamp,
        "ID": id == null ? null : id,
        "name": name == null ? null : name,
        "type": type == null ? null : type,
        "title": title,
        "seen": seen == null ? null : seen,
        "read": read == null ? null : read,
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

class Travel {
  Travel({
    this.destination,
    this.timestamp,
    this.departed,
    this.timeLeft,
  });

  String destination;
  int timestamp;
  int departed;
  int timeLeft;

  factory Travel.fromJson(Map<String, dynamic> json) => Travel(
        destination: json["destination"] == null ? null : json["destination"],
        timestamp: json["timestamp"] == null ? null : json["timestamp"],
        departed: json["departed"] == null ? null : json["departed"],
        timeLeft: json["time_left"] == null ? null : json["time_left"],
      );

  Map<String, dynamic> toJson() => {
        "destination": destination == null ? null : destination,
        "timestamp": timestamp == null ? null : timestamp,
        "departed": departed == null ? null : departed,
        "time_left": timeLeft == null ? null : timeLeft,
      };
}

class TornIcons {
  TornIcons({
    this.icon12,
    this.icon13,
    this.icon15,
    this.icon16,
    this.icon17,
    this.icon18,
    this.icon20,
    this.icon30,
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
    this.icon84,
    this.icon85,
    this.icon86,
  });

  String icon12;
  String icon13;
  String icon15;
  String icon16;
  String icon17;
  String icon18;
  String icon20;
  String icon30;
  String icon37;
  String icon39;
  String icon40;
  String icon41;
  String icon42;
  String icon43;
  String icon44;
  String icon45;
  String icon46;
  String icon47;
  String icon48;
  String icon49;
  String icon50;
  String icon51;
  String icon52;
  String icon53;
  String icon57;
  String icon58;
  String icon59;
  String icon60;
  String icon61;
  String icon63;
  String icon64;
  String icon65;
  String icon66;
  String icon67;
  String icon68;
  String icon75;
  String icon76;
  String icon78;
  String icon79;
  String icon80;
  String icon84;
  String icon85;
  String icon86;

  factory TornIcons.fromJson(Map<String, dynamic> json) => TornIcons(
    icon12: json["icon12"] == null ? null : json["icon12"],
    icon13: json["icon13"] == null ? null : json["icon13"],
    icon15: json["icon15"] == null ? null : json["icon15"],
    icon16: json["icon16"] == null ? null : json["icon16"],
    icon17: json["icon17"] == null ? null : json["icon17"],
    icon18: json["icon18"] == null ? null : json["icon18"],
    icon20: json["icon20"] == null ? null : json["icon20"],
    icon30: json["icon30"] == null ? null : json["icon30"],
    icon37: json["icon37"] == null ? null : json["icon37"],
    icon39: json["icon39"] == null ? null : json["icon39"],
    icon40: json["icon40"] == null ? null : json["icon40"],
    icon41: json["icon41"] == null ? null : json["icon41"],
    icon42: json["icon42"] == null ? null : json["icon42"],
    icon43: json["icon43"] == null ? null : json["icon43"],
    icon44: json["icon44"] == null ? null : json["icon44"],
    icon45: json["icon45"] == null ? null : json["icon45"],
    icon46: json["icon46"] == null ? null : json["icon46"],
    icon47: json["icon47"] == null ? null : json["icon47"],
    icon48: json["icon48"] == null ? null : json["icon48"],
    icon49: json["icon49"] == null ? null : json["icon49"],
    icon50: json["icon50"] == null ? null : json["icon50"],
    icon51: json["icon51"] == null ? null : json["icon51"],
    icon52: json["icon52"] == null ? null : json["icon52"],
    icon53: json["icon53"] == null ? null : json["icon53"],
    icon57: json["icon57"] == null ? null : json["icon57"],
    icon58: json["icon58"] == null ? null : json["icon58"],
    icon59: json["icon59"] == null ? null : json["icon59"],
    icon60: json["icon60"] == null ? null : json["icon60"],
    icon61: json["icon61"] == null ? null : json["icon61"],
    icon63: json["icon63"] == null ? null : json["icon63"],
    icon64: json["icon64"] == null ? null : json["icon64"],
    icon65: json["icon65"] == null ? null : json["icon65"],
    icon66: json["icon66"] == null ? null : json["icon66"],
    icon67: json["icon67"] == null ? null : json["icon67"],
    icon68: json["icon68"] == null ? null : json["icon68"],
    icon75: json["icon75"] == null ? null : json["icon75"],
    icon76: json["icon76"] == null ? null : json["icon76"],
    icon78: json["icon78"] == null ? null : json["icon78"],
    icon79: json["icon79"] == null ? null : json["icon79"],
    icon80: json["icon80"] == null ? null : json["icon80"],
    icon84: json["icon84"] == null ? null : json["icon84"],
    icon85: json["icon85"] == null ? null : json["icon85"],
    icon86: json["icon86"] == null ? null : json["icon86"],
  );

  Map<String, dynamic> toJson() => {
    "icon12": icon12 == null ? null : icon12,
    "icon13": icon13 == null ? null : icon13,
    "icon15": icon15 == null ? null : icon15,
    "icon16": icon16 == null ? null : icon16,
    "icon17": icon17 == null ? null : icon17,
    "icon18": icon18 == null ? null : icon18,
    "icon20": icon20 == null ? null : icon20,
    "icon30": icon30 == null ? null : icon30,
    "icon37": icon37 == null ? null : icon37,
    "icon39": icon39 == null ? null : icon39,
    "icon40": icon40 == null ? null : icon40,
    "icon41": icon41 == null ? null : icon41,
    "icon42": icon42 == null ? null : icon42,
    "icon43": icon43 == null ? null : icon43,
    "icon44": icon44 == null ? null : icon44,
    "icon45": icon45 == null ? null : icon45,
    "icon46": icon46 == null ? null : icon46,
    "icon47": icon47 == null ? null : icon47,
    "icon48": icon48 == null ? null : icon48,
    "icon49": icon49 == null ? null : icon49,
    "icon50": icon50 == null ? null : icon50,
    "icon51": icon51 == null ? null : icon51,
    "icon52": icon52 == null ? null : icon52,
    "icon53": icon53 == null ? null : icon53,
    "icon57": icon57 == null ? null : icon57,
    "icon58": icon58 == null ? null : icon58,
    "icon59": icon59 == null ? null : icon59,
    "icon60": icon60 == null ? null : icon60,
    "icon61": icon61 == null ? null : icon61,
    "icon63": icon63 == null ? null : icon63,
    "icon64": icon64 == null ? null : icon64,
    "icon65": icon65 == null ? null : icon65,
    "icon66": icon66 == null ? null : icon66,
    "icon67": icon67 == null ? null : icon67,
    "icon68": icon68 == null ? null : icon68,
    "icon75": icon75 == null ? null : icon75,
    "icon76": icon76 == null ? null : icon76,
    "icon78": icon78 == null ? null : icon78,
    "icon79": icon79 == null ? null : icon79,
    "icon80": icon80 == null ? null : icon80,
    "icon84": icon85 == null ? null : icon84,
    "icon85": icon85 == null ? null : icon85,
    "icon86": icon86 == null ? null : icon86,
  };

}
