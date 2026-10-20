import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

import 'chat_fakes.dart';

void main() {
  useTempPathProvider();

  const torn = 'https://www.torn.com/index.php';
  const other = 'https://www.example.org';
  final original = NativeChat.sendTouch;

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
      await tester.pump(const Duration(seconds: 14));
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
      await tester.pump(const Duration(seconds: 14));
      expect(NativeChat.tornTabMissing.value, isFalse);
      await tester.pump(const Duration(seconds: 2));
      expect(NativeChat.tornTabMissing.value, isTrue);
      change(torn: true);
    });

    testWidgets('a tab that wakes without a notice ends it', (tester) async {
      live = false;
      await open(tester);
      await tester.pump(const Duration(seconds: 16));
      expect(NativeChat.tornTabMissing.value, isTrue);

      live = true;
      await tester.pump(const Duration(seconds: 1));
      expect(NativeChat.tornTabMissing.value, isFalse);
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
    final start = DateTime(2026, 10, 20, 12);

    test('goes out at most every 15 seconds', () {
      var sent = 0;
      NativeChat.sendTouch = () async => sent++;
      NativeChat.touch(start);
      NativeChat.touch(start.add(const Duration(seconds: 10)));
      NativeChat.touch(start.add(const Duration(seconds: 14)));
      expect(sent, 1);
      NativeChat.touch(start.add(const Duration(seconds: 15)));
      expect(sent, 2);
      NativeChat.touch(start.add(const Duration(seconds: 20)));
      expect(sent, 2);
    });

    test('never goes out while paused', () {
      var sent = 0;
      NativeChat.sendTouch = () async => sent++;
      NativeChat.tornTabMissing.value = true;
      NativeChat.touch(start);
      expect(sent, 0);
      NativeChat.tornTabMissing.value = false;
      NativeChat.touch(start.add(const Duration(seconds: 1)));
      expect(sent, 1);
    });
  });
}
