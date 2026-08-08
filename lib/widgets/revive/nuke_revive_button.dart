import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:torn_pda/models/profile/own_profile_model.dart';
import 'package:torn_pda/models/profile/revive_services/revive_provider.dart';
import 'package:torn_pda/providers/api/api_v1_calls.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/external/nuke_revive.dart';
import 'package:torn_pda/widgets/revive/revive_provider_info_text.dart';

class NukeReviveButton extends StatefulWidget {
  final ThemeProvider? themeProvider;
  final OwnProfileExtended? user;
  final SettingsProvider? settingsProvider;
  final WebViewProvider? webViewProvider;

  const NukeReviveButton({
    required this.themeProvider,
    required this.settingsProvider,
    required this.webViewProvider,
    this.user,
    super.key,
  });

  @override
  NukeReviveButtonState createState() => NukeReviveButtonState();
}

class NukeReviveButtonState extends State<NukeReviveButton> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        openNukeReviveDialog(context, widget.themeProvider!, widget.user);
      },
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 13),
            child: Image.asset('images/icons/nuke-revive.png', width: 24),
          ),
          const SizedBox(width: 10),
          const Flexible(child: Text("Request a revive (Nuke)")),
        ],
      ),
    );
  }
}

Future<void> openNukeReviveDialog(BuildContext ctx, ThemeProvider themeProvider, OwnProfileExtended? user) {
  return showDialog<void>(
    context: ctx,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0.0,
        backgroundColor: Colors.transparent,
        content: SingleChildScrollView(
          child: Stack(
            children: <Widget>[
              SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.only(top: 45, bottom: 16, left: 16, right: 16),
                  margin: const EdgeInsets.only(top: 15),
                  decoration: BoxDecoration(
                    color: themeProvider.secondBackground,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10.0, offset: Offset(0.0, 10.0))],
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
                                "REQUEST A REVIVE FROM NUKE",
                                style: TextStyle(fontSize: 11, color: themeProvider.mainText),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Flexible(child: ReviveProviderInfoText(provider: ReviveProviders.nuke)),
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
                                  text:
                                      'There was an error contacting Torn API to get your current status, '
                                      'please try again after a while!',
                                  textStyle: const TextStyle(fontSize: 13, color: Colors.white),
                                  contentColor: Colors.red[800]!,
                                  duration: const Duration(seconds: 5),
                                  contentPadding: const EdgeInsets.all(10),
                                );
                                Navigator.of(context).pop();
                                return;
                              }

                              if (user!.status!.color != 'red' && user!.status!.state != "Hospital") {
                                BotToast.showText(
                                  text:
                                      'According to Torn you are not currently hospitalized, please wait a '
                                      'few seconds and try again!',
                                  textStyle: const TextStyle(fontSize: 13, color: Colors.white),
                                  contentColor: Colors.red[800]!,
                                  duration: const Duration(seconds: 5),
                                  contentPadding: const EdgeInsets.all(10),
                                );
                                Navigator.of(context).pop();
                                return;
                              }

                              final nuke = NukeRevive(
                                playerId: user!.playerId!,
                                playerName: user!.name,
                                playerFaction: user!.faction!.factionId,
                                playerLocation: user!.travel!.destination,
                              );

                              nuke.callMedic().then((success) {
                                String message = 'Revive requested!';
                                Color messageColor = Colors.green;
                                if (!success) {
                                  message =
                                      'There was an error contacting Nuke, try again later '
                                      "or contact them through Central Hospital's Discord "
                                      'server!';
                                  messageColor = Colors.red.shade800;
                                }

                                BotToast.showText(
                                  text: message,
                                  textStyle: const TextStyle(fontSize: 13, color: Colors.white),
                                  contentColor: messageColor,
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
                      ),
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
                    child: SizedBox(height: 34, width: 34, child: Image.asset('images/icons/nuke-revive.png')),
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
