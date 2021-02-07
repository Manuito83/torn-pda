import 'dart:async';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:torn_pda/models/travel/foreign_stock_in.dart';
import 'package:torn_pda/models/items_model.dart';
import 'package:torn_pda/models/inventory_model.dart';
import 'package:torn_pda/utils/firestore.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:torn_pda/utils/travel/travel_times.dart';
import 'package:torn_pda/widgets/travel/delayed_travel_dialog.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/utils/time_formatter.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'dart:convert';
import "dart:collection";
import 'dart:ui';

class ForeignStockCard extends StatefulWidget {
  final ForeignStock foreignStock;
  final bool inventoryEnabled;
  final bool showArrivalTime;
  final InventoryModel inventoryModel;
  final ItemsModel allTornItems;
  final int capacity;
  final int moneyOnHand;
  final Function flagPressedCallback;
  final TravelTicket ticket;
  final Map<String, dynamic> activeRestocks;

  ForeignStockCard(
      {@required this.foreignStock,
      @required this.inventoryEnabled,
      @required this.inventoryModel,
      @required this.showArrivalTime,
      @required this.capacity,
      @required this.allTornItems,
      @required this.moneyOnHand,
      @required this.flagPressedCallback,
      @required this.ticket,
      @required this.activeRestocks,
      @required Key key})
      : super(key: key);

  @override
  _ForeignStockCardState createState() => _ForeignStockCardState();
}

class _ForeignStockCardState extends State<ForeignStockCard> {
  var _expandableController = ExpandableController();

  Future _footerInformationRetrieved;
  bool _footerSuccessful = false;

  var _periodicMap = SplayTreeMap();

  var _averageTimeToRestock = 0;
  var _restockReliability = 0;
  var _projectedRestockDateTime = DateTime.now();
  var _depletionTrendPerSecond = 0.0;

  var _invQuantity = 0;

  var _delayedDepartureTime = DateTime.now();
  String _countryFullName = "";
  String _codeName = "";

  DateTime _earliestArrival = DateTime.now();
  int _travelSeconds = 0;

  SettingsProvider _settingsProvider;
  ThemeProvider _themeProvider;

  List<Color> gradientColors = [
    const Color(0xff23b6e6),
    const Color(0xff02d39a),
  ];

  Timer _ticker;

