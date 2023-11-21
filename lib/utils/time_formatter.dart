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
      case TimeZoneSetting.tornTime:
        timeZonedTime = inputTime!.toUtc();
        zoneId = 'TCT';
    }

    final now = DateTime.now();
    final difference = timeZonedTime.difference(now).inDays;

    switch (timeFormatSetting) {
      case TimeFormatSetting.h24:
        final formatter = DateFormat('HH:mm');
        hourFormatted = '${formatter.format(timeZonedTime)} $zoneId';
      case TimeFormatSetting.h12:
        final formatter = DateFormat('hh:mm a');
        hourFormatted = '${formatter.format(timeZonedTime)} $zoneId';
    }

    String suffix;
    if (difference == 0) {
      suffix = includeToday ? 'today' : '';
    } else if (difference == 1) {
      suffix = 'tomorrow';
    } else {
      suffix = 'in $difference days';
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
