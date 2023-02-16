import 'package:bot_toast/bot_toast.dart';
import 'package:easy_rich_text/easy_rich_text.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:torn_pda/models/profile/own_profile_model.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/api_caller.dart';
import 'package:torn_pda/utils/external/uhc_revive.dart';
import 'package:url_launcher/url_launcher.dart';

class UhcReviveButton extends StatefulWidget {
  final ThemeProvider themeProvider;
  final OwnProfileExtended user;
  final SettingsProvider settingsProvider;
  final WebViewProvider webViewProvider;

  const UhcReviveButton({
    @required this.themeProvider,
    @required this.settingsProvider,
    @required this.webViewProvider,
    this.user,
    Key key,
  }) : super(key: key);

  @override
  _UhcReviveButtonState createState() => _UhcReviveButtonState();
}

class _UhcReviveButtonState extends State<UhcReviveButton> {
  OwnProfileExtended _user;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _user = widget.user;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _openUhcReviveDialog(context);
      },
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 13),
            child: Image.asset('images/icons/uhc_revive.png', width: 24),
          ),
          SizedBox(width: 10),
          Flexible(child: Text("Request a revive (UHC)")),
        ],
      ),
    );
  }

  Future<void> _openUhcReviveDialog(BuildContext _) {
    return showDialog<void>(
      context: _,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
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
                    padding: EdgeInsets.only(
                      top: 45,
                      bottom: 16,
                      left: 16,
                      right: 16,
                    ),
                    margin: EdgeInsets.only(top: 15),
                    decoration: new BoxDecoration(
                      color: widget.themeProvider.secondBackground,
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // To make the card compact
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  "REQUEST A REVIVE FROM UHC",
                                  style: TextStyle(fontSize: 11, color: widget.themeProvider.mainText),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: EasyRichText(
                            "Universal Health Care (UHC for short) is a revive alliance consisting "
                            "of several factions. You can find more information in the forums or "
                            "in the UHC Discord server.",
                            defaultStyle: TextStyle(fontSize: 13, color: widget.themeProvider.mainText),
                            patternList: [
                              EasyRichTextPattern(
                                targetString: 'forums',
                                style: TextStyle(color: Colors.blue),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () async {
                                    _launchBrowser(
                                      url: 'https://www.torn.com/forums.php#/p=threads&f=67&t=16192913&b=0&a=0',
                                      dialogRequested: true,
                                      context: _,
                                    );
                                  },
                              ),
                              EasyRichTextPattern(
                                targetString: 'UHC Discord',
                                style: TextStyle(color: Colors.blue),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () async {
                                    var url = 'https://discord.gg/JJprTpb';
                                    if (await canLaunch(url)) {
                                      await launch(url, forceSafariVC: false);
                                    }
                                  },
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 10),
                        Flexible(
                          child: Text(
                            "Each revive must be paid directly to the reviver and costs "
                            "\$1 million or 1 Xanax. There are special prices for faction contracts "
                            "(more information in the forums).",
                            style: TextStyle(fontSize: 13, color: widget.themeProvider.mainText),
                          ),
                        ),
                        SizedBox(height: 10),
                        Flexible(
                          child: Text(
                            "Please keep in mind if you don't pay for the requested revive, "
                            "you risk getting blocked from UHC!",
                            style: TextStyle(fontSize: 13, color: widget.themeProvider.mainText),
                          ),
                        ),
                        SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            TextButton(
                              child: Text("Medic!"),
                              onPressed: () async {
                                // User can be null if we are not accessing from the Profile page
                                if (widget.user == null) {
                                  var apiResponse = await TornApiCaller().getOwnProfileExtended(limit: 3);
                                  if (apiResponse is OwnProfileExtended) {
                                    _user = apiResponse;
                                  }
                                }

                                if (_user == null) {
                                  BotToast.showText(
                                    text: 'There was an error contacting Torn API to get your current status, '
                                        'please try again after a while!',
                                    textStyle: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white,
                                    ),
                                    contentColor: Colors.red[800],
                                    duration: Duration(seconds: 5),
                                    contentPadding: EdgeInsets.all(10),
                                  );
                                  Navigator.of(context).pop();
                                  return;
                                }

                                if (_user.status.color != 'red' && _user.status.state != "Hospital") {
                                  BotToast.showText(
                                    text: 'According to Torn you are not currently hospitalized, please wait a '
                                        'few seconds and try again!',
                                    textStyle: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white,
                                    ),
                                    contentColor: Colors.red[800],
                                    duration: Duration(seconds: 5),
                                    contentPadding: EdgeInsets.all(10),
                                  );
                                  Navigator.of(context).pop();
                                  return;
                                }

                                var uhc = UhcRevive(
                                  playerId: _user.playerId,
                                  playerName: _user.name,
                                  playerFaction: _user.faction.factionName,
                                  playerFactionId: _user.faction.factionId,
                                );

                                uhc.callMedic().then((value) {
                                  var resultString = "";
                                  var resultColor = Colors.transparent;

                                  if (value == "200") {
                                    resultString = "Request received by UHC!\n\n"
                                        "Please pay your reviver "
                                        "1 Xanax or \$1M";
                                    resultColor = Colors.green[800];
                                  } else if (value == "error") {
                                    resultString = "There was an error contacting UHC, try again later"
                                        "or contact them through UHC\'s Discord"
                                        "server!";
                                    resultColor = Colors.red[800];
                                  } else {
                                    resultString = value;
                                    resultColor = Colors.red[800];
                                  }

                                  BotToast.showText(
                                    text: resultString,
                                    textStyle: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white,
                                    ),
                                    contentColor: resultColor,
                                    duration: Duration(seconds: 5),
                                    contentPadding: EdgeInsets.all(10),
                                  );
                                });

                                Navigator.of(context).pop();
                              },
                            ),
                            TextButton(
                              child: Text("Cancel"),
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
                    backgroundColor: widget.themeProvider.secondBackground,
                    child: CircleAvatar(
                      backgroundColor: widget.themeProvider.secondBackground,
                      radius: 22,
                      child: SizedBox(
                        height: 34,
                        width: 34,
                        child: Image.asset(
                          'images/icons/uhc_revive.png',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _launchBrowser({
    @required String url,
    @required bool dialogRequested,
    bool recallLastSession = false,
    BuildContext context,
  }) async {
    if (!widget.settingsProvider.useQuickBrowser) dialogRequested = false;
    widget.webViewProvider.openBrowserPreference(
      context: context,
      url: url,
      useDialog: dialogRequested,
      recallLastSession: recallLastSession,
    );
  }
}
