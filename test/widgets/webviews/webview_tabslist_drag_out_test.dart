import 'dart:async';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/webviews/circular_menu/circular_menu_tabs.dart';
import 'package:torn_pda/widgets/webviews/webview_tabslist.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const double wide = 1000;
  const double narrow = 700;
  const Duration hold = Duration(milliseconds: 600);

  late Directory tempDir;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('tabs_drag_out_test');
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

  List<String> order(WebViewProvider p) => [for (final t in p.tabList) t.id];

  List<String> apart(WebViewProvider p) => [
    for (final t in p.tabList)
      if (t.splitApart) t.id,
  ];

  // Left half is a drop zone
  Future<WebViewProvider> pumpBar(
    WidgetTester tester, {
    double width = wide,
    bool ownPanelZone = false,
    ValueNotifier<bool>? showBar,
    ValueNotifier<bool>? hideBar,
    int tabs = 4,
    Widget? leading,
  }) async {
    tester.view.physicalSize = const Size(1000, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    late ThemeProvider theme;
    final provider = (await tester.runAsync(() async {
      // Restore calls Firebase Analytics
      theme = runZonedGuarded(ThemeProvider.new, (_, _) {})!;
      await Prefs().setWebViewSecondaryTabs('{"tabsSave":[]}');
      await Prefs().setWebViewMainTab('{"tabsSave":[]}');
      await Prefs().setSplitBrowsersLayout('');
      final provider = WebViewProvider();
      provider.splitScreenPosition = WebViewSplitPosition.left;
      provider.changeUseTabIcons(false);
      for (var i = 0; i < tabs; i++) {
        await provider.addTab(url: 'https://www.torn.com/page$i.php', tabUid: 'tab$i');
      }
      provider.updateSplitScreenWidth(width);
      return provider;
    }))!;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<WebViewProvider>.value(value: provider),
          ChangeNotifierProvider<ThemeProvider>.value(value: theme),
          ChangeNotifierProvider<SettingsProvider>(create: (_) => SettingsProvider()),
        ],
        child: ToastificationWrapper(
          child: MaterialApp(
            builder: BotToastInit(),
            navigatorObservers: [BotToastNavigatorObserver()],
            home: Scaffold(
              body: Stack(
                children: [
                  Column(
                    children: [
                      const Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  ColoredBox(color: Colors.white),
                                  Positioned.fill(child: TabDropZone(label: "Open here")),
                                ],
                              ),
                            ),
                            Expanded(child: SizedBox.expand()),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 50,
                        child: ValueListenableBuilder<bool>(
                          valueListenable: showBar ?? ValueNotifier(true),
                          builder: (_, show, _) => !show
                              ? const SizedBox.shrink()
                              : hideBar == null
                              ? TabsList(leading: leading)
                              : ValueListenableBuilder<bool>(
                                  valueListenable: hideBar,
                                  builder: (_, hidden, child) =>
                                      Visibility(maintainState: true, visible: !hidden, child: child!),
                                  child: TabsList(leading: leading),
                                ),
                        ),
                      ),
                    ],
                  ),
                  // Zone of the bar's own panel
                  if (ownPanelZone) const Positioned.fill(child: TabDropZone(label: "Move here")),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return provider;
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pumpAndSettle();
    // Pending Prefs writes block later tests
    for (var i = 0; i < 30; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump(const Duration(milliseconds: 10));
    }
  }

  Future<void> dragTo(WidgetTester tester, TestGesture gesture, Offset from, Offset to) async {
    const int steps = 8;
    for (var i = 1; i <= steps; i++) {
      await gesture.moveTo(Offset.lerp(from, to, i / steps)!);
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  Future<void> longPressDrag(
    WidgetTester tester,
    String tabUid,
    Offset to, {
    FutureOr<void> Function(TestGesture gesture)? beforeRelease,
  }) async {
    final Offset from = tester.getCenter(find.byKey(ValueKey(tabUid)));
    final gesture = await tester.startGesture(from);
    await tester.pump(hold);
    await dragTo(tester, gesture, from, to);
    await beforeRelease?.call(gesture);
    await gesture.up();
    await settle(tester);
  }

  Rect ghostRect(WidgetTester tester, String key, Rect start) => find
      .byKey(ValueKey(key))
      .evaluate()
      .map((e) => (e.renderObject! as RenderBox).localToGlobal(Offset.zero) & (e.renderObject! as RenderBox).size)
      .firstWhere((r) => r != start);

  testWidgets('the zone label goes to the half of the zone without the finger', (tester) async {
    await pumpBar(tester);
    final Rect zone = tester.getRect(find.byType(TabDropZone));
    final Offset from = tester.getCenter(find.byKey(const ValueKey('tab1')));
    final gesture = await tester.startGesture(from);
    await tester.pump(hold);

    await dragTo(tester, gesture, from, const Offset(250, 450));
    expect(tester.getCenter(find.text('Open here')).dy, lessThan(zone.center.dy));
    await dragTo(tester, gesture, const Offset(250, 450), const Offset(250, 100));
    expect(tester.getCenter(find.text('Open here')).dy, greaterThan(zone.center.dy));

    await dragTo(tester, gesture, const Offset(250, 100), from);
    await gesture.up();
    await settle(tester);
  });

  testWidgets('a tab dropped over the app opens the split panel with it at the end', (tester) async {
    final p = await pumpBar(tester);

    await longPressDrag(
      tester,
      'tab1',
      const Offset(250, 250),
      beforeRelease: (_) => expect(find.text('Open here'), findsOneWidget),
    );

    expect(find.text('Open here'), findsNothing);
    expect(apart(p), ['tab1']);
    expect(order(p), ['tab0', 'tab2', 'tab3', 'tab1']);
    expect(p.splitBrowsersActive, isTrue);
    expect(p.tabList[p.currentTab].id, 'tab1');
  });

  testWidgets('a locked tab dragged to the other panel stays with warnings on', (tester) async {
    final p = await pumpBar(tester);
    p.tabList[1].isLocked = true;

    await longPressDrag(tester, 'tab1', const Offset(250, 250));

    expect(find.text('A locked tab cannot be moved to the other panel!'), findsOneWidget);
    expect(apart(p), isEmpty);
    expect(order(p), ['tab0', 'tab1', 'tab2', 'tab3']);
    expect(p.splitBrowsersActive, isFalse);

    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('a locked tab dragged to the other panel moves with warnings off', (tester) async {
    final p = await pumpBar(tester);
    p.tabList[1].isLocked = true;
    tester.element(find.byType(TabsList)).read<SettingsProvider>().showTabLockWarnings = false;

    await longPressDrag(tester, 'tab1', const Offset(250, 250));

    expect(apart(p), ['tab1']);
    expect(order(p), ['tab0', 'tab2', 'tab3', 'tab1']);
  });

  testWidgets('a tab dropped outside any drop zone stays where it was', (tester) async {
    final p = await pumpBar(tester);

    await longPressDrag(
      tester,
      'tab1',
      const Offset(750, 250),
      beforeRelease: (_) => expect(find.text('Open here'), findsNothing),
    );

    expect(apart(p), isEmpty);
    expect(order(p), ['tab0', 'tab1', 'tab2', 'tab3']);
    expect(p.splitBrowsersActive, isFalse);
  });

  testWidgets('on a narrow screen there is no drop zone and the tab is not moved', (tester) async {
    final p = await pumpBar(tester, width: narrow);

    await longPressDrag(
      tester,
      'tab1',
      tester.getCenter(find.byKey(const ValueKey('tab1'))) - const Offset(0, 300),
      beforeRelease: (_) => expect(find.text('Open here'), findsNothing),
    );

    expect(apart(p), isEmpty);
    expect(order(p), ['tab0', 'tab1', 'tab2', 'tab3']);
  });

  testWidgets('with split screen off in Settings there is no drop zone', (tester) async {
    final p = await pumpBar(tester);
    p.splitScreenPosition = WebViewSplitPosition.off;
    await tester.pump();

    await longPressDrag(
      tester,
      'tab1',
      tester.getCenter(find.byKey(const ValueKey('tab1'))) - const Offset(0, 300),
      beforeRelease: (_) => expect(find.text('Open here'), findsNothing),
    );

    expect(apart(p), isEmpty);
    expect(order(p), ['tab0', 'tab1', 'tab2', 'tab3']);
  });

  testWidgets('reordering inside the bar still works', (tester) async {
    final p = await pumpBar(tester);
    final Offset last = tester.getCenter(find.byKey(const ValueKey('tab3')));

    await longPressDrag(tester, 'tab1', last + const Offset(20, 0));

    expect(apart(p), isEmpty);
    expect(order(p), ['tab0', 'tab2', 'tab3', 'tab1']);
  });

  testWidgets('a reorder with the finger drifting a little above the bar still reorders', (tester) async {
    final p = await pumpBar(tester);
    final Offset last = tester.getCenter(find.byKey(const ValueKey('tab3')));

    await longPressDrag(tester, 'tab1', Offset(750, last.dy - 60));

    expect(apart(p), isEmpty);
    expect(order(p), ['tab0', 'tab2', 'tab3', 'tab1']);
  });

  testWidgets('the zone of the panel that holds the bar does not count', (tester) async {
    final p = await pumpBar(tester, ownPanelZone: true);

    await longPressDrag(
      tester,
      'tab1',
      const Offset(750, 250),
      beforeRelease: (_) => expect(find.text('Move here'), findsNothing),
    );

    expect(apart(p), isEmpty);
    expect(order(p), ['tab0', 'tab1', 'tab2', 'tab3']);
    expect(p.splitBrowsersActive, isFalse);
  });

  testWidgets('a second finger stops the first one from moving a tab', (tester) async {
    final p = await pumpBar(tester);
    final Offset from = tester.getCenter(find.byKey(const ValueKey('tab1')));
    final first = await tester.startGesture(from);
    await tester.pump(hold);
    await dragTo(tester, first, from, const Offset(250, 250));
    expect(find.text('Open here'), findsOneWidget);

    final second = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('tab2'))));
    await tester.pump();
    expect(find.text('Open here'), findsNothing);
    // Long enough for a second reorder
    await tester.pump(hold);
    await dragTo(tester, first, const Offset(250, 250), const Offset(240, 240));
    expect(find.text('Open here'), findsNothing);
    await first.up();
    await tester.pump();
    await second.up();
    await settle(tester);

    expect(apart(p), isEmpty);
    expect(order(p), ['tab0', 'tab1', 'tab2', 'tab3']);
  });

  testWidgets('narrowing the screen mid-drag hides the drop zone and turns it back into a reorder', (tester) async {
    final p = await pumpBar(tester);

    await longPressDrag(
      tester,
      'tab1',
      const Offset(250, 250),
      beforeRelease: (gesture) async {
        expect(find.text('Open here'), findsOneWidget);
        p.updateSplitScreenWidth(narrow);
        await gesture.moveBy(const Offset(-5, 0));
        await tester.pump();
        expect(find.text('Open here'), findsNothing);
      },
    );

    p.updateSplitScreenWidth(wide);
    expect(apart(p), isEmpty);
    expect(order(p), ['tab0', 'tab2', 'tab3', 'tab1']);
    expect(p.splitBrowsersActive, isFalse);
  });

  testWidgets('narrowing the screen right before the release drops nothing', (tester) async {
    final p = await pumpBar(tester);

    await longPressDrag(tester, 'tab1', const Offset(250, 250), beforeRelease: (_) => p.updateSplitScreenWidth(narrow));

    p.updateSplitScreenWidth(wide);
    expect(apart(p), isEmpty);
    expect(order(p), ['tab0', 'tab1', 'tab2', 'tab3']);
    expect(p.splitBrowsersActive, isFalse);
  });

  testWidgets('a bar removed mid-drag leaves no zone lit and moves nothing', (tester) async {
    final showBar = ValueNotifier(true);
    final p = await pumpBar(tester, showBar: showBar);

    await longPressDrag(
      tester,
      'tab1',
      const Offset(250, 250),
      beforeRelease: (_) async {
        expect(find.text('Open here'), findsOneWidget);
        showBar.value = false;
        await tester.pump();
      },
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Open here'), findsNothing);
    expect(apart(p), isEmpty);
    expect(order(p), ['tab0', 'tab1', 'tab2', 'tab3']);
  });

  testWidgets('turning the screen mid-reorder cancels it without errors', (tester) async {
    final p = await pumpBar(tester, tabs: 20);
    await tester.runAsync(() async {
      for (var i = 0; i < 17; i++) {
        p.moveTabToOtherGroup(3);
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await settle(tester);
    final List<String> before = order(p);
    final Offset last = tester.getCenter(find.byKey(const ValueKey('tab2')));

    // Over the other group's hidden tabs
    await longPressDrag(
      tester,
      'tab1',
      last + const Offset(150, 0),
      beforeRelease: (_) async {
        tester.view.physicalSize = const Size(400, 900);
        p.updateSplitScreenWidth(400);
        await tester.pump();
      },
    );

    expect(tester.takeException(), isNull);
    expect(order(p), before);

    tester.view.physicalSize = const Size(1000, 600);
    p.updateSplitScreenWidth(wide);
    await settle(tester);

    expect(tester.takeException(), isNull);
    expect(order(p), before);
  });

  testWidgets('a bar hidden by a turn mid-reorder leaves no tab floating', (tester) async {
    final hideBar = ValueNotifier(false);
    final p = await pumpBar(tester, hideBar: hideBar);
    final Offset from = tester.getCenter(find.byKey(const ValueKey('tab1')));
    final gesture = await tester.startGesture(from);
    await tester.pump(hold);
    await dragTo(tester, gesture, from, tester.getCenter(find.byKey(const ValueKey('tab3'))));

    hideBar.value = true;
    tester.view.physicalSize = const Size(600, 1000);
    await tester.pump();
    await gesture.up();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byKey(const ValueKey('tab1')), findsNothing);
    expect(tester.takeException(), isNull);

    hideBar.value = false;
    tester.view.physicalSize = const Size(1000, 600);
    await settle(tester);

    expect(order(p), ['tab0', 'tab1', 'tab2', 'tab3']);
  });

  testWidgets('the dragged tab is the one moved even if the tabs change mid-drag', (tester) async {
    final p = await pumpBar(tester);

    await longPressDrag(
      tester,
      'tab2',
      const Offset(250, 250),
      beforeRelease: (_) async {
        p.moveTabToOtherGroup(1);
        await tester.pump();
        // Any list change during a reorder trips the SDK
        expect(tester.takeException(), isFlutterError);
      },
    );

    expect(apart(p), ['tab1', 'tab2']);
    expect(order(p), ['tab0', 'tab3', 'tab1', 'tab2']);
  });

  testWidgets('the pointer up reaches a Listener around the list before the reorder ends', (tester) async {
    final events = <String>[];
    final items = ['a', 'b', 'c'];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: 50,
              child: Listener(
                onPointerUp: (_) => events.add('pointerUp'),
                child: ReorderableListView(
                  scrollDirection: Axis.horizontal,
                  buildDefaultDragHandles: false,
                  onReorderStart: (_) => events.add('start'),
                  onReorderEnd: (_) => events.add('end'),
                  onReorderItem: (from, to) => events.add('item'),
                  children: [
                    for (var i = 0; i < items.length; i++)
                      ReorderableDelayedDragStartListener(
                        key: ValueKey(items[i]),
                        index: i,
                        child: SizedBox(width: 80, child: Text(items[i])),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(tester.getCenter(find.text('a')), kind: PointerDeviceKind.touch);
    await tester.pump(hold);
    for (var i = 0; i < 8; i++) {
      await gesture.moveBy(const Offset(25, -40));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(events, ['start', 'pointerUp', 'end', 'item']);
  });

  group('dragging the main tab', () {
    // Wider than the press area
    final Widget mainTab = Builder(
      builder: (context) => SizedBox(
        key: const ValueKey('main'),
        width: 100,
        height: 40,
        child: CircularMenuTabs(
          webViewProvider: context.read<WebViewProvider>(),
          tabIndex: 0,
          items: const [SizedBox()],
          backgroundWidget: const ColoredBox(color: Colors.red, child: SizedBox(width: 100, height: 40)),
        ),
      ),
    );

    testWidgets('dropped over the app opens a copy there and the main tab stays', (tester) async {
      final p = await pumpBar(tester, leading: mainTab);

      await longPressDrag(
        tester,
        'main',
        const Offset(250, 250),
        beforeRelease: (_) {
          expect(find.text('Copy here'), findsOneWidget);
          expect(find.byKey(const ValueKey('main')), findsNWidgets(2));
        },
      );

      expect(find.text('Copy here'), findsNothing);
      expect(find.byKey(const ValueKey('main')), findsOneWidget);
      expect(p.tabList.length, 5);
      expect(order(p).take(4), ['tab0', 'tab1', 'tab2', 'tab3']);
      expect(p.tabList.last.currentUrl, p.tabList[0].currentUrl);
      expect(p.tabList.last.splitApart, isTrue);
      expect(p.tabList[0].splitApart, isFalse);
      expect(p.splitBrowsersActive, isTrue);
      expect(p.tabList[p.currentTab], p.tabList.last);
    });

    testWidgets('dropped over the other browser adds the copy at the end of its group', (tester) async {
      final p = await pumpBar(tester, leading: mainTab);
      p.moveTabToOtherGroup(2);
      await settle(tester);
      expect(apart(p), ['tab2']);

      await longPressDrag(tester, 'main', const Offset(250, 250));

      expect(p.tabList.length, 5);
      expect(apart(p), ['tab2', p.tabList.last.id]);
      expect(p.tabList.last.currentUrl, p.tabList[0].currentUrl);
      expect(p.tabList[0].id, 'tab0');
    });

    testWidgets('dropped on its own panel or outside any zone does nothing', (tester) async {
      final p = await pumpBar(tester, leading: mainTab, ownPanelZone: true);

      await longPressDrag(
        tester,
        'main',
        const Offset(750, 250),
        beforeRelease: (_) => expect(find.text('Copy here'), findsNothing),
      );

      expect(p.tabList.length, 4);
      expect(apart(p), isEmpty);
      expect(find.byKey(const ValueKey('main')), findsOneWidget);
    });

    testWidgets('the copy is made like a duplicated tab and is awake in the other panel', (tester) async {
      final p = await pumpBar(tester, leading: mainTab);
      p.tabList[0].historyBack = ['https://www.torn.com/back.php'];

      await longPressDrag(tester, 'main', const Offset(250, 250));

      expect(find.text('Added duplicated tab!'), findsOneWidget);
      expect(p.tabList.last.historyBack, ['https://www.torn.com/back.php']);
      expect(p.tabList.last.sleepTab, isFalse);
      expect(p.tabList.last.webView, isNotNull);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('a main tab in chaining mode is not copied', (tester) async {
      final p = await pumpBar(tester, leading: mainTab);
      p.tabList[0].isChainingBrowser = true;

      await longPressDrag(tester, 'main', const Offset(250, 250));

      expect(find.text("Chaining tabs can't be duplicated!"), findsOneWidget);
      expect(p.tabList.length, 4);
      expect(apart(p), isEmpty);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('a second finger stops the main tab from being copied', (tester) async {
      final p = await pumpBar(tester, leading: mainTab);
      final Offset from = tester.getCenter(find.byKey(const ValueKey('main')));
      final first = await tester.startGesture(from);
      await tester.pump(hold);
      await dragTo(tester, first, from, const Offset(250, 250));
      expect(find.text('Copy here'), findsOneWidget);

      final second = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('tab2'))));
      await tester.pump();
      expect(find.text('Copy here'), findsNothing);
      expect(find.byKey(const ValueKey('main')), findsOneWidget);
      await dragTo(tester, first, const Offset(250, 250), const Offset(240, 240));
      await first.up();
      await tester.pump();
      await second.up();
      await settle(tester);

      expect(p.tabList.length, 4);
      expect(apart(p), isEmpty);
    });

    testWidgets('a locked main tab is still copied', (tester) async {
      final p = await pumpBar(tester, leading: mainTab);
      p.tabList[0].isLocked = true;

      await longPressDrag(tester, 'main', const Offset(250, 250));

      expect(p.tabList.length, 5);
      expect(p.tabList.last.splitApart, isTrue);
    });

    testWidgets('its ghost follows the finger like a tab ghost and leaves the label uncovered', (tester) async {
      await pumpBar(tester, leading: mainTab);
      const Offset target = Offset(250, 250);

      for (final key in ['tab1', 'main']) {
        final Rect start = tester.getRect(find.byKey(ValueKey(key)));
        final gesture = await tester.startGesture(start.center);
        await tester.pump(hold);
        await dragTo(tester, gesture, start.center, start.center.translate(30, 0));
        expect(ghostRect(tester, key, start).topLeft, start.topLeft.translate(30, 0), reason: key);

        await dragTo(tester, gesture, start.center.translate(30, 0), target);
        final Rect ghost = ghostRect(tester, key, start);
        expect(ghost.topLeft, start.topLeft + (target - start.center), reason: key);
        expect(ghost.overlaps(tester.getRect(find.text(key == 'main' ? 'Copy here' : 'Open here'))), isFalse);

        await dragTo(tester, gesture, target, start.center);
        await gesture.up();
        await settle(tester);
      }
    });

    testWidgets('released inside the bar, its ghost goes back to it and nothing is copied', (tester) async {
      final p = await pumpBar(tester, leading: mainTab);
      final Rect start = tester.getRect(find.byKey(const ValueKey('main')));
      final gesture = await tester.startGesture(start.center);
      await tester.pump(hold);
      await dragTo(tester, gesture, start.center, start.center.translate(120, 0));
      await gesture.up();

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final double halfway = ghostRect(tester, 'main', start).left;
      expect(halfway, greaterThan(start.left));
      expect(halfway, lessThan(start.left + 120));

      await settle(tester);
      expect(find.byKey(const ValueKey('main')), findsOneWidget);
      expect(p.tabList.length, 4);
    });

    testWidgets('pressed outside the press area of the other tabs it is not dragged', (tester) async {
      final p = await pumpBar(tester, leading: mainTab);
      final Rect main = tester.getRect(find.byKey(const ValueKey('main')));
      final Offset from = main.centerLeft.translate(5, 0);
      final gesture = await tester.startGesture(from);
      await tester.pump(hold);
      await dragTo(tester, gesture, from, const Offset(250, 250));
      expect(find.text('Copy here'), findsNothing);
      expect(find.byKey(const ValueKey('main')), findsOneWidget);
      await gesture.up();
      await settle(tester);

      expect(p.tabList.length, 4);
    });

    testWidgets('on a narrow screen it is not dragged', (tester) async {
      final p = await pumpBar(tester, leading: mainTab, width: narrow);

      await longPressDrag(
        tester,
        'main',
        const Offset(250, 250),
        beforeRelease: (_) => expect(find.byKey(const ValueKey('main')), findsOneWidget),
      );

      expect(p.tabList.length, 4);
      expect(apart(p), isEmpty);
    });

    testWidgets('turning the screen mid-drag drops the ghost and copies nothing', (tester) async {
      final p = await pumpBar(tester, leading: mainTab);
      final gesture = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('main'))));
      await tester.pump(hold);
      await dragTo(tester, gesture, tester.getCenter(find.byKey(const ValueKey('main')).first), const Offset(250, 250));
      expect(find.byKey(const ValueKey('main')), findsNWidgets(2));

      tester.view.physicalSize = const Size(600, 1000);
      await tester.pump();
      await gesture.up();
      await settle(tester);

      expect(find.byKey(const ValueKey('main')), findsOneWidget);
      expect(p.tabList.length, 4);
    });
  });
}
