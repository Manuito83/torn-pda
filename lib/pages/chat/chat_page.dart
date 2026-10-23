import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/pages/chat/chat_conversation_page.dart';
import 'package:torn_pda/pages/chat/chat_search_page.dart';
import 'package:torn_pda/pages/chat/chat_settings_page.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';
import 'package:torn_pda/torn-pda-native/stats/stats_controller.dart';
import 'package:torn_pda/widgets/chat/chat_alerts_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_friends_sheet.dart';
import 'package:torn_pda/widgets/chat/chat_intro_sheet.dart';
import 'package:torn_pda/widgets/chat/chat_link_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_theme.dart';
import 'package:torn_pda/widgets/chat/chat_inbox_view.dart';
import 'package:torn_pda/widgets/chat/chat_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, this.initialRoomId, this.initialMessageId, this.openSaved = false});

  final String? initialRoomId;
  final String? initialMessageId;
  final bool openSaved;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final ChatController _chat;
  final GlobalKey<ChatInboxViewState> _inbox = GlobalKey();

  @override
  void initState() {
    super.initState();
    _chat = context.read<ChatController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chat.attach();
      if (widget.initialRoomId != null) _open(widget.initialRoomId!, messageId: widget.initialMessageId);
      if (widget.openSaved) _openSearch(saved: true);
      if (_chat.available) showChatIntro(context);
    });
  }

  @override
  void dispose() {
    if (NativeChat.bigWindowShown && NativeChat.bigWindow.value?.roomId == null) return super.dispose();
    _chat.detach();
    super.dispose();
  }

  Future<void> _open(String roomId, {ChatUser? newPeer, String? messageId, DateTime? at}) async {
    _inbox.currentState?.closeReplies();
    if (newPeer != null) _chat.addDraftDm(newPeer);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<ChatController>.value(
          value: _chat,
          child: ChatTheme(
            child: ChatConversationPage(roomId: roomId, focusMessageId: messageId, focusAt: at),
          ),
        ),
      ),
    );
    _chat.closeConversation(roomId);
  }

  void _openSearch({bool saved = false}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<ChatController>.value(
          value: _chat,
          child: ChatTheme(
            child: ChatPausedGate(
              child: ChatSearchPage(
                saved: saved,
                onOpen: (roomId, {messageId, at}) => _open(roomId, messageId: messageId, at: at),
                onPlayer: (user) => _open(ChatRoom.dmId(user.id), newPeer: user),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChatInboxView(
      key: _inbox,
      chat: _chat,
      onOpen: _open,
      onSaved: () => _openSearch(saved: true),
      frame: _frame,
    );
  }

  Widget _frame(BuildContext context, PreferredSizeWidget? tabBar, Widget body) {
    final chat = _chat;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: (MediaQuery.textScalerOf(context).scale(40) + 16)
            .clamp(kToolbarHeight, double.infinity)
            .toDouble(),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chat'),
            ChatConnectionLine(state: chat.connection),
          ],
        ),
        actions: [
          if (chat.available)
            IconButton(tooltip: 'Search', icon: const Icon(Icons.search_rounded), onPressed: _openSearch),
          ChatAlertsButton(onOpen: _open),
          if (NativeChat.prefs.inAppEnabled)
            const IconButton(
              tooltip: 'Open in a window',
              icon: Icon(Icons.picture_in_picture_alt_rounded),
              onPressed: NativeChat.openBigWindow,
            ),
          IconButton(
            tooltip: 'Chat settings',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => showChatSettings(Navigator.of(context)),
          ),
        ],
        bottom: tabBar,
      ),
      floatingActionButton: ChatInboxButtons(
        chat: chat,
        onPick: (user) => _open(ChatRoom.dmId(user.id), newPeer: user),
      ),
      body: body,
    );
  }
}

class ChatInboxButtons extends StatelessWidget {
  const ChatInboxButtons({super.key, required this.chat, required this.onPick});

  final ChatController chat;
  final ValueChanged<ChatUser> onPick;

  static Future<void> _pick(
    BuildContext context,
    ChatController chat,
    Widget sheet,
    ValueChanged<ChatUser> onPick,
  ) async {
    final user = await showModalBottomSheet<ChatUser>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => ChangeNotifierProvider<ChatController>.value(value: chat, child: sheet),
    );
    if (user != null && context.mounted) onPick(user);
  }

  static Future<void> pickFriend(BuildContext context, ChatController chat, ValueChanged<ChatUser> onPick) {
    StatsController.chat.count('friends');
    return _pick(context, chat, const ChatFriendsSheet(), onPick);
  }

  static Future<void> pickNewChat(BuildContext context, ChatController chat, ValueChanged<ChatUser> onPick) =>
      _pick(context, chat, const _NewChatSheet(), onPick);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: chat,
      builder: (context, _) => !chat.available
          ? const SizedBox.shrink()
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.small(
                  heroTag: null,
                  tooltip: 'Friends',
                  onPressed: () => pickFriend(context, chat, onPick),
                  child: const Icon(Icons.people_alt_rounded),
                ),
                if (chat.ready) ...[
                  const SizedBox(height: 12),
                  FloatingActionButton(
                    heroTag: null,
                    tooltip: 'New private chat',
                    onPressed: () => pickNewChat(context, chat, onPick),
                    child: const Icon(Icons.add_comment_rounded),
                  ),
                ],
              ],
            ),
    );
  }
}

class _NewChatSheet extends StatefulWidget {
  const _NewChatSheet();

  @override
  State<_NewChatSheet> createState() => _NewChatSheetState();
}

class _NewChatSheetState extends State<_NewChatSheet> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(ChatController chat, String text) {
    _debounce?.cancel();
    if (text.trim().length < 2) {
      chat.search('');
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => chat.search(text));
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatController>();
    final results = chat.searchResults;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.6,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: (text) => _onChanged(chat, text),
                onSubmitted: chat.search,
                decoration: InputDecoration(
                  hintText: 'Search a player by name',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                ),
              ),
            ),
            Expanded(
              child: chat.searching
                  ? const Center(child: CircularProgressIndicator())
                  : results == null
                  ? const ChatStateMessage(
                      icon: Icons.person_add_alt_rounded,
                      title: 'Start a private chat',
                      subtitle: 'Type at least two letters of a name',
                    )
                  : results.isEmpty
                  ? const ChatStateMessage(
                      icon: Icons.person_search_rounded,
                      title: 'No players found',
                      subtitle: 'Check the spelling or try fewer letters',
                    )
                  : ListView(
                      children: [
                        for (final user in results)
                          ListTile(
                            leading: ChatAvatar(user: user, size: 40),
                            title: Text(user.name),
                            subtitle: Text('[${user.id}]'),
                            trailing: IconButton(
                              tooltip: 'Player details',
                              icon: const Icon(Icons.more_vert_rounded),
                              onPressed: () => showChatPlayerActions(context, user),
                            ),
                            onTap: () => Navigator.pop(context, user),
                            onLongPress: () => showChatPlayerActions(context, user),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
