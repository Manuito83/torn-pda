// Dart imports:
import 'dart:async';
import 'dart:convert';
import 'dart:developer';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:torn_pda/drawer.dart';
// Project imports:
import 'package:torn_pda/models/inventory_model.dart';
import 'package:torn_pda/models/items_model.dart';
import 'package:torn_pda/models/profile/own_profile_model.dart';
import 'package:torn_pda/models/travel/foreign_stock_in.dart';
import 'package:torn_pda/models/travel/foreign_stock_sort.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/api_caller.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/utils/travel/travel_times.dart';
import 'package:torn_pda/widgets/travel/foreign_stock_card.dart';
import 'package:torn_pda/widgets/travel/stock_options_dialog.dart';

class ReturnFlagPressed {
  bool flagPressed = false;
  bool shortTap = true;

  ReturnFlagPressed({@required this.flagPressed, @required this.shortTap});
}

class ForeignStockPage extends StatefulWidget {
  final String apiKey;

  ForeignStockPage({@required this.apiKey});

  @override
  _ForeignStockPageState createState() => _ForeignStockPageState();
}

class _ForeignStockPageState extends State<ForeignStockPage> {
  PanelController _pc = new PanelController();

  final double _initFabHeight = 25.0;
  double _fabHeight;
  double _panelHeightOpen = 300;
  double _panelHeightClosed = 75.0;

  ThemeProvider _themeProvider;
  SettingsProvider _settingsProvider;

  Future _apiCalled;
  bool _apiSuccess;
  bool _yataTimeOut = false;

  var _activeRestocks = Map<String, dynamic>();

  /// MODELS
  // CAUTION: model in 'foreign_stock_in.dart' has been altered with easier names for classes
  // and contains also the enum for countries. Both models below are based on that file.

  // This is the model used for the cards. Simplified just with the fields
  // needed and adapted from the model that comes from YATA. It's a list of StockElement (which
  // is defined in YATA), so that it can be filtered and sorted easily
  var _filteredStocksCards = <ForeignStock>[];
  // This is the model as it comes from YATA. There is some complexity as it consist on several
  // arrays and some details need to be filled in for the stocks as we fetch from the API
  var _stocksYataModel = ForeignStockInModel();
  // This is the official items model from Torn
  ItemsModel _allTornItems;

  bool _inventoryEnabled = true;
  bool _showArrivalTime = true;
  bool _showBarsCooldownAnalysis = true;
  InventoryModel _inventory;
  //OwnProfileExtended _travelModel;
  OwnProfileExtended _profile;
  int _capacity;

  final _filteredTypes = List<bool>.filled(4, true, growable: false);
  final _filteredFlags = List<bool>.filled(12, true, growable: false);

  bool _alphabeticalFilter = false;

  String _countriesFilteredText = '';
  List<String> _countryCodesAlphabetical = [
    'ARG',
    'CAN',
    'CAY',
    'CHN',
    'HAW',
    'JPN',
    'MEX',
    'AFR',
    'SWI',
    'UAE',
    'UK',
  ];
  List<String> _countryCodesTime = [
    'MEX',
    'CAY',
    'CAN',
    'HAW',
    'UK',
    'ARG',
    'SWI',
    'JPN',
    'CHN',
    'UAE',
    'AFR',
  ];

  String _typesFilteredText = '';
  List<String> _typeCodes = [
    'Flowers',
    'Plushies',
    'Drugs',
    'Others',
  ];

  var _currentSort;
  final _popupChoices = <StockSort>[
    StockSort(type: StockSortType.country),
    StockSort(type: StockSortType.name),
    StockSort(type: StockSortType.type),
    StockSort(type: StockSortType.quantity),
    StockSort(type: StockSortType.inventoryQuantity),
    StockSort(type: StockSortType.price),
    StockSort(type: StockSortType.value),
    StockSort(type: StockSortType.profit),
    StockSort(type: StockSortType.arrivalTime),
  ];

  RefreshController _refreshController = RefreshController(initialRefresh: false);

  List<ForeignStock> _hiddenStocks = <ForeignStock>[];

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _fabHeight = _initFabHeight;
    _apiCalled = _fetchApiInformation();
    _restoreSharedPreferences();

