// Dart imports:
import 'dart:io';
// Package imports:
import 'package:bot_toast/bot_toast.dart';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
// Project imports:
import 'package:torn_pda/models/firebase_user_model.dart';
import 'package:torn_pda/models/profile/own_profile_basic.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/utils/api_caller.dart';
import 'package:torn_pda/utils/firebase_firestore.dart';
import 'package:torn_pda/utils/notification.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/alerts/events_filter_dialog.dart';
import 'package:torn_pda/widgets/alerts/loot_npc_dialog.dart';
import 'package:torn_pda/widgets/alerts/refills_requested_dialog.dart';

import '../main.dart';
import 'alerts/stockmarket_alerts_page.dart';

class AlertsSettings extends StatefulWidget {
  final Function stockMarketInMenuCallback;

  const AlertsSettings(this.stockMarketInMenuCallback);

  @override
  _AlertsSettingsState createState() => _AlertsSettingsState();
}

class _AlertsSettingsState extends State<AlertsSettings> {
  FirebaseUserModel _firebaseUserModel;

  Future _firestoreProfileReceived;

  SettingsProvider _settingsProvider;
  ThemeProvider _themeProvider;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _firestoreProfileReceived = firestore.getUserProfile();
    analytics.setCurrentScreen(screenName: 'alerts');
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return Scaffold(
      backgroundColor: _themeProvider.canvas,
      appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
      bottomNavigationBar: !_settingsProvider.appBarTop
          ? SizedBox(
              height: AppBar().preferredSize.height,
              child: buildAppBar(),
            )
          : null,
      body: Container(
        color: _themeProvider.canvas,
        child: FutureBuilder(
          future: _firestoreProfileReceived,
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.data is FirebaseUserModel) {
                if (_firebaseUserModel == null) {
                  // We don't use the snapshot data any longer if we have updated the model after a reset
                  _firebaseUserModel = snapshot.data as FirebaseUserModel;
                }
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      const Padding(
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
                          title: const Text("Travel"),
                          subtitle: const Text(
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
                          title: const Text("Foreign stocks"),
                          subtitle: const Text(
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
                          title: const Text("Energy full"),
                          subtitle: const Text(
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
                          title: const Text("Nerve full"),
                          subtitle: const Text(
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
                          title: const Text("Hospital admission and release"),
                          subtitle: const Text(
                            "If you are offline, you'll be notified if you are "
                            "hospitalized, revived or out of hospital",
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
                          title: const Text("Drugs cooldown"),
                          subtitle: const Text(
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
                          value: _firebaseUserModel.lootAlerts.isNotEmpty ?? false,
                          title: const Text("Loot"),
                          subtitle: const Text(
                            "Get notified when an NPC is about to reach level 4 or 5 (between 5 and 6 "
                            "minutes in advance)",
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          onChanged: (value) async {
                            await showDialog(
                              context: context,
                              barrierDismissible: true,
                              builder: (BuildContext context) {
                                return LootAlertsDialog(
                                  userModel: _firebaseUserModel,
                                );
                              },
                            );
                            setState(() {
                              // Refresh lootAlerts (check or uncheck box)
                            });
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 5, 8, 0),
                        child: CheckboxListTile(
                          checkColor: Colors.white,
                          activeColor: Colors.blueGrey,
                          value: _firebaseUserModel.racingNotification ?? false,
                          title: const Text("Racing"),
                          subtitle: const Text(
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
                          title: const Text("Messages"),
                          subtitle: const Text(
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
                          title: const Text("Events"),
                          subtitle: const Text(
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
                              const Padding(
                                padding: EdgeInsets.only(left: 10),
                                child: Text(
                                  "Filter out events",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.keyboard_arrow_right_outlined),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return EventsFilterDialog(
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
                        padding: const EdgeInsets.fromLTRB(8, 5, 8, 0),
                        child: CheckboxListTile(
                          checkColor: Colors.white,
                          activeColor: Colors.blueGrey,
                          value: _firebaseUserModel.refillsNotification ?? false,
                          title: const Text("Refills"),
                          subtitle: const Text(
                            "Get notified if you still have unused refills",
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
                              const Padding(
                                padding: EdgeInsets.only(left: 10),
                                child: Text(
                                  "Time",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                              DropdownButton<int>(
                                value: _firebaseUserModel?.refillsTime,
                                items: [
                                  DropdownMenuItem(
                                    value: 16,
                                    child: SizedBox(
                                      width: 80,
                                      child: Text(
                                        "16:00 TCT",
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 17,
                                    child: SizedBox(
                                      width: 80,
                                      child: Text(
                                        "17:00 TCT",
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 18,
                                    child: SizedBox(
                                      width: 80,
                                      child: Text(
                                        "18:00 TCT",
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 19,
                                    child: SizedBox(
                                      width: 80,
                                      child: Text(
                                        "19:00 TCT",
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 20,
                                    child: SizedBox(
                                      width: 80,
                                      child: Text(
                                        "20:00 TCT",
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 21,
                                    child: SizedBox(
                                      width: 80,
                                      child: Text(
                                        "21:00 TCT",
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 22,
                                    child: SizedBox(
                                      width: 80,
                                      child: Text(
                                        "22:00 TCT",
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 23,
                                    child: SizedBox(
                                      width: 80,
                                      child: Text(
                                        "23:00 TCT",
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (value) async {
                                  setState(() {
                                    _firebaseUserModel?.refillsTime = value;
                                  });
                                  firestore.setRefillTime(value);
                                },
                              ),
                            ],
                          ),
                        ),
                      if (_firebaseUserModel?.refillsNotification)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(25, 0, 20, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              const Padding(
                                padding: EdgeInsets.only(left: 10),
                                child: Text(
                                  "Choose refills",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.keyboard_arrow_right_outlined),
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
                              const Text("Stock market gain/loss"),
                              GestureDetector(
                                child: const Icon(Icons.keyboard_arrow_right_outlined),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) {
                                        return StockMarketAlertsPage(
                                          fbUser: _firebaseUserModel,
                                          calledFromMenu: false,
                                          stockMarketInMenuCallback: widget.stockMarketInMenuCallback,
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          subtitle: const Text(
                            "Configure price gain/loss alerts for any traded company",
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 5, 8, 0),
                        child: CheckboxListTile(
                          checkColor: Colors.white,
                          activeColor: Colors.blueGrey,
                          value: _firebaseUserModel.factionAssistMessage ?? false,
                          title: const Text("Faction assist messages"),
                          subtitle: const Text(
                            "Receive attack assist messages manually triggered by your faction mates",
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _firebaseUserModel?.factionAssistMessage = value;
                            });
                            firestore.toggleFactionAssistMessage(value);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 5, 8, 0),
                        child: CheckboxListTile(
                          checkColor: Colors.white,
                          activeColor: Colors.blueGrey,
                          value: _firebaseUserModel.retaliationNotification ?? false,
                          title: const Text("Retaliation"),
                          subtitle: const Text(
                            "Get notified whenever it is possible to initiate a retaliation attack. On tapping a "
                            "notification, a single target will open the browser; multiple targets will redirect you "
                            "to the Retaliation section",
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _firebaseUserModel?.retaliationNotification = value;
                            });
                            firestore.toggleRetaliationNotification(value);
                          },
                        ),
                      ),
                      const SizedBox(height: 60),
                    ],
                  ),
                );
              } else {
                return _connectError();
              }
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      //brightness: Brightness.dark, // For downgrade to Flutter 2.2.3
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      title: const Text('Alerts'),
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () {
          final ScaffoldState scaffoldState = context.findRootAncestorStateOfType();
          scaffoldState.openDrawer();
        },
      ),
      actions: <Widget>[
        IconButton(
          icon: const Icon(
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
          icon: const Icon(
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
        children: const <Widget>[
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
          Text(
            'If this problem reoccurs, please log out from Torn API (remove '
            'you API Key in the Settings section and insert it again). Sorry for '
            'the inconvenience!',
          ),
        ],
      ),
    );
  }

  Widget _alertsInfoDialog() {
    return AlertDialog(
      title: const Text(
        "Alerts",
        style: TextStyle(
          fontSize: 18,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          children: const [
            Padding(
              padding: EdgeInsets.all(8.0),
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
          child: const Text("Close"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        )
      ],
    );
  }

  Widget _troubleShootingDialog() {
    return AlertDialog(
      title: const Text(
        "Troubleshooting",
        style: TextStyle(
          fontSize: 18,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          children: const [
            Padding(
              padding: EdgeInsets.all(8.0),
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
          child: const Text("Reset"),
          onPressed: () async {
            Navigator.of(context).pop();

            try {
              final _userProv = context.read<UserDetailsProvider>();

              // We save the key because the API call will reset it
              final savedKey = _userProv.basic.userApiKey;

              final dynamic myProfile = await TornApiCaller().getProfileBasic();

              if (myProfile is OwnProfileBasic) {
                myProfile
                  ..userApiKey = savedKey
                  ..userApiKeyValid = true;

                FirebaseUserModel fb = await firestore.uploadUsersProfileDetail(myProfile, userTriggered: true);
                setState(() {
                  _firebaseUserModel = fb;
                });
                await firestore.uploadLastActiveTime(DateTime.now().millisecondsSinceEpoch);

                if (Platform.isAndroid) {
                  final alertsVibration = await Prefs().getVibrationPattern();
                  // Deletes current channels and create new ones
                  reconfigureNotificationChannels(mod: alertsVibration);
                  // Update channel preferences
                  firestore.setVibrationPattern(alertsVibration);
                }

                BotToast.showText(
                  text: "Reset successful",
                  textStyle: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  contentColor: Colors.green[800],
                  duration: const Duration(seconds: 5),
                  contentPadding: const EdgeInsets.all(10),
                );

                return;
              }
            } catch (e) {
              // Same message below
            }

            BotToast.showText(
              text: "There was an error updating the database, try again later!",
              textStyle: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
              contentColor: Colors.orange[800],
              duration: const Duration(seconds: 5),
              contentPadding: const EdgeInsets.all(10),
            );
          },
        ),
        TextButton(
          child: const Text("Close"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        )
      ],
    );
  }
}
