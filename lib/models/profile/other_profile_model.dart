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
  Personalstats? personalstats;
  List<BazaarElement>? bazaar;
  Life? life;
  Status? status;
  Job? job;
  OtherProfileModelFaction? faction;
  Married? married;
  Basicicons? basicicons;
  States? states;
  LastAction? lastAction;
  Competition? competition;

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
    this.personalstats,
    this.bazaar,
    this.life,
    this.status,
    this.job,
    this.faction,
    this.married,
    this.basicicons,
    this.states,
    this.lastAction,
    this.competition,
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
        personalstats: json["personalstats"] == null ? null : Personalstats.fromJson(json["personalstats"]),
        bazaar: json["bazaar"] == null
            ? []
            : List<BazaarElement>.from(json["bazaar"]!.map((x) => BazaarElement.fromJson(x))),
        life: json["life"] == null ? null : Life.fromJson(json["life"]),
        status: json["status"] == null ? null : Status.fromJson(json["status"]),
        job: json["job"] == null ? null : Job.fromJson(json["job"]),
        faction: json["faction"] == null ? null : OtherProfileModelFaction.fromJson(json["faction"]),
        married: json["married"] == null ? null : Married.fromJson(json["married"]),
        basicicons: json["basicicons"] == null ? null : Basicicons.fromJson(json["basicicons"]),
        states: json["states"] == null ? null : States.fromJson(json["states"]),
        lastAction: json["last_action"] == null ? null : LastAction.fromJson(json["last_action"]),
        competition: json["competition"] == null ? null : Competition.fromJson(json["competition"]),
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
        "personalstats": personalstats?.toJson(),
        "bazaar": bazaar == null ? [] : List<dynamic>.from(bazaar!.map((x) => x.toJson())),
        "life": life?.toJson(),
        "status": status?.toJson(),
        "job": job?.toJson(),
        "faction": faction?.toJson(),
        "married": married?.toJson(),
        "basicicons": basicicons?.toJson(),
        "states": states?.toJson(),
        "last_action": lastAction?.toJson(),
        "competition": competition?.toJson(),
      };
}

class Basicicons {
  String? icon13;

  Basicicons({this.icon13});

  factory Basicicons.fromJson(Map<String, dynamic> json) => Basicicons(
        icon13: json["icon13"],
      );

  Map<String, dynamic> toJson() => {
        "icon13": icon13,
      };
}

class BazaarElement {
  int? id;
  String? name;
  String? type;
  int? quantity;
  int? price;
  int? marketPrice;
  int? uid;

  BazaarElement({
    this.id,
    this.name,
    this.type,
    this.quantity,
    this.price,
    this.marketPrice,
    this.uid,
  });

  factory BazaarElement.fromJson(Map<String, dynamic> json) => BazaarElement(
        id: json["ID"],
        name: json["name"],
        type: json["type"],
        quantity: json["quantity"],
        price: json["price"],
        marketPrice: json["market_price"],
        uid: json["UID"],
      );

