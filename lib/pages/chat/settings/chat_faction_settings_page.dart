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
            title: const Text('Taking watch turns on the Watcher'),
            subtitle: const Text('Leaving watch turns it off again if taking watch turned it on'),
            value: prefs.watchTurnsOnWatcher,
            onChanged: prefs.setWatchTurnsOnWatcher,
          ),
          SwitchListTile(
            title: const Text('War in faction chat'),
            subtitle: const Text('Ranked war score on top and a summary when it ends'),
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
            title: const Text("I'm a banker"),
            subtitle: const Text('Money requests from other members get a button that opens the vault page filled in'),
            value: prefs.factionBanker,
            onChanged: prefs.setFactionBanker,
          ),
          ChatFactionEventsSetting(prefs: prefs),
        ];
      },
    );
  }
}
