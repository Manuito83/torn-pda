// Flutter imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:torn_pda/models/profile/own_profile_basic.dart';
import 'package:torn_pda/utils/firebase_functions.dart';

class BackupDeleteDialog extends StatefulWidget {
  final OwnProfileBasic userProfile;
  const BackupDeleteDialog({super.key, required this.userProfile});

  @override
  BackupDeleteDialogState createState() => BackupDeleteDialogState();
}

class BackupDeleteDialogState extends State<BackupDeleteDialog> {
  double hPad = 15;
  double vPad = 20;
  double frame = 10;

  bool _deleteInProgress = false;
  late Future _serverPrefsFetched;
  String _serverError = "";
  Map<String, dynamic> _serverPrefs = {};

  @override
  void initState() {
    super.initState();
    _serverPrefsFetched = _getOriginalServerPrefs();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline),
                  SizedBox(width: 10),
                  Text(
                    "CLEAR BACKUP",
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
            FutureBuilder(
              future: _serverPrefsFetched,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_serverError.isNotEmpty)
                          Column(
                            children: [
                              Text("SERVER ERROR", style: TextStyle(color: Colors.red)),
                              Text(_serverError, style: TextStyle(color: Colors.red)),
                            ],
                          )
                        else if (_serverPrefs.isNotEmpty)
                          Text("This will delete your online backup, are you sure?")
                        else
                          Text("You don't have a backup to delete!"),
                      ],
                    ),
                  );
                }

                return Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        const Text("Fetching server info..."),
                        const SizedBox(height: 25),
                        const CircularProgressIndicator(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_serverPrefs.isNotEmpty)
                  TextButton(
                    child: _deleteInProgress
                        ? Container(
                            width: 20,
                            height: 20,
                            child: const CircularProgressIndicator(),
                          )
                        : const Text("Delete", style: TextStyle(color: Colors.red)),
                    onPressed: () async {
                      setState(() {
                        _deleteInProgress = true;
                      });

                      String message = "";
                      Color color = Colors.green;

                      try {
                        final result = await firebaseFunctions.deleteUserPrefs(
                          userId: widget.userProfile.playerId ?? 0,
                          apiKey: widget.userProfile.userApiKey.toString(),
                        );

                        message = result["message"];
                        color = result["success"] ? Colors.green : Colors.red;
                      } catch (e) {
                        message = "Error: $e";
                        color = Colors.red;
                      }

                      BotToast.showText(
                        text: message,
                        contentColor: color,
                        textStyle: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                        duration: const Duration(seconds: 4),
                        contentPadding: const EdgeInsets.all(10),
                      );

                      setState(() {
                        _deleteInProgress = false;
                      });

                      Navigator.of(context).pop();
                    },
                  ),
                TextButton(
                  child: const Text("Close"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                SizedBox(width: 10),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future _getOriginalServerPrefs() async {
    final result = await firebaseFunctions
        .getUserPrefs(userId: widget.userProfile.playerId ?? 0, apiKey: widget.userProfile.userApiKey.toString())
        .catchError((value) {
      return <String, dynamic>{"success": false, "message": "Could not connect to server"};
    });

    if (!result["success"]) {
      setState(() {
        _serverError = result["message"];
      });
      return;
    }

    setState(() {
      _serverPrefs = result["prefs"] ?? {};
    });
  }
}
