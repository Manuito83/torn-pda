import 'package:torn_pda/models/chat/chat_models.dart';

class ChatQuote {
  ChatQuote._();

  static const int excerptLength = 80;
  static const String _forwardPrefix = 'Forwarded from ';
  static const String _mark = '▎';
  // Old messages open with a plain ">"
  static final RegExp _quoteLine = RegExp(r'^(?:>|▎) ([^:\n]{1,40}): ([^\n]*)\n');

  static String excerpt(String content) {
    final flat = (parse(content)?.body ?? content).replaceAll(RegExp(r'\s+'), ' ').trim();
    return flat.length <= excerptLength ? flat : '${flat.substring(0, excerptLength - 1).trimRight()}…';
  }

  static String reply(ChatMessage to, String text) =>
      '$_mark ${to.sender.name}: ${excerpt(to.content)}\n${text.trim()}';

  /// Oldest first
  static String forward(String from, List<ChatMessage> messages) {
    final lines = [
      for (final m in messages)
        m.isSystem ? m.content.trim() : '${m.sender.name}: ${(parse(m.content)?.body ?? m.content).trim()}',
    ];
    return '$_forwardPrefix$from\n${lines.join('\n')}';
  }

  static ({String author, String excerpt, String body})? parse(String content) {
    final match = _quoteLine.firstMatch(content);
    if (match == null) return null;
    final body = content.substring(match.end);
    if (body.trim().isEmpty) return null;
    return (author: match.group(1)!, excerpt: match.group(2)!, body: body);
  }

  static ChatMessage? source(List<ChatMessage> messages, ChatMessage reply) {
    final quote = parse(reply.content);
    if (quote == null) return null;
    final at = messages.indexWhere((m) => m.id == reply.id);
    final stem = quote.excerpt.endsWith('…') ? quote.excerpt.substring(0, quote.excerpt.length - 1) : null;
    for (var i = (at < 0 ? messages.length : at) - 1; i >= 0; i--) {
      final m = messages[i];
      if (m.isSystem || m.sender.name != quote.author) continue;
      final text = excerpt(m.content);
      if (text == quote.excerpt || (stem != null && text.startsWith(stem))) return m;
    }
    return null;
  }

  static ({String from, String body})? forwarded(String content) {
    if (!content.startsWith(_forwardPrefix)) return null;
    final end = content.indexOf('\n');
    if (end < 0 || end == _forwardPrefix.length) return null;
    return (from: content.substring(_forwardPrefix.length, end), body: content.substring(end + 1));
  }
}
