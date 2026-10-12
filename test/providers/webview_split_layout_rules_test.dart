import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const double wide = 1000;
  const double narrow = 700;

  late Directory tempDir;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('split_layout_rules_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => tempDir.path,
    );
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    tempDir.deleteSync(recursive: true);
  });

  setUp(() async {
    await Prefs().setWebViewSecondaryTabs('{"tabsSave":[]}');
    await Prefs().setWebViewMainTab('{"tabsSave":[]}');
    await Prefs().setSplitBrowsersLayout('');
    await Prefs().setWebViewLastActiveTab(0);
    await Prefs().setSplitScreenWebview('off');
  });

  Future<void> settle() async {
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  Future<WebViewProvider> build({
    int count = 5,
    bool revertsToApp = false,
    WebViewSplitPosition position = WebViewSplitPosition.right,
  }) async {
    final provider = WebViewProvider();
    provider.splitScreenRevertsToApp = revertsToApp;
    provider.splitScreenPosition = position;
    for (var i = 0; i < count; i++) {
      await provider.addTab(url: 'https://www.torn.com/page$i.php', tabUid: 'tab$i');
    }
    provider.updateSplitScreenWidth(wide);
    return provider;
  }

  List<SplitSlotContent?> slots(WebViewProvider p) => [p.splitLeftSlot, p.splitRightSlot];

  int at(WebViewProvider p, String uid) => p.tabList.indexWhere((t) => t.id == uid);

  bool send(WebViewProvider p, String uid) => p.moveTabToOtherGroup(at(p, uid));

  Future<WebViewProvider> buildAppOverMain() async {
    final p = await build();
    send(p, 'tab3');
    p.exitBrowserSlotToApp(p.slotOfGroup(SplitGroup.main));
    expect(slots(p), [SplitSlotContent.apartBrowser, SplitSlotContent.app]);
    expect(p.tabList[p.currentTab].id, 'tab3');
    return p;
  }

  group('widening after changes made on a narrow screen', () {
    test('a tab activated in the group the app covered brings that group back', () async {
      final p = await buildAppOverMain();
      p.updateSplitScreenWidth(narrow);
      p.activateTab(2);

      p.updateSplitScreenWidth(wide);

      expect(p.currentTab, 2);
      expect(slots(p), [SplitSlotContent.apartBrowser, SplitSlotContent.mainBrowser]);
      expect(p.visibleTabIndexForGroup(SplitGroup.main), 2);
      expect(p.isTabVisible(2), isTrue);
      expect(p.focusedGroup, SplitGroup.main);
      expect(p.webViewSplitActive, isFalse);
      await settle();
    });

    test('the same holds when the narrow view shows the app', () async {
      final p = await buildAppOverMain();
      p.splitScreenRevertsToApp = true;
      p.updateSplitScreenWidth(narrow);
      p.browserShowInForeground = true;
      p.activateTab(1);

      p.updateSplitScreenWidth(wide);

      expect(p.currentTab, 1);
      expect(slots(p), [SplitSlotContent.apartBrowser, SplitSlotContent.mainBrowser]);
      await settle();
    });

    test('closing the last apart tab with the app over the main group leaves no blank panel', () async {
      final p = await buildAppOverMain();
      p.updateSplitScreenWidth(narrow);
      await p.removeTab(position: at(p, 'tab3'));

      p.updateSplitScreenWidth(wide);

      expect(slots(p), [SplitSlotContent.app, SplitSlotContent.browser]);
      expect(p.splitApartOpen, isFalse);
      expect(p.splitBrowsersActive, isFalse);
      expect(p.isTabVisible(p.currentTab), isTrue);
      expect(p.webViewSplitActive, isTrue);
      await settle();
    });

    test('a tab activated in the group that stays on screen keeps the app where it was', () async {
      final p = await build();
      send(p, 'tab3');
      send(p, 'tab4');
      p.exitBrowserSlotToApp(p.slotOfGroup(SplitGroup.main));
      p.updateSplitScreenWidth(narrow);
      p.activateTab(at(p, 'tab3'));

      p.updateSplitScreenWidth(wide);

      expect(p.tabList[p.currentTab].id, 'tab3');
      expect(slots(p), [SplitSlotContent.apartBrowser, SplitSlotContent.app]);
      await settle();
    });
  });

  group('Remote Config switch off and on again', () {
    test('a tab activated in the group the app covered brings that group back', () async {
      final p = await buildAppOverMain();
      p.splitBrowsersAllowedRC = false;
      p.activateTab(2);

      p.splitBrowsersAllowedRC = true;

      expect(p.currentTab, 2);
      expect(slots(p), [SplitSlotContent.apartBrowser, SplitSlotContent.mainBrowser]);
      expect(p.isTabVisible(2), isTrue);
      await settle();
    });

    test('closing the last apart tab with the app over the main group leaves no blank panel', () async {
      final p = await buildAppOverMain();
      p.splitBrowsersAllowedRC = false;
      await p.removeTab(position: at(p, 'tab3'));

      p.splitBrowsersAllowedRC = true;

      expect(slots(p), [SplitSlotContent.app, SplitSlotContent.browser]);
      expect(p.splitApartOpen, isFalse);
      await settle();
    });
  });

  group('two browsers need split screen enabled in Settings', () {
    test('with split screen off a tab cannot be sent apart', () async {
      final p = await build(position: WebViewSplitPosition.off);

      expect(p.splitBrowsersAllowed, isFalse);
      expect(p.moveTabToOtherGroup(2), isFalse);
      expect(p.tabList[2].splitApart, isFalse);
      expect(p.splitBrowsersActive, isFalse);
      expect(p.splitRightSlot, isNull);
      await settle();
    });

    test('switching split screen off with two browsers leaves a single view with every tab', () async {
      final p = await build(count: 6);
      p.moveTabToOtherGroup(2);
      p.moveTabToOtherGroup(4);
      final List<String> order = [for (final t in p.tabList) t.id];

      p.splitScreenPosition = WebViewSplitPosition.off;

      expect(p.splitBrowsersActive, isFalse);
      expect(p.splitRightSlot, isNull);
      expect(p.webViewSplitActive, isFalse);
      expect(p.tabIndexesForGroup(SplitGroup.main), [0, 1, 2, 3, 4, 5]);
      expect([for (final t in p.tabList) t.id], order);
      expect(p.moveTabToOtherGroup(3), isFalse);
      await settle();
    });

    test('switching split screen off while the app covers a group leaves no group hidden', () async {
      final p = await buildAppOverMain();

      p.splitScreenPosition = WebViewSplitPosition.off;

      expect(p.splitRightSlot, isNull);
      expect(p.tabIndexesForGroup(SplitGroup.main).length, p.tabList.length);
      await settle();
    });

    test('switching it on again brings back both groups with the app in its slot', () async {
      final p = await build();
      send(p, 'tab3');
      expect(slots(p), [SplitSlotContent.apartBrowser, SplitSlotContent.mainBrowser]);
      p.splitScreenPosition = WebViewSplitPosition.off;

      p.splitScreenPosition = WebViewSplitPosition.right;

      expect(p.tabList[at(p, 'tab3')].splitApart, isTrue);
      expect(p.splitBrowsersActive, isTrue);
      expect(slots(p), [SplitSlotContent.app, SplitSlotContent.mainBrowser]);
      expect(p.tabList[p.currentTab].id, isNot('tab3'));
      expect(p.isTabVisible(p.currentTab), isTrue);
      await settle();
    });

    test('on a narrow screen it also stays in a single view after widening', () async {
      final p = await build();
      p.moveTabToOtherGroup(3);
      p.updateSplitScreenWidth(narrow);
      p.splitScreenPosition = WebViewSplitPosition.off;

      p.updateSplitScreenWidth(wide);

      expect(p.splitRightSlot, isNull);
      expect(p.splitBrowsersActive, isFalse);
      await settle();
    });
  });

  group('tab menu bar height', () {
    test('grows with the items of the open menu so that the top one takes taps', () async {
      final p = await build();
      expect(p.verticalMenuBarHeight, 40);

      p.verticalMenuOpen();
      p.reportVerticalMenuItems(7);
      expect(p.verticalMenuBarHeight, 390);

      p.reportVerticalMenuItems(8);
      expect(p.verticalMenuBarHeight, 50 + 47 * 8);

      p.verticalMenuClose();
      expect(p.verticalMenuBarHeight, 40);
      await settle();
    });
  });
}
