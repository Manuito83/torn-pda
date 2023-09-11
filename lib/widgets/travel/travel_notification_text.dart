// Flutter imports:
// Package imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Project imports:
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class TravelNotificationTextDialog extends StatefulWidget {
  final String title;
  final String body;

  const TravelNotificationTextDialog({
    required this.title,
    required this.body,
  });

  @override
  TravelNotificationTextDialogState createState() => TravelNotificationTextDialogState();
}

class TravelNotificationTextDialogState extends State<TravelNotificationTextDialog> {
  late ThemeProvider _themeProvider;

  final _notificationTitleController = TextEditingController();
  final _notificationBodyController = TextEditingController();

  final _notificationFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _notificationTitleController.text = widget.title;
    _notificationBodyController.text = widget.body;
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context);
    return SingleChildScrollView(
      child: Stack(
        children: <Widget>[
          SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.only(
                top: 45,
                bottom: 16,
                left: 16,
                right: 16,
              ),
              margin: const EdgeInsets.only(top: 30),
              decoration: BoxDecoration(
                color: _themeProvider.secondBackground,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10.0,
                    offset: Offset(0.0, 10.0),
                  ),
                ],
              ),
              child: Form(
                key: _notificationFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.only(bottom: 3),
                      child: Text('Notification title'),
                    ),
                    TextFormField(
                      style: const TextStyle(fontSize: 14),
                      controller: _notificationTitleController,
                      maxLength: 15,
                      minLines: 1,
                      decoration: const InputDecoration(
                        counterText: "",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return "Cannot be empty!";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 3),
                      child: Text('Notification description'),
                    ),
                    TextFormField(
                      style: const TextStyle(fontSize: 14),
                      controller: _notificationBodyController,
                      maxLength: 50,
                      minLines: 1,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        counterText: "",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return "Cannot be empty!";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        TextButton(
                          child: const Text("Change"),
                          onPressed: () async {
                            if (_notificationFormKey.currentState!.validate()) {
                              // Get rid of dialog first, so that it can't
                              // be pressed twice
                              Navigator.of(context).pop();
                              // Copy controller's text to local variable
                              // early and delete the global, so that text
                              // does not appear again in case of failure
                              Prefs().setTravelNotificationTitle(_notificationTitleController.text);
                              Prefs().setTravelNotificationBody(_notificationBodyController.text);

                              BotToast.showText(
                                text: "Notification details changed!",
                                textStyle: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                                contentColor: Colors.green,
                                duration: const Duration(seconds: 3),
                                contentPadding: const EdgeInsets.all(10),
                              );
                            }
                          },
                        ),
                        const SizedBox(width: 10),
                        TextButton(
                          child: const Text("Cancel"),
                          onPressed: () {
                            Navigator.of(context).pop();
                            _notificationTitleController.text = '';
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            child: CircleAvatar(
              radius: 26,
              backgroundColor: _themeProvider.secondBackground,
              child: CircleAvatar(
                backgroundColor: _themeProvider.mainText,
                radius: 22,
                child: SizedBox(
                  height: 28,
                  width: 28,
                  child: Icon(
                    Icons.textsms,
                    color: _themeProvider.secondBackground,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
