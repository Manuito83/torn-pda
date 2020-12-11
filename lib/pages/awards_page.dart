import 'dart:async';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/utils/external/yata_comm.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:torn_pda/widgets/other/flipping_yata.dart';
import 'package:intl/intl.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:torn_pda/utils/html_parser.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class Award {
  Award({
    this.name = "",
    this.description = "",
    this.category = '',
    this.subCategory = "",
    this.type = "",
    this.image,
    this.achieve = 0,
    this.circulation = 0,
    this.rScore = 0,
    this.rarity = "",
    this.goal = 0,
    this.current = 0,
    this.dateAwarded = 0,
    this.daysLeft = 0,
    this.comment = "",
    this.pinned,
    this.doubleMerit,
    this.tripleMerit,
    this.nextCrime,
  });

  String name;
  String description;
  String category;
  String subCategory;
  String type;
  Image image;
  double achieve;
  double circulation;
  double rScore;
  String rarity;
  double goal;
  double current;
  double dateAwarded;
  double daysLeft;
  String comment;
  bool pinned;
  bool doubleMerit;
  bool tripleMerit;
  bool nextCrime;
}

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
                                if (!_hiddenCategories.contains(_allAwards[index].category)) {
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
            child: SizedBox(height: 70, child: _categoryFilter()),
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

  void _fillAllAwardsCards() {
    for (var award in _allAwards) {

      Color borderColor = Colors.transparent;
      if (award.achieve == 1) {
        borderColor = Colors.green;
      } else if (award.achieve > 0.80 && award.achieve < 1) {
        borderColor = Colors.blue;
      }

      Row titleRow = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          award.type == "Honor" ? award.image : Text(award.name),
          Row(
            children: [
              award.doubleMerit != null ||
                      award.tripleMerit != null ||
                      award.nextCrime != null
                  ? GestureDetector(
                      onTap: () {
                        String special = "";

                        if (award.nextCrime != null) {
                          special = "Next crime to do!";
                        } else if (award.tripleMerit != null) {
                          special = "Triple merit!";
                        } else if (award.doubleMerit != null) {
                          special = "Double merit!";
                        }

                        BotToast.showText(
                          text: special,
                          textStyle: TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                          ),
                          contentColor: Colors.green[800],
                          duration: Duration(seconds: 6),
                          contentPadding: EdgeInsets.all(10),
                        );
                      },
                      child: Image.asset(
                        award.nextCrime != null
                            ? 'images/awards/trophy.png'
                            : award.tripleMerit != null
                                ? 'images/awards/triple_merit.png'
                                : 'images/awards/double_merit.png',
                        height: 18,
                      ),
                    )
                  : SizedBox.shrink(),
              SizedBox(width: 8),
              award.pinned
                  ? Icon(
                      MdiIcons.pin,
                      color: Colors.green,
                      size: 20,
                    )
                  : Icon(
                      MdiIcons.pinOutline,
                      size: 20,
                    ),
            ],
          )
        ],
      );

      Row descriptionRow = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              '${award.description}',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      );

      Widget commentIconRow = SizedBox.shrink();
      if (award.comment != null) {
        award.comment = HtmlParser.fix(
            award.comment.replaceAll("<br>", "\n").replaceAll("  ", ""));
        commentIconRow = Row(
          children: [
            SizedBox(width: 4),
            GestureDetector(
              onTap: () {
                BotToast.showText(
                  text: award.comment,
                  textStyle: TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                  ),
                  contentColor: Colors.grey[800],
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

      var achievedPercentage = (award.achieve * 100).round();
      final decimalFormat = new NumberFormat("#,##0", "en_US");
      final rarityFormat = new NumberFormat("##0.0000", "en_US");
      Widget detailsRow = Row(
        children: [
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "$achievedPercentage%",
                      style: TextStyle(
                        fontSize: 12,
                        color: achievedPercentage == 100
                            ? Colors.green
                            : _themeProvider.mainText,
                      ),
                    ),
                    Text(
                      ' - ${decimalFormat.format(award.current.ceil())}'
                      '/${decimalFormat.format(award.goal.ceil())}',
                      style: TextStyle(fontSize: 12),
                    ),
                    award.daysLeft != null
                        ? award.daysLeft > 0
                            ? Text(
                                " - ${decimalFormat.format(award.daysLeft.round())} "
                                "days",
                                style: TextStyle(fontSize: 12),
                              )
                            : award.daysLeft == 0
                                ? Text(
                                    " - ${(DateFormat('yyyy-MM-dd').format(
                                      DateTime.fromMillisecondsSinceEpoch(
                                          award.dateAwarded.round() * 1000),
                                    ))}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey,
                                    ),
                                  )
                                : Row(
                                    children: [
                                      Text(' - '),
                                      Icon(Icons.all_inclusive, size: 19),
                                    ],
                                  )
                        : SizedBox.shrink(),
                    commentIconRow,
                  ],
                ),
                Container(width: 10),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "${decimalFormat.format(award.circulation)}",
                      style: TextStyle(fontSize: 12),
                    ),
                    SizedBox(width: 5),
                    GestureDetector(
                      onTap: () {
                        BotToast.showText(
                          text:
                              "Circulation: ${decimalFormat.format(award.circulation)}\n\n "
                              "Rarity: ${award.rarity}\n\n"
                              "Score: ${rarityFormat.format(award.rScore)}%",
                          textStyle: TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                          ),
                          contentColor: Colors.grey[800],
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
              ],
            ),
          ),
        ],
      );

      ConstrainedBox category = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: 50),
        child: RotatedBox(
          quarterTurns: 3,
          child: Text(
            award.subCategory.toUpperCase(),
            softWrap: true,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              fontSize: 7,
            ),
          ),
        ),
      );

      // MAIN CARD
      Widget mainCard = SizedBox.shrink();
      if (award.type == "Honor") {
        mainCard = Card(
          shape: RoundedRectangleBorder(
            side: BorderSide(color: borderColor, width: 1.5),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            child: Row(
              children: [
                category,
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      titleRow,
                      SizedBox(height: 5),
                      descriptionRow,
                      SizedBox(height: 5),
                      detailsRow,
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (award.type == "Medal") {
        mainCard = Card(
          shape: RoundedRectangleBorder(
            side: BorderSide(color: borderColor, width: 1.5),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            child: Row(
              children: [
                category,
                SizedBox(width: 5),
                award.image,
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      titleRow,
                      SizedBox(height: 5),
                      descriptionRow,
                      SizedBox(height: 5),
                      detailsRow,
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }

      _allAwardsCards.add(mainCard);
    }
  }

  Widget _categoryFilter() {
    var catChips = List<Widget>();
    for (var cat in _allCategories.keys) {
      Widget catIcon = SizedBox.shrink();
      String catStats = "";
      switch (cat) {
        case "crimes":
          catIcon = Image.asset(
            'images/awards/categories/fingerprint.png',
            height: 16,
          );
          catStats = _allCategories["crimes"];
          break;
        case "drugs":
          break;
        case "attacks":
          break;
        case "faction":
          break;
        case "items":
          break;
        case "travel":
          break;
        case "work":
          break;
        case "gym":
          break;
        case "money":
          break;
        case "competitions":
          break;
        case "commitment":
          break;
        case "miscellaneous":
          break;
      }

      catChips.add(
        GestureDetector(
          child: Chip(
            side: BorderSide(
                color: _hiddenCategories.contains(cat)
                    ? Colors.grey[800]
                    : Colors.green,
                width: 1.5),
            avatar: catIcon,
            label: Text(catStats, style: TextStyle(fontSize: 12)),
          ),
          onTap: () {

            String action = "";
            if (_hiddenCategories.contains(cat)) {
              action = "Added $cat";
              _hiddenCategories.remove(cat);
            } else {
              action = "Removed $cat";
              _hiddenCategories.add(cat);
            }

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

    _fillAllAwardsCards();
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
