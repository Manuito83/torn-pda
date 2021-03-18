import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:torn_pda/models/profile/other_profile_model.dart';
import 'package:torn_pda/providers/friends_provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/utils/api_caller.dart';
import 'package:provider/provider.dart';

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

  Widget _mainDetailsWidget = SizedBox.shrink();

  UserDetailsProvider _userDetails;
  var _expandableController = ExpandableController();

  @override
  void initState() {
    super.initState();
    _userDetails = context.read<UserDetailsProvider>();

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
              controller: _expandableController,
              expanded: _mainDetailsWidget,
            );
          } else if (_errorToShow) {
            return ExpandablePanel(
              controller: _expandableController,
              expanded: _mainDetailsWidget,
            );
          } else {
            return SizedBox.shrink();
          }
        }
        return SizedBox.shrink();
      },
    );
  }

  Future<void> _fetchAndAssess() async {
    var otherProfile = await TornApiCaller.target(
      widget.apiKey,
      widget.profileId.toString(),
    ).getOtherProfile;

    // FRIEND CHECK
    var isFriend = false;
    var friendsProv = context.read<FriendsProvider>();
    if (!friendsProv.initialized) {
      await friendsProv.initFriends();
    }
    for (var friend in friendsProv.allFriends) {
      if (friend.playerId == widget.profileId) isFriend = true;
    }

    var isTornPda = false;
    var isPartner = false;

    var isOwnPlayer = false;
    var isOwnFaction = false;
    var isFriendlyFaction = false;
    // This one will take own player, own faction or friendly faction (so that
    // we don't show them separately, but by importance (first one self, then
    // own faction and lastly friendly faction)
    var playerOrFaction = false;

    var hasEstimatedStats = false;

    if (otherProfile is OtherProfileModel) {

      String estimatedStats = "";
      try {
        estimatedStats = _calculateStats(otherProfile);
        hasEstimatedStats = true;
      } catch (e) {
        // Will be empty
      }

      if (otherProfile.playerId == 2225097) {
        isTornPda = true;
      }

      if (otherProfile.married.spouseId == _userDetails.basic.playerId) {
        isPartner = true;
      }

      if (otherProfile.playerId == _userDetails.basic.playerId) {
        isOwnPlayer = true;
        playerOrFaction = true;
      }

      if (otherProfile.faction.factionId ==
          _userDetails.basic.faction.factionId) {
        isOwnFaction = true;
        playerOrFaction = true;
      }

      var settingsProvider = context.read<SettingsProvider>();
      for (var fact in settingsProvider.friendlyFactions) {
        if (otherProfile.faction.factionId == fact.id) {
          isFriendlyFaction = true;
          break;
        }
      }

      if ((hasEstimatedStats ||
              isTornPda ||
              isPartner ||
              isFriend ||
              isFriendlyFaction ||
              playerOrFaction) &&
          mounted) {
        Widget estimatedStatsWidget = SizedBox.shrink();
        Widget tornPdaWidget = SizedBox.shrink();
        Widget partnerWidget = SizedBox.shrink();
        Widget friendsWidget = SizedBox.shrink();
        Widget friendlyFactionWidget = SizedBox.shrink();
        Widget playerOrFactionWidget = SizedBox.shrink();
        Color backgroundColor = Colors.transparent;

        if (hasEstimatedStats) {
          estimatedStatsWidget = Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  "STATS:",
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
          );
        }

        if (isTornPda) {
          tornPdaWidget = Row(
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
          );
        }

        if (isFriend) {
          Color friendTextColor = Colors.green;
          String friendText = "This is a friend of yours!";
          if (widget.profileCheckType == ProfileCheckType.attack) {
            friendTextColor = Colors.black;
            friendText = "CAUTION: this is a friend of yours!";
            backgroundColor = Colors.red;
          }
          friendsWidget = Row(
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

        if (isOwnPlayer) {
          playerOrFactionWidget = Row(
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
        } else if (isOwnFaction) {
          String factionText = "This is a fellow faction member "
              "(${otherProfile.faction.position.toLowerCase()})!";
          Color factionColor = Colors.green;
          if (widget.profileCheckType == ProfileCheckType.attack) {
            factionColor = Colors.black;
            factionText = "CAUTION: this is a fellow faction member!";
            backgroundColor = Colors.red;
          }
          playerOrFactionWidget = Row(
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
        } else if (isFriendlyFaction) {
          String factionText = "This is an allied faction member "
              "(${otherProfile.faction.factionName})!";
          Color factionColor = Colors.green;
          if (widget.profileCheckType == ProfileCheckType.attack) {
            factionColor = Colors.black;
            factionText = "CAUTION: this is an allied faction member!";
            backgroundColor = Colors.red;
          }

          friendlyFactionWidget = Row(
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

        if (isPartner) {
          String partnerText = "This is your lovely "
              "${otherProfile.gender == "Male" ? "husband" : "wife"}!";
          Color partnerColor = Colors.green;
          if (widget.profileCheckType == ProfileCheckType.attack) {
            partnerColor = Colors.black;
            partnerText = "CAUTION: this is your "
                "${otherProfile.gender == "Male" ? "husband" : "wife"}! "
                "Are you really that mad at "
                "${otherProfile.gender == "Male" ? "him" : "her"}?";
            backgroundColor = Colors.red;
          }

          partnerWidget = Row(
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

        Widget mainWidgetBox = Container(
          color: backgroundColor,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Flexible(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      estimatedStatsWidget,
                      if (hasEstimatedStats && isTornPda) SizedBox(height: 8),
                      tornPdaWidget,
                      if ((hasEstimatedStats || isTornPda) && isPartner)
                        SizedBox(height: 8),
                      partnerWidget,
                      if ((hasEstimatedStats || isTornPda || isPartner) &&
                          isFriend)
                        SizedBox(height: 8),
                      friendsWidget,
                      if ((hasEstimatedStats ||
                              isTornPda ||
                              isPartner ||
                              isFriend) &&
                          playerOrFaction)
                        SizedBox(height: 8),
                      playerOrFactionWidget,
                      if ((hasEstimatedStats ||
                              isTornPda ||
                              isPartner ||
                              isFriend ||
                              playerOrFaction) &&
                          isFriendlyFaction)
                        SizedBox(height: 8),
                      friendlyFactionWidget,
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

        setState(() {
          _mainDetailsWidget = mainWidgetBox;
          _infoToShow = true;
          _expandableController.expanded = true;
        });
      }
    } else {
      Widget errorDetails = Container(
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

      setState(() {
        _errorToShow = true;
        _expandableController.expanded = true;
        _mainDetailsWidget = errorDetails;
      });
    }
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
