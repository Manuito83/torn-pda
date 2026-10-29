import 'package:torn_pda/models/chat/chat_status.dart';

class ChatUser {
  final int id;
  final String name;
  final String? avatarUrl;
  final String? status;

  /// Only from faction and company rosters
  final ChatPlayerStatus? playerStatus;

  /// Faction leader or co-leader, company director
  final bool leader;

  const ChatUser({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.status,
    this.playerStatus,
    this.leader = false,
  });
}

enum ChatMessageState { sent, pending, failed }

class ChatMessage {
  final String id;
  final String? reqId;
  final String roomId;
  final ChatUser sender;
  final String content;
  final DateTime createdAt;
  final bool isSystem;
  final ChatMessageState state;

  /// Only this device, never sent or stored
  final bool isLocal;

  const ChatMessage({
    required this.id,
    this.reqId,
    required this.roomId,
    required this.sender,
    required this.content,
    required this.createdAt,
    this.isSystem = false,
    this.state = ChatMessageState.sent,
    this.isLocal = false,
  });
}

enum ChatRoomType { official, custom, dm }

/// Private chats use the id `dm:<userId>`
class ChatRoom {
  final String id;
  final String name;
  final ChatRoomType type;
  final bool canWrite;
  final int? messageSeq;
  final ChatUser? peer;
  final ChatMessage? lastMessage;

  final String? icon;

  final String? emblemUrl;

  /// Torn's reportTyping rule
  final bool reportTyping;

  const ChatRoom({
    required this.id,
    required this.name,
    this.type = ChatRoomType.official,
    this.canWrite = true,
    this.messageSeq,
    this.peer,
    this.lastMessage,
    this.icon,
    this.emblemUrl,
    this.reportTyping = true,
  });

  /// Contextual room while abroad
  static const String travelId = 'travelling';

  bool get isDm => type == ChatRoomType.dm;

  ChatRoom withEmblem(String? url) => ChatRoom(
    id: id,
    name: name,
    type: type,
    canWrite: canWrite,
    messageSeq: messageSeq,
    peer: peer,
    lastMessage: lastMessage,
    icon: icon,
    emblemUrl: url,
    reportTyping: reportTyping,
  );

  static String dmId(int userId) => 'dm:$userId';

  static int? peerIdOf(String id) => id.startsWith('dm:') ? int.tryParse(id.substring(3)) : null;
}

enum ChatConnection { starting, connecting, connected, disconnected, noSession, needsBrowser, twoFactor, offline, tornDown, error }

sealed class ChatEvent {
  const ChatEvent();
}

class ChatReadyEvent extends ChatEvent {
  final int? myUserId;
  final String? myName;
  const ChatReadyEvent(this.myUserId, {this.myName});
}

class ChatConnectionEvent extends ChatEvent {
  final ChatConnection state;
  final bool reconnected;

  /// Might still clear up by itself
  final bool tentative;
  const ChatConnectionEvent(this.state, {this.reconnected = false, this.tentative = false});
}

class ChatRoomsEvent extends ChatEvent {
  final List<ChatRoom> rooms;
  const ChatRoomsEvent(this.rooms);
}

class ChatDmsEvent extends ChatEvent {
  final List<ChatRoom> dms;
  const ChatDmsEvent(this.dms);
}

/// Torn's "Your private chats", newest first
class ChatRecentDmsEvent extends ChatEvent {
  final List<ChatRoom> dms;
  final int offset;
  final bool hasMore;
  const ChatRecentDmsEvent(this.dms, {required this.offset, required this.hasMore});
}

class ChatUnreadEvent extends ChatEvent {
  final Map<String, int> counts;
  const ChatUnreadEvent(this.counts);
}

class ChatUnreadFailedEvent extends ChatEvent {
  const ChatUnreadFailedEvent();
}

/// Null [roomId] means everything
class ChatReadEvent extends ChatEvent {
  final String? roomId;
  final int? unread;
  const ChatReadEvent(this.roomId, this.unread);
}

class ChatPeekEvent extends ChatEvent {
  final String roomId;
  final ChatMessage? last;
  const ChatPeekEvent(this.roomId, this.last);
}

class ChatSearchEvent extends ChatEvent {
  final String query;
  final List<ChatUser> users;
  const ChatSearchEvent(this.query, this.users);
}

enum ChatPresence {
  online,
  idle,
  offline;

  static ChatPresence? parse(dynamic value) => switch ('$value'.toLowerCase()) {
    'online' => online,
    'idle' => idle,
    'offline' => offline,
    _ => null,
  };
}

class ChatLastAction {
  final ChatPresence presence;
  final DateTime? at;
  const ChatLastAction(this.presence, [this.at]);

  /// "5m", "2h", "3d", null under a minute
  static String? ago(DateTime at, DateTime now) {
    final gap = now.difference(at);
    if (gap.inMinutes < 1) return null;
    if (gap.inMinutes < 60) return '${gap.inMinutes}m';
    if (gap.inHours < 48) return '${gap.inHours}h';
    return '${gap.inDays}d';
  }
}

class ChatPresenceEvent extends ChatEvent {
  final Map<int, ChatPresence> users;
  const ChatPresenceEvent(this.users);
}

class ChatBlockedEvent extends ChatEvent {
  final Set<int> userIds;
  const ChatBlockedEvent(this.userIds);
}

class ChatSendResultEvent extends ChatEvent {
  final String roomId;
  final String reqId;
  final bool ok;
  const ChatSendResultEvent(this.roomId, this.reqId, {required this.ok});
}

class ChatHistoryEvent extends ChatEvent {
  final String roomId;
  final List<ChatMessage> messages;
  final bool hasOlder;
  final bool isOlderPage;
  const ChatHistoryEvent(this.roomId, this.messages, {required this.hasOlder, required this.isOlderPage});
}

class ChatMessageEvent extends ChatEvent {
  final ChatMessage message;
  final int? unread;
  const ChatMessageEvent(this.message, {this.unread});
}

class ChatMessageDeletedEvent extends ChatEvent {
  final String roomId;
  final String messageId;
  const ChatMessageDeletedEvent(this.roomId, this.messageId);
}

class ChatTypingEvent extends ChatEvent {
  final String roomId;
  final List<ChatUser> users;
  const ChatTypingEvent(this.roomId, this.users);
}
