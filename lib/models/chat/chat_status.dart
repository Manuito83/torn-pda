import 'package:torn_pda/models/chaining/bars_model.dart';

class ChatStatusPiece {
  const ChatStatusPiece(this.key, this.label, this.text);

  final String key;
  final String label;
  final String text;
}

/// For "my status" in the message box
class ChatStatus {
  ChatStatus._();

  static const Duration barsMaxAge = Duration(minutes: 5);

  /// 3m 40s, 8m, 2h 5m, 45s
  static String duration(int seconds) {
    if (seconds <= 0) return '0s';
    final units = [
      (seconds ~/ 86400, 'd'),
      (seconds % 86400 ~/ 3600, 'h'),
      (seconds % 3600 ~/ 60, 'm'),
      (seconds % 60, 's'),
    ];
    final first = units.indexWhere((u) => u.$1 > 0);
    return [
      for (final u in units.skip(first).take(2))
        if (u.$1 > 0) '${u.$1}${u.$2}',
    ].join(' ');
  }

  static List<ChatStatusPiece> pieces({
    required BarsStatusCooldownsModel bars,
    required int now,
    int chainCurrent = 0,
    int chainSeconds = 0,
  }) {
    final age = now - (bars.serverTime ?? now);
    final fresh = age <= barsMaxAge.inSeconds;
    final status = bars.status;
    final travel = bars.travel;
    final until = status?.until ?? 0;
    final cooldowns = bars.cooldowns;

    String? bar(PersonalBars? b, String tag) =>
        fresh && b?.current != null && b?.maximum != null ? '$tag ${b!.current}/${b.maximum}' : null;
    int left(int? value) => (value ?? 0) - age;

    final destination = travel?.destination ?? '';
    final landsIn = (travel?.timestamp ?? 0) - now;
    final String? trip = switch (status?.state) {
      'Traveling' when landsIn > 0 && destination.isNotEmpty => 'landing in $destination in ${duration(landsIn)}',
      'Abroad' when destination.isNotEmpty => 'In $destination',
      _ => null,
    };

    final entries = <(String, String, String?)>[
      ('energy', 'Energy', bar(bars.energy, 'E')),
      ('nerve', 'Nerve', bar(bars.nerve, 'N')),
      ('happy', 'Happy', fresh && bars.happy?.current != null ? 'Happy ${bars.happy!.current}' : null),
      ('life', 'Life', bar(bars.life, 'Life')),
      ('travel', 'Travel', trip),
      ('hospital', 'Hospital', status?.state == 'Hospital' && until > now ? 'Hosp ${duration(until - now)}' : null),
      ('jail', 'Jail', status?.state == 'Jail' && until > now ? 'Jail ${duration(until - now)}' : null),
      ('drug', 'Drug cooldown', left(cooldowns?.drug) > 0 ? 'Drug cd ${duration(left(cooldowns?.drug))}' : null),
      (
        'booster',
        'Booster cooldown',
        left(cooldowns?.booster) > 0 ? 'Booster cd ${duration(left(cooldowns?.booster))}' : null,
      ),
      (
        'medical',
        'Medical cooldown',
        left(cooldowns?.medical) > 0 ? 'Medical cd ${duration(left(cooldowns?.medical))}' : null,
      ),
      (
        'chain',
        'Chain',
        chainCurrent > 0 && chainSeconds > 0 ? 'Chain $chainCurrent (${duration(chainSeconds)} left)' : null,
      ),
    ];
    return [
      for (final (key, label, text) in entries)
        if (text != null) ChatStatusPiece(key, label, text),
    ];
  }

  static String compose(List<ChatStatusPiece> pieces, Set<String> on) =>
      pieces.where((p) => on.contains(p.key)).map((p) => p.text).join(' - ');
}

class ChatPlayerStatus {
  const ChatPlayerStatus(this.state, {this.description = '', this.until});

  final String state;
  final String description;
  final DateTime? until;

  static const _ranked = ['Okay', 'Hospital', 'Jail', 'Traveling', 'Abroad', 'Federal', 'Fallen'];

  static ChatPlayerStatus? from(String? state, String? description, dynamic until) {
    if (state == null || state.isEmpty) return null;
    final seconds = until is int ? until : int.tryParse('$until') ?? 0;
    return ChatPlayerStatus(
      state,
      description: description ?? '',
      until: seconds > 0 ? DateTime.fromMillisecondsSinceEpoch(seconds * 1000) : null,
    );
  }

  int get rank {
    final at = _ranked.indexOf(state);
    return at < 0 ? _ranked.length : at;
  }

  /// Null once over, before any refresh
  Duration? left(DateTime now) => until != null && until!.isAfter(now) ? until!.difference(now) : null;

  /// "Hospital 12m 30s", "To Japan", "From Japan", "In Japan"
  String label(DateTime now) {
    const back = 'Returning to Torn from ';
    if (state == 'Traveling' && description.startsWith(back)) return 'From ${description.substring(back.length)}';
    if (state == 'Traveling' && description.contains(' to ')) {
      return 'To ${description.substring(description.lastIndexOf(' to ') + 4)}';
    }
    if (state == 'Abroad' && description.startsWith('In ')) return description;
    final seconds = left(now)?.inSeconds;
    return seconds == null ? state : '$state ${ChatStatus.duration(seconds)}';
  }

  static int compare(ChatPlayerStatus? a, ChatPlayerStatus? b, DateTime now) {
    final ranks = (a?.rank ?? _ranked.length).compareTo(b?.rank ?? _ranked.length);
    if (ranks != 0) return ranks;
    const far = Duration(days: 3650);
    return (a?.left(now) ?? far).compareTo(b?.left(now) ?? far);
  }
}
