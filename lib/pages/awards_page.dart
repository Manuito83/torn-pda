import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/utils/external/yata_comm.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:torn_pda/widgets/other/flipping_yata.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:torn_pda/widgets/awards/award_card.dart';
import 'package:torn_pda/models/awards/awards_model.dart';
import 'package:torn_pda/models/awards/awards_sort.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/providers/awards_provider.dart';
import 'package:intl/intl.dart';
import 'package:torn_pda/utils/html_parser.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:torn_pda/pages/awards/awards_graphs.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:torn_pda/widgets/webviews/webview_dialog.dart';

class AwardsHeaderInfo {
  var headerInfo = Map<String, String>();
  double playerScore = 0;
  int achievedAwards = 0;
  int totalAwards = 0;
  int achievedHonors = 0;
  int totalHonors = 0;
  int achievedMedals = 0;
  int totalMedals = 0;
}

class AwardsPage extends StatefulWidget {
  @override
  _AwardsPageState createState() => _AwardsPageState();
}

class _AwardsPageState extends State<AwardsPage> {
  // Main list with all awards
  var _allAwards = <Award>[];
  var _allAwardsCards = <Widget>[];
  var _allCategories = Map<String, String>();
  List<dynamic> _allAwardsGraphs;

  // Active categories
  var _hiddenCategories = <String>[];

  Future _getAwardsPayload;
  bool _apiSuccess = false;
  String _errorReason = "";

  SettingsProvider _settingsProvider;
  UserDetailsProvider _userProvider;
  ThemeProvider _themeProvider;
  AwardsProvider _pinProvider;

  PanelController _pc = new PanelController();
  final double _initFabHeight = 25.0;
  double _fabHeight;
  double _panelHeightOpen = 360;
  double _panelHeightClosed = 75.0;

  // Saved prefs
  String _savedSort = "";
  bool _showAchievedAwards = false;

