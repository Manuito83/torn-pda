// Dart imports:
import 'dart:async';

// Package imports:
// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/drawer.dart';
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/chaining/ranked_wars_model.dart';
import 'package:torn_pda/models/chaining/war_sort.dart';
import 'package:torn_pda/providers/api/api_v1_calls.dart';
// Project imports:
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/user_helper.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/chaining/ranked_war_card.dart';
import 'package:torn_pda/widgets/chaining/ranked_war_options.dart';

class RankedWarsPage extends StatefulWidget {
  final bool calledFromMenu;

  const RankedWarsPage({this.calledFromMenu = false});

  @override
  RankedWarsPageState createState() => RankedWarsPageState();
}

class RankedWarsPageState extends State<RankedWarsPage> with SingleTickerProviderStateMixin {
  ThemeProvider? _themeProvider;
  SettingsProvider? _settingsProvider;
  
  late WebViewProvider _webViewProvider;

  RankedWarsModel _rankedWarsModel = RankedWarsModel();

  Future? _rankedWarsFetchedAndPrefsLoaded;

  final Map<RankedWarStatus, RankedWarSortType> _defaultSortTypePerTabMap = {
    RankedWarStatus.active: RankedWarSortType.progressDes,
    RankedWarStatus.upcoming: RankedWarSortType.timeDes,
    RankedWarStatus.finished: RankedWarSortType.timeDes,
  };

  // State for sorting
  final Map<RankedWarStatus, RankedWarSortType> _sortTypePerTab = {
    RankedWarStatus.active: RankedWarSortType.progressDes,
    RankedWarStatus.upcoming: RankedWarSortType.timeDes,
    RankedWarStatus.finished: RankedWarSortType.timeDes,
  };

  TabController? _tabController;

  // State for searching
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  late int _timeNow;
  int _ownFaction = 0;

