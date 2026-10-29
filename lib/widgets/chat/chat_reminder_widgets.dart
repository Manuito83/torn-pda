import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/main.dart' show flutterLocalNotificationsPlugin;
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_reminder.dart';
import 'package:torn_pda/providers/chain_status_controller.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/utils/notification.dart';
import 'package:torn_pda/widgets/chat/chat_toast.dart';
import 'package:torn_pda/widgets/chat/chat_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

Future<void> showChatReminderSheet(BuildContext context, ChatMessage message, String roomName) async {
  final chain = Get.isRegistered<ChainStatusController>() ? Get.find<ChainStatusController>() : null;
  final now = DateTime.now();
  final game = chain?.barsAndStatusModel == null
      ? const <ChatReminderOption>[]
      : ChatReminders.triggers(bars: chain!.barsAndStatusModel!, now: now.millisecondsSinceEpoch ~/ 1000);
  const waits = [('In 10 min', Duration(minutes: 10)), ('In 1 h', Duration(hours: 1))];
  final theme = Theme.of(context);
  final picked = await showModalBottomSheet<ChatReminderOption>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Remind me', style: theme.textTheme.titleMedium),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
              child: Text(
                '${message.sender.name}: ${message.content}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            for (final (label, wait) in waits)
              ListTile(
                minTileHeight: 48,
                leading: const Icon(Icons.alarm_rounded),
                title: Text(label),
                trailing: Text(NativeChat.prefs.stamp(now.add(wait))),
                onTap: () => Navigator.pop(sheet, ChatReminderOption(label, DateTime.now().add(wait))),
              ),
            for (final option in game)
              ListTile(
                minTileHeight: 48,
                leading: const Icon(Icons.alarm_rounded),
                title: Text(option.label),
                trailing: Text(NativeChat.prefs.stamp(option.at)),
                onTap: () => Navigator.pop(sheet, option),
              ),
            ListTile(
              minTileHeight: 48,
              leading: const Icon(Icons.schedule_rounded),
              title: const Text('Custom time'),
              onTap: () async {
                final prefs = NativeChat.prefs;
                final time = await showChatTimePicker(
                  sheet,
                  TimeOfDay.fromDateTime(prefs.wallClock(now.add(const Duration(hours: 1)))),
                );
                if (time == null || !sheet.mounted) return;
                final at = prefs.nextAt(time.hour, time.minute, DateTime.now());
                Navigator.pop(sheet, ChatReminderOption('Custom time', at));
              },
            ),
          ],
        ),
      ),
    ),
  );
  if (picked == null || !context.mounted) return;
  void tell(String text) => chatToast(text, seconds: 3);
  if (!picked.at.isAfter(DateTime.now())) return tell('That time has passed, pick another one');

  final settings = context.read<SettingsProvider>();
  if (Platform.isAndroid) await assessExactAlarmsPermissionsAndroid(context, settings);
  final prefs = NativeChat.prefs;
  final reminder = ChatReminder.of(
    message,
    roomName,
    id: ChatReminders.nextId(prefs.reminders),
    at: picked.at,
    label: picked.label,
  );
  try {
    await scheduleChatReminder(reminder);
  } catch (_) {
    if (context.mounted) tell('Could not set the reminder');
    return;
  }
  prefs.setReminders([...prefs.pendingReminders, reminder]);
  if (!context.mounted) return;
  tell('Reminder set for ${NativeChat.prefs.stamp(picked.at)}');
}

Future<void> showChatRemindersList(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => ListenableBuilder(
    listenable: NativeChat.prefs,
    builder: (sheet, _) {
      final theme = Theme.of(sheet);
      final pending = NativeChat.prefs.pendingReminders;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(sheet).height * 0.7),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: 12),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('Reminders', style: theme.textTheme.titleMedium),
              ),
              if (pending.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No pending reminders. Long press a message and pick Remind me in its menu',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              for (final r in pending)
                ListTile(
                  title: Text(r.excerpt, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${r.author} in ${r.roomName} - ${NativeChat.prefs.stamp(r.at)} (${r.label})'),
                  trailing: IconButton(
                    tooltip: 'Delete reminder',
                    style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () async {
                      await flutterLocalNotificationsPlugin.cancel(r.id);
                      NativeChat.prefs.setReminders([...NativeChat.prefs.reminders.where((x) => x.id != r.id)]);
                    },
                  ),
                ),
            ],
          ),
        ),
      );
    },
  ),
);
