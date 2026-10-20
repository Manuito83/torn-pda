import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torn_pda/pages/chat/chat_settings_page.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/widgets/chat/chat_theme.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

import 'chat_fakes.dart';

Finder _barTitle(String title) => find.descendant(of: find.byType(AppBar), matching: find.text(title));

void main() {
  useTempPathProvider();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  tearDown(() {
    NativeChat.prefs
      ..setMentions(true)
      ..setTicker(true)
      ..setTickerTop(true)
      ..setAlertNotify(true)
      ..setQuietHours(false);
  });

  Future<void> openSettings(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const MaterialApp(home: ChatTheme(child: ChatSettingsPage())),
      ),
    );
  }

  testWidgets('each row opens its page', (tester) async {
    await openSettings(tester);
    for (final title in [
      'Open the chat from',
      'Alerts',
      'Rooms',
      'Appearance',
      'Messages & links',
      'Writing & actions',
      'People',
      'Faction room',
    ]) {
      await tester.tap(find.widgetWithText(ListTile, title));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(_barTitle(title), findsOneWidget, reason: title);
      expect(tester.takeException(), isNull, reason: title);
      await tester.pageBack();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }
  });

  testWidgets('alerts summary follows mentions, ticker and quiet hours', (tester) async {
    NativeChat.prefs
      ..setMentions(false)
      ..setTickerTop(false)
      ..setQuietHours(true);
    await openSettings(tester);
    expect(find.textContaining('Mentions off - Ticker bottom - Quiet'), findsOneWidget);

    NativeChat.prefs
      ..setTicker(false)
      ..setAlertNotify(false);
    await tester.pump();
    expect(find.text('Mentions off - Ticker off'), findsOneWidget);
  });

  testWidgets('chat settings stays under alerts', (tester) async {
    late NavigatorState navigator;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            navigator = Navigator.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    showChatSettings(navigator, alerts: true);
    await tester.pumpAndSettle();
    expect(_barTitle('Alerts'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(_barTitle('Chat settings'), findsOneWidget);
  });
}
