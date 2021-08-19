// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:provider/provider.dart';

// Project imports:
import 'package:torn_pda/pages/chaining/attacks_page.dart';
//import 'package:torn_pda/pages/chaining/tac/tac_page.dart';
import 'package:torn_pda/pages/chaining/targets_page.dart';
import 'package:torn_pda/providers/chain_status_provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/widgets/animated_indexedstack.dart';
import 'package:torn_pda/widgets/bounce_tabbar.dart';
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
    bool isThemeLight = _themeProvider.currentTheme == AppTheme.light ? true : false;
    double padding = _isAppBarTop ? 0 : kBottomNavigationBarHeight;
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
                    initialIndex: 0,
                    onTabChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    backgroundColor: isThemeLight ? Colors.blueGrey : Colors.grey[900],
                    items: [
                      Image.asset(
                        'images/icons/ic_target_account_black_48dp.png',
                        color: isThemeLight ? Colors.white : _themeProvider.mainText,
                        width: 28,
                      ),
                      Icon(
                        Icons.person,
                        color: isThemeLight ? Colors.white : _themeProvider.mainText,
                      ),
                      // Text('TAC', style: TextStyle(color: _themeProvider.mainText))
                    ],
                    locationTop: true,
                  ),
              ],
            );
          } else {
            return CircularProgressIndicator();
          }
        },
      ),
      bottomNavigationBar: _isAppBarTop
          ? BounceTabBar(
              initialIndex: 0,
              onTabChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              backgroundColor: isThemeLight ? Colors.blueGrey : Colors.grey[900],
              items: [
                Image.asset(
                  'images/icons/ic_target_account_black_48dp.png',
                  color: isThemeLight ? Colors.white : _themeProvider.mainText,
                  width: 28,
                ),
                Icon(
                  Icons.person,
                  color: isThemeLight ? Colors.white : _themeProvider.mainText,
                ),
                // Text('TAC', style: TextStyle(color: _themeProvider.mainText))
              ],
              locationTop: false,
            )
          : SizedBox.shrink(),
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
    var userDetails = Provider.of<UserDetailsProvider>(context, listen: false);
    _myCurrentKey = userDetails.basic.userApiKey;
    //_tacEnabled = await Prefs().getTACEnabled();

    if (!_chainStatusProvider.initialised) {
      await _chainStatusProvider.loadPreferences(apiKey: _myCurrentKey);
    }
  }
}
