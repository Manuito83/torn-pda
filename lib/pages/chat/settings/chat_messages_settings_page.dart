import 'package:flutter/material.dart';
import 'package:torn_pda/models/chat/chat_rooms.dart';
import 'package:torn_pda/pages/chat/chat_item_nicknames_page.dart';
import 'package:torn_pda/pages/chat/settings/chat_settings_subpage.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/providers/chat/chat_translate.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

class ChatMessagesSettingsPage extends StatelessWidget {
  const ChatMessagesSettingsPage({super.key});

  Widget _loadChoice(
    BuildContext context,
    String title,
    ChatImageAutoLoad value,
    ValueChanged<ChatImageAutoLoad> onChanged,
    String hint,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(title, style: theme.textTheme.titleSmall),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<ChatImageAutoLoad>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: ChatImageAutoLoad.never, label: Text('Never')),
                ButtonSegment(value: ChatImageAutoLoad.torn, label: Text('Only Torn')),
                ButtonSegment(value: ChatImageAutoLoad.always, label: Text('Always')),
              ],
              selected: {value},
              onSelectionChanged: (v) => onChanged(v.first),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
          child: Text(hint, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChatSettingsSubpage(
      title: 'Messages & links',
      builder: (context) {
        final prefs = NativeChat.prefs;
        return [
          SwitchListTile(
            title: const Text('Load images in private chats'),
            subtitle: const Text('Private chats, faction, company and groups. Known sites only, others wait for a tap'),
            value: prefs.imagesPrivate,
            onChanged: prefs.setImagesPrivate,
          ),
          SwitchListTile(
            title: const Text('Load images in public channels'),
            subtitle: const Text('Global, Trade and other public rooms. Known sites only, others wait for a tap'),
            value: prefs.imagesPublic,
            onChanged: prefs.setImagesPublic,
          ),
          _loadChoice(context, 'Link previews', prefs.linkPreviews, prefs.setLinkPreviews, switch (prefs.linkPreviews) {
            ChatImageAutoLoad.never => 'Every preview waits until you tap it',
            ChatImageAutoLoad.torn => 'Torn links fill in from the API, other sites wait until you tap them',
            ChatImageAutoLoad.always => 'Torn links fill in by themselves, other sites in the chats below. '
                'Those sites see your IP address',
          }),
          if (prefs.linkPreviews == ChatImageAutoLoad.always) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text('Load link previews automatically', style: Theme.of(context).textTheme.titleSmall),
            ),
            for (final group in ChatPrefs.tickerOptions)
              SwitchListTile(
                dense: true,
                title: Text(ChatRooms.labelOf(group)),
                value: !prefs.linkPreviewsOff.contains(group),
                onChanged: (v) => prefs.setLinkPreviewsIn(group, v),
              ),
          ],
          SwitchListTile(
            title: const Text('Preview links in a window'),
            subtitle: const Text('A small browser over the app, without scripts'),
            value: prefs.linkWindow,
            onChanged: prefs.setLinkWindow,
          ),
          if (!prefs.linkWindow)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Open links in', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<bool>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: false, label: Text('Main tab')),
                        ButtonSegment(value: true, label: Text('New tab')),
                      ],
                      selected: {prefs.linkNewTab},
                      onSelectionChanged: (v) => prefs.setLinkNewTab(v.first),
                    ),
                  ),
                ],
              ),
            ),
          const ChatSettingsHeading('Trade'),
          SwitchListTile(
            title: const Text('Price check on offers'),
            subtitle: const Text('Shows the market value next to WTS and WTB prices in Trade and Global'),
            value: prefs.priceCheck,
            onChanged: prefs.setPriceCheck,
          ),
          SwitchListTile(
            title: const Text('Bazaar analysis'),
            subtitle: const Text('Checks the bazaar of whoever offers an item, in the bubble and in bazaar links'),
            value: prefs.bazaarAnalysis,
            onChanged: prefs.priceCheck ? prefs.setBazaarAnalysis : null,
          ),
          SwitchListTile(
            title: const Text('Compare amounts with your cash'),
            subtitle: const Text('Tapping an amount says if your cash covers it'),
            value: prefs.moneyOnHand,
            onChanged: prefs.setMoneyOnHand,
          ),
          ChatSettingsLink(
            leading: const Icon(Icons.sell_outlined),
            title: 'Item nicknames (${prefs.itemAliases.length})',
            subtitle: 'Short names players use, like xans for Xanax',
            page: const ChatItemNicknamesPage(),
          ),
          const ChatSettingsHeading('Reading'),
          SwitchListTile(
            title: const Text('Explain Torn slang everywhere'),
            subtitle: const Text('Underline terms like OC or xanax in every chat, not only in the New players room'),
            value: prefs.slangEverywhere,
            onChanged: prefs.setSlangEverywhere,
          ),
          ListTile(
            leading: const Icon(Icons.translate_rounded),
            title: const Text('Translate to'),
            subtitle: const Text(
              'Long press a message and tap translate. Only that text goes to Google Translate, '
              'or to MyMemory if it fails',
            ),
            trailing: DropdownButton<String>(
              value: ChatTranslator.languages.containsKey(prefs.translateTo) ? prefs.translateTo : '',
              underline: const SizedBox(),
              items: [
                DropdownMenuItem(value: '', child: Text('Device (${ChatTranslator.deviceLanguage()})')),
                for (final e in ChatTranslator.languages.entries) DropdownMenuItem(value: e.key, child: Text(e.value)),
              ],
              onChanged: (v) => prefs.setTranslateTo(v ?? ''),
            ),
          ),
        ];
      },
    );
  }
}
