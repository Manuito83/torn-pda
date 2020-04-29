import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/pages/chaining/targets_page.dart';
import 'package:torn_pda/pages/chaining/attacks_page.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class ChainingPage extends StatefulWidget {
  @override
  _ChainingPageState createState() => _ChainingPageState();
}

class _ChainingPageState extends State<ChainingPage> {
  String _myCurrentKey = '';
  Future _finishedLoadingPreferences;

  ThemeProvider _themeProvider;

  int _currentPage = 0;

  PageController _bottomNavPageController;

  @override
  void initState() {
    super.initState();
    _finishedLoadingPreferences = _restoreSharedPreferences();
    _bottomNavPageController = PageController(
      initialPage: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return Scaffold(
      body: FutureBuilder(
          future: _finishedLoadingPreferences,
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (_myCurrentKey != '') {
                return Scaffold(
                  body: PageView(
                    physics: NeverScrollableScrollPhysics(),
                    controller: _bottomNavPageController,
                    children: <Widget>[
                      TargetsPage(
                        userKey: _myCurrentKey,
                      ),
                      AttacksPage(
                        userKey: _myCurrentKey,
                      ),
                    ],
                  ),
                  bottomNavigationBar: _bottomNavBar(),
                );
              } else {
                return Scaffold(
                  drawer: new Drawer(),
                  appBar: AppBar(
                    title: Text('Chaining'),
                    leading: new IconButton(
                      icon: new Icon(Icons.menu),
                      onPressed: () {
                        final ScaffoldState scaffoldState =
                        context.findRootAncestorStateOfType();
                        scaffoldState.openDrawer();
                      },
                    ),
                  ),
                  body: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        children: <Widget>[
                          Text(
                            'Torn API Key not found!',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 30),
                            child: Text(
                              'Please go to the Settings section and configure your '
                              'Torn API Key properly.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
            } else {
              return Padding(
                padding: EdgeInsets.all(10),
                child: CircularProgressIndicator(),
              );
            }
          }),
    );
  }

  @override
  Future dispose() async {
    _bottomNavPageController.dispose();
    super.dispose();
  }

  Widget _bottomNavBar() {
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
              color: _currentPage == 0
                  ? _themeProvider.navSelected
                  : Colors.transparent,
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
              color: _currentPage == 1
                  ? _themeProvider.navSelected
                  : Colors.transparent,
              child: IconButton(
                icon: Icon(Icons.person,
                  color: _themeProvider.mainText,
                ),
                onPressed: () {
                  setState(() {
                    _onSelectedPage(page: 1);
                  });
                },
              ),
            ),
          ),
        ],
      ),
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

  Future _restoreSharedPreferences() async {
    String key = await SharedPreferencesModel().getApiKey();
    if (key != '') {
      _myCurrentKey = key;
    }
  }
}
