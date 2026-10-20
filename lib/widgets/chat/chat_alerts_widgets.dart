import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chat/chat_alerts.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_rooms.dart';
import 'package:torn_pda/models/chat/chat_tone.dart';
import 'package:torn_pda/providers/chain_status_controller.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/widgets/chat/chat_link_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

class ChatAlertsButton extends StatelessWidget {
  const ChatAlertsButton({super.key, required this.onOpen});

  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatController>();
    final unseen = chat.unseenAlerts;
    return IconButton(
      tooltip: unseen > 0 ? 'Mentions and highlight words, $unseen new' : 'Mentions and highlight words',
      icon: Badge(
        isLabelVisible: unseen > 0,
        label: ExcludeSemantics(child: Text(unseen > 99 ? '99+' : '$unseen')),
        child: const Icon(Icons.alternate_email_rounded),
      ),
      onPressed: () async {
        final roomId = await showModalBottomSheet<String>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => _ChatAlertsSheet(chat),
        );
        chat.markAlertsSeen();
        if (roomId != null) onOpen(roomId);
      },
    );
  }
}

class _ChatAlertsSheet extends StatelessWidget {
  const _ChatAlertsSheet(this.chat);

  final ChatController chat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: chat,
      builder: (context, _) {
        final alerts = chat.alerts;
        return SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.7,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 8, 4),
                child: Row(
                  children: [
                    Expanded(child: Text('Mentions and highlight words', style: theme.textTheme.titleMedium)),
                    if (alerts.isNotEmpty) TextButton(onPressed: chat.clearAlerts, child: const Text('Clear')),
                  ],
                ),
              ),
              Expanded(
                child: alerts.isEmpty
                    ? ChatStateMessage(
                        icon: Icons.alternate_email_rounded,
                        title: 'Nothing yet',
                        subtitle: chat.myName == null
                            ? 'Mentions show up here once the chat is connected'
                            : 'Mentions of ${chat.myName} and your highlight words show up here while the app is open',
                      )
                    : ListView.separated(
                        itemCount: alerts.length,
                        separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
                        itemBuilder: (context, index) => _alertTile(context, alerts[index]),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _alertTile(BuildContext context, ChatAlert alert) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final m = alert.message;
    final room = chat.roomById(m.roomId);
    final match = alert.match;
    return ListTile(
      leading: ChatRoomAvatar(room: room, size: 40),
      title: Text(
        room.isDm ? m.sender.name : '${m.sender.name} in ${room.name}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontWeight: alert.seen ? null : FontWeight.w700),
      ),
      subtitle: Text(m.content.replaceAll('\n', ' '), maxLines: 3, overflow: TextOverflow.ellipsis),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(DateFormat.Hm().format(m.createdAt), style: theme.textTheme.labelSmall),
          const SizedBox(height: 4),
          if (match != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(color: scheme.tertiaryContainer, borderRadius: BorderRadius.circular(8)),
              child: Text(
                match.mention ? '@' : match.keyword!,
                style: theme.textTheme.labelSmall?.copyWith(color: scheme.onTertiaryContainer),
              ),
            ),
        ],
      ),
      onTap: () => Navigator.pop(context, m.roomId),
      onLongPress: m.sender.id > 0 ? () => showChatPlayerActions(context, m.sender) : null,
    );
  }
}

String chatMuteUntilText(DateTime until) {
  final now = DateTime.now();
  final days = DateTime(until.year, until.month, until.day).difference(DateTime(now.year, now.month, now.day)).inDays;
  final time = DateFormat.Hm().format(until);
  return switch (days) {
    0 => time,
    1 => 'tomorrow $time',
    _ => '${DateFormat.MMMd().format(until)} $time',
  };
}

Widget _dropdownTile(BuildContext context, String title, Widget dropdown) {
  return ListTile(
    title: Text(title),
    trailing: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width / 2),
      child: IntrinsicWidth(child: dropdown),
    ),
  );
}

