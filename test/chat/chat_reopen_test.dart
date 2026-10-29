import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torn_pda/pages/chat/chat_page.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/widgets/chat/chat_overlay.dart';
import 'package:torn_pda/widgets/chat/chat_quick_window.dart';
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

Future<void> _closeAll(WidgetTester tester) async {
  NativeChat.closeQuickWindow();
  NativeChat.closeBigWindow();
  NativeChat.minimized.value = const [];
  await tester.pump();
  await tester.pump(const Duration(seconds: 21));
}

const _frame = Rect.fromLTWH(20, 40, 340, 440);

/// What a closed app left behind
void _leftOpen(List<String> onScreen, {List<String> windows = const [], String? bigRoom}) {
  NativeChat.prefs
    ..onScreen = onScreen
    ..windows = [for (final id in windows) ChatWindowFrame.encode(id, _frame, ChatWindowSize.m)]
    ..bigWindow = onScreen.contains(NativeChat.bigWindowId) || bigRoom != null
        ? ChatBigWindow.encode(ChatBigWindow(roomId: bigRoom), const Rect.fromLTWH(200, 40, 360, 520))
        : [];
}

void main() {
  useTempPathProvider();
  var ready = false;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    NativeChat.prefs
      ..introSeen = true
      ..inAppEnabled = true
      ..launcher = ChatLauncher.bubble
      ..launcherTap = ChatLauncherTap.full
      ..miniBubbles = true
      ..reopenChats = true
      ..onScreen = []
      ..windows = []
      ..bigWindow = []
      ..archived = {}
      ..ignored = {}
      ..drafts = {};
    ready = false;
    NativeChat.sessionOk = () => ready;
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
    NativeChat.sessionOk = () => true;
    NativeChat.isUnlisted = (id) => NativeChat.controller.isUnlisted(id);
    Get.reset();
  });

  group('saved', () {
    test('saves open windows back to front', () {
      NativeChat.openQuickWindow('global');
      NativeChat.openBigWindow();
      NativeChat.setBigWindowRoom('dm:7');
      NativeChat.toggleBigWindowFull();
      NativeChat.openQuickWindow('faction');
      NativeChat.saveOnScreen();
      final back = ChatOnScreen.decode(NativeChat.prefs.onScreen);
      expect(back.stack, ['global', NativeChat.bigWindowId, 'faction']);
      expect(back.full, isTrue);
      expect(back.screen, isFalse);

      NativeChat.screenOpen.value = true;
      NativeChat.saveOnScreen();
      expect(ChatOnScreen.decode(NativeChat.prefs.onScreen).screen, isTrue);
      expect(ChatOnScreen.decode(NativeChat.prefs.onScreen).screenRoom, isNull);
    });

    test('room ids with colons survive, junk is dropped', () {
      const shown = ChatOnScreen(stack: ['dm:7', NativeChat.bigWindowId], screen: true, screenRoom: 'dm:9');
      final back = ChatOnScreen.decode([...shown.encode(), '', ':other', 'dm:7']);
      expect(back.stack, ['dm:7', NativeChat.bigWindowId]);
      expect(back.screenRoom, 'dm:9');
      expect(back.full, isFalse);
      expect(ChatOnScreen.decode(const []).isEmpty, isTrue);
    });
  });

  group('reopen', () {
    testWidgets('off, open windows come back as bubbles only', (tester) async {
      NativeChat.prefs.reopenChats = false;
      _leftOpen(['global', NativeChat.bigWindowId], windows: ['global'], bigRoom: 'dm:7');
      await _pumpApp(tester);
      NativeChat.restoreWindows();
      ready = true;
      NativeChat.tryReopen();
      await tester.pump(const Duration(milliseconds: 400));
      expect(NativeChat.quickWindows.value, isEmpty);
      expect(NativeChat.bigWindow.value?.minimized, isTrue);
      expect(NativeChat.minimized.value.map((m) => m.roomId), ['global']);
    });

    testWidgets('bubbles while the chat connects, then windows as they were', (tester) async {
      _leftOpen(['global', NativeChat.bigWindowId, 'dm:3'], windows: ['trade', 'global', 'dm:3'], bigRoom: 'dm:7');
      await _pumpApp(tester);
      NativeChat.restoreWindows();
      await tester.pump(const Duration(seconds: 5));
      expect(NativeChat.quickWindows.value, isEmpty);
      expect(NativeChat.minimized.value.map((m) => m.roomId), ['trade', 'global', 'dm:3']);

      ready = true;
      NativeChat.tryReopen();
      await tester.pump(const Duration(milliseconds: 400));
      expect(NativeChat.quickWindows.value, ['global', 'dm:3']);
      expect(NativeChat.stackOrder, ['global', NativeChat.bigWindowId, 'dm:3']);
      expect(NativeChat.bigWindow.value?.roomId, 'dm:7');
      expect(NativeChat.minimized.value.map((m) => m.roomId), ['trade']);
      await _closeAll(tester);
    });

    testWidgets('past the wait it stays as bubbles and never opens late', (tester) async {
      _leftOpen(['global'], windows: ['global']);
      await _pumpApp(tester);
      NativeChat.restoreWindows();
      await tester.pump(const Duration(seconds: 21));
      ready = true;
      NativeChat.tryReopen();
      await tester.pump(const Duration(milliseconds: 400));
      expect(NativeChat.quickWindows.value, isEmpty);
      expect(NativeChat.minimized.value.map((m) => m.roomId), ['global']);
    });

    testWidgets('nothing is saved over it until the player changes something', (tester) async {
      _leftOpen(['global'], windows: ['global']);
      await _pumpApp(tester);
      NativeChat.restoreWindows();
      NativeChat.saveOnScreen();
      expect(NativeChat.prefs.onScreen, ['global']);
      await tester.pump(const Duration(seconds: 21));
      NativeChat.saveOnScreen();
      expect(NativeChat.prefs.onScreen, ['global']);

      NativeChat.openQuickWindow('dm:3');
      expect(NativeChat.prefs.onScreen, ['dm:3']);
      await _closeAll(tester);
    });

    testWidgets('a room Torn no longer lists stays closed', (tester) async {
      NativeChat.isUnlisted = (id) => id == 'poker';
      _leftOpen(['poker', 'global'], windows: ['poker', 'global']);
      await _pumpApp(tester);
      NativeChat.restoreWindows();
      ready = true;
      NativeChat.tryReopen();
      await tester.pump(const Duration(milliseconds: 400));
      expect(NativeChat.quickWindows.value, ['global']);
      await _closeAll(tester);
    });

    testWidgets('without small bubbles the window keeps its saved place', (tester) async {
      NativeChat.prefs
        ..launcher = ChatLauncher.menuHeader
        ..miniBubbles = false;
      _leftOpen(['global'], windows: ['global']);
      await _pumpApp(tester);
      NativeChat.restoreWindows();
      expect(NativeChat.minimized.value, isEmpty);
      NativeChat.openQuickWindow('dm:3');
      await tester.pump(const Duration(milliseconds: 400));
      expect(NativeChat.prefs.windows.map((e) => ChatWindowFrame.decode(e).frame), contains(_frame));

      ready = true;
      NativeChat.tryReopen();
      await tester.pump(const Duration(milliseconds: 400));
      expect(NativeChat.quickWindows.value, ['global', 'dm:3']);
      await _closeAll(tester);
    });

    testWidgets('a window asked meanwhile stays in front and the cap holds', (tester) async {
      _leftOpen(['global', 'dm:3', 'trade'], windows: ['global', 'dm:3', 'trade']);
      await _pumpApp(tester);
      NativeChat.restoreWindows();
      NativeChat.openQuickWindow('dm:5');
      ready = true;
      NativeChat.tryReopen();
      await tester.pump(const Duration(milliseconds: 400));
      expect(NativeChat.quickWindows.value, ['dm:3', 'trade', 'dm:5']);
      expect(NativeChat.minimized.value.map((m) => m.roomId), contains('global'));
      await _closeAll(tester);
    });

    testWidgets('archived and ignored private chats reopen', (tester) async {
      NativeChat.prefs
        ..archived = {'dm:7'}
        ..ignored = {8: 'someone'};
      _leftOpen(['dm:7', 'dm:8'], windows: ['dm:7', 'dm:8']);
      await _pumpApp(tester);
      NativeChat.restoreWindows();
      ready = true;
      NativeChat.tryReopen();
      await tester.pump(const Duration(milliseconds: 400));
      expect(NativeChat.quickWindows.value, ['dm:7', 'dm:8']);
      await _closeAll(tester);
    });

    testWidgets('the full chat reopens on its room once dialogs are gone', (tester) async {
      _leftOpen(const ChatOnScreen(screen: true, screenRoom: 'dm:3').encode());
      final key = await _pumpApp(tester);
      NativeChat.restoreWindows();
      unawaited(showDialog<void>(context: key.currentContext!, builder: (_) => const AlertDialog(content: Text('news'))));
      await tester.pump(const Duration(milliseconds: 400));
      ready = true;
      NativeChat.tryReopen();
      await tester.pump(const Duration(milliseconds: 400));
      expect(NativeChat.screenOpen.value, isFalse);

      key.currentState!.pop();
      await tester.pump(const Duration(milliseconds: 400));
      expect(NativeChat.screenOpen.value, isTrue);
      expect(tester.widget<ChatPage>(find.byType(ChatPage, skipOffstage: false)).initialRoomId, 'dm:3');
      key.currentState!.pop();
      await tester.pump(const Duration(milliseconds: 400));
    });

    testWidgets('the full chat waits for a dialog in the side menu navigator', (tester) async {
      _leftOpen(const ChatOnScreen(screen: true).encode());
      final inner = GlobalKey<NavigatorState>();
      final key = await _pumpApp(
        tester,
        home: Navigator(
          key: inner,
          observers: [NativeChat.homeWatch],
          onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => const Scaffold()),
        ),
      );
      NativeChat.restoreWindows();
      unawaited(
        showDialog<void>(
          context: inner.currentContext!,
          useRootNavigator: false,
          builder: (_) => const AlertDialog(content: Text('news')),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      ready = true;
      NativeChat.tryReopen();
      await tester.pump(const Duration(milliseconds: 400));
      expect(NativeChat.screenOpen.value, isFalse);

      inner.currentState!.pop();
      await tester.pump(const Duration(milliseconds: 400));
      expect(NativeChat.screenOpen.value, isTrue);
      key.currentState!.pop();
      await tester.pump(const Duration(milliseconds: 400));
    });

    testWidgets('a chat opened from a notification wins over the saved one', (tester) async {
      _leftOpen(['global'], windows: ['global']);
      final key = await _pumpApp(tester);
      NativeChat.restoreWindows();
      unawaited(NativeChat.open(key.currentState!, roomId: 'dm:3'));
      await tester.pump(const Duration(milliseconds: 400));
      ready = true;
      NativeChat.tryReopen();
      await tester.pump(const Duration(milliseconds: 400));
      expect(NativeChat.quickWindows.value, isEmpty);
      key.currentState!.pop();
      await tester.pump(const Duration(milliseconds: 400));
    });
  });
}
