import 'package:intl/intl.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:flutter/material.dart';

class TimeFormatter {
  final DateTime inputTime;
  final TimeFormatSetting timeFormatSetting;
  final TimeZoneSetting timeZoneSetting;


  TimeFormatter(
      {@required this.inputTime,
        @required this.timeFormatSetting,
        @required this.timeZoneSetting});

  String _timeFormatted;
  String get format {
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
        _timeFormatted = '${formatter.format(timeZonedTime)} $zoneId';
        break;
      case TimeFormatSetting.h12:
        var formatter = DateFormat('hh:mm a');
        _timeFormatted = '${formatter.format(timeZonedTime)} $zoneId';
        break;
    }

    return _timeFormatted;
  }

}
