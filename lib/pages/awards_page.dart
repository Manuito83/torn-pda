// Dart imports:
import 'dart:async';

// Package imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
// Flutter imports:
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:torn_pda/drawer.dart';
// Project imports:
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/awards/awards_model.dart';
import 'package:torn_pda/models/awards/awards_sort.dart';
import 'package:torn_pda/pages/awards/awards_graphs.dart';
import 'package:torn_pda/providers/awards_provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/external/yata_comm.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/awards/award_card.dart';
import 'package:torn_pda/widgets/awards/award_card_pin.dart';
import 'package:torn_pda/widgets/other/flipping_yata.dart';
import 'package:torn_pda/widgets/webviews/pda_browser_icon.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';

class AwardsHeaderInfo {
  Map<String, String> headerInfo = <String, String>{};
  double? playerScore = 0;
  int? achievedAwards = 0;
  int? totalAwards = 0;
  int? achievedHonors = 0;
  int? totalHonors = 0;
  int? achievedMedals = 0;
  int? totalMedals = 0;
}

class AwardsPage extends StatefulWidget {
  @override
  AwardsPageState createState() => AwardsPageState();
}

class AwardsPageState extends State<AwardsPage> {
  // Main list with all awards
  final _allAwards = <Award>[];
  var _allAwardsCards = <Widget>[];
  final _allCategories = <String?, String>{};
  List<dynamic>? _allAwardsGraphs;

  // Active categories
  var _hiddenCategories = <String?>[];

  Future? _getAwardsPayload;
  bool _apiSuccess = false;
  String? _errorReason = "";

  late SettingsProvider _settingsProvider;
  late UserDetailsProvider _userProvider;
  late ThemeProvider _themeProvider;
  late AwardsProvider _pinProvider;

  final PanelController _pc = PanelController();
  final double _initFabHeight = 25.0;
  double? _fabHeight;
  final double _panelHeightOpen = 360;
  final double _panelHeightClosed = 75.0;

  // Saved prefs
  String _savedSort = "";
  bool _showAchievedAwards = false;

  final _headerInfo = AwardsHeaderInfo();

  final _popupSortChoices = <AwardsSort>[
    AwardsSort(type: AwardsSortType.percentageDes),
    AwardsSort(type: AwardsSortType.percentageAsc),
    AwardsSort(type: AwardsSortType.categoryDes),
    AwardsSort(type: AwardsSortType.categoryAsc),
    AwardsSort(type: AwardsSortType.nameDes),
    AwardsSort(type: AwardsSortType.nameAsc),
    AwardsSort(type: AwardsSortType.rarityAsc),
    AwardsSort(type: AwardsSortType.rarityDesc),
    AwardsSort(type: AwardsSortType.daysAsc),
    AwardsSort(type: AwardsSortType.daysDes),
  ];

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _userProvider = Provider.of<UserDetailsProvider>(context, listen: false);
    _pinProvider = Provider.of<AwardsProvider>(context, listen: false);
    _fabHeight = _initFabHeight;
    _getAwardsPayload = _fetchYataAndPopulate();

    analytics.setCurrentScreen(screenName: 'awards');

    routeWithDrawer = true;
    routeName = "awards";
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
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
        child: Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[
            // Main body
            FutureBuilder(
              future: _getAwardsPayload,
              builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (_apiSuccess) {
                    return Scrollbar(
                      child: Column(
                        children: [
                          Expanded(
                            child: _awardsListView(),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return _connectError();
                  }
                } else {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Text('Calling YATA...'),
                        const SizedBox(height: 30),
                        FlippingYata(),
                      ],
                    ),
                  );
                }
              },
            ),

