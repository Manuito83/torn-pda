import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
// Package imports:
import 'package:provider/provider.dart';
import 'package:torn_pda/drawer.dart';
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/firebase_user_model.dart';
import 'package:torn_pda/models/stockmarket/stockmarket_model.dart';
import 'package:torn_pda/models/stockmarket/stockmarket_user_model.dart';
import 'package:torn_pda/providers/api_caller.dart';
// Project imports:
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/firebase_firestore.dart';
import 'package:torn_pda/utils/travel/profit_formatter.dart';
import 'package:torn_pda/widgets/alerts/share_price_card.dart';
import 'package:torn_pda/widgets/alerts/share_price_options.dart';
import 'package:torn_pda/widgets/pda_browser_icon.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';

class StockMarketAlertsPage extends StatefulWidget {
  final FirebaseUserModel? fbUser;
  final bool calledFromMenu;
  final Function stockMarketInMenuCallback;

  const StockMarketAlertsPage({this.fbUser, required this.calledFromMenu, required this.stockMarketInMenuCallback});

  @override
  StockMarketAlertsPageState createState() => StockMarketAlertsPageState();
}

class StockMarketAlertsPageState extends State<StockMarketAlertsPage> {
  FirebaseUserModel? _fbUser;

  var _stockList = <StockMarketStock>[];

  SettingsProvider? _settingsP;
  ThemeProvider? _themeProvider;
  late WebViewProvider _webViewProvider;

  double _totalValue = 0;
  double _totalProfit = 0;

  Future? _stocksInitialised;
  bool _errorInitializing = false;

  @override
  void initState() {
    super.initState();

    _settingsP = Provider.of<SettingsProvider>(context, listen: false);

    routeName = "stockmarket_alerts_page";
    if (!widget.calledFromMenu) {
      // We are NOT getting updated stocks every time
      _fbUser = widget.fbUser;

      routeWithDrawer = false;
      _settingsP!.willPopShouldGoBackStream.stream.listen((event) {
        if (mounted && routeName == "stockmarket_alerts_page") _goBack();
      });
    } else {
      routeWithDrawer = true;
    }
    _stocksInitialised = _initialiseStocks();
    analytics.logScreenView(screenName: 'stockMarket');
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context);
    _webViewProvider = Provider.of<WebViewProvider>(context);

