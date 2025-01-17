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

  String formatHourWithDaysElapsed({bool includeToday = false, bool includeYesterday = false}) {
    late DateTime timeZonedTime;
    late DateTime now;
    String? hourFormatted;
    String? zoneId;

    // Convert input time to the appropriate time zone and get current time accordingly
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

    // Create dates without time in the same time zone to ensure accurate day difference
    DateTime nowDate;
    DateTime timeZonedDate;

    if (timeZoneSetting == TimeZoneSetting.tornTime) {
      // Create dates in UTC
      nowDate = DateTime.utc(now.year, now.month, now.day);
      timeZonedDate = DateTime.utc(timeZonedTime.year, timeZonedTime.month, timeZonedTime.day);
    } else {
      // Create dates in local time
      nowDate = DateTime(now.year, now.month, now.day);
      timeZonedDate = DateTime(timeZonedTime.year, timeZonedTime.month, timeZonedTime.day);
    }

    // Calculate the difference in days based on the dates
    int differenceInDays = timeZonedDate.difference(nowDate).inDays;

    // Format the hour according to the specified time format settings
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

    // Determine the appropriate suffix based on the difference in days
    if (differenceInDays == 0) {
      // If the event is today, optionally append "today"
      suffix = includeToday ? ' today' : '';
    } else if (differenceInDays == 1) {
      // If the event is tomorrow
      suffix = ' tomorrow';
    } else if (differenceInDays > 1) {
      // If the event is in multiple days
      suffix = ' in $differenceInDays days';
    } else {
      // If the event is in the past, indicate "yesterday"
      suffix = includeYesterday ? ' yesterday' : '';
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
