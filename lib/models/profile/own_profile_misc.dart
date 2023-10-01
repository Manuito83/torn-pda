// To parse this JSON data, do
//
//     final ownProfileMisc = ownProfileMiscFromJson(jsonString);

// Dart imports:
import 'dart:convert';

/// This exists because if we mix some requests in Torn (e.g.: money and networth), there is
/// some data that does not show up. So this complements.
OwnProfileMisc ownProfileMiscFromJson(String str) => OwnProfileMisc.fromJson(json.decode(str));

String ownProfileMiscToJson(OwnProfileMisc data) => json.encode(data.toJson());

class OwnProfileMisc {
  OwnProfileMisc({
    this.points,
    this.caymanBank,
    this.vaultAmount,
    this.dailyNetworth,
    this.moneyOnhand,
    this.educationCurrent,
    this.educationTimeleft,
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
    // Crimes
    this.hunting,
    this.racing,
    this.reviving,
    this.searchForCash,
    this.bootlegging,
    this.graffiti,
    this.burglary,
    this.shoplifting,
    this.cardSkimming,
    //
    this.cityBank,
    this.educationCompleted,
    this.strengthInfo,
    this.defenseInfo,
    this.speedInfo,
    this.dexterityInfo,
    this.jobpoints,
    this.properties,
    this.bazaar,
  });

  int? points;
  int? caymanBank;
  int? vaultAmount;
  int? dailyNetworth;
  int? moneyOnhand;
  int? educationCurrent;
  int? educationTimeleft;
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
  // Skills
  String? hunting;
  String? racing;
  String? reviving;
  String? searchForCash;
  String? bootlegging;
  String? graffiti;
  String? burglary;
  String? shoplifting;
  String? cardSkimming;
  //
  CityBank? cityBank;
  List<int>? educationCompleted;
  List<String>? strengthInfo;
  List<String>? defenseInfo;
  List<String>? speedInfo;
  List<String>? dexterityInfo;
  Jobpoints? jobpoints;
  Map<String, Property>? properties;
  List<Bazaar>? bazaar;

