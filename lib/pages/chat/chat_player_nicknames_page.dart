import 'package:flutter/material.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_person.dart';
import 'package:torn_pda/widgets/chat/chat_person_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

class ChatPlayerNicknamesPage extends StatelessWidget {
  const ChatPlayerNicknamesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prefs = NativeChat.prefs;
    return Scaffold(
      appBar: AppBar(title: const Text('Player nicknames')),
      body: ListenableBuilder(
        listenable: prefs,
        builder: (context, _) {
          final people = prefs.people.entries.toList()
            ..sort((a, b) => a.value.name.toLowerCase().compareTo(b.value.name.toLowerCase()));
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  people.isEmpty
                      ? 'None yet. Tap a player\'s name in the chat, then Customize'
                      : 'Players with a nickname, a name color or a highlight. Only you can see these',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              for (final MapEntry(key: id, value: style) in people)
                ListTile(
                  leading: ChatAvatar(
                    user: ChatUser(id: id, name: style.name),
                    size: 36,
                  ),
                  title: Text(
                    style.nickname.isEmpty ? style.name : style.nickname,
                    style: style.nameColor == null ? null : TextStyle(color: style.nameColor),
                  ),
                  subtitle: Text(style.nickname.isEmpty ? '[$id]' : '${style.name} [$id]'),
                  onTap: () => showChatPersonSettings(context, ChatUser(id: id, name: style.name)),
                  trailing: IconButton(
                    tooltip: 'Remove ${style.name}',
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () => prefs.setPerson(id, ChatPersonStyle.none),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
