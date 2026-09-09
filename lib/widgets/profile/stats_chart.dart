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
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/number_formatter.dart';
import 'package:http/http.dart' as http;
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';

enum TornStatsChartType { Line, Pie }

enum StatSeries { strength, defense, speed, dexterity }

extension StatSeriesDisplay on StatSeries {
  String get shortLabel => switch (this) {
        StatSeries.strength => 'STR',
        StatSeries.defense => 'DEF',
        StatSeries.speed => 'SPD',
        StatSeries.dexterity => 'DEX',
      };

  String get fullLabel => switch (this) {
        StatSeries.strength => 'Strength',
        StatSeries.defense => 'Defense',
        StatSeries.speed => 'Speed',
        StatSeries.dexterity => 'Dexterity',
      };

  Color get color => switch (this) {
        StatSeries.strength => Colors.blue,
        StatSeries.defense => Colors.red,
        StatSeries.speed => Colors.orange,
        StatSeries.dexterity => Colors.green,
      };
}

const Set<StatSeries> _allStatSeries = {
  StatSeries.strength,
  StatSeries.defense,
  StatSeries.speed,
  StatSeries.dexterity,
};

Set<StatSeries> statSeriesFromHiddenKeys(List<String> hiddenKeys) {
  final hidden = <StatSeries>{};
  for (final key in hiddenKeys) {
    for (final stat in StatSeries.values) {
      if (stat.name == key) hidden.add(stat);
    }
  }
  if (hidden.length >= _allStatSeries.length) return {};
  return hidden;
}

String formatTornStatsErrorMessage(
  String? message, {
  String prefix = '',
}) {
  final normalized = (message ?? '').replaceFirst(RegExp(r'^ERROR:\s*', caseSensitive: false), '').trim();
  final baseMessage = normalized.isEmpty ? 'Unknown error' : normalized;

  final formattedMessage = baseMessage.toLowerCase() == 'user not found.'
      ? 'User not found. Please make sure you are using the same API key in Torn Stats and Torn PDA, '
          'or configure your Torn Stats API key in Torn PDA Settings > Alternative API Keys'
      : baseMessage;

  return prefix.isEmpty ? formattedMessage : '$prefix$formattedMessage';
}

String formatTornStatsHttpError(
  int statusCode, {
  String prefix = '',
}) {
  final message = switch (statusCode) {
    401 ||
    403 =>
      'Torn Stats rejected the request. Please check that your API key is correct in Torn PDA Settings > Alternative API Keys.',
    404 => 'Torn Stats could not find this resource. The service may be temporarily unavailable.',
    429 => 'Torn Stats is receiving too many requests right now. Please try again in a moment.',
    500 || 502 || 503 || 504 => 'Torn Stats had a server problem. Please try again later.',
    _ => 'Request failed with HTTP $statusCode.',
  };

  return prefix.isEmpty ? message : '$prefix$message';
}

class StatsChart extends StatefulWidget {
  final TornStatsChartType chartType;
  final StatsChartTornStats? statsData;
  final UserController userController;
  final Function callbackStatsUpdate;
  final bool isCachedData;

  StatsChart({
    super.key,
    required this.chartType,
    required this.statsData,
    required this.userController,
    required this.callbackStatsUpdate,
    this.isCachedData = false,
  });

  @override
  State<StatsChart> createState() => _StatsChartState();
}

class _StatsChartState extends State<StatsChart> {
  bool _statsUpdating = false;

  void _toggleStat(SettingsProvider settingsProvider, StatSeries stat) {
    final hidden = statSeriesFromHiddenKeys(settingsProvider.tornStatsChartHiddenStats);
    if (hidden.contains(stat)) {
      hidden.remove(stat);
    } else if (hidden.length < _allStatSeries.length - 1) {
      hidden.add(stat);
    } else {
      return;
    }
    settingsProvider.setTornStatsChartHiddenStats = hidden.map((e) => e.name).toList();
  }

