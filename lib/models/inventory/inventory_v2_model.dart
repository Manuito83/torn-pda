class InventoryV2Item {
  final int id;
  final int amount;
  final bool equipped;
  final String name;
  final bool factionOwned;
  final String? uid;

  InventoryV2Item({
    required this.id,
    required this.amount,
    required this.equipped,
    required this.name,
    required this.factionOwned,
    this.uid,
  });

  factory InventoryV2Item.fromJson(Map<String, dynamic> json) {
    return InventoryV2Item(
      id: (json["id"] as num?)?.toInt() ?? 0,
      amount: (json["amount"] as num?)?.toInt() ?? 0,
      equipped: json["equipped"] as bool? ?? false,
      name: json["name"] as String? ?? "",
      factionOwned: json["faction_owned"] as bool? ?? false,
      uid: json["uid"]?.toString(),
    );
  }
}

class InventoryV2DisplayItem {
  final int id;
  final int quantity;

  InventoryV2DisplayItem({required this.id, required this.quantity});

  factory InventoryV2DisplayItem.fromJson(Map<String, dynamic> json) {
    return InventoryV2DisplayItem(
      id: ((json["ID"] ?? json["id"]) as num?)?.toInt() ?? 0,
      quantity: (json["quantity"] as num?)?.toInt() ?? 0,
    );
  }
}

class InventoryV2Category {
  final List<InventoryV2Item> items;
  final int timestamp;

  /// Display case
  final List<InventoryV2DisplayItem>? display;

  InventoryV2Category({required this.items, required this.timestamp, this.display});

  factory InventoryV2Category.fromJson(Map<String, dynamic> json) {
    final rows = json["items"];
    return InventoryV2Category(
      items: rows is List
          ? rows.whereType<Map<String, dynamic>>().map((e) => InventoryV2Item.fromJson(e)).toList()
          : <InventoryV2Item>[],
      timestamp: (json["timestamp"] as num?)?.toInt() ?? 0,
    );
  }
}
