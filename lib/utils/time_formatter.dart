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
    late DateTime now;
    String? hourFormatted;
    String? zoneId;
    switch (timeZoneSetting) {
      case TimeZoneSetting.localTime:
        timeZonedTime = inputTime!.toLocal();
        zoneId = 'LT';
        now = DateTime.now();
        break;
      case TimeZoneSetting.tornTime:
        timeZonedTime = inputTime!.toUtc();
        zoneId = 'TCT';
        now = DateTime.now().toUtc();
        break;
    }

    int differenceInDays = timeZonedTime.difference(now).inDays;

    // Handle cases where [differenceInDays] can lead to errors
    if (differenceInDays == 0 && timeZonedTime.day != now.day) {
      // Event is happening later in the day but after midnight, so consider it as "tomorrow"
      differenceInDays = 1;
    } else if (differenceInDays == 1 && timeZonedTime.day != now.add(Duration(days: 1)).day) {
      // Event is happening after two midnights, so consider it as "in 2 days"
      differenceInDays = 2;
    }

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
      suffix = includeToday ? ' today' : '';
    } else if (differenceInDays == 1) {
      suffix = ' tomorrow';
    } else {
      suffix = ' in $differenceInDays days';
    }

    return '$hourFormatted$suffix';
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
