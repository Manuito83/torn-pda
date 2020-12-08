// To parse this JSON data, do
//
//     final yataAwards = yataAwardsFromJson(jsonString);

import 'dart:convert';

YataAwards yataAwardsFromJson(String str) => YataAwards.fromJson(json.decode(str));

String yataAwardsToJson(YataAwards data) => json.encode(data.toJson());

class YataAwards {
  YataAwards({
    this.player,
    this.pinnedAwards,
    this.graph,
    this.graph2,
    this.awardscat,
    this.view,
    this.userInfo,
    this.awards,
    this.summaryByType,
  });

  Player player;
  PinnedAwards pinnedAwards;
  List<List<dynamic>> graph;
  List<List<dynamic>> graph2;
  bool awardscat;
  View view;
  UserInfo userInfo;
  Awards awards;
  SummaryByType summaryByType;

  factory YataAwards.fromJson(Map<String, dynamic> json) => YataAwards(
    player: json["player"] == null ? null : Player.fromJson(json["player"]),
    pinnedAwards: json["pinnedAwards"] == null ? null : PinnedAwards.fromJson(json["pinnedAwards"]),
    graph: json["graph"] == null ? null : List<List<dynamic>>.from(json["graph"].map((x) => List<dynamic>.from(x.map((x) => x)))),
    graph2: json["graph2"] == null ? null : List<List<dynamic>>.from(json["graph2"].map((x) => List<dynamic>.from(x.map((x) => x)))),
    awardscat: json["awardscat"] == null ? null : json["awardscat"],
    view: json["view"] == null ? null : View.fromJson(json["view"]),
    userInfo: json["userInfo"] == null ? null : UserInfo.fromJson(json["userInfo"]),
    awards: json["awards"] == null ? null : Awards.fromJson(json["awards"]),
    summaryByType: json["summaryByType"] == null ? null : SummaryByType.fromJson(json["summaryByType"]),
  );

  Map<String, dynamic> toJson() => {
    "player": player == null ? null : player.toJson(),
    "pinnedAwards": pinnedAwards == null ? null : pinnedAwards.toJson(),
    "graph": graph == null ? null : List<dynamic>.from(graph.map((x) => List<dynamic>.from(x.map((x) => x)))),
    "graph2": graph2 == null ? null : List<dynamic>.from(graph2.map((x) => List<dynamic>.from(x.map((x) => x)))),
    "awardscat": awardscat == null ? null : awardscat,
    "view": view == null ? null : view.toJson(),
    "userInfo": userInfo == null ? null : userInfo.toJson(),
    "awards": awards == null ? null : awards.toJson(),
    "summaryByType": summaryByType == null ? null : summaryByType.toJson(),
  };
}

class Awards {
  Awards({
    this.illegalProducts,
    this.theft,
    this.autoTheft,
    this.drugDeals,
    this.computerCrimes,
    this.murder,
    this.fraudCrimes,
    this.otherCrimes,
    this.organisedCrimes,
    this.jail,
    this.total,
    this.cannabis,
    this.ecstasy,
    this.ketamine,
    this.lsd,
    this.opium,
    this.shrooms,
    this.awardsSpeed,
    this.pcp,
    this.xanax,
    this.vicodin,
    this.wins,
    this.defends,
    this.escapes,
    this.killStreak,
    this.criticalHits,
    this.bounties,
    this.fireRounds,
    this.specialAmmo,
    this.otherAttacks,
    this.assists,
    this.damage,
    this.finishingHits,
    this.respect,
    this.chains,
    this.otherFaction,
    this.commitment,
    this.dirtyBomb,
    this.city,
    this.medicalItems,
    this.otherItems,
    this.pranks,
    this.consume,
    this.destinations,
    this.time,
    this.importItems,
    this.attacksAbroad,
    this.hunting,
    this.bachelors,
    this.courses,
    this.workingStats,
    this.jobPoints,
    this.cityJobs,
    this.memberships,
    this.otherGym,
    this.defense,
    this.dexterity,
    this.speed,
    this.strength,
    this.totalStats,
    this.stocks,
    this.bank,
    this.estate,
    this.networth,
    this.casino,
    this.donations,
    this.otherMoney,
    this.elimination,
    this.otherComp,
    this.tokenShop,
    this.tcEndurance,
    this.tornOfTheDead,
    this.trickOrTreats,
    this.dogTag,
    this.spouse,
    this.donator,
    this.age,
    this.level,
    this.rank,
    this.otherCommitment,
    this.social,
    this.points,
    this.perks,
    this.racing,
    this.awards,
    this.missions,
    this.maximum,
    this.revives,
    this.events,
    this.otherMisc,
  });

  IllegalProducts illegalProducts;
  Theft theft;
  AutoTheft autoTheft;
  DrugDeals drugDeals;
  ComputerCrimes computerCrimes;
  Murder murder;
  FraudCrimes fraudCrimes;
  OtherCrimes otherCrimes;
  OrganisedCrimes organisedCrimes;
  Jail jail;
  Total total;
  Cannabis cannabis;
  Ecstasy ecstasy;
  Ketamine ketamine;
  Lsd lsd;
  Opium opium;
  Shrooms shrooms;
  SpeedClass awardsSpeed;
  Pcp pcp;
  Xanax xanax;
  Vicodin vicodin;
  Wins wins;
  Defends defends;
  Escapes escapes;
  KillStreak killStreak;
  CriticalHits criticalHits;
  Bounties bounties;
  FireRounds fireRounds;
  SpecialAmmo specialAmmo;
  OtherAttacks otherAttacks;
  Assists assists;
  Damage damage;
  FinishingHits finishingHits;
  Respect respect;
  Chains chains;
  OtherFaction otherFaction;
  Commitment commitment;
  DirtyBomb dirtyBomb;
  City city;
  MedicalItems medicalItems;
  OtherItems otherItems;
  Pranks pranks;
  Consume consume;
  Destinations destinations;
  Time time;
  ImportItems importItems;
  AttacksAbroad attacksAbroad;
  Hunting hunting;
  Bachelors bachelors;
  Courses courses;
  WorkingStats workingStats;
  JobPoints jobPoints;
  CityJobs cityJobs;
  Memberships memberships;
  OtherGym otherGym;
  Defense defense;
  Dexterity dexterity;
  Speed speed;
  Strength strength;
  TotalStats totalStats;
  Stocks stocks;
  Bank bank;
  Estate estate;
  Networth networth;
  Casino casino;
  Donations donations;
  OtherMoney otherMoney;
  Elimination elimination;
  OtherComp otherComp;
  TokenShop tokenShop;
  TcEndurance tcEndurance;
  TornOfTheDead tornOfTheDead;
  TrickOrTreats trickOrTreats;
  DogTag dogTag;
  Spouse spouse;
  Donator donator;
  Age age;
  Level level;
  Rank rank;
  OtherCommitment otherCommitment;
  Social social;
  Points points;
  Perks perks;
  Racing racing;
  AwardsClass awards;
  Missions missions;
  Maximum maximum;
  Revives revives;
  Events events;
  OtherMisc otherMisc;

  factory Awards.fromJson(Map<String, dynamic> json) => Awards(
    illegalProducts: json["Illegal products"] == null ? null : IllegalProducts.fromJson(json["Illegal products"]),
    theft: json["Theft"] == null ? null : Theft.fromJson(json["Theft"]),
    autoTheft: json["Auto theft"] == null ? null : AutoTheft.fromJson(json["Auto theft"]),
    drugDeals: json["Drug deals"] == null ? null : DrugDeals.fromJson(json["Drug deals"]),
    computerCrimes: json["Computer crimes"] == null ? null : ComputerCrimes.fromJson(json["Computer crimes"]),
    murder: json["Murder"] == null ? null : Murder.fromJson(json["Murder"]),
    fraudCrimes: json["Fraud crimes"] == null ? null : FraudCrimes.fromJson(json["Fraud crimes"]),
    otherCrimes: json["Other crimes"] == null ? null : OtherCrimes.fromJson(json["Other crimes"]),
    organisedCrimes: json["Organised crimes"] == null ? null : OrganisedCrimes.fromJson(json["Organised crimes"]),
    jail: json["Jail"] == null ? null : Jail.fromJson(json["Jail"]),
    total: json["Total"] == null ? null : Total.fromJson(json["Total"]),
    cannabis: json["Cannabis "] == null ? null : Cannabis.fromJson(json["Cannabis "]),
    ecstasy: json["Ecstasy "] == null ? null : Ecstasy.fromJson(json["Ecstasy "]),
    ketamine: json["Ketamine "] == null ? null : Ketamine.fromJson(json["Ketamine "]),
    lsd: json["LSD "] == null ? null : Lsd.fromJson(json["LSD "]),
    opium: json["Opium "] == null ? null : Opium.fromJson(json["Opium "]),
    shrooms: json["Shrooms "] == null ? null : Shrooms.fromJson(json["Shrooms "]),
    awardsSpeed: json["Speed "] == null ? null : SpeedClass.fromJson(json["Speed "]),
    pcp: json["PCP "] == null ? null : Pcp.fromJson(json["PCP "]),
    xanax: json["Xanax "] == null ? null : Xanax.fromJson(json["Xanax "]),
    vicodin: json["Vicodin "] == null ? null : Vicodin.fromJson(json["Vicodin "]),
    wins: json["Wins"] == null ? null : Wins.fromJson(json["Wins"]),
    defends: json["Defends"] == null ? null : Defends.fromJson(json["Defends"]),
    escapes: json["Escapes"] == null ? null : Escapes.fromJson(json["Escapes"]),
    killStreak: json["Kill streak"] == null ? null : KillStreak.fromJson(json["Kill streak"]),
    criticalHits: json["Critical hits"] == null ? null : CriticalHits.fromJson(json["Critical hits"]),
    bounties: json["Bounties"] == null ? null : Bounties.fromJson(json["Bounties"]),
    fireRounds: json["Fire rounds"] == null ? null : FireRounds.fromJson(json["Fire rounds"]),
    specialAmmo: json["Special ammo"] == null ? null : SpecialAmmo.fromJson(json["Special ammo"]),
    otherAttacks: json["Other Attacks"] == null ? null : OtherAttacks.fromJson(json["Other Attacks"]),
    assists: json["Assists"] == null ? null : Assists.fromJson(json["Assists"]),
    damage: json["Damage"] == null ? null : Damage.fromJson(json["Damage"]),
    finishingHits: json["Finishing hits"] == null ? null : FinishingHits.fromJson(json["Finishing hits"]),
    respect: json["Respect"] == null ? null : Respect.fromJson(json["Respect"]),
    chains: json["Chains"] == null ? null : Chains.fromJson(json["Chains"]),
    otherFaction: json["Other Faction"] == null ? null : OtherFaction.fromJson(json["Other Faction"]),
    commitment: json["Commitment"] == null ? null : Commitment.fromJson(json["Commitment"]),
    dirtyBomb: json["Dirty bomb"] == null ? null : DirtyBomb.fromJson(json["Dirty bomb"]),
    city: json["City"] == null ? null : City.fromJson(json["City"]),
    medicalItems: json["Medical items"] == null ? null : MedicalItems.fromJson(json["Medical items"]),
    otherItems: json["Other Items"] == null ? null : OtherItems.fromJson(json["Other Items"]),
    pranks: json["Pranks"] == null ? null : Pranks.fromJson(json["Pranks"]),
    consume: json["Consume"] == null ? null : Consume.fromJson(json["Consume"]),
    destinations: json["Destinations"] == null ? null : Destinations.fromJson(json["Destinations"]),
    time: json["Time"] == null ? null : Time.fromJson(json["Time"]),
    importItems: json["Import items"] == null ? null : ImportItems.fromJson(json["Import items"]),
    attacksAbroad: json["Attacks abroad"] == null ? null : AttacksAbroad.fromJson(json["Attacks abroad"]),
    hunting: json["Hunting"] == null ? null : Hunting.fromJson(json["Hunting"]),
    bachelors: json["Bachelors"] == null ? null : Bachelors.fromJson(json["Bachelors"]),
    courses: json["Courses"] == null ? null : Courses.fromJson(json["Courses"]),
    workingStats: json["Working stats"] == null ? null : WorkingStats.fromJson(json["Working stats"]),
    jobPoints: json["Job points"] == null ? null : JobPoints.fromJson(json["Job points"]),
    cityJobs: json["City jobs"] == null ? null : CityJobs.fromJson(json["City jobs"]),
    memberships: json["Memberships"] == null ? null : Memberships.fromJson(json["Memberships"]),
    otherGym: json["Other Gym"] == null ? null : OtherGym.fromJson(json["Other Gym"]),
    defense: json["Defense"] == null ? null : Defense.fromJson(json["Defense"]),
    dexterity: json["Dexterity"] == null ? null : Dexterity.fromJson(json["Dexterity"]),
    speed: json["Speed"] == null ? null : Speed.fromJson(json["Speed"]),
    strength: json["Strength"] == null ? null : Strength.fromJson(json["Strength"]),
    totalStats: json["Total stats"] == null ? null : TotalStats.fromJson(json["Total stats"]),
    stocks: json["Stocks"] == null ? null : Stocks.fromJson(json["Stocks"]),
    bank: json["Bank"] == null ? null : Bank.fromJson(json["Bank"]),
    estate: json["Estate"] == null ? null : Estate.fromJson(json["Estate"]),
    networth: json["Networth"] == null ? null : Networth.fromJson(json["Networth"]),
    casino: json["Casino"] == null ? null : Casino.fromJson(json["Casino"]),
    donations: json["Donations"] == null ? null : Donations.fromJson(json["Donations"]),
    otherMoney: json["Other Money"] == null ? null : OtherMoney.fromJson(json["Other Money"]),
    elimination: json["Elimination"] == null ? null : Elimination.fromJson(json["Elimination"]),
    otherComp: json["Other Comp"] == null ? null : OtherComp.fromJson(json["Other Comp"]),
    tokenShop: json["Token shop"] == null ? null : TokenShop.fromJson(json["Token shop"]),
    tcEndurance: json["TC endurance"] == null ? null : TcEndurance.fromJson(json["TC endurance"]),
    tornOfTheDead: json["Torn of the dead"] == null ? null : TornOfTheDead.fromJson(json["Torn of the dead"]),
    trickOrTreats: json["Trick or treats"] == null ? null : TrickOrTreats.fromJson(json["Trick or treats"]),
    dogTag: json["Dog tag"] == null ? null : DogTag.fromJson(json["Dog tag"]),
    spouse: json["Spouse"] == null ? null : Spouse.fromJson(json["Spouse"]),
    donator: json["Donator"] == null ? null : Donator.fromJson(json["Donator"]),
    age: json["Age"] == null ? null : Age.fromJson(json["Age"]),
    level: json["Level"] == null ? null : Level.fromJson(json["Level"]),
    rank: json["Rank"] == null ? null : Rank.fromJson(json["Rank"]),
    otherCommitment: json["Other Commitment"] == null ? null : OtherCommitment.fromJson(json["Other Commitment"]),
    social: json["Social"] == null ? null : Social.fromJson(json["Social"]),
    points: json["Points"] == null ? null : Points.fromJson(json["Points"]),
    perks: json["Perks"] == null ? null : Perks.fromJson(json["Perks"]),
    racing: json["Racing"] == null ? null : Racing.fromJson(json["Racing"]),
    awards: json["Awards"] == null ? null : AwardsClass.fromJson(json["Awards"]),
    missions: json["Missions"] == null ? null : Missions.fromJson(json["Missions"]),
    maximum: json["Maximum"] == null ? null : Maximum.fromJson(json["Maximum"]),
    revives: json["Revives"] == null ? null : Revives.fromJson(json["Revives"]),
    events: json["Events"] == null ? null : Events.fromJson(json["Events"]),
    otherMisc: json["Other Misc"] == null ? null : OtherMisc.fromJson(json["Other Misc"]),
  );

  Map<String, dynamic> toJson() => {
    "Illegal products": illegalProducts == null ? null : illegalProducts.toJson(),
    "Theft": theft == null ? null : theft.toJson(),
    "Auto theft": autoTheft == null ? null : autoTheft.toJson(),
    "Drug deals": drugDeals == null ? null : drugDeals.toJson(),
    "Computer crimes": computerCrimes == null ? null : computerCrimes.toJson(),
    "Murder": murder == null ? null : murder.toJson(),
    "Fraud crimes": fraudCrimes == null ? null : fraudCrimes.toJson(),
    "Other crimes": otherCrimes == null ? null : otherCrimes.toJson(),
    "Organised crimes": organisedCrimes == null ? null : organisedCrimes.toJson(),
    "Jail": jail == null ? null : jail.toJson(),
    "Total": total == null ? null : total.toJson(),
    "Cannabis ": cannabis == null ? null : cannabis.toJson(),
    "Ecstasy ": ecstasy == null ? null : ecstasy.toJson(),
    "Ketamine ": ketamine == null ? null : ketamine.toJson(),
    "LSD ": lsd == null ? null : lsd.toJson(),
    "Opium ": opium == null ? null : opium.toJson(),
    "Shrooms ": shrooms == null ? null : shrooms.toJson(),
    "Speed ": awardsSpeed == null ? null : awardsSpeed.toJson(),
    "PCP ": pcp == null ? null : pcp.toJson(),
    "Xanax ": xanax == null ? null : xanax.toJson(),
    "Vicodin ": vicodin == null ? null : vicodin.toJson(),
    "Wins": wins == null ? null : wins.toJson(),
    "Defends": defends == null ? null : defends.toJson(),
    "Escapes": escapes == null ? null : escapes.toJson(),
    "Kill streak": killStreak == null ? null : killStreak.toJson(),
    "Critical hits": criticalHits == null ? null : criticalHits.toJson(),
    "Bounties": bounties == null ? null : bounties.toJson(),
    "Fire rounds": fireRounds == null ? null : fireRounds.toJson(),
    "Special ammo": specialAmmo == null ? null : specialAmmo.toJson(),
    "Other Attacks": otherAttacks == null ? null : otherAttacks.toJson(),
    "Assists": assists == null ? null : assists.toJson(),
    "Damage": damage == null ? null : damage.toJson(),
    "Finishing hits": finishingHits == null ? null : finishingHits.toJson(),
    "Respect": respect == null ? null : respect.toJson(),
    "Chains": chains == null ? null : chains.toJson(),
    "Other Faction": otherFaction == null ? null : otherFaction.toJson(),
    "Commitment": commitment == null ? null : commitment.toJson(),
    "Dirty bomb": dirtyBomb == null ? null : dirtyBomb.toJson(),
    "City": city == null ? null : city.toJson(),
    "Medical items": medicalItems == null ? null : medicalItems.toJson(),
    "Other Items": otherItems == null ? null : otherItems.toJson(),
    "Pranks": pranks == null ? null : pranks.toJson(),
    "Consume": consume == null ? null : consume.toJson(),
    "Destinations": destinations == null ? null : destinations.toJson(),
    "Time": time == null ? null : time.toJson(),
    "Import items": importItems == null ? null : importItems.toJson(),
    "Attacks abroad": attacksAbroad == null ? null : attacksAbroad.toJson(),
    "Hunting": hunting == null ? null : hunting.toJson(),
    "Bachelors": bachelors == null ? null : bachelors.toJson(),
    "Courses": courses == null ? null : courses.toJson(),
    "Working stats": workingStats == null ? null : workingStats.toJson(),
    "Job points": jobPoints == null ? null : jobPoints.toJson(),
    "City jobs": cityJobs == null ? null : cityJobs.toJson(),
    "Memberships": memberships == null ? null : memberships.toJson(),
    "Other Gym": otherGym == null ? null : otherGym.toJson(),
    "Defense": defense == null ? null : defense.toJson(),
    "Dexterity": dexterity == null ? null : dexterity.toJson(),
    "Speed": speed == null ? null : speed.toJson(),
    "Strength": strength == null ? null : strength.toJson(),
    "Total stats": totalStats == null ? null : totalStats.toJson(),
    "Stocks": stocks == null ? null : stocks.toJson(),
    "Bank": bank == null ? null : bank.toJson(),
    "Estate": estate == null ? null : estate.toJson(),
    "Networth": networth == null ? null : networth.toJson(),
    "Casino": casino == null ? null : casino.toJson(),
    "Donations": donations == null ? null : donations.toJson(),
    "Other Money": otherMoney == null ? null : otherMoney.toJson(),
    "Elimination": elimination == null ? null : elimination.toJson(),
    "Other Comp": otherComp == null ? null : otherComp.toJson(),
    "Token shop": tokenShop == null ? null : tokenShop.toJson(),
    "TC endurance": tcEndurance == null ? null : tcEndurance.toJson(),
    "Torn of the dead": tornOfTheDead == null ? null : tornOfTheDead.toJson(),
    "Trick or treats": trickOrTreats == null ? null : trickOrTreats.toJson(),
    "Dog tag": dogTag == null ? null : dogTag.toJson(),
    "Spouse": spouse == null ? null : spouse.toJson(),
    "Donator": donator == null ? null : donator.toJson(),
    "Age": age == null ? null : age.toJson(),
    "Level": level == null ? null : level.toJson(),
    "Rank": rank == null ? null : rank.toJson(),
    "Other Commitment": otherCommitment == null ? null : otherCommitment.toJson(),
    "Social": social == null ? null : social.toJson(),
    "Points": points == null ? null : points.toJson(),
    "Perks": perks == null ? null : perks.toJson(),
    "Racing": racing == null ? null : racing.toJson(),
    "Awards": awards == null ? null : awards.toJson(),
    "Missions": missions == null ? null : missions.toJson(),
    "Maximum": maximum == null ? null : maximum.toJson(),
    "Revives": revives == null ? null : revives.toJson(),
    "Events": events == null ? null : events.toJson(),
    "Other Misc": otherMisc == null ? null : otherMisc.toJson(),
  };
}

class Age {
  Age({
    this.m225,
    this.m226,
    this.m227,
    this.m228,
    this.m229,
    this.m230,
    this.m231,
    this.m232,
    this.m234,
    this.m235,
  });

  M225 m225;
  M225 m226;
  M225 m227;
  M225 m228;
  M225 m229;
  M225 m230;
  M225 m231;
  M225 m232;
  M225 m234;
  M225 m235;

  factory Age.fromJson(Map<String, dynamic> json) => Age(
    m225: json["m_225"] == null ? null : M225.fromJson(json["m_225"]),
    m226: json["m_226"] == null ? null : M225.fromJson(json["m_226"]),
    m227: json["m_227"] == null ? null : M225.fromJson(json["m_227"]),
    m228: json["m_228"] == null ? null : M225.fromJson(json["m_228"]),
    m229: json["m_229"] == null ? null : M225.fromJson(json["m_229"]),
    m230: json["m_230"] == null ? null : M225.fromJson(json["m_230"]),
    m231: json["m_231"] == null ? null : M225.fromJson(json["m_231"]),
    m232: json["m_232"] == null ? null : M225.fromJson(json["m_232"]),
    m234: json["m_234"] == null ? null : M225.fromJson(json["m_234"]),
    m235: json["m_235"] == null ? null : M225.fromJson(json["m_235"]),
  );

  Map<String, dynamic> toJson() => {
    "m_225": m225 == null ? null : m225.toJson(),
    "m_226": m226 == null ? null : m226.toJson(),
    "m_227": m227 == null ? null : m227.toJson(),
    "m_228": m228 == null ? null : m228.toJson(),
    "m_229": m229 == null ? null : m229.toJson(),
    "m_230": m230 == null ? null : m230.toJson(),
    "m_231": m231 == null ? null : m231.toJson(),
    "m_232": m232 == null ? null : m232.toJson(),
    "m_234": m234 == null ? null : m234.toJson(),
    "m_235": m235 == null ? null : m235.toJson(),
  };
}

class M225 {
  M225({
    this.name,
    this.description,
    this.type,
    this.circulation,
    this.rarity,
    this.img,
    this.rScore,
    this.awardType,
    this.awardedTime,
    this.goal,
    this.achieve,
    this.current,
    this.left,
    this.comment,
    this.m225Double,
    this.next,
    this.triple,
    this.wait,
    this.head,
  });

  String name;
  String description;
  String type;
  num circulation;
  String rarity;
  String img;
  num rScore;
  String awardType;
  num awardedTime;
  num goal;
  num achieve;
  num current;
  num left;
  String comment;
  bool m225Double;
  bool next;
  bool triple;
  num wait;
  String head;

