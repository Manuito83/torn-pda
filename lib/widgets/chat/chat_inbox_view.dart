import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_rooms.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/widgets/chat/chat_alerts_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_help.dart';
import 'package:torn_pda/widgets/chat/chat_intro_sheet.dart';
import 'package:torn_pda/widgets/chat/chat_link_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_list_reply.dart';
import 'package:torn_pda/widgets/chat/chat_slide_to_place.dart';
import 'package:torn_pda/widgets/chat/chat_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

typedef ChatInboxFrame = Widget Function(BuildContext context, PreferredSizeWidget? tabBar, Widget body);

class ChatInboxView extends StatefulWidget {
  const ChatInboxView({super.key, required this.chat, required this.onOpen, this.onSaved, required this.frame});

  final ChatController chat;
  final ValueChanged<String> onOpen;

  /// No Saved chip when null
  final VoidCallback? onSaved;

  final ChatInboxFrame frame;

  @override
  State<ChatInboxView> createState() => ChatInboxViewState();
}

class ChatInboxViewState extends State<ChatInboxView> {
  static bool _unreadOnly = false;

  final Set<String> _replying = {};

  void closeReplies() {
    if (_replying.isNotEmpty) setState(_replying.clear);
  }

  void _open(String roomId) {
    closeReplies();
    widget.onOpen(roomId);
  }

  @override
  Widget build(BuildContext context) {
    final chat = widget.chat;
    return ListenableBuilder(
      listenable: Listenable.merge([chat, NativeChat.prefs]),
      builder: (context, _) {
        final prefs = NativeChat.prefs;
        final status = _statusMessage(chat);
        final visible = chat.conversations
            .where((r) => !prefs.hiddenRooms.contains(r.id) && !prefs.isArchived(r.id))
            .toList();
        List<ChatRoom> placed(ChatGlobalsPlacement where) => [
          for (final id in ChatPrefs.bubbleOptions)
            ...visible.where((r) => r.id == id && prefs.placementOf(id) == where),
        ];
        final top = placed(ChatGlobalsPlacement.top);
        final social = placed(ChatGlobalsPlacement.tab);
        final tabs = status == null && prefs.usesSocialTab;
        final main = [...top, ..._pinnedFirst(visible.where((r) => !top.contains(r) && !social.contains(r)))];
        final body = Column(
          children: [
            ChatStartingBar(starting: chat.starting, phrases: false),
            Expanded(
              child:
                  status ??
                  (tabs
                      ? TabBarView(
                          children: [
                            _list(chat, main),
                            social.isEmpty
                                ? const ChatStateMessage(
                                    icon: Icons.visibility_off_rounded,
                                    title: 'Social rooms are hidden',
                                    subtitle: 'Chat settings can show them again',
                                  )
                                : _list(chat, _pinnedFirst(social), social: true),
                          ],
                        )
                      : _list(chat, main)),
            ),
          ],
        );
        final framed = widget.frame(context, tabs ? _tabBar(chat, main, social) : null, body);
        return ChatPausedGate(child: tabs ? DefaultTabController(length: 2, child: framed) : framed);
      },
    );
  }

