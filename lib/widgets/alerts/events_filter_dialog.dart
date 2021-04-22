import 'package:flutter/material.dart';
import 'package:torn_pda/models/firebase_user_model.dart';
import 'package:torn_pda/utils/firebase_firestore.dart';

class EventsFilterDialog extends StatefulWidget {
  final FirebaseUserModel userModel;

  EventsFilterDialog({@required this.userModel});

  @override
  _EventsFilterDialogState createState() => _EventsFilterDialogState();
}

class _EventsFilterDialogState extends State<EventsFilterDialog> {
  FirebaseUserModel _firebaseUserModel;

  @override
  void initState() {
    super.initState();
    _firebaseUserModel = widget.userModel;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Filter out events"),
      content: SingleChildScrollView(
        child: Column(
          children: [
            Text(
              "Choose which type of events you would like to "
              "filter OUT (you won't receive notifications from these).",
              style: TextStyle(
                fontSize: 14,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text("Organized crimes"),
                  Switch(
                    value: _firebaseUserModel.eventsFilter.contains('crimes'),
                    onChanged: (value) {
                      if (value) {
                        setState(() {
                          firestore.addToEventsFilter('crimes');
                        });
                      } else {
                        setState(() {
                          firestore.removeFromEventsFilter('crimes');
                        });
                      }
                    },
                    activeTrackColor: Colors.redAccent[100],
                    activeColor: Colors.red,
                    inactiveThumbColor: Colors.green[100],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text("Company trains"),
                  Switch(
                    value: _firebaseUserModel.eventsFilter.contains('trains'),
                    onChanged: (value) {
                      if (value) {
                        setState(() {
                          firestore.addToEventsFilter('trains');
                        });
                      } else {
                        setState(() {
                          firestore.removeFromEventsFilter('trains');
                        });
                      }
                    },
                    activeTrackColor: Colors.redAccent[100],
                    activeColor: Colors.red,
                    inactiveThumbColor: Colors.green[100],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text("Racing"),
                  Switch(
                    value: _firebaseUserModel.eventsFilter.contains('racing'),
                    onChanged: (value) {
                      if (value) {
                        setState(() {
                          firestore.addToEventsFilter('racing');
                        });
                      } else {
                        setState(() {
                          firestore.removeFromEventsFilter('racing');
                        });
                      }
                    },
                    activeTrackColor: Colors.redAccent[100],
                    activeColor: Colors.red,
                    inactiveThumbColor: Colors.green[100],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text("Bazaar"),
                  Switch(
                    value: _firebaseUserModel.eventsFilter.contains('bazaar'),
                    onChanged: (value) {
                      if (value) {
                        setState(() {
                          firestore.addToEventsFilter('bazaar');
                        });
                      } else {
                        setState(() {
                          firestore.removeFromEventsFilter('bazaar');
                        });
                      }
                    },
                    activeTrackColor: Colors.redAccent[100],
                    activeColor: Colors.red,
                    inactiveThumbColor: Colors.green[100],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text("Attacks"),
                  Switch(
                    value: _firebaseUserModel.eventsFilter.contains('attacks'),
                    onChanged: (value) {
                      if (value) {
                        setState(() {
                          firestore.addToEventsFilter('attacks');
                        });
                      } else {
                        setState(() {
                          firestore.removeFromEventsFilter('attacks');
                        });
                      }
                    },
                    activeTrackColor: Colors.redAccent[100],
                    activeColor: Colors.red,
                    inactiveThumbColor: Colors.green[100],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text("Revives"),
                  Switch(
                    value: _firebaseUserModel.eventsFilter.contains('revives'),
                    onChanged: (value) {
                      if (value) {
                        setState(() {
                          firestore.addToEventsFilter('revives');
                        });
                      } else {
                        setState(() {
                          firestore.removeFromEventsFilter('revives');
                        });
                      }
                    },
                    activeTrackColor: Colors.redAccent[100],
                    activeColor: Colors.red,
                    inactiveThumbColor: Colors.green[100],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 15),
          child: TextButton(
            child: Text("Close"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        )
      ],
    );
  }
}
