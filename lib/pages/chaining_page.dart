// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:provider/provider.dart';

// Project imports:
import 'package:torn_pda/pages/chaining/attacks_page.dart';
import 'package:torn_pda/pages/chaining/tac/tac_page.dart';
import 'package:torn_pda/pages/chaining/targets_page.dart';
import 'package:torn_pda/providers/chain_status_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

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
  PageController _bottomNavPageController;

  bool _tacEnabled = true;

  @override
  void initState() {
    super.initState();
    _chainStatusProvider = Provider.of<ChainStatusProvider>(context, listen: false);
    _preferencesLoaded = _restorePreferences();
    _bottomNavPageController = PageController(
      initialPage: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return Scaffold(
      body: FutureBuilder(
        future: _preferencesLoaded,
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return PageView(
              physics: NeverScrollableScrollPhysics(),
              controller: _bottomNavPageController,
              children: <Widget>[
                TargetsPage(
                  userKey: _myCurrentKey,
                  tabCallback: _tabCallback,
                ),
                AttacksPage(
                  userKey: _myCurrentKey,
                ),
                TacPage(
                  userKey: _myCurrentKey,
                ),
              ],
            );
          } else {
            return CircularProgressIndicator();
          }
        },
      ),
      bottomNavigationBar: _bottomNavBar(),
    );
  }

  @override
  Future dispose() async {
    _bottomNavPageController.dispose();
    super.dispose();
  }

  Widget _bottomNavBar() {
    return FutureBuilder(
      future: _preferencesLoaded,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Container(
            height: 40,
            decoration: new BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.grey,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Expanded(
                  child: Container(
                    color: _currentPage == 0 ? _themeProvider.navSelected : Colors.transparent,
                    child: IconButton(
                      icon: Image.asset(
                        'images/icons/ic_target_account_black_48dp.png',
                        color: _themeProvider.mainText,
                      ),
                      onPressed: () {
                        _onSelectedPage(page: 0);
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    color: _currentPage == 1 ? _themeProvider.navSelected : Colors.transparent,
                    child: IconButton(
                      icon: Icon(
                        Icons.person,
                        color: _themeProvider.mainText,
                      ),
                      onPressed: () {
                        _onSelectedPage(page: 1);
                      },
                    ),
                  ),
                ),
                if (_tacEnabled)
                  Expanded(
                    child: Container(
                      color: _currentPage == 2 ? _themeProvider.navSelected : Colors.transparent,
                      child: TextButton(
                        child: Text('TAC',
                            style: TextStyle(
                              color: _themeProvider.mainText,
                            )),
                        onPressed: () {
                          _onSelectedPage(page: 2);
                        },
                      ),
                    ),
                  )
                else
                  SizedBox.shrink(),
              ],
            ),
          );
        } else {
          return SizedBox.shrink();
        }
      },
    );
  }

  void _onSelectedPage({int page}) {
    _bottomNavPageController.animateToPage(
      page,
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    setState(() {
      _currentPage = page;
    });
  }

  void _tabCallback(bool tacEnabled) {
    setState(() {
      _tacEnabled = tacEnabled;
    });
  }

  Future _restorePreferences() async {
    var userDetails = Provider.of<UserDetailsProvider>(context, listen: false);
    _myCurrentKey = userDetails.basic.userApiKey;
    _tacEnabled = await Prefs().getTACEnabled();

    if (!_chainStatusProvider.initialised) {
      await _chainStatusProvider.loadPreferences(apiKey: _myCurrentKey);
    }
  }
}
