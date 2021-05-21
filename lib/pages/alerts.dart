// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

// Project imports:
import 'package:torn_pda/models/firebase_user_model.dart';
import 'package:torn_pda/models/profile/own_profile_basic.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/utils/api_caller.dart';
import 'package:torn_pda/utils/firebase_auth.dart';
import 'package:torn_pda/utils/firebase_firestore.dart';
import 'package:torn_pda/utils/notification.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/alerts/events_filter_dialog.dart';
import 'package:torn_pda/widgets/alerts/refills_requested_dialog.dart';
import '../main.dart';
import 'alerts/stockmarket_alerts_page.dart';

class AlertsSettings extends StatefulWidget {
  @override
  _AlertsSettingsState createState() => _AlertsSettingsState();
}

class _AlertsSettingsState extends State<AlertsSettings> {
  FirebaseUserModel _firebaseUserModel;

  Future _firestoreProfileReceived;

  SettingsProvider _settingsProvider;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _firestoreProfileReceived = firestore.getUserProfile(force: false);
    analytics.logEvent(name: 'section_changed', parameters: {'section': 'alerts'});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
      bottomNavigationBar: !_settingsProvider.appBarTop
          ? SizedBox(
              height: AppBar().preferredSize.height,
              child: buildAppBar(),
            )
          : null,
      body: FutureBuilder(
          future: _firestoreProfileReceived,
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.data is FirebaseUserModel) {
                _firebaseUserModel = snapshot.data;
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          "Alerts are automatic notifications that you only "
                          "need to activate once. However, you will normally be notified "
                          "earlier than with manual notifications; also, notifications might be delayed "
                          "due to network status or device throttling.",
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                        child: CheckboxListTile(
                          checkColor: Colors.white,
                          activeColor: Colors.blueGrey,
                          value: _firebaseUserModel.travelNotification ?? false,
                          title: Text("Travel"),
                          subtitle: Text(
                            "Get notified just before you arrive",
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _firebaseUserModel?.travelNotification = value;
                            });
                            firestore.subscribeToTravelNotification(value);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                        child: CheckboxListTile(
                          checkColor: Colors.white,
                          activeColor: Colors.blueGrey,
                          value: _firebaseUserModel.foreignRestockNotification ?? false,
                          title: Text("Foreign stocks"),
                          subtitle: Text(
                            "Get notified whenever new stocks are put in the market abroad. NOTE: in order to activate "
                            "specific stock alerts, you need to go to the stocks page (Travel section) to activate the ones you are interested in!",
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _firebaseUserModel?.foreignRestockNotification = value;
                            });
                            firestore.subscribeToForeignRestockNotification(value);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 5, 8, 0),
                        child: CheckboxListTile(
                          checkColor: Colors.white,
                          activeColor: Colors.blueGrey,
                          value: _firebaseUserModel.energyNotification ?? false,
                          title: Text("Energy full"),
                          subtitle: Text(
                            "Get notified once you reach full energy",
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _firebaseUserModel?.energyNotification = value;
                            });
                            firestore.subscribeToEnergyNotification(value);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 5, 8, 0),
                        child: CheckboxListTile(
                          checkColor: Colors.white,
                          activeColor: Colors.blueGrey,
                          value: _firebaseUserModel.nerveNotification ?? false,
                          title: Text("Nerve full"),
                          subtitle: Text(
                            "Get notified once you reach full nerve",
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _firebaseUserModel?.nerveNotification = value;
                            });
                            firestore.subscribeToNerveNotification(value);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 5, 8, 0),
                        child: CheckboxListTile(
                          checkColor: Colors.white,
                          activeColor: Colors.blueGrey,
                          value: _firebaseUserModel.hospitalNotification ?? false,
                          title: Text("Hospital admission and release"),
                          subtitle: Text(
                            "If you are offline, you'll be notified if you are "
                            "hospitalised, revived or out of hospital",
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _firebaseUserModel?.hospitalNotification = value;
                            });
                            firestore.subscribeToHospitalNotification(value);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 5, 8, 0),
                        child: CheckboxListTile(
                          checkColor: Colors.white,
                          activeColor: Colors.blueGrey,
                          value: _firebaseUserModel.drugsNotification ?? false,
                          title: Text("Drugs cooldown"),
                          subtitle: Text(
                            "Get notified when your drugs cooldown "
                            "has expired",
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _firebaseUserModel?.drugsNotification = value;
                            });
                            firestore.subscribeToDrugsNotification(value);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 5, 8, 0),
                        child: CheckboxListTile(
                          checkColor: Colors.white,
                          activeColor: Colors.blueGrey,
                          value: _firebaseUserModel.racingNotification ?? false,
                          title: Text("Racing"),
                          subtitle: Text(
                            "Get notified when you cross the finish line",
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _firebaseUserModel?.racingNotification = value;
                            });
                            firestore.subscribeToRacingNotification(value);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 5, 8, 0),
                        child: CheckboxListTile(
                          checkColor: Colors.white,
                          activeColor: Colors.blueGrey,
                          value: _firebaseUserModel.messagesNotification ?? false,
                          title: Text("Messages"),
                          subtitle: Text(
                            "Get notified when you receive new messages",
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _firebaseUserModel?.messagesNotification = value;
                            });
                            firestore.subscribeToMessagesNotification(value);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 5, 8, 0),
                        child: CheckboxListTile(
                          checkColor: Colors.white,
                          activeColor: Colors.blueGrey,
                          value: _firebaseUserModel.eventsNotification ?? false,
                          title: Text("Events"),
                          subtitle: Text(
                            "Get notified when you receive new events",
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _firebaseUserModel?.eventsNotification = value;
                            });
                            firestore.subscribeToEventsNotification(value);
                          },
                        ),
                      ),
                      if (_firebaseUserModel?.eventsNotification)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(25, 0, 20, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: Text(
                                  "Filter out events",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                              IconButton(
                                  icon: Icon(Icons.keyboard_arrow_right_outlined),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return EventsFilterDialog(
                                          userModel: _firebaseUserModel,
                                        );
                                      },
                                    );
                                  }),
                            ],
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 5, 8, 0),
                        child: CheckboxListTile(
                          checkColor: Colors.white,
                          activeColor: Colors.blueGrey,
                          value: _firebaseUserModel.refillsNotification ?? false,
                          title: Text("Refills"),
                          subtitle: Text(
                            "Get notified (22:00 TCT) if you still have unused refills",
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _firebaseUserModel?.refillsNotification = value;
                            });
                            firestore.subscribeToRefillsNotification(value);
                          },
                        ),
                      ),
                      if (_firebaseUserModel?.refillsNotification)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(25, 0, 20, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: Text(
                                  "Choose refills",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.keyboard_arrow_right_outlined),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return RefillsRequestedDialog(
                                        userModel: _firebaseUserModel,
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 5, 15, 0),
                        child: ListTile(
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Stock market gain/loss"),
                              GestureDetector(
                                child: Icon(Icons.keyboard_arrow_right_outlined),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) {
                                        return StockMarketAlertsPage();
                                      },
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          subtitle: Text(
                            "Configure price gain/loss alerts for any traded company",
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 60),
                    ],
                  ),
                );
              } else {
                return _connectError();
              }
            } else {
              return Center(child: CircularProgressIndicator());
            }
          }),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      brightness: Brightness.dark,
      title: Text('Alerts'),
      leading: new IconButton(
        icon: new Icon(Icons.menu),
        onPressed: () {
          final ScaffoldState scaffoldState = context.findRootAncestorStateOfType();
          scaffoldState.openDrawer();
        },
      ),
      actions: <Widget>[
        IconButton(
          icon: Icon(
            MdiIcons.hammer,
          ),
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return _troubleShootingDialog();
              },
            );
          },
        ),
        IconButton(
          icon: Icon(
            Icons.info_outline,
          ),
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return _alertsInfoDialog();
              },
            );
          },
        ),
      ],
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
            'There was an error contacting the server!',
            style: TextStyle(
              color: Colors.red,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Please try again later.',
            style: TextStyle(
              color: Colors.red,
            ),
          ),
          SizedBox(height: 20),
          Text('If this problem reoccurs, please log out from Torn API (remove '
              'you API Key in the Settings section and insert it again). Sorry for '
              'the inconvenience!'),
        ],
      ),
    );
  }

  Widget _alertsInfoDialog() {
    return AlertDialog(
      title: Text(
        "Alerts",
        style: TextStyle(
          fontSize: 18,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Note: if you don't use Torn PDA for more than 5 days, "
                "all notifications will be turned off automatically. "
                "\n\nThis is to prevent the over usage of resources. "
                "Please make sure you return back to the app once a "
                "week to get uninterrupted service.",
                style: TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text("Close"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        )
      ],
    );
  }

  Widget _troubleShootingDialog() {
    return AlertDialog(
      title: Text(
        "Troubleshooting",
        style: TextStyle(
          fontSize: 18,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "If you are having issues receiving alerts, this will try to reset your server-based "
                "configuration and notifications channels. "
                "\n\nYou won't lose any settings or configurations. "
                "If it doesn't solve the problem, however, you can contact us directly in Discord."
                "\n\nTap Reset below to proceed.",
                style: TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text("Reset"),
          onPressed: () async {
            Navigator.of(context).pop();

            try {
              var _userProv = context.read<UserDetailsProvider>();

              // We save the key because the API call will reset it
              var savedKey = _userProv.basic.userApiKey;

              dynamic myProfile = await TornApiCaller.ownBasic(savedKey).getProfileBasic;

              if (myProfile is OwnProfileBasic) {
                myProfile
                  ..userApiKey = savedKey
                  ..userApiKeyValid = true;

                User mFirebaseUser = await firebaseAuth.signInAnon();
                firestore.setUID(mFirebaseUser.uid);
                await firestore.uploadUsersProfileDetail(myProfile, userTriggered: true);
                await firestore.uploadLastActiveTime(DateTime.now().millisecondsSinceEpoch);

                if (Platform.isAndroid) {
                  var alertsVibration = await Prefs().getVibrationPattern();
                  // Deletes current channels and create new ones
                  reconfigureNotificationChannels(mod: alertsVibration);
                  // Update channel preferences
                  firestore.setVibrationPattern(alertsVibration);
                }
              }

              BotToast.showText(
                text: "Reset successful",
                textStyle: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
                contentColor: Colors.green[800],
                duration: Duration(seconds: 5),
                contentPadding: EdgeInsets.all(10),
              );
            } catch (e) {
              BotToast.showText(
                text: "There was an error: $e",
                textStyle: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
                contentColor: Colors.orange[800],
                duration: Duration(seconds: 5),
                contentPadding: EdgeInsets.all(10),
              );
            }
          },
        ),
        TextButton(
          child: Text("Close"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        )
      ],
    );
  }
}
