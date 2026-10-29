import 'dart:async';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torn_pda/models/chaining/bars_model.dart';
import 'package:torn_pda/models/chat/chat_alerts.dart';
import 'package:torn_pda/models/chat/chat_emoji.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_quote.dart';
import 'package:torn_pda/pages/chat/chat_conversation_page.dart';
import 'package:torn_pda/pages/chat/chat_page.dart';
import 'package:torn_pda/pages/chat/chat_settings_page.dart';
import 'package:torn_pda/pages/chat/settings/chat_alerts_settings_page.dart';
import 'package:torn_pda/pages/chat/settings/chat_appearance_settings_page.dart';
import 'package:torn_pda/pages/chat/settings/chat_faction_settings_page.dart';
import 'package:torn_pda/pages/chat/settings/chat_launcher_settings_page.dart';
import 'package:torn_pda/pages/chat/settings/chat_messages_settings_page.dart';
import 'package:torn_pda/pages/chat/settings/chat_people_settings_page.dart';
import 'package:torn_pda/pages/chat/settings/chat_rooms_settings_page.dart';
import 'package:torn_pda/pages/chat/settings/chat_upload_settings_page.dart';
import 'package:torn_pda/pages/chat/settings/chat_writing_settings_page.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/widgets/chat/chat_big_window.dart';
import 'package:torn_pda/widgets/chat/chat_overlay.dart';
import 'package:torn_pda/widgets/chat/chat_quick_window.dart';
import 'package:torn_pda/widgets/chat/chat_status_sheet.dart';
import 'package:torn_pda/widgets/chat/chat_theme.dart';
import 'package:torn_pda/widgets/chat/chat_ticker.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';
import 'package:torn_pda/widgets/webviews/split_divider.dart';

import 'chat_fakes.dart';

enum _Look { light, dark, bigText, chatText }

// Same base as the app theme in main.dart
ThemeData _theme(bool dark) => ThemeData(
  primarySwatch: Colors.blueGrey,
  useMaterial3: false,
  brightness: dark ? Brightness.dark : Brightness.light,
  cardColor: dark ? Colors.grey[800] : Colors.white,
  appBarTheme: AppBarTheme(backgroundColor: dark ? const Color(0xFF252525) : Colors.blueGrey),
);

// Colors from ThemeProvider, without its storage
class _Theme extends ThemeProvider {
  _Theme(this.look) {
    final dark = look == AppTheme.dark;
    canvas = dark ? Colors.grey[900]! : Colors.grey[50]!;
    secondBackground = dark ? Colors.grey[800]! : Colors.grey[200]!;
    mainText = dark ? Colors.grey[50]! : Colors.black;
    buttonText = dark ? Colors.grey[200]! : Colors.white;
    navSelected = dark ? Colors.blueGrey[600]! : Colors.blueGrey[100]!;
    statusBar = dark ? const Color(0xFF252525) : Colors.blueGrey;
    cardColor = dark ? Colors.grey[800]! : Colors.white;
    cardSurfaceTintColor = cardColor;
  }

  final AppTheme look;

  @override
  AppTheme get currentTheme => look;
}

class _Scene {
  _Scene(this.tester, this.look);

  final WidgetTester tester;
  final _Look look;
  final source = FakeChatSource();
  late final chat = ChatController(source, ChatPrefs());
  final navigator = GlobalKey<NavigatorState>();
  late final theme = _Theme(look == _Look.dark ? AppTheme.dark : AppTheme.light);

  Future<void> pump(Widget home, {bool overlay = false}) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        theme: _theme(look == _Look.dark),
        navigatorObservers: [BotToastNavigatorObserver(), if (overlay) NativeChat.rootWatch],
        builder: (context, child) => Stack(
          children: [
            BotToastInit()(context, child),
            if (overlay) ChatOverlay(navigatorKey: navigator),
          ],
        ),
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeProvider>.value(value: theme),
            ChangeNotifierProvider<ChatController>.value(value: chat),
          ],
          child: ChatTheme(child: home),
        ),
      ),
    );
    await tester.pump();
  }

  void connect() => source
    ..emit(const ChatReadyEvent(99, myName: 'Me'))
    ..emit(const ChatConnectionEvent(ChatConnection.connected))
    ..emit(
      const ChatDmsEvent([
        ChatRoom(
          id: 'dm:7',
          name: 'Bravo',
          type: ChatRoomType.dm,
          peer: ChatUser(id: 7, name: 'Bravo'),
        ),
      ]),
    );

  ChatMessage say(String id, String room, int sender, String name, String text, int minutes) => chatMessage(
    id,
    room,
    sender: sender,
    name: name,
    text: text,
    at: DateTime.now().subtract(Duration(minutes: minutes)),
  );

  // Links, image, reply, mention and own message
  void talk(String room) {
    final first = say('m1', room, 3, 'Alpha', 'Raid at noon, bring Xanax', 30);
    source.emit(
      ChatHistoryEvent(
        room,
        [
          first,
          say(
            'm2',
            room,
            4,
            'Charlie',
            'Profile https://www.torn.com/profiles.php?XID=7 and https://example.com/page',
            20,
          ),
          say('m3', room, 5, 'Delta', 'https://i.imgur.com/abc.png', 15),
          say('m4', room, 6, 'Echo', ChatQuote.reply(first, 'on my way'), 10),
          say('m5', room, 3, 'Alpha', '@Me are you joining?', 5),
          say('m6', room, 99, 'Me', 'Sure, a very long answer that has to wrap over a few lines on a phone', 1),
        ],
        hasOlder: false,
        isOlderPage: false,
      ),
    );
  }

  Future<void> close() async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 31));
    chat.dispose();
  }
}