  factory M225.fromJson(Map<String, dynamic> json) => M225(
    name: json["name"] == null ? null : json["name"],
    description: json["description"] == null ? null : json["description"],
    type: json["type"] == null ? null : json["type"],
    circulation: json["circulation"] == null ? null : json["circulation"],
    rarity: json["rarity"] == null ? null : json["rarity"],
    img: json["img"] == null ? null : json["img"],
    rScore: json["rScore"] == null ? null : json["rScore"],
    awardType: json["awardType"] == null ? null : json["awardType"],
    awardedTime: json["awarded_time"] == null ? null : json["awarded_time"],
    goal: json["goal"] == null ? null : json["goal"],
    achieve: json["achieve"] == null ? null : json["achieve"],
    current: json["current"] == null ? null : json["current"],
    left: json["left"] == null ? null : json["left"],
    comment: json["comment"] == null ? null : json["comment"],
    m225Double: json["num"] == null ? null : json["num"],
    next: json["next"] == null ? null : json["next"],
    triple: json["triple"] == null ? null : json["triple"],
    wait: json["wait"] == null ? null : json["wait"],
    head: json["head"] == null ? null : json["head"],
  );

  Map<String, dynamic> toJson() => {
    "name": name == null ? null : name,
    "description": description == null ? null : description,
    "type": type == null ? null : type,
    "circulation": circulation == null ? null : circulation,
    "rarity": rarity == null ? null : rarity,
    "img": img == null ? null : img,
    "rScore": rScore == null ? null : rScore,
    "awardType": awardType == null ? null : awardType,
    "awarded_time": awardedTime == null ? null : awardedTime,
    "goal": goal == null ? null : goal,
    "achieve": achieve == null ? null : achieve,
    "current": current == null ? null : current,
    "left": left == null ? null : left,
    "comment": comment == null ? null : comment,
    "num": m225Double == null ? null : m225Double,
    "next": next == null ? null : next,
    "triple": triple == null ? null : triple,
    "wait": wait == null ? null : wait,
    "head": head == null ? null : head,
  };
}

class Assists {
  Assists({
    this.h490,
    this.h639,
    this.h665,
  });

  H490 h490;
  H490 h639;
  H490 h665;

  factory Assists.fromJson(Map<String, dynamic> json) => Assists(
    h490: json["h_490"] == null ? null : H490.fromJson(json["h_490"]),
    h639: json["h_639"] == null ? null : H490.fromJson(json["h_639"]),
    h665: json["h_665"] == null ? null : H490.fromJson(json["h_665"]),
  );

  Map<String, dynamic> toJson() => {
    "h_490": h490 == null ? null : h490.toJson(),
    "h_639": h639 == null ? null : h639.toJson(),
    "h_665": h665 == null ? null : h665.toJson(),
  };
}

class H490 {
  H490({
    this.name,
    this.description,
    this.type,
    this.circulation,
    this.rarity,
    this.img,
    this.unreach,
    this.rScore,
    this.awardType,
    this.awardedTime,
    this.goal,
    this.current,
    this.achieve,
    this.left,
    this.comment,
    this.h490Double,
    this.head,
    this.triple,
  });

  String name;
  String description;
  num type;
  num circulation;
  String rarity;
  String img;
  num unreach;
  num rScore;
  String awardType;
  num awardedTime;
  num goal;
  num current;
  num achieve;
  num left;
  dynamic comment;
  bool h490Double;
  String head;
  bool triple;

  factory H490.fromJson(Map<String, dynamic> json) => H490(
    name: json["name"] == null ? null : json["name"],
    description: json["description"] == null ? null : json["description"],
    type: json["type"] == null ? null : json["type"],
    circulation: json["circulation"] == null ? null : json["circulation"],
    rarity: json["rarity"] == null ? null : json["rarity"],
    img: json["img"] == null ? null : json["img"],
    unreach: json["unreach"] == null ? null : json["unreach"],
    rScore: json["rScore"] == null ? null : json["rScore"],
    awardType: json["awardType"] == null ? null : json["awardType"],
    awardedTime: json["awarded_time"] == null ? null : json["awarded_time"],
    goal: json["goal"] == null ? null : json["goal"],
    current: json["current"] == null ? null : json["current"],
    achieve: json["achieve"] == null ? null : json["achieve"],
    left: json["left"] == null ? null : json["left"],
    comment: json["comment"],
    h490Double: json["num"] == null ? null : json["num"],
    head: json["head"] == null ? null : json["head"],
    triple: json["triple"] == null ? null : json["triple"],
  );

  Map<String, dynamic> toJson() => {
    "name": name == null ? null : name,
    "description": description == null ? null : description,
    "type": type == null ? null : type,
    "circulation": circulation == null ? null : circulation,
    "rarity": rarity == null ? null : rarity,
    "img": img == null ? null : img,
    "unreach": unreach == null ? null : unreach,
    "rScore": rScore == null ? null : rScore,
    "awardType": awardType == null ? null : awardType,
    "awarded_time": awardedTime == null ? null : awardedTime,
    "goal": goal == null ? null : goal,
    "current": current == null ? null : current,
    "achieve": achieve == null ? null : achieve,
    "left": left == null ? null : left,
    "comment": comment,
    "num": h490Double == null ? null : h490Double,
    "head": head == null ? null : head,
    "triple": triple == null ? null : triple,
  };
}

class AttacksAbroad {
  AttacksAbroad({
    this.h846,
  });

  H490 h846;

  factory AttacksAbroad.fromJson(Map<String, dynamic> json) => AttacksAbroad(
    h846: json["h_846"] == null ? null : H490.fromJson(json["h_846"]),
  );

  Map<String, dynamic> toJson() => {
    "h_846": h846 == null ? null : h846.toJson(),
  };
}

class AutoTheft {
  AutoTheft({
    this.h160,
    this.m69,
    this.m70,
    this.m71,
    this.m72,
    this.m73,
    this.m102,
    this.m103,
    this.m104,
    this.m121,
    this.m122,
    this.m123,
    this.m124,
    this.m133,
    this.m134,
    this.m135,
    this.m136,
    this.m137,
    this.m138,
    this.m139,
    this.m140,
    this.m141,
  });

  H490 h160;
  M225 m69;
  M225 m70;
  M225 m71;
  M225 m72;
  M225 m73;
  M225 m102;
  M225 m103;
  M225 m104;
  M225 m121;
  M225 m122;
  M225 m123;
  M225 m124;
  M225 m133;
  M225 m134;
  M225 m135;
  M225 m136;
  M225 m137;
  M225 m138;
  M225 m139;
  M225 m140;
  M225 m141;

  factory AutoTheft.fromJson(Map<String, dynamic> json) => AutoTheft(
    h160: json["h_160"] == null ? null : H490.fromJson(json["h_160"]),
    m69: json["m_69"] == null ? null : M225.fromJson(json["m_69"]),
    m70: json["m_70"] == null ? null : M225.fromJson(json["m_70"]),
    m71: json["m_71"] == null ? null : M225.fromJson(json["m_71"]),
    m72: json["m_72"] == null ? null : M225.fromJson(json["m_72"]),
    m73: json["m_73"] == null ? null : M225.fromJson(json["m_73"]),
    m102: json["m_102"] == null ? null : M225.fromJson(json["m_102"]),
    m103: json["m_103"] == null ? null : M225.fromJson(json["m_103"]),
    m104: json["m_104"] == null ? null : M225.fromJson(json["m_104"]),
    m121: json["m_121"] == null ? null : M225.fromJson(json["m_121"]),
    m122: json["m_122"] == null ? null : M225.fromJson(json["m_122"]),
    m123: json["m_123"] == null ? null : M225.fromJson(json["m_123"]),
    m124: json["m_124"] == null ? null : M225.fromJson(json["m_124"]),
    m133: json["m_133"] == null ? null : M225.fromJson(json["m_133"]),
    m134: json["m_134"] == null ? null : M225.fromJson(json["m_134"]),
    m135: json["m_135"] == null ? null : M225.fromJson(json["m_135"]),
    m136: json["m_136"] == null ? null : M225.fromJson(json["m_136"]),
    m137: json["m_137"] == null ? null : M225.fromJson(json["m_137"]),
    m138: json["m_138"] == null ? null : M225.fromJson(json["m_138"]),
    m139: json["m_139"] == null ? null : M225.fromJson(json["m_139"]),
    m140: json["m_140"] == null ? null : M225.fromJson(json["m_140"]),
    m141: json["m_141"] == null ? null : M225.fromJson(json["m_141"]),
  );

  Map<String, dynamic> toJson() => {
    "h_160": h160 == null ? null : h160.toJson(),
    "m_69": m69 == null ? null : m69.toJson(),
    "m_70": m70 == null ? null : m70.toJson(),
    "m_71": m71 == null ? null : m71.toJson(),
    "m_72": m72 == null ? null : m72.toJson(),
    "m_73": m73 == null ? null : m73.toJson(),
    "m_102": m102 == null ? null : m102.toJson(),
    "m_103": m103 == null ? null : m103.toJson(),
    "m_104": m104 == null ? null : m104.toJson(),
    "m_121": m121 == null ? null : m121.toJson(),
    "m_122": m122 == null ? null : m122.toJson(),
    "m_123": m123 == null ? null : m123.toJson(),
    "m_124": m124 == null ? null : m124.toJson(),
    "m_133": m133 == null ? null : m133.toJson(),
    "m_134": m134 == null ? null : m134.toJson(),
    "m_135": m135 == null ? null : m135.toJson(),
    "m_136": m136 == null ? null : m136.toJson(),
    "m_137": m137 == null ? null : m137.toJson(),
    "m_138": m138 == null ? null : m138.toJson(),
    "m_139": m139 == null ? null : m139.toJson(),
    "m_140": m140 == null ? null : m140.toJson(),
    "m_141": m141 == null ? null : m141.toJson(),
  };
}

class AwardsClass {
  AwardsClass({
    this.h229,
    this.h606,
    this.h614,
  });

  H490 h229;
  H490 h606;
  H490 h614;

  factory AwardsClass.fromJson(Map<String, dynamic> json) => AwardsClass(
    h229: json["h_229"] == null ? null : H490.fromJson(json["h_229"]),
    h606: json["h_606"] == null ? null : H490.fromJson(json["h_606"]),
    h614: json["h_614"] == null ? null : H490.fromJson(json["h_614"]),
  );

  Map<String, dynamic> toJson() => {
    "h_229": h229 == null ? null : h229.toJson(),
    "h_606": h606 == null ? null : h606.toJson(),
    "h_614": h614 == null ? null : h614.toJson(),
  };
}

class SpeedClass {
  SpeedClass({
    this.h35,
  });

  H490 h35;

  factory SpeedClass.fromJson(Map<String, dynamic> json) => SpeedClass(
    h35: json["h_35"] == null ? null : H490.fromJson(json["h_35"]),
  );

  Map<String, dynamic> toJson() => {
    "h_35": h35 == null ? null : h35.toJson(),
  };
}

class Bachelors {
  Bachelors({
    this.h53,
    this.h54,
    this.h55,
    this.h56,
    this.h57,
    this.h58,
    this.h59,
    this.h60,
    this.h61,
    this.h62,
    this.h63,
    this.h64,
  });

  H490 h53;
  H490 h54;
  H490 h55;
  H490 h56;
  H490 h57;
  H490 h58;
  H490 h59;
  H490 h60;
  H490 h61;
  H490 h62;
  H490 h63;
  H490 h64;

  factory Bachelors.fromJson(Map<String, dynamic> json) => Bachelors(
    h53: json["h_53"] == null ? null : H490.fromJson(json["h_53"]),
    h54: json["h_54"] == null ? null : H490.fromJson(json["h_54"]),
    h55: json["h_55"] == null ? null : H490.fromJson(json["h_55"]),
    h56: json["h_56"] == null ? null : H490.fromJson(json["h_56"]),
    h57: json["h_57"] == null ? null : H490.fromJson(json["h_57"]),
    h58: json["h_58"] == null ? null : H490.fromJson(json["h_58"]),
    h59: json["h_59"] == null ? null : H490.fromJson(json["h_59"]),
    h60: json["h_60"] == null ? null : H490.fromJson(json["h_60"]),
    h61: json["h_61"] == null ? null : H490.fromJson(json["h_61"]),
    h62: json["h_62"] == null ? null : H490.fromJson(json["h_62"]),
    h63: json["h_63"] == null ? null : H490.fromJson(json["h_63"]),
    h64: json["h_64"] == null ? null : H490.fromJson(json["h_64"]),
  );

  Map<String, dynamic> toJson() => {
    "h_53": h53 == null ? null : h53.toJson(),
    "h_54": h54 == null ? null : h54.toJson(),
    "h_55": h55 == null ? null : h55.toJson(),
    "h_56": h56 == null ? null : h56.toJson(),
    "h_57": h57 == null ? null : h57.toJson(),
    "h_58": h58 == null ? null : h58.toJson(),
    "h_59": h59 == null ? null : h59.toJson(),
    "h_60": h60 == null ? null : h60.toJson(),
    "h_61": h61 == null ? null : h61.toJson(),
    "h_62": h62 == null ? null : h62.toJson(),
    "h_63": h63 == null ? null : h63.toJson(),
    "h_64": h64 == null ? null : h64.toJson(),
  };
}

class Bank {
  Bank({
    this.h10,
    this.h12,
  });

  H490 h10;
  H490 h12;

  factory Bank.fromJson(Map<String, dynamic> json) => Bank(
    h10: json["h_10"] == null ? null : H490.fromJson(json["h_10"]),
    h12: json["h_12"] == null ? null : H490.fromJson(json["h_12"]),
  );

  Map<String, dynamic> toJson() => {
    "h_10": h10 == null ? null : h10.toJson(),
    "h_12": h12 == null ? null : h12.toJson(),
  };
}

class Bounties {
  Bounties({
    this.h232,
    this.h236,
    this.m201,
    this.m202,
    this.m203,
  });

  H490 h232;
  H490 h236;
  M225 m201;
  M225 m202;
  M225 m203;

  factory Bounties.fromJson(Map<String, dynamic> json) => Bounties(
    h232: json["h_232"] == null ? null : H490.fromJson(json["h_232"]),
    h236: json["h_236"] == null ? null : H490.fromJson(json["h_236"]),
    m201: json["m_201"] == null ? null : M225.fromJson(json["m_201"]),
    m202: json["m_202"] == null ? null : M225.fromJson(json["m_202"]),
    m203: json["m_203"] == null ? null : M225.fromJson(json["m_203"]),
  );

  Map<String, dynamic> toJson() => {
    "h_232": h232 == null ? null : h232.toJson(),
    "h_236": h236 == null ? null : h236.toJson(),
    "m_201": m201 == null ? null : m201.toJson(),
    "m_202": m202 == null ? null : m202.toJson(),
    "m_203": m203 == null ? null : m203.toJson(),
  };
}

class Cannabis {
  Cannabis({
    this.h26,
    this.h29,
  });

  H490 h26;
  H490 h29;

  factory Cannabis.fromJson(Map<String, dynamic> json) => Cannabis(
    h26: json["h_26"] == null ? null : H490.fromJson(json["h_26"]),
    h29: json["h_29"] == null ? null : H490.fromJson(json["h_29"]),
  );

  Map<String, dynamic> toJson() => {
    "h_26": h26 == null ? null : h26.toJson(),
    "h_29": h29 == null ? null : h29.toJson(),
  };
}

class Casino {
  Casino({
    this.h237,
    this.h269,
    this.h275,
    this.h276,
    this.h326,
    this.h327,
    this.h338,
    this.h427,
    this.h431,
    this.h437,
    this.h513,
    this.h519,
  });

  H490 h237;
  H490 h269;
  H490 h275;
  H490 h276;
  H490 h326;
  H490 h327;
  H490 h338;
  H490 h427;
  H490 h431;
  H490 h437;
  H490 h513;
  H490 h519;

  factory Casino.fromJson(Map<String, dynamic> json) => Casino(
    h237: json["h_237"] == null ? null : H490.fromJson(json["h_237"]),
    h269: json["h_269"] == null ? null : H490.fromJson(json["h_269"]),
    h275: json["h_275"] == null ? null : H490.fromJson(json["h_275"]),
    h276: json["h_276"] == null ? null : H490.fromJson(json["h_276"]),
    h326: json["h_326"] == null ? null : H490.fromJson(json["h_326"]),
    h327: json["h_327"] == null ? null : H490.fromJson(json["h_327"]),
    h338: json["h_338"] == null ? null : H490.fromJson(json["h_338"]),
    h427: json["h_427"] == null ? null : H490.fromJson(json["h_427"]),
    h431: json["h_431"] == null ? null : H490.fromJson(json["h_431"]),
    h437: json["h_437"] == null ? null : H490.fromJson(json["h_437"]),
    h513: json["h_513"] == null ? null : H490.fromJson(json["h_513"]),
    h519: json["h_519"] == null ? null : H490.fromJson(json["h_519"]),
  );

  Map<String, dynamic> toJson() => {
    "h_237": h237 == null ? null : h237.toJson(),
    "h_269": h269 == null ? null : h269.toJson(),
    "h_275": h275 == null ? null : h275.toJson(),
    "h_276": h276 == null ? null : h276.toJson(),
    "h_326": h326 == null ? null : h326.toJson(),
    "h_327": h327 == null ? null : h327.toJson(),
    "h_338": h338 == null ? null : h338.toJson(),
    "h_427": h427 == null ? null : h427.toJson(),
    "h_431": h431 == null ? null : h431.toJson(),
    "h_437": h437 == null ? null : h437.toJson(),
    "h_513": h513 == null ? null : h513.toJson(),
    "h_519": h519 == null ? null : h519.toJson(),
  };
}

class Chains {
  Chains({
    this.h253,
    this.h255,
    this.h257,
    this.h475,
    this.h476,
    this.h641,
    this.h916,
  });

  H490 h253;
  H490 h255;
  H490 h257;
  H490 h475;
  H490 h476;
  H490 h641;
  H490 h916;

  factory Chains.fromJson(Map<String, dynamic> json) => Chains(
    h253: json["h_253"] == null ? null : H490.fromJson(json["h_253"]),
    h255: json["h_255"] == null ? null : H490.fromJson(json["h_255"]),
    h257: json["h_257"] == null ? null : H490.fromJson(json["h_257"]),
    h475: json["h_475"] == null ? null : H490.fromJson(json["h_475"]),
    h476: json["h_476"] == null ? null : H490.fromJson(json["h_476"]),
    h641: json["h_641"] == null ? null : H490.fromJson(json["h_641"]),
    h916: json["h_916"] == null ? null : H490.fromJson(json["h_916"]),
  );

  Map<String, dynamic> toJson() => {
    "h_253": h253 == null ? null : h253.toJson(),
    "h_255": h255 == null ? null : h255.toJson(),
    "h_257": h257 == null ? null : h257.toJson(),
    "h_475": h475 == null ? null : h475.toJson(),
    "h_476": h476 == null ? null : h476.toJson(),
    "h_641": h641 == null ? null : h641.toJson(),
    "h_916": h916 == null ? null : h916.toJson(),
  };
}

class City {
  City({
    this.h1,
    this.h238,
    this.h271,
    this.h743,
    this.m204,
    this.m205,
    this.m206,
  });

  H490 h1;
  H490 h238;
  H490 h271;
  H490 h743;
  M225 m204;
  M225 m205;
  M225 m206;

  factory City.fromJson(Map<String, dynamic> json) => City(
    h1: json["h_1"] == null ? null : H490.fromJson(json["h_1"]),
    h238: json["h_238"] == null ? null : H490.fromJson(json["h_238"]),
    h271: json["h_271"] == null ? null : H490.fromJson(json["h_271"]),
    h743: json["h_743"] == null ? null : H490.fromJson(json["h_743"]),
    m204: json["m_204"] == null ? null : M225.fromJson(json["m_204"]),
    m205: json["m_205"] == null ? null : M225.fromJson(json["m_205"]),
    m206: json["m_206"] == null ? null : M225.fromJson(json["m_206"]),
  );

  Map<String, dynamic> toJson() => {
    "h_1": h1 == null ? null : h1.toJson(),
    "h_238": h238 == null ? null : h238.toJson(),
    "h_271": h271 == null ? null : h271.toJson(),
    "h_743": h743 == null ? null : h743.toJson(),
    "m_204": m204 == null ? null : m204.toJson(),
    "m_205": m205 == null ? null : m205.toJson(),
    "m_206": m206 == null ? null : m206.toJson(),
  };
}

class CityJobs {
  CityJobs({
    this.h220,
  });

  H490 h220;

  factory CityJobs.fromJson(Map<String, dynamic> json) => CityJobs(
    h220: json["h_220"] == null ? null : H490.fromJson(json["h_220"]),
  );

  Map<String, dynamic> toJson() => {
    "h_220": h220 == null ? null : h220.toJson(),
  };
}

class Commitment {
  Commitment({
    this.m26,
    this.m27,
    this.m28,
    this.m29,
    this.m108,
    this.m109,
    this.m148,
    this.m149,
    this.m150,
    this.m151,
  });

  M225 m26;
  M225 m27;
  M225 m28;
  M225 m29;
  M225 m108;
  M225 m109;
  M225 m148;
  M225 m149;
  M225 m150;
  M225 m151;

  factory Commitment.fromJson(Map<String, dynamic> json) => Commitment(
    m26: json["m_26"] == null ? null : M225.fromJson(json["m_26"]),
    m27: json["m_27"] == null ? null : M225.fromJson(json["m_27"]),
    m28: json["m_28"] == null ? null : M225.fromJson(json["m_28"]),
    m29: json["m_29"] == null ? null : M225.fromJson(json["m_29"]),
    m108: json["m_108"] == null ? null : M225.fromJson(json["m_108"]),
    m109: json["m_109"] == null ? null : M225.fromJson(json["m_109"]),
    m148: json["m_148"] == null ? null : M225.fromJson(json["m_148"]),
    m149: json["m_149"] == null ? null : M225.fromJson(json["m_149"]),
    m150: json["m_150"] == null ? null : M225.fromJson(json["m_150"]),
    m151: json["m_151"] == null ? null : M225.fromJson(json["m_151"]),
  );

  Map<String, dynamic> toJson() => {
    "m_26": m26 == null ? null : m26.toJson(),
    "m_27": m27 == null ? null : m27.toJson(),
    "m_28": m28 == null ? null : m28.toJson(),
    "m_29": m29 == null ? null : m29.toJson(),
    "m_108": m108 == null ? null : m108.toJson(),
    "m_109": m109 == null ? null : m109.toJson(),
    "m_148": m148 == null ? null : m148.toJson(),
    "m_149": m149 == null ? null : m149.toJson(),
    "m_150": m150 == null ? null : m150.toJson(),
    "m_151": m151 == null ? null : m151.toJson(),
  };
}

class ComputerCrimes {
  ComputerCrimes({
    this.h155,
    this.h161,
    this.m54,
    this.m55,
    this.m56,
    this.m57,
    this.m58,
    this.m59,
    this.m60,
    this.m61,
    this.m62,
    this.m63,
    this.m142,
    this.m143,
    this.m144,
    this.m145,
    this.m146,
    this.m147,
  });

  H490 h155;
  H490 h161;
  M225 m54;
  M225 m55;
  M225 m56;
  M225 m57;
  M225 m58;
  M225 m59;
  M225 m60;
  M225 m61;
  M225 m62;
  M225 m63;
  M225 m142;
  M225 m143;
  M225 m144;
  M225 m145;
  M225 m146;
  M225 m147;

  factory ComputerCrimes.fromJson(Map<String, dynamic> json) => ComputerCrimes(
    h155: json["h_155"] == null ? null : H490.fromJson(json["h_155"]),
    h161: json["h_161"] == null ? null : H490.fromJson(json["h_161"]),
    m54: json["m_54"] == null ? null : M225.fromJson(json["m_54"]),
    m55: json["m_55"] == null ? null : M225.fromJson(json["m_55"]),
    m56: json["m_56"] == null ? null : M225.fromJson(json["m_56"]),
    m57: json["m_57"] == null ? null : M225.fromJson(json["m_57"]),
    m58: json["m_58"] == null ? null : M225.fromJson(json["m_58"]),
    m59: json["m_59"] == null ? null : M225.fromJson(json["m_59"]),
    m60: json["m_60"] == null ? null : M225.fromJson(json["m_60"]),
    m61: json["m_61"] == null ? null : M225.fromJson(json["m_61"]),
    m62: json["m_62"] == null ? null : M225.fromJson(json["m_62"]),
    m63: json["m_63"] == null ? null : M225.fromJson(json["m_63"]),
    m142: json["m_142"] == null ? null : M225.fromJson(json["m_142"]),
    m143: json["m_143"] == null ? null : M225.fromJson(json["m_143"]),
    m144: json["m_144"] == null ? null : M225.fromJson(json["m_144"]),
    m145: json["m_145"] == null ? null : M225.fromJson(json["m_145"]),
    m146: json["m_146"] == null ? null : M225.fromJson(json["m_146"]),
    m147: json["m_147"] == null ? null : M225.fromJson(json["m_147"]),
  );

