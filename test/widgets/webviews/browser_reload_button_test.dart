import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/widgets/webviews/browser_reload_button.dart';

void main() {
  Widget buildButton({required bool isReloading, required VoidCallback onPressed}) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: BrowserReloadButton(isReloading: isReloading, color: Colors.white, onPressed: onPressed),
        ),
      ),
    );
  }

  testWidgets('provides a 48px tap target and reload tooltip', (tester) async {
    var presses = 0;
    await tester.pumpWidget(buildButton(isReloading: false, onPressed: () => presses++));

    expect(tester.getSize(find.byType(IconButton)), const Size(48, 48));
    expect(find.byTooltip('Reload page'), findsOneWidget);

    await tester.tap(find.byType(IconButton));
    expect(presses, 1);
  });

  testWidgets('shows progress while busy but still accepts taps', (tester) async {
    var presses = 0;
    await tester.pumpWidget(buildButton(isReloading: true, onPressed: () => presses++));
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.byKey(const ValueKey('browser-reload-progress')), findsOneWidget);
    expect(find.byTooltip('Reloading page'), findsOneWidget);

    // A stuck page is exactly when users tap again, so the button must not lock them out
    await tester.tap(find.byType(IconButton));
    expect(presses, 1);
  });
}
