import 'package:torn_pda/models/chat/chat_faction_ops.dart';
import 'package:torn_pda/models/chat/chat_links.dart';
import 'package:torn_pda/models/chat/chat_time.dart';
import 'package:torn_pda/utils/number_formatter.dart';

class ChatRetal {
  const ChatRetal({required this.id, required this.name, required this.expiry, this.stats});

  final int id;
  final String name;
  final DateTime expiry;

  /// "1.2B (spy)", "~350M (FFS)" or "2M-25M (est.)"
  final String? stats;
}

const String chatRetalLinePrefix = 'local-retal-';

String chatRetalLineId(ChatRetal retal) =>
    '$chatRetalLinePrefix${retal.id}-${retal.expiry.millisecondsSinceEpoch ~/ 1000}';

({int id, DateTime expiry})? chatRetalLineOf(String id) {
  if (!id.startsWith(chatRetalLinePrefix)) return null;
  final parts = id.substring(chatRetalLinePrefix.length).split('-');
  final (player, expiry) = (int.tryParse(parts.first), int.tryParse(parts.last));
  if (parts.length != 2 || player == null || expiry == null) return null;
  return (id: player, expiry: DateTime.fromMillisecondsSinceEpoch(expiry * 1000));
}

/// The clock goes in the widget
String chatRetalLine(ChatRetal retal) => ['Retal: ${retal.name}', ?retal.stats].join(' - ');

/// Spy, then FFS, then estimate, like Settings
String? chatRetalStats({
  int spy = -1,
  DateTime? spyAt,
  String? ffs,
  String estimated = '',
  int ffsOverSpyMonths = 0,
  required DateTime now,
}) {
  final spyOld = spyAt != null && ffsOverSpyMonths > 0 && now.difference(spyAt).inDays ~/ 30 >= ffsOverSpyMonths;
  if (spy > 0 && !(spyOld && ffs != null)) return '${formatBigNumbers(spy)} (spy)';
  if (ffs != null) return '~$ffs (FFS)';
  if (estimated.isEmpty) return null;
  return '${estimated.replaceAll(' ', '')} (est.)';
}

class ChatRetalCall {
  const ChatRetalCall({required this.name, required this.id, required this.until, this.stats});

  final String name;
  final int id;
  final DateTime until;
  final String? stats;
}

final RegExp _retalCall = RegExp(
  r'^(?:\[PDA\] )?Retal available: ([\w-]+)(?: - ([^\n]{1,40}?))? - until (\d\d):(\d\d):(\d\d) TCT'
  r' - https://www\.torn\.com/(?:loader|page)\.php\?sid=attack&user2ID=(\d{1,10})$',
);

String chatRetalCallText(ChatRetal retal) => [
  '${chatPdaMark}Retal available: ${retal.name}',
  ?retal.stats,
  'until ${chatTct(retal.expiry, seconds: true)} TCT',
  '$chatAttackUrl${retal.id}',
].join(' - ');

/// Null unless the whole text is a retal notice
ChatRetalCall? chatRetalCallOf(String text, DateTime sentAt) {
  final match = _retalCall.firstMatch(text);
  if (match == null) return null;
  final [hour, minute, second] = [for (var i = 3; i <= 5; i++) int.parse(match[i]!)];
  if (hour > 23 || minute > 59 || second > 59) return null;
  final sent = sentAt.toUtc();
  var until = DateTime.utc(sent.year, sent.month, sent.day, hour, minute, second);
  // Midnight in TCT before the end
  if (until.difference(sent) < const Duration(hours: -12)) until = until.add(const Duration(days: 1));
  if (until.difference(sent) > const Duration(hours: 12)) until = until.subtract(const Duration(days: 1));
  final ahead = until.difference(sent);
  if (ahead < const Duration(minutes: -1) || ahead > const Duration(minutes: 6)) return null;
  return ChatRetalCall(name: match[1]!, id: int.parse(match[6]!), until: until, stats: match[2]);
}
