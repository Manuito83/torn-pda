// Dart imports:
import 'dart:async';
import 'dart:io';

// Package imports:
import 'package:bot_toast/bot_toast.dart';
// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chaining/yata/yata_spy_model.dart';
import 'package:torn_pda/models/profile/other_profile_model.dart';
// Project imports:
import 'package:torn_pda/models/profile/shortcuts_model.dart';
import 'package:torn_pda/providers/api/api_v2_calls.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/shortcuts_provider.dart';
import 'package:torn_pda/providers/spies_controller.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/firebase_functions.dart';
import 'package:torn_pda/utils/number_formatter.dart';
import 'package:torn_pda/utils/stats_calculator.dart';
import 'package:torn_pda/utils/timestamp_ago.dart';
import 'package:torn_pda/widgets/webviews/webview_shortcuts_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebviewUrlDialog extends StatefulWidget {
  final Function? callFindInPage;
  final String? title;
  final String url;
  final InAppWebViewController? inAppWebview;
  final WebViewController? stockWebView;
  final UserDetailsProvider? userProvider;

  const WebviewUrlDialog({
    this.callFindInPage,
    required this.title,
    required this.url,
    this.inAppWebview,
    this.stockWebView,
    required this.userProvider,
  });

  @override
  WebviewUrlDialogState createState() => WebviewUrlDialogState();
}

class WebviewUrlDialogState extends State<WebviewUrlDialog> {
  ThemeProvider? _themeProvider;
  late ShortcutsProvider _shortcutsProvider;
  late SettingsProvider _settingsProvider;
  late WebViewProvider _webviewProvider;

  final _customURLController = TextEditingController();
  final _customURLKey = GlobalKey<FormState>();

  String? _currentUrl;
  String? _pageTitle;

