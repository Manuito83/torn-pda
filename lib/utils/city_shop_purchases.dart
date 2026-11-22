import 'package:bot_toast/bot_toast.dart';
import 'package:material_ui/material_ui.dart';
import 'package:torn_pda/models/cityshops/city_shop_daily_limit.dart';
import 'package:torn_pda/models/firebase_user_model.dart';
import 'package:torn_pda/utils/firebase_firestore.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

// The browser reports each buyShopItem response here; at the limit, city shop alerts are muted until reset
class CityShopPurchases {
  CityShopPurchases({Future<FirebaseUserModel?> Function()? profile, Future<bool> Function(int untilMs)? mute})
    : _profile = profile ?? (() => FirestoreHelper().getUserProfile()),
      _mute = mute ?? ((untilMs) => FirestoreHelper().setCityShopMutedUntil(untilMs));

  final Future<FirebaseUserModel?> Function() _profile;
  final Future<bool> Function(int untilMs) _mute;
  Future<void> _last = Future.value();

  // In order, so no buy is lost
  Future<void> report(Map<dynamic, dynamic> data) {
    final next = _last.then((_) => _apply(data));
    _last = next.catchError((_) {});
    return next;
  }

  Future<void> _apply(Map<dynamic, dynamic> data) async {
    if (!await Prefs().getCityShopAutoPauseEnabled()) return;
    final profile = await _profile();
    if (profile == null || profile.cityShopRestockNotification != true) return;

    final now = DateTime.now().toUtc();
    if (profile.cityShopMutedUntil > now.millisecondsSinceEpoch) return;

    final day = tctDay(now);
    final countToday = await Prefs().getCityShopBoughtDay() == day ? await Prefs().getCityShopBoughtCount() : 0;
    final result = cityShopPurchaseResult(data, countToday);
    if (result.count != countToday) await Prefs().setCityShopBought(day: day, count: result.count);
    if (!result.reached) return;

    final ok = await _mute(nextTctMidnightMs(now));
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
