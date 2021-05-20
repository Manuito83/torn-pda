// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:intl/intl.dart';

// Project imports:
import 'package:torn_pda/providers/settings_provider.dart';

class TimeFormatter {
  final DateTime inputTime;
  final TimeFormatSetting timeFormatSetting;
  final TimeZoneSetting timeZoneSetting;

  TimeFormatter(
      {@required this.inputTime,
        @required this.timeFormatSetting,
        @required this.timeZoneSetting});

  String _hourFormatted;
  String get formatHour {
    DateTime timeZonedTime;
    String zoneId;
    switch (timeZoneSetting) {
      case TimeZoneSetting.localTime:
        timeZonedTime = inputTime.toLocal();
        zoneId = 'LT';
        break;
      case TimeZoneSetting.tornTime:
        timeZonedTime = inputTime.toUtc();
        zoneId = 'TCT';
        break;
    }

    switch (timeFormatSetting) {
      case TimeFormatSetting.h24:
        var formatter = DateFormat('HH:mm');
        _hourFormatted = '${formatter.format(timeZonedTime)} $zoneId';
        break;
      case TimeFormatSetting.h12:
        var formatter = DateFormat('hh:mm a');
        _hourFormatted = '${formatter.format(timeZonedTime)} $zoneId';
        break;
    }

    return _hourFormatted;
  }

  String _dayWeekFormatted;
  String get formatDayWeek {
    DateTime timeZonedTime;
    switch (timeZoneSetting) {
      case TimeZoneSetting.localTime:
        timeZonedTime = inputTime.toLocal();
        break;
      case TimeZoneSetting.tornTime:
        timeZonedTime = inputTime.toUtc();
        break;
    }

    var formatter = DateFormat('EEEE');
    _dayWeekFormatted = 'on ${formatter.format(timeZonedTime)}';

    return _dayWeekFormatted;
  }

  String _monthDayFormatted;
  String get formatMonthDay {
    DateTime timeZonedTime;
    switch (timeZoneSetting) {
      case TimeZoneSetting.localTime:
        timeZonedTime = inputTime.toLocal();
        break;
      case TimeZoneSetting.tornTime:
        timeZonedTime = inputTime.toUtc();
        break;
    }

    var formatter = DateFormat('MMM dd');
    _monthDayFormatted = '${formatter.format(timeZonedTime)}';

    return _monthDayFormatted;
  }

}
