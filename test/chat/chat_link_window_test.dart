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
import 'package:torn_pda/widgets/chat/chat_link_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_link_window.dart';
import 'package:torn_pda/widgets/chat/chat_overlay.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

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
  });

  group('link taps', () {
    setUp(() {
      Get.reset();
      ChatLinkPreviews.resetForTests();
      ChatPlayerCards.resetForTests();
      ChatPlayerCards.fetch = (id) async => {
        'profile': {
          'status': {'state': 'Okay'},
        },
      };
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async => null,
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
  });
}
