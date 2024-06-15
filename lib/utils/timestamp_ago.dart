// Package imports:
import 'package:intl/intl.dart';

String readTimestamp(int timestamp) {
  final now = DateTime.now().toUtc();
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  final diff = now.difference(date);
  var time = '';

  if (diff.inSeconds <= 0 ||
      diff.inSeconds > 0 && diff.inMinutes == 0 ||
      diff.inMinutes > 0 && diff.inHours == 0 ||
      diff.inHours > 0 && diff.inDays == 0) {
    time = '${DateFormat('HH:mm').format(date)} TCT';
  } else if (diff.inDays > 0 && diff.inDays < 7) {
    time = '${diff.inDays} ${diff.inDays == 1 ? 'day' : 'days'} ago';
  } else if (diff.inDays >= 7 && diff.inDays < 30) {
    time = '${(diff.inDays / 7).floor()} ${((diff.inDays / 7).floor() == 1) ? 'week' : 'weeks'} ago';
  } else if (diff.inDays >= 30 && diff.inDays < 365) {
    time = '${(diff.inDays / 30).floor()} ${((diff.inDays / 30).floor() == 1) ? 'month' : 'months'} ago';
  } else {
    time = '${(diff.inDays / 365).floor()} ${((diff.inDays / 365).floor() == 1) ? 'year' : 'years'} ago';
  }

  return time;
}
