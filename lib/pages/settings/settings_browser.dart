// Dart imports:
import 'dart:async';
import 'dart:io';

// Flutter imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

// Package imports:
import 'package:provider/provider.dart';
import 'package:torn_pda/drawer.dart';
import 'package:torn_pda/main.dart';

// Project imports:
import 'package:torn_pda/pages/settings/friendly_factions.dart';
import 'package:torn_pda/pages/settings/userscripts_page.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/providers/userscripts_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/settings/chat_highlight_word_dialog.dart';
import 'package:torn_pda/widgets/pda_browser_icon.dart';
import 'package:torn_pda/pages/settings/locked_tab_exceptions_page.dart';
import 'package:torn_pda/widgets/webviews/tabs_wipe_dialog.dart';
import 'package:torn_pda/widgets/webviews/webview_fab.dart';

class SettingsBrowserPage extends StatefulWidget {
  final UserDetailsProvider userDetailsProvider;

  const SettingsBrowserPage({required this.userDetailsProvider, super.key});

  @override
  SettingsBrowserPageState createState() => SettingsBrowserPageState();
}

class SettingsBrowserPageState extends State<SettingsBrowserPage> {
  Timer? _ticker;

  Future? _preferencesRestored;

  late bool _highlightChat;
  Color _highlightColor = const Color(0xff7ca900);

  int? _browserStyle = 0;

  late ThemeProvider _themeProvider;
  late SettingsProvider _settingsProvider;
  late UserScriptsProvider _userScriptsProvider;
  late WebViewProvider _webViewProvider;

  final List<TabsWipeTimeRange> tabsRemoveTimeRangesList = [
    TabsWipeTimeRange.oneDay,
    TabsWipeTimeRange.twoDays,
    TabsWipeTimeRange.threeDays,
    TabsWipeTimeRange.fiveDays,
    TabsWipeTimeRange.sevenDays,
    TabsWipeTimeRange.fifteenDays,
    TabsWipeTimeRange.oneMonth,
  ];

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _userScriptsProvider = Provider.of<UserScriptsProvider>(context, listen: false);

    _preferencesRestored = _restorePreferences();

