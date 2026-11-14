import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
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
}
