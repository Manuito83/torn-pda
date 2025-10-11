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
  // V2 API selections transitioned
  final EducationV2 education;
  final List<PropertyV2> properties;

  // V2 API CURRENTLY IN transition from legacy in v3.8.4
  WorkStats? workStats;
  BattleStats? battleStats;
  Jobpoints? jobpoints;
  Money? money;
  Skills? skills;

  // Legacy / V1 API fields not transitioned by Torn
  int? playerId;
  CityBank? cityBank;
  List<String>? strengthInfo;
  List<String>? defenseInfo;
  List<String>? speedInfo;
  List<String>? dexterityInfo;
  List<Bazaar>? bazaar;
  List<Itemmarket>? itemmarket;
  Metadata? metadata;

  // Battle Stats Getters
  double get effectiveStrength => battleStats?.effectiveStrength ?? 0.0;
  double get effectiveDefense => battleStats?.effectiveDefense ?? 0.0;
  double get effectiveSpeed => battleStats?.effectiveSpeed ?? 0.0;
  double get effectiveDexterity => battleStats?.effectiveDexterity ?? 0.0;
  double get effectiveTotal => battleStats?.effectiveTotal ?? 0.0;

  // Battle Stats Modifiers Getters
  int get strengthModifierPercent => battleStats?.strengthModifierPercent ?? 0;
  int get defenseModifierPercent => battleStats?.defenseModifierPercent ?? 0;
  int get speedModifierPercent => battleStats?.speedModifierPercent ?? 0;
  int get dexterityModifierPercent => battleStats?.dexterityModifierPercent ?? 0;

  OwnProfileMisc({
    required this.education,
    required this.properties,
    this.workStats,
    this.battleStats,
    this.jobpoints,
    this.money,
    this.skills,
    this.playerId,
    this.cityBank,
    this.strengthInfo,
    this.defenseInfo,
    this.speedInfo,
    this.dexterityInfo,
    this.bazaar,
    this.itemmarket,
    this.metadata,
  });

  factory OwnProfileMisc.fromJson(Map<String, dynamic> json) {
    return OwnProfileMisc(
      education: EducationV2.fromJson(json["education"] ?? {}),
      properties: json['properties'] != null && json['properties'] is List
          ? List<PropertyV2>.from(json['properties'].map((x) => PropertyV2.fromJson(x)))
          : [],
      workStats: WorkStats.fromJson(json),
      battleStats: BattleStats.fromJson(json),
      jobpoints: Jobpoints.fromJson(json),
      money: Money.fromJson(json),
      skills: Skills.fromJson(json),
      playerId: json["player_id"],
      cityBank: json["city_bank"] == null ? null : CityBank.fromJson(json["city_bank"]),
      strengthInfo: json["strength_info"] == null ? [] : List<String>.from(json["strength_info"]),
      defenseInfo: json["defense_info"] == null ? [] : List<String>.from(json["defense_info"]),
      speedInfo: json["speed_info"] == null ? [] : List<String>.from(json["speed_info"]),
      dexterityInfo: json["dexterity_info"] == null ? [] : List<String>.from(json["dexterity_info"]),
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
        "workstats": workStats?.toJson(),
        "battlestats": battleStats?.toJson(),
        "jobpoints": jobpoints?.toJson(),
        "money": money?.toJson(),
        "skills": skills?.skillList?.map((x) => x.toJson()).toList() ?? [],
        "player_id": playerId,
        "city_bank": cityBank?.toJson(),
        "strength_info": strengthInfo == null ? [] : List<dynamic>.from(strengthInfo!.map((x) => x)),
        "defense_info": defenseInfo == null ? [] : List<dynamic>.from(defenseInfo!.map((x) => x)),
        "speed_info": speedInfo == null ? [] : List<dynamic>.from(speedInfo!.map((x) => x)),
        "dexterity_info": dexterityInfo == null ? [] : List<dynamic>.from(dexterityInfo!.map((x) => x)),
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

  factory Bazaar.fromJson(Map<String, dynamic> json) {
    try {
      return Bazaar(
        id: json["ID"],
        name: json["name"],
        type: json["type"],
        quantity: json["quantity"],
        price: json["price"],
        marketPrice: json["market_price"],
        uid: json["UID"],
      );
    } catch (e) {
      log('Error parsing Bazaar: $e');
      return Bazaar();
    }
  }

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

  factory CityBank.fromJson(Map<String, dynamic> json) {
    try {
      return CityBank(
        amount: json["amount"],
        timeLeft: json["time_left"],
      );
    } catch (e) {
      log('Error parsing CityBank: $e');
      return CityBank();
    }
  }

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

  factory Itemmarket.fromJson(Map<String, dynamic> json) {
    try {
      return Itemmarket(
        id: json["id"],
        price: json["price"],
        averagePrice: json["average_price"],
        amount: json["amount"],
        isAnonymous: json["is_anonymous"],
        available: json["available"],
        item: json["item"] == null ? null : Item.fromJson(json["item"]),
      );
    } catch (e) {
      log('Error parsing Itemmarket: $e');
      return Itemmarket();
    }
  }

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

  factory Item.fromJson(Map<String, dynamic> json) {
    try {
      return Item(
        id: json["id"],
        name: json["name"],
        type: json["type"],
        uid: json["uid"],
        stats: json["stats"],
        rarity: json["rarity"],
        bonuses: (json["bonuses"] as List<dynamic>?) ?? [],
      );
    } catch (e) {
      log('Error parsing Item: $e');
      return Item(bonuses: []);
    }
  }

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
  List<CompanyJobpoints>? companies;

  Jobpoints({
    this.jobs,
    this.companies,
  });

  factory Jobpoints.fromJson(Map<String, dynamic> json) {
    try {
      // TODO: Once legacy API is removed, only use this
      /*
    if (json.containsKey('jobpoints') && json['jobpoints'] != null) {
      final jobpointsData = json['jobpoints'] as Map<String, dynamic>;
      return Jobpoints(
        jobs: jobpointsData['jobs'] != null ? Jobs.fromJson(jobpointsData['jobs']) : null,
        companies: jobpointsData['companies'] != null && jobpointsData['companies'] is List
            ? List<CompanyJobpoints>.from(jobpointsData['companies'].map((x) => CompanyJobpoints.fromJson(x)))
            : null,
      );
    }
    return Jobpoints();
    */

      // Handle both legacy and new API structures
      if (json.containsKey('jobpoints') && json['jobpoints'] != null) {
        final jobpointsData = json['jobpoints'] as Map<String, dynamic>;

        // New API: companies as List
        if (jobpointsData['companies'] != null && jobpointsData['companies'] is List) {
          return Jobpoints(
            jobs: jobpointsData['jobs'] != null ? Jobs.fromJson(jobpointsData['jobs']) : null,
            companies: List<CompanyJobpoints>.from(jobpointsData['companies'].map((x) => CompanyJobpoints.fromJson(x))),
          );
        } else {
          // Old API: companies as Map within jobpoints object
          return Jobpoints(
            jobs: jobpointsData['jobs'] != null ? Jobs.fromJson(jobpointsData['jobs']) : null,
            companies: jobpointsData['companies'] != null && jobpointsData['companies'] is Map
                ? (jobpointsData['companies'] as Map<String, dynamic>).entries.map((entry) {
                    return CompanyJobpoints.legacy(
                      int.parse(entry.key),
                      entry.value['name'] ?? '',
                      entry.value['jobpoints'] ?? 0,
                    );
                  }).toList()
                : null,
          );
        }
      }
    } catch (e) {
      log('Error parsing jobpoints: $e');
    }

    return Jobpoints();
  }

  Map<String, dynamic> toJson() => {
        "jobs": jobs?.toJson(),
        "companies": companies?.map((x) => x.toJson()).toList() ?? [],
      };
}

class CompanyJobpoints {
  CompanyInfo company;
  int points;

  CompanyJobpoints({
    required this.company,
    required this.points,
  });

  factory CompanyJobpoints.fromJson(Map<String, dynamic> json) {
    try {
      return CompanyJobpoints(
        company: CompanyInfo.fromJson(json['company']),
        points: json['points'] ?? 0,
      );
    } catch (e) {
      log('Error parsing CompanyJobpoints: $e');
      return CompanyJobpoints(
        company: CompanyInfo(id: 0, name: ''),
        points: 0,
      );
    }
  }

  // TODO: Remove when legacy API is discontinued
  factory CompanyJobpoints.legacy(int id, String name, int jobpoints) => CompanyJobpoints(
        company: CompanyInfo(id: id, name: name),
        points: jobpoints,
      );

  Map<String, dynamic> toJson() => {
        "company": company.toJson(),
        "points": points,
      };
}

class CompanyInfo {
  int id;
  String name;

  CompanyInfo({
    required this.id,
    required this.name,
  });

  factory CompanyInfo.fromJson(Map<String, dynamic> json) {
    try {
      return CompanyInfo(
        id: json['id'],
        name: json['name'],
      );
    } catch (e) {
      log('Error parsing CompanyInfo: $e');
      return CompanyInfo(id: 0, name: '');
    }
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
      };
}

// Legacy class - TODO: Remove when legacy API is discontinued
class Company {
  String? name;
  int? jobpoints;

  Company({
    this.name,
    this.jobpoints,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    try {
      return Company(
        name: json["name"],
        jobpoints: json["jobpoints"],
      );
    } catch (e) {
      log('Error parsing Company: $e');
      return Company();
    }
  }

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

  factory Jobs.fromJson(Map<String, dynamic> json) {
    try {
      return Jobs(
        army: json["army"],
        medical: json["medical"],
        casino: json["casino"],
        education: json["education"],
        law: json["law"],
        grocer: json["grocer"],
      );
    } catch (e) {
      log('Error parsing Jobs: $e');
      return Jobs();
    }
  }

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

  factory Metadata.fromJson(Map<String, dynamic> json) {
    try {
      return Metadata(links: json["links"] == null ? null : Links.fromJson(json["links"]));
    } catch (e) {
      log('Error parsing Metadata: $e');
      return Metadata();
    }
  }
  Map<String, dynamic> toJson() => {"links": links?.toJson()};
}

class Links {
  dynamic prev;
  dynamic next;

  Links({
    this.prev,
    this.next,
  });

  factory Links.fromJson(Map<String, dynamic> json) {
    try {
      return Links(
        prev: json["prev"],
        next: json["next"],
      );
    } catch (e) {
      log('Error parsing Links: $e');
      return Links();
    }
  }

  Map<String, dynamic> toJson() => {
        "prev": prev,
        "next": next,
      };
}

class WorkStats {
  final int? manualLabor;
  final int? intelligence;
  final int? endurance;

  WorkStats({
    this.manualLabor,
    this.intelligence,
    this.endurance,
  });

  factory WorkStats.fromJson(Map<String, dynamic> json) {
    try {
      // TODO: Once legacy API is removed, only use this
      /*
      if (json.containsKey('workstats') && json['workstats'] != null) {
        final workstatsData = json['workstats'] as Map<String, dynamic>;
        return WorkStats(
          manualLabor: workstatsData['manual_labor'] ?? 0,
          intelligence: workstatsData['intelligence'] ?? 0,
          endurance: workstatsData['endurance'] ?? 0,
        );
      }
      return WorkStats(manualLabor: 0, intelligence: 0, endurance: 0);
      */

      // Handle both legacy and new API structures
      final workstatsData = (json.containsKey('workstats') && json['workstats'] != null)
          ? json['workstats'] as Map<String, dynamic> // New API
          : json; // Legacy API

      return WorkStats(
        manualLabor: workstatsData['manual_labor'] ?? 0,
        intelligence: workstatsData['intelligence'] ?? 0,
        endurance: workstatsData['endurance'] ?? 0,
      );
    } catch (e) {
      log("Error parsing WorkStats: $e");
    }

    return WorkStats();
  }

  Map<String, dynamic> toJson() => {
        "manual_labor": manualLabor,
        "intelligence": intelligence,
        "endurance": endurance,
      };
}

class BattleStats {
  final BattleStat? strength;
  final BattleStat? defense;
  final BattleStat? speed;
  final BattleStat? dexterity;
  final int? total;

  BattleStats({
    this.strength,
    this.defense,
    this.speed,
    this.dexterity,
    this.total,
  });

  /// Valores efectivos calculados (con modificadores aplicados)
  double get effectiveStrength => strength?.effectiveValue ?? 0.0;
  double get effectiveDefense => defense?.effectiveValue ?? 0.0;
  double get effectiveSpeed => speed?.effectiveValue ?? 0.0;
  double get effectiveDexterity => dexterity?.effectiveValue ?? 0.0;
  double get effectiveTotal => effectiveStrength + effectiveDefense + effectiveSpeed + effectiveDexterity;

  /// Modificadores en porcentaje
  int get strengthModifierPercent => strength?.totalModifierPercent ?? 0;
  int get defenseModifierPercent => defense?.totalModifierPercent ?? 0;
  int get speedModifierPercent => speed?.totalModifierPercent ?? 0;
  int get dexterityModifierPercent => dexterity?.totalModifierPercent ?? 0;

  factory BattleStats.fromJson(Map<String, dynamic> json) {
    try {
      // TODO: Once legacy API is removed, only use this
      /*
      if (json.containsKey('battlestats') && json['battlestats'] != null) {
        final battlestatsData = json['battlestats'] as Map<String, dynamic>;
        return BattleStats(
          strength: battlestatsData['strength'] != null ? BattleStat.fromJson(battlestatsData['strength']) : null,
          defense: battlestatsData['defense'] != null ? BattleStat.fromJson(battlestatsData['defense']) : null,
          speed: battlestatsData['speed'] != null ? BattleStat.fromJson(battlestatsData['speed']) : null,
          dexterity: battlestatsData['dexterity'] != null ? BattleStat.fromJson(battlestatsData['dexterity']) : null,
          total: battlestatsData['total'],
        );
      }
      return BattleStats();
      */

      // Handle both legacy and new API structures
      if (json.containsKey('battlestats') && json['battlestats'] != null) {
        // New API: battlestats is a separate object with rich structure
        final battlestatsData = json['battlestats'] as Map<String, dynamic>;
        return BattleStats(
          strength: battlestatsData['strength'] != null ? BattleStat.fromJson(battlestatsData['strength']) : null,
          defense: battlestatsData['defense'] != null ? BattleStat.fromJson(battlestatsData['defense']) : null,
          speed: battlestatsData['speed'] != null ? BattleStat.fromJson(battlestatsData['speed']) : null,
          dexterity: battlestatsData['dexterity'] != null ? BattleStat.fromJson(battlestatsData['dexterity']) : null,
          total: battlestatsData['total'],
        );
      } else {
        // Legacy API: battlestats are at the root with simple structure
        // Create BattleStat objects from legacy data with strength_info, defense_info, etc.
        final strengthInfo = json['strength_info'] != null ? List<String>.from(json['strength_info']) : <String>[];
        final defenseInfo = json['defense_info'] != null ? List<String>.from(json['defense_info']) : <String>[];
        final speedInfo = json['speed_info'] != null ? List<String>.from(json['speed_info']) : <String>[];
        final dexterityInfo = json['dexterity_info'] != null ? List<String>.from(json['dexterity_info']) : <String>[];

        return BattleStats(
          strength: json['strength'] != null
              ? BattleStat.legacy(json['strength'], json['strength_modifier'] ?? 0, strengthInfo)
              : null,
          defense: json['defense'] != null
              ? BattleStat.legacy(json['defense'], json['defense_modifier'] ?? 0, defenseInfo)
              : null,
          speed:
              json['speed'] != null ? BattleStat.legacy(json['speed'], json['speed_modifier'] ?? 0, speedInfo) : null,
          dexterity: json['dexterity'] != null
              ? BattleStat.legacy(json['dexterity'], json['dexterity_modifier'] ?? 0, dexterityInfo)
              : null,
          total: json['total'],
        );
      }
    } catch (e) {
      log("Error parsing BattleStats: $e");
    }

    return BattleStats();
  }

  Map<String, dynamic> toJson() => {
        "strength": strength?.toJson(),
        "defense": defense?.toJson(),
        "speed": speed?.toJson(),
        "dexterity": dexterity?.toJson(),
        "total": total,
      };
}

class BattleStat {
  final int value;
  final int modifier;
  final List<BattleStatModifier>? modifiers;

  BattleStat({
    required this.value,
    required this.modifier,
    this.modifiers,
  });

  double get effectiveValue {
    if (modifiers == null || modifiers!.isEmpty) {
      return value.toDouble();
    }

    int totalModifierPercent = 0;
    final RegExp percentRegex = RegExp(r"(\+|\-)([0-9]+)(%)");

    for (final mod in modifiers!) {
      final matches = percentRegex.allMatches(mod.effect);
      for (final match in matches) {
        final change = int.tryParse(match.group(2) ?? '0') ?? 0;
        if (match.group(1) == '-') {
          totalModifierPercent -= change;
        } else if (match.group(1) == '+') {
          totalModifierPercent += change;
        }
      }
    }

    return value + (value * totalModifierPercent / 100);
  }

  int get totalModifierPercent {
    if (modifiers == null || modifiers!.isEmpty) {
      return 0;
    }

    int totalModifierPercent = 0;
    final RegExp percentRegex = RegExp(r"(\+|\-)([0-9]+)(%)");

    for (final mod in modifiers!) {
      final matches = percentRegex.allMatches(mod.effect);
      for (final match in matches) {
        final change = int.tryParse(match.group(2) ?? '0') ?? 0;
        if (match.group(1) == '-') {
          totalModifierPercent -= change;
        } else if (match.group(1) == '+') {
          totalModifierPercent += change;
        }
      }
    }

    return totalModifierPercent;
  }

  bool get hasModifiers {
    return modifiers != null && modifiers!.isNotEmpty && totalModifierPercent != 0;
  }

  factory BattleStat.fromJson(Map<String, dynamic> json) {
    try {
      return BattleStat(
        value: json['value'],
        modifier: json['modifier'],
        modifiers: json['modifiers'] != null
            ? List<BattleStatModifier>.from(json['modifiers'].map((x) => BattleStatModifier.fromJson(x)))
            : null,
      );
    } catch (e) {
      log('Error parsing BattleStat: $e');
      return BattleStat(value: 0, modifier: 0);
    }
  }

  // TODO: Remove when legacy API is discontinued
  factory BattleStat.legacy(int value, int modifier, List<String> infoList) {
    // Parse infoList to create modifiers
    final List<BattleStatModifier> parsedModifiers = [];
    final RegExp percentRegex = RegExp(r"(\+|\-)([0-9]+)(%)");

    for (final info in infoList) {
      final matches = percentRegex.allMatches(info);
      for (final match in matches) {
        final sign = match.group(1) ?? '';
        final percentValue = int.tryParse(match.group(2) ?? '0') ?? 0;
        final effect = '$sign$percentValue%';

        parsedModifiers.add(BattleStatModifier(
          effect: effect,
          value: percentValue.toDouble(),
          type: 'legacy',
        ));
      }
    }

    return BattleStat(
      value: value,
      modifier: modifier,
      modifiers: parsedModifiers.isEmpty ? null : parsedModifiers,
    );
  }

  Map<String, dynamic> toJson() => {
        "value": value,
        "modifier": modifier,
        "modifiers": modifiers?.map((x) => x.toJson()).toList(),
      };
}

class BattleStatModifier {
  final String effect;
  final double value;
  final String type;

  BattleStatModifier({
    required this.effect,
    required this.value,
    required this.type,
  });

  factory BattleStatModifier.fromJson(Map<String, dynamic> json) {
    try {
      return BattleStatModifier(
        effect: json['effect'] ?? '',
        value: json['value'] != null ? json['value'].toDouble() : 0.0,
        type: json['type'] ?? '',
      );
    } catch (e) {
      log('Error parsing BattleStatModifier: $e');
      return BattleStatModifier(effect: '', value: 0.0, type: '');
    }
  }

  Map<String, dynamic> toJson() => {
        "effect": effect,
        "value": value,
        "type": type,
      };
}

class Money {
  final int? points;
  final int? wallet;
  final int? company;
  final int? vault;
  final int? caymanBank;
  final CityBankV2? cityBank;
  final FactionMoney? faction;
  final int? dailyNetworth;

  Money({
    this.points,
    this.wallet,
    this.company,
    this.vault,
    this.caymanBank,
    this.cityBank,
    this.faction,
    this.dailyNetworth,
  });

  factory Money.fromJson(Map<String, dynamic> json) {
    try {
      // TODO: Once legacy API is removed, only use this
      /*
      if (json.containsKey('money') && json['money'] != null) {
        final moneyData = json['money'] as Map<String, dynamic>;
        return Money(
          points: moneyData['points'] ?? 0,
          wallet: moneyData['wallet'] ?? 0,
          company: moneyData['company'] ?? 0,
          vault: moneyData['vault'] ?? 0,
          caymanBank: moneyData['cayman_bank'] ?? 0,
          cityBank: CityBankV2.fromJson(moneyData['city_bank'] ?? {}),
          faction: moneyData['faction'] != null ? FactionMoney.fromJson(moneyData['faction']) : null,
          dailyNetworth: moneyData['daily_networth'] ?? 0,
        );
      }
      return Money(
        points: 0, wallet: 0, company: 0, vault: 0, 
        caymanBank: 0, cityBank: CityBankV2(), dailyNetworth: 0
      );
    */

      // Handle both legacy and new API structures
      if (json.containsKey('money') && json['money'] != null) {
        // New API: money is a unified object
        final moneyData = json['money'] as Map<String, dynamic>;
        return Money(
          points: moneyData['points'] ?? 0,
          wallet: moneyData['wallet'] ?? 0,
          company: moneyData['company'] ?? 0,
          vault: moneyData['vault'] ?? 0,
          caymanBank: moneyData['cayman_bank'] ?? 0,
          cityBank: CityBankV2.fromJson(moneyData['city_bank'] ?? {}),
          faction: moneyData['faction'] != null ? FactionMoney.fromJson(moneyData['faction']) : null,
          dailyNetworth: moneyData['daily_networth'] ?? 0,
        );
      } else {
        // Legacy API: money fields scattered at root level
        return Money(
          points: json['points'] ?? 0,
          wallet: json['money_onhand'] ?? 0,
          company: json['company_funds'] ?? 0,
          vault: json['vault_amount'] ?? 0,
          caymanBank: json['cayman_bank'] ?? 0,
          cityBank: json['city_bank'] != null ? CityBankV2.legacy(json['city_bank']) : CityBankV2(),
          faction: null,
          dailyNetworth: json['daily_networth'] ?? 0,
        );
      }
    } catch (e) {
      log("Error parsing Money: $e");
    }

    return Money();
  }

  Map<String, dynamic> toJson() => {
        "points": points,
        "wallet": wallet,
        "company": company,
        "vault": vault,
        "cayman_bank": caymanBank,
        "city_bank": cityBank?.toJson(),
        "faction": faction?.toJson(),
        "daily_networth": dailyNetworth,
      };
}

class CityBankV2 {
  final int amount;
  final int until;

  CityBankV2({
    this.amount = 0,
    this.until = 0,
  });

  factory CityBankV2.fromJson(Map<String, dynamic> json) {
    try {
      return CityBankV2(
        amount: json['amount'] ?? 0,
        until: json['until'] ?? 0,
      );
    } catch (e) {
      log('Error parsing CityBankV2: $e');
      return CityBankV2();
    }
  }

  // TODO: Remove when legacy API is discontinued
  factory CityBankV2.legacy(Map<String, dynamic> json) => CityBankV2(
        amount: json['amount'] ?? 0,
        until: json['time_left'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        "amount": amount,
        "until": until,
      };
}

class FactionMoney {
  final int money;
  final int points;

  FactionMoney({
    required this.money,
    required this.points,
  });

  factory FactionMoney.fromJson(Map<String, dynamic> json) {
    try {
      return FactionMoney(
        money: json['money'] ?? 0,
        points: json['points'] ?? 0,
      );
    } catch (e) {
      log('Error parsing FactionMoney: $e');
      return FactionMoney(money: 0, points: 0);
    }
  }

  Map<String, dynamic> toJson() => {
        "money": money,
        "points": points,
      };
}

class Skills {
  final List<Skill>? skillList;

  Skills({this.skillList});

  factory Skills.fromJson(Map<String, dynamic> json) {
    try {
      // TODO: Once legacy API is removed, only use this
      /*
      if (json.containsKey('skills') && json['skills'] != null && json['skills'] is List) {
        return Skills(
          skillList: List<Skill>.from(json['skills'].map((x) => Skill.fromJson(x))),
        );
      }
      return Skills(skillList: []);
      */

      // Handle both legacy and new API structures
      if (json.containsKey('skills') && json['skills'] != null && json['skills'] is List) {
        // New API: skills is a List of Skill objects
        return Skills(
          skillList: List<Skill>.from(json['skills'].map((x) => Skill.fromJson(x))),
        );
      } else {
        // Legacy API: skills are individual fields at root level
        final List<Skill> skills = [];

        // Map all known skill fields from legacy to new structure
        final Map<String, String> skillMap = {
          'forgery': 'Forgery',
          'search_for_cash': 'Search for Cash',
          'bootlegging': 'Bootlegging',
          'card_skimming': 'Card Skimming',
          'reviving': 'Reviving',
          'graffiti': 'Graffiti',
          'hunting': 'Hunting',
          'burglary': 'Burglary',
          'shoplifting': 'Shoplifting',
          'cracking': 'Cracking',
          'scamming': 'Scamming',
          'pickpocketing': 'Pickpocketing',
          'racing': 'Racing',
          'hustling': 'Hustling',
          'disposal': 'Disposal',
        };

        skillMap.forEach((slug, name) {
          if (json[slug] != null) {
            final level = double.tryParse(json[slug].toString()) ?? 0.0;
            skills.add(Skill(slug: slug, name: name, level: level));
          }
        });

        return Skills(skillList: skills);
      }
    } catch (e) {
      log("Error parsing Skills: $e");
    }

    return Skills();
  }

  Map<String, dynamic> toJson() => {
        "skills": skillList == null ? [] : skillList!.map((x) => x.toJson()).toList(),
      };
}

class Skill {
  final String slug;
  final String name;
  final double level;

  Skill({
    required this.slug,
    required this.name,
    required this.level,
  });

  factory Skill.fromJson(Map<String, dynamic> json) {
    try {
      return Skill(
        slug: json['slug'] ?? '',
        name: json['name'] ?? '',
        level: (json['level'] ?? 0).toDouble(),
      );
    } catch (e) {
      log('Error parsing Skill: $e');
      return Skill(slug: '', name: '', level: 0.0);
    }
  }

  Map<String, dynamic> toJson() => {
        "slug": slug,
        "name": name,
        "level": level,
      };
}
