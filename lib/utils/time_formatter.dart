// Package imports:
import 'package:intl/intl.dart';

// Project imports:
import 'package:torn_pda/providers/settings_provider.dart';

class TimeFormatter {
  final DateTime? inputTime;
  final TimeFormatSetting timeFormatSetting;
  final TimeZoneSetting timeZoneSetting;

  TimeFormatter({required this.inputTime, required this.timeFormatSetting, required this.timeZoneSetting});

  /// Returns the formatted hour with timezone identifier
  ///
  /// Examples:
  /// - 24h format + Local Time: "14:35 LT"
  /// - 12h format + Local Time: "02:35 PM LT"
  /// - 24h format + Torn Time: "19:35 TCT"
  /// - 12h format + Torn Time: "07:35 PM TCT"
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

  /// Returns the formatted hour with relative day information
  ///
  /// Examples:
  /// - Same day: "14:35 LT" (no suffix by default)
  /// - Same day with includeToday: "14:35 LT today"
  /// - Next day: "14:35 LT tomorrow"
  /// - Future days: "14:35 LT in 3 days"
  /// - Previous day with includeYesterday: "14:35 LT yesterday"
  /// - Past days: "14:35 LT" (no suffix by default)
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

  /// Returns the day of the week with "on" prefix
  ///
  /// Examples:
  /// - Monday: "on Monday"
  /// - Wednesday: "on Wednesday"
  /// - Sunday: "on Sunday"
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

  /// Returns the month and day in abbreviated format
  ///
  /// Examples:
  /// - January 5th: "Jan 05"
  /// - March 15th: "Mar 15"
  /// - December 25th: "Dec 25"
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

  /// Returns the formatted hour with timezone (same as formatHour but different method)
  ///
  /// Examples:
  /// - 24h format + Local Time: "14:35 LT"
  /// - 12h format + Local Time: "02:35 PM LT"
  /// - 24h format + Torn Time: "19:35 TCT"
  /// - 12h format + Torn Time: "07:35 PM TCT"
  String get formatHourWithDate {
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
    return hourFormatted;
  }

  /// Returns the day and month in DD MMM format
  ///
  /// Examples:
  /// - January 5th: "05 Jan"
  /// - March 15th: "15 Mar"
  /// - December 25th: "25 Dec"
  String? get formatDayMonth {
    late DateTime timeZonedTime;
    switch (timeZoneSetting) {
      case TimeZoneSetting.localTime:
        timeZonedTime = inputTime!.toLocal();
      case TimeZoneSetting.tornTime:
        timeZonedTime = inputTime!.toUtc();
    }

    final formatter = DateFormat('dd MMM');
    return formatter.format(timeZonedTime);
  }

  /// Returns the formatted hour combined with day and month
  ///
  /// Examples:
  /// - 24h format + Local Time: "14:35 LT, 15 Mar"
  /// - 12h format + Local Time: "02:35 PM LT, 05 Jan"
  /// - 24h format + Torn Time: "19:35 TCT, 25 Dec"
  /// - 12h format + Torn Time: "07:35 PM TCT, 01 Apr"
  String get formatHourAndDayMonth {
    final hourPart = formatHourWithDate;
    final dayMonthPart = formatDayMonth;
    return '$hourPart, $dayMonthPart';
  }

  /// Returns the time elapsed since the input time in human-readable format
  ///
  /// Examples:
  /// - Less than 1 minute: "seconds"
  /// - Exactly 1 minute: "1 minute"
  /// - Multiple minutes: "15 minutes"
  /// - Exactly 1 hour: "1 hour"
  /// - Hour + minutes: "2 hours, 30 minutes"
  /// - Exactly 1 day: "1 day"
  /// - Day + hours: "3 days, 5 hours"
  /// - Day + hours + minutes: "2 days, 4 hours, 15 minutes"
  /// - Large periods: "45 days, 12 hours, 30 minutes"
  String get formatTimeAgo {
    late DateTime now;
    late DateTime timeToCompare;

    switch (timeZoneSetting) {
      case TimeZoneSetting.localTime:
        now = DateTime.now();
        timeToCompare = inputTime!.toLocal();
        break;
      case TimeZoneSetting.tornTime:
        now = DateTime.now().toUtc();
        timeToCompare = inputTime!.toUtc();
        break;
    }

    final Duration difference = now.difference(timeToCompare);

    if (difference.inSeconds < 60) {
      return "seconds";
    }

    List<String> parts = [];
    int days = difference.inDays;
    int hours = difference.inHours % 24;
    int minutes = difference.inMinutes % 60;

    if (days > 0) {
      parts.add("$days ${days == 1 ? 'day' : 'days'}");
    }
    if (hours > 0) {
      parts.add("$hours ${hours == 1 ? 'hour' : 'hours'}");
    }
    if (minutes > 0) {
      parts.add("$minutes ${minutes == 1 ? 'minute' : 'minutes'}");
    }

    return parts.isEmpty ? "seconds" : parts.join(", ");
  }
}
