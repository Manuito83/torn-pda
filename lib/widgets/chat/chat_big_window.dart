import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/pages/chat/chat_conversation_page.dart';
import 'package:torn_pda/pages/chat/chat_page.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';
import 'package:torn_pda/widgets/chat/chat_inbox_view.dart';
import 'package:torn_pda/widgets/chat/chat_quick_window.dart';
import 'package:torn_pda/widgets/chat/chat_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

class ChatBigWindowView extends StatefulWidget {
  const ChatBigWindowView({
    super.key,
    required this.chat,
    required this.roomId,
    required this.fullscreen,
    required this.onClose,
    this.onMinimize,
    this.onFullscreen,
    this.onDrag,
    this.onDragEnd,
    this.onResize,
    this.onResizeEnd,
  });

  final ChatController chat;

  /// Null shows the list
  final String? roomId;
  final bool fullscreen;
  final VoidCallback onClose;
  final VoidCallback? onMinimize;
  final VoidCallback? onFullscreen;
  final ValueChanged<Offset>? onDrag;
  final ValueChanged<Velocity>? onDragEnd;
  final ValueChanged<Offset>? onResize;
  final VoidCallback? onResizeEnd;

  @override
  State<ChatBigWindowView> createState() => _ChatBigWindowViewState();
}

class _ChatBigWindowViewState extends State<ChatBigWindowView> {
  @override
  void initState() {
    super.initState();
    if (widget.roomId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.chat.attach();
      });
    }
  }

  @override
  void didUpdateWidget(ChatBigWindowView old) {
    super.didUpdateWidget(old);
    if (old.roomId == widget.roomId) return;
    _release(old.roomId);
    if (widget.roomId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.chat.attach();
      });
    } else if (old.roomId == null) {
      widget.chat.detach();
    }
  }

  @override
  void dispose() {
    _release(widget.roomId);
    if (widget.roomId == null) widget.chat.detach();
    super.dispose();
  }

  // A small window may hold the room
  void _release(String? roomId) {
    if (roomId == null) return;
    final chat = widget.chat;
    Future.microtask(() {
      if (!NativeChat.quickWindows.value.contains(roomId)) chat.closeConversation(roomId);
    });
  }

  void _pick(ChatUser user) {
    widget.chat.addDraftDm(user);
    NativeChat.setBigWindowRoom(ChatRoom.dmId(user.id));
  }

  List<PopupMenuItem<VoidCallback>> _moreItems() {
    final chat = widget.chat;
    if (widget.roomId != null || !chat.available) return const [];
    return [
      PopupMenuItem(value: () => ChatInboxButtons.pickFriend(context, chat, _pick), child: const Text('Friends')),
      if (chat.ready)
        PopupMenuItem(
          value: () => ChatInboxButtons.pickNewChat(context, chat, _pick),
          child: const Text('New private chat'),
        ),
    ];
  }

  Widget _listFrame(BuildContext context, PreferredSizeWidget? tabBar, Widget body) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      children: [
        if (tabBar != null)
          Theme(
            data: theme.copyWith(
              tabBarTheme: theme.tabBarTheme.copyWith(
                labelColor: scheme.onSurface,
                unselectedLabelColor: scheme.onSurfaceVariant,
                indicatorColor: theme.tabBarTheme.indicatorColor ?? scheme.primary,
              ),
            ),
            child: tabBar,
          ),
        Expanded(child: body),
      ],
    );
  }

  Widget _header(BuildContext context) {
    final style = Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700);
    return ListenableBuilder(
      listenable: widget.chat,
      builder: (context, _) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Chat', style: style),
                DefaultTextStyle.merge(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  child: ChatConnectionLine(state: widget.chat.connection),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roomId = widget.roomId;
    return ChatWindowBox(
      header: _header(context),
      onClose: widget.onClose,
      onMinimize: widget.onMinimize,
      onFullscreen: widget.onFullscreen,
      fullscreen: widget.fullscreen,
      onExpand: NativeChat.expandBigWindow,
      moreItems: _moreItems,
      onDrag: widget.onDrag,
      onDragEnd: widget.onDragEnd,
      onResize: widget.onResize,
      onResizeEnd: widget.onResizeEnd,
      child: ChangeNotifierProvider<ChatController>.value(
        value: widget.chat,
        child: roomId == null
            ? ChatInboxView(
                chat: widget.chat,
                onOpen: NativeChat.setBigWindowRoom,
                onSaved: () => NativeChat.expandBigWindow(saved: true),
                frame: _listFrame,
              )
            : ChatConversationPage(
                key: ValueKey(roomId),
                roomId: roomId,
                embedded: true,
                onBack: () => NativeChat.setBigWindowRoom(null),
                onOpenRoom: NativeChat.setBigWindowRoom,
                onGone: () => NativeChat.setBigWindowRoom(null),
                onPopOut: NativeChat.popOutBigWindow,
              ),
      ),
    );
  }
}
