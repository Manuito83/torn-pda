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
    tempDir = Directory.systemTemp.createTempSync('split_toggle_test');
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

  Future<WebViewProvider> build({double width = wide}) async {
    final provider = WebViewProvider();
    await provider.addTab(url: 'https://www.torn.com/page.php', tabUid: 'tab0');
    provider.updateSplitScreenWidth(width);
    provider.browserShowInForeground = true;
    return provider;
  }

  group('quick split switch', () {
    test('turns the split on and saves the same preference as Settings', () async {
      final p = await build();
      expect(p.webViewSplitActive, isFalse);

      p.toggleSplitScreen();

      expect(p.splitScreenPosition, WebViewSplitPosition.right);
      expect(await Prefs().getSplitScreenWebview(), 'right');
      expect(p.webViewSplitActive, isTrue);
      expect([p.splitLeftSlot, p.splitRightSlot], [SplitSlotContent.app, SplitSlotContent.browser]);
      await settle();
    });

    test('turning it off keeps the browser on screen', () async {
      final p = await build();
      p.toggleSplitScreen();

      p.toggleSplitScreen();

      expect(p.splitScreenPosition, WebViewSplitPosition.off);
      expect(await Prefs().getSplitScreenWebview(), 'off');
      expect(p.webViewSplitActive, isFalse);
      expect(p.browserShowInForeground, isTrue);
      expect(p.splitRightSlot, isNull);
      await settle();
    });

    test('brings the side the user had back', () async {
      final p = await build();
      p.splitScreenPosition = WebViewSplitPosition.left;
      p.toggleSplitScreen();
      expect(p.splitScreenPosition, WebViewSplitPosition.off);

      p.toggleSplitScreen();

      expect(p.splitScreenPosition, WebViewSplitPosition.left);
      expect([p.splitLeftSlot, p.splitRightSlot], [SplitSlotContent.browser, SplitSlotContent.app]);
      await settle();
    });

    test('does not open the split by itself when the device unfolds', () async {
      final p = await build(width: narrow);

      p.updateSplitScreenWidth(wide);

      expect(p.webViewSplitActive, isFalse);
      expect(p.splitRightSlot, isNull);
      await settle();
    });

    test('on a narrow screen it only saves the preference', () async {
      final p = await build(width: narrow);

      p.toggleSplitScreen();
      expect(p.splitScreenPosition, WebViewSplitPosition.right);
      expect(p.webViewSplitActive, isFalse);

      p.updateSplitScreenWidth(wide);
      expect(p.webViewSplitActive, isTrue);
      await settle();
    });
  });
}
