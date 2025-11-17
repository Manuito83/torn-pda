import 'dart:async';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import 'package:torn_pda/models/profile/external/torn_stats_chart.dart';
import 'package:torn_pda/models/profile/external/torn_stats_chart_update.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/number_formatter.dart';
import 'package:http/http.dart' as http;
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';

enum TornStatsChartType { Line, Pie }

class StatsChart extends StatefulWidget {
  final TornStatsChartType chartType;
  final StatsChartTornStats? statsData;
  final UserController userController;
  final Function callbackStatsUpdate;

  StatsChart({
    super.key,
    required this.chartType,
    required this.statsData,
    required this.userController,
    required this.callbackStatsUpdate,
  });

  @override
  State<StatsChart> createState() => _StatsChartState();
}

class _StatsChartState extends State<StatsChart> {
  bool _statsUpdating = false;

  @override
  Widget build(BuildContext context) {
    final dynamic chartData;
    if (widget.chartType == TornStatsChartType.Line) {
      chartData = _buildLineChartData();
    } else {
      chartData = _buildPieChartData();
    }

    return Column(
      children: [
        _legend(),
        const SizedBox(height: 5),
        Flexible(
          child: widget.chartType == TornStatsChartType.Line
              ? LineChart(chartData as LineChartData)
              : PieChart(chartData as PieChartData),
        ),
      ],
    );
  }

