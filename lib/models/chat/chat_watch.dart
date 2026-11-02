import 'package:torn_pda/models/chat/chat_faction_ops.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_retal.dart';
import 'package:torn_pda/models/chat/chat_time.dart';

const Duration chatWatchWindow = Duration(hours: 12);
const Duration chatReliefKept = Duration(minutes: 30);
const Duration chatWatchWarning = Duration(minutes: 5);
const List<int> chatWatchHours = [1, 2, 4, 8];

final String _mark = RegExp.escape(chatPdaMark);
final RegExp _watching = RegExp('^${_mark}Watching the chain until (\\d\\d):(\\d\\d) TCT\$', caseSensitive: false);
final RegExp _done = RegExp('^${_mark}Done watching the chain\$', caseSensitive: false);
final RegExp _relief = RegExp('^${_mark}Need a chain watcher(?: from (\\d\\d):(\\d\\d) TCT)?\$', caseSensitive: false);

String chatWatchText(DateTime until) => '${chatPdaMark}Watching the chain until ${chatTct(until)} TCT';

const String chatWatchLeaveText = '${chatPdaMark}Done watching the chain';

String chatReliefText(DateTime? from) =>
    '${chatPdaMark}Need a chain watcher${from == null ? '' : ' from ${chatTct(from)} TCT'}';

enum ChatWatchKind { watching, done, relief }

/// Next HH:MM TCT, null past 12 hours
DateTime? _nextTct(String? hour, String? minute, DateTime sentAt) {
  final (h, m) = (int.parse(hour!), int.parse(minute!));
  if (h > 23 || m > 59) return null;
  final t = sentAt.toUtc();
  var at = DateTime.utc(t.year, t.month, t.day, h, m);
  if (!at.isAfter(t)) at = at.add(const Duration(days: 1));
  return at.difference(t) > chatWatchWindow ? null : at;
}

/// Null unless the whole text matches
({ChatWatchKind kind, DateTime? at})? chatWatchOf(String text, DateTime sentAt) {
  if (!text.startsWith('[')) return null;
  if (_done.hasMatch(text)) return (kind: ChatWatchKind.done, at: null);
  if (_watching.firstMatch(text) case final match?) {
    final until = _nextTct(match[1], match[2], sentAt);
    return until == null ? null : (kind: ChatWatchKind.watching, at: until);
  }
  if (_relief.firstMatch(text) case final match?) {
    final from = match[1] == null ? null : _nextTct(match[1], match[2], sentAt);
    return (kind: ChatWatchKind.relief, at: from);
  }
  return null;
}

class ChatWatcher {
  const ChatWatcher({
    required this.user,
    required this.since,
    required this.until,
    required this.said,
    required this.messageId,
  });

  final ChatUser user;
  final DateTime since;
  final DateTime until;

  /// Last time they took or renewed it
  final DateTime said;
  final String messageId;

  ChatWatcher endingAt(DateTime at) =>
      ChatWatcher(user: user, since: since, until: at, said: said, messageId: messageId);
}

class ChatRelief {
  const ChatRelief({required this.user, required this.asked, this.from});

  final ChatUser user;
  final DateTime asked;
  final DateTime? from;

  DateTime get forgotten => (from ?? asked).add(chatReliefKept);
}

typedef ChatTakeover = ({ChatUser asker, ChatUser taker, DateTime at});

class ChatWatchState {
  const ChatWatchState({
    this.seen = false,
    this.cooldown = false,
    this.watchers = const [],
    this.reliefs = const [],
    this.takeovers = const [],
    this.lapsed = const {},
    this.closed = const [],
    this.next,
  });

  /// Any watch line in the window
  final bool seen;
  final bool cooldown;
  final List<ChatWatcher> watchers;
  final List<ChatRelief> reliefs;
  final List<ChatTakeover> takeovers;

  /// Ran out on their own, by player
  final Map<int, DateTime> lapsed;

  /// Ended by the cooldown
  final List<ChatWatcher> closed;

  /// When the clock alone changes it
  final DateTime? next;

  ChatWatcher? of(int? id) => watchers.where((w) => w.user.id == id).firstOrNull;

  /// Asked from watch, else a plain plea
  bool isRelief(ChatRelief r) => of(r.user.id) != null;
}

typedef ChatWatchRoom = ({ChatWatchState state, bool short});

bool _counts(ChatMessage m) => !m.isSystem && !m.isLocal && m.state == ChatMessageState.sent;

