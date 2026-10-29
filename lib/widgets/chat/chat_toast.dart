import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

typedef ChatHeldToast = ({String text, String action, VoidCallback? onAction, VoidCallback? onClose});

final ValueNotifier<ChatHeldToast?> chatHeldToast = ValueNotifier(null);

bool chatToastHosted = false;

void dropChatToast() {
  final toast = chatHeldToast.value;
  if (toast == null) return;
  chatHeldToast.value = null;
  // After its action ran
  scheduleMicrotask(() => toast.onClose?.call());
}

/// Self-closing notice, optional action button
void chatToast(String text, {int seconds = 2, String? action, VoidCallback? onAction, VoidCallback? onClose}) {
  final platform = WidgetsBinding.instance.platformDispatcher;
  final view = platform.implicitView;
  if (view != null) {
    SemanticsService.sendAnnouncement(view, action == null ? text : '$text. $action available', TextDirection.ltr);
  }
  final held = action != null && platform.accessibilityFeatures.accessibleNavigation;
  if (held && chatToastHosted) {
    dropChatToast();
    chatHeldToast.value = (text: text, action: action, onAction: onAction, onClose: onClose);
    return;
  }
  BotToast.showCustomText(
    clickClose: !held,
    crossPage: false,
    align: const Alignment(0, 0.8),
    duration: held ? null : Duration(seconds: seconds),
    onClose: onClose,
    toastBuilder: (close) => ChatToastBox(text: text, action: action, onAction: onAction, close: close, held: held),
  );
}

class ChatToastBox extends StatelessWidget {
  const ChatToastBox({
    super.key,
    required this.text,
    required this.close,
    this.action,
    this.onAction,
    this.held = false,
  });

  final String text;
  final VoidCallback close;
  final String? action;
  final VoidCallback? onAction;

  final bool held;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: EdgeInsets.only(left: 16, top: 4, bottom: 4, right: action == null ? 16 : 4),
        decoration: BoxDecoration(color: const Color(0xE6303030), borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(text, style: const TextStyle(fontSize: 14, color: Colors.white)),
              ),
            ),
            if (action case final action?)
              TextButton(
                style: TextButton.styleFrom(minimumSize: const Size(48, 48), foregroundColor: Colors.lightBlueAccent),
                onPressed: () {
                  close();
                  onAction?.call();
                },
                child: Text(action),
              ),
            if (held)
              Semantics(
                container: true,
                child: IconButton(
                  tooltip: 'Dismiss',
                  color: Colors.white,
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: close,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
