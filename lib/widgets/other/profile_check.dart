// Dart imports:
import 'dart:convert';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:expandable/expandable.dart';
import 'package:http/http.dart' as http;
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

// Project imports:
import 'package:torn_pda/models/chaining/yata/yata_spy_model.dart';
import 'package:torn_pda/models/profile/other_profile_model.dart';
import 'package:torn_pda/providers/friends_provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/utils/api_caller.dart';
import 'package:torn_pda/utils/number_formatter.dart';
import 'package:torn_pda/utils/offset_animation.dart';
import 'package:torn_pda/utils/timestamp_ago.dart';

enum ProfileCheckType {
  profile,
  attack,
}

class ProfileAttackCheckWidget extends StatefulWidget {
  final int profileId;
  final String apiKey;
  final ProfileCheckType profileCheckType;

  ProfileAttackCheckWidget(
      {@required this.profileId,
      @required this.apiKey,
      @required this.profileCheckType,
      @required Key key})
      : super(key: key);

  @override
  _ProfileAttackCheckWidgetState createState() =>
      _ProfileAttackCheckWidgetState();
}

class _ProfileAttackCheckWidgetState extends State<ProfileAttackCheckWidget> {
  final _levelTriggers = [2, 6, 11, 26, 31, 50, 71, 100];
  final _crimesTriggers = [100, 5000, 10000, 20000, 30000, 50000];
  final _networthTriggers = [
    5000000,
    50000000,
    500000000,
    5000000000,
    50000000000
  ];

  final _ranksTriggers = {
    "Absolute beginner": 1,
    "Beginner": 2,
    "Inexperienced": 3,
    "Rookie": 4,
    "Novice": 5,
    "Below average": 6,
    "Average": 7,
    "Reasonable": 8,
    "Above average": 9,
    "Competent": 10,
    "Highly competent": 11,
    "Veteran": 12,
    "Distinguished": 13,
    "Highly distinguished": 14,
    "Professional": 15,
    "Star": 16,
    "Master": 17,
    "Outstanding": 18,
    "Celebrity": 19,
    "Supreme": 20,
    "Idolized": 21,
    "Champion": 22,
    "Heroic": 23,
    "Legendary": 24,
    "Elite": 25,
    "Invincible": 26,
  };

  final _statsResults = [
    "< 2k",
    "2k - 25k",
    "20k - 250k",
    "200k - 2.5M",
    "2M - 25M",
    "20M - 250M",
    "> 200M",
  ];

  Future _checkedPerson;
  bool _infoToShow = false;
  bool _errorToShow = false;

  SettingsProvider _settingsProvider;

  UserDetailsProvider _userDetails;
  var _expandableController = ExpandableController();

  Widget _estimatedStatsWidget; // Has to be null at the beginning
  Widget _errorDetailsWidget = SizedBox.shrink();

  var _isTornPda = false;
  var _isPartner = false;
  var _isFriend = false;
  var _isOwnPlayer = false;
  var _isOwnFaction = false;
  var _isFriendlyFaction = false;
  var _isWorkColleague = false;
  // This one will take own player, own faction or friendly faction (so that
  // we don't show them separately, but by importance (first one self, then
  // own faction and lastly friendly faction)
  var _networthWidgetEnabled = false;

  Widget _tornPdaWidget = SizedBox.shrink();
  Widget _partnerWidget = SizedBox.shrink();
  Widget _friendsWidget = SizedBox.shrink();
  Widget _friendlyFactionWidget = SizedBox.shrink();
  Widget _workColleagueWidget = SizedBox.shrink();
  Widget _playerOrFactionWidget = SizedBox.shrink();
  Widget _networthWidget = SizedBox.shrink();

  Color _backgroundColor = Colors.grey[900];

