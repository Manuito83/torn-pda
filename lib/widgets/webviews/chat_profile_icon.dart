import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

const String chatProfileIconHandler = 'PDA_chatProfileIcon';

final UserScript chatProfileIconScript = UserScript(
  groupName: 'pda_chatProfileIcon',
  injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
  source:
      """
    (function () {
      var host = location.hostname;
      if (host !== 'torn.com' && !host.endsWith('.torn.com')) return;
      var replaying = false;
      window.addEventListener('chat.openChannel', function (e) {
        if (replaying) return;
        var detail = e.detail;
        var stopped = false;
        var replayed = false;
        var replay = function () {
          if (replayed) return;
          replayed = true;
          replaying = true;
          try { window.dispatchEvent(new CustomEvent(e.type, { detail: detail })); } finally { replaying = false; }
        };
        try {
          var bridge = window.flutter_inappwebview;
          if (!bridge || !bridge.callHandler || !detail || detail.pda || detail.userId == null) return;
          e.stopImmediatePropagation();
          stopped = true;
          var result = bridge.callHandler('$chatProfileIconHandler', String(detail.userId));
          if (!result || typeof result.then !== 'function') {
            replay();
            return;
          }
          result.then(function (done) {
            if (done !== true) replay();
          }, replay);
        } catch (err) {
          if (stopped) replay();
        }
      }, true);
    })();
  """,
);

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

void addChatProfileIconHandler(InAppWebViewController webview) {
  webview.addJavaScriptHandler(
    handlerName: chatProfileIconHandler,
    callback: (JavaScriptHandlerFunctionData data) {
      try {
        return handleChatProfileIcon(
          data.args.isEmpty ? null : data.args.first,
          choice: NativeChat.prefs.profileIcon,
          usable: NativeChat.usable,
          connected: NativeChat.controller.ready && NativeChat.controller.connection == ChatConnection.connected,
          open: NativeChat.openQuickWindow,
        );
      } catch (_) {
        return false;
      }
    },
  );
}
