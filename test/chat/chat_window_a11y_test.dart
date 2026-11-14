import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torn_pda/pages/chat/chat_settings_page.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/widgets/chat/chat_overlay.dart';
import 'package:torn_pda/widgets/chat/chat_quick_window.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

import 'chat_fakes.dart';

Future<void> _pumpApp(WidgetTester tester, {GlobalKey<NavigatorState>? navigator, Widget? home}) async {
  final key = navigator ?? GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    ChangeNotifierProvider<WebViewProvider>(
      create: (_) => WebViewProvider(),
      child: MaterialApp(
        navigatorKey: key,
        navigatorObservers: [BotToastNavigatorObserver(), NativeChat.rootWatch],
        builder: (context, child) => Stack(
          children: [
            BotToastInit()(context, child),
            ChatOverlay(navigatorKey: key),
          ],
        ),
        home: home ?? const Scaffold(body: Center(child: Text('page below'))),
      ),
    ),
  );
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) => tester.pump(const Duration(milliseconds: 400));

Set<String> _actions(SemanticsNode node) => {
  for (final id in node.getSemanticsData().customSemanticsActionIds ?? const <int>[])
    ?CustomSemanticsAction.getAction(id)?.label,
};

FinderBase<SemanticsNode> _offering(String action) =>
    find.semantics.byPredicate((node) => _actions(node).contains(action));

final _page = find.semantics.byLabel('page below');

