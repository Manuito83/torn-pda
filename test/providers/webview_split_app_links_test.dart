import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/webviews/chaining_payload.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const double wide = 1000;
  const double narrow = 700;
  const String link = 'https://www.torn.com/link.php';

  late Directory tempDir;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('split_app_links_test');
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

  List<SplitSlotContent?> slots(WebViewProvider p) => [p.splitLeftSlot, p.splitRightSlot];

  int at(WebViewProvider p, String uid) => p.tabList.indexWhere((t) => t.id == uid);

  late SettingsProvider settings;

  Future<WebViewProvider> build({
    required WebViewSplitPosition position,
    double width = wide,
    SplitAppLinkTarget target = SplitAppLinkTarget.browserTab,
  }) async {
    final provider = WebViewProvider();
    provider.splitScreenPosition = position;
    for (var i = 0; i < 4; i++) {
      await provider.addTab(url: 'https://www.torn.com/page$i.php', tabUid: 'tab$i');
    }
    provider.updateSplitScreenWidth(width);
    settings = SettingsProvider()..splitAppLinkTarget = target;
    return provider;
  }

  Future<bool> tap(
    WebViewProvider p, {
    BrowserTapType type = BrowserTapType.short,
    bool fromNotification = false,
    ChainingPayload? chain,
  }) async {
    final bool opened = await p.openLinkBesideApp(
      url: link,
      tapType: type,
      fromNotification: fromNotification,
      settings: settings,
      isChainingBrowser: chain != null,
      chainingPayload: chain,
    );
    await settle();
    return opened;
  }

  // tab2 apart, under the app
  Future<WebViewProvider> browserBesideApartUnderApp({
    required WebViewSplitPosition position,
    required SplitAppLinkTarget target,
  }) async {
    final p = await build(position: position, target: target);
    p.moveTabToOtherGroup(2);
    p.activateTab(at(p, 'tab1'));
    expect(p.exitBrowserSlotToApp(p.slotOfGroup(SplitGroup.apart)), isTrue);
    expect(p.tabList[p.currentTab].id, 'tab1');
    return p;
  }

  for (final position in [WebViewSplitPosition.left, WebViewSplitPosition.right]) {
    final bool appRight = position == WebViewSplitPosition.left;
    final List<SplitSlotContent> before = appRight
        ? [SplitSlotContent.mainBrowser, SplitSlotContent.app]
        : [SplitSlotContent.app, SplitSlotContent.mainBrowser];
    final List<SplitSlotContent> bothBrowsers = appRight
        ? [SplitSlotContent.mainBrowser, SplitSlotContent.apartBrowser]
        : [SplitSlotContent.apartBrowser, SplitSlotContent.mainBrowser];

    group(appRight ? '[browser | app] with a group under the app' : '[app | browser] with a group under the app', () {
      test('current tab: loads in the tab beside and the app stays', () async {
        final p = await browserBesideApartUnderApp(position: position, target: SplitAppLinkTarget.browserTab);
        expect(slots(p), before);

        expect(await tap(p), isTrue);

        expect(slots(p), before);
        expect(p.tabList.length, 4);
        expect(p.tabList[p.currentTab].id, 'tab1');
        expect(p.tabList[at(p, 'tab1')].currentUrl, link);
        expect(p.tabList[at(p, 'tab2')].currentUrl, isNot(link));
      });

      test('new tab: opens at the end of the browser beside and the app stays', () async {
        final p = await browserBesideApartUnderApp(position: position, target: SplitAppLinkTarget.browserNewTab);

        expect(await tap(p), isTrue);

        expect(slots(p), before);
        expect(p.tabList.length, 5);
        expect(p.currentTab, 4);
        expect(p.tabList.last.currentUrl, link);
        expect(p.tabList.last.splitApart, isFalse);
      });

      test('tab behind the app: the app leaves and that tab loads', () async {
        final p = await browserBesideApartUnderApp(position: position, target: SplitAppLinkTarget.appSideTab);

        expect(await tap(p), isTrue);

        expect(slots(p), bothBrowsers);
        expect(p.tabList.length, 4);
        expect(p.tabList[p.currentTab].id, 'tab2');
        expect(p.tabList[at(p, 'tab2')].currentUrl, link);
        expect(p.tabList[at(p, 'tab1')].currentUrl, isNot(link));
      });

      test('new tab on the app side: the app leaves and the tab opens at the end of that group', () async {
        final p = await browserBesideApartUnderApp(position: position, target: SplitAppLinkTarget.appSideNewTab);

        expect(await tap(p), isTrue);

        expect(slots(p), bothBrowsers);
        expect(p.tabList.length, 5);
        expect(p.currentTab, 4);
        expect(p.tabList.last.currentUrl, link);
        expect(p.tabList.last.splitApart, isTrue);
      });
    });

    group(appRight ? '[browser | app] with nothing under the app' : '[app | browser] with nothing under the app', () {
      final List<SplitSlotContent> today = appRight
          ? [SplitSlotContent.browser, SplitSlotContent.app]
          : [SplitSlotContent.app, SplitSlotContent.browser];

      test('current tab: loads in the focused tab, not in the main one', () async {
        final p = await build(position: position);
        p.activateTab(2);
        expect(slots(p), today);

        expect(await tap(p), isTrue);

        expect(slots(p), today);
        expect(p.currentTab, 2);
        expect(p.tabList[2].currentUrl, link);
        expect(p.tabList[0].currentUrl, isNot(link));
      });

      test('new tab: opens at the end of the browser and the app stays', () async {
        final p = await build(position: position, target: SplitAppLinkTarget.browserNewTab);

        expect(await tap(p), isTrue);

        expect(slots(p), today);
        expect(p.tabList.length, 5);
        expect(p.currentTab, 4);
        expect(p.tabList.last.currentUrl, link);
        expect(p.tabList.last.splitApart, isFalse);
      });

      for (final target in [SplitAppLinkTarget.appSideTab, SplitAppLinkTarget.appSideNewTab]) {
        test('${target.name}: a new tab opens a group where the app was', () async {
          final p = await build(position: position, target: target);

          expect(await tap(p), isTrue);

          expect(slots(p), bothBrowsers);
          expect(p.tabList.length, 5);
          expect(p.currentTab, 4);
          expect(p.tabList.last.currentUrl, link);
          expect(p.tabList.last.splitApart, isTrue);
          expect(p.tabList.where((t) => t.splitApart).length, 1);
        });
      }
    });
  }

  group('the app covering the main group', () {
    // [app | apart], focus on tab2
    Future<WebViewProvider> appOverMain(SplitAppLinkTarget target) async {
      final p = await build(position: WebViewSplitPosition.left, target: target);
      p.moveTabToOtherGroup(2);
      p.activateTab(at(p, 'tab1'));
      expect(p.exitBrowserSlotToApp(SplitSide.left), isTrue);
      expect(slots(p), [SplitSlotContent.app, SplitSlotContent.apartBrowser]);
      expect(p.tabList[p.currentTab].id, 'tab2');
      return p;
    }

    test('current tab: loads in the apart tab beside', () async {
      final p = await appOverMain(SplitAppLinkTarget.browserTab);

      expect(await tap(p), isTrue);

      expect(slots(p), [SplitSlotContent.app, SplitSlotContent.apartBrowser]);
      expect(p.tabList[at(p, 'tab2')].currentUrl, link);
    });

    test('new tab: opens in the apart group beside', () async {
      final p = await appOverMain(SplitAppLinkTarget.browserNewTab);

      expect(await tap(p), isTrue);

      expect(slots(p), [SplitSlotContent.app, SplitSlotContent.apartBrowser]);
      expect(p.tabList.last.currentUrl, link);
      expect(p.tabList.last.splitApart, isTrue);
      expect(p.currentTab, 4);
    });

    test('tab behind the app: the main group comes back with its shown tab', () async {
      final p = await appOverMain(SplitAppLinkTarget.appSideTab);

      expect(await tap(p), isTrue);

      expect(slots(p), [SplitSlotContent.mainBrowser, SplitSlotContent.apartBrowser]);
      expect(p.tabList[p.currentTab].id, 'tab1');
      expect(p.tabList[at(p, 'tab1')].currentUrl, link);
    });

    test('new tab on the app side: opens at the end of the main group', () async {
      final p = await appOverMain(SplitAppLinkTarget.appSideNewTab);

      expect(await tap(p), isTrue);

      expect(slots(p), [SplitSlotContent.mainBrowser, SplitSlotContent.apartBrowser]);
      expect(p.tabList.last.currentUrl, link);
      expect(p.tabList.last.splitApart, isFalse);
      expect(p.currentTab, 4);
    });
  });

  group('chaining', () {
    ChainingPayload payload() => ChainingPayload()
      ..attackIdList = ['1']
      ..attackNameList = ['target']
      ..attackNotesList = ['']
      ..attackNotesColorList = ['']
      ..showNotes = false
      ..showBlankNotes = false
      ..showOnlineFactionWarning = false;

    for (final (target, uid) in [
      (SplitAppLinkTarget.browserTab, 'tab1'),
      (SplitAppLinkTarget.browserNewTab, null),
      (SplitAppLinkTarget.appSideTab, 'tab2'),
      (SplitAppLinkTarget.appSideNewTab, null),
    ]) {
      test('${target.name}: the tab that opens the link becomes the chaining one', () async {
        final p = await browserBesideApartUnderApp(position: WebViewSplitPosition.left, target: target);
        final ChainingPayload chain = payload();

        expect(await tap(p, type: BrowserTapType.chainShort, chain: chain), isTrue);

        final TabDetails opened = uid == null ? p.tabList.last : p.tabList[at(p, uid)];
        expect(p.tabList.length, uid == null ? 5 : 4);
        expect(opened.isChainingBrowser, isTrue);
        expect(opened.chainingPayload, same(chain));
        expect(opened.currentUrl, link);
        expect(p.tabList[0].isChainingBrowser, isFalse);
        expect(p.tabList[0].currentUrl, isNot(link));
        expect(p.tabList.where((t) => t.isChainingBrowser).length, 1);
      });
    }

    test('cancelling without a tab cancels the main one, as always', () async {
      final p = await build(position: WebViewSplitPosition.right);
      p.convertToChainingBrowser(chainingPayload: payload());
      p.activateTab(2);
      expect(p.tabList[0].isChainingBrowser, isTrue);

      p.cancelChainingBrowser();
      await settle();

      expect(p.tabList[0].isChainingBrowser, isFalse);
    });

    test('cancelling a given tab leaves the main one chaining', () async {
      final p = await build(position: WebViewSplitPosition.right);
      p.convertToChainingBrowser(chainingPayload: payload());
      p.convertToChainingBrowser(chainingPayload: payload(), index: 2);
      p.activateTab(1);

      p.cancelChainingBrowser(tabUid: 'tab2');
      await settle();

      expect(p.tabList[at(p, 'tab2')].isChainingBrowser, isFalse);
      expect(p.tabList[0].isChainingBrowser, isTrue);
    });

    test('cancelling a tab that is gone does nothing', () async {
      final p = await build(position: WebViewSplitPosition.right);
      p.convertToChainingBrowser(chainingPayload: payload());

      p.cancelChainingBrowser(tabUid: 'gone');
      await settle();

      expect(p.tabList[0].isChainingBrowser, isTrue);
    });
  });

  test('a sleeping tab behind the app wakes with the link', () async {
    final p = await browserBesideApartUnderApp(
      position: WebViewSplitPosition.left,
      target: SplitAppLinkTarget.appSideTab,
    );
    await p.hibernateInactiveTabs();
    expect(p.tabList[at(p, 'tab2')].sleepTab, isTrue);

    expect(await tap(p), isTrue);

    final TabDetails woken = p.tabList[at(p, 'tab2')];
    expect(woken.sleepTab, isFalse);
    expect(woken.webView, isNotNull);
    expect(woken.currentUrl, link);
    expect(p.tabList[p.currentTab].id, 'tab2');
  });

  group('a fully locked target tab', () {
    test('current tab: opens a new tab in the browser beside and the app stays', () async {
      final p = await browserBesideApartUnderApp(
        position: WebViewSplitPosition.left,
        target: SplitAppLinkTarget.browserTab,
      );
      p.tabList[at(p, 'tab1')]
        ..isLocked = true
        ..isLockFull = true;

      expect(await tap(p), isTrue);

      expect(slots(p), [SplitSlotContent.mainBrowser, SplitSlotContent.app]);
      expect(p.tabList[at(p, 'tab1')].currentUrl, isNot(link));
      expect(p.tabList.length, 5);
      expect(p.currentTab, 4);
      expect(p.tabList.last.currentUrl, link);
      expect(p.tabList.last.splitApart, isFalse);
    });

    test('tab behind the app: opens a new tab in that group and the app leaves', () async {
      final p = await browserBesideApartUnderApp(
        position: WebViewSplitPosition.left,
        target: SplitAppLinkTarget.appSideTab,
      );
      p.tabList[at(p, 'tab2')]
        ..isLocked = true
        ..isLockFull = true;

      expect(await tap(p), isTrue);

      expect(slots(p), [SplitSlotContent.mainBrowser, SplitSlotContent.apartBrowser]);
      expect(p.tabList[at(p, 'tab2')].currentUrl, isNot(link));
      expect(p.tabList.length, 5);
      expect(p.currentTab, 4);
      expect(p.tabList.last.currentUrl, link);
      expect(p.tabList.last.splitApart, isTrue);
    });
  });

  group('the usual path', () {
    for (final type in [BrowserTapType.notification, BrowserTapType.deeplink]) {
      test('${type.name}: left to the usual path, nothing changes', () async {
        final p = await browserBesideApartUnderApp(
          position: WebViewSplitPosition.left,
          target: SplitAppLinkTarget.appSideNewTab,
        );

        expect(await tap(p, type: type), isFalse);

        expect(slots(p), [SplitSlotContent.mainBrowser, SplitSlotContent.app]);
        expect(p.tabList.length, 4);
        expect(p.tabList.every((t) => t.currentUrl != link), isTrue);
      });
    }

    test('a Loot Rangers notification, a chaining tap, is left to the usual path', () async {
      final p = await browserBesideApartUnderApp(
        position: WebViewSplitPosition.left,
        target: SplitAppLinkTarget.appSideNewTab,
      );

      expect(await tap(p, type: BrowserTapType.chainShort, fromNotification: true), isFalse);

      expect(slots(p), [SplitSlotContent.mainBrowser, SplitSlotContent.app]);
      expect(p.tabList.length, 4);
      expect(p.tabList.every((t) => t.currentUrl != link), isTrue);
    });

    test('a narrow screen is left to the usual path', () async {
      final p = await build(
        position: WebViewSplitPosition.right,
        width: narrow,
        target: SplitAppLinkTarget.appSideNewTab,
      );

      expect(await tap(p, type: BrowserTapType.long), isFalse);

      expect(p.splitRightSlot, isNull);
      expect(p.tabList.length, 4);
      expect(p.tabList.every((t) => t.currentUrl != link), isTrue);
    });

    test('two browsers on screen, with no app, are left to the usual path', () async {
      final p = await build(position: WebViewSplitPosition.left, target: SplitAppLinkTarget.appSideNewTab);
      p.moveTabToOtherGroup(2);
      expect(slots(p), [SplitSlotContent.mainBrowser, SplitSlotContent.apartBrowser]);

      expect(await tap(p), isFalse);

      expect(p.tabList.length, 4);
    });

    test('split screen off is left to the usual path', () async {
      final p = await build(position: WebViewSplitPosition.off, target: SplitAppLinkTarget.appSideNewTab);

      expect(await tap(p), isFalse);

      expect(p.tabList.length, 4);
    });
  });
}
