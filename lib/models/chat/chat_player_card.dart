import 'package:torn_pda/models/chat/chat_faction_ops.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_money.dart';

enum ChatStatusKind { okay, hospital, jail, travel, other }

class ChatStatusClock {
  final String label;
  final String verb;
  final DateTime until;

  const ChatStatusClock(this.label, this.verb, this.until);

  static ChatStatusClock? parse(Map? status) {
    final until = status?['until'];
    if (until is! int || until <= 0) return null;
    final description = status!['description'];
    final (label, verb) = switch ('${status['state']}'.toLowerCase()) {
      'hospital' => ('In hospital', 'out in'),
      'jail' => ('In jail', 'out in'),
      'traveling' => (description is String && description.isNotEmpty ? description : 'Traveling', 'lands in'),
      _ => ('', ''),
    };
    return label.isEmpty ? null : ChatStatusClock(label, verb, DateTime.fromMillisecondsSinceEpoch(until * 1000));
  }

  String? at(DateTime now) {
    final remaining = until.difference(now);
    if (remaining.inSeconds <= 0) return null;
    return '$label - $verb ${remaining.inDays >= 1 ? ChatPlayerCard.span(remaining) : chatClock(remaining)}';
  }
}

class ChatPlayerCard {
  final int? level;
  final String? factionName;
  final String? factionTag;
  final String? position;
  final ChatStatusKind kind;
  final String? state;
  final String? description;
  final ChatStatusClock? clock;
  final DateTime? lastAction;
  final String? lastActionRelative;
  final ChatPresence? presence;
  final int? life;
  final int? maxLife;
  final int? ageDays;
  final String? discordId;

  const ChatPlayerCard({
    this.level,
    this.factionName,
    this.factionTag,
    this.position,
    this.kind = ChatStatusKind.other,
    this.state,
    this.description,
    this.clock,
    this.lastAction,
    this.lastActionRelative,
    this.presence,
    this.life,
    this.maxLife,
    this.ageDays,
    this.discordId,
  });

  static ChatPlayerCard? fromJson(Map<String, dynamic> json) {
    final p = json['profile'] is Map ? json['profile'] as Map : json;
    if (p['level'] == null && p['status'] is! Map) return null;
    final status = p['status'] is Map ? p['status'] as Map : const {};
    final faction = p['faction'] is Map ? p['faction'] as Map : const {};
    final action = p['last_action'] is Map ? p['last_action'] as Map : const {};
    final life = p['life'] is Map ? p['life'] as Map : const {};
    final state = status['state'] is String ? status['state'] as String : null;
    final stamp = action['timestamp'];
    return ChatPlayerCard(
      level: p['level'] is int ? p['level'] as int : null,
      factionName: _text(faction['name']),
      factionTag: _text(faction['tag']),
      position: _text(faction['position']),
      kind: switch (state?.toLowerCase()) {
        'okay' => ChatStatusKind.okay,
        'hospital' => ChatStatusKind.hospital,
        'jail' => ChatStatusKind.jail,
        'traveling' || 'abroad' => ChatStatusKind.travel,
        _ => ChatStatusKind.other,
      },
      state: state,
      description: _text(status['description']),
      clock: ChatStatusClock.parse(status),
      lastAction: stamp is int && stamp > 0 ? DateTime.fromMillisecondsSinceEpoch(stamp * 1000) : null,
      lastActionRelative: _text(action['relative']),
      presence: ChatPresence.parse(_text(action['status'])),
      life: life['current'] is int ? life['current'] as int : null,
      maxLife: life['maximum'] is int ? life['maximum'] as int : null,
      ageDays: p['age'] is int ? p['age'] as int : null,
      discordId: _discord(json['discord']),
    );
  }

  static String? _discord(Object? v) {
    final id = v is Map ? v['discord_id'] : null;
    return _text(id is int ? '$id' : id);
  }

  static String? _text(Object? v) => v is String && v.trim().isNotEmpty ? v.trim() : null;

  /// "2d 3h", "3h 5m", "12m", "40s"
  static String span(Duration d) {
    if (d.inDays >= 1) return '${d.inDays}d ${d.inHours % 24}h';
    if (d.inHours >= 1) return '${d.inHours}h ${d.inMinutes % 60}m';
    if (d.inMinutes >= 1) return '${d.inMinutes}m';
    return '${d.inSeconds.clamp(0, 59)}s';
  }

  String? statusText(DateTime now) => switch (kind) {
    ChatStatusKind.okay => 'Okay',
    ChatStatusKind.hospital => clock?.at(now) ?? 'Hospital',
    ChatStatusKind.jail => clock?.at(now) ?? 'Jail',
    _ => clock?.at(now) ?? description ?? state,
  };

  String? lastActionText(DateTime now) {
    final at = lastAction;
    if (at != null) {
      final ago = ChatLastAction.ago(at, now);
      return ago == null ? 'Active just now' : 'Last action $ago ago';
    }
    return lastActionRelative == null ? null : 'Last action $lastActionRelative';
  }

  String? get levelText => level == null ? null : 'Lvl $level';

  String? get factionText {
    final name = factionTag != null && factionName != null ? '$factionName [$factionTag]' : factionName;
    if (name == null) return null;
    return position == null ? name : '$name, $position';
  }

  String? get lifeText =>
      life == null || maxLife == null ? null : 'Life ${chatCount(life!)}/${chatCount(maxLife!)}';

  String? get ageText => ageDays == null
      ? null
      : ageDays == 1
      ? '1 day old'
      : '${chatCount(ageDays!)} days old';
}
