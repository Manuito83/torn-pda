import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:torn_pda/models/profile/external/torn_stats_chart.dart';
import 'package:torn_pda/utils/number_formatter.dart';

class StatsChart extends StatelessWidget {
  StatsChart({required this.statsData});

  final StatsChartTornStats? statsData;

  final _strengthSpots = <FlSpot>[];
  final _speedSpots = <FlSpot>[];
  final _defenseSpots = <FlSpot>[];
  final _dexteritySpots = <FlSpot>[];
  final _timestamps = <int?>[];

  @override
  Widget build(BuildContext context) {
    LineChartData lineChartData = buildData();
    return Column(
      children: [
        _legend(),
        SizedBox(height: 5),
        Flexible(child: LineChart(lineChartData)),
      ],
    );
  }

  Row _legend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('images/icons/tornstats_logo.png', width: 12),
        SizedBox(width: 5),
        Text('STATS', style: TextStyle(fontSize: 8)),
        SizedBox(width: 20),
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
        ),
        Text(' STR', style: TextStyle(fontSize: 7)),
        SizedBox(width: 6),
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.circle,
          ),
        ),
        Text(' DEF', style: TextStyle(fontSize: 7)),
        SizedBox(width: 6),
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
        ),
        Text(' SPD', style: TextStyle(fontSize: 7)),
        SizedBox(width: 6),
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
        ),
        Text(' DEX', style: TextStyle(fontSize: 7)),
        SizedBox(width: 6),
        Text('', style: TextStyle(fontSize: 8)),
      ],
    );
  }

  LineChartData buildData() {
    double maxStat = 0;
    if (_strengthSpots.isEmpty) {
      for (int i = 0; i < statsData!.data!.length; i++) {
        _strengthSpots.add(FlSpot(i.toDouble(), statsData!.data![i].strength!.toDouble()));
        _speedSpots.add(FlSpot(i.toDouble(), statsData!.data![i].speed!.toDouble()));
        _defenseSpots.add(FlSpot(i.toDouble(), statsData!.data![i].defense!.toDouble()));
        _dexteritySpots.add(FlSpot(i.toDouble(), statsData!.data![i].dexterity!.toDouble()));
        _timestamps.add(statsData!.data![i].timestamp);
        int thisMax = [
          statsData!.data![i].strength ?? 0,
          statsData!.data![i].speed ?? 0,
          statsData!.data![i].defense ?? 0,
          statsData!.data![i].dexterity ?? 0,
        ].fold(0, max);
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
              int thisX = value[0].x.toInt();

              NumberFormat f = NumberFormat("###,###", "en_US");

              // Get time comparing position in x with timestamps
              var ts = 0;
              var timesList = [];
              _timestamps.forEach((e) => timesList.add("${e}"));
              if (thisX > timesList.length) {
                thisX = timesList.length;
              }
              ts = int.parse(timesList[thisX]);
              var date = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
              DateFormat formatter = DateFormat('d LLL yyyy');

              // The first line (STR) will be preceded by date
              String strLine = "${formatter.format(date)}";

              // Configure the last line to show totals
              double total = 0;
              for (var stat in value) {
                total += stat.y;
              }
              String dexLine = "TOTAL ${f.format(total.toInt())}";

              // Values come unsorted, we sort them here to our liking
              tooltips.add(LineTooltipItem(
                "$strLine\n\nSTR: ${f.format(statsData!.data![thisX].strength)}",
                TextStyle(fontSize: 10),
              ));
              tooltips.add(LineTooltipItem(
                "DEF: ${f.format(statsData!.data![thisX].defense)}",
                TextStyle(fontSize: 10),
              ));
              tooltips.add(LineTooltipItem(
                "SPD: ${f.format(statsData!.data![thisX].speed)}",
                TextStyle(fontSize: 10),
              ));
              tooltips.add(LineTooltipItem(
                "DEX: ${f.format(statsData!.data![thisX].dexterity)}\n\n$dexLine",
                TextStyle(fontSize: 10),
              ));

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

              int ts = _timestamps[position.toInt()]! * 1000;
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
