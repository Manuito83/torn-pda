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
                CheckboxListTile(
                  value: firebaseUserModel.travelNotification ?? false,
                  title: Text("Travel Arrival Notification"),
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
              ],
            ),
    );
  }
}
