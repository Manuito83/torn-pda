// To parse this JSON data, do
//
//     final otherProfileModel = otherProfileModelFromJson(jsonString);

// Dart imports:
import 'dart:convert';

import 'own_profile_basic.dart';

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
  Life life;
  Status status;
  Job job;
  Faction faction;
  Married married;
  //Basicicons basicicons;
  States states;
  LastAction lastAction;
  Criminalrecord criminalrecord;
  Personalstats personalstats;
  List<Bazaar> bazaar;

  factory OtherProfileModel.fromJson(Map<String, dynamic> json) => OtherProfileModel(
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
        "life": life == null ? null : life.toJson(),
        "status": status == null ? null : status.toJson(),
        "job": job == null ? null : job.toJson(),
        "faction": faction == null ? null : faction.toJson(),
        "married": married == null ? null : married.toJson(),
        //"basicicons": basicicons == null ? null : basicicons.toJson(),
        "states": states == null ? null : states.toJson(),
        "last_action": lastAction == null ? null : lastAction.toJson(),
        "criminalrecord": criminalrecord == null ? null : criminalrecord.toJson(),
        "personalstats": personalstats == null ? null : personalstats.toJson(),
        "bazaar": bazaar == null ? null : List<dynamic>.from(bazaar.map((x) => x.toJson())),
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

  int id;
  String name;
  String type;
  int quantity;
  int price;
  int marketPrice;

  factory Bazaar.fromJson(Map<String, dynamic> json) => Bazaar(
        id: json["ID"] == null ? null : json["ID"],
        name: json["name"] == null ? null : json["name"],
        type: json["type"] == null ? null : json["type"],
        quantity: json["quantity"] == null ? null : json["quantity"],
        price: json["price"] == null ? null : json["price"],
        marketPrice: json["market_price"] == null ? null : json["market_price"],
      );

  Map<String, dynamic> toJson() => {
        "ID": id == null ? null : id,
        "name": name == null ? null : name,
        "type": type == null ? null : type,
        "quantity": quantity == null ? null : quantity,
        "price": price == null ? null : price,
        "market_price": marketPrice == null ? null : marketPrice,
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

  int sellingIllegalProducts;
  int theft;
  int autoTheft;
  int drugDeals;
  int computerCrimes;
  int murder;
  int fraudCrimes;
  int other;
  int total;

  factory Criminalrecord.fromJson(Map<String, dynamic> json) => Criminalrecord(
        sellingIllegalProducts: json["selling_illegal_products"] == null ? null : json["selling_illegal_products"],
        theft: json["theft"] == null ? null : json["theft"],
        autoTheft: json["auto_theft"] == null ? null : json["auto_theft"],
        drugDeals: json["drug_deals"] == null ? null : json["drug_deals"],
        computerCrimes: json["computer_crimes"] == null ? null : json["computer_crimes"],
        murder: json["murder"] == null ? null : json["murder"],
        fraudCrimes: json["fraud_crimes"] == null ? null : json["fraud_crimes"],
        other: json["other"] == null ? null : json["other"],
        total: json["total"] == null ? null : json["total"],
      );

  Map<String, dynamic> toJson() => {
        "selling_illegal_products": sellingIllegalProducts == null ? null : sellingIllegalProducts,
        "theft": theft == null ? null : theft,
        "auto_theft": autoTheft == null ? null : autoTheft,
        "drug_deals": drugDeals == null ? null : drugDeals,
        "computer_crimes": computerCrimes == null ? null : computerCrimes,
        "murder": murder == null ? null : murder,
        "fraud_crimes": fraudCrimes == null ? null : fraudCrimes,
        "other": other == null ? null : other,
        "total": total == null ? null : total,
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
        factionTag: json["faction_tag"] == null ? null : json["faction_tag"],
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
        companyName: json["company_name"] == null ? null : json["company_name"].toString(),
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

  int useractivity;
  int itemsbought;
  int pointsbought;
  int itemsboughtabroad;
  int weaponsbought;
  int itemssent;
  int auctionswon;
  int auctionsells;
  int attackswon;
  int attackslost;
  int attacksdraw;
  int bestkillstreak;
  int moneymugged;
  int attacksstealthed;
  int attackhits;
  int attackmisses;
  int attackdamage;
  int attackcriticalhits;
  int respectforfaction;
  int onehitkills;
  int defendswon;
  int defendslost;
  int defendsstalemated;
  int bestdamage;
  int roundsfired;
  int yourunaway;
  int theyrunaway;
  int highestbeaten;
  int peoplebusted;
  int failedbusts;
  int peoplebought;
  int peopleboughtspent;
  int virusescoded;
  int cityfinds;
  int traveltimes;
  int bountiesplaced;
  int bountiesreceived;
  int bountiescollected;
  int totalbountyreward;
  int revives;
  int revivesreceived;
  int medicalitemsused;
  int statenhancersused;
  int refills;
  int trainsreceived;
  int totalbountyspent;
  int drugsused;
  int overdosed;
  int meritsbought;
  int timesloggedin;
  int personalsplaced;
  int classifiedadsplaced;
  int mailssent;
  int friendmailssent;
  int factionmailssent;
  int companymailssent;
  int spousemailssent;
  int largestmug;
  int cantaken;
  int exttaken;
  int kettaken;
  int lsdtaken;
  int opitaken;
  int shrtaken;
  int spetaken;
  int pcptaken;
  int xantaken;
  int victaken;
  int chahits;
  int heahits;
  int axehits;
  int grehits;
  int machits;
  int pishits;
  int rifhits;
  int shohits;
  int smghits;
  int piehits;
  int slahits;
  int argtravel;
  int mextravel;
  int dubtravel;
  int hawtravel;
  int japtravel;
  int lontravel;
  int soutravel;
  int switravel;
  int chitravel;
  int cantravel;
  int dumpfinds;
  int dumpsearches;
  int itemsdumped;
  int daysbeendonator;
  int caytravel;
  int jailed;
  int hospital;
  int attacksassisted;
  int bloodwithdrawn;
  int networth;
  int missionscompleted;
  int contractscompleted;
  int dukecontractscompleted;
  int missioncreditsearned;
  int consumablesused;
  int candyused;
  int alcoholused;
  int energydrinkused;
  int nerverefills;
  int unarmoredwon;
  int h2Hhits;
  int organisedcrimes;
  int territorytime;
  int territoryjoins;
  int arrestsmade;
  int tokenrefills;
  int booksread;
  int traveltime;
  int boostersused;
  int rehabs;
  int rehabcost;
  int awards;
  int receivedbountyvalue;
  int raceswon;
  int racesentered;
  int racingpointsearned;
  int specialammoused;
  int cityitemsbought;
  int hollowammoused;
  int tracerammoused;
  int piercingammoused;
  int incendiaryammoused;
  int attackswonabroad;
  int defendslostabroad;
  int retals;
  int elo;
  int reviveskill;
  int activestreak;
  int bestactivestreak;
  int jobpointsused;

  factory Personalstats.fromJson(Map<String, dynamic> json) => Personalstats(
        useractivity: json["useractivity"] == null ? null : json["useractivity"],
        itemsbought: json["itemsbought"] == null ? null : json["itemsbought"],
        pointsbought: json["pointsbought"] == null ? null : json["pointsbought"],
        itemsboughtabroad: json["itemsboughtabroad"] == null ? null : json["itemsboughtabroad"],
        weaponsbought: json["weaponsbought"] == null ? null : json["weaponsbought"],
        itemssent: json["itemssent"] == null ? null : json["itemssent"],
        auctionswon: json["auctionswon"] == null ? null : json["auctionswon"],
        auctionsells: json["auctionsells"] == null ? null : json["auctionsells"],
        attackswon: json["attackswon"] == null ? null : json["attackswon"],
        attackslost: json["attackslost"] == null ? null : json["attackslost"],
        attacksdraw: json["attacksdraw"] == null ? null : json["attacksdraw"],
        bestkillstreak: json["bestkillstreak"] == null ? null : json["bestkillstreak"],
        moneymugged: json["moneymugged"] == null ? null : json["moneymugged"],
        attacksstealthed: json["attacksstealthed"] == null ? null : json["attacksstealthed"],
        attackhits: json["attackhits"] == null ? null : json["attackhits"],
        attackmisses: json["attackmisses"] == null ? null : json["attackmisses"],
        attackdamage: json["attackdamage"] == null ? null : json["attackdamage"],
        attackcriticalhits: json["attackcriticalhits"] == null ? null : json["attackcriticalhits"],
        respectforfaction: json["respectforfaction"] == null ? null : json["respectforfaction"],
        onehitkills: json["onehitkills"] == null ? null : json["onehitkills"],
        defendswon: json["defendswon"] == null ? null : json["defendswon"],
        defendslost: json["defendslost"] == null ? null : json["defendslost"],
        defendsstalemated: json["defendsstalemated"] == null ? null : json["defendsstalemated"],
        bestdamage: json["bestdamage"] == null ? null : json["bestdamage"],
        roundsfired: json["roundsfired"] == null ? null : json["roundsfired"],
        yourunaway: json["yourunaway"] == null ? null : json["yourunaway"],
        theyrunaway: json["theyrunaway"] == null ? null : json["theyrunaway"],
        highestbeaten: json["highestbeaten"] == null ? null : json["highestbeaten"],
        peoplebusted: json["peoplebusted"] == null ? null : json["peoplebusted"],
        failedbusts: json["failedbusts"] == null ? null : json["failedbusts"],
        peoplebought: json["peoplebought"] == null ? null : json["peoplebought"],
        peopleboughtspent: json["peopleboughtspent"] == null ? null : json["peopleboughtspent"],
        virusescoded: json["virusescoded"] == null ? null : json["virusescoded"],
        cityfinds: json["cityfinds"] == null ? null : json["cityfinds"],
        traveltimes: json["traveltimes"] == null ? null : json["traveltimes"],
        bountiesplaced: json["bountiesplaced"] == null ? null : json["bountiesplaced"],
        bountiesreceived: json["bountiesreceived"] == null ? null : json["bountiesreceived"],
        bountiescollected: json["bountiescollected"] == null ? null : json["bountiescollected"],
        totalbountyreward: json["totalbountyreward"] == null ? null : json["totalbountyreward"],
        revives: json["revives"] == null ? null : json["revives"],
        revivesreceived: json["revivesreceived"] == null ? null : json["revivesreceived"],
        medicalitemsused: json["medicalitemsused"] == null ? null : json["medicalitemsused"],
        statenhancersused: json["statenhancersused"] == null ? null : json["statenhancersused"],
        refills: json["refills"] == null ? null : json["refills"],
        trainsreceived: json["trainsreceived"] == null ? null : json["trainsreceived"],
        totalbountyspent: json["totalbountyspent"] == null ? null : json["totalbountyspent"],
        drugsused: json["drugsused"] == null ? null : json["drugsused"],
        overdosed: json["overdosed"] == null ? null : json["overdosed"],
        meritsbought: json["meritsbought"] == null ? null : json["meritsbought"],
        timesloggedin: json["timesloggedin"] == null ? null : json["timesloggedin"],
        personalsplaced: json["personalsplaced"] == null ? null : json["personalsplaced"],
        classifiedadsplaced: json["classifiedadsplaced"] == null ? null : json["classifiedadsplaced"],
        mailssent: json["mailssent"] == null ? null : json["mailssent"],
        friendmailssent: json["friendmailssent"] == null ? null : json["friendmailssent"],
        factionmailssent: json["factionmailssent"] == null ? null : json["factionmailssent"],
        companymailssent: json["companymailssent"] == null ? null : json["companymailssent"],
        spousemailssent: json["spousemailssent"] == null ? null : json["spousemailssent"],
        largestmug: json["largestmug"] == null ? null : json["largestmug"],
        cantaken: json["cantaken"] == null ? null : json["cantaken"],
        exttaken: json["exttaken"] == null ? null : json["exttaken"],
        kettaken: json["kettaken"] == null ? null : json["kettaken"],
        lsdtaken: json["lsdtaken"] == null ? null : json["lsdtaken"],
        opitaken: json["opitaken"] == null ? null : json["opitaken"],
        shrtaken: json["shrtaken"] == null ? null : json["shrtaken"],
        spetaken: json["spetaken"] == null ? null : json["spetaken"],
        pcptaken: json["pcptaken"] == null ? null : json["pcptaken"],
        xantaken: json["xantaken"] == null ? null : json["xantaken"],
        victaken: json["victaken"] == null ? null : json["victaken"],
        chahits: json["chahits"] == null ? null : json["chahits"],
        heahits: json["heahits"] == null ? null : json["heahits"],
        axehits: json["axehits"] == null ? null : json["axehits"],
        grehits: json["grehits"] == null ? null : json["grehits"],
        machits: json["machits"] == null ? null : json["machits"],
        pishits: json["pishits"] == null ? null : json["pishits"],
        rifhits: json["rifhits"] == null ? null : json["rifhits"],
        shohits: json["shohits"] == null ? null : json["shohits"],
        smghits: json["smghits"] == null ? null : json["smghits"],
        piehits: json["piehits"] == null ? null : json["piehits"],
        slahits: json["slahits"] == null ? null : json["slahits"],
        argtravel: json["argtravel"] == null ? null : json["argtravel"],
        mextravel: json["mextravel"] == null ? null : json["mextravel"],
        dubtravel: json["dubtravel"] == null ? null : json["dubtravel"],
        hawtravel: json["hawtravel"] == null ? null : json["hawtravel"],
        japtravel: json["japtravel"] == null ? null : json["japtravel"],
        lontravel: json["lontravel"] == null ? null : json["lontravel"],
        soutravel: json["soutravel"] == null ? null : json["soutravel"],
        switravel: json["switravel"] == null ? null : json["switravel"],
        chitravel: json["chitravel"] == null ? null : json["chitravel"],
        cantravel: json["cantravel"] == null ? null : json["cantravel"],
        dumpfinds: json["dumpfinds"] == null ? null : json["dumpfinds"],
        dumpsearches: json["dumpsearches"] == null ? null : json["dumpsearches"],
        itemsdumped: json["itemsdumped"] == null ? null : json["itemsdumped"],
        daysbeendonator: json["daysbeendonator"] == null ? null : json["daysbeendonator"],
        caytravel: json["caytravel"] == null ? null : json["caytravel"],
        jailed: json["jailed"] == null ? null : json["jailed"],
        hospital: json["hospital"] == null ? null : json["hospital"],
        attacksassisted: json["attacksassisted"] == null ? null : json["attacksassisted"],
        bloodwithdrawn: json["bloodwithdrawn"] == null ? null : json["bloodwithdrawn"],
        networth: json["networth"] == null ? null : json["networth"],
        missionscompleted: json["missionscompleted"] == null ? null : json["missionscompleted"],
        contractscompleted: json["contractscompleted"] == null ? null : json["contractscompleted"],
        dukecontractscompleted: json["dukecontractscompleted"] == null ? null : json["dukecontractscompleted"],
        missioncreditsearned: json["missioncreditsearned"] == null ? null : json["missioncreditsearned"],
        consumablesused: json["consumablesused"] == null ? null : json["consumablesused"],
        candyused: json["candyused"] == null ? null : json["candyused"],
        alcoholused: json["alcoholused"] == null ? null : json["alcoholused"],
        energydrinkused: json["energydrinkused"] == null ? null : json["energydrinkused"],
        nerverefills: json["nerverefills"] == null ? null : json["nerverefills"],
        unarmoredwon: json["unarmoredwon"] == null ? null : json["unarmoredwon"],
        h2Hhits: json["h2hhits"] == null ? null : json["h2hhits"],
        organisedcrimes: json["organisedcrimes"] == null ? null : json["organisedcrimes"],
        territorytime: json["territorytime"] == null ? null : json["territorytime"],
        territoryjoins: json["territoryjoins"] == null ? null : json["territoryjoins"],
        arrestsmade: json["arrestsmade"] == null ? null : json["arrestsmade"],
        tokenrefills: json["tokenrefills"] == null ? null : json["tokenrefills"],
        booksread: json["booksread"] == null ? null : json["booksread"],
        traveltime: json["traveltime"] == null ? null : json["traveltime"],
        boostersused: json["boostersused"] == null ? null : json["boostersused"],
        rehabs: json["rehabs"] == null ? null : json["rehabs"],
        rehabcost: json["rehabcost"] == null ? null : json["rehabcost"],
        awards: json["awards"] == null ? null : json["awards"],
        receivedbountyvalue: json["receivedbountyvalue"] == null ? null : json["receivedbountyvalue"],
        raceswon: json["raceswon"] == null ? null : json["raceswon"],
        racesentered: json["racesentered"] == null ? null : json["racesentered"],
        racingpointsearned: json["racingpointsearned"] == null ? null : json["racingpointsearned"],
        specialammoused: json["specialammoused"] == null ? null : json["specialammoused"],
        cityitemsbought: json["cityitemsbought"] == null ? null : json["cityitemsbought"],
        hollowammoused: json["hollowammoused"] == null ? null : json["hollowammoused"],
        tracerammoused: json["tracerammoused"] == null ? null : json["tracerammoused"],
        piercingammoused: json["piercingammoused"] == null ? null : json["piercingammoused"],
        incendiaryammoused: json["incendiaryammoused"] == null ? null : json["incendiaryammoused"],
        attackswonabroad: json["attackswonabroad"] == null ? null : json["attackswonabroad"],
        defendslostabroad: json["defendslostabroad"] == null ? null : json["defendslostabroad"],
        retals: json["retals"] == null ? null : json["retals"],
        elo: json["elo"] == null ? null : json["elo"],
        reviveskill: json["reviveskill"] == null ? null : json["reviveskill"],
        activestreak: json["activestreak"] == null ? null : json["activestreak"],
        bestactivestreak: json["bestactivestreak"] == null ? null : json["bestactivestreak"],
        jobpointsused: json["jobpointsused"] == null ? null : json["jobpointsused"],
      );

  Map<String, dynamic> toJson() => {
        "useractivity": useractivity == null ? null : useractivity,
        "itemsbought": itemsbought == null ? null : itemsbought,
        "pointsbought": pointsbought == null ? null : pointsbought,
        "itemsboughtabroad": itemsboughtabroad == null ? null : itemsboughtabroad,
        "weaponsbought": weaponsbought == null ? null : weaponsbought,
        "itemssent": itemssent == null ? null : itemssent,
        "auctionswon": auctionswon == null ? null : auctionswon,
        "auctionsells": auctionsells == null ? null : auctionsells,
        "attackswon": attackswon == null ? null : attackswon,
        "attackslost": attackslost == null ? null : attackslost,
        "attacksdraw": attacksdraw == null ? null : attacksdraw,
        "bestkillstreak": bestkillstreak == null ? null : bestkillstreak,
        "moneymugged": moneymugged == null ? null : moneymugged,
        "attacksstealthed": attacksstealthed == null ? null : attacksstealthed,
        "attackhits": attackhits == null ? null : attackhits,
        "attackmisses": attackmisses == null ? null : attackmisses,
        "attackdamage": attackdamage == null ? null : attackdamage,
        "attackcriticalhits": attackcriticalhits == null ? null : attackcriticalhits,
        "respectforfaction": respectforfaction == null ? null : respectforfaction,
        "onehitkills": onehitkills == null ? null : onehitkills,
        "defendswon": defendswon == null ? null : defendswon,
        "defendslost": defendslost == null ? null : defendslost,
        "defendsstalemated": defendsstalemated == null ? null : defendsstalemated,
        "bestdamage": bestdamage == null ? null : bestdamage,
        "roundsfired": roundsfired == null ? null : roundsfired,
        "yourunaway": yourunaway == null ? null : yourunaway,
        "theyrunaway": theyrunaway == null ? null : theyrunaway,
        "highestbeaten": highestbeaten == null ? null : highestbeaten,
        "peoplebusted": peoplebusted == null ? null : peoplebusted,
        "failedbusts": failedbusts == null ? null : failedbusts,
        "peoplebought": peoplebought == null ? null : peoplebought,
        "peopleboughtspent": peopleboughtspent == null ? null : peopleboughtspent,
        "virusescoded": virusescoded == null ? null : virusescoded,
        "cityfinds": cityfinds == null ? null : cityfinds,
        "traveltimes": traveltimes == null ? null : traveltimes,
        "bountiesplaced": bountiesplaced == null ? null : bountiesplaced,
        "bountiesreceived": bountiesreceived == null ? null : bountiesreceived,
        "bountiescollected": bountiescollected == null ? null : bountiescollected,
        "totalbountyreward": totalbountyreward == null ? null : totalbountyreward,
        "revives": revives == null ? null : revives,
        "revivesreceived": revivesreceived == null ? null : revivesreceived,
        "medicalitemsused": medicalitemsused == null ? null : medicalitemsused,
        "statenhancersused": statenhancersused == null ? null : statenhancersused,
        "refills": refills == null ? null : refills,
        "trainsreceived": trainsreceived == null ? null : trainsreceived,
        "totalbountyspent": totalbountyspent == null ? null : totalbountyspent,
        "drugsused": drugsused == null ? null : drugsused,
        "overdosed": overdosed == null ? null : overdosed,
        "meritsbought": meritsbought == null ? null : meritsbought,
        "timesloggedin": timesloggedin == null ? null : timesloggedin,
        "personalsplaced": personalsplaced == null ? null : personalsplaced,
        "classifiedadsplaced": classifiedadsplaced == null ? null : classifiedadsplaced,
        "mailssent": mailssent == null ? null : mailssent,
        "friendmailssent": friendmailssent == null ? null : friendmailssent,
        "factionmailssent": factionmailssent == null ? null : factionmailssent,
        "companymailssent": companymailssent == null ? null : companymailssent,
        "spousemailssent": spousemailssent == null ? null : spousemailssent,
        "largestmug": largestmug == null ? null : largestmug,
        "cantaken": cantaken == null ? null : cantaken,
        "exttaken": exttaken == null ? null : exttaken,
        "kettaken": kettaken == null ? null : kettaken,
        "lsdtaken": lsdtaken == null ? null : lsdtaken,
        "opitaken": opitaken == null ? null : opitaken,
        "shrtaken": shrtaken == null ? null : shrtaken,
        "spetaken": spetaken == null ? null : spetaken,
        "pcptaken": pcptaken == null ? null : pcptaken,
        "xantaken": xantaken == null ? null : xantaken,
        "victaken": victaken == null ? null : victaken,
        "chahits": chahits == null ? null : chahits,
        "heahits": heahits == null ? null : heahits,
        "axehits": axehits == null ? null : axehits,
        "grehits": grehits == null ? null : grehits,
        "machits": machits == null ? null : machits,
        "pishits": pishits == null ? null : pishits,
        "rifhits": rifhits == null ? null : rifhits,
        "shohits": shohits == null ? null : shohits,
        "smghits": smghits == null ? null : smghits,
        "piehits": piehits == null ? null : piehits,
        "slahits": slahits == null ? null : slahits,
        "argtravel": argtravel == null ? null : argtravel,
        "mextravel": mextravel == null ? null : mextravel,
        "dubtravel": dubtravel == null ? null : dubtravel,
        "hawtravel": hawtravel == null ? null : hawtravel,
        "japtravel": japtravel == null ? null : japtravel,
        "lontravel": lontravel == null ? null : lontravel,
        "soutravel": soutravel == null ? null : soutravel,
        "switravel": switravel == null ? null : switravel,
        "chitravel": chitravel == null ? null : chitravel,
        "cantravel": cantravel == null ? null : cantravel,
        "dumpfinds": dumpfinds == null ? null : dumpfinds,
        "dumpsearches": dumpsearches == null ? null : dumpsearches,
        "itemsdumped": itemsdumped == null ? null : itemsdumped,
        "daysbeendonator": daysbeendonator == null ? null : daysbeendonator,
        "caytravel": caytravel == null ? null : caytravel,
        "jailed": jailed == null ? null : jailed,
        "hospital": hospital == null ? null : hospital,
        "attacksassisted": attacksassisted == null ? null : attacksassisted,
        "bloodwithdrawn": bloodwithdrawn == null ? null : bloodwithdrawn,
        "networth": networth == null ? null : networth,
        "missionscompleted": missionscompleted == null ? null : missionscompleted,
        "contractscompleted": contractscompleted == null ? null : contractscompleted,
        "dukecontractscompleted": dukecontractscompleted == null ? null : dukecontractscompleted,
        "missioncreditsearned": missioncreditsearned == null ? null : missioncreditsearned,
        "consumablesused": consumablesused == null ? null : consumablesused,
        "candyused": candyused == null ? null : candyused,
        "alcoholused": alcoholused == null ? null : alcoholused,
        "energydrinkused": energydrinkused == null ? null : energydrinkused,
        "nerverefills": nerverefills == null ? null : nerverefills,
        "unarmoredwon": unarmoredwon == null ? null : unarmoredwon,
        "h2hhits": h2Hhits == null ? null : h2Hhits,
        "organisedcrimes": organisedcrimes == null ? null : organisedcrimes,
        "territorytime": territorytime == null ? null : territorytime,
        "territoryjoins": territoryjoins == null ? null : territoryjoins,
        "arrestsmade": arrestsmade == null ? null : arrestsmade,
        "tokenrefills": tokenrefills == null ? null : tokenrefills,
        "booksread": booksread == null ? null : booksread,
        "traveltime": traveltime == null ? null : traveltime,
        "boostersused": boostersused == null ? null : boostersused,
        "rehabs": rehabs == null ? null : rehabs,
        "rehabcost": rehabcost == null ? null : rehabcost,
        "awards": awards == null ? null : awards,
        "receivedbountyvalue": receivedbountyvalue == null ? null : receivedbountyvalue,
        "raceswon": raceswon == null ? null : raceswon,
        "racesentered": racesentered == null ? null : racesentered,
        "racingpointsearned": racingpointsearned == null ? null : racingpointsearned,
        "specialammoused": specialammoused == null ? null : specialammoused,
        "cityitemsbought": cityitemsbought == null ? null : cityitemsbought,
        "hollowammoused": hollowammoused == null ? null : hollowammoused,
        "tracerammoused": tracerammoused == null ? null : tracerammoused,
        "piercingammoused": piercingammoused == null ? null : piercingammoused,
        "incendiaryammoused": incendiaryammoused == null ? null : incendiaryammoused,
        "attackswonabroad": attackswonabroad == null ? null : attackswonabroad,
        "defendslostabroad": defendslostabroad == null ? null : defendslostabroad,
        "retals": retals == null ? null : retals,
        "elo": elo == null ? null : elo,
        "reviveskill": reviveskill == null ? null : reviveskill,
        "activestreak": activestreak == null ? null : activestreak,
        "bestactivestreak": bestactivestreak == null ? null : bestactivestreak,
        "jobpointsused": jobpointsused == null ? null : jobpointsused,
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
