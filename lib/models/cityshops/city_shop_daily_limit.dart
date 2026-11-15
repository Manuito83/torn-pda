// Torn allows 100 city shop purchases per day (all shops together), resetting at 00:00 TCT
const int cityShopDailyLimit = 100;

String tctDay(DateTime nowUtc) {
  return "${nowUtc.year}-${nowUtc.month.toString().padLeft(2, "0")}-${nowUtc.day.toString().padLeft(2, "0")}";
}

int nextTctMidnightMs(DateTime nowUtc) {
  return DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day + 1).millisecondsSinceEpoch;
}

/// Today's count after a buyShopItem response
({int count, bool reached}) cityShopPurchaseResult(
  Map<dynamic, dynamic> response,
  int countToday, {
  int limit = cityShopDailyLimit,
}) {
  final bool success = response["success"] == true;
  final String text = (response["text"] ?? "").toString().toLowerCase();
  final int amount = int.tryParse("${response["amount"]}") ?? 0;

  final bool bought = success && amount > 0;
  final int count = bought ? countToday + amount : countToday;
  final bool toldByTorn = text.contains("maximum of") && text.contains("today");
  return (count: count, reached: toldByTorn || (bought && count >= limit));
}
