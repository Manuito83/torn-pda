import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chat/chat_links.dart';
import 'package:torn_pda/providers/chat/chat_link_info.dart';
import 'package:torn_pda/providers/chat/chat_player_card.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/chat/chat_link_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_link_window.dart';
import 'package:torn_pda/widgets/chat/chat_overlay.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';
import 'package:torn_pda/widgets/webviews/chaining_payload.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';

import 'chat_fakes.dart';

class _FakeWebPlatform extends InAppWebViewPlatform {
  int created = 0;
  int disposed = 0;

  @override
  PlatformInAppWebViewWidget createPlatformInAppWebViewWidget(PlatformInAppWebViewWidgetCreationParams params) {
    created++;
    return _FakeWebView(params, this);
  }
}

class _FakeWebView extends PlatformInAppWebViewWidget {
  _FakeWebView(super.params, this.platform) : super.implementation();

  final _FakeWebPlatform platform;

  @override
  Widget build(BuildContext context) => const ColoredBox(color: Colors.white, child: SizedBox.expand());

  @override
  T controllerFromPlatform<T>(PlatformInAppWebViewController controller) => throw UnimplementedError();

  @override
  void dispose() => platform.disposed++;
}

class _Browser extends WebViewProvider {
  final List<String?> preferred = [];

  @override
  Future openBrowserPreference({
    required BuildContext context,
    required String? url,
    required BrowserTapType browserTapType,
    bool recallLastSession = false,
    bool fromNotification = false,
    bool isChainingBrowser = false,
    ChainingPayload? chainingPayload,
    bool focusedPanel = false,
    bool forceApp = false,
  }) async => preferred.add(url);
}

