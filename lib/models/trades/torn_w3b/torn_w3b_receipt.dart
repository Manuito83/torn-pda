import 'dart:convert';

TornW3bReceiptRequest tornW3bReceiptRequestFromJson(String str) => TornW3bReceiptRequest.fromJson(json.decode(str));

String tornW3bReceiptRequestToJson(TornW3bReceiptRequest data) => json.encode(data.toJson());

class TornW3bReceiptRequest {
  List<TornW3bReceiptRequestItem> items;
  String username;
  int tradeId;
  bool includeMessage;

  TornW3bReceiptRequest({
    required this.items,
    required this.username,
    required this.tradeId,
    this.includeMessage = true,
  });

  factory TornW3bReceiptRequest.fromJson(Map<String, dynamic> json) => TornW3bReceiptRequest(
        items: List<TornW3bReceiptRequestItem>.from(
          json['items'].map((x) => TornW3bReceiptRequestItem.fromJson(x)),
        ),
        username: json['username'],
        tradeId: json['tradeID'],
        includeMessage: json['includeMessage'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'items': List<dynamic>.from(items.map((x) => x.toJson())),
        'username': username,
        'tradeID': tradeId,
        'includeMessage': includeMessage,
      };
}

class TornW3bReceiptRequestItem {
  String? name;
  int? itemId;
  int quantity;

  TornW3bReceiptRequestItem({
    this.name,
    this.itemId,
    required this.quantity,
  });

  factory TornW3bReceiptRequestItem.fromJson(Map<String, dynamic> json) => TornW3bReceiptRequestItem(
        name: json['name'],
        itemId: json['itemID'],
        quantity: json['quantity'],
      );

  Map<String, dynamic> toJson() => {
        if (name != null && name!.isNotEmpty) 'name': name,
        if (itemId != null && itemId! > 0) 'itemID': itemId,
        'quantity': quantity,
      };
}

TornW3bReceiptResponse tornW3bReceiptResponseFromJson(String str) => TornW3bReceiptResponse.fromJson(json.decode(str));

class TornW3bReceiptResponse {
  TornW3bReceiptResponseData receipt;
  String receiptUrl;
  TornW3bReceiptWarnings warnings;

  TornW3bReceiptResponse({
    required this.receipt,
    required this.receiptUrl,
    required this.warnings,
  });

  factory TornW3bReceiptResponse.fromJson(Map<String, dynamic> json) => TornW3bReceiptResponse(
        receipt: TornW3bReceiptResponseData.fromJson(json['receipt'] ?? {}),
        receiptUrl: json['receiptURL'] ?? '',
        warnings: TornW3bReceiptWarnings.fromJson(json['warnings'] ?? {}),
      );
}

class TornW3bReceiptResponseData {
  List<TornW3bReceiptResponseItem> items;
  int totalValue;

  TornW3bReceiptResponseData({
    this.items = const [],
    this.totalValue = 0,
  });

  factory TornW3bReceiptResponseData.fromJson(Map<String, dynamic> json) => TornW3bReceiptResponseData(
        items: json['items'] == null
            ? []
            : List<TornW3bReceiptResponseItem>.from(
                json['items'].map((x) => TornW3bReceiptResponseItem.fromJson(x)),
              ),
        totalValue: _asInt(json['total_value']),
      );
}

class TornW3bReceiptResponseItem {
  int itemId;
  String name;
  int quantity;
  int priceUsed;
  int totalValue;

  TornW3bReceiptResponseItem({
    this.itemId = 0,
    this.name = '',
    this.quantity = 0,
    this.priceUsed = 0,
    this.totalValue = 0,
  });

  factory TornW3bReceiptResponseItem.fromJson(Map<String, dynamic> json) => TornW3bReceiptResponseItem(
        itemId: _asInt(json['itemId']),
        name: json['name'] ?? '',
        quantity: _asInt(json['quantity']),
        priceUsed: _asInt(json['priceUsed']),
        totalValue: _asInt(json['totalValue']),
      );
}

class TornW3bReceiptWarnings {
  List<String> notFound;
  List<String> notPriced;

  TornW3bReceiptWarnings({
    this.notFound = const [],
    this.notPriced = const [],
  });

  factory TornW3bReceiptWarnings.fromJson(Map<String, dynamic> json) => TornW3bReceiptWarnings(
        notFound: json['notFound'] == null ? [] : List<String>.from(json['notFound'].map((x) => x.toString())),
        notPriced: json['notPriced'] == null ? [] : List<String>.from(json['notPriced'].map((x) => x.toString())),
      );
}

String tornW3bReceiptUpdateRequestToJson(TornW3bReceiptUpdateRequest data) => json.encode(data.toJson());

class TornW3bReceiptUpdateRequest {
  List<TornW3bReceiptPriceUpdateItem> items;

  TornW3bReceiptUpdateRequest({
    required this.items,
  });

  Map<String, dynamic> toJson() => {
        'items': List<dynamic>.from(items.map((x) => x.toJson())),
      };
}

class TornW3bReceiptPriceUpdateItem {
  int itemId;
  int price;

  TornW3bReceiptPriceUpdateItem({
    required this.itemId,
    required this.price,
  });

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'price': price,
      };
}

TornW3bReceiptUpdateResponse tornW3bReceiptUpdateResponseFromJson(String str) =>
    TornW3bReceiptUpdateResponse.fromJson(json.decode(str));

class TornW3bReceiptUpdateResponse {
  bool success;
  TornW3bReceiptUpdateResponseData data;

  TornW3bReceiptUpdateResponse({
    this.success = false,
    required this.data,
  });

  factory TornW3bReceiptUpdateResponse.fromJson(Map<String, dynamic> json) => TornW3bReceiptUpdateResponse(
        success: json['success'] ?? false,
        data: TornW3bReceiptUpdateResponseData.fromJson(json['data'] ?? {}),
      );
}

class TornW3bReceiptUpdateResponseData {
  TornW3bReceiptResponseData receipt;
  String receiptUrl;

  TornW3bReceiptUpdateResponseData({
    required this.receipt,
    this.receiptUrl = '',
  });

  factory TornW3bReceiptUpdateResponseData.fromJson(Map<String, dynamic> json) => TornW3bReceiptUpdateResponseData(
        receipt: TornW3bReceiptResponseData.fromJson(json['receipt'] ?? {}),
        receiptUrl: json['receiptURL'] ?? '',
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
    final normalized = value.replaceAll(',', '').replaceAll(r'$', '').trim();

    if (normalized.isEmpty) {
      return 0;
    }

    final asInt = int.tryParse(normalized);
    if (asInt != null) {
      return asInt;
    }

    final asDouble = double.tryParse(normalized);
    if (asDouble != null) {
      return asDouble.round();
    }

    final digitsOnly = normalized.replaceAll(RegExp(r'[^0-9.-]'), '');
    final fallbackInt = int.tryParse(digitsOnly);
    if (fallbackInt != null) {
      return fallbackInt;
    }

    final fallbackDouble = double.tryParse(digitsOnly);
    if (fallbackDouble != null) {
      return fallbackDouble.round();
    }

    return 0;
  }

  return 0;
}
