import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class TravelNotificationTextDialog extends StatefulWidget {
  final String title;
  final String body;

  TravelNotificationTextDialog({
    @required this.title,
    @required this.body,
  });

  @override
  _TravelNotificationTextDialogState createState() =>
      _TravelNotificationTextDialogState();
}

class _TravelNotificationTextDialogState
    extends State<TravelNotificationTextDialog> {
  ThemeProvider _themeProvider;

  final _notificationTitleController = new TextEditingController();
  final _notificationBodyController = new TextEditingController();

  var _notificationFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _notificationTitleController.text = widget.title;
    _notificationBodyController.text = widget.body;
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return SingleChildScrollView(
      child: Stack(
        children: <Widget>[
          SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.only(
                top: 45,
                bottom: 16,
                left: 16,
                right: 16,
              ),
              margin: EdgeInsets.only(top: 30),
              decoration: new BoxDecoration(
                color: _themeProvider.background,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10.0,
                    offset: const Offset(0.0, 10.0),
                  ),
                ],
              ),
              child: Form(
                key: _notificationFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text('Notification title'),
                    ),
                    TextFormField(
                      style: TextStyle(fontSize: 14),
                      controller: _notificationTitleController,
                      maxLength: 15,
                      minLines: 1,
                      maxLines: 1,
                      decoration: InputDecoration(
                        counterText: "",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value.isEmpty) {
                          return "Cannot be empty!";
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.0),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text('Notification description'),
                    ),
                    TextFormField(
                      style: TextStyle(fontSize: 14),
                      controller: _notificationBodyController,
                      maxLength: 50,
                      minLines: 1,
                      maxLines: 2,
                      decoration: InputDecoration(
                        counterText: "",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value.isEmpty) {
                          return "Cannot be empty!";
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        TextButton(
                          child: Text("Change"),
                          onPressed: () async {
                            if (_notificationFormKey.currentState.validate()) {
                              // Get rid of dialog first, so that it can't
                              // be pressed twice
                              Navigator.of(context).pop();
                              // Copy controller's text to local variable
                              // early and delete the global, so that text
                              // does not appear again in case of failure
                              Prefs()
                                  .setTravelNotificationTitle(
                                      _notificationTitleController.text);
                              Prefs()
                                  .setTravelNotificationBody(
                                      _notificationBodyController.text);

                              BotToast.showText(
                                text: "Notification details changed!",
                                textStyle: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                                contentColor: Colors.green,
                                duration: Duration(seconds: 3),
                                contentPadding: EdgeInsets.all(10),
                              );
                            }
                          },
                        ),
                        SizedBox(width: 10),
                        TextButton(
                          child: Text("Cancel"),
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
              backgroundColor: _themeProvider.background,
              child: CircleAvatar(
                backgroundColor: _themeProvider.mainText,
                radius: 22,
                child: SizedBox(
                  height: 28,
                  width: 28,
                  child: Icon(
                    Icons.textsms,
                    color: _themeProvider.background,
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
