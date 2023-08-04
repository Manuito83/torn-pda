import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/profile/own_profile_model.dart';
import 'package:torn_pda/providers/api_caller.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/external/hela_revive.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';
import 'package:url_launcher/url_launcher.dart';

class HelaReviveButton extends StatefulWidget {
  final ThemeProvider? themeProvider;
  final OwnProfileExtended? user;
  final SettingsProvider? settingsProvider;
  final WebViewProvider? webViewProvider;

  const HelaReviveButton({
    required this.themeProvider,
    required this.settingsProvider,
    required this.webViewProvider,
    this.user,
    super.key,
  });

  @override
  _HelaReviveButtonState createState() => _HelaReviveButtonState();
}

class _HelaReviveButtonState extends State<HelaReviveButton> {
  OwnProfileExtended? _user;

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
        _openHelaReviveDialog(context);
      },
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 13),
            child: Image.asset('images/icons/hela_revive.png', width: 24),
          ),
          const SizedBox(width: 10),
          const Flexible(child: Text("Request a revive (HeLa)")),
        ],
      ),
    );
  }

  Future<void> _openHelaReviveDialog(BuildContext _) {
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
                    padding: const EdgeInsets.only(
                      top: 45,
                      bottom: 16,
                      left: 16,
                      right: 16,
                    ),
                    margin: const EdgeInsets.only(top: 15),
                    decoration: BoxDecoration(
                      color: widget.themeProvider!.secondBackground,
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
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  "REQUEST A REVIVE FROM HELA",
                                  style: TextStyle(fontSize: 11, color: widget.themeProvider!.mainText),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: RichText(
                            text: TextSpan(
                              text: "HeLa is an independent revive faction, comprised of a small group of active, "
                                  "premium revivers."
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
                                      const url = 'https://www.torn.com/forums.php#/p=threads&f=10&t=16233040&b=0&a=0';
                                      context.read<WebViewProvider>().openBrowserPreference(
                                            context: context,
                                            url: url,
                                            browserTapType: BrowserTapType.short,
                                          );
                                    },
                                    onLongPress: () {
                                      Navigator.of(context).pop();
                                      const url = 'https://www.torn.com/forums.php#/p=threads&f=10&t=16233040&b=0&a=0';
                                      context.read<WebViewProvider>().openBrowserPreference(
                                            context: context,
                                            url: url,
                                            browserTapType: BrowserTapType.long,
                                          );
                                    },
                                    child: const Text(
                                      'forum thread',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                                const TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Discord server',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                    fontSize: 13,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () async {
                                      const url = 'https://discord.gg/hWamUgW';
                                      if (await canLaunchUrl(Uri.parse(url))) {
                                        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                                      }
                                    },
                                ),
                                const TextSpan(
                                    text: "\n\nRevives cost 1 million or 1 Xanax each, unless on contract. "
                                        "Refusal to pay will result in getting blacklisted.",),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            TextButton(
                              child: const Text("Medic!"),
                              onPressed: () async {
                                // User can be null if we are not accessing from the Profile page
                                if (widget.user == null) {
                                  final apiResponse =
                                      await Get.find<ApiCallerController>().getOwnProfileExtended(limit: 3);
                                  if (apiResponse is OwnProfileExtended) {
                                    _user = apiResponse;
                                  }
                                }

                                if (_user == null) {
                                  BotToast.showText(
                                    text: 'There was an error contacting Torn API to get your current status, '
                                        'please try again after a while!',
                                    textStyle: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.white,
                                    ),
                                    contentColor: Colors.red[800]!,
                                    duration: const Duration(seconds: 5),
                                    contentPadding: const EdgeInsets.all(10),
                                  );
                                  Navigator.of(context).pop();
                                  return;
                                }

                                if (_user!.status!.color != 'red' && _user!.status!.state != "Hospital") {
                                  BotToast.showText(
                                    text: 'According to Torn you are not currently hospitalized, please wait a '
                                        'few seconds and try again!',
                                    textStyle: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.white,
                                    ),
                                    contentColor: Colors.red[800]!,
                                    duration: const Duration(seconds: 5),
                                    contentPadding: const EdgeInsets.all(10),
                                  );
                                  Navigator.of(context).pop();
                                  return;
                                }

                                final hela = HelaRevive(
                                  tornId: _user!.playerId,
                                  username: _user!.name,
                                );

                                hela.callMedic().then((value) {
                                  var resultColor = Colors.green[800];

                                  if (value.contains("Error")) {
                                    resultColor = Colors.red[800];
                                  }

                                  BotToast.showText(
                                    text: value,
                                    textStyle: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.white,
                                    ),
                                    contentColor: resultColor!,
                                    duration: const Duration(seconds: 5),
                                    contentPadding: const EdgeInsets.all(10),
                                  );
                                });

                                Navigator.of(context).pop();
                              },
                            ),
                            TextButton(
                              child: const Text("Cancel"),
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
                    backgroundColor: widget.themeProvider!.secondBackground,
                    child: CircleAvatar(
                      backgroundColor: widget.themeProvider!.secondBackground,
                      radius: 22,
                      child: SizedBox(
                        height: 34,
                        width: 34,
                        child: Image.asset(
                          'images/icons/hela_revive.png',
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
