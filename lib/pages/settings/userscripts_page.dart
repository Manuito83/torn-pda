// Flutter imports:
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:easy_rich_text/easy_rich_text.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

// Project imports:
import 'package:torn_pda/models/userscript_model.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/userscripts_provider.dart';
import 'package:torn_pda/widgets/settings/userscripts_add_dialog.dart';
import 'package:torn_pda/widgets/settings/userscripts_revert_dialog.dart';
import 'package:torn_pda/widgets/webviews/webview_dialog.dart';

class UserScriptsPage extends StatefulWidget {
  @override
  _UserScriptsPageState createState() => _UserScriptsPageState();
}

class _UserScriptsPageState extends State<UserScriptsPage> {
  ThemeProvider _themeProvider;
  SettingsProvider _settingsProvider;
  UserScriptsProvider _userScriptsProvider;

  bool _firstTimeNotAccepted = false;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _userScriptsProvider = Provider.of<UserScriptsProvider>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_userScriptsProvider.scriptsFirstTime) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return _firstTimeDialog();
          },
        );
        if (_firstTimeNotAccepted) {
          _willPopCallback();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return WillPopScope(
      onWillPop: _willPopCallback,
      child: Container(
        color: _themeProvider.currentTheme == AppTheme.light
            ? MediaQuery.of(context).orientation == Orientation.portrait
                ? Colors.blueGrey
                : Colors.grey[900]
            : Colors.grey[900],
        child: SafeArea(
          top: _settingsProvider.appBarTop ? false : true,
          bottom: true,
          child: Scaffold(
            appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
            bottomNavigationBar: !_settingsProvider.appBarTop
                ? SizedBox(
                    height: AppBar().preferredSize.height,
                    child: buildAppBar(),
                  )
                : null,
            body: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => FocusScope.of(context).requestFocus(new FocusNode()),
              child: Column(
                children: <Widget>[
                  SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ButtonTheme(
                        minWidth: 1.0,
                        child: ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all<Color>(_themeProvider.background),
                            shape: MaterialStateProperty.all<OutlinedBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                                side: BorderSide(width: 2, color: Colors.blueGrey),
                              ),
                            ),
                          ),
                          child: Icon(
                            Icons.add,
                            size: 20,
                            color: _themeProvider.mainText,
                          ),
                          onPressed: () {
                            _showAddDialog(context);
                          },
                        ),
                      ),
                      SizedBox(width: 15),
                      ButtonTheme(
                        minWidth: 1.0,
                        child: ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all<Color>(_themeProvider.background),
                            shape: MaterialStateProperty.all<OutlinedBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                                side: BorderSide(
                                  width: 2,
                                  color: Colors.blueGrey,
                                ),
                              ),
                            ),
                          ),
                          child: Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: _themeProvider.mainText,
                          ),
                          onPressed: () {
                            _openWipeDialog();
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Preexisting scripts might require modifications to work with Torn PDA. '
                      'Please ensure that you use scripts responsibly and '
                      'understand the hazards. Tap the exclamation mark for more information.',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Flexible(
                    child: Consumer<UserScriptsProvider>(
                      builder: (context, settingsProvider, child) => scriptsCards(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  ListView scriptsCards() {
    var scriptList = <Widget>[];
    for (var script in _userScriptsProvider.userScriptList) {
      scriptList.add(
        Card(
          key: UniqueKey(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      SizedBox(
                        height: 20,
                        width: 60,
                        child: Switch(
                          value: script.enabled,
                          activeTrackColor: Colors.green[100],
                          activeColor: Colors.green,
                          inactiveThumbColor: Colors.red[100],
                          onChanged: (value) {
                            _userScriptsProvider.changeUserScriptEnabled(script, value);
                          },
                        ),
                      ),
                      SizedBox(width: 10),
                      Flexible(child: Text(script.name)),
                    ],
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      child: Icon(Icons.edit),
                      onTap: () {
                        return showDialog<void>(
                          context: context,
                          barrierDismissible: false, // user must tap button!
                          builder: (BuildContext context) {
                            return UserScriptsAddDialog(
                              editExisting: true,
                              editScript: script,
                            );
                          },
                        );
                      },
                    ),
                    SizedBox(width: 15),
                    GestureDetector(
                      child: Icon(
                        Icons.delete_outlined,
                        color: Colors.red[300],
                      ),
                      onTap: () async {
                        _openDeleteSingleDialog(script);
                      },
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView(
      children: scriptList,
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      brightness: Brightness.dark,
      toolbarHeight: 50,
      title: Text('User scripts'),
      leading: new IconButton(
        icon: new Icon(Icons.arrow_back),
        onPressed: () {
          _willPopCallback();
        },
      ),
      actions: [
        IconButton(
          icon: Icon(
            MdiIcons.backupRestore,
          ),
          onPressed: () async {
            _openRestoreDialog();
          },
        ),
        IconButton(
          icon: Icon(
            MdiIcons.alertDecagramOutline,
            color: Colors.orange[300],
          ),
          onPressed: () async {
            await showDialog(
              context: context,
              builder: (BuildContext context) {
                return _disclaimerDialog();
              },
            );
          },
        ),
      ],
    );
  }

  Future<void> _showAddDialog(BuildContext _) {
    return showDialog<void>(
      context: _,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return UserScriptsAddDialog(editExisting: false);
      },
    );
  }

  Future<void> _openWipeDialog() {
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // To make the card compact
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            "CAUTION",
                            style: TextStyle(fontSize: 13, color: Colors.red),
                          ),
                        ),
                        SizedBox(height: 10),
                        Flexible(
                          child: Text(
                            "This will remove all user scripts!",
                            style: TextStyle(fontSize: 12, color: _themeProvider.mainText),
                          ),
                        ),
                        SizedBox(height: 10),
                        Flexible(
                          child: Text(
                            "Are you sure?",
                            style: TextStyle(fontSize: 12, color: _themeProvider.mainText),
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            TextButton(
                              child: Text("Do it!"),
                              onPressed: () {
                                _userScriptsProvider.wipe();
                                Navigator.of(context).pop();
                              },
                            ),
                            TextButton(
                              child: Text("Oh no!"),
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
                    backgroundColor: _themeProvider.background,
                    child: CircleAvatar(
                      backgroundColor: _themeProvider.background,
                      radius: 22,
                      child: SizedBox(
                        height: 34,
                        width: 34,
                        child: Icon(Icons.delete_forever_outlined),
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

  Future<void> _openDeleteSingleDialog(UserScriptModel script) {
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // To make the card compact
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            "Remove ${script.name}?",
                            style: TextStyle(fontSize: 12, color: _themeProvider.mainText),
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            TextButton(
                              child: Text("Do it!"),
                              onPressed: () {
                                _userScriptsProvider.removeUserScript(script);
                                Navigator.of(context).pop();
                              },
                            ),
                            TextButton(
                              child: Text("Oh no!"),
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
                    backgroundColor: _themeProvider.background,
                    child: CircleAvatar(
                      backgroundColor: _themeProvider.background,
                      radius: 22,
                      child: SizedBox(
                        height: 34,
                        width: 34,
                        child: Icon(Icons.delete_forever_outlined),
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

  Future<void> _openRestoreDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return UserScriptsRevertDialog();
      },
    );
  }

  _disclaimerDialog() {
    return AlertDialog(
      title: Text("DISCLAIMER"),
      content: Scrollbar(
        isAlwaysShown: true,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "User scripts are small programs written in JavaScript that enhance the browser's "
                  "functionalities. Be careful when using them and ensure that you understand the code "
                  "and what the script accomplishes; otherwise, ensure they come from a reliable "
                  "source and have been checked by someone you trust.\n\n"
                  "As in any other browser, user scripts might be used maliciously to get information "
                  "from your Torn account or other websites you visit.",
                  style: TextStyle(
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 25),
                Text(
                  "TIPS",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                EasyRichText(
                  "Join our Discord server if you need help or are willing to contribute with new userscripts ideas or working code. "
                  "There is a list of tested userscripts in our GitHub repository.",
                  patternList: [
                    EasyRichTextPattern(
                      targetString: 'Discord server',
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        color: Colors.blue[400],
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () async {
                          var url = 'https://discord.gg/vyP23kJ';
                          if (await canLaunch(url)) {
                            await launch(url, forceSafariVC: false);
                          }
                        },
                    ),
                    EasyRichTextPattern(
                      targetString: 'list of tested userscripts',
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        color: Colors.blue[400],
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () async {
                          await openBrowserDialog(
                            context,
                            'https://github.com/Manuito83/torn-pda/tree/master/userscripts',
                            callBack: null,
                          );
                        },
                    ),
                  ],
                  defaultStyle: TextStyle(
                    fontSize: 13,
                    color: _themeProvider.mainText,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "Activation URLs starting with '@match' in the header are supported; however, wildcards (*) will be ignored. "
                  "Instead, you can use full URLs or just a part of them (e.g. 'profile.php' or 'torn.com').",
                  style: TextStyle(
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "You can use the text '###PDA-APIKEY###' in a script instead of your real API key. "
                  "Torn PDA will replace it with your API key in runtime.",
                  style: TextStyle(
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "User scripts are isolated from one another on runtime and executed inside anonymous functions. "
                  "There is no need for you to adapt them this way.",
                  style: TextStyle(
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 25),
                Text(
                  "TROUBLESHOOTING",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  "Preexisting Torn user scripts (e.g. for Greasemonkey) may require some "
                  "code changes to work with Torn PDA if external libraries were used.\n\n"
                  "If a script does not work as intended after changing its code in Torn PDA, please "
                  "try resetting your browser cache in the advanced browser settings section.",
                  style: TextStyle(
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton(
            child: Text("Understood"),
            onPressed: () {
              Navigator.of(context).pop('exit');
            },
          ),
        ),
      ],
    );
  }

  _firstTimeDialog() {
    return WillPopScope(
      onWillPop: () async => false,
      child: AlertDialog(
        title: Text("CAUTION"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Be careful when using user scripts and ensure that you understand the code "
                "and what it accomplishes; otherwise, ensure they come from a reliable "
                "source and have been checked by someone you trust.\n\n"
                "As in any other browser, user scripts might be used maliciously to get information "
                "from your Torn account or other websites you visit.",
                style: TextStyle(
                  fontSize: 13,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Please, read the disclaimer by pressing the warning icon in the app bar for "
                "more information.",
                style: TextStyle(
                  fontSize: 13,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Do you understand the risk?",
                style: TextStyle(
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              child: Text("Yes, I promise!"),
              onPressed: () {
                _userScriptsProvider.changeScriptsFirstTime(false);
                Navigator.of(context).pop('exit');
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              child: Text("What?!"),
              onPressed: () {
                _firstTimeNotAccepted = true;
                BotToast.showText(
                  text: 'Returning...!',
                  textStyle: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  contentColor: Colors.orange[800],
                  duration: Duration(seconds: 2),
                  contentPadding: EdgeInsets.all(10),
                );
                Navigator.of(context).pop('exit');
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _willPopCallback() async {
    Navigator.of(context).pop();
    return true;
  }
}