  late StreamSubscription _willPopSubscription;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 3, vsync: this);
    _tabController!.addListener(_handleTabSelection);

    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    
    _ownFaction = UserHelper.factionId;

    _rankedWarsFetchedAndPrefsLoaded = _loadPrefsAndFetchData();

    _timeNow = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    routeWithDrawer = false;
    routeName = "ranked_wars";
    _willPopSubscription = _settingsProvider!.willPopShouldGoBackStream.stream.listen((event) {
      if (mounted && routeName == "ranked_wars") _goBack();
    });

    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchTerm = _searchController.text;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController?.removeListener(_handleTabSelection);
    _tabController?.dispose();
    _searchController.dispose();
    _willPopSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context);
    _webViewProvider = Provider.of<WebViewProvider>(context);

    return Container(
      color: _themeProvider!.currentTheme == AppTheme.light
          ? MediaQuery.orientationOf(context) == Orientation.portrait
              ? Colors.blueGrey
              : isStatusBarShown
                  ? _themeProvider!.statusBar
                  : _themeProvider!.canvas
          : _themeProvider!.canvas,
      child: FutureBuilder(
        future: _rankedWarsFetchedAndPrefsLoaded,
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (_rankedWarsModel.rankedwars != null && _rankedWarsModel.rankedwars!.isNotEmpty) {
              return DefaultTabController(
                length: 3,
                initialIndex: _tabController?.index ?? 0,
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
                                      : isStatusBarShown
                                          ? _themeProvider!.statusBar
                                          : _themeProvider!.canvas
                                  : _themeProvider!.canvas,
                              child: Column(
                                children: <Widget>[
                                  Expanded(child: Container()),
                                  TabBar(
                                    controller: _tabController,
                                    tabs: const [
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
                              controller: _tabController,
                              children: [
                                _buildTabContent(RankedWarStatus.active),
                                _buildTabContent(RankedWarStatus.upcoming),
                                _buildTabContent(RankedWarStatus.finished),
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

  Widget _buildTabContent(RankedWarStatus status) {
    RankedWar? ownFactionWar;
    String? ownFactionWarKey;
    Map<String, RankedWar> otherFactionWars = {};

    // Filter and separate other wars from own
    _rankedWarsModel.rankedwars?.forEach((key, value) {
      bool includeInTab = false;
      switch (status) {
        case RankedWarStatus.active:
          includeInTab = value.war?.start != null && value.war!.start! < _timeNow && value.war!.end == 0;
          break;
        case RankedWarStatus.upcoming:
          includeInTab = value.war?.start != null && value.war!.start! > _timeNow;
          break;
        case RankedWarStatus.finished:
          includeInTab = value.war?.end != null && value.war!.end! != 0 && value.war!.end! < _timeNow;
          break;
      }

      if (includeInTab) {
        if (ownFactionWar == null && (value.factions?.containsKey(_ownFaction.toString()) ?? false)) {
          ownFactionWar = value;
          ownFactionWarKey = key;
        } else {
          otherFactionWars[key] = value;
        }
      }
    });

    // Search and filter own war
    if (_isSearching && _searchTerm.isNotEmpty && ownFactionWar != null) {
      bool ownWarMatchesSearch = false;
      if (ownFactionWar!.factions != null) {
        for (var faction in ownFactionWar!.factions!.values) {
          if (faction.name != null && faction.name!.toLowerCase().contains(_searchTerm)) {
            ownWarMatchesSearch = true;
            break;
          }
        }
      }
      if (!ownWarMatchesSearch) {
        ownFactionWar = null;
        ownFactionWarKey = null;
      }
    }

    final RankedWarSortType currentSortForThisTab = _getCurrentSortTypeForTab(status);
    final Map<String, RankedWar> sortedOtherFactionWars =
        _applySearchAndSort(otherFactionWars, status, currentSortForThisTab);

    // Create cards
    List<Widget> warCards = [];

    // Add own faction war if exists, then others
    if (ownFactionWar != null && ownFactionWarKey != null) {
      warCards.add(
        Column(
          children: [
            const SizedBox(height: 10),
            RankedWarCard(
              key: ValueKey("other_$ownFactionWarKey"),
              rankedWar: ownFactionWar!,
              status: status,
              warId: ownFactionWarKey!,
              ownFactionId: _ownFaction,
            ),
          ],
        ),
      );

      if (sortedOtherFactionWars.isNotEmpty) {
        warCards.add(const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Divider(thickness: 2, color: Colors.grey),
        ));
      }
    }

    sortedOtherFactionWars.forEach((key, value) {
      warCards.add(
        RankedWarCard(
          key: ValueKey("other_$key"),
          rankedWar: value,
          status: status,
          warId: key,
          ownFactionId: _ownFaction,
        ),
      );
    });

    return _buildWarList(warCards);
  }

  Widget _buildWarList(List<Widget> warCards) {
    if (warCards.isEmpty) {
      String message = "No wars in this category.";
      if (_isSearching && _searchTerm.isNotEmpty) {
        message = "No wars found matching '$_searchTerm'";
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            message,
            style: TextStyle(fontSize: 16, color: _themeProvider?.mainText),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView(children: warCards);
  }

  AppBar buildAppBarSuccess(BuildContext _) {
    final currentTabIndex = _tabController?.index ?? 0;

    RankedWarStatus currentTabStatus = RankedWarStatus.values[currentTabIndex];
    RankedWarSortType currentSortTypeForThisTab = _getCurrentSortTypeForTab(currentTabStatus);

    List<RankedWarSortType> availableSortTypes = [RankedWarSortType.timeAsc, RankedWarSortType.timeDes];
    if (currentTabStatus == RankedWarStatus.active) {
      availableSortTypes.addAll([RankedWarSortType.progressAsc, RankedWarSortType.progressDes]);
    }

    return AppBar(
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: _settingsProvider!.appBarTop ? 2 : 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: _themeProvider!.statusBar,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      toolbarHeight: kMinInteractiveDimension,
      leading: IconButton(
        icon: _isSearching
            ? const Icon(Icons.close)
            : (widget.calledFromMenu ? const Icon(Icons.dehaze) : const Icon(Icons.arrow_back)),
        onPressed: () {
          if (_isSearching) {
            setState(() {
              _isSearching = false;
              _searchController.clear();
            });
          } else {
            _goBack();
          }
        },
      ),
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search by faction name...',
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
              ),
              style: const TextStyle(color: Colors.white, fontSize: 18),
            )
          : const Text("Ranked Wars", style: TextStyle(color: Colors.white)),
      actions: _isSearching
          ? []
          : [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  setState(() {
                    _isSearching = true;
                  });
                },
              ),
              // Note: depending on the tab, we'll change the popupmenu options
              PopupMenuButton<RankedWarSortType>(
                icon: const Icon(Icons.sort),
                tooltip: "Sort wars",
                onSelected: (RankedWarSortType result) {
                  setState(() {
                    _sortTypePerTab[currentTabStatus] = result;
                    _saveSortPreferences();
                  });
                },
                itemBuilder: (BuildContext context) {
                  return availableSortTypes.map((type) {
                    final sortOption = RankedWarSort(type: type);
                    final bool isSelected = type == currentSortTypeForThisTab;
                    return PopupMenuItem<RankedWarSortType>(
                      value: type,
                      child: Row(
                        children: [
                          if (isSelected)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Icon(
                                Icons.arrow_forward_ios_outlined,
                                color: _themeProvider?.mainText ?? Colors.black,
                                size: 15,
                              ),
                            ),
                          Flexible(
                            child: Text(
                              sortOption.description,
                              style: TextStyle(
                                fontSize: 13,
                                color: _themeProvider?.mainText ?? Colors.black,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList();
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings),
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
      bottom: _settingsProvider!.appBarTop && !_isSearching
          ? TabBar(
              controller: _tabController,
              tabs: const [
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
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: _settingsProvider!.appBarTop ? 2 : 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      title: const Text("Ranked Wars", style: TextStyle(color: Colors.white)),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          _goBack();
        },
      ),
    );
  }

  Future<void> _fetchRankedWards() async {
    final dynamic apiResponse = await ApiCallsV1.getRankedWars();
    if (!mounted) return;

    if (apiResponse is RankedWarsModel) {
      setState(() {
        _rankedWarsModel = apiResponse;
        _rankedWarsModel.rankedwars ??= {};
      });
    } else {
      setState(() {
        _rankedWarsModel = RankedWarsModel(rankedwars: {});
      });
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

  Map<String, RankedWar> _applySearchAndSort(
      Map<String, RankedWar> inputWars, RankedWarStatus statusContext, RankedWarSortType sortType) {
    Map<String, RankedWar> warsToProcess = Map.from(inputWars);

    // Search
    if (_isSearching && _searchTerm.isNotEmpty) {
      warsToProcess.removeWhere((key, rankedWar) {
        bool match = false;
        if (rankedWar.factions != null) {
          for (var faction in rankedWar.factions!.values) {
            if (faction.name != null && faction.name!.toLowerCase().contains(_searchTerm)) {
              match = true;
              break;
            }
          }
        }
        return !match;
      });
    }

    // Sort
    var sortedEntries = warsToProcess.entries.toList();

    double getScoreDifferencePercent(RankedWar rankedWar) {
      final targetScoreValue = rankedWar.war?.target;

      if (targetScoreValue == null || targetScoreValue == 0) {
        return 0.0;
      }

      List<WarFaction> factionsList = rankedWar.factions!.values.toList();
      double score1 = (factionsList[0].score ?? 0).toDouble();
      double score2 = (factionsList[1].score ?? 0).toDouble();
      double targetScore = targetScoreValue.toDouble();

      double absoluteDifference = (score1 - score2).abs();
      return (absoluteDifference / targetScore) * 100.0;
    }

    // Sort time changes depending on the tab we use
    int getTimeValue(RankedWar war) {
      if (statusContext == RankedWarStatus.finished) {
        return war.war?.end ?? 0;
      }
      return war.war?.start ?? 0;
    }

    switch (sortType) {
      case RankedWarSortType.timeAsc:
        sortedEntries.sort((e1, e2) => getTimeValue(e1.value).compareTo(getTimeValue(e2.value)));
        break;
      case RankedWarSortType.timeDes:
        sortedEntries.sort((e1, e2) => getTimeValue(e2.value).compareTo(getTimeValue(e1.value)));
        break;
      case RankedWarSortType.progressAsc:
        if (statusContext == RankedWarStatus.active) {
          sortedEntries.sort((e1, e2) {
            final diffPercent1 = getScoreDifferencePercent(e1.value);
            final diffPercent2 = getScoreDifferencePercent(e2.value);
            return diffPercent1.compareTo(diffPercent2);
          });
        } else {
          // Fallback for Upcoming/Finished
          sortedEntries.sort((e1, e2) => getTimeValue(e1.value).compareTo(getTimeValue(e2.value)));
        }
        break;
      case RankedWarSortType.progressDes:
        if (statusContext == RankedWarStatus.active) {
          sortedEntries.sort((e1, e2) {
            final diffPercent1 = getScoreDifferencePercent(e1.value);
            final diffPercent2 = getScoreDifferencePercent(e2.value);
            return diffPercent2.compareTo(diffPercent1);
          });
        } else {
          // Fallback
          sortedEntries.sort((e1, e2) => getTimeValue(e2.value).compareTo(getTimeValue(e1.value)));
        }
        break;
    }
    return Map.fromEntries(sortedEntries);
  }

  void _goBack() {
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
      Navigator.pop(context);
    }
  }

  void _handleTabSelection() {
    if (_tabController!.indexIsChanging || !mounted) return;

    RankedWarStatus currentTabStatus = RankedWarStatus.values[_tabController!.index];
    RankedWarSortType currentSortForTab =
        _sortTypePerTab[currentTabStatus] ?? _defaultSortTypePerTabMap[currentTabStatus]!;

    bool sortTypeIsInvalidForTab =
        (currentTabStatus == RankedWarStatus.upcoming || currentTabStatus == RankedWarStatus.finished) &&
            (currentSortForTab == RankedWarSortType.progressAsc || currentSortForTab == RankedWarSortType.progressDes);

    if (sortTypeIsInvalidForTab) {
      setState(() {
        _sortTypePerTab[currentTabStatus] = _defaultSortTypePerTabMap[currentTabStatus]!;
        _saveSortPreferences();
      });
    } else {
      setState(() {});
    }
  }

  RankedWarSortType _getCurrentSortTypeForTab(RankedWarStatus tabStatus) {
    return _sortTypePerTab[tabStatus] ?? RankedWarSortType.timeDes;
  }

  Future<void> _loadSortPreferences() async {
    String prefsString = await Prefs().getRankerWarSortPerTab();
    List<String> tabPrefs = prefsString.split('-');

    Map<RankedWarStatus, RankedWarSortType> loadedSorts = {};

    for (String prefEntry in tabPrefs) {
      if (prefEntry.isEmpty) continue;
      List<String> parts = prefEntry.split('#');
      if (parts.length == 2) {
        RankedWarStatus? status;
        if (parts[0] == 'active') status = RankedWarStatus.active;
        if (parts[0] == 'upcoming') status = RankedWarStatus.upcoming;
        if (parts[0] == 'finished') status = RankedWarStatus.finished;

        // Match the sort type
        RankedWarSortType? sortType;
        if (status != null) {
          try {
            sortType = RankedWarSortType.values.firstWhere(
              (e) => e.name == parts[1],
            );
          } catch (e) {
            sortType = null;
          }
        }

        // Check if the sort type is valid for the status
        // and set it to the default if not
        // (e.g., progress sort types are not valid for upcoming/finished)
        if (status != null && sortType != null) {
          bool isValidForTab = true;
          if ((status == RankedWarStatus.upcoming || status == RankedWarStatus.finished) &&
              (sortType == RankedWarSortType.progressAsc || sortType == RankedWarSortType.progressDes)) {
            isValidForTab = false;
          }

          if (isValidForTab) {
            loadedSorts[status] = sortType;
          } else {
            loadedSorts[status] = _defaultSortTypePerTabMap[status]!;
          }
        } else if (status != null) {
          loadedSorts[status] = _defaultSortTypePerTabMap[status]!;
        }
      }
    }

    if (mounted) {
      setState(() {
        _sortTypePerTab[RankedWarStatus.active] =
            loadedSorts[RankedWarStatus.active] ?? _defaultSortTypePerTabMap[RankedWarStatus.active]!;
        _sortTypePerTab[RankedWarStatus.upcoming] =
            loadedSorts[RankedWarStatus.upcoming] ?? _defaultSortTypePerTabMap[RankedWarStatus.upcoming]!;
        _sortTypePerTab[RankedWarStatus.finished] =
            loadedSorts[RankedWarStatus.finished] ?? _defaultSortTypePerTabMap[RankedWarStatus.finished]!;
      });
    }
  }

  Future<void> _loadPrefsAndFetchData() async {
    await _loadSortPreferences();
    await _fetchRankedWards();
  }

  Future<void> _saveSortPreferences() async {
    String activeSort =
        'active#${(_sortTypePerTab[RankedWarStatus.active] ?? _defaultSortTypePerTabMap[RankedWarStatus.active]!).toString().split('.').last}';
    String upcomingSort =
        'upcoming#${(_sortTypePerTab[RankedWarStatus.upcoming] ?? _defaultSortTypePerTabMap[RankedWarStatus.upcoming]!).toString().split('.').last}';
    String finishedSort =
        'finished#${(_sortTypePerTab[RankedWarStatus.finished] ?? _defaultSortTypePerTabMap[RankedWarStatus.finished]!).toString().split('.').last}';
    await Prefs().setRankerWarSortPerTab('$activeSort-$upcomingSort-$finishedSort');
  }
}
