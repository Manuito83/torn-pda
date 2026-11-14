import 'package:torn_pda/models/chaining/ranked_wars_model.dart';
import 'package:torn_pda/models/chat/chat_links.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_money.dart';
import 'package:torn_pda/models/chat/chat_time.dart';

enum ChatChainLevel { ok, caution, danger, cooldown }

class ChatChain {
  const ChatChain({required this.hits, required this.seconds, this.cooldown = false, this.bonus});

  final int hits;
  final int seconds;
  final bool cooldown;
  final int? bonus;

  // API counts, not the local clock
  bool get alive => !cooldown && hits > 0;

  bool get running => !cooldown && hits > 0 && seconds > 0;

  bool get shown => running || cooldown;

  // Same cut points as the floating window
  ChatChainLevel get level {
    if (cooldown) return ChatChainLevel.cooldown;
    return hits < 10 ? ChatChainLevel.ok : chatChainLevelAt(seconds);
  }
}

/// Level by the clock once hits count
ChatChainLevel chatChainLevelAt(int seconds) => seconds < 60
    ? ChatChainLevel.danger
    : seconds < 150
    ? ChatChainLevel.caution
    : ChatChainLevel.ok;

/// Chain Watcher threshold, null when off
class ChatChainAlarm {
  double? threshold;

  bool under(ChatChain chain) {
    final limit = threshold;
    return limit != null && chain.running && chain.hits >= 10 && chain.seconds <= limit;
  }
}

const String chatChainLinePrefix = 'local-chain-';

String chatChainLineId(DateTime at) => '$chatChainLinePrefix${at.millisecondsSinceEpoch}';

/// When the local chain line runs out
DateTime? chatChainLineAt(String id) {
  if (!id.startsWith(chatChainLinePrefix)) return null;
  final millis = int.tryParse(id.substring(chatChainLinePrefix.length));
  return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
}

class ChatWar {
  const ChatWar({
    required this.ours,
    required this.theirs,
    required this.enemy,
    required this.start,
    this.target,
    this.enemyId,
  });

  final int ours;
  final int theirs;
  final String enemy;
  final DateTime start;
  final int? target;
  final int? enemyId;
}

/// "0:45", "4:30" or "1:02:03"
String chatClock(Duration d) {
  final s = d.isNegative ? 0 : d.inSeconds;
  final mm = (s ~/ 60 % 60).toString();
  final ss = (s % 60).toString().padLeft(2, '0');
  if (s < 3600) return '$mm:$ss';
  return '${s ~/ 3600}:${mm.padLeft(2, '0')}:$ss';
}

/// "45m" or "5h 12m"
String chatSpan(Duration d) {
  final m = d.isNegative ? 0 : d.inMinutes;
  return m < 60 ? '${m}m' : '${m ~/ 60}h ${m % 60}m';
}

String chatChainLine(int seconds) => 'Chain at ${chatClock(Duration(seconds: seconds))}';

/// "312/500", only hits in cooldown
String chatChainCount(ChatChain chain) {
  final hits = chatCount(chain.hits);
  final bonus = chain.bonus;
  if (chain.cooldown || bonus == null || bonus <= chain.hits) return hits;
  return '$hits/${chatCount(bonus)}';
}

String chatWarScore(ChatWar war) => '${chatCount(war.ours)} : ${chatCount(war.theirs)}';

/// "+254" or "-120"
String chatWarLead(ChatWar war) {
  final lead = war.ours - war.theirs;
  return '${lead < 0 ? '-' : '+'}${chatCount(lead.abs())}';
}

const int chatHitCallMax = 600;

/// Marks the lines PDA reads
const String chatPdaMark = '[PDA] ';

final RegExp _hitCall = RegExp(
  r'^(?:\[PDA\] )?Hitting ([\w-]+) in (\d{1,3})s - at (\d\d):(\d\d):(\d\d) TCT'
  r'(?: - https://www\.torn\.com/(?:loader|page)\.php\?sid=attack&user2ID=(\d+))?$',
);

/// Link for the web chat
String chatHitCallText(String name, int seconds, DateTime sentAt, {int? id}) {
  final at = sentAt.toUtc().add(Duration(seconds: seconds));
  final link = id == null ? '' : ' - $chatAttackUrl$id';
  return '${chatPdaMark}Hitting $name in ${seconds}s - at ${chatTct(at, seconds: true)} TCT$link';
}

class ChatHitCall {
  const ChatHitCall({required this.name, required this.seconds, required this.at, this.id});

  final String name;
  final int seconds;
  final DateTime at;

  /// Null from older builds
  final int? id;
}

/// Null unless the whole text is a call, counts from [sentAt]
ChatHitCall? chatHitCallOf(String text, DateTime sentAt) {
  final match = _hitCall.firstMatch(text);
  if (match == null) return null;
  final [seconds, hour, minute, second] = [for (var i = 2; i <= 5; i++) int.parse(match[i]!)];
  if (seconds < 1 || seconds > chatHitCallMax || hour > 23 || minute > 59 || second > 59) return null;
  final at = sentAt.toUtc().add(Duration(seconds: seconds));
  var said = DateTime.utc(at.year, at.month, at.day, hour, minute, second);
  // Midnight in TCT between send and hit
  if (said.difference(at) > const Duration(hours: 12)) said = said.subtract(const Duration(days: 1));
  if (at.difference(said) > const Duration(hours: 12)) said = said.add(const Duration(days: 1));
  if (said.difference(at).abs() > const Duration(minutes: 5)) return null;
  final id = match[6];
  return ChatHitCall(name: match[1]!, seconds: seconds, at: at, id: id == null ? null : int.tryParse(id));
}