  Map<String, dynamic> toJson() => {
    "h_155": h155 == null ? null : h155.toJson(),
    "h_161": h161 == null ? null : h161.toJson(),
    "m_54": m54 == null ? null : m54.toJson(),
    "m_55": m55 == null ? null : m55.toJson(),
    "m_56": m56 == null ? null : m56.toJson(),
    "m_57": m57 == null ? null : m57.toJson(),
    "m_58": m58 == null ? null : m58.toJson(),
    "m_59": m59 == null ? null : m59.toJson(),
    "m_60": m60 == null ? null : m60.toJson(),
    "m_61": m61 == null ? null : m61.toJson(),
    "m_62": m62 == null ? null : m62.toJson(),
    "m_63": m63 == null ? null : m63.toJson(),
    "m_142": m142 == null ? null : m142.toJson(),
    "m_143": m143 == null ? null : m143.toJson(),
    "m_144": m144 == null ? null : m144.toJson(),
    "m_145": m145 == null ? null : m145.toJson(),
    "m_146": m146 == null ? null : m146.toJson(),
    "m_147": m147 == null ? null : m147.toJson(),
  };
}

class Consume {
  Consume({
    this.h527,
    this.h534,
    this.h537,
    this.h538,
    this.h539,
  });

  H490 h527;
  H490 h534;
  H490 h537;
  H490 h538;
  H490 h539;

  factory Consume.fromJson(Map<String, dynamic> json) => Consume(
    h527: json["h_527"] == null ? null : H490.fromJson(json["h_527"]),
    h534: json["h_534"] == null ? null : H490.fromJson(json["h_534"]),
    h537: json["h_537"] == null ? null : H490.fromJson(json["h_537"]),
    h538: json["h_538"] == null ? null : H490.fromJson(json["h_538"]),
    h539: json["h_539"] == null ? null : H490.fromJson(json["h_539"]),
  );

  Map<String, dynamic> toJson() => {
    "h_527": h527 == null ? null : h527.toJson(),
    "h_534": h534 == null ? null : h534.toJson(),
    "h_537": h537 == null ? null : h537.toJson(),
    "h_538": h538 == null ? null : h538.toJson(),
    "h_539": h539 == null ? null : h539.toJson(),
  };
}

class Courses {
  Courses({
    this.h651,
    this.h653,
    this.h656,
    this.h659,
  });

  H490 h651;
  H490 h653;
  H490 h656;
  H490 h659;

  factory Courses.fromJson(Map<String, dynamic> json) => Courses(
    h651: json["h_651"] == null ? null : H490.fromJson(json["h_651"]),
    h653: json["h_653"] == null ? null : H490.fromJson(json["h_653"]),
    h656: json["h_656"] == null ? null : H490.fromJson(json["h_656"]),
    h659: json["h_659"] == null ? null : H490.fromJson(json["h_659"]),
  );

  Map<String, dynamic> toJson() => {
    "h_651": h651 == null ? null : h651.toJson(),
    "h_653": h653 == null ? null : h653.toJson(),
    "h_656": h656 == null ? null : h656.toJson(),
    "h_659": h659 == null ? null : h659.toJson(),
  };
}

class CriticalHits {
  CriticalHits({
    this.h20,
    this.h227,
    this.m195,
    this.m196,
    this.m197,
  });

  H490 h20;
  H490 h227;
  M225 m195;
  M225 m196;
  M225 m197;

  factory CriticalHits.fromJson(Map<String, dynamic> json) => CriticalHits(
    h20: json["h_20"] == null ? null : H490.fromJson(json["h_20"]),
    h227: json["h_227"] == null ? null : H490.fromJson(json["h_227"]),
    m195: json["m_195"] == null ? null : M225.fromJson(json["m_195"]),
    m196: json["m_196"] == null ? null : M225.fromJson(json["m_196"]),
    m197: json["m_197"] == null ? null : M225.fromJson(json["m_197"]),
  );

  Map<String, dynamic> toJson() => {
    "h_20": h20 == null ? null : h20.toJson(),
    "h_227": h227 == null ? null : h227.toJson(),
    "m_195": m195 == null ? null : m195.toJson(),
    "m_196": m196 == null ? null : m196.toJson(),
    "m_197": m197 == null ? null : m197.toJson(),
  };
}

class Damage {
  Damage({
    this.h740,
    this.h741,
    this.h786,
    this.h1001,
    this.h1002,
    this.h1003,
    this.h1004,
  });

  H490 h740;
  H490 h741;
  H490 h786;
  H490 h1001;
  H490 h1002;
  H490 h1003;
  H490 h1004;

  factory Damage.fromJson(Map<String, dynamic> json) => Damage(
    h740: json["h_740"] == null ? null : H490.fromJson(json["h_740"]),
    h741: json["h_741"] == null ? null : H490.fromJson(json["h_741"]),
    h786: json["h_786"] == null ? null : H490.fromJson(json["h_786"]),
    h1001: json["h_1001"] == null ? null : H490.fromJson(json["h_1001"]),
    h1002: json["h_1002"] == null ? null : H490.fromJson(json["h_1002"]),
    h1003: json["h_1003"] == null ? null : H490.fromJson(json["h_1003"]),
    h1004: json["h_1004"] == null ? null : H490.fromJson(json["h_1004"]),
  );

  Map<String, dynamic> toJson() => {
    "h_740": h740 == null ? null : h740.toJson(),
    "h_741": h741 == null ? null : h741.toJson(),
    "h_786": h786 == null ? null : h786.toJson(),
    "h_1001": h1001 == null ? null : h1001.toJson(),
    "h_1002": h1002 == null ? null : h1002.toJson(),
    "h_1003": h1003 == null ? null : h1003.toJson(),
    "h_1004": h1004 == null ? null : h1004.toJson(),
  };
}

class Defends {
  Defends({
    this.h22,
    this.h228,
    this.h719,
    this.m179,
    this.m180,
    this.m181,
    this.m182,
    this.m183,
  });

  H490 h22;
  H490 h228;
  H490 h719;
  M225 m179;
  M225 m180;
  M225 m181;
  M225 m182;
  M225 m183;

  factory Defends.fromJson(Map<String, dynamic> json) => Defends(
    h22: json["h_22"] == null ? null : H490.fromJson(json["h_22"]),
    h228: json["h_228"] == null ? null : H490.fromJson(json["h_228"]),
    h719: json["h_719"] == null ? null : H490.fromJson(json["h_719"]),
    m179: json["m_179"] == null ? null : M225.fromJson(json["m_179"]),
    m180: json["m_180"] == null ? null : M225.fromJson(json["m_180"]),
    m181: json["m_181"] == null ? null : M225.fromJson(json["m_181"]),
    m182: json["m_182"] == null ? null : M225.fromJson(json["m_182"]),
    m183: json["m_183"] == null ? null : M225.fromJson(json["m_183"]),
  );

  Map<String, dynamic> toJson() => {
    "h_22": h22 == null ? null : h22.toJson(),
    "h_228": h228 == null ? null : h228.toJson(),
    "h_719": h719 == null ? null : h719.toJson(),
    "m_179": m179 == null ? null : m179.toJson(),
    "m_180": m180 == null ? null : m180.toJson(),
    "m_181": m181 == null ? null : m181.toJson(),
    "m_182": m182 == null ? null : m182.toJson(),
    "m_183": m183 == null ? null : m183.toJson(),
  };
}

class Defense {
  Defense({
    this.h240,
    this.h497,
    this.h498,
    this.h640,
  });

  H490 h240;
  H490 h497;
  H490 h498;
  H490 h640;

  factory Defense.fromJson(Map<String, dynamic> json) => Defense(
    h240: json["h_240"] == null ? null : H490.fromJson(json["h_240"]),
    h497: json["h_497"] == null ? null : H490.fromJson(json["h_497"]),
    h498: json["h_498"] == null ? null : H490.fromJson(json["h_498"]),
    h640: json["h_640"] == null ? null : H490.fromJson(json["h_640"]),
  );

  Map<String, dynamic> toJson() => {
    "h_240": h240 == null ? null : h240.toJson(),
    "h_497": h497 == null ? null : h497.toJson(),
    "h_498": h498 == null ? null : h498.toJson(),
    "h_640": h640 == null ? null : h640.toJson(),
  };
}

class Destinations {
  Destinations({
    this.h130,
    this.h131,
    this.h132,
    this.h133,
    this.h134,
    this.h135,
    this.h136,
    this.h137,
    this.h138,
    this.h139,
    this.h272,
  });

  H490 h130;
  H490 h131;
  H490 h132;
  H490 h133;
  H490 h134;
  H490 h135;
  H490 h136;
  H490 h137;
  H490 h138;
  H490 h139;
  H490 h272;

  factory Destinations.fromJson(Map<String, dynamic> json) => Destinations(
    h130: json["h_130"] == null ? null : H490.fromJson(json["h_130"]),
    h131: json["h_131"] == null ? null : H490.fromJson(json["h_131"]),
    h132: json["h_132"] == null ? null : H490.fromJson(json["h_132"]),
    h133: json["h_133"] == null ? null : H490.fromJson(json["h_133"]),
    h134: json["h_134"] == null ? null : H490.fromJson(json["h_134"]),
    h135: json["h_135"] == null ? null : H490.fromJson(json["h_135"]),
    h136: json["h_136"] == null ? null : H490.fromJson(json["h_136"]),
    h137: json["h_137"] == null ? null : H490.fromJson(json["h_137"]),
    h138: json["h_138"] == null ? null : H490.fromJson(json["h_138"]),
    h139: json["h_139"] == null ? null : H490.fromJson(json["h_139"]),
    h272: json["h_272"] == null ? null : H490.fromJson(json["h_272"]),
  );

  Map<String, dynamic> toJson() => {
    "h_130": h130 == null ? null : h130.toJson(),
    "h_131": h131 == null ? null : h131.toJson(),
    "h_132": h132 == null ? null : h132.toJson(),
    "h_133": h133 == null ? null : h133.toJson(),
    "h_134": h134 == null ? null : h134.toJson(),
    "h_135": h135 == null ? null : h135.toJson(),
    "h_136": h136 == null ? null : h136.toJson(),
    "h_137": h137 == null ? null : h137.toJson(),
    "h_138": h138 == null ? null : h138.toJson(),
    "h_139": h139 == null ? null : h139.toJson(),
    "h_272": h272 == null ? null : h272.toJson(),
  };
}

class Dexterity {
  Dexterity({
    this.h241,
    this.h629,
    this.h635,
    this.h638,
  });

  H490 h241;
  H490 h629;
  H490 h635;
  H490 h638;

  factory Dexterity.fromJson(Map<String, dynamic> json) => Dexterity(
    h241: json["h_241"] == null ? null : H490.fromJson(json["h_241"]),
    h629: json["h_629"] == null ? null : H490.fromJson(json["h_629"]),
    h635: json["h_635"] == null ? null : H490.fromJson(json["h_635"]),
    h638: json["h_638"] == null ? null : H490.fromJson(json["h_638"]),
  );

  Map<String, dynamic> toJson() => {
    "h_241": h241 == null ? null : h241.toJson(),
    "h_629": h629 == null ? null : h629.toJson(),
    "h_635": h635 == null ? null : h635.toJson(),
    "h_638": h638 == null ? null : h638.toJson(),
  };
}

class DirtyBomb {
  DirtyBomb({
    this.h14,
    this.h156,
    this.h231,
  });

  H490 h14;
  H490 h156;
  H490 h231;

  factory DirtyBomb.fromJson(Map<String, dynamic> json) => DirtyBomb(
    h14: json["h_14"] == null ? null : H490.fromJson(json["h_14"]),
    h156: json["h_156"] == null ? null : H490.fromJson(json["h_156"]),
    h231: json["h_231"] == null ? null : H490.fromJson(json["h_231"]),
  );

  Map<String, dynamic> toJson() => {
    "h_14": h14 == null ? null : h14.toJson(),
    "h_156": h156 == null ? null : h156.toJson(),
    "h_231": h231 == null ? null : h231.toJson(),
  };
}

class DogTag {
  DogTag({
    this.h221,
    this.h277,
  });

  H490 h221;
  H490 h277;

  factory DogTag.fromJson(Map<String, dynamic> json) => DogTag(
    h221: json["h_221"] == null ? null : H490.fromJson(json["h_221"]),
    h277: json["h_277"] == null ? null : H490.fromJson(json["h_277"]),
  );

  Map<String, dynamic> toJson() => {
    "h_221": h221 == null ? null : h221.toJson(),
    "h_277": h277 == null ? null : h277.toJson(),
  };
}

class Donations {
  Donations({
    this.h520,
    this.h521,
    this.h522,
    this.h523,
  });

  H490 h520;
  H490 h521;
  H490 h522;
  H490 h523;

  factory Donations.fromJson(Map<String, dynamic> json) => Donations(
    h520: json["h_520"] == null ? null : H490.fromJson(json["h_520"]),
    h521: json["h_521"] == null ? null : H490.fromJson(json["h_521"]),
    h522: json["h_522"] == null ? null : H490.fromJson(json["h_522"]),
    h523: json["h_523"] == null ? null : H490.fromJson(json["h_523"]),
  );

  Map<String, dynamic> toJson() => {
    "h_520": h520 == null ? null : h520.toJson(),
    "h_521": h521 == null ? null : h521.toJson(),
    "h_522": h522 == null ? null : h522.toJson(),
    "h_523": h523 == null ? null : h523.toJson(),
  };
}

class Donator {
  Donator({
    this.m210,
    this.m211,
    this.m212,
    this.m213,
    this.m214,
  });

  M225 m210;
  M225 m211;
  M225 m212;
  M225 m213;
  M225 m214;

  factory Donator.fromJson(Map<String, dynamic> json) => Donator(
    m210: json["m_210"] == null ? null : M225.fromJson(json["m_210"]),
    m211: json["m_211"] == null ? null : M225.fromJson(json["m_211"]),
    m212: json["m_212"] == null ? null : M225.fromJson(json["m_212"]),
    m213: json["m_213"] == null ? null : M225.fromJson(json["m_213"]),
    m214: json["m_214"] == null ? null : M225.fromJson(json["m_214"]),
  );

  Map<String, dynamic> toJson() => {
    "m_210": m210 == null ? null : m210.toJson(),
    "m_211": m211 == null ? null : m211.toJson(),
    "m_212": m212 == null ? null : m212.toJson(),
    "m_213": m213 == null ? null : m213.toJson(),
    "m_214": m214 == null ? null : m214.toJson(),
  };
}

class DrugDeals {
  DrugDeals({
    this.h153,
    this.m85,
    this.m86,
    this.m87,
    this.m88,
    this.m152,
    this.m153,
    this.m154,
    this.m155,
  });

  H490 h153;
  M225 m85;
  M225 m86;
  M225 m87;
  M225 m88;
  M225 m152;
  M225 m153;
  M225 m154;
  M225 m155;

  factory DrugDeals.fromJson(Map<String, dynamic> json) => DrugDeals(
    h153: json["h_153"] == null ? null : H490.fromJson(json["h_153"]),
    m85: json["m_85"] == null ? null : M225.fromJson(json["m_85"]),
    m86: json["m_86"] == null ? null : M225.fromJson(json["m_86"]),
    m87: json["m_87"] == null ? null : M225.fromJson(json["m_87"]),
    m88: json["m_88"] == null ? null : M225.fromJson(json["m_88"]),
    m152: json["m_152"] == null ? null : M225.fromJson(json["m_152"]),
    m153: json["m_153"] == null ? null : M225.fromJson(json["m_153"]),
    m154: json["m_154"] == null ? null : M225.fromJson(json["m_154"]),
    m155: json["m_155"] == null ? null : M225.fromJson(json["m_155"]),
  );

  Map<String, dynamic> toJson() => {
    "h_153": h153 == null ? null : h153.toJson(),
    "m_85": m85 == null ? null : m85.toJson(),
    "m_86": m86 == null ? null : m86.toJson(),
    "m_87": m87 == null ? null : m87.toJson(),
    "m_88": m88 == null ? null : m88.toJson(),
    "m_152": m152 == null ? null : m152.toJson(),
    "m_153": m153 == null ? null : m153.toJson(),
    "m_154": m154 == null ? null : m154.toJson(),
    "m_155": m155 == null ? null : m155.toJson(),
  };
}

class Ecstasy {
  Ecstasy({
    this.h30,
  });

  H490 h30;

  factory Ecstasy.fromJson(Map<String, dynamic> json) => Ecstasy(
    h30: json["h_30"] == null ? null : H490.fromJson(json["h_30"]),
  );

  Map<String, dynamic> toJson() => {
    "h_30": h30 == null ? null : h30.toJson(),
  };
}

class Elimination {
  Elimination({
    this.h212,
    this.h226,
    this.h279,
    this.h280,
  });

  H490 h212;
  H490 h226;
  H490 h279;
  H490 h280;

  factory Elimination.fromJson(Map<String, dynamic> json) => Elimination(
    h212: json["h_212"] == null ? null : H490.fromJson(json["h_212"]),
    h226: json["h_226"] == null ? null : H490.fromJson(json["h_226"]),
    h279: json["h_279"] == null ? null : H490.fromJson(json["h_279"]),
    h280: json["h_280"] == null ? null : H490.fromJson(json["h_280"]),
  );

  Map<String, dynamic> toJson() => {
    "h_212": h212 == null ? null : h212.toJson(),
    "h_226": h226 == null ? null : h226.toJson(),
    "h_279": h279 == null ? null : h279.toJson(),
    "h_280": h280 == null ? null : h280.toJson(),
  };
}

class Escapes {
  Escapes({
    this.m184,
    this.m185,
    this.m186,
    this.m187,
    this.m188,
    this.m189,
  });

  M225 m184;
  M225 m185;
  M225 m186;
  M225 m187;
  M225 m188;
  M225 m189;

  factory Escapes.fromJson(Map<String, dynamic> json) => Escapes(
    m184: json["m_184"] == null ? null : M225.fromJson(json["m_184"]),
    m185: json["m_185"] == null ? null : M225.fromJson(json["m_185"]),
    m186: json["m_186"] == null ? null : M225.fromJson(json["m_186"]),
    m187: json["m_187"] == null ? null : M225.fromJson(json["m_187"]),
    m188: json["m_188"] == null ? null : M225.fromJson(json["m_188"]),
    m189: json["m_189"] == null ? null : M225.fromJson(json["m_189"]),
  );

  Map<String, dynamic> toJson() => {
    "m_184": m184 == null ? null : m184.toJson(),
    "m_185": m185 == null ? null : m185.toJson(),
    "m_186": m186 == null ? null : m186.toJson(),
    "m_187": m187 == null ? null : m187.toJson(),
    "m_188": m188 == null ? null : m188.toJson(),
    "m_189": m189 == null ? null : m189.toJson(),
  };
}

class Estate {
  Estate({
    this.h9,
    this.h258,
    this.h860,
  });

  H490 h9;
  H490 h258;
  H490 h860;

  factory Estate.fromJson(Map<String, dynamic> json) => Estate(
    h9: json["h_9"] == null ? null : H490.fromJson(json["h_9"]),
    h258: json["h_258"] == null ? null : H490.fromJson(json["h_258"]),
    h860: json["h_860"] == null ? null : H490.fromJson(json["h_860"]),
  );

  Map<String, dynamic> toJson() => {
    "h_9": h9 == null ? null : h9.toJson(),
    "h_258": h258 == null ? null : h258.toJson(),
    "h_860": h860 == null ? null : h860.toJson(),
  };
}

class Events {
  Events({
    this.h309,
    this.h375,
    this.h443,
    this.h459,
    this.h731,
  });

  H490 h309;
  H490 h375;
  H490 h443;
  H490 h459;
  H490 h731;

  factory Events.fromJson(Map<String, dynamic> json) => Events(
    h309: json["h_309"] == null ? null : H490.fromJson(json["h_309"]),
    h375: json["h_375"] == null ? null : H490.fromJson(json["h_375"]),
    h443: json["h_443"] == null ? null : H490.fromJson(json["h_443"]),
    h459: json["h_459"] == null ? null : H490.fromJson(json["h_459"]),
    h731: json["h_731"] == null ? null : H490.fromJson(json["h_731"]),
  );

  Map<String, dynamic> toJson() => {
    "h_309": h309 == null ? null : h309.toJson(),
    "h_375": h375 == null ? null : h375.toJson(),
    "h_443": h443 == null ? null : h443.toJson(),
    "h_459": h459 == null ? null : h459.toJson(),
    "h_731": h731 == null ? null : h731.toJson(),
  };
}

class FinishingHits {
  FinishingHits({
    this.h28,
    this.h141,
    this.h142,
    this.h143,
    this.h144,
    this.h145,
    this.h146,
    this.h147,
    this.h148,
    this.h149,
    this.h150,
    this.h515,
    this.h611,
    this.h828,
    this.h871,
  });

  H490 h28;
  H490 h141;
  H490 h142;
  H490 h143;
  H490 h144;
  H490 h145;
  H490 h146;
  H490 h147;
  H490 h148;
  H490 h149;
  H490 h150;
  H490 h515;
  H490 h611;
  H490 h828;
  H490 h871;

  factory FinishingHits.fromJson(Map<String, dynamic> json) => FinishingHits(
    h28: json["h_28"] == null ? null : H490.fromJson(json["h_28"]),
    h141: json["h_141"] == null ? null : H490.fromJson(json["h_141"]),
    h142: json["h_142"] == null ? null : H490.fromJson(json["h_142"]),
    h143: json["h_143"] == null ? null : H490.fromJson(json["h_143"]),
    h144: json["h_144"] == null ? null : H490.fromJson(json["h_144"]),
    h145: json["h_145"] == null ? null : H490.fromJson(json["h_145"]),
    h146: json["h_146"] == null ? null : H490.fromJson(json["h_146"]),
    h147: json["h_147"] == null ? null : H490.fromJson(json["h_147"]),
    h148: json["h_148"] == null ? null : H490.fromJson(json["h_148"]),
    h149: json["h_149"] == null ? null : H490.fromJson(json["h_149"]),
    h150: json["h_150"] == null ? null : H490.fromJson(json["h_150"]),
    h515: json["h_515"] == null ? null : H490.fromJson(json["h_515"]),
    h611: json["h_611"] == null ? null : H490.fromJson(json["h_611"]),
    h828: json["h_828"] == null ? null : H490.fromJson(json["h_828"]),
    h871: json["h_871"] == null ? null : H490.fromJson(json["h_871"]),
  );

  Map<String, dynamic> toJson() => {
    "h_28": h28 == null ? null : h28.toJson(),
    "h_141": h141 == null ? null : h141.toJson(),
    "h_142": h142 == null ? null : h142.toJson(),
    "h_143": h143 == null ? null : h143.toJson(),
    "h_144": h144 == null ? null : h144.toJson(),
    "h_145": h145 == null ? null : h145.toJson(),
    "h_146": h146 == null ? null : h146.toJson(),
    "h_147": h147 == null ? null : h147.toJson(),
    "h_148": h148 == null ? null : h148.toJson(),
    "h_149": h149 == null ? null : h149.toJson(),
    "h_150": h150 == null ? null : h150.toJson(),
    "h_515": h515 == null ? null : h515.toJson(),
    "h_611": h611 == null ? null : h611.toJson(),
    "h_828": h828 == null ? null : h828.toJson(),
    "h_871": h871 == null ? null : h871.toJson(),
  };
}

class FireRounds {
  FireRounds({
    this.h140,
    this.h151,
    this.h834,
    this.h836,
  });

  H490 h140;
  H490 h151;
  H490 h834;
  H490 h836;

  factory FireRounds.fromJson(Map<String, dynamic> json) => FireRounds(
    h140: json["h_140"] == null ? null : H490.fromJson(json["h_140"]),
    h151: json["h_151"] == null ? null : H490.fromJson(json["h_151"]),
    h834: json["h_834"] == null ? null : H490.fromJson(json["h_834"]),
    h836: json["h_836"] == null ? null : H490.fromJson(json["h_836"]),
  );

  Map<String, dynamic> toJson() => {
    "h_140": h140 == null ? null : h140.toJson(),
    "h_151": h151 == null ? null : h151.toJson(),
    "h_834": h834 == null ? null : h834.toJson(),
    "h_836": h836 == null ? null : h836.toJson(),
  };
}

class FraudCrimes {
  FraudCrimes({
    this.h24,
    this.m97,
    this.m98,
    this.m99,
    this.m100,
    this.m101,
    this.m117,
    this.m118,
    this.m119,
    this.m120,
    this.m127,
    this.m128,
    this.m129,
    this.m130,
    this.m131,
    this.m132,
    this.m173,
  });

  H490 h24;
  M225 m97;
  M225 m98;
  M225 m99;
  M225 m100;
  M225 m101;
  M225 m117;
  M225 m118;
  M225 m119;
  M225 m120;
  M225 m127;
  M225 m128;
  M225 m129;
  M225 m130;
  M225 m131;
  M225 m132;
  M225 m173;

