import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/utils/external/ffscouter_comm.dart';
import 'package:torn_pda/models/chaining/ffscouter/ffscouter_stats_model.dart';
import 'package:torn_pda/utils/number_formatter.dart';

class FFScouterStatsHistoryChart extends StatefulWidget {
  final int playerId;

  const FFScouterStatsHistoryChart({super.key, required this.playerId});

  @override
  State<FFScouterStatsHistoryChart> createState() => _FFScouterStatsHistoryChartState();
}

class _FFScouterStatsHistoryChartState extends State<FFScouterStatsHistoryChart> {
  late final Future<FFScouterStatsHistory?> _history = _fetch();

  Future<FFScouterStatsHistory?> _fetch() async {
    final result = await FFScouterComm.getStatsHistory(
      key: Get.find<UserController>().alternativeFFScouterKey,
      target: widget.playerId,
    );
    return result.success ? result.data : null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FFScouterStatsHistory?>(
      future: _history,
      builder: (context, snapshot) {
        final points = snapshot.data?.points ?? const <FFScouterStatsHistoryPoint>[];
        if (points.length < 2) return const SizedBox.shrink();

        final first = points.first;
        final last = points.last;
        final dateFormat = DateFormat('d MMM yyyy');
        final firstDate = dateFormat.format(DateTime.fromMillisecondsSinceEpoch(first.timestamp * 1000));
        final lastDate = dateFormat.format(DateTime.fromMillisecondsSinceEpoch(last.timestamp * 1000));
        final change = (last.bsEstimate! - first.bsEstimate!) / first.bsEstimate! * 100;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "ESTIMATE HISTORY",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink[700], fontSize: 16),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 6),
              child: Text(
                "${first.bsEstimateHuman ?? formatBigNumbers(first.bsEstimate!)} ($firstDate) to "
                "${last.bsEstimateHuman ?? formatBigNumbers(last.bsEstimate!)} ($lastDate), "
                "${change >= 0 ? "+" : ""}${change.toStringAsFixed(0)}%",
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 14, right: 12),
              child: SizedBox(height: 150, child: LineChart(_chartData(points))),
            ),
          ],
        );
      },
    );
  }

  LineChartData _chartData(List<FFScouterStatsHistoryPoint> points) {
    final spots = points.map((p) => FlSpot(p.timestamp / 86400, p.bsEstimate!.toDouble())).toList();
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final daysSpan = spots.last.x - spots.first.x;

    return LineChartData(
      minY: 0,
      maxY: maxY * 1.1,
      lineBarsData: [
        LineChartBarData(spots: spots, barWidth: 2, color: Colors.pink[400], dotData: const FlDotData(show: false)),
      ],
      gridData: FlGridData(
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) => const FlLine(strokeWidth: 0.2, color: Colors.grey),
      ),
      borderData: FlBorderData(show: false),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          fitInsideHorizontally: true,
          getTooltipColor: (_) => Colors.blueGrey,
          getTooltipItems: (touched) => touched.map((spot) {
            final date = DateTime.fromMillisecondsSinceEpoch((spot.x * 86400000).round());
            return LineTooltipItem(
              "${DateFormat('d MMM yyyy').format(date)}\n${formatBigNumbers(spot.y.round())}",
              const TextStyle(fontSize: 10, color: Colors.white),
            );
          }).toList(),
        ),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 44,
            getTitlesWidget: (value, meta) {
              if (value == 0 || value == meta.max) return const SizedBox.shrink();
              return Text(formatBigNumbers(value.round()), style: const TextStyle(fontSize: 9));
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 22,
            interval: daysSpan > 3 ? daysSpan / 3 : 1,
            getTitlesWidget: (value, meta) {
              if (value == meta.min || value == meta.max) return const SizedBox.shrink();
              final date = DateTime.fromMillisecondsSinceEpoch((value * 86400000).round());
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(DateFormat('d MMM').format(date), style: const TextStyle(fontSize: 9)),
              );
            },
          ),
        ),
      ),
    );
  }
}