  Future<void> _showLegendDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Consumer<SettingsProvider>(
          builder: (context, settingsProvider, _) {
            final hidden = statSeriesFromHiddenKeys(settingsProvider.tornStatsChartHiddenStats);
            return AlertDialog(
              title: const Text('Chart stats', style: TextStyle(fontSize: 16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final stat in StatSeries.values)
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      secondary: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(color: stat.color, shape: BoxShape.circle),
                      ),
                      title: Text(stat.fullLabel, style: const TextStyle(fontSize: 14)),
                      value: !hidden.contains(stat),
                      onChanged: (!hidden.contains(stat) && hidden.length >= _allStatSeries.length - 1)
                          ? null
                          : (_) => _toggleStat(settingsProvider, stat),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    bool showBoth = settingsProvider.tornStatsChartShowBoth;

    final (List<String> hiddenKeys, int rangeMonths) = context.select<SettingsProvider, (List<String>, int)>(
      (sp) => (sp.tornStatsChartHiddenStats, sp.tornStatsChartRange),
    );
    final Set<StatSeries> hidden = statSeriesFromHiddenKeys(hiddenKeys);

    bool isOldData = false;
    bool isStaleData = false;
    if (widget.statsData?.data != null && widget.statsData!.data!.isNotEmpty) {
      int maxTimestamp = 0;
      for (var element in widget.statsData!.data!) {
        if (element.timestamp != null && element.timestamp! > maxTimestamp) {
          maxTimestamp = element.timestamp!;
        }
      }
      if (maxTimestamp > 0) {
        final latestDate = DateTime.fromMillisecondsSinceEpoch(maxTimestamp * 1000);
        final now = DateTime.now();
        final difference = now.difference(latestDate);
        if (difference.inDays > 30) {
          isOldData = true;
        } else if (difference.inDays > 5 && widget.isCachedData) {
          isStaleData = true;
        }
      }
    }

    Widget? warningWidget;
    if (isOldData) {
      warningWidget = Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning, size: 12, color: Colors.orange[800]),
            const SizedBox(width: 5),
            Text(
              "TS sent data older than 1 month",
              style: TextStyle(
                fontSize: 10,
                color: Colors.orange[800],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else if (isStaleData) {
      warningWidget = Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning, size: 12, color: Colors.orange[800]),
            const SizedBox(width: 5),
            Text(
              "Displaying old cached data (> 5 days)",
              style: TextStyle(
                fontSize: 10,
                color: Colors.orange[800],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    if (showBoth) {
      Widget firstChart;
      Widget secondChart;

      if (widget.chartType == TornStatsChartType.Line) {
        firstChart = LineChart(_buildLineChartData(rangeMonths, hidden));
        secondChart = PieChart(_buildPieChartData(hidden));
      } else {
        firstChart = PieChart(_buildPieChartData(hidden));
        secondChart = LineChart(_buildLineChartData(rangeMonths, hidden));
      }

      return Column(
        children: [
          if (warningWidget != null) warningWidget,
          _legend(hidden),
          const SizedBox(height: 5),
          Flexible(child: firstChart),
          const SizedBox(height: 20),
          Flexible(child: secondChart),
        ],
      );
    }

    Widget chart;
    if (widget.chartType == TornStatsChartType.Line) {
      chart = LineChart(_buildLineChartData(rangeMonths, hidden));
    } else {
      chart = PieChart(_buildPieChartData(hidden));
    }

    return Column(
      children: [
        if (warningWidget != null) warningWidget,
        _legend(hidden),
        const SizedBox(height: 5),
        Flexible(
          child: chart,
        ),
      ],
    );
  }

  Row _legend(Set<StatSeries> hidden) {
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
                } else {
                  message = formatTornStatsErrorMessage(statsJson.message, prefix: 'Error updating stats: ');
                }
              } else if (resp.statusCode == 404 && resp.body.contains('User not found')) {
                message = formatTornStatsErrorMessage('User not found.', prefix: 'Error updating stats: ');
              } else {
                message = formatTornStatsHttpError(resp.statusCode, prefix: 'Error updating stats: ');
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
        GestureDetector(
          onTap: _showLegendDialog,
          child: Row(
            children: [
              for (final stat in StatSeries.values) ...[
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: hidden.contains(stat) ? stat.color.withAlpha(70) : stat.color,
                    shape: BoxShape.circle,
                  ),
                ),
                Text(
                  ' ${stat.shortLabel}',
                  style: TextStyle(
                    fontSize: 7,
                    color: hidden.contains(stat) ? Colors.grey : null,
                  ),
                ),
                if (stat != StatSeries.values.last) const SizedBox(width: 6),
              ],
            ],
          ),
        ),
      ],
    );
  }

  LineChartData _buildLineChartData(int rangeMonths, Set<StatSeries> hidden) {
    return buildStatsLineChartData(
      allData: widget.statsData!.data!,
      rangeMonths: rangeMonths,
      currentYearColor: context.read<ThemeProvider>().mainText,
      visibleStats: _allStatSeries.difference(hidden),
    );
  }

  PieChartData _buildPieChartData(Set<StatSeries> hidden) {
    List<PieChartSectionData> sections = [];
    Map<StatSeries, double> sums = calculateSumOfStats(hidden);
    double totalSum = sums.values.reduce((a, b) => a + b);

    sums.forEach((stat, value) {
      double percent = (value / totalSum) * 100;
      sections.add(
        PieChartSectionData(
          color: stat.color,
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

  Map<StatSeries, double> calculateSumOfStats(Set<StatSeries> hidden) {
    final values = {
      StatSeries.strength: widget.statsData!.data!.last.strength!.toDouble(),
      StatSeries.speed: widget.statsData!.data!.last.speed!.toDouble(),
      StatSeries.defense: widget.statsData!.data!.last.defense!.toDouble(),
      StatSeries.dexterity: widget.statsData!.data!.last.dexterity!.toDouble(),
    };
    return {
      for (final entry in values.entries)
        if (!hidden.contains(entry.key)) entry.key: entry.value,
    };
  }
}

const double _gapBreakMinDays = 7;
const double _gapBreakMedianFactor = 6;

double statsChartGapLimitInDays(List<double> xValues) {
  if (xValues.length < 3) return double.infinity;
  final gaps = <double>[];
  for (int i = 1; i < xValues.length; i++) {
    gaps.add(xValues[i] - xValues[i - 1]);
  }
  gaps.sort();
  final double median = gaps[gaps.length ~/ 2];
  return max(_gapBreakMinDays, median * _gapBreakMedianFactor);
}

LineChartData buildStatsLineChartData({
  required List<Datum> allData,
  required int rangeMonths,
  required Color currentYearColor,
  Set<StatSeries> visibleStats = _allStatSeries,
}) {
  final List<StatSeries> orderedVisible =
      [StatSeries.strength, StatSeries.defense, StatSeries.speed, StatSeries.dexterity]
          .where(visibleStats.contains)
          .toList();

  var data = allData.where((e) => e.timestamp != null && e.timestamp! > 0).toList();

  if (rangeMonths > 0 && data.isNotEmpty) {
    // Show the last X months of AVAILABLE data
    final int maxTimestamp = data.map((e) => e.timestamp!).reduce(max);
    final latestDate = DateTime.fromMillisecondsSinceEpoch(maxTimestamp * 1000);
    final cutoffDate = latestDate.subtract(Duration(days: rangeMonths * 30));
    data = data.where((e) {
      return DateTime.fromMillisecondsSinceEpoch(e.timestamp! * 1000).isAfter(cutoffDate);
    }).toList();
  }

  final xValues = <double>[];
  final indexByX = <double, int>{};
  double maxStat = 0;

  for (int i = 0; i < data.length; i++) {
    final double x = data[i].timestamp! / 86400;
    xValues.add(x);
    indexByX[x] = i;
    final int thisMax = [
      if (visibleStats.contains(StatSeries.strength)) data[i].strength ?? 0,
      if (visibleStats.contains(StatSeries.speed)) data[i].speed ?? 0,
      if (visibleStats.contains(StatSeries.defense)) data[i].defense ?? 0,
      if (visibleStats.contains(StatSeries.dexterity)) data[i].dexterity ?? 0,
    ].fold(0, max);
    if (thisMax > maxStat) {
      maxStat = thisMax.toDouble();
    }
  }

  final double gapLimit = statsChartGapLimitInDays(xValues);

  List<FlSpot> spotsOf(int? Function(Datum d) stat) {
    final spots = <FlSpot>[];
    for (int i = 0; i < data.length; i++) {
      if (i > 0 && xValues[i] - xValues[i - 1] > gapLimit) {
        spots.add(FlSpot.nullSpot);
      }
      spots.add(FlSpot(xValues[i], (stat(data[i]) ?? 0).toDouble()));
    }
    return spots;
  }

  final gapBands = <VerticalRangeAnnotation>[];
  for (int i = 1; i < xValues.length; i++) {
    if (xValues[i] - xValues[i - 1] > gapLimit) {
      gapBands.add(
        VerticalRangeAnnotation(
          x1: xValues[i - 1],
          x2: xValues[i],
          color: Colors.grey.withAlpha(38),
        ),
      );
    }
  }

  final double minX = xValues.isEmpty ? 0 : xValues.reduce(min);
  final double maxX = xValues.isEmpty ? 1 : xValues.reduce(max);
  final double labelInterval = maxX > minX ? (maxX - minX) / 5 : 1;

  return LineChartData(
    minX: minX,
    maxX: maxX,
    maxY: maxStat * 1.1,
    rangeAnnotations: RangeAnnotations(verticalRangeAnnotations: gapBands),
    lineBarsData: [
      if (visibleStats.contains(StatSeries.strength))
        LineChartBarData(
          spots: spotsOf((d) => d.strength),
          isCurved: false,
          barWidth: 2,
          color: Colors.blue,
          dotData: const FlDotData(
            show: false,
          ),
        ),
      if (visibleStats.contains(StatSeries.speed))
        LineChartBarData(
          spots: spotsOf((d) => d.speed),
          isCurved: false,
          barWidth: 2,
          color: Colors.orange,
          dotData: const FlDotData(
            show: false,
          ),
        ),
      if (visibleStats.contains(StatSeries.defense))
        LineChartBarData(
          spots: spotsOf((d) => d.defense),
          isCurved: false,
          barWidth: 2,
          color: Colors.red,
          dotData: const FlDotData(
            show: false,
          ),
        ),
      if (visibleStats.contains(StatSeries.dexterity))
        LineChartBarData(
          spots: spotsOf((d) => d.dexterity),
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
        getTooltipItems: (touchedSpots) {
          final int? index = touchedSpots.isEmpty ? null : indexByX[touchedSpots.first.x];
          if (index == null || touchedSpots.length != orderedVisible.length) {
            return List<LineTooltipItem?>.filled(touchedSpots.length, null);
          }

          final Datum touched = data[index];
          final NumberFormat f = NumberFormat("###,###", "en_US");
          final DateTime date = DateTime.fromMillisecondsSinceEpoch(touched.timestamp! * 1000);
          final String header = DateFormat('d LLL yyyy').format(date);
          final int total =
              (touched.strength ?? 0) + (touched.defense ?? 0) + (touched.speed ?? 0) + (touched.dexterity ?? 0);
          const style = TextStyle(fontSize: 10, color: Colors.white);

          int valueOf(StatSeries stat) => switch (stat) {
                StatSeries.strength => touched.strength ?? 0,
                StatSeries.defense => touched.defense ?? 0,
                StatSeries.speed => touched.speed ?? 0,
                StatSeries.dexterity => touched.dexterity ?? 0,
              };

          return [
            for (int i = 0; i < orderedVisible.length; i++)
              LineTooltipItem(
                [
                  if (i == 0) "$header\n\n",
                  "${orderedVisible[i].shortLabel}: ${f.format(valueOf(orderedVisible[i]))}",
                  if (i == orderedVisible.length - 1) "\n\nTOTAL ${f.format(total)}",
                ].join(),
                style,
              ),
          ];
        },
      ),
    ),
    titlesData: FlTitlesData(
      show: true,
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: labelInterval,
          getTitlesWidget: (position, meta) {
            if (meta.appliedInterval > 0 && position != meta.min && position != meta.max) {
              final double edge = meta.appliedInterval * 0.5;
              if (position - meta.min < edge || meta.max - position < edge) {
                return const SizedBox.shrink();
              }
            }

            final DateTime dt = DateTime.fromMillisecondsSinceEpoch((position * 86400 * 1000).round());
            final DateFormat formatter = DateFormat('d LLL');
            final String date = formatter.format(dt);

            const degrees = -50;
            const radians = degrees * pi / 180;

            // Color logic based on year
            final int currentYear = DateTime.now().year;
            Color yearColor;
            if (dt.year == currentYear) {
              yearColor = currentYearColor;
            } else if (dt.year == currentYear - 1) {
              yearColor = Colors.blue;
            } else if (dt.year == currentYear - 2) {
              yearColor = Colors.yellow[800]!;
            } else {
              yearColor = Colors.red;
            }

            return Transform.rotate(
              angle: radians,
              child: SizedBox(
                width: 60,
                child: Text(
                  date,
                  style: TextStyle(fontSize: 9, color: yearColor),
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
