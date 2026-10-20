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
          if (prefs.launcher == ChatLauncher.bubble) ...const [
            ChatGlowSettings(),
            ChatSettingsNote('Same as ticker follows the ticker levels in Alerts'),
          ],
        ];
      },
    );
  }
}
