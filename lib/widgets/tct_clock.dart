import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import 'package:torn_pda/models/api_v2/torn_v2.swagger.dart';
import 'package:torn_pda/providers/api/api_v2_calls.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class TctClock extends StatefulWidget {
  final Color color;
  final Function onTap;
  final Function onLongPress;

  const TctClock({
    required this.color,
    required this.onTap,
    required this.onLongPress,
    super.key,
  });

  @override
  State<TctClock> createState() => TctClockState();
}

class TctClockState extends State<TctClock> {
  late Timer _oneSecTimer;
  late Timer _thirtyMinTimer;
  DateTime _currentTctTime = DateTime.now().toUtc();
  bool _isEventActive = false;

  TornCalendarResponse? _calendar;

  bool debug = false; // TODO

  @override
  void initState() {
    super.initState();
    // 1-second timer to refresh the clock display
    _oneSecTimer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _refreshTctClock());

    // 30-minute timer to check for active events or competitions
    _thirtyMinTimer = Timer.periodic(const Duration(minutes: 30), (Timer t) => _checkActiveEvents());

    _updateCalendar();
  }

  @override
  void dispose() {
    _oneSecTimer.cancel();
    _thirtyMinTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: true);
    final TimeFormatSetting timePrefs = settingsProvider.currentTimeFormat;
    late DateFormat formatter;
    switch (timePrefs) {
      case TimeFormatSetting.h24:
        formatter = DateFormat(settingsProvider.showSecondsInClock ? 'HH:mm:ss' : 'HH:mm');
        break;
      case TimeFormatSetting.h12:
        formatter = DateFormat(settingsProvider.showSecondsInClock ? 'hh:mm:ss a' : 'hh:mm a');
        break;
    }

    return GestureDetector(
      onTap: () {
        widget.onTap();
        _showToast();
      },
      onLongPress: () {
        widget.onLongPress();
        _showToast();
      },
      child: Container(
        // Shadow if an event or competition is active
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              formatter.format(_currentTctTime),
              style: TextStyle(
                fontSize: settingsProvider.showSecondsInClock ? 12 : 14,
                color: widget.color,
                fontWeight:
                    _isEventActive && settingsProvider.tctClockHighlightsEvents ? FontWeight.bold : FontWeight.normal,
                shadows: _isEventActive && settingsProvider.tctClockHighlightsEvents
                    ? [
                        Shadow(
                          color: Colors.orange.shade800.withValues(alpha: 0.8),
                          offset: const Offset(0, 0),
                          blurRadius: 5,
                        )
                      ]
                    : null,
              ),
            ),
            Text(
              'TCT',
              style: TextStyle(
                fontSize: settingsProvider.showDateInClock != "off" ? 10 : 14,
                color: widget.color,
                fontWeight:
                    _isEventActive && settingsProvider.tctClockHighlightsEvents ? FontWeight.bold : FontWeight.normal,
                shadows: _isEventActive && settingsProvider.tctClockHighlightsEvents
                    ? [
                        Shadow(
                          color: Colors.orange.shade800.withValues(alpha: 0.8),
                          offset: const Offset(0, 0),
                          blurRadius: 5,
                        )
                      ]
                    : null,
              ),
            ),
            if (settingsProvider.showDateInClock != "off")
              Text(
                settingsProvider.showDateInClock == "dayfirst"
                    ? DateFormat('dd MMM').format(_currentTctTime).toUpperCase()
                    : DateFormat('MMM dd').format(_currentTctTime).toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  color: widget.color,
                  fontWeight:
                      _isEventActive && settingsProvider.tctClockHighlightsEvents ? FontWeight.bold : FontWeight.normal,
                  shadows: _isEventActive && settingsProvider.tctClockHighlightsEvents
                      ? [
                          Shadow(
                            color: Colors.orange.shade800.withValues(alpha: 0.8),
                            offset: const Offset(0, 0),
                            blurRadius: 5,
                          )
                        ]
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showToast() {
    List<dynamic> activeEvents = _getActiveEvents();

    if (activeEvents.isNotEmpty) {
      final DateTime now = DateTime.now().toUtc();
      List<String> eventStrings = [];

      // Build toast for each active event
      for (var event in activeEvents) {
        int endTimestamp;
        String title;
        String description;
        if (event is Map) {
          endTimestamp = event["end"];
          title = event["title"];
          description = event["description"];
        } else {
          endTimestamp = event.end!;
          title = event.title!;
          description = event.description!;
        }

        DateTime eventEnd = DateTime.fromMillisecondsSinceEpoch(endTimestamp * 1000, isUtc: true);
        Duration remaining = eventEnd.difference(now);

        String remainingStr;
        if (remaining.inDays >= 1) {
          int days = remaining.inDays;
          int hours = remaining.inHours % 24;
          remainingStr = "$days ${days == 1 ? 'day' : 'days'} $hours ${hours == 1 ? 'hour' : 'hours'} remaining";
        } else if (remaining.inHours >= 1) {
          int hours = remaining.inHours;
          remainingStr = "$hours ${hours == 1 ? 'hour' : 'hours'} remaining";
        } else {
          int minutes = remaining.inMinutes;
          remainingStr = "$minutes ${minutes == 1 ? 'minute' : 'minutes'} remaining";
        }

        String eventString = "[$title] is active!\n\n$description\n\n$remainingStr";
        eventStrings.add(eventString);
      }

      String toastMessage = eventStrings.join("\n\n\n\n");
      toastification.show(
        showIcon: false,
        borderSide: BorderSide(color: Colors.orange.shade800, width: 2),
        closeButtonShowType: CloseButtonShowType.none,
        closeOnClick: true,
        autoCloseDuration: Duration(seconds: 5),
        showProgressBar: false,
        alignment: Alignment.bottomCenter,
        title: Text(
          toastMessage,
          textAlign: TextAlign.center,
          maxLines: 50,
        ),
      );
    }
  }

  void _refreshTctClock() {
    setState(() {
      _currentTctTime = DateTime.now().toUtc();
    });
  }

  List<dynamic> _getActiveEvents() {
    List<dynamic> eventsList = [];
    final DateTime now = DateTime.now().toUtc();

    if (_calendar != null && _calendar!.calendar != null) {
      if (_calendar!.calendar!.competitions != null) {
        for (var comp in _calendar!.calendar!.competitions!) {
          if (comp.start != null && comp.end != null) {
            DateTime start = DateTime.fromMillisecondsSinceEpoch(comp.start! * 1000, isUtc: true);
            DateTime end = DateTime.fromMillisecondsSinceEpoch(comp.end! * 1000, isUtc: true);
            if (now.isAfter(start) && now.isBefore(end)) {
              eventsList.add(comp);
            }
          }
        }
      }

      if (_calendar!.calendar!.events != null) {
        for (var ev in _calendar!.calendar!.events!) {
          if (ev.start != null && ev.end != null) {
            DateTime start = DateTime.fromMillisecondsSinceEpoch(ev.start! * 1000, isUtc: true);
            DateTime end = DateTime.fromMillisecondsSinceEpoch(ev.end! * 1000, isUtc: true);
            if (now.isAfter(start) && now.isBefore(end)) {
              eventsList.add(ev);
            }
          }
        }
      }
    }

    if (debug && !kReleaseMode) {
      eventsList = [
        {
          "title": "Valentine's Day",
          "description": "Love Juice reduces the energy cost of attacking & reviving",
          "start": (now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000),
          "end": (now.add(const Duration(hours: 2)).millisecondsSinceEpoch ~/ 1000),
        },
        {
          "title": "Christmas Town",
          "description": "Torn's very own festive theme park opens its doors to the public",
          "start": (now.subtract(const Duration(hours: 2)).millisecondsSinceEpoch ~/ 1000),
          "end": (now.add(const Duration(hours: 3)).millisecondsSinceEpoch ~/ 1000),
        }
      ];
    }

    return eventsList;
  }

  /// Checks if the current time falls within any event or competition period
  Future<void> _checkActiveEvents() async {
    List<dynamic> activeEvents = _getActiveEvents();
    setState(() {
      _isEventActive = activeEvents.isNotEmpty || (debug && !kReleaseMode);
    });
  }

  /// If there's recent data available in [_calendar], it will check for active events directly
  /// Otherwise (no data or older than 10 days), it will get the API first
  Future<void> _updateCalendar() async {
    try {
      String? storedCalendarJson = await Prefs().getTornCalendarModel();
      if (storedCalendarJson.isNotEmpty) {
        _calendar = TornCalendarResponse.fromJson(jsonDecode(storedCalendarJson));
      }

      int lastTimestamp = await Prefs().getTornCalendarLastUpdate();
      DateTime lastUpdate = DateTime.fromMillisecondsSinceEpoch(lastTimestamp, isUtc: true);
      final now = DateTime.now();

      if (_calendar == null || now.difference(lastUpdate).inDays > 10) {
        final dynamic jsonData = await _fetchCalendarDataFromApi();
        if (jsonData != null && jsonData is TornCalendarResponse) {
          _calendar = jsonData;
          await Prefs().setTornCalendarModel(jsonEncode(_calendar!.toJson()));
          await Prefs().setTornCalendarLastUpdate(now.millisecondsSinceEpoch);
        }
      }

      _checkActiveEvents();
    } catch (e, t) {
      if (!Platform.isWindows) FirebaseCrashlytics.instance.log("PDA Crash at TCT Clock");
      if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError("Error: $e", t);
    }
  }

  Future<dynamic> _fetchCalendarDataFromApi() async {
    final dynamic calendar = await ApiCallsV2.getTornCalendar_v2();
    return calendar;
  }
}
