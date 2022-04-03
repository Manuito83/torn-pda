import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:torn_pda/models/profile/external/torn_stats_chart.dart';
import 'package:torn_pda/utils/number_formatter.dart';

class StatsChart extends StatelessWidget {
  StatsChart({@required this.statsData});

  final StatsChartTornStats statsData;

  final _strengthSpots = <FlSpot>[];
  final _speedSpots = <FlSpot>[];
  final _defenseSpots = <FlSpot>[];
  final _dexteritySpots = <FlSpot>[];
  final _timestamps = <int>[];

  @override
  Widget build(BuildContext context) {
    LineChartData lineChartData = buildData();
    return LineChart(lineChartData);
  }

  LineChartData buildData() {
    double maxStat = 0;
    if (_strengthSpots.isEmpty) {
      for (int i = 0; i < statsData.data.length; i++) {
        _strengthSpots.add(FlSpot(i.toDouble(), statsData.data[i].strength.toDouble()));
        _speedSpots.add(FlSpot(i.toDouble(), statsData.data[i].speed.toDouble()));
        _defenseSpots.add(FlSpot(i.toDouble(), statsData.data[i].defense.toDouble()));
        _dexteritySpots.add(FlSpot(i.toDouble(), statsData.data[i].dexterity.toDouble()));
        _timestamps.add(statsData.data[i].timestamp);
        var thisMax = [
          statsData.data[i].strength,
          statsData.data[i].speed,
          statsData.data[i].defense,
          statsData.data[i].dexterity,
        ].reduce(max);
        if (thisMax > maxStat) {
          maxStat = thisMax.toDouble();
        }
      }
    }

    return LineChartData(
      maxY: maxStat * 1.05,
      lineBarsData: [
        LineChartBarData(
          spots: _strengthSpots,
          isCurved: true,
          barWidth: 2,
          color: Colors.blue,
          dotData: FlDotData(
            show: false,
          ),
        ),
        LineChartBarData(
          spots: _speedSpots,
          isCurved: true,
          barWidth: 2,
          color: Colors.red,
          dotData: FlDotData(
            show: false,
          ),
        ),
        LineChartBarData(
          spots: _defenseSpots,
          isCurved: true,
          barWidth: 2,
          color: Colors.orange,
          dotData: FlDotData(
            show: false,
          ),
        ),
        LineChartBarData(
          spots: _dexteritySpots,
          isCurved: true,
          barWidth: 2,
          color: Colors.green,
          dotData: FlDotData(
            show: false,
          ),
        ),
      ],
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            strokeWidth: 0.2,
            color: Colors.grey,
          );
        },
      ),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: false,
            tooltipBgColor: Colors.blueGrey.withOpacity(1),
            getTooltipItems: (value) {
              var tooltips = <LineTooltipItem>[];
              int stat = 1;
              int total = 0;
              for (var spot in value) {
                // Get time
                var ts = 0;
                var timesList = [];
                _timestamps.forEach((e) => timesList.add("${e}"));
                var x = spot.x.toInt();
                if (x > timesList.length) {
                  x = timesList.length;
                }
                ts = int.parse(timesList[x]);
                var date = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
                DateFormat formatter = DateFormat('d LLL');

                String statLine = "";
                if (stat == 1) {
                  statLine = "STR";
                } else if (stat == 2) {
                  statLine = "SPD";
                } else if (stat == 3) {
                  statLine = "DEF";
                } else if (stat == 4) {
                  statLine = "DEX";
                }

                var f = NumberFormat("###,###", "en_US");
                int statValue = spot.y.toInt();
                statLine += " ${f.format(statValue)}";
                total += statValue;

                String tooltip = "";
                if (stat == 1) {
                  tooltip = "${formatter.format(date)}\n\n$statLine";
                } else if (stat == 4) {
                  tooltip = "$statLine\n\nTotal ${f.format(total)}";
                } else {
                  tooltip = statLine;
                }

                LineTooltipItem thisItem = LineTooltipItem(
                  tooltip,
                  TextStyle(
                    fontSize: 10,
                  ),
                );
                tooltips.add(thisItem);

                stat++;
              }

              return tooltips;
            }),
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (position, meta) {
              if (position == 0) return SizedBox.shrink();

              int ts = _timestamps[position.toInt()] * 1000;
              DateTime dt = DateTime.fromMillisecondsSinceEpoch(ts);
              DateFormat formatter = DateFormat('d LLL');
              String date = formatter.format(dt);

              final degrees = -50;
              final radians = degrees * pi / 180;

              return Transform.rotate(
                angle: radians,
                child: SizedBox(
                  width: 60,
                  child: Text(
                    date,
                    style: TextStyle(fontSize: 9),
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
              if (position == 0) return SizedBox.shrink();
              return Text(
                formatBigNumbers(position.toInt()),
                style: TextStyle(fontSize: 9),
              );
            },
          ),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
    );
  }
}
