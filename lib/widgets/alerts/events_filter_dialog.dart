// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:torn_pda/models/firebase_user_model.dart';
import 'package:torn_pda/utils/firebase_firestore.dart';

class EventsFilterDialog extends StatefulWidget {
  final FirebaseUserModel? userModel;

  const EventsFilterDialog({required this.userModel});

  @override
  EventsFilterDialogState createState() => EventsFilterDialogState();
}

class EventsFilterDialogState extends State<EventsFilterDialog> {
  FirebaseUserModel? _firebaseUserModel;

  @override
  void initState() {
    super.initState();
    _firebaseUserModel = widget.userModel;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Filter out events"),
      content: SingleChildScrollView(
        child: Column(
          children: [
            const Text(
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
                  const Text("Organized crimes"),
                  Switch(
                    value: _firebaseUserModel!.eventsFilter.contains('crimes'),
                    onChanged: (value) {
                      if (value) {
                        setState(() {
                          FirestoreHelper().addToEventsFilter('crimes');
                        });
                      } else {
                        setState(() {
                          FirestoreHelper().removeFromEventsFilter('crimes');
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
                  const Text("Company trains"),
                  Switch(
                    value: _firebaseUserModel!.eventsFilter.contains('trains'),
                    onChanged: (value) {
                      if (value) {
                        setState(() {
                          FirestoreHelper().addToEventsFilter('trains');
                        });
                      } else {
                        setState(() {
                          FirestoreHelper().removeFromEventsFilter('trains');
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
                  const Text("Racing"),
                  Switch(
                    value: _firebaseUserModel!.eventsFilter.contains('racing'),
                    onChanged: (value) {
                      if (value) {
                        setState(() {
                          FirestoreHelper().addToEventsFilter('racing');
                        });
                      } else {
                        setState(() {
                          FirestoreHelper().removeFromEventsFilter('racing');
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
                  const Text("Bazaar"),
                  Switch(
                    value: _firebaseUserModel!.eventsFilter.contains('bazaar'),
                    onChanged: (value) {
                      if (value) {
                        setState(() {
                          FirestoreHelper().addToEventsFilter('bazaar');
                        });
                      } else {
                        setState(() {
                          FirestoreHelper().removeFromEventsFilter('bazaar');
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
                  const Text("Attacks"),
                  Switch(
                    value: _firebaseUserModel!.eventsFilter.contains('attacks'),
                    onChanged: (value) {
                      if (value) {
                        setState(() {
                          FirestoreHelper().addToEventsFilter('attacks');
                        });
                      } else {
                        setState(() {
                          FirestoreHelper().removeFromEventsFilter('attacks');
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
                  const Text("Revives"),
                  Switch(
                    value: _firebaseUserModel!.eventsFilter.contains('revives'),
                    onChanged: (value) {
                      if (value) {
                        setState(() {
                          FirestoreHelper().addToEventsFilter('revives');
                        });
                      } else {
                        setState(() {
                          FirestoreHelper().removeFromEventsFilter('revives');
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
                  const Text("Trades"),
                  Switch(
                    value: _firebaseUserModel!.eventsFilter.contains('trades'),
                    onChanged: (value) {
                      if (value) {
                        setState(() {
                          FirestoreHelper().addToEventsFilter('trades');
                        });
                      } else {
                        setState(() {
                          FirestoreHelper().removeFromEventsFilter('trades');
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
                  const Text("Market sales"),
                  Switch(
                    value: _firebaseUserModel!.eventsFilter.contains('market_sales'),
                    onChanged: (value) {
                      if (value) {
                        setState(() {
                          FirestoreHelper().addToEventsFilter('market_sales');
                        });
                      } else {
                        setState(() {
                          FirestoreHelper().removeFromEventsFilter('market_sales');
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
                  const Text("Bounty claims"),
                  Switch(
                    value: _firebaseUserModel!.eventsFilter.contains('bounty_claims'),
                    onChanged: (value) {
                      if (value) {
                        setState(() {
                          FirestoreHelper().addToEventsFilter('bounty_claims');
                        });
                      } else {
                        setState(() {
                          FirestoreHelper().removeFromEventsFilter('bounty_claims');
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
                  const Text("Player referrals"),
                  Switch(
                    value: _firebaseUserModel!.eventsFilter.contains('referrals'),
                    onChanged: (value) {
                      if (value) {
                        setState(() {
                          FirestoreHelper().addToEventsFilter('referrals');
                        });
                      } else {
                        setState(() {
                          FirestoreHelper().removeFromEventsFilter('referrals');
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
                  const Text("Faction applications"),
                  Switch(
                    value: _firebaseUserModel!.eventsFilter.contains('faction_applications'),
                    onChanged: (value) {
                      if (value) {
                        setState(() {
                          FirestoreHelper().addToEventsFilter('faction_applications');
                        });
                      } else {
                        setState(() {
                          FirestoreHelper().removeFromEventsFilter('faction_applications');
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
                  const Text("Property rental"),
                  Switch(
                    value: _firebaseUserModel!.eventsFilter.contains('rental'),
                    onChanged: (value) {
                      if (value) {
                        setState(() {
                          FirestoreHelper().addToEventsFilter('rental');
                        });
                      } else {
                        setState(() {
                          FirestoreHelper().removeFromEventsFilter('rental');
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
            child: const Text("Close"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        )
      ],
    );
  }
}
