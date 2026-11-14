import 'package:torn_pda/models/chat/chat_status.dart';
import 'package:torn_pda/models/chat/chat_time.dart';

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

  /// Torn's input blockers, empty when writable
  final List<String> blockers;
  final int? messageSeq;
  final ChatUser? peer;
  final ChatMessage? lastMessage;

  final String? icon;

  final String? emblemUrl;

  final bool reportTyping;

  const ChatRoom({
    required this.id,
    required this.name,
    this.type = ChatRoomType.official,
    this.blockers = const [],
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

  bool get canWrite => blockers.isEmpty;

  static const String blockedByMe = 'blocked_by_me';

  // Torn's order and wording
  static const Map<String, String> _blockerTexts = {
    'you_room_banned': 'You have been banned from this room',
    'room_frozen': 'This room is frozen',
    'invited_only': 'Accept the invitation to chat in this room',
    'not_member': 'You are not a member of this room',
    'user_banned': 'This person has been chat banned',
    blockedByMe: 'You have blocked this person',
    'blocked_by_other': 'This person has blocked you',
    'stranger_declined': 'This person does not want to talk to strangers',
  };

  String? get blockerText => _blockerTexts.entries.where((e) => blockers.contains(e.key)).firstOrNull?.value;

  ChatRoom withEmblem(String? url) => _copy(emblemUrl: url, blockers: blockers);

  ChatRoom withBlockers(List<String> value) => _copy(emblemUrl: emblemUrl, blockers: value);

  ChatRoom _copy({required String? emblemUrl, required List<String> blockers}) => ChatRoom(
    id: id,
    name: name,
    type: type,
    blockers: blockers,
    messageSeq: messageSeq,
    peer: peer,
    lastMessage: lastMessage,
    icon: icon,
    emblemUrl: emblemUrl,
    reportTyping: reportTyping,
  );

  static String dmId(int userId) => 'dm:$userId';

  static int? peerIdOf(String id) => id.startsWith('dm:') ? int.tryParse(id.substring(3)) : null;
}

enum ChatConnection {
  starting,
  connecting,
  connected,
  disconnected,
  noSession,
  needsBrowser,
  twoFactor,
  offline,
  tornDown,
  slowLoad,
  error,
}

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
  final List<ChatUser> users;
  const ChatBlockedEvent(this.users);
}

class ChatBlockersEvent extends ChatEvent {
  final String roomId;
  final List<String> blockers;
  const ChatBlockersEvent(this.roomId, this.blockers);
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

enum ChatRoomLoad { loaded, loading, timedOut, unreachable, session }

/// Null when the session line says it
String? chatUnreachableReason(ChatConnection connection, ChatRoomLoad load) => switch (connection) {
  ChatConnection.noSession => 'Log in to Torn in the browser',
  ChatConnection.needsBrowser => 'Finish logging in to Torn in the browser',
  ChatConnection.twoFactor => 'Enter your 2FA code in the browser',
  _ => load == ChatRoomLoad.session ? null : 'Could not reach the chat',
};

const Duration _groupGap = Duration(minutes: 5);

bool chatSameGroup(ChatClock clock, ChatMessage? a, ChatMessage? b) {
  if (a == null || b == null || a.isSystem || b.isSystem || a.sender.id != b.sender.id) return false;
  return clock.sameDay(a.createdAt, b.createdAt) && b.createdAt.difference(a.createdAt).abs() < _groupGap;
}

String? chatTravelFlag(ChatRoom room) => room.id == ChatRoom.travelId ? chatCountryFlag(room.name) : null;

String? chatCountryFlag(String country) {
  final name = country.trim().toLowerCase().replaceAll(' ', '-');
  final file = switch (name) {
    'uk' || 'united-kingdom' => 'uk',
    'uae' || 'united-arab-emirates' => 'uae',
    'cayman' || 'cayman-islands' => 'cayman',
    'argentina' || 'canada' || 'china' || 'hawaii' || 'japan' || 'mexico' || 'south-africa' || 'switzerland' => name,
    _ => null,
  };
  return file == null ? null : 'images/flags/ball/ball_$file.png';
}
