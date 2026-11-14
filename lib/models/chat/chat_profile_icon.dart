import 'package:torn_pda/models/chat/chat_models.dart';

enum ChatProfileIcon { pda, torn }

/// True when the PDA chat took the click
bool handleChatProfileIcon(
  Object? raw, {
  required ChatProfileIcon choice,
  required bool usable,
  required bool connected,
  required void Function(String roomId) open,
}) {
  if (choice != ChatProfileIcon.pda || !usable || !connected) return false;
  final text = raw is int ? '$raw' : (raw is String ? raw : '');
  if (!RegExp(r'^[1-9]\d{0,17}$').hasMatch(text)) return false;
  final id = int.parse(text);
  open(ChatRoom.dmId(id));
  return true;
}
