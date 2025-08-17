class PropertyV2 {
  final int? id;
  final Owner? owner;
  final PropertyInfo? property;
  final int? happy;
  final Upkeep? upkeep;
  final int? marketPrice;
  final List<String>? modifications;
  final List<StaffMember>? staff;
  final List<UsedBy>? usedBy;
  final String? status;

  // Rental-specific fields (status: "rented")
  final int? cost;
  final int? costPerDay;
  final int? rentalPeriod;
  final int? rentalPeriodRemaining;
  final RentedBy? rentedBy;

  // For rent fields (status: "for_rent")
  final RenterAsked? renterAsked;

  PropertyV2({
    this.id,
    this.owner,
    this.property,
    this.happy,
    this.upkeep,
    this.marketPrice,
    this.modifications,
    this.staff,
    this.usedBy,
    this.status,
    this.cost,
    this.costPerDay,
    this.rentalPeriod,
    this.rentalPeriodRemaining,
    this.rentedBy,
    this.renterAsked,
  });

  factory PropertyV2.fromJson(Map<String, dynamic> json) {
    return PropertyV2(
      id: json["id"],
      owner: json["owner"] != null ? Owner.fromJson(json["owner"]) : null,
      property: json["property"] != null ? PropertyInfo.fromJson(json["property"]) : null,
      happy: json["happy"],
      upkeep: json["upkeep"] != null ? Upkeep.fromJson(json["upkeep"]) : null,
      marketPrice: json["market_price"],
      modifications: json["modifications"] != null ? List<String>.from(json["modifications"]) : null,
      staff: json["staff"] != null ? List<StaffMember>.from(json["staff"].map((x) => StaffMember.fromJson(x))) : null,
      usedBy: json["used_by"] != null ? List<UsedBy>.from(json["used_by"].map((x) => UsedBy.fromJson(x))) : null,
      status: json["status"],
      cost: json["cost"],
      costPerDay: json["cost_per_day"],
      rentalPeriod: json["rental_period"],
      rentalPeriodRemaining: json["rental_period_remaining"],
      rentedBy: json["rented_by"] != null ? RentedBy.fromJson(json["rented_by"]) : null,
      renterAsked: json["renter_asked"] != null ? RenterAsked.fromJson(json["renter_asked"]) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) "id": id,
        if (owner != null) "owner": owner!.toJson(),
        if (property != null) "property": property!.toJson(),
        if (happy != null) "happy": happy,
        if (upkeep != null) "upkeep": upkeep!.toJson(),
        if (marketPrice != null) "market_price": marketPrice,
        if (modifications != null) "modifications": List<dynamic>.from(modifications!.map((x) => x)),
        if (staff != null) "staff": List<dynamic>.from(staff!.map((x) => x.toJson())),
        if (usedBy != null) "used_by": List<dynamic>.from(usedBy!.map((x) => x.toJson())),
        if (status != null) "status": status,
        if (cost != null) "cost": cost,
        if (costPerDay != null) "cost_per_day": costPerDay,
        if (rentalPeriod != null) "rental_period": rentalPeriod,
        if (rentalPeriodRemaining != null) "rental_period_remaining": rentalPeriodRemaining,
        if (rentedBy != null) "rented_by": rentedBy!.toJson(),
        if (renterAsked != null) "renter_asked": renterAsked!.toJson(),
      };
}

class Owner {
  final int? id;
  final String? name;

  Owner({this.id, this.name});

  factory Owner.fromJson(Map<String, dynamic> json) => Owner(
        id: json["id"],
        name: json["name"],
      );

  Map<String, dynamic> toJson() => {
        if (id != null) "id": id,
        if (name != null) "name": name,
      };
}

class PropertyInfo {
  final int? id;
  final String? name;

  PropertyInfo({this.id, this.name});

  factory PropertyInfo.fromJson(Map<String, dynamic> json) => PropertyInfo(
        id: json["id"],
        name: json["name"],
      );