  var _headerInfo = AwardsHeaderInfo();

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
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return Scaffold(
      appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
      bottomNavigationBar: !_settingsProvider.appBarTop
          ? SizedBox(
              height: AppBar().preferredSize.height,
              child: buildAppBar(),
            )
          : null,
      body: Stack(
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
                      Text('Calling YATA...'),
                      SizedBox(height: 30),
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
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(18.0),
                      topRight: Radius.circular(18.0),
                    ),
                    onPanelSlide: (double pos) => setState(() {
                      _fabHeight =
                          pos * (_panelHeightOpen - _panelHeightClosed) +
                              _initFabHeight;
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
            future: _getAwardsPayload,
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
    );
  }

  Widget _header() {
    var pinnedCards = <Widget>[];
    for (var pinned in _pinProvider.pinnedAwards) {
      Widget commentIconRow = SizedBox.shrink();
      if (pinned.comment != null && pinned.comment.trim() != "") {
        pinned.comment = HtmlParser.fix(
            pinned.comment.replaceAll("<br>", "\n").replaceAll("  ", ""));
        commentIconRow = Row(
          children: [
            SizedBox(width: 4),
            GestureDetector(
              onTap: () {
                BotToast.showText(
                  text: pinned.comment,
                  textStyle: TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                  ),
                  contentColor: Colors.grey[700],
                  duration: Duration(seconds: 6),
                  contentPadding: EdgeInsets.all(10),
                );
              },
              child: Icon(
                Icons.info_outline,
                size: 19,
              ),
            ),
          ],
        );
      }

      var achievedPercentage = (pinned.achieve * 100).truncate();
      final decimalFormat = new NumberFormat("#,##0", "en_US");
      Widget pinDetails = Row(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "$achievedPercentage%",
                style: TextStyle(
                  fontSize: 12,
                ),
              ),
              Text(
                ' - ${decimalFormat.format(pinned.current.ceil())}'
                '/${decimalFormat.format(pinned.goal.ceil())}',
                style: TextStyle(fontSize: 12),
              ),
              if (pinned.daysLeft != -99)
                pinned.daysLeft > 0 && pinned.daysLeft < double.maxFinite
                    ? Text(
                        " - ${decimalFormat.format(pinned.daysLeft.round())} "
                        "days",
                        style: TextStyle(fontSize: 12),
                      )
                    : pinned.daysLeft == double.maxFinite
                        ? Row(
                            children: [
                              Text(' - '),
                              Icon(Icons.all_inclusive, size: 19),
                            ],
                          )
                        : Text(
                            " - ${(DateFormat('yyyy-MM-dd').format(
                              DateTime.fromMillisecondsSinceEpoch(
                                  pinned.dateAwarded.round() * 1000),
                            ))}",
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          )
              else
                SizedBox.shrink(),
              commentIconRow,
            ],
          ),
        ],
      );

      pinnedCards.add(
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(pinned.name),
                        SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            BotToast.showText(
                              text: pinned.description,
                              textStyle: TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                              ),
                              contentColor: Colors.grey[700],
                              duration: Duration(seconds: 6),
                              contentPadding: EdgeInsets.all(10),
                            );
                          },
                          child: Icon(
                            Icons.info_outline,
                            size: 19,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {

                        // TODO: replace with comment when syncing with YATA
                        String action = 'Pins are not being synchronized with YATA yet, please '
                            'pin or unpin your awards in YATA\'s website and refresh '
                            'this section to see the changes.';
                        Color actionColor = Colors.grey[700];

                        // TODO: add YATA post call and checks
                        /*
                        _pinProvider.removePinned(pinned);
                        _buildAwardsWidgetList();
                        */

                        BotToast.showText(
                          text: action,
                          textStyle: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                          contentColor: actionColor,
                          duration: Duration(seconds: 6),
                          contentPadding: EdgeInsets.all(10),
                        );
                      },
                      child: Icon(
                        MdiIcons.pin,
                        color: Colors.green,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                pinDetails,
              ],
            ),
          ),
        ),
      );
    }

    Widget pinnedSection = Column(children: pinnedCards);

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
                    '${double.parse((_headerInfo.playerScore / 10000).toStringAsFixed(2))}'),
                SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    String achievement =
                        "Achieved ${_headerInfo.achievedAwards}"
                        "/${_headerInfo.totalAwards} awards\n\n"
                        "Medals ${_headerInfo.achievedMedals}"
                        "/${_headerInfo.totalMedals}\n"
                        "Honors ${_headerInfo.achievedHonors}"
                        "/${_headerInfo.totalHonors}";

                    BotToast.showText(
                      text: achievement,
                      textStyle: TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                      ),
                      contentColor: Colors.green[700],
                      duration: Duration(seconds: 6),
                      contentPadding: EdgeInsets.all(10),
                    );
                  },
                  child: Icon(
                    Icons.info_outline,
                    size: 19,
                  ),
                ),
              ],
            ),
          ),
          if (_pinProvider.pinnedAwards.length > 0)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                Text('PINNED AWARDS',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                pinnedSection,
              ],
            ),
          SizedBox(height: 20),
          Text('AWARDS LIST', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
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

          if (!_showAchievedAwards &&
              _allAwards[index - 1].achieve * 100.truncate() == 100) {
            return SizedBox.shrink();
          }

          if (!_hiddenCategories.contains(_allAwards[index - 1].category)) {
            return _allAwardsCards[index];
          }

          return SizedBox.shrink();
        }
        // This return is for the header and footer
        return _allAwardsCards[index];
      },
    );
  }

  Widget _bottomPanel(ScrollController sc) {
    return Container(
      decoration: BoxDecoration(
          color: _themeProvider.background,
          borderRadius: BorderRadius.all(Radius.circular(24.0)),
          boxShadow: [
            BoxShadow(
              blurRadius: 2.0,
              color: Colors.orange[800],
            ),
          ]),
      margin: const EdgeInsets.all(24.0),
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 12.0,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 30,
                height: 5,
                decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.all(Radius.circular(12.0))),
              ),
            ],
          ),
          SizedBox(height: 40.0),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Row(
              children: <Widget>[
                Text("Show achieved awards"),
                Switch(
                  value: _showAchievedAwards,
                  onChanged: (value) {
                    SharedPreferencesModel().setShowAchievedAwards(value);
                    setState(() {
                      _showAchievedAwards = value;
                    });
                  },
                  activeTrackColor: Colors.lightGreenAccent,
                  activeColor: Colors.green,
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
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      brightness: Brightness.dark,
      title: Row(
        children: [
          Text('Awards'),
          SizedBox(width: 8),
          GestureDetector(
              onTap: () {
                BotToast.showText(
                  text:
                      "This section is part of YATA's mobile interface, all details "
                      "information and actions are directly linked to your YATA account.",
                  textStyle: TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                  ),
                  contentColor: Colors.green[800],
                  duration: Duration(seconds: 6),
                  contentPadding: EdgeInsets.all(10),
                );
              },
              child: Image.asset('images/icons/yata_logo.png', height: 28)),
        ],
      ),
      leading: new IconButton(
        icon: new Icon(Icons.menu),
        onPressed: () {
          final ScaffoldState scaffoldState =
              context.findRootAncestorStateOfType();
          scaffoldState.openDrawer();
        },
      ),
      actions: [
        _apiSuccess
            ? IconButton(
                icon: Icon(
                  Icons.bar_chart_outlined,
                  color: _themeProvider.buttonText,
                ),
                onPressed: () async {
                  // Only pass awards that are being shown in the active list
                  var graphsToPass = <dynamic>[];
                  for (var awardGraph in _allAwardsGraphs) {
                    for (var award in _allAwards) {
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
            : SizedBox.shrink(),
        _apiSuccess
            ? PopupMenuButton<AwardsSort>(
                icon: Icon(
                  Icons.sort,
                ),
                onSelected: _sortAwards,
                itemBuilder: (BuildContext context) {
                  return _popupSortChoices.map((AwardsSort choice) {
                    return PopupMenuItem<AwardsSort>(
                      value: choice,
                      child: Text(
                        choice.description,
                        style: TextStyle(
                          fontSize: 13,
                        ),
                      ),
                    );
                  }).toList();
                },
              )
            : SizedBox.shrink(),
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
            Text(
              'There was an error with YATA!',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'Please make sure you have a valid account with YATA  in order to '
              'use this section. ',
            ),
            SizedBox(height: 20),
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    openBrowserDialog(context, 'https://yata.alwaysdata.net');
                  },
                  child: Image.asset('images/icons/yata_logo.png', height: 35),
                ),
                SizedBox(width: 10),
                Flexible(
                  child: Text(
                      'Don\'t have one? Have you changed your API key recently? '
                      'Login here with YATA (tap the icon) and then reload this section!'),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RaisedButton(
                  child: Row(
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
            SizedBox(height: 30),
            Text(
                'Otherwise, there might be a problem signing in with YATA, please '
                'try again later!'),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(30),
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
    var catChips = <Widget>[];
    for (var cat in _allCategories.keys) {
      Widget catIcon = SizedBox.shrink();
      String catStats = _allCategories[cat];
      switch (cat) {
        case "crimes":
          catIcon = Image.asset(
            'images/awards/categories/fingerprint.png',
            height: 15,
            color: _themeProvider.mainText,
          );
          break;
        case "drugs":
          catIcon = Image.asset(
            'images/awards/categories/cannabis.png',
            height: 15,
            color: _themeProvider.mainText,
          );
          break;
        case "attacks":
          catIcon = Image.asset(
            'images/awards/categories/crosshair.png',
            height: 15,
            color: _themeProvider.mainText,
          );
          break;
        case "faction":
          catIcon = Image.asset(
            'images/awards/categories/fist.png',
            height: 15,
            color: _themeProvider.mainText,
          );
          break;
        case "items":
          catIcon = Image.asset(
            'images/awards/categories/toilet_paper.png',
            height: 15,
            color: _themeProvider.mainText,
          );
          break;
        case "travel":
          catIcon = Image.asset(
            'images/awards/categories/plane.png',
            height: 15,
            color: _themeProvider.mainText,
          );
          break;
        case "work":
          catIcon = Image.asset(
            'images/awards/categories/graduate.png',
            height: 15,
            color: _themeProvider.mainText,
          );
          break;
        case "gym":
          catIcon = Image.asset(
            'images/awards/categories/dumbbell.png',
            height: 15,
            color: _themeProvider.mainText,
          );
          break;
        case "money":
          catIcon = Image.asset(
            'images/awards/categories/piggy_bank.png',
            height: 15,
            color: _themeProvider.mainText,
          );
          break;
        case "competitions":
          catIcon = Image.asset(
            'images/awards/trophy.png',
            height: 15,
            color: _themeProvider.mainText,
          );
          break;
        case "commitment":
          catIcon = Image.asset(
            'images/awards/categories/hourglass.png',
            height: 15,
            color: _themeProvider.mainText,
          );
          break;
        case "miscellaneous":
          catIcon = Image.asset(
            'images/awards/categories/checkered_flag.png',
            height: 15,
            color: _themeProvider.mainText,
          );
          break;
        default:
          catIcon = Text(
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
          side: BorderSide(
              color: _hiddenCategories.contains(cat)
                  ? Colors.grey[600]
                  : Colors.green,
              width: 1.5),
          avatar: catIcon,
          label: Text(catStats, style: TextStyle(fontSize: 12)),
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

            SharedPreferencesModel()
                .setHiddenAwardCategories(_hiddenCategories);

            BotToast.showText(
              text: action,
              textStyle: TextStyle(
                fontSize: 13,
                color: Colors.white,
              ),
              contentColor: Colors.green[800],
              duration: Duration(seconds: 2),
              contentPadding: EdgeInsets.all(10),
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

    var reply = await YataComm.getAwards(_userProvider.myUser.userApiKey);
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
    var pinMap = awardsJson["pinnedAwards"];

    // Populate all awards
    var awardsMap = awardsJson["awards"];

    awardsMap.forEach((awardsSubcategory, awardValues) {
      var awardsMap = awardValues as Map;

      awardsMap.forEach((key, value) {
        try {
          Image image;
          if (value["awardType"] == "Medal") {
            image = Image.asset(
              'images/awards/medals/${value["img"]}.png',
              errorBuilder: (
                BuildContext context,
                Object exception,
                StackTrace stackTrace,
              ) {
                return SizedBox.shrink();
              },
            );
          } else {
            image = Image.asset(
              'images/awards/honors/${value["img"]}.png',
              errorBuilder: (
                BuildContext context,
                Object exception,
                StackTrace stackTrace,
              ) {
                return SizedBox.shrink();
              },
            );
          }

          bool isPinned = false;
          pinMap.forEach((pinKey, pinValue) {
            if (key == pinKey) {
              isPinned = true;
            }
          });

          var singleAward = Award(
            category: value["category"],
            subCategory: awardsSubcategory,
            name: value["name"],
            description: value["description"],
            type: value["awardType"],
            image: image,
            achieve: value["achieve"].toDouble(),
            circulation: value["circulation"].toDouble(),
            rScore: value["rScore"] == null ? 0 : value["rScore"].toDouble(),
            rarity: value["rarity"],
            // Goal might be null sometimes (e.g. travel awards for < level 15)
            goal: value["goal"] == null ? 0 : value["goal"].toDouble(),
            current: value["current"].toDouble(),
            dateAwarded: value["awarded_time"].toDouble(),
            daysLeft: value["left"] == null
                ? -99 // Means no time
                : value["left"] is String
                    ? double.parse(value["left"])
                    : value["left"].toDouble(),
            // Avoid lists in comments (due to bug in imports from YATA)
            comment: value["comment"] is List<dynamic> ? "" : value["comment"],
            pinned: isPinned,
            doubleMerit: value["double"] ?? null,
            tripleMerit: value["triple"] ?? null,
            nextCrime: value["next"] ?? null,
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
          if (singleAward.pinned) {
            _pinProvider.addPinned(singleAward);
          }

          // Populate models list
          _allAwards.add(singleAward);
        } catch (e) {
          FirebaseCrashlytics.instance
              .log("PDA Crash at YATA AWARD (${value["name"]}). Error: $e");
          FirebaseCrashlytics.instance.recordError(e, null);
        }
      }); // FINISH FOR EACH SINGLE-AWARD
    }); // FINISH FOR EACH SUBCATEGORY

    // Get information needed for header
    _headerInfo.playerScore = awardsJson["player"]["awardsScor"].toDouble();

    _populateCategoryValues(awardsJson["summaryByType"]);
    _buildAwardsWidgetList();

    // Sort for the first time
    var awardsSort = AwardsSort();
    switch (_savedSort) {
      case '':
        awardsSort.type = AwardsSortType.nameAsc;
        break;
      case 'percentageDes':
        awardsSort.type = AwardsSortType.percentageDes;
        break;
      case 'percentageAsc':
        awardsSort.type = AwardsSortType.percentageAsc;
        break;
      case 'categoryDes':
        awardsSort.type = AwardsSortType.categoryDes;
        break;
      case 'categoryAsc':
        awardsSort.type = AwardsSortType.categoryAsc;
        break;
      case 'nameDes':
        awardsSort.type = AwardsSortType.nameDes;
        break;
      case 'nameAsc':
        awardsSort.type = AwardsSortType.nameAsc;
        break;
      case 'rarityAsc':
        awardsSort.type = AwardsSortType.rarityAsc;
        break;
      case 'rarityDesc':
        awardsSort.type = AwardsSortType.rarityDesc;
        break;
      case 'daysAsc':
        awardsSort.type = AwardsSortType.daysAsc;
        break;
      case 'daysDes':
        awardsSort.type = AwardsSortType.daysDes;
        break;
    }
    _sortAwards(awardsSort, initialLoad: true);
  }

  /// As we are using a ListView.builder, we cannot change order of items
  /// to sort on the move. Instead, we use this method to regenerate the whole
  /// _allAwardsCards list based on the _allAwards (models) list, plus we
  /// add an extra header and footer (first and last items)
  void _buildAwardsWidgetList() {
    Widget header = _header();
    Widget footer = SizedBox(height: 90);

    var newList = <Widget>[];
    newList.add(header);

    for (var award in _allAwards) {
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
    var statModel = Map<String, String>();
    for (var stats in catJson.entries) {
      var catName = stats.key;
      var catStats = "${stats.value["nAwarded"]}\/${stats.value["nAwards"]}";
      statModel.addAll({catName: catStats});
    }

    _allCategories.forEach((key, value) {
      for (var catStats in statModel.entries) {
        if (key.toLowerCase() == catStats.key.toLowerCase()) {
          _allCategories.update(key, (value) => catStats.value);
        }
      }
    });
  }

  void _sortAwards(AwardsSort choice, {bool initialLoad = false}) {
    String sortToSave;
    switch (choice.type) {
      case AwardsSortType.percentageDes:
        _allAwards.sort((a, b) => b.achieve.compareTo(a.achieve));
        _buildAwardsWidgetList();
        sortToSave = 'percentageDes';
        break;
      case AwardsSortType.percentageAsc:
        _allAwards.sort((a, b) => a.achieve.compareTo(b.achieve));
        _buildAwardsWidgetList();
        sortToSave = 'percentageAsc';
        break;
      case AwardsSortType.categoryDes:
        _allAwards.sort((a, b) => b.subCategory.compareTo(a.subCategory));
        _buildAwardsWidgetList();
        sortToSave = 'categoryDes';
        break;
      case AwardsSortType.categoryAsc:
        _allAwards.sort((a, b) => a.subCategory.compareTo(b.subCategory));
        _buildAwardsWidgetList();
        sortToSave = 'categoryAsc';
        break;
      case AwardsSortType.nameDes:
        _allAwards.sort((a, b) => b.name.trim().compareTo(a.name.trim()));
        _buildAwardsWidgetList();
        sortToSave = 'nameDes';
        break;
      case AwardsSortType.nameAsc:
        _allAwards.sort((a, b) => a.name.trim().compareTo(b.name.trim()));
        _buildAwardsWidgetList();
        sortToSave = 'nameAsc';
        break;
      case AwardsSortType.rarityAsc:
        _allAwards.sort((a, b) => b.rarity.compareTo(a.rarity));
        _buildAwardsWidgetList();
        sortToSave = 'rarityAsc';
        break;
      case AwardsSortType.rarityDesc:
        _allAwards.sort((a, b) => a.rarity.compareTo(b.rarity));
        _buildAwardsWidgetList();
        sortToSave = 'rarityDesc';
        break;
      case AwardsSortType.daysAsc:
        _allAwards.sort((a, b) => b.daysLeft.compareTo(a.daysLeft));
        _buildAwardsWidgetList();
        sortToSave = 'daysAsc';
        break;
      case AwardsSortType.daysDes:
        _allAwards.sort((a, b) => a.daysLeft.compareTo(b.daysLeft));
        _buildAwardsWidgetList();
        sortToSave = 'daysDes';
        break;
    }
    // Only save if we are not loading from shared prefs on init
    if (!initialLoad) {
      SharedPreferencesModel().setAwardsSort(sortToSave);
    }
  }

  _restorePrefs() async {
    _savedSort = await SharedPreferencesModel().getAwardsSort();
    _showAchievedAwards =
        await SharedPreferencesModel().getShowAchievedAwards();
    _hiddenCategories =
        await SharedPreferencesModel().getHiddenAwardCategories();
  }

  _onPinnedConditionChange() {
    _buildAwardsWidgetList();
  }

}
