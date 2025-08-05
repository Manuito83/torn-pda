class PropertyV2 {
  final int id;
  final Owner owner;
  final PropertyInfo propertyInfo;
  final int happy;
  final Upkeep? upkeep;
  final int? marketPrice;
  final List<String> modifications;
  final List<StaffMember> staff;
  final String status;
  final List<UsedBy> usedBy;

  PropertyV2({
    required this.id,
    required this.owner,
    required this.propertyInfo,
    required this.happy,
    this.upkeep,
    this.marketPrice,
    required this.modifications,
    required this.staff,
    required this.status,
    required this.usedBy,
  });

  factory PropertyV2.fromJson(Map<String, dynamic> json) => PropertyV2(
        id: json["id"] ?? 0,
        owner: Owner.fromJson(json["owner"] ?? {}),
        propertyInfo: PropertyInfo.fromJson(json["property"] ?? {}),
        happy: json["happy"] ?? 0,
        upkeep: json["upkeep"] == null ? null : Upkeep.fromJson(json["upkeep"]),
        marketPrice: json["market_price"],
        modifications: List<String>.from((json["modifications"] ?? []).map((x) => x)),
        staff: List<StaffMember>.from((json["staff"] ?? []).map((x) => StaffMember.fromJson(x))),
        status: json["status"] ?? "Unknown",
        usedBy: List<UsedBy>.from((json["used_by"] ?? []).map((x) => UsedBy.fromJson(x))),
      );

  factory PropertyV2.fromLegacyJson(String id, Map<String, dynamic> json) => PropertyV2(
        id: int.tryParse(id) ?? 0,
        owner: Owner(id: json["owner_id"] ?? 0, name: "N/A"),
        propertyInfo: PropertyInfo(id: json["property_type"] ?? 0, name: json["property"] ?? "Unknown"),
        happy: json["happy"] ?? 0,
        upkeep: null,
        marketPrice: json["marketprice"],
        modifications: [],
        staff: [],
        status: json["status"] ?? "Unknown",
        usedBy: [],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "owner": owner.toJson(),
        "property": propertyInfo.toJson(),
        "happy": happy,
        "upkeep": upkeep?.toJson(),
        "market_price": marketPrice,
        "modifications": List<dynamic>.from(modifications.map((x) => x)),
        "staff": List<dynamic>.from(staff.map((x) => x.toJson())),
        "status": status,
        "used_by": List<dynamic>.from(usedBy.map((x) => x.toJson())),
      };
}

class Owner {
  final int id;
  final String name;
  Owner({required this.id, required this.name});
  factory Owner.fromJson(Map<String, dynamic> json) => Owner(id: json["id"] ?? 0, name: json["name"] ?? "Unknown");
  Map<String, dynamic> toJson() => {"id": id, "name": name};
}

class PropertyInfo {
  final int id;
  final String name;
  PropertyInfo({required this.id, required this.name});
  factory PropertyInfo.fromJson(Map<String, dynamic> json) =>
      PropertyInfo(id: json["id"] ?? 0, name: json["name"] ?? "Unknown");
  Map<String, dynamic> toJson() => {"id": id, "name": name};
}

class Upkeep {
  final int property;
  final int staff;
  Upkeep({required this.property, required this.staff});
  factory Upkeep.fromJson(Map<String, dynamic> json) =>
      Upkeep(property: json["property"] ?? 0, staff: json["staff"] ?? 0);
  Map<String, dynamic> toJson() => {"property": property, "staff": staff};
}

class StaffMember {
  final String type;
  final int amount;
  StaffMember({required this.type, required this.amount});
  factory StaffMember.fromJson(Map<String, dynamic> json) =>
      StaffMember(type: json["type"] ?? "", amount: json["amount"] ?? 0);
  Map<String, dynamic> toJson() => {"type": type, "amount": amount};
}

class UsedBy {
  final int id;
  final String name;
  UsedBy({required this.id, required this.name});
  factory UsedBy.fromJson(Map<String, dynamic> json) => UsedBy(id: json["id"] ?? 0, name: json["name"] ?? "Unknown");
  Map<String, dynamic> toJson() => {"id": id, "name": name};
}
