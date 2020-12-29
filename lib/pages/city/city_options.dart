import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class CityOptions extends StatefulWidget {
  final Function callback;

  CityOptions({
    @required this.callback,
  });

  @override
  _CityOptionsState createState() => _CityOptionsState();
}

class _CityOptionsState extends State<CityOptions> {
  bool _cityEnabled = true;

  ThemeProvider _themeProvider;
  SettingsProvider _settingsProvider;

  Future _preferencesLoaded;

  @override
  void initState() {
    super.initState();
    _preferencesLoaded = _restorePreferences();
  }

  @override
  Widget build(BuildContext context) {
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return WillPopScope(
      onWillPop: _willPopCallback,
      child: Scaffold(
        appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
        bottomNavigationBar: !_settingsProvider.appBarTop
            ? SizedBox(
                height: AppBar().preferredSize.height,
                child: buildAppBar(),
              )
            : null,
        body: Builder(
          builder: (BuildContext context) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => FocusScope.of(context).requestFocus(new FocusNode()),
              child: FutureBuilder(
                future: _preferencesLoaded,
                builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text("Use city finder"),
                                Switch(
                                  value: _cityEnabled,
                                  onChanged: (value) {
                                    SharedPreferencesModel().setCityEnabled(value);
                                    setState(() {
                                      _cityEnabled = value;
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
                              'Consider deactivating the city finder if it impacts '
                                  'performance or you just simply would not prefer to use it',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                          SizedBox(height: 50),
                        ],
                      ),
                    );
                  } else {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      brightness: Brightness.dark,
      title: Text("City Finder"),
      leading: new IconButton(
        icon: new Icon(Icons.arrow_back),
        onPressed: () {
          widget.callback();
          Navigator.of(context).pop();},
      ),
    );
  }

  Future _restorePreferences() async {
    var cityEnabled = await SharedPreferencesModel().getCityEnabled();

    setState(() {
      _cityEnabled = cityEnabled;
    });
  }

  Future<bool> _willPopCallback() async {
    widget.callback();
    return true;
  }
}