  factory FraudCrimes.fromJson(Map<String, dynamic> json) => FraudCrimes(
    h24: json["h_24"] == null ? null : H490.fromJson(json["h_24"]),
    m97: json["m_97"] == null ? null : M225.fromJson(json["m_97"]),
    m98: json["m_98"] == null ? null : M225.fromJson(json["m_98"]),
    m99: json["m_99"] == null ? null : M225.fromJson(json["m_99"]),
    m100: json["m_100"] == null ? null : M225.fromJson(json["m_100"]),
    m101: json["m_101"] == null ? null : M225.fromJson(json["m_101"]),
    m117: json["m_117"] == null ? null : M225.fromJson(json["m_117"]),
    m118: json["m_118"] == null ? null : M225.fromJson(json["m_118"]),
    m119: json["m_119"] == null ? null : M225.fromJson(json["m_119"]),
    m120: json["m_120"] == null ? null : M225.fromJson(json["m_120"]),
    m127: json["m_127"] == null ? null : M225.fromJson(json["m_127"]),
    m128: json["m_128"] == null ? null : M225.fromJson(json["m_128"]),
    m129: json["m_129"] == null ? null : M225.fromJson(json["m_129"]),
    m130: json["m_130"] == null ? null : M225.fromJson(json["m_130"]),
    m131: json["m_131"] == null ? null : M225.fromJson(json["m_131"]),
    m132: json["m_132"] == null ? null : M225.fromJson(json["m_132"]),
    m173: json["m_173"] == null ? null : M225.fromJson(json["m_173"]),
  );

  Map<String, dynamic> toJson() => {
    "h_24": h24 == null ? null : h24.toJson(),
    "m_97": m97 == null ? null : m97.toJson(),
    "m_98": m98 == null ? null : m98.toJson(),
    "m_99": m99 == null ? null : m99.toJson(),
    "m_100": m100 == null ? null : m100.toJson(),
    "m_101": m101 == null ? null : m101.toJson(),
    "m_117": m117 == null ? null : m117.toJson(),
    "m_118": m118 == null ? null : m118.toJson(),
    "m_119": m119 == null ? null : m119.toJson(),
    "m_120": m120 == null ? null : m120.toJson(),
    "m_127": m127 == null ? null : m127.toJson(),
    "m_128": m128 == null ? null : m128.toJson(),
    "m_129": m129 == null ? null : m129.toJson(),
    "m_130": m130 == null ? null : m130.toJson(),
    "m_131": m131 == null ? null : m131.toJson(),
    "m_132": m132 == null ? null : m132.toJson(),
    "m_173": m173 == null ? null : m173.toJson(),
  };
}

class Hunting {
  Hunting({
    this.h50,
    this.h51,
    this.h52,
  });

  H490 h50;
  H490 h51;
  H490 h52;

  factory Hunting.fromJson(Map<String, dynamic> json) => Hunting(
    h50: json["h_50"] == null ? null : H490.fromJson(json["h_50"]),
    h51: json["h_51"] == null ? null : H490.fromJson(json["h_51"]),
    h52: json["h_52"] == null ? null : H490.fromJson(json["h_52"]),
  );

  Map<String, dynamic> toJson() => {
    "h_50": h50 == null ? null : h50.toJson(),
    "h_51": h51 == null ? null : h51.toJson(),
    "h_52": h52 == null ? null : h52.toJson(),
  };
}

class IllegalProducts {
  IllegalProducts({
    this.h152,
  });

  H490 h152;

  factory IllegalProducts.fromJson(Map<String, dynamic> json) => IllegalProducts(
    h152: json["h_152"] == null ? null : H490.fromJson(json["h_152"]),
  );

  Map<String, dynamic> toJson() => {
    "h_152": h152 == null ? null : h152.toJson(),
  };
}

class ImportItems {
  ImportItems({
    this.h541,
    this.h542,
    this.h543,
    this.h853,
  });

  H490 h541;
  H490 h542;
  H490 h543;
  H490 h853;

  factory ImportItems.fromJson(Map<String, dynamic> json) => ImportItems(
    h541: json["h_541"] == null ? null : H490.fromJson(json["h_541"]),
    h542: json["h_542"] == null ? null : H490.fromJson(json["h_542"]),
    h543: json["h_543"] == null ? null : H490.fromJson(json["h_543"]),
    h853: json["h_853"] == null ? null : H490.fromJson(json["h_853"]),
  );

  Map<String, dynamic> toJson() => {
    "h_541": h541 == null ? null : h541.toJson(),
    "h_542": h542 == null ? null : h542.toJson(),
    "h_543": h543 == null ? null : h543.toJson(),
    "h_853": h853 == null ? null : h853.toJson(),
  };
}

class Jail {
  Jail({
    this.h248,
    this.h249,
    this.h250,
    this.h252,
    this.h906,
    this.m30,
    this.m31,
    this.m32,
    this.m33,
    this.m105,
    this.m106,
    this.m107,
  });

  H490 h248;
  H490 h249;
  H490 h250;
  H490 h252;
  H490 h906;
  M225 m30;
  M225 m31;
  M225 m32;
  M225 m33;
  M225 m105;
  M225 m106;
  M225 m107;

  factory Jail.fromJson(Map<String, dynamic> json) => Jail(
    h248: json["h_248"] == null ? null : H490.fromJson(json["h_248"]),
    h249: json["h_249"] == null ? null : H490.fromJson(json["h_249"]),
    h250: json["h_250"] == null ? null : H490.fromJson(json["h_250"]),
    h252: json["h_252"] == null ? null : H490.fromJson(json["h_252"]),
    h906: json["h_906"] == null ? null : H490.fromJson(json["h_906"]),
    m30: json["m_30"] == null ? null : M225.fromJson(json["m_30"]),
    m31: json["m_31"] == null ? null : M225.fromJson(json["m_31"]),
    m32: json["m_32"] == null ? null : M225.fromJson(json["m_32"]),
    m33: json["m_33"] == null ? null : M225.fromJson(json["m_33"]),
    m105: json["m_105"] == null ? null : M225.fromJson(json["m_105"]),
    m106: json["m_106"] == null ? null : M225.fromJson(json["m_106"]),
    m107: json["m_107"] == null ? null : M225.fromJson(json["m_107"]),
  );

  Map<String, dynamic> toJson() => {
    "h_248": h248 == null ? null : h248.toJson(),
    "h_249": h249 == null ? null : h249.toJson(),
    "h_250": h250 == null ? null : h250.toJson(),
    "h_252": h252 == null ? null : h252.toJson(),
    "h_906": h906 == null ? null : h906.toJson(),
    "m_30": m30 == null ? null : m30.toJson(),
    "m_31": m31 == null ? null : m31.toJson(),
    "m_32": m32 == null ? null : m32.toJson(),
    "m_33": m33 == null ? null : m33.toJson(),
    "m_105": m105 == null ? null : m105.toJson(),
    "m_106": m106 == null ? null : m106.toJson(),
    "m_107": m107 == null ? null : m107.toJson(),
  };
}

class JobPoints {
  JobPoints({
    this.h4,
    this.h164,
    this.h742,
  });

  H490 h4;
  H490 h164;
  H490 h742;

  factory JobPoints.fromJson(Map<String, dynamic> json) => JobPoints(
    h4: json["h_4"] == null ? null : H490.fromJson(json["h_4"]),
    h164: json["h_164"] == null ? null : H490.fromJson(json["h_164"]),
    h742: json["h_742"] == null ? null : H490.fromJson(json["h_742"]),
  );

  Map<String, dynamic> toJson() => {
    "h_4": h4 == null ? null : h4.toJson(),
    "h_164": h164 == null ? null : h164.toJson(),
    "h_742": h742 == null ? null : h742.toJson(),
  };
}

class Ketamine {
  Ketamine({
    this.h31,
  });

  H490 h31;

  factory Ketamine.fromJson(Map<String, dynamic> json) => Ketamine(
    h31: json["h_31"] == null ? null : H490.fromJson(json["h_31"]),
  );

  Map<String, dynamic> toJson() => {
    "h_31": h31 == null ? null : h31.toJson(),
  };
}

class KillStreak {
  KillStreak({
    this.h15,
    this.h16,
    this.h17,
    this.m190,
    this.m191,
    this.m192,
    this.m193,
    this.m194,
  });

  H490 h15;
  H490 h16;
  H490 h17;
  M225 m190;
  M225 m191;
  M225 m192;
  M225 m193;
  M225 m194;

  factory KillStreak.fromJson(Map<String, dynamic> json) => KillStreak(
    h15: json["h_15"] == null ? null : H490.fromJson(json["h_15"]),
    h16: json["h_16"] == null ? null : H490.fromJson(json["h_16"]),
    h17: json["h_17"] == null ? null : H490.fromJson(json["h_17"]),
    m190: json["m_190"] == null ? null : M225.fromJson(json["m_190"]),
    m191: json["m_191"] == null ? null : M225.fromJson(json["m_191"]),
    m192: json["m_192"] == null ? null : M225.fromJson(json["m_192"]),
    m193: json["m_193"] == null ? null : M225.fromJson(json["m_193"]),
    m194: json["m_194"] == null ? null : M225.fromJson(json["m_194"]),
  );

  Map<String, dynamic> toJson() => {
    "h_15": h15 == null ? null : h15.toJson(),
    "h_16": h16 == null ? null : h16.toJson(),
    "h_17": h17 == null ? null : h17.toJson(),
    "m_190": m190 == null ? null : m190.toJson(),
    "m_191": m191 == null ? null : m191.toJson(),
    "m_192": m192 == null ? null : m192.toJson(),
    "m_193": m193 == null ? null : m193.toJson(),
    "m_194": m194 == null ? null : m194.toJson(),
  };
}

class Level {
  Level({
    this.h13,
    this.h18,
    this.h259,
    this.h264,
    this.h265,
    this.m34,
    this.m35,
    this.m36,
    this.m37,
    this.m38,
    this.m39,
    this.m40,
    this.m41,
    this.m42,
    this.m43,
    this.m44,
    this.m45,
    this.m46,
    this.m47,
    this.m48,
    this.m49,
    this.m50,
    this.m51,
    this.m52,
    this.m53,
  });

  H490 h13;
  H490 h18;
  H490 h259;
  H490 h264;
  H490 h265;
  M225 m34;
  M225 m35;
  M225 m36;
  M225 m37;
  M225 m38;
  M225 m39;
  M225 m40;
  M225 m41;
  M225 m42;
  M225 m43;
  M225 m44;
  M225 m45;
  M225 m46;
  M225 m47;
  M225 m48;
  M225 m49;
  M225 m50;
  M225 m51;
  M225 m52;
  M225 m53;

  factory Level.fromJson(Map<String, dynamic> json) => Level(
    h13: json["h_13"] == null ? null : H490.fromJson(json["h_13"]),
    h18: json["h_18"] == null ? null : H490.fromJson(json["h_18"]),
    h259: json["h_259"] == null ? null : H490.fromJson(json["h_259"]),
    h264: json["h_264"] == null ? null : H490.fromJson(json["h_264"]),
    h265: json["h_265"] == null ? null : H490.fromJson(json["h_265"]),
    m34: json["m_34"] == null ? null : M225.fromJson(json["m_34"]),
    m35: json["m_35"] == null ? null : M225.fromJson(json["m_35"]),
    m36: json["m_36"] == null ? null : M225.fromJson(json["m_36"]),
    m37: json["m_37"] == null ? null : M225.fromJson(json["m_37"]),
    m38: json["m_38"] == null ? null : M225.fromJson(json["m_38"]),
    m39: json["m_39"] == null ? null : M225.fromJson(json["m_39"]),
    m40: json["m_40"] == null ? null : M225.fromJson(json["m_40"]),
    m41: json["m_41"] == null ? null : M225.fromJson(json["m_41"]),
    m42: json["m_42"] == null ? null : M225.fromJson(json["m_42"]),
    m43: json["m_43"] == null ? null : M225.fromJson(json["m_43"]),
    m44: json["m_44"] == null ? null : M225.fromJson(json["m_44"]),
    m45: json["m_45"] == null ? null : M225.fromJson(json["m_45"]),
    m46: json["m_46"] == null ? null : M225.fromJson(json["m_46"]),
    m47: json["m_47"] == null ? null : M225.fromJson(json["m_47"]),
    m48: json["m_48"] == null ? null : M225.fromJson(json["m_48"]),
    m49: json["m_49"] == null ? null : M225.fromJson(json["m_49"]),
    m50: json["m_50"] == null ? null : M225.fromJson(json["m_50"]),
    m51: json["m_51"] == null ? null : M225.fromJson(json["m_51"]),
    m52: json["m_52"] == null ? null : M225.fromJson(json["m_52"]),
    m53: json["m_53"] == null ? null : M225.fromJson(json["m_53"]),
  );

  Map<String, dynamic> toJson() => {
    "h_13": h13 == null ? null : h13.toJson(),
    "h_18": h18 == null ? null : h18.toJson(),
    "h_259": h259 == null ? null : h259.toJson(),
    "h_264": h264 == null ? null : h264.toJson(),
    "h_265": h265 == null ? null : h265.toJson(),
    "m_34": m34 == null ? null : m34.toJson(),
    "m_35": m35 == null ? null : m35.toJson(),
    "m_36": m36 == null ? null : m36.toJson(),
    "m_37": m37 == null ? null : m37.toJson(),
    "m_38": m38 == null ? null : m38.toJson(),
    "m_39": m39 == null ? null : m39.toJson(),
    "m_40": m40 == null ? null : m40.toJson(),
    "m_41": m41 == null ? null : m41.toJson(),
    "m_42": m42 == null ? null : m42.toJson(),
    "m_43": m43 == null ? null : m43.toJson(),
    "m_44": m44 == null ? null : m44.toJson(),
    "m_45": m45 == null ? null : m45.toJson(),
    "m_46": m46 == null ? null : m46.toJson(),
    "m_47": m47 == null ? null : m47.toJson(),
    "m_48": m48 == null ? null : m48.toJson(),
    "m_49": m49 == null ? null : m49.toJson(),
    "m_50": m50 == null ? null : m50.toJson(),
    "m_51": m51 == null ? null : m51.toJson(),
    "m_52": m52 == null ? null : m52.toJson(),
    "m_53": m53 == null ? null : m53.toJson(),
  };
}

class Lsd {
  Lsd({
    this.h32,
  });

  H490 h32;

  factory Lsd.fromJson(Map<String, dynamic> json) => Lsd(
    h32: json["h_32"] == null ? null : H490.fromJson(json["h_32"]),
  );

  Map<String, dynamic> toJson() => {
    "h_32": h32 == null ? null : h32.toJson(),
  };
}

class Maximum {
  Maximum({
    this.h380,
    this.h395,
    this.h617,
  });

  H490 h380;
  H490 h395;
  H490 h617;

  factory Maximum.fromJson(Map<String, dynamic> json) => Maximum(
    h380: json["h_380"] == null ? null : H490.fromJson(json["h_380"]),
    h395: json["h_395"] == null ? null : H490.fromJson(json["h_395"]),
    h617: json["h_617"] == null ? null : H490.fromJson(json["h_617"]),
  );

  Map<String, dynamic> toJson() => {
    "h_380": h380 == null ? null : h380.toJson(),
    "h_395": h395 == null ? null : h395.toJson(),
    "h_617": h617 == null ? null : h617.toJson(),
  };
}

class MedicalItems {
  MedicalItems({
    this.h7,
    this.h367,
    this.h398,
    this.h406,
    this.h418,
    this.h882,
    this.m198,
    this.m199,
    this.m200,
  });

  H490 h7;
  H490 h367;
  H490 h398;
  H490 h406;
  H490 h418;
  H490 h882;
  M225 m198;
  M225 m199;
  M225 m200;

  factory MedicalItems.fromJson(Map<String, dynamic> json) => MedicalItems(
    h7: json["h_7"] == null ? null : H490.fromJson(json["h_7"]),
    h367: json["h_367"] == null ? null : H490.fromJson(json["h_367"]),
    h398: json["h_398"] == null ? null : H490.fromJson(json["h_398"]),
    h406: json["h_406"] == null ? null : H490.fromJson(json["h_406"]),
    h418: json["h_418"] == null ? null : H490.fromJson(json["h_418"]),
    h882: json["h_882"] == null ? null : H490.fromJson(json["h_882"]),
    m198: json["m_198"] == null ? null : M225.fromJson(json["m_198"]),
    m199: json["m_199"] == null ? null : M225.fromJson(json["m_199"]),
    m200: json["m_200"] == null ? null : M225.fromJson(json["m_200"]),
  );

  Map<String, dynamic> toJson() => {
    "h_7": h7 == null ? null : h7.toJson(),
    "h_367": h367 == null ? null : h367.toJson(),
    "h_398": h398 == null ? null : h398.toJson(),
    "h_406": h406 == null ? null : h406.toJson(),
    "h_418": h418 == null ? null : h418.toJson(),
    "h_882": h882 == null ? null : h882.toJson(),
    "m_198": m198 == null ? null : m198.toJson(),
    "m_199": m199 == null ? null : m199.toJson(),
    "m_200": m200 == null ? null : m200.toJson(),
  };
}

class Memberships {
  Memberships({
    this.h233,
    this.h234,
    this.h235,
  });

  H490 h233;
  H490 h234;
  H490 h235;

  factory Memberships.fromJson(Map<String, dynamic> json) => Memberships(
    h233: json["h_233"] == null ? null : H490.fromJson(json["h_233"]),
    h234: json["h_234"] == null ? null : H490.fromJson(json["h_234"]),
    h235: json["h_235"] == null ? null : H490.fromJson(json["h_235"]),
  );

  Map<String, dynamic> toJson() => {
    "h_233": h233 == null ? null : h233.toJson(),
    "h_234": h234 == null ? null : h234.toJson(),
    "h_235": h235 == null ? null : h235.toJson(),
  };
}

class Missions {
  Missions({
    this.h371,
    this.h491,
    this.h636,
    this.h664,
    this.h851,
  });

  H490 h371;
  H490 h491;
  H490 h636;
  H490 h664;
  H490 h851;

  factory Missions.fromJson(Map<String, dynamic> json) => Missions(
    h371: json["h_371"] == null ? null : H490.fromJson(json["h_371"]),
    h491: json["h_491"] == null ? null : H490.fromJson(json["h_491"]),
    h636: json["h_636"] == null ? null : H490.fromJson(json["h_636"]),
    h664: json["h_664"] == null ? null : H490.fromJson(json["h_664"]),
    h851: json["h_851"] == null ? null : H490.fromJson(json["h_851"]),
  );

  Map<String, dynamic> toJson() => {
    "h_371": h371 == null ? null : h371.toJson(),
    "h_491": h491 == null ? null : h491.toJson(),
    "h_636": h636 == null ? null : h636.toJson(),
    "h_664": h664 == null ? null : h664.toJson(),
    "h_851": h851 == null ? null : h851.toJson(),
  };
}

class Murder {
  Murder({
    this.h159,
    this.m64,
    this.m65,
    this.m66,
    this.m67,
    this.m68,
    this.m125,
    this.m126,
    this.m163,
    this.m164,
    this.m165,
  });

  H490 h159;
  M225 m64;
  M225 m65;
  M225 m66;
  M225 m67;
  M225 m68;
  M225 m125;
  M225 m126;
  M225 m163;
  M225 m164;
  M225 m165;

  factory Murder.fromJson(Map<String, dynamic> json) => Murder(
    h159: json["h_159"] == null ? null : H490.fromJson(json["h_159"]),
    m64: json["m_64"] == null ? null : M225.fromJson(json["m_64"]),
    m65: json["m_65"] == null ? null : M225.fromJson(json["m_65"]),
    m66: json["m_66"] == null ? null : M225.fromJson(json["m_66"]),
    m67: json["m_67"] == null ? null : M225.fromJson(json["m_67"]),
    m68: json["m_68"] == null ? null : M225.fromJson(json["m_68"]),
    m125: json["m_125"] == null ? null : M225.fromJson(json["m_125"]),
    m126: json["m_126"] == null ? null : M225.fromJson(json["m_126"]),
    m163: json["m_163"] == null ? null : M225.fromJson(json["m_163"]),
    m164: json["m_164"] == null ? null : M225.fromJson(json["m_164"]),
    m165: json["m_165"] == null ? null : M225.fromJson(json["m_165"]),
  );

  Map<String, dynamic> toJson() => {
    "h_159": h159 == null ? null : h159.toJson(),
    "m_64": m64 == null ? null : m64.toJson(),
    "m_65": m65 == null ? null : m65.toJson(),
    "m_66": m66 == null ? null : m66.toJson(),
    "m_67": m67 == null ? null : m67.toJson(),
    "m_68": m68 == null ? null : m68.toJson(),
    "m_125": m125 == null ? null : m125.toJson(),
    "m_126": m126 == null ? null : m126.toJson(),
    "m_163": m163 == null ? null : m163.toJson(),
    "m_164": m164 == null ? null : m164.toJson(),
    "m_165": m165 == null ? null : m165.toJson(),
  };
}

class Networth {
  Networth({
    this.m89,
    this.m90,
    this.m91,
    this.m92,
    this.m93,
    this.m94,
    this.m95,
    this.m96,
    this.m236,
    this.m237,
    this.m238,
    this.m239,
    this.m240,
    this.m241,
  });

  M225 m89;
  M225 m90;
  M225 m91;
  M225 m92;
  M225 m93;
  M225 m94;
  M225 m95;
  M225 m96;
  M225 m236;
  M225 m237;
  M225 m238;
  M225 m239;
  M225 m240;
  M225 m241;

  factory Networth.fromJson(Map<String, dynamic> json) => Networth(
    m89: json["m_89"] == null ? null : M225.fromJson(json["m_89"]),
    m90: json["m_90"] == null ? null : M225.fromJson(json["m_90"]),
    m91: json["m_91"] == null ? null : M225.fromJson(json["m_91"]),
    m92: json["m_92"] == null ? null : M225.fromJson(json["m_92"]),
    m93: json["m_93"] == null ? null : M225.fromJson(json["m_93"]),
    m94: json["m_94"] == null ? null : M225.fromJson(json["m_94"]),
    m95: json["m_95"] == null ? null : M225.fromJson(json["m_95"]),
    m96: json["m_96"] == null ? null : M225.fromJson(json["m_96"]),
    m236: json["m_236"] == null ? null : M225.fromJson(json["m_236"]),
    m237: json["m_237"] == null ? null : M225.fromJson(json["m_237"]),
    m238: json["m_238"] == null ? null : M225.fromJson(json["m_238"]),
    m239: json["m_239"] == null ? null : M225.fromJson(json["m_239"]),
    m240: json["m_240"] == null ? null : M225.fromJson(json["m_240"]),
    m241: json["m_241"] == null ? null : M225.fromJson(json["m_241"]),
  );

  Map<String, dynamic> toJson() => {
    "m_89": m89 == null ? null : m89.toJson(),
    "m_90": m90 == null ? null : m90.toJson(),
    "m_91": m91 == null ? null : m91.toJson(),
    "m_92": m92 == null ? null : m92.toJson(),
    "m_93": m93 == null ? null : m93.toJson(),
    "m_94": m94 == null ? null : m94.toJson(),
    "m_95": m95 == null ? null : m95.toJson(),
    "m_96": m96 == null ? null : m96.toJson(),
    "m_236": m236 == null ? null : m236.toJson(),
    "m_237": m237 == null ? null : m237.toJson(),
    "m_238": m238 == null ? null : m238.toJson(),
    "m_239": m239 == null ? null : m239.toJson(),
    "m_240": m240 == null ? null : m240.toJson(),
    "m_241": m241 == null ? null : m241.toJson(),
  };
}

class Opium {
  Opium({
    this.h33,
  });

  H490 h33;

  factory Opium.fromJson(Map<String, dynamic> json) => Opium(
    h33: json["h_33"] == null ? null : H490.fromJson(json["h_33"]),
  );

  Map<String, dynamic> toJson() => {
    "h_33": h33 == null ? null : h33.toJson(),
  };
}

class OrganisedCrimes {
  OrganisedCrimes({
    this.h552,
  });

  H490 h552;

  factory OrganisedCrimes.fromJson(Map<String, dynamic> json) => OrganisedCrimes(
    h552: json["h_552"] == null ? null : H490.fromJson(json["h_552"]),
  );

  Map<String, dynamic> toJson() => {
    "h_552": h552 == null ? null : h552.toJson(),
  };
}

class OtherAttacks {
  OtherAttacks({
    this.h27,
    this.h230,
    this.h247,
    this.h254,
    this.h270,
    this.h317,
    this.h414,
    this.h481,
    this.h500,
    this.h517,
    this.h601,
    this.h608,
    this.h615,
    this.h627,
    this.h631,
    this.h670,
    this.h739,
    this.h763,
    this.h778,
    this.h781,
    this.h827,
    this.h838,
    this.h843,
    this.h896,
    this.h902,
    this.h903,
    this.h955,
  });

