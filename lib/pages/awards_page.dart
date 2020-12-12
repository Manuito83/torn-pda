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
import 'file:///D:/PROGRAMACION/torn_pda/lib/widgets/awards/award_card.dart';
import 'package:torn_pda/models/awards/awards_model.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class AwardsPage extends StatefulWidget {
  @override
  _AwardsPageState createState() => _AwardsPageState();
}

class _AwardsPageState extends State<AwardsPage> {
  // Main list with all awards
  var _allAwards = List<Award>();
  var _allAwardsCards = List<Widget>();
  var _allCategories = Map<String, String>();

  // Active categories
  var _hiddenCategories = List<String>();

  Future _getAwardsPayload;
  bool _apiSuccess = false;

  SettingsProvider _settingsProvider;
  UserDetailsProvider _userProvider;
  ThemeProvider _themeProvider;

  PanelController _pc = new PanelController();
  final double _initFabHeight = 25.0;
  double _fabHeight;
  double _panelHeightOpen = 300;
  double _panelHeightClosed = 75.0;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _userProvider = Provider.of<UserDetailsProvider>(context, listen: false);
    _fabHeight = _initFabHeight;
    _getAwardsPayload = _fetchYataApi();
  }

  @override
  void dispose() {
    super.dispose();
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
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(left: 15, top: 5),
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: _allAwardsCards.length,
                              itemBuilder: (BuildContext context, int index) {
                                if (!_hiddenCategories
                                    .contains(_allAwards[index].category)) {
                                  return _allAwardsCards[index];
                                } else {
                                  return SizedBox.shrink();
                                }
                              },
                            ),
                          ),
                          SizedBox(height: 20),
                        ],
                      ),
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
                      Text('Fetching data...'),
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
            padding: const EdgeInsets.all(10),
            child: _categoryFilter(),
          ),
        ],
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
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
    );
  }

  Widget _connectError() {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'There was an error contacting with Yata!',
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

  Widget _categoryFilter() {
    var catChips = List<Widget>();
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

  Future _fetchYataApi() async {
    var reply = await YataComm.getAwards(_userProvider.myUser.userApiKey);
    if (reply is YataError) {
      // TODO
    } else {
      await _populateInfo(reply);
      setState(() {
        _apiSuccess = true;
      });
    }
  }

  _populateInfo(Map awardsJson) {
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
            goal: value["goal"].toDouble(),
            current: value["current"].toDouble(),
            dateAwarded: value["awarded_time"].toDouble(),
            daysLeft: value["left"] == null
                ? null
                : value["left"] is String
                    ? double.parse(value["left"])
                    : value["left"].toDouble(),
            comment: value["comment"],
            pinned: isPinned,
            doubleMerit: value["double"] ?? null,
            tripleMerit: value["triple"] ?? null,
            nextCrime: value["next"] ?? null,
          );

          // Populate main lists
          _allAwards.add(singleAward);

          // Populate categories (for filtering) only if the category has not
          // been seen yet. Later we will add current/max to each category
          // in _populateCategoryValues()
          if (!_allCategories.containsKey(singleAward.category)) {
            _allCategories.addAll({singleAward.category: ""});
          }

          _allAwardsCards.add(AwardCard(award: singleAward));
        } catch (e) {
          // TODO activate and delete print
          print(e);
          /*
          FirebaseCrashlytics.instance
              .log("PDA Crash at YATA AWARD (${value["name"]}). Error: $e");
          FirebaseCrashlytics.instance.recordError(e, null);
          */
        }
      }); // FINISH FOR EACH SINGLE-AWARD
    }); // FINISH FOR EACH SUBCATEGORY

    //_fillAllAwardsCards();
    _populateCategoryValues(awardsJson["summaryByType"]);
  }

  void _populateCategoryValues(Map catJson) {
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
}
