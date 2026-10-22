import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torn_pda/models/chat/chat_alerts.dart';
import 'package:torn_pda/models/chat/chat_filter.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/pages/chat/chat_conversation_page.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/providers/pip_controller.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/widgets/chat/chat_overlay.dart';
import 'package:torn_pda/widgets/chat/chat_quick_window.dart';
import 'package:torn_pda/widgets/chat/chat_ticker.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';
import 'package:torn_pda/widgets/webviews/split_divider.dart';

import 'chat_fakes.dart';

class _QuietPip extends PipController {
  @override
  // ignore: must_call_super
  void onInit() {}
}

Future<GlobalKey<NavigatorState>> _pumpApp(WidgetTester tester, {Widget home = const Scaffold()}) async {
  final key = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: key,
      navigatorObservers: [BotToastNavigatorObserver(), NativeChat.rootWatch],
      builder: (context, child) => Stack(
        children: [
          BotToastInit()(context, child),
          ChatOverlay(navigatorKey: key),
        ],
      ),
      home: home,
    ),
  );
  await tester.pump(const Duration(milliseconds: 400));
  return key;
}

Future<void> _settle(WidgetTester tester) => tester.pump(const Duration(milliseconds: 400));

Finder _mini(String roomId) => find.byKey(ValueKey('mini:$roomId'));

Finder _caption(String text) => find.textContaining(text, findRichText: true);

