class TradeSyncItem {
  int itemId;
  String name;
  int quantity;
  int price;
  int totalPrice;
  int providerProfit;
  bool hasProviderProfit;

  TradeSyncItem({
    this.itemId = 0,
    this.name = '',
    this.quantity = 0,
    this.price = 0,
    this.totalPrice = 0,
    this.providerProfit = 0,
    this.hasProviderProfit = false,
  });
}

class TradeSyncReceiptRequestItem {
  int itemId;
  String name;
  int quantity;
  int? price;

  TradeSyncReceiptRequestItem({
    this.itemId = 0,
    this.name = '',
    this.quantity = 0,
    this.price,
  });
}

class TradeSyncReceiptRequest {
  String ownerUsername;
  int ownerUserId;
  String sellerUsername;
  int sellerUserId;
  int tradeId;
  List<TradeSyncReceiptRequestItem> items;

  TradeSyncReceiptRequest({
    this.ownerUsername = '',
    this.ownerUserId = 0,
    this.sellerUsername = '',
    this.sellerUserId = 0,
    this.tradeId = 0,
    this.items = const [],
  });
}

class TradeSyncReceiptData {
  String receiptId;
  String message;
  String url;
  int totalValue;
  bool canEdit;
  bool serverError;
  String serverErrorReason;
  List<TradeSyncItem> items;

  TradeSyncReceiptData({
    this.receiptId = '',
    this.message = '',
    this.url = '',
    this.totalValue = 0,
    this.canEdit = false,
    this.serverError = false,
    this.serverErrorReason = '',
    this.items = const [],
  });
}
