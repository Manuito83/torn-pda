// Dart imports:
import 'dart:async';

// Package imports:
// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/drawer.dart';
import 'package:torn_pda/models/chaining/ranked_wars_model.dart';
import 'package:torn_pda/providers/api_caller.dart';
// Project imports:
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/widgets/chaining/ranked_war_card.dart';
import 'package:torn_pda/widgets/chaining/ranked_war_options.dart';

class RankedWarsPage extends StatefulWidget {
  final bool calledFromMenu;

  const RankedWarsPage({this.calledFromMenu = false});

  @override
  RankedWarsPageState createState() => RankedWarsPageState();
}

class RankedWarsPageState extends State<RankedWarsPage> {
  ThemeProvider? _themeProvider;
  SettingsProvider? _settingsProvider;
  late UserDetailsProvider _userProvider;
  late WebViewProvider _webViewProvider;

  Future? _rankedWarsFetched;
  RankedWarsModel _rankedWarsModel = RankedWarsModel();

  late int _timeNow;
  int _ownFaction = 0;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    _userProvider = Provider.of<UserDetailsProvider>(context, listen: false);
    _ownFaction = _userProvider.basic!.faction!.factionId ?? 0;

    _rankedWarsFetched = _fetchRankedWards();
    _timeNow = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    routeWithDrawer = false;
    routeName = "ranked_wars";
    _settingsProvider!.willPopShouldGoBack.stream.listen((event) {
      if (mounted && routeName == "ranked_wars") _goBack();
    });
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
      child: FutureBuilder(
        future: _rankedWarsFetched,
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (_rankedWarsModel.rankedwars != null && _rankedWarsModel.rankedwars!.isNotEmpty) {
              return DefaultTabController(
                length: 3,
                child: SafeArea(
                  child: Scaffold(
                    backgroundColor: _themeProvider!.canvas,
                    appBar: _settingsProvider!.appBarTop
                        ? buildAppBarSuccess(context)
                        : PreferredSize(
                            preferredSize: const Size.fromHeight(kToolbarHeight),
                            child: Container(
                              color: _themeProvider!.currentTheme == AppTheme.light
                                  ? MediaQuery.orientationOf(context) == Orientation.portrait
                                      ? Colors.blueGrey
                                      : _themeProvider!.canvas
                                  : _themeProvider!.canvas,
                              child: Column(
                                children: <Widget>[
                                  Expanded(child: Container()),
                                  const TabBar(
                                    tabs: [
                                      Tab(text: "Active"),
                                      Tab(text: "Upcoming"),
                                      Tab(text: "Finished"),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                    bottomNavigationBar: !_settingsProvider!.appBarTop
                        ? SizedBox(
                            height: AppBar().preferredSize.height,
                            child: buildAppBarSuccess(context),
                          )
                        : null,
                    body: Container(
                      color: _themeProvider!.canvas,
                      child: Column(
                        children: [
                          Expanded(
                            child: TabBarView(
                              children: [
                                _tabActive(),
                                _tabUpcoming(),
                                _tabFinished(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            } else {
              return SafeArea(
                child: Scaffold(
                  backgroundColor: _themeProvider!.canvas,
                  appBar: _settingsProvider!.appBarTop ? buildAppBarError(context) : null,
                  body: Container(color: _themeProvider!.canvas, child: _fetchError()),
                ),
              );
            }
          } else {
            return SafeArea(
              child: Scaffold(
                backgroundColor: _themeProvider!.canvas,
                appBar: _settingsProvider!.appBarTop ? buildAppBarError(context) : null,
                body: Container(
                  color: _themeProvider!.currentTheme == AppTheme.extraDark ? Colors.black : Colors.transparent,
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _tabActive() {
    List<Widget> activeWarsCards = <Widget>[];

    final sortedByValueMap = Map.fromEntries(
      _rankedWarsModel.rankedwars!.entries.toList()
        ..sort((e1, e2) => e1.value.war!.start!.compareTo(e2.value.war!.start!)),
    );

    sortedByValueMap.forEach((key, value) {
      if (value.war!.start! < _timeNow && value.war!.end == 0 && value.factions!.containsKey(_ownFaction.toString())) {
        activeWarsCards.add(
          Column(
            children: [
              const SizedBox(height: 10),
              RankedWarCard(
                rankedWar: value,
                status: RankedWarStatus.active,
                warId: key,
                ownFactionId: _ownFaction,
                key: UniqueKey(),
              ),
              const Divider(),
            ],
          ),
        );
      }
    });

    sortedByValueMap.forEach((key, value) {
      if (value.war!.start! < _timeNow && value.war!.end == 0 && !value.factions!.containsKey(_ownFaction.toString())) {
        activeWarsCards.add(
          RankedWarCard(
            rankedWar: value,
            status: RankedWarStatus.active,
            warId: key,
            ownFactionId: _ownFaction,
            key: UniqueKey(),
          ),
        );
      }
    });

    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            children: activeWarsCards,
          ),
        ),
      ],
    );
  }

  Widget _tabUpcoming() {
    List<Widget> upComingWars = <Widget>[];

    final sortedByValueMap = Map.fromEntries(
      _rankedWarsModel.rankedwars!.entries.toList()
        ..sort((e1, e2) => e1.value.war!.start!.compareTo(e2.value.war!.start!)),
    );

    sortedByValueMap.forEach((key, value) {
      if (value.war!.start! > _timeNow && value.factions!.containsKey(_ownFaction.toString())) {
        upComingWars.add(
          Column(
            children: [
              const SizedBox(height: 10),
              RankedWarCard(
                rankedWar: value,
                status: RankedWarStatus.upcoming,
                warId: key,
                ownFactionId: _ownFaction,
                key: UniqueKey(),
              ),
              const Divider(),
            ],
          ),
        );
      }
    });

    sortedByValueMap.forEach((key, value) {
      if (value.war!.start! > _timeNow && !value.factions!.containsKey(_ownFaction.toString())) {
        upComingWars.add(
          RankedWarCard(
            rankedWar: value,
            status: RankedWarStatus.upcoming,
            warId: key,
            ownFactionId: _ownFaction,
            key: UniqueKey(),
          ),
        );
      }
    });

    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            children: upComingWars,
          ),
        ),
      ],
    );
  }

  Widget _tabFinished() {
    List<Widget> finishedWars = <Widget>[];

    final sortedByValueMap = Map.fromEntries(
      _rankedWarsModel.rankedwars!.entries.toList()
        ..sort((e1, e2) => e1.value.war!.start!.compareTo(e2.value.war!.start!)),
    );

    sortedByValueMap.forEach((key, value) {
      if (value.war!.end != 0 && value.war!.end! < _timeNow && value.factions!.containsKey(_ownFaction.toString())) {
        finishedWars.add(
          Column(
            children: [
              const SizedBox(height: 10),
              RankedWarCard(
                rankedWar: value,
                status: RankedWarStatus.finished,
                warId: key,
                ownFactionId: _ownFaction,
                key: UniqueKey(),
              ),
              const Divider(),
            ],
          ),
        );
      }
    });

    sortedByValueMap.forEach((key, value) {
      if (value.war!.end != 0 && value.war!.end! < _timeNow && !value.factions!.containsKey(_ownFaction.toString())) {
        finishedWars.add(
          RankedWarCard(
            rankedWar: value,
            status: RankedWarStatus.finished,
            warId: key,
            ownFactionId: _ownFaction,
            key: UniqueKey(),
          ),
        );
      }
    });

    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            children: finishedWars,
          ),
        ),
      ],
    );
  }

  AppBar buildAppBarSuccess(BuildContext _) {
    return AppBar(
      iconTheme: IconThemeData(color: Colors.white),
      elevation: _settingsProvider!.appBarTop ? 2 : 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor:
            _themeProvider!.currentTheme == AppTheme.light ? Colors.blueGrey : _themeProvider!.canvas,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      toolbarHeight: kMinInteractiveDimension,
      title: const Text("Ranked Wars", style: TextStyle(color: Colors.white)),
      leading: IconButton(
        icon: widget.calledFromMenu ? const Icon(Icons.dehaze) : const Icon(Icons.arrow_back),
        onPressed: () {
          _goBack();
        },
      ),
      actions: [
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
                return RankedWarOptions(
                  _themeProvider,
                  _settingsProvider,
                );
              },
            );
          },
        )
      ],
      bottom: _settingsProvider!.appBarTop
          ? const TabBar(
              tabs: [
                Tab(text: "Active"),
                Tab(text: "Upcoming"),
                Tab(text: "Finished"),
              ],
            )
          : null,
    );
  }

  AppBar buildAppBarError(BuildContext _) {
    return AppBar(
      iconTheme: IconThemeData(color: Colors.white),
      elevation: _settingsProvider!.appBarTop ? 2 : 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      title: const Text("Ranked Wars", style: TextStyle(color: Colors.white)),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
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
            Get.back();
          }
        },
      ),
    );
  }

  Future _fetchRankedWards() async {
    final dynamic apiResponse = await Get.find<ApiCallerController>().getRankedWars();

    if (apiResponse is RankedWarsModel) {
      if (apiResponse.rankedwars != null) {
        _rankedWarsModel = apiResponse;
      }
    }
  }

  Widget _fetchError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_rankedWarsModel.rankedwars != null && _rankedWarsModel.rankedwars!.isEmpty)
              Text(
                'No wars found',
                style: TextStyle(color: Colors.orange[800], fontSize: 20, fontWeight: FontWeight.bold),
              )
            else
              const Text(
                'OOPS!',
                style: TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 20),
            if (_rankedWarsModel.rankedwars != null && _rankedWarsModel.rankedwars!.isEmpty)
              const Text(
                'The ranked wars list returned from the API is empty, please try again later!',
              )
            else
              const Text(
                'There was an error getting data from the API, please try again later!',
              ),
          ],
        ),
      ),
    );
  }

  _goBack() {
    if (widget.calledFromMenu) {
      final ScaffoldState? scaffoldState = context.findRootAncestorStateOfType();
      if (scaffoldState != null) {
        if (_webViewProvider.webViewSplitActive && _webViewProvider.splitScreenPosition == WebViewSplitPosition.left) {
          scaffoldState.openEndDrawer();
        } else {
          scaffoldState.openDrawer();
        }
      }
    } else {
      routeWithDrawer = true;
      routeName = "chaining_war";
      Get.back();
    }
  }
}
