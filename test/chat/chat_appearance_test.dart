import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torn_pda/models/chat/chat_colors.dart';
import 'package:torn_pda/models/chat/chat_player_color.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/chat/chat_color_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_theme.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

import 'chat_fakes.dart';

ThemeData _pda(Brightness brightness) =>
    ThemeData(primarySwatch: Colors.blueGrey, useMaterial3: false, brightness: brightness);

double _contrast(Color a, Color b) => ChatPlayerColor.contrast(a, b);

void main() {
  useTempPathProvider();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    NativeChat.prefs.colors.value = const {};
  });

  tearDown(() => NativeChat.prefs.colors.value = const {});

  test('text scale snaps, clamps and persists', () async {
    final prefs = ChatPrefs()..setTextScale(0.8 + (1.6 - 0.8) / 8);
    expect(prefs.textScale, 0.9);
    prefs.setTextScale(0.5);
    expect(prefs.textScale, 0.8);
    final again = ChatPrefs();
    await again.load();
    expect(again.textScale, 0.8);
    await Prefs().setNativeChatTextScale(3);
    await again.load();
    expect(again.textScale, 1.6);
  });

  test('list text size snaps, clamps and persists apart from the chat one', () async {
    final prefs = ChatPrefs()..setListTextScale(1.34);
    expect(prefs.listTextScale, 1.3);
    expect(prefs.textScale, 1);
    prefs.setListTextScale(9);
    expect(prefs.listTextScale, 1.6);
    final again = ChatPrefs();
    await again.load();
    expect(again.listTextScale, 1.6);
  });

  test('list reply count keeps saved values and fits out of range ones', () async {
    final prefs = ChatPrefs();
    for (final (saved, shown) in [(3, 3), (5, 5), (10, 10), (14, 14), (0, 1), (99, 20)]) {
      await Prefs().setNativeChatListReplyCount(saved);
      await prefs.load();
      expect(prefs.listReplyCount, shown, reason: '$saved');
    }
    prefs.setListReplyCount(40);
    expect(prefs.listReplyCount, 20);
  });

  test('colors json and slots', () {
    const colors = ChatColors({ChatColorSlot.mineBubble: Color(0xFF123456), ChatColorSlot.otherText: Colors.white});
    final back = ChatColors.fromJson(colors.toJson());
    expect(back[ChatColorSlot.mineBubble], const Color(0xFF123456));
    expect(back[ChatColorSlot.otherText]!.toARGB32(), Colors.white.toARGB32());
    expect(back[ChatColorSlot.background], isNull);
    expect(ChatColors.fromJson({'mineBubble': 'red', 'nope': 1}).isEmpty, isTrue);
    expect(ChatColors.fromJson('garbage').isEmpty, isTrue);

    final set = const ChatColors().withSlot(ChatColorSlot.background, Colors.black);
    expect(set[ChatColorSlot.background], Colors.black);
    expect(set.withSlot(ChatColorSlot.background, null).isEmpty, isTrue);
  });

  test('auto text contrast on custom bubbles', () {
    for (final theme in [_pda(Brightness.light), _pda(Brightness.dark)]) {
      for (var hue = 0; hue < 360; hue += 15) {
        for (final lightness in [0.1, 0.3, 0.45, 0.6, 0.9]) {
          final bubble = HSLColor.fromAHSL(1, hue.toDouble(), 0.7, lightness).toColor();
          final palette = ChatColors({
            ChatColorSlot.mineBubble: bubble,
            ChatColorSlot.otherBubble: bubble,
          }).resolve(theme.colorScheme, theme.scaffoldBackgroundColor);
          expect(_contrast(palette.mineText, bubble), greaterThanOrEqualTo(4.5));
          expect(_contrast(palette.otherText, bubble), greaterThanOrEqualTo(4.5));
        }
      }
    }
    final light = _pda(Brightness.light).colorScheme;
    expect(
      const ChatColors({ChatColorSlot.mineBubble: Colors.yellow}).resolve(light, Colors.white).mineText,
      Colors.black,
    );
    final picked = const ChatColors({
      ChatColorSlot.mineBubble: Colors.yellow,
      ChatColorSlot.mineText: Colors.white,
    }).resolve(light, Colors.white);
    expect(picked.mineText, Colors.white);
  });

  test('a player keeps one readable color on any bubble', () {
    final bg = ColorScheme.fromSeed(seedColor: Colors.deepPurple).surfaceContainerHighest;
    expect(ChatPlayerColor.of(2345, bg), ChatPlayerColor.of(2345, bg));
    final backgrounds = [
      for (final b in Brightness.values)
        ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: b).surfaceContainerHighest,
      for (var hue = 0; hue < 360; hue += 20)
        for (final lightness in [0.2, 0.35, 0.45, 0.55, 0.7])
          HSLColor.fromAHSL(1, hue.toDouble(), 0.6, lightness).toColor(),
    ];
    for (final bubble in backgrounds) {
      for (var id = 1; id < 3000; id += 7) {
        expect(_contrast(ChatPlayerColor.of(id * 977, bubble), bubble), greaterThanOrEqualTo(4.5));
      }
    }
  });

  test('blackOrWhite always reaches 4.5:1', () {
    for (var v = 0; v <= 255; v += 5) {
      final bg = Color.fromARGB(255, v, (v * 3) % 256, 255 - v);
      expect(_contrast(ChatPlayerColor.blackOrWhite(bg), bg), greaterThanOrEqualTo(4.5));
    }
  });

  test('the dark chat theme follows PDA and keeps custom colors', () {
    for (final extra in [false, true]) {
      final theme = chatDarkTheme(_pda(Brightness.dark), extra: extra);
      final palette = const ChatColors().resolve(theme.colorScheme, theme.scaffoldBackgroundColor);
      expect(palette.otherBubble, isNot(palette.background));
      expect(palette.mineBubble, isNot(palette.background));
      expect(_contrast(palette.otherText, palette.otherBubble), greaterThanOrEqualTo(4.5));
      expect(_contrast(palette.mineText, palette.mineBubble), greaterThanOrEqualTo(4.5));
      const custom = ChatColors({ChatColorSlot.background: Colors.indigo, ChatColorSlot.otherBubble: Colors.teal});
      final mine = custom.resolve(theme.colorScheme, theme.scaffoldBackgroundColor);
      expect((mine.background, mine.otherBubble), (Colors.indigo, Colors.teal));
    }
  });

  testWidgets('settings warn about hard to read text and fix it', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: _pda(Brightness.light),
        home: const Scaffold(body: SingleChildScrollView(child: ChatColorSettings())),
      ),
    );
    expect(find.textContaining('hard to read'), findsNothing);

    NativeChat.prefs.setChatColors(
      'light',
      const ChatColors({ChatColorSlot.mineBubble: Colors.yellow, ChatColorSlot.mineText: Colors.white}),
    );
    await tester.pump();
    await tester.tap(find.text('Custom colors'));
    await tester.pumpAndSettle();
    expect(find.textContaining('My text is hard to read'), findsOneWidget);
    await tester.ensureVisible(find.text('Use black'));
    await tester.tap(find.text('Use black'));
    await tester.pump();
    expect(NativeChat.prefs.colorsFor('light')[ChatColorSlot.mineText], Colors.black);
    expect(find.textContaining('hard to read'), findsNothing);

    await tester.ensureVisible(find.widgetWithText(TextButton, 'Reset'));
    await tester.tap(find.widgetWithText(TextButton, 'Reset'));
    await tester.pump();
    expect(NativeChat.prefs.colorsFor('light').isEmpty, isTrue);
  });
}
