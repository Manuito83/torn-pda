import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:torn_pda/utils/firebase_firestore.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

// Torn allows 100 city shop purchases per day (all shops together), resetting at 00:00 TCT
// The browser reports each buyShopItem response here; at the limit, city shop alerts are muted until reset
class CityShopDailyLimit {
  static const int limit = 100;

  static String tctDay(DateTime nowUtc) {
    return "${nowUtc.year}-${nowUtc.month.toString().padLeft(2, "0")}-${nowUtc.day.toString().padLeft(2, "0")}";
  }

  static int nextTctMidnightMs() {
    final now = DateTime.now().toUtc();
    return DateTime.utc(now.year, now.month, now.day + 1).millisecondsSinceEpoch;
  }

  static Future<void> onPurchaseReport(Map<dynamic, dynamic> data) async {
    if (!await Prefs().getCityShopAutoPauseEnabled()) return;
    final profile = await FirestoreHelper().getUserProfile();
    if (profile == null || profile.cityShopRestockNotification != true) return;

    final now = DateTime.now().toUtc();
    if (profile.cityShopMutedUntil > now.millisecondsSinceEpoch) return;

    final bool success = data["success"] == true;
    final String text = (data["text"] ?? "").toString().toLowerCase();
    final int amount = int.tryParse("${data["amount"]}") ?? 0;

    bool reached = text.contains("maximum of") && text.contains("today");
    if (success && amount > 0) {
      final day = tctDay(now);
      final sameDay = await Prefs().getCityShopBoughtDay() == day;
      final count = (sameDay ? await Prefs().getCityShopBoughtCount() : 0) + amount;
      await Prefs().setCityShopBought(day: day, count: count);
      if (count >= limit) reached = true;
    }
    if (!reached) return;

    final ok = await FirestoreHelper().setCityShopMutedUntil(nextTctMidnightMs());
    if (!ok) return;
    BotToast.showText(
      text: "City shop alerts paused until 00:00 TCT (daily purchase limit reached)",
      textStyle: const TextStyle(fontSize: 14, color: Colors.white),
      contentColor: Colors.green[800]!,
      duration: const Duration(seconds: 5),
      contentPadding: const EdgeInsets.all(10),
      clickClose: true,
    );
  }
}
