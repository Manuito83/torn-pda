import 'package:torn_pda/models/chaining/watch_defcon.dart';

const pipHighlightDuration = Duration(seconds: 30);

// The frame colour already shows the level
String pipWatchLabel(WatchDefcon defcon, {required bool panicMode, required double panicValue}) {
  final panicAt = panicValue.toInt();
  final minutes = (panicAt ~/ 60).toString().padLeft(2, '0');
  final seconds = (panicAt % 60).toString().padLeft(2, '0');
  return switch (defcon) {
    WatchDefcon.panic => 'PANIC!',
    WatchDefcon.apiFail => 'API FAILED',
    WatchDefcon.cooldown || WatchDefcon.off => '',
    _ when panicMode => 'PANIC AT $minutes:$seconds',
    _ => '',
  };
}

class PipPlayer {
  PipPlayer({required this.id, required this.name});

  final int id;
  String name;
  String? state;
  String description = '';
  int until = 0;
  DateTime? changedAt;
  bool error = false;

  bool get highlighted => changedAt != null && DateTime.now().difference(changedAt!) < pipHighlightDuration;

  bool get confined => const ['Hospital', 'Jail', 'Federal'].contains(state);

  int get remaining => until - DateTime.now().millisecondsSinceEpoch ~/ 1000;
}
