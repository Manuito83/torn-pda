// Package imports:
import 'package:intl/intl.dart';

String readTimestamp(int timestamp) {
  var now = DateTime.now();
  var format = DateFormat('HH:mm');
  var date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  var diff = now.difference(date);
  var time = '';

  if (diff.inSeconds <= 0 || diff.inSeconds > 0 && diff.inMinutes == 0 || diff.inMinutes > 0 && diff.inHours == 0 || diff.inHours > 0 && diff.inDays == 0) {
    time = format.format(date);
  } else if (diff.inDays > 0 && diff.inDays < 7) {
    if (diff.inDays == 1) {
      time = diff.inDays.toString() + ' day ago';
    } else {
      time = diff.inDays.toString() + ' days ago';
    }
  } else {
    if (diff.inDays == 7) {
      time = (diff.inDays / 7).floor().toString() + ' week ago';
    } else {
      time = (diff.inDays / 7).floor().toString() + ' weeks ago';
    }
  }

  return time;
}
