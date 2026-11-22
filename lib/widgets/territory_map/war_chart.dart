import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';
import 'package:torn_pda/models/chat/chat_faction_ops.dart';
import 'package:torn_pda/models/territory_map/war_file.dart';
import 'package:torn_pda/utils/number_formatter.dart';

const _scoreColor = Colors.red;
const _attackersColor = Colors.orange;
const _defendersColor = Colors.blue;

class WarChart extends StatelessWidget {
  const WarChart({super.key, required this.start, required this.target, required this.samples});

  final DateTime start;
  final int target;

  // Oldest first, live or final point included
  final List<WarSample> samples;

  @override
  Widget build(BuildContext context) {
    double hours(DateTime at) => at.difference(start).inSeconds / 3600;
    final maxWall = max(1, samples.map((s) => max(s.attackers, s.defenders)).reduce(max));
    final wallStep = (maxWall / 4).ceil();
    final scale = target / (wallStep * 4);
    final span = max(1.0, hours(samples.last.at));
    final hourStep = max(1, (span / 4).ceil()).toDouble();

    LineChartBarData walls(int Function(WarSample) count, Color color) => LineChartBarData(
      spots: [for (final s in samples) FlSpot(hours(s.at), count(s) * scale)],
      color: color,
      barWidth: 1,
      isStepLineChart: true,
      lineChartStepData: const LineChartStepData(stepDirection: LineChartStepData.stepDirectionForward),
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.12)),
    );

    final data = LineChartData(
      minX: 0,
      maxX: span,
      minY: 0,
      maxY: target.toDouble(),
      lineBarsData: [
        LineChartBarData(
          spots: [for (final s in samples) FlSpot(hours(s.at), s.score.toDouble())],
          color: _scoreColor,
          barWidth: 2,
          dotData: const FlDotData(show: false),
        ),
        walls((s) => s.attackers, _attackersColor),
        walls((s) => s.defenders, _defendersColor),
      ],
      gridData: FlGridData(
        drawVerticalLine: false,
        horizontalInterval: scale * wallStep,
        getDrawingHorizontalLine: (_) => const FlLine(strokeWidth: 0.2, color: Colors.grey),
      ),
      borderData: FlBorderData(show: false),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          fitInsideHorizontally: true,
          getTooltipColor: (_) => Colors.blueGrey,
          getTooltipItems: (touched) => [
            for (final spot in touched)
              LineTooltipItem(switch (spot.barIndex) {
                0 => '${chatSpan(Duration(seconds: (spot.x * 3600).round()))} in\n${formatBigNumbers(spot.y.round())}',
                1 => '${(spot.y / scale).round()} attacking',
                _ => '${(spot.y / scale).round()} defending',
              }, TextStyle(fontSize: 10, color: spot.bar.color)),
          ],
        ),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: target / 4,
            getTitlesWidget: (value, meta) =>
                Text(formatBigNumbers(value.round()), style: const TextStyle(fontSize: 9, color: _scoreColor)),
          ),
        ),
        rightTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24,
            interval: scale * wallStep,
            getTitlesWidget: (value, meta) => Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text('${(value / scale).round()}', style: const TextStyle(fontSize: 9)),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 20,
            interval: hourStep,
            getTitlesWidget: (value, meta) {
              if (value == meta.max && value % hourStep != 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('${value.round()}h', style: const TextStyle(fontSize: 9)),
              );
            },
          ),
        ),
      ),
    );

    Widget key(String label, Color color) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 3, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10, right: 4),
          child: SizedBox(height: 170, child: LineChart(data)),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 14,
          children: [key('Score', _scoreColor), key('Attackers', _attackersColor), key('Defenders', _defendersColor)],
        ),
      ],
    );
  }
}
