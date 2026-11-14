import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torn_pda/models/chat/chat_alerts.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/widgets/alerts/alert_cards.dart';
import 'package:torn_pda/widgets/chat/chat_appearance_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_help.dart';
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

  test('accessibility help goes first only when the phone needs it', () {
    expect(chatHelpGroupsOf({}).last, ChatHelpGroup.accessibility);
    final needed = chatHelpGroupsOf({ChatNeed.largeText});
    expect(needed.first, ChatHelpGroup.accessibility);
    expect(needed.toSet(), ChatHelpGroup.values.toSet());
    expect(needed, hasLength(ChatHelpGroup.values.length));
  });

  test('help entries that fit the phone come first in their group', () {
    final entries = chatHelpOf(ChatHelpGroup.accessibility, {ChatNeed.largeText});
    expect(entries.first.needs, contains(ChatNeed.largeText));
  });
}
