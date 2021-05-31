import 'package:intl/intl.dart';

String formatProfit(int moneyInput) {
  final profitCurrencyHigh = new NumberFormat("#,##0.0", "en_US");
  final costCurrencyLow = new NumberFormat("#,##0", "en_US");
  String profitFormat;

  // Money standards to reduce string length (adding two zeros for .00)
  final billion = 1000000000;
  final million = 1000000;
  final thousand = 1000;

  // Profit
  if (moneyInput < -billion || moneyInput > billion) {
    final profitBillion = moneyInput / billion;
    profitFormat = '${profitCurrencyHigh.format(profitBillion)}B';
  } else if (moneyInput < -million || moneyInput > million) {
    final profitMillion = moneyInput / million;
    profitFormat = '${profitCurrencyHigh.format(profitMillion)}M';
  } else if (moneyInput < -thousand || moneyInput > thousand) {
    final profitThousand = moneyInput / thousand;
    profitFormat = '${profitCurrencyHigh.format(profitThousand)}K';
  } else {
    profitFormat = '${costCurrencyLow.format(moneyInput)}';
  }
  return profitFormat;
}