import 'package:bot_toast/bot_toast.dart';
import 'package:easy_rich_text/easy_rich_text.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/profile/own_profile_model.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/providers/api_caller.dart';
import 'package:torn_pda/utils/country_check.dart';
import 'package:torn_pda/utils/external/wtf_revive.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';
import 'package:url_launcher/url_launcher.dart';

class WtfReviveButton extends StatefulWidget {
  final ThemeProvider themeProvider;
  final OwnProfileExtended user;
  final SettingsProvider settingsProvider;
  final WebViewProvider webViewProvider;

  const WtfReviveButton({
    @required this.themeProvider,
    @required this.settingsProvider,
    @required this.webViewProvider,
    this.user,
    Key key,
  }) : super(key: key);

  @override
  _WtfReviveButtonState createState() => _WtfReviveButtonState();
}

class _WtfReviveButtonState extends State<WtfReviveButton> {
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
        _openWtfReviveDialog(context);
      },
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 13),
            child: Image.asset('images/icons/wtf_revive.png', width: 24),
          ),
          SizedBox(width: 10),
          Flexible(child: Text("Request a revive (WTF)")),
        ],
      ),
    );
  }

  Future<void> _openWtfReviveDialog(BuildContext _) {
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
                                  "REQUEST A REVIVE FROM WTF",
                                  style: TextStyle(fontSize: 11, color: widget.themeProvider.mainText),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: RichText(
                            text: TextSpan(
                              text:
                                  "WTF are a collection of factions looking to bolster their ranks with new and veteran "
                                  "players alike. They provide Reviving and Attacking services."
                                  "\n\nCheck out their ",
                              style: TextStyle(
                                color: context.read<ThemeProvider>().mainText,
                                fontSize: 13,
                              ),
                              children: <InlineSpan>[
                                WidgetSpan(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).pop();
                                      context.read<WebViewProvider>().openBrowserPreference(
                                            context: context,
                                            url: 'https://www.torn.com/forums.php#/p=threads&f=24&t=16012007&b=0&a=0',
                                            browserTapType: BrowserTapType.short,
                                          );
                                    },
                                    onLongPress: () {
                                      Navigator.of(context).pop();
                                      context.read<WebViewProvider>().openBrowserPreference(
                                            context: context,
                                            url: 'https://www.torn.com/forums.php#/p=threads&f=24&t=16012007&b=0&a=0',
                                            browserTapType: BrowserTapType.long,
                                          );
                                    },
                                    child: Text(
                                      'forum thread',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                                TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Discord server',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                    fontSize: 13,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () async {
                                      var url = 'https://discord.gg/S5Qp6aZd';
                                      if (await canLaunchUrl(Uri.parse(url))) {
                                        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                                      }
                                    },
                                ),
                                TextSpan(text: ' for more information.'),
                                TextSpan(
                                    text: "\n\nRevives cost 1 million or 1 Xanax each, unless on contract. "
                                        "Refusal to pay will result in getting blacklisted."),
                              ],
                            ),
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
                                  var apiResponse =
                                      await Get.find<ApiCallerController>().getOwnProfileExtended(limit: 3);
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

                                var wtf = WtfRevive(
                                    tornId: _user.playerId,
                                    username: _user.name,
                                    faction: _user.faction.factionName,
                                    country: countryCheck(
                                      state: _user.status.state,
                                      description: _user.status.description,
                                    ));

                                wtf.callMedic().then((args) {
                                  var resultColor = Colors.green[800];
                                  String message = args[1];

                                  int code = int.tryParse(args[0]);
                                  if (code == null) {
                                    resultColor = Colors.red[800];
                                  } else if (code != 200) {
                                    resultColor = Colors.red[800];
                                  }

                                  BotToast.showText(
                                    text: message,
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
                          'images/icons/wtf_revive.png',
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
}
