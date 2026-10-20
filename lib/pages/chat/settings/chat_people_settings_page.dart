import 'package:flutter/material.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/pages/chat/chat_player_nicknames_page.dart';
import 'package:torn_pda/pages/chat/settings/chat_settings_subpage.dart';
import 'package:torn_pda/widgets/chat/chat_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

class ChatPeopleSettingsPage extends StatelessWidget {
  const ChatPeopleSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChatSettingsSubpage(
      title: 'People',
      builder: (context) {
        final prefs = NativeChat.prefs;
        return [
          SwitchListTile(
            title: const Text('Color per player'),
            subtitle: const Text('Each sender keeps the same name color in rooms'),
            value: prefs.playerColors,
            onChanged: prefs.setPlayerColors,
          ),
          ChatSettingsLink(
            leading: const Icon(Icons.face_retouching_natural_rounded),
            title: 'Player nicknames (${prefs.people.length})',
            subtitle: 'Players with a nickname, a name color or a highlight',
            page: const ChatPlayerNicknamesPage(),
          ),
          ChatSettingsLink(
            leading: const Icon(Icons.person_off_rounded),
            title: 'Ignored players (${prefs.ignored.length})',
            page: const ChatIgnoredPage(),
          ),
        ];
      },
    );
  }
}

class ChatIgnoredPage extends StatelessWidget {
  const ChatIgnoredPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChatSettingsSubpage(
      title: 'Ignored players',
      description:
          'Their messages are hidden only in Torn PDA. Tap a name in the chat to ignore someone. '
          'Players you block in Torn are hidden too',
      builder: (context) {
        final prefs = NativeChat.prefs;
        return [
          if (prefs.ignored.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'Nobody is ignored',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
          for (final e in prefs.ignored.entries)
            ListTile(
              leading: ChatAvatar(
                user: ChatUser(id: e.key, name: e.value),
                size: 36,
              ),
              title: Text(e.value),
              subtitle: Text('[${e.key}]'),
              trailing: TextButton(
                onPressed: () => prefs.setIgnored(e.key, e.value, false),
                child: const Text('Unignore'),
              ),
            ),
        ];
      },
    );
  }
}
