// Dart imports:
import 'dart:developer';
import 'dart:io';

// Package imports:
import 'package:expandable/expandable.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
// Flutter imports:
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/chaining/yata/yata_spy_model.dart';
// Project imports:
import 'package:torn_pda/models/profile/other_profile_model/other_profile_pda.dart';
import 'package:torn_pda/models/profile/own_stats_model.dart';
import 'package:torn_pda/providers/api/api_v1_calls.dart';
import 'package:torn_pda/providers/api/api_v2_calls.dart';
import 'package:torn_pda/providers/friends_provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/spies_controller.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/number_formatter.dart';
import 'package:torn_pda/utils/stats_calculator.dart';
import 'package:torn_pda/utils/user_helper.dart';
import 'package:torn_pda/utils/webview_dialog_helper.dart';
import 'package:torn_pda/widgets/profile_check/profile_check_add_button.dart';
import 'package:torn_pda/widgets/profile_check/profile_check_notes.dart';
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
  final SpiesController _spyController = Get.find<SpiesController>();

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
        if (_settingsProvider.notesWidgetEnabledProfile)
          ProfileCheckNotes(
            profileId: widget.profileId.toString(),
            playerName: _playerName,
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
    try {
      final dynamic otherProfile = await ApiCallsV2.getOtherUserProfile_v2(
        payload: {
          "id": widget.profileId.toString(),
        },
      );

      // FRIEND CHECK
      if (!mounted) return; // We could be unmounted when rapidly skipping the first target

      final friendsProv = context.read<FriendsProvider>();
      if (!friendsProv.initialized) {
        await friendsProv.initFriends();
      }
      for (final friend in friendsProv.allFriends) {
        if (friend.playerId == widget.profileId) _isFriend = true;
      }

      if (otherProfile is OtherProfilePDA) {
        logToUser(
          "Profile Check API received for: ${otherProfile.name}",
          backgroundcolor: Colors.blue,
          borderColor: Colors.white,
          duration: 8,
        );

        _playerName = otherProfile.name;
        _factionName = otherProfile.factionName;
        _factionId = otherProfile.factionId;

        // Estimated stats is not awaited, since it can take a few seconds
        // to contact YATA / TS and decide what we show
        estimatedStatsCalculator(otherProfile).then((value) {
          setState(() {});
        });

        if (otherProfile.id == 2225097 || otherProfile.id == 2190604) {
          _isTornPda = true;
        }

        if (otherProfile.isMySpouse(UserHelper.playerId)) {
          _isPartner = true;
        }

        if (otherProfile.id == UserHelper.playerId) {
          _isOwnPlayer = true;
        }

        if (otherProfile.isInMyFaction(UserHelper.factionId)) {
          _isOwnFaction = true;
        }

        final settingsProvider = context.read<SettingsProvider>();
        for (final fact in settingsProvider.friendlyFactions) {
          if (otherProfile.factionId == fact.id) {
            _isFriendlyFaction = true;
            break;
          }
        }

        if (!_isOwnPlayer && otherProfile.hasJob && otherProfile.jobId == UserHelper.companyId) {
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
              "(${otherProfile.factionPosition})!";
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
              "(${otherProfile.factionName})!";
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
          if (otherProfile.bazaar != null && otherProfile.bazaar!.isNotEmpty) {
            for (final item in otherProfile.bazaar!) {
              bazaar += item.totalValue;
            }
          }

          _networthWidget = Container(
            color: Colors.grey[900],
            child: Padding(
              padding: const EdgeInsets.fromLTRB(15, 4, 15, 4),
              child: Row(
                children: [
                  const Icon(
                    MdiIcons.cash100,
                    color: Colors.green,
                    size: 17,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      formatBigNumbers(otherProfile.personalstats?.networth ?? 0),
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

        logToUser(
          "Profile Check: expanded!",
          backgroundcolor: Colors.blue,
          borderColor: Colors.white,
          duration: 8,
        );
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
    } catch (e, trace) {
      logToUser(
        "Profile Check Error: $e, $trace",
        backgroundcolor: Colors.blue,
        borderColor: Colors.white,
        duration: 8,
      );
      if (!Platform.isWindows) {
        FirebaseCrashlytics.instance.log("PDA Crash at Profile Check");
        FirebaseCrashlytics.instance.recordError("PDA Error: $e", trace);
      }
    }
  }

  Future estimatedStatsCalculator(OtherProfilePDA otherProfile) async {
    // Even if we have no spy, we want to show estimated stats
    final npcs = [4, 10, 15, 17, 19, 20];
    String estimatedStats = "";
    bool npc = false;
    if (npcs.contains(otherProfile.id)) {
      estimatedStats = "NPC!";
      npc = true;
    } else {
      try {
        estimatedStats = StatsCalculator.calculateStats(
          criminalRecordTotal: otherProfile.personalstats?.criminalRecordTotal,
          level: otherProfile.level,
          networth: otherProfile.personalstats?.networth,
          rank: otherProfile.rank,
        );
      } catch (e) {
        estimatedStats = "UNK";
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
    final own = await ApiCallsV1.getOwnPersonalStats();
    if (own is OwnPersonalStatsModel) {
      // XANAX
      final int otherXanax = otherProfile.personalstats?.xanax ?? 0;
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
      final int otherRefill = otherProfile.personalstats?.energyRefills ?? 0;
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
      final int otherEnhancement = otherProfile.personalstats?.statEnhancers ?? 0;
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
      final int otherCans = otherProfile.personalstats?.energyDrinks ?? 0;
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
      ecstasy = otherProfile.personalstats?.ecstasy ?? 0;
      lsd = otherProfile.personalstats?.lsd ?? 0;
      if (otherXanax + ecstasy > 150) {
        sslProb = false;
      } else {
        if (lsd > 50 && lsd < 100) {
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

    YataSpyModel? yataSpy;
    SpiesSource? thisSource;

    // Locate the spy first based on the active source
    try {
      // Find the spy based in the current selected spy source
      if (_spyController.spiesSource == SpiesSource.yata) {
        final spy = _spyController.getYataSpy(userId: otherProfile.id.toString(), name: otherProfile.name);
        if (spy != null) {
          yataSpy = spy;
          thisSource = SpiesSource.yata;
        } else if (_spyController.allowMixedSpiesSources) {
          // Check alternate source of spies if we allow mixed sources
          final altSpy = _spyController.getTornStatsSpy(userId: otherProfile.id.toString());
          if (altSpy != null) {
            yataSpy = altSpy.toYataModel();
            thisSource = SpiesSource.tornStats;
          }
        }
      } else if (_spyController.spiesSource == SpiesSource.tornStats) {
        final spy = _spyController.getTornStatsSpy(userId: otherProfile.id.toString());
        if (spy != null) {
          yataSpy = spy.toYataModel();
          thisSource = SpiesSource.tornStats;
        } else if (_spyController.allowMixedSpiesSources) {
          // Check alternate source of spies if we allow mixed sources
          final altSpy = _spyController.getYataSpy(userId: otherProfile.id.toString(), name: otherProfile.name);
          if (altSpy != null) {
            yataSpy = altSpy;
            thisSource = SpiesSource.yata;
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
        if (otherProfile.lastActionStatus == "Offline")
          const Icon(Icons.remove_circle, size: 10, color: Colors.grey)
        else
          otherProfile.lastActionStatus == "Idle"
              ? const Icon(Icons.adjust, size: 12, color: Colors.orange)
              : const Icon(Icons.circle, size: 12, color: Colors.green),
        if (otherProfile.lastActionStatus == "Offline" || otherProfile.lastActionStatus == "Idle")
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              (otherProfile.lastActionRelative ?? '')
                  .replaceAll("minute ago", "m")
                  .replaceAll("minutes ago", "m")
                  .replaceAll("hour ago", "h")
                  .replaceAll("hours ago", "h")
                  .replaceAll("day ago", "d")
                  .replaceAll("days ago", "d"),
              style: TextStyle(
                fontSize: 11,
                color: otherProfile.lastActionStatus == "Idle" ? Colors.orange : Colors.grey,
              ),
            ),
          ),
      ],
    );

    if (yataSpy != null) {
      // Stats spans
      final statsSpans = <TextSpan>[];
      final strength = yataSpy.strength;
      final speed = yataSpy.speed;
      final defense = yataSpy.defense;
      final dexterity = yataSpy.dexterity;
      final total = yataSpy.total;
      // STR
      var strColor = Colors.white;
      if (strength != -1) {
        if (UserHelper.strength >= strength!) {
          strColor = Colors.green;
        } else if (UserHelper.strength * 1.15 > strength) {
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
        if (UserHelper.speed >= speed!) {
          spdColor = Colors.green;
        } else if (UserHelper.speed * 1.15 > speed) {
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
        if (UserHelper.defense >= defense!) {
          defColor = Colors.green;
        } else if (UserHelper.defense * 1.15 > defense) {
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
        if (UserHelper.dexterity >= dexterity!) {
          dexColor = Colors.green;
        } else if (UserHelper.dexterity * 1.15 > dexterity) {
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
        if (UserHelper.totalStats >= total!) {
          infoColorStats = Colors.green;
        } else if (UserHelper.totalStats * 1.15 > total) {
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
                thisSource == SpiesSource.yata ? 'images/icons/yata_logo.png' : 'images/icons/tornstats_logo.png',
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
                      padding: const EdgeInsets.only(left: 8),
                      child: GestureDetector(
                        child: Icon(
                          Icons.info_outline,
                          color: infoColorStats,
                          size: 18,
                        ),
                        onTap: () {
                          showWebviewDialog<void>(
                            context: context,
                            builder: (BuildContext context) {
                              final spiesPayload = SpiesPayload(
                                spyController: _spyController,
                                strength: strength ?? -1,
                                strengthUpdate: yataSpy?.strengthTimestamp ?? -1,
                                defense: defense ?? -1,
                                defenseUpdate: yataSpy?.defenseTimestamp ?? -1,
                                speed: speed ?? -1,
                                speedUpdate: yataSpy?.speedTimestamp ?? -1,
                                dexterity: dexterity ?? -1,
                                dexterityUpdate: yataSpy?.dexterityTimestamp ?? -1,
                                total: total ?? -1,
                                totalUpdate: yataSpy?.totalTimestamp,
                                update: yataSpy?.update ?? 0,
                                spySource: thisSource,
                                name: _playerName ?? '',
                                factionName: _factionName ?? '',
                                themeProvider: widget.themeProvider!,
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
                                otherXanTaken: otherProfile.personalstats?.xanax ?? 0,
                                otherEctTaken: otherProfile.personalstats?.ecstasy ?? 0,
                                otherLsdTaken: otherProfile.personalstats?.lsd ?? 0,
                                otherName: otherProfile.name ?? '',
                                otherFactionName: otherProfile.factionName ?? '',
                                otherLastActionRelative: otherProfile.lastActionRelative ?? '',
                                themeProvider: widget.themeProvider!,
                              );

                              final ffScouterStatsPayload = FFScouterStatsPayload(targetId: otherProfile.id ?? 0);
                              final yataStatsPayload = YataStatsPayload(targetId: otherProfile.id ?? 0);

                              return StatsDialog(
                                spiesPayload: spiesPayload,
                                estimatedStatsPayload: estimatedStatsPayload,
                                ffScouterStatsPayload:
                                    _settingsProvider.ffScouterEnabledStatus != 0 ? ffScouterStatsPayload : null,
                                yataStatsPayload:
                                    _settingsProvider.yataStatsEnabledStatus != 0 ? yataStatsPayload : null,
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
    } else if (yataSpy == null) {
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
                      showWebviewDialog<void>(
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
                            otherXanTaken: otherProfile.personalstats?.xanax ?? 0,
                            otherEctTaken: otherProfile.personalstats?.ecstasy ?? 0,
                            otherLsdTaken: otherProfile.personalstats?.lsd ?? 0,
                            otherName: otherProfile.name ?? '',
                            otherFactionName: otherProfile.factionName ?? '',
                            otherLastActionRelative: otherProfile.lastActionRelative ?? '',
                            themeProvider: widget.themeProvider!,
                          );

                          final ffScouterStatsPayload = FFScouterStatsPayload(targetId: otherProfile.id ?? 0);
                          final yataStatsPayload = YataStatsPayload(targetId: otherProfile.id ?? 0);

                          return StatsDialog(
                            spiesPayload: null,
                            estimatedStatsPayload: estimatedStatsPayload,
                            ffScouterStatsPayload:
                                _settingsProvider.ffScouterEnabledStatus != 0 ? ffScouterStatsPayload : null,
                            yataStatsPayload: _settingsProvider.yataStatsEnabledStatus != 0 ? yataStatsPayload : null,
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
