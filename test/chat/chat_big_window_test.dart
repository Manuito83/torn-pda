import 'dart:async';
import 'dart:math' as math;

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/pages/chat/chat_conversation_page.dart';
import 'package:torn_pda/pages/chat/chat_page.dart';
import 'package:torn_pda/pages/chat/chat_search_page.dart';
import 'package:torn_pda/pages/chat/chat_settings_page.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/widgets/chat/chat_big_window.dart';
import 'package:torn_pda/widgets/chat/chat_icon_menu.dart';
import 'package:torn_pda/widgets/chat/chat_overlay.dart';
import 'package:torn_pda/widgets/chat/chat_quick_window.dart';
import 'package:torn_pda/widgets/chat/chat_slot_sheet.dart';
import 'package:torn_pda/widgets/chat/chat_status_sheet.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';
import 'package:torn_pda/widgets/webviews/split_divider.dart';

import 'chat_fakes.dart';

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

Finder get _bigWindowView => find.byType(ChatBigWindowView);

List<String> _minimizedRooms() => NativeChat.minimized.value.map((m) => m.roomId).toList();

void main() {
  useTempPathProvider();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    NativeChat.prefs
      ..introSeen = true
      ..inAppEnabled = true
      ..launcher = ChatLauncher.bubble
      ..launcherTap = ChatLauncherTap.full
      ..ticker = true
      ..bubbleSpot = []
      ..windows = []
      ..bigWindow = []
      ..drafts = {}
      ..markedUnread = {};
    NativeChat.keyValid.value = true;
    NativeChat.quickWindows.value = const [];
    NativeChat.minimized.value = const [];
    NativeChat.bigWindow.value = null;
    NativeChat.screenOpen.value = false;
    NativeChat.tornTabMissing.value = false;
    splitDividerRect.value = null;
  });

  tearDown(() {
    NativeChat.quickWindows.value = const [];
    NativeChat.minimized.value = const [];
    NativeChat.bigWindow.value = null;
    NativeChat.tornTabMissing.value = false;
    splitDividerRect.value = null;
    Get.reset();
  });

  group('room in one place', () {
    test('the big window takes a room from its small one', () {
      NativeChat.openQuickWindow('dm:1');
      NativeChat.openQuickWindow('dm:2');
      NativeChat.prefs.setDraft('dm:2', 'half a message');

      NativeChat.openBigWindow();
      NativeChat.setBigWindowRoom('dm:1');
      expect(NativeChat.quickWindows.value, ['dm:2']);
      expect(NativeChat.bigWindow.value?.roomId, 'dm:1');

      NativeChat.setBigWindowRoom('dm:2');
      expect(NativeChat.quickWindows.value, isEmpty);
      expect(_minimizedRooms(), ['dm:2']);
      expect(NativeChat.bigWindow.value?.roomId, 'dm:2');
    });

    test('a small window takes the room back and the big one returns to the list', () {
      NativeChat.openBigWindow();
      NativeChat.setBigWindowRoom('dm:1');
      NativeChat.openQuickWindow('dm:1');
      expect(NativeChat.bigWindow.value?.roomId, isNull);
      expect(NativeChat.quickWindows.value, ['dm:1']);

      NativeChat.setBigWindowRoom('faction');
      NativeChat.openQuickWindow('dm:3');
      expect(NativeChat.bigWindow.value?.roomId, 'faction');

      NativeChat.swapQuickWindow('dm:3', 'faction');
      expect(NativeChat.bigWindow.value?.roomId, isNull);
    });

    test('a minimized big window gives the room up too', () {
      NativeChat.openBigWindow();
      NativeChat.setBigWindowRoom('dm:1');
      NativeChat.minimizeBigWindow();
      NativeChat.openQuickWindow('dm:1');
      NativeChat.restoreBigWindow();
      expect(NativeChat.bigWindow.value?.roomId, isNull);
      expect(NativeChat.bigWindow.value?.minimized, isFalse);
    });

    test('popping out leaves the list behind', () {
      NativeChat.openBigWindow();
      NativeChat.setBigWindowRoom('dm:5');
      NativeChat.popOutBigWindow();
      expect(NativeChat.quickWindows.value, ['dm:5']);
      expect(NativeChat.bigWindow.value?.roomId, isNull);
      expect(NativeChat.bigWindowShown, isTrue);
    });

    testWidgets('a room that is gone sends the big window to the list', (tester) async {
      await _pumpApp(tester);
      NativeChat.openBigWindow();
      NativeChat.setBigWindowRoom('poker');
      NativeChat.onRoomGone(const ChatRoom(id: 'poker', name: 'Poker'));
      await tester.pump(const Duration(seconds: 4));
      expect(NativeChat.bigWindow.value?.roomId, isNull);
      expect(NativeChat.bigWindowShown, isTrue);
    });
  });

  group('back and split screen', () {
    testWidgets('back goes to the list, then minimizes, then leaves the window alone', (tester) async {
      final key = await _pumpApp(tester, home: const Scaffold(body: Text('home')));
      key.currentState!.push(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('second'))));
      await _settle(tester);
      await _settle(tester);
      NativeChat.openBigWindow();
      NativeChat.setBigWindowRoom('global');
      await _settle(tester);

      await tester.binding.handlePopRoute();
      await _settle(tester);
      expect(NativeChat.bigWindow.value?.roomId, isNull);
      expect(NativeChat.bigWindowShown, isTrue);

      await tester.binding.handlePopRoute();
      await _settle(tester);
      expect(NativeChat.bigWindow.value?.minimized, isTrue);
      expect(find.text('second'), findsOneWidget);

      await tester.binding.handlePopRoute();
      for (var i = 0; i < 4; i++) {
        await _settle(tester);
      }
      expect(find.text('second'), findsNothing);
      expect(NativeChat.bigWindow.value?.minimized, isTrue);
    });

    testWidgets('the window opens in the panel it was asked for', (tester) async {
      await _pumpApp(tester);
      const divider = Rect.fromLTWH(396, 0, 8, 600);
      splitDividerRect.value = divider;
      NativeChat.openBigWindow(side: SplitSide.right);
      await _settle(tester);
      expect(tester.getRect(_bigWindowView).left, greaterThanOrEqualTo(divider.right));

      NativeChat.closeBigWindow();
      await _settle(tester);
      NativeChat.openBigWindow(side: SplitSide.left);
      await _settle(tester);
      expect(tester.getRect(_bigWindowView).right, lessThanOrEqualTo(divider.left));
    });
  });

  group('cap and order', () {
    test('the big window does not count for the three small ones', () {
      NativeChat.openBigWindow();
      for (final room in ['dm:1', 'dm:2', 'dm:3']) {
        NativeChat.openQuickWindow(room);
      }
      expect(NativeChat.quickWindows.value, ['dm:1', 'dm:2', 'dm:3']);
      expect(NativeChat.minimized.value, isEmpty);
      NativeChat.openQuickWindow('dm:4');
      expect(NativeChat.quickWindows.value, ['dm:2', 'dm:3', 'dm:4']);
      expect(_minimizedRooms(), ['dm:1']);
      expect(NativeChat.bigWindowShown, isTrue);
    });

    test('a restored window goes in front', () {
      NativeChat.openQuickWindow('a');
      NativeChat.openBigWindow();
      expect(NativeChat.stackOrder, ['a', NativeChat.bigWindowId]);
      NativeChat.minimizeQuickWindow('a');
      NativeChat.openQuickWindow('a');
      expect(NativeChat.stackOrder, [NativeChat.bigWindowId, 'a']);
    });

    test('touching a window puts it in front, the other keeps its place', () {
      NativeChat.openQuickWindow('a');
      NativeChat.openQuickWindow('b');
      NativeChat.openBigWindow();
      expect(NativeChat.stackOrder, ['a', 'b', NativeChat.bigWindowId]);

      NativeChat.focusQuickWindow('a');
      expect(NativeChat.stackOrder, ['b', NativeChat.bigWindowId, 'a']);

      NativeChat.focusBigWindow();
      expect(NativeChat.stackOrder, ['b', 'a', NativeChat.bigWindowId]);

      NativeChat.openQuickWindow('c');
      expect(NativeChat.stackOrder, ['b', 'a', NativeChat.bigWindowId, 'c']);

      NativeChat.focusQuickWindow('b');
      expect(NativeChat.stackOrder, ['a', NativeChat.bigWindowId, 'c', 'b']);
    });

    test('a small window already last still passes the big one', () {
      NativeChat.openQuickWindow('a');
      NativeChat.openBigWindow();
      expect(NativeChat.stackOrder.last, NativeChat.bigWindowId);
      NativeChat.focusQuickWindow('a');
      expect(NativeChat.stackOrder, [NativeChat.bigWindowId, 'a']);
    });

    test('a minimized big window is not in the stack', () {
      NativeChat.openQuickWindow('a');
      NativeChat.openBigWindow();
      NativeChat.minimizeBigWindow();
      expect(NativeChat.stackOrder, ['a']);
      NativeChat.restoreBigWindow();
      expect(NativeChat.stackOrder, ['a', NativeChat.bigWindowId]);
    });

    test('hiding the small windows folds the big one too', () {
      NativeChat.openQuickWindow('a');
      NativeChat.openBigWindow();
      NativeChat.setBigWindowRoom('dm:9');
      NativeChat.hideQuickWindows();
      expect(NativeChat.bigWindow.value?.minimized, isTrue);
      expect(NativeChat.bigWindow.value?.roomId, 'dm:9');
      expect(NativeChat.quickWindows.value, isEmpty);
    });
  });

  group('saved state', () {
    test('frame, state and room survive a round trip', () {
      const frame = Rect.fromLTWH(10, 20.5, 300, 400);
      final saved = ChatBigWindow.encode(const ChatBigWindow(roomId: 'dm:7'), frame);
      final back = ChatBigWindow.decode(saved);
      expect(back.frame, frame);
      expect(back.bigWindow?.roomId, 'dm:7');

      expect(ChatBigWindow.decode(ChatBigWindow.encode(null, frame)).bigWindow, isNull);
      expect(ChatBigWindow.decode(ChatBigWindow.encode(null, frame)).frame, frame);
      expect(ChatBigWindow.decode(const ['open', '']).bigWindow?.roomId, isNull);
      expect(ChatBigWindow.decode(const ['open', 'faction', 'x', '1', '2', '3']).frame, isNull);
      expect(ChatBigWindow.decode(const []).bigWindow, isNull);
    });

    test('it comes back as a bubble and never as a room', () {
      NativeChat.prefs.bigWindow = ChatBigWindow.encode(
        const ChatBigWindow(roomId: 'dm:7'),
        const Rect.fromLTWH(0, 0, 300, 400),
      );
      NativeChat.loadBigWindow();
      expect(NativeChat.bigWindow.value?.minimized, isTrue);
      expect(NativeChat.bigWindow.value?.roomId, 'dm:7');
      expect(NativeChat.quickWindows.value, isEmpty);
      expect(NativeChat.minimized.value, isEmpty);
      expect(NativeChat.prefs.windows, isEmpty);

      NativeChat.prefs.bigWindow = ChatBigWindow.encode(null, const Rect.fromLTWH(0, 0, 300, 400));
      NativeChat.loadBigWindow();
      expect(NativeChat.bigWindow.value, isNull);
    });
  });

  group('window', () {
    testWidgets('full screen fills the area and gives the frame back', (tester) async {
      await _pumpApp(tester);
      NativeChat.openBigWindow();
      await _settle(tester);
      expect(_bigWindowView, findsOneWidget);
      final frame = tester.getRect(_bigWindowView);
      expect(frame.width, greaterThanOrEqualTo(280));
      expect(frame.height, greaterThanOrEqualTo(360));

      await tester.tap(find.byTooltip('More'));
      await _settle(tester);
      await _settle(tester);
      await tester.tap(find.text('Maximize window'));
      await _settle(tester);
      final full = tester.getRect(_bigWindowView);
      expect(full.width, greaterThan(frame.width));
      expect(full.height, greaterThan(frame.height));

      await tester.tap(find.byTooltip('More'));
      await _settle(tester);
      await _settle(tester);
      await tester.tap(find.text('Restore window size'));
      await _settle(tester);
      expect(tester.getRect(_bigWindowView), frame);
    });

    testWidgets('Chat settings from More minimizes the window', (tester) async {
      await _pumpApp(tester);
      NativeChat.openBigWindow();
      await _settle(tester);
      await tester.tap(find.byTooltip('More'));
      await _settle(tester);
      await _settle(tester);
      await tester.tap(find.text('Chat settings'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(ChatSettingsPage), findsOneWidget);
      expect(NativeChat.bigWindow.value?.minimized, isTrue);
    });

    testWidgets('over a rising keyboard it shrinks in place and gets its size back', (tester) async {
      const dpr = 2.625;
      tester.view.physicalSize = const Size(1080, 2424);
      tester.view.devicePixelRatio = dpr;
      addTearDown(tester.view.reset);
      await _pumpApp(tester);
      NativeChat.openBigWindow();
      await _settle(tester);
      final window = tester.state(_bigWindowView);
      final frame = tester.getRect(_bigWindowView);
      final saved = [...NativeChat.prefs.bigWindow];
      final screen = tester.view.physicalSize.height / dpr;

      for (var inset = 0.0; inset <= 500; inset += 20) {
        tester.view.viewInsets = FakeViewPadding(bottom: inset * dpr);
        await tester.pump(const Duration(milliseconds: 16));
        final rect = tester.getRect(_bigWindowView);
        expect(rect.top, frame.top);
        expect(rect.bottom, moreOrLessEquals(math.min(frame.bottom, screen - inset - 12)));
        expect(rect.width, frame.width);
      }

      tester.view.viewInsets = FakeViewPadding.zero;
      await _settle(tester);
      expect(tester.getRect(_bigWindowView), frame);
      expect(tester.state(_bigWindowView), same(window));
      expect(NativeChat.prefs.bigWindow, saved);
    });

    testWidgets('dragged or resized over a keyboard it keeps the saved size', (tester) async {
      const dpr = 2.625;
      tester.view.physicalSize = const Size(1080, 2424);
      tester.view.devicePixelRatio = dpr;
      addTearDown(tester.view.reset);
      await _pumpApp(tester);
      NativeChat.openBigWindow();
      await _settle(tester);
      final frame = tester.getRect(_bigWindowView);
      double savedHeight() => double.parse(NativeChat.prefs.bigWindow[5]);

      tester.view.viewInsets = const FakeViewPadding(bottom: 400 * dpr);
      await _settle(tester);
      final shrunk = tester.getRect(_bigWindowView);
      expect(shrunk.height, lessThan(frame.height));

      final drag = await tester.startGesture(shrunk.topLeft + const Offset(40, 20));
      await drag.moveBy(const Offset(0, 30));
      await tester.pump();
      await drag.moveBy(const Offset(0, 30));
      await tester.pump();
      expect(tester.getRect(_bigWindowView).top, moreOrLessEquals(shrunk.top + 60, epsilon: 20));
      await drag.moveBy(const Offset(0, -60));
      await drag.up();
      await _settle(tester);
      await _settle(tester);
      expect(savedHeight(), frame.height);

      await tester.dragFrom(tester.getRect(_bigWindowView).bottomRight - const Offset(8, 8), const Offset(0, -30));
      await _settle(tester);
      tester.view.viewInsets = FakeViewPadding.zero;
      await _settle(tester);
      expect(savedHeight(), moreOrLessEquals(frame.height - 30, epsilon: 20));
      expect(tester.getRect(_bigWindowView).height, savedHeight());
    });

    test('aboveKeyboard shrinks, rises, then fills', () {
      const room = Rect.fromLTRB(8, 16, 400, 400);
      const frame = Rect.fromLTWH(30, 200, 360, 520);
      expect(ChatWindowFrame.aboveKeyboard(frame, room), const Rect.fromLTRB(30, 150, 390, 400));
      expect(
        ChatWindowFrame.aboveKeyboard(frame, const Rect.fromLTRB(8, 16, 400, 216)),
        const Rect.fromLTRB(30, 16, 390, 216),
      );
      expect(
        ChatWindowFrame.aboveKeyboard(const Rect.fromLTWH(30, 100, 360, 260), room),
        const Rect.fromLTWH(30, 100, 360, 260),
      );
    });

    testWidgets('it moves and keeps a size fit for a list', (tester) async {
      await _pumpApp(tester);
      NativeChat.openBigWindow();
      await _settle(tester);
      final frame = tester.getRect(_bigWindowView);

      await tester.dragFrom(frame.bottomRight - const Offset(8, 8), const Offset(-400, -400));
      await _settle(tester);
      final small = tester.getRect(_bigWindowView);
      expect(small.width, 280);
      expect(small.height, 360);

      await tester.dragFrom(small.topLeft + const Offset(40, 20), const Offset(30, 20));
      await _settle(tester);
      expect(tester.getRect(_bigWindowView).topLeft, small.topLeft + const Offset(30, 20));
    });

    testWidgets('minimized, it waits as a bubble and comes back', (tester) async {
      NativeChat.prefs.launcher = ChatLauncher.browser;
      await _pumpApp(tester);
      NativeChat.openBigWindow();
      NativeChat.setBigWindowRoom('global');
      NativeChat.toggleBigWindowFull();
      await _settle(tester);
      expect(find.byType(ChatConversationPage), findsOneWidget);
      final full = tester.getRect(_bigWindowView);

      await tester.tap(find.byTooltip('Minimize'));
      await _settle(tester);
      expect(_bigWindowView, findsNothing);
      final bubble = find.byKey(const ValueKey('mini:${NativeChat.bigWindowId}'));
      expect(bubble, findsOneWidget);
      expect(NativeChat.bigWindow.value?.roomId, 'global');

      await tester.tap(bubble);
      await _settle(tester);
      expect(find.byType(ChatConversationPage), findsOneWidget);
      expect(tester.getRect(_bigWindowView), full);
      expect(bubble, findsNothing);
    });

    testWidgets('with the bubble launcher, the bubble holds it and brings it back', (tester) async {
      await _pumpApp(tester);
      NativeChat.openBigWindow();
      NativeChat.setBigWindowRoom('global');
      await _settle(tester);
      expect(find.byIcon(Icons.web_asset_rounded), findsNothing);

      NativeChat.minimizeBigWindow();
      await _settle(tester);
      expect(_bigWindowView, findsNothing);
      expect(find.byKey(const ValueKey('mini:${NativeChat.bigWindowId}')), findsNothing);
      expect(find.byIcon(Icons.forum_rounded), findsOneWidget);
      expect(find.byIcon(Icons.web_asset_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.forum_rounded));
      await _settle(tester);
      expect(NativeChat.bigWindowHolds('global'), isTrue);
      expect(_bigWindowView, findsOneWidget);
      expect(find.byIcon(Icons.web_asset_rounded), findsNothing);
    });

    testWidgets('pop out hands the room to a small window and the list returns', (tester) async {
      await _pumpApp(tester);
      NativeChat.openBigWindow();
      NativeChat.setBigWindowRoom('global');
      await _settle(tester);

      await tester.tap(find.byTooltip('Open in a small window'));
      await _settle(tester);
      expect(NativeChat.quickWindows.value, ['global']);
      expect(find.byType(ChatConversationPage), findsNothing);
      expect(_bigWindowView, findsOneWidget);
    });

    testWidgets('paused, it waits in the notice and X closes it', (tester) async {
      await _pumpApp(tester);
      NativeChat.openBigWindow();
      await _settle(tester);
      NativeChat.tornTabMissing.value = true;
      await _settle(tester);
      expect(_bigWindowView, findsNothing);
      expect(find.text('Chat paused'), findsOneWidget);

      NativeChat.tornTabMissing.value = false;
      await _settle(tester);
      expect(_bigWindowView, findsOneWidget);
      expect(find.text('Chat paused'), findsNothing);

      NativeChat.tornTabMissing.value = true;
      await _settle(tester);
      await tester.tap(find.byTooltip('Close chat windows'));
      await _settle(tester);
      expect(NativeChat.bigWindow.value, isNull);
      NativeChat.tornTabMissing.value = false;
      await _settle(tester);
      expect(_bigWindowView, findsNothing);
    });

    testWidgets('sheets from the window open above the overlay', (tester) async {
      await _pumpApp(tester);
      NativeChat.openBigWindow();
      await _settle(tester);
      showModalBottomSheet<void>(context: tester.element(_bigWindowView), builder: (_) => const Text('sheet'));
      await _settle(tester);
      await _settle(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('sheet'), findsOneWidget);
      expect(tester.getRect(find.text('sheet')).bottom, greaterThan(tester.getRect(_bigWindowView).bottom));

      NativeChat.tornTabMissing.value = true;
      await _settle(tester);
      await _settle(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('sheet'), findsNothing);
      NativeChat.tornTabMissing.value = false;
    });

    testWidgets('the status sheet from the window closes the keyboard', (tester) async {
      final fetch = chatStatusFetch;
      addTearDown(() => chatStatusFetch = fetch);
      chatStatusFetch = () async => null;
      final typing = FocusNode();
      addTearDown(typing.dispose);
      await _pumpApp(tester, home: Scaffold(body: TextField(focusNode: typing, autofocus: true)));
      NativeChat.openBigWindow();
      await _settle(tester);
      expect(typing.hasFocus, isTrue);

      unawaited(showChatStatusSheet(tester.element(_bigWindowView), (_) {}));
      await _settle(tester);
      expect(find.text('Insert my status'), findsOneWidget);
      expect(typing.hasFocus, isFalse);
    });

    testWidgets('a sheet with its own field keeps the keyboard', (tester) async {
      await _pumpApp(tester, home: const Scaffold(body: TextField(autofocus: true)));
      NativeChat.openBigWindow();
      await _settle(tester);

      unawaited(showChatSlotSheet(tester.element(_bigWindowView), 'Hi {name}', const {}, const ['name']));
      await _settle(tester);
      final field = tester.widget<EditableText>(
        find.descendant(of: find.byType(ChatSlotSheet), matching: find.byType(EditableText)),
      );
      expect(field.focusNode.hasFocus, isTrue);
    });
  });

  group('page and window', () {
    testWidgets('opening the page folds the window and the window closes the page', (tester) async {
      final key = await _pumpApp(tester);
      NativeChat.openBigWindow();
      NativeChat.setBigWindowRoom('global');
      await _settle(tester);

      unawaited(NativeChat.open(key.currentState!));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(NativeChat.screenOpen.value, isTrue);
      expect(find.byType(ChatPage), findsOneWidget);
      expect(NativeChat.bigWindow.value?.minimized, isTrue);
      expect(_bigWindowView, findsNothing);

      NativeChat.openBigWindow();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(ChatPage), findsNothing);
      expect(NativeChat.screenOpen.value, isFalse);
      expect(NativeChat.bigWindowShown, isTrue);
      expect(_bigWindowView, findsOneWidget);
    });

    testWidgets('the page button opens the window', (tester) async {
      final key = await _pumpApp(tester);
      unawaited(NativeChat.open(key.currentState!));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.byTooltip('Open in a window'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(ChatPage), findsNothing);
      expect(_bigWindowView, findsOneWidget);
    });
  });

  group('browser icon', () {
    final icon = Scaffold(
      appBar: AppBar(
        actions: [
          ChatIconButton(
            color: Colors.white,
            hiddenInTab: false,
            hiddenEverywhere: false,
            onHideInTab: (_) {},
            onHideEverywhere: (_) {},
          ),
        ],
      ),
    );

    testWidgets('a tap opens what the setting says', (tester) async {
      NativeChat.prefs.launcherTap = ChatLauncherTap.window;
      await _pumpApp(tester, home: icon);
      await tester.tap(find.byType(ChatIconButton));
      await _settle(tester);
      expect(_bigWindowView, findsOneWidget);
      expect(NativeChat.screenOpen.value, isFalse);
      await tester.tap(find.byType(ChatIconButton));
      await _settle(tester);
      expect(NativeChat.bigWindow.value, isNull);

      NativeChat.prefs.launcherTap = ChatLauncherTap.full;
      await tester.tap(find.byType(ChatIconButton));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(ChatPage), findsOneWidget);
      expect(_bigWindowView, findsNothing);
    });

    testWidgets('paused, a tap opens the window and the notice shows', (tester) async {
      NativeChat.prefs.launcherTap = ChatLauncherTap.window;
      await _pumpApp(tester, home: icon);
      NativeChat.tornTabMissing.value = true;
      await _settle(tester);
      await tester.tap(find.byType(ChatIconButton));
      await _settle(tester);
      expect(NativeChat.bigWindowShown, isTrue);
      expect(_bigWindowView, findsNothing);
      expect(find.text('Chat paused'), findsOneWidget);
    });

    testWidgets('the long press menu opens the window, the page and the settings', (tester) async {
      await _pumpApp(tester, home: icon);
      await tester.longPress(find.byType(ChatIconButton));
      await _settle(tester);
      await tester.tap(find.text('Window'));
      await _settle(tester);
      expect(_bigWindowView, findsOneWidget);

      NativeChat.closeBigWindow();
      await tester.longPress(find.byType(ChatIconButton));
      await _settle(tester);
      await tester.tap(find.text('Chat settings'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(ChatSettingsPage), findsOneWidget);
      await tester.pageBack();
      await _settle(tester);
      await _settle(tester);

      await tester.longPress(find.byType(ChatIconButton));
      await _settle(tester);
      await tester.tap(find.text('Full chat'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(NativeChat.screenOpen.value, isTrue);
      expect(find.byType(ChatPage), findsOneWidget);
    });
  });

  group('bubble', () {
    Finder bubble() => find.byIcon(Icons.forum_rounded).first;

    testWidgets('a tap opens what the setting says', (tester) async {
      final key = await _pumpApp(tester);
      await tester.tap(bubble());
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(ChatPage), findsOneWidget);
      key.currentState!.pop();
      await _settle(tester);
      await _settle(tester);

      NativeChat.prefs.launcherTap = ChatLauncherTap.window;
      await tester.tap(bubble());
      await _settle(tester);
      expect(_bigWindowView, findsOneWidget);
      expect(NativeChat.screenOpen.value, isFalse);
    });

    testWidgets('a long press gives the chat menu', (tester) async {
      await _pumpApp(tester);
      await tester.longPress(bubble());
      await _settle(tester);
      await tester.tap(find.text('Window'));
      await _settle(tester);
      expect(_bigWindowView, findsOneWidget);

      await tester.longPress(bubble());
      await _settle(tester);
      await tester.tap(find.text('Chat settings'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(ChatSettingsPage), findsOneWidget);
      expect(NativeChat.bigWindow.value?.minimized, isTrue);
    });
  });

  group('saved', () {
    testWidgets('leaving for the saved search closes the window', (tester) async {
      await _pumpApp(tester);
      NativeChat.openBigWindow();
      await _settle(tester);

      NativeChat.expandBigWindow(saved: true);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(NativeChat.bigWindow.value, isNull);
      expect(find.byType(ChatPage), findsOneWidget);
      expect(find.byType(ChatSearchPage, skipOffstage: false), findsOneWidget);
    });
  });
}
