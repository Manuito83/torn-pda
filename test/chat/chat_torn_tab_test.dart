import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/chat/chat_theme.dart';
import 'package:torn_pda/widgets/chat/chat_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

import 'chat_fakes.dart';

void main() {
  useTempPathProvider();

  const torn = 'https://www.torn.com/index.php';
  const other = 'https://www.example.org';
  final original = NativeChat.sendTouch;
  final originalSession = NativeChat.sessionOk;
  final originalLoading = NativeChat.isLoading;

  setUp(() async {
    await Prefs().setWebViewSecondaryTabs('{"tabsSave":[]}');
    await Prefs().setWebViewMainTab('{"tabsSave":[]}');
    await Prefs().setSplitBrowsersLayout('');
    await Prefs().setWebViewLastActiveTab(0);
    NativeChat.resetTabs();
    NativeChat.isLive = (_) => true;
    NativeChat.prefs.inAppEnabled = true;
    NativeChat.keyValid.value = true;
  });

  tearDown(() {
    NativeChat.resetTabs();
    NativeChat.isLive = NativeChat.tabAlive;
    NativeChat.sendTouch = original;
    NativeChat.sessionOk = originalSession;
    NativeChat.isLoading = originalLoading;
    NativeChat.setTabGrace(30);
  });

  Future<WebViewProvider> browser(List<String> urls) async {
    final web = WebViewProvider()..splitScreenPosition = WebViewSplitPosition.left;
    for (var i = 0; i < urls.length; i++) {
      await web.addTab(url: urls[i], tabUid: 'tab$i');
    }
    return web;
  }

  group('torn tab open', () {
    test('only the shown tab counts', () async {
      final web = await browser([other, torn, torn]);
      expect(NativeChat.tornTabOpen(web), isFalse);
      web.activateTab(1);
      expect(NativeChat.tornTabOpen(web), isTrue);
      web.activateTab(0);
      expect(NativeChat.tornTabOpen(web), isFalse);
    });

    test('a tab that is not mounted is not live', () async {
      NativeChat.isLive = NativeChat.tabAlive;
      final web = await browser([torn]);
      expect(NativeChat.tornTabOpen(web), isFalse);
    });

    test('a dead page does not count', () async {
      final web = await browser([torn, torn]);
      NativeChat.isLive = (tab) => tab.id != 'tab0';
      expect(NativeChat.tornTabOpen(web), isFalse);
      web.activateTab(1);
      expect(NativeChat.tornTabOpen(web), isTrue);
    });

    test('either side of a split browser counts', () async {
      var web = await browser([other, torn, other]);
      web.updateSplitScreenWidth(1000);
      web.moveTabToOtherGroup(1);
      expect(NativeChat.tornTabOpen(web), isTrue);

      web = await browser([torn, other, other]);
      web.updateSplitScreenWidth(1000);
      web.moveTabToOtherGroup(2);
      expect(NativeChat.tornTabOpen(web), isTrue);
    });

    test('a Torn tab behind the shown ones does not count', () async {
      final web = await browser([other, torn, other]);
      web.updateSplitScreenWidth(1000);
      web.moveTabToOtherGroup(2);
      expect(NativeChat.tornTabOpen(web), isFalse);
    });

    test('a shown tab that is still loading counts', () async {
      NativeChat.isLive = (_) => false;
      NativeChat.isLoading = (_) => true;
      final web = await browser([torn]);
      expect(NativeChat.tornTabOpen(web), isFalse);
      web.browserShowInForeground = true;
      expect(NativeChat.tornTabOpen(web), isTrue);
      expect(NativeChat.tornTabOpen(web, loaded: true), isFalse);
    });

    test('any Torn tab is known, awake or not', () async {
      NativeChat.isLive = (_) => false;
      final web = await browser([other]);
      NativeChat.watchTabs(web);
      expect(NativeChat.tornTabExists.value, isFalse);
      await web.addTab(url: torn, tabUid: 'tabT');
      expect(NativeChat.tornTabExists.value, isTrue);
      await web.removeTab(position: 1);
      expect(NativeChat.tornTabExists.value, isFalse);
    });

    test('a shown tab that is not mounted does not count', () async {
      NativeChat.isLive = (_) => false;
      NativeChat.isLoading = NativeChat.tabLoading;
      final web = await browser([torn]);
      web.browserShowInForeground = true;
      expect(NativeChat.tornTabOpen(web), isFalse);
    });

    test('tornTabIndex falls back to the tab made for the chat', () {
      const urls = [other, other, other];
      expect(NativeChat.tornTabIndex(const [other, other, null], [0, 1, 2], made: 2), 2);
      expect(NativeChat.tornTabIndex(urls, [0, 1, 2], made: 2), isNull);
      expect(NativeChat.tornTabIndex(urls, [0, 1, 2]), isNull);
      expect(NativeChat.tornTabIndex(const [torn, other], [0, 1], made: 1), 0);
    });

    test('tornTabIndex prefers a live tab', () {
      const urls = [torn, other, torn];
      expect(NativeChat.tornTabIndex(urls, [0, 1, 2], live: (i) => i == 2), 2);
      expect(NativeChat.tornTabIndex(urls, [0, 1, 2], live: (_) => false), 0);
      expect(NativeChat.tornTabIndex(const [other], [0], live: (_) => true), isNull);
    });
  });

  group('pause', () {
    late WebViewProvider web;
    var live = true;

    void change({required bool torn}) {
      live = torn;
      NativeChat.watchTabs(web);
    }

    setUp(() => live = true);

    Future<void> open(WidgetTester tester) async {
      web = (await tester.runAsync(() => browser([torn])))!;
      NativeChat.isLive = (_) => live;
      addTearDown(NativeChat.resetTabs);
      NativeChat.watchTabs(web);
    }

    testWidgets('comes after the margin and ends at once', (tester) async {
      await open(tester);
      expect(NativeChat.tornTabMissing.value, isFalse);

      change(torn: false);
      await tester.pump(const Duration(seconds: 29));
      expect(NativeChat.tornTabMissing.value, isFalse);
      await tester.pump(const Duration(seconds: 2));
      expect(NativeChat.tornTabMissing.value, isTrue);

      change(torn: true);
      expect(NativeChat.tornTabMissing.value, isFalse);
    });

    testWidgets('coming back restarts the margin', (tester) async {
      await open(tester);

      change(torn: false);
      await tester.pump(const Duration(seconds: 10));
      change(torn: true);
      await tester.pump(const Duration(seconds: 1));
      change(torn: false);
      await tester.pump(const Duration(seconds: 29));
      expect(NativeChat.tornTabMissing.value, isFalse);
      await tester.pump(const Duration(seconds: 2));
      expect(NativeChat.tornTabMissing.value, isTrue);
      change(torn: true);
    });

    testWidgets('a lost live tab keeps the margin with a good session', (tester) async {
      NativeChat.sessionOk = () => true;
      await open(tester);

      change(torn: false);
      await tester.pump(const Duration(seconds: 29));
      expect(NativeChat.tornTabMissing.value, isFalse);
      await tester.pump(const Duration(seconds: 2));
      expect(NativeChat.tornTabMissing.value, isTrue);
      change(torn: true);
    });

    testWidgets('the margin comes from the setting, zero means none', (tester) async {
      NativeChat.setTabGrace(5);
      await open(tester);
      change(torn: false);
      await tester.pump(const Duration(seconds: 4));
      expect(NativeChat.tornTabMissing.value, isFalse);
      await tester.pump(const Duration(seconds: 2));
      expect(NativeChat.tornTabMissing.value, isTrue);
      change(torn: true);

      NativeChat.setTabGrace(0);
      change(torn: false);
      expect(NativeChat.tornTabMissing.value, isTrue);
      change(torn: true);
    });

    testWidgets('no live tab at start pauses without the margin', (tester) async {
      NativeChat.sessionOk = () => true;
      live = false;
      await open(tester);
      await tester.pump(const Duration(seconds: 1));
      expect(NativeChat.tornTabMissing.value, isFalse);
      await tester.pump(const Duration(seconds: 2));
      expect(NativeChat.tornTabMissing.value, isTrue);
      change(torn: true);
    });

    testWidgets('no live tab at start keeps the margin without a session', (tester) async {
      NativeChat.sessionOk = () => false;
      live = false;
      await open(tester);
      await tester.pump(const Duration(seconds: 25));
      expect(NativeChat.tornTabMissing.value, isFalse);
      await tester.pump(const Duration(seconds: 6));
      expect(NativeChat.tornTabMissing.value, isTrue);
      change(torn: true);
    });

    testWidgets('a tab alive within the settle time never pauses', (tester) async {
      NativeChat.sessionOk = () => true;
      live = false;
      await open(tester);
      await tester.pump(const Duration(seconds: 1));
      live = true;
      await tester.pump(const Duration(seconds: 1));
      expect(NativeChat.tornTabMissing.value, isFalse);
      await tester.pump(const Duration(seconds: 5));
      expect(NativeChat.tornTabMissing.value, isFalse);
    });

    testWidgets('opening a window while paused leaves the browser alone', (tester) async {
      await open(tester);
      NativeChat.tornTabMissing.value = true;
      final tabs = web.tabList.length;
      NativeChat.openQuickWindow('dm:1');
      await tester.pump(const Duration(seconds: 5));
      expect(NativeChat.quickWindows.value, ['dm:1']);
      expect(web.browserShowInForeground, isFalse);
      expect(web.tabList.length, tabs);
      NativeChat.closeQuickWindow();
      NativeChat.tornTabMissing.value = false;
    });

    testWidgets('opening the chat page while paused leaves the browser alone', (tester) async {
      await open(tester);
      final key = GlobalKey<NavigatorState>();
      NativeChat.navigatorKey = key;
      addTearDown(() => NativeChat.navigatorKey = null);
      await tester.pumpWidget(
        ChangeNotifierProvider<WebViewProvider>.value(
          value: web,
          child: MaterialApp(navigatorKey: key, home: const SizedBox()),
        ),
      );
      NativeChat.tornTabMissing.value = true;
      final tabs = web.tabList.length;
      unawaited(NativeChat.open(key.currentState!));
      await tester.pump(const Duration(seconds: 5));
      expect(NativeChat.screenOpen.value, isTrue);
      expect(web.browserShowInForeground, isFalse);
      expect(web.tabList.length, tabs);
      key.currentState!.popUntil((route) => route.isFirst);
      await tester.pump();
      NativeChat.tornTabMissing.value = false;
    });

    testWidgets('a tab that wakes ends the pause', (tester) async {
      live = false;
      await open(tester);
      await tester.pump(const Duration(seconds: 31));
      expect(NativeChat.tornTabMissing.value, isTrue);

      live = true;
      await tester.pump(const Duration(seconds: 1));
      expect(NativeChat.tornTabMissing.value, isFalse);
    });
  });

  group('gate', () {
    var taps = 0;

    Future<void> show(WidgetTester tester) async {
      taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ChatPausedGate(
                    child: Scaffold(
                      body: TextButton(onPressed: () => taps++, child: const Text('page')),
                    ),
                  ),
                ),
              ),
              child: const Text('chat'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('chat'));
      await tester.pumpAndSettle();
    }

    testWidgets('blocks the page behind the card', (tester) async {
      await show(tester);
      await tester.tap(find.text('page'));
      expect(taps, 1);

      NativeChat.tornTabMissing.value = true;
      await tester.pump();
      await tester.tap(find.text('page'), warnIfMissed: false);
      expect(taps, 1);

      NativeChat.tornTabMissing.value = false;
      await tester.pump();
      await tester.tap(find.text('page'));
      expect(taps, 2);
    });

    testWidgets('a dialog open before the pause is closed', (tester) async {
      await show(tester);
      unawaited(showDialog<void>(context: tester.element(find.text('page')), builder: (_) => const Text('dialog')));
      await tester.pumpAndSettle();
      expect(find.text('dialog'), findsOneWidget);

      NativeChat.tornTabMissing.value = true;
      await tester.pumpAndSettle();
      expect(find.text('dialog'), findsNothing);
      expect(find.text('page'), findsOneWidget);
      NativeChat.tornTabMissing.value = false;
    });

    testWidgets('close chat only closes it', (tester) async {
      final web = (await tester.runAsync(() => browser([other])))!;
      NativeChat.watchTabs(web);
      await show(tester);
      NativeChat.tornTabMissing.value = true;
      await tester.pump();
      await tester.tap(find.text('Close chat'));
      await tester.pumpAndSettle();
      expect(find.text('page'), findsNothing);
      expect(find.text('chat'), findsOneWidget);
      expect(web.browserShowInForeground, isFalse);
      expect(web.tabList.length, 1);
      NativeChat.resetTabs();
    });
  });

  group('background', () {
    testWidgets('does not count as losing the tab', (tester) async {
      final web = (await tester.runAsync(() => browser([torn])))!;
      NativeChat.isLive = (_) => false;
      addTearDown(NativeChat.resetTabs);
      NativeChat.watchTabs(web);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 20));
      expect(NativeChat.tornTabMissing.value, isFalse);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    });

    testWidgets('a chat that is off never pauses', (tester) async {
      final web = (await tester.runAsync(() => browser([torn])))!;
      NativeChat.isLive = (_) => false;
      NativeChat.keyValid.value = false;
      addTearDown(NativeChat.resetTabs);
      NativeChat.watchTabs(web);
      await tester.pump(const Duration(seconds: 20));
      expect(NativeChat.tornTabMissing.value, isFalse);
    });
  });

  group('touch', () {
    test('never goes out while paused', () {
      var sent = 0;
      NativeChat.sendTouch = () async => sent++;
      NativeChat.tornTabMissing.value = true;
      NativeChat.touch();
      expect(sent, 0);
      NativeChat.tornTabMissing.value = false;
      NativeChat.touch();
      expect(sent, 1);
    });

    testWidgets('a tap touches, a scroll does not', (tester) async {
      var sent = 0;
      NativeChat.sendTouch = () async => sent++;
      await tester.pumpWidget(
        MaterialApp(
          home: ChatTaps(
            child: ListView(children: [for (var i = 0; i < 50; i++) SizedBox(height: 60, child: Text('row $i'))]),
          ),
        ),
      );
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(sent, 0);
      await tester.tap(find.text('row 6'));
      expect(sent, 1);
    });
  });
}