Future<void> _inbox(_Scene s) async {
  await s.pump(const ChatPage());
  s.connect();
  s.source
    ..emit(ChatPeekEvent('global', s.say('g1', 'global', 3, 'Alpha', 'anyone up for a raid?', 5)))
    ..emit(ChatPeekEvent('dm:7', s.say('d1', 'dm:7', 7, 'Bravo', 'psst', 1)))
    ..emit(const ChatUnreadEvent({'global': 4, 'faction': 2, 'dm:7': 3}));
  await s.tester.pump();
}

Future<void> _conversation(_Scene s) async {
  await s.pump(const ChatConversationPage(roomId: 'global'));
  s.connect();
  s.talk('global');
  await s.tester.pump();
}

Future<void> _composeTools(_Scene s) async {
  // Emoji glyphs are missing in tests
  NativeChat.prefs
    ..quickReplies = ['Price?', 'On my way']
    ..emojiFavorites = [];
  await s.pump(const ChatConversationPage(roomId: 'faction'));
  s.connect();
  s.talk('faction');
  await s.tester.pump();
  await s.tester.tap(find.byTooltip('Quick actions'));
  await s.tester.pumpAndSettle();
}

Future<void> _quickWindow(_Scene s) async {
  await s.pump(
    Scaffold(
      body: Center(
        child: SizedBox(
          width: 340,
          height: 440,
          child: ChatQuickWindow(
            chat: s.chat,
            roomId: 'global',
            onClose: () {},
            onExpand: () {},
            onNext: () {},
            onMinimize: () {},
            sizeLabel: 'M',
            onCycleSize: () {},
          ),
        ),
      ),
    ),
  );
  s.connect();
  s.talk('global');
  await s.tester.pump();
}

Future<void> _bigWindow(_Scene s, String? roomId) async {
  await s.pump(
    Scaffold(
      body: Center(
        child: SizedBox(
          width: 390,
          height: 640,
          child: ChatBigWindowView(
            chat: s.chat,
            roomId: roomId,
            fullscreen: false,
            onClose: () {},
            onMinimize: () {},
            onFullscreen: () {},
          ),
        ),
      ),
    ),
  );
  s.connect();
  s.source.emit(const ChatUnreadEvent({'global': 4, 'faction': 2, 'dm:7': 3}));
  s.talk('global');
  await s.tester.pump();
}

Future<void> _bubble(_Scene s) async {
  NativeChat.minimized.value = const [ChatMinimized('faction', window: true), ChatMinimized('dm:7', window: true)];
  await s.pump(const Scaffold(), overlay: true);
  await s.tester.pump(const Duration(milliseconds: 400));
}

Future<void> _ticker(_Scene s) async {
  final prefs = ChatPrefs()
    ..tickerLevels = {
      for (final group in ['dm', 'faction', 'company', 'global', 'trade']) group: ChatAlertLevel.all,
    };
  await s.pump(
    Scaffold(
      body: ChatTicker(chat: s.chat, prefs: prefs, onOpen: (_) {}),
    ),
  );
  s.connect();
  for (final (id, room, user, name, text) in [
    ('t1', 'dm:7', 7, 'Bravo', 'psst, are you there?'),
    ('t2', 'faction', 3, 'Alpha', 'Raid in five minutes'),
    ('t3', 'global', 4, 'Echo', 'Me are you there?'),
  ]) {
    s.source.emit(ChatMessageEvent(chatMessage(id, room, sender: user, name: name, text: text, at: DateTime.now())));
  }
  await s.tester.pump();
  await s.tester.pump(const Duration(milliseconds: 300));
  await s.tester.pump(const Duration(milliseconds: 300));
}

Future<void> _statusSheet(_Scene s) async {
  final fetch = chatStatusFetch;
  addTearDown(() => chatStatusFetch = fetch);
  chatStatusFetch = () async => BarsStatusCooldownsModel(
    serverTime: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    energy: PersonalBars(current: 95, maximum: 150),
    nerve: PersonalBars(current: 20, maximum: 55),
    happy: PersonalBars(current: 4000, maximum: 5000),
    life: PersonalBars(current: 7000, maximum: 7500),
    status: Status(state: 'Okay', until: 0),
    travel: Travel(destination: 'Torn', timestamp: 0),
    cooldowns: Cooldowns(drug: 600, medical: 0, booster: 3600),
  );
  await s.pump(const Scaffold());
  unawaited(showChatStatusSheet(s.navigator.currentContext!, (_) {}));
  await s.tester.pumpAndSettle();
}

