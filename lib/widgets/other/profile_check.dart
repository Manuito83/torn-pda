// Dart imports:
import 'dart:convert';
import 'dart:developer';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:expandable/expandable.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chaining/target_model.dart';
import 'package:torn_pda/models/chaining/tornstats/tornstats_spy_model.dart';

// Project imports:
import 'package:torn_pda/models/chaining/yata/yata_spy_model.dart';
import 'package:torn_pda/models/profile/other_profile_model.dart';
import 'package:torn_pda/models/profile/own_stats_model.dart';
import 'package:torn_pda/providers/friends_provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/targets_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/utils/api_caller.dart';
import 'package:torn_pda/utils/html_parser.dart';
import 'package:torn_pda/utils/number_formatter.dart';
import 'package:torn_pda/utils/offset_animation.dart';
import 'package:torn_pda/utils/stats_calculator.dart';
import 'package:torn_pda/utils/timestamp_ago.dart';

enum ProfileCheckType {
  profile,
  attack,
}

enum SpiesSource {
  yata,
  tornStats,
}

class ProfileAttackCheckWidget extends StatefulWidget {
  final int profileId;
  final String apiKey;
  final ProfileCheckType profileCheckType;
  final ThemeProvider themeProvider;

  ProfileAttackCheckWidget({
    @required this.profileId,
    @required this.apiKey,
    @required this.profileCheckType,
    @required Key key,
    @required this.themeProvider,
  }) : super(key: key);

  @override
  _ProfileAttackCheckWidgetState createState() => _ProfileAttackCheckWidgetState();
}

class _ProfileAttackCheckWidgetState extends State<ProfileAttackCheckWidget> {
  Future _checkedPerson;
  bool _infoToShow = false;
  bool _errorToShow = false;

  SettingsProvider _settingsProvider;
  UserController _u = Get.put(UserController());

  TargetsProvider _targetsProvider;
  UserDetailsProvider _userDetails;
  var _expandableController = ExpandableController();

  Widget _statsWidget; // Has to be null at the beginning
  Widget _errorDetailsWidget = SizedBox.shrink();