Future<void> showChatRoomAlerts(BuildContext context, ChatRoom room) {
  final theme = Theme.of(context);
  final chain = Get.isRegistered<ChainStatusController>() ? Get.find<ChainStatusController>() : null;
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (context) => ListenableBuilder(
      listenable: NativeChat.prefs,
      builder: (context, _) {
        final prefs = NativeChat.prefs;
        final muted = prefs.isMuted(room.id);
        final until = prefs.mutedUntilOf(room.id);
        final level = prefs.alertLevel(room.id);
        final tone = prefs.toneOf(room.id);
        final landing = chatLandingTime(chain?.barsAndStatusModel, DateTime.now());
        final effect = level == ChatAlertLevel.mentions
            ? 'Only when you are mentioned, with or without @'
            : 'No alerts at all from this chat';
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: ChatRoomAvatar(room: room, size: 40),
                  title: Text(room.name),
                ),
                ListTile(
                  leading: Icon(
                    until != null
                        ? Icons.snooze_rounded
                        : (muted ? Icons.notifications_off_rounded : Icons.notifications_none_rounded),
                  ),
                  title: const Text('Mute for'),
                  subtitle: Text(
                    !muted
                        ? effect
                        : (until == null
                              ? 'Muted until you unmute. $effect'
                              : 'Until ${chatMuteUntilText(until)}. $effect'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      if (muted)
                        ActionChip(
                          label: const Text('Unmute'),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            prefs.setMuted(room.id, false);
                          },
                        ),
                      for (final option in ChatMuteFor.values)
                        ChoiceChip(
                          label: Text(option.label),
                          selected: option == ChatMuteFor.always
                              ? muted && until == null
                              : option == prefs.muteChoiceOf(room.id),
                          onSelected: (_) {
                            HapticFeedback.lightImpact();
                            prefs.setMuted(room.id, true, until: option.until(DateTime.now()), choice: option);
                          },
                        ),
                      if (landing != null)
                        ChoiceChip(
                          label: const Text('Until I land'),
                          selected: muted && until == landing,
                          onSelected: (_) {
                            HapticFeedback.lightImpact();
                            prefs.setMuted(room.id, true, until: landing);
                          },
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Alert on', style: theme.textTheme.titleSmall),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SegmentedButton<ChatAlertLevel>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: ChatAlertLevel.all, label: Text('Everything')),
                      ButtonSegment(value: ChatAlertLevel.mentions, label: Text('Mentions')),
                      ButtonSegment(value: ChatAlertLevel.none, label: Text('Nothing')),
                    ],
                    selected: {level},
                    onSelectionChanged: (v) => prefs.setAlertLevel(room.id, v.first),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Highlight words alert only with Everything',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
                _dropdownTile(
                  context,
                  'Sound',
                  DropdownButton<ChatSound>(
                    value: tone.sound,
                    isExpanded: true,
                    onChanged: (v) => prefs.setTone(room.id, tone.copyWith(sound: v)),
                    items: [
                      for (final s in ChatSound.values)
                        DropdownMenuItem(
                          value: s,
                          child: Text(
                            s == ChatSound.standard
                                ? 'Default (${ChatTone.standard.resolve(prefs.allSound, room.id).sound.label})'
                                : s.label,
                          ),
                        ),
                    ],
                  ),
                ),
                _dropdownTile(
                  context,
                  'Vibration',
                  DropdownButton<ChatVibration>(
                    value: tone.vibration,
                    isExpanded: true,
                    onChanged: (v) => prefs.setTone(room.id, tone.copyWith(vibration: v)),
                    items: [for (final v in ChatVibration.values) DropdownMenuItem(value: v, child: Text(v.label))],
                  ),
                ),
                if (room.isDm || Platform.isIOS)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        [
                          if (room.isDm) 'Also used for their mentions in rooms',
                          if (Platform.isIOS) 'iOS decides the vibration',
                        ].join('. '),
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                if (!room.isDm)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: ChatRoomStatePicker(roomId: room.id),
                  ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class ChatAlertSettings extends StatelessWidget {
  const ChatAlertSettings({super.key});

  static String _time(BuildContext context, int minutes) =>
      TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60).format(context);

  static Future<void> _pickTime(BuildContext context, int minutes, void Function(int) onPicked) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
    );
    if (picked != null) onPicked(picked.hour * 60 + picked.minute);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prefs = NativeChat.prefs;
    return ListenableBuilder(
      listenable: NativeChat.prefs,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: Text(
              NativeChat.controller.myName == null
                  ? 'Mentions of your name'
                  : 'Mentions of ${NativeChat.controller.myName}',
            ),
            subtitle: const Text('@name or the name alone, as a whole word'),
            value: prefs.mentions,
            onChanged: prefs.setMentions,
          ),
          SwitchListTile(
            title: const Text('Notify while the app is open'),
            subtitle: const Text('When off, mentions only show in the @ list'),
            value: prefs.alertNotify,
            onChanged: prefs.setAlertNotify,
          ),
          SwitchListTile(
            title: const Text('Vibrate on in-app chat alerts'),
            subtitle: const Text('When the app is open'),
            value: prefs.alertVibrate,
            onChanged: prefs.setAlertVibrate,
          ),
          if (prefs.alertNotify) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text('Tapping a notification opens', style: theme.textTheme.bodyMedium),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SegmentedButton<ChatNotificationTap>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: ChatNotificationTap.window,
                    icon: Icon(Icons.picture_in_picture_alt_rounded),
                    label: Text('Quick window'),
                  ),
                  ButtonSegment(
                    value: ChatNotificationTap.inbox,
                    icon: Icon(Icons.forum_rounded),
                    label: Text('Full chat'),
                  ),
                ],
                selected: {prefs.notificationTap},
                onSelectionChanged: (v) => prefs.setNotificationTap(v.first),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
              child: Text(
                prefs.notificationTap == ChatNotificationTap.window
                    ? 'A floating window over the browser or the app'
                    : 'The chat screen, open on that conversation',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            SwitchListTile(
              title: const Text('Quiet hours'),
              subtitle: Text(
                'No chat notifications from ${_time(context, prefs.quietFrom)} to ${_time(context, prefs.quietTo)}. '
                'The ticker, the counts and the list of mentions keep working',
              ),
              value: prefs.quietHours,
              onChanged: prefs.setQuietHours,
            ),
            if (prefs.quietHours)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.bedtime_rounded, size: 18),
                        label: Text('From ${_time(context, prefs.quietFrom)}'),
                        onPressed: () => _pickTime(context, prefs.quietFrom, (m) => prefs.setQuietRange(from: m)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.wb_sunny_rounded, size: 18),
                        label: Text('To ${_time(context, prefs.quietTo)}'),
                        onPressed: () => _pickTime(context, prefs.quietTo, (m) => prefs.setQuietRange(to: m)),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          SwitchListTile(
            title: const Text('Sound for all chats'),
            subtitle: const Text(
              'Off: private, faction and company chats use Keyboard, the rest are silent. Each chat can change it',
            ),
            value: prefs.soundForAll,
            onChanged: prefs.setSoundForAll,
          ),
          if (prefs.soundForAll)
            _dropdownTile(
              context,
              'Sound',
              DropdownButton<ChatSound>(
                value: prefs.soundForAllType,
                isExpanded: true,
                onChanged: (v) {
                  if (v != null) prefs.setSoundForAllType(v);
                },
                items: [for (final s in ChatSound.audible) DropdownMenuItem(value: s, child: Text(s.label))],
              ),
            ),
        ],
      ),
    );
  }
}

