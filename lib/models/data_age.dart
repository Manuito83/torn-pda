import 'package:torn_pda/models/chat/chat_time.dart';

/// Null under a minute old
String? dataAgeText(int? epochSeconds, {DateTime? now}) {
  if (epochSeconds == null || epochSeconds <= 0) return null;
  final at = DateTime.fromMillisecondsSinceEpoch(epochSeconds * 1000);
  final time = now ?? DateTime.now();
  return time.difference(at).inSeconds < 60 ? null : ChatTimeRef.relative(at, time);
}
