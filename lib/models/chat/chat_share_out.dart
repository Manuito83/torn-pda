import 'package:intl/intl.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_price_check.dart';
import 'package:torn_pda/models/chat/chat_status.dart';

/// Texts PDA screens leave in the box
class ChatShareOut {
  ChatShareOut._();

  static String _profileLink(int id) => 'https://www.torn.com/profiles.php?XID=$id';

  /// "Hospital, out in 2h 5m"
  static String condition({String? state, String? description, int? until, required int now}) {
    final left = (until ?? 0) - now;
    return switch (state) {
      null || '' => 'Unknown',
      'Hospital' when left > 0 => 'Hospital, out in ${ChatStatus.duration(left)}',
      'Jail' when left > 0 => 'Jail, out in ${ChatStatus.duration(left)}',
      'Traveling' when left > 0 => '${_text(description, 'Traveling')}, lands in ${ChatStatus.duration(left)}',
      'Traveling' || 'Abroad' => _text(description, state),
      _ => state,
    };
  }

  /// "Name [id], lvl 90, Okay" + link
  static String player({
    required String name,
    required int id,
    int? level,
    String? state,
    String? description,
    int? until,
    required int now,
  }) {
    final parts = [
      '$name [$id]',
      if (level != null && level > 0) 'lvl $level',
      condition(state: state, description: description, until: until, now: now),
    ];
    return '${parts.join(', ')}\n${_profileLink(id)}';
  }

  static String foreignStock({
    required String item,
    required String country,
    required int quantity,
    required int cost,
    required Duration age,
  }) {
    final now = DateTime.now();
    final since = ChatLastAction.ago(now.subtract(age), now);
    return '$item in $country: $quantity at ${money(cost)} (${since == null ? 'just now' : '$since ago'})';
  }

  /// "Ranked war #12: A vs B"
  static String rankedWar({
    required String warId,
    required (String name, int score, int chain) left,
    required (String name, int score, int chain) right,
    int target = 0,
    required List<String> time,
  }) {
    final number = NumberFormat('#,##0', 'en_US');
    final lead = (left.$2 - right.$2).abs();
    return [
      'Ranked war #$warId: ${left.$1} ${number.format(left.$2)} vs ${right.$1} ${number.format(right.$2)}',
      if (target > 0) 'Lead ${number.format(lead)} of ${number.format(target)} needed',
      'Chain ${left.$3} vs ${right.$3}',
      ...time.where((t) => t.isNotEmpty),
    ].join('\n');
  }

  static String money(int value) => value >= 1000 ? '\$${ChatPriceCheck.short(value)}' : '\$$value';

  static String _text(String? text, String fallback) => text == null || text.trim().isEmpty ? fallback : text.trim();
}