class ChatHighlightWords extends StatefulWidget {
  const ChatHighlightWords({super.key});

  @override
  State<ChatHighlightWords> createState() => _ChatHighlightWordsState();
}

class _ChatHighlightWordsState extends State<ChatHighlightWords> {
  final TextEditingController _word = TextEditingController();

  @override
  void dispose() {
    _word.dispose();
    super.dispose();
  }

  void _add() {
    NativeChat.prefs.addKeyword(_word.text);
    _word.clear();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = NativeChat.prefs;
    return ListenableBuilder(
      listenable: prefs,
      builder: (context, _) => Column(
        children: [
          for (final word in prefs.browserWords)
            ListTile(
              dense: true,
              title: Text(word),
              leading: IconButton(
                tooltip: prefs.alertWords.contains(word) ? 'Stop alerting for $word' : 'Alert for $word',
                icon: Icon(
                  prefs.alertWords.contains(word)
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_off_outlined,
                ),
                onPressed: () => prefs.setWordAlert(word, !prefs.alertWords.contains(word)),
              ),
              trailing: IconButton(
                tooltip: 'Remove $word',
                icon: const Icon(Icons.close_rounded),
                onPressed: () => prefs.removeKeyword(word),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _word,
              maxLength: ChatPrefs.maxWordLength,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _add(),
              decoration: InputDecoration(
                hintText: 'Add a word: an item, RW, a faction tag',
                counterText: '',
                isDense: true,
                suffixIcon: IconButton(tooltip: 'Add word', icon: const Icon(Icons.add_rounded), onPressed: _add),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatTickerSettings extends StatelessWidget {
  const ChatTickerSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prefs = NativeChat.prefs;
    final hint = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return ListenableBuilder(
      listenable: NativeChat.prefs,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: const Text('Show the ticker'),
            subtitle: const Text('A line for each new message, over the browser and the app'),
            value: prefs.ticker,
            onChanged: prefs.setTicker,
          ),
          if (prefs.ticker) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: true, icon: Icon(Icons.vertical_align_top_rounded), label: Text('Top')),
                  ButtonSegment(value: false, icon: Icon(Icons.vertical_align_bottom_rounded), label: Text('Bottom')),
                ],
                selected: {prefs.tickerTop},
                onSelectionChanged: (v) => prefs.setTickerTop(v.first),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Text('When tapped', style: theme.textTheme.titleSmall),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<ChatTickerTap>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: ChatTickerTap.window, label: Text('Open quick window')),
                    ButtonSegment(value: ChatTickerTap.expand, label: Text('Expand in place')),
                  ],
                  selected: {prefs.tickerTap},
                  onSelectionChanged: (v) => prefs.setTickerTap(v.first),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Text(
                'Press and hold for the other one. Expanded shows the whole message with Open and Reply',
                style: hint,
              ),
            ),
            ListTile(
              title: const Text('Time on screen'),
              trailing: DropdownButton<int>(
                value: prefs.tickerSeconds,
                underline: const SizedBox.shrink(),
                items: [
                  for (final s in ChatPrefs.tickerSecondsOptions)
                    DropdownMenuItem(value: s, child: Text(s == 0 ? 'Until dismissed' : '$s s')),
                ],
                onChanged: (v) => prefs.setTickerSeconds(v ?? 6),
              ),
            ),
            ListTile(
              title: const Text('How many at a time'),
              trailing: SegmentedButton<int>(
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                segments: [for (final n in ChatPrefs.tickerMaxOptions) ButtonSegment(value: n, label: Text('$n'))],
                selected: {prefs.tickerMax},
                onSelectionChanged: (v) => prefs.setTickerMax(v.first),
              ),
            ),
            ListTile(
              title: const Text('Lines of text'),
              subtitle: const Text('The size follows the chat text size in Appearance'),
              trailing: SegmentedButton<int>(
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                segments: [for (final n in ChatPrefs.tickerLinesOptions) ButtonSegment(value: n, label: Text('$n'))],
                selected: {prefs.tickerLines},
                onSelectionChanged: (v) => prefs.setTickerLines(v.first),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: NativeChat.tickerDemo.launch,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Preview'),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text('Muted chats and ignored players stay out. @ means only when you are mentioned', style: hint),
            ),
            for (final group in ChatPrefs.tickerOptions)
              ChatGroupLevelRow(
                group: group,
                level: prefs.tickerLevel(group),
                onChanged: (level) => prefs.setTickerLevel(group, level),
              ),
          ],
        ],
      ),
    );
  }
}

