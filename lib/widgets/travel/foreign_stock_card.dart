// Dart imports:
import 'dart:async';
import "dart:collection";
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;

// Package imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:expandable/expandable.dart';
import 'package:fl_chart/fl_chart.dart';
// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:torn_pda/models/profile/own_profile_model.dart';
// Project imports:
import 'package:torn_pda/models/travel/foreign_stock_in.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/firebase_firestore.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/utils/time_formatter.dart';
import 'package:torn_pda/utils/travel/profit_formatter.dart';
import 'package:torn_pda/utils/travel/travel_times.dart';
import 'package:torn_pda/widgets/travel/delayed_travel_dialog.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';

class ForeignStockCard extends StatefulWidget {
  final ForeignStock foreignStock;
  final bool inventoryEnabled;
  final bool showArrivalTime;
  final bool showBarsCooldownAnalysis;
  final int? capacity;
  final OwnProfileExtended? profile;
  final Function flagPressedCallback;
  final Function requestMoneyRefresh;
  final Function(ForeignStock) memberHiddenCallback;
  final TravelTicket? ticket;
  final Map<String, dynamic>? activeRestocks;

  final int? travelingTimeStamp;
  final CountryName travelingCountry;
  final String? travelingCountryFullName;

  final bool displayShowcase;

  const ForeignStockCard({
    required this.foreignStock,
    required this.inventoryEnabled,
    required this.showArrivalTime,
    required this.showBarsCooldownAnalysis,
    required this.capacity,
    required this.profile,
    required this.flagPressedCallback,
    required this.requestMoneyRefresh,
    required this.memberHiddenCallback,
    required this.ticket,
    required this.activeRestocks,
    required this.travelingTimeStamp,
    required this.travelingCountry,
    required this.travelingCountryFullName,
    required this.displayShowcase,
    required Key key,
  }) : super(key: key);

  @override
  ForeignStockCardState createState() => ForeignStockCardState();
}

class ForeignStockCardState extends State<ForeignStockCard> {
  final _expandableController = ExpandableController();

  Future? _footerInformationRetrieved;
  bool _footerSuccessful = false;
  String errorReason = "";

  var _periodicMap = SplayTreeMap();

  var _averageTimeToRestock = 0;
  var _restockReliability = 0;
  var _projectedRestockDateTime = DateTime.now();
  var _depletionTrendPerSecond = 0.0;

  int? _invQuantity = 0;

  var _delayedDepartureTime = DateTime.now();
  String _codeName = "";

  DateTime _earliestArrival = DateTime.now();
  int _travelSeconds = 0;

  DateTime _earliestBackToTorn = DateTime.now();

  late Stream _browserHasClosed;
  late StreamSubscription _browserHasClosedSubscription;

  // Used for mid-trip calculations
  bool _flyingToThisCountry = false;
  bool _flyingElsewhere = false;
  bool _landedInWidgetCountry = false;
  String _tripExplanatory = "";

  late SettingsProvider _settingsProvider;
  late ThemeProvider _themeProvider;

  List<Color> gradientColors = [
    const Color(0xff23b6e6),
    const Color(0xff02d39a),
  ];

  Timer? _ticker;

  // Showcases
  final GlobalKey _showcaseMoneyIcon = GlobalKey();
  final GlobalKey _showcaseFlagIcon = GlobalKey();
  final GlobalKey _showcaseExpandIcon = GlobalKey();
  final GlobalKey _showcaseHideStock = GlobalKey();

  bool _cashCheckPressed = false;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _calculateDetails();
    _themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    _expandableController.addListener(() {
      if (_expandableController.expanded == true && !_footerSuccessful) {
        _footerInformationRetrieved = _getFooterInformation();
      }
    });

    _ticker = Timer.periodic(const Duration(minutes: 1), (Timer t) => _timerUpdate());

    // Build code name
    _codeName = "${widget.foreignStock.countryCode}-${widget.foreignStock.name}";

