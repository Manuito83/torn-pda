import 'package:flutter/material.dart';
import 'package:torn_pda/pages/chat/settings/chat_settings_subpage.dart';
import 'package:torn_pda/widgets/chat/chat_faction_events_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

class ChatFactionSettingsPage extends StatelessWidget {
  const ChatFactionSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChatSettingsSubpage(
      title: 'Faction room',
      description: 'Enemy chain, who is online, events and the chain and war summaries call the API',
      builder: (context) {
        final prefs = NativeChat.prefs;
        return [
          SwitchListTile(
            title: const Text('Chain in faction chat'),
            subtitle: const Text('Hits and timeout in the header, a note when it gets low, a summary when it ends'),
            value: prefs.factionChain,
            onChanged: prefs.setFactionChain,
          ),
          SwitchListTile(
            title: const Text('War in faction chat'),
            subtitle: const Text('Ranked war score on top, a note for each retal, a summary when it ends'),
            value: prefs.factionWar,
            onChanged: prefs.setFactionWar,
          ),
          SwitchListTile(
            title: const Text('Enemy chain in faction chat'),
            subtitle: const Text('Hits and time left of the enemy chain during a ranked war'),
            value: prefs.factionEnemyChain,
            onChanged: prefs.setFactionEnemyChain,
          ),
          SwitchListTile(
            title: const Text('Who is online in faction chat'),
            subtitle: const Text('Online, hospital and abroad count, tap for the member list'),
            value: prefs.factionRoster,
            onChanged: prefs.setFactionRoster,
          ),
          ChatFactionEventsSetting(prefs: prefs),
        ];
      },
    );
  }
}
