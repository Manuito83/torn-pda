import 'package:flutter/material.dart';
import 'package:torn_pda/pages/chat/settings/chat_alerts_settings_page.dart';
import 'package:torn_pda/pages/chat/settings/chat_appearance_settings_page.dart';
import 'package:torn_pda/pages/chat/settings/chat_faction_settings_page.dart';
import 'package:torn_pda/pages/chat/settings/chat_launcher_settings_page.dart';
import 'package:torn_pda/pages/chat/settings/chat_messages_settings_page.dart';
import 'package:torn_pda/pages/chat/settings/chat_people_settings_page.dart';
import 'package:torn_pda/pages/chat/settings/chat_rooms_settings_page.dart';
import 'package:torn_pda/pages/chat/settings/chat_settings_subpage.dart';
import 'package:torn_pda/pages/chat/settings/chat_upload_settings_page.dart';
import 'package:torn_pda/pages/chat/settings/chat_writing_settings_page.dart';
import 'package:torn_pda/pages/settings/app_icon_menu_page.dart';
import 'package:torn_pda/providers/chat/chat_backup.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/widgets/chat/chat_alias_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_intro_sheet.dart';
import 'package:torn_pda/widgets/chat/chat_reminder_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_theme.dart';
import 'package:torn_pda/widgets/chat/chat_toast.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

Future<void> showChatSettings(NavigatorState navigator, {bool alerts = false, bool imageUpload = false}) {
  final opened = navigator.push(MaterialPageRoute(builder: (_) => const ChatTheme(child: ChatSettingsPage())));
  if (alerts) {
    navigator.push(MaterialPageRoute(builder: (_) => const ChatTheme(child: ChatAlertsSettingsPage())));
  }
  if (imageUpload) {
    navigator.push(MaterialPageRoute(builder: (_) => const ChatTheme(child: ChatUploadSettingsPage())));
  }
  return opened;
}

class ChatSettingsPage extends StatelessWidget {
  const ChatSettingsPage({super.key});

  String _alertsSummary() {
    final prefs = NativeChat.prefs;
    return [
      prefs.mentions ? 'Mentions on' : 'Mentions off',
      prefs.ticker ? 'Ticker ${prefs.tickerTop ? 'top' : 'bottom'}' : 'Ticker off',
      if (prefs.quietHours && prefs.alertNotify) 'Quiet ${prefs.minutesClock(prefs.quietFrom)} to ${prefs.minutesClock(prefs.quietTo)}',
    ].join(' - ');
  }

  String? _import(String text, bool replace) {
    final ChatBackup backup;
    try {
      backup = ChatBackup.parse(text);
    } on FormatException catch (e) {
      return e.message;
    }
    NativeChat.prefs.applyBackup(backup, replace: replace);
    if (replace && backup.inAppEnabled != null && backup.inAppEnabled != NativeChat.prefs.inAppEnabled) {
      NativeChat.setEnabled(backup.inAppEnabled!);
    }
    AppIconMenu.publish();
    chatToast('Chat settings imported', seconds: 2);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ChatSettingsSubpage(
      title: 'Chat settings',
      builder: (context) {
        final prefs = NativeChat.prefs;
        return [
          SwitchListTile(
            title: const Text('In-app chat'),
            subtitle: const Text('Read and write Torn chat inside Torn PDA'),
            value: prefs.inAppEnabled,
            onChanged: NativeChat.setEnabled,
          ),
          if (NativeChat.compiled) const ChatHideWebChatTile(title: 'Hide Torn\'s web chat in browser tabs'),
          const SizedBox(height: 8),
          ChatSettingsLink(
            leading: const Icon(Icons.ads_click_rounded),
            title: 'Chat button',
            subtitle: switch (prefs.launcher) {
              ChatLauncher.bubble => 'Bubble',
              ChatLauncher.browser => 'Browser',
              ChatLauncher.menuHeader => 'Menu header',
              ChatLauncher.menuBar => 'Menu bar',
            },
            page: const ChatLauncherSettingsPage(),
          ),
          ChatSettingsLink(
            leading: const Icon(Icons.notifications_rounded),
            title: 'Alerts',
            subtitle: _alertsSummary(),
            page: const ChatAlertsSettingsPage(),
          ),
          const ChatSettingsLink(
            leading: Icon(Icons.view_agenda_rounded),
            title: 'Rooms',
            subtitle: 'Placement, live or frozen, unread',
            page: ChatRoomsSettingsPage(),
          ),
          const ChatSettingsLink(
            leading: Icon(Icons.text_fields_rounded),
            title: 'Appearance',
            subtitle: 'Bubbles, text size, colors',
            page: ChatAppearanceSettingsPage(),
          ),
          const ChatSettingsLink(
            leading: Icon(Icons.perm_media_rounded),
            title: 'Messages & links',
            subtitle: 'Images, previews, prices, translate',
            page: ChatMessagesSettingsPage(),
          ),
          const ChatSettingsLink(
            leading: Icon(Icons.edit_note_rounded),
            title: 'Writing & actions',
            subtitle: 'Quick actions, replies, long press',
            page: ChatWritingSettingsPage(),
          ),
          ChatSettingsLink(
            leading: const Icon(Icons.badge_rounded),
            title: 'People',
            subtitle: '${prefs.people.length} customized - ${prefs.ignored.length} ignored',
            page: const ChatPeopleSettingsPage(),
          ),
          const ChatSettingsLink(
            leading: Icon(Icons.shield_rounded),
            title: 'Faction room',
            subtitle: 'Chain, war, who is online',
            page: ChatFactionSettingsPage(),
          ),
          const ChatSettingsHeading('More'),
          ListTile(
            leading: const Icon(Icons.lightbulb_outline_rounded),
            title: const Text('How the chat works'),
            subtitle: const Text('The bubble, the chat icon and where things are'),
            onTap: () => showChatIntro(context, always: true),
          ),
          ListTile(
            leading: const Icon(Icons.alarm_rounded),
            title: const Text('Reminders'),
            subtitle: Text('${prefs.pendingReminders.length} pending'),
            onTap: () => showChatRemindersList(context),
          ),
          ListTile(
            leading: const Icon(Icons.settings_backup_restore_rounded),
            title: const Text('Back up chat settings'),
            subtitle: const Text('Move your nicknames, notes, colors and preferences to another device'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ChatExportMenu(
                  tooltip: 'Export chat settings',
                  text: () => ChatBackup.export(prefs, DateTime.now()),
                  copied: 'Chat settings copied',
                ),
                IconButton(
                  tooltip: 'Import chat settings',
                  icon: const Icon(Icons.download_rounded),
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => ChatImportDialog(
                      title: 'Import chat settings',
                      hint:
                          'Paste the exported text or pick a file. Merge keeps what you already have and adds the '
                          'rest. Replace overwrites everything with the backup',
                      label: 'Chat settings',
                      actions: [('Merge', (text) => _import(text, false)), ('Replace', (text) => _import(text, true))],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ];
      },
    );
  }
}
