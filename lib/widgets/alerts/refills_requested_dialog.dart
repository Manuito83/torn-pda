// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:torn_pda/models/firebase_user_model.dart';
import 'package:torn_pda/utils/firebase_firestore.dart';

class RefillsRequestedDialog extends StatefulWidget {
  final FirebaseUserModel? userModel;

  const RefillsRequestedDialog({required this.userModel});

  @override
  RefillsRequestedDialogState createState() => RefillsRequestedDialogState();
}

class RefillsRequestedDialogState extends State<RefillsRequestedDialog> {
  FirebaseUserModel? _firebaseUserModel;

  @override
  void initState() {
    super.initState();
    _firebaseUserModel = widget.userModel;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Choose refills"),
      content: SingleChildScrollView(
        child: Column(
          children: [
            const Text(
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
                  const Text("Energy"),
                  Switch(
                    value: _firebaseUserModel!.refillsRequested.contains('energy'),
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
                  const Text("Nerve"),
                  Switch(
                    value: _firebaseUserModel!.refillsRequested.contains('nerve'),
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
                  const Text("Casino tokens"),
                  Switch(
                    value: _firebaseUserModel!.refillsRequested.contains('token'),
                    onChanged: (value) {
                      if (value) {
                        setState(() {
                          firestore.addToRefillsRequested('token');
                        });
                      } else {
                        setState(() {
                          firestore.removeFromRefillsRequested('token');
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
