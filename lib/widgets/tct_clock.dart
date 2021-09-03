import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';

class TctClock extends StatefulWidget {
  const TctClock({
    Key key,
  }) : super(key: key);

  @override
  State<TctClock> createState() => _TctClockState();
}

class _TctClockState extends State<TctClock> {
  Timer _oneSecTimer;
  DateTime _currentTctTime = DateTime.now().toUtc();

  @override
  void initState() {
    _oneSecTimer = new Timer.periodic(Duration(seconds: 1), (Timer t) => _refreshTctClock());
    super.initState();
  }

  @override
  void dispose() {
    _oneSecTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    TimeFormatSetting timePrefs = settingsProvider.currentTimeFormat;
    DateFormat formatter;
    switch (timePrefs) {
      case TimeFormatSetting.h24:
        formatter = DateFormat('HH:mm');
        break;
      case TimeFormatSetting.h12:
        formatter = DateFormat('hh:mm a');
        break;
    }

    return GestureDetector(
      onTap: () {
        _launchBrowser(url: "https://www.torn.com/calendar.php", dialogRequested: true);
      },
      onLongPress: () {
        _launchBrowser(url: "https://www.torn.com/calendar.php", dialogRequested: false);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            formatter.format(_currentTctTime),
            style: TextStyle(fontSize: 14),
          ),
          Text(
            'TCT',
            style: TextStyle(fontSize: settingsProvider.showDateInClock != "off" ? 10 : 14),
          ),
          if (settingsProvider.showDateInClock != "off")
            Text(
              settingsProvider.showDateInClock == "dayfirst"
                  ? DateFormat('dd MMM').format(_currentTctTime).toUpperCase()
                  : DateFormat('MMM dd').format(_currentTctTime).toUpperCase(),
              style: TextStyle(fontSize: 10),
            ),
        ],
      ),
    );
  }

  void _refreshTctClock() {
    setState(() {
      _currentTctTime = DateTime.now().toUtc();
    });
  }

  void _launchBrowser({@required String url, @required bool dialogRequested}) async {
    if (!context.read<SettingsProvider>().useQuickBrowser) dialogRequested = false;
    await context.read<WebViewProvider>().openBrowserPreference(
          context: context,
          url: url,
          useDialog: dialogRequested,
        );
  }
}