enum ChatHitJoinState { armed, disarmed, offered, launched, missed }

const Duration chatHitOpenEarly = Duration(seconds: 5);

/// The one call this player armed, own or joined
class ChatHitJoin {
  const ChatHitJoin({
    required this.messageId,
    this.roomId = 'faction',
    required this.id,
    required this.name,
    required this.at,
    required this.opens,
    this.own = false,
    this.state = ChatHitJoinState.armed,
  });

  /// Five seconds early, or right away
  factory ChatHitJoin.arm({
    required String messageId,
    required String roomId,
    required int id,
    required String name,
    required DateTime at,
    required DateTime now,
    bool own = false,
  }) {
    final early = at.subtract(chatHitOpenEarly);
    return ChatHitJoin(
      messageId: messageId,
      roomId: roomId,
      id: id,
      name: name,
      at: at,
      opens: early.isAfter(now) ? early : now,
      own: own,
    );
  }

  final String messageId;
  final String roomId;
  final int id;
  final String name;
  final DateTime at;

  /// When the attack page opens
  final DateTime opens;
  final bool own;
  final ChatHitJoinState state;

  /// Still meant to hit, armed or not
  bool get pending => state == ChatHitJoinState.armed || state == ChatHitJoinState.disarmed;

  bool isFor(ChatMessage m) => m.id == messageId || m.reqId == messageId;

  ChatHitJoin copyWith({ChatHitJoinState? state, DateTime? at, DateTime? opens}) => ChatHitJoin(
    messageId: messageId,
    roomId: roomId,
    id: id,
    name: name,
    at: at ?? this.at,
    opens: opens ?? this.opens,
    own: own,
    state: state ?? this.state,
  );
}

final RegExp _joinLine = RegExp(r'^(?:\[PDA\] )?(Joining|Not joining) ([\w-]+)$');

String chatJoinText(String name, {bool joining = true}) =>
    '$chatPdaMark${joining ? 'Joining' : 'Not joining'} $name';

({String name, bool joining})? chatJoinOf(String text) {
  final match = _joinLine.firstMatch(text);
  return match == null ? null : (name: match[2]!, joining: match[1] == 'Joining');
}

/// Sent while the call counted, same target
bool chatJoinFits(ChatMessage line, ChatMessage call, ChatHitCall hit) {
  if (line.isSystem || line.state != ChatMessageState.sent) return false;
  if (line.createdAt.isBefore(call.createdAt) || line.createdAt.isAfter(hit.at)) return false;
  return chatJoinOf(line.content)?.name.toLowerCase() == hit.name.toLowerCase();
}

/// Each player's last word counts
List<ChatUser> chatJoinersOf(ChatMessage call, ChatHitCall hit, Iterable<ChatMessage> messages) {
  final last = <int, ChatMessage>{};
  for (final m in messages) {
    if (!chatJoinFits(m, call, hit)) continue;
    final old = last[m.sender.id];
    if (old == null || !old.createdAt.isAfter(m.createdAt)) last[m.sender.id] = m;
  }
  return [
    for (final m in last.values)
      if (chatJoinOf(m.content)!.joining) m.sender,
  ];
}

List<(ChatMessage, ChatHitCall)> _callsIn(Iterable<ChatMessage> messages) => [
  for (final m in messages)
    if (!m.isSystem)
      if (chatHitCallOf(m.content, m.createdAt) case final hit?) (m, hit),
];

/// Join lines a call in the room explains
Set<String> chatJoinsFolded(List<ChatMessage> messages) {
  final calls = _callsIn(messages);
  if (calls.isEmpty) return const {};
  return {
    for (final m in messages)
      if (chatJoinOf(m.content) != null && calls.any((c) => chatJoinFits(m, c.$1, c.$2))) m.id,
  };
}

bool chatJoinFolds(ChatMessage line, Iterable<ChatMessage> room) =>
    chatJoinOf(line.content) != null && _callsIn(room).any((c) => chatJoinFits(line, c.$1, c.$2));

enum ChatHitPhase { counting, now, done }

/// Seconds left rounded up, bar fill
({int seconds, double fill, ChatHitPhase phase}) chatHitCountdown(ChatHitCall call, DateTime now) {
  final left = call.at.difference(now).inMilliseconds;
  final seconds = (left / 1000).ceil();
  final phase = left > 0
      ? ChatHitPhase.counting
      : left > -3000
      ? ChatHitPhase.now
      : ChatHitPhase.done;
  return (seconds: seconds, fill: (left / (call.seconds * 1000)).clamp(0.0, 1.0), phase: phase);
}

ChatWar? warOf(RankedWar? war, int factionId, DateTime now) {
  final info = war?.war;
  final factions = war?.factions;
  if (info?.start == null || factions == null || (info!.end ?? 0) != 0) return null;
  final start = DateTime.fromMillisecondsSinceEpoch(info.start! * 1000);
  final ours = factions['$factionId'];
  final other = factions.entries.where((e) => e.key != '$factionId').firstOrNull;
  final enemy = other?.value;
  if (start.isAfter(now) || ours == null || enemy == null) return null;
  return ChatWar(
    ours: ours.score ?? 0,
    theirs: enemy.score ?? 0,
    enemy: enemy.name ?? 'Enemy',
    start: start,
    target: info.target,
    enemyId: int.tryParse(other!.key),
  );
}
