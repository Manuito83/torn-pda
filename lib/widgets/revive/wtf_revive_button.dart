import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/profile/own_profile_model.dart';
import 'package:torn_pda/providers/api/api_v1_calls.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/country_check.dart';
import 'package:torn_pda/utils/external/wtf_revive.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';
import 'package:url_launcher/url_launcher.dart';

class WtfReviveButton extends StatefulWidget {
  final ThemeProvider? themeProvider;
  final OwnProfileExtended? user;
  final SettingsProvider? settingsProvider;
  final WebViewProvider? webViewProvider;

  const WtfReviveButton({
    required this.themeProvider,
    required this.settingsProvider,
    required this.webViewProvider,
    this.user,
    super.key,
  });

  @override
  WtfReviveButtonState createState() => WtfReviveButtonState();
}

class WtfReviveButtonState extends State<WtfReviveButton> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        openWtfReviveDialog(context, widget.themeProvider!, widget.user);
      },
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 13),
            child: Image.asset('images/icons/wtf_revive.png', width: 24),
          ),
          const SizedBox(width: 10),
          const Flexible(child: Text("Request a revive (WTF)")),
        ],
      ),
    );
  }
}

Future<void> openWtfReviveDialog(BuildContext _, ThemeProvider themeProvider, OwnProfileExtended? user) {
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
                    color: themeProvider.secondBackground,
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
                                "REQUEST A REVIVE FROM WTF",
                                style: TextStyle(fontSize: 11, color: themeProvider.mainText),
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
                                    const url = 'https://discord.gg/S5Qp6aZd';
                                    if (await canLaunchUrl(Uri.parse(url))) {
                                      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                                    }
                                  },
                              ),
                              const TextSpan(text: ' for more information.'),
                              TextSpan(
                                text: "\n\nRevives cost ${context.read<SettingsProvider>().reviveWtfPrice}, "
                                    "unless on contract. Refusal to pay will result in getting blacklisted.",
                              ),
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
                              if (user == null) {
                                final apiResponse = await ApiCallsV1.getOwnProfileExtended(limit: 3);
                                if (apiResponse is OwnProfileExtended) {
                                  user = apiResponse;
                                }
                              }

                              if (user == null) {
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

                              if (user!.status!.color != 'red' && user!.status!.state != "Hospital") {
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

                              final wtf = WtfRevive(
                                tornId: user!.playerId,
                                username: user!.name,
                                faction: user!.faction!.factionName,
                                country: countryCheck(
                                  state: user!.status!.state,
                                  description: user!.status!.description,
                                ),
                              );

                              wtf.callMedic().then((args) {
                                var resultColor = Colors.green[800];
                                final String message = args[1]!;

                                int? code = int.tryParse(args[0]!);
                                if (code == null) {
                                  resultColor = Colors.red[800];
                                } else if (code != 200) {
                                  resultColor = Colors.red[800];
                                }

                                BotToast.showText(
                                  text: message,
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
                  backgroundColor: themeProvider.secondBackground,
                  child: CircleAvatar(
                    backgroundColor: themeProvider.secondBackground,
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
