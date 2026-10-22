import 'package:flutter/material.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_rooms.dart';
import 'package:torn_pda/pages/chat/settings/chat_settings_subpage.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/widgets/chat/chat_alerts_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

class ChatRoomsSettingsPage extends StatelessWidget {
  const ChatRoomsSettingsPage({super.key});

  static const _waitingChoices = [0, 1, 3, 6, 12, 24];

  Widget _placementRow(BuildContext context, String room, String label) {
    final prefs = NativeChat.prefs;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ChatGlobalsPlacement>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: ChatGlobalsPlacement.top, label: Text('On top')),
                ButtonSegment(value: ChatGlobalsPlacement.mixed, label: Text('By activity')),
                ButtonSegment(value: ChatGlobalsPlacement.tab, label: Text('Social tab')),
              ],
              selected: {prefs.placementOf(room)},
              onSelectionChanged: (v) => prefs.setRoomPlacement(room, v.first),
            ),
          ),
        ],
      ),
    );
  }

  String _state(String id) {
    final prefs = NativeChat.prefs;
    final until = prefs.frozenUntilOf(id);
    final state = switch (prefs.roomState(id)) {
      ChatRoomState.live => 'Live',
      ChatRoomState.frozen => until == null ? 'Frozen' : 'Frozen until ${chatMuteUntilText(until)}',
      ChatRoomState.hidden => 'Hidden',
    };
    final listed = ChatRooms.whenListed(id);
    return listed == null ? state : '$state - $listed';
  }

  @override
  Widget build(BuildContext context) {
    return ChatSettingsSubpage(
      title: 'Rooms',
      builder: (context) {
        final prefs = NativeChat.prefs;
        final chat = NativeChat.controller;
        final listed = [
          for (final r in chat.rooms)
            if (!r.isDm) r.id,
        ];
        final rooms = [...listed, ...ChatRooms.occasional.where((id) => !listed.contains(id))];
        return [
          const ChatSettingsHeading(
            'Where rooms go',
            description:
                'On top: first, above pinned chats. By activity: mixed with the rest. Social tab: a tab of their own',
          ),
          _placementRow(context, 'global', 'Rooms like Global and Trade'),
          for (final room in ChatPrefs.placedRooms) _placementRow(context, room, ChatRooms.labelOf(room)),
          const SizedBox(height: 8),
          const ChatSettingsHeading(
            'Each room',
            description:
                'Live rooms update in real time. Frozen ones save battery: no messages or alerts until unfrozen. '
                'Hidden ones leave the list and the counts. Rooms you have left in Torn are not listed',
          ),
          for (final id in rooms)
            ChatSettingsLink(
              leading: ChatRoomGlyph.of(chat.roomById(id)),
              title: ChatRooms.isKnown(id) ? ChatRooms.labelOf(id) : chat.roomById(id).name,
              subtitle: _state(id),
              onTap: () {
                final room = chat.roomById(id);
                showChatRoomAlerts(
                  context,
                  ChatRooms.isKnown(id) ? ChatRoom(id: id, name: ChatRooms.labelOf(id), type: room.type) : room,
                );
              },
            ),
          const SizedBox(height: 8),
          const ChatSettingsHeading('Unread', description: 'What adds to the unread counts'),
          SwitchListTile(
            title: const Text('Muted chats count as unread'),
            value: prefs.mutedUnread,
            onChanged: prefs.setMutedUnread,
          ),
          ListTile(
            title: const Text('Waiting for you'),
            subtitle: const Text('Private chats left unanswered, shown at the top of the list'),
            trailing: DropdownButton<int>(
              value: _waitingChoices.contains(prefs.waitingHours) ? prefs.waitingHours : 3,
              underline: const SizedBox.shrink(),
              items: [
                for (final h in _waitingChoices)
                  DropdownMenuItem(value: h, child: Text(h == 0 ? 'Off' : 'After ${h}h')),
              ],
              onChanged: (v) => prefs.setWaitingHours(v ?? 3),
            ),
          ),
          const ChatSettingsHeading('Unread counts shown'),
          for (final room in ChatPrefs.bubbleOptions)
            CheckboxListTile(
              secondary: room == 'dm' ? Icon(chatRoomIcon(room)) : ChatRoomGlyph.of(chat.roomById(room)),
              title: Text(ChatRooms.labelOf(room)),
              subtitle: ChatPrefs.globalRooms.contains(room) ? const Text('Torn never marks it as read') : null,
              value: prefs.bubbleRooms.contains(room),
              onChanged: (v) => prefs.setBubbleRoom(room, v ?? false),
            ),
          SwitchListTile(
            title: const Text('Show a single total'),
            subtitle: const Text('Instead of one number per chat'),
            value: prefs.bubbleTotal,
            onChanged: prefs.setBubbleTotal,
          ),
        ];
      },
    );
  }
}
