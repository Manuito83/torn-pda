// Dart imports:
import 'dart:async';
import 'dart:math';

// Package imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:fl_chart/fl_chart.dart';
// Flutter imports:
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/drawer.dart';
// Project imports:
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';

class AwardsGraphs extends StatefulWidget {
  const AwardsGraphs({required this.graphInfo});

  final List<dynamic> graphInfo;

  @override
  AwardsGraphsState createState() => AwardsGraphsState();
}

class AwardsGraphsState extends State<AwardsGraphs> {
  final Color barBackgroundColor = const Color(0xff72d8bf);

  int? _touchedIndex;

  bool _landScape = false;

  late SettingsProvider _settingsProvider;
  late ThemeProvider _themeProvider;
  late StreamSubscription _willPopSubscription;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    routeWithDrawer = false;
    routeName = "awards_graphs";
    _willPopSubscription = _settingsProvider.willPopShouldGoBackStream.stream.listen((event) {
      if (mounted && routeName == "awards_graphs") _goBack();
    });
  }

  @override
  void dispose() {
    _willPopSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
      color: _themeProvider.currentTheme == AppTheme.light
          ? MediaQuery.orientationOf(context) == Orientation.portrait
              ? Colors.blueGrey
              : Colors.grey[900]
          : _themeProvider.currentTheme == AppTheme.dark
              ? Colors.grey[900]
              : Colors.black,
      child: SafeArea(
        right: context.read<WebViewProvider>().webViewSplitActive &&
            context.read<WebViewProvider>().splitScreenPosition == WebViewSplitPosition.left,
        left: context.read<WebViewProvider>().webViewSplitActive &&
            context.read<WebViewProvider>().splitScreenPosition == WebViewSplitPosition.right,
        child: Scaffold(
          backgroundColor: _themeProvider.canvas,
          appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
          bottomNavigationBar: !_settingsProvider.appBarTop
              ? SizedBox(
                  height: AppBar().preferredSize.height,
                  child: buildAppBar(),
                )
              : null,
          body: Container(
            color: _themeProvider.canvas,
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      title: Row(
        children: [
          const Text('Awards graph'),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              BotToast.showText(
                text: "This section is part of YATA's mobile interface, all details "
                    "information and actions are directly linked to your YATA account.",
                textStyle: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                ),
                contentColor: Colors.green[800]!,
                duration: const Duration(seconds: 6),
                contentPadding: const EdgeInsets.all(10),
              );
            },
            child: Image.asset('images/icons/yata_logo.png', height: 28),
          ),
        ],
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          _goBack();
        },
      ),
      actions: [
        // Only give option to rotate if it's not already been allowed app-wide
        if (!_settingsProvider.allowScreenRotation)
          IconButton(
            icon: Icon(
              Icons.screen_rotation_outlined,
              color: _themeProvider.buttonText,
            ),
            onPressed: () {
              if (_landScape) {
                _landScape = false;
                SystemChrome.setPreferredOrientations([
                  DeviceOrientation.portraitUp,
                ]);
              } else {
                _landScape = true;
                SystemChrome.setPreferredOrientations([
                  DeviceOrientation.landscapeRight,
                  DeviceOrientation.landscapeLeft,
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
          getTooltipColor: (touchedSpot) => Colors.blueGrey,
          fitInsideVertically: true,
          fitInsideHorizontally: true,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final decimalFormat = NumberFormat("#,##0", "en_US");
            final achieved = widget.graphInfo[group.x][2] == 0 ? "NOT ACHIEVED" : "ACHIEVED";
            return BarTooltipItem(
              "${widget.graphInfo[group.x][0]}\n"
              "Circulation ${decimalFormat.format(widget.graphInfo[group.x][1])}\n"
              "Rarity ${widget.graphInfo[group.x][4].toStringAsFixed(4)}\n\n"
              "$achieved",
              const TextStyle(color: Colors.yellow, fontSize: 12),
            );
          },
        ),
        // Threshold so that the smallest bars can be selected as well
        touchExtraThreshold: const EdgeInsets.only(top: 30),
        touchCallback: (flTouchEvent, barTouchResponse) {
          setState(() {
            if (barTouchResponse?.spot != null &&
                barTouchResponse is! PointerUpEvent &&
                barTouchResponse is! PointerExitEvent) {
              _touchedIndex = barTouchResponse!.spot!.touchedBarGroupIndex;
            } else {
              _touchedIndex = -1;
            }
          });
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        topTitles: const AxisTitles(
          sideTitles: SideTitles(
            showTitles: false,
          ),
        ),
        bottomTitles: const AxisTitles(
          sideTitles: SideTitles(
            showTitles: false,
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(
            showTitles: false,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            reservedSize: 40,
            interval: 1,
            showTitles: true,
            getTitlesWidget: (value, titleMeta) {
              // Antilogarithm
              final int yValue = pow(10, value).round();
              String yString = yValue.toString();
              if (yValue == 1) {
                yString = "0";
              } else if (yValue > 999) {
                yString = "${(yValue / 1000).truncate().toStringAsFixed(0)}K";
              }

              return Text(
                yString,
                style: TextStyle(
                  color: _themeProvider.mainText,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: false,
      ),
      barGroups: showingGroups(),
    );
  }

  List<BarChartGroupData> showingGroups() {
    final double width = MediaQuery.sizeOf(context).width;
    var pixelPerBar = (width - 200) / widget.graphInfo.length;
    if (pixelPerBar < 1) {
      pixelPerBar = 1;
    }

    final awardBarList = <BarChartGroupData>[];
    for (var i = 0; i < widget.graphInfo.length; i++) {
      awardBarList.add(
        makeGroupData(
          x: i,
          //y: widget.graphInfo[i][1].toDouble(),
          y: log(widget.graphInfo[i][1]) / ln10,
          isTouched: i == _touchedIndex,
          barColor: widget.graphInfo[i][2] == 0 ? Colors.red : Colors.green,
          width: pixelPerBar,
        ),
      );
    }

    return awardBarList;
  }

  BarChartGroupData makeGroupData({
    required int x,
    required double y,
    bool isTouched = false,
    Color barColor = Colors.white,
    double width = 2,
    List<int> showTooltips = const [],
  }) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: isTouched ? Colors.yellow : barColor,
          width: width,
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: y,
            color: barBackgroundColor,
          ),
        ),
      ],
      showingTooltipIndicators: showTooltips,
    );
  }

  void _goBack() {
    // Only revert rotation if it's not allowed app-wide
    if (!_settingsProvider.allowScreenRotation) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }

    routeWithDrawer = true;
    routeName = "awards";
    Navigator.of(context).pop();
  }
}
