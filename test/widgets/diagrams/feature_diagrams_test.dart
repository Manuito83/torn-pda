import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/pages/settings/split_links_examples_page.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/diagrams/feature_diagrams.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('feature_diagrams_test');
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

  Future<ThemeProvider> themeFor(WidgetTester tester, AppTheme kind) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    return (await tester.runAsync(() async {
      // Restore calls Firebase Analytics
      final theme = runZonedGuarded(ThemeProvider.new, (_, _) {})!;
      await Future<void>.delayed(const Duration(milliseconds: 50));
      theme.changeTheme = kind;
      return theme;
    }))!;
  }

  Future<void> playCycle(WidgetTester tester) async {
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);
    }
  }

  for (final kind in AppTheme.values) {
    testWidgets('every scene plays a full cycle at 320 wide (${kind.name})', (tester) async {
      final theme = await themeFor(tester, kind);
      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeProvider>.value(
          value: theme,
          child: MaterialApp(
            home: Scaffold(
              body: ListView(
                children: [
                  for (final scene in FeatureDiagramScene.values) FeatureDiagram(scenes: [scene]),
                  const FeatureDiagram(scenes: FeatureDiagramScene.values),
                ],
              ),
            ),
          ),
        ),
      );
      await playCycle(tester);
      expect(find.byType(FeatureDiagram), findsWidgets);
      expect(tester.getSize(find.byType(FeatureDiagram).first).width, 320);
    });
  }

  testWidgets('several scenes take turns with their caption', (tester) async {
    final theme = await themeFor(tester, AppTheme.light);
    await tester.pumpWidget(
      ChangeNotifierProvider<ThemeProvider>.value(
        value: theme,
        child: const MaterialApp(
          home: Scaffold(body: FeatureDiagram(scenes: [FeatureDiagramScene.linkCurrentTab, FeatureDiagramScene.linkNewTab])),
        ),
      ),
    );
    expect(find.text(featureDiagramCaptions[FeatureDiagramScene.linkCurrentTab]!), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 5300));
    await tester.pump();
    expect(find.text(featureDiagramCaptions[FeatureDiagramScene.linkNewTab]!), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 5300));
    await tester.pump();
    expect(find.text(featureDiagramCaptions[FeatureDiagramScene.linkCurrentTab]!), findsOneWidget);
  });

  for (final kind in [AppTheme.light, AppTheme.dark]) {
    testWidgets('examples page builds at 320 wide and marks the current option (${kind.name})', (tester) async {
      final theme = await themeFor(tester, kind);
      final (webView, settings) = (await tester.runAsync(() async {
        await Prefs().setWebViewSecondaryTabs('{"tabsSave":[]}');
        await Prefs().setWebViewMainTab('{"tabsSave":[]}');
        await Prefs().setSplitBrowsersLayout('');
        final settings = SettingsProvider()..splitAppLinkTarget = SplitAppLinkTarget.appSideTab;
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return (WebViewProvider(), settings);
      }))!;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeProvider>.value(value: theme),
            ChangeNotifierProvider<SettingsProvider>.value(value: settings),
            ChangeNotifierProvider<WebViewProvider>.value(value: webView),
          ],
          child: const MaterialApp(home: SplitLinksExamplesPage()),
        ),
      );
      await playCycle(tester);

      expect(find.byType(FeatureDiagram), findsWidgets);
      await tester.drag(find.byType(ListView), const Offset(0, -350));
      await tester.pump();
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      final checkRow = find.ancestor(of: find.byIcon(Icons.check_circle), matching: find.byType(Row));
      expect(find.descendant(of: checkRow.first, matching: find.text("Tab behind app")), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -3000));
      await tester.pump();
      expect(find.textContaining("works like New tab, app side"), findsOneWidget);
      await playCycle(tester);
    });
  }
}
