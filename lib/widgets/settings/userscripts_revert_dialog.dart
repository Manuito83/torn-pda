// Flutter imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

// Project imports:
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/userscripts_provider.dart';

class UserScriptsRevertDialog extends StatefulWidget {
  @override
  UserScriptsRevertDialogState createState() => UserScriptsRevertDialogState();
}

class UserScriptsRevertDialogState extends State<UserScriptsRevertDialog> {
  late ThemeProvider _themeProvider;
  late UserScriptsProvider _userScriptsProvider;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _userScriptsProvider = Provider.of<UserScriptsProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context);

    // Get number missing example scripts

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0.0,
      backgroundColor: Colors.transparent,
      content: SingleChildScrollView(
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
                margin: const EdgeInsets.only(top: 15),
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
                child: Column(
                  mainAxisSize: MainAxisSize.min, // To make the card compact
                  children: <Widget>[
                    const SizedBox(height: 10),
                    Flexible(
                      child: Text(
                        "This will re-add any of the example userscripts that you may have deleted!",
                        style: TextStyle(fontSize: 12, color: _themeProvider.mainText),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        TextButton(
                          child: const Text("Do it!"),
                          onPressed: _loading
                              ? null
                              : () {
                                  setState(() {
                                    _loading = true;
                                  });
                                  _userScriptsProvider
                                      .addDefaultScripts()
                                      .then((r) => BotToast.showText(
                                            text: "${r.added} script${r.added == 1 ? "" : "s"} added.\n"
                                                "${r.failed} script${r.failed == 1 ? "" : "s"} failed.\n"
                                                "${r.removed} script${r.removed == 1 ? "" : "s"} removed.",
                                            textStyle: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ))
                                      .then(Navigator.of(context).pop)
                                      .then((_) => setState(() {
                                            _loading = false;
                                          }));
                                },
                        ),
                        TextButton(
                          child: const Text("Better not!"),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    )
                  ],
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
                  backgroundColor: _themeProvider.secondBackground,
                  radius: 22,
                  child: const SizedBox(
                    height: 34,
                    width: 34,
                    child: Icon(MdiIcons.backupRestore),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
