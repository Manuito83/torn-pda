import 'package:intl/intl.dart';

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

  /// Takes a time in the device's zone
  static String insertText(DateTime time) => '${DateFormat('HH:mm').format(time.toUtc())} TCT';
}
