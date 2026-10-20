import 'package:torn_pda/models/chaining/bars_model.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_quote.dart';
import 'package:torn_pda/models/chat/chat_status.dart';

class ChatReminder {
  const ChatReminder({
    required this.id,
    required this.roomId,
    required this.roomName,
    required this.messageId,
    required this.author,
    required this.excerpt,
    required this.at,
    required this.label,
  });

  final int id;
  final String roomId;
  final String roomName;
  final String messageId;
  final String author;
  final String excerpt;
  final DateTime at;

  /// Like "When I land"
  final String label;

  factory ChatReminder.of(
    ChatMessage m,
    String roomName, {
    required int id,
    required DateTime at,
    required String label,
  }) => ChatReminder(
    id: id,
    roomId: m.roomId,
    roomName: roomName,
    messageId: m.id,
    author: m.sender.name,
    excerpt: ChatQuote.excerpt(m.content),
    at: at,
    label: label,
  );

  Map<String, dynamic> toJson() => {
    'n': id,
    'room': roomId,
    'roomName': roomName,
    'id': messageId,
    'author': author,
    'text': excerpt,
    'at': at.millisecondsSinceEpoch,
    'label': label,
  };

  static ChatReminder? fromJson(dynamic json) {
    if (json is! Map || json['n'] is! int || json['room'] is! String || json['id'] is! String || json['at'] is! int) {
      return null;
    }
    return ChatReminder(
      id: json['n'] as int,
      roomId: json['room'] as String,
      roomName: '${json['roomName'] ?? json['room']}',
      messageId: json['id'] as String,
      author: '${json['author'] ?? ''}',
      excerpt: '${json['text'] ?? ''}',
      at: DateTime.fromMillisecondsSinceEpoch(json['at'] as int),
      label: '${json['label'] ?? ''}',
    );
  }
}

class ChatReminderOption {
  const ChatReminderOption(this.label, this.at);

  final String label;
  final DateTime at;
}

class ChatReminders {
  ChatReminders._();

  static const int idBase = 678000;
  static const int idSpan = 1000;
  static const String _payloadPrefix = 'pdachat-remind:';

  static int nextId(Iterable<ChatReminder> used) {
    final taken = {for (final r in used) r.id};
    for (var i = 0; i < idSpan; i++) {
      if (!taken.contains(idBase + i)) return idBase + i;
    }
    return idBase;
  }

  static List<ChatReminderOption> triggers({required BarsStatusCooldownsModel bars, required int now}) {
    final status = bars.status;
    final serverTime = bars.serverTime ?? now;
    final fresh = now - serverTime <= ChatStatus.barsMaxAge.inSeconds;
    final landing = bars.travel?.timestamp ?? 0;
    final until = status?.until ?? 0;
    final full = bars.energy?.fulltime ?? 0;
    DateTime at(int seconds) => DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    return [
      if (status?.state == 'Traveling' && landing > now) ChatReminderOption('When I land', at(landing)),
      if (status?.state == 'Hospital' && until > now) ChatReminderOption('When I leave hospital', at(until)),
      if (fresh && serverTime + full > now) ChatReminderOption('When energy is full', at(serverTime + full)),
    ];
  }

  /// Letters only, payloads match by substring
  static String payload(String roomId, String messageId) =>
      _payloadPrefix +
      '$roomId\n$messageId'.codeUnits.expand((c) => [c >> 4, c & 15]).map((n) => String.fromCharCode(65 + n)).join();

  static (String, String)? fromPayload(String? payload) {
    if (payload == null || !payload.startsWith(_payloadPrefix)) return null;
    final letters = payload.substring(_payloadPrefix.length).codeUnits.map((c) => c - 65).toList();
    if (letters.isEmpty || letters.length.isOdd || letters.any((n) => n < 0 || n > 15)) return null;
    final parts = String.fromCharCodes([
      for (var i = 0; i < letters.length; i += 2) letters[i] << 4 | letters[i + 1],
    ]).split('\n');
    return parts.length == 2 && parts[0].isNotEmpty && parts[1].isNotEmpty ? (parts[0], parts[1]) : null;
  }
}
