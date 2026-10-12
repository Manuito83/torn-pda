import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/terminal_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/webviews/dev_tools/dev_tools_main.dart';
import 'package:torn_pda/widgets/webviews/dev_tools/dev_tools_network.dart';

class _CountingController extends Fake implements InAppWebViewController {
  int evaluations = 0;

  @override
  Future<dynamic> evaluateJavascript({required String source, ContentWorld? contentWorld}) async {
    evaluations++;
    return null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('dev_tools_split_test');
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

  late WebViewProvider provider;
  late TerminalProvider terminal;

  int at(String uid) => provider.tabList.indexWhere((t) => t.id == uid);

  Key? keyOf(String uid) => provider.tabList[at(uid)].webViewKey;

  // Prefs need real async
  Future<void> act(WidgetTester tester, void Function() change) async {
    await tester.runAsync(() async {
      change();
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pump();
  }

  Future<void> pumpDevTools(WidgetTester tester, Widget devTools) async {
    tester.view.physicalSize = const Size(1000, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    late ThemeProvider theme;
    provider = (await tester.runAsync(() async {
      // Restore calls Firebase Analytics
      theme = runZonedGuarded(ThemeProvider.new, (_, _) {})!;
      await Prefs().setWebViewSecondaryTabs('{"tabsSave":[]}');
      await Prefs().setWebViewMainTab('{"tabsSave":[]}');
      await Prefs().setSplitBrowsersLayout('');
      final provider = WebViewProvider();
      provider.splitScreenPosition = WebViewSplitPosition.right;
      for (var i = 0; i < 4; i++) {
        await provider.addTab(url: 'https://www.torn.com/page$i.php', tabUid: 'tab$i');
      }
      provider.updateSplitScreenWidth(1000);
      return provider;
    }))!;
    terminal = TerminalProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<WebViewProvider>.value(value: provider),
          ChangeNotifierProvider<ThemeProvider>.value(value: theme),
          ChangeNotifierProvider<SettingsProvider>(create: (_) => SettingsProvider()),
          ChangeNotifierProvider<TerminalProvider>.value(value: terminal),
        ],
        child: MaterialApp(home: devTools),
      ),
    );
    await tester.pump();
  }

  testWidgets('in a slot they follow the focused tab and its rebuilt webview', (tester) async {
    await pumpDevTools(tester, const DevToolsMainPage());
    await act(tester, () {
      provider.activateTab(at('tab1'));
      expect(provider.openSplitDevTools('tab1'), isTrue);
      provider.reportTabPageTitle(keyOf('tab1'), 'Faction');
      terminal.addInstruction(keyOf('tab1'), 'from tab1');
      terminal.addInstruction(keyOf('tab2'), 'from tab2');
    });
    expect(find.text('Dev Tools · Faction'), findsOneWidget);
    expect(find.text('from tab1'), findsOneWidget);

    await act(tester, () => provider.activateTab(at('tab2')));
    expect(find.text('from tab2'), findsOneWidget);
    expect(find.text('from tab1'), findsNothing);

    await act(tester, () {
      provider.rebuildUnresponsiveWebView(tabUid: 'tab2', isChainingBrowser: false, chainingPayload: null);
      terminal.addInstruction(keyOf('tab2'), 'after rebuild');
    });
    expect(find.text('after rebuild'), findsOneWidget);
  });

  testWidgets('in a slot the arrow closes them and there is no timer menu', (tester) async {
    await pumpDevTools(tester, const DevToolsMainPage());
    await act(tester, () => provider.openSplitDevTools(provider.tabList[provider.currentTab].id));
    expect(find.byIcon(Icons.timer_outlined), findsNothing);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await act(tester, () {});
    expect(provider.splitDevToolsSlot, isNull);
    expect(provider.splitLeftSlot, SplitSlotContent.app);
  });

  testWidgets('full screen they keep the timer menu and follow their tab after a rebuild', (tester) async {
    await pumpDevTools(tester, const DevToolsMainPage(tabUid: 'tab3'));
    expect(find.byIcon(Icons.timer_outlined), findsOneWidget);

    await act(tester, () {
      provider.rebuildUnresponsiveWebView(tabUid: 'tab3', isChainingBrowser: false, chainingPayload: null);
      terminal.addInstruction(keyOf('tab3'), 'rebuilt tab3');
    });
    expect(find.text('rebuilt tab3'), findsOneWidget);
  });

  testWidgets('in a slot the page tabs start again when the tab navigates', (tester) async {
    await pumpDevTools(tester, const DevToolsMainPage(initialIndex: 1));
    await act(tester, () => provider.openSplitDevTools(provider.tabList[provider.currentTab].id));
    final State first = tester.state(find.byType(DevToolsNetworkTab));

    await act(tester, () => provider.reportTabPageTitle(keyOf('tab0'), 'Other title'));
    expect(tester.state(find.byType(DevToolsNetworkTab)), same(first));

    await act(tester, () => provider.reportTabLoadUrl(keyOf('tab0'), 'https://www.torn.com/other.php'));
    expect(tester.state(find.byType(DevToolsNetworkTab)), isNot(same(first)));
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Network asks the page once and again only on refresh', (tester) async {
    final controller = _CountingController();
    final rebuild = ValueNotifier<int>(0);
    addTearDown(rebuild.dispose);
    await pumpDevTools(
      tester,
      Scaffold(
        body: ValueListenableBuilder<int>(
          valueListenable: rebuild,
          builder: (context, value, _) => DevToolsNetworkTab(webViewController: controller),
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();
    expect(controller.evaluations, 1);

    for (var i = 1; i <= 3; i++) {
      rebuild.value = i;
      await tester.pump();
    }
    expect(controller.evaluations, 1);

    await tester.tap(find.text('Refresh'));
    await tester.pump();
    expect(controller.evaluations, 2);
    await tester.pump(const Duration(seconds: 1));
  });
}
