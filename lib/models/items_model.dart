// To parse this JSON data, do
//
//     final itemsModel = itemsModelFromJson(jsonString);

import 'dart:convert';

ItemsModel itemsModelFromJson(String str) => ItemsModel.fromJson(json.decode(str));

String itemsModelToJson(ItemsModel data) => json.encode(data.toJson());

class ItemsModel {
  Map<String, Item> items;

  ItemsModel({
    this.items,
  });

  factory ItemsModel.fromJson(Map<String, dynamic> json) => ItemsModel(
    items: json["items"] == null ? null : Map.from(json["items"]).map((k, v) => MapEntry<String, Item>(k, Item.fromJson(v))),
  );

  Map<String, dynamic> toJson() => {
    "items": items == null ? null : Map.from(items).map((k, v) => MapEntry<String, dynamic>(k, v.toJson())),
  };
}

class Item {
  String name;
  String description;
  String effect;
  Requirement requirement;
  ItemType type;
  WeaponType weaponType;
  int buyPrice;
  int sellPrice;
  int marketValue;
  int circulation;
  String image;

  Item({
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
  });

  factory Item.fromJson(Map<String, dynamic> json) => Item(
    name: json["name"] == null ? null : json["name"],
    description: json["description"] == null ? null : json["description"],
    effect: json["effect"] == null ? null : json["effect"],
    requirement: json["requirement"] == null ? null : requirementValues.map[json["requirement"]],
    type: json["type"] == null ? null : typeValues.map[json["type"]],
    weaponType: json["weapon_type"] == null ? null : weaponTypeValues.map[json["weapon_type"]],
    buyPrice: json["buy_price"] == null ? null : json["buy_price"],
    sellPrice: json["sell_price"] == null ? null : json["sell_price"],
    marketValue: json["market_value"] == null ? null : json["market_value"],
    circulation: json["circulation"] == null ? null : json["circulation"],
    image: json["image"] == null ? null : json["image"],
  );

  Map<String, dynamic> toJson() => {
    "name": name == null ? null : name,
    "description": description == null ? null : description,
    "effect": effect == null ? null : effect,
    "requirement": requirement == null ? null : requirementValues.reverse[requirement],
    "type": type == null ? null : typeValues.reverse[type],
    "weapon_type": weaponType == null ? null : weaponTypeValues.reverse[weaponType],
    "buy_price": buyPrice == null ? null : buyPrice,
    "sell_price": sellPrice == null ? null : sellPrice,
    "market_value": marketValue == null ? null : marketValue,
    "circulation": circulation == null ? null : circulation,
    "image": image == null ? null : image,
  };
}

enum Requirement { EMPTY, UNDER_THE_EFFECT_OF_RADIATION_POISONING, BACHELOR_OF_BIOLOGY_EDUCATION_COURSE, INTRAVENOUS_THERAPY_EDUCATION_COURSE, ONLY_WORKS_DURING_THE_VALENTINE_S_DAY_EVENT, REQUIRES_NOTHING }

final requirementValues = EnumValues({
  "Bachelor of Biology education course.": Requirement.BACHELOR_OF_BIOLOGY_EDUCATION_COURSE,
  "": Requirement.EMPTY,
  "Intravenous Therapy education course.": Requirement.INTRAVENOUS_THERAPY_EDUCATION_COURSE,
  "Only works during the Valentine's day event.": Requirement.ONLY_WORKS_DURING_THE_VALENTINE_S_DAY_EVENT,
  "Requires nothing.": Requirement.REQUIRES_NOTHING,
  "Under the effect of radiation poisoning.": Requirement.UNDER_THE_EFFECT_OF_RADIATION_POISONING
});

enum ItemType { MELEE, SECONDARY, PRIMARY, DEFENSIVE, CANDY, ELECTRONIC, CLOTHING, JEWELRY, OTHER, MEDICAL, VIRUS, COLLECTIBLE, CAR, FLOWER, BOOSTER, UNUSED, ALCOHOL, PLUSHIE, DRUG, TEMPORARY, SPECIAL, SUPPLY_PACK, ENHANCER, ARTIFACT, ENERGY_DRINK, BOOK }

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

enum WeaponType { CLUBBING, PIERCING, SLASHING, MECHANICAL, PISTOL, SHOTGUN, SMG, RIFLE, MACHINE_GUN, HEAVY_ARTILLERY, TEMPORARY }

final weaponTypeValues = EnumValues({
  "Clubbing": WeaponType.CLUBBING,
  "Heavy artillery": WeaponType.HEAVY_ARTILLERY,
  "Machine gun": WeaponType.MACHINE_GUN,
  "Mechanical": WeaponType.MECHANICAL,
  "Piercing": WeaponType.PIERCING,
  "Pistol": WeaponType.PISTOL,
  "Rifle": WeaponType.RIFLE,
  "Shotgun": WeaponType.SHOTGUN,
  "Slashing": WeaponType.SLASHING,
  "SMG": WeaponType.SMG,
  "Temporary": WeaponType.TEMPORARY
});

class EnumValues<T> {
  Map<String, T> map;
  Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    if (reverseMap == null) {
      reverseMap = map.map((k, v) => new MapEntry(v, k));
    }
    return reverseMap;
  }
}
