import 'package:flutter/material.dart';
import 'package:torn_pda/pages/chat/settings/chat_settings_subpage.dart';
import 'package:torn_pda/pages/chat/settings/chat_upload_settings_page.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/widgets/chat/chat_compose_tools.dart';
import 'package:torn_pda/widgets/chat/chat_link_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_message_actions.dart';
import 'package:torn_pda/widgets/chat/chat_settings_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

class ChatWritingSettingsPage extends StatelessWidget {
  const ChatWritingSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChatSettingsSubpage(
      title: 'Writing & actions',
      builder: (context) {
        final prefs = NativeChat.prefs;
        final replies = prefs.quickReplies.length;
        final host = prefs.imageHost;
        final uploadKey = prefs.credentialFor(host).isNotEmpty;
        return [
          const ChatSettingsHeading('Sending'),
          SwitchListTile(
            title: const Text('Warn before sending API keys'),
            subtitle: const Text('Asks first if a message looks like an API key'),
            value: prefs.warnApiKey,
            onChanged: prefs.setWarnApiKey,
          ),
          SwitchListTile(
            title: const Text('Confirm messages to public rooms'),
            subtitle: const Text('Asks before sending to a public room like Global or Trade'),
            value: prefs.confirmPublic,
            onChanged: prefs.setConfirmPublic,
          ),
          SwitchListTile(
            title: const Text('Enter sends with a physical keyboard'),
            subtitle: const Text('Shift and Enter adds a new line'),
            value: prefs.enterSendsHardware,
            onChanged: prefs.setEnterSendsHardware,
          ),
          SwitchListTile(
            title: const Text('Enter sends with the on-screen keyboard'),
            subtitle: const Text('The action key sends instead of adding a new line'),
            value: prefs.enterSendsSoft,
            onChanged: prefs.setEnterSendsSoft,
          ),
          ChatSettingsLink(
            leading: const Icon(Icons.bolt_rounded),
            title: 'Quick actions',
            subtitle: prefs.quickRowsShown.map((t) => t.title).join(' - '),
            page: ChatSettingsSubpage(
              title: 'Quick actions',
              description:
                  'Shown under the bolt next to the message box. Pick what each row shows, then turn actions on '
                  'or off and drag the handle to reorder them',
              builder: (_) => const [ChatQuickActionsEditor()],
            ),
          ),
          ChatSettingsLink(
            leading: const Icon(Icons.chat_bubble_outline_rounded),
            title: 'Quick replies',
            subtitle: '$replies ${replies == 1 ? 'reply' : 'replies'}',
            page: ChatSettingsSubpage(title: 'Quick replies', builder: (_) => const [ChatQuickReplySettings()]),
          ),
          const ChatSettingsLink(
            leading: Icon(Icons.touch_app_rounded),
            title: 'Message actions',
            subtitle: 'Long press and swipe',
            page: ChatMessageActionsSettingsPage(),
          ),
          ChatSettingsLink(
            leading: const Icon(Icons.cloud_upload_outlined),
            title: 'Image upload',
            subtitle: host.needsCredential && !uploadKey ? 'Off' : '${host.label}${uploadKey ? ' - ${host.credentialName} set' : ''}',
            page: const ChatUploadSettingsPage(),
          ),
        ];
      },
    );
  }
}

class ChatMessageActionsSettingsPage extends StatelessWidget {
  const ChatMessageActionsSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChatSettingsSubpage(
      title: 'Message actions',
      builder: (context) => [
        ChatSettingsTile(
          title: 'Swipe left on a message',
          subtitle: 'Outside private chats, acts on who wrote it',
          control: (below) => DropdownButton<ChatSwipeAction>(
            isExpanded: below,
            value: NativeChat.prefs.swipeLeft,
            underline: const SizedBox.shrink(),
            items: [
              for (final a in ChatSwipeAction.values)
                DropdownMenuItem(value: a, child: Text(chatSwipeLook[a]?.$2 ?? 'Off')),
            ],
            onChanged: (v) => NativeChat.prefs.setSwipeLeft(v!),
          ),
        ),
        const ChatSettingsHeading(
          'Actions',
          description: 'The buttons under a message you long press. Drag to reorder',
        ),
        const ChatMessageActionsEditor(),
      ],
    );
  }
}
