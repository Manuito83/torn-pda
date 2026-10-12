import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/main.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/changelog.dart';

class _FakeWebViewProvider extends ChangeNotifier implements WebViewProvider {
  _FakeWebViewProvider(this.splitScreenPosition);

  @override
  WebViewSplitPosition splitScreenPosition;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  const title = 'Browser: added support for two groups of tabs side by side';
  const detailStart = 'On wide screens with split screen enabled in Settings';

  Future<void> pump(WidgetTester tester, double width, WebViewSplitPosition position) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 2400);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
          ChangeNotifierProvider<WebViewProvider>.value(value: _FakeWebViewProvider(position)),
        ],
        child: const MaterialApp(home: Scaffold(body: ChangeLog(autoTriggered: false))),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('item is open without close or info icon on wide and narrow windows', (tester) async {
    await pump(tester, 400, WebViewSplitPosition.off);
    final narrowInfoIcons = find.byIcon(Icons.info_outline).evaluate().length;
    expect(find.text(title), findsOneWidget);
    expect(find.textContaining(detailStart), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNothing);

    await pump(tester, kSplitScreenMinWidth, WebViewSplitPosition.off);
    expect(find.textContaining(detailStart), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNothing);
    expect(find.byIcon(Icons.info_outline).evaluate().length, narrowInfoIcons);
    expect(tester.takeException(), isNull);
  });

  testWidgets('item is open with split screen on', (tester) async {
    await pump(tester, 400, WebViewSplitPosition.right);

    expect(find.textContaining(detailStart), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pinned item does not overflow at 320 wide', (tester) async {
    await pump(tester, 320, WebViewSplitPosition.right);
    expect(tester.takeException(), isNull);

    expect(tester.getRect(find.text(title)).right, lessThanOrEqualTo(320));
    expect(tester.getRect(find.textContaining(detailStart)).right, lessThanOrEqualTo(320));
  });
}
