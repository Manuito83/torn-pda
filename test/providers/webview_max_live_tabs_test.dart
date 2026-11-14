import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('max_live_tabs_test');
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

  // Last use as minutes after the epoch
  Future<WebViewProvider> build() async {
    final p = WebViewProvider();
    const used = [0, 50, 10, 40, 20, 30];
    for (var i = 0; i < used.length; i++) {
      await p.addTab(url: 'https://www.torn.com/page$i.php', tabUid: 'tab$i', lastUsedTime: used[i] * 60000);
    }
    return p;
  }

  List<String> asleep(WebViewProvider p) => [
    for (final t in p.tabList)
      if (t.sleepTab) t.id,
  ];

  test('cap sleeps the oldest hidden tabs', () async {
    final p = await build();
    p.activateTab(2);
    p.tabList[2].lastUsedTimeDT = DateTime.fromMillisecondsSinceEpoch(0);

    p.maxLiveTabsOverride = 4;

    expect(asleep(p), ['tab4', 'tab5']);
    expect(p.tabList[4].webView, isNull);
    expect(p.tabList[4].sleepingWebView?.customUrl, 'https://www.torn.com/page4.php');
  });

  test('new tab over the cap sleeps the oldest hidden', () async {
    final p = await build();
    p.maxLiveTabsOverride = 6;
    expect(asleep(p), isEmpty);

    await p.addTab(url: 'https://www.torn.com/page6.php', tabUid: 'tab6');

    expect(asleep(p), ['tab2']);
  });
}
