import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_quote.dart';

class ChatSaved {
  final String messageId;
  final String roomId;
  final String roomName;
  final String author;
  final String excerpt;
  final DateTime createdAt;

  const ChatSaved({
    required this.messageId,
    required this.roomId,
    required this.roomName,
    required this.author,
    required this.excerpt,
    required this.createdAt,
  });

  factory ChatSaved.of(ChatMessage m, String roomName) => ChatSaved(
    messageId: m.id,
    roomId: m.roomId,
    roomName: roomName,
    author: m.sender.name,
    excerpt: ChatQuote.excerpt(m.content),
    createdAt: m.createdAt,
  );

  Map<String, dynamic> toJson() => {
    'id': messageId,
    'room': roomId,
    'roomName': roomName,
    'author': author,
    'text': excerpt,
    'at': createdAt.millisecondsSinceEpoch,
  };

  static ChatSaved? fromJson(dynamic json) {
    if (json is! Map || json['id'] is! String || json['room'] is! String || json['at'] is! int) return null;
    return ChatSaved(
      messageId: json['id'] as String,
      roomId: json['room'] as String,
      roomName: '${json['roomName'] ?? json['room']}',
      author: '${json['author'] ?? ''}',
      excerpt: '${json['text'] ?? ''}',
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['at'] as int),
    );
  }
}
