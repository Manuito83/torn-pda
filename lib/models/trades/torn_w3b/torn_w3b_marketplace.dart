import 'dart:convert';

TornW3bMarketplaceResponse tornW3bMarketplaceResponseFromJson(String str) =>
    TornW3bMarketplaceResponse.fromJson(json.decode(str));

class TornW3bMarketplaceResponse {
  List<TornW3bMarketplaceItem> items;

  TornW3bMarketplaceResponse({
    this.items = const [],
  });

  factory TornW3bMarketplaceResponse.fromJson(Map<String, dynamic> json) => TornW3bMarketplaceResponse(
        items: json['items'] == null
            ? []
            : List<TornW3bMarketplaceItem>.from(
                json['items'].map((x) => TornW3bMarketplaceItem.fromJson(x)),
              ),
      );
}

class TornW3bMarketplaceItem {
  int itemId;
  int marketPrice;
  int? bazaarAverage;

  TornW3bMarketplaceItem({
    this.itemId = 0,
    this.marketPrice = 0,
    this.bazaarAverage,
  });

  factory TornW3bMarketplaceItem.fromJson(Map<String, dynamic> json) => TornW3bMarketplaceItem(
        itemId: _asInt(json['item_id'] ?? json['itemId'] ?? json['itemID']),
        marketPrice: _asInt(json['market_price'] ?? json['marketPrice']),
        bazaarAverage: _asNullableInt(json['bazaar_average'] ?? json['bazaarAverage']),
      );
}

int _asInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is double) {
    return value.round();
  }

  if (value is String) {
    return int.tryParse(value) ?? 0;
  }

  return 0;
}

int? _asNullableInt(dynamic value) {
  if (value == null) {
    return null;
  }

  final parsed = _asInt(value);
  return parsed == 0 && value != 0 && value != '0' ? null : parsed;
}
