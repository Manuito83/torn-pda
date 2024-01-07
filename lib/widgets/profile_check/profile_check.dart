// Dart imports:
import 'dart:developer';

// Package imports:
import 'package:expandable/expandable.dart';
// Flutter imports:
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
// Project imports:
import 'package:torn_pda/models/profile/other_profile_model.dart';
import 'package:torn_pda/models/profile/own_stats_model.dart';
import 'package:torn_pda/providers/api_caller.dart';
import 'package:torn_pda/providers/friends_provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/spies_controller.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/utils/number_formatter.dart';
import 'package:torn_pda/utils/stats_calculator.dart';
import 'package:torn_pda/widgets/profile_check/profile_check_add_button.dart';
import 'package:torn_pda/widgets/stats/stats_dialog.dart';

enum ProfileCheckType {
  profile,
  attack,
}

class ProfileAttackCheckWidget extends StatefulWidget {
  final int profileId;
  final String? apiKey;
  final ProfileCheckType profileCheckType;
  final ThemeProvider? themeProvider;

  const ProfileAttackCheckWidget({
    required this.profileId,
    required this.apiKey,
    required this.profileCheckType,
    required Key key,
    required this.themeProvider,
  }) : super(key: key);

  @override
  ProfileAttackCheckWidgetState createState() => ProfileAttackCheckWidgetState();
}

class ProfileAttackCheckWidgetState extends State<ProfileAttackCheckWidget> {
  final navigatorKey = GlobalKey<NavigatorState>();

  Future? _checkedPerson;
  bool _infoToShow = false;
  bool _errorToShow = false;

  late SettingsProvider _settingsProvider;
  final SpiesController _spy = Get.find<SpiesController>();

  late UserDetailsProvider _userDetails;
  final _expandableController = ExpandableController();

  Widget? _statsWidget; // Has to be null at the beginning
  Widget _errorDetailsWidget = const SizedBox.shrink();

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

  String? _playerName = "Player";
  String? _factionName = "Faction";
  int? _factionId = 0;

  Widget _tornPdaWidget = const SizedBox.shrink();
  Widget _partnerWidget = const SizedBox.shrink();
  Widget _friendsWidget = const SizedBox.shrink();
  Widget _friendlyFactionWidget = const SizedBox.shrink();
  Widget _workColleagueWidget = const SizedBox.shrink();
  Widget _playerOrFactionWidget = const SizedBox.shrink();
  Widget _networthWidget = const SizedBox.shrink();

