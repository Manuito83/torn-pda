import 'dart:async';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chaining/target_sort.dart';
import 'package:torn_pda/models/chaining/yata/yata_distribution_models.dart';
import 'package:torn_pda/models/chaining/yata/yata_targets_import.dart';
import 'package:torn_pda/pages/chaining/targets_backup_page.dart';
import 'package:torn_pda/pages/chaining/targets_options_page.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/targets_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/chaining/chain_timer.dart';
import 'package:torn_pda/widgets/chaining/targets_list.dart';
import 'package:torn_pda/widgets/chaining/yata/yata_targets_dialog.dart';
import 'package:http/http.dart' as http;
import 'package:torn_pda/main.dart';

class TacPage extends StatefulWidget {
  final String userKey;

  const TacPage({Key key, @required this.userKey}) : super(key: key);

  @override
  _TacPageState createState() => _TacPageState();
}

class _TacPageState extends State<TacPage> {
  Future _preferencesLoaded;

  ThemeProvider _themeProvider;
  SettingsProvider _settingsProvider;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _preferencesLoaded = _restorePreferences();

    analytics.logEvent(name: 'section_changed', parameters: {'section': 'tac'});
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return Scaffold(
      drawer: Drawer(),
      appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
      bottomNavigationBar: !_settingsProvider.appBarTop
          ? SizedBox(
              height: AppBar().preferredSize.height,
              child: buildAppBar(),
            )
          : null,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).requestFocus(new FocusNode()),
        child: Column(
          children: <Widget>[
            SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // TODO
              ],
            ),
            SizedBox(height: 5),
            ChainTimer(
              userKey: widget.userKey,
              alwaysDarkBackground: false,
              chainTimerParent: ChainTimerParent.targets,
            ),
            RaisedButton(
              child: Text('Get'),
              onPressed: () {
                _fetchTac();
              },
            ),
          ],
        ),
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      brightness: Brightness.dark,
      title: Text("Torn Attack Central"),
      leading: new IconButton(
        icon: new Icon(Icons.menu),
        onPressed: () {
          final ScaffoldState scaffoldState =
              context.findRootAncestorStateOfType();
          scaffoldState.openDrawer();
        },
      ),
      actions: <Widget>[
        // TODO
      ],
    );
  }

  Future _restorePreferences() async {
    // TODO
  }

  Future _fetchTac() async {
    const action = 'fetch';
    var apiKey = widget.userKey;
    var optimalLevel = 3;
    var rank = 8;
    var optimal = 1;

    var url = 'https://tornattackcentral.eu/pdaintegration.php?action='
        '$action&key=$apiKey&optimallevel=$optimalLevel&optimal='
        '$optimal&rank=$rank';

    try {
      var response = await http.get(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8'
        },
      );

      if (response.statusCode == 200) {
        print(response.body);
      } else {
        // TODO:
      }
    } catch (e) {
      print(e);
    }
  }
}
