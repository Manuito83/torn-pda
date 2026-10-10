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
    tempDir = Directory.systemTemp.createTempSync('split_return_from_app_test');
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

  Future<WebViewProvider> build({required WebViewSplitPosition position}) async {
    final provider = WebViewProvider();
    provider.splitScreenPosition = position;
    for (var i = 0; i < 4; i++) {
      await provider.addTab(url: 'https://www.torn.com/page$i.php', tabUid: 'tab$i');
    }
    provider.updateSplitScreenWidth(wide);
    return provider;
  }

  List<SplitSlotContent?> slots(WebViewProvider p) => [p.splitLeftSlot, p.splitRightSlot];

  Future<WebViewProvider> appLeftApartRight() async {
    final p = await build(position: WebViewSplitPosition.left);
    p.moveTabToOtherGroup(2);
    expect(slots(p), [SplitSlotContent.mainBrowser, SplitSlotContent.apartBrowser]);
    expect(p.exitBrowserSlotToApp(SplitSide.left), isTrue);
    expect(slots(p), [SplitSlotContent.app, SplitSlotContent.apartBrowser]);
    return p;
  }

  Future<WebViewProvider> apartLeftAppRight() async {
    final p = await build(position: WebViewSplitPosition.right);
    p.moveTabToOtherGroup(2);
    expect(slots(p), [SplitSlotContent.apartBrowser, SplitSlotContent.mainBrowser]);
    expect(p.exitBrowserSlotToApp(SplitSide.right), isTrue);
    expect(slots(p), [SplitSlotContent.apartBrowser, SplitSlotContent.app]);
    return p;
  }

  group('[app | apart]', () {
    test('the app can open the browser while it covers the main group', () async {
      final p = await appLeftApartRight();

      expect(p.webViewSplitActive, isTrue);
      expect(p.appCanOpenBrowser, isTrue);
      await settle();
    });

    test('opening the browser from the app gives [main | apart]', () async {
      final p = await appLeftApartRight();

      p.browserShowInForeground = true;

      expect(slots(p), [SplitSlotContent.mainBrowser, SplitSlotContent.apartBrowser]);
      expect(p.webViewSplitActive, isFalse);
      expect(p.browserShowInForeground, isTrue);
      await settle();
    });

    test('the focus stays in the apart group', () async {
      final p = await appLeftApartRight();
      expect(p.currentTab, 2);

      p.browserShowInForeground = true;

      expect(p.currentTab, 2);
      expect(p.isTabVisible(0), isTrue);
      expect(p.isTabVisible(2), isTrue);
      await settle();
    });

    test('a link to the main tab brings its group back with the focus', () async {
      final p = await appLeftApartRight();

      p.activateTab(0);
      p.browserShowInForeground = true;

      expect(slots(p), [SplitSlotContent.mainBrowser, SplitSlotContent.apartBrowser]);
      expect(p.currentTab, 0);
      expect(p.visibleTabIndexForGroup(SplitGroup.apart), 2);
      await settle();
    });

    test('the returned browser can be closed to the app again', () async {
      final p = await appLeftApartRight();
      p.browserShowInForeground = true;

      p.browserShowInForeground = false;

      expect(slots(p).where((s) => s == SplitSlotContent.app).length, 1);
      expect(p.appCanOpenBrowser, isTrue);
      await settle();
    });
  });

  group('[apart | app]', () {
    test('the app can open the browser while it covers the main group', () async {
      final p = await apartLeftAppRight();

      expect(p.webViewSplitActive, isTrue);
      expect(p.appCanOpenBrowser, isTrue);
      await settle();
    });

    test('opening the browser from the app gives [apart | main]', () async {
      final p = await apartLeftAppRight();

      p.browserShowInForeground = true;

      expect(slots(p), [SplitSlotContent.apartBrowser, SplitSlotContent.mainBrowser]);
      expect(p.webViewSplitActive, isFalse);
      expect(p.browserShowInForeground, isTrue);
      await settle();
    });

    test('a link to the main tab brings its group back with the focus', () async {
      final p = await apartLeftAppRight();

      p.activateTab(0);
      p.browserShowInForeground = true;

      expect(slots(p), [SplitSlotContent.apartBrowser, SplitSlotContent.mainBrowser]);
      expect(p.currentTab, 0);
      await settle();
    });
  });

  group('the app covering the apart group', () {
    test('[main | app] comes back as [main | apart]', () async {
      final p = await build(position: WebViewSplitPosition.left);
      p.moveTabToOtherGroup(2);
      p.exitBrowserSlotToApp(SplitSide.right);
      expect(slots(p), [SplitSlotContent.mainBrowser, SplitSlotContent.app]);
      expect(p.appCanOpenBrowser, isTrue);

      p.browserShowInForeground = true;

      expect(slots(p), [SplitSlotContent.mainBrowser, SplitSlotContent.apartBrowser]);
      await settle();
    });
  });

  group('without two browsers the icon behaves as today', () {
    test('split screen of today: the browser is already on screen', () async {
      final p = await build(position: WebViewSplitPosition.right);

      expect(slots(p), [SplitSlotContent.app, SplitSlotContent.browser]);
      expect(p.appCanOpenBrowser, isFalse);
      await settle();
    });

    test('single view: the app can open the browser', () async {
      final p = await build(position: WebViewSplitPosition.off);
      p.browserShowInForeground = false;

      expect(p.appCanOpenBrowser, isTrue);
      await settle();
    });
  });
}
