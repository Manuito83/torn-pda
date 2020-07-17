import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:torn_pda/models/loot/loot_model.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/utils/time_formatter.dart';
import '../main.dart';

enum LootTime {
  dateTime,
  timer,
}

class LootPage extends StatefulWidget {
  @override
  _LootPageState createState() => _LootPageState();
}

class _LootPageState extends State<LootPage> {
  Map<String, LootModel> _lootMap;
  Future _getLootInfoFromYata;
  bool _apiSuccess = false;

  SettingsProvider _settingsProvider;

  int _yataTicks = 0;
  Timer _tickerUpdateTimes;

  LootTime _lootTime;

  @override
  void initState() {
    super.initState();
    _getLootInfoFromYata = _fetchYataApi();
    analytics
        .logEvent(name: 'section_changed', parameters: {'section': 'loot'});

    _tickerUpdateTimes =
        new Timer.periodic(Duration(seconds: 1), (Timer t) => _updateTimes());
  }

  @override
  void dispose() {
    _tickerUpdateTimes.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: Text('Loot'),
        leading: new IconButton(
          icon: new Icon(Icons.menu),
          onPressed: () {
            final ScaffoldState scaffoldState =
                context.findRootAncestorStateOfType();
            scaffoldState.openDrawer();
          },
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              MdiIcons.timerSandEmpty,
            ),
            onPressed: () {
              setState(() {
                _lootTime == LootTime.timer
                    ? _lootTime = LootTime.dateTime
                    : _lootTime = LootTime.timer;
              });
            },
          ),
        ],
      ),
      body: FutureBuilder(
          future: _getLootInfoFromYata,
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (_apiSuccess) {
                return Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(5),
                      child: _returnNpcs(),
                    ),
                  ],
                );
              } else {
                return _connectError();
              }
            } else {
              return Center(child: CircularProgressIndicator());
            }
          }),
    );
  }

  Widget _connectError() {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'There was an error contacting with Yata!',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Text(
            'Please try again later.',
          ),
          SizedBox(height: 20),
          Text('If this problem reoccurs, please let us know!'),
        ],
      ),
    );
  }

  Widget _returnNpcs() {
    // Final card of every NPC
    var npcBoxes = List<Widget>();

    // Loop every NPC
    var npcModels = List<LootModel>();

    for (var npc in _lootMap.values) {
      // Get npcLevels in a column and format them
      int thisIndex = 1;
      var npcLevels = List<Widget>();
      var npcLevelsColumn = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: npcLevels,
      );

      npc.timings.forEach((key, value) {
        // Time formatting
        var levelDateTime =
            DateTime.fromMillisecondsSinceEpoch(value.ts * 1000);
        var time = TimeFormatter(
          inputTime: levelDateTime,
          timeFormatSetting: _settingsProvider.currentTimeFormat,
          timeZoneSetting: _settingsProvider.currentTimeZone,
        ).format;

        // Text string styling
        bool isPast = false;
        if (DateTime.now().isAfter(levelDateTime)) {
          isPast = true;
        }
        bool isCurrent = false;
        if (key == npc.levels.current.toString()) {
          isCurrent = true;
        }

        String timeString = "Level $thisIndex";
        var style = TextStyle();
        if (isPast && !isCurrent) {
          timeString += " at $time";
          style = TextStyle(color: Colors.grey);
        } else if (isCurrent) {
          timeString += " (now)";
          style = TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
          );
        } else {
          var timeDiff = levelDateTime.difference(DateTime.now());
          var diffFormatted = _formatDuration(timeDiff);
          if (_lootTime == LootTime.timer) {
            timeString += " in $diffFormatted";
          } else {
            timeString += " at $time";
          }
        }

        var timeText = Text(
          timeString,
          style: style,
        );

        npcLevels.add(timeText);
        npcLevels.add(SizedBox(height: 2));
        thisIndex++;
      });

      npcBoxes.add(Card(
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.people),
              SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${npc.name}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    npcLevelsColumn,
                  ],
                ),
              ),
              Icon(MdiIcons.knife),
            ],
          ),
        ),
      ));
      npcModels.add(npc);
    }

    Widget npcWidget = Column(children: npcBoxes);
    return npcWidget;
  }

  Future _fetchYataApi() async {
    try {
      // Database API
      String url = 'https://yata.alwaysdata.net/loot/timings/';
      final response = await http.get(url).timeout(Duration(seconds: 10));
      if (response.statusCode == 200) {
        _lootMap = lootModelFromJson(response.body);
        _lootMap.length >= 1 ? _apiSuccess = true : _apiSuccess = false;
      } else {
        _apiSuccess = false;
      }
    } catch (e) {
      _apiSuccess = false;
    }

    // DEBUG //
    /*
    _lootMap.remove('4');
    _lootMap.forEach((key, value) {
      if (key == '15') {
        value.levels.current = 0;
        value.levels.next = 1;
        int adder = 15;
        value.timings.forEach((key, value) {
          value.due = adder;
          value.ts = (DateTime.now().millisecondsSinceEpoch/1000).floor() + adder;
          adder = adder + 15;
        });
      }
    });
    print("Debugging! Comment this out!");
    */
    // DEBUG //

  }

  void _updateTimes() {
    setState(() {
      // As we only call YATA every few minutes, we need to ensure
      // that we keep all times updated
      for (var npc in _lootMap.values) {
        // Update main timing values comparing stored TS with current time
        var tsNow = (DateTime.now().millisecondsSinceEpoch/1000).round();
        var timingsList = List<Timing>();
        npc.timings.forEach((key, value) {
          value.due = value.ts - tsNow;
          timingsList.add(Timing(due: value.due, ts: value.ts, pro: value.pro));
        });
        // Make sure to advance levels if the times comes in between updates
        if (timingsList[0].due > 0) {
          npc.levels.current = 0;
          npc.levels.next = 1;
        } else if (timingsList[4].due < 0) {
          npc.levels.current = 5;
          npc.levels.next = 5;
        } else {
          for (var i = 0; i < 4; i++) {
            if (timingsList[i].due < 0 && timingsList[i + 1].due > 0) {
              npc.levels.current = i + 1;
              npc.levels.next = i + 2;
            }
          }
        }
      }
    });

    // We only call YATA once every 5 minutes
    if (_yataTicks >= 300) {
      _fetchYataApi();
      _yataTicks = 0;
    }
    _yataTicks++;
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}
