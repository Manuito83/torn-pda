// To parse this JSON data, do
//
//     final propertyModel = propertyModelFromJson(jsonString);

import 'dart:convert';

PropertyModel propertyModelFromJson(String str) => PropertyModel.fromJson(json.decode(str));

String propertyModelToJson(PropertyModel data) => json.encode(data.toJson());

class PropertyModel {
  PropertyModel({
    this.property,
  });

  Property property;

  factory PropertyModel.fromJson(Map<String, dynamic> json) => PropertyModel(
    property: json["property"] == null ? null : Property.fromJson(json["property"]),
  );

  Map<String, dynamic> toJson() => {
    "property": property == null ? null : property.toJson(),
  };
}

class Property {
  Property({
    this.ownerId,
    this.propertyType,
    this.happy,
    this.upkeep,
    this.upgrades,
    this.staff,
    this.rented,
    this.usersLiving,
  });

  int ownerId;
  int propertyType;
  int happy;
  int upkeep;
  List<String> upgrades;
  List<dynamic> staff;
  Rented rented;
  dynamic usersLiving;

  factory Property.fromJson(Map<String, dynamic> json) => Property(
    ownerId: json["owner_id"] == null ? null : json["owner_id"],
    propertyType: json["property_type"] == null ? null : json["property_type"],
    happy: json["happy"] == null ? null : json["happy"],
    upkeep: json["upkeep"] == null ? null : json["upkeep"],
    upgrades: json["upgrades"] == null ? null : List<String>.from(json["upgrades"].map((x) => x)),
    staff: json["staff"] == null ? null : List<dynamic>.from(json["staff"].map((x) => x)),
    rented: json["rented"] == null ? null : Rented.fromJson(json["rented"]),
    usersLiving: json["users_living"],
  );

  Map<String, dynamic> toJson() => {
    "owner_id": ownerId == null ? null : ownerId,
    "property_type": propertyType == null ? null : propertyType,
    "happy": happy == null ? null : happy,
    "upkeep": upkeep == null ? null : upkeep,
    "upgrades": upgrades == null ? null : List<dynamic>.from(upgrades.map((x) => x)),
    "staff": staff == null ? null : List<dynamic>.from(staff.map((x) => x)),
    "rented": rented == null ? null : rented.toJson(),
    "users_living": usersLiving,
  };
}

class Rented {
  Rented({
    this.userId,
    this.daysLeft,
    this.totalCost,
    this.costPerDay,
  });

  int userId;
  int daysLeft;
  String totalCost;
  String costPerDay;

  factory Rented.fromJson(Map<String, dynamic> json) => Rented(
    userId: json["user_id"] == null ? null : json["user_id"],
    daysLeft: json["days_left"] == null ? null : json["days_left"],
    totalCost: json["total_cost"] == null ? null : json["total_cost"],
    costPerDay: json["cost_per_day"] == null ? null : json["cost_per_day"],
  );

  Map<String, dynamic> toJson() => {
    "user_id": userId == null ? null : userId,
    "days_left": daysLeft == null ? null : daysLeft,
    "total_cost": totalCost == null ? null : totalCost,
    "cost_per_day": costPerDay == null ? null : costPerDay,
  };
}