  bool _addButtonActive = true;

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
    _targetsProvider = Provider.of<TargetsProvider>(context, listen: true);
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_statsWidget != null)
          Row(
            children: [
              Expanded(
                child: _statsWidget,
              ),
              _addRemoveTargetIcon(),
            ],
          ),
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
    );
  }

  Future<void> _fetchAndAssess() async {
    var otherProfile = await TornApiCaller().getOtherProfile(playerId: widget.profileId.toString());

    // FRIEND CHECK
    if (!mounted) return; // We could be unmounted when rapidly skipping the first target
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
          otherProfile.faction.factionId == _userDetails.basic.faction.factionId) {
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
                  fontWeight: friendText.contains("CAUTION") ? FontWeight.bold : FontWeight.normal,
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
                  fontWeight: factionText.contains("CAUTION") ? FontWeight.bold : FontWeight.normal,
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
                  fontWeight: factionText.contains("CAUTION") ? FontWeight.bold : FontWeight.normal,
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
                  fontWeight: partnerText.contains("CAUTION") ? FontWeight.bold : FontWeight.normal,
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
                  fontWeight: colleagueText.contains("CAUTION") ? FontWeight.bold : FontWeight.normal,
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

    if (_settingsProvider.profileStatsEnabled == "0" || _settingsProvider.profileStatsEnabled == "2") {
      int strength = 0;
      int defense = 0;
      int speed = 0;
      int dexterity = 0;
      int total = 0;
      int timestamp = 0;
      String name = "";
      String factionName = "";
      bool spyFound = false;
      SpiesSource spiesSource;

      try {
        if (_settingsProvider.spiesSource == SpiesSource.yata) {
          String yataURL = 'https://yata.yt/api/v1/spy/${otherProfile.playerId}?key=${_u.alternativeYataKey}';
          var resp = await http.get(Uri.parse(yataURL)).timeout(Duration(seconds: 5));
          if (resp.statusCode == 200) {
            var spyJson = json.decode(resp.body);
            var spiedStats = spyJson["spies"]["${otherProfile.playerId}"];
            if (spiedStats != null) {
              var spyModel = yataSpyModelFromJson(json.encode(spiedStats));
              spiesSource = SpiesSource.yata;
              strength = spyModel.strength;
              defense = spyModel.defense;
              speed = spyModel.speed;
              dexterity = spyModel.dexterity;
              total = spyModel.total;
              timestamp = spyModel.update;
              name = spyModel.targetName;
              factionName = spyModel.targetFactionName;
              spyFound = true;
            }
          }
        } else {
          String tornStatsURL =
              'https://www.tornstats.com/api/v1/${_u.alternativeTornStatsKey}/spy/${otherProfile.playerId}';
          var resp = await http.get(Uri.parse(tornStatsURL)).timeout(Duration(seconds: 5));
          if (resp.statusCode == 200) {
            TornStatsSpyModel spyJson = tornStatsSpyModelFromJson(resp.body);
            if (spyJson != null) {
              if (!spyJson.message.contains("ERROR") && !spyJson.spy.message.contains("not found")) {
                spiesSource = SpiesSource.tornStats;
                strength = spyJson.spy.strength;
                defense = spyJson.spy.defense;
                speed = spyJson.spy.speed;
                dexterity = spyJson.spy.dexterity;
                total = spyJson.spy.total;
                timestamp = spyJson.spy.timestamp;
                spyFound = true;
              }
            }
          }
        }
      } catch (e) {
        // Won't get spies details
        log("Spy details failed: $e");
      }

      if (spyFound) {
        // Stats spans
        var statsSpans = <TextSpan>[];
        // STR
        var strColor = Colors.white;
        if (strength != -1) {
          if (_userDetails.basic.strength >= strength) {
            strColor = Colors.green;
          } else if (_userDetails.basic.strength * 1.15 > strength) {
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
              text: "${formatBigNumbers(strength)}",
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
        if (speed != -1) {
          if (_userDetails.basic.speed >= speed) {
            spdColor = Colors.green;
          } else if (_userDetails.basic.speed * 1.15 > speed) {
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
              text: "${formatBigNumbers(speed)}",
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
        if (defense != -1) {
          if (_userDetails.basic.defense >= defense) {
            defColor = Colors.green;
          } else if (_userDetails.basic.defense * 1.15 > defense) {
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
              text: "${formatBigNumbers(defense)}",
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
        if (dexterity != -1) {
          if (_userDetails.basic.dexterity >= dexterity) {
            dexColor = Colors.green;
          } else if (_userDetails.basic.dexterity * 1.15 > dexterity) {
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
              text: "${formatBigNumbers(dexterity)}",
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

        Widget onlineStatus = Row(
          children: [
            otherProfile.lastAction.status == "Offline"
                ? Icon(Icons.remove_circle, size: 10, color: Colors.grey)
                : otherProfile.lastAction.status == "Idle"
                    ? Icon(Icons.adjust, size: 12, color: Colors.orange)
                    : Icon(Icons.circle, size: 12, color: Colors.green),
            if (otherProfile.lastAction.status == "Offline" || otherProfile.lastAction.status == "Idle")
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Text(
                  otherProfile.lastAction.relative
                      .replaceAll("minute ago", "m")
                      .replaceAll("minutes ago", "m")
                      .replaceAll("hour ago", "h")
                      .replaceAll("hours ago", "h")
                      .replaceAll("day ago", "d")
                      .replaceAll("days ago", "d"),
                  style: TextStyle(
                    fontSize: 11,
                    color: otherProfile.lastAction.status == "Idle" ? Colors.orange : Colors.grey,
                  ),
                ),
              ),
          ],
        );

        Color infoColorStats = Colors.white;
        if (total != -1) {
          infoColorStats = Colors.red;
          if (_userDetails.basic.total >= total) {
            infoColorStats = Colors.green;
          } else if (_userDetails.basic.total * 1.15 > total) {
            infoColorStats = Colors.orange;
          }
        }

        _statsWidget = Container(
          color: Colors.grey[900],
          child: Padding(
            padding: EdgeInsets.fromLTRB(15, 4, 8, 4),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Image.asset(
                    spiesSource == SpiesSource.yata ? 'images/icons/yata_logo.png' : 'images/icons/tornstats_logo.png',
                    height: 18),
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
                      onlineStatus,
                      Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: GestureDetector(
                          child: Icon(
                            Icons.info_outline,
                            color: infoColorStats,
                            size: 18,
                          ),
                          onTap: () {
                            _showSpiedDetailsDialog(
                              strength: strength,
                              defense: defense,
                              speed: speed,
                              dexterity: dexterity,
                              total: total,
                              name: name,
                              factionName: factionName,
                              update: timestamp,
                              spiesSource: spiesSource,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (!spyFound && _settingsProvider.profileStatsEnabled == "0") {
        // Even if we have no YATA spy, but we want to show estimated stats
        var npcs = [4, 10, 15, 17, 19, 20];
        String estimatedStats = "";
        bool npc = false;
        if (npcs.contains(otherProfile.playerId)) {
          estimatedStats = "NPC!";
          npc = true;
        } else {
          try {
            estimatedStats = StatsCalculator.calculateStats(
              criminalRecordTotal: otherProfile.criminalrecord.total,
              level: otherProfile.level,
              networth: otherProfile.personalstats.networth,
              rank: otherProfile.rank,
            );
          } catch (e) {
            estimatedStats = "(EST) UNK";
          }
        }

        // Globals
        int xanaxComparison = 0;
        Color xanaxColor = Colors.orange;
        int refillComparison = 0;
        Color refillColor = Colors.orange;
        int enhancementComparison = 0;
        Color enhancementColor = Colors.white;
        int cansComparison = 0;
        Color cansColor = Colors.orange;
        Color sslColor = Colors.green;
        bool sslProb = true;
        int ecstasy = 0;
        int lsd = 0;

        List<Widget> additional = <Widget>[];
        var own = await TornApiCaller().getOwnPersonalStats();
        if (own is OwnPersonalStatsModel) {
          // XANAX
          int otherXanax = otherProfile.personalstats.xantaken;
          int myXanax = own.personalstats.xantaken;
          xanaxComparison = otherXanax - myXanax;
          if (xanaxComparison < -10) {
            xanaxColor = Colors.green;
          } else if (xanaxComparison > 10) {
            xanaxColor = Colors.red;
          }
          Text xanaxText = Text(
            "XAN",
            style: TextStyle(color: xanaxColor, fontSize: 11),
          );

          // REFILLS
          int otherRefill = otherProfile.personalstats.refills;
          int myRefill = own.personalstats.refills;
          refillComparison = otherRefill - myRefill;
          refillColor = Colors.orange;
          if (refillComparison < -10) {
            refillColor = Colors.green;
          } else if (refillComparison > 10) {
            refillColor = Colors.red;
          }
          Text refillText = Text(
            "RFL",
            style: TextStyle(color: refillColor, fontSize: 11),
          );

          // ENHANCEMENT
          int otherEnhancement = otherProfile.personalstats.statenhancersused;
          int myEnhancement = own.personalstats.statenhancersused;
          enhancementComparison = otherEnhancement - myEnhancement;
          if (enhancementComparison < 0) {
            enhancementColor = Colors.green;
          } else if (enhancementComparison > 0) {
            enhancementColor = Colors.red;
          }
          Text enhancementText = Text(
            "ENH",
            style: TextStyle(color: enhancementColor, fontSize: 11),
          );

          // CANS
          int otherCans = otherProfile.personalstats.energydrinkused;
          int myCans = own.personalstats.energydrinkused;
          cansComparison = otherCans - myCans;
          if (cansComparison < 0) {
            cansColor = Colors.green;
          } else if (cansComparison > 0) {
            cansColor = Colors.red;
          }
          Text cansText = Text(
            "CAN",
            style: TextStyle(color: cansColor, fontSize: 11),
          );

          /// SSL
          /// If (xan + esc) > 150, SSL is blank;
          /// if (esc + xan) < 150 & LSD < 50, SSL is green;
          /// if (esc + xan) < 150 & LSD > 50 & LSD < 100, SSL is yellow;
          /// if (esc + xan) < 150 & LSD > 100 SSL is red
          Widget sslWidget = SizedBox.shrink();
          sslColor = Colors.green;
          ecstasy = otherProfile.personalstats.exttaken;
          lsd = otherProfile.personalstats.lsdtaken;
          if (otherXanax + ecstasy > 150) {
            sslProb = false;
          } else {
            if (lsd > 50 && lsd < 50) {
              sslColor = Colors.orange;
            } else if (lsd > 100) {
              sslColor = Colors.red;
            }
            sslWidget = Text(
              "[SSL]",
              style: TextStyle(
                color: sslColor,
                fontSize: 11,
              ),
            );
          }

          additional.add(xanaxText);
          additional.add(SizedBox(width: 5));
          additional.add(refillText);
          additional.add(SizedBox(width: 5));
          additional.add(enhancementText);
          additional.add(SizedBox(width: 5));
          additional.add(cansText);
          additional.add(SizedBox(width: 5));
          additional.add(sslWidget);
          additional.add(SizedBox(width: 5));
        }

        // ONLINE STATUS
        Widget onlineStatus = Row(
          children: [
            otherProfile.lastAction.status == "Offline"
                ? Icon(Icons.remove_circle, size: 10, color: Colors.grey)
                : otherProfile.lastAction.status == "Idle"
                    ? Icon(Icons.adjust, size: 12, color: Colors.orange)
                    : Icon(Icons.circle, size: 12, color: Colors.green),
            if (otherProfile.lastAction.status == "Offline" || otherProfile.lastAction.status == "Idle")
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Text(
                  otherProfile.lastAction.relative
                      .replaceAll("minute ago", "m")
                      .replaceAll("minutes ago", "m")
                      .replaceAll("hour ago", "h")
                      .replaceAll("hours ago", "h")
                      .replaceAll("day ago", "d")
                      .replaceAll("days ago", "d"),
                  style: TextStyle(
                    fontSize: 11,
                    color: otherProfile.lastAction.status == "Idle" ? Colors.orange : Colors.grey,
                  ),
                ),
              ),
          ],
        );

        _statsWidget = Container(
          color: Colors.grey[900],
          child: Padding(
            padding: EdgeInsets.fromLTRB(15, 4, 8, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        npc ? "" : "(EST)",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                      SizedBox(width: 5),
                      Text(
                        estimatedStats,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontStyle: estimatedStats == "(EST) UNK" ? FontStyle.italic : FontStyle.normal,
                        ),
                      ),
                      SizedBox(width: 5),
                      if (!npc)
                        Expanded(
                          child: Wrap(
                            children: additional,
                          ),
                        ),
                    ],
                  ),
                ),
                if (!npc) onlineStatus,
                if (!npc)
                  Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: GestureDetector(
                      child: Icon(
                        Icons.info_outline,
                        color: Colors.white,
                        size: 18,
                      ),
                      onTap: () {
                        _showEstimatedDetailsDialog(
                          xanaxComparison,
                          xanaxColor,
                          refillComparison,
                          refillColor,
                          enhancementComparison,
                          enhancementColor,
                          cansComparison,
                          cansColor,
                          sslColor,
                          sslProb,
                          otherProfile,
                        );
                      },
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

  Widget _addRemoveTargetIcon() {
    bool targetExists = false;
    Color targetExistsColor = Colors.green;
    TargetModel target = TargetModel();
    for (TargetModel t in _targetsProvider.allTargets) {
      if (t.playerId == widget.profileId) {
        targetExists = true;
        targetExistsColor = Colors.red;
        target = t;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        child: _addButtonActive
            ? targetExists
                ? Icon(
                    Icons.remove_circle_outline,
                    color: targetExistsColor,
                    size: 18,
                  )
                : Icon(
                    Icons.add_circle_outline,
                    color: targetExistsColor,
                    size: 18,
                  )
            : SizedBox(
                height: 15,
                width: 15,
                child: CircularProgressIndicator(),
              ),
        onTap: () async {
          setState(() {
            _addButtonActive = false;
          });

          if (targetExists) {
            _targetsProvider.deleteTarget(target);
            BotToast.showText(
              clickClose: true,
              text: HtmlParser.fix('Removed from Torn PDA targets!'),
              textStyle: TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
              contentColor: Colors.orange[900],
              duration: Duration(seconds: 3),
              contentPadding: EdgeInsets.all(10),
            );
          } else {
            dynamic attacks = await _targetsProvider.getAttacks();
            AddTargetResult tryAddTarget = await _targetsProvider.addTarget(
              targetId: widget.profileId.toString(),
              attacks: attacks,
            );
            if (tryAddTarget.success) {
              BotToast.showText(
                clickClose: true,
                text: HtmlParser.fix('Added ${tryAddTarget.targetName} [${tryAddTarget.targetId}] to your '
                    'main targets list in Torn PDA!'),
                textStyle: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
                contentColor: Colors.green[700],
                duration: Duration(seconds: 3),
                contentPadding: EdgeInsets.all(10),
              );
            } else if (!tryAddTarget.success) {
              BotToast.showText(
                clickClose: true,
                text: HtmlParser.fix('Error adding ${widget.profileId}. ${tryAddTarget.errorReason}'),
                textStyle: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
                contentColor: Colors.red[900],
                duration: Duration(seconds: 4),
                contentPadding: EdgeInsets.all(10),
              );
            }
          }

          if (mounted) {
            setState(() {
              _addButtonActive = true;
            });
          }
        },
      ),
    );
  }

  void _showSpiedDetailsDialog({
    @required int strength,
    @required int defense,
    @required int speed,
    @required int dexterity,
    @required int total,
    @required int update,
    @required String name,
    @required String factionName,
    @required SpiesSource spiesSource,
  }) {
    String lastUpdated = "";
    if (update != 0) {
      lastUpdated = readTimestamp(update);
    }

    Widget strWidget;
    if (strength == -1) {
      strWidget = Text(
        "Strength: unknown",
        style: TextStyle(fontSize: 12),
      );
    } else {
      var strDiff = "";
      Color strColor;
      var result = _userDetails.basic.strength - strength;
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
            "Strength: ${formatBigNumbers(strength)}",
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
    if (speed == -1) {
      spdWidget = Text(
        "Speed: unknown",
        style: TextStyle(fontSize: 12),
      );
    } else {
      var spdDiff = "";
      Color spdColor;
      var result = _userDetails.basic.speed - speed;
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
            "Speed: ${formatBigNumbers(speed)}",
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
    if (defense == -1) {
      defWidget = Text(
        "Defense: unknown",
        style: TextStyle(fontSize: 12),
      );
    } else {
      var defDiff = "";
      Color defColor;
      var result = _userDetails.basic.defense - defense;
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
            "Defense: ${formatBigNumbers(defense)}",
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
    if (dexterity == -1) {
      dexWidget = Text(
        "Dexterity: unknown",
        style: TextStyle(fontSize: 12),
      );
    } else {
      var dexDiff = "";
      Color dexColor;
      var result = _userDetails.basic.dexterity - dexterity;
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
            "Dexterity: ${formatBigNumbers(dexterity)}",
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
    if (total == -1) {
      totalWidget = Text(
        "TOTAL: unknown",
        style: TextStyle(fontSize: 12),
      );
    } else {
      var totalDiff = "";
      Color totalColor;
      var result = _userDetails.basic.total - total;
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
            "TOTAL: ${formatBigNumbers(total)}",
            style: TextStyle(fontSize: 12),
          ),
          Text(
            totalDiff,
            style: TextStyle(fontSize: 12, color: totalColor),
          ),
        ],
      );
    }

    Widget sourceWidget = SizedBox.shrink();
    if (spiesSource != null) {
      sourceWidget = Row(
        children: [
          Text(
            "Source: ",
            style: TextStyle(fontSize: 12),
          ),
          SizedBox(
            height: 16,
            width: 16,
            child: Image.asset(
              spiesSource == SpiesSource.yata ? 'images/icons/yata_logo.png' : 'images/icons/tornstats_logo.png',
            ),
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
        title: name.isNotEmpty ? Text(name) : Text("Spied stats"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (factionName != "0" && factionName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(4),
                child: Text(
                  "Faction: ${factionName}",
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
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 4),
              child: sourceWidget,
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

  void _showEstimatedDetailsDialog(
    int xanaxCompare,
    Color xanaxColor,
    int refillCompare,
    Color refillColor,
    int enhancementCompare,
    Color enhancementColor,
    int cansCompare,
    Color cansColor,
    Color sslColor,
    bool sslProb,
    OtherProfileModel otherProfile,
  ) {
    String xanaxRelative = "SAME as you";
    if (xanaxCompare > 0) {
      xanaxRelative = "${xanaxCompare.abs()} MORE than you";
    } else {
      xanaxRelative = "${xanaxCompare.abs()} LESS than you";
    }
    Widget xanaxWidget = Row(
      children: [
        Text(
          "> Xanax: ",
          style: TextStyle(fontSize: 14),
        ),
        Flexible(
          child: Text(
            "$xanaxRelative",
            style: TextStyle(color: xanaxColor, fontSize: 14),
          ),
        ),
      ],
    );
    ;

    String refillRelative = "SAME as you";
    if (refillCompare > 0) {
      refillRelative = "${refillCompare.abs()} MORE than you";
    } else {
      refillRelative = "${refillCompare.abs()} LESS than you";
    }
    Widget refillWidget = Row(
      children: [
        Text(
          "> (E) Refills: ",
          style: TextStyle(fontSize: 14),
        ),
        Flexible(
          child: Text(
            "$refillRelative",
            style: TextStyle(color: refillColor, fontSize: 14),
          ),
        ),
      ],
    );

    String enhancementRelative = "SAME as you";
    if (enhancementColor == Colors.white) enhancementColor = widget.themeProvider.mainText;
    if (enhancementCompare > 0) {
      enhancementRelative = "${enhancementCompare.abs()} MORE than you";
    } else if (enhancementCompare < 0) {
      enhancementRelative = "${enhancementCompare.abs()} LESS than you";
    }
    Widget enhancementWidget = Row(
      children: [
        Text(
          "> Enhancer(s): ",
          style: TextStyle(fontSize: 14),
        ),
        Flexible(
          child: Text(
            "$enhancementRelative",
            style: TextStyle(color: enhancementColor, fontSize: 14),
          ),
        ),
      ],
    );

    String cansRelative = "SAME as you";
    if (cansCompare > 0) {
      cansRelative = "${cansCompare.abs()} MORE than you";
    } else if (cansCompare < 0) {
      cansRelative = "${cansCompare.abs()} LESS than you";
    }
    Widget cansWidget = Row(
      children: [
        Text(
          "> Cans: ",
          style: TextStyle(fontSize: 14),
        ),
        Flexible(
          child: Text(
            "$cansRelative",
            style: TextStyle(color: cansColor, fontSize: 14),
          ),
        ),
      ],
    );

    Widget sslWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "> SSL probability: ",
              style: TextStyle(fontSize: 14),
            ),
            Text(
              "${!sslProb ? "none" : sslColor == Colors.green ? "low" : sslColor == Colors.orange ? "med" : "high"}",
              style: TextStyle(
                color: sslColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Text(
            "[Sports Science Lab Gym]",
            style: TextStyle(fontSize: 9),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Xanax: ${otherProfile.personalstats.xantaken}",
                style: TextStyle(fontSize: 12),
              ),
              Text(
                "Ecstasy: ${otherProfile.personalstats.exttaken}",
                style: TextStyle(fontSize: 12),
              ),
              Text(
                "LSD: ${otherProfile.personalstats.lsdtaken}",
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );

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
        title: Text(otherProfile.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (otherProfile.faction.factionName != "0")
              Padding(
                padding: const EdgeInsets.all(2),
                child: Text(
                  "Faction: ${otherProfile.faction.factionName}",
                  style: TextStyle(fontSize: 12),
                ),
              ),
            if (otherProfile.lastAction.relative.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(2),
                child: Text(
                  "Online: ${otherProfile.lastAction.relative.replaceAll("0 minutes ago", "now")}",
                  style: TextStyle(fontSize: 12),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 4, bottom: 0),
              child: xanaxWidget,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 4, bottom: 0),
              child: refillWidget,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 4, bottom: 0),
              child: enhancementWidget,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 4, bottom: 0),
              child: cansWidget,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 4, bottom: 0),
              child: sslWidget,
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
}