    // Join a stream that will notify when the browser closes (a browser initiated in Profile or elsewhere)
    // So that we can 1) refresh the API, 2) start the API timer again
    final WebViewProvider webViewProvider = context.read<WebViewProvider>();
    _browserHasClosed = webViewProvider.browserHasClosedStream.stream;
    _browserHasClosedSubscription = _browserHasClosed.listen((event) {
      if (_cashCheckPressed) {
        log("Browser has closed in Foreign Stocks, refreshing money!");
        _refreshMoney();
        _cashCheckPressed = false;
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _expandableController.dispose();
    _browserHasClosedSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      builder: (_) {
        _launchShowCases(_);
        return Slidable(
          startActionPane: ActionPane(
            motion: const DrawerMotion(),
            children: [
              SlidableAction(
                label: 'Hide',
                backgroundColor: Colors.blue,
                icon: MdiIcons.eyeRemoveOutline,
                onPressed: (context) {
                  widget.memberHiddenCallback(widget.foreignStock);
                },
              ),
            ],
          ),
          child: Card(
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: widget.activeRestocks!.keys.contains(_codeName) ? Colors.blue : Colors.transparent,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Row(
              children: [
                Showcase(
                  key: _showcaseHideStock,
                  title: 'Swipe to hide',
                  description: "\nSwipe right to hide stocks you don't want to see.\n\nYou can restore them "
                      "later at any time by using the 'eye' icon in the app bar.",
                  targetPadding: const EdgeInsets.all(10),
                  disableMovingAnimation: true,
                  textColor: _themeProvider.mainText,
                  tooltipBackgroundColor: _themeProvider.secondBackground,
                  descTextStyle: const TextStyle(fontSize: 13),
                  tooltipPadding: const EdgeInsets.all(20),
                  child: const SizedBox(height: 80),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ExpandablePanel(
                      collapsed: Container(),
                      controller: _expandableController,
                      theme: const ExpandableThemeData(
                        hasIcon: false,
                      ),
                      header: _header(),
                      expanded: _footer(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _launchShowCases(BuildContext _) async {
    if (!widget.displayShowcase) return;
    await Future.delayed(const Duration(seconds: 1), () async {
      if (!mounted) return;

      final List showCases = <GlobalKey<State<StatefulWidget>>>[];

      if (!_settingsProvider.showCases.contains("foreign_flagIcon")) {
        _settingsProvider.addShowCase = "foreign_flagIcon";
        showCases.add(_showcaseFlagIcon);
      }

      if (!_settingsProvider.showCases.contains("foreign_moneyIcon")) {
        _settingsProvider.addShowCase = "foreign_moneyIcon";
        showCases.add(_showcaseMoneyIcon);
      }

      if (!_settingsProvider.showCases.contains("foreign_expandIcon")) {
        _settingsProvider.addShowCase = "foreign_expandIcon";
        showCases.add(_showcaseExpandIcon);
      }

      if (!_settingsProvider.showCases.contains("foreign_swipeToHide")) {
        _settingsProvider.addShowCase = "foreign_swipeToHide";
        showCases.add(_showcaseHideStock);
      }

      if (showCases.isNotEmpty) {
        ShowCaseWidget.of(_).startShowCase(showCases as List<GlobalKey<State<StatefulWidget>>>);
      }
    });
  }

  Widget _header() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _firstRow(widget.foreignStock),
                  const SizedBox(height: 10),
                  _secondRow(widget.foreignStock),
                ],
              ),
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
        reliabilityColor = _themeProvider.getTextColor(Colors.red);
      } else if (_restockReliability >= 33 && _restockReliability < 66) {
        reliability = "medium";
        reliabilityColor = _themeProvider.getTextColor(Colors.orangeAccent);
      } else if (_restockReliability >= 66 && _restockReliability < 80) {
        reliability = "medium-high";
        reliabilityColor = _themeProvider.getTextColor(Colors.green);
      } else {
        reliability = "high";
        reliabilityColor = _themeProvider.getTextColor(Colors.green);
      }
    }

    // WHEN TO TRAVEL
    var whenToTravel = "";
    var arrivalTime = "";
    var depletesTime = "";
    Color? whenToTravelColor = _themeProvider.mainText;

    bool delayDeparture = false;

    // Calculates when to leave, taking into account:
    //  - If there are items: arrive before depletion
    //  - If there are no items: arrive when restock happens
    //  - Does NOT take into account a restock that depletes quickly

    if (_earliestArrival.isAfter(_projectedRestockDateTime) || widget.foreignStock.quantity! > 0) {
      // Checks > 0 in case restock has happened already

      delayDeparture = false;

      // Avoid dividing by 0 if we have no trend
      if (widget.foreignStock.quantity! > 0 && _depletionTrendPerSecond > 0) {
        final secondsToDeplete = widget.foreignStock.quantity! / _depletionTrendPerSecond;

        // If depleting very slowly (more than a day)
        if (secondsToDeplete > 86400) {
          whenToTravel = "Travel NOW";
          depletesTime = "Depletes in more than a day";
        }
        // If we won't arrive before depletion
        else {
          final depletionDateTime = DateTime.now().add(Duration(seconds: secondsToDeplete.round()));
          if (_earliestArrival.isAfter(depletionDateTime)) {
            whenToTravel = "Caution, depletes at ${_timeFormatter(depletionDateTime)}";
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
        if (widget.foreignStock.quantity! > 0 || average != "unknown") {
          whenToTravel = "Travel NOW";
        }
      }
      arrivalTime = "You will be there at ${_timeFormatter(_earliestArrival)}";
    }
    // If we arrive before restock if we depart now
    else {
      delayDeparture = true;

      final additionalWait = _projectedRestockDateTime.difference(_earliestArrival).inSeconds;

      _delayedDepartureTime = DateTime.now().add(Duration(seconds: additionalWait));

      whenToTravel = "Travel at ${_timeFormatter(_delayedDepartureTime)}";
      if (_delayedDepartureTime.difference(DateTime.now()).inHours > 24) {
        whenToTravel += " on ${_dateFormatter(_delayedDepartureTime)}";
      }
      final delayedArrival = _delayedDepartureTime.add(Duration(seconds: _travelSeconds));
      arrivalTime = "You will be there at ${_timeFormatter(delayedArrival)}";
      if (delayedArrival.difference(DateTime.now()).inHours > 24) {
        arrivalTime += " on ${_dateFormatter(delayedArrival)}";
      }
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
                  if (_flyingElsewhere || _flyingToThisCountry)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                _tripExplanatory,
                                style: const TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (depletesTime.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              depletesTime,
                              style: const TextStyle(
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        if (delayDeparture)
                          IconButton(
                            iconSize: 22,
                            icon: const Icon(Icons.notifications_none),
                            onPressed: () {
                              _showDelayedTravelDialog();
                            },
                          ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              whenToTravel,
                              style: TextStyle(fontSize: 12, color: whenToTravelColor),
                            ),
                            if (depletesTime.isNotEmpty)
                              Text(
                                depletesTime,
                                style: const TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                            Text(
                              arrivalTime,
                              style: const TextStyle(
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  const SizedBox(height: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Average restock time: $average",
                        style: const TextStyle(
                          fontSize: 12,
                        ),
                      ),
                      if (widget.foreignStock.quantity == 0)
                        Row(
                          children: [
                            const Flexible(
                              child: Text(
                                "Next restock might happen at: ",
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            Text(
                              _projectedRestockDateTime.isAfter(DateTime.now().add(const Duration(days: 7))) ||
                                      _projectedRestockDateTime.isBefore(DateTime.now().toLocal())
                                  ? 'unknown'
                                  : TimeFormatter(
                                      inputTime: _projectedRestockDateTime,
                                      timeFormatSetting: _settingsProvider.currentTimeFormat,
                                      timeZoneSetting: _settingsProvider.currentTimeZone,
                                    ).formatHourWithDaysElapsed(includeToday: true),
                              style: TextStyle(
                                fontSize: 12,
                                color: reliabilityColor,
                              ),
                            ),
                          ],
                        ),
                      if (reliability.isNotEmpty)
                        Row(
                          children: [
                            const Text(
                              "Reliability: ",
                              style: TextStyle(
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              reliability,
                              style: TextStyle(
                                fontSize: 12,
                                color: reliabilityColor,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  if (widget.showBarsCooldownAnalysis) _affectedBars(),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    width: 600,
                    child: LineChart(_mainChartData()),
                  ),
                  SizedBox(height: _settingsProvider.currentTimeFormat == TimeFormatSetting.h12 ? 60 : 40),
                  Text(
                    // Only include more than 0 per hour and
                    (_depletionTrendPerSecond * 3600).floor() > 0 && _depletionTrendPerSecond < 86400
                        ? "Depletion rate: ${(_depletionTrendPerSecond * 3600).floor()}/hour"
                        : "Depletion rate: unknown",
                    style: const TextStyle(
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 15),
                  if (!Platform.isWindows)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                      child: CheckboxListTile(
                        checkColor: Colors.white,
                        activeColor: Colors.blue,
                        value: widget.activeRestocks!.keys.contains(_codeName) ? true : false,
                        title: const Text(
                          "Restock alert (auto)",
                          style: TextStyle(
                            fontSize: 12,
                          ),
                        ),
                        subtitle: Text(
                          "Get notified whenever ${widget.foreignStock.name} is restocked in "
                          "${widget.foreignStock.countryFullName}",
                          style: const TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        onChanged: (ticked) async {
                          if (ticked!) {
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
            String errorMessage = "There is an issue contacting the server, please try again later";
            Color errorColor = _themeProvider.getTextColor(Colors.red);

            if (errorReason.contains("cannot get field")) {
              errorMessage = "There's no further information for this item yet!\n\nIt could be an issue with the "
                  "server or either a very rare item that hasn't been reported a minumum number of times.";
              errorColor = _themeProvider.getTextColor(Colors.orange);
            }

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                errorMessage,
                style: TextStyle(
                  color: errorColor,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            );
          }
        } else {
          return const Center(
            child: Padding(
              padding: EdgeInsets.fromLTRB(8, 20, 8, 8),
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }

  Future _addToActiveRestockAlerts() async {
    final time = DateTime.now().millisecondsSinceEpoch;
    if (!widget.activeRestocks!.keys.contains(_codeName)) {
      Map<String, dynamic> tempMap = widget.activeRestocks!;
      tempMap.addAll({_codeName: time});
      FirestoreHelper().updateActiveRestockAlerts(tempMap).then((success) async {
        if (success) {
          setState(() {
            widget.activeRestocks!.addAll({_codeName: time});
          });
          Prefs().setActiveRestocks(json.encode(tempMap));

          final alertsEnabled = await Prefs().getRestocksNotificationEnabled();
          if (!alertsEnabled) {
            BotToast.showText(
              text: "Your restocks notifications are OFF, remember to active "
                  "them in the Alerts section!",
              textStyle: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
              contentColor: _themeProvider.getTextColor(Colors.orange[700]),
              duration: const Duration(seconds: 4),
              contentPadding: const EdgeInsets.all(10),
            );
          }
        }
      });
    }
  }

  Future _removeToActiveRestockAlerts() async {
    if (widget.activeRestocks!.keys.contains(_codeName)) {
      Map<String, dynamic> tempMap = widget.activeRestocks!;
      tempMap.removeWhere((key, value) => key == _codeName);
      FirestoreHelper().updateActiveRestockAlerts(tempMap).then((success) {
        if (success) {
          setState(() {
            widget.activeRestocks!.removeWhere((key, value) => key == _codeName);
          });
          Prefs().setActiveRestocks(json.encode(tempMap));
        }
      });
    }
  }

  Row _firstRow(ForeignStock stock) {
    return Row(
      children: <Widget>[
        Image.asset('images/torn_items/small/${stock.id}_small.png'),
        const Padding(
          padding: EdgeInsets.only(right: 10),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(stock.name!),
            ),
            if (widget.inventoryEnabled && _invQuantity != null)
              SizedBox(
                width: 100,
                child: Text(
                  "Inv: x$_invQuantity",
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            if (widget.showArrivalTime) _arrivalTime(),
          ],
        ),
        const Padding(
          padding: EdgeInsets.only(right: 15),
        ),
        SizedBox(
          width: 55,
          child: Text(
            'x${stock.quantity}',
            style: TextStyle(
              color: stock.quantity! > 0
                  ? _themeProvider.getTextColor(Colors.green)
                  : _themeProvider.getTextColor(Colors.red),
              fontWeight: stock.quantity! > 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        _returnLastUpdated(),
      ],
    );
  }

  Widget _secondRow(ForeignStock stock) {
    // Travel time per hour, round trip

    // We recalculate profit here so that it changes with capacity or ticket type
    // in realtime. The profit that came from the parent was only for sorting just
    // after retrieving data
    stock.profit = (stock.value /
            (TravelTimes.travelTimeMinutesOneWay(
                  ticket: widget.ticket,
                  countryCode: widget.foreignStock.country,
                ) *
                2 /
                60))
        .round();

    // Currency configuration
    final costCurrency = NumberFormat("#,##0", "en_US");

    // Item cost
    Widget costWidget;
    String moneyToBuy = '';
    String moneyToBuyExtra = '';
    Color? moneyToBuyColor = Colors.grey;
    if (widget.profile!.moneyOnHand! >= stock.cost! * widget.capacity!) {
      moneyToBuy = 'You have the \$${costCurrency.format(stock.cost! * widget.capacity!)} necessary to '
          'buy ${widget.capacity} ${stock.name}';
      moneyToBuyColor = Colors.green[800];
      costWidget = Row(
        children: [
          GestureDetector(
            child: Showcase(
              key: _showcaseMoneyIcon,
              title: 'Quick money check',
              description: '\nTap to see if you need to carry some more money before your departure.'
                  ' If you do, tap the safe to vault icon to access it in game.',
              targetPadding: const EdgeInsets.all(10),
              disableMovingAnimation: true,
              textColor: _themeProvider.mainText,
              tooltipBackgroundColor: _themeProvider.secondBackground,
              descTextStyle: const TextStyle(fontSize: 13),
              tooltipPadding: const EdgeInsets.all(20),
              child: Icon(
                MdiIcons.cash,
                color: moneyToBuyColor,
              ),
            ),
            onTap: () {
              BotToast.showText(
                text: moneyToBuy,
                textStyle: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
                contentColor: _themeProvider.getTextColor(moneyToBuyColor),
                duration: const Duration(seconds: 4),
                contentPadding: const EdgeInsets.all(10),
              );
            },
          ),
          const SizedBox(width: 5),
          _stockCostColumn(costCurrency, stock),
        ],
      );
    } else {
      final howMany = (widget.profile!.moneyOnHand! / stock.cost!).floor();
      final String howManyString = howMany == 0 ? "cannot buy a single" : "can only buy $howMany";
      moneyToBuy = 'You $howManyString ${stock.name} with the money you have.';
      moneyToBuyExtra = 'You need '
          '\$${costCurrency.format((stock.cost! * widget.capacity!) - widget.profile!.moneyOnHand!)} more '
          '(a total of \$${costCurrency.format(stock.cost! * widget.capacity!)}) to buy ${widget.capacity}.';
      moneyToBuyColor = Colors.orange[800];
      costWidget = Row(
        children: [
          GestureDetector(
            child: Icon(
              MdiIcons.cash,
              color: moneyToBuyColor,
            ),
            onTap: () {
              BotToast.showCustomText(
                duration: const Duration(seconds: 6),
                onlyOne: true,
                clickClose: true,
                crossPage: false,
                animationDuration: const Duration(milliseconds: 200),
                animationReverseDuration: const Duration(milliseconds: 200),
                toastBuilder: (_) => Padding(
                  padding: const EdgeInsets.all(30),
                  child: Card(
                    color: moneyToBuyColor,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              moneyToBuy,
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Flexible(
                            child: Text(
                              moneyToBuyExtra,
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            child: Image.asset(
                              'images/icons/home/vault.png',
                              width: 40,
                              height: 40,
                              color: Colors.white,
                            ),
                            onTap: () {
                              _openWalletDialog();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 5),
          _stockCostColumn(costCurrency, stock),
        ],
      );
    }

    // Profit and profit per hour
    Widget profitWidget;
    Widget profitPerMinuteWidget;
    final profitColor =
        stock.value <= 0 ? _themeProvider.getTextColor(Colors.red) : _themeProvider.getTextColor(Colors.green);

    String profitFormatted = formatProfit(inputInt: stock.value.abs());
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
    String profitPerHourFormatted = formatProfit(inputInt: (stock.profit * widget.capacity!).abs());
    if (stock.profit <= 0) {
      profitPerHourFormatted = '-\$$profitPerHourFormatted';
    } else {
      profitPerHourFormatted = '+\$$profitPerHourFormatted';
    }

    profitPerMinuteWidget = Text(
      '($profitPerHourFormatted/hour)',
      style: TextStyle(color: profitColor, fontSize: 11),
    );

    return Row(
      children: <Widget>[
        Flexible(flex: 2, child: costWidget),
        const SizedBox(width: 8),
        Flexible(child: profitWidget),
        const SizedBox(width: 8),
        Flexible(flex: 2, child: profitPerMinuteWidget),
      ],
    );
  }

  Flexible _stockCostColumn(NumberFormat costCurrency, ForeignStock stock) {
    return Flexible(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\$${costCurrency.format(stock.cost)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            '(\$${costCurrency.format(stock.cost! * widget.capacity!)})',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _countryFlagAndArrow(ForeignStock stock) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        GestureDetector(
          child: Showcase(
            key: _showcaseFlagIcon,
            title: 'Travel Agency',
            description: '\nTap any flag to access the Travel Agency directly from this section!',
            targetPadding: const EdgeInsets.all(10),
            disableMovingAnimation: true,
            textColor: _themeProvider.mainText,
            tooltipBackgroundColor: _themeProvider.secondBackground,
            descTextStyle: const TextStyle(fontSize: 13),
            tooltipPadding: const EdgeInsets.all(20),
            child: CountryCodeAndFlag(stock: stock),
          ),
          onLongPress: () {
            _launchMoneyWarning(stock);
            widget.flagPressedCallback(true, false);
          },
          onTap: () {
            _launchMoneyWarning(stock);
            widget.flagPressedCallback(true, true);
          },
        ),
        Showcase(
          key: _showcaseExpandIcon,
          title: 'Detailed view',
          description: '\nClick to expand the item card and learn more details about your travel and stock!',
          targetPadding: const EdgeInsets.all(10),
          disableMovingAnimation: true,
          textColor: _themeProvider.mainText,
          tooltipBackgroundColor: _themeProvider.secondBackground,
          descTextStyle: const TextStyle(fontSize: 13),
          tooltipPadding: const EdgeInsets.all(20),
          child: const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Icon(Icons.keyboard_arrow_down_outlined),
          ),
        ),
      ],
    );
  }

  void _launchMoneyWarning(ForeignStock stock) {
    // Currency configuration
    final costCurrency = NumberFormat("#,##0", "en_US");

    final moneyOnHand = widget.profile!.moneyOnHand!;
    String moneyToBuy = '';
    Color moneyToBuyColor = Colors.grey;
    if (moneyOnHand >= stock.cost! * widget.capacity!) {
      moneyToBuy = 'You HAVE the \$${costCurrency.format(stock.cost! * widget.capacity!)} necessary to '
          'buy ${widget.capacity} ${stock.name}';
      moneyToBuyColor = _themeProvider.getTextColor(Colors.green);
    } else {
      moneyToBuy = 'You DO NOT HAVE the \$${costCurrency.format(stock.cost! * widget.capacity!)} '
          'necessary to buy ${widget.capacity} ${stock.name}. Add another '
          '\$${costCurrency.format((stock.cost! * widget.capacity!) - moneyOnHand)}';
      moneyToBuyColor = _themeProvider.getTextColor(Colors.red);
    }

    BotToast.showText(
      clickClose: true,
      text: moneyToBuy,
      textStyle: const TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
      contentColor: moneyToBuyColor,
      duration: const Duration(seconds: 4),
      contentPadding: const EdgeInsets.all(10),
    );
  }

  Row _returnLastUpdated() {
    final inputTime = DateTime.fromMillisecondsSinceEpoch(widget.foreignStock.timestamp! * 1000);
    final timeDifference = DateTime.now().difference(inputTime);
    String timeString;
    Color color;
    if (timeDifference.inMinutes < 1) {
      timeString = 'now';
      color = _themeProvider.getTextColor(Colors.green);
    } else if (timeDifference.inMinutes == 1 && timeDifference.inHours < 1) {
      timeString = '1 min';
      color = _themeProvider.getTextColor(Colors.green);
    } else if (timeDifference.inMinutes > 1 && timeDifference.inMinutes < 30) {
      timeString = '${timeDifference.inMinutes} min';
      color = _themeProvider.getTextColor(Colors.green);
    } else if (timeDifference.inMinutes >= 30 && timeDifference.inHours < 1) {
      timeString = '${timeDifference.inMinutes} min';
      color = _themeProvider.getTextColor(Colors.orange);
    } else if (timeDifference.inHours == 1 && timeDifference.inDays < 1) {
      timeString = '1 hour';
      color = _themeProvider.getTextColor(Colors.orange);
    } else if (timeDifference.inHours > 1 && timeDifference.inDays < 1) {
      timeString = '${timeDifference.inHours} hours';
      color = _themeProvider.getTextColor(Colors.red);
    } else if (timeDifference.inDays == 1) {
      timeString = '1 day';
      color = _themeProvider.getTextColor(Colors.red);
    } else {
      timeString = '${timeDifference.inDays} days';
      color = _themeProvider.getTextColor(Colors.red);
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
      final firestoreData = await FirestoreHelper().getStockInformation(_codeName);

      // Chart date
      final responseMap = firestoreData.get('periodicMap');
      Map<int, int> firestoreMap = <int, int>{};
      responseMap.forEach((key, value) {
        firestoreMap.putIfAbsent(int.parse(key), () => value);
      });

      _periodicMap = SplayTreeMap<int, int>.from(firestoreMap, (a, b) => a.compareTo(b));

      // RESTOCK AVERAGE AND RELIABILITY
      final restockList = firestoreData.get('restockElapsed');

      if (restockList.length > 0) {
        var sum = 0;
        for (final int res in restockList) {
          sum += res;
        }
        _averageTimeToRestock = sum ~/ restockList.length;

        final twentyPercent = _averageTimeToRestock * 0.2;
        var insideTenPercentAverage = 0;
        for (final res in restockList) {
          if ((_averageTimeToRestock + twentyPercent > res) && (_averageTimeToRestock - twentyPercent < res)) {
            insideTenPercentAverage++;
          }
        }
        // We need a minimum number of restocks to give credibility
        if (restockList.length > 5) {
          _restockReliability = insideTenPercentAverage * 100 ~/ restockList.length;
        } else {
          _restockReliability = 0;
        }
      }

      // TIMES TO RESTOCK
      final lastEmpty = firestoreData.get('lastEmpty');
      final lastEmptyDateTime = DateTime.fromMillisecondsSinceEpoch(lastEmpty * 1000);
      _projectedRestockDateTime = lastEmptyDateTime.add(Duration(seconds: _averageTimeToRestock));

      // CURRENT DEPLETION TREND
      if (widget.foreignStock.quantity! > 0) {
        final inverseList = [];
        final inverseMap = SplayTreeMap<int, int>.from(firestoreMap, (a, b) => b.compareTo(a));
        for (final e in inverseMap.entries) {
          inverseList.add("${e.key}, ${e.value}");
        }
        final currentTimestamp = int.parse(inverseList[0].split(",")[0]);
        final currentQuantity = int.parse(inverseList[0].split(",")[1]);
        var fullTimestamp = 0;
        var fullQuantity = 0;
        // We look from now until the last full quantity (list comes from reversed map)
        for (var i = 0; i < inverseList.length; i++) {
          final qty = int.parse(inverseList[i].split(",")[1]);
          final ts = int.parse(inverseList[i].split(",")[0]);
          if (qty == 0) break;
          fullQuantity = qty;
          fullTimestamp = ts;
        }
        final quantityVariation = fullQuantity - currentQuantity;
        final secondsInVariation = currentTimestamp - fullTimestamp;

        final ratio = quantityVariation / secondsInVariation;
        if (ratio > 0) {
          _depletionTrendPerSecond = ratio;
        }
      }

      setState(() {
        _footerSuccessful = true;
      });
    } catch (e) {
      log(e.toString());
      errorReason = e.toString();
      setState(() {
        _footerSuccessful = false;
      });
    }
  }

  Widget _affectedBars() {
    List<Widget> affected = <Widget>[];
    List<Widget> affectedDelayed = <Widget>[];

    affected.add(
      const Text(
        "Bars/cooldowns (immediate departure):",
        style: TextStyle(
          fontSize: 12,
        ),
      ),
    );

    bool anyAffectation = false;

    final DateTime energyTime = DateTime.now().add(Duration(seconds: widget.profile!.energy!.fulltime!));
    if (energyTime.isBefore(_earliestBackToTorn)) {
      anyAffectation = true;
      final Duration energyGap = _earliestBackToTorn.difference(energyTime);
      affected.add(
        Padding(
          padding: const EdgeInsets.only(left: 5),
          child: Text(
            widget.profile!.energy!.fulltime! == 0 || energyTime.isBefore(DateTime.now())
                ? "- Energy is full"
                : energyGap.inHours > 24
                    ? "- Energy will be full more than a day before your return"
                    : "- Energy will be full ${_formatDuration(energyGap)} before your return",
            style: TextStyle(
              color: _themeProvider.getTextColor(Colors.orange),
              fontSize: 12,
            ),
          ),
        ),
      );
    } else {
      affected.add(
        Padding(
          padding: const EdgeInsets.only(left: 5),
          child: Text(
            "- Energy OK",
            style: TextStyle(
              color: _themeProvider.getTextColor(Colors.green),
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    final DateTime nerveTime = DateTime.now().add(Duration(seconds: widget.profile!.nerve!.fulltime!));
    if (nerveTime.isBefore(_earliestBackToTorn)) {
      anyAffectation = true;
      final Duration nerveGap = _earliestBackToTorn.difference(nerveTime);
      affected.add(
        Padding(
          padding: const EdgeInsets.only(left: 5),
          child: Text(
            widget.profile!.nerve!.fulltime! == 0 || nerveTime.isBefore(DateTime.now())
                ? "- Nerve is full"
                : nerveGap.inHours > 24
                    ? "- Nerve will be full more than a day before your return"
                    : "- Nerve will be full ${_formatDuration(nerveGap)} before your return",
            style: TextStyle(
              color: _themeProvider.getTextColor(Colors.orange),
              fontSize: 12,
            ),
          ),
        ),
      );
    } else {
      affected.add(
        Padding(
          padding: const EdgeInsets.only(left: 5),
          child: Text(
            "- Nerve OK",
            style: TextStyle(
              color: _themeProvider.getTextColor(Colors.green),
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    final DateTime drugsTime = DateTime.now().add(Duration(seconds: widget.profile!.cooldowns!.drug!));
    if (drugsTime.isBefore(_earliestBackToTorn)) {
      anyAffectation = true;
      final Duration drugsGap = _earliestBackToTorn.difference(drugsTime);
      affected.add(
        Padding(
          padding: const EdgeInsets.only(left: 5),
          child: Text(
            widget.profile!.cooldowns!.drug! == 0 || drugsTime.isBefore(DateTime.now())
                ? "- No drug cooldown"
                : drugsGap.inHours > 24
                    ? "- Drug cooldown will be over more than a day before your return"
                    : "- Drug cooldown will be over ${_formatDuration(drugsGap)} before your return",
            style: TextStyle(
              color: _themeProvider.getTextColor(Colors.orange),
              fontSize: 12,
            ),
          ),
        ),
      );
    } else {
      affected.add(
        Padding(
          padding: const EdgeInsets.only(left: 5),
          child: Text(
            "- Drug cooldown OK",
            style: TextStyle(
              color: _themeProvider.getTextColor(Colors.green),
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    final DateTime medicalTime = DateTime.now().add(Duration(seconds: widget.profile!.cooldowns!.medical!));
    if (medicalTime.isBefore(_earliestBackToTorn)) {
      anyAffectation = true;
      final Duration medicalGap = _earliestBackToTorn.difference(medicalTime);
      affected.add(
        Padding(
          padding: const EdgeInsets.only(left: 5),
          child: Text(
            widget.profile!.cooldowns!.medical! == 0 || medicalTime.isBefore(DateTime.now())
                ? "- No medical cooldown"
                : medicalGap.inHours > 24
                    ? "- Medical cooldown will be over more than a day before your return"
                    : "- Medical cooldown will be over ${_formatDuration(medicalGap)} before your return",
            style: TextStyle(
              color: _themeProvider.getTextColor(Colors.orange),
              fontSize: 12,
            ),
          ),
        ),
      );
    } else {
      affected.add(
        Padding(
          padding: const EdgeInsets.only(left: 5),
          child: Text(
            "- Medical cooldown OK",
            style: TextStyle(
              color: _themeProvider.getTextColor(Colors.green),
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    final DateTime boosterTime = DateTime.now().add(Duration(seconds: widget.profile!.cooldowns!.booster!));
    if (boosterTime.isBefore(_earliestBackToTorn)) {
      anyAffectation = true;
      final Duration boosterGap = _earliestBackToTorn.difference(boosterTime);
      affected.add(
        Padding(
          padding: const EdgeInsets.only(left: 5),
          child: Text(
            widget.profile!.cooldowns!.booster! == 0 || boosterTime.isBefore(DateTime.now())
                ? "- No booster cooldown"
                : boosterGap.inHours > 24
                    ? "- Booster cooldown will be over more than a day before your return"
                    : "- Booster cooldown will be over ${_formatDuration(boosterGap)} before your return",
            style: TextStyle(
              color: _themeProvider.getTextColor(Colors.orange),
              fontSize: 12,
            ),
          ),
        ),
      );
    } else {
      affected.add(
        Padding(
          padding: const EdgeInsets.only(left: 5),
          child: Text(
            "- Booster cooldown OK",
            style: TextStyle(
              color: _themeProvider.getTextColor(Colors.green),
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    if (!anyAffectation) {
      affected.add(
        Padding(
          padding: const EdgeInsets.only(left: 5),
          child: Text(
            "No affectation",
            style: TextStyle(
              color: _themeProvider.getTextColor(Colors.green),
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    // DELAYED DEPARTURE
    if (_delayedDepartureTime.isAfter(DateTime.now())) {
      String whenToTravel = "delayed departure: ${_timeFormatter(_delayedDepartureTime)}";
      if (_delayedDepartureTime.difference(DateTime.now()).inHours > 24) {
        whenToTravel += " on ${_dateFormatter(_delayedDepartureTime)}";
      }

      affected.add(
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            "Bars/cooldowns ($whenToTravel):",
            style: const TextStyle(
              fontSize: 12,
            ),
          ),
        ),
      );

      bool anyDelayedAffectation = false;

      final Duration extraTime = _delayedDepartureTime.difference(DateTime.now());
      final DateTime earliestBackToTornDelayed = DateTime.now().add(Duration(seconds: extraTime.inSeconds));

      // Energy delayed
      if (energyTime.isBefore(earliestBackToTornDelayed)) {
        anyDelayedAffectation = true;
        final Duration energyGap = earliestBackToTornDelayed.difference(energyTime);
        affected.add(
          Padding(
            padding: const EdgeInsets.only(left: 5),
            child: Text(
              widget.profile!.energy!.fulltime! == 0 || energyTime.isBefore(DateTime.now())
                  ? "- Energy is full"
                  : energyGap.inHours > 24
                      ? "- Energy will be full more than a day before your return"
                      : "- Energy will be full ${_formatDuration(energyGap)} before your return",
              style: TextStyle(
                color: _themeProvider.getTextColor(Colors.orange),
                fontSize: 12,
              ),
            ),
          ),
        );
      }

      // Nerve delayed
      if (nerveTime.isBefore(earliestBackToTornDelayed)) {
        anyDelayedAffectation = true;
        final Duration nerveGap = earliestBackToTornDelayed.difference(nerveTime);
        affected.add(
          Padding(
            padding: const EdgeInsets.only(left: 5),
            child: Text(
              widget.profile!.nerve!.fulltime! == 0 || nerveTime.isBefore(DateTime.now())
                  ? "- Nerve is full"
                  : nerveGap.inHours > 24
                      ? "- Nerve will be full more than a day before your return"
                      : "- Nerve will be full ${_formatDuration(nerveGap)} before your return",
              style: TextStyle(
                color: _themeProvider.getTextColor(Colors.orange),
                fontSize: 12,
              ),
            ),
          ),
        );
      }

      // Drug delayed
      if (drugsTime.isBefore(earliestBackToTornDelayed)) {
        anyDelayedAffectation = true;
        final Duration drugsGap = earliestBackToTornDelayed.difference(drugsTime);
        affected.add(
          Padding(
            padding: const EdgeInsets.only(left: 5),
            child: Text(
              widget.profile!.cooldowns!.drug! == 0 || drugsTime.isBefore(DateTime.now())
                  ? "- No drug cooldown"
                  : drugsGap.inHours > 24
                      ? "- Drug cooldown will be over more than a day before your return"
                      : "- Drug cooldown will be over ${_formatDuration(drugsGap)} before your return",
              style: TextStyle(
                color: _themeProvider.getTextColor(Colors.orange),
                fontSize: 12,
              ),
            ),
          ),
        );
      }

      // Medical delayed
      if (medicalTime.isBefore(earliestBackToTornDelayed)) {
        anyDelayedAffectation = true;
        final Duration medicalsGap = earliestBackToTornDelayed.difference(medicalTime);
        affected.add(
          Padding(
            padding: const EdgeInsets.only(left: 5),
            child: Text(
              widget.profile!.cooldowns!.medical! == 0 || medicalTime.isBefore(DateTime.now())
                  ? "- No medical cooldown"
                  : medicalsGap.inHours > 24
                      ? "- Medical cooldown will be over more than a day before your return"
                      : "- Medical cooldown will be over ${_formatDuration(medicalsGap)} before your return",
              style: TextStyle(
                color: _themeProvider.getTextColor(Colors.orange),
                fontSize: 12,
              ),
            ),
          ),
        );
      }

      // Booster delayed
      if (boosterTime.isBefore(earliestBackToTornDelayed)) {
        anyDelayedAffectation = true;
        final Duration boostersGap = earliestBackToTornDelayed.difference(boosterTime);
        affected.add(
          Padding(
            padding: const EdgeInsets.only(left: 5),
            child: Text(
              widget.profile!.cooldowns!.booster! == 0 || boosterTime.isBefore(DateTime.now())
                  ? "- No booster cooldown"
                  : boostersGap.inHours > 24
                      ? "- Booster cooldown will be over more than a day before your return"
                      : "- Booster cooldown will be over ${_formatDuration(boostersGap)} before your return",
              style: TextStyle(
                color: _themeProvider.getTextColor(Colors.orange),
                fontSize: 12,
              ),
            ),
          ),
        );
      }

      // No delayed affectation
      if (!anyDelayedAffectation) {
        affected.add(
          Padding(
            padding: const EdgeInsets.only(left: 5),
            child: Text(
              "No affectation",
              style: TextStyle(
                color: _themeProvider.getTextColor(Colors.green),
                fontSize: 12,
              ),
            ),
          ),
        );
      }
    }

    affected.addAll(affectedDelayed);

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: affected,
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _mainChartData() {
    final spots = <FlSpot>[];
    double count = 0;
    double? maxY = 0;
    final timestamps = <int>[];

    // In order to avoid too many zigzags when restocks occur very frequently, we will restrict the data:
    // - If there are <= 5 restocks, we will show all the data (around 24 hours)
    // - If there are more than 5 restocks, we will show the last 12 hours of data

    // Count the restocks
    int restockCount = 0;
    int lastValue = 0;
    _periodicMap.forEach((timestamp, value) {
      if (value > 0 && lastValue == 0) {
        restockCount++;
      }
      lastValue = value;
    });

    // Filter the map if there are more than 5 restocks
    SplayTreeMap<dynamic, dynamic> filteredMap = _periodicMap;
    if (restockCount > 5) {
      // Find the latest timestamp
      int latestTimestamp = _periodicMap.keys.last * 1000;
      // Calculate the timestamp 12 hours before the latest timestamp
      DateTime cutoff = DateTime.fromMillisecondsSinceEpoch(latestTimestamp).subtract(const Duration(hours: 12));
      int cutoffMillis = cutoff.millisecondsSinceEpoch;

      // Ensure that the filtering results in fewer entries than the original map
      filteredMap = SplayTreeMap.fromIterable(
        _periodicMap.entries.where((entry) => entry.key * 1000 >= cutoffMillis),
        key: (entry) => entry.key,
        value: (entry) => entry.value,
      );
    }

    // Update the chart data
    filteredMap.forEach((timestamp, value) {
      spots.add(FlSpot(count, value.toDouble()));
      timestamps.add(timestamp); // Assuming timestamps is a list of DateTime
      if (value > maxY) maxY = value.toDouble();
      count++;
    });

    double interval;
    if (maxY! > 1000) {
      interval = 1000;
    } else if (maxY! > 200 && maxY! <= 1000) {
      interval = 200;
    } else if (maxY! > 20 && maxY! <= 200) {
      interval = 20;
    } else {
      interval = 2;
    }

    return LineChartData(
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          fitInsideHorizontally: true,
          fitInsideVertically: false,
          getTooltipColor: (touchedSpot) => Colors.blueGrey.withOpacity(1),
          getTooltipItems: (value) {
            final tooltips = <LineTooltipItem>[];
            for (final spot in value) {
              // Get time
              var ts = 0;
              final timesList = [];
              for (final e in filteredMap.entries) {
                timesList.add("${e.key}");
              }
              var x = spot.x.toInt();
              if (x > timesList.length) {
                x = timesList.length;
              }
              ts = int.parse(timesList[x]);
              final date = DateTime.fromMillisecondsSinceEpoch(ts * 1000);

              final LineTooltipItem thisItem = LineTooltipItem(
                "${spot.y.toInt()} items"
                "\nat ${_timeFormatter(date)}",
                const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              );
              tooltips.add(thisItem);
            }

            return tooltips;
          },
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: _themeProvider.currentTheme == AppTheme.dark ? Colors.blueGrey : const Color(0xff37434d),
            strokeWidth: 0.4,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        topTitles: const AxisTitles(
          sideTitles: SideTitles(
            showTitles: false,
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(
            showTitles: false,
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: filteredMap.length > 12 ? filteredMap.length / 12 : null,
            reservedSize: 20,
            getTitlesWidget: (xValue, titleMeta) {
              if (xValue.toInt() >= filteredMap.length) {
                xValue = xValue - 1;
              }
              final date = DateTime.fromMillisecondsSinceEpoch(timestamps[xValue.toInt()] * 1000);

              // Style
              TextStyle myStyle;
              if (xValue.toInt() >= filteredMap.length) {
                xValue = xValue - 1;
              }
              final difference = DateTime.now().difference(date).inHours;

              Color myColor = Colors.transparent;
              if (difference < 24) {
                myColor = _themeProvider.getTextColor(Colors.green);
              } else {
                myColor = _themeProvider.getTextColor(Colors.blue);
              }
              myStyle = TextStyle(
                color: myColor,
                fontSize: 10,
              );

              const degrees = -70;
              const radians = degrees * math.pi / 180;

              return Transform.rotate(
                angle: radians,
                child: SizedBox(
                  width: _settingsProvider.currentTimeFormat == TimeFormatSetting.h12 ? 120 : 80,
                  child: Text(
                    _timeFormatter(date)!,
                    style: myStyle,
                  ),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: interval,
            reservedSize: 20,
            getTitlesWidget: (yValue, titleMeta) {
              if (maxY! > 1000) {
                return Text(
                  "${(yValue / 1000).truncate().toStringAsFixed(0)}K",
                  style: TextStyle(
                    color: _themeProvider.currentTheme == AppTheme.dark ? Colors.blueGrey : const Color(0xff67727d),
                    fontSize: 10,
                  ),
                );
              } else if (yValue > 0) {
                return Text(
                  yValue.floor().toString(),
                  style: TextStyle(
                    color: _themeProvider.currentTheme == AppTheme.dark ? Colors.blueGrey : const Color(0xff67727d),
                    fontSize: 10,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(
          color: const Color(0xff37434d),
        ),
      ),
      minX: 0,
      maxX: filteredMap.length.toDouble(),
      minY: 0,
      maxY: maxY! + maxY! * 0.1,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: false,
          gradient: LinearGradient(colors: gradientColors),
          barWidth: 1.5,
          isStrokeCapRound: true,
          dotData: const FlDotData(
            show: false,
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    return "${twoDigits(duration.inHours)}h ${twoDigitMinutes}m";
  }

  _calculateDetails() {
    // INVENTORY
    _invQuantity = widget.foreignStock.inventoryQuantity;

    // ARRIVAL TIMES
    _flyingToThisCountry = false;
    _flyingElsewhere = false;
    _tripExplanatory = "";

    final now = DateTime.now();
    final travelTs = DateTime.fromMillisecondsSinceEpoch(widget.travelingTimeStamp! * 1000);

    // If we are traveling or stopped in another country abroad
    if (travelTs.isAfter(now) || widget.travelingCountry != CountryName.TORN) {
      // If we are in flight to Torn
      if (widget.travelingCountry == CountryName.TORN) {
        _flyingElsewhere = true;
        var timeToTorn = travelTs.difference(now).inSeconds;
        if (timeToTorn < 0) {
          timeToTorn = 0;
          // We are in Torn (after updating without refresh this might happen)
          _flyingElsewhere = false;
        }
        final timeToWidgetCountry = TravelTimes.travelTimeMinutesOneWay(
              ticket: widget.ticket,
              countryCode: widget.foreignStock.country,
            ) *
            60;
        final totalNeeded = timeToWidgetCountry + timeToTorn;
        _earliestArrival = DateTime.now().add(Duration(seconds: totalNeeded));

        _tripExplanatory = "You are flying back to Torn\n\n"
            "${_timeFormatter(_earliestArrival)} is your earliest possible arrival time to "
            "${widget.foreignStock.countryFullName} after you land";

        _earliestBackToTorn = DateTime.now().add(Duration(seconds: timeToWidgetCountry * 2 + timeToTorn));
      }
      // If this stock is in the country we are flying to, just look at time remaining
      else if (widget.travelingCountry == widget.foreignStock.country) {
        _flyingToThisCountry = true;
        var timeToWidgetCountry = travelTs.difference(now).inSeconds;
        if (timeToWidgetCountry < 0) {
          _landedInWidgetCountry = true;
          timeToWidgetCountry = 0;
        }
        _earliestArrival = travelTs;

        // If we want to come back (we only show this in the footer)
        final timeToTornAndBack = TravelTimes.travelTimeMinutesOneWay(
              ticket: widget.ticket,
              countryCode: widget.foreignStock.country,
            ) *
            60 *
            2;
        final totalNeeded = timeToTornAndBack + timeToWidgetCountry;
        final earliestArrivalToSame = DateTime.now().add(Duration(seconds: totalNeeded));

        if (timeToWidgetCountry == 0) {
          _tripExplanatory = "You are visiting ${widget.travelingCountryFullName}\n\n"
              "If you like it here and would like to come back later, ${_timeFormatter(earliestArrivalToSame)} "
              "is your earliest possible return time if you leave now";
        } else {
          _tripExplanatory = "You are flying to ${widget.travelingCountryFullName}\n\n"
              "If you like it there and would like to come back later, ${_timeFormatter(earliestArrivalToSame)} "
              "is your earliest possible return time if you leave quickly";
        }

        _earliestBackToTorn = DateTime.now().add(Duration(seconds: totalNeeded));
      }
      // If we are flying to a different country, account for the whole trip and
      // return flight from the first country
      else if (widget.travelingCountry != widget.foreignStock.country) {
        _flyingElsewhere = true;
        var timeToFirstCountryFromTorn = travelTs.difference(now).inSeconds;
        if (timeToFirstCountryFromTorn < 0) {
          timeToFirstCountryFromTorn = 0;
        }
        final timeBackToTorn = TravelTimes.travelTimeMinutesOneWay(
              ticket: widget.ticket,
              countryCode: widget.travelingCountry,
            ) *
            60;
        final timeToWidgetCountry = TravelTimes.travelTimeMinutesOneWay(
              ticket: widget.ticket,
              countryCode: widget.foreignStock.country,
            ) *
            60;
        final totalNeeded = timeToFirstCountryFromTorn + timeBackToTorn + timeToWidgetCountry;
        _earliestArrival = DateTime.now().add(Duration(seconds: totalNeeded));

        if (timeToFirstCountryFromTorn == 0) {
          _tripExplanatory = "You are visiting ${widget.travelingCountryFullName}\n\n"
              "${_timeFormatter(_earliestArrival)} is your earliest possible arrival time "
              "to ${widget.foreignStock.countryFullName} after you make your way back to Torn.";
        } else {
          _tripExplanatory = "You are flying to ${widget.travelingCountryFullName}.\n\n"
              "${_timeFormatter(_earliestArrival)} is your earliest possible arrival time to ${widget.foreignStock.countryFullName} "
              "after you make your way back to Torn.";
        }

        _earliestBackToTorn = DateTime.now().add(Duration(seconds: totalNeeded + timeBackToTorn));
      }
    } else {
      _travelSeconds = TravelTimes.travelTimeMinutesOneWay(
            ticket: widget.ticket,
            countryCode: widget.foreignStock.country,
          ) *
          60;
      _earliestArrival = DateTime.now().add(Duration(seconds: _travelSeconds));

      _earliestBackToTorn = DateTime.now().add(Duration(seconds: _travelSeconds * 2));
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
            country: widget.foreignStock.countryFullName,
            stockCodeName: _codeName,
            itemId: widget.foreignStock.id,
            countryId: widget.foreignStock.country!.index,
          ),
        );
      },
    );
  }

  String? _timeFormatter(DateTime time) {
    return TimeFormatter(
      inputTime: time,
      timeFormatSetting: _settingsProvider.currentTimeFormat,
      timeZoneSetting: _settingsProvider.currentTimeZone,
    ).formatHour;
  }

  String? _dateFormatter(DateTime time) {
    return TimeFormatter(
      inputTime: time,
      timeFormatSetting: _settingsProvider.currentTimeFormat,
      timeZoneSetting: _settingsProvider.currentTimeZone,
    ).formatMonthDay;
  }

  void _timerUpdate() {
    setState(() {
      _calculateDetails();
    });
  }

  Widget _arrivalTime() {
    return Row(
      children: [
        const Icon(MdiIcons.airplaneLanding, size: 12),
        const SizedBox(width: 2),
        if (_flyingToThisCountry)
          if (_landedInWidgetCountry)
            Text(
              "LANDED",
              style: TextStyle(
                fontSize: 11,
                color: _themeProvider.getTextColor(Colors.green),
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Text(
              "${_timeFormatter(_earliestArrival)}",
              style: TextStyle(
                fontSize: 11,
                color: _themeProvider.getTextColor(Colors.green),
                fontStyle: FontStyle.italic,
              ),
            )
        else if (_flyingElsewhere)
          Row(
            children: [
              Text(
                "${_timeFormatter(_earliestArrival)}",
                style: TextStyle(
                  fontSize: 11,
                  color: _themeProvider.getTextColor(Colors.orange[700]),
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(width: 3),
              GestureDetector(
                child: Icon(
                  Icons.info_outline,
                  size: 13,
                  color: Colors.orange[700],
                ),
                onTap: () {
                  BotToast.showText(
                    text: _tripExplanatory,
                    textStyle: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    contentColor: _themeProvider.getTextColor(Colors.grey[700]),
                    duration: const Duration(seconds: 6),
                    contentPadding: const EdgeInsets.all(10),
                  );
                },
              ),
            ],
          )
        else
          Text(
            "${_timeFormatter(_earliestArrival)}",
            style: const TextStyle(
              fontSize: 11,
            ),
          )
      ],
    );
  }

  Future<void> _openWalletDialog() {
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
          content: SingleChildScrollView(
            child: Stack(
              children: <Widget>[
                SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.only(
                      top: 45,
                      bottom: 16,
                      left: 16,
                      right: 16,
                    ),
                    margin: const EdgeInsets.only(top: 15),
                    decoration: BoxDecoration(
                      color: _themeProvider.secondBackground,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10.0,
                          offset: Offset(0.0, 10.0),
                        ),
                      ],
                    ),
                    child: Column(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                          child: ElevatedButton(
                            child: Row(
                              children: [
                                Image.asset(
                                  'images/icons/home/vault.png',
                                  width: 15,
                                  height: 15,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 15),
                                const Text("Personal vault"),
                              ],
                            ),
                            onPressed: () async {
                              const url = "https://www.torn.com/properties.php#/p=options&tab=vault";
                              Navigator.of(context).pop();
                              _cashCheckPressed = true;
                              context.read<WebViewProvider>().openBrowserPreference(
                                    context: context,
                                    url: url,
                                    browserTapType: BrowserTapType.short,
                                  );
                            },
                            onLongPress: () async {
                              const url = "https://www.torn.com/properties.php#/p=options&tab=vault";
                              Navigator.of(context).pop();
                              _cashCheckPressed = true;
                              context.read<WebViewProvider>().openBrowserPreference(
                                    context: context,
                                    url: url,
                                    browserTapType: BrowserTapType.long,
                                  );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                          child: ElevatedButton(
                            child: Row(
                              children: [
                                Image.asset(
                                  'images/icons/faction.png',
                                  width: 15,
                                  height: 15,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 15),
                                const Text("Faction vault"),
                              ],
                            ),
                            onPressed: () async {
                              const url = 'https://www.torn.com/factions.php?step=your#/tab=armoury';
                              Navigator.of(context).pop();
                              _cashCheckPressed = true;
                              context.read<WebViewProvider>().openBrowserPreference(
                                    context: context,
                                    url: url,
                                    browserTapType: BrowserTapType.short,
                                  );
                            },
                            onLongPress: () async {
                              const url = "https://www.torn.com/factions.php?step=your#/tab=armoury";
                              Navigator.of(context).pop();
                              _cashCheckPressed = true;
                              context.read<WebViewProvider>().openBrowserPreference(
                                    context: context,
                                    url: url,
                                    browserTapType: BrowserTapType.long,
                                  );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                          child: ElevatedButton(
                            child: Row(
                              children: [
                                Image.asset(
                                  'images/icons/home/job.png',
                                  width: 15,
                                  height: 15,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 15),
                                const Text("Company vault"),
                              ],
                            ),
                            onPressed: () async {
                              const url = 'https://www.torn.com/companies.php#/option=funds';
                              Navigator.of(context).pop();
                              _cashCheckPressed = true;
                              context.read<WebViewProvider>().openBrowserPreference(
                                    context: context,
                                    url: url,
                                    browserTapType: BrowserTapType.short,
                                  );
                            },
                            onLongPress: () async {
                              const url = "https://www.torn.com/companies.php#/option=funds";
                              Navigator.of(context).pop();
                              _cashCheckPressed = true;
                              context.read<WebViewProvider>().openBrowserPreference(
                                    context: context,
                                    url: url,
                                    browserTapType: BrowserTapType.long,
                                  );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          child: const Text("Cancel"),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: _themeProvider.secondBackground,
                    child: CircleAvatar(
                      backgroundColor: _themeProvider.secondBackground,
                      radius: 22,
                      child: const SizedBox(
                        height: 34,
                        width: 34,
                        child: Icon(
                          MdiIcons.cash100,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _refreshMoney() async {
    BotToast.showText(
      text: "Refreshing cash on hand, might take a few seconds...",
      textStyle: const TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
      contentColor: Colors.grey[700]!,
      duration: const Duration(seconds: 4),
      contentPadding: const EdgeInsets.all(15),
    );
    // First try
    await Future.delayed(const Duration(seconds: 5));
    if (mounted) {
      widget.requestMoneyRefresh();
    }
    // Second try
    await Future.delayed(const Duration(seconds: 10));
    if (mounted) {
      widget.requestMoneyRefresh();
    }
    // Third try
    await Future.delayed(const Duration(seconds: 20));
    if (mounted) {
      widget.requestMoneyRefresh();
    }
  }
}

class CountryCodeAndFlag extends StatelessWidget {
  final ForeignStock stock;
  final bool dense;

  const CountryCodeAndFlag({required this.stock, this.dense = false});

  @override
  Widget build(BuildContext context) {
    late String countryCode;
    late String flag;

    if (stock.country != null) {
      switch (stock.country!) {
        case CountryName.JAPAN:
          countryCode = 'JPN';
          flag = 'images/flags/stock/japan.png';
        case CountryName.HAWAII:
          countryCode = 'HAW';
          flag = 'images/flags/stock/hawaii.png';
        case CountryName.CHINA:
          countryCode = 'CHN';
          flag = 'images/flags/stock/china.png';
        case CountryName.ARGENTINA:
          countryCode = 'ARG';
          flag = 'images/flags/stock/argentina.png';
        case CountryName.UNITED_KINGDOM:
          countryCode = 'UK';
          flag = 'images/flags/stock/uk.png';
        case CountryName.CAYMAN_ISLANDS:
          countryCode = 'CAY';
          flag = 'images/flags/stock/cayman.png';
        case CountryName.SOUTH_AFRICA:
          countryCode = 'AFR';
          flag = 'images/flags/stock/south-africa.png';
        case CountryName.SWITZERLAND:
          countryCode = 'SWI';
          flag = 'images/flags/stock/switzerland.png';
        case CountryName.MEXICO:
          countryCode = 'MEX';
          flag = 'images/flags/stock/mexico.png';
        case CountryName.UAE:
          countryCode = 'UAE';
          flag = 'images/flags/stock/uae.png';
        case CountryName.CANADA:
          countryCode = 'CAN';
          flag = 'images/flags/stock/canada.png';
        case CountryName.TORN:
          break;
      }
    } else if (stock.countryCode != null) {
      // Requested from hidden stocks, codes differ!

      switch (stock.countryCode!.toUpperCase()) {
        case 'JAP':
          countryCode = 'JPN';
          flag = 'images/flags/stock/japan.png';
        case 'HAW':
          countryCode = 'HAW';
          flag = 'images/flags/stock/hawaii.png';
        case 'CHI':
          countryCode = 'CHN';
          flag = 'images/flags/stock/china.png';
        case 'ARG':
          countryCode = 'ARG';
          flag = 'images/flags/stock/argentina.png';
        case 'UNI':
          countryCode = 'UK';
          flag = 'images/flags/stock/uk.png';
        case 'CAY':
          countryCode = 'CAY';
          flag = 'images/flags/stock/cayman.png';
        case 'SOU':
          countryCode = 'AFR';
          flag = 'images/flags/stock/south-africa.png';
        case 'SWI':
          countryCode = 'SWI';
          flag = 'images/flags/stock/switzerland.png';
        case 'MEX':
          countryCode = 'MEX';
          flag = 'images/flags/stock/mexico.png';
        case 'UAE':
          countryCode = 'UAE';
          flag = 'images/flags/stock/uae.png';
        case 'CAN':
          countryCode = 'CAN';
          flag = 'images/flags/stock/canada.png';
      }
    } else {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Text(countryCode, style: TextStyle(fontSize: dense ? 12 : 14)),
        Image.asset(
          flag,
          width: dense ? 20 : 30,
        ),
      ],
    );
  }
}
