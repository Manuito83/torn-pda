import 'dart:async';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:torn_pda/models/chaining/target_model.dart';
import 'package:torn_pda/models/loot/loot_model.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/utils/api_caller.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/utils/time_formatter.dart';
import '../main.dart';

enum LootTimeType {
  dateTime,
  timer,
}

class LootPage extends StatefulWidget {
  @override
  _LootPageState createState() => _LootPageState();
}

class _LootPageState extends State<LootPage> {
  final _npcIds = [4, 15, 19];

  Map<String, LootModel> _lootMap;
  Future _getLootInfoFromYata;
  bool _apiSuccess = false;

  SettingsProvider _settingsProvider;
  UserDetailsProvider _userProvider;

  bool _firstLoad = true;
  int _tornTicks = 0;
  int _yataTicks = 0;
  Timer _tickerUpdateTimes;

  LootTimeType _lootTimeType;

  @override
  void initState() {
    super.initState();
    _userProvider = Provider.of<UserDetailsProvider>(context, listen: false);

    _getLootInfoFromYata = _updateTimes();

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
                if (_lootTimeType == LootTimeType.timer) {
                  _lootTimeType = LootTimeType.dateTime;
                  SharedPreferencesModel().setLootTimerType('dateTime');
                } else {
                  _lootTimeType = LootTimeType.timer;
                  SharedPreferencesModel().setLootTimerType('timer');
                }
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
                      child: _returnNpcCards(),
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

  Widget _returnNpcCards() {
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
          if (_lootTimeType == LootTimeType.timer) {
            timeString += " in $diffFormatted";
          } else {
            timeString += " at $time";
          }
          if (timeDiff.inMinutes < 10) {
            if (npc.levels.next >= 3) {
              style = TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              );
            } else {
              style = TextStyle(
                fontWeight: FontWeight.bold,
              );
            }
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

      Widget hospitalized;
      if (npc.status == "hospitalized") {
        hospitalized = Text(
          '[HOSPITALIZED]',
          style: TextStyle(
            color: Colors.red,
          ),
        );
      } else {
        hospitalized = SizedBox.shrink();
      }

      Widget knifeIcon;
      if (npc.levels.current >= 4) {
        knifeIcon = Icon(
          MdiIcons.knife,
          color: Colors.red,
        );
      } else {
        knifeIcon = Icon(MdiIcons.knife);
      }

      Color cardBorderColor() {
        if (npc.levels.current >= 4) {
          return Colors.orange;
        } else {
          return Colors.transparent;
        }
      }

      npcBoxes.add(
        Card(
          shape: RoundedRectangleBorder(
              side: BorderSide(color: cardBorderColor(), width: 1.5),
              borderRadius: BorderRadius.circular(4.0)),
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
                      Row(
                        children: [
                          Text(
                            '${npc.name}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: 10),
                          hospitalized,
                        ],
                      ),
                      SizedBox(height: 10),
                      npcLevelsColumn,
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: knifeIcon,
                ),
              ],
            ),
          ),
        ),
      );
      npcModels.add(npc);
    }

    Widget npcWidget = Column(children: npcBoxes);
    return npcWidget;
  }

  Future _updateTimes() async {
    var tsNow = (DateTime.now().millisecondsSinceEpoch / 1000).round();

    // On start, get both API and compare if Torn has more up to date info
    if (_firstLoad) {
      _firstLoad = false;
      await _loadPreferences();
      // Fill in YATA information
      await _fetchYataApi();
      // Get Torn API so that we can compare
      await _fetchCompareTornApi(tsNow);
    }
    // If it's not the first execution, fetch YATA every 5 minutes and Torn
    // every 30 seconds
    else {
      _yataTicks++;
      _tornTicks++;

      if (_yataTicks >= 300) {
        await _fetchYataApi();
        _yataTicks = 0;
      }
      if (_tornTicks > 30) {
        await _fetchCompareTornApi(tsNow);
        _tornTicks = 0;
      }
    }

    // We need to ensure that we keep all times updated
    if (mounted) {
      setState(() {
        for (var npc in _lootMap.values) {
          // Update main timing values comparing stored TS with current time
          var timingsList = List<Timing>();
          npc.timings.forEach((key, value) {
            value.due = value.ts - tsNow;
            timingsList.add(Timing(
              due: value.due,
              ts: value.ts,
              pro: value.pro,
            ));
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
    }
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
  }

  Future _fetchCompareTornApi(int tsNow) async {
    // Get Torn API so that we can compare
    for (var id in _npcIds) {
      var tornTarget = await TornApiCaller.target(
        _userProvider.myUser.userApiKey,
        id.toString(),
      ).getTarget;
      // If the tornTarget is in hospital as per Torn, we might need to
      // correct times that come from YATA
      if (tornTarget is TargetModel) {
        _lootMap.forEach((key, value) {
          // Look for our tornTarget
          if (key == id.toString()) {
            if (tornTarget.status.state == 'Hospital') {
              // If Torn gives a more up to date hospital out value
              if (tornTarget.status.until - 60 > value.hospout) {
                value.hospout = tornTarget.status.until;
                value.levels.current = 0;
                value.levels.next = 1;
                value.status = "hospitalized";
                value.update = tsNow;
                // Generate updated timings
                var newTimingMap = Map<String, Timing>();
                var lootDelays = [0, 30 * 60, 90 * 60, 210 * 60, 450 * 60];
                for (var i = 0; i < lootDelays.length; i++) {
                  var thisLevel = Timing(
                    due: value.hospout + lootDelays[i] - tsNow,
                    ts: value.hospout + lootDelays[i],
                    pro: 0,
                  );
                  newTimingMap.addAll({(i + 1).toString(): thisLevel});
                }
                value.timings = newTimingMap;
              }
            } else {
              value.status = "loot";
            }
          }
        });
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  Future _loadPreferences() async {
    var lootType = await SharedPreferencesModel().getLootTimerType();
    lootType == 'timer'
        ? _lootTimeType = LootTimeType.timer
        : _lootTimeType = LootTimeType.dateTime;
  }
}
