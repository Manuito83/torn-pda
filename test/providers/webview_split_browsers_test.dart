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
    tempDir = Directory.systemTemp.createTempSync('split_browsers_test');
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

  Future<WebViewProvider> build({
    int count = 6,
    double width = wide,
    bool revertsToApp = true,
    WebViewSplitPosition position = WebViewSplitPosition.left,
    List<String>? uids,
  }) async {
    final provider = WebViewProvider();
    provider.splitScreenRevertsToApp = revertsToApp;
    provider.splitScreenPosition = position;
    for (final uid in uids ?? [for (var i = 0; i < count; i++) 'tab$i']) {
      await provider.addTab(url: 'https://www.torn.com/$uid.php', tabUid: uid);
    }
    provider.updateSplitScreenWidth(width);
    return provider;
  }

  List<String> order(WebViewProvider p) => [for (final t in p.tabList) t.id];

  List<SplitSlotContent?> slots(WebViewProvider p) => [p.splitLeftSlot, p.splitRightSlot];

  int at(WebViewProvider p, String uid) => p.tabList.indexWhere((t) => t.id == uid);

  bool send(WebViewProvider p, String uid) => p.moveTabToOtherGroup(at(p, uid));

  List<String> ids(WebViewProvider p, SplitGroup g) => [for (final i in p.tabIndexesForGroup(g)) p.tabList[i].id];

  String shown(WebViewProvider p, SplitGroup g) => p.tabList[p.visibleTabIndexForGroup(g)!].id;

  group('sending a tab apart', () {
    test('activates the two browsers and puts the sent tab at the end of the global order', () async {
      final p = await build();
      expect(p.splitBrowsersActive, isFalse);

      expect(p.moveTabToOtherGroup(2), isTrue);

      expect(p.splitBrowsersActive, isTrue);
      expect(slots(p), unorderedEquals([SplitSlotContent.mainBrowser, SplitSlotContent.apartBrowser]));
      expect(ids(p, SplitGroup.main), ['tab0', 'tab1', 'tab3', 'tab4', 'tab5']);
      expect(ids(p, SplitGroup.apart), ['tab2']);
      expect(order(p), ['tab0', 'tab1', 'tab3', 'tab4', 'tab5', 'tab2']);
    });

    test('the sent tab is the one shown by the apart group and has the focus', () async {
      final p = await build();
      p.moveTabToOtherGroup(2);

      expect(shown(p, SplitGroup.apart), 'tab2');
      expect(p.tabList[p.currentTab].id, 'tab2');
      expect(p.focusedGroup, SplitGroup.apart);
    });

    test('several tabs pile up at the end in the order they were sent', () async {
      final p = await build();
      send(p, 'tab4');
      send(p, 'tab2');

      expect(ids(p, SplitGroup.apart), ['tab4', 'tab2']);
      expect(ids(p, SplitGroup.main), ['tab0', 'tab1', 'tab3', 'tab5']);
      expect(order(p), ['tab0', 'tab1', 'tab3', 'tab5', 'tab4', 'tab2']);
    });

    test('sending it back makes it a tab of the main group again', () async {
      final p = await build();
      send(p, 'tab2');
      send(p, 'tab4');

      expect(send(p, 'tab2'), isTrue);

      expect(ids(p, SplitGroup.main), ['tab0', 'tab1', 'tab3', 'tab5', 'tab2']);
      expect(ids(p, SplitGroup.apart), ['tab4']);
      expect(shown(p, SplitGroup.main), 'tab2');
    });

    test('narrowing gives back one view with every tab in the global order', () async {
      final p = await build(revertsToApp: false);
      send(p, 'tab2');
      send(p, 'tab4');

      p.updateSplitScreenWidth(narrow);

      expect(p.splitRightSlot, isNull);
      expect(p.splitLeftSlot, SplitSlotContent.browser);
      expect(p.tabIndexesForGroup(SplitGroup.main), [0, 1, 2, 3, 4, 5]);
      expect(p.tabIndexesForGroup(SplitGroup.apart), isEmpty);
      expect(order(p), ['tab0', 'tab1', 'tab3', 'tab5', 'tab2', 'tab4']);
    });
  });

  group('the apart group takes the slot where the app was', () {
    test('[app | 1 2 3 4] with the 3 apart gives [3 | 1 2 4]', () async {
      final p = await build(count: 5, position: WebViewSplitPosition.right);
      expect(slots(p), [SplitSlotContent.app, SplitSlotContent.browser]);

      expect(p.moveTabToOtherGroup(3), isTrue);

      expect(p.splitLeftSlot, SplitSlotContent.apartBrowser);
      expect(p.splitRightSlot, SplitSlotContent.mainBrowser);
      expect(p.slotOfGroup(SplitGroup.apart), SplitSide.left);
      expect(p.slotOfGroup(SplitGroup.main), SplitSide.right);
      expect(ids(p, SplitGroup.apart), ['tab3']);
      expect(ids(p, SplitGroup.main), ['tab0', 'tab1', 'tab2', 'tab4']);
    });

    test('[1 2 3 4 | app] with the 3 apart gives [1 2 4 | 3]', () async {
      final p = await build(count: 5, position: WebViewSplitPosition.left);
      expect(slots(p), [SplitSlotContent.browser, SplitSlotContent.app]);

      expect(p.moveTabToOtherGroup(3), isTrue);

      expect(p.splitLeftSlot, SplitSlotContent.mainBrowser);
      expect(p.splitRightSlot, SplitSlotContent.apartBrowser);
      expect(p.slotOfGroup(SplitGroup.main), SplitSide.left);
      expect(p.slotOfGroup(SplitGroup.apart), SplitSide.right);
    });

    test('with the app gone and two browsers, the next tab goes to the other panel', () async {
      final p = await build(count: 5, position: WebViewSplitPosition.right);
      send(p, 'tab3');

      send(p, 'tab1');

      expect(ids(p, SplitGroup.apart), ['tab3', 'tab1']);
      expect(p.splitLeftSlot, SplitSlotContent.apartBrowser);
      expect(p.splitRightSlot, SplitSlotContent.mainBrowser);

      send(p, 'tab3');

      expect(ids(p, SplitGroup.apart), ['tab1']);
      expect(ids(p, SplitGroup.main), ['tab0', 'tab2', 'tab4', 'tab3']);
      expect(p.splitLeftSlot, SplitSlotContent.apartBrowser);
      expect(p.splitRightSlot, SplitSlotContent.mainBrowser);
    });
  });

  group('main tab and main group', () {
    test('the main tab cannot be sent apart', () async {
      final p = await build();

      expect(p.moveTabToOtherGroup(0), isFalse);
      expect(p.tabList[0].splitApart, isFalse);
      expect(p.splitBrowsersActive, isFalse);
    });

    test('the main tab cannot be sent either when two browsers are active', () async {
      final p = await build();
      p.moveTabToOtherGroup(2);

      expect(p.moveTabToOtherGroup(0), isFalse);
      expect(p.tabIndexesForGroup(SplitGroup.main), contains(0));
    });

    test('the main group is never empty: sending every other tab apart leaves the main one', () async {
      final p = await build(count: 4);
      for (var i = 1; i < 4; i++) {
        send(p, 'tab$i');
      }

      expect(p.tabIndexesForGroup(SplitGroup.main), [0]);
      expect(ids(p, SplitGroup.apart), ['tab1', 'tab2', 'tab3']);
      expect(p.visibleTabIndexForGroup(SplitGroup.main), 0);
    });

    test('an out of range index is refused', () async {
      final p = await build(count: 3);

      expect(p.moveTabToOtherGroup(7), isFalse);
      expect(p.moveTabToOtherGroup(-1), isFalse);
    });
  });

  group('closing the last tab of the apart group', () {
    test('keeps two browsers with an empty apart group', () async {
      final p = await build(count: 3);
      p.moveTabToOtherGroup(2);

      await p.removeTab(position: 2);

      expect(p.splitBrowsersActive, isTrue);
      expect(p.splitApartEmpty, isTrue);
      expect(slots(p), unorderedEquals([SplitSlotContent.mainBrowser, SplitSlotContent.apartBrowser]));
      expect(p.visibleTabIndexForGroup(SplitGroup.apart), isNull);
      expect(p.tabIndexesForGroup(SplitGroup.apart), isEmpty);
    });

    test('closing the empty group turns its slot into the app', () async {
      final p = await build(count: 3);
      p.moveTabToOtherGroup(2);
      await p.removeTab(position: 2);
      final SplitSide apartSlot = p.slotOfGroup(SplitGroup.apart);

      expect(p.closeSplitApartGroup(), isTrue);

      expect(apartSlot == SplitSide.left ? p.splitLeftSlot : p.splitRightSlot, SplitSlotContent.app);
      expect(apartSlot == SplitSide.left ? p.splitRightSlot : p.splitLeftSlot, isNot(SplitSlotContent.app));
      expect(p.splitApartOpen, isFalse);
    });

    test('closing the empty group gives the app back the slot it had', () async {
      final p = await build(count: 4, position: WebViewSplitPosition.right);
      p.moveTabToOtherGroup(3);
      await p.removeTab(position: 3);
      expect(p.splitLeftSlot, SplitSlotContent.apartBrowser);

      expect(p.closeSplitApartGroup(), isTrue);

      expect(p.splitLeftSlot, SplitSlotContent.app);
      expect(p.splitRightSlot, anyOf(SplitSlotContent.browser, SplitSlotContent.mainBrowser));
    });

    test('an apart group with tabs cannot be closed', () async {
      final p = await build(count: 3);
      p.moveTabToOtherGroup(2);

      expect(p.closeSplitApartGroup(), isFalse);
      expect(slots(p), contains(SplitSlotContent.apartBrowser));
    });

    test('closing a visible apart tab shows the previous tab of the same group', () async {
      final p = await build();
      send(p, 'tab2');
      send(p, 'tab4');
      expect(shown(p, SplitGroup.apart), 'tab4');

      await p.removeTab(position: at(p, 'tab4'));

      expect(shown(p, SplitGroup.apart), 'tab2');
      expect(p.splitApartEmpty, isFalse);
    });

    test('closing a visible main tab shows the previous tab of the main group', () async {
      final p = await build();
      send(p, 'tab2');
      p.activateTab(at(p, 'tab3'));
      expect(shown(p, SplitGroup.main), 'tab3');

      await p.removeTab(position: at(p, 'tab3'));

      expect(shown(p, SplitGroup.main), 'tab1');
      expect(shown(p, SplitGroup.apart), 'tab2');
    });
  });

  group('a new tab opened from a tab is born in its group', () {
    test('from a tab of the apart group it is born apart', () async {
      final p = await build(count: 4);
      p.moveTabToOtherGroup(2);

      await p.addTab(url: 'https://www.torn.com/new.php', tabUid: 'child', openerTabUid: 'tab2');

      final int child = at(p, 'child');
      expect(p.tabList[child].splitApart, isTrue);
      expect(ids(p, SplitGroup.apart), ['tab2', 'child']);
    });

    test('from a tab of the main group it is born in the main group', () async {
      final p = await build(count: 4);
      p.moveTabToOtherGroup(2);

      await p.addTab(url: 'https://www.torn.com/new.php', tabUid: 'child', openerTabUid: 'tab1');

      final int child = p.tabList.indexWhere((t) => t.id == 'child');
      expect(p.tabList[child].splitApart, isFalse);
      expect(p.tabIndexesForGroup(SplitGroup.main), contains(child));
    });
  });

  group('the app takes the slot of the browser that is left', () {
    test('leaving the main browser (on the left) puts the app on the left', () async {
      final p = await build();
      p.moveTabToOtherGroup(2);
      final SplitSide mainSlot = p.slotOfGroup(SplitGroup.main);
      final SplitSide apartSlot = p.slotOfGroup(SplitGroup.apart);

      expect(p.exitBrowserSlotToApp(mainSlot), isTrue);

      expect(mainSlot == SplitSide.left ? p.splitLeftSlot : p.splitRightSlot, SplitSlotContent.app);
      expect(apartSlot == SplitSide.left ? p.splitLeftSlot : p.splitRightSlot, SplitSlotContent.apartBrowser);
    });

    test('leaving the apart browser puts the app in its slot', () async {
      final p = await build();
      p.moveTabToOtherGroup(2);
      final SplitSide mainSlot = p.slotOfGroup(SplitGroup.main);
      final SplitSide apartSlot = p.slotOfGroup(SplitGroup.apart);

      expect(p.exitBrowserSlotToApp(apartSlot), isTrue);

      expect(apartSlot == SplitSide.left ? p.splitLeftSlot : p.splitRightSlot, SplitSlotContent.app);
      expect(mainSlot == SplitSide.left ? p.splitLeftSlot : p.splitRightSlot, SplitSlotContent.mainBrowser);
    });

    test('with the main group on the right, leaving the left browser covers the apart group', () async {
      final p = await build(count: 5, position: WebViewSplitPosition.right);
      p.moveTabToOtherGroup(3);

      expect(p.exitBrowserSlotToApp(SplitSide.left), isTrue);

      expect(p.splitLeftSlot, SplitSlotContent.app);
      expect(p.splitRightSlot, SplitSlotContent.mainBrowser);
    });

    test('leaving a browser does not lose the tabs of either group', () async {
      final p = await build();
      p.moveTabToOtherGroup(2);
      final before = order(p);

      p.exitBrowserSlotToApp(p.slotOfGroup(SplitGroup.main));

      expect(order(p), before);
      expect(ids(p, SplitGroup.main), ['tab0', 'tab1', 'tab3', 'tab4', 'tab5']);
      expect(ids(p, SplitGroup.apart), ['tab2']);
    });
  });

  group('never the app in both slots', () {
    test('with the app in a slot the remaining browser cannot be closed', () async {
      final p = await build();
      p.moveTabToOtherGroup(2);
      p.exitBrowserSlotToApp(p.slotOfGroup(SplitGroup.main));
      final after = slots(p);

      expect(p.splitBrowserCanExitToApp, isFalse);
      expect(p.exitBrowserSlotToApp(p.slotOfGroup(SplitGroup.apart)), isFalse);
      expect(slots(p), after);
    });

    test('the same holds with the app in the slot of the apart group', () async {
      final p = await build();
      p.moveTabToOtherGroup(2);
      p.exitBrowserSlotToApp(p.slotOfGroup(SplitGroup.apart));
      final after = slots(p);

      expect(p.splitBrowserCanExitToApp, isFalse);
      expect(p.exitBrowserSlotToApp(p.slotOfGroup(SplitGroup.main)), isFalse);
      expect(slots(p), after);
    });

    test('with the apart group empty it is not possible to leave the other browser for the app', () async {
      final p = await build(count: 3);
      p.moveTabToOtherGroup(2);
      await p.removeTab(position: 2);
      final before = slots(p);

      expect(p.splitApartEmpty, isTrue);
      expect(p.splitBrowserCanExitToApp, isFalse);
      expect(p.exitBrowserSlotToApp(SplitSide.left), isFalse);
      expect(p.exitBrowserSlotToApp(SplitSide.right), isFalse);
      expect(slots(p), before);
    });
  });

  group('opening the browser from the app', () {
    for (final group in SplitGroup.values) {
      test('the group that was missing returns to its slot (app where the ${group.name} group was)', () async {
        final p = await build();
        p.moveTabToOtherGroup(2);
        final before = slots(p);
        p.exitBrowserSlotToApp(p.slotOfGroup(group));
        expect(slots(p), contains(SplitSlotContent.app));

        p.returnBrowserFromApp();

        expect(slots(p), before);
        expect(slots(p), isNot(contains(SplitSlotContent.app)));
        expect(p.splitBrowserCanExitToApp, isTrue);
      });
    }

    test('the group that was missing returns to its slot (main group on the right)', () async {
      final p = await build(count: 5, position: WebViewSplitPosition.right);
      p.moveTabToOtherGroup(3);
      p.exitBrowserSlotToApp(SplitSide.left);

      p.returnBrowserFromApp();

      expect(p.splitLeftSlot, SplitSlotContent.apartBrowser);
      expect(p.splitRightSlot, SplitSlotContent.mainBrowser);
    });

    test('showing the browser in the foreground does the same', () async {
      final p = await build();
      p.moveTabToOtherGroup(2);
      final before = slots(p);
      p.exitBrowserSlotToApp(p.slotOfGroup(SplitGroup.main));

      p.browserShowInForeground = true;

      expect(slots(p), before);
    });

    test('the tabs of the returning group are still there', () async {
      final p = await build();
      send(p, 'tab2');
      send(p, 'tab4');
      p.exitBrowserSlotToApp(p.slotOfGroup(SplitGroup.main));

      p.returnBrowserFromApp();

      expect(ids(p, SplitGroup.apart), ['tab2', 'tab4']);
      expect(ids(p, SplitGroup.main), ['tab0', 'tab1', 'tab3', 'tab5']);
      expect(p.visibleTabIndexForGroup(SplitGroup.main), isNotNull);
      expect(p.visibleTabIndexForGroup(SplitGroup.apart), isNotNull);
    });
  });

  group('narrowing and widening', () {
    test('wide from the threshold up', () async {
      final p = await build(width: kSplitScreenMinWidth - 1);
      p.moveTabToOtherGroup(2);
      expect(p.splitScreenWide, isFalse);
      expect(p.splitRightSlot, isNull);

      p.updateSplitScreenWidth(kSplitScreenMinWidth);

      expect(p.splitScreenWide, isTrue);
      expect(slots(p), unorderedEquals([SplitSlotContent.mainBrowser, SplitSlotContent.apartBrowser]));
    });

    test('narrow with revert to the app: one view showing the app', () async {
      final p = await build(revertsToApp: true);
      p.moveTabToOtherGroup(2);

      p.updateSplitScreenWidth(narrow);

      expect(p.splitLeftSlot, SplitSlotContent.app);
      expect(p.splitRightSlot, isNull);
    });

    test('narrow without revert to the app: one view showing the browser with all tabs', () async {
      final p = await build(revertsToApp: false);
      p.moveTabToOtherGroup(2);

      p.updateSplitScreenWidth(narrow);

      expect(p.splitLeftSlot, SplitSlotContent.browser);
      expect(p.splitRightSlot, isNull);
      expect(p.tabIndexesForGroup(SplitGroup.main).length, p.tabList.length);
    });

    test('widening brings back the previous split of tabs', () async {
      final p = await build(revertsToApp: false);
      send(p, 'tab2');
      send(p, 'tab4');
      final before = slots(p);
      p.updateSplitScreenWidth(narrow);

      p.updateSplitScreenWidth(wide);

      expect(slots(p), before);
      expect(ids(p, SplitGroup.main), ['tab0', 'tab1', 'tab3', 'tab5']);
      expect(ids(p, SplitGroup.apart), ['tab2', 'tab4']);
    });

    test('widening brings back the apart tab that was shown', () async {
      final p = await build(revertsToApp: false);
      send(p, 'tab2');
      send(p, 'tab4');
      p.updateSplitScreenWidth(narrow);

      p.updateSplitScreenWidth(wide);

      expect(shown(p, SplitGroup.apart), 'tab4');
    });

    test('widening brings back the app in its slot when it was there before', () async {
      final p = await build(revertsToApp: false);
      p.moveTabToOtherGroup(2);
      p.exitBrowserSlotToApp(p.slotOfGroup(SplitGroup.main));
      final before = slots(p);
      p.updateSplitScreenWidth(narrow);

      p.updateSplitScreenWidth(wide);

      expect(slots(p), before);
    });

    test('widening brings back the groups in the slots they had (main group on the right)', () async {
      final p = await build(count: 5, revertsToApp: false, position: WebViewSplitPosition.right);
      p.moveTabToOtherGroup(3);
      p.updateSplitScreenWidth(narrow);

      p.updateSplitScreenWidth(wide);

      expect(p.splitLeftSlot, SplitSlotContent.apartBrowser);
      expect(p.splitRightSlot, SplitSlotContent.mainBrowser);
    });

    test('an empty apart group survives narrowing and widening', () async {
      final p = await build(count: 3, revertsToApp: false);
      p.moveTabToOtherGroup(2);
      await p.removeTab(position: 2);
      p.updateSplitScreenWidth(narrow);

      p.updateSplitScreenWidth(wide);

      expect(slots(p), unorderedEquals([SplitSlotContent.mainBrowser, SplitSlotContent.apartBrowser]));
      expect(p.splitApartEmpty, isTrue);
    });
  });

  group('Remote Config switch', () {
    test('off: tabs cannot be sent apart', () async {
      final p = await build();
      p.splitBrowsersAllowedRC = false;

      expect(p.moveTabToOtherGroup(2), isFalse);
      expect(p.splitBrowsersActive, isFalse);
      expect(p.tabList[2].splitApart, isFalse);
    });

    test('off while two browsers are active: back to a single view with every tab', () async {
      final p = await build();
      p.moveTabToOtherGroup(2);
      p.moveTabToOtherGroup(4);

      p.splitBrowsersAllowedRC = false;

      expect(p.splitBrowsersActive, isFalse);
      expect(p.splitLeftSlot, isNot(SplitSlotContent.mainBrowser));
      expect(p.splitRightSlot, SplitSlotContent.app);
      expect(p.tabIndexesForGroup(SplitGroup.main), [0, 1, 2, 3, 4, 5]);
      expect(p.tabIndexesForGroup(SplitGroup.apart), isEmpty);
    });

    test('off while the app takes a slot: no browser group is left hidden', () async {
      final p = await build();
      p.moveTabToOtherGroup(2);
      p.exitBrowserSlotToApp(p.slotOfGroup(SplitGroup.main));

      p.splitBrowsersAllowedRC = false;

      expect(p.splitBrowsersActive, isFalse);
      expect(p.tabIndexesForGroup(SplitGroup.main).length, p.tabList.length);
    });
  });

  group('saving and restoring the groups', () {
    test('the apart marks come back after restoring the tabs', () async {
      final saved = WebViewProvider();
      saved.splitScreenPosition = WebViewSplitPosition.left;
      await saved.addTab(url: 'https://www.torn.com/main.php', tabUid: 'main');
      await saved.initialiseSecondary(useTabs: true);
      for (var i = 1; i < 5; i++) {
        await saved.addTab(url: 'https://www.torn.com/p$i.php', tabUid: 'saved$i');
      }
      saved.updateSplitScreenWidth(wide);
      send(saved, 'saved2');
      send(saved, 'saved4');
      await settle();

      final restored = WebViewProvider();
      restored.splitScreenPosition = WebViewSplitPosition.left;
      await restored.addTab(url: 'https://www.torn.com/main.php', tabUid: 'main');
      await restored.initialiseSecondary(useTabs: true, recallLastSession: true);
      restored.updateSplitScreenWidth(wide);

      expect(restored.tabList.map((t) => t.id), ['main', 'saved1', 'saved3', 'saved2', 'saved4']);
      expect(restored.tabList.map((t) => t.splitApart), [false, false, false, true, true]);
      expect(restored.splitBrowsersActive, isTrue);
      expect(ids(restored, SplitGroup.apart), ['saved2', 'saved4']);
    });

    test('the apart tab that was visible is the one shown after restoring', () async {
      final saved = WebViewProvider();
      saved.splitScreenPosition = WebViewSplitPosition.left;
      await saved.addTab(url: 'https://www.torn.com/main.php', tabUid: 'main');
      await saved.initialiseSecondary(useTabs: true);
      for (var i = 1; i < 5; i++) {
        await saved.addTab(url: 'https://www.torn.com/p$i.php', tabUid: 'vis$i');
      }
      saved.updateSplitScreenWidth(wide);
      send(saved, 'vis4');
      send(saved, 'vis2');
      await settle();

      final restored = WebViewProvider();
      restored.splitScreenPosition = WebViewSplitPosition.left;
      await restored.addTab(url: 'https://www.torn.com/main.php', tabUid: 'main');
      await restored.initialiseSecondary(useTabs: true, recallLastSession: true);
      restored.updateSplitScreenWidth(wide);

      expect(shown(restored, SplitGroup.apart), 'vis2');
    });
  });

  group('visible tabs are not put to sleep', () {
    test('forcing hibernation spares every tab on screen', () async {
      final p = await build();
      send(p, 'tab3');
      p.activateTab(at(p, 'tab2'));
      expect(p.isTabVisible(at(p, 'tab2')), isTrue);
      expect(p.isTabVisible(at(p, 'tab3')), isTrue);

      await p.hibernateInactiveTabs();

      expect(p.tabList[at(p, 'tab2')].sleepTab, isFalse, reason: 'visible in the main group');
      expect(p.tabList[at(p, 'tab3')].sleepTab, isFalse, reason: 'visible in the apart group');
      expect(p.tabList[at(p, 'tab1')].sleepTab, isTrue, reason: 'hidden, control');
      expect(p.tabList[at(p, 'tab4')].sleepTab, isTrue, reason: 'hidden, control');
      expect(p.tabList[at(p, 'tab5')].sleepTab, isTrue, reason: 'hidden, control');
    });

    test('focusing the main group leaves the apart tab on screen', () async {
      final p = await build();
      send(p, 'tab3');

      p.focusTab(0);

      expect(p.focusedGroup, SplitGroup.main);
      expect(shown(p, SplitGroup.apart), 'tab3');
      expect(p.isTabVisible(at(p, 'tab3')), isTrue);
      expect(p.isTabVisible(0), isTrue);
    });

    test('with the app covering one slot only the other browser tab is on screen', () async {
      final p = await build();
      send(p, 'tab3');
      p.exitBrowserSlotToApp(p.slotOfGroup(SplitGroup.main));

      expect(p.isTabVisible(at(p, 'tab3')), isTrue);
      expect(p.isTabVisible(at(p, 'tab1')), isFalse);
    });

    test('with the app covering the apart group its tab is not on screen but the focused one is', () async {
      final p = await build();
      send(p, 'tab3');
      p.exitBrowserSlotToApp(p.slotOfGroup(SplitGroup.apart));

      expect(p.isTabVisible(p.currentTab), isTrue);
      expect(p.isTabVisible(at(p, 'tab3')), isFalse);
    });

    test('opening the browser from the app leaves both groups with a visible tab', () async {
      final p = await build();
      p.moveTabToOtherGroup(3);
      p.exitBrowserSlotToApp(p.slotOfGroup(SplitGroup.main));

      p.returnBrowserFromApp();

      expect(p.isTabVisible(p.visibleTabIndexForGroup(SplitGroup.main)!), isTrue);
      expect(p.isTabVisible(p.visibleTabIndexForGroup(SplitGroup.apart)!), isTrue);
    });
  });

  group('a tab sent to the other group goes to its end', () {
    test('[1 2 3 | 5 6] with the 3 sent across gives [1 2 | 5 6 3], and 1 2 5 6 3 when joined', () async {
      final p = await build(uids: ['t1', 't2', 't3', 't5', 't6']);
      send(p, 't5');
      send(p, 't6');
      expect(ids(p, SplitGroup.main), ['t1', 't2', 't3']);
      expect(ids(p, SplitGroup.apart), ['t5', 't6']);

      expect(send(p, 't3'), isTrue);

      expect(ids(p, SplitGroup.main), ['t1', 't2']);
      expect(ids(p, SplitGroup.apart), ['t5', 't6', 't3']);
      expect(order(p), ['t1', 't2', 't5', 't6', 't3']);

      p.updateSplitScreenWidth(narrow);
      expect(ids(p, SplitGroup.main), ['t1', 't2', 't5', 't6', 't3']);
    });

    test('a tab coming back to the main group goes to its end and to the end of the list', () async {
      final p = await build(uids: ['t1', 't2', 't3', 't4']);
      send(p, 't2');
      send(p, 't3');
      expect(order(p), ['t1', 't4', 't2', 't3']);

      send(p, 't2');

      expect(ids(p, SplitGroup.main), ['t1', 't4', 't2']);
      expect(ids(p, SplitGroup.apart), ['t3']);
      expect(order(p), ['t1', 't4', 't3', 't2']);
    });

    test('the moved tab is shown and focused, and the group it leaves shows its previous neighbour', () async {
      final p = await build(uids: ['t1', 't2', 't3', 't4']);
      p.activateTab(at(p, 't3'));

      send(p, 't3');

      expect(p.tabList[p.currentTab].id, 't3');
      expect(shown(p, SplitGroup.apart), 't3');
      expect(shown(p, SplitGroup.main), 't2');
    });

    test('moving another tab while the focus is elsewhere keeps both groups showing the right tab', () async {
      final p = await build(uids: ['t1', 't2', 't3', 't4', 't5']);
      send(p, 't5');
      expect(p.tabList[p.currentTab].id, 't5');

      send(p, 't3');

      expect(order(p), ['t1', 't2', 't4', 't5', 't3']);
      expect(p.tabList[p.currentTab].id, 't3');
      expect(shown(p, SplitGroup.apart), 't3');
      expect(p.isTabVisible(at(p, 't3')), isTrue);
    });

    test('the last tab of the apart group sent back leaves it blank', () async {
      final p = await build(uids: ['t1', 't2', 't3']);
      send(p, 't2');

      send(p, 't2');

      expect(order(p), ['t1', 't3', 't2']);
      expect(p.splitApartEmpty, isTrue);
    });
  });

  group('the app can open the browser', () {
    Future<WebViewProvider> appLeftApartRight() async {
      final p = await build(count: 4);
      p.moveTabToOtherGroup(2);
      expect(slots(p), [SplitSlotContent.mainBrowser, SplitSlotContent.apartBrowser]);
      expect(p.exitBrowserSlotToApp(SplitSide.left), isTrue);
      expect(slots(p), [SplitSlotContent.app, SplitSlotContent.apartBrowser]);
      return p;
    }

    test('[app | apart]: it can while it covers the main group', () async {
      final p = await appLeftApartRight();

      expect(p.webViewSplitActive, isTrue);
      expect(p.appCanOpenBrowser, isTrue);
      await settle();
    });

    test('[app | apart]: the focus stays in the apart group', () async {
      final p = await appLeftApartRight();
      expect(p.tabList[p.currentTab].id, 'tab2');

      p.browserShowInForeground = true;

      expect(p.tabList[p.currentTab].id, 'tab2');
      expect(p.isTabVisible(0), isTrue);
      expect(p.isTabVisible(at(p, 'tab2')), isTrue);
      await settle();
    });

    test('[app | apart]: a link to the main tab brings its group back with the focus', () async {
      final p = await appLeftApartRight();

      p.activateTab(0);
      p.browserShowInForeground = true;

      expect(slots(p), [SplitSlotContent.mainBrowser, SplitSlotContent.apartBrowser]);
      expect(p.currentTab, 0);
      expect(p.visibleTabIndexForGroup(SplitGroup.apart), at(p, 'tab2'));
      await settle();
    });

    test('[app | apart]: the returned browser can be closed to the app again', () async {
      final p = await appLeftApartRight();
      p.browserShowInForeground = true;

      p.browserShowInForeground = false;

      expect(slots(p).where((s) => s == SplitSlotContent.app).length, 1);
      expect(p.appCanOpenBrowser, isTrue);
      await settle();
    });

    test('split screen: the browser is already on screen', () async {
      final p = await build(count: 4, position: WebViewSplitPosition.right);

      expect(slots(p), [SplitSlotContent.app, SplitSlotContent.browser]);
      expect(p.appCanOpenBrowser, isFalse);
      await settle();
    });

    test('single view: the app can open the browser', () async {
      final p = await build(count: 4, position: WebViewSplitPosition.off);
      p.browserShowInForeground = false;

      expect(p.appCanOpenBrowser, isTrue);
      await settle();
    });
  });
}