  Future<void> _showActions(ChatRoom room) async {
    final prefs = NativeChat.prefs;
    final pinned = prefs.isPinned(room.id);
    final peer = room.isDm ? ChatRoom.peerIdOf(room.id) : null;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: ChatRoomAvatar(room: room, size: 40),
                title: Text(peer == null ? room.name : prefs.displayName(peer, room.name)),
                trailing: peer == null
                    ? null
                    : const Icon(Icons.chevron_right_rounded, semanticLabel: 'Player details'),
                onTap: peer == null ? null : () => Navigator.pop(context, 'player'),
              ),
              if (widget.chat.canMarkRead(room.id))
                ListTile(
                  leading: const Icon(Icons.done_all_rounded),
                  title: const Text('Mark as read'),
                  onTap: () => Navigator.pop(context, 'read'),
                ),
              if (widget.chat.canMarkUnread(room.id))
                ListTile(
                  leading: const Icon(Icons.mark_chat_unread_outlined),
                  title: const Text('Mark as unread'),
                  onTap: () => Navigator.pop(context, 'unread'),
                ),
              ListTile(
                leading: Icon(
                  prefs.mutedUntilOf(room.id) != null
                      ? Icons.snooze_rounded
                      : (prefs.isMuted(room.id) ? Icons.notifications_off_rounded : Icons.notifications_active_rounded),
                ),
                title: const Text('Alerts and mute'),
                subtitle: switch (prefs.mutedUntilOf(room.id)) {
                  final until? => Text('Muted until ${NativeChat.prefs.stamp(until)}'),
                  null => null,
                },
                onTap: () => Navigator.pop(context, 'alerts'),
              ),
              ListTile(
                leading: Icon(pinned ? Icons.push_pin_outlined : Icons.push_pin_rounded),
                title: Text(pinned ? 'Unpin' : 'Pin to the top'),
                onTap: () => Navigator.pop(context, 'pin'),
              ),
              if (room.isDm)
                ListTile(
                  leading: const Icon(Icons.archive_outlined),
                  title: const Text('Archive'),
                  subtitle: const Text('Out of the list until they write again. Torn keeps the chat'),
                  onTap: () => Navigator.pop(context, 'archive'),
                ),
              if (room.isDm && widget.chat.isDmOpen(room.id))
                ListTile(
                  leading: const Icon(Icons.close_rounded),
                  title: const Text('Close chat'),
                  subtitle: const Text('Closes its panel in Torn. It stays in your recent chats'),
                  onTap: () => Navigator.pop(context, 'close'),
                ),
              if (!room.isDm)
                ListTile(
                  leading: const Icon(Icons.visibility_off_rounded),
                  title: const Text('Hide this room'),
                  subtitle: const Text('Only in Torn PDA, chat settings bring it back'),
                  onTap: () => Navigator.pop(context, 'hide'),
                ),
            ],
          ),
        ),
      ),
    );
    switch (action) {
      case 'player':
        if (mounted && peer != null) showChatPlayerActions(context, room.peer ?? ChatUser(id: peer, name: room.name));
      case 'read':
        _done(() => widget.chat.markRead(room.id));
      case 'unread':
        _done(() => widget.chat.markUnread(room.id));
      case 'alerts':
        if (mounted) showChatRoomAlerts(context, room);
      case 'pin':
        _done(() => prefs.setPinned(room.id, !pinned));
      case 'archive':
        _done(() => prefs.setArchived(room.id, true));
      case 'close':
        if (pinned) prefs.setPinned(room.id, false);
        widget.chat.closeDm(room.id);
      case 'hide':
        prefs.setRoomState(room.id, ChatRoomState.hidden);
    }
  }

  void _done(VoidCallback action) {
    HapticFeedback.lightImpact();
    action();
  }

  Widget _tile(ChatController chat, ChatRoom room) {
    final prefs = NativeChat.prefs;
    final pinned = prefs.isPinned(room.id);
    final muted = prefs.isMuted(room.id);
    final (shown, more) = chat.unreadShown(room.id);
    final unread = shown > 0 ? shown : chat.listUnreadFor(room.id);
    final dot = unread == 0 && !chat.tornMarksRead(room.id) && chat.newSinceVisit(room.id);
    final readable = widget.chat.canMarkRead(room.id);
    final unreadable = widget.chat.canMarkUnread(room.id);
    final replying = prefs.listReply && _replying.contains(room.id);
    final unreadCount = chat.unreadFor(room.id);
    SlidableAction action(IconData icon, String label, Color background, VoidCallback onPressed) => SlidableAction(
      onPressed: (_) => _done(onPressed),
      icon: icon,
      label: label,
      backgroundColor: background,
      foregroundColor: Colors.white,
    );
    final slidable = Slidable(
      key: ValueKey(room.id),
      groupTag: 'chats',
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: readable || unreadable ? 0.44 : 0.22,
        children: [
          if (readable)
            action(Icons.done_all_rounded, 'Read', Colors.lightBlue.shade700, () => widget.chat.markRead(room.id)),
          if (unreadable)
            action(
              Icons.mark_chat_unread_outlined,
              'Unread',
              Colors.lightBlue.shade700,
              () => widget.chat.markUnread(room.id),
            ),
          action(
            pinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
            pinned ? 'Unpin' : 'Pin',
            Colors.blueGrey.shade500,
            () => prefs.setPinned(room.id, !pinned),
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: room.isDm ? 0.44 : 0.22,
        children: [
          if (room.isDm)
            action(Icons.archive_outlined, 'Archive', Colors.teal.shade600, () => prefs.setArchived(room.id, true)),
          action(
            muted ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
            muted ? 'Unmute' : 'Mute',
            Colors.deepOrange.shade400,
            () => prefs.setMuted(room.id, !muted),
          ),
        ],
      ),
      child: ChatConversationTile(
        room: room,
        last: chat.lastMessageIn(room.id),
        unread: dot ? unreadCount : unread,
        more: more,
        dot: dot,
        myUserId: chat.myUserId,
        pinned: pinned,
        muted: muted,
        snoozed: prefs.mutedUntilOf(room.id) != null,
        frozen: prefs.isFrozen(room.id),
        mentioned: chat.hasUnseenAlert(room.id),
        draft: prefs.draftFor(room.id),
        awayLine: unreadCount > 0 ? chat.awayFor(room.id)?.inboxLine(unreadCount) : null,
        typing: chat.typingIn(room.id),
        hidePreview: replying,
        onTap: () => _open(room.id),
        onLongPress: () => _showActions(room),
        expanded: replying,
        onExpand: prefs.listReply
            ? () => setState(() => replying ? _replying.remove(room.id) : _replying.add(room.id))
            : null,
        actions: {
          if (readable)
            const CustomSemanticsAction(label: 'Mark as read'): () => _done(() => widget.chat.markRead(room.id)),
          if (unreadable)
            const CustomSemanticsAction(label: 'Mark as unread'): () => _done(() => widget.chat.markUnread(room.id)),
          CustomSemanticsAction(label: pinned ? 'Unpin' : 'Pin'): () => _done(() => prefs.setPinned(room.id, !pinned)),
          CustomSemanticsAction(label: muted ? 'Unmute' : 'Mute'): () => _done(() => prefs.setMuted(room.id, !muted)),
          if (room.isDm)
            const CustomSemanticsAction(label: 'Archive'): () => _done(() => prefs.setArchived(room.id, true)),
        },
      ),
    );
    if (!prefs.listReply) return slidable;
    return AnimatedContainer(
      key: ValueKey(room.id),
      duration: chatMotion(context, const Duration(milliseconds: 200)),
      color: replying ? Theme.of(context).colorScheme.surfaceContainerLow : Colors.transparent,
      child: Column(
        children: [
          slidable,
          AnimatedSize(
            duration: chatMotion(context, const Duration(milliseconds: 200)),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: replying
                ? ChatListReply(key: ValueKey(room.id), room: room)
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Future<void> _markAllRead() async {
    final count = widget.chat.readable.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark all as read'),
        content: Text(
          '${count == 1 ? 'One conversation has' : '$count conversations have'} unread messages. '
          'Rooms like Global and Trade, hidden rooms and archived chats stay as they are',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Mark as read')),
        ],
      ),
    );
    if (confirmed == true) widget.chat.markAllRead();
  }

  List<ChatRoom> _pinnedFirst(Iterable<ChatRoom> rooms) {
    final pinned = NativeChat.prefs.pinned;
    return [for (final id in pinned) ...rooms.where((r) => r.id == id), ...rooms.where((r) => !pinned.contains(r.id))];
  }

  TabBar _tabBar(ChatController chat, List<ChatRoom> main, List<ChatRoom> social) {
    final theme = Theme.of(context);
    Widget chip(String text, String spoken, Color background, Color foreground, [IconData? icon]) => Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, size: 12, color: foreground),
          Text(
            text,
            semanticsLabel: spoken,
            style: theme.textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
    String count(int n, [bool more = false]) => n > 99 ? '99+' : '$n${more ? '+' : ''}';
    final mainUnread = main.fold(0, (sum, r) => sum + (chat.countsInBadge(r.id) ? chat.unreadFor(r.id) : 0));
    return TabBar(
      tabs: [
        Tab(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Chats'),
                if (mainUnread > 0)
                  chip(
                    count(mainUnread),
                    '$mainUnread unread',
                    chatGroupColors('dm', theme.brightness).$1,
                    chatGroupColors('dm', theme.brightness).$2,
                  ),
              ],
            ),
          ),
        ),
        Tab(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Social'),
                for (final room in social)
                  if (chat.countsUnread(room.id))
                    if (chat.unreadShown(room.id) case (final unread, final more) when unread > 0)
                      Builder(
                        builder: (context) {
                          final (background, foreground) = chatGroupColors(room.id, theme.brightness);
                          return chip(
                            count(unread, more),
                            '${room.name} ${count(unread, more)} unread',
                            background,
                            foreground,
                            chatRoomIcon(room.id, room.icon),
                          );
                        },
                      ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget? _statusMessage(ChatController chat) {
    if (!chat.available && !chat.loggedOut) {
      return ChatStateMessage(
        icon: Icons.portable_wifi_off_rounded,
        title: 'In-app chat is off',
        subtitle: 'Turn it on to read Torn chat here',
        action: FilledButton.tonal(
          onPressed: () {
            setState(() => NativeChat.setEnabled(true));
            showChatIntro(context);
          },
          child: const Text('Turn on'),
        ),
      );
    }
    if (chat.sessionIssue) return ChatSessionMessage(state: chat.connection);
    if (chat.unreachable && (chat.connection == ChatConnection.error || chat.conversations.isEmpty)) {
      return ChatStateMessage(
        icon: Icons.cloud_off_rounded,
        title: 'Could not reach the chat',
        action: FilledButton.tonal(onPressed: chat.retry, child: const Text('Try again')),
      );
    }
    return null;
  }

  Widget _filterRow(int unread, bool canMarkAll) {
    final chips = Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        FilterChip(
          avatar: _unreadOnly ? null : const Icon(Icons.mark_chat_unread_outlined, size: 18),
          label: Text(unread > 0 ? 'Unread $unread' : 'Unread'),
          selected: _unreadOnly,
          onSelected: (value) => setState(() {
            _replying.clear();
            _unreadOnly = value;
          }),
        ),
        if (widget.onSaved != null && NativeChat.prefs.savedMessages.isNotEmpty)
          ActionChip(
            avatar: const Icon(Icons.bookmark_border_rounded, size: 18),
            label: Text('Saved ${NativeChat.prefs.savedMessages.length}'),
            onPressed: widget.onSaved,
          ),
      ],
    );
    final markAll = TextButton(onPressed: _markAllRead, child: const Text('Mark all as read'));
    final stacked = chatLargeText(MediaQuery.textScalerOf(context));
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                chips,
                if (canMarkAll) Align(alignment: Alignment.centerRight, child: markAll),
              ],
            )
          : Row(
              children: [
                Expanded(child: chips),
                if (canMarkAll) markAll,
              ],
            ),
    );
  }

  Widget _list(ChatController chat, List<ChatRoom> all, {bool social = false}) {
    final unread = all.where((r) => chat.unreadFor(r.id) > 0 && chat.countsUnread(r.id)).toList();
    // Open quick reply keeps its room
    final conversations = _unreadOnly ? all.where((r) => unread.contains(r) || _replying.contains(r.id)).toList() : all;
    final loading = !_unreadOnly && !social && (!chat.dmsLoaded || chat.loadingRecent);
    final empty = conversations.isEmpty && !loading;
    final more = !_unreadOnly && !social && !loading && chat.recentHasMore;
    final archived = social || _unreadOnly ? const <ChatRoom>[] : chat.archivedDms;
    final hidden = social || _unreadOnly ? const <ChatRoom>[] : chat.hiddenRooms;
    final tail = [
      if (archived.isNotEmpty)
        ListTile(
          leading: const Icon(Icons.archive_outlined),
          title: Text('Archived (${archived.length})'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => showChatArchived(context, _open),
        ),
      if (hidden.isNotEmpty)
        ListTile(
          leading: const Icon(Icons.visibility_off_outlined),
          title: Text('Hidden rooms (${hidden.length})'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => showChatHiddenRooms(context),
        ),
    ];
    final list = ListView.builder(
      key: PageStorageKey(social),
      padding: const EdgeInsets.only(bottom: 150),
      itemCount: 1 + conversations.length + (loading || more || empty ? 1 : 0) + tail.length,
      findChildIndexCallback: (key) {
        final index = conversations.indexWhere((r) => ValueKey(r.id) == key);
        return index < 0 ? null : 1 + index;
      },
      itemBuilder: (context, row) {
        final end = 1 + conversations.length + (loading || more || empty ? 1 : 0);
        if (row >= end) return tail[row - end];
        if (row == 0) {
          return Column(
            children: [
              _filterRow(unread.length, chat.ready && chat.readable.isNotEmpty),
              if (!social && !_unreadOnly)
                ChatWaitingStrip(
                  waiting: chat.waitingDms(),
                  onOpen: _open,
                  onDismiss: chat.dismissWaiting,
                  onDismissAll: chat.dismissWaiting,
                ),
            ],
          );
        }
        final index = row - 1;
        if (empty) {
          return Padding(
            padding: const EdgeInsets.only(top: 56),
            child: _unreadOnly
                ? const ChatStateMessage(
                    icon: Icons.mark_chat_read_outlined,
                    title: 'All caught up',
                    subtitle: 'No unread chats here',
                  )
                : const ChatStateMessage(
                    icon: Icons.forum_outlined,
                    title: 'No chats yet',
                    subtitle: 'Your faction, company and private chats will show up here',
                  ),
          );
        }
        if (index == conversations.length && more) {
          return Center(
            child: TextButton.icon(
              onPressed: chat.loadMoreRecent,
              icon: const Icon(Icons.expand_more_rounded),
              label: const Text('Older private chats'),
            ),
          );
        }
        if (conversations.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 56),
            child: ChatStateMessage(
              icon: Icons.forum_outlined,
              busy: true,
              title: 'Loading your chats',
              subtitle: chat.ready ? null : 'Connecting to Torn',
            ),
          );
        }
        if (index == conversations.length) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5)),
                ChatLoadingPhrase(active: chat.starting, centered: true),
              ],
            ),
          );
        }
        return ChatSlideToPlace(
          key: ValueKey(conversations[index].id),
          index: index,
          child: _tile(chat, conversations[index]),
        );
      },
    );
    return SlidableAutoCloseBehavior(child: list);
  }
}
