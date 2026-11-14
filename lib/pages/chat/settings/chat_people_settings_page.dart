import 'package:flutter/material.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/pages/chat/chat_player_nicknames_page.dart';
import 'package:torn_pda/pages/chat/settings/chat_settings_subpage.dart';
import 'package:torn_pda/widgets/chat/chat_player_actions_widgets.dart';
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
          ChatSettingsLink(
            leading: const Icon(Icons.block_rounded),
            title: 'Blocked in Torn (${NativeChat.controller.blockedUsers.length})',
            page: const ChatBlockedPage(),
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
          if (prefs.ignored.isEmpty) const _Nobody('Nobody is ignored'),
          for (final e in prefs.ignored.entries)
            _PersonRow(
              user: ChatUser(id: e.key, name: e.value),
              action: 'Unignore',
              onPressed: () => prefs.setIgnored(e.key, e.value, false),
            ),
        ];
      },
    );
  }
}

class ChatBlockedPage extends StatelessWidget {
  const ChatBlockedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChatSettingsSubpage(
      title: 'Blocked in Torn',
      description: 'Torn stops their private messages and mail to you. Same list as Torn\'s chat and mail ignore list',
      builder: (context) {
        final blocked = NativeChat.controller.blockedUsers;
        return [
          if (blocked.isEmpty) const _Nobody('Nobody is blocked'),
          for (final user in blocked) _PersonRow(user: user, action: 'Unblock', onPressed: () => chatUnblock(user)),
        ];
      },
    );
  }
}

class _Nobody extends StatelessWidget {
  const _Nobody(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.user, required this.action, required this.onPressed});

  final ChatUser user;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ChatAvatar(user: user, size: 36),
      title: Text(user.name),
      subtitle: Text('[${user.id}]'),
      trailing: TextButton(onPressed: onPressed, child: Text(action)),
    );
  }
}
