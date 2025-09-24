import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/profile/own_profile_model.dart';
import 'package:torn_pda/providers/api/api_v1_calls.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/external/wolverines_revive.dart';
import 'package:url_launcher/url_launcher.dart';

class WolverinesReviveButton extends StatefulWidget {
  final ThemeProvider? themeProvider;
  final OwnProfileExtended? user;
  final SettingsProvider? settingsProvider;
  final WebViewProvider? webViewProvider;

  const WolverinesReviveButton({
    required this.themeProvider,
    required this.settingsProvider,
    required this.webViewProvider,
    this.user,
    super.key,
  });

  @override
  WolverinesReviveButtonState createState() => WolverinesReviveButtonState();
}

class WolverinesReviveButtonState extends State<WolverinesReviveButton> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        openWolverinesReviveDialog(context, widget.themeProvider!, widget.user);
      },
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 13),
            child: Image.asset('images/icons/wolverines_revive.png', width: 24),
          ),
          const SizedBox(width: 10),
          const Flexible(child: Text("Request a revive (The Wolverines)")),
        ],
      ),
    );
  }
}

Future<void> openWolverinesReviveDialog(BuildContext _, ThemeProvider themeProvider, OwnProfileExtended? user) {
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
                                "REQUEST A REVIVE FROM THE WOLVERINES",
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
                                "The Wolverines is an independent revive faction that believes that revives should be more accessible."
                                "\n\nCheck out their ",
                            style: TextStyle(
                              color: context.read<ThemeProvider>().mainText,
                              fontSize: 13,
                            ),
                            children: <InlineSpan>[
                              TextSpan(
                                text: 'Discord server',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                  fontSize: 13,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () async {
                                    const url = 'https://discord.gg/XmR6TpHXHb';
                                    if (await canLaunchUrl(Uri.parse(url))) {
                                      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                                    }
                                  },
                              ),
                              TextSpan(
                                text: "\n\nRevives cost ${context.read<SettingsProvider>().reviveWolverinesPrice},"
                                    " unless on contract. Refusal to pay will result in getting blacklisted.",
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

                              final wolverines = WolverinesRevive(
                                tornId: user!.playerId,
                                username: user!.name,
                                price: context.read<SettingsProvider>().reviveWolverinesPrice,
                              );

                              wolverines.callMedic().then((value) {
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
                  backgroundColor: themeProvider.secondBackground,
                  child: CircleAvatar(
                    backgroundColor: themeProvider.secondBackground,
                    radius: 22,
                    child: SizedBox(
                      height: 34,
                      width: 34,
                      child: Image.asset(
                        'images/icons/wolverines_revive.png',
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
