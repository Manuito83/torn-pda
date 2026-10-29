import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torn_pda/models/chat/chat_alerts.dart';
import 'package:torn_pda/pages/chat/settings/chat_settings_subpage.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/widgets/alerts/alert_cards.dart';
import 'package:torn_pda/widgets/chat/chat_alerts_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_appearance_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_intro_sheet.dart';
import 'package:torn_pda/widgets/chat/chat_theme.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

import 'chat_fakes.dart';

SemanticsNode _node(Pattern label) => find.semantics.byLabel(label).evaluate().single;

Tristate _toggled(Pattern label) => _node(label).getSemanticsData().flagsCollection.isToggled;

void main() {
  useTempPathProvider();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  tearDown(() {
    NativeChat.prefs
      ..setTextScale(1)
      ..setTickerLevel('faction', ChatAlertLevel.all);
  });

  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view
      ..physicalSize = const Size(412, 3000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: MaterialApp(home: ChatTheme(child: child)),
      ),
    );
    await tester.pump();
  }

  testWidgets('an alert row is one switch that the screen reader can flip', (tester) async {
    final semantics = tester.ensureSemantics();
    var on = false;
    await pump(
      tester,
      Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => AlertRow(
            title: 'DM notifications',
            subtitle: 'Private messages',
            value: on,
            onChanged: (v) => setState(() => on = v),
          ),
        ),
      ),
    );

    final row = RegExp('DM notifications');
    expect(_toggled(row), Tristate.isFalse);
    expect(_node(row).rect.height, greaterThanOrEqualTo(48));
    tester.semantics.tap(find.semantics.byLabel(row));
    await tester.pump();
    expect(on, isTrue);
    expect(_toggled(row), Tristate.isTrue);
    semantics.dispose();
  });

  testWidgets('each ticker level button names its room', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester, ChatSettingsSubpage(title: 'Ticker', builder: (_) => const [ChatTickerSettings()]));

    tester.semantics.tap(find.semantics.byLabel('Faction: mentions only'));
    await tester.pump();
    expect(NativeChat.prefs.tickerLevel('faction'), ChatAlertLevel.mentions);
    semantics.dispose();
  });

  testWidgets('chat text size slider has a name and steps by 10%', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester, const Scaffold(body: ChatTextSizeSetting()));

    expect(_node('Chat text size').value, '100%');
    tester.semantics.increase(find.semantics.byLabel('Chat text size'));
    await tester.pump();
    expect(NativeChat.prefs.textScale, 1.1);
    expect(_node('Chat text size').value, '110%');
    semantics.dispose();
  });

  group('chat help', () {
    Future<void> openHelp(WidgetTester tester) async {
      await pump(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) =>
                TextButton(onPressed: () => showChatIntro(context, always: true), child: const Text('Help')),
          ),
        ),
      );
      await tester.tap(find.text('Help'));
      await tester.pumpAndSettle();
    }

    double top(WidgetTester tester, String title) => tester.getTopLeft(find.text(title)).dy;

    testWidgets('with large text, accessibility comes first, open, with the text size slider', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await openHelp(tester);

      expect(top(tester, 'Accessibility'), lessThan(top(tester, 'Start here')));
      expect(find.byType(ChatTextSizeSetting), findsOneWidget);
    });

    testWidgets('without accessibility settings, it stays last and closed', (tester) async {
      await openHelp(tester);

      expect(top(tester, 'Accessibility'), greaterThan(top(tester, 'Start here')));
      expect(find.text('Screen readers'), findsNothing);
    });
  });
}
