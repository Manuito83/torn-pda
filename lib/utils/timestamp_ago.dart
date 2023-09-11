// Package imports:
import 'package:intl/intl.dart';

String readTimestamp(int timestamp) {
  final now = DateTime.now();
  final format = DateFormat('HH:mm');
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  final diff = now.difference(date);
  var time = '';

  if (diff.inSeconds <= 0 || diff.inSeconds > 0 && diff.inMinutes == 0 || diff.inMinutes > 0 && diff.inHours == 0 || diff.inHours > 0 && diff.inDays == 0) {
    time = format.format(date);
  } else if (diff.inDays > 0 && diff.inDays < 7) {
    if (diff.inDays == 1) {
      time = '${diff.inDays} day ago';
    } else {
      time = '${diff.inDays} days ago';
    }
  } else {
    if (diff.inDays == 7) {
      time = '${(diff.inDays / 7).floor()} week ago';
    } else {
      time = '${(diff.inDays / 7).floor()} weeks ago';
    }
  }

  return time;
}
