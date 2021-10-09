// Flutter imports:
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

// Package imports:
import 'package:provider/provider.dart';

// Project imports:
import 'package:torn_pda/pages/chaining/attacks_page.dart';
//import 'package:torn_pda/pages/chaining/tac/tac_page.dart';
import 'package:torn_pda/pages/chaining/targets_page.dart';
import 'package:torn_pda/pages/chaining/war_page.dart';
import 'package:torn_pda/providers/chain_status_provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/providers/war_controller.dart';
import 'package:torn_pda/widgets/animated_indexedstack.dart';
import 'package:torn_pda/widgets/bounce_tabbar.dart';

import '../main.dart';
//import 'package:torn_pda/utils/shared_prefs.dart';

class ChainingPage extends StatefulWidget {
  @override
  _ChainingPageState createState() => _ChainingPageState();
}

class _ChainingPageState extends State<ChainingPage> {
  String _myCurrentKey = '';

  ThemeProvider _themeProvider;
  ChainStatusProvider _chainStatusProvider;
  Future _preferencesLoaded;
  SettingsProvider _settingsProvider;

  int _currentPage = 0;
  bool _isAppBarTop;

  //bool _tacEnabled = true;

  @override
  void initState() {
    super.initState();
    _chainStatusProvider = Provider.of<ChainStatusProvider>(context, listen: false);
    _isAppBarTop = context.read<SettingsProvider>().appBarTop;
    _preferencesLoaded = _restorePreferences();
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final bool isThemeLight = _themeProvider.currentTheme == AppTheme.light || false;
    final double padding = _isAppBarTop ? 0 : kBottomNavigationBarHeight;
    return Scaffold(
      extendBody: true,
      body: FutureBuilder(
        future: _preferencesLoaded,
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                Padding(
                  padding: EdgeInsets.only(top: padding),
                  child: AnimatedIndexedStack(
                    index: _currentPage,
                    duration: 200,
                    children: <Widget>[
                      TargetsPage(
                        userKey: _myCurrentKey,
                        // Used to add or remove TAC tab
                        //tabCallback: _tabCallback,
                      ),
                      AttacksPage(
                        userKey: _myCurrentKey,
                      ),
                      WarPage(
                        userKey: _myCurrentKey,
                      ),
                      /*
                      TacPage(
                        userKey: _myCurrentKey,
                      ),
                      */
                    ],
                  ),
                ),
                if (!_isAppBarTop)
                  BounceTabBar(
                    onTabChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                      handleSectionChange(index);
                    },
                    backgroundColor: isThemeLight ? Colors.blueGrey : Colors.grey[900],
                    items: [
                      Image.asset(
                        'images/icons/ic_target_account_black_48dp.png',
                        color: isThemeLight ? Colors.white : _themeProvider.mainText,
                        width: 28,
                      ),
                      Icon(
                        Icons.people,
                        color: isThemeLight ? Colors.white : _themeProvider.mainText,
                      ),
                      Icon(
                        MdiIcons.wall,
                        color: isThemeLight ? Colors.white : _themeProvider.mainText,
                      ),
                      // Text('TAC', style: TextStyle(color: _themeProvider.mainText))
                    ],
                    locationTop: true,
                  ),
              ],
            );
          } else {
            return const CircularProgressIndicator();
          }
        },
      ),
      bottomNavigationBar: _isAppBarTop
          ? BounceTabBar(
              onTabChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
                handleSectionChange(index);
              },
              backgroundColor: isThemeLight ? Colors.blueGrey : Colors.grey[900],
              items: [
                Image.asset(
                  'images/icons/ic_target_account_black_48dp.png',
                  color: isThemeLight ? Colors.white : _themeProvider.mainText,
                  width: 28,
                ),
                Icon(
                  Icons.people,
                  color: isThemeLight ? Colors.white : _themeProvider.mainText,
                ),
                Image.asset(
                  'images/icons/faction.png',
                  width: 18,
                  color: isThemeLight ? Colors.white : _themeProvider.mainText,
                ),
                // Text('TAC', style: TextStyle(color: _themeProvider.mainText))
              ],
              locationTop: false,
            )
          : const SizedBox.shrink(),
    );
  }

  /*
  void _tabCallback(bool tacEnabled) {
    setState(() {
      _tacEnabled = tacEnabled;
    });
  }
  */

  Future _restorePreferences() async {
    final userDetails = Provider.of<UserDetailsProvider>(context, listen: false);
    _myCurrentKey = userDetails.basic.userApiKey;
    //_tacEnabled = await Prefs().getTACEnabled();

    if (!_chainStatusProvider.initialised) {
      await _chainStatusProvider.loadPreferences(apiKey: _myCurrentKey);
    }
  }

  // IndexedStack loads all sections at the same time, but we need to load certain things when we
  // enter the section
  void handleSectionChange(int index) {
    switch (index) {
      case 0:
        analytics.logEvent(name: 'section_changed', parameters: {'section': 'targets'});
        break;
      case 1:
        analytics.logEvent(name: 'section_changed', parameters: {'section': 'attacks'});
        break;
      case 2:
        analytics.logEvent(name: 'section_changed', parameters: {'section': 'war'});
        if (!_settingsProvider.showCases.contains("war_add_faction")) {
          Get.put(WarController()).launchShowCaseAddFaction();
          _settingsProvider.addShowCase = "war_add_faction";
        }
        break;
    }
  }
}
