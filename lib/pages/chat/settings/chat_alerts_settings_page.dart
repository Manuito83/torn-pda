import 'package:flutter/material.dart';
import 'package:torn_pda/pages/chat/settings/chat_settings_subpage.dart';
import 'package:torn_pda/widgets/alerts/alert_cards.dart';
import 'package:torn_pda/widgets/chat/chat_alerts_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

class ChatAlertsSettingsPage extends StatelessWidget {
  const ChatAlertsSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChatSettingsSubpage(
      title: 'Alerts',
      builder: (context) {
        final prefs = NativeChat.prefs;
        final words = prefs.browserWords;
        final alerting = words.where(prefs.alertWords.contains).length;
        final seconds = prefs.tickerSeconds == 0 ? 'until dismissed' : '${prefs.tickerSeconds} s';
        return [
          const ChatSettingsHeading('Phone'),
          AlertRow(
            title: 'DM notifications',
            subtitle: alertDmPushText,
            value: prefs.dmPush,
            onChanged: prefs.setDmPush,
          ),
          const ChatSettingsNote('Same switch as in Alerts'),
          const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: TextButton(onPressed: NativeChat.openAlerts, child: Text('Open Alerts')),
            ),
          ),
          const ChatSettingsHeading('While the app is open'),
          const ChatAlertSettings(),
          ChatSettingsLink(
            leading: const Icon(Icons.subtitles_rounded),
            title: 'Ticker',
            subtitle: prefs.ticker
                ? '${prefs.tickerTop ? 'Top' : 'Bottom'} - $seconds - ${prefs.tickerMax} at a time'
                : 'Off',
            page: ChatSettingsSubpage(title: 'Ticker', builder: (_) => const [ChatTickerSettings()]),
          ),
          ChatSettingsLink(
            leading: const Icon(Icons.highlight_rounded),
            title: 'Highlight words',
            subtitle: words.isEmpty
                ? 'None'
                : '${words.length} ${words.length == 1 ? 'word' : 'words'}, $alerting alerting',
            page: ChatSettingsSubpage(
              title: 'Highlight words',
              description: 'Same list as Settings > Browser. The bell alerts only in chats set to Everything',
              builder: (_) => const [ChatHighlightWords()],
            ),
          ),
          const ChatSettingsNote('Each chat has its own level, mute and sound: long press it in the chat list'),
        ];
      },
    );
  }
}
