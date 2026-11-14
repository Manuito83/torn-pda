import 'package:torn_pda/models/chat/chat_faction_ops.dart';
import 'package:torn_pda/models/chat/chat_retal.dart';
import 'package:torn_pda/models/chat/chat_time.dart';
import 'package:torn_pda/models/chat/chat_watch.dart';

/// Hit, join and watch lines, shortened
String chatShortText(String text, DateTime sentAt, {String Function(DateTime at)? clock}) {
  if (!text.startsWith('[') &&
      !text.startsWith('Hitting ') &&
      !text.contains('oining ') &&
      !text.startsWith('Retal ')) {
    return text;
  }
  if (chatHitCallOf(text, sentAt) case final hit?) return 'Hitting ${hit.name} in ${hit.seconds}s';
  if (chatRetalCallOf(text, sentAt) case final retal?) {
    return ['Retal available: ${retal.name}', ?retal.stats, 'until ${(clock ?? chatTctText)(retal.until)}'].join(' - ');
  }
  if (chatJoinOf(text) case final join?) return '${join.joining ? 'Joining' : 'Not joining'} ${join.name}';
  final shown = clock ?? chatTctText;
  final from = (clock ?? chatTct)(sentAt);
  return switch (chatWatchOf(text, sentAt)) {
    (kind: ChatWatchKind.watching, :final at?) => 'On watch from $from to ${shown(at)}',
    (kind: ChatWatchKind.done, at: _) => 'Done watching',
    (kind: ChatWatchKind.relief, :final at?) => 'Chain watcher needed from ${shown(at)}',
    (kind: ChatWatchKind.relief, at: null) => 'Chain watcher needed',
    _ => text,
  };
}
