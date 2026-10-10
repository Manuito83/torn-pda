import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/widgets/webviews/split_divider.dart';
import 'package:torn_pda/widgets/webviews/webview_panels_stack.dart';

class _FakeTab extends StatefulWidget {
  const _FakeTab({super.key});

  @override
  State<_FakeTab> createState() => _FakeTabState();
}

class _FakeTabState extends State<_FakeTab> {
  @override
  Widget build(BuildContext context) => const ColoredBox(color: Colors.white, child: SizedBox.expand());
}

void main() {
  group("splitLeftSlotWidth", () {
    test("splits the width left after the divider", () {
      expect(splitLeftSlotWidth(1632, 0.5), (1632 - kSplitDividerWidth) / 2);
      expect(splitLeftSlotWidth(1632, 0.25), (1632 - kSplitDividerWidth) * 0.25);
    });

    test("never leaves a slot under the minimum width", () {
      expect(splitLeftSlotWidth(1632, 0), kSplitSlotMinWidth);
      expect(splitLeftSlotWidth(1632, 0.05), kSplitSlotMinWidth);
      expect(splitLeftSlotWidth(1632, 1), 1632 - kSplitDividerWidth - kSplitSlotMinWidth);
      expect(splitLeftSlotWidth(800, 0.9), 800 - kSplitDividerWidth - kSplitSlotMinWidth);
    });

    test("halves the width when both minimums do not fit", () {
      final double tight = kSplitSlotMinWidth * 2 + kSplitDividerWidth;
      expect(splitLeftSlotWidth(tight, 0.1), kSplitSlotMinWidth);
      expect(splitLeftSlotWidth(600, 0.1), (600 - kSplitDividerWidth) / 2);
      expect(splitLeftSlotWidth(600, 0.9), (600 - kSplitDividerWidth) / 2);
    });

    test("a slot with a safe area inset keeps the minimum as usable width", () {
      const double inset = 52;
      expect(splitLeftSlotWidth(952, 0, leftInset: inset), kSplitSlotMinWidth + inset);
      expect(splitLeftSlotWidth(952, 1, rightInset: inset), 952 - kSplitDividerWidth - kSplitSlotMinWidth - inset);
      expect(splitLeftSlotWidth(952, 0.5, leftInset: inset), (952 - kSplitDividerWidth) / 2);
    });

    test("without room for both minimums, each slot keeps its inset and halves the rest", () {
      expect(splitLeftSlotWidth(600, 0.1, leftInset: 40), 40 + (600 - kSplitDividerWidth - 40) / 2);
      expect(splitLeftSlotWidth(600, 0.9, rightInset: 40), (600 - kSplitDividerWidth - 40) / 2);
    });

    test("a ratio restored on another width keeps its share", () {
      final double ratio = splitLeftSlotWidth(1632, 0.4) / (1632 - kSplitDividerWidth);
      expect(splitLeftSlotWidth(1200, ratio), closeTo((1200 - kSplitDividerWidth) * 0.4, 0.001));
    });
  });

  group("SplitDivider", () {
    const double width = 1000;
    final double available = width - kSplitDividerWidth;
    final double leftWidth = splitLeftSlotWidth(width, 0.5);
    final Offset dividerCenter = Offset(leftWidth + kSplitDividerWidth / 2, 300);

    Future<List<double>> pumpDivider(WidgetTester tester) async {
      tester.view.physicalSize = const Size(width, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final changes = <double>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Row(
            children: [
              SizedBox(width: leftWidth),
              SplitDivider(width: width, ratio: 0.5, onRatioChanged: changes.add),
              const Expanded(child: SizedBox.expand()),
            ],
          ),
        ),
      );
      return changes;
    }

    testWidgets("a tap or a quick drag does not move it", (tester) async {
      final changes = await pumpDivider(tester);

      await tester.tapAt(dividerCenter);
      await tester.pumpAndSettle();
      await tester.dragFrom(dividerCenter, const Offset(150, 0));
      await tester.pumpAndSettle();

      expect(changes, isEmpty);
    });

    testWidgets("held for less than the threshold, a drag does not move it", (tester) async {
      final changes = await pumpDivider(tester);

      final gesture = await tester.startGesture(dividerCenter);
      await tester.pump(kSplitDividerHoldDuration - const Duration(milliseconds: 100));
      await gesture.moveBy(const Offset(150, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(changes, isEmpty);
    });

    testWidgets("held past the threshold, it follows the drag and reports on release", (tester) async {
      final changes = await pumpDivider(tester);

      final gesture = await tester.startGesture(dividerCenter);
      await tester.pump(kSplitDividerHoldDuration + const Duration(milliseconds: 50));
      await gesture.moveBy(const Offset(50, 0));
      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();
      expect(changes, isEmpty);
      await gesture.up();
      await tester.pumpAndSettle();

      expect(changes, hasLength(1));
      expect(changes.single, closeTo((leftWidth + 100) / available, 0.0001));
    });

    testWidgets("a release beyond the limit stops at the minimum width of the other slot", (tester) async {
      final changes = await pumpDivider(tester);

      final gesture = await tester.startGesture(dividerCenter);
      await tester.pump(kSplitDividerHoldDuration + const Duration(milliseconds: 50));
      await gesture.moveBy(const Offset(400, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(changes.single, closeTo((available - kSplitSlotMinWidth) / available, 0.0001));
    });
  });

  group("WebViewPanelsStack with a divider", () {
    final keys = List.generate(2, (i) => ValueKey("tab$i"));

    Future<void> pumpPanels(WidgetTester tester, {required double ratio, required bool keyboard}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WebViewPanelsStack(
            panelTabs: const [0, 1],
            childPanels: const [0, 1],
            focusedPanel: 1,
            splitRatio: ratio,
            onSplitRatioChanged: (_) {},
            resizeFocusedPanelForKeyboard: keyboard,
            duration: 100,
            errorCallback: () => fail("errorCallback called"),
            children: [for (final key in keys) _FakeTab(key: key)],
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets("panels follow the ratio and keep their State", (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await pumpPanels(tester, ratio: 0.5, keyboard: false);
      final before = [for (final key in keys) tester.state(find.byKey(key))];
      expect(tester.getSize(find.byKey(keys[0])).width, splitLeftSlotWidth(1600, 0.5));

      await pumpPanels(tester, ratio: 0.3, keyboard: false);
      final double left = splitLeftSlotWidth(1600, 0.3);
      expect(tester.getSize(find.byKey(keys[0])).width, left);
      expect(tester.getTopLeft(find.byKey(keys[1])).dx, left + kSplitDividerWidth);
      expect(tester.getSize(find.byKey(keys[1])).width, 1600 - left - kSplitDividerWidth);
      expect(tester.getTopLeft(find.byType(SplitDivider)).dx, left);
      for (var i = 0; i < keys.length; i++) {
        expect(identical(tester.state(find.byKey(keys[i])), before[i]), isTrue, reason: "State $i changed");
      }
    });

    testWidgets("the keyboard only shrinks the focused panel", (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.reset);

      await pumpPanels(tester, ratio: 0.5, keyboard: true);
      expect(tester.getSize(find.byKey(keys[0])).height, 900);
      expect(tester.getSize(find.byKey(keys[1])).height, 600);
      final BuildContext focused = tester.element(find.byKey(keys[1]));
      expect(MediaQuery.viewInsetsOf(focused).bottom, 0);

      await pumpPanels(tester, ratio: 0.5, keyboard: false);
      expect(tester.getSize(find.byKey(keys[1])).height, 900);
    });
  });
}