  @override
  void initState() {
    super.initState();
    _userDetails = context.read<UserDetailsProvider>();
    _settingsProvider = context.read<SettingsProvider>();
    _checkedPerson = _fetchAndAssess();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _checkedPerson,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (_infoToShow) {
            return ExpandablePanel(
              collapsed: null,
              controller: _expandableController,
              expanded: mainWidgetBox(),
            );
          } else if (_errorToShow) {
            return ExpandablePanel(
              collapsed: null,
              controller: _expandableController,
              expanded: _errorDetailsWidget,
            );
          } else {
            return SizedBox.shrink();
          }
        }
        return SizedBox.shrink();
      },
    );
  }

  Widget mainWidgetBox() {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_estimatedStatsWidget != null) _estimatedStatsWidget,
              if (_networthWidgetEnabled) _networthWidget,
              if (_isTornPda) _tornPdaWidget,
              // Container so that the background color can be changed for certain widgets
              Container(
                color: _backgroundColor,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(15, 0, 15, 0),
                  child: Column(
                    children: [
                      if (_isPartner)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: _partnerWidget,
                        ),
                      if (_isFriend)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: _friendsWidget,
                        ),
                      if (_isOwnFaction || _isOwnPlayer)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: _playerOrFactionWidget,
                        ),
                      if (_isFriendlyFaction)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: _friendlyFactionWidget,
                        ),
                      if (_isWorkColleague)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: _workColleagueWidget,
                        ),
                      if (_isWorkColleague ||
                          _isFriendlyFaction ||
                          _isFriendlyFaction ||
                          _isFriend ||
                          _isOwnFaction ||
                          _isPartner ||
                          _isOwnPlayer)
                        SizedBox(height: 2)
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _fetchAndAssess() async {
    var otherProfile = await TornApiCaller.target(
      widget.apiKey,
      widget.profileId.toString(),
    ).getOtherProfile;

    // FRIEND CHECK
    var friendsProv = context.read<FriendsProvider>();
    if (!friendsProv.initialized) {
      await friendsProv.initFriends();
    }
    for (var friend in friendsProv.allFriends) {
      if (friend.playerId == widget.profileId) _isFriend = true;
    }

    if (otherProfile is OtherProfileModel) {
      // Estimated stats is not awaited, since it can take a few seconds
      // to contact YATA and decide what we show
      estimatedStatsCalculator(otherProfile);

      if (otherProfile.playerId == 2225097) {
        _isTornPda = true;
      }

      if (otherProfile.married.spouseId == _userDetails.basic.playerId) {
        _isPartner = true;
      }

      if (otherProfile.playerId == _userDetails.basic.playerId) {
        _isOwnPlayer = true;
      }

      if (_userDetails.basic.faction.factionId != 0 &&
          otherProfile.faction.factionId ==
              _userDetails.basic.faction.factionId) {
        _isOwnFaction = true;
      }

      var settingsProvider = context.read<SettingsProvider>();
      for (var fact in settingsProvider.friendlyFactions) {
        if (otherProfile.faction.factionId == fact.id) {
          _isFriendlyFaction = true;
          break;
        }
      }

      if (!_isOwnPlayer &&
          otherProfile.job.companyId != 0 &&
          otherProfile.job.companyId == _userDetails.basic.job.companyId) {
        _isWorkColleague = true;
      }

      _networthWidgetEnabled = _settingsProvider.extraPlayerNetworth;

      if (_isTornPda) {
        _tornPdaWidget = Container(
          color: Colors.grey[900],
          child: Padding(
            padding: EdgeInsets.fromLTRB(15, 4, 15, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Image.asset(
                  'images/icons/torn_pda.png',
                  width: 16,
                  height: 16,
                  //color: Colors.brown[400],
                ),
                SizedBox(width: 10),
                Flexible(
                  child: Text(
                    "Hi! Thank you for using Torn PDA!",
                    style: TextStyle(
                      color: Colors.pink,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      if (_isFriend) {
        Color friendTextColor = Colors.green;
        String friendText = "This is a friend of yours!";
        if (widget.profileCheckType == ProfileCheckType.attack) {
          friendTextColor = Colors.black;
          friendText = "CAUTION: this is a friend of yours!";
          _backgroundColor = Colors.red;
        }
        _friendsWidget = Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(
              Icons.people,
              color: friendTextColor,
              size: 15,
            ),
            SizedBox(width: 10),
            Flexible(
              child: Text(
                friendText,
                style: TextStyle(
                  color: friendTextColor,
                  fontSize: 12,
                  fontWeight: friendText.contains("CAUTION")
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
          ],
        );
      }

      if (_isOwnPlayer) {
        _playerOrFactionWidget = Row(
          children: [
            Icon(
              MdiIcons.heart,
              color: Colors.green,
              size: 16,
            ),
            SizedBox(width: 10),
            Flexible(
              child: Text(
                "This is you, you're beautiful!",
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        );
      } else if (_isOwnFaction) {
        String factionText = "This is a fellow faction member "
            "(${otherProfile.faction.position})!";
        Color factionColor = Colors.green;
        if (widget.profileCheckType == ProfileCheckType.attack) {
          factionColor = Colors.black;
          factionText = "CAUTION: this is a fellow faction member!";
          _backgroundColor = Colors.red;
        }
        _playerOrFactionWidget = Row(
          children: [
            Image.asset(
              'images/icons/faction.png',
              width: 15,
              height: 12,
              color: factionColor,
            ),
            SizedBox(width: 10),
            Flexible(
              child: Text(
                factionText,
                style: TextStyle(
                  color: factionColor,
                  fontWeight: factionText.contains("CAUTION")
                      ? FontWeight.bold
                      : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        );
      } else if (_isFriendlyFaction) {
        String factionText = "This is an allied faction member "
            "(${otherProfile.faction.factionName})!";
        Color factionColor = Colors.green;
        if (widget.profileCheckType == ProfileCheckType.attack) {
          factionColor = Colors.black;
          factionText = "CAUTION: this is an allied faction member!";
          _backgroundColor = Colors.red;
        }

        _friendlyFactionWidget = Row(
          children: [
            Image.asset(
              'images/icons/faction.png',
              width: 15,
              height: 12,
              color: factionColor,
            ),
            SizedBox(width: 10),
            Flexible(
              child: Text(
                factionText,
                style: TextStyle(
                  color: factionColor,
                  fontWeight: factionText.contains("CAUTION")
                      ? FontWeight.bold
                      : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        );
      }

      if (_isPartner) {
        String partnerText = "This is your lovely "
            "${otherProfile.gender == "Male" ? "husband" : "wife"}!";
        Color partnerColor = Colors.green;
        if (widget.profileCheckType == ProfileCheckType.attack) {
          partnerColor = Colors.black;
          partnerText = "CAUTION: this is your "
              "${otherProfile.gender == "Male" ? "husband" : "wife"}! "
              "Are you really that mad at "
              "${otherProfile.gender == "Male" ? "him" : "her"}?";
          _backgroundColor = Colors.red;
        }

        _partnerWidget = Row(
          children: [
            Icon(
              MdiIcons.heart,
              color: partnerColor,
              size: 16,
            ),
            SizedBox(width: 10),
            Flexible(
              child: Text(
                partnerText,
                style: TextStyle(
                  color: partnerColor,
                  fontWeight: partnerText.contains("CAUTION")
                      ? FontWeight.bold
                      : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        );
      }

      if (_isWorkColleague) {
        Color colleagueTextColor = Colors.brown[300];
        String colleagueText = "This is a work colleague!";
        if (widget.profileCheckType == ProfileCheckType.attack) {
          colleagueTextColor = Colors.black;
          colleagueText = "CAUTION: this is a work colleague!";
          _backgroundColor = Colors.red;
        }
        _workColleagueWidget = Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(
              Icons.work,
              color: colleagueTextColor,
              size: 15,
            ),
            SizedBox(width: 10),
            Flexible(
              child: Text(
                colleagueText,
                style: TextStyle(
                  color: colleagueTextColor,
                  fontSize: 12,
                  fontWeight: colleagueText.contains("CAUTION")
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
          ],
        );
      }

      if (_networthWidgetEnabled) {
        _networthWidget = Container(
          color: Colors.grey[900],
          child: Padding(
            padding: EdgeInsets.fromLTRB(15, 4, 15, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(
                  MdiIcons.currencyUsdCircleOutline,
                  color: Colors.green,
                  size: 17,
                ),
                SizedBox(width: 10),
                Flexible(
                  child: Text(
                    "${formatBigNumbers(otherProfile.personalstats.networth)}",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      _infoToShow = true;
      _expandableController.expanded = true;
    } else {
      _errorDetailsWidget = Container(
        child: Padding(
          padding: EdgeInsets.fromLTRB(15, 5, 15, 5),
          child: Text(
            "Error contacting API (no details available)",
            style: TextStyle(
              color: Colors.white,
              fontStyle: FontStyle.italic,
              fontSize: 11,
            ),
          ),
        ),
      );

      _errorToShow = true;
      _expandableController.expanded = true;
    }
  }

  Future estimatedStatsCalculator(OtherProfileModel otherProfile) async {
    // 0 is enabled
    // 1 is disabled
    // 2 is only if spies

    if (_settingsProvider.profileStatsEnabled == "0" ||
        _settingsProvider.profileStatsEnabled == "2") {
      var spyModel = YataSpyModel();
      var spyFoundInYata = false;
      try {
        String yataURL =
            'https://yata.yt/api/v1/spy/${otherProfile.playerId}?key=${_userDetails.basic.userApiKey}';
        var resp =
            await http.get(Uri.parse(yataURL)).timeout(Duration(seconds: 5));
        if (resp.statusCode == 200) {
          var spyJson = json.decode(resp.body);
          var spiedStats = spyJson["spies"]["${otherProfile.playerId}"];
          if (spiedStats != null) {
            spyModel = yataSpyModelFromJson(json.encode(spiedStats));
            spyFoundInYata = true;
          }
        }
      } catch (e) {
        // Won't get YATA details
      }

      if (spyFoundInYata) {
        // Stats spans
        var statsSpans = <TextSpan>[];
        // STR
        var strColor = Colors.white;
        if (spyModel.strength != -1) {
          if (_userDetails.basic.strength >= spyModel.strength) {
            strColor = Colors.green;
          } else if (_userDetails.basic.strength * 1.15 > spyModel.strength) {
            strColor = Colors.orange;
          } else {
            strColor = Colors.red;
          }
          statsSpans.add(
            TextSpan(
              text: "STR ",
              style: TextStyle(color: Colors.white, fontSize: 11),
            ),
          );
          statsSpans.add(
            TextSpan(
              text: "${formatBigNumbers(spyModel.strength)}",
              style: TextStyle(color: strColor, fontSize: 11),
            ),
          );
          statsSpans.add(
            TextSpan(
              text: ", ",
              style: TextStyle(color: Colors.white, fontSize: 11),
            ),
          );
        } else {
          statsSpans.add(
            TextSpan(
              text: "STR ?, ",
              style: TextStyle(color: Colors.white, fontSize: 11),
            ),
          );
        }
        // SPD
        var spdColor = Colors.white;
        if (spyModel.speed != -1) {
          if (_userDetails.basic.speed >= spyModel.speed) {
            spdColor = Colors.green;
          } else if (_userDetails.basic.speed * 1.15 > spyModel.speed) {
            spdColor = Colors.orange;
          } else {
            spdColor = Colors.red;
          }
          statsSpans.add(
            TextSpan(
              text: "SPD ",
              style: TextStyle(color: Colors.white, fontSize: 11),
            ),
          );
          statsSpans.add(
            TextSpan(
              text: "${formatBigNumbers(spyModel.speed)}",
              style: TextStyle(color: spdColor, fontSize: 11),
            ),
          );
          statsSpans.add(
            TextSpan(
              text: ", ",
              style: TextStyle(color: Colors.white, fontSize: 11),
            ),
          );
        } else {
          statsSpans.add(
            TextSpan(
              text: "SPD ?, ",
              style: TextStyle(color: Colors.white, fontSize: 11),
            ),
          );
        }
        // DEF
        var defColor = Colors.white;
        if (spyModel.defense != -1) {
          if (_userDetails.basic.defense >= spyModel.defense) {
            defColor = Colors.green;
          } else if (_userDetails.basic.defense * 1.15 > spyModel.defense) {
            defColor = Colors.orange;
          } else {
            defColor = Colors.red;
          }
          statsSpans.add(
            TextSpan(
              text: "DEF ",
              style: TextStyle(color: Colors.white, fontSize: 11),
            ),
          );
          statsSpans.add(
            TextSpan(
              text: "${formatBigNumbers(spyModel.defense)}",
              style: TextStyle(color: defColor, fontSize: 11),
            ),
          );
          statsSpans.add(
            TextSpan(
              text: ", ",
              style: TextStyle(color: Colors.white, fontSize: 11),
            ),
          );
        } else {
          statsSpans.add(
            TextSpan(
              text: "DEF ?, ",
              style: TextStyle(color: Colors.white, fontSize: 11),
            ),
          );
        }
        // DEX
        var dexColor = Colors.white;
        if (spyModel.dexterity != -1) {
          if (_userDetails.basic.dexterity >= spyModel.dexterity) {
            dexColor = Colors.green;
          } else if (_userDetails.basic.dexterity * 1.15 > spyModel.dexterity) {
            dexColor = Colors.orange;
          } else {
            dexColor = Colors.red;
          }
          statsSpans.add(
            TextSpan(
              text: "DEX ",
              style: TextStyle(color: Colors.white, fontSize: 11),
            ),
          );
          statsSpans.add(
            TextSpan(
              text: "${formatBigNumbers(spyModel.dexterity)}",
              style: TextStyle(color: dexColor, fontSize: 11),
            ),
          );
        } else {
          statsSpans.add(
            TextSpan(
              text: "DEX ?",
              style: TextStyle(color: Colors.white, fontSize: 11),
            ),
          );
        }

        Color infoColorStats = Colors.white;
        if (spyModel.total != -1) {
          infoColorStats = Colors.red;
          if (_userDetails.basic.total >= spyModel.total) {
            infoColorStats = Colors.green;
          } else if (_userDetails.basic.total * 1.15 > spyModel.total) {
            infoColorStats = Colors.orange;
          }
        }

        _estimatedStatsWidget = Container(
          color: Colors.grey[900],
          child: Padding(
            padding: EdgeInsets.fromLTRB(15, 4, 15, 4),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Image.asset('images/icons/yata_logo.png', height: 18),
                SizedBox(width: 8),
                Flexible(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: RichText(
                          text: TextSpan(
                            children: statsSpans,
                          ),
                        ),
                      ),
                      GestureDetector(
                        child: Icon(
                          Icons.info_outline,
                          color: infoColorStats,
                          size: 18,
                        ),
                        onTap: () {
                          _showDetailsDialog(spyModel);
                        },
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (!spyFoundInYata &&
          _settingsProvider.profileStatsEnabled == "0") {
        // Even if we have no YATA spy, but we want to show estimated stats
        var npcs = [4, 10, 15, 17, 19, 20];
        String estimatedStats = "";
        if (npcs.contains(otherProfile.playerId)) {
          estimatedStats = "NPC!";
        } else {
          try {
            estimatedStats = _calculateStats(otherProfile);
          } catch (e) {
            estimatedStats = "unk";
          }
        }

        _estimatedStatsWidget = Container(
          color: Colors.grey[900],
          child: Padding(
            padding: EdgeInsets.fromLTRB(15, 4, 15, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    "(EST) STATS:",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    estimatedStats,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontStyle: estimatedStats == "unk"
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // This might come a few seconds after the main widget builds, so we are showing
      // it if mounted and refreshing state
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _showDetailsDialog(YataSpyModel spyModel) {
    String lastUpdated = "";
    if (spyModel.update != 0) {
      lastUpdated = readTimestamp(spyModel.update);
    }

    Widget strWidget;
    if (spyModel.strength == -1) {
      strWidget = Text(
        "Strength: unknown",
        style: TextStyle(fontSize: 12),
      );
    } else {
      var strDiff = "";
      Color strColor;
      var result = _userDetails.basic.strength - spyModel.strength;
      if (result == 0) {
        strDiff = "Same as you";
        strColor = Colors.orange;
      } else if (result < 0) {
        strDiff = "${formatBigNumbers(result.abs())} higher than you";
        strColor = Colors.red;
      } else {
        strDiff = "${formatBigNumbers(result.abs())} lower than you";
        strColor = Colors.green;
      }

      strWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Strength: ${formatBigNumbers(spyModel.strength)}",
            style: TextStyle(fontSize: 12),
          ),
          Text(
            strDiff,
            style: TextStyle(fontSize: 12, color: strColor),
          ),
        ],
      );
    }

    Widget spdWidget;
    if (spyModel.speed == -1) {
      spdWidget = Text(
        "Speed: unknown",
        style: TextStyle(fontSize: 12),
      );
    } else {
      var spdDiff = "";
      Color spdColor;
      var result = _userDetails.basic.speed - spyModel.speed;
      if (result == 0) {
        spdDiff = "Same as you";
        spdColor = Colors.orange;
      } else if (result < 0) {
        spdDiff = "${formatBigNumbers(result.abs())} higher than you";
        spdColor = Colors.red;
      } else {
        spdDiff = "${formatBigNumbers(result.abs())} lower than you";
        spdColor = Colors.green;
      }

      spdWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Speed: ${formatBigNumbers(spyModel.speed)}",
            style: TextStyle(fontSize: 12),
          ),
          Text(
            spdDiff,
            style: TextStyle(fontSize: 12, color: spdColor),
          ),
        ],
      );
    }

    Widget defWidget;
    if (spyModel.defense == -1) {
      defWidget = Text(
        "Defense: unknown",
        style: TextStyle(fontSize: 12),
      );
    } else {
      var defDiff = "";
      Color defColor;
      var result = _userDetails.basic.defense - spyModel.defense;
      if (result == 0) {
        defDiff = "Same as you";
        defColor = Colors.orange;
      } else if (result < 0) {
        defDiff = "${formatBigNumbers(result.abs())} higher than you";
        defColor = Colors.red;
      } else {
        defDiff = "${formatBigNumbers(result.abs())} lower than you";
        defColor = Colors.green;
      }

      defWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Defense: ${formatBigNumbers(spyModel.defense)}",
            style: TextStyle(fontSize: 12),
          ),
          Text(
            defDiff,
            style: TextStyle(fontSize: 12, color: defColor),
          ),
        ],
      );
    }

    Widget dexWidget;
    if (spyModel.dexterity == -1) {
      dexWidget = Text(
        "Dexterity: unknown",
        style: TextStyle(fontSize: 12),
      );
    } else {
      var dexDiff = "";
      Color dexColor;
      var result = _userDetails.basic.strength - spyModel.dexterity;
      if (result == 0) {
        dexDiff = "Same as you";
        dexColor = Colors.orange;
      } else if (result < 0) {
        dexDiff = "${formatBigNumbers(result.abs())} higher than you";
        dexColor = Colors.red;
      } else {
        dexDiff = "${formatBigNumbers(result.abs())} lower than you";
        dexColor = Colors.green;
      }

      dexWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Dexterity: ${formatBigNumbers(spyModel.dexterity)}",
            style: TextStyle(fontSize: 12),
          ),
          Text(
            dexDiff,
            style: TextStyle(fontSize: 12, color: dexColor),
          ),
        ],
      );
    }

    Widget totalWidget;
    if (spyModel.total == -1) {
      totalWidget = Text(
        "TOTAL: unknown",
        style: TextStyle(fontSize: 12),
      );
    } else {
      var totalDiff = "";
      Color totalColor;
      var result = _userDetails.basic.total - spyModel.total;
      if (result == 0) {
        totalDiff = "Same as you";
        totalColor = Colors.orange;
      } else if (result < 0) {
        totalDiff = "${formatBigNumbers(result.abs())} higher than you";
        totalColor = Colors.red;
      } else {
        totalDiff = "${formatBigNumbers(result.abs())} lower than you";
        totalColor = Colors.green;
      }

      totalWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "TOTAL: ${formatBigNumbers(spyModel.dexterity)}",
            style: TextStyle(fontSize: 12),
          ),
          Text(
            totalDiff,
            style: TextStyle(fontSize: 12, color: totalColor),
          ),
        ],
      );
    }

    BotToast.showAnimationWidget(
      clickClose: false,
      allowClick: false,
      onlyOne: true,
      wrapToastAnimation: (controller, cancel, child) => Stack(
        children: <Widget>[
          GestureDetector(
            onTap: () {
              cancel();
            },
            child: AnimatedBuilder(
              builder: (_, child) => Opacity(
                opacity: controller.value,
                child: child,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.black26),
                child: SizedBox.expand(),
              ),
              animation: controller,
            ),
          ),
          CustomOffsetAnimation(
            controller: controller,
            child: child,
          )
        ],
      ),
      toastBuilder: (cancelFunc) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        title: Text(spyModel.targetName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (spyModel.targetFactionName != "0")
              Padding(
                padding: const EdgeInsets.all(4),
                child: Text(
                  "Faction: ${spyModel.targetFactionName}",
                  style: TextStyle(fontSize: 12),
                ),
              ),
            if (lastUpdated.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(4),
                child: Text(
                  "Updated: $lastUpdated",
                  style: TextStyle(fontSize: 12),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 4, bottom: 10),
              child: strWidget,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: spdWidget,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: defWidget,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: dexWidget,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 4),
              child: totalWidget,
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              cancelFunc();
            },
            child: const Text('Thanks'),
          ),
        ],
      ),
      animationDuration: Duration(milliseconds: 300),
    );
  }

  String _calculateStats(OtherProfileModel otherProfile) {
    var levelIndex =
        _levelTriggers.lastIndexWhere((x) => x <= otherProfile.level) + 1;
    var crimeIndex = _crimesTriggers
            .lastIndexWhere((x) => x <= otherProfile.criminalrecord.total) +
        1;
    var networthIndex = _networthTriggers
            .lastIndexWhere((x) => x <= otherProfile.personalstats.networth) +
        1;
    var rankIndex = 0;
    _ranksTriggers.forEach((tornRank, index) {
      if (otherProfile.rank.contains(tornRank)) {
        rankIndex = index;
      }
    });

    var finalIndex = rankIndex - levelIndex - crimeIndex - networthIndex - 1;
    if (finalIndex >= 0 && finalIndex <= 6) {
      return _statsResults[finalIndex];
    }
    return "unk";
  }

  
}
