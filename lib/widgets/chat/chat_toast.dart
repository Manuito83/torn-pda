import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';

/// Self-closing notice, optional action button
void chatToast(String text, {int seconds = 2, String? action, VoidCallback? onAction, VoidCallback? onClose}) {
  BotToast.showCustomText(
    clickClose: true,
    crossPage: false,
    align: const Alignment(0, 0.8),
    duration: Duration(seconds: seconds),
    onClose: onClose,
    toastBuilder: (close) => Container(
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
          if (action != null)
            TextButton(
              style: TextButton.styleFrom(minimumSize: const Size(48, 48), foregroundColor: Colors.lightBlueAccent),
              onPressed: () {
                close();
                onAction?.call();
              },
              child: Text(action),
            ),
        ],
      ),
    ),
  );
}
