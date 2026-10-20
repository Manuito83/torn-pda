import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_share.dart';
import 'package:torn_pda/models/chat/chat_share_out.dart';
import 'package:torn_pda/models/faction/faction_model.dart';
import 'package:torn_pda/pages/chat/chat_conversation_page.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';
import 'package:torn_pda/providers/chat/chat_image_upload.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/widgets/chaining/share_attack_options.dart';
import 'package:torn_pda/widgets/chat/chat_share_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

import 'chat_fakes.dart';

const _share = MethodChannel('tornpda.share');

ChatMessage _at(String text, DateTime at, {String name = 'Alpha', bool system = false}) => ChatMessage(
  id: text,
  roomId: 'faction',
  sender: ChatUser(id: 1, name: name),
  content: text,
  createdAt: at,
  isSystem: system,
);

Future<List<String>> _composer(WidgetTester tester) async {
  final sent = <String>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: ChatComposer(roomName: 'Faction', roomId: 'faction', enabled: true, onSend: sent.add),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return sent;
}

String _box(WidgetTester tester) => tester.widget<TextField>(find.byType(TextField).first).controller!.text;

void main() {
  useTempPathProvider();

  tearDown(() {
    ChatShareIn.pending.value = null;
    NativeChat.prefs.imageHost = ChatImageHost.imgur;
    NativeChat.debugCanShareToFaction = null;
    NativeChat.closeQuickWindow();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_share, null);
  });

  group('outgoing', () {
    test('outgoing format and order', () {
      expect(
        ChatShared.outgoing([
          _at('second', DateTime.utc(2026, 10, 14, 9, 30), name: 'Bravo'),
          _at('first', DateTime.utc(2026, 10, 14, 9, 5)),
        ]),
        '[09:05 TCT] Alpha: first\n[09:30 TCT] Bravo: second',
      );
      expect(ChatShared.outgoing([_at('hi', DateTime.utc(2026, 10, 14, 22, 15).toLocal())]), '[22:15 TCT] Alpha: hi');
      expect(
        ChatShared.outgoing([
          _at('late', DateTime.utc(2026, 10, 13, 23, 58)),
          _at('early', DateTime.utc(2026, 10, 14, 0, 2)),
        ]),
        '[Oct 13 23:58 TCT] Alpha: late\n[Oct 14 00:02 TCT] Alpha: early',
      );
    });

    test('drops reply quotes and markup, system lines have no name', () {
      final text = ChatShared.outgoing([
        _at('> Bravo: hello\n**yes** please', DateTime.utc(2026, 1, 1, 10)),
        _at('Bravo joined', DateTime.utc(2026, 1, 1, 10, 1), system: true),
      ]);
      expect(text, '[10:00 TCT] Alpha: yes please\n[10:01 TCT] Bravo joined');
    });

    test('a player goes with level, status and link', () {
      const now = 1000000;
      expect(
        ChatShareOut.player(name: 'Bravo', id: 7, level: 90, state: 'Okay', now: now),
        'Bravo [7], lvl 90, Okay\nhttps://www.torn.com/profiles.php?XID=7',
      );
      expect(
        ChatShareOut.player(name: 'Bravo', id: 7, state: 'Hospital', until: now + 7500, now: now).split('\n').first,
        'Bravo [7], Hospital, out in 2h 5m',
      );
      expect(ChatShareOut.player(name: 'Bravo', id: 7, level: 0, now: now).split('\n').first, 'Bravo [7], Unknown');
      expect(ChatShareOut.condition(state: 'Hospital', until: now - 5, now: now), 'Hospital');
      expect(
        ChatShareOut.condition(state: 'Traveling', description: 'Traveling to Mexico', until: now + 480, now: now),
        'Traveling to Mexico, lands in 8m',
      );
      expect(ChatShareOut.condition(state: 'Abroad', description: 'In Mexico', now: now), 'In Mexico');
    });

    test('a foreign stock goes with price and age', () {
      String stock(int cost, Duration age) =>
          ChatShareOut.foreignStock(item: 'Xanax', country: 'Mexico', quantity: 12, cost: cost, age: age);
      expect(stock(830000, const Duration(minutes: 3)), 'Xanax in Mexico: 12 at \$830k (3m ago)');
      expect(stock(950, const Duration(seconds: 20)), 'Xanax in Mexico: 12 at \$950 (just now)');
      expect(stock(950, const Duration(hours: 5)), endsWith('(5h ago)'));
      expect(stock(950, const Duration(days: 2)), endsWith('(2d ago)'));
      expect(ChatShareOut.money(1240000), '\$1.2m');
      expect(ChatShareOut.money(45000), '\$45k');
    });

    test('a ranked war goes with score, lead, chains and time', () {
      final text = ChatShareOut.rankedWar(
        warId: '12',
        left: ('Alpha', 1200, 40),
        right: ('Bravo', 980, 12),
        target: 5000,
        time: ['War #12, started Mon @ 14:00', ''],
      );
      expect(
        text,
        'Ranked war #12: Alpha 1,200 vs Bravo 980\nLead 220 of 5,000 needed\nChain 40 vs 12\n'
        'War #12, started Mon @ 14:00',
      );
    });

    testWidgets('menu share text', (tester) async {
      NativeChat.prefs.introSeen = true;
      final calls = <Map>[];
      const channel = MethodChannel('dev.fluttercommunity.plus/share');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call.arguments as Map);
        return 'dev.fluttercommunity.plus/share/unavailable';
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
      final source = FakeChatSource(sync: false);
      final chat = ChatController(source, ChatPrefs());
      source.emit(const ChatReadyEvent(99));
      await tester.pump();
      await tester.pumpWidget(
        MaterialApp(
          builder: BotToastInit(),
          navigatorObservers: [BotToastNavigatorObserver()],
          home: ChangeNotifierProvider<ChatController>.value(
            value: chat,
            child: const ChatConversationPage(roomId: 'faction'),
          ),
        ),
      );
      await tester.pump();
      source.emit(
        ChatHistoryEvent(
          'faction',
          [
            chatMessage(
              'm1',
              'faction',
              sender: 3,
              name: 'Charlie',
              text: 'raid at **noon**',
              at: DateTime.utc(2026, 10, 14, 11, 40),
            ),
          ],
          hasOlder: false,
          isOlderPage: false,
        ),
      );
      await tester.pump();

      await tester.longPress(find.textContaining('raid at', findRichText: true));
      await tester.pump();
      await tester.tap(find.byTooltip('Share'));
      await tester.pumpAndSettle();
      expect(calls.single['text'], '[11:40 TCT] Charlie: raid at noon');
      expect(find.byTooltip('Cancel selection'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
      chat.dispose();
    });
  });

  group('incoming', () {
    test('reads text, image and the first Torn link', () {
      final shared = ChatShared.from({'type': 'image/png', 'text': ' look ', 'image': 'content://x/1'})!;
      expect((shared.text, shared.image, shared.type), ('look', 'content://x/1', 'image/png'));
      expect(ChatShared.from(null), isNull);
      expect(ChatShared.from('text'), isNull);
      expect(ChatShared.from({'type': 'text/plain', 'text': '  '}), isNull);

      const text = 'see https://example.com and https://www.torn.com/profiles.php?XID=1 now';
      expect(const ChatShared(text: text).tornLink, 'https://www.torn.com/profiles.php?XID=1');
      expect(const ChatShared(text: 'https://nottorn.com/x').tornLink, isNull);
      expect(const ChatShared(text: 'no link').tornLink, isNull);
    });

    test('image type comes from the file signature', () {
      expect(ChatShared.imageExtension([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0]), 'png');
      expect(ChatShared.imageExtension([0xFF, 0xD8, 0xFF, 0xE0]), 'jpg');
      expect(ChatShared.imageExtension('GIF89a..'.codeUnits), 'gif');
      expect(ChatShared.imageExtension('RIFF\x00\x00\x00\x00WEBPVP8 '.codeUnits), 'webp');
      expect(ChatShared.imageExtension('RIFF\x00\x00\x00\x00WAVE'.codeUnits), isNull);
      expect(ChatShared.imageExtension('<?xml'.codeUnits), isNull);
      expect(ChatShared.imageExtension(const []), isNull);
    });

    test('readImage deletes the cache file', () async {
      final dir = (await getTemporaryDirectory()).path;
      final file = File('$dir/chat_share/shared');
      final other = File('$dir/chat_share/keep')..createSync(recursive: true);
      Map? asked;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_share, (call) async {
        asked = call.arguments as Map;
        file.writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xE0]);
        return null;
      });
      final bytes = await ChatShareIn.readImage('content://other.app/1');
      expect(asked, {'uri': 'content://other.app/1'});
      expect(ChatShared.imageExtension(bytes), 'jpg');
      expect(file.existsSync(), isFalse);
      expect(other.existsSync(), isTrue);
    });

    testWidgets('shared link fills its room box', (tester) async {
      ChatShareIn.offer('global', const ChatShared(text: 'hi'));
      final sent = await _composer(tester);
      expect(_box(tester), isEmpty);
      expect(ChatShareIn.pending.value, isNotNull);

      ChatShareIn.offer('faction', const ChatShared(text: 'https://www.torn.com/x'));
      await tester.pumpAndSettle();
      expect(_box(tester).trim(), 'https://www.torn.com/x');
      expect(sent, isEmpty);
      expect(ChatShareIn.pending.value, isNull);
    });

    testWidgets('a share older than two minutes is dropped', (tester) async {
      ChatShareIn.pending.value = (
        roomId: 'faction',
        shared: const ChatShared(text: 'old'),
        at: DateTime.now().subtract(const Duration(minutes: 3)),
      );
      await _composer(tester);
      expect(_box(tester), isEmpty);
      expect(ChatShareIn.pending.value, isNull);
    });

    testWidgets('a shared image asks before uploading', (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        _share,
        (call) async => throw PlatformException(code: 'too_big'),
      );
      NativeChat.prefs.imageHost = ChatImageHost.catbox;
      ChatShareIn.offer('faction', const ChatShared(image: 'content://x/1', type: 'image/png'));
      final sent = await _composer(tester);
      expect(find.text('Upload the shared image?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(_box(tester), isEmpty);
      expect(sent, isEmpty);

      ChatShareIn.offer('faction', const ChatShared(image: 'content://x/1', type: 'image/png'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Upload'));
      await tester.pumpAndSettle();
      expect(find.text('The shared image is over 32 MB'), findsOneWidget);
    });
  });

  group('faction share', () {
    test('attack share to faction', () {
      NativeChat.shareToFaction('Target: Alpha [1]\nURL: u\n');
      expect(ChatShareIn.pending.value!.roomId, 'faction');
      expect(ChatShareIn.pending.value!.shared.text, 'Target: Alpha [1]\nURL: u');
      expect(NativeChat.quickWindows.value, ['faction']);

      NativeChat.shareToFaction('Target: Bravo [2]');
      expect(NativeChat.quickWindows.value, ['faction']);
      expect(ChatShareIn.pending.value!.shared.text, 'Target: Bravo [2]');
    });

    testWidgets('faction chat button only when allowed', (tester) async {
      final settings = SettingsProvider()..ffScouterEnabledStatusRemoteConfig = false;
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SettingsProvider>.value(value: settings),
            ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => ShareAttackDialog(member: Member(memberId: 42, name: 'Bravo')),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      Future<void> open() async {
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
      }

      NativeChat.debugCanShareToFaction = false;
      await open();
      expect(find.text('FACTION\nCHAT'), findsNothing);
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();

      NativeChat.debugCanShareToFaction = true;
      await open();
      await tester.tap(find.text('FACTION\nCHAT'));
      await tester.pumpAndSettle();
      expect(find.byType(ShareAttackDialog), findsNothing);
      expect(settings.shareOptions, isEmpty);
      expect(ChatShareIn.pending.value!.roomId, 'faction');
      expect(
        ChatShareIn.pending.value!.shared.text,
        'Target: Bravo [42]\nURL: https://www.torn.com/page.php?sid=attack&user2ID=42',
      );
      expect(NativeChat.quickWindows.value, ['faction']);
    });
  });
}
