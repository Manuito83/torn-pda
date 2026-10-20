import 'package:intl/intl.dart';

/// Amount like "$1.5m" or "850k"
class ChatMoneyRef {
  const ChatMoneyRef(this.amount, this.raw);

  final int amount;
  final String raw;

  static final NumberFormat _money = NumberFormat.decimalPattern('en_US');

  static final RegExp _pattern = RegExp(
    r'(?<![\w.,#:/])(\$)?(\d{1,3}(?:,\d{3})+(?:\.\d+)?|\d+(?:\.\d+)?)(?:(k|m|b)|\s?(mil|mill|million|bil|billion))?'
    r'(?!\w)(?!\.\d)(?!,\d)(?!\s(?:ago|min|mins|minutes|sec|secs|seconds)\b)',
    caseSensitive: false,
  );

  static const Map<String, int> _scale = {
    'k': 1000,
    'm': 1000000,
    'b': 1000000000,
    'mil': 1000000,
    'mill': 1000000,
    'million': 1000000,
    'bil': 1000000000,
    'billion': 1000000000,
  };

  static String format(int amount) => '\$${_money.format(amount)}';

  static List<Object> split(String text) {
    final parts = <Object>[];
    var last = 0;
    for (final match in _pattern.allMatches(text)) {
      final number = match.group(2)!;
      final unit = (match.group(3) ?? match.group(4))?.toLowerCase();
      final separated = number.contains(',');
      // Bare numbers are ids, levels or counts
      if (match.group(1) == null && unit == null && (!separated || number.contains('.'))) continue;
      if (unit == null && number.contains('.')) continue;
      if (unit != null && separated) continue;
      if (number.replaceAll(',', '').length > 12) continue;
      final value = double.parse(number.replaceAll(',', '')) * (unit == null ? 1 : _scale[unit]!);
      if (value < 1) continue;
      if (match.start > last) parts.add(text.substring(last, match.start));
      parts.add(ChatMoneyRef(value.round(), match.group(0)!));
      last = match.end;
    }
    if (last < text.length) parts.add(text.substring(last));
    return parts;
  }

  /// "You have $X on hand: enough"
  String coverage(int onHand) {
    final have = 'You have ${format(onHand)} on hand';
    return onHand >= amount ? '$have: enough' : '$have: short by ${format(amount - onHand)}';
  }
}