  H490 h27;
  H490 h230;
  H490 h247;
  H490 h254;
  H490 h270;
  H490 h317;
  H490 h414;
  H490 h481;
  H490 h500;
  H490 h517;
  H490 h601;
  H490 h608;
  H490 h615;
  H490 h627;
  H490 h631;
  H490 h670;
  H490 h739;
  H490 h763;
  H490 h778;
  H490 h781;
  H490 h827;
  H490 h838;
  H490 h843;
  H490 h896;
  H490 h902;
  H490 h903;
  H490 h955;

  factory OtherAttacks.fromJson(Map<String, dynamic> json) => OtherAttacks(
    h27: json["h_27"] == null ? null : H490.fromJson(json["h_27"]),
    h230: json["h_230"] == null ? null : H490.fromJson(json["h_230"]),
    h247: json["h_247"] == null ? null : H490.fromJson(json["h_247"]),
    h254: json["h_254"] == null ? null : H490.fromJson(json["h_254"]),
    h270: json["h_270"] == null ? null : H490.fromJson(json["h_270"]),
    h317: json["h_317"] == null ? null : H490.fromJson(json["h_317"]),
    h414: json["h_414"] == null ? null : H490.fromJson(json["h_414"]),
    h481: json["h_481"] == null ? null : H490.fromJson(json["h_481"]),
    h500: json["h_500"] == null ? null : H490.fromJson(json["h_500"]),
    h517: json["h_517"] == null ? null : H490.fromJson(json["h_517"]),
    h601: json["h_601"] == null ? null : H490.fromJson(json["h_601"]),
    h608: json["h_608"] == null ? null : H490.fromJson(json["h_608"]),
    h615: json["h_615"] == null ? null : H490.fromJson(json["h_615"]),
    h627: json["h_627"] == null ? null : H490.fromJson(json["h_627"]),
    h631: json["h_631"] == null ? null : H490.fromJson(json["h_631"]),
    h670: json["h_670"] == null ? null : H490.fromJson(json["h_670"]),
    h739: json["h_739"] == null ? null : H490.fromJson(json["h_739"]),
    h763: json["h_763"] == null ? null : H490.fromJson(json["h_763"]),
    h778: json["h_778"] == null ? null : H490.fromJson(json["h_778"]),
    h781: json["h_781"] == null ? null : H490.fromJson(json["h_781"]),
    h827: json["h_827"] == null ? null : H490.fromJson(json["h_827"]),
    h838: json["h_838"] == null ? null : H490.fromJson(json["h_838"]),
    h843: json["h_843"] == null ? null : H490.fromJson(json["h_843"]),
    h896: json["h_896"] == null ? null : H490.fromJson(json["h_896"]),
    h902: json["h_902"] == null ? null : H490.fromJson(json["h_902"]),
    h903: json["h_903"] == null ? null : H490.fromJson(json["h_903"]),
    h955: json["h_955"] == null ? null : H490.fromJson(json["h_955"]),
  );

  Map<String, dynamic> toJson() => {
    "h_27": h27 == null ? null : h27.toJson(),
    "h_230": h230 == null ? null : h230.toJson(),
    "h_247": h247 == null ? null : h247.toJson(),
    "h_254": h254 == null ? null : h254.toJson(),
    "h_270": h270 == null ? null : h270.toJson(),
    "h_317": h317 == null ? null : h317.toJson(),
    "h_414": h414 == null ? null : h414.toJson(),
    "h_481": h481 == null ? null : h481.toJson(),
    "h_500": h500 == null ? null : h500.toJson(),
    "h_517": h517 == null ? null : h517.toJson(),
    "h_601": h601 == null ? null : h601.toJson(),
    "h_608": h608 == null ? null : h608.toJson(),
    "h_615": h615 == null ? null : h615.toJson(),
    "h_627": h627 == null ? null : h627.toJson(),
    "h_631": h631 == null ? null : h631.toJson(),
    "h_670": h670 == null ? null : h670.toJson(),
    "h_739": h739 == null ? null : h739.toJson(),
    "h_763": h763 == null ? null : h763.toJson(),
    "h_778": h778 == null ? null : h778.toJson(),
    "h_781": h781 == null ? null : h781.toJson(),
    "h_827": h827 == null ? null : h827.toJson(),
    "h_838": h838 == null ? null : h838.toJson(),
    "h_843": h843 == null ? null : h843.toJson(),
    "h_896": h896 == null ? null : h896.toJson(),
    "h_902": h902 == null ? null : h902.toJson(),
    "h_903": h903 == null ? null : h903.toJson(),
    "h_955": h955 == null ? null : h955.toJson(),
  };
}

class OtherCommitment {
  OtherCommitment({
    this.h245,
    this.h312,
    this.h873,
  });

  H490 h245;
  H490 h312;
  H490 h873;

  factory OtherCommitment.fromJson(Map<String, dynamic> json) => OtherCommitment(
    h245: json["h_245"] == null ? null : H490.fromJson(json["h_245"]),
    h312: json["h_312"] == null ? null : H490.fromJson(json["h_312"]),
    h873: json["h_873"] == null ? null : H490.fromJson(json["h_873"]),
  );

  Map<String, dynamic> toJson() => {
    "h_245": h245 == null ? null : h245.toJson(),
    "h_312": h312 == null ? null : h312.toJson(),
    "h_873": h873 == null ? null : h873.toJson(),
  };
}

class OtherComp {
  OtherComp({
    this.h213,
    this.h222,
    this.h330,
  });

  H490 h213;
  H490 h222;
  H490 h330;

  factory OtherComp.fromJson(Map<String, dynamic> json) => OtherComp(
    h213: json["h_213"] == null ? null : H490.fromJson(json["h_213"]),
    h222: json["h_222"] == null ? null : H490.fromJson(json["h_222"]),
    h330: json["h_330"] == null ? null : H490.fromJson(json["h_330"]),
  );

  Map<String, dynamic> toJson() => {
    "h_213": h213 == null ? null : h213.toJson(),
    "h_222": h222 == null ? null : h222.toJson(),
    "h_330": h330 == null ? null : h330.toJson(),
  };
}

class OtherCrimes {
  OtherCrimes({
    this.h6,
  });

  H490 h6;

  factory OtherCrimes.fromJson(Map<String, dynamic> json) => OtherCrimes(
    h6: json["h_6"] == null ? null : H490.fromJson(json["h_6"]),
  );

  Map<String, dynamic> toJson() => {
    "h_6": h6 == null ? null : h6.toJson(),
  };
}

class OtherFaction {
  OtherFaction({
    this.h488,
    this.h605,
  });

  H490 h488;
  H490 h605;

  factory OtherFaction.fromJson(Map<String, dynamic> json) => OtherFaction(
    h488: json["h_488"] == null ? null : H490.fromJson(json["h_488"]),
    h605: json["h_605"] == null ? null : H490.fromJson(json["h_605"]),
  );

  Map<String, dynamic> toJson() => {
    "h_488": h488 == null ? null : h488.toJson(),
    "h_605": h605 == null ? null : h605.toJson(),
  };
}

class OtherGym {
  OtherGym({
    this.h888,
  });

  H490 h888;

  factory OtherGym.fromJson(Map<String, dynamic> json) => OtherGym(
    h888: json["h_888"] == null ? null : H490.fromJson(json["h_888"]),
  );

  Map<String, dynamic> toJson() => {
    "h_888": h888 == null ? null : h888.toJson(),
  };
}

class OtherItems {
  OtherItems({
    this.h216,
    this.h273,
    this.h699,
  });

  H490 h216;
  H490 h273;
  H490 h699;

  factory OtherItems.fromJson(Map<String, dynamic> json) => OtherItems(
    h216: json["h_216"] == null ? null : H490.fromJson(json["h_216"]),
    h273: json["h_273"] == null ? null : H490.fromJson(json["h_273"]),
    h699: json["h_699"] == null ? null : H490.fromJson(json["h_699"]),
  );

  Map<String, dynamic> toJson() => {
    "h_216": h216 == null ? null : h216.toJson(),
    "h_273": h273 == null ? null : h273.toJson(),
    "h_699": h699 == null ? null : h699.toJson(),
  };
}

class OtherMisc {
  OtherMisc({
    this.h316,
    this.h700,
    this.h839,
    this.h845,
  });

  H490 h316;
  H490 h700;
  H490 h839;
  H490 h845;

  factory OtherMisc.fromJson(Map<String, dynamic> json) => OtherMisc(
    h316: json["h_316"] == null ? null : H490.fromJson(json["h_316"]),
    h700: json["h_700"] == null ? null : H490.fromJson(json["h_700"]),
    h839: json["h_839"] == null ? null : H490.fromJson(json["h_839"]),
    h845: json["h_845"] == null ? null : H490.fromJson(json["h_845"]),
  );

  Map<String, dynamic> toJson() => {
    "h_316": h316 == null ? null : h316.toJson(),
    "h_700": h700 == null ? null : h700.toJson(),
    "h_839": h839 == null ? null : h839.toJson(),
    "h_845": h845 == null ? null : h845.toJson(),
  };
}

class OtherMoney {
  OtherMoney({
    this.h8,
    this.h239,
    this.h268,
  });

  H490 h8;
  H490 h239;
  H490 h268;

  factory OtherMoney.fromJson(Map<String, dynamic> json) => OtherMoney(
    h8: json["h_8"] == null ? null : H490.fromJson(json["h_8"]),
    h239: json["h_239"] == null ? null : H490.fromJson(json["h_239"]),
    h268: json["h_268"] == null ? null : H490.fromJson(json["h_268"]),
  );

  Map<String, dynamic> toJson() => {
    "h_8": h8 == null ? null : h8.toJson(),
    "h_239": h239 == null ? null : h239.toJson(),
    "h_268": h268 == null ? null : h268.toJson(),
  };
}

class Pcp {
  Pcp({
    this.h36,
  });

  H490 h36;

  factory Pcp.fromJson(Map<String, dynamic> json) => Pcp(
    h36: json["h_36"] == null ? null : H490.fromJson(json["h_36"]),
  );

  Map<String, dynamic> toJson() => {
    "h_36": h36 == null ? null : h36.toJson(),
  };
}

class Perks {
  Perks({
    this.h244,
    this.h607,
    this.h620,
  });

  H490 h244;
  H490 h607;
  H490 h620;

  factory Perks.fromJson(Map<String, dynamic> json) => Perks(
    h244: json["h_244"] == null ? null : H490.fromJson(json["h_244"]),
    h607: json["h_607"] == null ? null : H490.fromJson(json["h_607"]),
    h620: json["h_620"] == null ? null : H490.fromJson(json["h_620"]),
  );

  Map<String, dynamic> toJson() => {
    "h_244": h244 == null ? null : h244.toJson(),
    "h_607": h607 == null ? null : h607.toJson(),
    "h_620": h620 == null ? null : h620.toJson(),
  };
}

class Points {
  Points({
    this.h266,
    this.h288,
    this.h334,
    this.h566,
  });

  H490 h266;
  H490 h288;
  H490 h334;
  H490 h566;

  factory Points.fromJson(Map<String, dynamic> json) => Points(
    h266: json["h_266"] == null ? null : H490.fromJson(json["h_266"]),
    h288: json["h_288"] == null ? null : H490.fromJson(json["h_288"]),
    h334: json["h_334"] == null ? null : H490.fromJson(json["h_334"]),
    h566: json["h_566"] == null ? null : H490.fromJson(json["h_566"]),
  );

  Map<String, dynamic> toJson() => {
    "h_266": h266 == null ? null : h266.toJson(),
    "h_288": h288 == null ? null : h288.toJson(),
    "h_334": h334 == null ? null : h334.toJson(),
    "h_566": h566 == null ? null : h566.toJson(),
  };
}

class Pranks {
  Pranks({
    this.h678,
    this.h716,
    this.h717,
  });

  H490 h678;
  H490 h716;
  H490 h717;

  factory Pranks.fromJson(Map<String, dynamic> json) => Pranks(
    h678: json["h_678"] == null ? null : H490.fromJson(json["h_678"]),
    h716: json["h_716"] == null ? null : H490.fromJson(json["h_716"]),
    h717: json["h_717"] == null ? null : H490.fromJson(json["h_717"]),
  );

  Map<String, dynamic> toJson() => {
    "h_678": h678 == null ? null : h678.toJson(),
    "h_716": h716 == null ? null : h716.toJson(),
    "h_717": h717 == null ? null : h717.toJson(),
  };
}

class Racing {
  Racing({
    this.h21,
    this.h274,
    this.h571,
    this.h572,
    this.h581,
    this.h734,
  });

  H490 h21;
  H490 h274;
  H490 h571;
  H490 h572;
  H490 h581;
  H490 h734;

  factory Racing.fromJson(Map<String, dynamic> json) => Racing(
    h21: json["h_21"] == null ? null : H490.fromJson(json["h_21"]),
    h274: json["h_274"] == null ? null : H490.fromJson(json["h_274"]),
    h571: json["h_571"] == null ? null : H490.fromJson(json["h_571"]),
    h572: json["h_572"] == null ? null : H490.fromJson(json["h_572"]),
    h581: json["h_581"] == null ? null : H490.fromJson(json["h_581"]),
    h734: json["h_734"] == null ? null : H490.fromJson(json["h_734"]),
  );

  Map<String, dynamic> toJson() => {
    "h_21": h21 == null ? null : h21.toJson(),
    "h_274": h274 == null ? null : h274.toJson(),
    "h_571": h571 == null ? null : h571.toJson(),
    "h_572": h572 == null ? null : h572.toJson(),
    "h_581": h581 == null ? null : h581.toJson(),
    "h_734": h734 == null ? null : h734.toJson(),
  };
}

class Rank {
  Rank({
    this.m1,
    this.m2,
    this.m3,
    this.m4,
    this.m5,
    this.m6,
    this.m7,
    this.m8,
    this.m9,
    this.m10,
    this.m11,
    this.m12,
    this.m13,
    this.m14,
    this.m15,
    this.m16,
    this.m17,
    this.m18,
    this.m19,
    this.m20,
    this.m21,
    this.m22,
    this.m23,
    this.m24,
    this.m25,
  });

  M225 m1;
  M225 m2;
  M225 m3;
  M225 m4;
  M225 m5;
  M225 m6;
  M225 m7;
  M225 m8;
  M225 m9;
  M225 m10;
  M225 m11;
  M225 m12;
  M225 m13;
  M225 m14;
  M225 m15;
  M225 m16;
  M225 m17;
  M225 m18;
  M225 m19;
  M225 m20;
  M225 m21;
  M225 m22;
  M225 m23;
  M225 m24;
  M225 m25;

  factory Rank.fromJson(Map<String, dynamic> json) => Rank(
    m1: json["m_1"] == null ? null : M225.fromJson(json["m_1"]),
    m2: json["m_2"] == null ? null : M225.fromJson(json["m_2"]),
    m3: json["m_3"] == null ? null : M225.fromJson(json["m_3"]),
    m4: json["m_4"] == null ? null : M225.fromJson(json["m_4"]),
    m5: json["m_5"] == null ? null : M225.fromJson(json["m_5"]),
    m6: json["m_6"] == null ? null : M225.fromJson(json["m_6"]),
    m7: json["m_7"] == null ? null : M225.fromJson(json["m_7"]),
    m8: json["m_8"] == null ? null : M225.fromJson(json["m_8"]),
    m9: json["m_9"] == null ? null : M225.fromJson(json["m_9"]),
    m10: json["m_10"] == null ? null : M225.fromJson(json["m_10"]),
    m11: json["m_11"] == null ? null : M225.fromJson(json["m_11"]),
    m12: json["m_12"] == null ? null : M225.fromJson(json["m_12"]),
    m13: json["m_13"] == null ? null : M225.fromJson(json["m_13"]),
    m14: json["m_14"] == null ? null : M225.fromJson(json["m_14"]),
    m15: json["m_15"] == null ? null : M225.fromJson(json["m_15"]),
    m16: json["m_16"] == null ? null : M225.fromJson(json["m_16"]),
    m17: json["m_17"] == null ? null : M225.fromJson(json["m_17"]),
    m18: json["m_18"] == null ? null : M225.fromJson(json["m_18"]),
    m19: json["m_19"] == null ? null : M225.fromJson(json["m_19"]),
    m20: json["m_20"] == null ? null : M225.fromJson(json["m_20"]),
    m21: json["m_21"] == null ? null : M225.fromJson(json["m_21"]),
    m22: json["m_22"] == null ? null : M225.fromJson(json["m_22"]),
    m23: json["m_23"] == null ? null : M225.fromJson(json["m_23"]),
    m24: json["m_24"] == null ? null : M225.fromJson(json["m_24"]),
    m25: json["m_25"] == null ? null : M225.fromJson(json["m_25"]),
  );

  Map<String, dynamic> toJson() => {
    "m_1": m1 == null ? null : m1.toJson(),
    "m_2": m2 == null ? null : m2.toJson(),
    "m_3": m3 == null ? null : m3.toJson(),
    "m_4": m4 == null ? null : m4.toJson(),
    "m_5": m5 == null ? null : m5.toJson(),
    "m_6": m6 == null ? null : m6.toJson(),
    "m_7": m7 == null ? null : m7.toJson(),
    "m_8": m8 == null ? null : m8.toJson(),
    "m_9": m9 == null ? null : m9.toJson(),
    "m_10": m10 == null ? null : m10.toJson(),
    "m_11": m11 == null ? null : m11.toJson(),
    "m_12": m12 == null ? null : m12.toJson(),
    "m_13": m13 == null ? null : m13.toJson(),
    "m_14": m14 == null ? null : m14.toJson(),
    "m_15": m15 == null ? null : m15.toJson(),
    "m_16": m16 == null ? null : m16.toJson(),
    "m_17": m17 == null ? null : m17.toJson(),
    "m_18": m18 == null ? null : m18.toJson(),
    "m_19": m19 == null ? null : m19.toJson(),
    "m_20": m20 == null ? null : m20.toJson(),
    "m_21": m21 == null ? null : m21.toJson(),
    "m_22": m22 == null ? null : m22.toJson(),
    "m_23": m23 == null ? null : m23.toJson(),
    "m_24": m24 == null ? null : m24.toJson(),
    "m_25": m25 == null ? null : m25.toJson(),
  };
}

class Respect {
  Respect({
    this.h256,
    this.h477,
    this.h478,
    this.m215,
    this.m216,
    this.m217,
    this.m218,
    this.m219,
    this.m220,
    this.m221,
    this.m222,
    this.m223,
    this.m224,
  });

  H490 h256;
  H490 h477;
  H490 h478;
  M225 m215;
  M225 m216;
  M225 m217;
  M225 m218;
  M225 m219;
  M225 m220;
  M225 m221;
  M225 m222;
  M225 m223;
  M225 m224;

  factory Respect.fromJson(Map<String, dynamic> json) => Respect(
    h256: json["h_256"] == null ? null : H490.fromJson(json["h_256"]),
    h477: json["h_477"] == null ? null : H490.fromJson(json["h_477"]),
    h478: json["h_478"] == null ? null : H490.fromJson(json["h_478"]),
    m215: json["m_215"] == null ? null : M225.fromJson(json["m_215"]),
    m216: json["m_216"] == null ? null : M225.fromJson(json["m_216"]),
    m217: json["m_217"] == null ? null : M225.fromJson(json["m_217"]),
    m218: json["m_218"] == null ? null : M225.fromJson(json["m_218"]),
    m219: json["m_219"] == null ? null : M225.fromJson(json["m_219"]),
    m220: json["m_220"] == null ? null : M225.fromJson(json["m_220"]),
    m221: json["m_221"] == null ? null : M225.fromJson(json["m_221"]),
    m222: json["m_222"] == null ? null : M225.fromJson(json["m_222"]),
    m223: json["m_223"] == null ? null : M225.fromJson(json["m_223"]),
    m224: json["m_224"] == null ? null : M225.fromJson(json["m_224"]),
  );

  Map<String, dynamic> toJson() => {
    "h_256": h256 == null ? null : h256.toJson(),
    "h_477": h477 == null ? null : h477.toJson(),
    "h_478": h478 == null ? null : h478.toJson(),
    "m_215": m215 == null ? null : m215.toJson(),
    "m_216": m216 == null ? null : m216.toJson(),
    "m_217": m217 == null ? null : m217.toJson(),
    "m_218": m218 == null ? null : m218.toJson(),
    "m_219": m219 == null ? null : m219.toJson(),
    "m_220": m220 == null ? null : m220.toJson(),
    "m_221": m221 == null ? null : m221.toJson(),
    "m_222": m222 == null ? null : m222.toJson(),
    "m_223": m223 == null ? null : m223.toJson(),
    "m_224": m224 == null ? null : m224.toJson(),
  };
}

class Revives {
  Revives({
    this.h23,
    this.h267,
    this.h322,
    this.h863,
    this.h870,
  });

  H490 h23;
  H490 h267;
  H490 h322;
  H490 h863;
  H490 h870;

  factory Revives.fromJson(Map<String, dynamic> json) => Revives(
    h23: json["h_23"] == null ? null : H490.fromJson(json["h_23"]),
    h267: json["h_267"] == null ? null : H490.fromJson(json["h_267"]),
    h322: json["h_322"] == null ? null : H490.fromJson(json["h_322"]),
    h863: json["h_863"] == null ? null : H490.fromJson(json["h_863"]),
    h870: json["h_870"] == null ? null : H490.fromJson(json["h_870"]),
  );

  Map<String, dynamic> toJson() => {
    "h_23": h23 == null ? null : h23.toJson(),
    "h_267": h267 == null ? null : h267.toJson(),
    "h_322": h322 == null ? null : h322.toJson(),
    "h_863": h863 == null ? null : h863.toJson(),
    "h_870": h870 == null ? null : h870.toJson(),
  };
}

class Shrooms {
  Shrooms({
    this.h34,
  });

  H490 h34;

  factory Shrooms.fromJson(Map<String, dynamic> json) => Shrooms(
    h34: json["h_34"] == null ? null : H490.fromJson(json["h_34"]),
  );

  Map<String, dynamic> toJson() => {
    "h_34": h34 == null ? null : h34.toJson(),
  };
}

class Social {
  Social({
    this.h5,
    this.h167,
    this.h217,
    this.h218,
    this.h219,
    this.h223,
    this.h246,
  });

  H490 h5;
  H490 h167;
  H490 h217;
  H490 h218;
  H490 h219;
  H490 h223;
  H490 h246;

  factory Social.fromJson(Map<String, dynamic> json) => Social(
    h5: json["h_5"] == null ? null : H490.fromJson(json["h_5"]),
    h167: json["h_167"] == null ? null : H490.fromJson(json["h_167"]),
    h217: json["h_217"] == null ? null : H490.fromJson(json["h_217"]),
    h218: json["h_218"] == null ? null : H490.fromJson(json["h_218"]),
    h219: json["h_219"] == null ? null : H490.fromJson(json["h_219"]),
    h223: json["h_223"] == null ? null : H490.fromJson(json["h_223"]),
    h246: json["h_246"] == null ? null : H490.fromJson(json["h_246"]),
  );

  Map<String, dynamic> toJson() => {
    "h_5": h5 == null ? null : h5.toJson(),
    "h_167": h167 == null ? null : h167.toJson(),
    "h_217": h217 == null ? null : h217.toJson(),
    "h_218": h218 == null ? null : h218.toJson(),
    "h_219": h219 == null ? null : h219.toJson(),
    "h_223": h223 == null ? null : h223.toJson(),
    "h_246": h246 == null ? null : h246.toJson(),
  };
}

class SpecialAmmo {
  SpecialAmmo({
    this.h791,
    this.h793,
    this.h800,
    this.h942,
    this.h943,
    this.h944,
    this.h945,
    this.h951,
  });

  H490 h791;
  H490 h793;
  H490 h800;
  H490 h942;
  H490 h943;
  H490 h944;
  H490 h945;
  H490 h951;

  factory SpecialAmmo.fromJson(Map<String, dynamic> json) => SpecialAmmo(
    h791: json["h_791"] == null ? null : H490.fromJson(json["h_791"]),
    h793: json["h_793"] == null ? null : H490.fromJson(json["h_793"]),
    h800: json["h_800"] == null ? null : H490.fromJson(json["h_800"]),
    h942: json["h_942"] == null ? null : H490.fromJson(json["h_942"]),
    h943: json["h_943"] == null ? null : H490.fromJson(json["h_943"]),
    h944: json["h_944"] == null ? null : H490.fromJson(json["h_944"]),
    h945: json["h_945"] == null ? null : H490.fromJson(json["h_945"]),
    h951: json["h_951"] == null ? null : H490.fromJson(json["h_951"]),
  );

