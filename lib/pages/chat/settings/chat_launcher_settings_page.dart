import 'package:flutter/material.dart';
import 'package:torn_pda/pages/chat/settings/chat_settings_subpage.dart';
import 'package:torn_pda/pages/settings/app_icon_menu_page.dart';
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
      title: 'Chat button',
      description: 'Where the chat button lives, with your unread count',
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
          ChatSettingsNote(
            'Tap it to open ${prefs.launcherTap == ChatLauncherTap.full ? 'the full chat' : 'a chat window'}, '
            'long press it for Window, Full chat and Chat settings',
          ),
          const ListTile(title: Text('Tapping the button opens')),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<ChatLauncherTap>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: ChatLauncherTap.full, label: Text('Full chat')),
                  ButtonSegment(value: ChatLauncherTap.window, label: Text('Window')),
                ],
                selected: {prefs.launcherTap},
                onSelectionChanged: (v) => prefs.setLauncherTap(v.first),
              ),
            ),
          ),
          if (prefs.launcher != ChatLauncher.bubble)
            SwitchListTile(
              title: const Text('Minimize chats to small bubbles'),
              subtitle: const Text('One bubble per chat, tap it to bring the chat back. Off, windows only close'),
              value: prefs.miniBubbles,
              onChanged: prefs.setMiniBubbles,
            ),
          SwitchListTile(
            title: const Text('Reopen chats as I left them'),
            subtitle: const Text('Windows and the full chat you had open come back after a restart'),
            value: prefs.reopenChats,
            onChanged: prefs.setReopenChats,
          ),
          ListTile(
            title: const Text('App icon menu'),
            subtitle: const Text('Pick what a long press on the Torn PDA icon shows'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                settings: const RouteSettings(name: 'app_icon_menu'),
                builder: (_) => const AppIconMenuPage(),
              ),
            ),
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