    return Container(
      color: _themeProvider!.currentTheme == AppTheme.light
          ? MediaQuery.orientationOf(context) == Orientation.portrait
              ? Colors.blueGrey
              : _themeProvider!.canvas
          : _themeProvider!.canvas,
      child: SafeArea(
        right: _webViewProvider.webViewSplitActive && _webViewProvider.splitScreenPosition == WebViewSplitPosition.left,
        left: _webViewProvider.webViewSplitActive && _webViewProvider.splitScreenPosition == WebViewSplitPosition.right,
        child: Scaffold(
          backgroundColor: _themeProvider!.canvas,
          appBar: _settingsP!.appBarTop ? buildAppBar() : null,
          bottomNavigationBar: !_settingsP!.appBarTop
              ? SizedBox(
                  height: AppBar().preferredSize.height,
                  child: buildAppBar(),
                )
              : null,
          body: Container(
            color: _themeProvider!.canvas,
            child: Builder(
              builder: (BuildContext context) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
                  child: FutureBuilder(
                    future: _stocksInitialised,
                    builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        if (!_errorInitializing) {
                          return RefreshIndicator(
                            onRefresh: () async {
                              await _initialiseStocks();
                              setState(() {});
                              await Future.delayed(const Duration(seconds: 1));
                            },
                            child: SingleChildScrollView(
                              child: Column(
                                children: <Widget>[
                                  _alertActivator(),
                                  const Divider(),
                                  const Text("Traded Companies"),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        "Value: ",
                                        style: TextStyle(fontSize: 10),
                                      ),
                                      Text(
                                        formatProfit(inputDouble: _totalValue),
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                      Text(
                                        " - ${_totalProfit >= 0 ? 'Profit' : 'Loss'}: ",
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                      Text(
                                        formatProfit(inputDouble: _totalProfit),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: _totalProfit >= 0 ? Colors.green : Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  _allStocksList(),
                                  const SizedBox(height: 50),
                                ],
                              ),
                            ),
                          );
                        } else {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                  'OOPS!',
                                  style: TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                                  child: Column(
                                    children: [
                                      Text(
                                        'There was an error retrieving market share or alerts information.'
                                        '\n\nPlease try again in a few minutes!',
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      } else {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      iconTheme: IconThemeData(color: Colors.white),
      elevation: _settingsP!.appBarTop ? 2 : 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      title: const Text("Stock market alerts", style: TextStyle(color: Colors.white)),
      leadingWidth: _webViewProvider.webViewSplitActive ? 50 : 88,
      leading: Row(
        children: [
          IconButton(
            icon: widget.calledFromMenu ? const Icon(Icons.dehaze) : const Icon(Icons.arrow_back),
            onPressed: () {
              if (widget.calledFromMenu) {
                final ScaffoldState? scaffoldState = context.findRootAncestorStateOfType();
                if (scaffoldState != null) {
                  if (_webViewProvider.webViewSplitActive &&
                      _webViewProvider.splitScreenPosition == WebViewSplitPosition.left) {
                    scaffoldState.openEndDrawer();
                  } else {
                    scaffoldState.openDrawer();
                  }
                }
              } else {
                routeWithDrawer = true;
                _goBack();
              }
            },
          ),
          if (!_webViewProvider.webViewSplitActive) PdaBrowserIcon(),
        ],
      ),
      actions: [
        GestureDetector(
          child: Icon(
            MdiIcons.openInApp,
          ),
          onTap: () {
            _launchBrowser(shortTap: true);
          },
          onLongPress: () {
            _launchBrowser(shortTap: false);
          },
        ),
        const SizedBox(width: 5),
        IconButton(
          icon: const Icon(
            Icons.settings,
          ),
          onPressed: () async {
            return showDialog(
              useRootNavigator: false,
              context: context,
              barrierDismissible: true,
              builder: (BuildContext context) {
                return SharePriceOptions(_themeProvider, _settingsP, widget.stockMarketInMenuCallback);
              },
            );
          },
        ),
      ],
    );
  }

  Padding _alertActivator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 5, 8, 0),
      child: CheckboxListTile(
        checkColor: Colors.white,
        activeColor: Colors.blueGrey,
        value: _fbUser!.stockMarketNotification ?? false,
        title: const Text(
          "Stock Market notification",
          style: TextStyle(fontSize: 14),
        ),
        subtitle: const Text(
          "Main toggle for the custom price alerts you set up below",
          style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
        ),
        onChanged: (value) {
          setState(() {
            _fbUser?.stockMarketNotification = value;
          });
          firestore.subscribeToStockMarketNotification(value);
        },
      ),
    );
  }

  ListView _allStocksList() {
    final stockCards = <Widget>[];
    bool insideUserStocks = false;

    for (final stock in _stockList) {
      if (stock.owned == 0 && insideUserStocks == true) {
        stockCards.add(
          const Column(
            children: [
              SizedBox(height: 5),
              SizedBox(width: 150, child: Divider()),
              SizedBox(height: 5),
            ],
          ),
        );
        insideUserStocks = false;
      } else if (stock.owned == 1) {
        insideUserStocks = true;
      }

      stockCards.add(SharePriceCard(stock: stock));
    }

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: stockCards,
    );
  }

  Future _initialiseStocks() async {
    try {
      // If we call from the main menu, we have to get the fbUser before loading anything, as it won't come from
      // the alerts pages, like in other cases
      if (widget.calledFromMenu) {
        _fbUser = await firestore.getUserProfile(); // We are NOT getting updated stocks every time
      }

      final allStocksReply = await Get.find<ApiCallerController>().getAllStocks();
      final userStocksReply = await Get.find<ApiCallerController>().getUserStocks();

      if (allStocksReply is! StockMarketModel || userStocksReply is! StockMarketUserModel) {
        _errorInitializing = true;
        return;
      }

      // Convert all stocks to list
      final allStocks = allStocksReply;
      _stockList = allStocks.stocks!.entries.map((e) => e.value).toList();

      // Convert user stocks to list
      final userStocks = userStocksReply;
      var ownedStocks = [];
      if (userStocks.stocks != null) {
        ownedStocks = userStocks.stocks!.entries.map((e) => e.value).toList();
      }

      // Get owned stocks
      _totalValue = 0;
      _totalProfit = 0;
      for (final stockOwned in ownedStocks) {
        for (final listedStock in _stockList) {
          if (stockOwned.stockId == listedStock.stockId) {
            listedStock.owned = 1;

            // Calculate gains
            int totalShares = 0;
            double totalMoneyGain = 0;
            double totalMoneySpent = 0;
            stockOwned.transactions.forEach((key, transaction) {
              totalShares += transaction.shares is String ? int.parse(transaction.shares) : transaction.shares as int;
              final singleGain = listedStock.currentPrice! - transaction.boughtPrice;
              totalMoneyGain += singleGain * transaction.shares;
              totalMoneySpent += transaction.boughtPrice * transaction.shares;
            });

            final averageGain = totalMoneyGain / totalShares;
            final averageBought = totalMoneySpent / totalShares;
            listedStock.gain = totalMoneyGain;
            listedStock.percentageGain = averageGain * 100 / averageBought;
            listedStock.sharesOwned = totalShares;

            _totalValue += totalShares * listedStock.currentPrice!;
            _totalProfit += totalMoneyGain;
          }
        }
      }

      // Complete details based on what's saved in Firebase
      for (final fbAlert in _fbUser!.stockMarketShares) {
        final acronym = fbAlert.toString().substring(0, 3);
        final regex = RegExp(r"[A-Z]+-G-((?:\d+(?:\.)?(?:\d{1,2}))|n)-L-((?:\d+(?:\.)?(?:\d{1,2}))|n)");
        final match = regex.firstMatch(fbAlert.toString())!;
        final fbGain = match.group(1);
        final fbLoss = match.group(2);
        for (final listedStock in _stockList) {
          if (listedStock.acronym == acronym) {
            if (fbGain != "n") {
              listedStock.alertGain = double.tryParse(fbGain!);
            }
            if (fbLoss != "n") {
              listedStock.alertLoss = double.tryParse(fbLoss!);
            }
          }
        }
      }

      // Sort by acronym, then by owned status
      _stockList.sort((a, b) => a.acronym!.compareTo(b.acronym!));
      _stockList.sort((a, b) => b.owned.compareTo(a.owned));
    } catch (e, t) {
      logToUser("PDA Error at parsing stocks: $e, $t");
    }
  }

  void _launchBrowser({required shortTap}) {
    const String url = "https://www.torn.com/page.php?sid=stocks";
    _webViewProvider.openBrowserPreference(
      context: context,
      url: url,
      browserTapType: shortTap ? BrowserTapType.short : BrowserTapType.long,
    );
  }

  _goBack() {
    routeWithDrawer = true;
    if (!widget.calledFromMenu) {
      routeName = "alerts";
    } else {
      routeName = "drawer";
    }
    Navigator.of(context).pop();
  }
}
