import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:developer';
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

class _ActiveCalendarEvent {
  const _ActiveCalendarEvent({
    required this.title,
    required this.description,
    required this.start,
    required this.end,
    this.usesUserStartTime = false,
    this.userStartTimeLiteral,
    this.userStartTimeApplied = false,
  });

  final String title;
  final String description;
  final DateTime start;
  final DateTime end;
  final bool usesUserStartTime;
  final String? userStartTimeLiteral;
  final bool userStartTimeApplied;
}

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
  String? _userCalendarStartTimeRaw;
  Duration? _userCalendarStartOffset;
  bool _isFetchingUserStartTime = false;

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
                shadows: _isEventActive && settingsProvider.tctClockHighlightsEvents ? _shadowList() : null,
              ),
            ),
            Text(
              'TCT',
              style: TextStyle(
                fontSize: settingsProvider.showDateInClock != "off" ? 10 : 14,
                color: widget.color,
                fontWeight:
                    _isEventActive && settingsProvider.tctClockHighlightsEvents ? FontWeight.bold : FontWeight.normal,
                shadows: _isEventActive && settingsProvider.tctClockHighlightsEvents ? _shadowList() : null,
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
                  shadows: _isEventActive && settingsProvider.tctClockHighlightsEvents ? _shadowList() : null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showToast() {
    final List<_ActiveCalendarEvent> activeEvents = _getActiveEvents();

    if (activeEvents.isNotEmpty) {
      final DateTime now = DateTime.now().toUtc();
      final List<String> eventStrings = [];

      for (final _ActiveCalendarEvent event in activeEvents) {
        final DateTime eventEnd = event.end;
        final Duration remaining = eventEnd.difference(now);

        String remainingStr;
        if (remaining.inDays >= 1) {
          final int days = remaining.inDays;
          final int hours = remaining.inHours % 24;
          remainingStr = "$days ${days == 1 ? 'day' : 'days'} $hours ${hours == 1 ? 'hour' : 'hours'} remaining";
        } else if (remaining.inHours >= 1) {
          final int hours = remaining.inHours;
          remainingStr = "$hours ${hours == 1 ? 'hour' : 'hours'} remaining";
        } else {
          final int minutes = remaining.inMinutes;
          remainingStr = "$minutes ${minutes == 1 ? 'minute' : 'minutes'} remaining";
        }

        String eventString = "[${event.title}] is active!\n\n${event.description}\n\n$remainingStr";
        if (event.usesUserStartTime && event.userStartTimeLiteral != null) {
          eventString += "\n\nStart time: ${event.userStartTimeLiteral}";
          if (!event.userStartTimeApplied) {
            eventString += "\n(Using default timing; couldn't apply configured start)";
          }
        }

        eventStrings.add(eventString);
      }

      final String toastMessage = eventStrings.join("\n\n\n\n");
      final int durationSeconds = activeEvents.length * 5 < 5 ? 5 : activeEvents.length * 5;
      toastification.show(
        showIcon: false,
        borderSide: BorderSide(color: Colors.orange.shade800, width: 2),
        closeButtonShowType: CloseButtonShowType.none,
        closeOnClick: true,
        autoCloseDuration: Duration(seconds: durationSeconds),
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

  List<_ActiveCalendarEvent> _getActiveEvents() {
    List<_ActiveCalendarEvent> eventsList = [];
    final DateTime now = DateTime.now().toUtc();

    if (_calendar != null) {
      for (final TornCalendarActivity comp in _calendar!.calendar.competitions) {
        final _ActiveCalendarEvent? activeEvent = _buildActiveEvent(comp, now);
        if (activeEvent != null) {
          eventsList.add(activeEvent);
        }
      }

      for (final TornCalendarActivity ev in _calendar!.calendar.events) {
        final _ActiveCalendarEvent? activeEvent = _buildActiveEvent(ev, now);
        if (activeEvent != null) {
          eventsList.add(activeEvent);
        }
      }
    }

    if (debug && !kReleaseMode) {
      // Simulate a full-day Torn event that gets shifted to a 10:30 TCT user start
      final DateTime dayStart = DateTime.utc(now.year, now.month, now.day);
      final DateTime dayEnd = dayStart.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
      final Duration fullDayDuration = dayEnd.difference(dayStart);

      final DateTime customStart = DateTime.utc(dayStart.year, dayStart.month, dayStart.day, 10, 30);
      final DateTime customEnd = customStart.add(fullDayDuration);

      eventsList = [
        _ActiveCalendarEvent(
          title: "Valentine's Day",
          description: "Love Juice reduces the energy cost of attacking & reviving",
          start: customStart,
          end: customEnd,
          usesUserStartTime: true,
          userStartTimeLiteral: "10:30 TCT",
          userStartTimeApplied: true,
        ),
        _ActiveCalendarEvent(
          title: "Christmas Town",
          description: "Torn's very own festive theme park opens its doors to the public",
          start: dayStart,
          end: dayEnd,
        ),
      ];
    }

    if (debug) {
      for (final _ActiveCalendarEvent ev in eventsList) {
        final String startStr = DateFormat('yyyy-MM-dd HH:mm').format(ev.start);
        final String endStr = DateFormat('yyyy-MM-dd HH:mm').format(ev.end);
        log('🗓️ ${ev.title}: $startStr → $endStr');
      }
    }

    return eventsList;
  }

  _ActiveCalendarEvent? _buildActiveEvent(TornCalendarActivity activity, DateTime nowUtc) {
    final DateTime baseStart = DateTime.fromMillisecondsSinceEpoch(activity.start * 1000, isUtc: true);
    final DateTime baseEnd = DateTime.fromMillisecondsSinceEpoch(activity.end * 1000, isUtc: true);
    final Duration duration = baseEnd.difference(baseStart);

    DateTime effectiveStart = baseStart;
    DateTime effectiveEnd = baseEnd;
    final bool usesUserStartTime = activity.fixedStartTime == false;
    bool userStartTimeApplied = false;

    if (usesUserStartTime && _userCalendarStartOffset != null) {
      // Shift the start to the player selected hour and then
      // compute the end so the total duration matches Torn's duration
      effectiveStart = _applyUserStartTime(baseStart, _userCalendarStartOffset!);
      effectiveEnd = effectiveStart.add(duration);
      userStartTimeApplied = true;
    }

    if (nowUtc.isAfter(effectiveStart) && nowUtc.isBefore(effectiveEnd)) {
      return _ActiveCalendarEvent(
        title: activity.title,
        description: activity.description,
        start: effectiveStart,
        end: effectiveEnd,
        usesUserStartTime: usesUserStartTime,
        userStartTimeLiteral: usesUserStartTime ? _userCalendarStartTimeRaw : null,
        userStartTimeApplied: userStartTimeApplied,
      );
    }

    return null;
  }

  bool _calendarDataMissingFixedStartFlag(TornCalendarResponse calendar) {
    return calendar.calendar.competitions.any((activity) => activity.fixedStartTime == null) ||
        calendar.calendar.events.any((activity) => activity.fixedStartTime == null);
  }

  bool _calendarRequiresUserStartTime(TornCalendarResponse calendar) {
    return calendar.calendar.competitions.any((activity) => activity.fixedStartTime == false) ||
        calendar.calendar.events.any((activity) => activity.fixedStartTime == false);
  }

  Future<void> _ensureUserCalendarStartTime({bool forceRefresh = false}) async {
    if (_isFetchingUserStartTime) return;
    if (!forceRefresh && _userCalendarStartTimeRaw != null) return;

    _isFetchingUserStartTime = true;
    try {
      final UserCalendarResponse? response = await ApiCallsV2.getUserCalendar_v2();
      if (response != null) {
        final String rawStartTime = response.calendar.startTime;
        final Duration? parsedOffset = _parseUserCalendarStartTime(rawStartTime);

        if (!mounted) {
          _userCalendarStartTimeRaw = rawStartTime;
          _userCalendarStartOffset = parsedOffset;
        } else {
          setState(() {
            _userCalendarStartTimeRaw = rawStartTime;
            _userCalendarStartOffset = parsedOffset;
          });
        }
      }
    } catch (e, t) {
      if (!Platform.isWindows) {
        FirebaseCrashlytics.instance.log("PDA Crash at TCT Clock - user calendar");
        FirebaseCrashlytics.instance.recordError("Error: $e", t);
      }
    } finally {
      _isFetchingUserStartTime = false;
    }
  }

  Duration? _parseUserCalendarStartTime(String rawStartTime) {
    final String trimmed = rawStartTime.trim();
    if (trimmed.isEmpty) return null;

    final String normalizedUpper = trimmed.toUpperCase();
    final String withoutTct = normalizedUpper.replaceAll('TCT', '').trim();
    final String replaced = withoutTct.replaceAll('.', ':');

    final RegExpMatch? match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(replaced);
    if (match == null) return null;

    final int? hours = int.tryParse(match.group(1)!);
    final int? minutes = int.tryParse(match.group(2)!);

    if (hours == null || minutes == null) return null;
    if (hours < 0 || hours > 23 || minutes < 0 || minutes > 59) return null;

    return Duration(hours: hours, minutes: minutes);
  }

  DateTime _applyUserStartTime(DateTime baseStart, Duration offset) {
    final int hours = offset.inHours;
    final int minutes = offset.inMinutes.remainder(60);
    return DateTime.utc(baseStart.year, baseStart.month, baseStart.day, hours, minutes);
  }

  /// Checks if the current time falls within any event or competition period
  Future<void> _checkActiveEvents() async {
    if (!mounted) return;
    final List<_ActiveCalendarEvent> activeEvents = _getActiveEvents();
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

      final bool refreshMissingFixedStart = _calendar != null && _calendarDataMissingFixedStartFlag(_calendar!);

      if (_calendar == null || now.difference(lastUpdate).inDays > 10 || refreshMissingFixedStart) {
        final dynamic jsonData = await _fetchCalendarDataFromApi();
        if (jsonData != null && jsonData is TornCalendarResponse) {
          _calendar = jsonData;
          await Prefs().setTornCalendarModel(jsonEncode(_calendar!.toJson()));
          await Prefs().setTornCalendarLastUpdate(now.millisecondsSinceEpoch);
        }
      }

      if (_calendar != null && _calendarRequiresUserStartTime(_calendar!)) {
        await _ensureUserCalendarStartTime(forceRefresh: true);
      }

      await _checkActiveEvents();
    } catch (e, t) {
      if (!Platform.isWindows) FirebaseCrashlytics.instance.log("PDA Crash at TCT Clock");
      if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError("Error: $e", t);
    }
  }

  Future<dynamic> _fetchCalendarDataFromApi() async {
    final dynamic calendar = await ApiCallsV2.getTornCalendar_v2();
    return calendar;
  }

  List<Shadow> _shadowList() {
    return [
      Shadow(
        color: Colors.orange.shade800.withValues(alpha: 1),
        offset: const Offset(0, 0),
        blurRadius: 20,
      ),
      Shadow(
        color: Colors.orange.shade800.withValues(alpha: 1),
        offset: const Offset(0, 0),
        blurRadius: 20,
      ),
      Shadow(
        color: Colors.orange.shade800.withValues(alpha: 1),
        offset: const Offset(0, 0),
        blurRadius: 5,
      ),
    ];
  }
}
