import 'package:flutter/material.dart';
import 'package:torn_pda/models/firebase_user_model.dart';
import 'package:torn_pda/utils/firebase_firestore.dart';

class RefillsRequestedDialog extends StatefulWidget {
  final FirebaseUserModel userModel;

  RefillsRequestedDialog({@required this.userModel});

  @override
  _RefillsRequestedDialogState createState() => _RefillsRequestedDialogState();
}

class _RefillsRequestedDialogState extends State<RefillsRequestedDialog> {
  FirebaseUserModel _firebaseUserModel;

  @override
  void initState() {
    super.initState();
    _firebaseUserModel = widget.userModel;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Choose refills"),
      content: SingleChildScrollView(
        child: Column(
          children: [
            Text(
              "Choose which unused refills types you'd "
              "like to be alerted about a couple of hours before the "
              "end of day in Torn",
              style: TextStyle(
                fontSize: 14,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text("Energy"),
                  Switch(
                    value:
                        _firebaseUserModel.refillsRequested.contains('energy'),
                    onChanged: (value) {
                      if (value) {
                        setState(() {
                          firestore.addToRefillsRequested('energy');
                        });
                      } else {
                        setState(() {
                          firestore.removeFromRefillsRequested('energy');
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text("Nerve"),
                  Switch(
                    value:
                        _firebaseUserModel.refillsRequested.contains('nerve'),
                    onChanged: (value) {
                      if (value) {
                        setState(() {
                          firestore.addToRefillsRequested('nerve');
                        });
                      } else {
                        setState(() {
                          firestore.removeFromRefillsRequested('nerve');
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text("Casino tokens"),
                  Switch(
                    value:
                        _firebaseUserModel.refillsRequested.contains('tokens'),
                    onChanged: (value) {
                      if (value) {
                        setState(() {
                          firestore.addToRefillsRequested('tokens');
                        });
                      } else {
                        setState(() {
                          firestore.removeFromRefillsRequested('tokens');
                        });
                      }
                    },
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