  Row _legend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          child: Row(
            children: [
              Image.asset('images/icons/tornstats_logo.png', width: 12),
              const SizedBox(width: 5),
              const Text('STATS', style: TextStyle(fontSize: 8)),
              const SizedBox(width: 5),
              _statsUpdating
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh, size: 14),
            ],
          ),
          onTap: () async {
            setState(() {
              _statsUpdating = true;
            });

            bool success = false;
            String message = "";
            try {
              final String tornStatsURL =
                  'https://www.tornstats.com/api/v2/${widget.userController.alternativeTornStatsKey}/battlestats/record';
              final resp = await http.get(Uri.parse(tornStatsURL)).timeout(const Duration(seconds: 10));
              if (resp.statusCode == 200) {
                final TornStatsChartUpdate statsJson = tornStatsChartUpdateFromJson(resp.body);
                if (statsJson.status! && statsJson.message != null) {
                  message = statsJson.message!;
                  success = true;
                  widget.callbackStatsUpdate();
                }
              }
            } on TimeoutException {
              message = "Error updating stats: Torn Stats did not respond, it might be unavailable at this time";
            } catch (e) {
              message = "Error updating stats: $e";
            }

            toastification.showCustom(
              autoCloseDuration: null,
              alignment: Alignment.bottomCenter,
              builder: (BuildContext context, ToastificationItem holder) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: success ? Colors.green[600] : Colors.red[600],
                    border: Border.all(
                      color: success ? Colors.green.shade800 : Colors.red.shade800,
                      width: 2,
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset('images/icons/tornstats_logo.png', width: 24),
                      const SizedBox(width: 20),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Stats update report',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              message,
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (success)
                                  TextButton(
                                    onPressed: () {
                                      toastification.dismiss(holder);
                                      const url = 'https://tornstats.com/';
                                      context.read<WebViewProvider>().openBrowserPreference(
                                            context: context,
                                            url: url,
                                            browserTapType: BrowserTapType.short,
                                          );
                                    },
                                    child: const Text(
                                      'Open Torn Stats',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12.0),
                                        side: const BorderSide(color: Colors.white, width: 2.0),
                                      ),
                                    ),
                                  ),
                                if (success)
                                  GestureDetector(
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(text: message));
                                      toastification.dismiss(holder);
                                      toastification.showCustom(
                                        autoCloseDuration: const Duration(seconds: 2),
                                        alignment: Alignment.center,
                                        builder: (BuildContext context, ToastificationItem holder) {
                                          return GestureDetector(
                                            onTap: () {
                                              toastification.dismiss(holder);
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(8),
                                                color: Colors.green[600],
                                                border: Border.all(
                                                  color: Colors.green.shade800,
                                                  width: 2,
                                                ),
                                              ),
                                              padding: const EdgeInsets.all(16),
                                              margin: const EdgeInsets.all(8),
                                              child: const Row(
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.copy),
                                                  SizedBox(width: 20),
                                                  Flexible(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          'Copied to clipboard!',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      );

                                      setState(() {
                                        _statsUpdating = false;
                                      });
                                    },
                                    child: const Icon(Icons.copy, color: Colors.white),
                                  ),
                                GestureDetector(
                                  onTap: () {
                                    toastification.dismiss(holder);
                                  },
                                  child: const Icon(Icons.cancel, color: Colors.white),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );

            setState(() {
              _statsUpdating = false;
            });
          },
        ),
        const SizedBox(width: 30),
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
        ),
        const Text(' STR', style: TextStyle(fontSize: 7)),
        const SizedBox(width: 6),
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
        ),
        const Text(' DEF', style: TextStyle(fontSize: 7)),
        const SizedBox(width: 6),
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.circle,
          ),
        ),
        const Text(' SPD', style: TextStyle(fontSize: 7)),
        const SizedBox(width: 6),
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
        ),
        const Text(' DEX', style: TextStyle(fontSize: 7)),
        const SizedBox(width: 6),
        const Text('', style: TextStyle(fontSize: 8)),
      ],
    );
  }

  LineChartData _buildLineChartData() {
    double maxStat = 0;

    final strengthSpots = <FlSpot>[];
    final speedSpots = <FlSpot>[];
    final defenseSpots = <FlSpot>[];
    final dexteritySpots = <FlSpot>[];
    final timestamps = <int?>[];

    for (int i = 0; i < widget.statsData!.data!.length; i++) {
      strengthSpots.add(FlSpot(i.toDouble(), widget.statsData!.data![i].strength!.toDouble()));
      speedSpots.add(FlSpot(i.toDouble(), widget.statsData!.data![i].speed!.toDouble()));
      defenseSpots.add(FlSpot(i.toDouble(), widget.statsData!.data![i].defense!.toDouble()));
      dexteritySpots.add(FlSpot(i.toDouble(), widget.statsData!.data![i].dexterity!.toDouble()));
      timestamps.add(widget.statsData!.data![i].timestamp);
      final int thisMax = [
        widget.statsData!.data![i].strength ?? 0,
        widget.statsData!.data![i].speed ?? 0,
        widget.statsData!.data![i].defense ?? 0,
        widget.statsData!.data![i].dexterity ?? 0,
      ].fold(0, max);
      if (thisMax > maxStat) {
        maxStat = thisMax.toDouble();
      }
    }

    return LineChartData(
      maxY: maxStat * 1.05,
      lineBarsData: [
        LineChartBarData(
          spots: strengthSpots,
          isCurved: false,
          barWidth: 2,
          color: Colors.blue,
          dotData: const FlDotData(
            show: false,
          ),
        ),
        LineChartBarData(
          spots: speedSpots,
          isCurved: false,
          barWidth: 2,
          color: Colors.orange,
          dotData: const FlDotData(
            show: false,
          ),
        ),
        LineChartBarData(
          spots: defenseSpots,
          isCurved: false,
          barWidth: 2,
          color: Colors.red,
          dotData: const FlDotData(
            show: false,
          ),
        ),
        LineChartBarData(
          spots: dexteritySpots,
          isCurved: false,
          barWidth: 2,
          color: Colors.green,
          dotData: const FlDotData(
            show: false,
          ),
        ),
      ],
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) {
          return const FlLine(
            strokeWidth: 0.2,
            color: Colors.grey,
          );
        },
      ),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          fitInsideHorizontally: true,
          fitInsideVertically: false,
          getTooltipColor: (touchedSpot) => Colors.blueGrey.withAlpha(255),
          getTooltipItems: (value) {
            final tooltips = <LineTooltipItem>[];
            int thisX = value[0].x.toInt();

            final NumberFormat f = NumberFormat("###,###", "en_US");

            // Get time comparing position in x with timestamps
            var ts = 0;
            final timesList = [];
            for (final e in timestamps) {
              timesList.add("$e");
            }
            if (thisX > timesList.length) {
              thisX = timesList.length;
            }
            ts = int.parse(timesList[thisX]);
            final date = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
            final DateFormat formatter = DateFormat('d LLL yyyy');

            // The first line (STR) will be preceded by date
            final String strLine = formatter.format(date);

            // Configure the last line to show totals
            double total = 0;
            for (final stat in value) {
              total += stat.y;
            }
            final String dexLine = "TOTAL ${f.format(total.toInt())}";

            // Values come unsorted, we sort them here to our liking
            tooltips.add(
              LineTooltipItem(
                "$strLine\n\nSTR: ${f.format(widget.statsData!.data![thisX].strength)}",
                const TextStyle(fontSize: 10, color: Colors.white),
              ),
            );
            tooltips.add(
              LineTooltipItem(
                "DEF: ${f.format(widget.statsData!.data![thisX].defense)}",
                const TextStyle(fontSize: 10, color: Colors.white),
              ),
            );
            tooltips.add(
              LineTooltipItem(
                "SPD: ${f.format(widget.statsData!.data![thisX].speed)}",
                const TextStyle(fontSize: 10, color: Colors.white),
              ),
            );
            tooltips.add(
              LineTooltipItem(
                "DEX: ${f.format(widget.statsData!.data![thisX].dexterity)}\n\n$dexLine",
                const TextStyle(fontSize: 10, color: Colors.white),
              ),
            );

            return tooltips;
          },
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (position, meta) {
              if (position == 0) return const SizedBox.shrink();

              final int ts = timestamps[position.toInt()]! * 1000;
              final DateTime dt = DateTime.fromMillisecondsSinceEpoch(ts);
              final DateFormat formatter = DateFormat('d LLL');
              final String date = formatter.format(dt);

              const degrees = -50;
              const radians = degrees * pi / 180;

              return Transform.rotate(
                angle: radians,
                child: SizedBox(
                  width: 60,
                  child: Text(
                    date,
                    style: const TextStyle(fontSize: 9),
                  ),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            reservedSize: 50,
            showTitles: true,
            getTitlesWidget: (position, meta) {
              if (position == 0) return const SizedBox.shrink();
              return Text(
                formatBigNumbers(position.toInt()),
                style: const TextStyle(fontSize: 9),
              );
            },
          ),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
    );
  }

  PieChartData _buildPieChartData() {
    List<PieChartSectionData> sections = [];
    Map<String, double> sums = calculateSumOfStats();
    double totalSum = sums.values.reduce((a, b) => a + b);

    sums.forEach((label, value) {
      double percent = (value / totalSum) * 100;
      sections.add(
        PieChartSectionData(
          color: getColorForLabel(label),
          value: value,
          title: '${percent.toStringAsFixed(0)}%',
          radius: 50,
          titleStyle: const TextStyle(color: Colors.black),
        ),
      );
    });

    return PieChartData(
      sections: sections,
    );
  }

  Map<String, double> calculateSumOfStats() {
    return {
      'Strength': widget.statsData!.data!.last.strength!.toDouble(),
      'Speed': widget.statsData!.data!.last.speed!.toDouble(),
      'Defense': widget.statsData!.data!.last.defense!.toDouble(),
      'Dexterity': widget.statsData!.data!.last.dexterity!.toDouble(),
    };
  }

  Color getColorForLabel(String label) {
    switch (label) {
      case 'Strength':
        return Colors.blue;
      case 'Speed':
        return Colors.orange;
      case 'Defense':
        return Colors.red;
      case 'Dexterity':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
