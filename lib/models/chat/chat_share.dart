import 'package:intl/intl.dart';
import 'package:torn_pda/models/chat/chat_format.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_quote.dart';

/// Text or image shared into PDA
class ChatShared {
  const ChatShared({this.text = '', this.image, this.type = ''});

  final String text;

  /// Android content uri
  final String? image;
  final String type;

  static final RegExp _url = RegExp(r'https?://[^\s<>"]+', caseSensitive: false);

  static ChatShared? from(Object? raw) {
    if (raw is! Map) return null;
    final text = raw['text'] is String ? (raw['text'] as String).trim() : '';
    final image = raw['image'] is String && (raw['image'] as String).isNotEmpty ? raw['image'] as String : null;
    if (text.isEmpty && image == null) return null;
    return ChatShared(text: text, image: image, type: raw['type'] is String ? raw['type'] as String : '');
  }

  String? get tornLink {
    for (final match in _url.allMatches(text)) {
      final host = Uri.tryParse(match.group(0)!)?.host.toLowerCase() ?? '';
      if (host == 'torn.com' || host.endsWith('.torn.com')) return match.group(0);
    }
    return null;
  }

  /// Null if not an image
  static String? imageExtension(List<int> bytes) {
    bool starts(List<int> sign, [int at = 0]) {
      if (bytes.length < at + sign.length) return false;
      for (var i = 0; i < sign.length; i++) {
        if (bytes[at + i] != sign[i]) return false;
      }
      return true;
    }

    if (starts(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) return 'png';
    if (starts(const [0xFF, 0xD8, 0xFF])) return 'jpg';
    if (starts('GIF87a'.codeUnits) || starts('GIF89a'.codeUnits)) return 'gif';
    if (starts('RIFF'.codeUnits) && starts('WEBP'.codeUnits, 8)) return 'webp';
    return null;
  }

  /// "[14:05 TCT] Name: text", oldest first
  static String outgoing(List<ChatMessage> messages) {
    final sorted = [...messages]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final days = {for (final m in sorted) m.createdAt.toUtc().toString().substring(0, 10)};
    final lines = <String>[];
    for (final m in sorted) {
      final at = m.createdAt.toUtc();
      final stamp = DateFormat(days.length > 1 ? 'MMM d HH:mm' : 'HH:mm', 'en_US').format(at);
      final body = ChatFormat.plain((ChatQuote.parse(m.content)?.body ?? m.content).trim());
      lines.add(m.isSystem ? '[$stamp TCT] $body' : '[$stamp TCT] ${m.sender.name}: $body');
    }
    return lines.join('\n');
  }
}
