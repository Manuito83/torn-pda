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
    tempDir = Directory.systemTemp.createTempSync('split_app_side_test');
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

  Future<WebViewProvider> build({required WebViewSplitPosition position, double width = wide}) async {
    final provider = WebViewProvider();
    provider.splitScreenPosition = position;
    for (var i = 0; i < 4; i++) {
      await provider.addTab(url: 'https://www.torn.com/page$i.php', tabUid: 'tab$i');
    }
    provider.updateSplitScreenWidth(width);
    return provider;
  }

  group('split screen of today', () {
    test('browser right: the app is on the left', () async {
      final p = await build(position: WebViewSplitPosition.right);

      expect([p.splitLeftSlot, p.splitRightSlot], [SplitSlotContent.app, SplitSlotContent.browser]);
      expect(p.splitAppSide, SplitSide.left);
      expect(p.splitScreenAndBrowserLeft(), isFalse);
      await settle();
    });

    test('browser left: the app is on the right', () async {
      final p = await build(position: WebViewSplitPosition.left);

      expect([p.splitLeftSlot, p.splitRightSlot], [SplitSlotContent.browser, SplitSlotContent.app]);
      expect(p.splitAppSide, SplitSide.right);
      expect(p.splitScreenAndBrowserLeft(), isTrue);
      await settle();
    });

    test('split screen off: no app side', () async {
      final p = await build(position: WebViewSplitPosition.off);

      expect(p.splitAppSide, isNull);
      expect(p.splitScreenAndBrowserLeft(), isFalse);
      await settle();
    });
  });

  group('app in the slot opposite to the setting', () {
    test('[apart | app] with the browser set to the right', () async {
      final p = await build(position: WebViewSplitPosition.right);
      p.moveTabToOtherGroup(2);
      expect(p.exitBrowserSlotToApp(p.slotOfGroup(SplitGroup.main)), isTrue);

      expect([p.splitLeftSlot, p.splitRightSlot], [SplitSlotContent.apartBrowser, SplitSlotContent.app]);
      expect(p.splitAppSide, SplitSide.right);
      expect(p.splitScreenAndBrowserLeft(), isTrue);
      await settle();
    });

    test('[app | main] with the browser set to the left', () async {
      final p = await build(position: WebViewSplitPosition.right);
      p.moveTabToOtherGroup(2);
      expect(p.exitBrowserSlotToApp(p.slotOfGroup(SplitGroup.apart)), isTrue);
      p.splitScreenPosition = WebViewSplitPosition.left;

      expect([p.splitLeftSlot, p.splitRightSlot], [SplitSlotContent.app, SplitSlotContent.mainBrowser]);
      expect(p.splitAppSide, SplitSide.left);
      expect(p.splitScreenAndBrowserLeft(), isFalse);
      await settle();
    });

    test('two browsers without the app: no app side', () async {
      final p = await build(position: WebViewSplitPosition.right);
      p.moveTabToOtherGroup(2);

      expect(p.splitRightSlot, isNot(SplitSlotContent.app));
      expect(p.splitLeftSlot, isNot(SplitSlotContent.app));
      expect(p.splitAppSide, isNull);
      await settle();
    });
  });

  test('Remote Config off: back to the side of the setting', () async {
    final p = await build(position: WebViewSplitPosition.right);
    p.moveTabToOtherGroup(2);
    p.exitBrowserSlotToApp(p.slotOfGroup(SplitGroup.main));
    expect(p.splitAppSide, SplitSide.right);

    p.splitBrowsersAllowedRC = false;

    expect([p.splitLeftSlot, p.splitRightSlot], [SplitSlotContent.app, SplitSlotContent.browser]);
    expect(p.splitAppSide, SplitSide.left);
    p.splitBrowsersAllowedRC = true;
    await settle();
  });

  group('narrow screen', () {
    test('no app side with the split screen set', () async {
      final p = await build(position: WebViewSplitPosition.left, width: narrow);

      expect(p.splitRightSlot, isNull);
      expect(p.splitAppSide, isNull);
      await settle();
    });

    test('no app side after narrowing with the app in the opposite slot', () async {
      final p = await build(position: WebViewSplitPosition.right);
      p.moveTabToOtherGroup(2);
      p.exitBrowserSlotToApp(p.slotOfGroup(SplitGroup.main));

      p.updateSplitScreenWidth(narrow);

      expect(p.splitRightSlot, isNull);
      expect(p.splitAppSide, isNull);
      await settle();
    });
  });
}
