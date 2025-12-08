import 'package:intl/intl.dart';

String formatBigNumbers(int moneyInput) {
  final long = NumberFormat("#,##0.0", "en_US");
  final short = NumberFormat("#,##0", "en_US");
  String numberFormatted;

  // Money standards to reduce string length (adding two zeros for .00)
  const billion = 1000000000;
  const million = 1000000;
  const thousand = 1000;

  // Profit
  if (moneyInput <= -billion || moneyInput >= billion) {
    final profitBillion = moneyInput / billion;
    numberFormatted = '${long.format(profitBillion)}B';
  } else if (moneyInput <= -million || moneyInput >= million) {
    final profitMillion = moneyInput / million;
    numberFormatted = '${long.format(profitMillion)}M';
  } else if (moneyInput <= -thousand || moneyInput >= thousand) {
    final profitThousand = moneyInput / thousand;
    numberFormatted = '${long.format(profitThousand)}K';
  } else {
    numberFormatted = short.format(moneyInput);
  }
  return numberFormatted;
}