  Color? _backgroundColor = Colors.grey[900];

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
              collapsed: Container(),
              controller: _expandableController,
              expanded: mainWidgetBox(),
            );
          } else if (_errorToShow) {
            return ExpandablePanel(
              collapsed: Container(),
              controller: _expandableController,
              expanded: _errorDetailsWidget,
            );
          } else {
            return const SizedBox.shrink();
          }
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget mainWidgetBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_statsWidget != null)
          Container(
            color: Colors.grey[900],
            child: Row(
              children: [
                Expanded(
                  child: _statsWidget!,
                ),
                ProfileCheckAddButton(
                  profileId: widget.profileId,
                  playerName: _playerName,
                  factionId: _factionId,
                ),
              ],
            ),
          ),
        if (_networthWidgetEnabled) _networthWidget,
        if (_isTornPda) _tornPdaWidget,
        // Container so that the background color can be changed for certain widgets
        Container(
          color: _backgroundColor,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
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
                  const SizedBox(height: 2)
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _fetchAndAssess() async {
    final otherProfile =
        await Get.find<ApiCallerController>().getOtherProfileExtended(playerId: widget.profileId.toString());

    // FRIEND CHECK
    if (!mounted) return; // We could be unmounted when rapidly skipping the first target
    final friendsProv = context.read<FriendsProvider>();
    if (!friendsProv.initialized) {
      await friendsProv.initFriends();
    }
    for (final friend in friendsProv.allFriends) {
      if (friend.playerId == widget.profileId) _isFriend = true;
    }

    if (otherProfile is OtherProfileModel) {
      _playerName = otherProfile.name;
      _factionName = otherProfile.faction!.factionName;
      _factionId = otherProfile.faction!.factionId;

      // Estimated stats is not awaited, since it can take a few seconds
      // to contact YATA / TS and decide what we show
      estimatedStatsCalculator(otherProfile).then((value) {
        setState(() {});
      });

      if (otherProfile.playerId == 2225097) {
        _isTornPda = true;
      }

      if (otherProfile.married!.spouseId == _userDetails.basic!.playerId) {
        _isPartner = true;
      }

      if (otherProfile.playerId == _userDetails.basic!.playerId) {
        _isOwnPlayer = true;
      }

      if (_userDetails.basic!.faction!.factionId != 0 &&
          otherProfile.faction!.factionId == _userDetails.basic!.faction!.factionId) {
        _isOwnFaction = true;
      }

      final settingsProvider = context.read<SettingsProvider>();
      for (final fact in settingsProvider.friendlyFactions) {
        if (otherProfile.faction!.factionId == fact.id) {
          _isFriendlyFaction = true;
          break;
        }
      }

      if (!_isOwnPlayer &&
          otherProfile.job!.companyId != 0 &&
          otherProfile.job!.companyId == _userDetails.basic!.job!.companyId) {
        _isWorkColleague = true;
      }

      _networthWidgetEnabled = _settingsProvider.extraPlayerNetworth;

      if (_isTornPda) {
        _tornPdaWidget = Container(
          color: Colors.grey[900],
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 4, 15, 4),
            child: Row(
              children: [
                Image.asset(
                  'images/icons/torn_pda.png',
                  width: 16,
                  height: 16,
                  //color: Colors.brown[400],
                ),
                const SizedBox(width: 10),
                const Flexible(
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
          children: [
            Icon(
              Icons.people,
              color: friendTextColor,
              size: 15,
            ),
            const SizedBox(width: 10),
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
        _playerOrFactionWidget = const Row(
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
            "(${otherProfile.faction!.position})!";
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
            const SizedBox(width: 10),
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
            "(${otherProfile.faction!.factionName})!";
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
            const SizedBox(width: 10),
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
            "${otherProfile.gender == "Male" ? "husband" : otherProfile.gender == "Female" ? "wife" : "partner"}!";
        Color partnerColor = Colors.green;
        if (widget.profileCheckType == ProfileCheckType.attack) {
          partnerColor = Colors.black;
          partnerText = "CAUTION: this is your "
              "${otherProfile.gender == "Male" ? "husband" : otherProfile.gender == "Female" ? "wife" : "partner"}! "
              "Are you really that mad"
              "${otherProfile.gender == "Male" ? " at him" : otherProfile.gender == "Female" ? " at her" : ""}?";
          _backgroundColor = Colors.red;
        }

        _partnerWidget = Row(
          children: [
            Icon(
              MdiIcons.heart,
              color: partnerColor,
              size: 16,
            ),
            const SizedBox(width: 10),
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
        Color? colleagueTextColor = Colors.brown[300];
        String colleagueText = "This is a work colleague!";
        if (widget.profileCheckType == ProfileCheckType.attack) {
          colleagueTextColor = Colors.black;
          colleagueText = "CAUTION: this is a work colleague!";
          _backgroundColor = Colors.red;
        }
        _workColleagueWidget = Row(
          children: [
            Icon(
              Icons.work,
              color: colleagueTextColor,
              size: 15,
            ),
            const SizedBox(width: 10),
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
        int bazaar = 0;
        if (otherProfile.bazaar!.isNotEmpty) {
          for (final b in otherProfile.bazaar!) {
            if (b.marketPrice is double) {
              b.marketPrice = b.marketPrice.round();
            }

            var itemCost = b.marketPrice * b.quantity;
            bazaar += itemCost as int;
          }
        }

        _networthWidget = Container(
          color: Colors.grey[900],
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 4, 15, 4),
            child: Row(
              children: [
                const Icon(
                  MdiIcons.currencyUsdCircleOutline,
                  color: Colors.green,
                  size: 17,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    formatBigNumbers(otherProfile.personalstats!.networth!),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
                ),
                if (bazaar > 0)
                  Flexible(
                    child: Row(
                      children: [
                        const SizedBox(width: 30),
                        Image.asset(
                          "images/icons/inventory/bazaar.png",
                          color: Colors.green,
                          width: 14,
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            formatBigNumbers(bazaar),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
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
        child: const Padding(
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
    // Even if we have no spy, we want to show estimated stats
    final npcs = [4, 10, 15, 17, 19, 20];
    String estimatedStats = "";
    bool npc = false;
    if (npcs.contains(otherProfile.playerId)) {
      estimatedStats = "NPC!";
      npc = true;
    } else {
      try {
        estimatedStats = StatsCalculator.calculateStats(
          criminalRecordTotal: otherProfile.criminalrecord!.total,
          level: otherProfile.level,
          networth: otherProfile.personalstats!.networth,
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
    int? ecstasy = 0;
    int? lsd = 0;

    List<Widget> additional = <Widget>[];
    final own = await Get.find<ApiCallerController>().getOwnPersonalStats();
    if (own is OwnPersonalStatsModel) {
      // XANAX
      final int otherXanax = otherProfile.personalstats!.xantaken!;
      final int myXanax = own.personalstats!.xantaken!;
      xanaxComparison = otherXanax - myXanax;
      if (xanaxComparison < -10) {
        xanaxColor = Colors.green;
      } else if (xanaxComparison > 10) {
        xanaxColor = Colors.red;
      }
      final Text xanaxText = Text(
        "XAN",
        style: TextStyle(color: xanaxColor, fontSize: 11),
      );

      // REFILLS
      final int otherRefill = otherProfile.personalstats!.refills!;
      final int myRefill = own.personalstats!.refills!;
      refillComparison = otherRefill - myRefill;
      refillColor = Colors.orange;
      if (refillComparison < -10) {
        refillColor = Colors.green;
      } else if (refillComparison > 10) {
        refillColor = Colors.red;
      }
      final Text refillText = Text(
        "RFL",
        style: TextStyle(color: refillColor, fontSize: 11),
      );

      // ENHANCEMENT
      final int otherEnhancement = otherProfile.personalstats!.statenhancersused!;
      final int myEnhancement = own.personalstats!.statenhancersused!;
      enhancementComparison = otherEnhancement - myEnhancement;
      if (enhancementComparison < 0) {
        enhancementColor = Colors.green;
      } else if (enhancementComparison > 0) {
        enhancementColor = Colors.red;
      }
      final Text enhancementText = Text(
        "ENH",
        style: TextStyle(color: enhancementColor, fontSize: 11),
      );

      // CANS
      final int otherCans = otherProfile.personalstats!.energydrinkused!;
      final int myCans = own.personalstats!.energydrinkused!;
      cansComparison = otherCans - myCans;
      if (cansComparison < 0) {
        cansColor = Colors.green;
      } else if (cansComparison > 0) {
        cansColor = Colors.red;
      }
      final Text cansText = Text(
        "CAN",
        style: TextStyle(color: cansColor, fontSize: 11),
      );

      /// SSL
      /// If (xan + esc) > 150, SSL is blank;
      /// if (esc + xan) < 150 & LSD < 50, SSL is green;
      /// if (esc + xan) < 150 & LSD > 50 & LSD < 100, SSL is yellow;
      /// if (esc + xan) < 150 & LSD > 100 SSL is red
      Widget sslWidget = const SizedBox.shrink();
      sslColor = Colors.green;
      ecstasy = otherProfile.personalstats!.exttaken;
      lsd = otherProfile.personalstats!.lsdtaken;
      if (otherXanax + ecstasy! > 150) {
        sslProb = false;
      } else {
        if (lsd! > 50 && lsd < 50) {
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
      additional.add(const SizedBox(width: 5));
      additional.add(refillText);
      additional.add(const SizedBox(width: 5));
      additional.add(enhancementText);
      additional.add(const SizedBox(width: 5));
      additional.add(cansText);
      additional.add(const SizedBox(width: 5));
      additional.add(sslWidget);
      additional.add(const SizedBox(width: 5));
    }

    int? strength = 0;
    int? strengthUpdate;
    int? defense = 0;
    int? defenseUpdate;
    int? speed = 0;
    int? speedUpdate;
    int? dexterity = 0;
    int? dexterityUpdate;
    int? total = 0;
    int? totalUpdate;
    bool spyFound = false;

    try {
      if (_spy.spiesSource == SpiesSource.yata) {
        for (var spy in _spy.yataSpies) {
          if (spy.targetName == otherProfile.name) {
            strength = spy.strength;
            strengthUpdate = spy.strengthTimestamp;
            defense = spy.defense;
            defenseUpdate = spy.defenseTimestamp;
            speed = spy.speed;
            speedUpdate = spy.speedTimestamp;
            dexterity = spy.dexterity;
            dexterityUpdate = spy.dexterityTimestamp;
            total = spy.total;
            totalUpdate = spy.totalTimestamp;
            spyFound = true;
            continue;
          }
        }
      } else {
        for (var spy in _spy.tornStatsSpies.spies) {
          if (spy.playerName == otherProfile.name) {
            strength = spy.strength;
            defense = spy.defense;
            speed = spy.speed;
            dexterity = spy.dexterity;
            total = spy.total;
            spyFound = true;
            continue;
          }
        }
      }
    } catch (e) {
      // Won't get spies details
      log("Spy details failed: $e");
    }

    // ONLINE STATUS
    final Widget onlineStatus = Row(
      children: [
        if (otherProfile.lastAction!.status == "Offline")
          const Icon(Icons.remove_circle, size: 10, color: Colors.grey)
        else
          otherProfile.lastAction!.status == "Idle"
              ? const Icon(Icons.adjust, size: 12, color: Colors.orange)
              : const Icon(Icons.circle, size: 12, color: Colors.green),
        if (otherProfile.lastAction!.status == "Offline" || otherProfile.lastAction!.status == "Idle")
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              otherProfile.lastAction!.relative!
                  .replaceAll("minute ago", "m")
                  .replaceAll("minutes ago", "m")
                  .replaceAll("hour ago", "h")
                  .replaceAll("hours ago", "h")
                  .replaceAll("day ago", "d")
                  .replaceAll("days ago", "d"),
              style: TextStyle(
                fontSize: 11,
                color: otherProfile.lastAction!.status == "Idle" ? Colors.orange : Colors.grey,
              ),
            ),
          ),
      ],
    );

    if (spyFound) {
      // Stats spans
      final statsSpans = <TextSpan>[];
      // STR
      var strColor = Colors.white;
      if (strength != -1) {
        if (_userDetails.basic!.strength! >= strength!) {
          strColor = Colors.green;
        } else if (_userDetails.basic!.strength! * 1.15 > strength) {
          strColor = Colors.orange;
        } else {
          strColor = Colors.red;
        }
        statsSpans.add(
          const TextSpan(
            text: "STR ",
            style: TextStyle(color: Colors.white, fontSize: 11),
          ),
        );
        statsSpans.add(
          TextSpan(
            text: formatBigNumbers(strength),
            style: TextStyle(color: strColor, fontSize: 11),
          ),
        );
        statsSpans.add(
          const TextSpan(
            text: ", ",
            style: TextStyle(color: Colors.white, fontSize: 11),
          ),
        );
      } else {
        statsSpans.add(
          const TextSpan(
            text: "STR ?, ",
            style: TextStyle(color: Colors.white, fontSize: 11),
          ),
        );
      }
      // SPD
      var spdColor = Colors.white;
      if (speed != -1) {
        if (_userDetails.basic!.speed! >= speed!) {
          spdColor = Colors.green;
        } else if (_userDetails.basic!.speed! * 1.15 > speed) {
          spdColor = Colors.orange;
        } else {
          spdColor = Colors.red;
        }
        statsSpans.add(
          const TextSpan(
            text: "SPD ",
            style: TextStyle(color: Colors.white, fontSize: 11),
          ),
        );
        statsSpans.add(
          TextSpan(
            text: formatBigNumbers(speed),
            style: TextStyle(color: spdColor, fontSize: 11),
          ),
        );
        statsSpans.add(
          const TextSpan(
            text: ", ",
            style: TextStyle(color: Colors.white, fontSize: 11),
          ),
        );
      } else {
        statsSpans.add(
          const TextSpan(
            text: "SPD ?, ",
            style: TextStyle(color: Colors.white, fontSize: 11),
          ),
        );
      }
      // DEF
      var defColor = Colors.white;
      if (defense != -1) {
        if (_userDetails.basic!.defense! >= defense!) {
          defColor = Colors.green;
        } else if (_userDetails.basic!.defense! * 1.15 > defense) {
          defColor = Colors.orange;
        } else {
          defColor = Colors.red;
        }
        statsSpans.add(
          const TextSpan(
            text: "DEF ",
            style: TextStyle(color: Colors.white, fontSize: 11),
          ),
        );
        statsSpans.add(
          TextSpan(
            text: formatBigNumbers(defense),
            style: TextStyle(color: defColor, fontSize: 11),
          ),
        );
        statsSpans.add(
          const TextSpan(
            text: ", ",
            style: TextStyle(color: Colors.white, fontSize: 11),
          ),
        );
      } else {
        statsSpans.add(
          const TextSpan(
            text: "DEF ?, ",
            style: TextStyle(color: Colors.white, fontSize: 11),
          ),
        );
      }
      // DEX
      var dexColor = Colors.white;
      if (dexterity != -1) {
        if (_userDetails.basic!.dexterity! >= dexterity!) {
          dexColor = Colors.green;
        } else if (_userDetails.basic!.dexterity! * 1.15 > dexterity) {
          dexColor = Colors.orange;
        } else {
          dexColor = Colors.red;
        }
        statsSpans.add(
          const TextSpan(
            text: "DEX ",
            style: TextStyle(color: Colors.white, fontSize: 11),
          ),
        );
        statsSpans.add(
          TextSpan(
            text: formatBigNumbers(dexterity),
            style: TextStyle(color: dexColor, fontSize: 11),
          ),
        );
      } else {
        statsSpans.add(
          const TextSpan(
            text: "DEX ?",
            style: TextStyle(color: Colors.white, fontSize: 11),
          ),
        );
      }

      Color infoColorStats = Colors.white;
      if (total != -1) {
        infoColorStats = Colors.red;
        if (_userDetails.basic!.total! >= total!) {
          infoColorStats = Colors.green;
        } else if (_userDetails.basic!.total! * 1.15 > total) {
          infoColorStats = Colors.orange;
        }
      }

      _statsWidget = Container(
        color: Colors.grey[900],
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 4, 8, 4),
          child: Row(
            children: [
              Image.asset(
                _spy.spiesSource == SpiesSource.yata ? 'images/icons/yata_logo.png' : 'images/icons/tornstats_logo.png',
                height: 18,
              ),
              const SizedBox(width: 8),
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
                          showDialog<void>(
                            context: context,
                            builder: (BuildContext context) {
                              final spiesPayload = SpiesPayload(
                                spy: _spy,
                                strength: strength ?? -1,
                                strengthUpdate: strengthUpdate,
                                defense: defense ?? -1,
                                defenseUpdate: defenseUpdate,
                                speed: speed ?? -1,
                                speedUpdate: speedUpdate,
                                dexterity: dexterity ?? -1,
                                dexterityUpdate: dexterityUpdate,
                                total: total ?? -1,
                                totalUpdate: totalUpdate,
                                update: totalUpdate,
                                name: _playerName!,
                                factionName: _factionName!,
                                themeProvider: widget.themeProvider!,
                                userDetailsProvider: _userDetails,
                              );

                              final estimatedStatsPayload = EstimatedStatsPayload(
                                xanaxCompare: xanaxComparison,
                                xanaxColor: xanaxColor,
                                refillCompare: refillComparison,
                                refillColor: refillColor,
                                enhancementCompare: enhancementComparison,
                                enhancementColor: enhancementColor,
                                cansCompare: cansComparison,
                                cansColor: cansColor,
                                sslColor: sslColor,
                                sslProb: sslProb,
                                otherXanTaken: otherProfile.personalstats!.xantaken!,
                                otherEctTaken: otherProfile.personalstats!.exttaken!,
                                otherLsdTaken: otherProfile.personalstats!.lsdtaken!,
                                otherName: otherProfile.name!,
                                otherFactionName: otherProfile.name!,
                                otherLastActionRelative: otherProfile.lastAction!.relative!,
                                themeProvider: widget.themeProvider!,
                              );

                              final tscStatsPayload = TSCStatsPayload(targetId: otherProfile.playerId!);

                              return StatsDialog(
                                spiesPayload: spiesPayload,
                                estimatedStatsPayload: estimatedStatsPayload,
                                tscStatsPayload: _settingsProvider.tscEnabledStatus != 0 ? tscStatsPayload : null,
                              );
                            },
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
    } else if (!spyFound) {
      _statsWidget = Container(
        color: Colors.grey[900],
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 4, 8, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    Text(
                      npc ? "" : "(EST)",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      estimatedStats,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontStyle: estimatedStats == "(EST) UNK" ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                    const SizedBox(width: 5),
                    if (!npc)
                      Flexible(
                        child: Wrap(
                          children: additional,
                        ),
                      ),
                  ],
                ),
              ),
              if (!npc)
                Padding(
                  padding: const EdgeInsets.only(right: 30),
                  child: onlineStatus,
                ),
              if (!npc)
                Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: GestureDetector(
                    child: const Icon(
                      Icons.info_outline,
                      color: Colors.white,
                      size: 18,
                    ),
                    onTap: () {
                      showDialog<void>(
                        context: context,
                        builder: (BuildContext context) {
                          final estimatedStatsPayload = EstimatedStatsPayload(
                            xanaxCompare: xanaxComparison,
                            xanaxColor: xanaxColor,
                            refillCompare: refillComparison,
                            refillColor: refillColor,
                            enhancementCompare: enhancementComparison,
                            enhancementColor: enhancementColor,
                            cansCompare: cansComparison,
                            cansColor: cansColor,
                            sslColor: sslColor,
                            sslProb: sslProb,
                            otherXanTaken: otherProfile.personalstats!.xantaken!,
                            otherEctTaken: otherProfile.personalstats!.exttaken!,
                            otherLsdTaken: otherProfile.personalstats!.lsdtaken!,
                            otherName: otherProfile.name!,
                            otherFactionName: otherProfile.name!,
                            otherLastActionRelative: otherProfile.lastAction!.relative!,
                            themeProvider: widget.themeProvider!,
                          );

                          final tscStatsPayload = TSCStatsPayload(targetId: otherProfile.playerId!);

                          return StatsDialog(
                            spiesPayload: null,
                            estimatedStatsPayload: estimatedStatsPayload,
                            tscStatsPayload: _settingsProvider.tscEnabledStatus != 0 ? tscStatsPayload : null,
                          );
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      );

      // This might come a few seconds after the main widget builds, so we are showing
      // it if mounted and refreshing state
      if (mounted) {
        setState(() {});
      }
    }
  }
}
