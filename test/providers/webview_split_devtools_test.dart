import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/providers/terminal_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/webviews/tabs_wipe_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const double wide = 1000;
  const double narrow = 700;

  late Directory tempDir;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('split_devtools_test');
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

  Future<WebViewProvider> build({
    bool revertsToApp = false,
    WebViewSplitPosition position = WebViewSplitPosition.right,
  }) async {
    final provider = WebViewProvider();
    provider.splitScreenRevertsToApp = revertsToApp;
    provider.splitScreenPosition = position;
    for (var i = 0; i < 5; i++) {
      await provider.addTab(url: 'https://www.torn.com/page$i.php', tabUid: 'tab$i');
    }
    provider.updateSplitScreenWidth(wide);
    return provider;
  }

  List<SplitSlotContent?> slots(WebViewProvider p) => [p.splitLeftSlot, p.splitRightSlot];

  int at(WebViewProvider p, String uid) => p.tabList.indexWhere((t) => t.id == uid);

  bool send(WebViewProvider p, String uid) => p.moveTabToOtherGroup(at(p, uid));

  String focused(WebViewProvider p) => p.tabList[p.currentTab].id;

  String shownIn(WebViewProvider p, SplitGroup group) => p.tabList[p.visibleTabIndexForGroup(group)!].id;

  void expectPainted(WebViewProvider p) {
    final SplitSide? slot = p.splitDevToolsSlot;
    expect(p.splitLeftSlot == SplitSlotContent.devTools, slot == SplitSide.left);
    expect(p.splitRightSlot == SplitSlotContent.devTools, slot == SplitSide.right);
  }

  // [apart tab3 | main], focus on tab3
  Future<WebViewProvider> buildTwoBrowsers() async {
    final p = await build();
    send(p, 'tab3');
    expect(slots(p), [SplitSlotContent.apartBrowser, SplitSlotContent.mainBrowser]);
    expect(focused(p), 'tab3');
    return p;
  }

  group('next to the app', () {
    test('they take the slot of the app, which comes back on closing them', () async {
      final p = await build();
      expect(slots(p), [SplitSlotContent.app, SplitSlotContent.browser]);

      expect(p.openSplitDevTools(focused(p)), isTrue);
      expect(slots(p), [SplitSlotContent.devTools, SplitSlotContent.browser]);
      expect(p.splitDevToolsSlot, SplitSide.left);
      expect(p.webViewSplitActive, isTrue);
      expect(p.splitAppSide, SplitSide.left);

      p.closeSplitDevTools();
      expect(slots(p), [SplitSlotContent.app, SplitSlotContent.browser]);
      expect(p.splitDevToolsSlot, isNull);
      expect(p.webViewSplitActive, isTrue);
    });

    test('they follow the tab shown next to them', () async {
      final p = await build();
      p.openSplitDevTools(focused(p));
      p.activateTab(at(p, 'tab2'));
      expect(focused(p), 'tab2');
      expect(slots(p), [SplitSlotContent.devTools, SplitSlotContent.browser]);
    });

    test('moving a tab to the other side closes them and shows the tab where they were', () async {
      final p = await build();
      p.openSplitDevTools(focused(p));
      send(p, 'tab2');
      expect(p.splitDevToolsSlot, isNull);
      expect(slots(p), [SplitSlotContent.apartBrowser, SplitSlotContent.mainBrowser]);
      expect(shownIn(p, SplitGroup.apart), 'tab2');
      expect(focused(p), 'tab2');
    });
  });

  group('with two browsers', () {
    test('they cover the other group, which comes back as it was on closing them', () async {
      final p = await buildTwoBrowsers();
      final String mainShown = shownIn(p, SplitGroup.main);

      expect(p.openSplitDevTools('tab3'), isTrue);
      expect(slots(p), [SplitSlotContent.apartBrowser, SplitSlotContent.devTools]);
      expect(p.webViewSplitActive, isFalse);
      expect(p.isTabUidVisible('tab3'), isTrue);
      expect(p.isTabUidVisible(mainShown), isFalse);

      p.closeSplitDevTools();
      expect(slots(p), [SplitSlotContent.apartBrowser, SplitSlotContent.mainBrowser]);
      expect(shownIn(p, SplitGroup.main), mainShown);
      expect(p.isTabUidVisible(mainShown), isTrue);
      expect(focused(p), 'tab3');
    });

    test('opened from the main group they cover the apart group', () async {
      final p = await buildTwoBrowsers();
      final String mainShown = shownIn(p, SplitGroup.main);

      expect(p.openSplitDevTools(mainShown), isTrue);
      expect(focused(p), mainShown);
      expect(slots(p), [SplitSlotContent.devTools, SplitSlotContent.mainBrowser]);
      expect(p.isTabUidVisible('tab3'), isFalse);
    });

    test('they follow the tab shown next to them', () async {
      final p = await buildTwoBrowsers();
      send(p, 'tab4');
      p.openSplitDevTools('tab4');
      p.activateTab(at(p, 'tab3'));
      expect(focused(p), 'tab3');
      expect(slots(p), [SplitSlotContent.apartBrowser, SplitSlotContent.devTools]);
    });

    test('activating from outside a tab of the covered group closes them and shows it', () async {
      final p = await buildTwoBrowsers();
      p.openSplitDevTools(shownIn(p, SplitGroup.main));
      expect(slots(p), [SplitSlotContent.devTools, SplitSlotContent.mainBrowser]);

      p.activateTab(at(p, 'tab3'));
      expect(p.splitDevToolsSlot, isNull);
      expect(slots(p), [SplitSlotContent.apartBrowser, SplitSlotContent.mainBrowser]);
      expect(focused(p), 'tab3');
    });

    test('moving a tab to the covered group closes them and shows the tab there', () async {
      final p = await buildTwoBrowsers();
      p.openSplitDevTools(shownIn(p, SplitGroup.main));
      send(p, 'tab2');
      expect(p.splitDevToolsSlot, isNull);
      expect(slots(p), [SplitSlotContent.apartBrowser, SplitSlotContent.mainBrowser]);
      expect(shownIn(p, SplitGroup.apart), 'tab2');
    });

    test('closing the last tab of their panel closes them', () async {
      final p = await buildTwoBrowsers();
      final String mainShown = shownIn(p, SplitGroup.main);
      p.openSplitDevTools('tab3');
      await p.removeTab(position: at(p, 'tab3'));
      expect(p.splitDevToolsSlot, isNull);
      expect(p.isTabUidVisible(mainShown), isTrue);
    });

    test('closing another tab of their panel keeps them', () async {
      final p = await buildTwoBrowsers();
      send(p, 'tab4');
      p.openSplitDevTools('tab4');
      await p.removeTab(position: at(p, 'tab4'));
      expect(focused(p), 'tab3');
      expect(slots(p), [SplitSlotContent.apartBrowser, SplitSlotContent.devTools]);
    });

    test('leaving the browser for the app closes them', () async {
      final p = await buildTwoBrowsers();
      p.openSplitDevTools('tab3');
      expect(p.exitBrowserSlotToApp(p.slotOfGroup(SplitGroup.apart)), isTrue);
      expect(p.splitDevToolsSlot, isNull);
      expect(slots(p), [SplitSlotContent.app, SplitSlotContent.mainBrowser]);
    });

    test('with the app over a group they take the slot of the app', () async {
      final p = await buildTwoBrowsers();
      send(p, 'tab4');
      p.exitBrowserSlotToApp(p.slotOfGroup(SplitGroup.main));
      expect(slots(p), [SplitSlotContent.apartBrowser, SplitSlotContent.app]);

      p.openSplitDevTools(focused(p));
      expect(slots(p), [SplitSlotContent.apartBrowser, SplitSlotContent.devTools]);
      expect(p.webViewSplitActive, isTrue);
      p.closeSplitDevTools();
      expect(slots(p), [SplitSlotContent.apartBrowser, SplitSlotContent.app]);
    });
  });

  group('narrowing and widening', () {
    for (final revertsToApp in [false, true]) {
      test('next to the app they hide and come back (revert to app: $revertsToApp)', () async {
        final p = await build(revertsToApp: revertsToApp);
        p.openSplitDevTools(focused(p));

        p.updateSplitScreenWidth(narrow);
        expect(p.splitDevToolsSlot, isNull);
        expect(p.splitRightSlot, isNull);
        expect(p.webViewSplitActive, isFalse);

        p.updateSplitScreenWidth(wide);
        expect(slots(p), [SplitSlotContent.devTools, SplitSlotContent.browser]);
        expect(p.webViewSplitActive, isTrue);
      });

      test('with two browsers they hide and come back (revert to app: $revertsToApp)', () async {
        final p = await build(revertsToApp: revertsToApp);
        send(p, 'tab3');
        p.openSplitDevTools('tab3');

        p.updateSplitScreenWidth(narrow);
        expect(p.splitDevToolsSlot, isNull);
        expect(p.splitRightSlot, isNull);

        p.updateSplitScreenWidth(wide);
        expect(slots(p), [SplitSlotContent.apartBrowser, SplitSlotContent.devTools]);
        expect(p.isTabUidVisible('tab3'), isTrue);
      });
    }

    test('on a narrow screen they open full screen', () async {
      final p = await build();
      p.updateSplitScreenWidth(narrow);
      expect(p.openSplitDevTools(focused(p)), isFalse);
      p.updateSplitScreenWidth(wide);
      expect(p.splitDevToolsSlot, isNull);
      expect(slots(p), [SplitSlotContent.app, SplitSlotContent.browser]);
    });

    test('with split screen off in Settings they open full screen', () async {
      final p = await build(position: WebViewSplitPosition.off);
      p.browserShowInForeground = true;
      expect(p.openSplitDevTools(focused(p)), isFalse);
      expect(p.splitDevToolsSlot, isNull);
    });
  });

  group('the DevTools slot is always painted', () {
    final Map<String, List<void Function(WebViewProvider)>> scenarios = {
      'next to the app': [
        (p) => p.openSplitDevTools(focused(p)),
        (p) => p.activateTab(at(p, 'tab2')),
        (p) => p.updateSplitScreenWidth(narrow),
        (p) => p.updateSplitScreenWidth(wide),
        (p) => p.splitScreenRatio = 0.3,
        (p) => p.browserShowInForeground = false,
        (p) => p.openSplitDevTools(focused(p)),
        (p) => send(p, 'tab4'),
        (p) => p.openSplitDevTools('tab4'),
        (p) => p.splitBrowsersAllowedRC = false,
        (p) => p.splitBrowsersAllowedRC = true,
        (p) => p.openSplitDevTools(focused(p)),
        (p) => p.splitScreenPosition = WebViewSplitPosition.left,
        (p) => p.splitScreenPosition = WebViewSplitPosition.off,
        (p) => p.splitScreenPosition = WebViewSplitPosition.right,
      ],
      'with two browsers': [
        (p) => send(p, 'tab3'),
        (p) => p.openSplitDevTools('tab3'),
        (p) => send(p, 'tab4'),
        (p) => p.openSplitDevTools('tab4'),
        (p) => p.activateTab(at(p, 'tab3')),
        (p) => p.openSplitDevTools(shownIn(p, SplitGroup.main)),
        (p) => p.activateTab(at(p, 'tab1')),
        (p) => p.activateTab(at(p, 'tab4')),
        (p) => p.openSplitDevTools('tab4'),
        (p) => p.updateSplitScreenWidth(narrow),
        (p) => p.activateTab(at(p, 'tab2')),
        (p) => p.updateSplitScreenWidth(wide),
        (p) => p.exitBrowserSlotToApp(p.slotOfGroup(SplitGroup.apart)),
        (p) => p.openSplitDevTools(focused(p)),
        (p) => p.browserShowInForeground = true,
        (p) => p.returnBrowserFromApp(),
        (p) => p.openSplitDevTools('tab3'),
        (p) => p.wipeTabs(includeLockedTabs: true, timeRange: TabsWipeTimeRange.any),
      ],
    };
    for (final scenario in scenarios.entries) {
      for (final revertsToApp in [false, true]) {
        test('${scenario.key} (revert to app: $revertsToApp)', () async {
          final p = await build(revertsToApp: revertsToApp);
          expectPainted(p);
          for (final step in scenario.value) {
            step(p);
            expectPainted(p);
            await Future<void>.delayed(const Duration(milliseconds: 10));
          }
        });
      }
    }
  });

  group('turning split screen off forgets them', () {
    test('in Settings, even while they are hidden on a narrow screen', () async {
      final p = await build();
      p.openSplitDevTools(focused(p));
      p.updateSplitScreenWidth(narrow);
      p.splitScreenPosition = WebViewSplitPosition.off;
      p.updateSplitScreenWidth(wide);
      p.splitScreenPosition = WebViewSplitPosition.right;
      expect(p.splitDevToolsSlot, isNull);
      expect(slots(p), [SplitSlotContent.app, SplitSlotContent.browser]);
    });

    test('with the Remote Config switch', () async {
      final p = await build();
      p.openSplitDevTools(focused(p));
      p.splitBrowsersAllowedRC = false;
      expect(p.splitDevToolsSlot, isNull);
      p.splitBrowsersAllowedRC = true;
      expect(p.splitDevToolsSlot, isNull);
      expect(slots(p), [SplitSlotContent.app, SplitSlotContent.browser]);
    });
  });

  test('opening them again keeps their inner tab and opening them anew starts on the terminal', () async {
    final p = await build();
    p.openSplitDevTools(focused(p));
    p.splitDevToolsTabIndex = 1;
    p.openSplitDevTools(focused(p));
    expect(p.splitDevToolsTabIndex, 1);
    p.closeSplitDevTools();
    p.openSplitDevTools(focused(p));
    expect(p.splitDevToolsTabIndex, 0);
  });

  group('console of the tabs', () {
    test('a sleeping tab keeps it and a closed tab frees it', () async {
      final p = await build();
      final terminal = TerminalProvider();
      final key = p.tabList[at(p, 'tab2')].webViewKey;
      terminal.addInstruction(key, 'hello');

      p.releaseTabConsole(terminal, tabUid: 'tab2', disposedKey: key);
      expect(terminal.getTerminal(key), contains('hello'));

      await p.removeTab(position: at(p, 'tab2'));
      p.releaseTabConsole(terminal, tabUid: 'tab2', disposedKey: key);
      expect(terminal.hasTerminal(key), isFalse);
    });

    test('a rebuilt tab keeps it under its new key', () async {
      final p = await build();
      final terminal = TerminalProvider();
      final oldKey = p.tabList[at(p, 'tab3')].webViewKey;
      terminal.addInstruction(oldKey, 'before');

      p.rebuildUnresponsiveWebView(tabUid: 'tab3', isChainingBrowser: false, chainingPayload: null);
      final newKey = p.tabList[at(p, 'tab3')].webViewKey;
      expect(newKey, isNot(oldKey));
      terminal.addInstruction(newKey, 'after');

      p.releaseTabConsole(terminal, tabUid: 'tab3', disposedKey: oldKey);
      expect(terminal.hasTerminal(oldKey), isFalse);
      expect(terminal.getTerminal(newKey), '[OUT] < after\n\n[OUT] < before\n\n');
    });
  });
}
