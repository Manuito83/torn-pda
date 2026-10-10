import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const double wide = 1000;

  late Directory tempDir;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('split_on_screen_test');
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
    await Prefs().setSplitScreenWebview('left');
  });

  Future<WebViewProvider> build({int count = 5, WebViewSplitPosition position = WebViewSplitPosition.left}) async {
    final provider = WebViewProvider();
    provider.splitScreenRevertsToApp = false;
    provider.splitScreenPosition = position;
    for (var i = 0; i < count; i++) {
      await provider.addTab(url: 'https://www.torn.com/page$i.php', tabUid: 'tab$i');
    }
    provider.updateSplitScreenWidth(wide);
    return provider;
  }

  List<bool> onScreen(WebViewProvider p) => [for (final t in p.tabList) p.isTabUidOnScreen(t.id)];

  group('isTabUidOnScreen', () {
    test('a single view only shows the focused tab, and only with the browser in front', () async {
      final p = await build(position: WebViewSplitPosition.off);
      expect(p.splitBrowsersActive, isFalse);
      expect(onScreen(p), [false, false, false, false, false]);

      p.browserShowInForeground = true;
      expect(onScreen(p), [true, false, false, false, false]);

      p.activateTab(3);
      expect(onScreen(p), [false, false, false, true, false]);
      expect(p.isTabUidOnScreen('missing'), isFalse);
    });

    test('two browsers show the focused tab and the one of the other panel', () async {
      final p = await build();
      p.browserShowInForeground = true;
      p.moveTabToOtherGroup(2);
      expect(p.splitBrowsersActive, isTrue);
      expect(p.currentTab, 2);
      expect(onScreen(p), [true, false, true, false, false]);

      p.activateTab(3);
      expect(onScreen(p), [false, false, true, true, false]);
    });

    test('a group covered by the app is not on screen', () async {
      final p = await build();
      p.browserShowInForeground = true;
      p.moveTabToOtherGroup(2);

      expect(p.exitBrowserSlotToApp(p.slotOfGroup(SplitGroup.main)), isTrue);
      expect(onScreen(p), [false, false, true, false, false]);

      p.returnBrowserFromApp();
      expect(onScreen(p), [true, false, true, false, false]);
    });
  });

  group('reportChatRemovalChange', () {
    test('changes the tab it is given, not the focused one', () async {
      final p = await build();
      p.browserShowInForeground = true;
      p.moveTabToOtherGroup(2);
      expect(p.currentTab, 2);

      p.reportChatRemovalChange('tab0', true, false);
      expect([for (final t in p.tabList) t.chatRemovalActiveTab], [true, false, false, false, false]);
      expect(p.chatRemovalActiveGlobal, isFalse);

      p.reportChatRemovalChange('tab4', true, true);
      expect([for (final t in p.tabList) t.chatRemovalActiveTab], [true, false, false, false, true]);
      expect(p.chatRemovalActiveGlobal, isTrue);

      p.reportChatRemovalChange('missing', false, false);
      expect([for (final t in p.tabList) t.chatRemovalActiveTab], [true, false, false, false, true]);
    });
  });

  group('energy warnings', () {
    test('only the tab that loads or comes on screen is assessed', () async {
      final p = await build();
      p.browserShowInForeground = true;
      p.moveTabToOtherGroup(2);
      final assessed = <int>[];
      p.onAssessTabForTesting = assessed.add;

      p.reportTabLoadUrl(p.tabList[0].webView!.key, 'https://www.torn.com/gym.php');
      expect(assessed, [0]);

      assessed.clear();
      p.reportTabLoadUrl(p.tabList[1].webView!.key, 'https://www.torn.com/gym.php');
      expect(assessed, isEmpty);

      assessed.clear();
      p.focusTab(0);
      expect(assessed, [0]);

      assessed.clear();
      p.activateTab(3);
      expect(assessed, [3]);

      p.exitBrowserSlotToApp(p.slotOfGroup(SplitGroup.apart));
      assessed.clear();
      p.returnBrowserFromApp();
      expect(assessed, [2]);
    });
  });
}
