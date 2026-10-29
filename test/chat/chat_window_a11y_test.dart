import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/widgets/chat/chat_overlay.dart';
import 'package:torn_pda/widgets/chat/chat_quick_window.dart';
import 'package:torn_pda/widgets/chat/chat_toast.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';
import 'package:torn_pda/widgets/webviews/split_divider.dart';

import 'chat_fakes.dart';

Future<void> _pumpApp(WidgetTester tester, {GlobalKey<NavigatorState>? navigator}) async {
  final key = navigator ?? GlobalKey<NavigatorState>();
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
      home: const Scaffold(body: Center(child: Text('page below'))),
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

List<String> _listen(WidgetTester tester) {
  final spoken = <String>[];
  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, (message) async {
    final map = message as Map<Object?, Object?>;
    if (map['type'] == 'announce') spoken.add((map['data'] as Map<Object?, Object?>)['message']! as String);
  });
  addTearDown(() => messenger.setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, null));
  return spoken;
}

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
    splitDividerRect.value = null;
  });

  tearDown(() {
    NativeChat.quickWindows.value = const [];
    NativeChat.minimized.value = const [];
    NativeChat.bigWindow.value = null;
    NativeChat.tornTabMissing.value = false;
    chatHeldToast.value = null;
    Get.reset();
  });

  test('a nudge takes half the free room, then stops at the edge', () {
    const area = Rect.fromLTWH(0, 0, 400, 800);
    const frame = Rect.fromLTWH(30, 200, 340, 400);
    expect(ChatWindowFrame.moves(frame, area).keys, ['Move up', 'Move down', 'Move left', 'Move right']);

    final up = ChatWindowFrame.nudge(frame, area, ChatWindowFrame.moves(frame, area)['Move up']!);
    expect(up, const Rect.fromLTWH(30, 0, 340, 400));
    expect(ChatWindowFrame.moves(up, area).keys, isNot(contains('Move up')));

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

  testWidgets('the paused notice is announced and closes from its own button', (tester) async {
    final semantics = tester.ensureSemantics();
    final spoken = _listen(tester);
    await _pumpApp(tester);
    NativeChat.quickWindows.value = ['global'];
    await _settle(tester);

    NativeChat.tornTabMissing.value = true;
    await _settle(tester);
    expect(spoken, ['Chat paused. Back on a Torn tab to keep chatting']);
    expect(_page, findsOne);
    final notice = find.semantics.byLabel(RegExp('^Chat paused'));
    expect(notice.evaluate().single.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);

    final close = find.semantics.byPredicate((node) => node.tooltip == 'Close chat windows');
    expect(close.evaluate().single.rect.width, lessThan(100));
    tester.semantics.tap(close);
    await _settle(tester);
    expect(NativeChat.quickWindows.value, isEmpty);
    semantics.dispose();
  });

  testWidgets('with a screen reader, a toast with Undo waits above the windows', (tester) async {
    final semantics = tester.ensureSemantics();
    final spoken = _listen(tester);
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      accessibleNavigation: true,
    );
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await _pumpApp(tester);
    NativeChat.quickWindows.value = ['global'];
    await _settle(tester);

    final events = <String>[];
    chatToast(
      'Removed from targets',
      seconds: 4,
      action: 'Undo',
      onAction: () => events.add('undo'),
      onClose: () => events.add('close'),
    );
    await tester.pump(const Duration(seconds: 20));
    expect(spoken, ['Removed from targets. Undo available']);
    expect(find.semantics.byLabel('Removed from targets'), findsOne);

    tester.semantics.tap(find.semantics.byLabel('Undo'));
    await tester.pump();
    expect(events, ['undo', 'close']);
    expect(find.text('Removed from targets'), findsNothing);

    chatToast('1 chat marked as read', action: 'Undo', onClose: () => events.add('closed again'));
    await tester.pump(const Duration(seconds: 20));
    tester.semantics.tap(find.semantics.byPredicate((node) => node.tooltip == 'Dismiss'));
    await tester.pump();
    expect(events.last, 'closed again');
    expect(find.text('1 chat marked as read'), findsNothing);
    semantics.dispose();
  });

  testWidgets('with less motion, a minimized chat pops in at full size', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await _pumpApp(tester);
    NativeChat.minimized.value = const [ChatMinimized('faction', window: true)];
    await tester.pump();
    final scale = tester.widget<Transform>(
      find.descendant(of: find.byKey(const ValueKey('mini:faction')), matching: find.byType(Transform)).first,
    );
    expect(scale.transform.storage.first, 1);
  });
}