  Map<String, dynamic> toJson() => {
        "ID": id,
        "name": name,
        "type": type,
        "quantity": quantity,
        "price": price,
        "market_price": marketPrice,
        "UID": uid,
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

class OtherProfileModelFaction {
  String? position;
  int? factionId;
  int? daysInFaction;
  String? factionName;
  String? factionTag;
  String? factionTagImage;

  OtherProfileModelFaction({
    this.position,
    this.factionId,
    this.daysInFaction,
    this.factionName,
    this.factionTag,
    this.factionTagImage,
  });

  factory OtherProfileModelFaction.fromJson(Map<String, dynamic> json) => OtherProfileModelFaction(
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
  Attacking? attacking;
  BattleStats? battleStats;
  Jobs? jobs;
  Trading? trading;
  Jail? jail;
  Hospital? hospital;
  FinishingHits? finishingHits;
  Communication? communication;
  Crimes? crimes;
  Bounties? bounties;
  Investments? investments;
  PersonalstatsItems? items;
  Travel? travel;
  Drugs? drugs;
  Missions? missions;
  Racing? racing;
  PersonalstatsNetworth? networth;
  Other? other;

  Personalstats({
    this.attacking,
    this.battleStats,
    this.jobs,
    this.trading,
    this.jail,
    this.hospital,
    this.finishingHits,
    this.communication,
    this.crimes,
    this.bounties,
    this.investments,
    this.items,
    this.travel,
    this.drugs,
    this.missions,
    this.racing,
    this.networth,
    this.other,
  });

  factory Personalstats.fromJson(Map<String, dynamic> json) => Personalstats(
        attacking: json["attacking"] == null ? null : Attacking.fromJson(json["attacking"]),
        battleStats: json["battle_stats"] == null ? null : BattleStats.fromJson(json["battle_stats"]),
        jobs: json["jobs"] == null ? null : Jobs.fromJson(json["jobs"]),
        trading: json["trading"] == null ? null : Trading.fromJson(json["trading"]),
        jail: json["jail"] == null ? null : Jail.fromJson(json["jail"]),
        hospital: json["hospital"] == null ? null : Hospital.fromJson(json["hospital"]),
        finishingHits: json["finishing_hits"] == null ? null : FinishingHits.fromJson(json["finishing_hits"]),
        communication: json["communication"] == null ? null : Communication.fromJson(json["communication"]),
        crimes: json["crimes"] == null ? null : Crimes.fromJson(json["crimes"]),
        bounties: json["bounties"] == null ? null : Bounties.fromJson(json["bounties"]),
        investments: json["investments"] == null ? null : Investments.fromJson(json["investments"]),
        items: json["items"] == null ? null : PersonalstatsItems.fromJson(json["items"]),
        travel: json["travel"] == null ? null : Travel.fromJson(json["travel"]),
        drugs: json["drugs"] == null ? null : Drugs.fromJson(json["drugs"]),
        missions: json["missions"] == null ? null : Missions.fromJson(json["missions"]),
        racing: json["racing"] == null ? null : Racing.fromJson(json["racing"]),
        networth: json["networth"] == null ? null : PersonalstatsNetworth.fromJson(json["networth"]),
        other: json["other"] == null ? null : Other.fromJson(json["other"]),
      );

  Map<String, dynamic> toJson() => {
        "attacking": attacking?.toJson(),
        "battle_stats": battleStats?.toJson(),
        "jobs": jobs?.toJson(),
        "trading": trading?.toJson(),
        "jail": jail?.toJson(),
        "hospital": hospital?.toJson(),
        "finishing_hits": finishingHits?.toJson(),
        "communication": communication?.toJson(),
        "crimes": crimes?.toJson(),
        "bounties": bounties?.toJson(),
        "investments": investments?.toJson(),
        "items": items?.toJson(),
        "travel": travel?.toJson(),
        "drugs": drugs?.toJson(),
        "missions": missions?.toJson(),
        "racing": racing?.toJson(),
        "networth": networth?.toJson(),
        "other": other?.toJson(),
      };
}

class Attacking {
  Attacks? attacks;
  Defends? defends;
  int? elo;
  int? unarmoredWins;
  int? highestLevelBeaten;
  Escapes? escapes;
  Streak? killstreak;
  Hits? hits;
  Damage? damage;
  AttackingNetworth? networth;
  Ammunition? ammunition;
  AttackingFaction? faction;

  Attacking({
    this.attacks,
    this.defends,
    this.elo,
    this.unarmoredWins,
    this.highestLevelBeaten,
    this.escapes,
    this.killstreak,
    this.hits,
    this.damage,
    this.networth,
    this.ammunition,
    this.faction,
  });

  factory Attacking.fromJson(Map<String, dynamic> json) => Attacking(
        attacks: json["attacks"] == null ? null : Attacks.fromJson(json["attacks"]),
        defends: json["defends"] == null ? null : Defends.fromJson(json["defends"]),
        elo: json["elo"],
        unarmoredWins: json["unarmored_wins"],
        highestLevelBeaten: json["highest_level_beaten"],
        escapes: json["escapes"] == null ? null : Escapes.fromJson(json["escapes"]),
        killstreak: json["killstreak"] == null ? null : Streak.fromJson(json["killstreak"]),
        hits: json["hits"] == null ? null : Hits.fromJson(json["hits"]),
        damage: json["damage"] == null ? null : Damage.fromJson(json["damage"]),
        networth: json["networth"] == null ? null : AttackingNetworth.fromJson(json["networth"]),
        ammunition: json["ammunition"] == null ? null : Ammunition.fromJson(json["ammunition"]),
        faction: json["faction"] == null ? null : AttackingFaction.fromJson(json["faction"]),
      );

  Map<String, dynamic> toJson() => {
        "attacks": attacks?.toJson(),
        "defends": defends?.toJson(),
        "elo": elo,
        "unarmored_wins": unarmoredWins,
        "highest_level_beaten": highestLevelBeaten,
        "escapes": escapes?.toJson(),
        "killstreak": killstreak?.toJson(),
        "hits": hits?.toJson(),
        "damage": damage?.toJson(),
        "networth": networth?.toJson(),
        "ammunition": ammunition?.toJson(),
        "faction": faction?.toJson(),
      };
}

class Ammunition {
  int? total;
  int? special;
  int? hollowPoint;
  int? tracer;
  int? piercing;
  int? incendiary;

  Ammunition({
    this.total,
    this.special,
    this.hollowPoint,
    this.tracer,
    this.piercing,
    this.incendiary,
  });

  factory Ammunition.fromJson(Map<String, dynamic> json) => Ammunition(
        total: json["total"],
        special: json["special"],
        hollowPoint: json["hollow_point"],
        tracer: json["tracer"],
        piercing: json["piercing"],
        incendiary: json["incendiary"],
      );

  Map<String, dynamic> toJson() => {
        "total": total,
        "special": special,
        "hollow_point": hollowPoint,
        "tracer": tracer,
        "piercing": piercing,
        "incendiary": incendiary,
      };
}

class Attacks {
  int? won;
  int? lost;
  int? stalemate;
  int? assist;
  int? stealth;

  Attacks({
    this.won,
    this.lost,
    this.stalemate,
    this.assist,
    this.stealth,
  });

  factory Attacks.fromJson(Map<String, dynamic> json) => Attacks(
        won: json["won"],
        lost: json["lost"],
        stalemate: json["stalemate"],
        assist: json["assist"],
        stealth: json["stealth"],
      );

  Map<String, dynamic> toJson() => {
        "won": won,
        "lost": lost,
        "stalemate": stalemate,
        "assist": assist,
        "stealth": stealth,
      };
}

class Damage {
  int? total;
  int? best;

  Damage({
    this.total,
    this.best,
  });

  factory Damage.fromJson(Map<String, dynamic> json) => Damage(
        total: json["total"],
        best: json["best"],
      );

  Map<String, dynamic> toJson() => {
        "total": total,
        "best": best,
      };
}

class Defends {
  int? won;
  int? lost;
  int? stalemate;
  int? total;

  Defends({
    this.won,
    this.lost,
    this.stalemate,
    this.total,
  });

  factory Defends.fromJson(Map<String, dynamic> json) => Defends(
        won: json["won"],
        lost: json["lost"],
        stalemate: json["stalemate"],
        total: json["total"],
      );

  Map<String, dynamic> toJson() => {
        "won": won,
        "lost": lost,
        "stalemate": stalemate,
        "total": total,
      };
}

class Escapes {
  int? player;
  int? foes;

  Escapes({
    this.player,
    this.foes,
  });

  factory Escapes.fromJson(Map<String, dynamic> json) => Escapes(
        player: json["player"],
        foes: json["foes"],
      );

  Map<String, dynamic> toJson() => {
        "player": player,
        "foes": foes,
      };
}

class AttackingFaction {
  int? respect;
  int? retaliations;
  int? rankedWarHits;
  int? raidHits;
  Territory? territory;

  AttackingFaction({
    this.respect,
    this.retaliations,
    this.rankedWarHits,
    this.raidHits,
    this.territory,
  });

  factory AttackingFaction.fromJson(Map<String, dynamic> json) => AttackingFaction(
        respect: json["respect"],
        retaliations: json["retaliations"],
        rankedWarHits: json["ranked_war_hits"],
        raidHits: json["raid_hits"],
        territory: json["territory"] == null ? null : Territory.fromJson(json["territory"]),
      );

  Map<String, dynamic> toJson() => {
        "respect": respect,
        "retaliations": retaliations,
        "ranked_war_hits": rankedWarHits,
        "raid_hits": raidHits,
        "territory": territory?.toJson(),
      };
}

class Territory {
  int? wallJoins;
  int? wallClears;
  int? wallTime;

  Territory({
    this.wallJoins,
    this.wallClears,
    this.wallTime,
  });

  factory Territory.fromJson(Map<String, dynamic> json) => Territory(
        wallJoins: json["wall_joins"],
        wallClears: json["wall_clears"],
        wallTime: json["wall_time"],
      );

  Map<String, dynamic> toJson() => {
        "wall_joins": wallJoins,
        "wall_clears": wallClears,
        "wall_time": wallTime,
      };
}

class Hits {
  int? success;
  int? miss;
  int? critical;
  int? oneHitKills;

  Hits({
    this.success,
    this.miss,
    this.critical,
    this.oneHitKills,
  });

  factory Hits.fromJson(Map<String, dynamic> json) => Hits(
        success: json["success"],
        miss: json["miss"],
        critical: json["critical"],
        oneHitKills: json["one_hit_kills"],
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "miss": miss,
        "critical": critical,
        "one_hit_kills": oneHitKills,
      };
}

class Streak {
  int? best;
  int? current;

  Streak({
    this.best,
    this.current,
  });

  factory Streak.fromJson(Map<String, dynamic> json) => Streak(
        best: json["best"],
        current: json["current"],
      );

  Map<String, dynamic> toJson() => {
        "best": best,
        "current": current,
      };
}

class AttackingNetworth {
  int? moneyMugged;
  int? largestMug;
  int? itemsLooted;

  AttackingNetworth({
    this.moneyMugged,
    this.largestMug,
    this.itemsLooted,
  });

  factory AttackingNetworth.fromJson(Map<String, dynamic> json) => AttackingNetworth(
        moneyMugged: json["money_mugged"],
        largestMug: json["largest_mug"],
        itemsLooted: json["items_looted"],
      );

  Map<String, dynamic> toJson() => {
        "money_mugged": moneyMugged,
        "largest_mug": largestMug,
        "items_looted": itemsLooted,
      };
}

class BattleStats {
  int? strength;
  int? defense;
  int? speed;
  int? dexterity;
  int? total;

  BattleStats({
    this.strength,
    this.defense,
    this.speed,
    this.dexterity,
    this.total,
  });

  factory BattleStats.fromJson(Map<String, dynamic> json) => BattleStats(
        strength: json["strength"],
        defense: json["defense"],
        speed: json["speed"],
        dexterity: json["dexterity"],
        total: json["total"],
      );

  Map<String, dynamic> toJson() => {
        "strength": strength,
        "defense": defense,
        "speed": speed,
        "dexterity": dexterity,
        "total": total,
      };
}

class Bounties {
  Collected? placed;
  Collected? collected;
  Collected? received;

  Bounties({
    this.placed,
    this.collected,
    this.received,
  });

  factory Bounties.fromJson(Map<String, dynamic> json) => Bounties(
        placed: json["placed"] == null ? null : Collected.fromJson(json["placed"]),
        collected: json["collected"] == null ? null : Collected.fromJson(json["collected"]),
        received: json["received"] == null ? null : Collected.fromJson(json["received"]),
      );

  Map<String, dynamic> toJson() => {
        "placed": placed?.toJson(),
        "collected": collected?.toJson(),
        "received": received?.toJson(),
      };
}

class Collected {
  int? amount;
  int? value;

  Collected({
    this.amount,
    this.value,
  });

  factory Collected.fromJson(Map<String, dynamic> json) => Collected(
        amount: json["amount"],
        value: json["value"],
      );

  Map<String, dynamic> toJson() => {
        "amount": amount,
        "value": value,
      };
}

class Communication {
  MailsSent? mailsSent;
  int? classifiedAds;
  int? personals;

  Communication({
    this.mailsSent,
    this.classifiedAds,
    this.personals,
  });

  factory Communication.fromJson(Map<String, dynamic> json) => Communication(
        mailsSent: json["mails_sent"] == null ? null : MailsSent.fromJson(json["mails_sent"]),
        classifiedAds: json["classified_ads"],
        personals: json["personals"],
      );

  Map<String, dynamic> toJson() => {
        "mails_sent": mailsSent?.toJson(),
        "classified_ads": classifiedAds,
        "personals": personals,
      };
}

class MailsSent {
  int? total;
  int? friends;
  int? faction;
  int? colleagues;
  int? spouse;

  MailsSent({
    this.total,
    this.friends,
    this.faction,
    this.colleagues,
    this.spouse,
  });

  factory MailsSent.fromJson(Map<String, dynamic> json) => MailsSent(
        total: json["total"],
        friends: json["friends"],
        faction: json["faction"],
        colleagues: json["colleagues"],
        spouse: json["spouse"],
      );

  Map<String, dynamic> toJson() => {
        "total": total,
        "friends": friends,
        "faction": faction,
        "colleagues": colleagues,
        "spouse": spouse,
      };
}

class Crimes {
  Offenses? offenses;
  Skills? skills;
  String? version;

  Crimes({
    this.offenses,
    this.skills,
    this.version,
  });

  factory Crimes.fromJson(Map<String, dynamic> json) => Crimes(
        offenses: json["offenses"] == null ? null : Offenses.fromJson(json["offenses"]),
        skills: json["skills"] == null ? null : Skills.fromJson(json["skills"]),
        version: json["version"],
      );

  Map<String, dynamic> toJson() => {
        "offenses": offenses?.toJson(),
        "skills": skills?.toJson(),
        "version": version,
      };
}

class Offenses {
  int? vandalism;
  int? fraud;
  int? theft;
  int? counterfeiting;
  int? illicitServices;
  int? cybercrime;
  int? extortion;
  int? illegalProduction;
  int? organizedCrimes;
  int? total;

  Offenses({
    this.vandalism,
    this.fraud,
    this.theft,
    this.counterfeiting,
    this.illicitServices,
    this.cybercrime,
    this.extortion,
    this.illegalProduction,
    this.organizedCrimes,
    this.total,
  });

  factory Offenses.fromJson(Map<String, dynamic> json) => Offenses(
        vandalism: json["vandalism"],
        fraud: json["fraud"],
        theft: json["theft"],
        counterfeiting: json["counterfeiting"],
        illicitServices: json["illicit_services"],
        cybercrime: json["cybercrime"],
        extortion: json["extortion"],
        illegalProduction: json["illegal_production"],
        organizedCrimes: json["organized_crimes"],
        total: json["total"],
      );

  Map<String, dynamic> toJson() => {
        "vandalism": vandalism,
        "fraud": fraud,
        "theft": theft,
        "counterfeiting": counterfeiting,
        "illicit_services": illicitServices,
        "cybercrime": cybercrime,
        "extortion": extortion,
        "illegal_production": illegalProduction,
        "organized_crimes": organizedCrimes,
        "total": total,
      };
}

class Skills {
  int? searchForCash;
  int? bootlegging;
  int? graffiti;
  int? shoplifting;
  int? pickpocketing;
  int? cardSkimming;
  int? burglary;
  int? hustling;
  int? disposal;
  int? cracking;
  int? forgery;
  int? scamming;

  Skills({
    this.searchForCash,
    this.bootlegging,
    this.graffiti,
    this.shoplifting,
    this.pickpocketing,
    this.cardSkimming,
    this.burglary,
    this.hustling,
    this.disposal,
    this.cracking,
    this.forgery,
    this.scamming,
  });

  factory Skills.fromJson(Map<String, dynamic> json) => Skills(
        searchForCash: json["search_for_cash"],
        bootlegging: json["bootlegging"],
        graffiti: json["graffiti"],
        shoplifting: json["shoplifting"],
        pickpocketing: json["pickpocketing"],
        cardSkimming: json["card_skimming"],
        burglary: json["burglary"],
        hustling: json["hustling"],
        disposal: json["disposal"],
        cracking: json["cracking"],
        forgery: json["forgery"],
        scamming: json["scamming"],
      );

  Map<String, dynamic> toJson() => {
        "search_for_cash": searchForCash,
        "bootlegging": bootlegging,
        "graffiti": graffiti,
        "shoplifting": shoplifting,
        "pickpocketing": pickpocketing,
        "card_skimming": cardSkimming,
        "burglary": burglary,
        "hustling": hustling,
        "disposal": disposal,
        "cracking": cracking,
        "forgery": forgery,
        "scamming": scamming,
      };
}

class Drugs {
  int? cannabis;
  int? ecstasy;
  int? ketamine;
  int? lsd;
  int? opium;
  int? pcp;
  int? shrooms;
  int? speed;
  int? vicodin;
  int? xanax;
  int? total;
  int? overdoses;
  Rehabilitations? rehabilitations;

  Drugs({
    this.cannabis,
    this.ecstasy,
    this.ketamine,
    this.lsd,
    this.opium,
    this.pcp,
    this.shrooms,
    this.speed,
    this.vicodin,
    this.xanax,
    this.total,
    this.overdoses,
    this.rehabilitations,
  });

  factory Drugs.fromJson(Map<String, dynamic> json) => Drugs(
        cannabis: json["cannabis"],
        ecstasy: json["ecstasy"],
        ketamine: json["ketamine"],
        lsd: json["lsd"],
        opium: json["opium"],
        pcp: json["pcp"],
        shrooms: json["shrooms"],
        speed: json["speed"],
        vicodin: json["vicodin"],
        xanax: json["xanax"],
        total: json["total"],
        overdoses: json["overdoses"],
        rehabilitations: json["rehabilitations"] == null ? null : Rehabilitations.fromJson(json["rehabilitations"]),
      );

  Map<String, dynamic> toJson() => {
        "cannabis": cannabis,
        "ecstasy": ecstasy,
        "ketamine": ketamine,
        "lsd": lsd,
        "opium": opium,
        "pcp": pcp,
        "shrooms": shrooms,
        "speed": speed,
        "vicodin": vicodin,
        "xanax": xanax,
        "total": total,
        "overdoses": overdoses,
        "rehabilitations": rehabilitations?.toJson(),
      };
}

class Rehabilitations {
  int? amount;
  int? fees;

  Rehabilitations({
    this.amount,
    this.fees,
  });

  factory Rehabilitations.fromJson(Map<String, dynamic> json) => Rehabilitations(
        amount: json["amount"],
        fees: json["fees"],
      );

  Map<String, dynamic> toJson() => {
        "amount": amount,
        "fees": fees,
      };
}

class FinishingHits {
  int? heavyArtillery;
  int? machineGuns;
  int? rifles;
  int? subMachineGuns;
  int? shotguns;
  int? pistols;
  int? temporary;
  int? piercing;
  int? slashing;
  int? clubbing;
  int? mechanical;
  int? handToHand;

  FinishingHits({
    this.heavyArtillery,
    this.machineGuns,
    this.rifles,
    this.subMachineGuns,
    this.shotguns,
    this.pistols,
    this.temporary,
    this.piercing,
    this.slashing,
    this.clubbing,
    this.mechanical,
    this.handToHand,
  });

  factory FinishingHits.fromJson(Map<String, dynamic> json) => FinishingHits(
        heavyArtillery: json["heavy_artillery"],
        machineGuns: json["machine_guns"],
        rifles: json["rifles"],
        subMachineGuns: json["sub_machine_guns"],
        shotguns: json["shotguns"],
        pistols: json["pistols"],
        temporary: json["temporary"],
        piercing: json["piercing"],
        slashing: json["slashing"],
        clubbing: json["clubbing"],
        mechanical: json["mechanical"],
        handToHand: json["hand_to_hand"],
      );

  Map<String, dynamic> toJson() => {
        "heavy_artillery": heavyArtillery,
        "machine_guns": machineGuns,
        "rifles": rifles,
        "sub_machine_guns": subMachineGuns,
        "shotguns": shotguns,
        "pistols": pistols,
        "temporary": temporary,
        "piercing": piercing,
        "slashing": slashing,
        "clubbing": clubbing,
        "mechanical": mechanical,
        "hand_to_hand": handToHand,
      };
}

class Hospital {
  int? timesHospitalized;
  int? medicalItemsUsed;
  int? bloodWithdrawn;
  Reviving? reviving;

  Hospital({
    this.timesHospitalized,
    this.medicalItemsUsed,
    this.bloodWithdrawn,
    this.reviving,
  });

  factory Hospital.fromJson(Map<String, dynamic> json) => Hospital(
        timesHospitalized: json["times_hospitalized"],
        medicalItemsUsed: json["medical_items_used"],
        bloodWithdrawn: json["blood_withdrawn"],
        reviving: json["reviving"] == null ? null : Reviving.fromJson(json["reviving"]),
      );

  Map<String, dynamic> toJson() => {
        "times_hospitalized": timesHospitalized,
        "medical_items_used": medicalItemsUsed,
        "blood_withdrawn": bloodWithdrawn,
        "reviving": reviving?.toJson(),
      };
}

class Reviving {
  int? skill;
  int? revives;
  int? revivesReceived;

  Reviving({
    this.skill,
    this.revives,
    this.revivesReceived,
  });

  factory Reviving.fromJson(Map<String, dynamic> json) => Reviving(
        skill: json["skill"],
        revives: json["revives"],
        revivesReceived: json["revives_received"],
      );

  Map<String, dynamic> toJson() => {
        "skill": skill,
        "revives": revives,
        "revives_received": revivesReceived,
      };
}

class Investments {
  Bank? bank;
  Stocks? stocks;

  Investments({
    this.bank,
    this.stocks,
  });

  factory Investments.fromJson(Map<String, dynamic> json) => Investments(
        bank: json["bank"] == null ? null : Bank.fromJson(json["bank"]),
        stocks: json["stocks"] == null ? null : Stocks.fromJson(json["stocks"]),
      );

  Map<String, dynamic> toJson() => {
        "bank": bank?.toJson(),
        "stocks": stocks?.toJson(),
      };
}

class Bank {
  int? total;
  int? profit;
  int? current;
  int? timeRemaining;

  Bank({
    this.total,
    this.profit,
    this.current,
    this.timeRemaining,
  });

  factory Bank.fromJson(Map<String, dynamic> json) => Bank(
        total: json["total"],
        profit: json["profit"],
        current: json["current"],
        timeRemaining: json["time_remaining"],
      );

  Map<String, dynamic> toJson() => {
        "total": total,
        "profit": profit,
        "current": current,
        "time_remaining": timeRemaining,
      };
}

class Stocks {
  int? profits;
  int? losses;
  int? fees;
  int? netProfits;
  int? payouts;

  Stocks({
    this.profits,
    this.losses,
    this.fees,
    this.netProfits,
    this.payouts,
  });

  factory Stocks.fromJson(Map<String, dynamic> json) => Stocks(
        profits: json["profits"],
        losses: json["losses"],
        fees: json["fees"],
        netProfits: json["net_profits"],
        payouts: json["payouts"],
      );

  Map<String, dynamic> toJson() => {
        "profits": profits,
        "losses": losses,
        "fees": fees,
        "net_profits": netProfits,
        "payouts": payouts,
      };
}

class PersonalstatsItems {
  Found? found;
  int? trashed;
  Used? used;
  int? virusesCoded;

  PersonalstatsItems({
    this.found,
    this.trashed,
    this.used,
    this.virusesCoded,
  });

  factory PersonalstatsItems.fromJson(Map<String, dynamic> json) => PersonalstatsItems(
        found: json["found"] == null ? null : Found.fromJson(json["found"]),
        trashed: json["trashed"],
        used: json["used"] == null ? null : Used.fromJson(json["used"]),
        virusesCoded: json["viruses_coded"],
      );

  Map<String, dynamic> toJson() => {
        "found": found?.toJson(),
        "trashed": trashed,
        "used": used?.toJson(),
        "viruses_coded": virusesCoded,
      };
}

class Found {
  int? city;
  int? dump;
  int? easterEggs;

  Found({
    this.city,
    this.dump,
    this.easterEggs,
  });

  factory Found.fromJson(Map<String, dynamic> json) => Found(
        city: json["city"],
        dump: json["dump"],
        easterEggs: json["easter_eggs"],
      );

  Map<String, dynamic> toJson() => {
        "city": city,
        "dump": dump,
        "easter_eggs": easterEggs,
      };
}

class Used {
  int? books;
  int? boosters;
  int? consumables;
  int? candy;
  int? alcohol;
  int? energy;
  int? energyDrinks;
  int? statEnhancers;
  int? easterEggs;

  Used({
    this.books,
    this.boosters,
    this.consumables,
    this.candy,
    this.alcohol,
    this.energy,
    this.energyDrinks,
    this.statEnhancers,
    this.easterEggs,
  });

  factory Used.fromJson(Map<String, dynamic> json) => Used(
        books: json["books"],
        boosters: json["boosters"],
        consumables: json["consumables"],
        candy: json["candy"],
        alcohol: json["alcohol"],
        energy: json["energy"],
        energyDrinks: json["energy_drinks"],
        statEnhancers: json["stat_enhancers"],
        easterEggs: json["easter_eggs"],
      );

  Map<String, dynamic> toJson() => {
        "books": books,
        "boosters": boosters,
        "consumables": consumables,
        "candy": candy,
        "alcohol": alcohol,
        "energy": energy,
        "energy_drinks": energyDrinks,
        "stat_enhancers": statEnhancers,
        "easter_eggs": easterEggs,
      };
}

class Jail {
  int? timesJailed;
  Busts? busts;
  Rehabilitations? bails;

  Jail({
    this.timesJailed,
    this.busts,
    this.bails,
  });

  factory Jail.fromJson(Map<String, dynamic> json) => Jail(
        timesJailed: json["times_jailed"],
        busts: json["busts"] == null ? null : Busts.fromJson(json["busts"]),
        bails: json["bails"] == null ? null : Rehabilitations.fromJson(json["bails"]),
      );

  Map<String, dynamic> toJson() => {
        "times_jailed": timesJailed,
        "busts": busts?.toJson(),
        "bails": bails?.toJson(),
      };
}

class Busts {
  int? success;
  int? fails;

  Busts({
    this.success,
    this.fails,
  });

  factory Busts.fromJson(Map<String, dynamic> json) => Busts(
        success: json["success"],
        fails: json["fails"],
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "fails": fails,
      };
}

class Jobs {
  int? jobPointsUsed;
  int? trainsReceived;
  Stats? stats;

  Jobs({
    this.jobPointsUsed,
    this.trainsReceived,
    this.stats,
  });

  factory Jobs.fromJson(Map<String, dynamic> json) => Jobs(
        jobPointsUsed: json["job_points_used"],
        trainsReceived: json["trains_received"],
        stats: json["stats"] == null ? null : Stats.fromJson(json["stats"]),
      );

  Map<String, dynamic> toJson() => {
        "job_points_used": jobPointsUsed,
        "trains_received": trainsReceived,
        "stats": stats?.toJson(),
      };
}

class Stats {
  int? manual;
  int? intelligence;
  int? endurance;
  int? total;

  Stats({
    this.manual,
    this.intelligence,
    this.endurance,
    this.total,
  });

  factory Stats.fromJson(Map<String, dynamic> json) => Stats(
        manual: json["manual"],
        intelligence: json["intelligence"],
        endurance: json["endurance"],
        total: json["total"],
      );

  Map<String, dynamic> toJson() => {
        "manual": manual,
        "intelligence": intelligence,
        "endurance": endurance,
        "total": total,
      };
}

class Missions {
  int? missions;
  Contracts? contracts;
  int? credits;

  Missions({
    this.missions,
    this.contracts,
    this.credits,
  });

  factory Missions.fromJson(Map<String, dynamic> json) => Missions(
        missions: json["missions"],
        contracts: json["contracts"] == null ? null : Contracts.fromJson(json["contracts"]),
        credits: json["credits"],
      );

  Map<String, dynamic> toJson() => {
        "missions": missions,
        "contracts": contracts?.toJson(),
        "credits": credits,
      };
}

class Contracts {
  int? total;
  int? duke;

  Contracts({
    this.total,
    this.duke,
  });

  factory Contracts.fromJson(Map<String, dynamic> json) => Contracts(
        total: json["total"],
        duke: json["duke"],
      );

  Map<String, dynamic> toJson() => {
        "total": total,
        "duke": duke,
      };
}

class PersonalstatsNetworth {
  int? total;
  int? wallet;
  int? vaults;
  int? bank;
  int? overseasBank;
  int? points;
  int? inventory;
  int? displayCase;
  int? bazaar;
  int? itemMarket;
  int? property;
  int? stockMarket;
  int? auctionHouse;
  int? bookie;
  int? company;
  int? enlistedCars;
  int? piggyBank;
  int? pending;
  int? loans;
  int? unpaidFees;

  PersonalstatsNetworth({
    this.total,
    this.wallet,
    this.vaults,
    this.bank,
    this.overseasBank,
    this.points,
    this.inventory,
    this.displayCase,
    this.bazaar,
    this.itemMarket,
    this.property,
    this.stockMarket,
    this.auctionHouse,
    this.bookie,
    this.company,
    this.enlistedCars,
    this.piggyBank,
    this.pending,
    this.loans,
    this.unpaidFees,
  });

  factory PersonalstatsNetworth.fromJson(Map<String, dynamic> json) => PersonalstatsNetworth(
        total: json["total"],
        wallet: json["wallet"],
        vaults: json["vaults"],
        bank: json["bank"],
        overseasBank: json["overseas_bank"],
        points: json["points"],
        inventory: json["inventory"],
        displayCase: json["display_case"],
        bazaar: json["bazaar"],
        itemMarket: json["item_market"],
        property: json["property"],
        stockMarket: json["stock_market"],
        auctionHouse: json["auction_house"],
        bookie: json["bookie"],
        company: json["company"],
        enlistedCars: json["enlisted_cars"],
        piggyBank: json["piggy_bank"],
        pending: json["pending"],
        loans: json["loans"],
        unpaidFees: json["unpaid_fees"],
      );

  Map<String, dynamic> toJson() => {
        "total": total,
        "wallet": wallet,
        "vaults": vaults,
        "bank": bank,
        "overseas_bank": overseasBank,
        "points": points,
        "inventory": inventory,
        "display_case": displayCase,
        "bazaar": bazaar,
        "item_market": itemMarket,
        "property": property,
        "stock_market": stockMarket,
        "auction_house": auctionHouse,
        "bookie": bookie,
        "company": company,
        "enlisted_cars": enlistedCars,
        "piggy_bank": piggyBank,
        "pending": pending,
        "loans": loans,
        "unpaid_fees": unpaidFees,
      };
}

class Other {
  Activity? activity;
  int? awards;
  int? meritsBought;
  Refills? refills;
  int? donatorDays;
  int? rankedWarWins;

  Other({
    this.activity,
    this.awards,
    this.meritsBought,
    this.refills,
    this.donatorDays,
    this.rankedWarWins,
  });

  factory Other.fromJson(Map<String, dynamic> json) => Other(
        activity: json["activity"] == null ? null : Activity.fromJson(json["activity"]),
        awards: json["awards"],
        meritsBought: json["merits_bought"],
        refills: json["refills"] == null ? null : Refills.fromJson(json["refills"]),
        donatorDays: json["donator_days"],
        rankedWarWins: json["ranked_war_wins"],
      );

  Map<String, dynamic> toJson() => {
        "activity": activity?.toJson(),
        "awards": awards,
        "merits_bought": meritsBought,
        "refills": refills?.toJson(),
        "donator_days": donatorDays,
        "ranked_war_wins": rankedWarWins,
      };
}

class Activity {
  int? time;
  Streak? streak;

  Activity({
    this.time,
    this.streak,
  });

  factory Activity.fromJson(Map<String, dynamic> json) => Activity(
        time: json["time"],
        streak: json["streak"] == null ? null : Streak.fromJson(json["streak"]),
      );

  Map<String, dynamic> toJson() => {
        "time": time,
        "streak": streak?.toJson(),
      };
}

class Refills {
  int? energy;
  int? nerve;
  int? token;

  Refills({
    this.energy,
    this.nerve,
    this.token,
  });

  factory Refills.fromJson(Map<String, dynamic> json) => Refills(
        energy: json["energy"],
        nerve: json["nerve"],
        token: json["token"],
      );

  Map<String, dynamic> toJson() => {
        "energy": energy,
        "nerve": nerve,
        "token": token,
      };
}

class Racing {
  int? skill;
  int? points;
  Races? races;

  Racing({
    this.skill,
    this.points,
    this.races,
  });

  factory Racing.fromJson(Map<String, dynamic> json) => Racing(
        skill: json["skill"],
        points: json["points"],
        races: json["races"] == null ? null : Races.fromJson(json["races"]),
      );

  Map<String, dynamic> toJson() => {
        "skill": skill,
        "points": points,
        "races": races?.toJson(),
      };
}

class Races {
  int? entered;
  int? won;

  Races({
    this.entered,
    this.won,
  });

  factory Races.fromJson(Map<String, dynamic> json) => Races(
        entered: json["entered"],
        won: json["won"],
      );

  Map<String, dynamic> toJson() => {
        "entered": entered,
        "won": won,
      };
}

class Trading {
  TradingItems? items;
  int? trades;
  Points? points;
  TradingBazaar? bazaar;

  Trading({
    this.items,
    this.trades,
    this.points,
    this.bazaar,
  });

  factory Trading.fromJson(Map<String, dynamic> json) => Trading(
        items: json["items"] == null ? null : TradingItems.fromJson(json["items"]),
        trades: json["trades"],
        points: json["points"] == null ? null : Points.fromJson(json["points"]),
        bazaar: json["bazaar"] == null ? null : TradingBazaar.fromJson(json["bazaar"]),
      );

  Map<String, dynamic> toJson() => {
        "items": items?.toJson(),
        "trades": trades,
        "points": points?.toJson(),
        "bazaar": bazaar?.toJson(),
      };
}

class TradingBazaar {
  int? customers;
  int? sales;
  int? profit;

  TradingBazaar({
    this.customers,
    this.sales,
    this.profit,
  });

  factory TradingBazaar.fromJson(Map<String, dynamic> json) => TradingBazaar(
        customers: json["customers"],
        sales: json["sales"],
        profit: json["profit"],
      );

  Map<String, dynamic> toJson() => {
        "customers": customers,
        "sales": sales,
        "profit": profit,
      };
}

class TradingItems {
  Bought? bought;
  Auctions? auctions;
  int? sent;

  TradingItems({
    this.bought,
    this.auctions,
    this.sent,
  });

  factory TradingItems.fromJson(Map<String, dynamic> json) => TradingItems(
        bought: json["bought"] == null ? null : Bought.fromJson(json["bought"]),
        auctions: json["auctions"] == null ? null : Auctions.fromJson(json["auctions"]),
        sent: json["sent"],
      );

  Map<String, dynamic> toJson() => {
        "bought": bought?.toJson(),
        "auctions": auctions?.toJson(),
        "sent": sent,
      };
}

class Auctions {
  int? won;
  int? sold;

  Auctions({
    this.won,
    this.sold,
  });

  factory Auctions.fromJson(Map<String, dynamic> json) => Auctions(
        won: json["won"],
        sold: json["sold"],
      );

  Map<String, dynamic> toJson() => {
        "won": won,
        "sold": sold,
      };
}

class Bought {
  int? market;
  int? shops;

  Bought({
    this.market,
    this.shops,
  });

  factory Bought.fromJson(Map<String, dynamic> json) => Bought(
        market: json["market"],
        shops: json["shops"],
      );

  Map<String, dynamic> toJson() => {
        "market": market,
        "shops": shops,
      };
}

class Points {
  int? bought;
  int? sold;

  Points({
    this.bought,
    this.sold,
  });

  factory Points.fromJson(Map<String, dynamic> json) => Points(
        bought: json["bought"],
        sold: json["sold"],
      );

  Map<String, dynamic> toJson() => {
        "bought": bought,
        "sold": sold,
      };
}

class Travel {
  int? total;
  int? timeSpent;
  int? itemsBought;
  Hunting? hunting;
  int? attacksWon;
  int? defendsLost;
  int? argentina;
  int? canada;
  int? caymanIslands;
  int? china;
  int? hawaii;
  int? japan;
  int? mexico;
  int? unitedArabEmirates;
  int? unitedKingdom;
  int? southAfrica;
  int? switzerland;

  Travel({
    this.total,
    this.timeSpent,
    this.itemsBought,
    this.hunting,
    this.attacksWon,
    this.defendsLost,
    this.argentina,
    this.canada,
    this.caymanIslands,
    this.china,
    this.hawaii,
    this.japan,
    this.mexico,
    this.unitedArabEmirates,
    this.unitedKingdom,
    this.southAfrica,
    this.switzerland,
  });

  factory Travel.fromJson(Map<String, dynamic> json) => Travel(
        total: json["total"],
        timeSpent: json["time_spent"],
        itemsBought: json["items_bought"],
        hunting: json["hunting"] == null ? null : Hunting.fromJson(json["hunting"]),
        attacksWon: json["attacks_won"],
        defendsLost: json["defends_lost"],
        argentina: json["argentina"],
        canada: json["canada"],
        caymanIslands: json["cayman_islands"],
        china: json["china"],
        hawaii: json["hawaii"],
        japan: json["japan"],
        mexico: json["mexico"],
        unitedArabEmirates: json["united_arab_emirates"],
        unitedKingdom: json["united_kingdom"],
        southAfrica: json["south_africa"],
        switzerland: json["switzerland"],
      );

  Map<String, dynamic> toJson() => {
        "total": total,
        "time_spent": timeSpent,
        "items_bought": itemsBought,
        "hunting": hunting?.toJson(),
        "attacks_won": attacksWon,
        "defends_lost": defendsLost,
        "argentina": argentina,
        "canada": canada,
        "cayman_islands": caymanIslands,
        "china": china,
        "hawaii": hawaii,
        "japan": japan,
        "mexico": mexico,
        "united_arab_emirates": unitedArabEmirates,
        "united_kingdom": unitedKingdom,
        "south_africa": southAfrica,
        "switzerland": switzerland,
      };
}

class Hunting {
  int? skill;

  Hunting({
    this.skill,
  });

  factory Hunting.fromJson(Map<String, dynamic> json) => Hunting(
        skill: json["skill"],
      );

  Map<String, dynamic> toJson() => {
        "skill": skill,
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
