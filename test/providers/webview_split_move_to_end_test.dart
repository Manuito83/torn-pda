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
    tempDir = Directory.systemTemp.createTempSync('split_move_to_end_test');
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

  Future<void> settle() async {
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  Future<WebViewProvider> build(List<String> uids, {double width = wide}) async {
    final provider = WebViewProvider();
    provider.splitScreenPosition = WebViewSplitPosition.left;
    for (final uid in uids) {
      await provider.addTab(url: 'https://www.torn.com/$uid.php', tabUid: uid);
    }
    provider.updateSplitScreenWidth(width);
    return provider;
  }

  List<String> order(WebViewProvider p) => [for (final t in p.tabList) t.id];

  List<String> tabsOf(WebViewProvider p, SplitGroup g) => [for (final i in p.tabIndexesForGroup(g)) p.tabList[i].id];

  int indexOf(WebViewProvider p, String uid) => p.tabList.indexWhere((t) => t.id == uid);

  bool move(WebViewProvider p, String uid) => p.moveTabToOtherGroup(indexOf(p, uid));

  String? shown(WebViewProvider p, SplitGroup g) {
    final int? index = p.visibleTabIndexForGroup(g);
    return index == null ? null : p.tabList[index].id;
  }

  group('a tab sent to the other group goes to its end', () {
    test('[1 2 3 | 5 6] with the 3 sent across gives [1 2 | 5 6 3], and 1 2 5 6 3 when joined', () async {
      final p = await build(['t1', 't2', 't3', 't5', 't6']);
      move(p, 't5');
      move(p, 't6');
      expect(tabsOf(p, SplitGroup.main), ['t1', 't2', 't3']);
      expect(tabsOf(p, SplitGroup.apart), ['t5', 't6']);

      expect(move(p, 't3'), isTrue);

      expect(tabsOf(p, SplitGroup.main), ['t1', 't2']);
      expect(tabsOf(p, SplitGroup.apart), ['t5', 't6', 't3']);
      expect(order(p), ['t1', 't2', 't5', 't6', 't3']);

      p.updateSplitScreenWidth(narrow);
      expect(tabsOf(p, SplitGroup.main), ['t1', 't2', 't5', 't6', 't3']);
    });

    test('a tab coming back to the main group goes to its end and to the end of the list', () async {
      final p = await build(['t1', 't2', 't3', 't4']);
      move(p, 't2');
      move(p, 't3');
      expect(order(p), ['t1', 't4', 't2', 't3']);

      move(p, 't2');

      expect(tabsOf(p, SplitGroup.main), ['t1', 't4', 't2']);
      expect(tabsOf(p, SplitGroup.apart), ['t3']);
      expect(order(p), ['t1', 't4', 't3', 't2']);
    });

    test('opening the split panel from one view also puts the tab last', () async {
      final p = await build(['t1', 't2', 't3', 't4']);

      move(p, 't2');

      expect(order(p), ['t1', 't3', 't4', 't2']);
      expect(tabsOf(p, SplitGroup.apart), ['t2']);
    });

    test('the moved tab is shown and focused, and the group it leaves shows its previous neighbour', () async {
      final p = await build(['t1', 't2', 't3', 't4']);
      p.activateTab(indexOf(p, 't3'));

      move(p, 't3');

      expect(p.tabList[p.currentTab].id, 't3');
      expect(shown(p, SplitGroup.apart), 't3');
      expect(shown(p, SplitGroup.main), 't2');
    });

    test('moving another tab while the focus is elsewhere keeps both groups showing the right tab', () async {
      final p = await build(['t1', 't2', 't3', 't4', 't5']);
      move(p, 't5');
      expect(p.tabList[p.currentTab].id, 't5');

      move(p, 't3');

      expect(order(p), ['t1', 't2', 't4', 't5', 't3']);
      expect(p.tabList[p.currentTab].id, 't3');
      expect(shown(p, SplitGroup.apart), 't3');
      expect(p.isTabVisible(indexOf(p, 't3')), isTrue);
    });

    test('the main tab cannot be moved and stays first', () async {
      final p = await build(['t1', 't2', 't3']);

      expect(p.moveTabToOtherGroup(0), isFalse);

      expect(order(p), ['t1', 't2', 't3']);
    });

    test('the last tab of the apart group sent back leaves it blank', () async {
      final p = await build(['t1', 't2', 't3']);
      move(p, 't2');

      move(p, 't2');

      expect(order(p), ['t1', 't3', 't2']);
      expect(p.splitApartEmpty, isTrue);
    });

    test('the new order and the focused tab survive a restart', () async {
      final saved = WebViewProvider();
      saved.splitScreenPosition = WebViewSplitPosition.left;
      await saved.addTab(url: 'https://www.torn.com/t1.php', tabUid: 't1');
      await saved.initialiseSecondary(useTabs: true);
      for (final uid in ['t2', 't3', 't4']) {
        await saved.addTab(url: 'https://www.torn.com/$uid.php', tabUid: uid);
      }
      saved.updateSplitScreenWidth(wide);
      move(saved, 't4');
      move(saved, 't2');
      await settle();

      final restored = WebViewProvider();
      restored.splitScreenPosition = WebViewSplitPosition.left;
      await restored.addTab(url: 'https://www.torn.com/t1.php', tabUid: 't1');
      await restored.initialiseSecondary(useTabs: true, recallLastSession: true);
      restored.updateSplitScreenWidth(wide);

      expect(order(restored), ['t1', 't3', 't4', 't2']);
      expect(tabsOf(restored, SplitGroup.apart), ['t4', 't2']);
      expect(restored.tabList[restored.currentTab].id, 't2');
      expect(restored.apartVisibleTabUid, 't2');
    });
  });
}
