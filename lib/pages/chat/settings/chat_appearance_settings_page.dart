import 'package:flutter/material.dart';
import 'package:torn_pda/pages/chat/settings/chat_settings_subpage.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/widgets/chat/chat_appearance_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_color_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_settings_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

class ChatAppearanceSettingsPage extends StatelessWidget {
  const ChatAppearanceSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChatSettingsSubpage(
      title: 'Appearance',
      builder: (context) {
        final custom = [
          for (final (theme, label) in const [('light', 'Light'), ('dark', 'Dark'), ('extraDark', 'Extra dark')])
            if (!NativeChat.prefs.colorsFor(theme).isEmpty) label,
        ];
        return [
          const ChatAppearanceSettings(),
          ChatSettingsTile(
            title: 'Chat times',
            subtitle: 'Messages, chat list and reminders. 12 or 24 hours as in the app settings',
            control: (below) => DropdownButton<ChatTimes>(
              isExpanded: below,
              value: NativeChat.prefs.chatTimes,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: ChatTimes.app, child: Text('As in app settings')),
                DropdownMenuItem(value: ChatTimes.tct, child: Text('Torn City Time (TCT)')),
                DropdownMenuItem(value: ChatTimes.local, child: Text('Local time')),
              ],
              onChanged: (v) => NativeChat.prefs.setChatTimes(v!),
            ),
          ),
          ChatSettingsTile(
            title: 'Chat animations',
            subtitle: 'How new messages and the chat list move. Off with reduced motion',
            control: (below) => DropdownButton<ChatAnimations>(
              isExpanded: below,
              value: NativeChat.prefs.animations,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: ChatAnimations.quick, child: Text('Quick')),
                DropdownMenuItem(value: ChatAnimations.smooth, child: Text('Smooth')),
                DropdownMenuItem(value: ChatAnimations.verySmooth, child: Text('Very smooth')),
              ],
              onChanged: (v) => NativeChat.prefs.setAnimations(v!),
            ),
          ),
          ChatSettingsLink(
            leading: const Icon(Icons.palette_rounded),
            title: 'Colors',
            subtitle: custom.isEmpty ? 'Default' : 'Custom in ${custom.join(', ')}',
            page: ChatSettingsSubpage(
              title: 'Colors',
              description: 'One set per app theme',
              builder: (_) => const [ChatColorSettings()],
            ),
          ),
        ];
      },
    );
  }
}
