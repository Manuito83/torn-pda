import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torn_pda/drawer.dart';
import 'package:torn_pda/providers/chain_status_controller.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/widgets/chat/chat_chain_sheets.dart';

import 'chat_fakes.dart';

void main() {
  useTempPathProvider();

  late SettingsProvider settings;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.put(ChainStatusController());
    settings = SettingsProvider();
    routeWithDrawer = true;
    routeName = 'drawer';
  });

  tearDown(Get.reset);

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
          ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(onPressed: () => openChainOptions(context), child: const Text('Panic')),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Panic'));
    await tester.pumpAndSettle();
    expect(find.text('Chain Watcher'), findsOneWidget);
    expect((routeWithDrawer, routeName), (false, 'chain_watcher_options'));
  }

  testWidgets('the arrow closes the options and the route flags come back', (tester) async {
    await open(tester);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Chain Watcher'), findsNothing);
    expect((routeWithDrawer, routeName), (true, 'drawer'));
  });

  testWidgets('the system back does the same', (tester) async {
    await open(tester);
    settings.willPopShouldGoBackStream.add(true);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Chain Watcher'), findsNothing);
    expect((routeWithDrawer, routeName), (true, 'drawer'));
  });
}
