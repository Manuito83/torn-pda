// Package imports:
import 'package:intl/intl.dart';

// Project imports:
import 'package:torn_pda/providers/settings_provider.dart';

class TimeFormatter {
  final DateTime? inputTime;
  final TimeFormatSetting timeFormatSetting;
  final TimeZoneSetting timeZoneSetting;

  TimeFormatter({required this.inputTime, required this.timeFormatSetting, required this.timeZoneSetting});

  String? get formatHour {
    late DateTime timeZonedTime;
    String? hourFormatted;
    String? zoneId;
    switch (timeZoneSetting) {
      case TimeZoneSetting.localTime:
        timeZonedTime = inputTime!.toLocal();
        zoneId = 'LT';
      case TimeZoneSetting.tornTime:
        timeZonedTime = inputTime!.toUtc();
        zoneId = 'TCT';
    }

    switch (timeFormatSetting) {
      case TimeFormatSetting.h24:
        final formatter = DateFormat('HH:mm');
        hourFormatted = '${formatter.format(timeZonedTime)} $zoneId';
      case TimeFormatSetting.h12:
        final formatter = DateFormat('hh:mm a');
        hourFormatted = '${formatter.format(timeZonedTime)} $zoneId';
    }

    return hourFormatted;
  }

  String formatHourWithDaysElapsed({bool includeToday = false}) {
    late DateTime timeZonedTime;
    String? hourFormatted;
    String? zoneId;
    switch (timeZoneSetting) {
      case TimeZoneSetting.localTime:
        timeZonedTime = inputTime!.toLocal();
        zoneId = 'LT';
        break;
      case TimeZoneSetting.tornTime:
        timeZonedTime = inputTime!.toUtc();
        zoneId = 'TCT';
        break;
    }

    final now = DateTime.now();
    int differenceInDays = (timeZonedTime.weekday - now.weekday + 7) % 7;

    switch (timeFormatSetting) {
      case TimeFormatSetting.h24:
        final formatter = DateFormat('HH:mm');
        hourFormatted = '${formatter.format(timeZonedTime)} $zoneId';
        break;
      case TimeFormatSetting.h12:
        final formatter = DateFormat('hh:mm a');
        hourFormatted = '${formatter.format(timeZonedTime)} $zoneId';
        break;
    }

    String suffix;
    if (differenceInDays == 0) {
      suffix = includeToday ? 'today' : '';
    } else if (differenceInDays == 1) {
      suffix = 'tomorrow';
    } else {
      suffix = 'in $differenceInDays days';
    }

    return '$hourFormatted $suffix';
  }

  String? _dayWeekFormatted;
  String? get formatDayWeek {
    late DateTime timeZonedTime;
    switch (timeZoneSetting) {
      case TimeZoneSetting.localTime:
        timeZonedTime = inputTime!.toLocal();
      case TimeZoneSetting.tornTime:
        timeZonedTime = inputTime!.toUtc();
    }

    final formatter = DateFormat('EEEE');
    _dayWeekFormatted = 'on ${formatter.format(timeZonedTime)}';

    return _dayWeekFormatted;
  }

  String? _monthDayFormatted;
  String? get formatMonthDay {
    late DateTime timeZonedTime;
    switch (timeZoneSetting) {
      case TimeZoneSetting.localTime:
        timeZonedTime = inputTime!.toLocal();
      case TimeZoneSetting.tornTime:
        timeZonedTime = inputTime!.toUtc();
    }

    final formatter = DateFormat('MMM dd');
    _monthDayFormatted = formatter.format(timeZonedTime);

    return _monthDayFormatted;
  }
}
