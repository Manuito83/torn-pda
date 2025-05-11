// To parse this JSON data, do
//
//     final ownProfileMisc = ownProfileMiscFromJson(jsonString);

import 'dart:convert';

OwnProfileMisc ownProfileMiscFromJsonV2(String rawJson) => OwnProfileMisc.fromJson(
      json.decode(rawJson) as Map<String, dynamic>,
    );

String ownProfileMiscToJson(OwnProfileMisc data) => json.encode(data.toJson());

class OwnProfileMisc {
  // ── v2 new fields -------──────────────
  final List<int> educationCompleted;
  final int? educationCurrent;
  final int? educationTimeleft;

  // ── common fields ─────────────────────
  int? points;
  int? caymanBank;
  int? vaultAmount;
  int? companyFunds;
  int? dailyNetworth;
  int? moneyOnhand;
  int? manualLabor;
  int? intelligence;
  int? endurance;
  int? strength;
  int? speed;
  int? dexterity;
  int? defense;
  int? total;
  int? strengthModifier;
  int? defenseModifier;
  int? speedModifier;
  int? dexterityModifier;
  String? searchForCash;
  String? forgery;
  String? bootlegging;
  String? reviving;
  String? graffiti;
  String? hunting;
  String? burglary;
  String? shoplifting;
  String? cracking;
  String? pickpocketing;
  String? racing;
  String? scamming;
  String? disposal;
  String? hustling;
  String? cardSkimming;
  int? playerId;
  CityBank? cityBank;
  List<String>? strengthInfo;
  List<String>? defenseInfo;
  List<String>? speedInfo;
  List<String>? dexterityInfo;
  Jobpoints? jobpoints;
  Map<String, Property>? properties;
  List<Bazaar>? bazaar;
  List<Itemmarket>? itemmarket;
  Metadata? metadata;

  OwnProfileMisc({
    this.points,
    this.caymanBank,
    this.vaultAmount,
    this.companyFunds,
    this.dailyNetworth,
    this.moneyOnhand,
    this.educationCurrent,
    this.educationTimeleft,
    required this.educationCompleted,
    this.manualLabor,
    this.intelligence,
    this.endurance,
    this.strength,
    this.speed,
    this.dexterity,
    this.defense,
    this.total,
    this.strengthModifier,
    this.defenseModifier,
    this.speedModifier,
    this.dexterityModifier,
    this.searchForCash,
    this.forgery,
    this.bootlegging,
    this.reviving,
    this.graffiti,
    this.hunting,
    this.burglary,
    this.shoplifting,
    this.cracking,
    this.pickpocketing,
    this.racing,
    this.scamming,
    this.disposal,
    this.hustling,
    this.cardSkimming,
    this.playerId,
    this.cityBank,
    this.strengthInfo,
    this.defenseInfo,
    this.speedInfo,
    this.dexterityInfo,
    this.jobpoints,
    this.properties,
    this.bazaar,
    this.itemmarket,
    this.metadata,
  });