void main() {
  useTempPathProvider();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    NativeChat.prefs
      ..introSeen = true
      ..inAppEnabled = true
      ..ticker = true
      ..bubbleSpot = []
      ..windows = []
      ..markedUnread = {};
    NativeChat.keyValid.value = true;
    NativeChat.quickWindows.value = const [];
    NativeChat.minimized.value = const [];
    NativeChat.screenOpen.value = false;
    NativeChat.drawerOpen.value = false;
    splitDividerRect.value = null;
  });

  tearDown(() {
    NativeChat.quickWindows.value = const [];
    NativeChat.minimized.value = const [];
    splitDividerRect.value = null;
    Get.reset();
  });

  group('quick windows', () {
    test('the window frame stays on screen', () {
      const area = Rect.fromLTRB(8, 40, 403, 860);
      expect(
        [for (var p = ChatWindowSize.s, i = 0; i < 4; p = p.next, i++) p],
        [ChatWindowSize.s, ChatWindowSize.m, ChatWindowSize.l, ChatWindowSize.s],
      );

      expect(ChatWindowFrame.fit(const Rect.fromLTWH(300, 700, 420, 640), area), const Rect.fromLTWH(8, 220, 395, 640));
      final tiny = ChatWindowFrame.fit(const Rect.fromLTWH(-50, 0, 100, 80), area);
      expect(tiny.size, ChatWindowFrame.minSize);
      expect(tiny.topLeft, const Offset(8, 40));

      final out = ChatWindowFrame.loose(const Rect.fromLTWH(250, -30, 260, 300), area);
      expect(out, const Rect.fromLTWH(250, 40, 260, 300));
      expect(ChatWindowFrame.outside(out, area), closeTo(107 / 260, 0.001));
      expect(ChatWindowFrame.loose(const Rect.fromLTWH(900, 100, 260, 300), area).left, 403);
      expect(ChatWindowFrame.outside(const Rect.fromLTWH(20, 100, 260, 300), area), 0);

      const divider = Rect.fromLTWH(200, 0, 12, 900);
      expect(ChatWindowFrame.panel(area, divider, SplitSide.left), const Rect.fromLTRB(8, 40, 200, 860));
      expect(ChatWindowFrame.panel(area, divider, SplitSide.right), const Rect.fromLTRB(212, 40, 403, 860));
      expect(ChatWindowFrame.panel(area, null, SplitSide.left), area);
      expect(ChatWindowFrame.panel(area, divider, null), area);

      final decoded = ChatWindowFrame.decode(
        ChatWindowFrame.encode('a|b', const Rect.fromLTWH(1, 2, 300, 400), ChatWindowSize.l),
      );
      expect(
        (decoded.roomId, decoded.frame, decoded.preset),
        ('a|b', const Rect.fromLTWH(1, 2, 300, 400), ChatWindowSize.l),
      );
      expect(ChatWindowFrame.decode('dm:5').frame, isNull);
    });

    test('three windows at most, the rest minimized', () {
      List<String> minimized() => NativeChat.minimized.value.map((m) => m.roomId).toList();
      for (final room in ['dm:1', 'dm:2', 'faction']) {
        NativeChat.openQuickWindow(room);
      }
      expect(NativeChat.quickWindows.value, ['dm:1', 'dm:2', 'faction']);

      NativeChat.focusQuickWindow('dm:1');
      expect(NativeChat.quickWindows.value.last, 'dm:1');

      NativeChat.openQuickWindow('company');
      expect(NativeChat.quickWindows.value, ['faction', 'dm:1', 'company']);
      expect(minimized(), ['dm:2']);

      NativeChat.minimizeQuickWindow('dm:1');
      NativeChat.closeQuickWindow('faction');
      expect(NativeChat.quickWindows.value, ['company']);
      expect(minimized(), ['dm:2', 'dm:1']);
      expect(NativeChat.takeResume('dm:1'), isNull);

      NativeChat.restore(NativeChat.minimized.value.first);
      expect(NativeChat.quickWindows.value, ['company', 'dm:2']);
      expect(minimized(), ['dm:1']);

      NativeChat.hideQuickWindows();
      expect(NativeChat.quickWindows.value, isEmpty);
      expect(minimized(), ['dm:1', 'company', 'dm:2']);

      NativeChat.restore();
      expect(NativeChat.quickWindows.value, ['dm:2']);
      NativeChat.dropMinimized('dm:1');
      expect(minimized(), ['company']);
    });

    testWidgets('replying from a caption puts the cursor in the composer', (tester) async {
      final source = FakeChatSource();
      final chat = ChatController(source, ChatPrefs());
      source.emit(const ChatReadyEvent(99));
      NativeChat.openQuickWindow('dm:7', reply: true);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 340,
              height: 440,
              child: ChatQuickWindow(chat: chat, roomId: 'dm:7', onClose: () {}),
            ),
          ),
        ),
      );
      await tester.pump();
      bool focused() => tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus;
      expect(focused(), isTrue);

      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      expect(focused(), isFalse);
      NativeChat.openQuickWindow('dm:7');
      await tester.pump();
      expect(focused(), isFalse);
      NativeChat.openQuickWindow('dm:7', reply: true);
      await tester.pump();
      expect(focused(), isTrue);

      await tester.pumpWidget(const SizedBox());
      chat.dispose();
    });

    testWidgets('a quick window over an open conversation hands it back', (tester) async {
      final source = FakeChatSource();
      final chat = ChatController(source, ChatPrefs());
      source
        ..emit(const ChatReadyEvent(99))
        ..emit(const ChatUnreadEvent({'faction': 2, 'dm:7': 1}));
      chat.openConversation('faction');
      expect(source.calls, contains('markRead faction'));

      final roomId = ValueNotifier<String?>('dm:7');
      final calls = <String>[];
      var resized = Offset.zero;
      var label = 'M';
      await tester.pumpWidget(
        MaterialApp(
          builder: BotToastInit(),
          navigatorObservers: [BotToastNavigatorObserver()],
          home: Scaffold(
            body: ValueListenableBuilder(
              valueListenable: roomId,
              builder: (context, id, _) => id == null
                  ? const SizedBox()
                  : StatefulBuilder(
                      builder: (context, setState) => SizedBox(
                        width: 340,
                        height: 440,
                        child: ChatQuickWindow(
                          chat: chat,
                          roomId: id,
                          onClose: () => roomId.value = null,
                          onMinimize: () => calls.add('minimize'),
                          onResize: (d) => resized += d,
                          onResizeEnd: () => calls.add('resized'),
                          sizeLabel: label,
                          onCycleSize: () => setState(() => label = label == 'M' ? 'L' : 'S'),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      );
      await tester.pump();
      String lastOpened() => source.calls.lastWhere((c) => c.startsWith('openRoom '));
      expect(chat.currentRoomId, 'dm:7');
      expect(chat.isOnScreen('faction'), isTrue);
      expect(lastOpened(), 'openRoom dm:7');
      expect(chat.unreadGroups(), isEmpty);

      source.emit(
        ChatHistoryEvent(
          'dm:7',
          [chatMessage('a', 'dm:7', sender: 7, at: DateTime.now())],
          hasOlder: false,
          isOlderPage: false,
        ),
      );
      await tester.pump();
      expect(find.text('text a'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'hi');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      expect(source.sent.single.roomId, 'dm:7');

      await tester.tap(find.byTooltip('More'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Window size: M'));
      await tester.pumpAndSettle();
      expect(label, 'L');
      await tester.tap(find.byTooltip('Minimize'));
      await tester.pump();
      expect(calls, ['minimize']);

      final corner = tester.getBottomRight(find.byType(ChatQuickWindow)) - const Offset(8, 8);
      await tester.dragFrom(corner, const Offset(-60, -40));
      await tester.pump();
      expect(resized.dx, lessThan(-30));
      expect(resized.dy, lessThan(-10));
      expect(calls.last, 'resized');

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      await tester.pump();
      expect(chat.currentRoomId, 'faction');
      expect(lastOpened(), 'openRoom faction');
      expect(source.count('closeRoom'), 0);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 31));
      chat.dispose();
    });
  });

  group('bubbles', () {
    Future<void> doubleTap(WidgetTester tester) async {
      final bubble = find.byIcon(Icons.forum_rounded);
      await tester.tap(bubble);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(bubble);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('a paused window leaves its notice, also over a dialog', (tester) async {
      final key = await _pumpApp(tester);
      NativeChat.quickWindows.value = ['global'];
      await _settle(tester);
      NativeChat.tornTabMissing.value = true;
      await _settle(tester);
      expect(find.text('Open Torn'), findsOneWidget);
      NativeChat.tornTabMissing.value = false;
      await _settle(tester);

      unawaited(showDialog<void>(context: key.currentContext!, builder: (_) => const Text('dialog')));
      await _settle(tester);
      NativeChat.tornTabMissing.value = true;
      await _settle(tester);
      expect(find.text('Open Torn'), findsOneWidget);
      expect(NativeChat.quickWindows.value, ['global']);
      NativeChat.tornTabMissing.value = false;
      NativeChat.closeQuickWindow();
    });

    testWidgets('minimized windows become bubbles, dismissed only from their menus', (tester) async {
      await _pumpApp(tester);
      NativeChat.quickWindows.value = ['faction'];
      NativeChat.minimizeQuickWindow('faction');
      NativeChat.minimize('company');
      await _settle(tester);
      expect(_mini('faction'), findsOneWidget);
      expect(_mini('company'), findsNothing);

      await tester.tap(_mini('faction'));
      expect(NativeChat.quickWindows.value, ['faction']);
      expect(NativeChat.minimized.value.map((m) => m.roomId), ['company']);
      NativeChat.closeQuickWindow();

      NativeChat.minimized.value = [for (var i = 1; i <= 5; i++) ChatMinimized('room$i', window: true)];
      await _settle(tester);
      for (final room in ['room3', 'room4', 'room5']) {
        expect(_mini(room), findsOneWidget);
      }
      expect(_mini('room1'), findsNothing);
      expect(_mini('room2'), findsNothing);

      await tester.tap(find.text('+2'));
      await _settle(tester);
      expect(find.text('room1'), findsOneWidget);
      expect(find.text('room2'), findsOneWidget);
      expect(find.text('room5'), findsNothing);
      await tester.tap(find.byTooltip('Dismiss').first);
      await _settle(tester);
      expect(find.text('+1'), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await _settle(tester);

      await tester.longPress(_mini('room5'));
      await _settle(tester);
      expect(find.text('Dismiss'), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await _settle(tester);
      expect(find.text('Dismiss'), findsNothing);
      expect(_mini('room5'), findsOneWidget);

      await tester.longPress(_mini('room5'));
      await _settle(tester);
      await tester.tap(find.text('Dismiss'));
      await _settle(tester);
      expect(_mini('room5'), findsNothing);
      expect(NativeChat.minimized.value.map((m) => m.roomId), ['room1', 'room3', 'room4']);
    });

    testWidgets('docked bubbles tuck away', (tester) async {
      NativeChat.prefs.bubbleSpot = ['1', '0.5', '1'];
      await _pumpApp(tester);
      NativeChat.minimized.value = const [ChatMinimized('faction', window: true)];
      await _settle(tester);
      double opacity() => tester
          .widget<AnimatedOpacity>(find.descendant(of: _mini('faction'), matching: find.byType(AnimatedOpacity)))
          .opacity;

      expect(opacity(), 0);
      await tester.tap(_mini('faction'), warnIfMissed: false);
      await tester.pump();
      expect(NativeChat.quickWindows.value, isEmpty);

      await tester.tapAt(tester.getRect(find.byIcon(Icons.forum_rounded)).centerLeft + const Offset(4, 0));
      await _settle(tester);
      expect(NativeChat.prefs.bubbleSpot.last, '0');
      expect(opacity(), 1);
    });

    testWidgets('double tap marks every chat read, with undo', (tester) async {
      NativeChat.prefs.setMarkedUnread('global', true);
      await _pumpApp(tester);
      await doubleTap(tester);
      expect(find.textContaining('Nothing to mark as read'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      NativeChat.prefs.setMarkedUnread('faction', true);
      expect(NativeChat.controller.readable, ['faction']);
      await doubleTap(tester);
      expect(find.text('1 chat marked as read'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(NativeChat.prefs.markedUnread, contains('faction'));

      await doubleTap(tester);
      expect(NativeChat.prefs.markedUnread, contains('faction'));
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(NativeChat.prefs.markedUnread, isNot(contains('faction')));
    });
  });

  group('ticker', () {
    testWidgets('caption filters and swipe', (tester) async {
      final prefs = ChatPrefs()
        ..browserWords = ['xanax']
        ..alertWords = {'xanax'}
        ..muted = {'company'}
        ..ignored = {5: 'Echo'}
        ..roomFilters = {
          'faction': ChatRoomFilter(hide: ['spam']),
        }
        ..tickerLevels = {'faction': ChatAlertLevel.all, 'company': ChatAlertLevel.all};
      final source = FakeChatSource();
      final chat = ChatController(source, prefs);
      final opened = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatTicker(chat: chat, prefs: prefs, onOpen: opened.add),
          ),
        ),
      );
      source.emit(const ChatReadyEvent(99, myName: 'Bravo'));
      await tester.pump();
      void live(String id, String room, int user, String text) => source.emit(
        ChatMessageEvent(chatMessage(id, room, sender: user, name: 'U$user', text: text, at: DateTime.now())),
      );
      Future<void> show() async {
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));
      }

      chat.openConversation('trade');
      live('1', 'global', 1, 'hello all');
      live('2', 'global', 1, 'selling Xanax @bravo');
      live('3', 'global', 1, 'only Xanax here');
      live('4', 'company', 2, 'muted chatter');
      live('5', 'trade', 4, 'cheap Xanax');
      live('6', 'dm:5', 5, 'ignored player');
      live('7', 'faction', 99, 'my own');
      live('8', 'dm:7', 7, 'psst');
      await show();
      for (final text in ['hello all', 'only Xanax', 'muted chatter', 'cheap Xanax', 'ignored player', 'my own']) {
        expect(_caption(text), findsNothing);
      }
      expect(_caption('selling Xanax'), findsOneWidget);
      expect(_caption('psst'), findsOneWidget);
      expect(find.byIcon(Icons.alternate_email_rounded), findsOneWidget);

      live('9', 'faction', 3, 'buy my spam');
      live('10', 'faction', 3, 'faction chatter');
      await show();
      expect(_caption('buy my spam'), findsNothing);
      expect(_caption('selling Xanax'), findsNothing);
      expect(_caption('psst'), findsOneWidget);
      expect(_caption('faction chatter'), findsOneWidget);

      live('11', 'dm:7', 7, 'again');
      await show();
      expect(_caption('psst'), findsNothing);
      await tester.tap(_caption('again'));
      await tester.pump();
      expect(opened, ['dm:7']);
      expect(_caption('again'), findsNothing);

      await tester.drag(_caption('faction chatter'), const Offset(500, 0));
      await tester.pumpAndSettle();
      expect(_caption('faction chatter'), findsNothing);

      prefs.ticker = false;
      live('12', 'dm:7', 7, 'while off');
      await tester.pump();
      expect(_caption('while off'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      chat.dispose();
    });

    testWidgets('a screen reader keeps captions until dismissed', (tester) async {
      final semantics = tester.ensureSemantics();
      final spoken = <String>[];
      tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, (
        message,
      ) async {
        final map = message as Map<Object?, Object?>;
        if (map['type'] == 'announce') spoken.add((map['data'] as Map<Object?, Object?>)['message']! as String);
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(
          SystemChannels.accessibility,
          null,
        ),
      );
      final prefs = ChatPrefs()
        ..tickerLevels = {
          for (final group in ['dm', 'faction', 'company', 'global', 'trade']) group: ChatAlertLevel.all,
        };
      final source = FakeChatSource();
      final chat = ChatController(source, prefs);
      final reader = ValueNotifier(true);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, page) => ValueListenableBuilder<bool>(
            valueListenable: reader,
            builder: (context, on, _) => MediaQuery(
              data: MediaQuery.of(context).copyWith(accessibleNavigation: on),
              child: page!,
            ),
          ),
          home: Scaffold(
            body: ChatTicker(chat: chat, prefs: prefs, onOpen: (_) {}),
          ),
        ),
      );
      void live(String id, String room, int user, String name, String text) => source.emit(
        ChatMessageEvent(chatMessage(id, room, sender: user, name: name, text: text, at: DateTime.now())),
      );
      source
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
      live('2', 'global', 3, 'Delta', 'selling xanax');
      live('1', 'dm:7', 7, 'Bravo', 'psst');
      live('3', 'global', 4, 'Echo', 'Me are you there?');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(spoken, ['Bravo, psst', 'Mention, Echo in Global, Me are you there?']);

      await tester.pump(const Duration(seconds: 12));
      final dm = find.bySemanticsLabel('Bravo, psst');
      expect(dm, findsOneWidget);
      final node = tester.getSemantics(dm);
      final dismiss = node.getSemanticsData().customSemanticsActionIds!.firstWhere(
        (id) => CustomSemanticsAction.getAction(id)?.label == 'Dismiss',
      );
      node.owner!.performAction(node.id, SemanticsAction.customAction, dismiss);
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Bravo, psst'), findsNothing);
      expect(find.bySemanticsLabel(RegExp('^Delta')), findsNothing);
      expect(find.bySemanticsLabel(RegExp('^Mention, Echo')), findsOneWidget);

      reader.value = false;
      spoken.clear();
      await tester.pump();
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(RegExp('^Mention, Echo')), findsNothing);
      live('4', 'dm:7', 7, 'Bravo', 'again');
      await tester.pump();
      expect(spoken, isEmpty);

      await tester.pumpWidget(const SizedBox());
      chat.dispose();
      semantics.dispose();
    });
  });

  testWidgets('the bubble steps off a split divider', (tester) async {
    NativeChat.prefs.bubbleSpot = ['0.5', '0.5', '0'];
    final split = ValueNotifier<double?>(null);
    await _pumpApp(
      tester,
      home: ValueListenableBuilder<double?>(
        valueListenable: split,
        builder: (context, left, _) => left == null
            ? const SizedBox()
            : Row(
                children: [
                  SizedBox(width: left),
                  SplitDivider(width: 800, ratio: 0.4, onRatioChanged: (_) {}),
                  const Expanded(child: SizedBox()),
                ],
              ),
      ),
    );
    Rect head() => Rect.fromCenter(center: tester.getCenter(find.byIcon(Icons.forum_rounded)), width: 48, height: 48);
    final free = head();

    split.value = free.center.dx - 2;
    await tester.pump();
    await tester.pump();
    await _settle(tester);
    final divider = splitDividerRect.value!;
    expect(divider, Rect.fromLTWH(free.center.dx - 2, 0, kSplitDividerWidth, 600));
    final moved = head();
    expect(moved.right <= divider.left || moved.left >= divider.right, isTrue);
    expect(moved.top, free.top);

    split.value = null;
    await tester.pump();
    await tester.pump();
    await _settle(tester);
    expect(splitDividerRect.value, isNull);
    expect(head(), free);
  });

  testWidgets('pip and drawer hiding', (tester) async {
    final pip = Get.put<PipController>(_QuietPip());
    await _pumpApp(tester);
    final bubble = find.byIcon(Icons.forum_rounded);
    expect(bubble, findsOneWidget);
    expect(find.byType(ChatTicker), findsOneWidget);

    NativeChat.drawerOpen.value = true;
    await tester.pump();
    expect(find.byType(ChatTicker), findsNothing);
    expect(bubble, findsOneWidget);
    NativeChat.drawerOpen.value = false;
    await tester.pump();
    expect(find.byType(ChatTicker), findsOneWidget);

    pip.inPip.value = true;
    await tester.pump();
    await tester.pump();
    expect(bubble, findsNothing);
    expect(find.byType(ChatTicker), findsNothing);
    pip.inPip.value = false;
    await tester.pump();
    await tester.pump();
    expect(bubble, findsOneWidget);
  });

  testWidgets('sheets open above the overlay and back closes them', (tester) async {
    final key = await _pumpApp(tester, home: const Scaffold(body: Text('home')));
    key.currentState!.push(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('second'))));
    await tester.pumpAndSettle();
    final bubble = find.bySemanticsLabel(RegExp('^Chat, '));
    expect(bubble, findsOneWidget);

    showDialog<void>(
      context: key.currentContext!,
      builder: (_) => const AlertDialog(content: Text('dialog')),
    );
    await tester.pumpAndSettle();
    expect(bubble, findsNothing);
    key.currentState!.pop();
    await tester.pumpAndSettle();
    expect(bubble, findsOneWidget);

    showModalBottomSheet<void>(context: tester.element(bubble), builder: (_) => const Text('launcher sheet'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('launcher sheet'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('launcher sheet'), findsNothing);
    expect(find.text('second'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('gone poker room closes everything', (tester) async {
    const faction = ChatRoom(id: 'faction', name: 'Faction');
    const poker = ChatRoom(id: 'poker', name: 'Poker', icon: 'casino');
    const notice = 'Poker chat closed: you left the table';
    final source = FakeChatSource();
    final chat = ChatController(source, ChatPrefs());
    source
      ..emit(const ChatReadyEvent(99, myName: 'Me'))
      ..emit(const ChatRoomsEvent([faction, poker]));
    await tester.pumpWidget(
      MaterialApp(
        builder: BotToastInit(),
        navigatorObservers: [BotToastNavigatorObserver()],
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context)
                .push(
                  MaterialPageRoute<void>(
                    builder: (_) => ChangeNotifierProvider<ChatController>.value(
                      value: chat,
                      child: const ChatConversationPage(roomId: 'poker'),
                    ),
                  ),
                )
                .then((_) => chat.closeConversation('poker')),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(ChatConversationPage), findsOneWidget);
    expect(chat.isOnScreen('poker'), isTrue);

    source.emit(const ChatRoomsEvent([faction]));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(ChatConversationPage), findsNothing);
    expect(find.text('open'), findsOneWidget);
    expect(chat.isOnScreen('poker'), isFalse);

    NativeChat.quickWindows.value = ['poker', 'faction'];
    NativeChat.minimized.value = const [ChatMinimized('poker'), ChatMinimized('company', window: true)];
    NativeChat.onRoomGone(poker);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(NativeChat.quickWindows.value, ['faction']);
    expect(NativeChat.minimized.value.map((m) => m.roomId), ['company']);
    expect(find.text(notice), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    NativeChat.onRoomGone(poker);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(notice), findsNothing);

    await tester.pumpWidget(const SizedBox());
    chat.dispose();
  });
}
