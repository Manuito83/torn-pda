// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Package imports:
import 'package:provider/provider.dart';

// Project imports:
import 'package:torn_pda/pages/chaining/attacks_page.dart';
import 'package:torn_pda/pages/chaining/retals_page.dart';
//import 'package:torn_pda/pages/chaining/tac/tac_page.dart';
import 'package:torn_pda/pages/chaining/targets_page.dart';
import 'package:torn_pda/pages/chaining/war_page.dart';
import 'package:torn_pda/providers/chain_status_provider.dart';
import 'package:torn_pda/providers/retals_controller.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/providers/war_controller.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/animated_indexedstack.dart';
import 'package:torn_pda/widgets/bounce_tabbar.dart';

import '../main.dart';
//import 'package:torn_pda/utils/shared_prefs.dart';

class ChainingPage extends StatefulWidget {
  final bool retalsRedirection;

  ChainingPage({@required this.retalsRedirection});

  @override
  _ChainingPageState createState() => _ChainingPageState();
}

class _ChainingPageState extends State<ChainingPage> {
  ThemeProvider _themeProvider;
  ChainStatusProvider _chainStatusProvider;
  Future _preferencesLoaded;
  SettingsProvider _settingsProvider;
  UserDetailsProvider _userProvider;

  int _currentPage = 0;
  bool _isAppBarTop;

  //bool _tacEnabled = true;

  @override
  void initState() {
    super.initState();
    _chainStatusProvider = Provider.of<ChainStatusProvider>(context, listen: false);
    _isAppBarTop = context.read<SettingsProvider>().appBarTop;
    _userProvider = context.read<UserDetailsProvider>();
    _preferencesLoaded = _restorePreferences();
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final bool isThemeLight = _themeProvider.currentTheme == AppTheme.light || false;
    final double padding = _isAppBarTop ? 0 : kBottomNavigationBarHeight;
    return Scaffold(
      backgroundColor: _themeProvider.canvas,
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
                          // Used to add or remove TAC tab
                          //tabCallback: _tabCallback,
                          ),
                      AttacksPage(),
                      WarPage(),
                      if (_userProvider.basic.faction.factionId != 0) RetalsPage(),
                      /*
                      TacPage(
                        userKey: _myCurrentKey,
                      ),
                      */
                    ],
                    errorCallback: null,
                  ),
                ),
                if (!_isAppBarTop)
                  FutureBuilder(
                    future: _preferencesLoaded,
                    builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return BounceTabBar(
                          onTabChanged: (index) {
                            setState(() {
                              _currentPage = index;
                            });
                            handleSectionChange(index);
                          },
                          themeProvider: _themeProvider,
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
                              width: 17,
                              color: isThemeLight ? Colors.white : _themeProvider.mainText,
                            ),
                            if (_userProvider.basic.faction.factionId != 0)
                              FaIcon(
                                FontAwesomeIcons.personWalkingArrowLoopLeft,
                                color: isThemeLight ? Colors.white : _themeProvider.mainText,
                                size: 18,
                              ),
                            // Text('TAC', style: TextStyle(color: _themeProvider.mainText))
                          ],
                          locationTop: true,
                        );
                      } else {
                        return SizedBox.shrink();
                      }
                    },
                  ),
              ],
            );
          } else {
            return const CircularProgressIndicator();
          }
        },
      ),
      bottomNavigationBar: _isAppBarTop
          ? FutureBuilder(
              future: _preferencesLoaded,
              builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return BounceTabBar(
                    initialIndex: _currentPage,
                    onTabChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                      handleSectionChange(index);
                    },
                    themeProvider: _themeProvider,
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
                        width: 17,
                        color: isThemeLight ? Colors.white : _themeProvider.mainText,
                      ),
                      if (_userProvider.basic.faction.factionId != 0)
                        FaIcon(
                          FontAwesomeIcons.personWalkingArrowLoopLeft,
                          color: isThemeLight ? Colors.white : _themeProvider.mainText,
                          size: 18,
                        ),
                      // Text('TAC', style: TextStyle(color: _themeProvider.mainText))
                    ],
                    locationTop: false,
                  );
                } else {
                  return SizedBox.shrink();
                }
              },
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
    //_tacEnabled = await Prefs().getTACEnabled();

    if (!_chainStatusProvider.initialised) {
      await _chainStatusProvider.loadPreferences();
    }

    if (widget.retalsRedirection && _userProvider.basic.faction.factionId != 0) {
      _currentPage = 3;
    } else {
      _currentPage = await Prefs().getChainingCurrentPage();
    }

    switch (_currentPage) {
      case 0:
        analytics.setCurrentScreen(screenName: 'targets');
        break;
      case 1:
        analytics.setCurrentScreen(screenName: 'attacks');
        break;
      case 2:
        analytics.setCurrentScreen(screenName: 'war');
        if (!_settingsProvider.showCases.contains("war")) {
          Get.put(WarController()).launchShowCaseAddFaction();
          _settingsProvider.addShowCase = "war";
        }
        break;
      case 3:
        if (_userProvider.basic.faction.factionId != 0) {
          analytics.setCurrentScreen(screenName: 'retals');
          Get.put(RetalsController()).retrieveRetals(context);
        }
        break;
    }
  }

  // IndexedStack loads all sections at the same time, but we need to load certain things when we
  // enter the section
  void handleSectionChange(int index) {
    switch (index) {
      case 0:
        analytics.setCurrentScreen(screenName: 'targets');
        Prefs().setChainingCurrentPage(_currentPage);
        break;
      case 1:
        analytics.setCurrentScreen(screenName: 'attacks');
        Prefs().setChainingCurrentPage(_currentPage);
        break;
      case 2:
        analytics.setCurrentScreen(screenName: 'war');
        if (!_settingsProvider.showCases.contains("war")) {
          Get.put(WarController()).launchShowCaseAddFaction();
          _settingsProvider.addShowCase = "war";
        }
        Prefs().setChainingCurrentPage(_currentPage);
        break;
      case 3:
        analytics.setCurrentScreen(screenName: 'retals');
        Prefs().setChainingCurrentPage(_currentPage);
        Get.put(RetalsController()).retrieveRetals(context);
        break;
    }
  }
}