  factory OwnProfileMisc.fromJson(Map<String, dynamic> json) {
    // ─────────────────────────────────────────────────────────────────────────
    // 1. V2 similar to V1
    // ─────────────────────────────────────────────────────────────────────────
    final points = json["points"];
    final caymanBank = json["cayman_bank"];
    final vaultAmount = json["vault_amount"];
    final companyFunds = json["company_funds"];
    final dailyNetworth = json["daily_networth"];
    final moneyOnhand = json["money_onhand"];

    final manualLabor = json["manual_labor"];
    final intelligence = json["intelligence"];
    final endurance = json["endurance"];
    final strength = json["strength"];
    final speed = json["speed"];
    final dexterity = json["dexterity"];
    final defense = json["defense"];
    final total = json["total"];
    final strengthModifier = json["strength_modifier"];
    final defenseModifier = json["defense_modifier"];
    final speedModifier = json["speed_modifier"];
    final dexterityModifier = json["dexterity_modifier"];

    final searchForCash = json["search_for_cash"];
    final forgery = json["forgery"];
    final bootlegging = json["bootlegging"];
    final reviving = json["reviving"];
    final graffiti = json["graffiti"];
    final hunting = json["hunting"];
    final burglary = json["burglary"];
    final shoplifting = json["shoplifting"];
    final cracking = json["cracking"];
    final pickpocketing = json["pickpocketing"];
    final racing = json["racing"];
    final scamming = json["scamming"];
    final disposal = json["disposal"];
    final hustling = json["hustling"];
    final cardSkimming = json["card_skimming"];

    final playerId = json["player_id"];
    final cityBank = json["city_bank"] == null ? null : CityBank.fromJson(json["city_bank"]);
    final strengthInfo = json["strength_info"] == null ? <String>[] : List<String>.from(json["strength_info"]);
    final defenseInfo = json["defense_info"] == null ? <String>[] : List<String>.from(json["defense_info"]);
    final speedInfo = json["speed_info"] == null ? <String>[] : List<String>.from(json["speed_info"]);
    final dexterityInfo = json["dexterity_info"] == null ? <String>[] : List<String>.from(json["dexterity_info"]);
    final jobpoints = json["jobpoints"] == null ? null : Jobpoints.fromJson(json["jobpoints"]);
    final properties = json["properties"] == null
        ? <String, Property>{}
        : Map.from(json["properties"]).map((k, v) => MapEntry<String, Property>(k, Property.fromJson(v)));
    final bazaar =
        json["bazaar"] == null ? <Bazaar>[] : List<Bazaar>.from(json["bazaar"].map((x) => Bazaar.fromJson(x)));
    final itemmarket = json["itemmarket"] == null
        ? <Itemmarket>[]
        : List<Itemmarket>.from(json["itemmarket"].map((x) => Itemmarket.fromJson(x)));
    final metadata = json["_metadata"] == null ? null : Metadata.fromJson(json["_metadata"]);

    // ─────────────────────────────────────────────────────────────────────────
    // 2. V2 adapted: education
    // ─────────────────────────────────────────────────────────────────────────
    late final List<int> educationCompleted;
    late final int? educationCurrent;
    late final int? educationTimeleft;

    final edu = json["education"] as Map<String, dynamic>;
    educationCompleted = List<int>.from((edu['complete'] ?? []) as List);

    if (edu["current"] != null) {
      final current = edu["current"] as Map<String, dynamic>;
      educationCurrent = current["id"] as int?;
      final untilEpoch = current["until"] as int?;
      educationTimeleft = untilEpoch == null
          ? null
          : (DateTime.fromMillisecondsSinceEpoch(untilEpoch * 1000).difference(DateTime.now()).inSeconds)
              .clamp(0, double.infinity)
              .toInt();
    } else {
      educationCurrent = null;
      educationTimeleft = null;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 3. Return fully-populated domain object
    // ─────────────────────────────────────────────────────────────────────────
    return OwnProfileMisc(
      points: points,
      caymanBank: caymanBank,
      vaultAmount: vaultAmount,
      companyFunds: companyFunds,
      dailyNetworth: dailyNetworth,
      moneyOnhand: moneyOnhand,
      educationCurrent: educationCurrent,
      educationTimeleft: educationTimeleft,
      manualLabor: manualLabor,
      intelligence: intelligence,
      endurance: endurance,
      strength: strength,
      speed: speed,
      dexterity: dexterity,
      defense: defense,
      total: total,
      strengthModifier: strengthModifier,
      defenseModifier: defenseModifier,
      speedModifier: speedModifier,
      dexterityModifier: dexterityModifier,
      searchForCash: searchForCash,
      forgery: forgery,
      bootlegging: bootlegging,
      reviving: reviving,
      graffiti: graffiti,
      hunting: hunting,
      burglary: burglary,
      shoplifting: shoplifting,
      cracking: cracking,
      pickpocketing: pickpocketing,
      racing: racing,
      scamming: scamming,
      disposal: disposal,
      hustling: hustling,
      cardSkimming: cardSkimming,
      playerId: playerId,
      cityBank: cityBank,
      educationCompleted: educationCompleted,
      strengthInfo: strengthInfo,
      defenseInfo: defenseInfo,
      speedInfo: speedInfo,
      dexterityInfo: dexterityInfo,
      jobpoints: jobpoints,
      properties: properties,
      bazaar: bazaar,
      itemmarket: itemmarket,
      metadata: metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        "points": points,
        "cayman_bank": caymanBank,
        "vault_amount": vaultAmount,
        "company_funds": companyFunds,
        "daily_networth": dailyNetworth,
        "money_onhand": moneyOnhand,
        "education_current": educationCurrent,
        "education_timeleft": educationTimeleft,
        "manual_labor": manualLabor,
        "intelligence": intelligence,
        "endurance": endurance,
        "strength": strength,
        "speed": speed,
        "dexterity": dexterity,
        "defense": defense,
        "total": total,
        "strength_modifier": strengthModifier,
        "defense_modifier": defenseModifier,
        "speed_modifier": speedModifier,
        "dexterity_modifier": dexterityModifier,
        "search_for_cash": searchForCash,
        "forgery": forgery,
        "bootlegging": bootlegging,
        "reviving": reviving,
        "graffiti": graffiti,
        "hunting": hunting,
        "burglary": burglary,
        "shoplifting": shoplifting,
        "cracking": cracking,
        "pickpocketing": pickpocketing,
        "racing": racing,
        "scamming": scamming,
        "disposal": disposal,
        "hustling": hustling,
        "card_skimming": cardSkimming,
        "player_id": playerId,
        "city_bank": cityBank?.toJson(),
        "education_completed": List<dynamic>.from(educationCompleted.map((x) => x)),
        "strength_info": strengthInfo == null ? [] : List<dynamic>.from(strengthInfo!.map((x) => x)),
        "defense_info": defenseInfo == null ? [] : List<dynamic>.from(defenseInfo!.map((x) => x)),
        "speed_info": speedInfo == null ? [] : List<dynamic>.from(speedInfo!.map((x) => x)),
        "dexterity_info": dexterityInfo == null ? [] : List<dynamic>.from(dexterityInfo!.map((x) => x)),
        "jobpoints": jobpoints?.toJson(),
        "properties": Map.from(properties!).map((k, v) => MapEntry<String, dynamic>(k, v.toJson())),
        "bazaar": bazaar == null ? [] : List<dynamic>.from(bazaar!.map((x) => x.toJson())),
        "itemmarket": itemmarket == null ? [] : List<dynamic>.from(itemmarket!.map((x) => x.toJson())),
        "_metadata": metadata?.toJson(),
      };
}

class Bazaar {
  int? id;
  String? name;
  String? type;
  int? quantity;
  int? price;
  int? marketPrice;
  int? uid;

  Bazaar({
    this.id,
    this.name,
    this.type,
    this.quantity,
    this.price,
    this.marketPrice,
    this.uid,
  });

  factory Bazaar.fromJson(Map<String, dynamic> json) => Bazaar(
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

class CityBank {
  int? amount;
  int? timeLeft;

  CityBank({
    this.amount,
    this.timeLeft,
  });

  factory CityBank.fromJson(Map<String, dynamic> json) => CityBank(
        amount: json["amount"],
        timeLeft: json["time_left"],
      );

  Map<String, dynamic> toJson() => {
        "amount": amount,
        "time_left": timeLeft,
      };
}

class Itemmarket {
  int? id;
  int? price;
  int? averagePrice;
  int? amount;
  bool? isAnonymous;
  int? available;
  Item? item;

  Itemmarket({
    this.id,
    this.price,
    this.averagePrice,
    this.amount,
    this.isAnonymous,
    this.available,
    this.item,
  });

  factory Itemmarket.fromJson(Map<String, dynamic> json) => Itemmarket(
        id: json["id"],
        price: json["price"],
        averagePrice: json["average_price"],
        amount: json["amount"],
        isAnonymous: json["is_anonymous"],
        available: json["available"],
        item: json["item"] == null ? null : Item.fromJson(json["item"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "price": price,
        "average_price": averagePrice,
        "amount": amount,
        "is_anonymous": isAnonymous,
        "available": available,
        "item": item?.toJson(),
      };
}

class Item {
  int? id;
  String? name;
  String? type;
  dynamic uid;
  dynamic stats;
  dynamic rarity;
  List<dynamic>? bonuses;

  Item({
    this.id,
    this.name,
    this.type,
    this.uid,
    this.stats,
    this.rarity,
    this.bonuses,
  });

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        id: json["id"],
        name: json["name"],
        type: json["type"],
        uid: json["uid"],
        stats: json["stats"],
        rarity: json["rarity"],
        bonuses: json["bonuses"] == null ? [] : List<dynamic>.from(json["bonuses"]!.map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "type": type,
        "uid": uid,
        "stats": stats,
        "rarity": rarity,
        "bonuses": bonuses == null ? [] : List<dynamic>.from(bonuses!.map((x) => x)),
      };
}

class Jobpoints {
  Jobs? jobs;
  Map<String, Company>? companies;

  Jobpoints({
    this.jobs,
    this.companies,
  });

  factory Jobpoints.fromJson(Map<String, dynamic> json) => Jobpoints(
        jobs: json["jobs"] == null ? null : Jobs.fromJson(json["jobs"]),
        companies: json["companies"] == null
            ? null
            : Map.from(json["companies"]!).map((k, v) => MapEntry<String, Company>(k, Company.fromJson(v))),
      );

  Map<String, dynamic> toJson() => {
        "jobs": jobs?.toJson(),
        "companies": Map.from(companies!).map((k, v) => MapEntry<String, dynamic>(k, v.toJson())),
      };
}

class Company {
  String? name;
  int? jobpoints;

  Company({
    this.name,
    this.jobpoints,
  });

  factory Company.fromJson(Map<String, dynamic> json) => Company(
        name: json["name"],
        jobpoints: json["jobpoints"],
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "jobpoints": jobpoints,
      };
}

class Jobs {
  int? army;
  int? medical;
  int? casino;
  int? education;
  int? law;
  int? grocer;

  Jobs({
    this.army,
    this.medical,
    this.casino,
    this.education,
    this.law,
    this.grocer,
  });

  factory Jobs.fromJson(Map<String, dynamic> json) => Jobs(
        army: json["army"],
        medical: json["medical"],
        casino: json["casino"],
        education: json["education"],
        law: json["law"],
        grocer: json["grocer"],
      );

  Map<String, dynamic> toJson() => {
        "army": army,
        "medical": medical,
        "casino": casino,
        "education": education,
        "law": law,
        "grocer": grocer,
      };
}

class Metadata {
  dynamic prev;
  dynamic next;

  Metadata({
    this.prev,
    this.next,
  });

  factory Metadata.fromJson(Map<String, dynamic> json) => Metadata(
        prev: json["prev"],
        next: json["next"],
      );

  Map<String, dynamic> toJson() => {
        "prev": prev,
        "next": next,
      };
}

class Property {
  int? ownerId;
  int? propertyType;
  String? property;
  String? status;
  int? happy;
  int? upkeep;
  int? staffCost;
  int? cost;
  int? marketprice;
  Modifications? modifications;
  Staff? staff;
  dynamic rented;

  Property({
    this.ownerId,
    this.propertyType,
    this.property,
    this.status,
    this.happy,
    this.upkeep,
    this.staffCost,
    this.cost,
    this.marketprice,
    this.modifications,
    this.staff,
    this.rented,
  });

  factory Property.fromJson(Map<String, dynamic> json) => Property(
        ownerId: json["owner_id"],
        propertyType: json["property_type"],
        property: json["property"],
        status: json["status"],
        happy: json["happy"],
        upkeep: json["upkeep"],
        staffCost: json["staff_cost"],
        cost: json["cost"],
        marketprice: json["marketprice"],
        modifications: json["modifications"] == null ? null : Modifications.fromJson(json["modifications"]),
        staff: json["staff"] == null ? null : Staff.fromJson(json["staff"]),
        rented: json["rented"],
      );

  Map<String, dynamic> toJson() => {
        "owner_id": ownerId,
        "property_type": propertyType,
        "property": property,
        "status": status,
        "happy": happy,
        "upkeep": upkeep,
        "staff_cost": staffCost,
        "cost": cost,
        "marketprice": marketprice,
        "modifications": modifications?.toJson(),
        "staff": staff?.toJson(),
        "rented": rented,
      };
}

class Modifications {
  int? interior;
  int? hotTub;
  int? sauna;
  int? pool;
  int? openBar;
  int? shootingRange;
  int? vault;
  int? medicalFacility;
  int? airstrip;
  int? yacht;

  Modifications({
    this.interior,
    this.hotTub,
    this.sauna,
    this.pool,
    this.openBar,
    this.shootingRange,
    this.vault,
    this.medicalFacility,
    this.airstrip,
    this.yacht,
  });

  factory Modifications.fromJson(Map<String, dynamic> json) => Modifications(
        interior: json["interior"],
        hotTub: json["hot_tub"],
        sauna: json["sauna"],
        pool: json["pool"],
        openBar: json["open_bar"],
        shootingRange: json["shooting_range"],
        vault: json["vault"],
        medicalFacility: json["medical_facility"],
        airstrip: json["airstrip"],
        yacht: json["yacht"],
      );

  Map<String, dynamic> toJson() => {
        "interior": interior,
        "hot_tub": hotTub,
        "sauna": sauna,
        "pool": pool,
        "open_bar": openBar,
        "shooting_range": shootingRange,
        "vault": vault,
        "medical_facility": medicalFacility,
        "airstrip": airstrip,
        "yacht": yacht,
      };
}

class Staff {
  int? maid;
  int? guard;
  int? pilot;
  int? butler;
  int? doctor;

  Staff({
    this.maid,
    this.guard,
    this.pilot,
    this.butler,
    this.doctor,
  });

  factory Staff.fromJson(Map<String, dynamic> json) => Staff(
        maid: json["maid"],
        guard: json["guard"],
        pilot: json["pilot"],
        butler: json["butler"],
        doctor: json["doctor"],
      );

  Map<String, dynamic> toJson() => {
        "maid": maid,
        "guard": guard,
        "pilot": pilot,
        "butler": butler,
        "doctor": doctor,
      };
}