  Map<String, dynamic> toJson() => {
    "h_791": h791 == null ? null : h791.toJson(),
    "h_793": h793 == null ? null : h793.toJson(),
    "h_800": h800 == null ? null : h800.toJson(),
    "h_942": h942 == null ? null : h942.toJson(),
    "h_943": h943 == null ? null : h943.toJson(),
    "h_944": h944 == null ? null : h944.toJson(),
    "h_945": h945 == null ? null : h945.toJson(),
    "h_951": h951 == null ? null : h951.toJson(),
  };
}

class Speed {
  Speed({
    this.h242,
    this.h505,
    this.h506,
    this.h550,
  });

  H490 h242;
  H490 h505;
  H490 h506;
  H490 h550;

  factory Speed.fromJson(Map<String, dynamic> json) => Speed(
    h242: json["h_242"] == null ? null : H490.fromJson(json["h_242"]),
    h505: json["h_505"] == null ? null : H490.fromJson(json["h_505"]),
    h506: json["h_506"] == null ? null : H490.fromJson(json["h_506"]),
    h550: json["h_550"] == null ? null : H490.fromJson(json["h_550"]),
  );

  Map<String, dynamic> toJson() => {
    "h_242": h242 == null ? null : h242.toJson(),
    "h_505": h505 == null ? null : h505.toJson(),
    "h_506": h506 == null ? null : h506.toJson(),
    "h_550": h550 == null ? null : h550.toJson(),
  };
}

class Spouse {
  Spouse({
    this.h162,
    this.h163,
    this.h166,
    this.m74,
    this.m75,
    this.m76,
    this.m77,
    this.m78,
    this.m79,
    this.m80,
    this.m110,
    this.m111,
    this.m112,
    this.m113,
    this.m114,
    this.m115,
    this.m116,
    this.m156,
    this.m157,
    this.m158,
    this.m159,
    this.m160,
    this.m161,
    this.m162,
  });

  H490 h162;
  H490 h163;
  H490 h166;
  M225 m74;
  M225 m75;
  M225 m76;
  M225 m77;
  M225 m78;
  M225 m79;
  M225 m80;
  M225 m110;
  M225 m111;
  M225 m112;
  M225 m113;
  M225 m114;
  M225 m115;
  M225 m116;
  M225 m156;
  M225 m157;
  M225 m158;
  M225 m159;
  M225 m160;
  M225 m161;
  M225 m162;

  factory Spouse.fromJson(Map<String, dynamic> json) => Spouse(
    h162: json["h_162"] == null ? null : H490.fromJson(json["h_162"]),
    h163: json["h_163"] == null ? null : H490.fromJson(json["h_163"]),
    h166: json["h_166"] == null ? null : H490.fromJson(json["h_166"]),
    m74: json["m_74"] == null ? null : M225.fromJson(json["m_74"]),
    m75: json["m_75"] == null ? null : M225.fromJson(json["m_75"]),
    m76: json["m_76"] == null ? null : M225.fromJson(json["m_76"]),
    m77: json["m_77"] == null ? null : M225.fromJson(json["m_77"]),
    m78: json["m_78"] == null ? null : M225.fromJson(json["m_78"]),
    m79: json["m_79"] == null ? null : M225.fromJson(json["m_79"]),
    m80: json["m_80"] == null ? null : M225.fromJson(json["m_80"]),
    m110: json["m_110"] == null ? null : M225.fromJson(json["m_110"]),
    m111: json["m_111"] == null ? null : M225.fromJson(json["m_111"]),
    m112: json["m_112"] == null ? null : M225.fromJson(json["m_112"]),
    m113: json["m_113"] == null ? null : M225.fromJson(json["m_113"]),
    m114: json["m_114"] == null ? null : M225.fromJson(json["m_114"]),
    m115: json["m_115"] == null ? null : M225.fromJson(json["m_115"]),
    m116: json["m_116"] == null ? null : M225.fromJson(json["m_116"]),
    m156: json["m_156"] == null ? null : M225.fromJson(json["m_156"]),
    m157: json["m_157"] == null ? null : M225.fromJson(json["m_157"]),
    m158: json["m_158"] == null ? null : M225.fromJson(json["m_158"]),
    m159: json["m_159"] == null ? null : M225.fromJson(json["m_159"]),
    m160: json["m_160"] == null ? null : M225.fromJson(json["m_160"]),
    m161: json["m_161"] == null ? null : M225.fromJson(json["m_161"]),
    m162: json["m_162"] == null ? null : M225.fromJson(json["m_162"]),
  );

  Map<String, dynamic> toJson() => {
    "h_162": h162 == null ? null : h162.toJson(),
    "h_163": h163 == null ? null : h163.toJson(),
    "h_166": h166 == null ? null : h166.toJson(),
    "m_74": m74 == null ? null : m74.toJson(),
    "m_75": m75 == null ? null : m75.toJson(),
    "m_76": m76 == null ? null : m76.toJson(),
    "m_77": m77 == null ? null : m77.toJson(),
    "m_78": m78 == null ? null : m78.toJson(),
    "m_79": m79 == null ? null : m79.toJson(),
    "m_80": m80 == null ? null : m80.toJson(),
    "m_110": m110 == null ? null : m110.toJson(),
    "m_111": m111 == null ? null : m111.toJson(),
    "m_112": m112 == null ? null : m112.toJson(),
    "m_113": m113 == null ? null : m113.toJson(),
    "m_114": m114 == null ? null : m114.toJson(),
    "m_115": m115 == null ? null : m115.toJson(),
    "m_116": m116 == null ? null : m116.toJson(),
    "m_156": m156 == null ? null : m156.toJson(),
    "m_157": m157 == null ? null : m157.toJson(),
    "m_158": m158 == null ? null : m158.toJson(),
    "m_159": m159 == null ? null : m159.toJson(),
    "m_160": m160 == null ? null : m160.toJson(),
    "m_161": m161 == null ? null : m161.toJson(),
    "m_162": m162 == null ? null : m162.toJson(),
  };
}

class Stocks {
  Stocks({
    this.h3,
    this.h19,
    this.h546,
    this.h869,
  });

  H490 h3;
  H490 h19;
  H490 h546;
  H490 h869;

  factory Stocks.fromJson(Map<String, dynamic> json) => Stocks(
    h3: json["h_3"] == null ? null : H490.fromJson(json["h_3"]),
    h19: json["h_19"] == null ? null : H490.fromJson(json["h_19"]),
    h546: json["h_546"] == null ? null : H490.fromJson(json["h_546"]),
    h869: json["h_869"] == null ? null : H490.fromJson(json["h_869"]),
  );

  Map<String, dynamic> toJson() => {
    "h_3": h3 == null ? null : h3.toJson(),
    "h_19": h19 == null ? null : h19.toJson(),
    "h_546": h546 == null ? null : h546.toJson(),
    "h_869": h869 == null ? null : h869.toJson(),
  };
}

class Strength {
  Strength({
    this.h243,
    this.h643,
    this.h646,
    this.h647,
  });

  H490 h243;
  H490 h643;
  H490 h646;
  H490 h647;

  factory Strength.fromJson(Map<String, dynamic> json) => Strength(
    h243: json["h_243"] == null ? null : H490.fromJson(json["h_243"]),
    h643: json["h_643"] == null ? null : H490.fromJson(json["h_643"]),
    h646: json["h_646"] == null ? null : H490.fromJson(json["h_646"]),
    h647: json["h_647"] == null ? null : H490.fromJson(json["h_647"]),
  );

  Map<String, dynamic> toJson() => {
    "h_243": h243 == null ? null : h243.toJson(),
    "h_643": h643 == null ? null : h643.toJson(),
    "h_646": h646 == null ? null : h646.toJson(),
    "h_647": h647 == null ? null : h647.toJson(),
  };
}

class TcEndurance {
  TcEndurance({
    this.h214,
    this.h224,
    this.h225,
    this.h278,
  });

  H490 h214;
  H490 h224;
  H490 h225;
  H490 h278;

  factory TcEndurance.fromJson(Map<String, dynamic> json) => TcEndurance(
    h214: json["h_214"] == null ? null : H490.fromJson(json["h_214"]),
    h224: json["h_224"] == null ? null : H490.fromJson(json["h_224"]),
    h225: json["h_225"] == null ? null : H490.fromJson(json["h_225"]),
    h278: json["h_278"] == null ? null : H490.fromJson(json["h_278"]),
  );

  Map<String, dynamic> toJson() => {
    "h_214": h214 == null ? null : h214.toJson(),
    "h_224": h224 == null ? null : h224.toJson(),
    "h_225": h225 == null ? null : h225.toJson(),
    "h_278": h278 == null ? null : h278.toJson(),
  };
}

class Theft {
  Theft({
    this.h2,
    this.h25,
    this.h154,
    this.h157,
    this.h158,
    this.m81,
    this.m82,
    this.m83,
    this.m84,
    this.m166,
    this.m167,
    this.m168,
    this.m169,
    this.m170,
    this.m171,
    this.m172,
  });

  H490 h2;
  H490 h25;
  H490 h154;
  H490 h157;
  H490 h158;
  M225 m81;
  M225 m82;
  M225 m83;
  M225 m84;
  M225 m166;
  M225 m167;
  M225 m168;
  M225 m169;
  M225 m170;
  M225 m171;
  M225 m172;

  factory Theft.fromJson(Map<String, dynamic> json) => Theft(
    h2: json["h_2"] == null ? null : H490.fromJson(json["h_2"]),
    h25: json["h_25"] == null ? null : H490.fromJson(json["h_25"]),
    h154: json["h_154"] == null ? null : H490.fromJson(json["h_154"]),
    h157: json["h_157"] == null ? null : H490.fromJson(json["h_157"]),
    h158: json["h_158"] == null ? null : H490.fromJson(json["h_158"]),
    m81: json["m_81"] == null ? null : M225.fromJson(json["m_81"]),
    m82: json["m_82"] == null ? null : M225.fromJson(json["m_82"]),
    m83: json["m_83"] == null ? null : M225.fromJson(json["m_83"]),
    m84: json["m_84"] == null ? null : M225.fromJson(json["m_84"]),
    m166: json["m_166"] == null ? null : M225.fromJson(json["m_166"]),
    m167: json["m_167"] == null ? null : M225.fromJson(json["m_167"]),
    m168: json["m_168"] == null ? null : M225.fromJson(json["m_168"]),
    m169: json["m_169"] == null ? null : M225.fromJson(json["m_169"]),
    m170: json["m_170"] == null ? null : M225.fromJson(json["m_170"]),
    m171: json["m_171"] == null ? null : M225.fromJson(json["m_171"]),
    m172: json["m_172"] == null ? null : M225.fromJson(json["m_172"]),
  );

  Map<String, dynamic> toJson() => {
    "h_2": h2 == null ? null : h2.toJson(),
    "h_25": h25 == null ? null : h25.toJson(),
    "h_154": h154 == null ? null : h154.toJson(),
    "h_157": h157 == null ? null : h157.toJson(),
    "h_158": h158 == null ? null : h158.toJson(),
    "m_81": m81 == null ? null : m81.toJson(),
    "m_82": m82 == null ? null : m82.toJson(),
    "m_83": m83 == null ? null : m83.toJson(),
    "m_84": m84 == null ? null : m84.toJson(),
    "m_166": m166 == null ? null : m166.toJson(),
    "m_167": m167 == null ? null : m167.toJson(),
    "m_168": m168 == null ? null : m168.toJson(),
    "m_169": m169 == null ? null : m169.toJson(),
    "m_170": m170 == null ? null : m170.toJson(),
    "m_171": m171 == null ? null : m171.toJson(),
    "m_172": m172 == null ? null : m172.toJson(),
  };
}

class Time {
  Time({
    this.h11,
    this.h165,
    this.h549,
    this.h557,
    this.h567,
    this.m207,
    this.m208,
    this.m209,
  });

  H490 h11;
  H490 h165;
  H490 h549;
  H490 h557;
  H490 h567;
  M225 m207;
  M225 m208;
  M225 m209;

  factory Time.fromJson(Map<String, dynamic> json) => Time(
    h11: json["h_11"] == null ? null : H490.fromJson(json["h_11"]),
    h165: json["h_165"] == null ? null : H490.fromJson(json["h_165"]),
    h549: json["h_549"] == null ? null : H490.fromJson(json["h_549"]),
    h557: json["h_557"] == null ? null : H490.fromJson(json["h_557"]),
    h567: json["h_567"] == null ? null : H490.fromJson(json["h_567"]),
    m207: json["m_207"] == null ? null : M225.fromJson(json["m_207"]),
    m208: json["m_208"] == null ? null : M225.fromJson(json["m_208"]),
    m209: json["m_209"] == null ? null : M225.fromJson(json["m_209"]),
  );

  Map<String, dynamic> toJson() => {
    "h_11": h11 == null ? null : h11.toJson(),
    "h_165": h165 == null ? null : h165.toJson(),
    "h_549": h549 == null ? null : h549.toJson(),
    "h_557": h557 == null ? null : h557.toJson(),
    "h_567": h567 == null ? null : h567.toJson(),
    "m_207": m207 == null ? null : m207.toJson(),
    "m_208": m208 == null ? null : m208.toJson(),
    "m_209": m209 == null ? null : m209.toJson(),
  };
}

class TokenShop {
  TokenShop({
    this.h215,
    this.h281,
    this.h283,
    this.h284,
    this.h294,
    this.h297,
    this.h298,
    this.h308,
    this.h313,
    this.h315,
    this.h318,
    this.h321,
    this.h729,
    this.h730,
  });

  H490 h215;
  H490 h281;
  H490 h283;
  H490 h284;
  H490 h294;
  H490 h297;
  H490 h298;
  H490 h308;
  H490 h313;
  H490 h315;
  H490 h318;
  H490 h321;
  H490 h729;
  H490 h730;

  factory TokenShop.fromJson(Map<String, dynamic> json) => TokenShop(
    h215: json["h_215"] == null ? null : H490.fromJson(json["h_215"]),
    h281: json["h_281"] == null ? null : H490.fromJson(json["h_281"]),
    h283: json["h_283"] == null ? null : H490.fromJson(json["h_283"]),
    h284: json["h_284"] == null ? null : H490.fromJson(json["h_284"]),
    h294: json["h_294"] == null ? null : H490.fromJson(json["h_294"]),
    h297: json["h_297"] == null ? null : H490.fromJson(json["h_297"]),
    h298: json["h_298"] == null ? null : H490.fromJson(json["h_298"]),
    h308: json["h_308"] == null ? null : H490.fromJson(json["h_308"]),
    h313: json["h_313"] == null ? null : H490.fromJson(json["h_313"]),
    h315: json["h_315"] == null ? null : H490.fromJson(json["h_315"]),
    h318: json["h_318"] == null ? null : H490.fromJson(json["h_318"]),
    h321: json["h_321"] == null ? null : H490.fromJson(json["h_321"]),
    h729: json["h_729"] == null ? null : H490.fromJson(json["h_729"]),
    h730: json["h_730"] == null ? null : H490.fromJson(json["h_730"]),
  );

  Map<String, dynamic> toJson() => {
    "h_215": h215 == null ? null : h215.toJson(),
    "h_281": h281 == null ? null : h281.toJson(),
    "h_283": h283 == null ? null : h283.toJson(),
    "h_284": h284 == null ? null : h284.toJson(),
    "h_294": h294 == null ? null : h294.toJson(),
    "h_297": h297 == null ? null : h297.toJson(),
    "h_298": h298 == null ? null : h298.toJson(),
    "h_308": h308 == null ? null : h308.toJson(),
    "h_313": h313 == null ? null : h313.toJson(),
    "h_315": h315 == null ? null : h315.toJson(),
    "h_318": h318 == null ? null : h318.toJson(),
    "h_321": h321 == null ? null : h321.toJson(),
    "h_729": h729 == null ? null : h729.toJson(),
    "h_730": h730 == null ? null : h730.toJson(),
  };
}

class TornOfTheDead {
  TornOfTheDead({
    this.h263,
    this.h306,
    this.h311,
  });

  H490 h263;
  H490 h306;
  H490 h311;

  factory TornOfTheDead.fromJson(Map<String, dynamic> json) => TornOfTheDead(
    h263: json["h_263"] == null ? null : H490.fromJson(json["h_263"]),
    h306: json["h_306"] == null ? null : H490.fromJson(json["h_306"]),
    h311: json["h_311"] == null ? null : H490.fromJson(json["h_311"]),
  );

  Map<String, dynamic> toJson() => {
    "h_263": h263 == null ? null : h263.toJson(),
    "h_306": h306 == null ? null : h306.toJson(),
    "h_311": h311 == null ? null : h311.toJson(),
  };
}

class Total {
  Total({
    this.h251,
  });

  H490 h251;

  factory Total.fromJson(Map<String, dynamic> json) => Total(
    h251: json["h_251"] == null ? null : H490.fromJson(json["h_251"]),
  );

  Map<String, dynamic> toJson() => {
    "h_251": h251 == null ? null : h251.toJson(),
  };
}

class TotalStats {
  TotalStats({
    this.h679,
    this.h686,
    this.h687,
    this.h690,
    this.h694,
    this.h704,
    this.h708,
    this.h720,
    this.h721,
    this.h723,
  });

  H490 h679;
  H490 h686;
  H490 h687;
  H490 h690;
  H490 h694;
  H490 h704;
  H490 h708;
  H490 h720;
  H490 h721;
  H490 h723;

  factory TotalStats.fromJson(Map<String, dynamic> json) => TotalStats(
    h679: json["h_679"] == null ? null : H490.fromJson(json["h_679"]),
    h686: json["h_686"] == null ? null : H490.fromJson(json["h_686"]),
    h687: json["h_687"] == null ? null : H490.fromJson(json["h_687"]),
    h690: json["h_690"] == null ? null : H490.fromJson(json["h_690"]),
    h694: json["h_694"] == null ? null : H490.fromJson(json["h_694"]),
    h704: json["h_704"] == null ? null : H490.fromJson(json["h_704"]),
    h708: json["h_708"] == null ? null : H490.fromJson(json["h_708"]),
    h720: json["h_720"] == null ? null : H490.fromJson(json["h_720"]),
    h721: json["h_721"] == null ? null : H490.fromJson(json["h_721"]),
    h723: json["h_723"] == null ? null : H490.fromJson(json["h_723"]),
  );

  Map<String, dynamic> toJson() => {
    "h_679": h679 == null ? null : h679.toJson(),
    "h_686": h686 == null ? null : h686.toJson(),
    "h_687": h687 == null ? null : h687.toJson(),
    "h_690": h690 == null ? null : h690.toJson(),
    "h_694": h694 == null ? null : h694.toJson(),
    "h_704": h704 == null ? null : h704.toJson(),
    "h_708": h708 == null ? null : h708.toJson(),
    "h_720": h720 == null ? null : h720.toJson(),
    "h_721": h721 == null ? null : h721.toJson(),
    "h_723": h723 == null ? null : h723.toJson(),
  };
}

class TrickOrTreats {
  TrickOrTreats({
    this.h964,
    this.h966,
    this.h969,
  });

  H490 h964;
  H490 h966;
  H490 h969;

  factory TrickOrTreats.fromJson(Map<String, dynamic> json) => TrickOrTreats(
    h964: json["h_964"] == null ? null : H490.fromJson(json["h_964"]),
    h966: json["h_966"] == null ? null : H490.fromJson(json["h_966"]),
    h969: json["h_969"] == null ? null : H490.fromJson(json["h_969"]),
  );

  Map<String, dynamic> toJson() => {
    "h_964": h964 == null ? null : h964.toJson(),
    "h_966": h966 == null ? null : h966.toJson(),
    "h_969": h969 == null ? null : h969.toJson(),
  };
}

class Vicodin {
  Vicodin({
    this.h38,
  });

  H490 h38;

  factory Vicodin.fromJson(Map<String, dynamic> json) => Vicodin(
    h38: json["h_38"] == null ? null : H490.fromJson(json["h_38"]),
  );

  Map<String, dynamic> toJson() => {
    "h_38": h38 == null ? null : h38.toJson(),
  };
}

class Wins {
  Wins({
    this.h39,
    this.h40,
    this.h41,
    this.h42,
    this.h43,
    this.h44,
    this.h45,
    this.h46,
    this.h47,
    this.h48,
    this.h49,
    this.m174,
    this.m175,
    this.m176,
    this.m177,
    this.m178,
  });

  H490 h39;
  H490 h40;
  H490 h41;
  H490 h42;
  H490 h43;
  H490 h44;
  H490 h45;
  H490 h46;
  H490 h47;
  H490 h48;
  H490 h49;
  M225 m174;
  M225 m175;
  M225 m176;
  M225 m177;
  M225 m178;

  factory Wins.fromJson(Map<String, dynamic> json) => Wins(
    h39: json["h_39"] == null ? null : H490.fromJson(json["h_39"]),
    h40: json["h_40"] == null ? null : H490.fromJson(json["h_40"]),
    h41: json["h_41"] == null ? null : H490.fromJson(json["h_41"]),
    h42: json["h_42"] == null ? null : H490.fromJson(json["h_42"]),
    h43: json["h_43"] == null ? null : H490.fromJson(json["h_43"]),
    h44: json["h_44"] == null ? null : H490.fromJson(json["h_44"]),
    h45: json["h_45"] == null ? null : H490.fromJson(json["h_45"]),
    h46: json["h_46"] == null ? null : H490.fromJson(json["h_46"]),
    h47: json["h_47"] == null ? null : H490.fromJson(json["h_47"]),
    h48: json["h_48"] == null ? null : H490.fromJson(json["h_48"]),
    h49: json["h_49"] == null ? null : H490.fromJson(json["h_49"]),
    m174: json["m_174"] == null ? null : M225.fromJson(json["m_174"]),
    m175: json["m_175"] == null ? null : M225.fromJson(json["m_175"]),
    m176: json["m_176"] == null ? null : M225.fromJson(json["m_176"]),
    m177: json["m_177"] == null ? null : M225.fromJson(json["m_177"]),
    m178: json["m_178"] == null ? null : M225.fromJson(json["m_178"]),
  );

  Map<String, dynamic> toJson() => {
    "h_39": h39 == null ? null : h39.toJson(),
    "h_40": h40 == null ? null : h40.toJson(),
    "h_41": h41 == null ? null : h41.toJson(),
    "h_42": h42 == null ? null : h42.toJson(),
    "h_43": h43 == null ? null : h43.toJson(),
    "h_44": h44 == null ? null : h44.toJson(),
    "h_45": h45 == null ? null : h45.toJson(),
    "h_46": h46 == null ? null : h46.toJson(),
    "h_47": h47 == null ? null : h47.toJson(),
    "h_48": h48 == null ? null : h48.toJson(),
    "h_49": h49 == null ? null : h49.toJson(),
    "m_174": m174 == null ? null : m174.toJson(),
    "m_175": m175 == null ? null : m175.toJson(),
    "m_176": m176 == null ? null : m176.toJson(),
    "m_177": m177 == null ? null : m177.toJson(),
    "m_178": m178 == null ? null : m178.toJson(),
  };
}

class WorkingStats {
  WorkingStats({
    this.h525,
    this.h530,
    this.h533,
    this.h844,
  });

  H490 h525;
  H490 h530;
  H490 h533;
  H490 h844;

  factory WorkingStats.fromJson(Map<String, dynamic> json) => WorkingStats(
    h525: json["h_525"] == null ? null : H490.fromJson(json["h_525"]),
    h530: json["h_530"] == null ? null : H490.fromJson(json["h_530"]),
    h533: json["h_533"] == null ? null : H490.fromJson(json["h_533"]),
    h844: json["h_844"] == null ? null : H490.fromJson(json["h_844"]),
  );

  Map<String, dynamic> toJson() => {
    "h_525": h525 == null ? null : h525.toJson(),
    "h_530": h530 == null ? null : h530.toJson(),
    "h_533": h533 == null ? null : h533.toJson(),
    "h_844": h844 == null ? null : h844.toJson(),
  };
}

class Xanax {
  Xanax({
    this.h37,
  });

  H490 h37;

  factory Xanax.fromJson(Map<String, dynamic> json) => Xanax(
    h37: json["h_37"] == null ? null : H490.fromJson(json["h_37"]),
  );

  Map<String, dynamic> toJson() => {
    "h_37": h37 == null ? null : h37.toJson(),
  };
}

class PinnedAwards {
  PinnedAwards();

  factory PinnedAwards.fromJson(Map<String, dynamic> json) => PinnedAwards(
  );

  Map<String, dynamic> toJson() => {
  };
}

class Player {
  Player({
    this.id,
    this.tId,
    this.name,
    this.active,
    this.validKey,
    this.factionId,
    this.factionAa,
    this.factionNa,
    this.companyId,
    this.companyTy,
    this.companyDi,
    this.companyNa,
    this.wint,
    this.wend,
    this.wman,
    this.lastUpdateTs,
    this.lastActionTs,
    this.chainInfo,
    this.chainJson,
    this.chainUpda,
    this.targetInfo,
    this.attacksUpda,
    this.revivesUpda,
    this.bazaarInfo,
    this.bazaarJson,
    this.bazaarUpda,
    this.awardsUpda,
    this.awardsScor,
    this.awardsNumb,
    this.awardsPinn,
    this.stocksInfo,
    this.stocksJson,
    this.stocksUpda,
    this.dId,
    this.activateNotifications,
    this.notifications,
  });