  factory OwnProfileMisc.fromJson(Map<String, dynamic> json) => OwnProfileMisc(
        points: json["points"],
        caymanBank: json["cayman_bank"],
        vaultAmount: json["vault_amount"],
        dailyNetworth: json["daily_networth"],
        moneyOnhand: json["money_onhand"],
        educationCurrent: json["education_current"],
        educationTimeleft: json["education_timeleft"],
        manualLabor: json["manual_labor"],
        intelligence: json["intelligence"],
        endurance: json["endurance"],
        strength: json["strength"],
        speed: json["speed"],
        dexterity: json["dexterity"],
        defense: json["defense"],
        total: json["total"],
        strengthModifier: json["strength_modifier"],
        defenseModifier: json["defense_modifier"],
        speedModifier: json["speed_modifier"],
        dexterityModifier: json["dexterity_modifier"],
        hunting: json["hunting"],
        racing: json["racing"],
        reviving: json["reviving"],
        searchForCash: json["search_for_cash"],
        bootlegging: json["bootlegging"],
        graffiti: json["graffiti"],
        burglary: json["burglary"],
        shoplifting: json["shoplifting"],
        cardSkimming: json["card_skimming"],
        cityBank: json["city_bank"] == null ? null : CityBank.fromJson(json["city_bank"]),
        educationCompleted:
            json["education_completed"] == null ? null : List<int>.from(json["education_completed"].map((x) => x)),
        strengthInfo: json["strength_info"] == null ? null : List<String>.from(json["strength_info"].map((x) => x)),
        defenseInfo: json["defense_info"] == null ? null : List<String>.from(json["defense_info"].map((x) => x)),
        speedInfo: json["speed_info"] == null ? null : List<String>.from(json["speed_info"].map((x) => x)),
        dexterityInfo: json["dexterity_info"] == null ? null : List<String>.from(json["dexterity_info"].map((x) => x)),
        jobpoints: json["jobpoints"] == null ? null : Jobpoints.fromJson(json["jobpoints"]),
        properties: json["properties"] == null
            ? null
            : Map.from(json["properties"]).map((k, v) => MapEntry<String, Property>(k, Property.fromJson(v))),
        bazaar: json["bazaar"] == null ? null : List<Bazaar>.from(json["bazaar"].map((x) => Bazaar.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "points": points,
        "cayman_bank": caymanBank,
        "vault_amount": vaultAmount,
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
        "hunting": hunting,
        "racing": racing,
        "reviving": reviving,
        "search_for_cash": searchForCash,
        "bootlegging": bootlegging,
        "graffiti": graffiti,
        "burglary": burglary,
        "shoplifting": shoplifting,
        "card_skimming": cardSkimming,
        "city_bank": cityBank == null ? null : cityBank!.toJson(),
        "education_completed":
            educationCompleted == null ? null : List<dynamic>.from(educationCompleted!.map((x) => x)),
        "strength_info": strengthInfo == null ? null : List<dynamic>.from(strengthInfo!.map((x) => x)),
        "defense_info": defenseInfo == null ? null : List<dynamic>.from(defenseInfo!.map((x) => x)),
        "speed_info": speedInfo == null ? null : List<dynamic>.from(speedInfo!.map((x) => x)),
        "dexterity_info": dexterityInfo == null ? null : List<dynamic>.from(dexterityInfo!.map((x) => x)),
        "jobpoints": jobpoints == null ? null : jobpoints!.toJson(),
        "properties":
            properties == null ? null : Map.from(properties!).map((k, v) => MapEntry<String, dynamic>(k, v.toJson())),
        "bazaar": List<dynamic>.from(bazaar!.map((x) => x.toJson())),
      };
}

class Jobpoints {
  Jobpoints({
    this.jobs,
    this.companies,
  });

  Jobs? jobs;
  Map<String, Company>? companies;

  factory Jobpoints.fromJson(Map<String, dynamic> json) => Jobpoints(
        jobs: json["jobs"] == null ? null : Jobs.fromJson(json["jobs"]),
        companies: json["companies"] == null
            ? null
            : Map.from(json["companies"]).map((k, v) => MapEntry<String, Company>(k, Company.fromJson(v))),
      );

  Map<String, dynamic> toJson() => {
        "jobs": jobs == null ? null : jobs!.toJson(),
        "companies":
            companies == null ? null : Map.from(companies!).map((k, v) => MapEntry<String, dynamic>(k, v.toJson())),
      };
}

class Jobs {
  Jobs({
    this.army,
    this.medical,
    this.casino,
    this.education,
    this.law,
    this.grocer,
  });

  int? army;
  int? medical;
  int? casino;
  int? education;
  int? law;
  int? grocer;

  factory Jobs.fromJson(Map<String, dynamic> json) => Jobs(
        army: json["army"] ?? 0,
        medical: json["medical"] ?? 0,
        casino: json["casino"] ?? 0,
        education: json["education"] ?? 0,
        law: json["law"] ?? 0,
        grocer: json["grocer"] ?? 0,
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

class Company {
  Company({
    this.name,
    this.jobpoints,
  });

  String? name;
  int? jobpoints;

  factory Company.fromJson(Map<String, dynamic> json) => Company(
        name: json["name"],
        jobpoints: json["jobpoints"],
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "jobpoints": jobpoints,
      };
}

class CityBank {
  CityBank({
    this.amount,
    this.timeLeft,
  });

  int? amount;
  int? timeLeft;

  factory CityBank.fromJson(Map<String, dynamic> json) => CityBank(
        amount: json["amount"],
        timeLeft: json["time_left"],
      );

  Map<String, dynamic> toJson() => {
        "amount": amount,
        "time_left": timeLeft,
      };
}

class Property {
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
  });

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
        "modifications": modifications == null ? null : modifications!.toJson(),
        "staff": staff == null ? null : staff!.toJson(),
      };
}

class Modifications {
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
  Staff({
    this.maid,
    this.guard,
    this.pilot,
    this.butler,
    this.doctor,
  });

  int? maid;
  int? guard;
  int? pilot;
  int? butler;
  int? doctor;

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