    routeWithDrawer = false;
    routeName = "settings_browser";
    _settingsProvider.willPopShouldGoBackStream.stream.listen((event) {
      if (mounted && routeName == "settings_browser") _goBack();
    });
  }

  @override
  Widget build(BuildContext context) {
    _webViewProvider = Provider.of<WebViewProvider>(context, listen: true);
    _themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
      color: _themeProvider.currentTheme == AppTheme.light
          ? MediaQuery.orientationOf(context) == Orientation.portrait
              ? Colors.blueGrey
              : _themeProvider.canvas
          : _themeProvider.canvas,
      child: SafeArea(
        right: _webViewProvider.webViewSplitActive && _webViewProvider.splitScreenPosition == WebViewSplitPosition.left,
        left: _webViewProvider.webViewSplitActive && _webViewProvider.splitScreenPosition == WebViewSplitPosition.right,
        child: Scaffold(
          backgroundColor: _themeProvider.canvas,
          appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
          bottomNavigationBar: !_settingsProvider.appBarTop
              ? SizedBox(
                  height: AppBar().preferredSize.height,
                  child: buildAppBar(),
                )
              : null,
          body: Container(
            color: _themeProvider.canvas,
            child: FutureBuilder(
              future: _preferencesRestored,
              builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
                    child: SingleChildScrollView(
                      child: Column(
                        children: <Widget>[
                          const SizedBox(height: 15),
                          _general(),
                          const SizedBox(height: 15),
                          const Divider(),
                          const SizedBox(height: 15),
                          _userScripts(),
                          const SizedBox(height: 15),
                          const Divider(),
                          const SizedBox(height: 10),
                          _tabs(),
                          const SizedBox(height: 15),
                          const Divider(),
                          const SizedBox(height: 10),
                          _fab(),
                          const SizedBox(height: 15),
                          const Divider(),
                          const SizedBox(height: 10),
                          _downloads(),
                          const SizedBox(height: 15),
                          const Divider(),
                          const SizedBox(height: 10),
                          _fullScreen(),
                          const SizedBox(height: 15),
                          const Divider(),
                          const SizedBox(height: 10),
                          if (Platform.isAndroid)
                            Column(
                              children: [
                                _textScale(context),
                                const SizedBox(height: 15),
                                const Divider(),
                                const SizedBox(height: 10),
                              ],
                            ),
                          _chat(context),
                          const SizedBox(height: 15),
                          const Divider(),
                          const SizedBox(height: 10),
                          _travel(),
                          const SizedBox(height: 15),
                          const Divider(),
                          const SizedBox(height: 10),
                          _energyExpenditureWarning(),
                          const SizedBox(height: 15),
                          const Divider(),
                          const SizedBox(height: 10),
                          _travelExpenditureWarning(),
                          const SizedBox(height: 15),
                          const Divider(),
                          const SizedBox(height: 10),
                          _profile(),
                          if (Platform.isIOS)
                            Column(
                              children: [
                                const SizedBox(height: 15),
                                const Divider(),
                                const SizedBox(height: 10),
                                _linkPreview(),
                              ],
                            ),
                          Column(
                            children: [
                              const SizedBox(height: 15),
                              const Divider(),
                              const SizedBox(height: 10),
                              if (Platform.isIOS) _pinchGesture(),
                              if (Platform.isIOS) _iosDisallowOverScroll(),
                              _reverseNavigationSwipe(),
                            ],
                          ),
                          const SizedBox(height: 15),
                          const Divider(),
                          const SizedBox(height: 10),
                          _maintenance(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  );
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Column _profile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'PLAYER PROFILES',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text("Extra player information"),
                  Switch(
                    value: _settingsProvider.extraPlayerInformation,
                    onChanged: (value) {
                      setState(() {
                        _settingsProvider.changeExtraPlayerInformation = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Add additional player information when visiting a profile or attacking '
                'someone (e.g. same faction, friendly faction, friends) and estimated stats',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            /*
            if (_settingsProvider.extraPlayerInformation)
              Column(
                children: [
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        const Text(
                          "Show players' stats",
                        ),
                        _profileStatsDropdown(),
                      ],
                    ),
                  ),
                  


                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            "If 'all stats' is selected, you will be shown either spied stats (supported by YATA and Torn Stats) or estimated stats "
                            "(which might be inaccurate) if the former can't be found. Alternatively, select only spied stats or hide all stats entirely.",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              */
            if (_settingsProvider.extraPlayerInformation)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        const Text(
                          "Friendly factions",
                        ),
                        IconButton(
                          icon: const Icon(Icons.keyboard_arrow_right_outlined),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (BuildContext context) => FriendlyFactionsPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'You will see a note if you are visiting the profile of a '
                      "friendly faction's player, or a warning if you are about to attack",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            if (_settingsProvider.extraPlayerInformation)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        const Text("Show networth"),
                        Switch(
                          value: _settingsProvider.extraPlayerNetworth,
                          onChanged: (value) {
                            setState(() {
                              _settingsProvider.changeExtraPlayerNetworth = value;
                            });
                          },
                          activeTrackColor: Colors.lightGreenAccent,
                          activeColor: Colors.green,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'If enabled, this will show an additional line with the networth of the '
                      'player you are visiting',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Flexible(child: const Text("Mini-profile name tap opens new tab")),
                  Switch(
                    value: _settingsProvider.hitInMiniProfileOpensNewTab,
                    onChanged: (value) {
                      setState(() {
                        _settingsProvider.hitInMiniProfileOpensNewTab = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'If enabled, tapping a player name in a mini-profile window will open a new tab, instead of loading '
                'the profile in the same window',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            if (_settingsProvider.hitInMiniProfileOpensNewTab)
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(30, 0, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Flexible(
                          child: Row(
                            children: [
                              Icon(Icons.arrow_forward_ios_outlined, size: 16),
                              SizedBox(width: 5),
                              Flexible(child: const Text("Automatically change to new tab")),
                            ],
                          ),
                        ),
                        Switch(
                          value: _settingsProvider.hitInMiniProfileOpensNewTabAndChangeTab,
                          onChanged: (value) {
                            setState(() {
                              _settingsProvider.hitInMiniProfileOpensNewTabAndChangeTab = value;
                            });
                          },
                          activeTrackColor: Colors.lightGreenAccent,
                          activeColor: Colors.green,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'By using this switch you can select if the browser should automatically change to the newly generated '
                      'tab after tapping a player\'s name in a mini-profile. By setting it to off, you can open several '
                      'tabs in a row from different mini-profiles.',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Column _userScripts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'USER SCRIPTS',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text("Enable custom user scripts"),
                  Switch(
                    value: _userScriptsProvider.userScriptsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _userScriptsProvider.setUserScriptsEnabled = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'You can load custom user scripts in the browser (this feature does not currently '
                'work when using the browser for chaining)',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            if (_userScriptsProvider.userScriptsEnabled)
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        const Text("Notify for Script Updates"),
                        Switch(
                          value: _userScriptsProvider.userScriptsNotifyUpdates,
                          onChanged: (value) {
                            setState(() {
                              _userScriptsProvider.setUserScriptsNotifyUpdates = value;
                            });
                          },
                          activeTrackColor: Colors.lightGreenAccent,
                          activeColor: Colors.green,
                        ),
                      ],
                    ),
                  )
                ],
              ),
            if (_userScriptsProvider.userScriptsEnabled)
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        const Text(
                          "Manage scripts",
                        ),
                        IconButton(
                          icon: Icon(MdiIcons.script),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (BuildContext context) => UserScriptsPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Column _linkPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'LINKS PREVIEW',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text("Allow links preview"),
                  Switch(
                    value: _settingsProvider.iosAllowLinkPreview,
                    onChanged: (value) {
                      setState(() {
                        _settingsProvider.changeIosAllowLinkPreview = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Allow browser to open an iOS native preview windows when '
                'long-pressing a link (only iOS 9+)',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Column _pinchGesture() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'GESTURES',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text("Zoom in/out pinch gestures"),
              Switch(
                value: _settingsProvider.iosBrowserPinch,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.setIosBrowserPinch = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Column _iosDisallowOverScroll() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text("Disallow overscroll"),
              Switch(
                value: _settingsProvider.iosDisallowOverscroll,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.setIosDisallowOverscroll = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Certain iOS versions (e.g.: iOS 16) might have issues with Torn overs-scrolling horizontally. '
            'By using this option you might get rid of such behavior. NOTE: this will restrict pull-to-refresh '
            'to work only from swipes at the top part of the browser.',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Column _reverseNavigationSwipe() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text("Reverse navigation swipe"),
              Switch(
                value: _settingsProvider.browserReverseNavitagtionSwipe,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.browserReverseNavigationSwipe = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'By default, swiping left-to-right in the page title navigates backwards, and right-to-left navigates '
            ' forwards. Enable this option to reverse the swipe direction',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Column _maintenance() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'MAINTENANCE',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text("Cache enabled"),
              Switch(
                value: Platform.isWindows
                    ? true
                    : _settingsProvider.webviewCacheEnabledRemoteConfig == "user"
                        ? _settingsProvider.webviewCacheEnabled
                        : _settingsProvider.webviewCacheEnabledRemoteConfig == "on"
                            ? true
                            : false,
                onChanged: Platform.isWindows
                    ? null
                    : _settingsProvider.webviewCacheEnabledRemoteConfig != "user"
                        ? null
                        : (value) {
                            setState(() {
                              _settingsProvider.webviewCacheEnabled = value;
                            });
                          },
                activeTrackColor: Platform.isWindows
                    ? Colors.grey[700]
                    : _settingsProvider.webviewCacheEnabledRemoteConfig == "user"
                        ? Colors.lightGreenAccent
                        : Colors.grey[700],
                activeColor: Platform.isWindows
                    ? Colors.grey[700]
                    : _settingsProvider.webviewCacheEnabledRemoteConfig == "user"
                        ? Colors.green
                        : Colors.grey[700],
                inactiveThumbColor: Platform.isWindows
                    ? Colors.grey[800]
                    : _settingsProvider.webviewCacheEnabledRemoteConfig == "user"
                        ? null
                        : Colors.grey[800],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Platform.isWindows
              ? Text(
                  "Cache is enabled from PDA and can't be changed right now",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                )
              : _settingsProvider.webviewCacheEnabledRemoteConfig == "user"
                  ? Text(
                      "Enable webview cache to improve performance (recommended). Disabling this might be useful if "
                      "you experience issues with Torn's website cache, such as images loading incorrectly, increased "
                      "app cached data, chat issues, etc. NOTE: this will only take effect after you restart the app.",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  : _settingsProvider.webviewCacheEnabledRemoteConfig == "on"
                      ? Text(
                          "Cache is enabled from PDA and can't be changed right now",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      : Text(
                          "Cache is disabled from PDA and can't be changed right now",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text("Browser cache"),
              ElevatedButton(
                child: const Text("Clear"),
                onPressed: () async {
                  _webViewProvider.clearCacheAndTabs();

                  BotToast.showText(
                    text: "Browser cache and tabs have been reset!",
                    textStyle: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    contentColor: Colors.grey[600]!,
                    duration: const Duration(seconds: 3),
                    contentPadding: const EdgeInsets.all(10),
                  );
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "Note: this will clear your browser's cache and current tabs. It can be "
            'useful in case of errors (sections not loading correctly, etc.). '
            "You'll be logged-out from Torn and all other sites",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text("Restore session cookie"),
              Switch(
                value: _settingsProvider.restoreSessionCookie,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.restoreSessionCookie = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Text(
            'Enable this option if you are getting logged out from Torn consistently; '
            'Torn PDA will try to reestablish your session ID when the browser opens',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Column _travel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'TRAVEL',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text("Remove airplane"),
              Switch(
                value: _settingsProvider.removeAirplane,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.changeRemoveAirplane = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  'Removes airplane and cloud animation when traveling',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text("Remove quick return button"),
              Switch(
                value: _settingsProvider.removeTravelQuickReturnButton,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.removeTravelQuickReturnButton = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  "By default, when abroad, you'll see a home icon button that you can "
                  "double-tap to initiate your travel back to Torn. You can optionally disable "
                  "it by using this option",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Column _energyExpenditureWarning() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                'GYM ENERGY EXPENDITURE WARNING',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text("Warn about chains"),
              Switch(
                value: _settingsProvider.warnAboutChains,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.changeWarnAboutChains = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Text(
            "If active, you'll get a message and a chain icon to the side of "
            'the energy bar, so that you avoid spending energy in the gym or hunting'
            'if you are unaware that your faction is chaining',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text("Warn about stacking"),
              Switch(
                value: _settingsProvider.warnAboutExcessEnergy,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.changeWarnAboutExcessEnergy = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Text(
            "If active, you'll get a message if your open a browser to the gym or go hunting"
            'and your energy is AT OR ABOVE your selected threshold, in case you forgot that '
            'you are stacking',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        if (_settingsProvider.warnAboutExcessEnergy)
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text(
                      "Threshold",
                      style: TextStyle(
                        fontSize: 12,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          _settingsProvider.warnAboutExcessEnergyThreshold.toString(),
                          style: const TextStyle(
                            fontSize: 12,
                          ),
                        ),
                        Slider(
                          min: 200,
                          max: 1000,
                          divisions: 16,
                          value: _settingsProvider.warnAboutExcessEnergyThreshold.toDouble(),
                          onChanged: (double value) {
                            setState(() {
                              _settingsProvider.changeWarnAboutExcessEnergyThreshold = value.floor();
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Column _travelExpenditureWarning() {
    final currentEnergyMax = widget.userDetailsProvider.basic?.energy?.maximum ?? -1;
    final currentNerveMax = widget.userDetailsProvider.basic?.nerve?.maximum ?? -1;
    final currentLifeMax = widget.userDetailsProvider.basic?.life?.maximum ?? -1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                'TRAVEL EXPENDITURE WARNING',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text("Energy excess warning"),
              Switch(
                value: _settingsProvider.travelEnergyExcessWarning,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.travelEnergyExcessWarning = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Text(
            "If enabled, you'll get a warning when you access the Travel Agency with your Energy Bar between a certain "
            "threshold to avoid a possible waste of energy during your trip (i.e.: you might want to use it in the "
            "gym or similar before boarding). Values above max can be avoided if you don't want the warning to trigger "
            "while you are stacking.",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        if (_settingsProvider.travelEnergyExcessWarning)
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 25),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text(
                      "Range",
                      style: TextStyle(
                        fontSize: 12,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          _settingsProvider.travelEnergyRangeWarningThreshold.end >= 110
                              ? "> ${_settingsProvider.travelEnergyRangeWarningThreshold.start.round()}%"
                              : "${_settingsProvider.travelEnergyRangeWarningThreshold.start.round()}% to ${_settingsProvider.travelEnergyRangeWarningThreshold.end.round()}%",
                          style: const TextStyle(
                            fontSize: 12,
                          ),
                        ),
                        RangeSlider(
                          min: 0,
                          max: 110,
                          divisions: 11,
                          values: _settingsProvider.travelEnergyRangeWarningThreshold,
                          labels: RangeLabels(
                            _buildRangeLabel(
                              _settingsProvider.travelEnergyRangeWarningThreshold.start,
                              currentEnergyMax,
                              "E",
                            ),
                            _buildRangeLabel(
                              _settingsProvider.travelEnergyRangeWarningThreshold.end,
                              currentEnergyMax,
                              "E",
                            ),
                          ),
                          onChanged: (RangeValues values) {
                            setState(() {
                              double startValue = values.start.roundToDouble();
                              double endValue = values.end.roundToDouble();

                              if (endValue - startValue >= 10) {
                                _settingsProvider.travelEnergyRangeWarningThreshold = RangeValues(startValue, endValue);
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text("Nerve excess warning"),
              Switch(
                value: _settingsProvider.travelNerveExcessWarning,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.travelNerveExcessWarning = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Text(
            "If enabled, you'll get a warning when you access the Travel Agency with your Nerve Bar above a certain "
            "threshold to avoid a possible waste of nerve during your trip (i.e.: you might want to do some crimes "
            "or similar before boarding)",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        if (_settingsProvider.travelNerveExcessWarning)
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 25),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text(
                      "Threshold",
                      style: TextStyle(
                        fontSize: 12,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          _settingsProvider.travelNerveExcessWarningThreshold >= 110
                              ? "> max"
                              : "${(_settingsProvider.travelNerveExcessWarningThreshold ~/ 10 * 10)}%",
                          style: const TextStyle(
                            fontSize: 12,
                          ),
                        ),
                        Slider(
                          min: 0,
                          max: 110,
                          divisions: 11,
                          value: _settingsProvider.travelNerveExcessWarningThreshold.toDouble(),
                          label: _buildSingleLabel(
                              _settingsProvider.travelNerveExcessWarningThreshold.toDouble(), currentNerveMax, "N"),
                          onChanged: (double value) {
                            setState(() {
                              _settingsProvider.travelNerveExcessWarningThreshold = (value.round() ~/ 10 * 10);
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text("Life excess warning"),
              Switch(
                value: _settingsProvider.travelLifeExcessWarning,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.travelLifeExcessWarning = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Text(
            "If enabled, you'll get a warning when you access the Travel Agency with your Life Bar above a certain "
            "threshold to avoid a possible waste of life during your trip (i.e.: you might want to fill some blood "
            "bags or similar before boarding)",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        if (_settingsProvider.travelLifeExcessWarning)
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 25),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text(
                      "Threshold",
                      style: TextStyle(
                        fontSize: 12,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          _settingsProvider.travelLifeExcessWarningThreshold >= 110
                              ? "> max"
                              : "${(_settingsProvider.travelLifeExcessWarningThreshold ~/ 10 * 10)}%",
                          style: const TextStyle(
                            fontSize: 12,
                          ),
                        ),
                        Slider(
                          min: 0,
                          max: 110,
                          divisions: 11,
                          value: _settingsProvider.travelLifeExcessWarningThreshold.toDouble(),
                          label: _buildSingleLabel(
                              _settingsProvider.travelLifeExcessWarningThreshold.toDouble(), currentLifeMax, "L"),
                          onChanged: (double value) {
                            setState(() {
                              _settingsProvider.travelLifeExcessWarningThreshold = (value.round() ~/ 10 * 10);
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text("Drug cooldown warning"),
              Switch(
                value: _settingsProvider.travelDrugCooldownWarning,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.travelDrugCooldownWarning = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Text(
            "If enabled, you'll get a warning when you access the Travel Agency with no drug cooldown time "
            ", just in case you forgot",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text("Booster cooldown warning"),
              Switch(
                value: _settingsProvider.travelBoosterCooldownWarning,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.travelBoosterCooldownWarning = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Text(
            "If enabled, you'll get a warning when you access the Travel Agency with no booster cooldown time "
            ", just in case you forgot",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  String _buildSingleLabel(double percentage, int currentMax, String type) {
    if (percentage >= 110) {
      return "> max\n> $currentMax $type";
    } else if (currentMax == -1) {
      return "${percentage.round()}%";
    } else {
      final realValue = (percentage / 100 * currentMax).round();
      return "${percentage.round()}%\n$realValue $type";
    }
  }

  String _buildRangeLabel(double percentage, int currentMax, String type) {
    if (percentage >= 110) {
      return "> max\n> $currentMax $type";
    } else if (currentMax == -1) {
      return "${percentage.round()}%";
    } else {
      final realValue = (percentage / 100 * currentMax).round();
      return "${percentage.round()}%\n$realValue $type";
    }
  }

  Column _textScale(BuildContext context) {
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'TEXT SCALE',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text("Browser text scale"),
              Row(
                children: [
                  Text(
                    _settingsProvider.androidBrowserTextScale.toString(),
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                  ),
                  Slider(
                    min: 8,
                    max: 20,
                    divisions: 12,
                    value: _settingsProvider.androidBrowserTextScale.toDouble(),
                    onChanged: (double value) {
                      setState(() {
                        _settingsProvider.changeAndroidBrowserTextScale = value.floor();
                      });
                      _webViewProvider.changeTextScale(value.floor());
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Text(
            "You can adjust the text scale in the browser to make it easier to read. Be advised that Torn might not "
            "follow this setting properly for all fonts in game, so some text might be unreadable.",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Column _chat(BuildContext context) {
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'CHAT',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text("Show chat remove icon"),
              Switch(
                value: _settingsProvider.chatRemoveEnabled,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.changeChatRemoveEnabled = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text("Highlight messages in chat"),
              Switch(
                value: _settingsProvider.highlightChat,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.changeHighlightChat = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        if (_highlightChat)
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Flexible(
                      child: Text(
                        "Select words to highlight",
                      ),
                    ),
                    ElevatedButton(
                        child: const Icon(Icons.drive_file_rename_outline_sharp),
                        onPressed: () => _showHighlightSelectorChat(context)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Flexible(
                      child: Text(
                        "Select highlight color",
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _highlightColor.withAlpha(255),
                        foregroundColor: Colors.white, // Ensures icon color is always white
                      ),
                      child: Icon(Icons.palette), // No need to set icon color explicitly
                      onPressed: () => _showColorPickerChat(context),
                    ),
                  ],
                ),
              ),
            ],
          )
        else
          const SizedBox.shrink(),
      ],
    );
  }

  Column _general() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'GENERAL',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text("Browser style"),
              _browserStyleDropdown(),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "There are three browser styles available, all sharing the same functionality. Please have a look "
            "at the Tips section for more information, or try them for yourself!",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        if (_webViewProvider.bottomBarStyleEnabled)
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text("Tabs below navigation bar"),
                    Switch(
                      value: _webViewProvider.browserBottomBarStylePlaceTabsAtBottom,
                      onChanged: (value) {
                        setState(() {
                          _webViewProvider.browserBottomBarStylePlaceTabsAtBottom = value;
                        });
                      },
                      activeTrackColor: Colors.lightGreenAccent,
                      activeColor: Colors.green,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'If enabled, browser tabs will be placed at the very bottom of the browser window (below the "close"'
                  'button and navigation controls)',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text("Show load bar"),
              Switch(
                value: _settingsProvider.loadBarBrowser,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.changeLoadBarBrowser = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text("Refresh method"),
              _refreshMethodDropdown(),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'The browser has pull to refresh functionality. '
            "However, you can get an extra refresh icon if it's useful for certain situations (e.g. "
            'jail or hospital)',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        /*
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text("Use quick browser"),
              Switch(
                value: _settingsProvider.useQuickBrowser,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.changeUseQuickBrowser = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Note: this will allow you to open the quick browser in most '
            'places by using a short tap (and long tap for full browser). '
            'This does not apply to the chaining browser and a few other '
            'specific links',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        */
      ],
    );
  }

  Column _tabs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'TABS',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
                child: Text(
                  'Tabs might increase memory and processor usage; be sure that you get familiar with how tabs work (see '
                  'the Tips section). It is highly recommended to use tabs to improve your Torn PDA experience.',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text("Use tabs in browser"),
              Switch(
                value: _settingsProvider.useTabsFullBrowser,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.changeUseTabsFullBrowser = value;
                  });
                  // Reset tabs to shown if we deactivate tabs (so that upon reactivation they show)
                  if (!value) {
                    Prefs().setHideTabs(false);
                  }
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        /*
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text("Tabs in quick browser"),
              Switch(
                value: _settingsProvider.useTabsBrowserDialog,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.changeUseTabsBrowserDialog = value;
                  });
                  // Reset tabs to shown if we deactivate tabs in both browsers (so that upon reactivation they show)
                  if (!value || !_settingsProvider.useTabsFullBrowser) {
                    Prefs().setHideTabs(false);
                  }
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        */
        if (_settingsProvider.useTabsFullBrowser)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_settingsProvider.useTabsFullBrowser)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Flexible(child: const Text("Automatically change to new tab from link")),
                          Switch(
                            value: _webViewProvider.automaticChangeToNewTabFromURL,
                            onChanged: (value) {
                              _webViewProvider.automaticChangeToNewTabFromURL = value;
                            },
                            activeTrackColor: Colors.lightGreenAccent,
                            activeColor: Colors.green,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 5),
                      child: Text(
                        "By default, when you open a new tab via the 'open in new tab' option, when long-pressing "
                        "a link, the browser will change to the newly created tab. If you disable this, the new tab "
                        "will be created but you will remain in the current page",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    // -- Unused tabs
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          const Text("Remove unused tabs"),
                          Switch(
                            value: _webViewProvider.removeUnusedTabs,
                            onChanged: (enabled) {
                              _webViewProvider.removeUnusedTabs = enabled;
                              _webViewProvider.togglePeriodicUnusedTabsRemovalRequest(enable: enabled);
                            },
                            activeTrackColor: Colors.lightGreenAccent,
                            activeColor: Colors.green,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 5),
                      child: Text(
                        'Removes unused tabs periodically (checks are performed when the app starts and then once every 24 hours)',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    if (_webViewProvider.removeUnusedTabs)
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 30, right: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Flexible(
                                  child: Row(
                                    children: [
                                      const Icon(Icons.keyboard_arrow_right_outlined),
                                      Flexible(child: Text("Include locked tabs")),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _webViewProvider.removeUnusedTabsIncludesLocked,
                                  onChanged: (value) {
                                    _webViewProvider.removeUnusedTabsIncludesLocked = value;
                                    // Ensure we update the periodic task parameters
                                    _webViewProvider.togglePeriodicUnusedTabsRemovalRequest(enable: true);
                                  },
                                  activeTrackColor: Colors.lightGreenAccent,
                                  activeColor: Colors.green,
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 30, right: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Flexible(
                                  child: Row(
                                    children: [
                                      const Icon(Icons.keyboard_arrow_right_outlined),
                                      Flexible(child: const Text("Inactive for")),
                                    ],
                                  ),
                                ),
                                DropdownButton<TabsWipeTimeRange>(
                                  value: _webViewProvider.removeUnusedTabsRangeDays,
                                  items: tabsRemoveTimeRangesList.map((TabsWipeTimeRange range) {
                                    return DropdownMenuItem<TabsWipeTimeRange>(
                                      value: range,
                                      child: Text(range.displayName),
                                    );
                                  }).toList(),
                                  onChanged: (TabsWipeTimeRange? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        _webViewProvider.removeUnusedTabsRangeDays = newValue;
                                      });
                                      // Ensure we update the periodic task parameters
                                      _webViewProvider.togglePeriodicUnusedTabsRemovalRequest(enable: true);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                    // -- Unused tabs ENDS --
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          const Text("Only load tabs when used"),
                          Switch(
                            value: _webViewProvider.onlyLoadTabsWhenUsed,
                            onChanged: (value) {
                              _webViewProvider.onlyLoadTabsWhenUsed = value;
                            },
                            activeTrackColor: Colors.lightGreenAccent,
                            activeColor: Colors.green,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 5),
                      child: Text(
                        'If active (recommended) not all tabs will load in memory upon browser initialization. Instead, '
                        'they will retrieve the web content when first used (tapped). This could add a small delay when the '
                        'tab is pressed visited the first time, but should improve the overall browser performance. '
                        'Also, tabs that have not been used for 24 hours will be deactivated to reduce memory consumption, '
                        'and will be reactivated with you switch back to them.\n\n'
                        'NOTE: in high performance devices, deactivating this option should make the browser quicker and '
                        'transitions between tabs will be more pleasant, while probably not being noticeable in term of memory usage.',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          const Text("Allow hiding tabs"),
                          Switch(
                            value: _settingsProvider.useTabsHideFeature,
                            onChanged: (value) {
                              setState(() {
                                _settingsProvider.changeUseTabsHideFeature = value;
                              });
                              // Show tabs if this feature is disabled
                              if (!value) {
                                Prefs().setHideTabs(false);
                              }
                            },
                            activeTrackColor: Colors.lightGreenAccent,
                            activeColor: Colors.green,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 5),
                      child: Text(
                        'Allow to temporarily hide tabs by swiping up/down in the title bar',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        if ((_settingsProvider.useTabsFullBrowser) && _settingsProvider.useTabsHideFeature)
          Padding(
            padding: const EdgeInsets.only(top: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 35, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      const Text("Select hide bar color"),
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(_settingsProvider.tabsHideBarColor).withAlpha(255),
                            foregroundColor: Colors.white, // Ensures icon color is always white
                          ),
                          child: Icon(Icons.palette), // No need to set icon color explicitly
                          onPressed: () => _showColorPickerTabs(context)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Choose the color of the bar that indicates that tabs are hidden',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (_settingsProvider.useTabsFullBrowser)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'TAB LOCKS',
                    style: TextStyle(fontSize: 10),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text("Show tab lock warnings"),
                    Switch(
                      value: _settingsProvider.showTabLockWarnings,
                      onChanged: (value) {
                        setState(() {
                          _settingsProvider.showTabLockWarnings = value;
                        });
                      },
                      activeTrackColor: Colors.lightGreenAccent,
                      activeColor: Colors.green,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 5),
                child: Text(
                  'If enabled, a short message with a lock icon will appear whenever the lock status of a tab is changed or '
                  'when the app is impeeding navigation or tab movement due to its lock condition. NOTE: without warning, '
                  'you will NOT be able to override navigation with full locks!',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Flexible(child: const Text("Full lock navigation opens a new tab")),
                    Switch(
                      value: _settingsProvider.fullLockNavigationAttemptOpensNewTab,
                      onChanged: (value) {
                        setState(() {
                          _settingsProvider.fullLockNavigationAttemptOpensNewTab = value;
                        });
                      },
                      activeTrackColor: Colors.lightGreenAccent,
                      activeColor: Colors.green,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 5),
                child: Text(
                  'If enabled, a navigation attempt from a tab with a full lock will open a new tab in the background '
                  '(the tab will be added but the browser will not switch to it automatically)',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        if (_settingsProvider.useTabsFullBrowser)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Flexible(child: const Text("Navigation exceptions for locked tabs")),
                    ElevatedButton(
                      child: Icon(MdiIcons.lockRemoveOutline),
                      onPressed: () async {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (BuildContext context) => LockedTabsNavigationExceptionsPage(
                              settingsProvider: _settingsProvider,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
                child: Text(
                  'By default, tabs with a full lock will not allow you to browse between different pages. However, '
                  'you can add exceptions by using this section. Make sure you review and understand how URLs need '
                  'to be configured',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Column _fab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'FLOATING ACTION BUTON',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Flexible(child: const Text("Enabled")),
              Switch(
                value: _webViewProvider.fabEnabled,
                onChanged: (value) {
                  _webViewProvider.fabEnabled = value;
                  // Reset coordinates in case something's gone wrong
                  // with height and width calculations
                  if (value) {
                    _webViewProvider.fabSavedPositionXY = [100, 100];
                  }
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 5),
          child: Text(
            "Shows a Floating Action Button while using the browser, which adds several "
            "action buttons and gestures to enhance navigation. NOTE: it is highly recommended "
            "that you read about how to use this button in the Tips section!",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        if (_webViewProvider.fabEnabled)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Flexible(child: const Text("Expand direction")),
                    _fabDirectionDropdown(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 5),
                child: Text(
                  "Dictates where to expand the option buttons when the Floating Action Button is tapped",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        if (_webViewProvider.fabEnabled)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Flexible(child: const Text("Only in fullscreen")),
                    Switch(
                      value: _webViewProvider.fabOnlyFullScreen,
                      onChanged: (value) {
                        _webViewProvider.fabOnlyFullScreen = value;
                      },
                      activeTrackColor: Colors.lightGreenAccent,
                      activeColor: Colors.green,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 5),
                child: Text(
                  "Only show the Floating Action Button when in full screen mode",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        if (_webViewProvider.fabEnabled)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Flexible(child: const Text("Number of buttons")),
                    Row(
                      children: [
                        Text(_webViewProvider.fabButtonCount.toString()),
                        Slider(
                          value: _webViewProvider.fabButtonCount.toDouble(),
                          min: FabSettings.minButtons.toDouble(),
                          max: FabSettings.maxButtons.toDouble(),
                          divisions: FabSettings.maxButtons - FabSettings.minButtons,
                          label: _webViewProvider.fabButtonCount.toString(),
                          onChanged: (value) {
                            setState(() {
                              _webViewProvider.fabButtonCount = value.toInt();
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Adjust the number of action buttons displayed when the FAB is expanded.",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              ...List.generate(_webViewProvider.fabButtonCount, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Button ${index + 1} action'),
                      DropdownButton<WebviewFabAction>(
                        value: _webViewProvider.fabButtonActions[index],
                        items: FabSettings.actions.map((action) {
                          return DropdownMenuItem(
                            value: action,
                            child: SizedBox(
                              width: 80,
                              child: Text(
                                action.fabActionName,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (newAction) {
                          if (newAction != null) {
                            setState(() {
                              _webViewProvider.updateFabButtonAction(index, newAction);
                            });
                          }
                        },
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        if (_webViewProvider.fabEnabled)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Double tap action"),
                    DropdownButton<WebviewFabAction>(
                      value: _webViewProvider.fabDoubleTapAction,
                      items: FabSettings.actions.map((action) {
                        return DropdownMenuItem(
                          value: action,
                          child: SizedBox(
                            width: 80,
                            child: Text(
                              action.fabActionName,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (action) {
                        if (action != null) {
                          _webViewProvider.updateFabDoubleTapAction(action);
                        }
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Triple tap action"),
                    DropdownButton<WebviewFabAction>(
                      value: _webViewProvider.fabTripleTapAction,
                      items: FabSettings.actions.map((action) {
                        return DropdownMenuItem(
                          value: action,
                          child: SizedBox(
                            width: 80,
                            child: Text(
                              action.fabActionName,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (action) {
                        if (action != null) {
                          _webViewProvider.updateFabTripleTapAction(action);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Column _fullScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'FULL SCREEN BEHAVIOR',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
          child: Text(
            'NOTE: full screen mode is only accessible if using tabs and through the quick menu tab!',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Flexible(child: Text("Full screen removes widgets")),
              Switch(
                value: _settingsProvider.fullScreenRemovesWidgets,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.fullScreenRemovesWidgets = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Dictates whether the full screen mode in the browser, when enabled, should also get rid of all of '
            'Torn PDA widgets',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Flexible(child: Text("Full screen removes chat")),
              Switch(
                value: _settingsProvider.fullScreenRemovesChat,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.fullScreenRemovesChat = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Dictates whether the full screen mode in the browser, when enabled, should also get rid of all of '
            'Torn chat bubbles in game',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Flexible(child: Text("Add reload button to tab bar")),
              Switch(
                value: _settingsProvider.fullScreenExtraReloadButton,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.fullScreenExtraReloadButton = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "When in full screen mode, adds an additional tab with a reload button for a quicker access",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Flexible(child: Text("Add close button to tab bar")),
              Switch(
                value: _settingsProvider.fullScreenExtraCloseButton,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.fullScreenExtraCloseButton = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "When in full screen mode, replaces the 'X' close button in the vertical menu by an additional tab for "
            "a quicker access",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 40,
              width: 50,
              child: Divider(),
            ),
          ],
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'FULL SCREEN POSITIONING',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Flexible(child: Text("Full screen extends to top")),
              Switch(
                value: _settingsProvider.fullScreenOverNotch,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.fullScreenOverNotch = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Dictates whether the full screen mode should extend all the way to the top, which might include '
            'the front-facing camera and any other sensors (notch). It will extend the view further, but certain '
            'web elements might be hidden or obscured, as might happen with corners.',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Flexible(child: Text("Full screen extends to bottom")),
              Switch(
                value: _settingsProvider.fullScreenOverBottom,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.fullScreenOverBottom = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Dictates whether the full screen mode should extend all the way to the bottom. In certain devices this '
            'might cause the tabs at the corner to be barely reachable.',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Flexible(child: Text("Full screen extends to sides")),
              Switch(
                value: _settingsProvider.fullScreenOverSides,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.fullScreenOverSides = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Dictates whether the full screen mode should extend all the way to the sides, including any possible '
            'front-facing cameras, notch, etc. Might be useful for landscape mode.',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 40,
              width: 50,
              child: Divider(),
            ),
          ],
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'FULL SCREEN INTERACTION',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
          child: Text(
            'NOTE: tabs opened in chaining mode (targets, war targets, loot NPCs, etc.) are not affected by these '
            'options, as chaining controls are needed to advance through the chain.',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Flexible(child: Text("Short tap opens full screen")),
              Switch(
                value: _settingsProvider.fullScreenByShortTap,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.fullScreenByShortTap = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "Opens the browser in full screen mode when an item in the app is short-tapped. Defaults to OFF.",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Flexible(child: Text("Long tap opens full screen")),
              Switch(
                value: _settingsProvider.fullScreenByLongTap,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.fullScreenByLongTap = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "Opens the browser in full screen mode when an item in the app is long-tapped. "
            "Defaults to ON.",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Flexible(child: Text("Short/long tap affect PDA icon")),
              Switch(
                value: _settingsProvider.fullScreenIncludesPDAButtonTap,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.fullScreenIncludesPDAButtonTap = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "By default, the PDA icon in the main pages of the app restores the browser as it was when you left it. "
            "By activating this option, the browser will change to windowed or full screen mode by adhering to "
            "your short and long tap preferences above. Defaults to OFF.",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Flexible(child: Text("Notifications open full screen")),
              Switch(
                value: _settingsProvider.fullScreenByNotificationTap,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.fullScreenByNotificationTap = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "Opens the browser in full screen mode when a notification is tapped. Defaults to OFF.",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Flexible(child: Text("Deep links open full screen")),
              Switch(
                value: _settingsProvider.fullScreenByDeepLinkTap,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.fullScreenByDeepLinkTap = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "Opens the browser in full screen mode when it has been triggered by a deep link. Defaults to OFF.",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Flexible(child: Text("Quick items open full screen")),
              Switch(
                value: _settingsProvider.fullScreenByQuickItemTap,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.fullScreenByQuickItemTap = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "Opens the browser in full screen mode when a quick item (in the app's main icon in your device) has been "
            "tapped.",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        //--
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Flexible(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("[CHAINING BROWSER]", style: TextStyle(fontSize: 11)),
                  Text("Short tap opens full screen"),
                ],
              )),
              Switch(
                value: _settingsProvider.fullScreenByShortChainingTap,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.fullScreenByShortChainingTap = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "Opens the browser in full screen mode when a target is short-tapped in the Chaining section. "
            "Defaults to OFF. Note that you can still access the chaining sequence controls by "
            "double tapping the main tab",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        //--
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Flexible(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("[CHAINING BROWSER]", style: TextStyle(fontSize: 11)),
                  Text("Long tap opens full screen"),
                ],
              )),
              Switch(
                value: _settingsProvider.fullScreenByLongChainingTap,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.fullScreenByLongChainingTap = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "Opens the browser in full screen mode when a target is long-pressed in the Chaining section. "
            "Defaults to OFF. Note that you can still access the chaining sequence controls by "
            "double tapping the main tab",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Column _downloads() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'DOWNLOADS',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text("Download action"),
              _downloadsDropdown(),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "Due to the operating system restrictions, Torn PDA can only download files to your app data folder (this "
            "is to avoid requesting unnecesary permissions). As this folder can be difficult to access in certain "
            "devices, the app can instead initiate a share request so that you can select whether to save your file "
            "locally or share it somewhere else",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  void _showColorPickerTabs(BuildContext context) async {
    showDialog(
      useRootNavigator: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a color!'),
          content: SingleChildScrollView(
            child: ColorPicker(
              color: Color(_settingsProvider.tabsHideBarColor),
              onColorChanged: (color) {
                setState(() {
                  _settingsProvider.changeTabsHideBarColor = color.value;
                });
              },
              width: 40,
              height: 40,
              borderRadius: 4,
              spacing: 5,
              runSpacing: 5,
              wheelDiameter: 155,
              heading: Text(
                'Select color',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              subheading: Text(
                'Select color shade',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              wheelSubheading: Text(
                'Selected color and its shades',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              showMaterialName: true,
              showColorName: true,
              showColorCode: true,
              copyPasteBehavior: const ColorPickerCopyPasteBehavior(
                longPressMenu: true,
              ),
              materialNameTextStyle: Theme.of(context).textTheme.bodySmall,
              colorNameTextStyle: Theme.of(context).textTheme.bodySmall,
              colorCodeTextStyle: Theme.of(context).textTheme.bodySmall,
              pickersEnabled: const <ColorPickerType, bool>{
                ColorPickerType.both: false,
                ColorPickerType.primary: true,
                ColorPickerType.accent: true,
                ColorPickerType.bw: false,
                ColorPickerType.custom: true,
                ColorPickerType.wheel: true,
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Got it'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showHighlightSelectorChat(BuildContext context) {
    showDialog(useRootNavigator: false, context: context, builder: (c) => ChatHighlightAddWordsDialog());
  }

  void _showColorPickerChat(BuildContext context) {
    var pickerColor = _highlightColor;
    showDialog(
      useRootNavigator: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a color!'),
          content: SingleChildScrollView(
            child: ColorPicker(
              color: _highlightColor,
              onColorChanged: (color) {
                _settingsProvider.changeHighlightColor = color.value;
                setState(() {
                  pickerColor = color;
                });
              },
              width: 40,
              height: 40,
              borderRadius: 4,
              spacing: 5,
              runSpacing: 5,
              wheelDiameter: 155,
              heading: Text(
                'Select color',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              subheading: Text(
                'Select color shade',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              wheelSubheading: Text(
                'Selected color and its shades',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              showMaterialName: true,
              showColorName: true,
              showColorCode: true,
              copyPasteBehavior: const ColorPickerCopyPasteBehavior(
                longPressMenu: true,
              ),
              materialNameTextStyle: Theme.of(context).textTheme.bodySmall,
              colorNameTextStyle: Theme.of(context).textTheme.bodySmall,
              colorCodeTextStyle: Theme.of(context).textTheme.bodySmall,
              pickersEnabled: const <ColorPickerType, bool>{
                ColorPickerType.both: false,
                ColorPickerType.primary: true,
                ColorPickerType.accent: true,
                ColorPickerType.bw: false,
                ColorPickerType.custom: true,
                ColorPickerType.wheel: true,
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Got it'),
              onPressed: () {
                setState(() => _highlightColor = pickerColor);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      iconTheme: IconThemeData(color: Colors.white),
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      toolbarHeight: 50,
      title: const Text('Browser settings', style: TextStyle(color: Colors.white)),
      leadingWidth: _webViewProvider.webViewSplitActive ? 50 : 88,
      leading: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              _goBack();
            },
          ),
          if (!_webViewProvider.webViewSplitActive) PdaBrowserIcon(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Widget _browserStyleDropdown() {
    return DropdownButton<int>(
      value: _browserStyle,
      items: const [
        DropdownMenuItem(
          value: 0,
          child: SizedBox(
            width: 80,
            child: Text(
              "Default",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: 1,
          child: SizedBox(
            width: 80,
            child: Text(
              "Bottom bar",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: 2,
          child: SizedBox(
            width: 80,
            child: Text(
              "Dialog",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        _browserStyle = value;

        switch (value) {
          case 0:
            analytics?.setUserProperty(name: "browser_style", value: "default");
            _webViewProvider.bottomBarStyleEnabled = false;
          case 1:
            analytics?.setUserProperty(name: "browser_style", value: "bottom_bar");
            _webViewProvider.bottomBarStyleEnabled = true;
            _webViewProvider.bottomBarStyleType = 1;
          case 2:
            analytics?.setUserProperty(name: "browser_style", value: "dialog");
            _webViewProvider.bottomBarStyleEnabled = true;
            _webViewProvider.bottomBarStyleType = 2;
        }
      },
    );
  }

  Widget _fabDirectionDropdown() {
    return DropdownButton<String>(
      value: _webViewProvider.fabDirection,
      items: const [
        DropdownMenuItem(
          value: "center",
          child: SizedBox(
            width: 70,
            child: Text(
              "Top",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "left",
          child: SizedBox(
            width: 70,
            child: Text(
              "Left",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "right",
          child: SizedBox(
            width: 70,
            child: Text(
              "Right",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _webViewProvider.fabDirection = value!;
        });
      },
    );
  }

  Widget _downloadsDropdown() {
    return DropdownButton<bool>(
      value: _settingsProvider.downloadActionShare,
      items: const [
        DropdownMenuItem(
          value: true,
          child: SizedBox(
            width: 70,
            child: Text(
              "Share",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: false,
          child: SizedBox(
            width: 70,
            child: Text(
              "Save",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _settingsProvider.downloadActionShare = value!;
        });
      },
    );
  }

  Widget _refreshMethodDropdown() {
    return DropdownButton<BrowserRefreshSetting>(
      value: _settingsProvider.browserRefreshMethod,
      items: const [
        DropdownMenuItem(
          value: BrowserRefreshSetting.icon,
          child: SizedBox(
            width: 100,
            child: Text(
              "Icon",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: BrowserRefreshSetting.pull,
          child: SizedBox(
            width: 100,
            child: Text(
              "Pull to refresh",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: BrowserRefreshSetting.both,
          child: SizedBox(
            width: 100,
            child: Text(
              "Both",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _settingsProvider.changeBrowserRefreshMethod = value;
          _webViewProvider.updatePullToRefresh(value);
        });
      },
    );
  }

  /*
  DropdownButton _profileStatsDropdown() {
    return DropdownButton<String>(
      value: _settingsProvider.profileStatsEnabled,
      items: const [
        DropdownMenuItem(
          value: "0",
          child: SizedBox(
            width: 80,
            child: Text(
              "All stats",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "2",
          child: SizedBox(
            width: 80,
            child: Text(
              "Spied only",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "1",
          child: SizedBox(
            width: 80,
            child: Text(
              "Hide",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _settingsProvider.changeProfileStatsEnabled = value;
        });
      },
    );
  }
  */

  Future _restorePreferences() async {
    final alternativeBrowser = await Prefs().getBrowserBottomBarStyleEnabled();
    final alternativeType = await Prefs().getBrowserBottomBarStyleType();
    var style = 0;
    if (alternativeBrowser) {
      style = alternativeType == 2 ? 2 : 1;
    }

    setState(() {
      _highlightChat = _settingsProvider.highlightChat;
      _highlightColor = Color(_settingsProvider.highlightColor);
      _browserStyle = style;
    });
  }

  _goBack() {
    routeWithDrawer = true;
    routeName = "settings";
    Navigator.of(context).pop();
  }
}