void main() {
  useTempPathProvider();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    NativeChat.prefs
      ..introSeen = true
      ..inAppEnabled = true
      ..launcher = ChatLauncher.bubble
      ..miniBubbles = true
      ..bubbleSpot = []
      ..windows = []
      ..windowFrame = [];
    NativeChat.keyValid.value = true;
    NativeChat.quickWindows.value = const [];
    NativeChat.minimized.value = const [];
    NativeChat.bigWindow.value = null;
    NativeChat.screenOpen.value = false;
    NativeChat.drawerOpen.value = false;
    NativeChat.tornTabMissing.value = false;
  });

  tearDown(() {
    NativeChat.quickWindows.value = const [];
    NativeChat.minimized.value = const [];
    NativeChat.bigWindow.value = null;
    NativeChat.tornTabMissing.value = false;
    NativeChat.dialOpen.value = false;
    NativeChat.controller.heldToast.value = null;
    Get.reset();
  });

  test('a nudge takes half the free room, then stops at the edge', () {
    const area = Rect.fromLTWH(0, 0, 400, 800);
    const frame = Rect.fromLTWH(30, 200, 340, 400);
    var moved = frame;
    Map<String?, VoidCallback> moves(Rect from) => {
      for (final e in ChatWindowFrame.semanticMoves(from, area, (to) => moved = to).entries) e.key.label: e.value,
    };
    expect(moves(frame).keys, ['Move up', 'Move down', 'Move left', 'Move right']);

    moves(frame)['Move up']!();
    final up = moved;
    expect(up, const Rect.fromLTWH(30, 0, 340, 400));
    expect(moves(up).keys, isNot(contains('Move up')));

    final down = ChatWindowFrame.nudge(up, area, const Offset(0, 1));
    expect(down.top, 200);
    expect(ChatWindowFrame.nudge(down, area, const Offset(0, 1)).bottom, 800);
    expect(ChatWindowFrame.nudge(frame, area, const Offset(1, 0)).right, 400);
  });

  testWidgets('an open window hides the page below until back puts it away', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pumpApp(tester);
    expect(_page, findsOne);

    NativeChat.quickWindows.value = ['global'];
    await _settle(tester);
    expect(_page, findsNothing);
    expect(find.semantics.byLabel(RegExp(r'^Chat, ')), findsNothing);
    expect(find.semantics.byLabel(RegExp(r'chat window$')), findsOne);

    await tester.binding.handlePopRoute();
    await _settle(tester);
    expect(NativeChat.quickWindows.value, isEmpty);
    expect(NativeChat.minimized.value.map((m) => m.roomId), ['global']);
    expect(_page, findsOne);

    NativeChat.quickWindows.value = ['global'];
    await _settle(tester);
    tester.semantics.dismiss(find.semantics.byLabel(RegExp(r'chat window$')));
    await _settle(tester);
    expect(NativeChat.quickWindows.value, isEmpty);
    expect(_page, findsOne);
    semantics.dispose();
  });

  testWidgets('without bubbles to land in, back closes the window', (tester) async {
    NativeChat.prefs
      ..launcher = ChatLauncher.menuBar
      ..miniBubbles = false;
    await _pumpApp(tester);
    NativeChat.quickWindows.value = ['global', 'trade'];
    await _settle(tester);

    await tester.binding.handlePopRoute();
    await _settle(tester);
    expect(NativeChat.quickWindows.value, ['global']);
    expect(NativeChat.minimized.value, isEmpty);
    NativeChat.closeQuickWindow();
    await tester.pump(const Duration(seconds: 21));
  });

  testWidgets('a dialog over an open window stays reachable', (tester) async {
    final semantics = tester.ensureSemantics();
    final key = GlobalKey<NavigatorState>();
    await _pumpApp(tester, navigator: key);
    NativeChat.quickWindows.value = ['global'];
    await _settle(tester);
    expect(_page, findsNothing);

    unawaited(
      showDialog<void>(
        context: key.currentContext!,
        builder: (_) => const AlertDialog(content: Text('a dialog')),
      ),
    );
    await _settle(tester);
    await _settle(tester);
    expect(find.semantics.byLabel('a dialog'), findsOne);

    key.currentState!.pop();
    await _settle(tester);
    expect(_page, findsNothing);
    semantics.dispose();
  });

  testWidgets('window and bubble move without dragging', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pumpApp(tester);
    NativeChat.quickWindows.value = ['global'];
    await _settle(tester);
    final before = tester.getRect(find.byType(ChatQuickWindow));

    tester.semantics.customAction(_offering('Move up'), const CustomSemanticsAction(label: 'Move up'));
    await _settle(tester);
    final after = tester.getRect(find.byType(ChatQuickWindow));
    expect(after.top, lessThan(before.top));
    expect(after.left, before.left);
    expect(_offering('Move up'), findsNothing);
    expect(_offering('Move down'), findsOne);

    NativeChat.closeQuickWindow();
    await _settle(tester);
    final bubble = find.semantics.byLabel(RegExp(r'^Chat, '));
    Future<List<String>> move(String label) async {
      tester.semantics.customAction(bubble, CustomSemanticsAction(label: label));
      await _settle(tester);
      return NativeChat.prefs.bubbleSpot.take(2).toList();
    }

    Iterable<String> moves() => _actions(bubble.evaluate().single).where((a) => a.startsWith('Move'));
    expect(moves(), unorderedEquals(['Move up', 'Move down', 'Move left']));
    expect(await move('Move left'), ['0.500', '0.700']);
    expect(await move('Move left'), ['0.000', '0.700']);
    expect(moves(), isNot(contains('Move left')));
    expect(await move('Move right'), ['0.500', '0.700']);
    expect(await move('Move right'), ['1.000', '0.700']);
    expect(await move('Move down'), ['1.000', '1.000']);
    expect(await move('Move up'), ['1.000', '0.500']);
    expect(await move('Move up'), ['1.000', '0.000']);
    semantics.dispose();
  });

  testWidgets('the full chat, chat settings and the speed dial stay readable under a window', (tester) async {
    final semantics = tester.ensureSemantics();
    final key = GlobalKey<NavigatorState>();
    // Like the drawer's own navigator
    final drawer = Navigator(
      onGenerateRoute: (_) => MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Center(child: Text('page below'))),
      ),
    );
    await _pumpApp(tester, navigator: key, home: drawer);
    NativeChat.quickWindows.value = ['global'];
    await _settle(tester);
    expect(_page, findsNothing);

    unawaited(NativeChat.open(key.currentState!));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(NativeChat.quickWindows.value, ['global']);
    expect(find.semantics.byPredicate((node) => node.tooltip == 'Open in a window'), findsOne);

    key.currentState!.pop();
    await _settle(tester);
    await _settle(tester);
    expect(_page, findsNothing);
    unawaited(showChatSettingsFrom(tester.element(find.text('page below'))));
    await _settle(tester);
    await _settle(tester);
    expect(find.semantics.byLabel(RegExp('^In-app chat')), findsOne);

    key.currentState!.pop();
    await _settle(tester);
    await _settle(tester);
    NativeChat.dialOpen.value = true;
    await _settle(tester);
    expect(_page, findsOne);
    semantics.dispose();
  });

  testWidgets(
    'on iOS only the big window takes the back swipe',
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    (tester) async {
      final key = GlobalKey<NavigatorState>();
      await _pumpApp(tester, navigator: key);
      final route = MaterialPageRoute<void>(builder: (_) => const Scaffold());
      unawaited(key.currentState!.push(route));
      await _settle(tester);
      await _settle(tester);
      NativeChat.quickWindows.value = ['global'];
      await _settle(tester);
      expect(route.popGestureEnabled, isTrue);

      NativeChat.openBigWindow();
      await _settle(tester);
      expect(route.popGestureEnabled, isFalse);
    },
  );

  testWidgets('with a screen reader, Mark all as read goes out after 10 s', (tester) async {
    final semantics = tester.ensureSemantics();
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      accessibleNavigation: true,
    );
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final key = GlobalKey<NavigatorState>();
    NativeChat.prefs.markedUnread = {};
    NativeChat.prefs.setMarkedUnread('faction', true);
    await _pumpApp(tester, navigator: key);
    void markAll() => tester.semantics.customAction(
      find.semantics.byLabel(RegExp(r'^Chat, ')),
      const CustomSemanticsAction(label: 'Mark all as read'),
    );

    markAll();
    await tester.pump(const Duration(seconds: 9));
    expect(NativeChat.prefs.markedUnread, contains('faction'));
    await tester.pump(const Duration(seconds: 2));
    expect(NativeChat.prefs.markedUnread, isNot(contains('faction')));
    expect(find.text('1 chat marked as read'), findsNothing);

    NativeChat.prefs.setMarkedUnread('faction', true);
    markAll();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('1 chat marked as read'), findsOne);
    unawaited(key.currentState!.push(MaterialPageRoute<void>(builder: (_) => const Scaffold())));
    await _settle(tester);
    expect(find.text('1 chat marked as read'), findsNothing);
    key.currentState!.pop();
    await _settle(tester);

    NativeChat.prefs.setMarkedUnread('faction', true);
    markAll();
    await tester.pump();
    tester.semantics.tap(find.semantics.byLabel('Undo'));
    await tester.pump(const Duration(seconds: 11));
    expect(NativeChat.prefs.markedUnread, contains('faction'));
    semantics.dispose();
  });
}