  @override
  void initState() {
    super.initState();

    _currentUrl = widget.url;
    _pageTitle = widget.title;

    _shortcutsProvider = Provider.of<ShortcutsProvider>(context, listen: false);
    _themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _webviewProvider = Provider.of<WebViewProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
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
                  color: _themeProvider!.secondBackground,
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
                    Flexible(
                      child: Text(
                        "OPTIONS",
                        style: TextStyle(fontSize: 12, color: _themeProvider!.mainText),
                      ),
                    ),
                    const SizedBox(height: 15),
                    if (widget.url.contains("www.torn.com/loader.php?sid=attack&user2ID=") &&
                        widget.userProvider!.basic!.faction!.factionId != 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: Row(
                            children: [
                              const Icon(MdiIcons.fencing, size: 20),
                              SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  'FACTION ASSISTANCE',
                                  style: TextStyle(fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                          onPressed: () async {
                            BotToast.showText(
                              text: "Requesting assistance from faction members!",
                              textStyle: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                              contentColor: Colors.green,
                              contentPadding: const EdgeInsets.all(10),
                            );

                            Navigator.of(context).pop();

                            final String attackId = widget.url.split("user2ID=")[1];

                            final dynamic t = await ApiCallsV2.getOtherUserProfile_v2(
                              payload: {
                                "id": attackId,
                              },
                            );

                            dynamic attackAssistMessageArg;
                            if (t is OtherProfileModel) {
                              final SpiesController spyController = Get.find<SpiesController>();

                              YataSpyModel? spy;

                              switch (spyController.spiesSource) {
                                case SpiesSource.yata:
                                  spy = spyController.getYataSpy(userId: attackId, name: t.name);
                                  break;
                                case SpiesSource.tornStats:
                                  spy = spyController.getTornStatsSpy(userId: attackId)?.toYataModel();
                                  break;
                                case null:
                                  break;
                              }
                              String? exactStats;

                              if (spy != null) {
                                final total = formatBigNumbers(spy.total!);
                                final str = formatBigNumbers(spy.strength!);
                                final spd = formatBigNumbers(spy.speed!);
                                final def = formatBigNumbers(spy.defense!);
                                final dex = formatBigNumbers(spy.dexterity!);
                                exactStats = "$total (STR $str, SPD $spd, DEF $def, DEX $dex), "
                                    "updated ${readTimestamp(spy.update!)}";
                              }
                              String estimatedStats = StatsCalculator.calculateStats(
                                criminalRecordTotal: t.personalstats?.crimes?.offenses?.total,
                                level: t.level,
                                networth: t.personalstats!.networth!.total,
                                rank: t.rank,
                              );

                              estimatedStats += "\n- Xanax: ${t.personalstats!.drugs!.xanax}";
                              estimatedStats += "\n- Refills (E): ${t.personalstats!.other!.refills!.energy}";
                              estimatedStats += "\n- Drinks (E): ${t.personalstats!.items!.used!.energy}";
                              estimatedStats += "\n(tap to get a comparison with you)";
                              attackAssistMessageArg = (
                                attackId: attackId,
                                attackName: t.name,
                                attackLevel: t.level.toString(),
                                attackLife: "${t.life!.current}/${t.life!.maximum}",
                                attackAge: t.age.toString(),
                                estimatedStats: estimatedStats,
                                exactStats: exactStats ?? "",
                                xanax: t.personalstats!.drugs!.xanax.toString(),
                                refills: t.personalstats!.other!.refills!.energy.toString(),
                                drinks: t.personalstats!.items!.used!.energy.toString(),
                              );
                            } else {
                              attackAssistMessageArg = (attackId: attackId);
                            }
                            final int membersNotified = await firebaseFunctions.sendAttackAssistMessage(
                              attackId: attackAssistMessageArg.attackId,
                              attackName: attackAssistMessageArg.attackName,
                              attackLevel: attackAssistMessageArg.attackLevel,
                              attackLife: attackAssistMessageArg.attackLife,
                              attackAge: attackAssistMessageArg.attackAge,
                              estimatedStats: attackAssistMessageArg.estimatedStats,
                              xanax: attackAssistMessageArg.xanax,
                              refills: attackAssistMessageArg.refills,
                              drinks: attackAssistMessageArg.drinks,
                              exactStats: attackAssistMessageArg.exactStats,
                            );

                            String membersMessage =
                                "$membersNotified faction member${membersNotified == 1 ? " has" : "s have"} been notified!";
                            Color? membersColor = Colors.green;

                            if (membersNotified == 0) {
                              membersMessage = "No faction member could be notified (not using Torn PDA or "
                                  "assists messages deactivated)!";
                              membersColor = Colors.orange[700];
                            } else if (membersNotified == -1) {
                              membersMessage = "There was a problem locating your faction's details, please try again!";
                              membersColor = Colors.orange[700];
                            }

                            BotToast.showText(
                              text: membersMessage,
                              textStyle: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                              contentColor: membersColor!,
                              duration: const Duration(seconds: 5),
                              contentPadding: const EdgeInsets.all(10),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Flexible(
                          child: Form(
                            key: _customURLKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min, // To make the card compact
                              children: <Widget>[
                                TextFormField(
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _themeProvider!.mainText,
                                  ),
                                  controller: _customURLController,
                                  maxLength: 300,
                                  textInputAction: TextInputAction.go,
                                  onFieldSubmitted: (value) {
                                    onCustomURLSubmitted();
                                  },
                                  decoration: const InputDecoration(
                                    counterText: "",
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                    labelText: 'Browse URL',
                                    labelStyle: TextStyle(fontSize: 12),
                                  ),
                                  validator: (value) {
                                    if (value!.replaceAll(' ', '').isEmpty) {
                                      return "Cannot be empty!";
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.double_arrow_outlined),
                          onPressed: () async {
                            onCustomURLSubmitted();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: Platform.isWindows ? 2 : 0),
                      child: ElevatedButton(
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.home, size: 20),
                            SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                'Torn Home',
                                style: TextStyle(fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.inAppWebview!.loadUrl(
                            urlRequest: URLRequest(
                              url: WebUri("https://www.torn.com"),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: Platform.isWindows ? 2 : 0),
                      child: ElevatedButton(
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.copy, size: 20),
                            SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                'Copy URL',
                                style: TextStyle(fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        onPressed: () {
                          String input = _currentUrl ?? "null";
                          Clipboard.setData(ClipboardData(text: input));

                          if (input.length > 60) {
                            input = "${input.substring(0, 60)}...";
                          }

                          BotToast.showText(
                            text: "Link copied! [$input]",
                            textStyle: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                            contentColor: Colors.green,
                            duration: const Duration(milliseconds: 1500),
                            contentPadding: const EdgeInsets.all(10),
                          );
                          _customURLController.text = "";
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: Platform.isWindows ? 2 : 0),
                      child: ElevatedButton(
                        onPressed: _shortcutsProvider.activeShortcuts.isNotEmpty
                            ? () {
                                Navigator.of(context).pop();
                                _openShortcutsDialog();
                                _customURLController.text = "";
                              }
                            : null,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'images/icons/heart.png',
                              width: 20,
                              color: _shortcutsProvider.activeShortcuts.isNotEmpty ? Colors.white : Colors.grey,
                            ),
                            const SizedBox(width: 5),
                            const Flexible(
                              child: Text(
                                'Browse shortcuts',
                                style: TextStyle(fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: Platform.isWindows ? 2 : 0),
                      child: ElevatedButton(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'images/icons/heart_add.png',
                              width: 20,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            const Flexible(
                              child: Text(
                                'Save as shortcut',
                                style: TextStyle(fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _openCustomShortcutDialog(_pageTitle, _currentUrl);
                          _customURLController.text = "";
                        },
                      ),
                    ),
                    if (widget.inAppWebview != null)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: Platform.isWindows ? 2 : 0),
                        child: ElevatedButton(
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search, size: 20),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Find in page',
                                  style: TextStyle(fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            bool wasFullScreenActive = false;
                            if (_webviewProvider.currentUiMode == UiMode.fullScreen) {
                              wasFullScreenActive = true;
                              _webviewProvider.setCurrentUiMode(UiMode.window, context);
                            }
                            widget.callFindInPage!(wasFullScreenActive);
                          },
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: Platform.isWindows ? 2 : 0),
                      child: ElevatedButton(
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.open_in_browser_outlined, size: 20),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'External browser',
                                style: TextStyle(fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        onPressed: () async {
                          Navigator.of(context).pop();
                          if (await canLaunchUrl(Uri.parse(_currentUrl!))) {
                            await launchUrl(Uri.parse(_currentUrl!), mode: LaunchMode.externalApplication);
                          }
                        },
                      ),
                    ),
                    if (widget.inAppWebview != null && Platform.isAndroid)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Column(
                          children: [
                            const Divider(),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'ZOOM',
                                  style: TextStyle(fontSize: 8),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 5),
                                  child: ElevatedButton(
                                    child: const Icon(MdiIcons.minus),
                                    onPressed: () async {
                                      if (Platform.isAndroid) {
                                        final InAppWebViewSettings newOptions =
                                            (await widget.inAppWebview!.getSettings())!;
                                        if (newOptions.initialScale == 0) {
                                          newOptions.initialScale = 350;
                                        } else if (newOptions.initialScale != null) {
                                          if (newOptions.initialScale! > 100) {
                                            newOptions.initialScale = newOptions.initialScale! - 5;
                                          }
                                        }
                                        widget.inAppWebview!.setSettings(settings: newOptions);
                                        _settingsProvider.setAndroidBrowserScale = newOptions.initialScale ?? 0;
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Padding(
                                  padding: const EdgeInsets.only(top: 5),
                                  child: ElevatedButton(
                                    child: const Icon(MdiIcons.refresh),
                                    onPressed: () async {
                                      if (Platform.isAndroid) {
                                        final InAppWebViewSettings newOptions =
                                            (await widget.inAppWebview!.getSettings())!;
                                        newOptions.initialScale = 0;
                                        widget.inAppWebview!.setSettings(settings: newOptions);
                                        _settingsProvider.setAndroidBrowserScale = 0;
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Padding(
                                  padding: const EdgeInsets.only(top: 5),
                                  child: ElevatedButton(
                                    child: const Icon(MdiIcons.plus),
                                    onPressed: () async {
                                      if (Platform.isAndroid) {
                                        final InAppWebViewSettings newSettings =
                                            (await widget.inAppWebview!.getSettings())!;
                                        if (newSettings.initialScale == 0) {
                                          newSettings.initialScale = 100;
                                        } else if (newSettings.initialScale! < 350) {
                                          newSettings.initialScale = newSettings.initialScale! + 5;
                                        }
                                        widget.inAppWebview!.setSettings(settings: newSettings);
                                        _settingsProvider.setAndroidBrowserScale = newSettings.initialScale!;
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    if (widget.inAppWebview != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Column(
                          children: [
                            const Divider(),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'DEV',
                                  style: TextStyle(fontSize: 8),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      const Text("Show terminal", style: TextStyle(fontSize: 12)),
                                      Switch(
                                        value: _settingsProvider.terminalEnabled,
                                        onChanged: (value) {
                                          setState(() {
                                            _settingsProvider.changeTerminalEnabled = value;
                                          });
                                        },
                                        activeTrackColor: Colors.lightGreenAccent,
                                        activeColor: Colors.green,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    TextButton(
                      child: const Text("Close"),
                      onPressed: () {
                        _customURLController.text = "";
                        Navigator.of(context).pop();
                      },
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
                backgroundColor: _themeProvider!.secondBackground,
                child: CircleAvatar(
                  backgroundColor: _themeProvider!.secondBackground,
                  radius: 22,
                  child: SizedBox(
                    height: 25,
                    width: 25,
                    child: Image.asset(
                      "images/icons/pda_icon.png",
                      width: 18,
                      height: 18,
                      color: _themeProvider!.mainText,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void onCustomURLSubmitted() {
    if (_customURLKey.currentState!.validate()) {
      String url = _customURLController.text.replaceAll(" ", "");
      if (!url.toLowerCase().contains("https://") && !url.toLowerCase().contains("http://")) {
        url = 'https://$url';
      } else if (url.toLowerCase().contains("http://")) {
        url = url.replaceAll("http://", "https://");
      }

      if (widget.inAppWebview != null) {
        widget.inAppWebview!.loadUrl(
          urlRequest: URLRequest(
            url: WebUri(url),
          ),
        );
      } else {
        widget.stockWebView!.loadRequest(Uri.parse(_customURLController.text));
      }

      _customURLController.text = "";
      Navigator.of(context).pop();
    }
  }

  Future<void> _openCustomShortcutDialog(String? title, String? url) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return CustomShortcutDialog(
          themeProvider: _themeProvider,
          title: title,
          url: url,
        );
      },
    );
  }

  Future<void> _openShortcutsDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        if (widget.inAppWebview != null) {
          return WebviewShortcutsDialog(
            inAppWebView: widget.inAppWebview,
          );
        } else {
          return WebviewShortcutsDialog(
            stockWebview: widget.stockWebView,
          );
        }
      },
    );
  }
}

class CustomShortcutDialog extends StatefulWidget {
  final ThemeProvider? themeProvider;
  final String? title;
  final String? url;

  const CustomShortcutDialog({
    required this.themeProvider,
    required this.title,
    required this.url,
    super.key,
  });

  @override
  State<CustomShortcutDialog> createState() => CustomShortcutDialogState();
}

class CustomShortcutDialogState extends State<CustomShortcutDialog> {
  late ShortcutsProvider _shortcutsProvider;

  final _customURLController = TextEditingController();
  final _customShortcutNameController = TextEditingController();
  final _customShortcutURLController = TextEditingController();
  final _customShortcutNameKey = GlobalKey<FormState>();
  final _customShortcutURLKey = GlobalKey<FormState>();

  @override
  @override
  void initState() {
    super.initState();
    _shortcutsProvider = context.read<ShortcutsProvider>();
    _customShortcutNameController.text = widget.title!;
    _customShortcutURLController.text = widget.url!;
  }

  @override
  Widget build(BuildContext context) {
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
                    Flexible(
                      child: Text(
                        "Add a name and URL for your custom shortcut. Note: "
                        "ensure URL begins with 'https://'",
                        style: TextStyle(fontSize: 12, color: widget.themeProvider!.mainText),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Form(
                      key: _customShortcutNameKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // To make the card compact
                        children: <Widget>[
                          TextFormField(
                            style: TextStyle(
                              fontSize: 14,
                              color: widget.themeProvider!.mainText,
                            ),
                            textCapitalization: TextCapitalization.sentences,
                            controller: _customShortcutNameController,
                            maxLength: 30,
                            decoration: const InputDecoration(
                              counterText: "",
                              isDense: true,
                              border: OutlineInputBorder(),
                              labelText: 'Name',
                            ),
                            validator: (value) {
                              if (value!.replaceAll(' ', '').isEmpty) {
                                return "Cannot be empty!";
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Flexible(
                          child: Form(
                            key: _customShortcutURLKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min, // To make the card compact
                              children: <Widget>[
                                TextFormField(
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: widget.themeProvider!.mainText,
                                  ),
                                  controller: _customShortcutURLController,
                                  maxLength: 300,
                                  decoration: const InputDecoration(
                                    counterText: "",
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                    labelText: 'URL',
                                  ),
                                  validator: (value) {
                                    if (value!.replaceAll(' ', '').isEmpty) {
                                      return "Cannot be empty!";
                                    }
                                    if (!value.toLowerCase().contains('https://')) {
                                      if (value.toLowerCase().contains('http://')) {
                                        return "Invalid, HTTPS needed!";
                                      }
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        TextButton(
                          child: const Text("Add"),
                          onPressed: () {
                            if (!_customShortcutURLKey.currentState!.validate()) {
                              return;
                            }
                            if (!_customShortcutNameKey.currentState!.validate()) {
                              return;
                            }

                            final customShortcut = Shortcut()
                              ..name = _customShortcutNameController.text
                              ..nickname = _customShortcutNameController.text
                              ..url = _customShortcutURLController.text
                              ..iconUrl = 'images/icons/pda_icon.png'
                              ..color = Colors.orange[500]
                              ..isCustom = true;

                            _shortcutsProvider.activateShortcut(customShortcut);
                            Navigator.of(context).pop();
                            _customShortcutNameController.text = '';
                            _customURLController.text = '';
                          },
                        ),
                        TextButton(
                          child: const Text("Close"),
                          onPressed: () {
                            Navigator.of(context).pop();
                            _customShortcutNameController.text = '';
                            _customURLController.text = '';
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
                    height: 25,
                    width: 25,
                    child: Image.asset(
                      "images/icons/pda_icon.png",
                      width: 18,
                      height: 18,
                      color: widget.themeProvider!.mainText,
                    ),
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