/// Each player's last word counts, from [since]
ChatWatchState chatWatchStateOf(
  List<ChatMessage> messages,
  DateTime now, {
  DateTime? since,
  bool cooldown = false,
}) {
  final start = now.subtract(chatWatchWindow);
  final on = <int, ChatWatcher>{};
  final open = <int, ChatRelief>{};
  final lapsed = <int, DateTime>{};
  final takeovers = <ChatTakeover>[];
  DateTime? oldest;

  void expire(DateTime at) {
    on.removeWhere((id, w) {
      if (w.until.isAfter(at)) return false;
      lapsed[id] = w.until;
      return true;
    });
    open.removeWhere((_, r) => !r.forgotten.isAfter(at));
  }

  for (final m in messages) {
    if (!_counts(m) || m.createdAt.isBefore(start)) continue;
    final say = chatWatchOf(m.content, m.createdAt);
    if (say == null) continue;
    oldest ??= m.createdAt;
    if (since != null && m.createdAt.isBefore(since)) continue;
    final (at, user) = (m.createdAt, m.sender);
    expire(at);
    switch (say.kind) {
      case ChatWatchKind.watching:
        for (final r in open.values) {
          if (r.user.id != user.id) takeovers.add((asker: r.user, taker: user, at: at));
        }
        open.clear();
        lapsed.remove(user.id);
        on[user.id] = ChatWatcher(
          user: user,
          since: on[user.id]?.since ?? at,
          until: say.at!,
          said: at,
          messageId: m.id,
        );
      case ChatWatchKind.done:
        lapsed.remove(user.id);
        on.remove(user.id);
        open.remove(user.id);
      case ChatWatchKind.relief:
        if ((on[user.id], say.at) case (final w?, final from?)) on[user.id] = w.endingAt(from);
        open[user.id] = ChatRelief(user: user, asked: at, from: say.at);
    }
  }
  expire(now);

  final watchers = on.values.toList()..sort((a, b) => a.since.compareTo(b.since));
  final ends = [
    for (final w in watchers) w.until,
    for (final r in open.values) r.forgotten,
    ?oldest?.add(chatWatchWindow),
  ];
  return ChatWatchState(
    seen: oldest != null,
    cooldown: cooldown,
    watchers: cooldown ? const [] : watchers,
    reliefs: cooldown ? const [] : open.values.toList(),
    takeovers: cooldown ? const [] : takeovers,
    lapsed: cooldown ? const {} : lapsed,
    closed: cooldown ? watchers : const [],
    next: ends.isEmpty ? null : ends.reduce((a, b) => a.isBefore(b) ? a : b),
  );
}

/// Every watch line but the last
List<String> _watchIds(List<ChatMessage> messages, DateTime now) {
  final start = now.subtract(chatWatchWindow);
  return [
    for (final m in messages)
      if (_counts(m) && !m.createdAt.isBefore(start) && chatWatchOf(m.content, m.createdAt) != null) m.id,
  ];
}

Set<String> chatWatchFolded(List<ChatMessage> messages, DateTime now) {
  final ids = _watchIds(messages, now);
  return ids.length < 2 ? const {} : ids.take(ids.length - 1).toSet();
}

/// The line holding the live card
String? chatWatchAnchor(List<ChatMessage> messages, DateTime now) => _watchIds(messages, now).lastOrNull;

typedef ChatSpecial = ({ChatHitCall? hit, ChatRetalCall? retal, bool watch});

/// Which faction card a message shows
ChatSpecial chatSpecialOf(ChatMessage m, {required bool factionRoom, required DateTime now}) {
  if (!factionRoom) return (hit: null, retal: null, watch: false);
  if (chatHitCallOf(m.content, m.createdAt) case final hit?) return (hit: hit, retal: null, watch: false);
  if (chatRetalCallOf(m.content, m.createdAt) case final retal?) return (hit: null, retal: retal, watch: false);
  final watch =
      m.state == ChatMessageState.sent &&
      now.difference(m.createdAt) < chatWatchWindow &&
      chatWatchOf(m.content, m.createdAt) != null;
  return (hit: null, retal: null, watch: watch);
}

enum ChatWatchLine { relief, nobody, soon, over, ended, cooldown }

const String chatWatchLinePrefix = 'local-watch-';

String chatWatchLineId(ChatWatchLine kind, [int player = 0]) => '$chatWatchLinePrefix${kind.name}-$player';

ChatWatchLine? chatWatchLineOf(String id) {
  if (!id.startsWith(chatWatchLinePrefix)) return null;
  final name = id.substring(chatWatchLinePrefix.length).split('-').first;
  return ChatWatchLine.values.where((k) => k.name == name).firstOrNull;
}

typedef ChatWatchNote = ({ChatWatchLine kind, String text, DateTime at, ChatUser? player});

/// Local lines, [atRisk] while it can break
List<ChatWatchNote> chatWatchNotes(
  ChatWatchState state,
  int? me,
  DateTime now, {
  required bool atRisk,
  String Function(DateTime at) clock = chatTctText,
}) {
  final mine = state.of(me);
  final over = mine == null
      ? null
      : state.takeovers.where((t) => t.asker.id == me && t.taker.id != me && t.at.isAfter(mine.said)).lastOrNull;
  final lapsed = mine == null ? state.lapsed[me] : null;
  return [
    for (final r in state.reliefs)
      if (r.user.id != me)
        (
          kind: ChatWatchLine.relief,
          text: switch ((state.isRelief(r), r.from)) {
            (true, final from?) => '${r.user.name} needs relief from ${clock(from)}',
            (false, final from?) => '${r.user.name} needs a chain watcher from ${clock(from)}',
            (_, null) => '${r.user.name} needs a chain watcher',
          },
          at: r.asked,
          player: r.user,
        ),
    if (atRisk && state.seen && state.watchers.isEmpty)
      (kind: ChatWatchLine.nobody, text: 'No one on watch', at: now, player: null),
    if (mine != null && !mine.until.isAfter(now.add(chatWatchWarning)))
      (
        kind: ChatWatchLine.soon,
        text: 'Your watch ends at ${clock(mine.until)}',
        at: mine.until.subtract(chatWatchWarning),
        player: null,
      ),
    if (over != null) (kind: ChatWatchLine.over, text: '${over.taker.name} took over', at: over.at, player: over.taker),
    if (lapsed != null)
      (kind: ChatWatchLine.ended, text: 'Your watch ended at ${clock(lapsed)}', at: lapsed, player: null),
    if (state.closed.any((w) => w.user.id == me))
      (kind: ChatWatchLine.cooldown, text: 'Chain is over, your watch ended', at: now, player: null),
  ];
}
