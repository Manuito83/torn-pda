import 'package:flutter/material.dart';
import 'package:torn_pda/models/firebase_user_model.dart';
import 'package:torn_pda/utils/firestore.dart';

import '../main.dart';

class AlertsSettings extends StatefulWidget {
  @override
  _AlertsSettingsState createState() => _AlertsSettingsState();
}

class _AlertsSettingsState extends State<AlertsSettings> {
  FirebaseUserModel _firebaseUserModel;

  Future _firestoreProfileReceived;

  @override
  void initState() {
    super.initState();
    _firestoreProfileReceived = firestore.getUserProfile();
    analytics.logEvent(name: 'section_changed', parameters: {'section': 'alerts'});
  }

  @override
  Widget build(BuildContext context) {
    return Banner(
      location: BannerLocation.bottomEnd,
      message: 'BETA',
      color: Colors.red.withOpacity(0.8),
      textStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.0, letterSpacing: 1.6),
      textDirection: TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
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
        ),
        body: FutureBuilder(
            future: _firestoreProfileReceived,
            builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.data is FirebaseUserModel) {
                  _firebaseUserModel = snapshot.data;
                  return Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          "Alerts are automatic notifications that you only "
                          "need to activate once. However, you will be notified "
                          "earlier than with manual notifications.",
                          style: Theme.of(context).textTheme.bodyText2.copyWith(
                                height: 1.3,
                              ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: CheckboxListTile(
                          checkColor: Colors.white,
                          activeColor: Colors.blueGrey,
                          value: _firebaseUserModel.travelNotification ?? false,
                          title: Text("Travel"),
                          subtitle: Text("Get notified just before you arrive"),
                          onChanged: (value) {
                            setState(() {
                              _firebaseUserModel?.travelNotification = value;
                            });
                            firestore.subscribeToTravelNotification(value);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: CheckboxListTile(
                          checkColor: Colors.white,
                          activeColor: Colors.blueGrey,
                          value: _firebaseUserModel.energyNotification ?? false,
                          title: Text("Energy full"),
                          subtitle: Text("Get notified once you reach full energy"),
                          onChanged: (value) {
                            setState(() {
                              _firebaseUserModel?.energyNotification = value;
                            });
                            firestore.subscribeToEnergyNotification(value);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: CheckboxListTile(
                          checkColor: Colors.white,
                          activeColor: Colors.blueGrey,
                          value: _firebaseUserModel.hospitalNotification ?? false,
                          title: Text("Hospital admission and release"),
                          subtitle: Text("If you are offline, you'll be notified if you are "
                              "hospitalised, revived or out of hospital"),
                          onChanged: (value) {
                            setState(() {
                              _firebaseUserModel?.hospitalNotification = value;
                            });
                            firestore.subscribeToHospitalNotification(value);
                          },
                        ),
                      ),
                    ],
                  );
                } else {
                  return _connectError();
                }
              } else {
                return Center(child: CircularProgressIndicator());
              }
            }),
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
              'you API Key in the Settings section and insert it again. Sorry for '
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
                "This feature is under test. If you find any issue, "
                "please report it to us (see 'About' section).",
                style: TextStyle(
                  fontSize: 15,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Note: if you don't use Torn PDA for more than 5 days, "
                "all notifications will be turned off automatically. "
                "This is to prevent the over usage of resources. "
                "Please make sure you return back to the app once a "
                "week to get uninterrupted service.",
                style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
      actions: [
        FlatButton(
          child: Text("Close"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        )
      ],
    );
  }
}
