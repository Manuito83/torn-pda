// To parse this JSON data, do
//
//     final ownProfileMisc = ownProfileMiscFromJson(jsonString);

import 'dart:convert';
import 'dart:developer';

import 'package:torn_pda/models/profile/user_v2_selections/education_v2_model.dart';
import 'package:torn_pda/models/profile/user_v2_selections/property_v2_model.dart';

OwnProfileMisc ownProfileMiscFromJson(String rawJson) => OwnProfileMisc.fromJson(
      json.decode(rawJson) as Map<String, dynamic>,
    );

String ownProfileMiscToJson(OwnProfileMisc data) => json.encode(data.toJson());

class OwnProfileMisc {
  // V2 API selections - properties can come as List or Map format
  final EducationV2 education;
  final List<PropertyV2> properties;

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
  List<Bazaar>? bazaar;
  List<Itemmarket>? itemmarket;
  Metadata? metadata;

  OwnProfileMisc({
    required this.education,
    required this.properties,
    this.points,
    this.caymanBank,
    this.vaultAmount,
    this.companyFunds,
    this.dailyNetworth,
    this.moneyOnhand,
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
    this.bazaar,
    this.itemmarket,
    this.metadata,
  });

  factory OwnProfileMisc.fromJson(Map<String, dynamic> json) {
    return OwnProfileMisc(
      education: EducationV2.fromJson(json["education"] ?? {}),
      properties: json['properties'] != null
          ? (() {
              try {
                return List<PropertyV2>.from(json['properties'].map((x) => PropertyV2.fromJson(x)));
              } catch (e) {
                log('Error parsing properties: $e');
                return <PropertyV2>[];
              }
            })()
          : [],
      points: json["points"],
      caymanBank: json["cayman_bank"],
      vaultAmount: json["vault_amount"],
      companyFunds: json["company_funds"],
      dailyNetworth: json["daily_networth"],
      moneyOnhand: json["money_onhand"],
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
      searchForCash: json["search_for_cash"],
      forgery: json["forgery"],
      bootlegging: json["bootlegging"],
      reviving: json["reviving"],
      graffiti: json["graffiti"],
      hunting: json["hunting"],
      burglary: json["burglary"],
      shoplifting: json["shoplifting"],
      cracking: json["cracking"],
      pickpocketing: json["pickpocketing"],
      racing: json["racing"],
      scamming: json["scamming"],
      disposal: json["disposal"],
      hustling: json["hustling"],
      cardSkimming: json["card_skimming"],
      playerId: json["player_id"],
      cityBank: json["city_bank"] == null ? null : CityBank.fromJson(json["city_bank"]),
      strengthInfo: json["strength_info"] == null ? [] : List<String>.from(json["strength_info"]),
      defenseInfo: json["defense_info"] == null ? [] : List<String>.from(json["defense_info"]),
      speedInfo: json["speed_info"] == null ? [] : List<String>.from(json["speed_info"]),
      dexterityInfo: json["dexterity_info"] == null ? [] : List<String>.from(json["dexterity_info"]),
      jobpoints: json["jobpoints"] == null ? null : Jobpoints.fromJson(json["jobpoints"]),
      bazaar: json["bazaar"] == null ? [] : List<Bazaar>.from(json["bazaar"].map((x) => Bazaar.fromJson(x))),
      itemmarket: json["itemmarket"] == null
          ? []
          : List<Itemmarket>.from(json["itemmarket"].map((x) => Itemmarket.fromJson(x))),
      metadata: json["_metadata"] == null ? null : Metadata.fromJson(json["_metadata"]),
    );
  }

  Map<String, dynamic> toJson() => {
        "education": education.toJson(),
        "properties": List<dynamic>.from(properties.map((x) => x.toJson())),
        "points": points,
        "cayman_bank": caymanBank,
        "vault_amount": vaultAmount,
        "company_funds": companyFunds,
        "daily_networth": dailyNetworth,
        "money_onhand": moneyOnhand,
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
        "strength_info": strengthInfo == null ? [] : List<dynamic>.from(strengthInfo!.map((x) => x)),
        "defense_info": defenseInfo == null ? [] : List<dynamic>.from(defenseInfo!.map((x) => x)),
        "speed_info": speedInfo == null ? [] : List<dynamic>.from(speedInfo!.map((x) => x)),
        "dexterity_info": dexterityInfo == null ? [] : List<dynamic>.from(dexterityInfo!.map((x) => x)),
        "jobpoints": jobpoints?.toJson(),
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
  List<dynamic> bonuses;

  Item({
    this.id,
    this.name,
    this.type,
    this.uid,
    this.stats,
    this.rarity,
    required this.bonuses,
  });

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        id: json["id"],
        name: json["name"],
        type: json["type"],
        uid: json["uid"],
        stats: json["stats"],
        rarity: json["rarity"],
        bonuses: (json["bonuses"] as List<dynamic>?) ?? [],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "type": type,
        "uid": uid,
        "stats": stats,
        "rarity": rarity,
        "bonuses": bonuses,
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
            : Map.from(json["companies"]).map((k, v) => MapEntry<String, Company>(k, Company.fromJson(v))),
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
  Links? links;

  Metadata({this.links});

  factory Metadata.fromJson(Map<String, dynamic> json) =>
      Metadata(links: json["links"] == null ? null : Links.fromJson(json["links"]));
  Map<String, dynamic> toJson() => {"links": links?.toJson()};
}

class Links {
  dynamic prev;
  dynamic next;

  Links({
    this.prev,
    this.next,
  });

  factory Links.fromJson(Map<String, dynamic> json) => Links(
        prev: json["prev"],
        next: json["next"],
      );

  Map<String, dynamic> toJson() => {
        "prev": prev,
        "next": next,
      };
}
