import 'package:flutter/material.dart';
import 'package:torn_pda/models/firebase_user_model.dart';
import 'package:torn_pda/utils/firestore.dart';

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
  }

  @override
  Widget build(BuildContext context) {
    return Banner(
      location: BannerLocation.bottomEnd,
      message: 'BETA',
      color: Colors.red.withOpacity(0.8),
      textStyle: TextStyle(
          fontWeight: FontWeight.w700, fontSize: 12.0, letterSpacing: 1.6),
      textDirection: TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Alerts'),
          leading: new IconButton(
            icon: new Icon(Icons.menu),
            onPressed: () {
              final ScaffoldState scaffoldState =
                  context.findRootAncestorStateOfType();
              scaffoldState.openDrawer();
            },
          ),
        ),
        body: FutureBuilder(
          future: _firestoreProfileReceived,
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.data is FirebaseUserModel) {
                _firebaseUserModel = snapshot.data;
                return Column(
                  children: [
                    SizedBox(height: 20),
                    CheckboxListTile(
                      checkColor: Colors.white,
                      activeColor: Colors.blueGrey,
                      value: _firebaseUserModel.travelNotification ?? false,
                      title: Text("Travel Arrival Notification"),
                      subtitle: Text(
                          "Get notified just before you arrive"),
                      onChanged: (value) {
                        setState(() {
                          _firebaseUserModel?.travelNotification = value;
                        });
                        firestore.subscribeToTravelNotification(value);
                      },
                    ),
                    CheckboxListTile(
                      checkColor: Colors.white,
                      activeColor: Colors.blueGrey,
                      value: _firebaseUserModel.energyNotification ?? false,
                      title: Text("Energy Full Notification"),
                      subtitle: Text("Get notified once you reach full energy"),
                      onChanged: (value) {
                        setState(() {
                          _firebaseUserModel?.energyNotification = value;
                        });
                        firestore.subscribeToEnergyNotification(value);
                      },
                    ),
                    Padding(
                      padding: EdgeInsets.all(15),
                      child: Text(
                        "Note: if you don't open the app for more than 7 days, "
                            "all notifications will be turned off automatically. "
                            "This is to prevent the over usage of resources. "
                            "Please make sure you return back to the app once a "
                            "week to get uninterrupted service.",
                        style: Theme.of(context)
                            .textTheme
                            .bodyText2
                            .copyWith(height: 1.3, fontStyle: FontStyle.italic),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(15),
                      child: Text(
                        "Note: this feature is under test. If you find an issue, "
                            "please be kind and report it (see 'About' section).",
                        style: Theme.of(context)
                            .textTheme
                            .bodyText2
                            .copyWith(height: 1.3, fontStyle: FontStyle.italic),
                      ),
                    )
                  ],
                );
              } else {
                return _connectError();
              }

            } else {
              return Center(child: CircularProgressIndicator());
            }
          }
        ),
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
          Text(
              'If this problem reoccurs, please log out from Torn API (remove '
              'you API Key in the Settings section and insert it again. Sorry for '
              'the inconvenience!'),
        ],
      ),
    );
  }
}