            // Sliding panel
            FutureBuilder(
              future: _getAwardsPayload,
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
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18.0),
                        topRight: Radius.circular(18.0),
                      ),
                      onPanelSlide: (double pos) => setState(() {
                        _fabHeight = pos * (_panelHeightOpen - _panelHeightClosed) + _initFabHeight;
                      }),
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),

            // FAB
            FutureBuilder(
              future: _getAwardsPayload,
              builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (_apiSuccess) {
                    return Positioned(
                      right: 35.0,
                      bottom: _fabHeight,
                      child: FloatingActionButton.extended(
                        icon: const Icon(Icons.filter_list),
                        label: const Text("Filter"),
                        elevation: 4,
                        onPressed: () {
                          _pc.isPanelOpen ? _pc.close() : _pc.open();
                        },
                        backgroundColor: Colors.orange,
                      ),
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    final pinnedCards = <Widget>[];
    for (final pinned in _pinProvider.pinnedAwards) {
      pinnedCards.add(
        AwardCardPin(
          award: pinned,
          pinConditionChange: _onPinnedConditionChange,
        ),
      );
    }

    final Widget pinnedSection = Column(children: pinnedCards);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 15, top: 15),
            child: Row(
              children: [
                Text('Your rarity score: '
                    '${double.parse((_headerInfo.playerScore! / 10000).toStringAsFixed(2))}'),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    final String achievement = "Achieved ${_headerInfo.achievedAwards}"
                        "/${_headerInfo.totalAwards} awards\n\n"
                        "Medals ${_headerInfo.achievedMedals}"
                        "/${_headerInfo.totalMedals}\n"
                        "Honors ${_headerInfo.achievedHonors}"
                        "/${_headerInfo.totalHonors}";

                    BotToast.showText(
                      text: achievement,
                      textStyle: const TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                      ),
                      contentColor: Colors.green[700]!,
                      duration: const Duration(seconds: 6),
                      contentPadding: const EdgeInsets.all(10),
                    );
                  },
                  child: const Icon(
                    Icons.info_outline,
                    size: 19,
                  ),
                ),
              ],
            ),
          ),
          if (_pinProvider.pinnedAwards.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Text('PINNED AWARDS', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                pinnedSection,
              ],
            ),
          const SizedBox(height: 20),
          const Text('AWARDS LIST', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  ListView _awardsListView() {
    return ListView.builder(
      // We need to paint more pixels in advance for to avoid jerks in the scrollbar
      cacheExtent: 10000,
      itemCount: _allAwardsCards.length,
      itemBuilder: (BuildContext context, int index) {
        // Because we are adding a header and a footer that are standard widgets
        // and not awards, we don't check for category the first or last items
        if (index != 0 && index != _allAwardsCards.length - 1) {
          // We need to decrease _allAwards by 1, because the header moves the
          // list one position compared to the _allAwardsCards list

          if (!_showAchievedAwards && _allAwards[index - 1].achieve! * 100 == 100) {
            return const SizedBox.shrink();
          }

          if (!_hiddenCategories.contains(_allAwards[index - 1].category)) {
            return _allAwardsCards[index];
          }

          return const SizedBox.shrink();
        }
        // This return is for the header and footer
        return _allAwardsCards[index];
      },
    );
  }

  Widget _bottomPanel(ScrollController sc) {
    return Container(
      decoration: BoxDecoration(
        color: _themeProvider.secondBackground,
        borderRadius: const BorderRadius.all(Radius.circular(24.0)),
        boxShadow: [
          BoxShadow(
            blurRadius: 2.0,
            color: Colors.orange[800]!,
          ),
        ],
      ),
      margin: const EdgeInsets.all(24.0),
      child: Column(
        children: <Widget>[
          const SizedBox(
            height: 12.0,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 30,
                height: 5,
                decoration:
                    BoxDecoration(color: Colors.grey[400], borderRadius: const BorderRadius.all(Radius.circular(12.0))),
              ),
            ],
          ),
          const SizedBox(height: 40.0),
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Row(
                  children: [
                    const Text("Show achieved"),
                    Switch(
                      value: _showAchievedAwards,
                      onChanged: (value) {
                        Prefs().setShowAchievedAwards(value);
                        setState(() {
                          _showAchievedAwards = value;
                        });
                      },
                      activeTrackColor: Colors.lightGreenAccent,
                      activeColor: Colors.green,
                    ),
                  ],
                ),
                RawChip(
                  selected: _hiddenCategories.isEmpty ? true : false,
                  side: BorderSide(color: _hiddenCategories.isEmpty ? Colors.green : Colors.grey[600]!, width: 1.5),
                  avatar: CircleAvatar(
                    backgroundColor: _hiddenCategories.isEmpty ? Colors.green : Colors.grey,
                  ),
                  label: const Text(
                    "ALL",
                    style: TextStyle(
                      fontSize: 12,
                    ),
                  ),
                  selectedColor: Colors.transparent,
                  disabledColor: Colors.grey,
                  onSelected: (bool isSelected) {
                    if (isSelected) {
                      setState(() {
                        _hiddenCategories.clear();
                      });
                    } else {
                      final fullList = [];
                      for (final cat in _allCategories.keys) {
                        fullList.add(cat);
                      }
                      setState(() {
                        _hiddenCategories = List<String?>.from(fullList);
                      });
                    }
                    Prefs().setHiddenAwardCategories(_hiddenCategories);
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _categoryFilterWrap(),
          ),
        ],
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      //brightness: Brightness.dark, // For downgrade to Flutter 2.2.3
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      title: Row(
        children: [
          const Text('Awards'),
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
      leadingWidth: context.read<WebViewProvider>().splitScreenPosition != WebViewSplitPosition.off ? 50 : 80,
      leading: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              final ScaffoldState? scaffoldState = context.findRootAncestorStateOfType();
              if (scaffoldState != null) {
                scaffoldState.openDrawer();
              }
            },
          ),
          if (context.read<WebViewProvider>().splitScreenPosition == WebViewSplitPosition.off) PdaBrowserIcon(),
        ],
      ),
      actions: [
        if (_apiSuccess)
          IconButton(
            icon: Icon(
              Icons.bar_chart_outlined,
              color: _themeProvider.buttonText,
            ),
            onPressed: () async {
              // Only pass awards that are being shown in the active list
              final graphsToPass = <dynamic>[];
              for (final awardGraph in _allAwardsGraphs!) {
                for (final award in _allAwards) {
                  if (awardGraph[0] == award.name) {
                    if (!_hiddenCategories.contains(award.category)) {
                      graphsToPass.add(awardGraph);
                    }
                  }
                }
              }

              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AwardsGraphs(
                    graphInfo: graphsToPass,
                  ),
                ),
              );
            },
          )
        else
          const SizedBox.shrink(),
        if (_apiSuccess)
          PopupMenuButton<AwardsSort>(
            icon: const Icon(
              Icons.sort,
            ),
            onSelected: _sortAwards,
            itemBuilder: (BuildContext context) {
              return _popupSortChoices.map((AwardsSort choice) {
                return PopupMenuItem<AwardsSort>(
                  value: choice,
                  child: Text(
                    choice.description,
                    style: const TextStyle(
                      fontSize: 13,
                    ),
                  ),
                );
              }).toList();
            },
          )
        else
          const SizedBox.shrink(),
      ],
    );
  }

  Widget _connectError() {
    if (_errorReason == "user") {
      return Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'There was an error with YATA!',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Please make sure you have a valid account with YATA in order to '
              'use this section. ',
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                GestureDetector(
                  onTap: () async {
                    const url = 'https://yata.yt';
                    await context.read<WebViewProvider>().openBrowserPreference(
                          context: context,
                          url: url,
                          browserTapType: BrowserTapType.short,
                        );
                  },
                  child: Image.asset('images/icons/yata_logo.png', height: 35),
                ),
                const SizedBox(width: 10),
                const Flexible(
                  child: Text("Don't have one? Have you changed your API key recently? "
                      'Login here with YATA (tap the icon) and then reload this section!'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh),
                      SizedBox(width: 6),
                      Text('Reload'),
                    ],
                  ),
                  onPressed: () {
                    setState(() {
                      _getAwardsPayload = _fetchYataAndPopulate();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Text('Otherwise, there might be a problem signing in with YATA, please '
                'try again later!'),
          ],
        ),
      );
    } else {
      return const Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'There was an error contacting with YATA!',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'Please try again later.',
            ),
            SizedBox(height: 20),
            Text('If this problem reoccurs, please let us know!'),
          ],
        ),
      );
    }
  }

  Widget _categoryFilterWrap() {
    final catChips = <Widget>[];
    for (final cat in _allCategories.keys) {
      Widget catIcon = const SizedBox.shrink();
      String? catStats = _allCategories[cat];
      switch (cat) {
        case "crimes":
          catIcon = Image.asset(
            'images/awards/categories/fingerprint.png',
            height: 15,
            color: _themeProvider.mainText,
          );
        case "drugs":
          catIcon = Image.asset(
            'images/awards/categories/cannabis.png',
            height: 15,
            color: _themeProvider.mainText,
          );
        case "attacks":
          catIcon = Image.asset(
            'images/awards/categories/crosshair.png',
            height: 15,
            color: _themeProvider.mainText,
          );
        case "faction":
          catIcon = Image.asset(
            'images/awards/categories/fist.png',
            height: 15,
            color: _themeProvider.mainText,
          );
        case "items":
          catIcon = Image.asset(
            'images/awards/categories/toilet_paper.png',
            height: 15,
            color: _themeProvider.mainText,
          );
        case "travel":
          catIcon = Image.asset(
            'images/awards/categories/plane.png',
            height: 15,
            color: _themeProvider.mainText,
          );
        case "work":
          catIcon = Image.asset(
            'images/awards/categories/graduate.png',
            height: 15,
            color: _themeProvider.mainText,
          );
        case "gym":
          catIcon = Image.asset(
            'images/awards/categories/dumbbell.png',
            height: 15,
            color: _themeProvider.mainText,
          );
        case "money":
          catIcon = Image.asset(
            'images/awards/categories/piggy_bank.png',
            height: 15,
            color: _themeProvider.mainText,
          );
        case "competitions":
          catIcon = Image.asset(
            'images/awards/trophy.png',
            height: 15,
            color: _themeProvider.mainText,
          );
        case "commitment":
          catIcon = Image.asset(
            'images/awards/categories/hourglass.png',
            height: 15,
            color: _themeProvider.mainText,
          );
        case "miscellaneous":
          catIcon = Image.asset(
            'images/awards/categories/checkered_flag.png',
            height: 15,
            color: _themeProvider.mainText,
          );
        default:
          catIcon = const Text(
            'T',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          );
          catStats = _allCategories["Other"];
          break;
      }

      catChips.add(
        RawChip(
          showCheckmark: false,
          selected: _hiddenCategories.contains(cat) ? false : true,
          side: BorderSide(color: _hiddenCategories.contains(cat) ? Colors.grey[600]! : Colors.green, width: 1.5),
          avatar: catIcon,
          label: Text(catStats!, style: const TextStyle(fontSize: 12)),
          selectedColor: Colors.transparent,
          disabledColor: Colors.grey,
          onSelected: (bool isSelected) {
            String action = "";

            setState(() {
              if (isSelected) {
                action = "Added $cat";
                _hiddenCategories.remove(cat);
              } else {
                action = "Removed $cat";
                _hiddenCategories.add(cat);
              }
            });

            Prefs().setHiddenAwardCategories(_hiddenCategories);

            BotToast.showText(
              text: action,
              textStyle: const TextStyle(
                fontSize: 13,
                color: Colors.white,
              ),
              contentColor: Colors.green[800]!,
              contentPadding: const EdgeInsets.all(10),
            );
          },
        ),
      );
    }

    return Wrap(
      spacing: 5,
      children: catChips,
    );
  }

  Future _fetchYataAndPopulate() async {
    await _restorePrefs();

    final reply = await YataComm.getAwards(_userProvider.basic!.userApiKey);
    if (reply is YataError) {
      _errorReason = reply.reason;
    } else {
      await _populateInfo(reply);
      setState(() {
        _apiSuccess = true;
      });
    }
  }

  _populateInfo(Map awardsJson) async {
    // Copy graphs for later use
    _allAwardsGraphs = awardsJson["graph"];

    // Check for pinned awards
    final pinMap = awardsJson["pinnedAwards"];
    // In case something mixed up, we'll rebuild the list later
    _pinProvider.pinnedAwards.clear();
    _pinProvider.pinnedNames.clear();

    // Populate all awards
    final awardsMap = awardsJson["awards"];

    awardsMap.forEach((awardsSubcategory, awardValues) {
      final awardsMap = awardValues as Map;

      awardsMap.forEach((key, value) {
        try {
          Widget image;
          if (value["awardType"] == "Medal") {
            image = Image.asset(
              'images/awards/medals/${value["img"]}.png',
              errorBuilder: (
                BuildContext context,
                Object exception,
                StackTrace? stackTrace,
              ) {
                return const SizedBox.shrink();
              },
            );
          } else {
            image = Image.asset(
              'images/awards/honors/${value["img"]}.png',
              errorBuilder: (
                BuildContext context,
                Object exception,
                StackTrace? stackTrace,
              ) {
                return const SizedBox.shrink();
              },
            );
          }

          bool isPinned = false;
          pinMap.forEach((pinKey, pinValue) {
            if (key == pinKey) {
              isPinned = true;
            }
          });

          final singleAward = Award(
            awardKey: key,
            category: value["category"],
            subCategory: awardsSubcategory,
            name: value["name"],
            description: value["description"],
            type: value["awardType"],
            image: image as Image?,
            achieve: value["achieve"].toDouble(),
            circulation: value["circulation"] == null ? 0 : value["circulation"].toDouble(),
            rScore: value["rScore"] == null ? 0 : value["rScore"].toDouble(),
            rarity: value["rarity"],
            // Goal might be null sometimes (e.g. travel awards for < level 15)
            goal: value["goal"] == null ? 0 : value["goal"].toDouble(),
            current: value["current"] == null
                ? 0
                : value["current"] is String
                    ? double.parse(value["current"])
                    : value["current"].toDouble(),
            dateAwarded: value["awarded_time"] == null ? 0 : value["awarded_time"].toDouble(),
            daysLeft: value["left"] == null
                ? -99 // Means no time
                : value["left"] is String
                    ? double.parse(value["left"])
                    : value["left"].toDouble(),
            // Avoid lists in comments (due to bug in imports from YATA)
            comment: value["comment"] is List<dynamic> ? "" : value["comment"],
            pinned: isPinned,
            doubleMerit: value["double"],
            tripleMerit: value["triple"],
            nextCrime: value["next"],
          );

          // Assign maxFinite so that they appear first if sorted by days left
          if (singleAward.daysLeft == -1) {
            singleAward.daysLeft = double.maxFinite;
          }

          // Populate categories (for filtering) only if the category has not
          // been seen yet. Later we will add current/max to each category
          // in _populateCategoryValues()
          if (!_allCategories.containsKey(singleAward.category)) {
            _allCategories.addAll({singleAward.category: ""});
          }

          // Add to pinned list
          if (singleAward.pinned!) {
            _pinProvider.pinnedAwards.add(singleAward);
            _pinProvider.pinnedNames.add(singleAward.name);
          }

          // Populate models list
          _allAwards.add(singleAward);
        } catch (e) {
          FirebaseCrashlytics.instance.log("PDA Crash at YATA AWARD (${value["name"]}). Error: $e");
          FirebaseCrashlytics.instance.recordError(e, null);
        }
      }); // FINISH FOR EACH SINGLE-AWARD
    }); // FINISH FOR EACH SUBCATEGORY

    // Get information needed for header
    _headerInfo.playerScore = awardsJson["player"]["awardsScor"].toDouble();

    _populateCategoryValues(awardsJson["summaryByType"]);
    _buildAwardsWidgetList();

    // Sort for the first time
    final awardsSort = AwardsSort();
    switch (_savedSort) {
      case '':
        awardsSort.type = AwardsSortType.nameAsc;
      case 'percentageDes':
        awardsSort.type = AwardsSortType.percentageDes;
      case 'percentageAsc':
        awardsSort.type = AwardsSortType.percentageAsc;
      case 'categoryDes':
        awardsSort.type = AwardsSortType.categoryDes;
      case 'categoryAsc':
        awardsSort.type = AwardsSortType.categoryAsc;
      case 'nameDes':
        awardsSort.type = AwardsSortType.nameDes;
      case 'nameAsc':
        awardsSort.type = AwardsSortType.nameAsc;
      case 'rarityAsc':
        awardsSort.type = AwardsSortType.rarityAsc;
      case 'rarityDesc':
        awardsSort.type = AwardsSortType.rarityDesc;
      case 'daysAsc':
        awardsSort.type = AwardsSortType.daysAsc;
      case 'daysDes':
        awardsSort.type = AwardsSortType.daysDes;
    }
    _sortAwards(awardsSort, initialLoad: true);
  }

  /// As we are using a ListView.builder, we cannot change order of items
  /// to sort on the move. Instead, we use this method to regenerate the whole
  /// _allAwardsCards list based on the _allAwards (models) list, plus we
  /// add an extra header and footer (first and last items)
  void _buildAwardsWidgetList() {
    final Widget header = _header();
    const Widget footer = SizedBox(height: 90);

    final newList = <Widget>[];
    newList.add(header);

    for (final award in _allAwards) {
      newList.add(
        AwardCard(
          award: award,
          pinConditionChange: _onPinnedConditionChange,
        ),
      );
    }

    newList.add(footer);

    setState(() {
      _allAwardsCards = List<Widget>.from(newList);
    });
  }

  void _populateCategoryValues(Map catJson) {
    // Fill info for the header
    _headerInfo
      ..achievedAwards = catJson['AllAwards']['nAwarded']
      ..totalAwards = catJson['AllAwards']['nAwards']
      ..achievedHonors = catJson['AllHonors']['nAwarded']
      ..totalHonors = catJson['AllHonors']['nAwards']
      ..achievedMedals = catJson['AllMedals']['nAwarded']
      ..totalMedals = catJson['AllMedals']['nAwards'];

    // Then fill rest of categories in _allCategories list
    final statModel = <String, String>{};
    for (final stats in catJson.entries) {
      final catName = stats.key;
      final catStats = "${stats.value["nAwarded"]}/${stats.value["nAwards"]}";
      statModel.addAll({catName: catStats});
    }

    _allCategories.forEach((key, value) {
      for (final catStats in statModel.entries) {
        if (key!.toLowerCase() == catStats.key.toLowerCase()) {
          _allCategories.update(key, (value) => catStats.value);
        }
      }
    });
  }

  void _sortAwards(AwardsSort choice, {bool initialLoad = false}) {
    late String sortToSave;
    if (choice.type == null) return;
    switch (choice.type!) {
      case AwardsSortType.percentageDes:
        _allAwards.sort((a, b) => b.achieve!.compareTo(a.achieve!));
        _buildAwardsWidgetList();
        sortToSave = 'percentageDes';
      case AwardsSortType.percentageAsc:
        _allAwards.sort((a, b) => a.achieve!.compareTo(b.achieve!));
        _buildAwardsWidgetList();
        sortToSave = 'percentageAsc';
      case AwardsSortType.categoryDes:
        _allAwards.sort((a, b) => b.subCategory.compareTo(a.subCategory));
        _buildAwardsWidgetList();
        sortToSave = 'categoryDes';
      case AwardsSortType.categoryAsc:
        _allAwards.sort((a, b) => a.subCategory.compareTo(b.subCategory));
        _buildAwardsWidgetList();
        sortToSave = 'categoryAsc';
      case AwardsSortType.nameDes:
        _allAwards.sort((a, b) => b.name!.trim().compareTo(a.name!.trim()));
        _buildAwardsWidgetList();
        sortToSave = 'nameDes';
      case AwardsSortType.nameAsc:
        _allAwards.sort((a, b) => a.name!.trim().compareTo(b.name!.trim()));
        _buildAwardsWidgetList();
        sortToSave = 'nameAsc';
      case AwardsSortType.rarityAsc:
        _allAwards.sort((a, b) => b.rarity!.compareTo(a.rarity!));
        _buildAwardsWidgetList();
        sortToSave = 'rarityAsc';
      case AwardsSortType.rarityDesc:
        _allAwards.sort((a, b) => a.rarity!.compareTo(b.rarity!));
        _buildAwardsWidgetList();
        sortToSave = 'rarityDesc';
      case AwardsSortType.daysAsc:
        _allAwards.sort((a, b) => a.daysLeft!.compareTo(b.daysLeft!));
        // As there are some awards with daysLeft = -99 that would go first in list
        // (which makes no sense, as daysLeft cannot be accounted for these), we have
        // to take them out from the beginning and add them to the end before rebuilding the list
        final noTimeAwards = <Award>[];
        for (var i = 0; i < _allAwards.length; i++) {
          if (_allAwards[i].daysLeft == -99) {
            noTimeAwards.add(_allAwards[i]);
          } else {
            break;
          }
        }
        for (final noTime in noTimeAwards) {
          _allAwards.remove(noTime);
        }
        _allAwards.addAll(noTimeAwards);
        _buildAwardsWidgetList();
        sortToSave = 'daysAsc';
      case AwardsSortType.daysDes:
        _allAwards.sort((a, b) => b.daysLeft!.compareTo(a.daysLeft!));
        _buildAwardsWidgetList();
        sortToSave = 'daysDes';
    }
    // Only save if we are not loading from shared prefs on init
    if (!initialLoad) {
      Prefs().setAwardsSort(sortToSave);
    }
  }

  _restorePrefs() async {
    _savedSort = await Prefs().getAwardsSort();
    _showAchievedAwards = await Prefs().getShowAchievedAwards();
    _hiddenCategories = await Prefs().getHiddenAwardCategories();
  }

  _onPinnedConditionChange() {
    _buildAwardsWidgetList();
  }
}
