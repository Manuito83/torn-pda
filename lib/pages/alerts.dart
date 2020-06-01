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
      body: Column(
        children: [
          CheckboxListTile(
            value: firebaseUserModel.energyFullReminder ?? false,
            title: Text("Energy Full Notification"),
            onChanged: (value) {
              setState(() {
                firebaseUserModel?.energyFullReminder = value;
              });
              firestore.subscribeToEnergyNotificaion(value);
            },
          ),
        ],
      ),
    );
  }
}
