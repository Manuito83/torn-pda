import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/main.dart' show kSplitScreenMinWidth;
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
  }) async {
    final provider = WebViewProvider();
    provider.splitScreenRevertsToApp = revertsToApp;
    provider.splitScreenPosition = position;
    for (var i = 0; i < count; i++) {
      await provider.addTab(url: 'https://www.torn.com/page$i.php', tabUid: 'tab$i');
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

    test('the sent tab is shown and focused in the slot where the app was', () async {
      final p = await build(count: 5, position: WebViewSplitPosition.right);
      p.moveTabToOtherGroup(3);

      expect(shown(p, SplitGroup.apart), 'tab3');
      expect(p.tabList[p.currentTab].id, 'tab3');
      expect(p.focusedGroup, SplitGroup.apart);
      expect(p.isTabVisible(at(p, 'tab3')), isTrue);
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

    test('the main group is never empty either when it sits on the right', () async {
      final p = await build(count: 4, position: WebViewSplitPosition.right);
      for (var i = 1; i < 4; i++) {
        send(p, 'tab$i');
      }

      expect(p.slotOfGroup(SplitGroup.main), SplitSide.right);
      expect(p.tabIndexesForGroup(SplitGroup.main), [0]);
      expect(p.visibleTabIndexForGroup(SplitGroup.main), 0);
      expect(p.splitRightSlot, SplitSlotContent.mainBrowser);
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

    test(
      'current behaviour, not contract: with the app covering the main group, the last apart tab closes the group',
      () async {
        final p = await build(count: 3);
        p.moveTabToOtherGroup(2);
        p.exitBrowserSlotToApp(p.slotOfGroup(SplitGroup.main));
        expect(slots(p), contains(SplitSlotContent.app));

        await p.removeTab(position: 2);

        expect(p.splitApartOpen, isFalse);
        expect(slots(p), isNot(contains(SplitSlotContent.apartBrowser)));
      },
    );
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

    test('from the main tab it is born in the main group', () async {
      final p = await build(count: 3);

      await p.addTab(url: 'https://www.torn.com/new.php', tabUid: 'child', openerTabUid: 'tab0');

      expect(p.tabList.last.splitApart, isFalse);
    });

    test('from an apart tab with the apart group on the left it is still born apart', () async {
      final p = await build(count: 4, position: WebViewSplitPosition.right);
      p.moveTabToOtherGroup(2);
      expect(p.slotOfGroup(SplitGroup.apart), SplitSide.left);

      await p.addTab(url: 'https://www.torn.com/new.php', tabUid: 'child', openerTabUid: 'tab2');

      expect(ids(p, SplitGroup.apart), ['tab2', 'child']);
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

    test('with two browsers and tabs in both, either of them can be closed', () async {
      final p = await build();
      p.moveTabToOtherGroup(2);

      expect(p.splitBrowserCanExitToApp, isTrue);
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

    test('with the apart group empty and the main group on the right it is not possible either', () async {
      final p = await build(count: 3, position: WebViewSplitPosition.right);
      p.moveTabToOtherGroup(2);
      await p.removeTab(position: 2);

      expect(p.splitBrowserCanExitToApp, isFalse);
      expect(p.exitBrowserSlotToApp(p.slotOfGroup(SplitGroup.main)), isFalse);
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
    test('threshold is 800 pt: at that width it is wide', () async {
      expect(kSplitScreenMinWidth, 800);

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

  group('split screen setting', () {
    test('off: tabs cannot be sent apart', () async {
      final p = await build(position: WebViewSplitPosition.off);

      expect(p.moveTabToOtherGroup(2), isFalse);
      expect(p.splitBrowsersActive, isFalse);
      expect(p.tabList[2].splitApart, isFalse);
    });

    test('turning it off with two browsers: back to a single view with every tab', () async {
      final p = await build();
      p.moveTabToOtherGroup(2);
      p.moveTabToOtherGroup(4);

      p.splitScreenPosition = WebViewSplitPosition.off;

      expect(p.splitBrowsersActive, isFalse);
      expect(p.tabIndexesForGroup(SplitGroup.main), [0, 1, 2, 3, 4, 5]);
      expect(p.tabIndexesForGroup(SplitGroup.apart), isEmpty);
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

      expect(restored.apartVisibleTabUid, 'vis2');
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

    test('the tab with the focus and the visible tab of the other group both count as visible', () async {
      final p = await build();
      send(p, 'tab3');
      p.activateTab(at(p, 'tab2'));

      expect(p.isTabVisible(at(p, 'tab2')), isTrue);
      expect(p.isTabVisible(at(p, 'tab3')), isTrue);
      expect(p.isTabVisible(at(p, 'tab1')), isFalse);
      expect(p.isTabVisible(at(p, 'tab4')), isFalse);
      expect(p.isTabUidVisible('tab3'), isTrue);
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
}
