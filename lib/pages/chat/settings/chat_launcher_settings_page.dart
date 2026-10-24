import 'package:flutter/material.dart';
import 'package:torn_pda/pages/chat/settings/chat_settings_subpage.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/widgets/chat/chat_alerts_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_logo_bubble.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';
import 'package:torn_pda/widgets/diagrams/feature_diagrams.dart';

class ChatLauncherSettingsPage extends StatelessWidget {
  const ChatLauncherSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChatSettingsSubpage(
      title: 'Open the chat from',
      description: 'The floating bubble, the browser chat button or the side menu',
      builder: (context) {
        final prefs = NativeChat.prefs;
        return [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
            child: Column(
              children: [
                FeatureDiagram(
                  key: ValueKey(prefs.launcher),
                  scenes: [
                    switch (prefs.launcher) {
                      ChatLauncher.bubble => FeatureDiagramScene.chatBubble,
                      ChatLauncher.browser => FeatureDiagramScene.chatBrowser,
                      ChatLauncher.menuHeader => FeatureDiagramScene.chatDrawer,
                      ChatLauncher.menuBar => FeatureDiagramScene.chatMenuBar,
                    },
                  ],
                  showCaption: true,
                ),
                const SizedBox(height: 12),
                const ChatLauncherPicker(),
              ],
            ),
          ),
          SwitchListTile(
            title: const Text('Chats in the app icon menu'),
            subtitle: const Text('Long press the Torn PDA icon to jump to your most used chats'),
            value: prefs.shortcuts,
            onChanged: NativeChat.setShortcuts,
          ),
          ListTile(
            title: const Text('Chat icon on Torn profiles'),
            subtitle: Text(
              prefs.profileIcon == ChatProfileIcon.pda
                  ? 'Opens a private chat window in Torn PDA'
                  : 'Opens the chat on Torn\'s own page',
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<ChatProfileIcon>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: ChatProfileIcon.pda, label: Text('Torn PDA')),
                  ButtonSegment(value: ChatProfileIcon.torn, label: Text('Torn')),
                ],
                selected: {prefs.profileIcon},
                onSelectionChanged: (v) => prefs.setProfileIcon(v.first),
              ),
            ),
          ),
          if (prefs.launcher == ChatLauncher.bubble) ...const [
            ChatGlowSettings(),
            ChatSettingsNote('Same as ticker follows the ticker levels in Alerts'),
          ],
        ];
      },
    );
  }
}