    routeWithDrawer = false;
    routeName = "foreign_stock";
    _settingsProvider.willPopShouldGoBack.stream.listen((event) {
      if (mounted && routeName == "foreign_stock") _goBack(false, false);
    });
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return Container(
      color: _themeProvider.currentTheme == AppTheme.light
          ? MediaQuery.of(context).orientation == Orientation.portrait
              ? Colors.blueGrey
              : Colors.grey[900]
          : _themeProvider.currentTheme == AppTheme.dark
              ? Colors.grey[900]
              : Colors.black,
      child: SafeArea(
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
            color: _themeProvider.currentTheme == AppTheme.extraDark ? Colors.black : Colors.transparent,
            child: Stack(
              alignment: Alignment.topCenter,
              children: <Widget>[
                FutureBuilder(
                  future: _apiCalled,
                  builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (_apiSuccess) {
                        return SmartRefresher(
                          enablePullDown: true,
                          header: WaterDropMaterialHeader(
                            backgroundColor: Theme.of(context).primaryColor,
                          ),
                          controller: _refreshController,
                          onRefresh: _onRefresh,
                          child: ListView(
                            children: _stockItems(),
                          ),
                        );
                      } else {
                        var errorTiles = <Widget>[];
                        errorTiles.add(
                          Center(
                            child: Column(
                              children: [
                                Image.asset(
                                  'images/icons/airplane.png',
                                  height: 100,
                                ),
                                SizedBox(height: 15),
                                Text(
                                  'OOPS!',
                                  style: TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                                  child: Text(
                                    'There was an error getting the information, please '
                                    'try again later or pull to refresh!',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );

                        return SmartRefresher(
                          enablePullDown: true,
                          header: WaterDropMaterialHeader(
                            backgroundColor: Theme.of(context).primaryColor,
                          ),
                          controller: _refreshController,
                          onRefresh: _onRefresh,
                          child: ListView(
                            children: [
                              SizedBox(
                                height: MediaQuery.of(context).size.height / 2,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: errorTiles,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    } else {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text('Fetching data...'),
                            SizedBox(height: 30),
                            CircularProgressIndicator(),
                          ],
                        ),
                      );
                    }
                  },
                ),

                // Sliding panel
                FutureBuilder(
                  future: _apiCalled,
                  builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (_apiSuccess) {
                        return SlidingUpPanel(
                          controller: _pc,
                          maxHeight: _panelHeightOpen,
                          minHeight: _panelHeightClosed,
                          renderPanelSheet: false,
                          backdropEnabled: true,
                          parallaxEnabled: true,
                          parallaxOffset: .5,
                          panelBuilder: (sc) => _bottomPanel(sc),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(18.0),
                            topRight: Radius.circular(18.0),
                          ),
                          onPanelSlide: (double pos) => setState(() {
                            _fabHeight = pos * (_panelHeightOpen - _panelHeightClosed) + _initFabHeight;
                          }),
                        );
                      } else {
                        return SizedBox.shrink();
                      }
                    } else {
                      return SizedBox.shrink();
                    }
                  },
                ),

                // FAB
                FutureBuilder(
                  future: _apiCalled,
                  builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (_apiSuccess) {
                        return Positioned(
                          right: 35.0,
                          bottom: _fabHeight,
                          child: FloatingActionButton.extended(
                            icon: Icon(Icons.filter_list),
                            label: Text("Filter"),
                            elevation: 4,
                            onPressed: () {
                              _pc.isPanelOpen ? _pc.close() : _pc.open();
                            },
                            backgroundColor: Colors.orange,
                          ),
                        );
                      } else {
                        return SizedBox.shrink();
                      }
                    } else {
                      return SizedBox.shrink();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _goBack(bool flag, bool shortTap) {
    routeWithDrawer = true;
    routeName = "drawer";
    // Returning 'false' to indicate we did not press a flag
    Navigator.pop(
      context,
      ReturnFlagPressed(flagPressed: flag, shortTap: shortTap),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      //brightness: Brightness.dark, // For downgrade to Flutter 2.2.3
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      title: Text("Foreign Stock"),
      leading: new IconButton(
        icon: new Icon(Icons.arrow_back),
        onPressed: () {
          _goBack(false, false);
        },
      ),
      actions: <Widget>[
        PopupMenuButton<StockSort>(
          icon: Icon(
            Icons.sort,
          ),
          onSelected: _sortStocks,
          itemBuilder: (BuildContext context) {
            return _popupChoices.map((StockSort choice) {
              return PopupMenuItem<StockSort>(
                value: choice,
                child: Text(
                  choice.description,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: choice.description == _currentSort.description ? FontWeight.bold : FontWeight.normal,
                    fontStyle: choice.description == _currentSort.description ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              );
            }).toList();
          },
        ),
        IconButton(
          icon: Icon(MdiIcons.eyeRemoveOutline),
          onPressed: _hiddenStocks.isEmpty
              ? null
              : () {
                  return showDialog<void>(
                    context: context,
                    barrierDismissible: true, // user must tap button!
                    builder: (BuildContext context) {
                      return HiddenForeignStockDialog(
                        hiddenStocks: _hiddenStocks,
                        themeProvider: _themeProvider,
                        unhide: _unhideMember,
                      );
                    },
                  );
                },
        ),
        IconButton(
          icon: Icon(Icons.settings),
          onPressed: () {
            _showOptionsDialog();
          },
        ),
      ],
    );
  }

  Widget _bottomPanel(ScrollController sc) {
    return Container(
      decoration: BoxDecoration(
          color: _themeProvider.secondBackground,
          borderRadius: BorderRadius.all(Radius.circular(24.0)),
          boxShadow: [
            BoxShadow(
              blurRadius: 2.0,
              color: Colors.orange[800],
            ),
          ]),
      margin: const EdgeInsets.all(22.0),
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 18.0,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 30,
                height: 5,
                decoration:
                    BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.all(Radius.circular(12.0))),
              ),
            ],
          ),
          SizedBox(height: 40.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: 40),
              SizedBox(height: 90, width: 220, child: _toggleFlagsFilter()),
              SizedBox(
                width: 40,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    child: Icon(
                      MdiIcons.filterVariant,
                      size: 30,
                    ),
                    onTap: () {
                      var orderType = "";
                      if (!_alphabeticalFilter) {
                        orderType = "Sorting countries alphabetically";
                      }
                      // We are changing to time
                      else {
                        orderType = "Sorting countries by flight time";
                      }

                      _transformAlphabeticalTime();

                      BotToast.showText(
                        text: orderType,
                        textStyle: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                        contentColor: Colors.grey[700],
                        duration: Duration(seconds: 2),
                        contentPadding: EdgeInsets.all(10),
                      );
                    },
                  ),
                ),
              )
            ],
          ),
          SizedBox(height: 20.0),
          SizedBox(height: 35, child: _toggleTypeFilter()),
        ],
      ),
    );
  }

  void _transformAlphabeticalTime() {
    var newFilter = List<bool>.filled(12, true, growable: false);

    // We are changing to alphabetical
    if (!_alphabeticalFilter) {
      newFilter[0] = _filteredFlags[5];
      newFilter[1] = _filteredFlags[2];
      newFilter[2] = _filteredFlags[1];
      newFilter[3] = _filteredFlags[8];
      newFilter[4] = _filteredFlags[3];
      newFilter[5] = _filteredFlags[7];
      newFilter[6] = _filteredFlags[0];
      newFilter[7] = _filteredFlags[10];
      newFilter[8] = _filteredFlags[6];
      newFilter[9] = _filteredFlags[9];
      newFilter[10] = _filteredFlags[4];
      newFilter[11] = _filteredFlags[11];
    }
    // We are changing to time
    else {
      newFilter[5] = _filteredFlags[0];
      newFilter[2] = _filteredFlags[1];
      newFilter[1] = _filteredFlags[2];
      newFilter[8] = _filteredFlags[3];
      newFilter[3] = _filteredFlags[4];
      newFilter[7] = _filteredFlags[5];
      newFilter[0] = _filteredFlags[6];
      newFilter[10] = _filteredFlags[7];
      newFilter[6] = _filteredFlags[8];
      newFilter[9] = _filteredFlags[9];
      newFilter[4] = _filteredFlags[10];
      newFilter[11] = _filteredFlags[11];
    }

    setState(() {
      for (var i = 0; i < _filteredFlags.length; i++) {
        _filteredFlags[i] = newFilter[i];
      }
      _alphabeticalFilter = !_alphabeticalFilter;
      _filterAndSortTopLists();
    });

    Prefs().setCountriesAlphabeticalFilter(_alphabeticalFilter);
    _saveFilteredFlags();
  }

  void _saveFilteredFlags() {
    var saveList = <String>[];
    for (var b in _filteredFlags) {
      b ? saveList.add('1') : saveList.add('0');
    }
    Prefs().setStockCountryFilter(saveList);
  }

  Widget _toggleFlagsFilter() {
    var flags = [];
    if (_alphabeticalFilter) {
      flags = [
        Image.asset('images/flags/stock/argentina.png', width: 25, height: 25),
        Image.asset('images/flags/stock/canada.png', width: 25, height: 25),
        Image.asset('images/flags/stock/cayman.png', width: 25, height: 25),
        Image.asset('images/flags/stock/china.png', width: 25, height: 25),
        Image.asset('images/flags/stock/hawaii.png', width: 25, height: 25),
        Image.asset('images/flags/stock/japan.png', width: 25, height: 25),
        Image.asset('images/flags/stock/mexico.png', width: 25, height: 25),
        Image.asset('images/flags/stock/south-africa.png', width: 25, height: 25),
        Image.asset('images/flags/stock/switzerland.png', width: 25, height: 25),
        Image.asset('images/flags/stock/uae.png', width: 25, height: 25),
        Image.asset('images/flags/stock/uk.png', width: 25, height: 25),
        Icon(
          Icons.select_all,
          color: _themeProvider.mainText,
        ),
      ];
    } else {
      flags = [
        Image.asset('images/flags/stock/mexico.png', width: 25, height: 25),
        Image.asset('images/flags/stock/cayman.png', width: 25, height: 25),
        Image.asset('images/flags/stock/canada.png', width: 25, height: 25),
        Image.asset('images/flags/stock/hawaii.png', width: 25, height: 25),
        Image.asset('images/flags/stock/uk.png', width: 25, height: 25),
        Image.asset('images/flags/stock/argentina.png', width: 25, height: 25),
        Image.asset('images/flags/stock/switzerland.png', width: 25, height: 25),
        Image.asset('images/flags/stock/japan.png', width: 25, height: 25),
        Image.asset('images/flags/stock/china.png', width: 25, height: 25),
        Image.asset('images/flags/stock/uae.png', width: 25, height: 25),
        Image.asset('images/flags/stock/south-africa.png', width: 25, height: 25),
        Icon(
          Icons.select_all,
          color: _themeProvider.mainText,
        ),
      ];
    }

    return GridView.count(
        shrinkWrap: true,
        crossAxisCount: 6,
        scrollDirection: Axis.vertical,
        mainAxisSpacing: 2.0,
        crossAxisSpacing: 2.0,
        childAspectRatio: 1,
        children: flags.asMap().entries.map((widget) {
          return ToggleButtons(
            constraints: BoxConstraints(minWidth: 30.0),
            highlightColor: Colors.orange,
            selectedBorderColor: Colors.green,
            isSelected: [_filteredFlags[widget.key]],
            children: [widget.value],
            onPressed: (_) {
              setState(() {
                // Item 11 is the icon for selecting/deselecting all
                if (widget.key == 11) {
                  if (_filteredFlags[widget.key]) {
                    for (int i = 0; i < _filteredFlags.length; i++) {
                      _filteredFlags[i] = false;
                    }
                  } else {
                    for (int i = 0; i < _filteredFlags.length; i++) {
                      _filteredFlags[i] = true;
                    }
                  }
                } else {
                  // Any country flag state change is handled here
                  _filteredFlags[widget.key] = !_filteredFlags[widget.key];
                  // Then, we check if we need to select Item 11
                  bool allFlagsSelected = true;
                  for (int i = 0; i < _filteredFlags.length - 1; i++) {
                    if (_filteredFlags[i] == false) {
                      allFlagsSelected = false;
                    }
                  }
                  if (allFlagsSelected) {
                    _filteredFlags[11] = true;
                  } else {
                    _filteredFlags[11] = false;
                  }
                }
              });

              // Saving to shared preferences
              _saveFilteredFlags();

              // Applying filter
              _filterAndSortTopLists();
            },
          );
        }).toList());
  }

  Widget _toggleTypeFilter() {
    return GridView.count(
        shrinkWrap: true,
        crossAxisCount: 1,
        scrollDirection: Axis.horizontal,
        mainAxisSpacing: 2.0,
        crossAxisSpacing: 2.0,
        childAspectRatio: 1,
        children: [
          Image.asset(
            'images/icons/ic_flower_black_48dp.png',
            width: 25,
            height: 25,
            color: _themeProvider.mainText,
          ),
          Image.asset(
            'images/icons/ic_dog_black_48dp.png',
            width: 25,
            height: 25,
            color: _themeProvider.mainText,
          ),
          Image.asset(
            'images/icons/ic_pill_black_48dp.png',
            width: 25,
            height: 25,
            color: _themeProvider.mainText,
          ),
          Icon(
            Icons.add_to_photos,
            color: _themeProvider.mainText,
          ),
        ].asMap().entries.map((widget) {
          return ToggleButtons(
            constraints: BoxConstraints(minWidth: 30.0),
            children: [widget.value],
            highlightColor: Colors.orange,
            selectedBorderColor: Colors.green,
            isSelected: [_filteredTypes[widget.key]],
            onPressed: (_) {
              setState(() {
                // Any item type state change is handled here
                _filteredTypes[widget.key] = !_filteredTypes[widget.key];
              });

              // Saving to shared preferences
              var saveList = <String>[];
              for (var b in _filteredTypes) {
                b ? saveList.add('1') : saveList.add('0');
              }
              Prefs().setStockTypeFilter(saveList);

              // Applying filter
              _filterAndSortTopLists();
            },
          );
        }).toList());
  }

  List<Widget> _stockItems() {
    var thisStockList = <Widget>[];

    Widget lastUpdateDetails = Padding(
      padding: EdgeInsets.fromLTRB(20, 15, 20, 10),
      child: Row(
        children: <Widget>[
          Text(
            'Last server update: ',
            style: TextStyle(fontSize: 11),
          ),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              _timeStampToString(_stocksYataModel.timestamp),
              style: TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );

    Widget countriesFilterDetails = Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Row(
        children: <Widget>[
          Text(
            'Countries: ',
            style: TextStyle(fontSize: 11),
          ),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              _countriesFilteredText,
              style: TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );

    Widget typesFilterDetails = Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 15),
      child: Row(
        children: <Widget>[
          Text(
            'Items: ',
            style: TextStyle(fontSize: 11),
          ),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              _typesFilteredText,
              style: TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );

    Widget hiddenDetails = SizedBox.shrink();
    if (_hiddenStocks.isNotEmpty) {
      hiddenDetails = Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 15),
        child: Row(
          children: <Widget>[
            Text(
              'There ${_hiddenStocks.length == 1 ? "is" : "are"} '
              '${_hiddenStocks.length}'
              ' hidden stock${_hiddenStocks.length == 1 ? "" : "s"}',
              style: TextStyle(fontSize: 11, color: Colors.orange[800]),
            ),
          ],
        ),
      );
    }

    thisStockList.add(lastUpdateDetails);
    thisStockList.add(countriesFilterDetails);
    thisStockList.add(typesFilterDetails);
    thisStockList.add(hiddenDetails);

    bool displayShowcase = true; // Add showcase to first card only
    for (var stock in _filteredStocksCards) {
      // Do not show hidden stock cards
      bool hidden = false;
      for (var h in _hiddenStocks) {
        if (h.id == stock.id && h.countryCode == stock.countryCode) {
          hidden = true;
          break;
        }
      }
      if (hidden) continue;

      thisStockList.add(
        ForeignStockCard(
          foreignStock: stock,
          capacity: _capacity,
          inventoryEnabled: _inventoryEnabled,
          showArrivalTime: _showArrivalTime,
          showBarsCooldownAnalysis: _showBarsCooldownAnalysis,
          profile: _profile,
          flagPressedCallback: _onFlagPressed,
          requestMoneyRefresh: _refreshMoney,
          memberHiddenCallback: _hideMember,
          ticket: _settingsProvider.travelTicket,
          activeRestocks: _activeRestocks,
          travellingTimeStamp: _profile.travel.timestamp,
          travellingCountry: _returnCountryName(_profile.travel.destination),
          travellingCountryFullName: _profile.travel.destination,
          displayShowcase: displayShowcase,
          key: UniqueKey(),
        ),
      );
      displayShowcase = false;
    }

    thisStockList.add(SizedBox(
      height: 100,
    ));
    return thisStockList;
  }

  Future<void> _fetchApiInformation() async {
    try {
      // Get all APIs
      await yataAPI();
      if (_yataTimeOut) {
        return;
      }

      await Future.wait<void>([
        tornItems(),
        inventory(),
        profileMisc(),
      ]);

      if (!_apiSuccess) {
        log("Unsuccessful Torn API replies");
        return;
      }

      // We need to calculate several additional values before sorting the list
      // for the first time, as this values don't come straight
      // in every stock from the API (but can be deducted)

      // NOTE: some of this values (i.e. profit and arrival time) will later be
      // recalculate in real time in the card widget. This first calculation is
      // only to compare ones with the others and sort.

      var itemList = _allTornItems.items.values.toList();
      _stocksYataModel.countries.forEach((countryKey, countryDetails) {
        for (var stock in countryDetails.stocks) {
          // Match with Torn items (contained in itemList)
          Item itemMatch = itemList[stock.id - 1];

          // Complete fields we need for value and profit
          stock.value = itemMatch.marketValue - stock.cost;

          // Assign actual profit depending on country (+ the country)
          stock.countryCode = countryKey;
          switch (countryKey) {
            case 'jap':
              stock.country = CountryName.JAPAN;
              stock.countryFullName = "Japan";
              break;
            case 'haw':
              stock.country = CountryName.HAWAII;
              stock.countryFullName = "Hawaii";
              break;
            case 'chi':
              stock.country = CountryName.CHINA;
              stock.countryFullName = "China";
              break;
            case 'arg':
              stock.country = CountryName.ARGENTINA;
              stock.countryFullName = "Argentina";
              break;
            case 'uni':
              stock.country = CountryName.UNITED_KINGDOM;
              stock.countryFullName = "UK";
              break;
            case 'cay':
              stock.country = CountryName.CAYMAN_ISLANDS;
              stock.countryFullName = "Cayman Islands";
              break;
            case 'sou':
              stock.country = CountryName.SOUTH_AFRICA;
              stock.countryFullName = "South Africa";
              break;
            case 'swi':
              stock.country = CountryName.SWITZERLAND;
              stock.countryFullName = "Switzerland";
              break;
            case 'mex':
              stock.country = CountryName.MEXICO;
              stock.countryFullName = "Mexico";
              break;
            case 'uae':
              stock.country = CountryName.UAE;
              stock.countryFullName = "UAE";
              break;
            case 'can':
              stock.country = CountryName.CANADA;
              stock.countryFullName = "Canada";
              break;
          }

          // Other fields contained in Yata and in Torn
          stock.profit = (stock.value /
                  (TravelTimes.travelTimeMinutesOneWay(
                        ticket: _settingsProvider.travelTicket,
                        countryCode: stock.country,
                      ) *
                      2 /
                      60))
              .round();

          stock.timestamp = countryDetails.update;
          stock.itemType = itemList[stock.id - 1].type;

          stock.arrivalTime = DateTime.now().add(
            Duration(
              minutes: TravelTimes.travelTimeMinutesOneWay(
                countryCode: stock.country,
                ticket: _settingsProvider.travelTicket,
              ),
            ),
          );

          var invQty = 0;
          for (var invItem in _inventory.inventory) {
            if (invItem.id == stock.id) {
              invQty = invItem.quantity;
              break;
            }
          }
          for (var displayItem in _inventory.display) {
            if (displayItem.id == stock.id) {
              invQty += displayItem.quantity;
            }
          }
          stock.inventoryQuantity = invQty;
        }
      });

      // This will trigger a filter by flags, types and also sorting
      _filterAndSortTopLists();
    } catch (e) {
      _apiSuccess = false;

      if (_settingsProvider.debugMessages) {
        BotToast.showText(
          text: "YATA debug catch: $e",
          textStyle: TextStyle(
            fontSize: 13,
            color: Colors.white,
          ),
          contentColor: Colors.red[800],
          duration: Duration(seconds: 4),
          contentPadding: EdgeInsets.all(10),
        );
      }
    }
  }

  Future yataAPI() async {
    try {
      _yataTimeOut = false;
      String yataURL = 'https://yata.yt/api/v1/travel/export/';
      var responseDB = await http.get(Uri.parse(yataURL)).timeout(Duration(seconds: 25));
      if (responseDB.statusCode == 200) {
        _stocksYataModel = foreignStockInModelFromJson(responseDB.body);
        _apiSuccess = true;
      } else {
        _apiSuccess = false;

        if (_settingsProvider.debugMessages) {
          BotToast.showText(
            text: "YATA debug error: ${responseDB.body}",
            textStyle: TextStyle(
              fontSize: 13,
              color: Colors.white,
            ),
            contentColor: Colors.red[800],
            duration: Duration(seconds: 4),
            contentPadding: EdgeInsets.all(10),
          );
        }
      }
    } catch (e) {
      _apiSuccess = false;
      if (e is TimeoutException) {
        _yataTimeOut = true;
        BotToast.showText(
          text: "YATA connection timed out, the server might be busy.\n\nPlease try again later!",
          textStyle: TextStyle(
            fontSize: 13,
            color: Colors.white,
          ),
          contentColor: Colors.red[800],
          duration: Duration(seconds: 4),
          contentPadding: EdgeInsets.all(10),
        );
      }
    }
  }

  Future tornItems() async {
    dynamic itemsResponse = await Get.find<ApiCallerController>().getItems();

    String error = "";
    if (itemsResponse is ApiError) {
      // Torn API generates lots of errors with this query (JAN 2023)
      ApiError e = itemsResponse as ApiError;
      error = e.errorReason;
      log("Recalling API due to items error: ${e.errorReason}");
      BotToast.showText(
        text: "Torn API replied with error, retrying after a few seconds, please wait...",
        onlyOne: true,
        textStyle: TextStyle(
          fontSize: 13,
          color: Colors.white,
        ),
        contentColor: Colors.orange[800],
        duration: Duration(seconds: 5),
        contentPadding: EdgeInsets.all(10),
      );
      await Future.delayed(const Duration(seconds: 8));
      itemsResponse = await Get.find<ApiCallerController>().getItems();
    }

    if (itemsResponse is ApiError) {
      _apiSuccess = false;
      if (itemsResponse.errorReason.isNotEmpty) {
        BotToast.showText(
          text: "Torn API response with error: $error",
          onlyOne: true,
          textStyle: TextStyle(
            fontSize: 13,
            color: Colors.white,
          ),
          contentColor: Colors.red[800],
          duration: Duration(seconds: 4),
          contentPadding: EdgeInsets.all(10),
        );
      }
      return;
    }

    _allTornItems = itemsResponse;
  }

  Future inventory() async {
    dynamic inventoryResponse = await Get.find<ApiCallerController>().getInventory();

    String error = "";
    if (inventoryResponse is ApiError) {
      // Torn API generates lots of errors with this query (JAN 2023)
      ApiError e = inventoryResponse as ApiError;
      error = e.errorReason;
      log("Recalling API due to profile error: ${e.errorReason}");
      BotToast.showText(
        text: "Torn API replied with error, retrying after a few seconds, please wait...",
        onlyOne: true,
        textStyle: TextStyle(
          fontSize: 13,
          color: Colors.white,
        ),
        contentColor: Colors.orange[800],
        duration: Duration(seconds: 5),
        contentPadding: EdgeInsets.all(10),
      );
      await Future.delayed(const Duration(seconds: 8));
      inventoryResponse = await Get.find<ApiCallerController>().getInventory();
    }

    if (inventoryResponse is ApiError) {
      _apiSuccess = false;
      if (inventoryResponse.errorReason.isNotEmpty) {
        BotToast.showText(
          text: "Torn API response with error: $error",
          onlyOne: true,
          textStyle: TextStyle(
            fontSize: 13,
            color: Colors.white,
          ),
          contentColor: Colors.red[800],
          duration: Duration(seconds: 4),
          contentPadding: EdgeInsets.all(10),
        );
      }
      return;
    }

    _inventory = inventoryResponse;
  }

  Future profileMisc() async {
    dynamic profileResponse = await Get.find<ApiCallerController>().getOwnProfileExtended(limit: 3);

    String error = "";
    if (profileResponse is ApiError) {
      // Torn API generates lots of errors with this query (JAN 2023)
      ApiError e = profileResponse as ApiError;
      error = e.errorReason;
      log("Recalling API due to profile error: ${e.errorReason}");
      BotToast.showText(
        text: "Torn API replied with error, retrying after a few seconds, please wait...",
        onlyOne: true,
        textStyle: TextStyle(
          fontSize: 13,
          color: Colors.white,
        ),
        contentColor: Colors.orange[800],
        duration: Duration(seconds: 5),
        contentPadding: EdgeInsets.all(10),
      );
      await Future.delayed(const Duration(seconds: 8));
      profileResponse = await Get.find<ApiCallerController>().getOwnProfileExtended(limit: 3);
    }

    if (profileResponse is ApiError) {
      _apiSuccess = false;
      if (profileResponse.errorReason.isNotEmpty) {
        BotToast.showText(
          text: "Torn API response with error: $error",
          onlyOne: true,
          textStyle: TextStyle(
            fontSize: 13,
            color: Colors.white,
          ),
          contentColor: Colors.red[800],
          duration: Duration(seconds: 4),
          contentPadding: EdgeInsets.all(10),
        );
      }
      return;
    }

    _profile = profileResponse;
  }

  void _filterAndSortTopLists() {
    // Edit countries string
    _countriesFilteredText = '';
    bool firstCountry = true;
    int totalCountriesShown = 0;
    for (var i = 0; i < _filteredFlags.length - 1; i++) {
      if (_filteredFlags[i]) {
        if (_alphabeticalFilter) {
          _countriesFilteredText += firstCountry ? _countryCodesAlphabetical[i] : ', ${_countryCodesAlphabetical[i]}';
        } else {
          _countriesFilteredText += firstCountry ? _countryCodesTime[i] : ', ${_countryCodesTime[i]}';
        }
        firstCountry = false;
        totalCountriesShown++;
      }
    }
    if (totalCountriesShown == 0) {
      _countriesFilteredText = 'NONE';
    } else if (totalCountriesShown == 11) {
      _countriesFilteredText = 'ALL';
    }

    // Filter countries
    bool filterDrug(ForeignStock stock) {
      switch (stock.itemType) {
        case ItemType.FLOWER:
          if (_filteredTypes[0]) {
            return true;
          }
          break;
        case ItemType.PLUSHIE:
          if (_filteredTypes[1]) {
            return true;
          }
          break;
        case ItemType.DRUG:
          if (_filteredTypes[2]) {
            return true;
          }
          break;
        default:
          if (_filteredTypes[3]) {
            return true;
          }
          break;
      }
      return false;
    }

    var countryMap = Map<String, CountryDetails>();
    _stocksYataModel.countries.forEach((countryKey, countryDetails) {
      var stockList = CountryDetails()..stocks = <ForeignStock>[];
      stockList.update = countryDetails.update;

      for (var stock in countryDetails.stocks) {
        var argentinaPosition = _alphabeticalFilter ? 0 : 5;
        var canadaPosition = _alphabeticalFilter ? 1 : 2;
        var caymanPosition = _alphabeticalFilter ? 2 : 1;
        var chinaPosition = _alphabeticalFilter ? 3 : 8;
        var hawaiiPosition = _alphabeticalFilter ? 4 : 3;
        var japanPosition = _alphabeticalFilter ? 5 : 7;
        var mexicoPosition = _alphabeticalFilter ? 6 : 0;
        var africaPosition = _alphabeticalFilter ? 7 : 10;
        var switzerlandPosition = _alphabeticalFilter ? 8 : 6;
        var uaePosition = _alphabeticalFilter ? 9 : 9;
        var ukPosition = _alphabeticalFilter ? 10 : 4;

        switch (stock.country) {
          case CountryName.ARGENTINA:
            if (_filteredFlags[argentinaPosition] && filterDrug(stock)) {
              stockList.stocks.add(stock);
            }
            break;
          case CountryName.CANADA:
            if (_filteredFlags[canadaPosition] && filterDrug(stock)) {
              stockList.stocks.add(stock);
            }
            break;
          case CountryName.CAYMAN_ISLANDS:
            if (_filteredFlags[caymanPosition] && filterDrug(stock)) {
              stockList.stocks.add(stock);
            }
            break;
          case CountryName.CHINA:
            if (_filteredFlags[chinaPosition] && filterDrug(stock)) {
              stockList.stocks.add(stock);
            }
            break;
          case CountryName.HAWAII:
            if (_filteredFlags[hawaiiPosition] && filterDrug(stock)) {
              stockList.stocks.add(stock);
            }
            break;
          case CountryName.JAPAN:
            if (_filteredFlags[japanPosition] && filterDrug(stock)) {
              stockList.stocks.add(stock);
            }
            break;
          case CountryName.MEXICO:
            if (_filteredFlags[mexicoPosition] && filterDrug(stock)) {
              stockList.stocks.add(stock);
            }
            break;
          case CountryName.SOUTH_AFRICA:
            if (_filteredFlags[africaPosition] && filterDrug(stock)) {
              stockList.stocks.add(stock);
            }
            break;
          case CountryName.SWITZERLAND:
            if (_filteredFlags[switzerlandPosition] && filterDrug(stock)) {
              stockList.stocks.add(stock);
            }
            break;
          case CountryName.UAE:
            if (_filteredFlags[uaePosition] && filterDrug(stock)) {
              stockList.stocks.add(stock);
            }
            break;
          case CountryName.UNITED_KINGDOM:
            if (_filteredFlags[ukPosition] && filterDrug(stock)) {
              stockList.stocks.add(stock);
            }
            break;
          case CountryName.TORN:
            break;
        }
      }

      countryMap.addAll({countryKey: stockList});
    });

    // Edit drug string
    _typesFilteredText = '';
    bool firstType = true;
    int totalTypesShown = 0;
    for (var i = 0; i < _filteredTypes.length; i++) {
      if (_filteredTypes[i]) {
        _typesFilteredText += firstType ? _typeCodes[i] : ', ${_typeCodes[i]}';
        firstType = false;
        totalTypesShown++;
      }
    }
    if (totalTypesShown == 0) {
      _typesFilteredText = 'NONE';
    } else if (totalTypesShown == 4) {
      _typesFilteredText = 'ALL';
    }

    setState(() {
      _filteredStocksCards.clear();
      countryMap.forEach((countryKey, countryDetails) {
        for (var stock in countryDetails.stocks) {
          _filteredStocksCards.add(stock);
        }
      });

      _sortStocks(_currentSort);
    });
  }

  void _sortStocks(StockSort choice) {
    // This gets assigned here from the popUpMenu
    _currentSort = choice;
    setState(() {
      switch (choice.type) {
        case StockSortType.country:
          _filteredStocksCards.sort((a, b) => a.country.index.compareTo(b.country.index));
          Prefs().setStockSort('country');
          break;
        case StockSortType.name:
          _filteredStocksCards.sort((a, b) => a.name.compareTo(b.name));
          Prefs().setStockSort('name');
          break;
        case StockSortType.type:
          _filteredStocksCards.sort((a, b) => a.itemType.toString().compareTo(b.itemType.toString()));
          Prefs().setStockSort('type');
          break;
        case StockSortType.quantity:
          _filteredStocksCards.sort((a, b) => b.quantity.compareTo(a.quantity));
          Prefs().setStockSort('quantity');
          break;
        case StockSortType.price:
          _filteredStocksCards.sort((a, b) => b.cost.compareTo(a.cost));
          Prefs().setStockSort('price');
          break;
        case StockSortType.value:
          _filteredStocksCards.sort((a, b) => b.value.compareTo(a.value));
          Prefs().setStockSort('value');
          break;
        case StockSortType.profit:
          _filteredStocksCards.sort((a, b) => b.profit.compareTo(a.profit));
          Prefs().setStockSort('profit');
          break;
        case StockSortType.arrivalTime:
          _filteredStocksCards.sort((a, b) => a.arrivalTime.compareTo(b.arrivalTime));
          Prefs().setStockSort('arrivalTime');
          break;
        case StockSortType.inventoryQuantity:
          _filteredStocksCards.sort((a, b) => b.inventoryQuantity.compareTo(a.inventoryQuantity));
          Prefs().setStockSort('inventoryQuantity');
          break;
      }
    });
  }

  Future _restoreSharedPreferences() async {
    var flagStrings = await Prefs().getStockCountryFilter();
    for (var i = 0; i < flagStrings.length; i++) {
      flagStrings[i] == '0' ? _filteredFlags[i] = false : _filteredFlags[i] = true;
    }
    _alphabeticalFilter = await Prefs().getCountriesAlphabeticalFilter();
    //_transformAlphabeticalTime();

    var typesStrings = await Prefs().getStockTypeFilter();
    for (var i = 0; i < typesStrings.length; i++) {
      typesStrings[i] == '0' ? _filteredTypes[i] = false : _filteredTypes[i] = true;
    }

    var sortString = await Prefs().getStockSort();
    StockSortType sortType;
    if (sortString == 'country') {
      sortType = StockSortType.country;
    } else if (sortString == 'name') {
      sortType = StockSortType.name;
    } else if (sortString == 'type') {
      sortType = StockSortType.type;
    } else if (sortString == 'quantity') {
      sortType = StockSortType.quantity;
    } else if (sortString == 'price') {
      sortType = StockSortType.price;
    } else if (sortString == 'value') {
      sortType = StockSortType.value;
    } else if (sortString == 'profit') {
      sortType = StockSortType.profit;
    } else if (sortString == 'arrivalTime') {
      sortType = StockSortType.arrivalTime;
    } else if (sortString == 'inventoryQuantity') {
      sortType = StockSortType.inventoryQuantity;
    }
    _currentSort = StockSort(type: sortType);

    _capacity = await Prefs().getStockCapacity();
    _inventoryEnabled = await Prefs().getShowForeignInventory();
    _showArrivalTime = await Prefs().getShowArrivalTime();
    _showBarsCooldownAnalysis = await Prefs().getShowBarsCooldownAnalysis();

    _activeRestocks = await json.decode(await Prefs().getActiveRestocks());

    List<String> savedHiddenRaw = await Prefs().getHiddenForeignStocks();
    for (var s in savedHiddenRaw) {
      _hiddenStocks.add(foreignStockFromJson(s));
    }
  }

  Future<void> _showOptionsDialog() {
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
            child: StocksOptionsDialog(
              capacity: _capacity,
              callBack: _onStocksOptionsChanged,
              inventoryEnabled: _inventoryEnabled,
              showArrivalTime: _showArrivalTime,
              showBarsCooldownAnalysis: _showBarsCooldownAnalysis,
              settingsProvider: _settingsProvider,
            ),
          ),
        );
      },
    );
  }

  void _onStocksOptionsChanged(
      int newCapacity, bool inventoryEnabled, bool showArrivalTime, bool showBarsCooldownAnalysis) {
    setState(() {
      _capacity = newCapacity;
      _inventoryEnabled = inventoryEnabled;
      _showArrivalTime = showArrivalTime;
      _showBarsCooldownAnalysis = showBarsCooldownAnalysis;
    });
  }

  String _timeStampToString(int timeStamp) {
    var inputTime = DateTime.fromMillisecondsSinceEpoch(timeStamp * 1000);
    var timeDifference = DateTime.now().difference(inputTime);
    if (timeDifference.inMinutes < 1) {
      return 'seconds ago';
    } else if (timeDifference.inMinutes == 1 && timeDifference.inHours < 1) {
      return '1 minute ago';
    } else if (timeDifference.inMinutes > 1 && timeDifference.inHours < 1) {
      return '${timeDifference.inMinutes} minutes ago';
    } else if (timeDifference.inHours == 1 && timeDifference.inDays < 1) {
      return '1 hour ago';
    } else if (timeDifference.inHours > 1 && timeDifference.inDays < 1) {
      return '${timeDifference.inHours} hours ago';
    } else if (timeDifference.inDays == 1) {
      return '1 day ago';
    } else {
      return '${timeDifference.inDays} days ago';
    }
  }

  void _onFlagPressed(bool flagPressed, bool shortTap) {
    _goBack(true, shortTap);
  }

  void _onRefresh() async {
    await Future.delayed(Duration(milliseconds: 500));
    await _fetchApiInformation();

    if (!mounted) return;

    setState(() {});
    _refreshController.refreshCompleted();
    // Initialize the controller again to avoid errors
    _refreshController = RefreshController(initialRefresh: false);
  }

  CountryName _returnCountryName(String country) {
    switch (country) {
      case "Argentina":
        return CountryName.ARGENTINA;
        break;
      case "Canada":
        return CountryName.CANADA;
        break;
      case "Cayman Islands":
        return CountryName.CAYMAN_ISLANDS;
        break;
      case "China":
        return CountryName.CHINA;
        break;
      case "Hawaii":
        return CountryName.HAWAII;
        break;
      case "Japan":
        return CountryName.JAPAN;
        break;
      case "Mexico":
        return CountryName.MEXICO;
        break;
      case "South Africa":
        return CountryName.SOUTH_AFRICA;
        break;
      case "Switzerland":
        return CountryName.SWITZERLAND;
        break;
      case "UAE":
        return CountryName.UAE;
        break;
      case "United Kingdom":
        return CountryName.UNITED_KINGDOM;
        break;
      default:
        return CountryName.TORN;
        break;
    }
  }

  _refreshMoney() async {
    var profileModel = await Get.find<ApiCallerController>().getOwnProfileExtended(limit: 3);
    if (profileModel is OwnProfileExtended && mounted) {
      setState(() {
        _profile = profileModel;
      });
    }
  }

  _hideMember(ForeignStock stock) async {
    for (var s in _hiddenStocks) {
      // Repeated hiding attempt!
      if (s.id == stock.id && s.id == stock.countryCode) return;
    }

    setState(() {
      _hiddenStocks.add(stock);
    });

    _saveHiddenStocks();
  }

  _unhideMember(int id, String countryCode) {
    setState(() {
      _hiddenStocks.removeWhere((element) => element.id == id && element.countryCode == countryCode);
    });

    _saveHiddenStocks();
  }

  _saveHiddenStocks() {
    var hiddenSaveList = <String>[];
    for (var h in _hiddenStocks) {
      hiddenSaveList.add(foreignStockToJson(h));
    }
    Prefs().setHiddenForeignStocks(hiddenSaveList);
  }
}

