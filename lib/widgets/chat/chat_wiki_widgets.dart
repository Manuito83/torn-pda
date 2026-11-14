import 'package:flutter/material.dart';
import 'package:torn_pda/models/chat/chat_wiki.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

Future<void> showChatSlangSheet(BuildContext context, ChatSlang slang) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheet) {
      final theme = Theme.of(sheet);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(slang.term, style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                slang.meaning,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.open_in_browser_rounded),
                  label: const Text('Open in wiki'),
                  onPressed: () {
                    Navigator.of(sheet).pop();
                    NativeChat.openLink(slang.url);
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