  Map<String, dynamic> toJson() => {
        if (id != null) "id": id,
        if (name != null) "name": name,
      };
}

class Upkeep {
  final int? property;
  final int? staff;

  Upkeep({this.property, this.staff});

  factory Upkeep.fromJson(Map<String, dynamic> json) => Upkeep(
        property: json["property"],
        staff: json["staff"],
      );

  Map<String, dynamic> toJson() => {
        if (property != null) "property": property,
        if (staff != null) "staff": staff,
      };
}

class StaffMember {
  final String? type;
  final int? amount;

  StaffMember({this.type, this.amount});

  factory StaffMember.fromJson(Map<String, dynamic> json) => StaffMember(
        type: json["type"],
        amount: json["amount"],
      );

  Map<String, dynamic> toJson() => {
        if (type != null) "type": type,
        if (amount != null) "amount": amount,
      };
}

class UsedBy {
  final int? id;
  final String? name;

  UsedBy({this.id, this.name});

  factory UsedBy.fromJson(Map<String, dynamic> json) => UsedBy(
        id: json["id"],
        name: json["name"],
      );

  Map<String, dynamic> toJson() => {
        if (id != null) "id": id,
        if (name != null) "name": name,
      };
}

class RentedBy {
  final int? id;
  final String? name;

  RentedBy({this.id, this.name});

  factory RentedBy.fromJson(Map<String, dynamic> json) => RentedBy(
        id: json["id"],
        name: json["name"],
      );

  Map<String, dynamic> toJson() => {
        if (id != null) "id": id,
        if (name != null) "name": name,
      };
}

class RenterAsked {
  final int? id;
  final String? name;

  RenterAsked({this.id, this.name});

  factory RenterAsked.fromJson(Map<String, dynamic> json) => RenterAsked(
        id: json["id"],
        name: json["name"],
      );

  Map<String, dynamic> toJson() => {
        if (id != null) "id": id,
        if (name != null) "name": name,
      };
}

class RentedInfo {
  final int? userId;
  final int? daysLeft;
  final int? totalCost;
  final int? costPerDay;

  RentedInfo({
    this.userId,
    this.daysLeft,
    this.totalCost,
    this.costPerDay,
  });

  factory RentedInfo.fromJson(Map<String, dynamic> json) => RentedInfo(
        userId: json["user_id"],
        daysLeft: json["days_left"],
        totalCost: json["total_cost"],
        costPerDay: json["cost_per_day"],
      );

  Map<String, dynamic> toJson() => {
        if (userId != null) "user_id": userId,
        if (daysLeft != null) "days_left": daysLeft,
        if (totalCost != null) "total_cost": totalCost,
        if (costPerDay != null) "cost_per_day": costPerDay,
      };
}

class PropertyV2Response {
  final List<PropertyV2> properties;
  final Metadata metadata;

  PropertyV2Response({
    required this.properties,
    required this.metadata,
  });

  factory PropertyV2Response.fromJson(Map<String, dynamic> json) => PropertyV2Response(
        properties: List<PropertyV2>.from((json["properties"] ?? []).map((x) => PropertyV2.fromJson(x))),
        metadata: Metadata.fromJson(json["_metadata"] ?? {}),
      );

  Map<String, dynamic> toJson() => {
        "properties": List<dynamic>.from(properties.map((x) => x.toJson())),
        "_metadata": metadata.toJson(),
      };
}

class Metadata {
  final Links links;

  Metadata({required this.links});

  factory Metadata.fromJson(Map<String, dynamic> json) => Metadata(
        links: Links.fromJson(json["links"] ?? {}),
      );

  Map<String, dynamic> toJson() => {
        "links": links.toJson(),
      };
}

class Links {
  final String? prev;
  final String? next;

  Links({this.prev, this.next});

  factory Links.fromJson(Map<String, dynamic> json) => Links(
        prev: json["prev"],
        next: json["next"],
      );

  Map<String, dynamic> toJson() => {
        "prev": prev,
        "next": next,
      };
}