Future<void> Function(_Scene) _page(Widget page) => (s) async {
  await s.pump(page);
  await s.tester.pump(const Duration(milliseconds: 500));
};

final _screens = <String, Future<void> Function(_Scene)>{
  'chat list': _inbox,
  'conversation': _conversation,
  'compose tools': _composeTools,
  'quick window': _quickWindow,
  'big window list': (s) => _bigWindow(s, null),
  'big window room': (s) => _bigWindow(s, 'global'),
  'bubble': _bubble,
  'ticker': _ticker,
  'status sheet': _statusSheet,
  'settings': _page(const ChatSettingsPage()),
  'settings launcher': _page(const ChatLauncherSettingsPage()),
  'settings alerts': _page(const ChatAlertsSettingsPage()),
  'settings rooms': _page(const ChatRoomsSettingsPage()),
  'settings appearance': _page(const ChatAppearanceSettingsPage()),
  'settings messages': _page(const ChatMessagesSettingsPage()),
  'settings writing': _page(const ChatWritingSettingsPage()),
  'settings message actions': _page(const ChatMessageActionsSettingsPage()),
  'settings people': _page(const ChatPeopleSettingsPage()),
  'settings ignored': _page(const ChatIgnoredPage()),
  'settings faction': _page(const ChatFactionSettingsPage()),
  'settings upload': _page(const ChatUploadSettingsPage()),
};

final _guidelines = <String, AccessibilityGuideline>{
  'android tap targets': androidTapTargetGuideline,
  'ios tap targets': iOSTapTargetGuideline,
  'labeled tap targets': labeledTapTargetGuideline,
  'text contrast': textContrastGuideline,
};

const _withMessages = {'conversation', 'compose tools', 'quick window', 'big window room', 'ticker'};

// Test glyphs are wider than real ones
Future<void> _loadRoboto() async {
  final cache = Platform.environment['FLUTTER_ROOT'] != null
      ? '${Platform.environment['FLUTTER_ROOT']}/bin/cache'
      : File(Platform.resolvedExecutable).parent.parent.parent.parent.path;
  final loader = FontLoader('Roboto');
  for (final weight in ['Regular', 'Medium', 'Bold']) {
    final bytes = File('$cache/artifacts/material_fonts/Roboto-$weight.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

// Known failures, remove an entry once fixed
final _known = <String, String>{};

void main() {
  useTempPathProvider();
  setUpAll(_loadRoboto);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    NativeChat.prefs
      ..introSeen = true
      ..inAppEnabled = true
      ..launcher = ChatLauncher.bubble
      ..ticker = true
      ..bubbleSpot = []
      ..windows = []
      ..bigWindow = []
      ..pinned = []
      ..muted = {}
      ..hiddenRooms = {}
      ..drafts = {}
      ..savedMessages = []
      ..pinnedMessages = {}
      ..markedUnread = {}
      ..quickReplies = []
      ..emojiFavorites = [...ChatEmoji.defaultFavorites];
    NativeChat.keyValid.value = true;
    NativeChat.quickWindows.value = const [];
    NativeChat.minimized.value = const [];
    NativeChat.bigWindow.value = null;
    NativeChat.screenOpen.value = false;
    NativeChat.drawerOpen.value = false;
    splitDividerRect.value = null;
  });

  tearDown(() {
    NativeChat.prefs.textScale = 1;
    NativeChat.quickWindows.value = const [];
    NativeChat.minimized.value = const [];
    NativeChat.bigWindow.value = null;
    splitDividerRect.value = null;
    Get.reset();
  });

  Future<_Scene> open(WidgetTester tester, String screen, _Look look) async {
    final tall = screen.startsWith('settings');
    final big = look == _Look.bigText || look == _Look.chatText;
    tester.view
      ..physicalSize = Size(big ? 720 : 824, tall ? 6000 : 1830)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    if (big) {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    }
    if (look == _Look.chatText) NativeChat.prefs.textScale = ChatPrefs.maxTextScale;
    final scene = _Scene(tester, look);
    await _screens[screen]!(scene);
    return scene;
  }

  for (final screen in _screens.keys) {
    group(screen, () {
      for (final look in [_Look.light, _Look.dark]) {
        for (final MapEntry(key: name, value: guideline) in _guidelines.entries) {
          final id = '$screen ${look.name} $name';
          testWidgets('${look.name} $name', skip: _known.containsKey(id), (tester) async {
            final semantics = tester.ensureSemantics();
            final scene = await open(tester, screen, look);
            await expectLater(tester, meetsGuideline(guideline));
            await scene.close();
            semantics.dispose();
          });
        }
      }

      for (final (look, name) in [
        (_Look.bigText, 'text at 200%'),
        if (_withMessages.contains(screen)) (_Look.chatText, 'text at 200% and chat text at its largest'),
      ]) {
        final id = '$screen $name';
        testWidgets(name, skip: _known.containsKey(id), (tester) async {
          final scene = await open(tester, screen, look);
          expect(tester.takeException(), isNull);
          await scene.close();
        });
      }
    });
  }
}