class HiddenForeignStockDialog extends StatefulWidget {
  final ThemeProvider themeProvider;
  final List<ForeignStock> hiddenStocks;
  final Function(int, String) unhide;

  const HiddenForeignStockDialog({
    Key key,
    @required this.themeProvider,
    @required this.hiddenStocks,
    @required this.unhide,
  }) : super(key: key);

  @override
  State<HiddenForeignStockDialog> createState() => _HiddenForeignStockDialogState();
}

class _HiddenForeignStockDialogState extends State<HiddenForeignStockDialog> {
  @override
  Widget build(BuildContext context) {
    List<Widget> hiddenCards = buildCards(widget.hiddenStocks, context);
    return AlertDialog(
      backgroundColor: widget.themeProvider.secondBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      actions: [
        TextButton(
          child: const Text("Close"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
      elevation: 0.0,
      content: Container(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Reset hidden targets",
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 15),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: hiddenCards,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> buildCards(List<ForeignStock> hiddenStocks, BuildContext context) {
    List<Widget> hiddenCards = <Widget>[];
    for (ForeignStock s in hiddenStocks) {
      hiddenCards.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            IconButton(
              icon: Icon(Icons.undo),
              onPressed: () {
                setState(() {
                  widget.unhide(s.id, s.countryCode);
                });

                if (widget.hiddenStocks.isEmpty) {
                  Navigator.of(context).pop();
                }
              },
            ),
            Expanded(
              child: Card(
                color: widget.themeProvider.cardColor,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 3, 8, 3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Text(
                            s.name,
                            style: TextStyle(fontSize: 13),
                          ),
                          CountryCodeAndFlag(
                            stock: s,
                            dense: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return hiddenCards;
  }
}