void main() {
  useTempPathProvider();

  const String link = 'https://www.torn.com/forums.php';
  const String home = 'https://www.torn.com/index.php';
  late _FakeWebPlatform platform;

  setUp(() {
    platform = _FakeWebPlatform();
    InAppWebViewPlatform.instance = platform;
    NativeChat.prefs
      ..inAppEnabled = true
      ..bubbleSpot = ['0.5', '0.5', '0']
      ..windows = []
      ..linkWindow = true
      ..linkNewTab = false;
    NativeChat.keyValid.value = true;
    NativeChat.linkWindow.value = null;
    NativeChat.minimized.value = const [];
    NativeChat.quickWindows.value = const [];
    NativeChat.shownPages.clear();
    NativeChat.screenOpen.value = false;
  });

  tearDown(() => NativeChat.navigatorKey = null);

  Future<void> emptyBrowser() async {
    await Prefs().setWebViewSecondaryTabs('{"tabsSave":[]}');
    await Prefs().setWebViewMainTab('{"tabsSave":[]}');
    await Prefs().setDefaultBrowser('app');
  }

  test('chat links go to one preview window', () async {
    var heard = 0;
    void listener() => heard++;
    NativeChat.linkWindow.addListener(listener);
    addTearDown(() => NativeChat.linkWindow.removeListener(listener));

    await NativeChat.openLink(link);
    await NativeChat.openLink(link);
    expect(heard, 2);
    expect(NativeChat.linkWindow.value?.url, link);
    NativeChat.closeLinkWindow();
    expect(NativeChat.linkWindow.value, isNull);

    NativeChat.prefs.linkWindow = false;
    await NativeChat.openLink(link);
    expect(NativeChat.linkWindow.value, isNull);
  });

  test('open browser reuses a Torn tab', () {
    const urls = ['https://www.google.com', home, null, 'https://torn.com/forums.php'];
    expect(NativeChat.tornTabIndex(urls, [3, 0, 1, 2, 3]), 3);
    expect(NativeChat.tornTabIndex(urls, [0, 2, 3, 0, 1, 2, 3]), 3);
    expect(NativeChat.tornTabIndex(urls, [9, 0, 1, 2, 3]), 1);
    expect(
      NativeChat.tornTabIndex(['https://nottorn.com', 'https://torn.com.evil.net', 'about:blank'], [0, 1, 2]),
      isNull,
    );
    expect(NativeChat.tornTabIndex(const [], [0]), isNull);
  });

  group('the window', () {
    var backs = 0;

    setUp(() => backs = 0);

    Future<GlobalKey<NavigatorState>> pumpApp(WidgetTester tester, {WebViewProvider? web}) async {
      tester.view.physicalSize = const Size(1290, 2796);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final key = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
            ChangeNotifierProvider.value(value: web ?? WebViewProvider()),
          ],
          child: MaterialApp(
            navigatorKey: key,
            navigatorObservers: [NativeChat.rootWatch],
            builder: (context, child) => Stack(
              children: [
                child!,
                ChatOverlay(navigatorKey: key),
              ],
            ),
            home: PopScope(canPop: false, onPopInvokedWithResult: (didPop, _) => backs++, child: const Scaffold()),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      return key;
    }

    Future<void> open(WidgetTester tester, String url) async {
      await NativeChat.openLink(url);
      await tester.pump();
      await tester.pump();
    }

    testWidgets('one window, reused, closed by its button or by back', (tester) async {
      await pumpApp(tester);
      await open(tester, link);
      expect(find.byType(ChatLinkWindow), findsOneWidget);
      await open(tester, 'https://example.org/page');
      expect(find.byType(InAppWebView), findsOneWidget);
      expect(platform.created - platform.disposed, 1);

      await tester.tap(find.byTooltip('Close'));
      await tester.pump();
      expect(find.byType(ChatLinkWindow), findsNothing);
      expect(platform.disposed, platform.created);

      await open(tester, link);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(NativeChat.linkWindow.value, isNull);
      expect(backs, 0);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(backs, 1);
    });

    testWidgets('the window moves, enlarges and swipes down to close', (tester) async {
      await pumpApp(tester);
      await open(tester, link);
      Rect window() => tester.getRect(find.bySemanticsLabel('Link preview'));
      final before = window();
      expect(before.width, ChatLinkWindow.size.width);

      await tester.drag(find.text('www.torn.com').first, const Offset(-60, 0));
      await tester.pump();
      expect(NativeChat.linkWindow.value, isNotNull);
      expect(window().left, isNot(before.left));

      await tester.tap(find.byTooltip('Enlarge'));
      await tester.pump();
      expect(window().width, greaterThan(ChatLinkWindow.size.width));
      expect(window().top, greaterThan(0));
      await tester.tap(find.byTooltip('Shrink'));
      await tester.pump();
      expect(window().width, ChatLinkWindow.size.width);

      await tester.fling(find.text('www.torn.com').first, const Offset(0, 250), 1500);
      await tester.pump();
      expect(NativeChat.linkWindow.value, isNull);
    });

    testWidgets('browser closes the window', (tester) async {
      final web = _Browser();
      await tester.runAsync(() async {
        await emptyBrowser();
        await web.addTab(url: home, tabUid: 'main');
      });
      final key = await pumpApp(tester, web: web);

      for (final button in ['Main tab', 'New tab']) {
        key.currentState!.push(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('conversation'))));
        await tester.pumpAndSettle();
        NativeChat.screenOpen.value = true;
        NativeChat.shownPages
          ..clear()
          ..add(() => const ChatMinimized('dm:7', offset: 120, frozenAtId: 'm1'));
        await open(tester, link);

        await tester.runAsync(() async {
          await tester.tap(find.text(button));
          await Future<void>.delayed(const Duration(milliseconds: 300));
        });
        await tester.pumpAndSettle();

        final kept = NativeChat.minimized.value.single;
        expect((kept.roomId, kept.window, kept.offset, kept.frozenAtId), ('dm:7', false, 120.0, 'm1'));
        expect(NativeChat.linkWindow.value, isNull);
        expect(find.text('conversation'), findsNothing);
      }
      expect(web.preferred, [link]);
      expect(web.tabList.map((t) => t.currentUrl), [home, link]);
      expect(web.currentTab, 1);
    });

    testWidgets('new tab waits for tab restore', (tester) async {
      final web = WebViewProvider();
      var restoring = false;
      web.addListener(() {
        if (!web.browserShowInForeground || restoring) return;
        restoring = true;
        web.addTab(url: home, tabUid: 'main');
        Future<void>.delayed(const Duration(seconds: 1), () async {
          await web.addTab(url: 'https://www.torn.com/gym.php', tabUid: 'saved');
          web.activateTab(0);
        });
      });
      await tester.runAsync(emptyBrowser);
      await pumpApp(tester, web: web);
      NativeChat.screenOpen.value = true;
      await open(tester, link);
      expect(web.tabList, isEmpty);

      await tester.runAsync(() async {
        await tester.tap(find.text('New tab'));
        await Future<void>.delayed(const Duration(seconds: 4));
      });
      await tester.pumpAndSettle();
      expect(web.tabList.map((t) => t.currentUrl), [home, 'https://www.torn.com/gym.php', link]);
      expect(web.currentTab, 2);
      expect(NativeChat.minimized.value, isEmpty);
    });
  });

  group('link taps', () {
    final copied = <String>[];

    setUp(() {
      Get.reset();
      ChatLinkPreviews.resetForTests();
      ChatPlayerCards.resetForTests();
      ChatPlayerCards.fetch = (id) async => {
        'profile': {
          'status': {'state': 'Okay'},
        },
      };
      copied.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') copied.add((call.arguments as Map)['text'] as String);
          return null;
        },
      );
    });

    tearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    Widget host(Widget child) => MaterialApp(
      builder: BotToastInit(),
      navigatorObservers: [BotToastNavigatorObserver()],
      home: Scaffold(body: child),
    );

    testWidgets('a profile link opens the player sheet', (tester) async {
      for (final url in ['https://www.torn.com/profiles.php?XID=42', 'https://torn.com/profiles.php?XID=42']) {
        final profile = ChatLink.parse(url)!;
        await tester.pumpWidget(
          host(
            Builder(
              builder: (context) =>
                  TextButton(onPressed: () => openChatLink(context, profile), child: const Text('go')),
            ),
          ),
        );
        await tester.tap(find.text('go'));
        await tester.pumpAndSettle();
        expect(find.byType(BottomSheet), findsOneWidget);
        expect(NativeChat.linkWindow.value, isNull);
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('link long press menu', (tester) async {
      var message = 0;
      await tester.pumpWidget(
        host(
          GestureDetector(
            onLongPress: () => message++,
            child: const ChatMessageText(content: 'x https://www.torn.com/forums.php?a=12345 y', color: Colors.black),
          ),
        ),
      );
      final text = find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains('forums.php'));
      await tester.longPress(text.first);
      await tester.pumpAndSettle();
      expect(message, 0);
      await tester.tap(find.text('Copy link'));
      await tester.pumpAndSettle();
      expect(copied, ['https://www.torn.com/forums.php?a=12345']);

      await tester.pumpWidget(host(ChatLinkCard(link: ChatLink.parse('https://example.org/x')!, color: Colors.black)));
      await tester.longPress(find.byType(ChatLinkCard));
      await tester.pumpAndSettle();
      expect(find.text('Open in external browser'), findsOneWidget);
      expect(NativeChat.linkWindow.value, isNull);
    });
  });

  group('split screen', () {
    late SettingsProvider settings;

    setUp(() async {
      await Prefs().setWebViewSecondaryTabs('{"tabsSave":[]}');
      await Prefs().setWebViewMainTab('{"tabsSave":[]}');
      await Prefs().setSplitBrowsersLayout('');
      await Prefs().setWebViewLastActiveTab(0);
    });

    int at(WebViewProvider p, String uid) => p.tabList.indexWhere((t) => t.id == uid);

    Future<WebViewProvider> build(SplitAppLinkTarget target) async {
      final provider = WebViewProvider()..splitScreenPosition = WebViewSplitPosition.left;
      for (var i = 0; i < 4; i++) {
        await provider.addTab(url: 'https://www.torn.com/page$i.php', tabUid: 'tab$i');
      }
      provider.updateSplitScreenWidth(1000);
      settings = SettingsProvider()..splitAppLinkTarget = target;
      return provider;
    }

    Future<bool> tap(WebViewProvider p) async {
      final opened = await p.openLinkBesideApp(
        url: link,
        tapType: BrowserTapType.short,
        settings: settings,
        focusedPanel: true,
      );
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      return opened;
    }

    test('new tab beside the app', () async {
      var p = await build(SplitAppLinkTarget.appSideNewTab);
      final before = [p.splitLeftSlot, p.splitRightSlot];
      expect(await tap(p), isTrue);
      expect([p.splitLeftSlot, p.splitRightSlot], before);
      expect(p.splitApartOpen, isFalse);
      expect(p.tabList.length, 5);
      expect(p.currentTab, 4);
      expect(p.tabList.last.splitApart, isFalse);

      p = await build(SplitAppLinkTarget.appSideNewTab);
      p.moveTabToOtherGroup(2);
      expect(await tap(p), isTrue);
      expect(p.tabList.length, 5);
      expect(p.currentTab, 4);
      expect(p.tabList.last.splitApart, isTrue);
      expect([p.splitLeftSlot, p.splitRightSlot], [SplitSlotContent.mainBrowser, SplitSlotContent.apartBrowser]);
    });

    test('link loads in focused tab', () async {
      var p = await build(SplitAppLinkTarget.appSideTab);
      p.moveTabToOtherGroup(2);
      p.activateTab(at(p, 'tab1'));
      expect(p.exitBrowserSlotToApp(p.slotOfGroup(SplitGroup.apart)), isTrue);
      final before = [p.splitLeftSlot, p.splitRightSlot];
      expect(await tap(p), isTrue);
      expect([p.splitLeftSlot, p.splitRightSlot], before);
      expect(p.tabList[p.currentTab].id, 'tab1');
      expect(p.tabList[at(p, 'tab1')].currentUrl, link);
      expect(p.tabList[at(p, 'tab2')].currentUrl, isNot(link));

      p = await build(SplitAppLinkTarget.appSideTab);
      p.moveTabToOtherGroup(2);
      expect(p.splitBrowsersActive, isTrue);
      expect(p.tabList[p.currentTab].id, 'tab2');
      expect(await tap(p), isTrue);
      expect([p.splitLeftSlot, p.splitRightSlot], [SplitSlotContent.mainBrowser, SplitSlotContent.apartBrowser]);
      expect(p.tabList[at(p, 'tab2')].currentUrl, link);
      expect(p.tabList[at(p, 'tab0')].currentUrl, isNot(link));
      expect(p.tabList[p.currentTab].id, 'tab2');

      p = await build(SplitAppLinkTarget.browserTab);
      p.moveTabToOtherGroup(2);
      p.updateSplitScreenWidth(700);
      expect(await tap(p), isFalse);
      expect(p.tabList.every((t) => t.currentUrl != link), isTrue);
    });
  });
}
