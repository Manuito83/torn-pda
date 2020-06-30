import 'package:flutter/material.dart';
import 'package:torn_pda/models/firebase_user_model.dart';
import 'package:torn_pda/utils/firestore.dart';

class AlertsSettings extends StatefulWidget {
  @override
  _AlertsSettingsState createState() => _AlertsSettingsState();
}

class _AlertsSettingsState extends State<AlertsSettings> {
  FirebaseUserModel firebaseUserModel;
  @override
  void initState() {
    super.initState();
    firestore.getUserProfile().then((profile) {
      setState(() {
        firebaseUserModel = profile;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      body: firebaseUserModel == null
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SizedBox(height: 20),
                CheckboxListTile(
                  value: firebaseUserModel.travelNotification ?? false,
                  title: Text("Travel Notification"),
                  subtitle: Text(
                      "Get notified 60 seconds before you reach your destination"),
                  onChanged: (value) {
                    setState(() {
                      firebaseUserModel?.travelNotification = value;
                    });
                    firestore.subscribeToTravelNotificaion(value);
                  },
                ),
                CheckboxListTile(
                  value: firebaseUserModel.energyNotification ?? false,
                  title: Text("Energy Full Notification"),
                  subtitle: Text("Get notified once you reach full energy"),
                  onChanged: (value) {
                    setState(() {
                      firebaseUserModel?.energyNotification = value;
                    });
                    firestore.subscribeToEnergyNotificaion(value);
                  },
                ),
                Padding(
                  padding: EdgeInsets.all(15),
                  child: Text(
                    "Note: If you dont open the app for more than 7 days, all notifications will be turned off automatically. This is to prevent the over usage of our resources. Please make sure you return back to the app once a week to get uninterrupted notification service.",
                    style: Theme.of(context)
                        .textTheme
                        .bodyText2
                        .copyWith(height: 1.8, fontStyle: FontStyle.italic),
                  ),
                )
              ],
            ),
    );
  }
}
