import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/main.dart' show navigatorKey;
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_share.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/widgets/chat/chat_toast.dart';
import 'package:torn_pda/widgets/chat/chat_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';

Future<ChatRoom?> showChatRoomPicker(BuildContext context, ChatController chat, String title) {
  return showModalBottomSheet<ChatRoom>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, scroll) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          Expanded(
            // Rooms can still be loading
            child: ListenableBuilder(
              listenable: chat,
              builder: (context, _) {
                final targets = chat.conversations
                    .where((r) => r.canWrite && !NativeChat.prefs.hiddenRooms.contains(r.id))
                    .toList();
                return ListView.builder(
                  controller: scroll,
                  itemCount: targets.length,
                  itemBuilder: (context, index) {
                    final room = targets[index];
                    return ListTile(
                      leading: ChatRoomAvatar(room: room, size: 40),
                      title: Text(room.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: room.isDm ? const Text('Private chat') : null,
                      onTap: () => Navigator.of(context).pop(room),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

/// Android share sheet into the chat
class ChatShareIn {
  ChatShareIn._();

  static const MethodChannel _channel = MethodChannel('tornpda.share');
  static final ValueNotifier<({String roomId, ChatShared shared, DateTime at})?> pending = ValueNotifier(null);
  static const Duration expiry = Duration(minutes: 2);
  static bool _started = false;

  static void start() {
    if (_started || !Platform.isAndroid) return;
    _started = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'shared') unawaited(_receive(ChatShared.from(call.arguments)));
    });
    _channel.invokeMethod('take').then((raw) => _receive(ChatShared.from(raw)), onError: (_) {});
  }

  static void offer(String roomId, ChatShared shared) {
    pending.value = (roomId: roomId, shared: shared, at: DateTime.now());
  }

  /// Picks a chat, leaves [text], never sends
  static Future<void> shareText(String text) async {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    NativeChat.hideQuickWindows();
    final room = await showChatRoomPicker(navigator.context, NativeChat.controller, 'Share to');
    if (room == null) return;
    offer(room.id, ChatShared(text: text.trim()));
    await NativeChat.open(navigator, roomId: room.id);
  }

  /// Android copies it to a cache file
  static Future<Uint8List> readImage(String uri) async {
    final file = File('${(await getTemporaryDirectory()).path}/chat_share/shared');
    await _channel.invokeMethod<void>('readImage', {'uri': uri});
    try {
      return await file.readAsBytes();
    } finally {
      if (await file.exists()) await file.delete();
    }
  }

  static ChatShared? take(String roomId) {
    final drop = pending.value;
    if (drop == null || drop.roomId != roomId) return null;
    pending.value = null;
    return DateTime.now().difference(drop.at) > expiry ? null : drop.shared;
  }

  static Future<void> _receive(ChatShared? shared) async {
    if (shared == null) return;
    for (var i = 0; i < 50 && navigatorKey.currentState == null; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
    }
    final chat = NativeChat.controller;
    // Rooms arrive a few seconds after launch
    for (var i = 0; i < 40 && NativeChat.compiled && chat.conversations.isEmpty; i++) {
      await Future.delayed(const Duration(milliseconds: 250));
    }
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    if (!NativeChat.compiled || chat.conversations.isEmpty) {
      final link = shared.tornLink;
      if (link != null) {
        await navigator.context.read<WebViewProvider>().openBrowserPreference(
          context: navigator.context,
          url: link,
          browserTapType: BrowserTapType.deeplink,
        );
        return;
      }
      chatToast(
        NativeChat.compiled
            ? 'The chat is not connected yet, share it again in a moment'
            : 'Torn PDA can only open Torn links shared from other apps',
        seconds: 4,
      );
      return;
    }
    NativeChat.hideQuickWindows();
    final room = await showChatRoomPicker(
      navigator.context,
      chat,
      shared.image != null ? 'Share image to' : 'Share to',
    );
    if (room == null) return;
    offer(room.id, shared);
    await NativeChat.open(navigator, roomId: room.id);
  }
}
