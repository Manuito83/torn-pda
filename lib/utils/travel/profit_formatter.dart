String formatProfit({int? inputInt, double? inputDouble}) {
  double? moneyInput = 0;
  if (inputInt != null) {
    moneyInput = inputInt.toDouble();
  } else {
    moneyInput = inputDouble;
  }

  double moneyAbs = moneyInput!.abs();
  if (moneyAbs >= 999 && moneyAbs < 99999) {
    return "${(moneyInput / 1000).toStringAsFixed(1)}K".replaceAll(".0K", "K");
  } else if (moneyAbs >= 99999 && moneyAbs < 999999) {
    return "${(moneyInput / 1000).toStringAsFixed(0)}K".replaceAll(".0K", "K").replaceAll("1000K", "1M");
  } else if (moneyAbs >= 999999 && moneyAbs < 999999999) {
    return "${(moneyInput / 1000000).toStringAsFixed(1)}M".replaceAll(".0M", "M").replaceAll("1000M", "1B");
  } else if (moneyAbs >= 999999999) {
    return "${(moneyInput / 1000000000).toStringAsFixed(1)}B".replaceAll(".0B", "B");
  } else {
    return moneyInput.toString();
  }
}
