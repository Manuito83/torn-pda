import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/utils/responsive_text.dart';

// Replicates the custom tab name box of the browser tab bar
Widget _tabNameBox(String name, {double minWidth = 30, double maxWidth = 70, bool avoidWordBreak = true}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: Container(
          constraints: BoxConstraints(minWidth: minWidth, maxWidth: maxWidth),
          height: 32,
          child: Align(
            widthFactor: 1,
            child: ResponsiveText(
              text: name,
              maxLines: 3,
              maxFontSize: 11,
              minFontSize: 8,
              textAlign: TextAlign.center,
              avoidWordBreak: avoidWordBreak,
              style: const TextStyle(height: 0.9, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    ),
  );
}

double _fontSize(WidgetTester tester) => tester.widget<Text>(find.byType(Text)).style!.fontSize!;

// The style sets a height factor of 0.9, so each line box measures 0.9 * fontSize
int _lines(WidgetTester tester) => (tester.getSize(find.byType(Text)).height / (_fontSize(tester) * 0.9)).round();

void main() {
  group('ResponsiveText in the tab name box', () {
    testWidgets('a single word is not broken', (tester) async {
      await tester.pumpWidget(_tabNameBox('Targets'));

      expect(_lines(tester), 1);
      expect(_fontSize(tester), lessThanOrEqualTo(11));
      expect(_fontSize(tester), greaterThanOrEqualTo(8));
    });

    testWidgets('several words wrap between them, one per line', (tester) async {
      await tester.pumpWidget(_tabNameBox('Target Board'));

      expect(_lines(tester), 2);
    });

    testWidgets('a word too long even at the minimum size still renders within the box', (tester) async {
      await tester.pumpWidget(_tabNameBox('Supercalifragilistic'));

      expect(_lines(tester), lessThanOrEqualTo(3));
      expect(_fontSize(tester), 8);
      expect(tester.getSize(find.byType(Align)).width, lessThanOrEqualTo(70));
    });

    testWidgets('a short name keeps the narrow box', (tester) async {
      await tester.pumpWidget(_tabNameBox('Gym'));

      expect(_lines(tester), 1);
      expect(tester.getSize(find.byType(Align)).width, greaterThanOrEqualTo(30));
      expect(tester.getSize(find.byType(Align)).width, lessThan(70));
    });

    testWidgets('the previous fixed 30px box did break the word', (tester) async {
      await tester.pumpWidget(_tabNameBox('Targets', minWidth: 30, maxWidth: 30, avoidWordBreak: false));

      expect(_lines(tester), greaterThan(1));
    });
  });
}
