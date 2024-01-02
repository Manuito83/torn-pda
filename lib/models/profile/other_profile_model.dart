// To parse this JSON data, do
//
//     final otherProfileModel = otherProfileModelFromJson(jsonString);

// Dart imports:
import 'dart:convert';

import 'package:torn_pda/models/profile/own_profile_basic.dart';

OtherProfileModel otherProfileModelFromJson(String str) => OtherProfileModel.fromJson(json.decode(str));

String otherProfileModelToJson(OtherProfileModel data) => json.encode(data.toJson());

class OtherProfileModel {
  OtherProfileModel({
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
    this.life,
    this.status,
    this.job,
    this.faction,
    this.married,
    //this.basicicons,
    this.states,
    this.lastAction,
    this.criminalrecord,
    this.personalstats,
    this.bazaar,
  });

  String? rank;
  int? level;
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
  dynamic competition;
  Life? life;
  Status? status;
  Job? job;
  Faction? faction;
  Married? married;
  //Basicicons basicicons;
  States? states;
  LastAction? lastAction;
  Criminalrecord? criminalrecord;
  Personalstats? personalstats;
  List<Bazaar>? bazaar;

  factory OtherProfileModel.fromJson(Map<String, dynamic> json) => OtherProfileModel(
        rank: json["rank"],
        level: json["level"],
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
        competition: json["competition"],
        life: json["life"] == null ? null : Life.fromJson(json["life"]),
        status: json["status"] == null ? null : Status.fromJson(json["status"]),
        job: json["job"] == null ? null : Job.fromJson(json["job"]),
        faction: json["faction"] == null ? null : Faction.fromJson(json["faction"]),
        married: json["married"] == null ? null : Married.fromJson(json["married"]),
        //basicicons: json["basicicons"] == null ? null : Basicicons.fromJson(json["basicicons"]),
        states: json["states"] == null ? null : States.fromJson(json["states"]),
        lastAction: json["last_action"] == null ? null : LastAction.fromJson(json["last_action"]),
        criminalrecord: json["criminalrecord"] == null ? null : Criminalrecord.fromJson(json["criminalrecord"]),
        personalstats: json["personalstats"] == null ? null : Personalstats.fromJson(json["personalstats"]),
        bazaar: json["bazaar"] == null ? null : List<Bazaar>.from(json["bazaar"].map((x) => Bazaar.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "rank": rank,
        "level": level,
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
        "competition": competition,
        "life": life?.toJson(),
        "status": status?.toJson(),
        "job": job?.toJson(),
        "faction": faction?.toJson(),
        "married": married?.toJson(),
        //"basicicons": basicicons == null ? null : basicicons.toJson(),
        "states": states?.toJson(),
        "last_action": lastAction?.toJson(),
        "criminalrecord": criminalrecord?.toJson(),
        "personalstats": personalstats?.toJson(),
        "bazaar": bazaar == null ? null : List<dynamic>.from(bazaar!.map((x) => x.toJson())),
      };
}

/*
class Basicicons {
  Basicicons({
    this.icon6,
    this.icon8,
    this.icon27,
    this.icon9,
    this.icon71,
  });

  String icon6;
  String icon8;
  String icon27;
  String icon9;
  String icon71;

  factory Basicicons.fromJson(Map<String, dynamic> json) => Basicicons(
    icon6: json["icon6"] == null ? null : json["icon6"],
    icon8: json["icon8"] == null ? null : json["icon8"],
    icon27: json["icon27"] == null ? null : json["icon27"],
    icon9: json["icon9"] == null ? null : json["icon9"],
    icon71: json["icon71"] == null ? null : json["icon71"],
  );

  Map<String, dynamic> toJson() => {
    "icon6": icon6 == null ? null : icon6,
    "icon8": icon8 == null ? null : icon8,
    "icon27": icon27 == null ? null : icon27,
    "icon9": icon9 == null ? null : icon9,
    "icon71": icon71 == null ? null : icon71,
  };
}
*/

class Bazaar {
  Bazaar({
    this.id,
    this.name,
    this.type,
    this.quantity,
    this.price,
    this.marketPrice,
  });

  int? id;
  String? name;
  String? type;
  int? quantity;
  dynamic price; // Sometimes returns a double (?)
  dynamic marketPrice;

  factory Bazaar.fromJson(Map<String, dynamic> json) => Bazaar(
        id: json["ID"],
        name: json["name"],
        type: json["type"],
        quantity: json["quantity"],
        price: json["price"],
        marketPrice: json["market_price"],
      );

  Map<String, dynamic> toJson() => {
        "ID": id,
        "name": name,
        "type": type,
        "quantity": quantity,
        "price": price,
        "market_price": marketPrice,
      };
}

class Criminalrecord {
  Criminalrecord({
    this.sellingIllegalProducts,
    this.theft,
    this.autoTheft,
    this.drugDeals,
    this.computerCrimes,
    this.murder,
    this.fraudCrimes,
    this.other,
    this.total,
  });

  int? sellingIllegalProducts;
  int? theft;
  int? autoTheft;
  int? drugDeals;
  int? computerCrimes;
  int? murder;
  int? fraudCrimes;
  int? other;
  int? total;

  factory Criminalrecord.fromJson(Map<String, dynamic> json) => Criminalrecord(
        sellingIllegalProducts: json["selling_illegal_products"],
        theft: json["theft"],
        autoTheft: json["auto_theft"],
        drugDeals: json["drug_deals"],
        computerCrimes: json["computer_crimes"],
        murder: json["murder"],
        fraudCrimes: json["fraud_crimes"],
        other: json["other"],
        total: json["total"],
      );

  Map<String, dynamic> toJson() => {
        "selling_illegal_products": sellingIllegalProducts,
        "theft": theft,
        "auto_theft": autoTheft,
        "drug_deals": drugDeals,
        "computer_crimes": computerCrimes,
        "murder": murder,
        "fraud_crimes": fraudCrimes,
        "other": other,
        "total": total,
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
        companyName: json["company_name"]?.toString(),
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

class Personalstats {
  Personalstats({
    this.useractivity,
    this.itemsbought,
    this.pointsbought,
    this.itemsboughtabroad,
    this.weaponsbought,
    this.itemssent,
    this.auctionswon,
    this.auctionsells,
    this.attackswon,
    this.attackslost,
    this.attacksdraw,
    this.bestkillstreak,
    this.moneymugged,
    this.attacksstealthed,
    this.attackhits,
    this.attackmisses,
    this.attackdamage,
    this.attackcriticalhits,
    this.respectforfaction,
    this.onehitkills,
    this.defendswon,
    this.defendslost,
    this.defendsstalemated,
    this.bestdamage,
    this.roundsfired,
    this.yourunaway,
    this.theyrunaway,
    this.highestbeaten,
    this.peoplebusted,
    this.failedbusts,
    this.peoplebought,
    this.peopleboughtspent,
    this.virusescoded,
    this.cityfinds,
    this.traveltimes,
    this.bountiesplaced,
    this.bountiesreceived,
    this.bountiescollected,
    this.totalbountyreward,
    this.revives,
    this.revivesreceived,
    this.medicalitemsused,
    this.statenhancersused,
    this.refills,
    this.trainsreceived,
    this.totalbountyspent,
    this.drugsused,
    this.overdosed,
    this.meritsbought,
    this.timesloggedin,
    this.personalsplaced,
    this.classifiedadsplaced,
    this.mailssent,
    this.friendmailssent,
    this.factionmailssent,
    this.companymailssent,
    this.spousemailssent,
    this.largestmug,
    this.cantaken,
    this.exttaken,
    this.kettaken,
    this.lsdtaken,
    this.opitaken,
    this.shrtaken,
    this.spetaken,
    this.pcptaken,
    this.xantaken,
    this.victaken,
    this.chahits,
    this.heahits,
    this.axehits,
    this.grehits,
    this.machits,
    this.pishits,
    this.rifhits,
    this.shohits,
    this.smghits,
    this.piehits,
    this.slahits,
    this.argtravel,
    this.mextravel,
    this.dubtravel,
    this.hawtravel,
    this.japtravel,
    this.lontravel,
    this.soutravel,
    this.switravel,
    this.chitravel,
    this.cantravel,
    this.dumpfinds,
    this.dumpsearches,
    this.itemsdumped,
    this.daysbeendonator,
    this.caytravel,
    this.jailed,
    this.hospital,
    this.attacksassisted,
    this.bloodwithdrawn,
    this.networth,
    this.missionscompleted,
    this.contractscompleted,
    this.dukecontractscompleted,
    this.missioncreditsearned,
    this.consumablesused,
    this.candyused,
    this.alcoholused,
    this.energydrinkused,
    this.nerverefills,
    this.unarmoredwon,
    this.h2Hhits,
    this.organisedcrimes,
    this.territorytime,
    this.territoryjoins,
    this.arrestsmade,
    this.tokenrefills,
    this.booksread,
    this.traveltime,
    this.boostersused,
    this.rehabs,
    this.rehabcost,
    this.awards,
    this.receivedbountyvalue,
    this.raceswon,
    this.racesentered,
    this.racingpointsearned,
    this.specialammoused,
    this.cityitemsbought,
    this.hollowammoused,
    this.tracerammoused,
    this.piercingammoused,
    this.incendiaryammoused,
    this.attackswonabroad,
    this.defendslostabroad,
    this.retals,
    this.elo,
    this.reviveskill,
    this.activestreak,
    this.bestactivestreak,
    this.jobpointsused,
  });

  int? useractivity;
  int? itemsbought;
  int? pointsbought;
  int? itemsboughtabroad;
  int? weaponsbought;
  int? itemssent;
  int? auctionswon;
  int? auctionsells;
  int? attackswon;
  int? attackslost;
  int? attacksdraw;
  int? bestkillstreak;
  int? moneymugged;
  int? attacksstealthed;
  int? attackhits;
  int? attackmisses;
  int? attackdamage;
  int? attackcriticalhits;
  int? respectforfaction;
  int? onehitkills;
  int? defendswon;
  int? defendslost;
  int? defendsstalemated;
  int? bestdamage;
  int? roundsfired;
  int? yourunaway;
  int? theyrunaway;
  int? highestbeaten;
  int? peoplebusted;
  int? failedbusts;
  int? peoplebought;
  int? peopleboughtspent;
  int? virusescoded;
  int? cityfinds;
  int? traveltimes;
  int? bountiesplaced;
  int? bountiesreceived;
  int? bountiescollected;
  int? totalbountyreward;
  int? revives;
  int? revivesreceived;
  int? medicalitemsused;
  int? statenhancersused;
  int? refills;
  int? trainsreceived;
  int? totalbountyspent;
  int? drugsused;
  int? overdosed;
  int? meritsbought;
  int? timesloggedin;
  int? personalsplaced;
  int? classifiedadsplaced;
  int? mailssent;
  int? friendmailssent;
  int? factionmailssent;
  int? companymailssent;
  int? spousemailssent;
  int? largestmug;
  int? cantaken;
  int? exttaken;
  int? kettaken;
  int? lsdtaken;
  int? opitaken;
  int? shrtaken;
  int? spetaken;
  int? pcptaken;
  int? xantaken;
  int? victaken;
  int? chahits;
  int? heahits;
  int? axehits;
  int? grehits;
  int? machits;
  int? pishits;
  int? rifhits;
  int? shohits;
  int? smghits;
  int? piehits;
  int? slahits;
  int? argtravel;
  int? mextravel;
  int? dubtravel;
  int? hawtravel;
  int? japtravel;
  int? lontravel;
  int? soutravel;
  int? switravel;
  int? chitravel;
  int? cantravel;
  int? dumpfinds;
  int? dumpsearches;
  int? itemsdumped;
  int? daysbeendonator;
  int? caytravel;
  int? jailed;
  int? hospital;
  int? attacksassisted;
  int? bloodwithdrawn;
  int? networth;
  int? missionscompleted;
  int? contractscompleted;
  int? dukecontractscompleted;
  int? missioncreditsearned;
  int? consumablesused;
  int? candyused;
  int? alcoholused;
  int? energydrinkused;
  int? nerverefills;
  int? unarmoredwon;
  int? h2Hhits;
  int? organisedcrimes;
  int? territorytime;
  int? territoryjoins;
  int? arrestsmade;
  int? tokenrefills;
  int? booksread;
  int? traveltime;
  int? boostersused;
  int? rehabs;
  int? rehabcost;
  int? awards;
  int? receivedbountyvalue;
  int? raceswon;
  int? racesentered;
  int? racingpointsearned;
  int? specialammoused;
  int? cityitemsbought;
  int? hollowammoused;
  int? tracerammoused;
  int? piercingammoused;
  int? incendiaryammoused;
  int? attackswonabroad;
  int? defendslostabroad;
  int? retals;
  int? elo;
  int? reviveskill;
  int? activestreak;
  int? bestactivestreak;
  int? jobpointsused;

  factory Personalstats.fromJson(Map<String, dynamic> json) => Personalstats(
        useractivity: json["useractivity"],
        itemsbought: json["itemsbought"],
        pointsbought: json["pointsbought"],
        itemsboughtabroad: json["itemsboughtabroad"],
        weaponsbought: json["weaponsbought"],
        itemssent: json["itemssent"],
        auctionswon: json["auctionswon"],
        auctionsells: json["auctionsells"],
        attackswon: json["attackswon"],
        attackslost: json["attackslost"],
        attacksdraw: json["attacksdraw"],
        bestkillstreak: json["bestkillstreak"],
        moneymugged: json["moneymugged"],
        attacksstealthed: json["attacksstealthed"],
        attackhits: json["attackhits"],
        attackmisses: json["attackmisses"],
        attackdamage: json["attackdamage"],
        attackcriticalhits: json["attackcriticalhits"],
        respectforfaction: json["respectforfaction"],
        onehitkills: json["onehitkills"],
        defendswon: json["defendswon"],
        defendslost: json["defendslost"],
        defendsstalemated: json["defendsstalemated"],
        bestdamage: json["bestdamage"],
        roundsfired: json["roundsfired"],
        yourunaway: json["yourunaway"],
        theyrunaway: json["theyrunaway"],
        highestbeaten: json["highestbeaten"],
        peoplebusted: json["peoplebusted"],
        failedbusts: json["failedbusts"],
        peoplebought: json["peoplebought"],
        peopleboughtspent: json["peopleboughtspent"],
        virusescoded: json["virusescoded"],
        cityfinds: json["cityfinds"],
        traveltimes: json["traveltimes"],
        bountiesplaced: json["bountiesplaced"],
        bountiesreceived: json["bountiesreceived"],
        bountiescollected: json["bountiescollected"],
        totalbountyreward: json["totalbountyreward"],
        revives: json["revives"],
        revivesreceived: json["revivesreceived"],
        medicalitemsused: json["medicalitemsused"],
        statenhancersused: json["statenhancersused"],
        refills: json["refills"],
        trainsreceived: json["trainsreceived"],
        totalbountyspent: json["totalbountyspent"],
        drugsused: json["drugsused"],
        overdosed: json["overdosed"],
        meritsbought: json["meritsbought"],
        timesloggedin: json["timesloggedin"],
        personalsplaced: json["personalsplaced"],
        classifiedadsplaced: json["classifiedadsplaced"],
        mailssent: json["mailssent"],
        friendmailssent: json["friendmailssent"],
        factionmailssent: json["factionmailssent"],
        companymailssent: json["companymailssent"],
        spousemailssent: json["spousemailssent"],
        largestmug: json["largestmug"],
        cantaken: json["cantaken"],
        exttaken: json["exttaken"],
        kettaken: json["kettaken"],
        lsdtaken: json["lsdtaken"],
        opitaken: json["opitaken"],
        shrtaken: json["shrtaken"],
        spetaken: json["spetaken"],
        pcptaken: json["pcptaken"],
        xantaken: json["xantaken"],
        victaken: json["victaken"],
        chahits: json["chahits"],
        heahits: json["heahits"],
        axehits: json["axehits"],
        grehits: json["grehits"],
        machits: json["machits"],
        pishits: json["pishits"],
        rifhits: json["rifhits"],
        shohits: json["shohits"],
        smghits: json["smghits"],
        piehits: json["piehits"],
        slahits: json["slahits"],
        argtravel: json["argtravel"],
        mextravel: json["mextravel"],
        dubtravel: json["dubtravel"],
        hawtravel: json["hawtravel"],
        japtravel: json["japtravel"],
        lontravel: json["lontravel"],
        soutravel: json["soutravel"],
        switravel: json["switravel"],
        chitravel: json["chitravel"],
        cantravel: json["cantravel"],
        dumpfinds: json["dumpfinds"],
        dumpsearches: json["dumpsearches"],
        itemsdumped: json["itemsdumped"],
        daysbeendonator: json["daysbeendonator"],
        caytravel: json["caytravel"],
        jailed: json["jailed"],
        hospital: json["hospital"],
        attacksassisted: json["attacksassisted"],
        bloodwithdrawn: json["bloodwithdrawn"],
        networth: json["networth"],
        missionscompleted: json["missionscompleted"],
        contractscompleted: json["contractscompleted"],
        dukecontractscompleted: json["dukecontractscompleted"],
        missioncreditsearned: json["missioncreditsearned"],
        consumablesused: json["consumablesused"],
        candyused: json["candyused"],
        alcoholused: json["alcoholused"],
        energydrinkused: json["energydrinkused"],
        nerverefills: json["nerverefills"],
        unarmoredwon: json["unarmoredwon"],
        h2Hhits: json["h2hhits"],
        organisedcrimes: json["organisedcrimes"],
        territorytime: json["territorytime"],
        territoryjoins: json["territoryjoins"],
        arrestsmade: json["arrestsmade"],
        tokenrefills: json["tokenrefills"],
        booksread: json["booksread"],
        traveltime: json["traveltime"],
        boostersused: json["boostersused"],
        rehabs: json["rehabs"],
        rehabcost: json["rehabcost"],
        awards: json["awards"],
        receivedbountyvalue: json["receivedbountyvalue"],
        raceswon: json["raceswon"],
        racesentered: json["racesentered"],
        racingpointsearned: json["racingpointsearned"],
        specialammoused: json["specialammoused"],
        cityitemsbought: json["cityitemsbought"],
        hollowammoused: json["hollowammoused"],
        tracerammoused: json["tracerammoused"],
        piercingammoused: json["piercingammoused"],
        incendiaryammoused: json["incendiaryammoused"],
        attackswonabroad: json["attackswonabroad"],
        defendslostabroad: json["defendslostabroad"],
        retals: json["retals"],
        elo: json["elo"],
        reviveskill: json["reviveskill"],
        activestreak: json["activestreak"],
        bestactivestreak: json["bestactivestreak"],
        jobpointsused: json["jobpointsused"],
      );

  Map<String, dynamic> toJson() => {
        "useractivity": useractivity,
        "itemsbought": itemsbought,
        "pointsbought": pointsbought,
        "itemsboughtabroad": itemsboughtabroad,
        "weaponsbought": weaponsbought,
        "itemssent": itemssent,
        "auctionswon": auctionswon,
        "auctionsells": auctionsells,
        "attackswon": attackswon,
        "attackslost": attackslost,
        "attacksdraw": attacksdraw,
        "bestkillstreak": bestkillstreak,
        "moneymugged": moneymugged,
        "attacksstealthed": attacksstealthed,
        "attackhits": attackhits,
        "attackmisses": attackmisses,
        "attackdamage": attackdamage,
        "attackcriticalhits": attackcriticalhits,
        "respectforfaction": respectforfaction,
        "onehitkills": onehitkills,
        "defendswon": defendswon,
        "defendslost": defendslost,
        "defendsstalemated": defendsstalemated,
        "bestdamage": bestdamage,
        "roundsfired": roundsfired,
        "yourunaway": yourunaway,
        "theyrunaway": theyrunaway,
        "highestbeaten": highestbeaten,
        "peoplebusted": peoplebusted,
        "failedbusts": failedbusts,
        "peoplebought": peoplebought,
        "peopleboughtspent": peopleboughtspent,
        "virusescoded": virusescoded,
        "cityfinds": cityfinds,
        "traveltimes": traveltimes,
        "bountiesplaced": bountiesplaced,
        "bountiesreceived": bountiesreceived,
        "bountiescollected": bountiescollected,
        "totalbountyreward": totalbountyreward,
        "revives": revives,
        "revivesreceived": revivesreceived,
        "medicalitemsused": medicalitemsused,
        "statenhancersused": statenhancersused,
        "refills": refills,
        "trainsreceived": trainsreceived,
        "totalbountyspent": totalbountyspent,
        "drugsused": drugsused,
        "overdosed": overdosed,
        "meritsbought": meritsbought,
        "timesloggedin": timesloggedin,
        "personalsplaced": personalsplaced,
        "classifiedadsplaced": classifiedadsplaced,
        "mailssent": mailssent,
        "friendmailssent": friendmailssent,
        "factionmailssent": factionmailssent,
        "companymailssent": companymailssent,
        "spousemailssent": spousemailssent,
        "largestmug": largestmug,
        "cantaken": cantaken,
        "exttaken": exttaken,
        "kettaken": kettaken,
        "lsdtaken": lsdtaken,
        "opitaken": opitaken,
        "shrtaken": shrtaken,
        "spetaken": spetaken,
        "pcptaken": pcptaken,
        "xantaken": xantaken,
        "victaken": victaken,
        "chahits": chahits,
        "heahits": heahits,
        "axehits": axehits,
        "grehits": grehits,
        "machits": machits,
        "pishits": pishits,
        "rifhits": rifhits,
        "shohits": shohits,
        "smghits": smghits,
        "piehits": piehits,
        "slahits": slahits,
        "argtravel": argtravel,
        "mextravel": mextravel,
        "dubtravel": dubtravel,
        "hawtravel": hawtravel,
        "japtravel": japtravel,
        "lontravel": lontravel,
        "soutravel": soutravel,
        "switravel": switravel,
        "chitravel": chitravel,
        "cantravel": cantravel,
        "dumpfinds": dumpfinds,
        "dumpsearches": dumpsearches,
        "itemsdumped": itemsdumped,
        "daysbeendonator": daysbeendonator,
        "caytravel": caytravel,
        "jailed": jailed,
        "hospital": hospital,
        "attacksassisted": attacksassisted,
        "bloodwithdrawn": bloodwithdrawn,
        "networth": networth,
        "missionscompleted": missionscompleted,
        "contractscompleted": contractscompleted,
        "dukecontractscompleted": dukecontractscompleted,
        "missioncreditsearned": missioncreditsearned,
        "consumablesused": consumablesused,
        "candyused": candyused,
        "alcoholused": alcoholused,
        "energydrinkused": energydrinkused,
        "nerverefills": nerverefills,
        "unarmoredwon": unarmoredwon,
        "h2hhits": h2Hhits,
        "organisedcrimes": organisedcrimes,
        "territorytime": territorytime,
        "territoryjoins": territoryjoins,
        "arrestsmade": arrestsmade,
        "tokenrefills": tokenrefills,
        "booksread": booksread,
        "traveltime": traveltime,
        "boostersused": boostersused,
        "rehabs": rehabs,
        "rehabcost": rehabcost,
        "awards": awards,
        "receivedbountyvalue": receivedbountyvalue,
        "raceswon": raceswon,
        "racesentered": racesentered,
        "racingpointsearned": racingpointsearned,
        "specialammoused": specialammoused,
        "cityitemsbought": cityitemsbought,
        "hollowammoused": hollowammoused,
        "tracerammoused": tracerammoused,
        "piercingammoused": piercingammoused,
        "incendiaryammoused": incendiaryammoused,
        "attackswonabroad": attackswonabroad,
        "defendslostabroad": defendslostabroad,
        "retals": retals,
        "elo": elo,
        "reviveskill": reviveskill,
        "activestreak": activestreak,
        "bestactivestreak": bestactivestreak,
        "jobpointsused": jobpointsused,
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
