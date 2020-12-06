import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/utils/external/yata_comm.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/models/awards/awards_model.dart' as yata;
import 'package:torn_pda/widgets/other/flipping_yata.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class Award {
  Award({
    this.name = "",
    this.description = "",
    this.type = "",
    this.image = "",
    this.achieve = 0,
    this.daysLeft = 0,
  });

  String name;
  String description;
  String type;
  String image;
  double achieve;
  double daysLeft;
}

class AwardsPage extends StatefulWidget {
  @override
  _AwardsPageState createState() => _AwardsPageState();
}

class _AwardsPageState extends State<AwardsPage> {
  // Main list with all awards
  var _allAwards = List<Award>();

  Future _getAwardsPayload;
  bool _apiSuccess = false;

  SettingsProvider _settingsProvider;
  UserDetailsProvider _userProvider;
  ThemeProvider _themeProvider;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _userProvider = Provider.of<UserDetailsProvider>(context, listen: false);
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
      body: FutureBuilder(
        future: _getAwardsPayload,
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (_apiSuccess) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(left: 15, top: 5),
                      child: ListView(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        children: _allAwardsCards(),
                      ),
                    ),
                    SizedBox(height: 20),
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
                  Text('Fetching data...'),
                  SizedBox(height: 30),
                  FlippingYata(),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      title: Text('Awards'),
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

  List<Widget> _allAwardsCards() {
    var awardsCards = List<Widget>();

    for (var award in _allAwards) {
      Color borderColor = Colors.transparent;
      if (award.achieve == 1) {
        borderColor = Colors.green;
      } else if (award.achieve > 0.80 && award.achieve < 1) {
        borderColor = Colors.blue;
      }

      awardsCards.add(
        Card(
          shape: RoundedRectangleBorder(
            side: BorderSide(color: borderColor, width: 1.5),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              children: [
                Text(award.name),
                Row(
                  children: [
                    Text("${(award.achieve * 100).round()}%"),
                    SizedBox(width: 10),

                    // TODO: show awarded time instead, if already achieved
                    award.daysLeft != null
                        ? Text("${(award.daysLeft).round()} days")
                        : SizedBox.shrink(),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return awardsCards;
  }

  Future _fetchYataApi() async {
    var reply = await YataComm.getAwards(_userProvider.myUser.userApiKey);
    if (reply is YataError) {
      // TODO
    } else {
      await _populateInfo(reply);
      _apiSuccess = true;
    }
  }

  _populateInfo(yata.YataAwards awardsModel) {
    var awardsMap = awardsModel.awards.toJson();

    awardsMap.forEach((awardsType, awardValues) {
      var awardsMap = awardValues as Map;

      awardsMap.forEach((key, value) {
        try {
          var singleAward = Award(
            type: awardsType,
            name: value["name"],
            description: value["description"],
            image: value["img"] == null ? null : value["img"],
            achieve: value["achieve"].toDouble(),
            daysLeft: value["left"] == null
                ? null
                : value["left"] is String
                    ? double.parse(value["left"])
                    : value["left"].toDouble(),
          );
          _allAwards.add(singleAward);
        } catch (e) {
          // TODO activate and delete print
          print(e);
          /*          FirebaseCrashlytics.instance
              .log("PDA Crash at YATA AWARD (${value["name"]}). Error: $e");
          FirebaseCrashlytics.instance.recordError(e, null);*/
        }
      });
    });
  }
}