  @override
  void initState() {
    super.initState();
    _calculateDetails();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    _expandableController.addListener(() {
      if (_expandableController.expanded == true && !_footerSuccessful) {
        _footerInformationRetrieved = _getFooterInformation();
      }
    });

    _ticker = new Timer.periodic(
        Duration(minutes: 1), (Timer t) => _timerUpdate());

    // Build code name
    _codeName = "${widget.foreignStock.countryCode}-"
        "${widget.foreignStock.name}";
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _expandableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: widget.activeRestocks.keys.contains(_codeName)
              ? Colors.blue
              : Colors.transparent,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ExpandablePanel(
          controller: _expandableController,
          theme: ExpandableThemeData(
            hasIcon: false,
          ),
          header: _header(),
          expanded: _footer(),
        ),
      ),
    );
  }

  Widget _header() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _firstRow(widget.foreignStock),
                SizedBox(height: 10),
                _secondRow(widget.foreignStock),
              ],
            ),
            _countryFlagAndArrow(widget.foreignStock),
          ],
        ),
      ],
    );
  }

  Widget _footer() {
    // AVERAGE CALCULATION
    var average = "unknown";
    var reliability = "";
    var reliabilityColor = Colors.transparent;
    if (_averageTimeToRestock > 0) {
      average = _formatDuration(Duration(seconds: _averageTimeToRestock));
      if (_restockReliability < 33) {
        reliability = "low";
        reliabilityColor = Colors.red;
      } else if (_restockReliability >= 33 && _restockReliability < 66) {
        reliability = "medium";
        reliabilityColor = Colors.orangeAccent;
      } else if (_restockReliability >= 66 && _restockReliability < 80) {
        reliability = "medium-high";
        reliabilityColor = Colors.green;
      } else {
        reliability = "high";
        reliabilityColor = Colors.green;
      }
    }

    // WHEN TO TRAVEL
    var whenToTravel = "";
    var arrivalTime = "";
    var depletesTime = "";
    Color whenToTravelColor = _themeProvider.mainText;

    bool delayDeparture = false;

    // Calculates when to leave, taking into account:
    //  - If there are items: arrive before depletion
    //  - If there are no items: arrive when restock happens
    //  - Does NOT take into account a restock that depletes quickly

    if (_earliestArrival.isAfter(_projectedRestockDateTime)) {
      delayDeparture = false;

      // Avoid dividing by 0 if we have no trend
      if (widget.foreignStock.quantity > 0 && _depletionTrendPerSecond > 0) {
        var secondsToDeplete =
            widget.foreignStock.quantity / _depletionTrendPerSecond;

        // If depleting very slowly (more than a day)
        if (secondsToDeplete > 86400) {
          whenToTravel = "Travel NOW";
          depletesTime = "Depletes in more than a day";
        }
        // If we won't arrive before depletion
        else {
          var depletionDateTime =
              DateTime.now().add(Duration(seconds: secondsToDeplete.round()));
          if (_earliestArrival.isAfter(depletionDateTime)) {
            whenToTravel =
                "Caution, depletes at ${_timeFormatter(depletionDateTime)}";
            whenToTravelColor = Colors.orangeAccent;
          }
          // If we arrive before depletion
          else {
            whenToTravel = "Travel NOW";
            depletesTime = "Depletes at ${_timeFormatter(depletionDateTime)}";
          }
        }
      }
      // Item is either empty or is not depleting
      else {
        // This will avoid recommending to travel with empty empty with no known
        // average restock time
        if (widget.foreignStock.quantity > 0 || average != "unknown") {
          whenToTravel = "Travel NOW";
        }
      }
      arrivalTime = "You will be there at ${_timeFormatter(_earliestArrival)}";
    }
    // If we arrive before restock if we depart now
    else {
      delayDeparture = true;

      var additionalWait =
          _projectedRestockDateTime.difference(_earliestArrival).inSeconds;

      _delayedDepartureTime =
          DateTime.now().add(Duration(seconds: additionalWait));

      whenToTravel = "Travel at ${_timeFormatter(_delayedDepartureTime)}";
      var delayedArrival =
          _delayedDepartureTime.add(Duration(seconds: _travelSeconds));
      arrivalTime = "You will be there at ${_timeFormatter(delayedArrival)}";
    }

    return FutureBuilder(
        future: _footerInformationRetrieved,
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (_footerSuccessful) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (delayDeparture)
                          IconButton(
                            iconSize: 22,
                            icon: Icon(Icons.notifications_none),
                            onPressed: () {
                              _showDelayedTravelDialog();
                            },
                          ),
                        if (whenToTravel.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                whenToTravel,
                                style: TextStyle(
                                    fontSize: 12, color: whenToTravelColor),
                              ),
                              if (depletesTime.isNotEmpty)
                                Text(
                                  depletesTime,
                                  style: TextStyle(
                                    fontSize: 12,
                                  ),
                                ),
                              Text(
                                arrivalTime,
                                style: TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    SizedBox(height: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Average restock time: $average",
                          style: TextStyle(
                            fontSize: 12,
                          ),
                        ),
                        if (reliability.isNotEmpty)
                          Row(
                            children: [
                              Text(
                                "Reliability: ",
                                style: TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                "$reliability",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: reliabilityColor,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    SizedBox(height: 20),
                    SizedBox(
                      height: 200,
                      width: 600,
                      child: LineChart(_mainChartData()),
                    ),
                    SizedBox(height: 25),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                      child: CheckboxListTile(
                        checkColor: Colors.white,
                        activeColor: Colors.blue,
                        value: widget.activeRestocks.keys.contains(_codeName)
                            ? true
                            : false,
                        title: Text(
                          "Restock alert (auto)",
                          style: TextStyle(
                            fontSize: 12,
                          ),
                        ),
                        subtitle: Text(
                          "Get notified whenever ${widget.foreignStock.name} is restocked in $_countryFullName",
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        onChanged: (ticked) async {
                          if (ticked) {
                            await _addToActiveRestockAlerts();
                          } else {
                            await _removeToActiveRestockAlerts();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              );
            } else {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  "There is an issue contacting the server, "
                  "please try again later",
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              );
            }
          } else {
            return Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
                child: CircularProgressIndicator(),
              ),
            );
          }
        });
  }

  Future _addToActiveRestockAlerts() async {
    var time = DateTime.now().millisecondsSinceEpoch;
    if (!widget.activeRestocks.keys.contains(_codeName)) {
      Map<String, dynamic> tempMap = widget.activeRestocks;
      tempMap.addAll({_codeName: time});
      firestore.updateActiveRestockAlerts(tempMap).then((success) async {
        if (success) {
          setState(() {
            widget.activeRestocks.addAll({_codeName: time});
          });
          SharedPreferencesModel().setActiveRestocks(json.encode(tempMap));

          var alertsEnabled =
              await SharedPreferencesModel().getRestocksNotificationEnabled();
          if (!alertsEnabled) {
            BotToast.showText(
              text: "Your restocks notifications are OFF, remember to active "
                  "them in the Alerts section!",
              textStyle: TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
              contentColor: Colors.orange[700],
              duration: Duration(seconds: 4),
              contentPadding: EdgeInsets.all(10),
            );
          }
        }
      });
    }
  }

  Future _removeToActiveRestockAlerts() async {
    if (widget.activeRestocks.keys.contains(_codeName)) {
      Map<String, dynamic> tempMap = widget.activeRestocks;
      tempMap.removeWhere((key, value) => key == _codeName);
      firestore.updateActiveRestockAlerts(tempMap).then((success) {
        if (success) {
          setState(() {
            widget.activeRestocks.removeWhere((key, value) => key == _codeName);
          });
          SharedPreferencesModel().setActiveRestocks(json.encode(tempMap));
        }
      });
    }
  }

  Row _firstRow(ForeignStock stock) {
    return Row(
      children: <Widget>[
        Image.asset('images/torn_items/small/${stock.id}_small.png'),
        Padding(
          padding: EdgeInsets.only(right: 10),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(stock.name),
            ),
            if (widget.inventoryEnabled)
              SizedBox(
                width: 100,
                child: Text(
                  "Inv: x$_invQuantity",
                  style: TextStyle(fontSize: 11),
                ),
              ),
            if (widget.showArrivalTime)
              Row(
                children: [
                  Icon(MdiIcons.airplaneLanding, size: 12),
                  SizedBox(width: 2),
                  Text(
                    "${_timeFormatter(_earliestArrival)}",
                    style: TextStyle(fontSize: 11),
                  ),
                ],
              ),
          ],
        ),
        Padding(
          padding: EdgeInsets.only(right: 15),
        ),
        SizedBox(
          width: 55,
          child: Text(
            'x${stock.quantity}',
            style: TextStyle(
              color: stock.quantity > 0 ? Colors.green : Colors.red,
              fontWeight:
                  stock.quantity > 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        _returnLastUpdated(),
      ],
    );
  }

  Row _secondRow(ForeignStock stock) {
    // Travel time per hour, round trip

    // We recalculate profit here so that it changes with capacity or ticket type
    // in realtime. The profit that came from the parent was only for sorting just
    // after retrieving data
    stock.profit = (stock.value /
            (TravelTimes.travelTimeMinutesOneWay(
                  ticket: widget.ticket,
                  country: widget.foreignStock.country,
                ) *
                2 /
                60))
        .round();

    // Currency configuration
    final costCurrency = new NumberFormat("#,##0", "en_US");

    // Item cost
    Widget costWidget;
    costWidget = Text(
      '\$${costCurrency.format(stock.cost)}',
      style: TextStyle(fontWeight: FontWeight.bold),
    );

    // Profit and profit per hour
    Widget profitWidget;
    Widget profitPerMinuteWidget;
    final profitColor = stock.value <= 0 ? Colors.red : Colors.green;

    String profitFormatted = formatProfit(stock.value.abs());
    if (stock.value <= 0) {
      profitFormatted = '-\$$profitFormatted';
    } else {
      profitFormatted = '+\$$profitFormatted';
    }

    profitWidget = Text(
      profitFormatted,
      style: TextStyle(color: profitColor),
    );

    // Profit per hour
    String profitPerHourFormatted =
        formatProfit((stock.profit * widget.capacity).abs());
    if (stock.profit <= 0) {
      profitPerHourFormatted = '-\$$profitPerHourFormatted';
    } else {
      profitPerHourFormatted = '+\$$profitPerHourFormatted';
    }

    profitPerMinuteWidget = Text(
      '($profitPerHourFormatted/hour)',
      style: TextStyle(color: profitColor),
    );

    return Row(
      children: <Widget>[
        costWidget,
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: profitWidget,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: profitPerMinuteWidget,
        ),
      ],
    );
  }

  String formatProfit(int moneyInput) {
    final profitCurrencyHigh = new NumberFormat("#,##0.0", "en_US");
    final costCurrencyLow = new NumberFormat("#,##0", "en_US");
    String profitFormat;

    // Money standards to reduce string length (adding two zeros for .00)
    final billion = 1000000000;
    final million = 1000000;
    final thousand = 1000;

    // Profit
    if (moneyInput < -billion || moneyInput > billion) {
      final profitBillion = moneyInput / billion;
      profitFormat = '${profitCurrencyHigh.format(profitBillion)}B';
    } else if (moneyInput < -million || moneyInput > million) {
      final profitMillion = moneyInput / million;
      profitFormat = '${profitCurrencyHigh.format(profitMillion)}M';
    } else if (moneyInput < -thousand || moneyInput > thousand) {
      final profitThousand = moneyInput / thousand;
      profitFormat = '${profitCurrencyHigh.format(profitThousand)}K';
    } else {
      profitFormat = '${costCurrencyLow.format(moneyInput)}';
    }
    return profitFormat;
  }

  Widget _countryFlagAndArrow(ForeignStock stock) {
    String countryCode;
    String flag;
    switch (stock.country) {
      case CountryName.JAPAN:
        countryCode = 'JPN';
        _countryFullName = 'Japan';
        flag = 'images/flags/stock/japan.png';
        break;
      case CountryName.HAWAII:
        countryCode = 'HAW';
        _countryFullName = 'Hawaii';
        flag = 'images/flags/stock/hawaii.png';
        break;
      case CountryName.CHINA:
        countryCode = 'CHN';
        _countryFullName = 'China';
        flag = 'images/flags/stock/china.png';
        break;
      case CountryName.ARGENTINA:
        countryCode = 'ARG';
        _countryFullName = 'Argentina';
        flag = 'images/flags/stock/argentina.png';
        break;
      case CountryName.UNITED_KINGDOM:
        countryCode = 'UK';
        _countryFullName = 'the United Kingdom';
        flag = 'images/flags/stock/uk.png';
        break;
      case CountryName.CAYMAN_ISLANDS:
        countryCode = 'CAY';
        _countryFullName = 'Cayman Islands';
        flag = 'images/flags/stock/cayman.png';
        break;
      case CountryName.SOUTH_AFRICA:
        countryCode = 'AFR';
        _countryFullName = 'South Africa';
        flag = 'images/flags/stock/south-africa.png';
        break;
      case CountryName.SWITZERLAND:
        countryCode = 'SWI';
        _countryFullName = 'Switzerland';
        flag = 'images/flags/stock/switzerland.png';
        break;
      case CountryName.MEXICO:
        countryCode = 'MEX';
        _countryFullName = 'Mexico';
        flag = 'images/flags/stock/mexico.png';
        break;
      case CountryName.UAE:
        countryCode = 'UAE';
        _countryFullName = 'the United Arab Emirates';
        flag = 'images/flags/stock/uae.png';
        break;
      case CountryName.CANADA:
        countryCode = 'CAN';
        _countryFullName = 'Canada';
        flag = 'images/flags/stock/canada.png';
        break;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        GestureDetector(
          child: Text(countryCode),
          onLongPress: () {
            _launchMoneyWarning(stock);
            widget.flagPressedCallback(true, false);
          },
          onTap: () {
            _launchMoneyWarning(stock);
            widget.flagPressedCallback(true, true);
          },
        ),
        Image.asset(
          flag,
          width: 30,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Icon(Icons.keyboard_arrow_down_outlined),
        ),
      ],
    );
  }

  void _launchMoneyWarning(ForeignStock stock) {
    // Currency configuration
    final costCurrency = new NumberFormat("#,##0", "en_US");

    var moneyOnHand = widget.moneyOnHand;
    String moneyToBuy = '';
    Color moneyToBuyColor = Colors.grey;
    if (moneyOnHand >= stock.cost * widget.capacity) {
      moneyToBuy =
          'You HAVE the \$${costCurrency.format(stock.cost * widget.capacity)} necessary to '
          'buy $widget.capacity ${stock.name}';
      moneyToBuyColor = Colors.green;
    } else {
      moneyToBuy =
          'You DO NOT HAVE the \$${costCurrency.format(stock.cost * widget.capacity)} '
          'necessary to buy $widget.capacity ${stock.name}. Add another '
          '\$${costCurrency.format((stock.cost * widget.capacity) - moneyOnHand)}';
      moneyToBuyColor = Colors.red;
    }

    BotToast.showText(
      text: moneyToBuy,
      textStyle: TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
      contentColor: moneyToBuyColor,
      duration: Duration(seconds: 6),
      contentPadding: EdgeInsets.all(10),
    );
  }

  Row _returnLastUpdated() {
    var inputTime = DateTime.fromMillisecondsSinceEpoch(widget.foreignStock.timestamp * 1000);
    var timeDifference = DateTime.now().difference(inputTime);
    var timeString;
    var color;
    if (timeDifference.inMinutes < 1) {
      timeString = 'now';
      color = Colors.green;
    } else if (timeDifference.inMinutes == 1 && timeDifference.inHours < 1) {
      timeString = '1 min';
      color = Colors.green;
    } else if (timeDifference.inMinutes > 1 && timeDifference.inMinutes < 30) {
      timeString = '${timeDifference.inMinutes} min';
      color = Colors.green;
    } else if (timeDifference.inMinutes >= 30 && timeDifference.inHours < 1) {
      timeString = '${timeDifference.inMinutes} min';
      color = Colors.orange;
    } else if (timeDifference.inHours == 1 && timeDifference.inDays < 1) {
      timeString = '1 hour';
      color = Colors.orange;
    } else if (timeDifference.inHours > 1 && timeDifference.inDays < 1) {
      timeString = '${timeDifference.inHours} hours';
      color = Colors.red;
    } else if (timeDifference.inDays == 1) {
      timeString = '1 day';
      color = Colors.red;
    } else {
      timeString = '${timeDifference.inDays} days';
      color = Colors.red;
    }
    return Row(
      children: <Widget>[
        Icon(
          Icons.access_time,
          size: 14,
          color: color,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 5),
          child: Text(
            timeString,
            style: TextStyle(color: color),
          ),
        ),
      ],
    );
  }

  Future _getFooterInformation() async {
    try {
      // Get the stock
      var firestoreData = await firestore.getStockInformation(_codeName);

      // Chart date
      var firestoreMap = firestoreData
          .data()['periodicMap']
          .map((k, v) => MapEntry(int.parse(k), v));

      _periodicMap =
          SplayTreeMap<int, int>.from(firestoreMap, (a, b) => a.compareTo(b));

      // RESTOCK AVERAGE AND RELIABILITY
      List restock = firestoreData.data()['restockElapsed'].toList();
      if (restock.length > 0) {
        var sum = 0;
        for (var res in restock) sum += res;
        _averageTimeToRestock = sum ~/ restock.length;

        var twentyPercent = _averageTimeToRestock * 0.2;
        var insideTenPercentAverage = 0;
        for (var res in restock) {
          if ((_averageTimeToRestock + twentyPercent > res) &&
              (_averageTimeToRestock - twentyPercent < res)) {
            insideTenPercentAverage++;
          }
        }
        // We need a minimum number of restocks to give credibility
        if (restock.length > 5) {
          _restockReliability = insideTenPercentAverage * 100 ~/ restock.length;
        } else {
          _restockReliability = 0;
        }
      }

      // TIMES TO RESTOCK
      var lastEmpty = firestoreData.data()['lastEmpty'];
      var lastEmptyDateTime =
          DateTime.fromMillisecondsSinceEpoch(lastEmpty * 1000);
      _projectedRestockDateTime =
          lastEmptyDateTime.add(Duration(seconds: _averageTimeToRestock));

      // CURRENT DEPLETION TREND
      if (widget.foreignStock.quantity > 0) {
        var inverseList = [];
        var inverseMap =
            SplayTreeMap<int, int>.from(firestoreMap, (a, b) => b.compareTo(a));
        inverseMap.entries
            .forEach((e) => inverseList.add("${e.key}, ${e.value}"));
        var currentTimestamp = int.parse((inverseList[0].split(","))[0]);
        var currentQuantity = int.parse((inverseList[0].split(","))[1]);
        var fullTimestamp = 0;
        var fullQuantity = 0;
        // We look from now until the last full quantity (list comes from reversed map)
        for (var i = 0; i < inverseList.length; i++) {
          var qty = int.parse((inverseList[i].split(","))[1]);
          var ts = int.parse((inverseList[i].split(","))[0]);
          if (qty == 0) break;
          fullQuantity = qty;
          fullTimestamp = ts;
        }
        var quantityVariation = fullQuantity - currentQuantity;
        var secondsInVariation = currentTimestamp - fullTimestamp;

        var ratio = quantityVariation / secondsInVariation;
        if (ratio > 0) {
          _depletionTrendPerSecond = ratio;
        }
      }

      setState(() {
        _footerSuccessful = true;
      });
    } catch (e) {
      setState(() {
        _footerSuccessful = false;
      });
    }
  }

  LineChartData _mainChartData() {
    var spots = <FlSpot>[];
    double count = 0;
    double maxY = 0;
    var timestamps = <int>[];

    _periodicMap.forEach((key, value) {
      spots.add(FlSpot(count, value.toDouble()));
      timestamps.add(key);
      if (value > maxY) maxY = value.toDouble();
      count++;
    });

    double interval;
    if (maxY > 1000) {
      interval = 1000;
    } else if (maxY > 200 && maxY <= 1000) {
      interval = 200;
    } else if (maxY > 20 && maxY <= 200) {
      interval = 20;
    } else {
      interval = 2;
    }

    return LineChartData(
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: false,
            tooltipBgColor: Colors.blueGrey.withOpacity(1),
            getTooltipItems: (value) {
              var tooltips = <LineTooltipItem>[];
              for (var spot in value) {
                // Get time
                var ts = 0;
                var timesList = [];
                _periodicMap.entries.forEach((e) => timesList.add("${e.key}"));
                var x = spot.x.toInt();
                if (x > timesList.length) {
                  x = timesList.length;
                }
                ts = int.parse(timesList[x]);
                var date = DateTime.fromMillisecondsSinceEpoch(ts * 1000);

                LineTooltipItem thisItem = LineTooltipItem(
                  "${spot.y.toInt()} items"
                  "\nat ${_timeFormatter(date)}",
                  TextStyle(
                    fontSize: 12,
                  ),
                );
                tooltips.add(thisItem);
              }

              return tooltips;
            }),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: _themeProvider.currentTheme == AppTheme.dark
                ? Colors.blueGrey
                : const Color(0xff37434d),
            strokeWidth: 0.4,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: SideTitles(
          rotateAngle: -70,
          showTitles: true,
          interval: _periodicMap.length > 12 ? _periodicMap.length / 12 : null,
          reservedSize: 20,
          margin: _settingsProvider.currentTimeFormat == TimeFormatSetting.h12
              ? 45
              : 30,
          getTextStyles: (xValue) {
            if (xValue.toInt() >= _periodicMap.length) {
              xValue = xValue - 1;
            }
            var date = DateTime.fromMillisecondsSinceEpoch(
                timestamps[xValue.toInt()] * 1000);
            var difference = DateTime.now().difference(date).inHours;

            Color myColor = Colors.transparent;
            if (difference < 24) {
              myColor = Colors.green;
            } else {
              myColor = Colors.blue;
            }
            return TextStyle(
              color: myColor,
              fontSize: 10,
            );
          },
          getTitles: (xValue) {
            if (xValue.toInt() >= _periodicMap.length) {
              xValue = xValue - 1;
            }
            var date = DateTime.fromMillisecondsSinceEpoch(
                timestamps[xValue.toInt()] * 1000);
            return _timeFormatter(date);
          },
        ),
        leftTitles: SideTitles(
          showTitles: true,
          interval: interval,
          reservedSize: 10,
          margin: 12,
          getTextStyles: (value) => TextStyle(
            color: _themeProvider.currentTheme == AppTheme.dark
                ? Colors.blueGrey
                : const Color(0xff67727d),
            fontSize: 10,
          ),
          getTitles: (yValue) {
            if (maxY > 1000) {
              return "${(yValue / 1000).truncate().toStringAsFixed(0)}K";
            }
            return yValue.floor().toString();
          },
        ),
      ),
      borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xff37434d), width: 1)),
      minX: 0,
      maxX: _periodicMap.length.toDouble(),
      minY: 0,
      maxY: maxY + maxY * 0.1,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: false,
          colors: gradientColors,
          barWidth: 1.5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: false,
          ),
          belowBarData: BarAreaData(
            show: true,
            colors:
                gradientColors.map((color) => color.withOpacity(0.3)).toList(),
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    return "${twoDigits(duration.inHours)}h ${twoDigitMinutes}m";
  }

  void _calculateDetails() {
    _travelSeconds = TravelTimes.travelTimeMinutesOneWay(
          ticket: widget.ticket,
          country: widget.foreignStock.country,
        ) *
        60;
    _earliestArrival = DateTime.now().add(Duration(seconds: _travelSeconds));

    if (widget.inventoryEnabled) {
      for (var invItem in widget.inventoryModel.inventory) {
        if (invItem.id == widget.foreignStock.id) {
          _invQuantity = invItem.quantity;
          break;
        }
      }
    }
  }

  Future<void> _showDelayedTravelDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0.0,
          backgroundColor: Colors.transparent,
          content: DelayedTravelDialog(
            stockName: widget.foreignStock.name,
            boardingTime: _delayedDepartureTime,
            country: _countryFullName,
            stockCodeName: _codeName,
            itemId: widget.foreignStock.id,
            countryId: widget.foreignStock.country.index,
          ),
        );
      },
    );
  }

  String _timeFormatter(DateTime time) {
    return TimeFormatter(
      inputTime: time,
      timeFormatSetting: _settingsProvider.currentTimeFormat,
      timeZoneSetting: _settingsProvider.currentTimeZone,
    ).format;
  }

  void _timerUpdate() {
    setState(() {
      _calculateDetails();
    });
  }
}
