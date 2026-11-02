import 'package:torn_pda/models/chat/chat_faction_ops.dart';
import 'package:torn_pda/models/chat/chat_watch.dart';

class ChatFactionNow {
  const ChatFactionNow({
    this.chain,
    this.war,
    this.live = false,
    this.watcher = false,
    this.panic = false,
    this.panicReady = false,
    this.watches = const {},
    this.me,
  });

  final ChatChain? chain;
  final ChatWar? war;
  final bool live;
  final bool watcher;
  final bool panic;

  /// Panic Mode configured in chain options
  final bool panicReady;

  /// Chain watch by faction room
  final Map<String, ChatWatchRoom> watches;
  final int? me;

  bool get isEmpty => chain == null && war == null;

  bool onWatchIn(String roomId) => watches[roomId]?.state.of(me) != null;

  /// Only for factions that use it
  bool watchShownIn(String roomId) => (watches[roomId]?.state.seen ?? false) && (chain?.running ?? false);
}

String chatChainSpoken(ChatChain chain, ChatFactionNow now, String roomId) {
  final bonus = chain.bonus;
  final watch = now.watchShownIn(roomId) ? now.watches[roomId] : null;
  return [
    if (chain.cooldown)
      'Chain cooldown, ${chain.hits} hits'
    else
      'Chain ${chain.hits}${bonus != null && bonus > chain.hits ? ' of $bonus' : ''} hits',
    '${chatClock(Duration(seconds: chain.seconds))} left',
    if (now.live) 'live',
    if (now.watcher) 'watcher on',
    if (now.panic) 'panic mode on',
    if (watch != null) ...[
      '${watch.state.watchers.length} on watch${watch.short ? ' so far' : ''}',
      if (now.onWatchIn(roomId)) 'you are on watch',
      if (watch.state.reliefs.isNotEmpty) 'relief needed',
    ],
  ].join(', ');
}
