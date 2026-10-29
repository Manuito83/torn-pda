import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/webviews/webview_full.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const torn = 'https://www.torn.com/index.php';
  const other = 'https://www.example.org';

  late Directory tempDir;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('hidden_load_test');
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
  });

  Future<void> settle() async {
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  // Saved tabs come back
  Future<List<bool>> restore(List<String> urls, int active) async {
    final saved = WebViewProvider();
    await saved.addTab(url: urls.first, tabUid: 't0');
    await saved.initialiseSecondary(useTabs: true);
    for (var i = 1; i < urls.length; i++) {
      await saved.addTab(url: urls[i], tabUid: 't$i');
    }
    // Same place, only to save
    saved.reorderTabs(saved.tabList.last, urls.length - 1, urls.length - 1);
    await settle();
    await Prefs().setWebViewLastActiveTab(active);

    final restored = WebViewProvider();
    await restored.addTab(url: urls.first, tabUid: 't0');
    await restored.initialiseSecondary(useTabs: true, recallLastSession: true);
    return [for (final tab in restored.tabList) tab.webView is WebViewFull && (tab.webView! as WebViewFull).loadWhenHidden];
  }

  test('loads hidden only the shown Torn tab', () async {
    expect(await restore([torn, other, torn], 2), [false, false, true]);
  });

  test('other sites wait', () async {
    expect(await restore([torn, other, torn], 1), [false, false, false]);
  });

  group('browser closed before the shown tab loads', () {
    tearDown(() => WebViewProvider.isAndroid = () => Platform.isAndroid);

    Future<bool> closeEarly(String url, {bool android = true}) async {
      WebViewProvider.isAndroid = () => android;
      final web = WebViewProvider();
      await web.addTab(url: url, tabUid: 't0');
      web.browserShowInForeground = true;
      web.browserShowInForeground = false;
      final view = web.tabList.first.webView;
      return view is WebViewFull && view.loadWhenHidden;
    }

    test('Torn tab rebuilds hidden', () async {
      expect(await closeEarly(torn), isTrue);
    });

    test('other sites wait', () async {
      expect(await closeEarly(other), isFalse);
    });

    test('iOS loads hidden by itself and is left alone', () async {
      expect(await closeEarly(torn, android: false), isFalse);
    });
  });
}
