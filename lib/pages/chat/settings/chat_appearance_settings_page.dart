import 'package:flutter/material.dart';
import 'package:torn_pda/pages/chat/settings/chat_settings_subpage.dart';
import 'package:torn_pda/widgets/chat/chat_appearance_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_color_widgets.dart';
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
