// Dart imports:
import 'dart:async';
import 'dart:convert';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:torn_pda/models/chaining/yata/yata_spy_model.dart';
import 'package:torn_pda/models/profile/other_profile_model.dart';

// Project imports:
import 'package:torn_pda/models/profile/shortcuts_model.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/shortcuts_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/utils/api_caller.dart';
import 'package:torn_pda/utils/firebase_functions.dart';
import 'package:torn_pda/utils/number_formatter.dart';
import 'package:torn_pda/utils/stats_calculator.dart';
import 'package:torn_pda/utils/timestamp_ago.dart';
import 'package:torn_pda/widgets/webviews/webview_shortcuts_dialog.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebviewUrlDialog extends StatefulWidget {
  final Function callFindInPage;
  final String title;
  final String url;
  final InAppWebViewController inAppWebview;
  final WebViewController stockWebView;
  final UserDetailsProvider userProvider;

  WebviewUrlDialog(
      {this.callFindInPage,
      @required this.title,
      @required this.url,
      this.inAppWebview,
      this.stockWebView,
      @required this.userProvider});

  @override
  _WebviewUrlDialogState createState() => _WebviewUrlDialogState();
}

class _WebviewUrlDialogState extends State<WebviewUrlDialog> {
  ThemeProvider _themeProvider;
  ShortcutsProvider _shortcutsProvider;
  SettingsProvider _settingsProvider;

  final _customURLController = new TextEditingController();
  var _customURLKey = GlobalKey<FormState>();

  final _customShortcutNameController = new TextEditingController();
  final _customShortcutURLController = new TextEditingController();
  var _customShortcutNameKey = GlobalKey<FormState>();
  var _customShortcutURLKey = GlobalKey<FormState>();

  String _currentUrl;
  String _pageTitle;

