// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:provider/provider.dart';
import 'package:torn_pda/models/firebase_user_model.dart';
import 'package:torn_pda/models/stockmarket/stockmarket_model.dart';
import 'package:torn_pda/models/stockmarket/stockmarket_user_model.dart';

// Project imports:
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/utils/api_caller.dart';
import 'package:torn_pda/widgets/alerts/share_pice_card.dart';

class StockMarketAlertsPage extends StatefulWidget {
  final FirebaseUserModel fbUser;

  StockMarketAlertsPage({@required this.fbUser});

  @override
  _StockMarketAlertsPageState createState() => _StockMarketAlertsPageState();
}

class _StockMarketAlertsPageState extends State<StockMarketAlertsPage> {
  var _stockList = <StockMarketStock>[];

  UserDetailsProvider _userP;
  SettingsProvider _settingsP;
  ThemeProvider _themeP;

  Future _stocksInitialised;
  bool _errorInitialising = false;

  @override
  void initState() {
    super.initState();
    _settingsP = Provider.of<SettingsProvider>(context, listen: false);
    _userP = Provider.of<UserDetailsProvider>(context, listen: false);
    _stocksInitialised = _initialiseStocks();
  }

  @override
  Widget build(BuildContext context) {
    _themeP = Provider.of<ThemeProvider>(context, listen: true);
    return WillPopScope(
      onWillPop: _willPopCallback,
      child: Container(
        color: _themeP.currentTheme == AppTheme.light
            ? MediaQuery.of(context).orientation == Orientation.portrait
                ? Colors.blueGrey
                : Colors.grey[900]
            : Colors.grey[900],
        child: SafeArea(
          top: _settingsP.appBarTop ? false : true,
          bottom: true,
          child: Scaffold(
            appBar: _settingsP.appBarTop ? buildAppBar() : null,
            bottomNavigationBar: !_settingsP.appBarTop
                ? SizedBox(
                    height: AppBar().preferredSize.height,
                    child: buildAppBar(),
                  )
                : null,
            body: Builder(
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
                                SizedBox(height: 50),
                                Divider(),
                                SizedBox(height: 10),
                                Text("Traded Companies"),
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
                                  style: TextStyle(
                                      color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold),
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
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      elevation: _settingsP.appBarTop ? 2 : 0,
      brightness: Brightness.dark,
      title: Text("Stock market alerts"),
      leading: new IconButton(
        icon: new Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.of(context).pop();
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
    var allStocksReply = await TornApiCaller.stockmarket(_userP.basic.userApiKey).getAllStocks;
    var userStocksReply = await TornApiCaller.stockmarket(_userP.basic.userApiKey).getUserStocks;

    if (allStocksReply is! StockMarketModel || userStocksReply is! StockMarketUserModel) {
      _errorInitialising = true;
      return;
    }

    // Convert all stocks to list
    var allStocks = allStocksReply as StockMarketModel;
    _stockList = allStocks.stocks.entries.map((e) => e.value).toList();

    // Convert user stocks to list
    var userStocks = userStocksReply as StockMarketUserModel;
    var ownedStocks = userStocks.stocks.entries.map((e) => e.value).toList();

    // Get owned stocks
    for (var stockOwned in ownedStocks) {
      for (var stockAvailable in _stockList) {
        if (stockOwned.stockId == stockAvailable.stockId) {
          stockAvailable.owned = 1;

          // Calculate gains
          int totalShares = 0;
          double totalMoneyGain = 0;
          double totalMoneySpent = 0;
          stockOwned.transactions.forEach((key, transaction) {
            totalShares += transaction.shares;
            var singleGain = stockAvailable.currentPrice - transaction.boughtPrice;
            totalMoneyGain += singleGain * transaction.shares;
            totalMoneySpent += transaction.boughtPrice * transaction.shares;
          });

          var averageGain = totalMoneyGain/totalShares;
          var averageBought = totalMoneySpent/totalShares;
          stockAvailable.gain = totalMoneyGain;
          stockAvailable.percentageGain = averageGain * 100 / averageBought;
        }
      }
    }

    // Sort by acronym, then by owned status
    _stockList.sort((a, b) => a.acronym.compareTo(b.acronym));
    _stockList.sort((a, b) => b.owned.compareTo(a.owned));
  }

  Future<bool> _willPopCallback() async {
    return true;
  }
}
