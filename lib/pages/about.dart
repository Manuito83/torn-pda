import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/changelog.dart';
import 'package:torn_pda/widgets/webviews/webview_full.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:torn_pda/widgets/webviews/webview_dialog.dart';

import '../main.dart';

class AboutPage extends StatefulWidget {
  @override
  _AboutPageState createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  SettingsProvider _settingsProvider;
  ThemeProvider _themeProvider;

  @override
  void initState() {
    super.initState();
    analytics
        .logEvent(name: 'section_changed', parameters: {'section': 'about'});
  }

  @override
  Widget build(BuildContext context) {
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return Scaffold(
      drawer: Drawer(),
      appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
      bottomNavigationBar: !_settingsProvider.appBarTop
          ? SizedBox(
              height: AppBar().preferredSize.height,
              child: buildAppBar(),
            )
          : null,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.fromLTRB(20, 50, 30, 10),
              child: Image(
                image: AssetImage('images/icons/torn_pda.png'),
                height: 100,
                fit: BoxFit.fill,
              ),
            ),
            Text(
              "Torn PDA",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 25, 30, 10),
              child: Text(
                "Torn PDA has been developed as an assistant for "
                "players of TORN City. It was conceived to enhance the "
                "experience of playing Torn from a mobile platform.",
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 10, 30, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Flexible(
                    child: Text(
                      "Would you like to collaborate?",
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(40, 0, 30, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: Image.asset(
                        'images/icons/ic_discord_black_48dp.png',
                        color: _themeProvider.mainText,
                      ),
                    ),
                  ),
                  Flexible(
                      child: RichText(
                    text: TextSpan(
                      text: 'Join our ',
                      style: DefaultTextStyle.of(context).style,
                      children: <TextSpan>[
                        TextSpan(
                          text: 'Discord channel',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.blue),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () async {
                              _settingsProvider.useQuickBrowser
                                  ? openBrowserDialog(
                                      context, 'https://discord.gg/vyP23kJ')
                                  : _openTornBrowser(
                                      'https://discord.gg/vyP23kJ');
                            },
                        ),
                        TextSpan(
                            text: ' and offer suggestions for new '
                                'features or report bugs you find!'),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(40, 0, 30, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Icon(Icons.forum),
                  ),
                  Flexible(
                    child: RichText(
                      text: TextSpan(
                        text: 'Give a thumbs up in the official ',
                        style: DefaultTextStyle.of(context).style,
                        children: <TextSpan>[
                          TextSpan(
                            text: 'Torn Forums',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () async {
                                _settingsProvider.useQuickBrowser
                                    ? openBrowserDialog(context,
                                        'https://www.torn.com/forums.php#/p=threads&f=67&t=16163503&b=0&a=0')
                                    : _openTornBrowser(
                                        'https://www.torn.com/forums.php#/p=threads&f=67&t=16163503&b=0&a=0');
                              },
                          ),
                          TextSpan(
                              text: ' and stay updated about the app or '
                                  'suggest new features.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(40, 0, 30, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: Image.asset(
                        'images/icons/ic_github_black_48dp.png',
                        color: _themeProvider.mainText,
                      ),
                    ),
                  ),
                  Flexible(
                    child: RichText(
                      text: TextSpan(
                        text: 'Help us code new features for the app in ',
                        style: DefaultTextStyle.of(context).style,
                        children: <TextSpan>[
                          TextSpan(
                            text: 'Github',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () async {
                                _settingsProvider.useQuickBrowser
                                    ? openBrowserDialog(context,
                                        'https://github.com/Manuito83/torn-pda')
                                    : _openTornBrowser(
                                        'https://github.com/Manuito83/torn-pda');
                              },
                          ),
                          TextSpan(
                              text: '. It is a nice way to practice your '
                                  'coding skills in Flutter!'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(40, 0, 30, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: Icon(Icons.attach_money),
                    ),
                  ),
                  Flexible(
                    child: RichText(
                      text: TextSpan(
                        text: 'If you\'d like to show your appreciation and '
                            'can afford a ',
                        style: DefaultTextStyle.of(context).style,
                        children: <TextSpan>[
                          TextSpan(
                            text: 'donation in game',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () async {
                                _settingsProvider.useQuickBrowser
                                    ? openBrowserDialog(context,
                                        'https://www.torn.com/trade.php#step=start&userID=2225097')
                                    : _openTornBrowser(
                                        'https://www.torn.com/trade.php#step=start&userID=2225097');
                              },
                          ),
                          TextSpan(text: ' it would be certainly appreciated!'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 15, 30, 0),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Flexible(
                        flex: 2,
                        child: Text(
                          "Changelog (major versions): ",
                        ),
                      ),
                      Flexible(
                        child: InkWell(
                          child: Text(
                            "show",
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                              color: Colors.blue,
                            ),
                          ),
                          onTap: _showChangeLogDialog,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Flexible(
                          flex: 2,
                          child: Text(
                            "Your version: v$appVersion",
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 15, 30, 0),
                child: Text('Contributors:'),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(30, 15, 30, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Flexible(
                    child: RichText(
                      text: TextSpan(
                        text: 'Developer: ',
                        style: DefaultTextStyle.of(context).style,
                        children: <TextSpan>[
                          TextSpan(
                            text: 'Manuito [2225097]',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () async {
                                _settingsProvider.useQuickBrowser
                                    ? openBrowserDialog(context,
                                        'https://www.torn.com/profiles.php?XID=2225097')
                                    : _openTornBrowser(
                                        'https://www.torn.com/profiles.php?XID=2225097');
                              },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(30, 0, 30, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Flexible(
                    child: RichText(
                      text: TextSpan(
                        text: 'Discord: ',
                        style: DefaultTextStyle.of(context).style,
                        children: <TextSpan>[
                          TextSpan(
                            text: 'Phillip_J_Fry [2184575]',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () async {
                                _settingsProvider.useQuickBrowser
                                    ? openBrowserDialog(context,
                                        'https://www.torn.com/profiles.php?XID=2184575')
                                    : _openTornBrowser(
                                        'https://www.torn.com/profiles.php?XID=2184575');
                              },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(30, 0, 30, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Flexible(
                    child: RichText(
                      text: TextSpan(
                        text: 'Special mention to ',
                        style: DefaultTextStyle.of(context).style,
                        children: <TextSpan>[
                          TextSpan(
                            text: 'Kivou [2000607]',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () async {
                                _settingsProvider.useQuickBrowser
                                    ? openBrowserDialog(context,
                                        'https://www.torn.com/profiles.php?XID=2000607')
                                    : _openTornBrowser(
                                        'https://www.torn.com/profiles.php?XID=2000607');
                              },
                          ),
                          TextSpan(
                            text: ' for the resources offered by YATA.',
                            style: DefaultTextStyle.of(context).style,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: EdgeInsets.fromLTRB(30, 0, 30, 10),
                child: Text('Some scripts, concepts and features have been '
                    'adapted from preexisting ones in tools like YATA, '
                    'Torn Tools or DocTorn.'),
              ),
            ),
            SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      brightness: Brightness.dark,
      leading: IconButton(
        icon: Icon(Icons.dehaze),
        onPressed: () {
          final ScaffoldState scaffoldState =
              context.findRootAncestorStateOfType();
          scaffoldState.openDrawer();
        },
      ),
      title: Text('About'),
    );
  }

  void _showChangeLogDialog() {
    showDialog(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (context) {
          return ChangeLog();
        });
  }

  Future _openTornBrowser(String page) async {
    var browserType = _settingsProvider.currentBrowser;

    switch (browserType) {
      case BrowserSetting.app:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext context) => WebViewFull(
              customUrl: page,
              customTitle: 'Torn',
            ),
          ),
        );
        break;
      case BrowserSetting.external:
        var url = page;
        if (await canLaunch(url)) {
          await launch(url, forceSafariVC: false);
        }
        break;
    }
  }

}