  num id;
  num tId;
  String name;
  bool active;
  bool validKey;
  num factionId;
  bool factionAa;
  String factionNa;
  num companyId;
  num companyTy;
  bool companyDi;
  String companyNa;
  num wint;
  num wend;
  num wman;
  num lastUpdateTs;
  num lastActionTs;
  String chainInfo;
  String chainJson;
  num chainUpda;
  String targetInfo;
  num attacksUpda;
  num revivesUpda;
  String bazaarInfo;
  String bazaarJson;
  num bazaarUpda;
  num awardsUpda;
  num awardsScor;
  num awardsNumb;
  String awardsPinn;
  String stocksInfo;
  String stocksJson;
  num stocksUpda;
  num dId;
  bool activateNotifications;
  String notifications;

  factory Player.fromJson(Map<String, dynamic> json) => Player(
    id: json["id"] == null ? null : json["id"],
    tId: json["tId"] == null ? null : json["tId"],
    name: json["name"] == null ? null : json["name"],
    active: json["active"] == null ? null : json["active"],
    validKey: json["validKey"] == null ? null : json["validKey"],
    factionId: json["factionId"] == null ? null : json["factionId"],
    factionAa: json["factionAA"] == null ? null : json["factionAA"],
    factionNa: json["factionNa"] == null ? null : json["factionNa"],
    companyId: json["companyId"] == null ? null : json["companyId"],
    companyTy: json["companyTy"] == null ? null : json["companyTy"],
    companyDi: json["companyDi"] == null ? null : json["companyDi"],
    companyNa: json["companyNa"] == null ? null : json["companyNa"],
    wint: json["wint"] == null ? null : json["wint"],
    wend: json["wend"] == null ? null : json["wend"],
    wman: json["wman"] == null ? null : json["wman"],
    lastUpdateTs: json["lastUpdateTS"] == null ? null : json["lastUpdateTS"],
    lastActionTs: json["lastActionTS"] == null ? null : json["lastActionTS"],
    chainInfo: json["chainInfo"] == null ? null : json["chainInfo"],
    chainJson: json["chainJson"] == null ? null : json["chainJson"],
    chainUpda: json["chainUpda"] == null ? null : json["chainUpda"],
    targetInfo: json["targetInfo"] == null ? null : json["targetInfo"],
    attacksUpda: json["attacksUpda"] == null ? null : json["attacksUpda"],
    revivesUpda: json["revivesUpda"] == null ? null : json["revivesUpda"],
    bazaarInfo: json["bazaarInfo"] == null ? null : json["bazaarInfo"],
    bazaarJson: json["bazaarJson"] == null ? null : json["bazaarJson"],
    bazaarUpda: json["bazaarUpda"] == null ? null : json["bazaarUpda"],
    awardsUpda: json["awardsUpda"] == null ? null : json["awardsUpda"],
    awardsScor: json["awardsScor"] == null ? null : json["awardsScor"],
    awardsNumb: json["awardsNumb"] == null ? null : json["awardsNumb"],
    awardsPinn: json["awardsPinn"] == null ? null : json["awardsPinn"],
    stocksInfo: json["stocksInfo"] == null ? null : json["stocksInfo"],
    stocksJson: json["stocksJson"] == null ? null : json["stocksJson"],
    stocksUpda: json["stocksUpda"] == null ? null : json["stocksUpda"],
    dId: json["dId"] == null ? null : json["dId"],
    activateNotifications: json["activateNotifications"] == null ? null : json["activateNotifications"],
    notifications: json["notifications"] == null ? null : json["notifications"],
  );

  Map<String, dynamic> toJson() => {
    "id": id == null ? null : id,
    "tId": tId == null ? null : tId,
    "name": name == null ? null : name,
    "active": active == null ? null : active,
    "validKey": validKey == null ? null : validKey,
    "factionId": factionId == null ? null : factionId,
    "factionAA": factionAa == null ? null : factionAa,
    "factionNa": factionNa == null ? null : factionNa,
    "companyId": companyId == null ? null : companyId,
    "companyTy": companyTy == null ? null : companyTy,
    "companyDi": companyDi == null ? null : companyDi,
    "companyNa": companyNa == null ? null : companyNa,
    "wint": wint == null ? null : wint,
    "wend": wend == null ? null : wend,
    "wman": wman == null ? null : wman,
    "lastUpdateTS": lastUpdateTs == null ? null : lastUpdateTs,
    "lastActionTS": lastActionTs == null ? null : lastActionTs,
    "chainInfo": chainInfo == null ? null : chainInfo,
    "chainJson": chainJson == null ? null : chainJson,
    "chainUpda": chainUpda == null ? null : chainUpda,
    "targetInfo": targetInfo == null ? null : targetInfo,
    "attacksUpda": attacksUpda == null ? null : attacksUpda,
    "revivesUpda": revivesUpda == null ? null : revivesUpda,
    "bazaarInfo": bazaarInfo == null ? null : bazaarInfo,
    "bazaarJson": bazaarJson == null ? null : bazaarJson,
    "bazaarUpda": bazaarUpda == null ? null : bazaarUpda,
    "awardsUpda": awardsUpda == null ? null : awardsUpda,
    "awardsScor": awardsScor == null ? null : awardsScor,
    "awardsNumb": awardsNumb == null ? null : awardsNumb,
    "awardsPinn": awardsPinn == null ? null : awardsPinn,
    "stocksInfo": stocksInfo == null ? null : stocksInfo,
    "stocksJson": stocksJson == null ? null : stocksJson,
    "stocksUpda": stocksUpda == null ? null : stocksUpda,
    "dId": dId == null ? null : dId,
    "activateNotifications": activateNotifications == null ? null : activateNotifications,
    "notifications": notifications == null ? null : notifications,
  };
}

class SummaryByType {
  SummaryByType({
    this.allAwards,
    this.allHonors,
    this.allMedals,
    this.attacks,
    this.commitment,
    this.travel,
    this.crimes,
    this.faction,
    this.money,
    this.miscellaneous,
    this.items,
    this.work,
    this.gym,
    this.competitions,
    this.drugs,
  });

  AllAwards allAwards;
  AllAwards allHonors;
  AllAwards allMedals;
  AllAwards attacks;
  AllAwards commitment;
  AllAwards travel;
  AllAwards crimes;
  AllAwards faction;
  AllAwards money;
  AllAwards miscellaneous;
  AllAwards items;
  AllAwards work;
  AllAwards gym;
  AllAwards competitions;
  AllAwards drugs;

  factory SummaryByType.fromJson(Map<String, dynamic> json) => SummaryByType(
    allAwards: json["AllAwards"] == null ? null : AllAwards.fromJson(json["AllAwards"]),
    allHonors: json["AllHonors"] == null ? null : AllAwards.fromJson(json["AllHonors"]),
    allMedals: json["AllMedals"] == null ? null : AllAwards.fromJson(json["AllMedals"]),
    attacks: json["Attacks"] == null ? null : AllAwards.fromJson(json["Attacks"]),
    commitment: json["Commitment"] == null ? null : AllAwards.fromJson(json["Commitment"]),
    travel: json["Travel"] == null ? null : AllAwards.fromJson(json["Travel"]),
    crimes: json["Crimes"] == null ? null : AllAwards.fromJson(json["Crimes"]),
    faction: json["Faction"] == null ? null : AllAwards.fromJson(json["Faction"]),
    money: json["Money"] == null ? null : AllAwards.fromJson(json["Money"]),
    miscellaneous: json["Miscellaneous"] == null ? null : AllAwards.fromJson(json["Miscellaneous"]),
    items: json["Items"] == null ? null : AllAwards.fromJson(json["Items"]),
    work: json["Work"] == null ? null : AllAwards.fromJson(json["Work"]),
    gym: json["Gym"] == null ? null : AllAwards.fromJson(json["Gym"]),
    competitions: json["Competitions"] == null ? null : AllAwards.fromJson(json["Competitions"]),
    drugs: json["Drugs"] == null ? null : AllAwards.fromJson(json["Drugs"]),
  );

  Map<String, dynamic> toJson() => {
    "AllAwards": allAwards == null ? null : allAwards.toJson(),
    "AllHonors": allHonors == null ? null : allHonors.toJson(),
    "AllMedals": allMedals == null ? null : allMedals.toJson(),
    "Attacks": attacks == null ? null : attacks.toJson(),
    "Commitment": commitment == null ? null : commitment.toJson(),
    "Travel": travel == null ? null : travel.toJson(),
    "Crimes": crimes == null ? null : crimes.toJson(),
    "Faction": faction == null ? null : faction.toJson(),
    "Money": money == null ? null : money.toJson(),
    "Miscellaneous": miscellaneous == null ? null : miscellaneous.toJson(),
    "Items": items == null ? null : items.toJson(),
    "Work": work == null ? null : work.toJson(),
    "Gym": gym == null ? null : gym.toJson(),
    "Competitions": competitions == null ? null : competitions.toJson(),
    "Drugs": drugs == null ? null : drugs.toJson(),
  };
}

class AllAwards {
  AllAwards({
    this.nAwarded,
    this.nAwards,
  });

  num nAwarded;
  num nAwards;

  factory AllAwards.fromJson(Map<String, dynamic> json) => AllAwards(
    nAwarded: json["nAwarded"] == null ? null : json["nAwarded"],
    nAwards: json["nAwards"] == null ? null : json["nAwards"],
  );

  Map<String, dynamic> toJson() => {
    "nAwarded": nAwarded == null ? null : nAwarded,
    "nAwards": nAwards == null ? null : nAwards,
  };
}

class UserInfo {
  UserInfo({
    this.educationCurrent,
    this.educationTimeleft,
    this.strength,
    this.speed,
    this.dexterity,
    this.defense,
    this.total,
    this.strengthModifier,
    this.defenseModifier,
    this.speedModifier,
    this.dexterityModifier,
    this.manualLabor,
    this.intelligence,
    this.endurance,
    this.activeGym,
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
    this.serverTime,
    this.personalstats,
    this.criminalrecord,
    this.educationCompleted,
    this.strengthInfo,
    this.defenseInfo,
    this.speedInfo,
    this.dexterityInfo,
    this.jobPerks,
    this.propertyPerks,
    this.stockPerks,
    this.meritPerks,
    this.educationPerks,
    this.enhancerPerks,
    this.companyPerks,
    this.factionPerks,
    this.bookPerks,
    this.networth,
    this.merits,
    this.life,
    this.status,
    this.job,
    this.faction,
    this.married,
    this.basicicons,
    this.states,
    this.lastAction,
    this.medalsAwarded,
    this.medalsTime,
    this.honorsAwarded,
    this.honorsTime,
    this.icons,
    this.happy,
    this.energy,
    this.nerve,
    this.chain,
    this.weaponexp,
    this.halloffame,
  });

  num educationCurrent;
  num educationTimeleft;
  num strength;
  num speed;
  num dexterity;
  num defense;
  num total;
  num strengthModifier;
  num defenseModifier;
  num speedModifier;
  num dexterityModifier;
  num manualLabor;
  num intelligence;
  num endurance;
  num activeGym;
  String rank;
  num level;
  String gender;
  String property;
  String signup;
  num awards;
  num friends;
  num enemies;
  num forumPosts;
  num karma;
  num age;
  String role;
  num donator;
  num playerId;
  String name;
  num propertyId;
  dynamic competition;
  num serverTime;
  Personalstats personalstats;
  Criminalrecord criminalrecord;
  List<num> educationCompleted;
  List<String> strengthInfo;
  List<String> defenseInfo;
  List<String> speedInfo;
  List<String> dexterityInfo;
  List<dynamic> jobPerks;
  List<String> propertyPerks;
  List<dynamic> stockPerks;
  List<String> meritPerks;
  List<String> educationPerks;
  List<String> enhancerPerks;
  List<String> companyPerks;
  List<String> factionPerks;
  List<dynamic> bookPerks;
  NetworthClass networth;
  Merits merits;
  Energy life;
  Status status;
  Job job;
  Faction faction;
  Married married;
  Basicicons basicicons;
  States states;
  LastAction lastAction;
  List<num> medalsAwarded;
  List<num> medalsTime;
  List<num> honorsAwarded;
  List<num> honorsTime;
  Icons icons;
  Energy happy;
  Energy energy;
  Energy nerve;
  Chain chain;
  List<Weaponexp> weaponexp;
  Halloffame halloffame;

  factory UserInfo.fromJson(Map<String, dynamic> json) => UserInfo(
    educationCurrent: json["education_current"] == null ? null : json["education_current"],
    educationTimeleft: json["education_timeleft"] == null ? null : json["education_timeleft"],
    strength: json["strength"] == null ? null : json["strength"],
    speed: json["speed"] == null ? null : json["speed"],
    dexterity: json["dexterity"] == null ? null : json["dexterity"],
    defense: json["defense"] == null ? null : json["defense"],
    total: json["total"] == null ? null : json["total"],
    strengthModifier: json["strength_modifier"] == null ? null : json["strength_modifier"],
    defenseModifier: json["defense_modifier"] == null ? null : json["defense_modifier"],
    speedModifier: json["speed_modifier"] == null ? null : json["speed_modifier"],
    dexterityModifier: json["dexterity_modifier"] == null ? null : json["dexterity_modifier"],
    manualLabor: json["manual_labor"] == null ? null : json["manual_labor"],
    intelligence: json["intelligence"] == null ? null : json["intelligence"],
    endurance: json["endurance"] == null ? null : json["endurance"],
    activeGym: json["active_gym"] == null ? null : json["active_gym"],
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
    serverTime: json["server_time"] == null ? null : json["server_time"],
    personalstats: json["personalstats"] == null ? null : Personalstats.fromJson(json["personalstats"]),
    criminalrecord: json["criminalrecord"] == null ? null : Criminalrecord.fromJson(json["criminalrecord"]),
    educationCompleted: json["education_completed"] == null ? null : List<num>.from(json["education_completed"].map((x) => x)),
    strengthInfo: json["strength_info"] == null ? null : List<String>.from(json["strength_info"].map((x) => x)),
    defenseInfo: json["defense_info"] == null ? null : List<String>.from(json["defense_info"].map((x) => x)),
    speedInfo: json["speed_info"] == null ? null : List<String>.from(json["speed_info"].map((x) => x)),
    dexterityInfo: json["dexterity_info"] == null ? null : List<String>.from(json["dexterity_info"].map((x) => x)),
    jobPerks: json["job_perks"] == null ? null : List<dynamic>.from(json["job_perks"].map((x) => x)),
    propertyPerks: json["property_perks"] == null ? null : List<String>.from(json["property_perks"].map((x) => x)),
    stockPerks: json["stock_perks"] == null ? null : List<dynamic>.from(json["stock_perks"].map((x) => x)),
    meritPerks: json["merit_perks"] == null ? null : List<String>.from(json["merit_perks"].map((x) => x)),
    educationPerks: json["education_perks"] == null ? null : List<String>.from(json["education_perks"].map((x) => x)),
    enhancerPerks: json["enhancer_perks"] == null ? null : List<String>.from(json["enhancer_perks"].map((x) => x)),
    companyPerks: json["company_perks"] == null ? null : List<String>.from(json["company_perks"].map((x) => x)),
    factionPerks: json["faction_perks"] == null ? null : List<String>.from(json["faction_perks"].map((x) => x)),
    bookPerks: json["book_perks"] == null ? null : List<dynamic>.from(json["book_perks"].map((x) => x)),
    networth: json["networth"] == null ? null : NetworthClass.fromJson(json["networth"]),
    merits: json["merits"] == null ? null : Merits.fromJson(json["merits"]),
    life: json["life"] == null ? null : Energy.fromJson(json["life"]),
    status: json["status"] == null ? null : Status.fromJson(json["status"]),
    job: json["job"] == null ? null : Job.fromJson(json["job"]),
    faction: json["faction"] == null ? null : Faction.fromJson(json["faction"]),
    married: json["married"] == null ? null : Married.fromJson(json["married"]),
    basicicons: json["basicicons"] == null ? null : Basicicons.fromJson(json["basicicons"]),
    states: json["states"] == null ? null : States.fromJson(json["states"]),
    lastAction: json["last_action"] == null ? null : LastAction.fromJson(json["last_action"]),
    medalsAwarded: json["medals_awarded"] == null ? null : List<num>.from(json["medals_awarded"].map((x) => x)),
    medalsTime: json["medals_time"] == null ? null : List<num>.from(json["medals_time"].map((x) => x)),
    honorsAwarded: json["honors_awarded"] == null ? null : List<num>.from(json["honors_awarded"].map((x) => x)),
    honorsTime: json["honors_time"] == null ? null : List<num>.from(json["honors_time"].map((x) => x)),
    icons: json["icons"] == null ? null : Icons.fromJson(json["icons"]),
    happy: json["happy"] == null ? null : Energy.fromJson(json["happy"]),
    energy: json["energy"] == null ? null : Energy.fromJson(json["energy"]),
    nerve: json["nerve"] == null ? null : Energy.fromJson(json["nerve"]),
    chain: json["chain"] == null ? null : Chain.fromJson(json["chain"]),
    weaponexp: json["weaponexp"] == null ? null : List<Weaponexp>.from(json["weaponexp"].map((x) => Weaponexp.fromJson(x))),
    halloffame: json["halloffame"] == null ? null : Halloffame.fromJson(json["halloffame"]),
  );

  Map<String, dynamic> toJson() => {
    "education_current": educationCurrent == null ? null : educationCurrent,
    "education_timeleft": educationTimeleft == null ? null : educationTimeleft,
    "strength": strength == null ? null : strength,
    "speed": speed == null ? null : speed,
    "dexterity": dexterity == null ? null : dexterity,
    "defense": defense == null ? null : defense,
    "total": total == null ? null : total,
    "strength_modifier": strengthModifier == null ? null : strengthModifier,
    "defense_modifier": defenseModifier == null ? null : defenseModifier,
    "speed_modifier": speedModifier == null ? null : speedModifier,
    "dexterity_modifier": dexterityModifier == null ? null : dexterityModifier,
    "manual_labor": manualLabor == null ? null : manualLabor,
    "intelligence": intelligence == null ? null : intelligence,
    "endurance": endurance == null ? null : endurance,
    "active_gym": activeGym == null ? null : activeGym,
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
    "server_time": serverTime == null ? null : serverTime,
    "personalstats": personalstats == null ? null : personalstats.toJson(),
    "criminalrecord": criminalrecord == null ? null : criminalrecord.toJson(),
    "education_completed": educationCompleted == null ? null : List<dynamic>.from(educationCompleted.map((x) => x)),
    "strength_info": strengthInfo == null ? null : List<dynamic>.from(strengthInfo.map((x) => x)),
    "defense_info": defenseInfo == null ? null : List<dynamic>.from(defenseInfo.map((x) => x)),
    "speed_info": speedInfo == null ? null : List<dynamic>.from(speedInfo.map((x) => x)),
    "dexterity_info": dexterityInfo == null ? null : List<dynamic>.from(dexterityInfo.map((x) => x)),
    "job_perks": jobPerks == null ? null : List<dynamic>.from(jobPerks.map((x) => x)),
    "property_perks": propertyPerks == null ? null : List<dynamic>.from(propertyPerks.map((x) => x)),
    "stock_perks": stockPerks == null ? null : List<dynamic>.from(stockPerks.map((x) => x)),
    "merit_perks": meritPerks == null ? null : List<dynamic>.from(meritPerks.map((x) => x)),
    "education_perks": educationPerks == null ? null : List<dynamic>.from(educationPerks.map((x) => x)),
    "enhancer_perks": enhancerPerks == null ? null : List<dynamic>.from(enhancerPerks.map((x) => x)),
    "company_perks": companyPerks == null ? null : List<dynamic>.from(companyPerks.map((x) => x)),
    "faction_perks": factionPerks == null ? null : List<dynamic>.from(factionPerks.map((x) => x)),
    "book_perks": bookPerks == null ? null : List<dynamic>.from(bookPerks.map((x) => x)),
    "networth": networth == null ? null : networth.toJson(),
    "merits": merits == null ? null : merits.toJson(),
    "life": life == null ? null : life.toJson(),
    "status": status == null ? null : status.toJson(),
    "job": job == null ? null : job.toJson(),
    "faction": faction == null ? null : faction.toJson(),
    "married": married == null ? null : married.toJson(),
    "basicicons": basicicons == null ? null : basicicons.toJson(),
    "states": states == null ? null : states.toJson(),
    "last_action": lastAction == null ? null : lastAction.toJson(),
    "medals_awarded": medalsAwarded == null ? null : List<dynamic>.from(medalsAwarded.map((x) => x)),
    "medals_time": medalsTime == null ? null : List<dynamic>.from(medalsTime.map((x) => x)),
    "honors_awarded": honorsAwarded == null ? null : List<dynamic>.from(honorsAwarded.map((x) => x)),
    "honors_time": honorsTime == null ? null : List<dynamic>.from(honorsTime.map((x) => x)),
    "icons": icons == null ? null : icons.toJson(),
    "happy": happy == null ? null : happy.toJson(),
    "energy": energy == null ? null : energy.toJson(),
    "nerve": nerve == null ? null : nerve.toJson(),
    "chain": chain == null ? null : chain.toJson(),
    "weaponexp": weaponexp == null ? null : List<dynamic>.from(weaponexp.map((x) => x.toJson())),
    "halloffame": halloffame == null ? null : halloffame.toJson(),
  };
}

class Basicicons {
  Basicicons({
    this.icon6,
    this.icon4,
    this.icon8,
    this.icon27,
    this.icon9,
  });

  String icon6;
  String icon4;
  String icon8;
  String icon27;
  String icon9;

  factory Basicicons.fromJson(Map<String, dynamic> json) => Basicicons(
    icon6: json["icon6"] == null ? null : json["icon6"],
    icon4: json["icon4"] == null ? null : json["icon4"],
    icon8: json["icon8"] == null ? null : json["icon8"],
    icon27: json["icon27"] == null ? null : json["icon27"],
    icon9: json["icon9"] == null ? null : json["icon9"],
  );

