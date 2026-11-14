import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:torn_pda/models/chat/chat_emoji.dart';
import 'package:torn_pda/models/chat/chat_send_check.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

/// True if confirmed or nothing to confirm
Future<bool> checkChatSend(BuildContext context, String text, {required String? roomId, required String roomName}) {
  final prefs = NativeChat.prefs;
  final ownKey = Get.isRegistered<UserController>() ? Get.find<UserController>().apiKey : null;
  final risk = prefs.warnApiKey ? ChatSendCheck.keyRisk(text, ownKey: ownKey) : ChatKeyRisk.none;
  final public = prefs.confirmPublic && ChatSendCheck.isPublic(roomId);
  if (risk == ChatKeyRisk.none && !public) return SynchronousFuture(true);
  return _confirmChatSend(context, risk: risk, roomName: roomName);
}

/// False if not sent
Future<bool> sendChatChecked(
  BuildContext context,
  String text, {
  required String? roomId,
  required String roomName,
  required ValueChanged<String> onSend,
}) => checkChatSend(context, text, roomId: roomId, roomName: roomName).then((ok) {
  if (!ok || !context.mounted) return false;
  onSend(text);
  NativeChat.prefs.countEmojis(ChatEmoji.found(text));
  return true;
});

Future<bool> _confirmChatSend(BuildContext context, {required ChatKeyRisk risk, required String roomName}) async {
  final scheme = Theme.of(context).colorScheme;
  final String title;
  final String body;
  switch (risk) {
    case ChatKeyRisk.own:
      title = 'Your API key';
      body = 'This looks like your API key. Anyone with it can read your account. Send anyway?';
    case ChatKeyRisk.similar:
      title = 'API key?';
      body = 'This looks like an API key. Anyone with it can read the account it belongs to. Send anyway?';
    case ChatKeyRisk.none:
      title = 'Send to $roomName?';
      body = 'Everyone in $roomName will see this message.';
  }
  final danger = risk == ChatKeyRisk.own;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: risk == ChatKeyRisk.none
          ? null
          : Icon(Icons.warning_amber_rounded, color: danger ? scheme.error : scheme.tertiary),
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          autofocus: true,
          style: TextButton.styleFrom(minimumSize: const Size(64, 48)),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          style: TextButton.styleFrom(
            minimumSize: const Size(64, 48),
            foregroundColor: risk == ChatKeyRisk.none ? null : (danger ? scheme.error : scheme.tertiary),
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Send'),
        ),
      ],
    ),
  );
  return result ?? false;
}
