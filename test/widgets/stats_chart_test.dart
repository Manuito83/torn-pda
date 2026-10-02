import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:torn_pda/models/profile/external/torn_stats_chart.dart';
import 'package:torn_pda/widgets/profile/stats_chart.dart';

const int _day = 86400;
const int _start = 1700000000;

Datum _datum(int timestamp, int base) => Datum(
      strength: base,
      defense: base ~/ 2,
      speed: base ~/ 3,
      dexterity: base * 2,
      total: base + base ~/ 2 + base ~/ 3 + base * 2,
      timestamp: timestamp,
    );

List<Datum> _dailyRecords(int count, {int from = _start, int step = _day, int base = 1000}) {
  return [
    for (int i = 0; i < count; i++) _datum(from + (i * step), base + (i * 100)),
  ];
}

List<Datum> _recordsWithGap({required int gapDays}) {
  final before = _dailyRecords(40);
  final after = _dailyRecords(
    40,
    from: before.last.timestamp! + (gapDays * _day),
    base: 500000,
  );
  return [...before, ...after];
}

const Set<StatSeries> _allSeries = {
  StatSeries.strength,
  StatSeries.defense,
  StatSeries.speed,
  StatSeries.dexterity,
};

const List<StatSeries> _fixedOrder = [
  StatSeries.strength,
  StatSeries.defense,
  StatSeries.speed,
  StatSeries.dexterity,
];

LineChartData _chartOf(List<Datum> data, {int rangeMonths = 0, Set<StatSeries> visibleStats = _allSeries}) {
  return buildStatsLineChartData(
    allData: data,
    rangeMonths: rangeMonths,
    currentYearColor: Colors.white,
    visibleStats: visibleStats,
  );
}

List<FlSpot> _strengthSpots(LineChartData chart) => chart.lineBarsData.first.spots;

int _valueOf(Datum d, StatSeries stat) => switch (stat) {
      StatSeries.strength => d.strength ?? 0,
      StatSeries.defense => d.defense ?? 0,
      StatSeries.speed => d.speed ?? 0,
      StatSeries.dexterity => d.dexterity ?? 0,
    };

