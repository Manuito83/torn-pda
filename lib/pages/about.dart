// Flutter imports:
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
// Package imports:
import 'package:provider/provider.dart';
import 'package:torn_pda/drawer.dart';
import 'package:torn_pda/main.dart';
// Project imports:
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/changelog.dart';
import 'package:torn_pda/widgets/pda_browser_icon.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatefulWidget {
  final String uid;

  const AboutPage({required this.uid});

  @override
  AboutPageState createState() => AboutPageState();
}

class AboutPageState extends State<AboutPage> {
  late SettingsProvider _settingsProvider;
  late ThemeProvider _themeProvider;
  late WebViewProvider _webViewProvider;

  @override
  void initState() {
    super.initState();
    analytics?.logScreenView(screenName: 'about');

    routeWithDrawer = true;
    routeName = "about";
  }

  @override
  Widget build(BuildContext context) {
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    _webViewProvider = Provider.of<WebViewProvider>(context);

    return Scaffold(
      backgroundColor: _themeProvider.canvas,
      drawer: !_webViewProvider.splitScreenAndBrowserLeft() ? const Drawer() : null,
      appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
      bottomNavigationBar: !_settingsProvider.appBarTop
          ? SizedBox(
              height: AppBar().preferredSize.height,
              child: buildAppBar(),
            )
          : null,
      body: Container(
        color: _themeProvider.canvas,
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 50, 30, 10),
                child: Image(
                  image: AssetImage('images/icons/torn_pda.png'),
                  height: 100,
                  fit: BoxFit.fill,
                ),
              ),
              const Text(
                "Torn PDA",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 25, 30, 10),
                child: Text(
                  "Torn PDA has been developed as an assistant for "
                  "players of TORN City. It was conceived to enhance the "
                  "experience of playing Torn from a mobile platform.",
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 10, 30, 20),
                child: Row(
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
                padding: const EdgeInsets.fromLTRB(40, 0, 30, 10),
                child: Row(
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
                                  decoration: _themeProvider.accesibilityNoTextColors ? TextDecoration.underline : null,
                                  fontWeight: FontWeight.bold,
                                  color: _themeProvider.getTextColor(Colors.blue)),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () async {
                                  const url = 'https://discord.gg/vyP23kJ';
                                  if (await canLaunchUrl(Uri.parse(url))) {
                                    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                                  }
                                },
                            ),
                            const TextSpan(
                              text: ' and offer suggestions for new '
                                  'features or report bugs you find!',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(40, 0, 30, 10),
                child: Row(
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: Icon(Icons.forum),
                    ),
                    Flexible(
                      child: RichText(
                        text: TextSpan(
                          text: 'Give a thumbs up in the official ',
                          style: DefaultTextStyle.of(context).style,
                          children: <InlineSpan>[
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () {
                                  const url = 'https://www.torn.com/forums.php#/p=threads&f=67&t=16163503&b=0&a=0';
                                  context.read<WebViewProvider>().openBrowserPreference(
                                        context: context,
                                        url: url,
                                        browserTapType: BrowserTapType.short,
                                      );
                                },
                                onLongPress: () {
                                  const url = 'https://www.torn.com/forums.php#/p=threads&f=67&t=16163503&b=0&a=0';
                                  context.read<WebViewProvider>().openBrowserPreference(
                                        context: context,
                                        url: url,
                                        browserTapType: BrowserTapType.long,
                                      );
                                },
                                child: Text(
                                  'Torn Forums',
                                  style: TextStyle(
                                      decoration:
                                          _themeProvider.accesibilityNoTextColors ? TextDecoration.underline : null,
                                      fontWeight: FontWeight.bold,
                                      color: _themeProvider.getTextColor(Colors.blue)),
                                ),
                              ),
                            ),
                            const TextSpan(
                              text: ' and stay updated about the app or '
                                  'suggest new features.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(40, 0, 30, 10),
                child: Row(
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
                          children: <InlineSpan>[
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () {
                                  const url = 'https://github.com/Manuito83/torn-pda';
                                  context.read<WebViewProvider>().openBrowserPreference(
                                        context: context,
                                        url: url,
                                        browserTapType: BrowserTapType.short,
                                      );
                                },
                                onLongPress: () {
                                  const url = 'https://github.com/Manuito83/torn-pda';
                                  context.read<WebViewProvider>().openBrowserPreference(
                                        context: context,
                                        url: url,
                                        browserTapType: BrowserTapType.long,
                                      );
                                },
                                child: Text(
                                  'Github',
                                  style: TextStyle(
                                      decoration:
                                          _themeProvider.accesibilityNoTextColors ? TextDecoration.underline : null,
                                      fontWeight: FontWeight.bold,
                                      color: _themeProvider.getTextColor(Colors.blue)),
                                ),
                              ),
                            ),
                            const TextSpan(
                              text: '. It is a nice way to practice your '
                                  'coding skills in Flutter!',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(40, 0, 30, 10),
                child: Row(
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: SizedBox(
                        height: 24,
                        width: 24,
                        child: Icon(Icons.attach_money),
                      ),
                    ),
                    Flexible(
                      child: RichText(
                        text: TextSpan(
                          text: "If you'd like to show your appreciation and "
                              'can afford a ',
                          style: DefaultTextStyle.of(context).style,
                          children: <InlineSpan>[
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () {
                                  const url = 'https://www.torn.com/trade.php#step=start&userID=2225097';
                                  context.read<WebViewProvider>().openBrowserPreference(
                                        context: context,
                                        url: url,
                                        browserTapType: BrowserTapType.short,
                                      );
                                },
                                onLongPress: () {
                                  const url = 'https://www.torn.com/trade.php#step=start&userID=2225097';
                                  context.read<WebViewProvider>().openBrowserPreference(
                                        context: context,
                                        url: url,
                                        browserTapType: BrowserTapType.long,
                                      );
                                },
                                child: Text(
                                  'donation in game',
                                  style: TextStyle(
                                      decoration:
                                          _themeProvider.accesibilityNoTextColors ? TextDecoration.underline : null,
                                      fontWeight: FontWeight.bold,
                                      color: _themeProvider.getTextColor(Colors.blue)),
                                ),
                              ),
                            ),
                            const TextSpan(text: ' it would be certainly appreciated!'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 15, 30, 0),
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Flexible(
                          flex: 2,
                          child: Text(
                            "Changelog (major versions): ",
                          ),
                        ),
                        Flexible(
                          child: InkWell(
                            onTap: _showChangeLogDialog,
                            child: Text(
                              "show",
                              style: TextStyle(
                                decoration: TextDecoration.underline,
                                color: _themeProvider.getTextColor(Colors.blue),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 15),
                      child: Row(
                        children: <Widget>[
                          Flexible(
                            flex: 2,
                            child: Text(
                              "Your version: v$appVersion (${Platform.isAndroid ? androidCompilation : iosCompilation})",
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.uid.isNotEmpty)
                      Row(
                        children: <Widget>[
                          Flexible(
                            flex: 2,
                            child: Text(
                              "UID: ${widget.uid.substring(widget.uid.length - 4)}",
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 15, 30, 0),
                  child: Text('Contributors:'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(30, 15, 30, 10),
                child: Row(
                  children: <Widget>[
                    Flexible(
                      child: RichText(
                        text: TextSpan(
                          text: 'Developers: ',
                          style: DefaultTextStyle.of(context).style,
                          children: <InlineSpan>[
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () {
                                  const url = 'https://www.torn.com/profiles.php?XID=2225097';
                                  context.read<WebViewProvider>().openBrowserPreference(
                                        context: context,
                                        url: url,
                                        browserTapType: BrowserTapType.short,
                                      );
                                },
                                onLongPress: () {
                                  const url = 'https://www.torn.com/profiles.php?XID=2225097';
                                  context.read<WebViewProvider>().openBrowserPreference(
                                        context: context,
                                        url: url,
                                        browserTapType: BrowserTapType.long,
                                      );
                                },
                                child: Text(
                                  'Manuito',
                                  style: TextStyle(
                                      decoration:
                                          _themeProvider.accesibilityNoTextColors ? TextDecoration.underline : null,
                                      fontWeight: FontWeight.bold,
                                      color: _themeProvider.getTextColor(Colors.blue)),
                                ),
                              ),
                            ),
                            const TextSpan(
                              text: ', ',
                            ),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () {
                                  const url = 'https://www.torn.com/profiles.php?XID=2190604';
                                  context.read<WebViewProvider>().openBrowserPreference(
                                        context: context,
                                        url: url,
                                        browserTapType: BrowserTapType.short,
                                      );
                                },
                                onLongPress: () {
                                  const url = 'https://www.torn.com/profiles.php?XID=2190604';
                                  context.read<WebViewProvider>().openBrowserPreference(
                                        context: context,
                                        url: url,
                                        browserTapType: BrowserTapType.long,
                                      );
                                },
                                child: Text(
                                  'Kwack',
                                  style: TextStyle(
                                      decoration:
                                          _themeProvider.accesibilityNoTextColors ? TextDecoration.underline : null,
                                      fontWeight: FontWeight.bold,
                                      color: _themeProvider.getTextColor(Colors.blue)),
                                ),
                              ),
                            ),
                            const TextSpan(
                              text: ', ',
                            ),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () {
                                  const url = 'https://www.torn.com/profiles.php?XID=2402357';
                                  context.read<WebViewProvider>().openBrowserPreference(
                                        context: context,
                                        url: url,
                                        browserTapType: BrowserTapType.short,
                                      );
                                },
                                onLongPress: () {
                                  const url = 'https://www.torn.com/profiles.php?XID=2402357';
                                  context.read<WebViewProvider>().openBrowserPreference(
                                        context: context,
                                        url: url,
                                        browserTapType: BrowserTapType.long,
                                      );
                                },
                                child: Text(
                                  'Mavri',
                                  style: TextStyle(
                                      decoration:
                                          _themeProvider.accesibilityNoTextColors ? TextDecoration.underline : null,
                                      fontWeight: FontWeight.bold,
                                      color: _themeProvider.getTextColor(Colors.blue)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(30, 0, 30, 10),
                child: Row(
                  children: <Widget>[
                    Flexible(
                      child: RichText(
                        text: TextSpan(
                          text: 'Discord: ',
                          style: DefaultTextStyle.of(context).style,
                          children: <InlineSpan>[
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () {
                                  const url = 'https://www.torn.com/profiles.php?XID=2184575';
                                  context.read<WebViewProvider>().openBrowserPreference(
                                        context: context,
                                        url: url,
                                        browserTapType: BrowserTapType.short,
                                      );
                                },
                                onLongPress: () {
                                  const url = 'https://www.torn.com/profiles.php?XID=2184575';
                                  context.read<WebViewProvider>().openBrowserPreference(
                                        context: context,
                                        url: url,
                                        browserTapType: BrowserTapType.long,
                                      );
                                },
                                child: Text(
                                  'Phillip_J_Fry',
                                  style: TextStyle(
                                      decoration:
                                          _themeProvider.accesibilityNoTextColors ? TextDecoration.underline : null,
                                      fontWeight: FontWeight.bold,
                                      color: _themeProvider.getTextColor(Colors.blue)),
                                ),
                              ),
                            ),
                            const TextSpan(
                              text: ', ',
                            ),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () {
                                  const url = 'https://www.torn.com/profiles.php?XID=2233317';
                                  context.read<WebViewProvider>().openBrowserPreference(
                                        context: context,
                                        url: url,
                                        browserTapType: BrowserTapType.short,
                                      );
                                },
                                onLongPress: () {
                                  const url = 'https://www.torn.com/profiles.php?XID=2233317';
                                  context.read<WebViewProvider>().openBrowserPreference(
                                        context: context,
                                        url: url,
                                        browserTapType: BrowserTapType.long,
                                      );
                                },
                                child: Text(
                                  'VioletStorm',
                                  style: TextStyle(
                                      decoration:
                                          _themeProvider.accesibilityNoTextColors ? TextDecoration.underline : null,
                                      fontWeight: FontWeight.bold,
                                      color: _themeProvider.getTextColor(Colors.blue)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(30, 0, 30, 10),
                child: Row(
                  children: <Widget>[
                    Flexible(
                      child: RichText(
                        text: TextSpan(
                          text: 'Special mention to ',
                          style: DefaultTextStyle.of(context).style,
                          children: <InlineSpan>[
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () {
                                  const url = 'https://www.torn.com/profiles.php?XID=2000607';
                                  context.read<WebViewProvider>().openBrowserPreference(
                                        context: context,
                                        url: url,
                                        browserTapType: BrowserTapType.short,
                                      );
                                },
                                onLongPress: () {
                                  const url = 'https://www.torn.com/profiles.php?XID=2000607';
                                  context.read<WebViewProvider>().openBrowserPreference(
                                        context: context,
                                        url: url,
                                        browserTapType: BrowserTapType.long,
                                      );
                                },
                                child: Text(
                                  'Kivou',
                                  style: TextStyle(
                                      decoration:
                                          _themeProvider.accesibilityNoTextColors ? TextDecoration.underline : null,
                                      fontWeight: FontWeight.bold,
                                      color: _themeProvider.getTextColor(Colors.blue)),
                                ),
                              ),
                            ),
                            TextSpan(
                              text: ' and ',
                              style: DefaultTextStyle.of(context).style,
                            ),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () {
                                  const url = 'https://www.torn.com/profiles.php?XID=776';
                                  context.read<WebViewProvider>().openBrowserPreference(
                                        context: context,
                                        url: url,
                                        browserTapType: BrowserTapType.short,
                                      );
                                },
                                onLongPress: () {
                                  const url = 'https://www.torn.com/profiles.php?XID=776';
                                  context.read<WebViewProvider>().openBrowserPreference(
                                        context: context,
                                        url: url,
                                        browserTapType: BrowserTapType.long,
                                      );
                                },
                                child: Text(
                                  'IceBlueFire',
                                  style: TextStyle(
                                      decoration:
                                          _themeProvider.accesibilityNoTextColors ? TextDecoration.underline : null,
                                      fontWeight: FontWeight.bold,
                                      color: _themeProvider.getTextColor(Colors.blue)),
                                ),
                              ),
                            ),
                            TextSpan(
                              text: ' for the resources and support offered by YATA and Torn Stats respectively. '
                                  'Also to the team at ',
                              style: DefaultTextStyle.of(context).style,
                            ),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () {
                                  const url = 'https://www.prombot.co.uk/home';
                                  context.read<WebViewProvider>().openBrowserPreference(
                                        context: context,
                                        url: url,
                                        browserTapType: BrowserTapType.short,
                                      );
                                },
                                onLongPress: () {
                                  const url = 'https://www.prombot.co.uk/home';
                                  context.read<WebViewProvider>().openBrowserPreference(
                                        context: context,
                                        url: url,
                                        browserTapType: BrowserTapType.long,
                                      );
                                },
                                child: Text(
                                  'Prometheus',
                                  style: TextStyle(
                                      decoration:
                                          _themeProvider.accesibilityNoTextColors ? TextDecoration.underline : null,
                                      fontWeight: FontWeight.bold,
                                      color: _themeProvider.getTextColor(Colors.blue)),
                                ),
                              ),
                            ),
                            TextSpan(
                              text: ' for the help with their foreign stock database.',
                              style: DefaultTextStyle.of(context).style,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(30, 0, 30, 10),
                  child: Text('Thank you to our partners, who chose Torn PDA as their mobile '
                      'interface: YATA, Arson Warehouse, Nuke (Central Hospital) '
                      'and Universal Health Care.'),
                ),
              ),
              const Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(30, 0, 30, 10),
                  child: Text('Some scripts, concepts, and features have been '
                      'adapted from preexisting ones in tools like YATA, '
                      'Torn Tools or DocTorn.'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(30, 0, 30, 10),
                child: Row(
                  children: <Widget>[
                    Flexible(
                      child: RichText(
                        text: TextSpan(
                          text: 'The JavaScript API for cross-origin http requests (see userscripts section) has '
                              'been developed by ',
                          style: DefaultTextStyle.of(context).style,
                          children: <InlineSpan>[
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () {
                                  const url = 'https://www.torn.com/profiles.php?XID=2503189';
                                  context.read<WebViewProvider>().openBrowserPreference(
                                        context: context,
                                        url: url,
                                        browserTapType: BrowserTapType.short,
                                      );
                                },
                                onLongPress: () {
                                  const url = 'https://www.torn.com/profiles.php?XID=2503189';
                                  context.read<WebViewProvider>().openBrowserPreference(
                                        context: context,
                                        url: url,
                                        browserTapType: BrowserTapType.long,
                                      );
                                },
                                child: Text(
                                  'Knoxby',
                                  style: TextStyle(
                                      decoration:
                                          _themeProvider.accesibilityNoTextColors ? TextDecoration.underline : null,
                                      fontWeight: FontWeight.bold,
                                      color: _themeProvider.getTextColor(Colors.blue)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 15, 30, 10),
                child: Row(
                  children: <Widget>[
                    Flexible(
                      child: RichText(
                        text: TextSpan(
                          text: "See Torn PDA's ",
                          style: DefaultTextStyle.of(context).style,
                          children: <InlineSpan>[
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () {
                                  const url = 'https://info.tornpda.com/pda-privacy.html';
                                  context.read<WebViewProvider>().openBrowserPreference(
                                        context: context,
                                        url: url,
                                        browserTapType: BrowserTapType.short,
                                      );
                                },
                                onLongPress: () {
                                  const url = 'https://info.tornpda.com/pda-privacy.html';
                                  context.read<WebViewProvider>().openBrowserPreference(
                                        context: context,
                                        url: url,
                                        browserTapType: BrowserTapType.long,
                                      );
                                },
                                child: Text(
                                  'privacy policy',
                                  style: TextStyle(
                                    decoration:
                                        _themeProvider.accesibilityNoTextColors ? TextDecoration.underline : null,
                                    color: _themeProvider.getTextColor(Colors.blue),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      leadingWidth: _webViewProvider.webViewSplitActive ? 50 : 88,
      leading: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              final ScaffoldState? scaffoldState = context.findRootAncestorStateOfType();
              if (scaffoldState != null) {
                if (_webViewProvider.splitScreenAndBrowserLeft()) {
                  scaffoldState.openEndDrawer();
                } else {
                  scaffoldState.openDrawer();
                }
              }
            },
          ),
          if (!_webViewProvider.webViewSplitActive) const PdaBrowserIcon()
        ],
      ),
      title: const Text('About', style: TextStyle(color: Colors.white)),
    );
  }

  void _showChangeLogDialog() {
    showDialog(
      useRootNavigator: false,
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (context) {
        return ChangeLog();
      },
    );
  }
}
