import 'dart:async';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/pip/pip_player.dart';
import 'package:torn_pda/providers/api/api_caller.dart';
import 'package:torn_pda/providers/api/api_utils.dart';
import 'package:torn_pda/providers/chain_status_controller.dart';
import 'package:torn_pda/providers/pip_controller.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/widgets/chaining/chain_widget.dart';
import 'package:torn_pda/widgets/pip/pip_player_picker.dart';
import 'package:torn_pda/widgets/pip/pip_view.dart';
import 'package:torn_pda/widgets/webviews/chaining_payload.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';

import '../providers/pip_controller_test.dart' show FakeApiCaller, FakeSettings, chainJson, fromNative, pipChannel;

class PanicChain extends ChainStatusController {
  var panicLaunched = false;

  @override
  Future<void> launchPanicAttack() async => panicLaunched = true;
}

class RecordingWebView extends WebViewProvider {
  final urls = <String?>[];

  @override
  Future openBrowserPreference({
    required BuildContext context,
    required String? url,
    required BrowserTapType browserTapType,
    bool recallLastSession = false,
    bool fromNotification = false,
    final bool isChainingBrowser = false,
    final ChainingPayload? chainingPayload,
    bool focusedPanel = false,
    bool forceApp = false,
  }) async {
    urls.add(url);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathChannel = MethodChannel('plugins.flutter.io/path_provider');

  late Directory tempDir;
  late FakeApiCaller api;
  late ChainStatusController chain;
  late PipController pip;
  late FakeSettings settings;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('pip_view_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      pathChannel,
      (call) async => tempDir.path,
    );
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(pathChannel, null);
    tempDir.deleteSync(recursive: true);
  });

  setUp(() {
    Get.reset();
    api = Get.put<ApiCallerController>(FakeApiCaller()) as FakeApiCaller;
    api.handler = (selection, _) async =>
        selection == ApiSelection_v1.chainStatus ? chainJson(current: 5, timeout: 200) : ApiError();
    chain = Get.put(ChainStatusController());
    pip = Get.put(PipController());
    pip.supported = true;
    settings = FakeSettings();
  });

  tearDown(Get.reset);

  // Stops every timer before the end
  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    chain.onClose();
    pip.onClose();
  }

  group('selection mode', () {
    const checked = Icons.check_box;
    late PipSelection selection;
    late List<String> cardTaps;
    late int pageBuilds;

    Future<void> pumpList(WidgetTester tester) async {
      selection = PipSelection();
      cardTaps = [];
      pageBuilds = 0;
      await tester.pumpWidget(
        MaterialApp(
          builder: BotToastInit(),
          navigatorObservers: [BotToastNavigatorObserver()],
          home: Scaffold(
            appBar: PipSelectionAppBar(
              selection: selection,
              appBar: () => AppBar(title: const Text('Targets')),
            ),
            body: PipSelectionScope(
              selection: selection,
              child: Builder(
                builder: (context) {
                  pageBuilds++;
                  return ListView(
                    children: [
                      for (var i = 1; i <= 6; i++)
                        PipSelectable(
                          id: i,
                          name: 'Player $i',
                          child: Card(
                            child: ListTile(title: Text('Player $i'), onTap: () => cardTaps.add('Player $i')),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
    }

    Future<void> tapCard(WidgetTester tester, String name) async {
      await tester.tap(find.text(name));
      await tester.pump();
    }

    Future<void> clearToasts(WidgetTester tester) async {
      BotToast.cleanAll();
      await tester.pump(const Duration(seconds: 3));
    }

    testWidgets('the cards keep their state when the mode changes', (tester) async {
      await pumpList(tester);
      final before = tester.element(find.byType(ListTile).first);
      selection.start(empty: false);
      await tester.pump();
      expect(tester.element(find.byType(ListTile).first), same(before));
      selection.cancel();
      await tester.pump();
      expect(tester.element(find.byType(ListTile).first), same(before));
    });

    testWidgets('tapping a card marks it and tapping again unmarks it', (tester) async {
      await pumpList(tester);
      selection.start(empty: false);
      await tester.pump();
      await tapCard(tester, 'Player 3');
      expect(find.byIcon(checked), findsOneWidget);
      expect(find.text('1 selected'), findsOneWidget);
      expect(find.text('Watch 1 player'), findsOneWidget);
      await tapCard(tester, 'Player 3');
      expect(find.byIcon(checked), findsNothing);
      expect(cardTaps, isEmpty);
      expect(pageBuilds, 1);
    });

    testWidgets('a fifth player is not marked and a toast says why', (tester) async {
      await pumpList(tester);
      selection.start(empty: false);
      await tester.pump();
      for (var i = 1; i <= 5; i++) {
        await tapCard(tester, 'Player $i');
      }
      expect(find.byIcon(checked), findsNWidgets(4));
      expect(selection.isPicked(5), isFalse);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Up to 4 players'), findsOneWidget);
      expect(find.text('Watch 4 players'), findsOneWidget);
      await clearToasts(tester);
    });

    testWidgets('back leaves the mode without watching', (tester) async {
      await pumpList(tester);
      selection.start(empty: false);
      await tester.pump();
      await tapCard(tester, 'Player 1');
      expect(pip.cancelPick(), isTrue);
      await tester.pump();
      expect(selection.active, isFalse);
      expect(find.byIcon(checked), findsNothing);
      expect(pip.cancelPick(), isFalse);
      expect(pip.players, isEmpty);
    });

    testWidgets('Watch opens the window with the marked players in order', (tester) async {
      await pumpList(tester);
      selection.start(empty: false);
      await tester.pump();
      await tapCard(tester, 'Player 3');
      await tapCard(tester, 'Player 1');
      await tester.tap(find.text('Watch 2 players'));
      await tester.pump();
      expect(selection.active, isFalse);
      expect(find.byIcon(checked), findsNothing);
      expect(pip.mode, PipMode.player);
      expect(pip.players.map((p) => p.id), [3, 1]);
      expect(pip.players.map((p) => p.name), ['Player 3', 'Player 1']);
      await finish(tester);
    });
  });

  group('chain widget button', () {
    Future<void> pumpChain(WidgetTester tester, {bool dark = true, bool hidden = false, GlobalKey? outer}) async {
      final theme = (await tester.runAsync(() async {
        // Restore calls Firebase Analytics
        final theme = runZonedGuarded(ThemeProvider.new, (_, _) {})!;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return theme;
      }))!;
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeProvider>.value(value: theme),
            ChangeNotifierProvider<SettingsProvider>.value(value: settings),
          ],
          child: MaterialApp(
            home: ShowCaseWidget(
              builder: (_) => Scaffold(
                body: Column(
                  children: [
                    if (outer != null) Showcase(key: outer, description: 'Page tutorial', child: const Text('Page')),
                    Expanded(
                      child: IndexedStack(
                        index: hidden ? 1 : 0,
                        children: [
                          ChainWidget(key: GlobalKey(), alwaysDarkBackground: dark),
                          const SizedBox(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    testWidgets('tutorial the first time in Chaining', (tester) async {
      await pumpChain(tester, dark: false);
      expect(find.text('Floating window'), findsNothing);
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Floating window'), findsOneWidget);
      expect(settings.showCases, ['pip_chain']);
      await finish(tester);
    });

    testWidgets('no tutorial from a hidden Chaining tab', (tester) async {
      await pumpChain(tester, dark: false, hidden: true);
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Floating window'), findsNothing);
      expect(settings.showCases, isEmpty);
      await finish(tester);
    });

    testWidgets('waits while the page tutorial is on', (tester) async {
      final outer = GlobalKey();
      await pumpChain(tester, dark: false, outer: outer);
      tester.state<ShowCaseWidgetState>(find.byType(ShowCaseWidget).first).startShowCase([outer]);
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Page tutorial'), findsOneWidget);
      expect(find.text('Floating window'), findsNothing);
      expect(settings.showCases, isEmpty);

      tester.state<ShowCaseWidgetState>(find.byType(ShowCaseWidget).first).dismiss();
      chain.update();
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Floating window'), findsOneWidget);
      expect(settings.showCases, ['pip_chain']);
      await finish(tester);
    });
  });

  group('floating window', () {
    Future<void> pumpView(WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: PipView()));
    }

    testWidgets('stakeouts alert, then back to waiting with the last one', (tester) async {
      pip.mode = PipMode.stakeouts;
      pip.stakeoutPlayers = 1;
      pip.inPip.value = true;
      await pumpView(tester);
      expect(find.text('1 player'), findsOneWidget);

      pip.stakeoutAlert(id: 4, name: 'Test', lines: ['Test is now OK!']);
      await tester.pump();
      expect(find.text('Test'), findsOneWidget);
      expect(find.text('Is now OK!'), findsOneWidget);
      expect(find.text('Stakeout, just now'), findsOneWidget);
      final background = tester.widget<Container>(
        find.ancestor(of: find.text('Test'), matching: find.byType(Container)).first,
      );
      expect([Colors.green[700], Colors.black], contains(background.color));

      pip.stakeoutChangedAt = DateTime.now().subtract(const Duration(seconds: 31));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('STAKEOUTS'), findsOneWidget);
      expect(find.text('Last: Test is now OK!'), findsOneWidget);
      expect(find.text('just now'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('several stakeout alerts show the last one and how many', (tester) async {
      pip.mode = PipMode.stakeouts;
      pip.inPip.value = true;
      await pumpView(tester);
      pip.stakeoutAlert(id: 4, name: 'A', lines: ['A is online!']);
      pip.stakeoutAlert(id: 5, name: 'B', lines: ['B has landed!']);
      await tester.pump();
      expect(find.text('B'), findsOneWidget);
      expect(find.text('Has landed!'), findsOneWidget);
      expect(find.text('2 alerts, just now'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('no banner for alerts before the window opened', (tester) async {
      pip.stakeoutAlert(id: 4, name: 'Test', lines: ['Test is now OK!']);
      pip.mode = PipMode.player;
      pip.players = [PipPlayer(id: 1, name: 'Target')];
      pip.inPip.value = true;
      await pumpView(tester);
      expect(find.text('Test is now OK!'), findsNothing);
      await finish(tester);
    });
  });

  testWidgets('the app keeps its full size under the window', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final sizes = <Size>[];
    await tester.pumpWidget(
      MaterialApp(
        home: PipHost(
          child: Builder(
            builder: (context) {
              sizes.add(MediaQuery.sizeOf(context));
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    expect(sizes.last, const Size(1000, 2000));

    pip.inPip.value = true;
    await tester.pump();
    tester.view.physicalSize = const Size(400, 300);
    await tester.pump();
    expect(sizes.last, const Size(1000, 2000));
    expect(find.byType(PipView), findsOneWidget);

    pip.inPip.value = false;
    await tester.pump();
    await tester.pump();
    expect(sizes.last, const Size(400, 300));
    debugDefaultTargetPlatformOverride = null;
    await finish(tester);
  });

  group('window buttons', () {
    late RecordingWebView webView;
    final nativeCalls = <String>[];

    Future<void> pumpApp(WidgetTester tester) async {
      webView = (await tester.runAsync(() async => RecordingWebView()))!;
      await tester.pumpWidget(
        ChangeNotifierProvider<WebViewProvider>.value(
          value: webView,
          child: MaterialApp(navigatorKey: navigatorKey, home: const SizedBox()),
        ),
      );
    }

    setUp(() {
      nativeCalls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(pipChannel, (
        call,
      ) async {
        nativeCalls.add(call.method);
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(pipChannel, null);
    });

    testWidgets('Profile opens the watched player', (tester) async {
      await pumpApp(tester);
      pip.mode = PipMode.player;
      pip.players = [PipPlayer(id: 7, name: 'Seven')];
      pip.stakeoutId = 9;
      await fromNative('action', 'profile');
      expect(webView.urls, ['https://www.torn.com/profiles.php?XID=7']);
      expect(nativeCalls, ['expand']);
      await finish(tester);
    });

    testWidgets('Profile in stakeouts opens the last alert', (tester) async {
      await pumpApp(tester);
      pip.mode = PipMode.stakeouts;
      pip.players = [PipPlayer(id: 7, name: 'Seven')];
      pip.stakeoutId = 9;
      pip.stakeoutChangedAt = DateTime.now();
      await fromNative('action', 'profile');
      expect(webView.urls, ['https://www.torn.com/profiles.php?XID=9']);
      expect(pip.stakeoutHighlighted, isFalse);
      expect(nativeCalls, ['expand']);
      await finish(tester);
    });

    testWidgets('Open PDA only expands', (tester) async {
      await pumpApp(tester);
      await fromNative('action', 'open');
      expect(webView.urls, isEmpty);
      expect(nativeCalls, ['expand']);
      await finish(tester);
    });

    testWidgets('Panic attack goes to the panic attack', (tester) async {
      Get.delete<PipController>(force: true);
      Get.delete<ChainStatusController>(force: true);
      final panicChain = Get.put<ChainStatusController>(PanicChain()) as PanicChain;
      chain = panicChain;
      pip = Get.put(PipController());
      await pumpApp(tester);
      await fromNative('action', 'panic');
      expect(panicChain.panicLaunched, isTrue);
      expect(webView.urls, isEmpty);
      await finish(tester);
    });
  });
}
