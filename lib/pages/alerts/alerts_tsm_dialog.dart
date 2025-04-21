import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/firebase_user_model.dart';
import 'package:torn_pda/models/profile/own_profile_basic.dart';
import 'package:torn_pda/providers/api/api_v1_calls.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/utils/firebase_firestore.dart';
import 'package:torn_pda/utils/firebase_functions.dart';
import 'package:torn_pda/utils/notification.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class AlertsTsmDialog extends StatefulWidget {
  final FirebaseUserModel? firebaseUserModel;
  final Function reassignFirebaseUserModelCallback;

  AlertsTsmDialog({required this.firebaseUserModel, required this.reassignFirebaseUserModelCallback, super.key});

  @override
  State<AlertsTsmDialog> createState() => _AlertsTsmDialogState();
}

class _AlertsTsmDialogState extends State<AlertsTsmDialog> {
  bool _isTestingNotification = false;
  bool _isResetting = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "If you are having issues receiving alerts, it could be due to several causes. This dialog will guide "
              "you to try to resolve the problem.",
              style: TextStyle(fontSize: 14),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "To start with, please tap the following button to send yourself a test notification:",
              style: TextStyle(fontSize: 14),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              child: _isTestingNotification
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    )
                  : const Text("Test Notification"),
              onPressed: _isTestingNotification
                  ? null
                  : () async {
                      bool success = false;

                      setState(() {
                        _isTestingNotification = true;
                      });

                      success = await firebaseFunctions.sendAlertsTroubleshootingTest();

                      if (success) {
                        BotToast.showText(
                          text: "Request sent, please wait for a few seconds...",
                          textStyle: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                          contentColor: Colors.green[800]!,
                          duration: const Duration(seconds: 5),
                          contentPadding: const EdgeInsets.all(10),
                        );
                      }

                      if (!success) {
                        BotToast.showText(
                          text: "There was a problem sending the request, no communicationn with the server!",
                          textStyle: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                          contentColor: Colors.orange[800]!,
                          duration: const Duration(seconds: 5),
                          contentPadding: const EdgeInsets.all(10),
                        );
                      }

                      setState(() {
                        _isTestingNotification = false;
                      });
                    },
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Did it reach you?",
              style: TextStyle(fontSize: 14),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "If it did, it means the server can reach your device with no issues. However, if you are still not getting "
              "other app notifications, please verify that they are correctly selected in the Alerts section and "
              "that your device main settings are not blocking or muting Torn PDA. Otherwise, keep reading.",
              style: TextStyle(fontSize: 14),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "If the test failed or other notifications are not gettin in, there might be a communication issue "
              "going on with the server. Please consider the following steps:",
              style: TextStyle(fontSize: 14),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Text(
              "1) In case this could be due a misconfiguration at server level, please tap the Soft Reset button "
              "below. Torn PDA will try to reconfigure your user. If you get a success message, please retry "
              "the test notification. Otherwise, keep reading.",
              style: TextStyle(fontSize: 14),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              child: _isResetting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    )
                  : const Text("Soft Reset"),
              onPressed: _isResetting
                  ? null
                  : () async {
                      setState(() {
                        _isResetting = true;
                      });

                      try {
                        final userProv = context.read<UserDetailsProvider>();

                        // We save the key because the API call will reset it
                        final savedKey = userProv.basic!.userApiKey;

                        final dynamic myProfile = await ApiCallsV1.getOwnProfileBasic();

                        if (myProfile is OwnProfileBasic) {
                          myProfile
                            ..userApiKey = savedKey
                            ..userApiKeyValid = true;

                          FirebaseUserModel? fb =
                              await FirestoreHelper().uploadUsersProfileDetail(myProfile, userTriggered: true);
                          widget.reassignFirebaseUserModelCallback(fb);
                          await FirestoreHelper().uploadLastActiveTime(DateTime.now().millisecondsSinceEpoch);

                          if (Platform.isAndroid) {
                            final alertsVibration = await Prefs().getVibrationPattern();
                            // Deletes current channels and create new ones
                            reconfigureNotificationChannels(mod: alertsVibration);
                            // Update channel preferences
                            FirestoreHelper().setVibrationPattern(alertsVibration);
                          }

                          BotToast.showText(
                            text: "Reset successful",
                            textStyle: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                            contentColor: Colors.green[800]!,
                            duration: const Duration(seconds: 5),
                            contentPadding: const EdgeInsets.all(10),
                          );

                          setState(() {
                            _isResetting = false;
                          });
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
                        contentColor: Colors.orange[800]!,
                        duration: const Duration(seconds: 5),
                        contentPadding: const EdgeInsets.all(10),
                      );

                      setState(() {
                        _isResetting = false;
                      });
                    },
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Text(
              "2) You can manually force a user reconfiguration in the server by going to Settings in Torn PDA. ",
              style: TextStyle(fontSize: 14),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Text(
              "Start by reloading your API Key (expand the API section at the top and tap 'Reload'). "
              "If that does not solve the problem (check once again the Test Notification here), "
              "remove your API Key (tap the bin icon) and insert it once again.",
              style: TextStyle(fontSize: 14),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Text(
              "3) Lastly, make sure your device or network configuration (router) is not blocking the Google Cloud or Google "
              "Services, since the Alerts server is hosted there. Some users might use a firewall to block Google "
              "or even download the app from a alternative app store; if that's your case, be aware that you might "
              "be unable to receive Alerts.",
              style: TextStyle(fontSize: 14),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Text(
              "If all of this fails, there might be a bigger issue happening with your local Torn PDA installation. "
              "Please consider uninstalling the app and installing it again. Before you do so, make sure you backup "
              "whatever option you like in the cloud (you can do this in Settings).",
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
