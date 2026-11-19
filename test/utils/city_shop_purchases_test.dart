import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:torn_pda/models/firebase_user_model.dart';
import 'package:torn_pda/utils/city_shop_purchases.dart';
import 'package:torn_pda/utils/sembast_db.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

import '../chat/chat_fakes.dart';

void main() {
  useTempPathProvider();
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  test('two purchases reported together both count', () async {
    await PrefsDatabase.clearAll();
    await Prefs().setCityShopAutoPauseEnabled(true);
    final purchases = CityShopPurchases(
      profile: () async => FirebaseUserModel()..cityShopRestockNotification = true,
      mute: (_) async => true,
    );

    await Future.wait([
      purchases.report({'success': true, 'amount': 3}),
      purchases.report({'success': true, 'amount': 4}),
    ]);

    expect(await Prefs().getCityShopBoughtCount(), 7);
  });
}
