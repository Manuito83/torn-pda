// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

// Package imports:
import 'package:provider/provider.dart';
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/firebase_user_model.dart';
import 'package:torn_pda/models/stockmarket/stockmarket_model.dart';
import 'package:torn_pda/models/stockmarket/stockmarket_user_model.dart';

// Project imports:
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/api_caller.dart';
import 'package:torn_pda/utils/firebase_firestore.dart';
import 'package:torn_pda/utils/travel/profit_formatter.dart';
import 'package:torn_pda/widgets/alerts/share_price_card.dart';
import 'package:torn_pda/widgets/alerts/share_price_options.dart';

class StockMarketAlertsPage extends StatefulWidget {
  final FirebaseUserModel fbUser;
  final bool calledFromMenu;
  final Function stockMarketInMenuCallback;

  StockMarketAlertsPage({this.fbUser, @required this.calledFromMenu, @required this.stockMarketInMenuCallback});

  @override
  _StockMarketAlertsPageState createState() => _StockMarketAlertsPageState();
}

class _StockMarketAlertsPageState extends State<StockMarketAlertsPage> {
  FirebaseUserModel _fbUser;

  var _stockList = <StockMarketStock>[];

  SettingsProvider _settingsP;
  ThemeProvider _themeProvider;
  WebViewProvider _webViewProvider;

  double _totalValue = 0;
  double _totalProfit = 0;

  Future _stocksInitialised;
  bool _errorInitialising = false;

