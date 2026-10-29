import 'package:torn_pda/models/chat/chat_models.dart';

abstract class ChatSource {
  bool get available;

  Stream<ChatEvent> get events;

  Future<void> openRoom(String roomId);

  Future<void> closeRoom();

  Future<void> loadOlder(String roomId, DateTime before);

  Future<void> pause(List<String> roomIds);

  Future<void> refreshRooms();

  Future<void> refreshUnread();

  /// Without [force], only if panels changed
  Future<void> refreshDms({bool force = false});

  Future<void> loadRecentDms({int offset = 0});

  Future<void> peek(List<String> roomIds);

  Future<void> search(String name);

  Future<void> online(List<int> userIds);

  Future<void> touch();

  Future<void> markRead(String roomId);

  Future<void> markAllRead();

  Future<void> loadBlocked();

  Future<void> closeDm(int userId);

  /// Start or stop typing
  Future<void> typing(String roomId, bool on);

  Future<void> send(String roomId, String content, String reqId);

  /// For a lost session
  Future<void> reconnect();

  /// After a native login as someone else
  Future<void> switchAccount();
}
