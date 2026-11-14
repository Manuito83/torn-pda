import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_money.dart';
import 'package:torn_pda/models/chat/chat_quote.dart';

class ChatBankRequest {
  const ChatBankRequest(this.amount, {this.full = false});

  /// Null for full balance or range
  final int? amount;
  final bool full;
}

enum ChatBankStatus { open, paid, cancelled, replaced }

class ChatBankEntry {
  ChatBankEntry(this.request, {required this.safe});

  final ChatBankRequest request;

  /// Written with the PDA request format
  final bool safe;
  ChatBankStatus status = ChatBankStatus.open;
  ChatUser? paidBy;
}

const String chatBankRoom = 'faction';

bool chatBankAppliesTo(String roomId) => roomId == chatBankRoom;

const String chatBankFullText = 'Bank request: full balance';
const String chatBankCancelText = 'Bank request cancelled';
const String chatBankCallText = 'Any banker online?';

const _keywords = ['bank', 'withdraw', 'balance', 'vault'];

const _units = {
  'k': 1000,
  'thousand': 1000,
  'thousands': 1000,
  'm': 1000000,
  'mil': 1000000,
  'mill': 1000000,
  'million': 1000000,
  'millions': 1000000,
  'b': 1000000000,
  'bn': 1000000000,
  'billion': 1000000000,
  'billions': 1000000000,
};

final String _unit = _units.keys.join('|');
const String _digits = r'(?:\d{1,3}(?:,\d{3})+|\d+(?:\.\d+)?)';
final String _number = '(?:[\$£€]\\s*)?$_digits(?:\\s*(?:$_unit))?';

final RegExp _figure = RegExp(
  '\\b(?:(?<all>all|max(?:imum)?|full|balance)'
  '|(?:between\\s+)?$_number\\s*(?:-|to|\u2013|\u2014|and)\\s*$_number'
  '|(?:[\$£€]\\s*)?(?<value>$_digits)(?:\\s*(?<unit>$_unit))?)\\b',
);

final RegExp _typed = RegExp(
  '^\\s*(?:[\$£€]\\s*)?(?<value>$_digits)\\s*(?<unit>$_unit)?\\s*\$',
  caseSensitive: false,
);

final RegExp _safe = RegExp(r'^Bank request: (?:full balance|\$\d[\d,.]*[kmb]?)$');
final RegExp _paid = RegExp(r'^Paid (?:\$[\d,]+ to )?(?:.+ )?\[(\d+)\]$');

ChatBankRequest? chatBankParse(String text) {
  final lower = text.trim().toLowerCase();
  if (!_keywords.any(lower.contains)) return null;
  final found = _figure.allMatches(lower).toList();
  if (found.isEmpty) return null;
  final pick = found.firstWhere((m) => m.namedGroup('unit') != null, orElse: () => found.last);
  final value = pick.namedGroup('value');
  if (value == null) return ChatBankRequest(null, full: pick.namedGroup('all') != null);
  final total = double.parse(value.replaceAll(',', '')) * (_units[pick.namedGroup('unit')] ?? 1);
  if (total == 0) return null;
  if (total < 1 || total > 1e15) return const ChatBankRequest(null);
  return ChatBankRequest(total.round());
}

/// Amount typed in the request box
int? chatBankParseTyped(String input) {
  final match = _typed.firstMatch(input);
  if (match == null) return null;
  final number = double.tryParse(match.namedGroup('value')!.replaceAll(',', ''));
  if (number == null) return null;
  final total = number * (_units[match.namedGroup('unit')?.toLowerCase()] ?? 1);
  if (total < 1 || total > 1e15) return null;
  return total.round();
}

String chatBankLink(int senderId, ChatBankRequest request) {
  final money = request.full ? 'SEND_FULL' : request.amount?.toString();
  return 'https://www.torn.com/factions.php?step=your#/tab=controls&giveMoneyTo=$senderId'
      '${money == null ? '' : '&money=$money'}';
}

/// Message text that chatBankParse reads back
String chatBankRequestText(int amount) => 'Bank request: \$${_short(amount)}';

String _short(int amount) {
  for (final (unit, letter) in const [(1000000000, 'b'), (1000000, 'm'), (1000, 'k')]) {
    if (amount >= unit && amount % (unit ~/ 100) == 0) {
      final shown = (amount / unit).toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
      return '$shown$letter';
    }
  }
  return chatCount(amount);
}

String chatBankPaidText(ChatUser to, int? amount) {
  final paid = amount == null ? 'Paid' : 'Paid ${ChatMoneyRef.format(amount)} to';
  final named = '$paid ${to.name} [${to.id}]';
  return chatBankParse(named) == null && !named.contains('\n') ? named : '$paid [${to.id}]';
}

String _bodyOf(String content) => ChatQuote.parse(content)?.body ?? content;

Map<String, ChatBankEntry> chatBankDerive(List<ChatMessage> messages) {
  final entries = <String, ChatBankEntry>{};
  final open = <int, ChatBankEntry>{};
  for (final m in messages) {
    if (m.isSystem || m.isLocal || m.state == ChatMessageState.failed) continue;
    if (ChatQuote.forwarded(m.content) != null) continue;
    final body = _bodyOf(m.content).trim();
    final paidTo = int.tryParse(_paid.firstMatch(body)?.group(1) ?? '');
    if (paidTo != null) {
      open.remove(paidTo)
        ?..status = ChatBankStatus.paid
        ..paidBy = m.sender;
      continue;
    }
    if (body.toLowerCase() == chatBankCancelText.toLowerCase()) {
      open.remove(m.sender.id)?.status = ChatBankStatus.cancelled;
      continue;
    }
    final request = chatBankParse(body);
    if (request == null || m.sender.id <= 0) continue;
    final entry = ChatBankEntry(request, safe: _safe.hasMatch(body));
    open[m.sender.id]?.status = ChatBankStatus.replaced;
    open[m.sender.id] = entry;
    entries[m.id] = entry;
  }
  return entries;
}