class ChatGroupLevelRow extends StatelessWidget {
  const ChatGroupLevelRow({super.key, required this.group, required this.level, required this.onChanged});

  final String group;
  final ChatAlertLevel level;
  final ValueChanged<ChatAlertLevel> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          SizedBox(width: 32, child: ChatRoomGlyph.of(NativeChat.controller.roomById(group), size: 22)),
          Expanded(child: Text(ChatRooms.labelOf(group))),
          SegmentedButton<ChatAlertLevel>(
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            segments: const [
              ButtonSegment(value: ChatAlertLevel.all, label: Text('All')),
              ButtonSegment(value: ChatAlertLevel.mentions, label: Text('@')),
              ButtonSegment(value: ChatAlertLevel.none, label: Text('Off')),
            ],
            selected: {level},
            onSelectionChanged: (v) => onChanged(v.first),
          ),
        ],
      ),
    );
  }
}

class ChatGlowSettings extends StatelessWidget {
  const ChatGlowSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prefs = NativeChat.prefs;
    return ListenableBuilder(
      listenable: prefs,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: const Text('Glow on new messages'),
            subtitle: Text(
              'A short flash in the color of the room the message came from. Never for frozen or hidden rooms',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<ChatGlowMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: ChatGlowMode.ticker, label: Text('Same as ticker')),
                  ButtonSegment(value: ChatGlowMode.custom, label: Text('Custom')),
                  ButtonSegment(value: ChatGlowMode.off, label: Text('Off')),
                ],
                selected: {prefs.glowMode},
                onSelectionChanged: (v) => prefs.setGlowMode(v.first),
              ),
            ),
          ),
          if (prefs.glowMode == ChatGlowMode.custom)
            for (final group in ChatPrefs.tickerOptions)
              ChatGroupLevelRow(
                group: group,
                level: prefs.glowLevel(group),
                onChanged: (level) => prefs.setGlowLevel(group, level),
              ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class ChatRoomStatePicker extends StatelessWidget {
  const ChatRoomStatePicker({super.key, required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prefs = NativeChat.prefs;
    final state = prefs.roomState(roomId);
    final until = prefs.frozenUntilOf(roomId);
    final hint = switch (state) {
      ChatRoomState.live => 'Updates in real time, like Torn\'s chat',
      ChatRoomState.frozen =>
        until == null
            ? 'Frozen until you unfreeze it. No messages, alerts or counts'
            : 'Frozen until ${chatMuteUntilText(until)}. No messages, alerts or counts',
      ChatRoomState.hidden => 'Out of the chat list and the counts',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<ChatRoomState>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: ChatRoomState.live, label: Text('Live')),
              ButtonSegment(value: ChatRoomState.frozen, icon: Icon(Icons.ac_unit_rounded), label: Text('Frozen')),
              ButtonSegment(value: ChatRoomState.hidden, label: Text('Hidden')),
            ],
            selected: {state},
            onSelectionChanged: (v) {
              HapticFeedback.lightImpact();
              prefs.setRoomState(roomId, v.first);
            },
          ),
        ),
        if (state == ChatRoomState.frozen)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 8,
              children: [
                for (final option in ChatMuteFor.values)
                  ChoiceChip(
                    label: Text(option.freezeLabel),
                    selected: option == ChatMuteFor.always ? until == null : option == prefs.freezeChoiceOf(roomId),
                    onSelected: (_) {
                      HapticFeedback.lightImpact();
                      prefs.setRoomState(
                        roomId,
                        ChatRoomState.frozen,
                        until: option.until(DateTime.now()),
                        choice: option,
                      );
                    },
                  ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(hint, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ),
      ],
    );
  }
}
