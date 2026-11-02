import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// Chat times in the zone and format shown
class ChatClock {
  ChatClock({required this.tornTime, this.h12 = false});

  final bool tornTime;
  final bool h12;

  @visibleForTesting
  Duration localOffset(DateTime at) => at.toLocal().timeZoneOffset;

  /// Chat zone time, as UTC
  DateTime wallClock(DateTime at) => at.toUtc().add(tornTime ? Duration.zero : localOffset(at));

  String clock(DateTime at) => clockOf(wallClock(at));

  /// [wall] already in the zone shown
  String clockOf(DateTime wall) => DateFormat(h12 ? 'h:mm a' : 'HH:mm').format(wall);

  String minutesClock(int minutes) => clockOf(DateTime.utc(2000, 1, 1, minutes ~/ 60, minutes % 60));

  /// Time, with the date if not today
  String stamp(DateTime at) {
    final time = clock(at);
    return switch (daysFrom(DateTime.now(), at)) {
      0 => time,
      1 => 'tomorrow $time',
      _ => '${DateFormat.MMMd().format(wallClock(at))}, $time',
    };
  }

  /// Device time, "tomorrow" if another day
  String localClock(DateTime at, DateTime now) {
    final here = at.toLocal();
    final today = now.toLocal();
    final days = DateTime(
      here.year,
      here.month,
      here.day,
    ).difference(DateTime(today.year, today.month, today.day)).inDays;
    final day = switch (days) {
      0 => '',
      1 => ' tomorrow',
      -1 => ' yesterday',
      _ => ' (${DateFormat.MMMd().format(here)})',
    };
    return '${clockOf(here)}$day';
  }

  /// Next [hour]:[minute] in chat time
  DateTime nextAt(int hour, int minute, DateTime now) {
    final (wall, here) = (wallClock(now), now.toLocal());
    var at = tornTime
        ? DateTime.utc(wall.year, wall.month, wall.day, hour, minute).toLocal()
        : DateTime(here.year, here.month, here.day, hour, minute);
    if (!at.isAfter(now)) at = at.add(const Duration(days: 1));
    return at;
  }

  /// Calendar days, negative if earlier
  int daysFrom(DateTime now, DateTime at) {
    final (x, y) = (wallClock(now), wallClock(at));
    return DateTime.utc(y.year, y.month, y.day).difference(DateTime.utc(x.year, x.month, x.day)).inDays;
  }

  bool sameDay(DateTime a, DateTime b) => daysFrom(a, b) == 0;
}

/// An explicit "18:00 TCT" in a message
class ChatTimeRef {
  const ChatTimeRef(this.hour, this.minute, this.raw);

  final int hour;
  final int minute;
  final String raw;

  static final RegExp _pattern = RegExp(
    r'(?<![\w:.])(\d{1,2})(?::(\d{2})|h(\d{2})?)?(?:\s?(am|pm))?\s?(?:tct|tc)(?![A-Za-z0-9])',
    caseSensitive: false,
  );

  // A date makes the day unknown
  static final RegExp _dated = RegExp(
    r'(\d[-/.]\d{1,2}|(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\.? \d{1,2}(st|nd|rd|th)?)[ ,]*(at |@ ?)?$',
    caseSensitive: false,
  );

  static List<Object> split(String text) {
    final parts = <Object>[];
    var last = 0;
    for (final match in _pattern.allMatches(text)) {
      final raw = match.group(0)!;
      final hasMinutes = match.group(2) != null || raw.toLowerCase().contains('h');
      final meridiem = match.group(4)?.toLowerCase();
      if (!hasMinutes && meridiem == null) continue;
      var hour = int.parse(match.group(1)!);
      final minute = int.tryParse(match.group(2) ?? match.group(3) ?? '0')!;
      if (meridiem != null) {
        if (hour < 1 || hour > 12) continue;
        hour = hour % 12 + (meridiem == 'pm' ? 12 : 0);
      }
      if (hour > 23 || minute > 59) continue;
      if (_dated.hasMatch(text.substring(0, match.start))) continue;
      if (match.start > last) parts.add(text.substring(last, match.start));
      parts.add(ChatTimeRef(hour, minute, raw));
      last = match.end;
    }
    if (last < text.length) parts.add(text.substring(last));
    return parts;
  }

  /// Next one, or today's within the hour
  DateTime occurrence(DateTime now) {
    final utc = now.toUtc();
    final today = DateTime.utc(utc.year, utc.month, utc.day, hour, minute);
    return today.isBefore(utc.subtract(const Duration(hours: 1))) ? today.add(const Duration(days: 1)) : today;
  }

  /// "in 2h 5m" or "20m ago"
  static String relative(DateTime at, DateTime now) {
    final seconds = at.difference(now).inSeconds;
    if (seconds.abs() < 60) return seconds >= 0 ? 'now' : 'just now';
    final minutes = seconds.abs() ~/ 60;
    final text = minutes >= 48 * 60
        ? '${minutes ~/ (24 * 60)}d'
        : minutes >= 60
        ? (minutes % 60 == 0 ? '${minutes ~/ 60}h' : '${minutes ~/ 60}h ${minutes % 60}m')
        : '${minutes}m';
    return seconds > 0 ? 'in $text' : '$text ago';
  }
}

String _two(int n) => n.toString().padLeft(2, '0');

String chatTct(DateTime at, {bool seconds = false}) {
  final t = at.toUtc();
  return '${_two(t.hour)}:${_two(t.minute)}${seconds ? ':${_two(t.second)}' : ''}';
}

/// Without the app clock
String chatTctText(DateTime at) => '${chatTct(at)} TCT';

/// Screen reader time, words instead of "5m"
String chatSpokenTime(ChatClock clock, DateTime at) {
  final gap = DateTime.now().difference(at);
  if (gap.inMinutes < 1) return 'just now';
  if (gap.inMinutes < 60) return gap.inMinutes == 1 ? '1 minute ago' : '${gap.inMinutes} minutes ago';
  if (gap.inHours < 24) return gap.inHours == 1 ? '1 hour ago' : '${gap.inHours} hours ago';
  return clock.stamp(at);
}