  Map<String, dynamic> toJson() => {
    "icon6": icon6 == null ? null : icon6,
    "icon4": icon4 == null ? null : icon4,
    "icon8": icon8 == null ? null : icon8,
    "icon27": icon27 == null ? null : icon27,
    "icon9": icon9 == null ? null : icon9,
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

  num current;
  num maximum;
  num timeout;
  num modifier;
  num cooldown;

  factory Chain.fromJson(Map<String, dynamic> json) => Chain(
    current: json["current"] == null ? null : json["current"],
    maximum: json["maximum"] == null ? null : json["maximum"],
    timeout: json["timeout"] == null ? null : json["timeout"],
    modifier: json["modifier"] == null ? null : json["modifier"],
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

  num sellingIllegalProducts;
  num theft;
  num autoTheft;
  num drugDeals;
  num computerCrimes;
  num murder;
  num fraudCrimes;
  num other;
  num total;

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

class Energy {
  Energy({
    this.current,
    this.maximum,
    this.increment,
    this.interval,
    this.ticktime,
    this.fulltime,
  });

  num current;
  num maximum;
  num increment;
  num interval;
  num ticktime;
  num fulltime;

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
  num factionId;
  num daysInFaction;
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

class Halloffame {
  Halloffame({
    this.attacks,
    this.battlestats,
    this.busts,
    this.defends,
    this.networth,
    this.offences,
    this.traveled,
    this.workstats,
    this.level,
    this.rank,
  });

  Attacks attacks;
  Attacks battlestats;
  Attacks busts;
  Attacks defends;
  Attacks networth;
  Attacks offences;
  Attacks traveled;
  Attacks workstats;
  Attacks level;
  Attacks rank;

  factory Halloffame.fromJson(Map<String, dynamic> json) => Halloffame(
    attacks: json["attacks"] == null ? null : Attacks.fromJson(json["attacks"]),
    battlestats: json["battlestats"] == null ? null : Attacks.fromJson(json["battlestats"]),
    busts: json["busts"] == null ? null : Attacks.fromJson(json["busts"]),
    defends: json["defends"] == null ? null : Attacks.fromJson(json["defends"]),
    networth: json["networth"] == null ? null : Attacks.fromJson(json["networth"]),
    offences: json["offences"] == null ? null : Attacks.fromJson(json["offences"]),
    traveled: json["traveled"] == null ? null : Attacks.fromJson(json["traveled"]),
    workstats: json["workstats"] == null ? null : Attacks.fromJson(json["workstats"]),
    level: json["level"] == null ? null : Attacks.fromJson(json["level"]),
    rank: json["rank"] == null ? null : Attacks.fromJson(json["rank"]),
  );

  Map<String, dynamic> toJson() => {
    "attacks": attacks == null ? null : attacks.toJson(),
    "battlestats": battlestats == null ? null : battlestats.toJson(),
    "busts": busts == null ? null : busts.toJson(),
    "defends": defends == null ? null : defends.toJson(),
    "networth": networth == null ? null : networth.toJson(),
    "offences": offences == null ? null : offences.toJson(),
    "traveled": traveled == null ? null : traveled.toJson(),
    "workstats": workstats == null ? null : workstats.toJson(),
    "level": level == null ? null : level.toJson(),
    "rank": rank == null ? null : rank.toJson(),
  };
}

class Attacks {
  Attacks({
    this.value,
    this.rank,
  });

  num value;
  num rank;

  factory Attacks.fromJson(Map<String, dynamic> json) => Attacks(
    value: json["value"] == null ? null : json["value"],
    rank: json["rank"] == null ? null : json["rank"],
  );

  Map<String, dynamic> toJson() => {
    "value": value == null ? null : value,
    "rank": rank == null ? null : rank,
  };
}

class Icons {
  Icons({
    this.icon6,
    this.icon4,
    this.icon8,
    this.icon38,
    this.icon27,
    this.icon9,
    this.icon19,
    this.icon32,
    this.icon44,
  });

  String icon6;
  String icon4;
  String icon8;
  String icon38;
  String icon27;
  String icon9;
  String icon19;
  String icon32;
  String icon44;

  factory Icons.fromJson(Map<String, dynamic> json) => Icons(
    icon6: json["icon6"] == null ? null : json["icon6"],
    icon4: json["icon4"] == null ? null : json["icon4"],
    icon8: json["icon8"] == null ? null : json["icon8"],
    icon38: json["icon38"] == null ? null : json["icon38"],
    icon27: json["icon27"] == null ? null : json["icon27"],
    icon9: json["icon9"] == null ? null : json["icon9"],
    icon19: json["icon19"] == null ? null : json["icon19"],
    icon32: json["icon32"] == null ? null : json["icon32"],
    icon44: json["icon44"] == null ? null : json["icon44"],
  );

  Map<String, dynamic> toJson() => {
    "icon6": icon6 == null ? null : icon6,
    "icon4": icon4 == null ? null : icon4,
    "icon8": icon8 == null ? null : icon8,
    "icon38": icon38 == null ? null : icon38,
    "icon27": icon27 == null ? null : icon27,
    "icon9": icon9 == null ? null : icon9,
    "icon19": icon19 == null ? null : icon19,
    "icon32": icon32 == null ? null : icon32,
    "icon44": icon44 == null ? null : icon44,
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
  num companyId;
  String companyName;
  num companyType;

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
  num timestamp;
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

  num spouseId;
  String spouseName;
  num duration;

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

class Merits {
  Merits({
    this.nerveBar,
    this.criticalHitRate,
    this.lifePoints,
    this.crimeExperience,
    this.educationLength,
    this.awareness,
    this.bankInterest,
    this.masterfulLooting,
    this.stealth,
    this.hospitalizing,
    this.brawn,
    this.protection,
    this.sharpness,
    this.evasion,
    this.heavyArtilleryMastery,
    this.machineGunMastery,
    this.rifleMastery,
    this.smgMastery,
    this.shotgunMastery,
    this.pistolMastery,
    this.clubMastery,
    this.piercingMastery,
    this.slashingMastery,
    this.mechanicalMastery,
    this.temporaryMastery,
  });

  num nerveBar;
  num criticalHitRate;
  num lifePoints;
  num crimeExperience;
  num educationLength;
  num awareness;
  num bankInterest;
  num masterfulLooting;
  num stealth;
  num hospitalizing;
  num brawn;
  num protection;
  num sharpness;
  num evasion;
  num heavyArtilleryMastery;
  num machineGunMastery;
  num rifleMastery;
  num smgMastery;
  num shotgunMastery;
  num pistolMastery;
  num clubMastery;
  num piercingMastery;
  num slashingMastery;
  num mechanicalMastery;
  num temporaryMastery;

  factory Merits.fromJson(Map<String, dynamic> json) => Merits(
    nerveBar: json["Nerve Bar"] == null ? null : json["Nerve Bar"],
    criticalHitRate: json["Critical Hit Rate"] == null ? null : json["Critical Hit Rate"],
    lifePoints: json["Life Points"] == null ? null : json["Life Points"],
    crimeExperience: json["Crime Experience"] == null ? null : json["Crime Experience"],
    educationLength: json["Education Length"] == null ? null : json["Education Length"],
    awareness: json["Awareness"] == null ? null : json["Awareness"],
    bankInterest: json["Bank Interest"] == null ? null : json["Bank Interest"],
    masterfulLooting: json["Masterful Looting"] == null ? null : json["Masterful Looting"],
    stealth: json["Stealth"] == null ? null : json["Stealth"],
    hospitalizing: json["Hospitalizing"] == null ? null : json["Hospitalizing"],
    brawn: json["Brawn"] == null ? null : json["Brawn"],
    protection: json["Protection"] == null ? null : json["Protection"],
    sharpness: json["Sharpness"] == null ? null : json["Sharpness"],
    evasion: json["Evasion"] == null ? null : json["Evasion"],
    heavyArtilleryMastery: json["Heavy Artillery Mastery"] == null ? null : json["Heavy Artillery Mastery"],
    machineGunMastery: json["Machine Gun Mastery"] == null ? null : json["Machine Gun Mastery"],
    rifleMastery: json["Rifle Mastery"] == null ? null : json["Rifle Mastery"],
    smgMastery: json["SMG Mastery"] == null ? null : json["SMG Mastery"],
    shotgunMastery: json["Shotgun Mastery"] == null ? null : json["Shotgun Mastery"],
    pistolMastery: json["Pistol Mastery"] == null ? null : json["Pistol Mastery"],
    clubMastery: json["Club Mastery"] == null ? null : json["Club Mastery"],
    piercingMastery: json["Piercing Mastery"] == null ? null : json["Piercing Mastery"],
    slashingMastery: json["Slashing Mastery"] == null ? null : json["Slashing Mastery"],
    mechanicalMastery: json["Mechanical Mastery"] == null ? null : json["Mechanical Mastery"],
    temporaryMastery: json["Temporary Mastery"] == null ? null : json["Temporary Mastery"],
  );

  Map<String, dynamic> toJson() => {
    "Nerve Bar": nerveBar == null ? null : nerveBar,
    "Critical Hit Rate": criticalHitRate == null ? null : criticalHitRate,
    "Life Points": lifePoints == null ? null : lifePoints,
    "Crime Experience": crimeExperience == null ? null : crimeExperience,
    "Education Length": educationLength == null ? null : educationLength,
    "Awareness": awareness == null ? null : awareness,
    "Bank Interest": bankInterest == null ? null : bankInterest,
    "Masterful Looting": masterfulLooting == null ? null : masterfulLooting,
    "Stealth": stealth == null ? null : stealth,
    "Hospitalizing": hospitalizing == null ? null : hospitalizing,
    "Brawn": brawn == null ? null : brawn,
    "Protection": protection == null ? null : protection,
    "Sharpness": sharpness == null ? null : sharpness,
    "Evasion": evasion == null ? null : evasion,
    "Heavy Artillery Mastery": heavyArtilleryMastery == null ? null : heavyArtilleryMastery,
    "Machine Gun Mastery": machineGunMastery == null ? null : machineGunMastery,
    "Rifle Mastery": rifleMastery == null ? null : rifleMastery,
    "SMG Mastery": smgMastery == null ? null : smgMastery,
    "Shotgun Mastery": shotgunMastery == null ? null : shotgunMastery,
    "Pistol Mastery": pistolMastery == null ? null : pistolMastery,
    "Club Mastery": clubMastery == null ? null : clubMastery,
    "Piercing Mastery": piercingMastery == null ? null : piercingMastery,
    "Slashing Mastery": slashingMastery == null ? null : slashingMastery,
    "Mechanical Mastery": mechanicalMastery == null ? null : mechanicalMastery,
    "Temporary Mastery": temporaryMastery == null ? null : temporaryMastery,
  };
}

class NetworthClass {
  NetworthClass({
    this.pending,
    this.wallet,
    this.bank,
    this.points,
    this.cayman,
    this.vault,
    this.piggybank,
    this.items,
    this.displaycase,
    this.bazaar,
    this.properties,
    this.stockmarket,
    this.auctionhouse,
    this.company,
    this.bookie,
    this.loan,
    this.unpaidfees,
    this.total,
    this.parsetime,
  });

  num pending;
  num wallet;
  num bank;
  num points;
  num cayman;
  num vault;
  num piggybank;
  num items;
  num displaycase;
  num bazaar;
  num properties;
  num stockmarket;
  num auctionhouse;
  num company;
  num bookie;
  num loan;
  num unpaidfees;
  num total;
  num parsetime;

  factory NetworthClass.fromJson(Map<String, dynamic> json) => NetworthClass(
    pending: json["pending"] == null ? null : json["pending"],
    wallet: json["wallet"] == null ? null : json["wallet"],
    bank: json["bank"] == null ? null : json["bank"],
    points: json["points"] == null ? null : json["points"],
    cayman: json["cayman"] == null ? null : json["cayman"],
    vault: json["vault"] == null ? null : json["vault"],
    piggybank: json["piggybank"] == null ? null : json["piggybank"],
    items: json["items"] == null ? null : json["items"],
    displaycase: json["displaycase"] == null ? null : json["displaycase"],
    bazaar: json["bazaar"] == null ? null : json["bazaar"],
    properties: json["properties"] == null ? null : json["properties"],
    stockmarket: json["stockmarket"] == null ? null : json["stockmarket"],
    auctionhouse: json["auctionhouse"] == null ? null : json["auctionhouse"],
    company: json["company"] == null ? null : json["company"],
    bookie: json["bookie"] == null ? null : json["bookie"],
    loan: json["loan"] == null ? null : json["loan"],
    unpaidfees: json["unpaidfees"] == null ? null : json["unpaidfees"],
    total: json["total"] == null ? null : json["total"],
    parsetime: json["parsetime"] == null ? null : json["parsetime"],
  );

  Map<String, dynamic> toJson() => {
    "pending": pending == null ? null : pending,
    "wallet": wallet == null ? null : wallet,
    "bank": bank == null ? null : bank,
    "points": points == null ? null : points,
    "cayman": cayman == null ? null : cayman,
    "vault": vault == null ? null : vault,
    "piggybank": piggybank == null ? null : piggybank,
    "items": items == null ? null : items,
    "displaycase": displaycase == null ? null : displaycase,
    "bazaar": bazaar == null ? null : bazaar,
    "properties": properties == null ? null : properties,
    "stockmarket": stockmarket == null ? null : stockmarket,
    "auctionhouse": auctionhouse == null ? null : auctionhouse,
    "company": company == null ? null : company,
    "bookie": bookie == null ? null : bookie,
    "loan": loan == null ? null : loan,
    "unpaidfees": unpaidfees == null ? null : unpaidfees,
    "total": total == null ? null : total,
    "parsetime": parsetime == null ? null : parsetime,
  };
}

class Personalstats {
  Personalstats({
    this.bazaarcustomers,
    this.bazaarsales,
    this.bazaarprofit,
    this.useractivity,
    this.itemsbought,
    this.pointsbought,
    this.itemsboughtabroad,
    this.moneyinvested,
    this.investedprofit,
    this.weaponsbought,
    this.trades,
    this.itemssent,
    this.auctionswon,
    this.auctionsells,
    this.pointssold,
    this.attackswon,
    this.attackslost,
    this.attacksdraw,
    this.bestkillstreak,
    this.killstreak,
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
    this.logins,
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
    this.stockpayouts,
    this.arrestsmade,
    this.tokenrefills,
    this.booksread,
    this.traveltime,
    this.boostersused,
    this.rehabs,
    this.rehabcost,
    this.awards,
    this.receivedbountyvalue,
    this.networthpending,
    this.networthwallet,
    this.networthbank,
    this.networthpoints,
    this.networthcayman,
    this.networthvault,
    this.networthpiggybank,
    this.networthitems,
    this.networthdisplaycase,
    this.networthbazaar,
    this.networthproperties,
    this.networthstockmarket,
    this.networthauctionhouse,
    this.networthcompany,
    this.networthbookie,
    this.networthloan,
    this.networthunpaidfees,
    this.racingskill,
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
    this.activestreak,
    this.bestactivestreak,
    this.jobpointsused,
  });

  num bazaarcustomers;
  num bazaarsales;
  num bazaarprofit;
  num useractivity;
  num itemsbought;
  num pointsbought;
  num itemsboughtabroad;
  num moneyinvested;
  num investedprofit;
  num weaponsbought;
  num trades;
  num itemssent;
  num auctionswon;
  num auctionsells;
  num pointssold;
  num attackswon;
  num attackslost;
  num attacksdraw;
  num bestkillstreak;
  num killstreak;
  num moneymugged;
  num attacksstealthed;
  num attackhits;
  num attackmisses;
  num attackdamage;
  num attackcriticalhits;
  num respectforfaction;
  num onehitkills;
  num defendswon;
  num defendslost;
  num defendsstalemated;
  num bestdamage;
  num roundsfired;
  num yourunaway;
  num theyrunaway;
  num highestbeaten;
  num peoplebusted;
  num failedbusts;
  num peoplebought;
  num peopleboughtspent;
  num virusescoded;
  num cityfinds;
  num traveltimes;
  num bountiesplaced;
  num bountiesreceived;
  num bountiescollected;
  num totalbountyreward;
  num revives;
  num revivesreceived;
  num medicalitemsused;
  num statenhancersused;
  num refills;
  num trainsreceived;
  num totalbountyspent;
  num drugsused;
  num overdosed;
  num meritsbought;
  num logins;
  num timesloggedin;
  num personalsplaced;
  num classifiedadsplaced;
  num mailssent;
  num friendmailssent;
  num factionmailssent;
  num companymailssent;
  num spousemailssent;
  num largestmug;
  num cantaken;
  num exttaken;
  num kettaken;
  num lsdtaken;
  num opitaken;
  num shrtaken;
  num spetaken;
  num pcptaken;
  num xantaken;
  num victaken;
  num chahits;
  num heahits;
  num axehits;
  num grehits;
  num machits;
  num pishits;
  num rifhits;
  num shohits;
  num smghits;
  num piehits;
  num slahits;
  num argtravel;
  num mextravel;
  num dubtravel;
  num hawtravel;
  num japtravel;
  num lontravel;
  num soutravel;
  num switravel;
  num chitravel;
  num cantravel;
  num dumpfinds;
  num dumpsearches;
  num itemsdumped;
  num daysbeendonator;
  num caytravel;
  num jailed;
  num hospital;
  num attacksassisted;
  num bloodwithdrawn;
  num networth;
  num missionscompleted;
  num contractscompleted;
  num dukecontractscompleted;
  num missioncreditsearned;
  num consumablesused;
  num candyused;
  num alcoholused;
  num energydrinkused;
  num nerverefills;
  num unarmoredwon;
  num h2Hhits;
  num organisedcrimes;
  num territorytime;
  num stockpayouts;
  num arrestsmade;
  num tokenrefills;
  num booksread;
  num traveltime;
  num boostersused;
  num rehabs;
  num rehabcost;
  num awards;
  num receivedbountyvalue;
  num networthpending;
  num networthwallet;
  num networthbank;
  num networthpoints;
  num networthcayman;
  num networthvault;
  num networthpiggybank;
  num networthitems;
  num networthdisplaycase;
  num networthbazaar;
  num networthproperties;
  num networthstockmarket;
  num networthauctionhouse;
  num networthcompany;
  num networthbookie;
  num networthloan;
  num networthunpaidfees;
  num racingskill;
  num raceswon;
  num racesentered;
  num racingpointsearned;
  num specialammoused;
  num cityitemsbought;
  num hollowammoused;
  num tracerammoused;
  num piercingammoused;
  num incendiaryammoused;
  num attackswonabroad;
  num defendslostabroad;
  num activestreak;
  num bestactivestreak;
  num jobpointsused;

  factory Personalstats.fromJson(Map<String, dynamic> json) => Personalstats(
    bazaarcustomers: json["bazaarcustomers"] == null ? null : json["bazaarcustomers"],
    bazaarsales: json["bazaarsales"] == null ? null : json["bazaarsales"],
    bazaarprofit: json["bazaarprofit"] == null ? null : json["bazaarprofit"],
    useractivity: json["useractivity"] == null ? null : json["useractivity"],
    itemsbought: json["itemsbought"] == null ? null : json["itemsbought"],
    pointsbought: json["pointsbought"] == null ? null : json["pointsbought"],
    itemsboughtabroad: json["itemsboughtabroad"] == null ? null : json["itemsboughtabroad"],
    moneyinvested: json["moneyinvested"] == null ? null : json["moneyinvested"],
    investedprofit: json["investedprofit"] == null ? null : json["investedprofit"],
    weaponsbought: json["weaponsbought"] == null ? null : json["weaponsbought"],
    trades: json["trades"] == null ? null : json["trades"],
    itemssent: json["itemssent"] == null ? null : json["itemssent"],
    auctionswon: json["auctionswon"] == null ? null : json["auctionswon"],
    auctionsells: json["auctionsells"] == null ? null : json["auctionsells"],
    pointssold: json["pointssold"] == null ? null : json["pointssold"],
    attackswon: json["attackswon"] == null ? null : json["attackswon"],
    attackslost: json["attackslost"] == null ? null : json["attackslost"],
    attacksdraw: json["attacksdraw"] == null ? null : json["attacksdraw"],
    bestkillstreak: json["bestkillstreak"] == null ? null : json["bestkillstreak"],
    killstreak: json["killstreak"] == null ? null : json["killstreak"],
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
    logins: json["logins"] == null ? null : json["logins"],
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
    stockpayouts: json["stockpayouts"] == null ? null : json["stockpayouts"],
    arrestsmade: json["arrestsmade"] == null ? null : json["arrestsmade"],
    tokenrefills: json["tokenrefills"] == null ? null : json["tokenrefills"],
    booksread: json["booksread"] == null ? null : json["booksread"],
    traveltime: json["traveltime"] == null ? null : json["traveltime"],
    boostersused: json["boostersused"] == null ? null : json["boostersused"],
    rehabs: json["rehabs"] == null ? null : json["rehabs"],
    rehabcost: json["rehabcost"] == null ? null : json["rehabcost"],
    awards: json["awards"] == null ? null : json["awards"],
    receivedbountyvalue: json["receivedbountyvalue"] == null ? null : json["receivedbountyvalue"],
    networthpending: json["networthpending"] == null ? null : json["networthpending"],
    networthwallet: json["networthwallet"] == null ? null : json["networthwallet"],
    networthbank: json["networthbank"] == null ? null : json["networthbank"],
    networthpoints: json["networthpoints"] == null ? null : json["networthpoints"],
    networthcayman: json["networthcayman"] == null ? null : json["networthcayman"],
    networthvault: json["networthvault"] == null ? null : json["networthvault"],
    networthpiggybank: json["networthpiggybank"] == null ? null : json["networthpiggybank"],
    networthitems: json["networthitems"] == null ? null : json["networthitems"],
    networthdisplaycase: json["networthdisplaycase"] == null ? null : json["networthdisplaycase"],
    networthbazaar: json["networthbazaar"] == null ? null : json["networthbazaar"],
    networthproperties: json["networthproperties"] == null ? null : json["networthproperties"],
    networthstockmarket: json["networthstockmarket"] == null ? null : json["networthstockmarket"],
    networthauctionhouse: json["networthauctionhouse"] == null ? null : json["networthauctionhouse"],
    networthcompany: json["networthcompany"] == null ? null : json["networthcompany"],
    networthbookie: json["networthbookie"] == null ? null : json["networthbookie"],
    networthloan: json["networthloan"] == null ? null : json["networthloan"],
    networthunpaidfees: json["networthunpaidfees"] == null ? null : json["networthunpaidfees"],
    racingskill: json["racingskill"] == null ? null : json["racingskill"],
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
    activestreak: json["activestreak"] == null ? null : json["activestreak"],
    bestactivestreak: json["bestactivestreak"] == null ? null : json["bestactivestreak"],
    jobpointsused: json["jobpointsused"] == null ? null : json["jobpointsused"],
  );

  Map<String, dynamic> toJson() => {
    "bazaarcustomers": bazaarcustomers == null ? null : bazaarcustomers,
    "bazaarsales": bazaarsales == null ? null : bazaarsales,
    "bazaarprofit": bazaarprofit == null ? null : bazaarprofit,
    "useractivity": useractivity == null ? null : useractivity,
    "itemsbought": itemsbought == null ? null : itemsbought,
    "pointsbought": pointsbought == null ? null : pointsbought,
    "itemsboughtabroad": itemsboughtabroad == null ? null : itemsboughtabroad,
    "moneyinvested": moneyinvested == null ? null : moneyinvested,
    "investedprofit": investedprofit == null ? null : investedprofit,
    "weaponsbought": weaponsbought == null ? null : weaponsbought,
    "trades": trades == null ? null : trades,
    "itemssent": itemssent == null ? null : itemssent,
    "auctionswon": auctionswon == null ? null : auctionswon,
    "auctionsells": auctionsells == null ? null : auctionsells,
    "pointssold": pointssold == null ? null : pointssold,
    "attackswon": attackswon == null ? null : attackswon,
    "attackslost": attackslost == null ? null : attackslost,
    "attacksdraw": attacksdraw == null ? null : attacksdraw,
    "bestkillstreak": bestkillstreak == null ? null : bestkillstreak,
    "killstreak": killstreak == null ? null : killstreak,
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
    "logins": logins == null ? null : logins,
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
    "stockpayouts": stockpayouts == null ? null : stockpayouts,
    "arrestsmade": arrestsmade == null ? null : arrestsmade,
    "tokenrefills": tokenrefills == null ? null : tokenrefills,
    "booksread": booksread == null ? null : booksread,
    "traveltime": traveltime == null ? null : traveltime,
    "boostersused": boostersused == null ? null : boostersused,
    "rehabs": rehabs == null ? null : rehabs,
    "rehabcost": rehabcost == null ? null : rehabcost,
    "awards": awards == null ? null : awards,
    "receivedbountyvalue": receivedbountyvalue == null ? null : receivedbountyvalue,
    "networthpending": networthpending == null ? null : networthpending,
    "networthwallet": networthwallet == null ? null : networthwallet,
    "networthbank": networthbank == null ? null : networthbank,
    "networthpoints": networthpoints == null ? null : networthpoints,
    "networthcayman": networthcayman == null ? null : networthcayman,
    "networthvault": networthvault == null ? null : networthvault,
    "networthpiggybank": networthpiggybank == null ? null : networthpiggybank,
    "networthitems": networthitems == null ? null : networthitems,
    "networthdisplaycase": networthdisplaycase == null ? null : networthdisplaycase,
    "networthbazaar": networthbazaar == null ? null : networthbazaar,
    "networthproperties": networthproperties == null ? null : networthproperties,
    "networthstockmarket": networthstockmarket == null ? null : networthstockmarket,
    "networthauctionhouse": networthauctionhouse == null ? null : networthauctionhouse,
    "networthcompany": networthcompany == null ? null : networthcompany,
    "networthbookie": networthbookie == null ? null : networthbookie,
    "networthloan": networthloan == null ? null : networthloan,
    "networthunpaidfees": networthunpaidfees == null ? null : networthunpaidfees,
    "racingskill": racingskill == null ? null : racingskill,
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

  num hospitalTimestamp;
  num jailTimestamp;

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
  num until;

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

class Weaponexp {
  Weaponexp({
    this.itemId,
    this.name,
    this.exp,
    this.hits,
    this.weaponexpClass,
  });

  num itemId;
  String name;
  num exp;
  num hits;
  String weaponexpClass;

  factory Weaponexp.fromJson(Map<String, dynamic> json) => Weaponexp(
    itemId: json["itemID"] == null ? null : json["itemID"],
    name: json["name"] == null ? null : json["name"],
    exp: json["exp"] == null ? null : json["exp"],
    hits: json["hits"] == null ? null : json["hits"],
    weaponexpClass: json["class"] == null ? null : json["class"],
  );

  Map<String, dynamic> toJson() => {
    "itemID": itemId == null ? null : itemId,
    "name": name == null ? null : name,
    "exp": exp == null ? null : exp,
    "hits": hits == null ? null : hits,
    "class": weaponexpClass == null ? null : weaponexpClass,
  };
}

class View {
  View({
    this.awards,
  });

  bool awards;

  factory View.fromJson(Map<String, dynamic> json) => View(
    awards: json["awards"] == null ? null : json["awards"],
  );

  Map<String, dynamic> toJson() => {
    "awards": awards == null ? null : awards,
  };
}