void main() {
  group('stats chart X axis', () {
    test('spots are placed by date, not by record index', () {
      final data = _dailyRecords(10);
      final spots = _strengthSpots(_chartOf(data));

      expect(spots.length, data.length);
      for (int i = 0; i < data.length; i++) {
        expect(spots[i].x, data[i].timestamp! / _day);
      }
    });

    test('uneven spacing is kept on the axis', () {
      final data = [
        _datum(_start, 1000),
        _datum(_start + _day, 2000),
        _datum(_start + (4 * _day), 3000),
      ];
      final spots = _strengthSpots(_chartOf(data));

      expect(spots[1].x - spots[0].x, 1);
      expect(spots[2].x - spots[1].x, 3);
    });
  });

  group('stats chart gaps', () {
    test('a long gap breaks the line', () {
      final data = _recordsWithGap(gapDays: 180);
      final spots = _strengthSpots(_chartOf(data));

      final nullIndexes = [
        for (int i = 0; i < spots.length; i++)
          if (spots[i].isNull()) i,
      ];

      expect(nullIndexes.length, 1);
      expect(spots[nullIndexes.first - 1].x, data[39].timestamp! / _day);
      expect(spots[nullIndexes.first + 1].x, data[40].timestamp! / _day);
    });

    test('daily data is never broken', () {
      final spots = _strengthSpots(_chartOf(_dailyRecords(60)));
      expect(spots.where((s) => s.isNull()), isEmpty);
    });

    test('the break threshold follows the recording cadence', () {
      // Weekly records: a 3 week hole is normal-ish and must not break the line
      final weekly = _dailyRecords(30, step: 7 * _day);
      expect(statsChartGapLimitInDays(weekly.map((e) => e.timestamp! / _day).toList()), 42);

      final daily = _dailyRecords(30);
      expect(statsChartGapLimitInDays(daily.map((e) => e.timestamp! / _day).toList()), 7);
    });

    test('gaps are shaded on the chart', () {
      final chart = _chartOf(_recordsWithGap(gapDays: 180));
      final bands = chart.rangeAnnotations.verticalRangeAnnotations;

      expect(bands.length, 1);
      expect(bands.first.x2 - bands.first.x1, 180);
    });
  });

  group('stats chart tooltip', () {
    test('maps the touched point to its record across a gap', () {
      final data = _recordsWithGap(gapDays: 180);
      final chart = _chartOf(data);
      final bars = chart.lineBarsData;

      // Last spot, so the null spot has already shifted every index by one
      final int spotIndex = bars.first.spots.length - 1;
      final touched = <LineBarSpot>[
        for (int bar = 0; bar < 4; bar++) LineBarSpot(bars[bar], bar, bars[bar].spots[spotIndex]),
      ];

      final items = chart.lineTouchData.touchTooltipData.getTooltipItems(touched);
      final Datum expected = data.last;
      final String expectedDate = DateFormat('d LLL yyyy').format(
        DateTime.fromMillisecondsSinceEpoch(expected.timestamp! * 1000),
      );

      expect(items.length, 4);
      expect(items.first!.text, contains(expectedDate));
      expect(items.first!.text, contains(NumberFormat("###,###", "en_US").format(expected.strength)));
      expect(items.last!.text, contains(NumberFormat("###,###", "en_US").format(expected.total)));
    });
  });

  group('stats chart range', () {
    test('range trims from the newest record, gaps included', () {
      final data = _recordsWithGap(gapDays: 180);
      final spots = _strengthSpots(_chartOf(data, rangeMonths: 3));

      final DateTime newest = DateTime.fromMillisecondsSinceEpoch(data.last.timestamp! * 1000);
      final DateTime cutoff = newest.subtract(const Duration(days: 90));

      for (final spot in spots.where((s) => s.isNotNull())) {
        final DateTime date = DateTime.fromMillisecondsSinceEpoch((spot.x * _day * 1000).round());
        expect(date.isAfter(cutoff), isTrue);
      }
      expect(spots.length, lessThan(data.length));
    });
  });

  group('stats chart tooltip with hidden series', () {
    final data = _dailyRecords(10);

    void expectTooltipWorksFor(Set<StatSeries> visible) {
      final chart = _chartOf(data, visibleStats: visible);
      final bars = chart.lineBarsData;
      expect(bars.length, visible.length);

      final int spotIndex = bars.first.spots.length - 1;
      final touched = <LineBarSpot>[
        for (int bar = 0; bar < bars.length; bar++) LineBarSpot(bars[bar], bar, bars[bar].spots[spotIndex]),
      ];

      final items = chart.lineTouchData.touchTooltipData.getTooltipItems(touched);
      expect(items.length, visible.length);
      expect(items.every((i) => i != null), isTrue);

      final ordered = _fixedOrder.where(visible.contains).toList();
      final Datum expected = data.last;
      final f = NumberFormat("###,###", "en_US");
      final String expectedDate = DateFormat('d LLL yyyy').format(
        DateTime.fromMillisecondsSinceEpoch(expected.timestamp! * 1000),
      );
      final int expectedTotal =
          (expected.strength ?? 0) + (expected.defense ?? 0) + (expected.speed ?? 0) + (expected.dexterity ?? 0);

      expect(items.first!.text, contains(expectedDate));
      expect(items.first!.text, contains(f.format(_valueOf(expected, ordered.first))));
      expect(items.last!.text, contains('TOTAL ${f.format(expectedTotal)}'));
    }

    test('works with all 4 series visible', () {
      expectTooltipWorksFor({StatSeries.strength, StatSeries.defense, StatSeries.speed, StatSeries.dexterity});
    });

    test('works with 3 series visible', () {
      expectTooltipWorksFor({StatSeries.strength, StatSeries.defense, StatSeries.speed});
    });

    test('works with 2 series visible', () {
      expectTooltipWorksFor({StatSeries.strength, StatSeries.dexterity});
    });

    test('works with 1 series visible', () {
      expectTooltipWorksFor({StatSeries.defense});
    });
  });

  group('statSeriesFromHiddenKeys', () {
    test('maps known keys to their StatSeries', () {
      expect(statSeriesFromHiddenKeys(['defense', 'speed']), {StatSeries.defense, StatSeries.speed});
    });

    test('ignores unknown or corrupted keys', () {
      expect(statSeriesFromHiddenKeys(['not_a_stat', 'defense']), {StatSeries.defense});
    });

    test('empty input hides nothing', () {
      expect(statSeriesFromHiddenKeys([]), isEmpty);
    });

    test('three hidden keys are honored, one stat stays visible', () {
      expect(
        statSeriesFromHiddenKeys(['strength', 'defense', 'speed']),
        {StatSeries.strength, StatSeries.defense, StatSeries.speed},
      );
    });

    test('never hides all four, even if prefs say so', () {
      expect(statSeriesFromHiddenKeys(['strength', 'defense', 'speed', 'dexterity']), isEmpty);
    });
  });
}
