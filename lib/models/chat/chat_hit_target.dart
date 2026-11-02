import 'dart:math' as math;

import 'package:torn_pda/models/chat/chat_faction_ops.dart';

enum ChatHitState { ok, hospital, jail, traveling, abroad, other }

class ChatHitTarget {
  const ChatHitTarget({
    required this.id,
    required this.name,
    this.level,
    this.state = ChatHitState.ok,
    this.until,
    this.place,
  });

  factory ChatHitTarget.fromStatus({
    required int id,
    required String name,
    int? level,
    String? state,
    int? until,
    String? description,
  }) {
    final kind = switch (state) {
      'Okay' => ChatHitState.ok,
      'Hospital' => ChatHitState.hospital,
      'Jail' => ChatHitState.jail,
      'Traveling' => ChatHitState.traveling,
      'Abroad' => ChatHitState.abroad,
      _ => ChatHitState.other,
    };
    return ChatHitTarget(
      id: id,
      name: name,
      level: level,
      state: kind,
      until: until == null || until <= 0 ? null : DateTime.fromMillisecondsSinceEpoch(until * 1000),
      place: kind == ChatHitState.abroad ? description?.replaceFirst(RegExp(r'^In '), '') : state,
    );
  }

  final int id;
  final String name;
  final int? level;
  final ChatHitState state;
  final DateTime? until;

  /// Country abroad, raw state when other
  final String? place;

  bool readyAt(DateTime now) =>
      state == ChatHitState.ok ||
      ((state == ChatHitState.hospital || state == ChatHitState.jail) && until != null && !until!.isAfter(now));
}

/// Id Join opens, null when doubtful
int? chatJoinTargetOf(ChatHitCall call, Iterable<ChatHitTarget> known) {
  bool sameName(ChatHitTarget t) => t.name.toLowerCase() == call.name.toLowerCase();
  final id = call.id;
  if (id == null) return known.where(sameName).firstOrNull?.id;
  final listed = known.where((t) => t.id == id).firstOrNull;
  return listed == null || sameName(listed) ? id : null;
}

/// First one ready, else the first
int chatFirstReady(List<ChatHitTarget> targets, DateTime now) => math.max(0, targets.indexWhere((t) => t.readyAt(now)));

/// Earliest release ahead of the first ready
DateTime? chatNextReadyChange(List<ChatHitTarget> targets, DateTime now) {
  final first = targets.indexWhere((t) => t.readyAt(now));
  final ends = [
    for (final t in first < 0 ? targets : targets.take(first))
      if (t.until != null && t.until!.isAfter(now)) t.until!,
  ];
  return ends.isEmpty ? null : ends.reduce((a, b) => a.isBefore(b) ? a : b);
}
