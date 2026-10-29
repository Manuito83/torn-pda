import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';
import 'package:torn_pda/widgets/webviews/webview_full.dart';

import 'chat_fakes.dart';

class ColdBrowser extends WebViewProvider {
  ColdBrowser(this.saved, {this.active = 0, this.restores = true});

  final List<String> saved;
  final int active;
  final bool restores;
  var restoreCalls = 0;

  @override
  Future<void> restoreBehind() async {
    restoreCalls++;
    if (!restores) return;
    for (var i = 0; i < saved.length; i++) {
      await addTab(sleepTab: true, url: saved[i], tabUid: 'tab$i');
    }
    currentTab = active;
  }
}

void main() {
  useTempPathProvider();

  const torn = 'https://www.torn.com/index.php';
  const other = 'https://www.example.org';
  var live = true;

  setUp(() async {
    await Prefs().setWebViewSecondaryTabs('{"tabsSave":[]}');
    await Prefs().setWebViewMainTab('{"tabsSave":[]}');
    await Prefs().setSplitBrowsersLayout('');
    await Prefs().setWebViewLastActiveTab(0);
    NativeChat.resetTabs();
    NativeChat.prefs.inAppEnabled = true;
    NativeChat.keyValid.value = true;
    NativeChat.sessionOk = () => true;
    live = true;
    NativeChat.isLive = (_) => live;
  });

  tearDown(() {
    NativeChat.bigWindow.value = null;
    NativeChat.quickWindows.value = const [];
    NativeChat.resetTabs();
    NativeChat.isLive = NativeChat.tabAlive;
    NativeChat.setTabGrace(30);
  });

  Future<GlobalKey<NavigatorState>> mount(WidgetTester tester, WebViewProvider web) async {
    final key = GlobalKey<NavigatorState>();
    NativeChat.navigatorKey = key;
    addTearDown(() => NativeChat.navigatorKey = null);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<WebViewProvider>.value(value: web),
          ChangeNotifierProvider<SettingsProvider>(create: (_) => SettingsProvider()),
        ],
        child: MaterialApp(
          navigatorKey: key,
          navigatorObservers: [BotToastNavigatorObserver()],
          builder: BotToastInit(),
          home: const SizedBox(),
        ),
      ),
    );
    NativeChat.watchTabs(web);
    return key;
  }

  Future<void> secs(WidgetTester tester, int n) async {
    for (var i = 0; i < n; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
  }

  Future<void> end(WidgetTester tester) async {
    await secs(tester, 3);
    await tester.pumpWidget(const SizedBox());
    NativeChat.resetTabs();
    // Saved prefs queue behind each other: wait until the line is empty
    var flushed = false;
    unawaited(Prefs().getWebViewLastActiveTab().then((_) => flushed = true));
    for (var i = 0; i < 100 && !flushed; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 10));
    }
    expect(flushed, isTrue);
  }

  List<bool> asleep(WebViewProvider web) => [for (final tab in web.tabList) tab.sleepTab];

  List<bool> loadsHidden(WebViewProvider web) => [
    for (final tab in web.tabList) tab.webView is WebViewFull && (tab.webView! as WebViewFull).loadWhenHidden,
  ];

  testWidgets('pauseKind by tab state', (tester) async {
    final web = ColdBrowser([torn, other], active: 0);
    await mount(tester, web);
    await web.restoreBehind();
    expect(NativeChat.pauseKind(web), 'asleep');

    web.wakeTab(0);
    expect(NativeChat.pauseKind(web), 'not_mounted');

    web.activateTab(1);
    expect(NativeChat.pauseKind(web), 'no_tab');
    await end(tester);
  });

  testWidgets('woken Torn tab loads hidden', (tester) async {
    final web = ColdBrowser([other, torn, torn], active: 0);
    await mount(tester, web);

    unawaited(NativeChat.restoreTornBehind(web));
    await secs(tester, 1);

    expect(loadsHidden(web), [false, true, false]);
    await end(tester);
  });

  testWidgets('cold, the active tab is Torn: only that one wakes', (tester) async {
    final web = ColdBrowser([other, torn, other], active: 1);
    await mount(tester, web);

    unawaited(NativeChat.restoreTornBehind(web));
    await secs(tester, 1);

    expect(asleep(web), [true, false, true]);
    expect(web.currentTab, 1);
    expect(web.browserShowInForeground, isFalse);
    expect(NativeChat.tornTabMissing.value, isFalse);
    await end(tester);
  });

  testWidgets('cold, another tab is Torn: it becomes the current one', (tester) async {
    final web = ColdBrowser([other, other, torn], active: 0);
    await mount(tester, web);

    unawaited(NativeChat.restoreTornBehind(web));
    await secs(tester, 1);

    expect(web.currentTab, 2);
    expect(asleep(web), [true, true, false]);
    expect(web.browserShowInForeground, isFalse);
    await end(tester);
  });

  testWidgets('cold, no Torn tab: all stay asleep and the notice comes', (tester) async {
    final web = ColdBrowser([other, other], active: 1);
    await mount(tester, web);

    unawaited(NativeChat.restoreTornBehind(web));
    await secs(tester, 1);

    expect(asleep(web), [true, true]);
    expect(web.currentTab, 1);
    expect(NativeChat.tornTabMissing.value, isTrue);
    await end(tester);
  });

  testWidgets('the notice waits for the restored page, up to the grace', (tester) async {
    NativeChat.setTabGrace(8);
    live = false;
    final web = ColdBrowser([torn]);
    await mount(tester, web);

    unawaited(NativeChat.restoreTornBehind(web));
    await secs(tester, 5);
    expect(NativeChat.tornTabMissing.value, isFalse);

    live = true;
    await secs(tester, 1);
    expect(NativeChat.tornTabMissing.value, isFalse);
    expect(NativeChat.tornTabExists.value, isTrue);
    await end(tester);
  });

  testWidgets('a page that never loads ends in the notice', (tester) async {
    NativeChat.setTabGrace(8);
    live = false;
    final web = ColdBrowser([torn]);
    await mount(tester, web);

    unawaited(NativeChat.restoreTornBehind(web));
    await secs(tester, 5);
    expect(NativeChat.tornTabMissing.value, isFalse);
    await secs(tester, 5);
    expect(NativeChat.tornTabMissing.value, isTrue);
    await end(tester);
  });

  testWidgets('opening a chat window restores once', (tester) async {
    final web = ColdBrowser([other, torn], active: 0);
    await mount(tester, web);

    NativeChat.openQuickWindow('global');
    NativeChat.openQuickWindow('faction');
    await secs(tester, 1);

    expect(web.restoreCalls, 1);
    expect(web.currentTab, 1);
    NativeChat.closeQuickWindow();
    await end(tester);
  });

  testWidgets('a browser that already has tabs is left alone', (tester) async {
    final web = ColdBrowser([torn]);
    await tester.runAsync(() => web.addTab(url: other, tabUid: 'open'));
    await mount(tester, web);

    unawaited(NativeChat.restoreTornBehind(web));
    await secs(tester, 1);

    expect(web.restoreCalls, 0);
    await end(tester);
  });

  testWidgets('Go to Torn tab after a cold restore reuses the restored tab', (tester) async {
    final web = ColdBrowser([other, torn], active: 0);
    await mount(tester, web);

    unawaited(NativeChat.openTornBrowser(keepChat: true));
    await secs(tester, 2);

    expect(web.tabList.length, 2);
    expect(web.currentTab, 1);
    expect(web.tabList[1].sleepTab, isFalse);
    expect(web.browserShowInForeground, isTrue);
    await end(tester);
  });

  testWidgets('a Torn tab restored while waiting is reused, not duplicated', (tester) async {
    final web = ColdBrowser(const [], restores: false);
    await mount(tester, web);

    unawaited(NativeChat.openTornBrowser(keepChat: true));
    await secs(tester, 1);
    await tester.runAsync(() async {
      await web.addTab(url: other, tabUid: 'tab0');
      await web.addTab(url: torn, tabUid: 'tab1', sleepTab: true);
    });
    await secs(tester, 6);

    expect(web.tabList.length, 2);
    expect(web.currentTab, 1);
    expect(web.tabList[1].sleepTab, isFalse);
    await end(tester);
  });

  testWidgets('with no Torn tab, a new one opens in the PDA icon style', (tester) async {
    final web = ColdBrowser([other], active: 0);
    final settings = (await tester.runAsync(() async {
      return SettingsProvider()
        ..fullScreenIncludesPDAButtonTap = true
        ..fullScreenByShortTap = true;
    }))!;
    final key = GlobalKey<NavigatorState>();
    NativeChat.navigatorKey = key;
    addTearDown(() => NativeChat.navigatorKey = null);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<WebViewProvider>.value(value: web),
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        ],
        child: MaterialApp(
          navigatorKey: key,
          navigatorObservers: [BotToastNavigatorObserver()],
          builder: BotToastInit(),
          home: const SizedBox(),
        ),
      ),
    );
    NativeChat.watchTabs(web);

    unawaited(NativeChat.openTornBrowser(keepChat: true));
    await secs(tester, 2);

    expect(web.tabList.length, 2);
    expect(web.currentTab, 1);
    expect(web.currentUiMode, UiMode.fullScreen);
    await end(tester);
  });
}