  @override
  void initState() {
    super.initState();
    _settingsP = Provider.of<SettingsProvider>(context, listen: false);
    _webViewProvider = context.read<WebViewProvider>();
    if (!widget.calledFromMenu) _fbUser = widget.fbUser; // We are NOT getting updated stocks every time
    _stocksInitialised = _initialiseStocks();
    analytics.setCurrentScreen(screenName: 'stockMarket');
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return WillPopScope(
      onWillPop: _willPopCallback,
      child: Container(
        color: _themeProvider.currentTheme == AppTheme.light
            ? MediaQuery.of(context).orientation == Orientation.portrait
                ? Colors.blueGrey
                : _themeProvider.canvas
            : _themeProvider.canvas,
        child: SafeArea(
          top: _settingsP.appBarTop ? false : true,
          bottom: true,
          child: Scaffold(
            backgroundColor: _themeProvider.canvas,
            appBar: _settingsP.appBarTop ? buildAppBar() : null,
            bottomNavigationBar: !_settingsP.appBarTop
                ? SizedBox(
                    height: AppBar().preferredSize.height,
                    child: buildAppBar(),
                  )
                : null,
            body: Container(
              color: _themeProvider.canvas,
              child: Builder(
                builder: (BuildContext context) {
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => FocusScope.of(context).requestFocus(new FocusNode()),
                    child: FutureBuilder(
                      future: _stocksInitialised,
                      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          if (!_errorInitialising) {
                            return SingleChildScrollView(
                              child: Column(
                                children: <Widget>[
                                  _alertActivator(),
                                  Divider(),
                                  Text("Traded Companies"),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Value: ",
                                        style: TextStyle(fontSize: 10),
                                      ),
                                      Text(
                                        formatProfit(inputDouble: _totalValue),
                                        style: TextStyle(fontSize: 10),
                                      ),
                                      Text(
                                        " - ${_totalProfit >= 0 ? 'Profit' : 'Loss'}: ",
                                        style: TextStyle(fontSize: 10),
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
                                  SizedBox(height: 10),
                                  _allStocksList(),
                                  SizedBox(height: 50),
                                ],
                              ),
                            );
                          } else {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    'OOPS!',
                                    style: TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
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
                          return Center(
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
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      //brightness: Brightness.dark, // For downgrade to Flutter 2.2.3
      elevation: _settingsP.appBarTop ? 2 : 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      title: Text("Stock market alerts"),
      leading: new IconButton(
        icon: widget.calledFromMenu ? const Icon(Icons.dehaze) : const Icon(Icons.arrow_back),
        onPressed: () {
          if (widget.calledFromMenu) {
            final ScaffoldState scaffoldState = context.findRootAncestorStateOfType();
            scaffoldState.openDrawer();
          } else {
            Navigator.of(context).pop();
          }
        },
      ),
      actions: [
        GestureDetector(
          child: Icon(
            MdiIcons.openInApp,
          ),
          onTap: () {
            _launchBrowser(dialog: true);
          },
          onLongPress: () {
            _launchBrowser(dialog: false);
          },
        ),
        SizedBox(width: 5),
        IconButton(
          icon: Icon(
            Icons.settings,
          ),
          onPressed: () async {
            return showDialog(
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

  _alertActivator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 5, 8, 0),
      child: CheckboxListTile(
        checkColor: Colors.white,
        activeColor: Colors.blueGrey,
        value: _fbUser.stockMarketNotification ?? false,
        title: Text(
          "Stock Market notification",
          style: TextStyle(fontSize: 14),
        ),
        subtitle: Text(
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
    var stockCards = <Widget>[];
    bool insideUserStocks = false;

    for (var stock in _stockList) {
      if (stock.owned == 0 && insideUserStocks == true) {
        stockCards.add(
          Column(
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
    // If we call from the main menu, we have to get the fbUser before loading anything, as it won't come from
    // the alerts pages, like in other cases
    if (widget.calledFromMenu) {
      _fbUser = await firestore.getUserProfile(force: false); // We are NOT getting updated stocks every time
    }

    var allStocksReply = await TornApiCaller().getAllStocks();
    var userStocksReply = await TornApiCaller().getUserStocks();

    if (allStocksReply is! StockMarketModel || userStocksReply is! StockMarketUserModel) {
      _errorInitialising = true;
      return;
    }

    // Convert all stocks to list
    var allStocks = allStocksReply as StockMarketModel;
    _stockList = allStocks.stocks.entries.map((e) => e.value).toList();

    // Convert user stocks to list
    var userStocks = userStocksReply as StockMarketUserModel;
    var ownedStocks = [];
    if (userStocks.stocks != null) {
      ownedStocks = userStocks.stocks.entries.map((e) => e.value).toList();
    }

    // Get owned stocks
    for (var stockOwned in ownedStocks) {
      for (var listedStock in _stockList) {
        if (stockOwned.stockId == listedStock.stockId) {
          listedStock.owned = 1;

          // Calculate gains
          int totalShares = 0;
          double totalMoneyGain = 0;
          double totalMoneySpent = 0;
          stockOwned.transactions.forEach((key, transaction) {
            totalShares += transaction.shares;
            var singleGain = listedStock.currentPrice - transaction.boughtPrice;
            totalMoneyGain += singleGain * transaction.shares;
            totalMoneySpent += transaction.boughtPrice * transaction.shares;
          });

          var averageGain = totalMoneyGain / totalShares;
          var averageBought = totalMoneySpent / totalShares;
          listedStock.gain = totalMoneyGain;
          listedStock.percentageGain = averageGain * 100 / averageBought;
          listedStock.sharesOwned = totalShares;

          _totalValue += totalShares * listedStock.currentPrice;
          _totalProfit += totalMoneyGain;
        }
      }
    }

    // Complete details based on what's saved in Firebase
    for (var fbAlert in _fbUser.stockMarketShares) {
      var acronym = fbAlert.toString().substring(0, 3);
      var regex = RegExp(r"[A-Z]+-G-((?:\d+(?:\.)?(?:\d{1,2}))|n)-L-((?:\d+(?:\.)?(?:\d{1,2}))|n)");
      var match = regex.firstMatch(fbAlert.toString());
      var fbGain = match.group(1);
      var fbLoss = match.group(2);
      for (var listedStock in _stockList) {
        if (listedStock.acronym == acronym) {
          if (fbGain != "n") {
            listedStock.alertGain = double.tryParse(fbGain);
          }
          if (fbLoss != "n") {
            listedStock.alertLoss = double.tryParse(fbLoss);
          }
        }
      }
    }

    // Sort by acronym, then by owned status
    _stockList.sort((a, b) => a.acronym.compareTo(b.acronym));
    _stockList.sort((a, b) => b.owned.compareTo(a.owned));
  }

  void _launchBrowser({@required dialog}) {
    String url = "https://www.torn.com/page.php?sid=stocks";
    _webViewProvider.openBrowserPreference(
      context: context,
      url: url,
      useDialog: dialog,
    );
  }

  Future<bool> _willPopCallback() async {
    return true;
  }
}