  @override
  void initState() {
    super.initState();

    _currentUrl = widget.url;
    _pageTitle = widget.title;

    _shortcutsProvider = Provider.of<ShortcutsProvider>(context, listen: false);
    _themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
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
                padding: EdgeInsets.only(
                  top: 45,
                  bottom: 16,
                  left: 16,
                  right: 16,
                ),
                margin: EdgeInsets.only(top: 15),
                decoration: new BoxDecoration(
                  color: _themeProvider.secondBackground,
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
                    Flexible(
                      child: Text(
                        "OPTIONS",
                        style: TextStyle(fontSize: 12, color: _themeProvider.mainText),
                      ),
                    ),
                    SizedBox(height: 15),
                    if (widget.url.contains("www.torn.com/loader.php?sid=attack&user2ID=") &&
                        widget.userProvider.basic.faction.factionId != 0)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          primary: Colors.red,
                          onPrimary: Colors.white,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(MdiIcons.fencing, size: 20),
                            SizedBox(width: 5),
                            Text('FACTION ASSISTANCE', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        onPressed: () async {
                          BotToast.showText(
                            onlyOne: true,
                            text: "Requesting assistance from faction members!",
                            textStyle: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                            contentColor: Colors.green,
                            duration: Duration(seconds: 2),
                            contentPadding: EdgeInsets.all(10),
                          );

                          Navigator.of(context).pop();

                          String apiKey = widget.userProvider.basic.userApiKey;

                          String attackId = widget.url.split("user2ID=")[1];
                          var t = await TornApiCaller().getOtherProfile(playerId: attackId);

                          // Get stats from YATA
                          var spyModel = YataSpyModel();
                          var spyFoundInYata = false;
                          try {
                            UserController _u = Get.put(UserController());
                            String yataURL = 'https://yata.yt/api/v1/spy/$attackId?key=${_u.alternativeYataKey}';
                            var resp = await http.get(Uri.parse(yataURL)).timeout(Duration(seconds: 5));
                            if (resp.statusCode == 200) {
                              var spyJson = json.decode(resp.body);
                              var spiedStats = spyJson["spies"]["$attackId"];
                              if (spiedStats != null) {
                                spyModel = yataSpyModelFromJson(json.encode(spiedStats));
                                spyFoundInYata = true;
                              }
                            }
                          } catch (e) {
                            // Won't get YATA details
                          }

                          int membersNotified = 0;
                          if (t is OtherProfileModel) {
                            // Fill stats either way
                            String exactStats = "";
                            String estimatedStats = "";
                            if (spyFoundInYata) {
                              String total = formatBigNumbers(spyModel.total);
                              String str = formatBigNumbers(spyModel.strength);
                              String spd = formatBigNumbers(spyModel.speed);
                              String def = formatBigNumbers(spyModel.defense);
                              String dex = formatBigNumbers(spyModel.dexterity);
                              exactStats = "${total} (STR $str, SPD $spd, DEF $def, DEX $dex), "
                                  "updated ${readTimestamp(spyModel.update)}";
                            } else {
                              estimatedStats = StatsCalculator.calculateStats(
                                criminalRecordTotal: t.criminalrecord.total,
                                level: t.level,
                                networth: t.personalstats.networth,
                                rank: t.rank,
                              );

                              estimatedStats += "\n- Xanax: ${t.personalstats.xantaken}";
                              estimatedStats += "\n- Refills (E): ${t.personalstats.refills}";
                              estimatedStats += "\n- Drinks (E): ${t.personalstats.energydrinkused}";
                              estimatedStats += "\n(tap to get a comparison with you)";
                            }

                            membersNotified = await firebaseFunctions.sendAttackAssistMessage(
                              attackId: attackId,
                              attackName: t.name,
                              attackLevel: t.level.toString(),
                              attackLife: "${t.life.current}/${t.life.maximum}",
                              attackAge: t.age.toString(),
                              estimatedStats: estimatedStats,
                              exactStats: exactStats,
                              xanax: t.personalstats.xantaken.toString(),
                              refills: t.personalstats.refills.toString(),
                              drinks: t.personalstats.energydrinkused.toString(),
                            );
                          } else {
                            membersNotified = await firebaseFunctions.sendAttackAssistMessage(
                              attackId: attackId,
                            );
                          }

                          String membersMessage = "$membersNotified faction member${membersNotified == 1 ? "" : "s"} "
                              "${membersNotified == 1 ? "has" : "have"} been notified!";
                          Color membersColor = Colors.green;

                          if (membersNotified == 0) {
                            membersMessage = "No faction member could be notified (not using Torn PDA or "
                                "assists messages deactivated)!";
                            membersColor = Colors.orange[700];
                          } else if (membersNotified == -1) {
                            membersMessage = "There was a problem locating your faction's details, please try again!";
                            membersColor = Colors.orange[700];
                          }

                          BotToast.showText(
                            onlyOne: true,
                            text: membersMessage,
                            textStyle: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                            contentColor: membersColor,
                            duration: Duration(seconds: 5),
                            contentPadding: EdgeInsets.all(10),
                          );
                        },
                      ),
                    SizedBox(height: 5),
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
                                    color: _themeProvider.mainText,
                                  ),
                                  controller: _customURLController,
                                  maxLength: 300,
                                  maxLines: 1,
                                  textInputAction: TextInputAction.go,
                                  onFieldSubmitted: (value) {
                                    onCustomURLSubmitted();
                                  },
                                  decoration: InputDecoration(
                                    counterText: "",
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                    labelText: 'Browse URL',
                                    labelStyle: TextStyle(fontSize: 12),
                                  ),
                                  validator: (value) {
                                    if (value.replaceAll(' ', '').isEmpty) {
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
                          icon: Icon(Icons.double_arrow_outlined),
                          onPressed: () async {
                            onCustomURLSubmitted();
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 5),
                    ElevatedButton(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        //mainAxisAlignment: MainAxisAlign,
                        children: [
                          Icon(Icons.copy, size: 20),
                          SizedBox(width: 5),
                          Text('Copy URL', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _currentUrl));

                        // Avoid copying _currentUrl directly unless we await,
                        // otherwise we can change _currentUrl while the copy
                        // is being performed and hang the app
                        var copied = _currentUrl;
                        if (_currentUrl.length > 60) {
                          copied = _currentUrl.substring(0, 60) + "...";
                        }

                        BotToast.showText(
                          text: "Current URL copied to "
                              "the clipboard [$copied]",
                          textStyle: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                          contentColor: Colors.green,
                          duration: Duration(seconds: 5),
                          contentPadding: EdgeInsets.all(10),
                        );
                        _customURLController.text = "";
                        Navigator.of(context).pop();
                      },
                    ),
                    SizedBox(height: 5),
                    ElevatedButton(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          //mainAxisAlignment: MainAxisAlign,
                          children: [
                            Image.asset(
                              'images/icons/heart.png',
                              width: 20,
                              color: _shortcutsProvider.activeShortcuts.length > 0 ? Colors.white : Colors.grey,
                            ),
                            SizedBox(width: 5),
                            Text('Browse shortcuts', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        onPressed: _shortcutsProvider.activeShortcuts.length > 0
                            ? () {
                                Navigator.of(context).pop();
                                _openShortcutsDialog();
                                _customURLController.text = "";
                              }
                            : null),
                    SizedBox(height: 5),
                    ElevatedButton(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        //mainAxisAlignment: MainAxisAlign,
                        children: [
                          Image.asset(
                            'images/icons/heart_add.png',
                            width: 20,
                            color: Colors.white,
                          ),
                          SizedBox(width: 8),
                          Text('Save as shortcut', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _openCustomShortcutDialog(_pageTitle, _currentUrl);
                        _customURLController.text = "";
                      },
                    ),
                    if (widget.inAppWebview != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: ElevatedButton(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            //mainAxisAlignment: MainAxisAlign,
                            children: [
                              Icon(Icons.search, size: 20),
                              SizedBox(width: 8),
                              Text('Find in page', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            widget.callFindInPage();
                          },
                        ),
                      ),
                    if (widget.inAppWebview != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Column(
                          children: [
                            Divider(),
                            Row(
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
                                      Text("Show terminal", style: TextStyle(fontSize: 12)),
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
                    SizedBox(height: 8),
                    TextButton(
                      child: Text("Close"),
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
                backgroundColor: _themeProvider.secondBackground,
                child: CircleAvatar(
                  backgroundColor: _themeProvider.secondBackground,
                  radius: 22,
                  child: SizedBox(
                    height: 25,
                    width: 25,
                    child: Image.asset(
                      "images/icons/pda_icon.png",
                      width: 18,
                      height: 18,
                      color: _themeProvider.mainText,
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
    if (_customURLKey.currentState.validate()) {
      String url = _customURLController.text.replaceAll(" ", "");
      if (!url.toLowerCase().contains("https://") && !url.toLowerCase().contains("http://")) {
        url = 'https://' + url;
      } else if (url.toLowerCase().contains("http://")) {
        url = url.replaceAll("http://", "https://");
      }

      if (widget.inAppWebview != null) {
        widget.inAppWebview.loadUrl(
          urlRequest: URLRequest(
            url: Uri.parse(url),
          ),
        );
      } else {
        widget.stockWebView.loadUrl(
          _customURLController.text,
        );
      }

      _customURLController.text = "";
      Navigator.of(context).pop();
    }
  }

  Future<void> _openCustomShortcutDialog(String title, String url) {
    _customShortcutNameController.text = title;
    _customShortcutURLController.text = url;
    return showDialog<void>(
      context: context,
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
                      color: _themeProvider.secondBackground,
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
                        Flexible(
                          child: Text(
                            "Add a name and URL for your custom shortcut. Note: "
                            "ensure URL begins with 'https://'",
                            style: TextStyle(fontSize: 12, color: _themeProvider.mainText),
                          ),
                        ),
                        SizedBox(height: 15),
                        Form(
                          key: _customShortcutNameKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min, // To make the card compact
                            children: <Widget>[
                              TextFormField(
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _themeProvider.mainText,
                                ),
                                textCapitalization: TextCapitalization.sentences,
                                controller: _customShortcutNameController,
                                maxLength: 30,
                                maxLines: 1,
                                decoration: InputDecoration(
                                  counterText: "",
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  labelText: 'Name',
                                ),
                                validator: (value) {
                                  if (value.replaceAll(' ', '').isEmpty) {
                                    return "Cannot be empty!";
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 15),
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
                                        color: _themeProvider.mainText,
                                      ),
                                      controller: _customShortcutURLController,
                                      maxLength: 300,
                                      maxLines: 1,
                                      decoration: InputDecoration(
                                        counterText: "",
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                        labelText: 'URL',
                                      ),
                                      validator: (value) {
                                        if (value.replaceAll(' ', '').isEmpty) {
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
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            TextButton(
                              child: Text("Add"),
                              onPressed: () {
                                if (!_customShortcutURLKey.currentState.validate()) {
                                  return;
                                }
                                if (!_customShortcutNameKey.currentState.validate()) {
                                  return;
                                }

                                var customShortcut = Shortcut()
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
                              child: Text("Close"),
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
                    backgroundColor: _themeProvider.secondBackground,
                    child: CircleAvatar(
                      backgroundColor: _themeProvider.secondBackground,
                      radius: 22,
                      child: SizedBox(
                        height: 25,
                        width: 25,
                        child: Image.asset(
                          "images/icons/pda_icon.png",
                          width: 18,
                          height: 18,
                          color: _themeProvider.mainText,
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
