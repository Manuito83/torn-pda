// To parse this JSON data, do
//
//     final itemsModel = itemsModelFromJson(jsonString);

// Dart imports:
import 'dart:convert';

ItemsModel itemsModelFromJson(String str) => ItemsModel.fromJson(json.decode(str));

String itemsModelToJson(ItemsModel data) => json.encode(data.toJson());

class ItemsModel {
  Map<String, Item>? items;

  ItemsModel({
    this.items,
  });

  factory ItemsModel.fromJson(Map<String, dynamic> json) => ItemsModel(
        items: json["items"] == null
            ? null
            : Map.from(json["items"]).map((k, v) => MapEntry<String, Item>(k, Item.fromJson(v))),
      );

  Map<String, dynamic> toJson() => {
        "items": items == null ? null : Map.from(items!).map((k, v) => MapEntry<String, dynamic>(k, v.toJson())),
      };
}

class Item {
  String? id; // Manually entered, as it doesn't follow the same order in the map
  int inventoryOwned = 0;
  int totalValue;
  //
  String? name;
  String? description;
  String? effect;
  String? requirement;
  ItemType? type;
  String? weaponType;
  int? buyPrice;
  int? sellPrice;
  int? marketValue;
  int? circulation;
  String? image;
  Coverage? coverage;

  Item({
    this.id,
    this.inventoryOwned = 0,
    this.totalValue = 0,
    this.name,
    this.description,
    this.effect,
    this.requirement,
    this.type,
    this.weaponType,
    this.buyPrice,
    this.sellPrice,
    this.marketValue,
    this.circulation,
    this.image,
    this.coverage,
  });

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        name: json["name"],
        description: json["description"],
        effect: json["effect"],
        requirement: json["requirement"],
        type: json["type"] == null ? null : typeValues.map[json["type"]],
        weaponType: json["weapon_type"],
        buyPrice: json["buy_price"],
        sellPrice: json["sell_price"],
        marketValue: json["market_value"],
        circulation: json["circulation"],
        image: json["image"],
        coverage: json["coverage"] == null ? null : Coverage.fromJson(json["coverage"]),
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "description": description,
        "effect": effect,
        "requirement": requirement,
        "type": type == null ? null : typeValues.reverse![type],
        "weapon_type": weaponType,
        "buy_price": buyPrice,
        "sell_price": sellPrice,
        "market_value": marketValue,
        "circulation": circulation,
        "image": image,
        "coverage": coverage?.toJson(),
      };
}

enum ItemType {
  MELEE,
  SECONDARY,
  PRIMARY,
  DEFENSIVE,
  CANDY,
  ELECTRONIC,
  CLOTHING,
  JEWELRY,
  OTHER,
  MEDICAL,
  VIRUS,
  COLLECTIBLE,
  CAR,
  FLOWER,
  BOOSTER,
  UNUSED,
  ALCOHOL,
  PLUSHIE,
  DRUG,
  TEMPORARY,
  SPECIAL,
  SUPPLY_PACK,
  ENHANCER,
  ARTIFACT,
  ENERGY_DRINK,
  BOOK
}

final typeValues = EnumValues({
  "Alcohol": ItemType.ALCOHOL,
  "Artifact": ItemType.ARTIFACT,
  "Book": ItemType.BOOK,
  "Booster": ItemType.BOOSTER,
  "Candy": ItemType.CANDY,
  "Car": ItemType.CAR,
  "Clothing": ItemType.CLOTHING,
  "Collectible": ItemType.COLLECTIBLE,
  "Defensive": ItemType.DEFENSIVE,
  "Drug": ItemType.DRUG,
  "Electronic": ItemType.ELECTRONIC,
  "Energy Drink": ItemType.ENERGY_DRINK,
  "Enhancer": ItemType.ENHANCER,
  "Flower": ItemType.FLOWER,
  "Jewelry": ItemType.JEWELRY,
  "Medical": ItemType.MEDICAL,
  "Melee": ItemType.MELEE,
  "Other": ItemType.OTHER,
  "Plushie": ItemType.PLUSHIE,
  "Primary": ItemType.PRIMARY,
  "Secondary": ItemType.SECONDARY,
  "Special": ItemType.SPECIAL,
  "Supply Pack": ItemType.SUPPLY_PACK,
  "Temporary": ItemType.TEMPORARY,
  "Unused": ItemType.UNUSED,
  "Virus": ItemType.VIRUS
});

class Coverage {
  Coverage({
    this.fullBodyCoverage,
    this.heartCoverage,
    this.stomachCoverage,
    this.chestCoverage,
    this.armCoverage,
    this.legCoverage,
    this.groinCoverage,
    this.handCoverage,
    this.footCoverage,
    this.headCoverage,
    this.throatCoverage,
  });

  double? fullBodyCoverage;
  double? heartCoverage;
  double? stomachCoverage;
  double? chestCoverage;
  double? armCoverage;
  double? legCoverage;
  double? groinCoverage;
  double? handCoverage;
  double? footCoverage;
  double? headCoverage;
  double? throatCoverage;

  factory Coverage.fromJson(Map<String, dynamic> json) => Coverage(
        fullBodyCoverage: json["Full Body Coverage"] == null ? 0 : json["Full Body Coverage"].toDouble(),
        heartCoverage: json["Heart Coverage"] == null ? 0 : json["Heart Coverage"].toDouble(),
        stomachCoverage: json["Stomach Coverage"] == null ? 0 : json["Stomach Coverage"].toDouble(),
        chestCoverage: json["Chest Coverage"] == null ? 0 : json["Chest Coverage"].toDouble(),
        armCoverage: json["Arm Coverage"] == null ? 0 : json["Arm Coverage"].toDouble(),
        legCoverage: json["Leg Coverage"] == null ? 0 : json["Leg Coverage"].toDouble(),
        groinCoverage: json["Groin Coverage"] == null ? 0 : json["Groin Coverage"].toDouble(),
        handCoverage: json["Hand Coverage"] == null ? 0 : json["Hand Coverage"].toDouble(),
        footCoverage: json["Foot Coverage"] == null ? 0 : json["Foot Coverage"].toDouble(),
        headCoverage: json["Head Coverage"] == null ? 0 : json["Head Coverage"].toDouble(),
        throatCoverage: json["Throat Coverage"] == null ? 0 : json["Throat Coverage"].toDouble(),
      );

  Map<String, dynamic> toJson() => {
        "Full Body Coverage": fullBodyCoverage,
        "Heart Coverage": heartCoverage,
        "Stomach Coverage": stomachCoverage,
        "Chest Coverage": chestCoverage,
        "Arm Coverage": armCoverage,
        "Leg Coverage": legCoverage,
        "Groin Coverage": groinCoverage,
        "Hand Coverage": handCoverage,
        "Foot Coverage": footCoverage,
        "Head Coverage": headCoverage,
        "Throat Coverage": throatCoverage,
      };
}

class EnumValues<T> {
  Map<String, T> map;
  Map<T, String>? reverseMap;

  EnumValues(this.map);

  Map<T, String>? get reverse {
    reverseMap ??= map.map((k, v) => MapEntry(v, k));
    return reverseMap;
  }
}
