import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/changelog.dart';
import 'package:torn_pda/widgets/webview_generic.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatefulWidget {
  @override
  _AboutPageState createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  SettingsProvider _settingsProvider;
  ThemeProvider _themeProvider;

  @override
  Widget build(BuildContext context) {
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return Scaffold(
      drawer: Drawer(),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.dehaze),
          onPressed: () {
            final ScaffoldState scaffoldState =
                context.findRootAncestorStateOfType();
            scaffoldState.openDrawer();
          },
        ),
        title: Text('About'),
      ),
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
                                fontWeight: FontWeight.bold,
                                color: Colors.blue),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () async {
                                // Only option for external browser, or
                                // Discord won't open
                                var url = 'https://discord.gg/vyP23kJ';
                                if (await canLaunch(url)) {
                                  await launch(url, forceSafariVC: false);
                                }
                              }),
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
                                var browserType =
                                    _settingsProvider.currentBrowser;
                                switch (browserType) {
                                  case BrowserSetting.app:
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (BuildContext context) =>
                                            TornWebViewGeneric(
                                          genericTitle: 'Forums',
                                          webViewType: WebViewType.custom,
                                          customUrl:
                                              'https://www.torn.com/forums.php#/p=threads&f=67&t=16163503&b=0&a=0',
                                        ),
                                      ),
                                    );
                                    break;
                                  case BrowserSetting.external:
                                    var url =
                                        'https://www.torn.com/forums.php#/p=threads&f=67&t=16163503&b=0&a=0';
                                    if (await canLaunch(url)) {
                                      await launch(url, forceSafariVC: false);
                                    }
                                    break;
                                }
                              },
                          ),
                          TextSpan(
                              text: ' and stay updated about the app or '
                                  'suggest new features'),
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
                                var browserType =
                                    _settingsProvider.currentBrowser;
                                switch (browserType) {
                                  case BrowserSetting.app:
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (BuildContext context) =>
                                            TornWebViewGeneric(
                                          genericTitle: 'Github',
                                          webViewType: WebViewType.custom,
                                          customUrl:
                                              'https://github.com/Manuito83/torn-pda',
                                        ),
                                      ),
                                    );
                                    break;
                                  case BrowserSetting.external:
                                    var url =
                                        'https://github.com/Manuito83/torn-pda';
                                    if (await canLaunch(url)) {
                                      await launch(url, forceSafariVC: false);
                                    }
                                    break;
                                }
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
                    child: Text('If you\'d like to show your appreciation and '
                        'can afford a donation in game, '
                        'it would be certainly appreciated!'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 15, 30, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Flexible(
                    child: Text(
                      "Changelog: ",
                    ),
                  ),
                  Flexible(
                    child: InkWell(
                      child: Text(
                        "click here to view",
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
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 10, 30, 0),
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
                                var browserType =
                                    _settingsProvider.currentBrowser;
                                switch (browserType) {
                                  case BrowserSetting.app:
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (BuildContext context) =>
                                            TornWebViewGeneric(
                                          profileId: '2225097',
                                          profileName: 'Manuito',
                                          webViewType: WebViewType.profile,
                                        ),
                                      ),
                                    );
                                    break;
                                  case BrowserSetting.external:
                                    var url =
                                        'https://www.torn.com/profiles.php?XID=2225097';
                                    if (await canLaunch(url)) {
                                      await launch(url, forceSafariVC: false);
                                    }
                                    break;
                                }
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
                                var browserType =
                                    _settingsProvider.currentBrowser;
                                switch (browserType) {
                                  case BrowserSetting.app:
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (BuildContext context) =>
                                            TornWebViewGeneric(
                                          profileId: '2184575',
                                          profileName: 'Phillip_J_Fry',
                                          webViewType: WebViewType.profile,
                                        ),
                                      ),
                                    );
                                    break;
                                  case BrowserSetting.external:
                                    var url =
                                        'https://www.torn.com/profiles.php?XID=2184575';
                                    if (await canLaunch(url)) {
                                      await launch(url, forceSafariVC: false);
                                    }
                                    break;
                                }
                              },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
}
