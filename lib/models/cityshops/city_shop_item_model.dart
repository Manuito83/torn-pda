// To parse this JSON data, do
//
//     final cityShopItemModel = CityShopItemModel.fromJson(jsonMap);

import 'package:flutter/material.dart';

enum CityShopMode {
  headsUp("heads_up", "Early warning", Colors.green),
  onRestock("on_restock", "When in stock", Colors.orange),
  noData("no_data", "No data", Colors.grey);

  const CityShopMode(this.apiValue, this.label, this.color);

  final String apiValue;
  final String label;
  final Color color;

  static CityShopMode fromApi(String? value) =>
      values.firstWhere((m) => m.apiValue == value, orElse: () => CityShopMode.noData);
}

enum CityShopReason {
  reliable("reliable"),
  lowReliability("low_reliability"),
  slowItem("slow_item"),
  learning("learning"),
  neverStocked("never_stocked");

  const CityShopReason(this.apiValue);

  final String apiValue;

  static CityShopReason fromApi(String? value) =>
      values.firstWhere((r) => r.apiValue == value, orElse: () => CityShopReason.lowReliability);
}

class CityShopWindowModel {
  CityShopWindowModel({required this.start, required this.end});

  final int start;
  final int end;

  factory CityShopWindowModel.fromJson(Map<String, dynamic> json) =>
      CityShopWindowModel(start: (json["start"] as num?)?.toInt() ?? 0, end: (json["end"] as num?)?.toInt() ?? 0);

  Map<String, dynamic> toJson() => {"start": start, "end": end};
}

class CityShopItemModel {
  CityShopItemModel({
    this.shop,
    this.item,
    this.shopId,
    this.itemId,
    this.mode = CityShopMode.noData,
    this.reason = CityShopReason.lowReliability,
    this.reliability,
    this.baseMin,
    this.cycles = 0,
    this.stockP10Min,
    this.stockMedianMin,
    this.fastSellFraction,
    this.window,
    this.stock = 0,
    this.gone = false,
    this.updated = 0,
  });

  final String? shop;
  final String? item;
  final int? shopId;
  final int? itemId;
  final CityShopMode mode;
  final CityShopReason reason;
  final int? reliability;
  final double? baseMin;
  final int cycles;
  final double? stockP10Min;
  final double? stockMedianMin;
  final double? fastSellFraction;
  final CityShopWindowModel? window;
  final int stock;
  final bool gone;
  final int updated;

  // Same key as the items document and cityShopActiveAlerts
  String get key => "$shopId-$itemId";

  // Shown under the item name: the honest number when there is one
  String get statusLabel {
    if (reliability != null) return "Reliability $reliability%";
    return reason == CityShopReason.neverStocked ? "Never seen in stock" : "Not enough data yet";
  }

  factory CityShopItemModel.fromJson(Map<String, dynamic> json) => CityShopItemModel(
    shop: json["shop"] as String?,
    item: json["item"] as String?,
    shopId: (json["shopId"] as num?)?.toInt(),
    itemId: (json["itemId"] as num?)?.toInt(),
    mode: CityShopMode.fromApi(json["mode"] as String?),
    reason: CityShopReason.fromApi(json["reason"] as String?),
    reliability: (json["reliability"] as num?)?.toInt(),
    baseMin: (json["baseMin"] as num?)?.toDouble(),
    cycles: (json["cycles"] as num?)?.toInt() ?? 0,
    stockP10Min: (json["stockP10Min"] as num?)?.toDouble(),
    stockMedianMin: (json["stockMedianMin"] as num?)?.toDouble(),
    fastSellFraction: (json["fastSellFraction"] as num?)?.toDouble(),
    window: json["window"] is Map
        ? CityShopWindowModel.fromJson(Map<String, dynamic>.from(json["window"] as Map))
        : null,
    stock: (json["stock"] as num?)?.toInt() ?? 0,
    gone: json["gone"] as bool? ?? false,
    updated: (json["updated"] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    "shop": shop,
    "item": item,
    "shopId": shopId,
    "itemId": itemId,
    "mode": mode.apiValue,
    "reason": reason.apiValue,
    "reliability": reliability,
    "baseMin": baseMin,
    "cycles": cycles,
    "stockP10Min": stockP10Min,
    "stockMedianMin": stockMedianMin,
    "fastSellFraction": fastSellFraction,
    "window": window?.toJson(),
    "stock": stock,
    "gone": gone,
    "updated": updated,
  };
}

// Big Al's (100) has its own page instead of shops.php?step=
class CityShopSlugs {
  static const Map<int, String> stepByShopId = {
    101: "candy", // Sally's Sweet Shop
    102: "clothes", // TC Clothing
    103: "bitsnbobs", // Bits 'n' Bobs
    104: "jewelry", // Jewelry Store
    105: "super", // Super Store
    107: "docks", // Docks
    108: "postoffice", // Post Office
    110: "pharmacy", // Pharmacy
    111: "nikeh", // Nikeh Performance / Nikeh Sports Shop
    113: "printstore", // Print Store
  };

  static const int bigAlGunShopId = 100;

  static String urlForShop(int? shopId) {
    if (shopId == CityShopSlugs.bigAlGunShopId) {
      return "https://www.torn.com/bigalgunshop.php";
    }
    final step = stepByShopId[shopId];
    if (step == null) return "https://www.torn.com/shops.php";
    return "https://www.torn.com/shops.php?step=$step";
  }
}
