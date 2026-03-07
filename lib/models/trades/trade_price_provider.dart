enum TradePriceProvider {
  none,
  tornExchange,
  tornW3b,
}

TradePriceProvider tradePriceProviderFromStorage(String value) {
  switch (value) {
    case 'tornExchange':
      return TradePriceProvider.tornExchange;
    case 'tornW3b':
      return TradePriceProvider.tornW3b;
    default:
      return TradePriceProvider.none;
  }
}

extension TradePriceProviderExtension on TradePriceProvider {
  String get storageValue {
    switch (this) {
      case TradePriceProvider.none:
        return 'none';
      case TradePriceProvider.tornExchange:
        return 'tornExchange';
      case TradePriceProvider.tornW3b:
        return 'tornW3b';
    }
  }

  String get label {
    switch (this) {
      case TradePriceProvider.none:
        return 'None';
      case TradePriceProvider.tornExchange:
        return 'Torn Exchange';
      case TradePriceProvider.tornW3b:
        return 'TornW3B';
    }
  }

  String get shortLabel {
    switch (this) {
      case TradePriceProvider.none:
        return '';
      case TradePriceProvider.tornExchange:
        return 'TE';
      case TradePriceProvider.tornW3b:
        return 'W3B';
    }
  }

  bool get supportsProviderProfit => this == TradePriceProvider.tornExchange;

  bool get supportsReceiptEditing => this == TradePriceProvider.tornW3b;
}
