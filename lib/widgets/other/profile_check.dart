import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:torn_pda/models/chaining/target_model.dart';
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
          } else if (_errorToShow){
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
    var target = await TornApiCaller.target(
      widget.apiKey,
      widget.profileId.toString(),
    ).getTarget;

    var tornPda = false;
    var ownProfile = false;
    var partner = false;
    var ownFaction = false;

    bool standard = false;
    if (target is TargetModel) {
      if (target.playerId == 2225097) {
        tornPda = true;
      }

      if (target.playerId == _userDetails.basic.playerId) {
        ownProfile = true;
        standard = true;
      }

      if (target.married.spouseId == _userDetails.basic.playerId) {
        partner = true;
        standard = true;
      }

      if (target.faction.factionId == _userDetails.basic.faction.factionId) {
        ownFaction = true;
        standard = true;
      }

      if ((tornPda || standard) && mounted) {
        Widget tornPdaDetails = SizedBox.shrink();
        Widget widgetDetails = SizedBox.shrink();
        Color backgroundColor = Colors.transparent;

        if (tornPda) {
          tornPdaDetails = Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Image.asset(
                'images/icons/torn_pda.png',
                width: 16,
                height: 16,
                //color: Colors.brown[400],
              ),
              SizedBox(width: 10),
              Text(
                "Hi! Thank you for using Torn PDA!",
                style: TextStyle(
                  color: Colors.pink,
                  fontSize: 12,
                ),
              ),
            ],
          );
        }

        if (ownProfile) {
          widgetDetails = Row(
            children: [
              Icon(
                MdiIcons.heart,
                color: Colors.green,
                size: 16,
              ),
              SizedBox(width: 10),
              Text(
                "This is you, you're beautiful!",
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                ),
              ),
            ],
          );
        } else if (ownFaction) {
          if (widget.profileCheckType == ProfileCheckType.profile) {
            widgetDetails = Row(
              children: [
                Image.asset(
                  'images/icons/faction.png',
                  width: 15,
                  height: 16,
                  color: Colors.green,
                ),
                SizedBox(width: 10),
                Text(
                  "This is a fellow faction member (${target.faction.position})!",
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                  ),
                ),
              ],
            );
          } else if (widget.profileCheckType == ProfileCheckType.attack) {
            backgroundColor = Colors.red;
            widgetDetails = Row(
              children: [
                Image.asset(
                  'images/icons/faction.png',
                  width: 15,
                  height: 16,
                  color: Colors.black,
                ),
                SizedBox(width: 10),
                Text(
                  "CAUTION: this is a fellow faction member!",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            );
          }
        } else if (partner) {
          if (widget.profileCheckType == ProfileCheckType.profile) {
            widgetDetails = Row(
              children: [
                Icon(
                  MdiIcons.heart,
                  color: Colors.red,
                  size: 16,
                ),
                SizedBox(width: 10),
                Text(
                  "This is your lovely ${target.gender == "Male" ? "husband" : "wife"}!",
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                  ),
                ),
              ],
            );
          } else if (widget.profileCheckType == ProfileCheckType.attack) {
            backgroundColor = Colors.red;
            widgetDetails = Row(
              children: [
                Icon(
                  MdiIcons.heart,
                  color: Colors.black,
                  size: 16,
                ),
                SizedBox(width: 10),
                Text(
                  "CAUTION: this is your ${target.gender == "Male" ? "husband" : "wife"}!",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            );
          }
        }

        Widget mainWidgetBox = Container(
          color: backgroundColor,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    tornPdaDetails,
                    if (tornPda && standard) SizedBox(height: 8),
                    widgetDetails,
                  ],
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
}
