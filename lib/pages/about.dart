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
import 'package:torn_pda/widgets/webviews/pda_browser_icon.dart';
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

  @override
  void initState() {
    super.initState();
    analytics.setCurrentScreen(screenName: 'about');

    routeWithDrawer = true;
    routeName = "about";
  }

  @override
  Widget build(BuildContext context) {
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: _themeProvider.canvas,
      drawer: const Drawer(),
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
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
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
                                child: const Text(
                                  'Torn Forums',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
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
                                child: const Text(
                                  'Github',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
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
                                child: const Text(
                                  'donation in game',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
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
                            child: const Text(
                              "show",
                              style: TextStyle(
                                decoration: TextDecoration.underline,
                                color: Colors.blue,
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
                          text: 'Developer: ',
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
                                child: const Text(
                                  'Manuito',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
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
                                child: const Text(
                                  'Phillip_J_Fry',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
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
                                child: const Text(
                                  'VioletStorm',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
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
                                child: const Text(
                                  'Kivou',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
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
                                child: const Text(
                                  'IceBlueFire',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                                ),
                              ),
                            ),
                            TextSpan(
                              text: ' for the resources and support offered by YATA and Torn Stats respectively.',
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
                                child: const Text(
                                  'Knoxby',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
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
      //brightness: Brightness.dark, // For downgrade to Flutter 2.2.3
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      leadingWidth: context.read<WebViewProvider>().webViewSplitActive ? 50 : 80,
      leading: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              final ScaffoldState? scaffoldState = context.findRootAncestorStateOfType();
              if (scaffoldState != null) {
                if (context.read<WebViewProvider>().webViewSplitActive &&
                    context.read<WebViewProvider>().splitScreenPosition == WebViewSplitPosition.left) {
                  scaffoldState.openEndDrawer();
                } else {
                  scaffoldState.openDrawer();
                }
              }
            },
          ),
          if (!context.read<WebViewProvider>().webViewSplitActive) PdaBrowserIcon()
        ],
      ),
      title: const Text('About'),
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
