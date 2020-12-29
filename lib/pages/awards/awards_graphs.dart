import 'package:provider/provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:intl/intl.dart';

class AwardsGraphs extends StatefulWidget {
  AwardsGraphs({@required this.graphInfo});

  final List<dynamic> graphInfo;

  @override
  _AwardsGraphsState createState() => _AwardsGraphsState();
}

class _AwardsGraphsState extends State<AwardsGraphs> {
  final Color barBackgroundColor = const Color(0xff72d8bf);

  int _touchedIndex;

  bool _landScape = false;

  SettingsProvider _settingsProvider;
  ThemeProvider _themeProvider;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return Container(
      color: _themeProvider.currentTheme == AppTheme.light
          ? Colors.blueGrey
          : Colors.grey[900],
      child: WillPopScope(
        onWillPop: _willPopCallback,
        child: SafeArea(
          top: _settingsProvider.appBarTop ? false : true,
          bottom: true,
          child: Scaffold(
            appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
            bottomNavigationBar: !_settingsProvider.appBarTop
                ? SizedBox(
                    height: AppBar().preferredSize.height,
                    child: buildAppBar(),
                  )
                : null,
            body: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  /*
                  Text(
                    'Awards',
                    style: TextStyle(
                        color: const Color(0xff0f4a3c),
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(
                    height: 38,
                  ),
                  */
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: BarChart(
                        mainBarData(),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      brightness: Brightness.dark,
      title: Row(
        children: [
          Text('Awards graph'),
          SizedBox(width: 8),
          GestureDetector(
              onTap: () {
                BotToast.showText(
                  text:
                      "This section is part of YATA's mobile interface, all details "
                      "information and actions are directly linked to your YATA account.",
                  textStyle: TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                  ),
                  contentColor: Colors.green[800],
                  duration: Duration(seconds: 6),
                  contentPadding: EdgeInsets.all(10),
                );
              },
              child: Image.asset('images/icons/yata_logo.png', height: 28)),
        ],
      ),
      leading: new IconButton(
        icon: new Icon(Icons.arrow_back),
        onPressed: () {
          _willPopCallback();
        },
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.screen_rotation_outlined,
            color: _themeProvider.buttonText,
          ),
          onPressed: () {
            if (_landScape) {
              _landScape = false;
              SystemChrome.setPreferredOrientations(
                  [DeviceOrientation.portraitUp]);
            } else {
              _landScape = true;
              SystemChrome.setPreferredOrientations([
                DeviceOrientation.landscapeRight,
                DeviceOrientation.landscapeLeft
              ]);
            }
          },
        )
      ],
    );
  }

  BarChartData mainBarData() {
    return BarChartData(
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueGrey,
            fitInsideVertically: true,
            fitInsideHorizontally: true,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final decimalFormat = new NumberFormat("#,##0", "en_US");
              var achieved = widget.graphInfo[group.x][2] == 0
                  ? "NOT ACHIEVED"
                  : "ACHIEVED";
              return BarTooltipItem(
                "${widget.graphInfo[group.x][0]}\n"
                "Circulation ${decimalFormat.format(widget.graphInfo[group.x][1])}\n"
                "Rarity ${widget.graphInfo[group.x][4].toStringAsFixed(4)}\n\n"
                "$achieved",
                TextStyle(color: Colors.yellow, fontSize: 12),
              );
            }),
        // Threshold so that the smallest bars can be selected as well
        touchExtraThreshold: EdgeInsets.only(top: 30),
        touchCallback: (barTouchResponse) {
          setState(() {
            if (barTouchResponse.spot != null &&
                barTouchResponse.touchInput is! FlPanEnd &&
                barTouchResponse.touchInput is! FlLongPressEnd) {
              _touchedIndex = barTouchResponse.spot.touchedBarGroupIndex;
            } else {
              _touchedIndex = -1;
            }
          });
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: SideTitles(
          showTitles: false,
        ),
        leftTitles: SideTitles(
          reservedSize: 25,
          getTitles: (value) {
            // Antilogarithm
            int yValue = pow(10, value).round();
            String yString = yValue.toString();
            if (yValue == 1) {
              return "0";
            } else if (yValue > 999) {
              yString = "${(yValue / 1000).truncate().toStringAsFixed(0)}K";
            }
            return yString;
          },
          getTextStyles: (value) {
            return TextStyle(color: _themeProvider.mainText, fontSize: 12);
          },
          showTitles: true,
          interval: 1,
        ),
      ),
      borderData: FlBorderData(
        show: false,
      ),
      barGroups: showingGroups(),
    );
  }

  List<BarChartGroupData> showingGroups() {
    double width = MediaQuery.of(context).size.width;
    var pixelPerBar = (width - 200) / widget.graphInfo.length;
    if (pixelPerBar < 1) {
      pixelPerBar = 1;
    }

    var awardBarList = <BarChartGroupData>[];
    for (var i = 0; i < widget.graphInfo.length; i++) {
      awardBarList.add(
        makeGroupData(
          x: i,
          //y: widget.graphInfo[i][1].toDouble(),
          y: log(widget.graphInfo[i][1]) / ln10.toDouble(),
          isTouched: i == _touchedIndex,
          barColor: widget.graphInfo[i][2] == 0 ? Colors.red : Colors.green,
          width: pixelPerBar,
        ),
      );
    }

    return awardBarList;
  }

  BarChartGroupData makeGroupData({
    int x,
    double y,
    bool isTouched = false,
    Color barColor = Colors.white,
    double width = 2,
    List<int> showTooltips = const [],
  }) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          //y: isTouched ? y + 1 : y,
          y: y,
          colors: isTouched ? [Colors.yellow] : [barColor],
          width: width,
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            //y: 20,
            y: y,
            colors: [barBackgroundColor],
          ),
        ),
      ],
      showingTooltipIndicators: showTooltips,
    );
  }

  Future<bool> _willPopCallback() async {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    Navigator.of(context).pop();
    return true;
  }
}
