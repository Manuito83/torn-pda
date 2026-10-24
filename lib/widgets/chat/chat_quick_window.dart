import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:torn_pda/models/chat/chat_faction_events.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_quote.dart';
import 'package:torn_pda/providers/chat/chat_api.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/widgets/chat/chat_color_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_link_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

enum ChatWindowSize {
  s(Size(260, 300)),
  m(Size(340, 440)),
  l(Size(420, 640));

  const ChatWindowSize(this.size);

  final Size size;

  String get label => name.toUpperCase();

  ChatWindowSize get next => values[(index + 1) % values.length];
}

class ChatWindowFrame {
  ChatWindowFrame._();

  static const Size minSize = Size(220, 200);
  static const Size bigWindowMinSize = Size(280, 360);
  static const double keyboardMinHeight = 250;

  /// [area] on [side] of the divider
  static Rect panel(Rect area, Rect? divider, SplitSide? side) => switch ((divider, side)) {
    (final d?, SplitSide.left) => Rect.fromLTRB(area.left, area.top, math.max(area.left, d.left), area.bottom),
    (final d?, SplitSide.right) => Rect.fromLTRB(math.min(d.right, area.right), area.top, area.right, area.bottom),
    _ => area,
  };

  static Rect fit(Rect frame, Rect area, {Size min = minSize}) {
    final width = frame.width.clamp(math.min(min.width, area.width), area.width).toDouble();
    final height = frame.height.clamp(math.min(min.height, area.height), area.height).toDouble();
    return Rect.fromLTWH(
      frame.left.clamp(area.left, area.right - width).toDouble(),
      frame.top.clamp(area.top, area.bottom - height).toDouble(),
      width,
      height,
    );
  }

  /// Shrinks over a keyboard, then rises
  static Rect aboveKeyboard(Rect frame, Rect area) {
    if (frame.bottom <= area.bottom) return frame;
    final height = math.min(area.height, math.max(keyboardMinHeight, area.bottom - frame.top));
    return Rect.fromLTWH(frame.left, area.bottom - height, frame.width, height);
  }

  /// Like [fit] but free to leave sideways
  static Rect loose(Rect frame, Rect area, {Size min = minSize}) {
    final fitted = fit(frame, area, min: min);
    final left = frame.left.clamp(area.left - fitted.width, area.right).toDouble();
    return Rect.fromLTWH(left, fitted.top, fitted.width, fitted.height);
  }

  /// Share of the width out of [area]
  static double outside(Rect frame, Rect area) {
    final out = math.max(0.0, area.left - frame.left) + math.max(0.0, frame.right - area.right);
    return frame.width <= 0 ? 0 : out / frame.width;
  }

  static String encode(String roomId, Rect frame, ChatWindowSize? preset) => [
    roomId,
    for (final v in [frame.left, frame.top, frame.width, frame.height]) v.toStringAsFixed(1),
    preset?.name ?? '',
  ].join('|');

  static ({String roomId, Rect? frame, ChatWindowSize? preset}) decode(String entry) {
    final parts = entry.split('|');
    if (parts.length < 6) return (roomId: entry, frame: null, preset: null);
    final roomId = parts.sublist(0, parts.length - 5).join('|');
    final v = parts.sublist(parts.length - 5, parts.length - 1).map(double.tryParse).toList();
    if (v.contains(null)) return (roomId: roomId, frame: null, preset: null);
    return (
      roomId: roomId,
      frame: Rect.fromLTWH(v[0]!, v[1]!, v[2]!, v[3]!),
      preset: ChatWindowSize.values.asNameMap()[parts.last],
    );
  }
}

class ChatWindowBox extends StatelessWidget {
  const ChatWindowBox({
    super.key,
    required this.header,
    required this.child,
    required this.onClose,
    this.onExpand,
    this.onNext,
    this.nextCount = 0,
    this.onMinimize,
    this.onFullscreen,
    this.fullscreen = false,
    this.onDrag,
    this.onDragEnd,
    this.onResize,
    this.onResizeEnd,
    this.sizeLabel,
    this.onCycleSize,
    this.moreItems,
  });

  final Widget header;
  final Widget child;
  final VoidCallback onClose;
  final VoidCallback? onExpand;
  final VoidCallback? onNext;
  final int nextCount;
  final VoidCallback? onMinimize;
  final VoidCallback? onFullscreen;
  final bool fullscreen;
  final ValueChanged<Offset>? onDrag;
  final ValueChanged<Velocity>? onDragEnd;
  final ValueChanged<Offset>? onResize;
  final VoidCallback? onResizeEnd;

  /// Null for a custom size
  final String? sizeLabel;
  final VoidCallback? onCycleSize;

  /// Menu entries before the rest
  final List<PopupMenuItem<VoidCallback>> Function()? moreItems;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: true,
      removeLeft: true,
      removeRight: true,
      child: Stack(
        children: [
          Positioned.fill(child: _window(context, scheme)),
          if (onResize != null) Positioned(right: 0, bottom: 0, child: _grip(scheme)),
        ],
      ),
    );
  }

  Widget _headerButton(String tooltip, Widget icon, VoidCallback? onPressed) {
    return IconButton(
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 48, height: 48),
      iconSize: 20,
      icon: icon,
      onPressed: onPressed,
    );
  }

  Widget _grip(ColorScheme scheme) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (d) => onResize!(d.delta),
      onPanEnd: (_) => onResizeEnd?.call(),
      child: SizedBox(width: 26, height: 26, child: CustomPaint(painter: _GripPainter(scheme.onSurfaceVariant))),
    );
  }

  Widget _window(BuildContext context, ColorScheme scheme) {
    return Material(
      color: chatPalette(context).background,
      elevation: 10,
      shadowColor: Colors.black54,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: onDrag == null ? null : (d) => onDrag!(d.delta),
            onPanEnd: onDragEnd == null ? null : (d) => onDragEnd!(d.velocity),
            child: Container(
              color: scheme.surfaceContainer,
              padding: const EdgeInsets.fromLTRB(10, 2, 2, 2),
              child: Row(
                children: [
                  Expanded(child: header),
                  if (onMinimize != null) _headerButton('Minimize', const Icon(Icons.minimize_rounded), onMinimize),
                  if (onFullscreen != null)
                    _headerButton(
                      fullscreen ? 'Exit full screen' : 'Full screen',
                      Icon(fullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded),
                      onFullscreen,
                    ),
                  if (onCycleSize != null || onExpand != null || onNext != null || moreItems != null)
                    PopupMenuButton<VoidCallback>(
                      tooltip: 'More',
                      icon: const Icon(Icons.more_vert_rounded),
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      onSelected: (action) => action(),
                      itemBuilder: (_) => [
                        ...?moreItems?.call(),
                        if (onCycleSize != null)
                          PopupMenuItem(value: onCycleSize, child: Text('Window size: ${sizeLabel ?? 'custom'}')),
                        if (onNext != null && nextCount > 0)
                          PopupMenuItem(value: onNext, child: Text('Next unread ($nextCount)')),
                        if (onExpand != null) PopupMenuItem(value: onExpand, child: const Text('Open the full chat')),
                      ],
                    ),
                  _headerButton('Close', const Icon(Icons.close_rounded), onClose),
                ],
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class ChatQuickWindow extends StatefulWidget {
  const ChatQuickWindow({
    super.key,
    required this.chat,
    required this.roomId,
    required this.onClose,
    this.onExpand,
    this.onNext,
    this.onMinimize,
    this.onDrag,
    this.onDragEnd,
    this.onResize,
    this.onResizeEnd,
    this.sizeLabel,
    this.onCycleSize,
  });

  final ChatController chat;
  final String roomId;
  final VoidCallback onClose;
  final VoidCallback? onExpand;
  final VoidCallback? onNext;
  final VoidCallback? onMinimize;
  final ValueChanged<Offset>? onDrag;
  final ValueChanged<Velocity>? onDragEnd;
  final ValueChanged<Offset>? onResize;
  final VoidCallback? onResizeEnd;

  /// Null for a custom size
  final String? sizeLabel;
  final VoidCallback? onCycleSize;

  @override
  State<ChatQuickWindow> createState() => _ChatQuickWindowState();
}

class _ChatQuickWindowState extends State<ChatQuickWindow> {
  static const int _shown = 60;
  ChatMessage? _replyTo;
  final ValueNotifier<int> _focusPing = ValueNotifier(0);
  late final bool _autofocus = NativeChat.takeComposerFocus(widget.roomId);

  @override
  void initState() {
    super.initState();
    NativeChat.composerFocus.addListener(_onFocusAsked);
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.chat.openConversation(widget.roomId));
  }

  void _onFocusAsked() {
    if (NativeChat.takeComposerFocus(widget.roomId)) _focusPing.value++;
  }

  @override
  void didUpdateWidget(ChatQuickWindow old) {
    super.didUpdateWidget(old);
    if (old.roomId == widget.roomId) return;
    _replyTo = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.chat
        ..closeConversation(old.roomId)
        ..openConversation(widget.roomId);
    });
  }

  @override
  void dispose() {
    NativeChat.composerFocus.removeListener(_onFocusAsked);
    _focusPing.dispose();
    final chat = widget.chat;
    final roomId = widget.roomId;
    scheduleMicrotask(() {
      if (!NativeChat.bigWindowHolds(roomId)) chat.closeConversation(roomId);
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.chat,
      builder: (context, _) => _window(widget.chat, widget.chat.roomById(widget.roomId)),
    );
  }

  Widget _window(ChatController chat, ChatRoom room) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ChatWindowBox(
      header: Row(
        children: [
          ChatRoomAvatar(room: room, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  room.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                DefaultTextStyle.merge(
                  style: TextStyle(color: scheme.onSurfaceVariant),
                  child: ChatConnectionLine(
                    state: chat.connection,
                    presence: chat.presenceOf(ChatRoom.peerIdOf(room.id)),
                    lastSeen: chat.lastSeenOf(ChatRoom.peerIdOf(room.id)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      onClose: widget.onClose,
      onExpand: widget.onExpand,
      onNext: widget.onNext,
      nextCount: chat.unreadQueue.length,
      onMinimize: widget.onMinimize,
      onDrag: widget.onDrag,
      onDragEnd: widget.onDragEnd,
      onResize: widget.onResize,
      onResizeEnd: widget.onResizeEnd,
      sizeLabel: widget.sizeLabel,
      onCycleSize: widget.onCycleSize,
      child: Column(
        children: [
          ChatStartingBar(starting: chat.starting, phrases: chat.isLoaded(room.id)),
          Expanded(
            child: ChatArrivals(chat: chat, roomId: room.id, child: _messages(chat, room)),
          ),
          ChatComposer(
            key: ValueKey(room.id),
            roomName: room.name,
            enabled: chat.available && room.canWrite,
            chat: chat,
            roomId: room.id,
            autofocus: _autofocus,
            focusSignal: _focusPing,
            onSend: (text) {
              final reply = _replyTo;
              chat.send(reply == null ? text : ChatQuote.reply(reply, text), to: room.id);
              if (reply != null) setState(() => _replyTo = null);
            },
            draft: NativeChat.prefs.draftFor(room.id),
            onDraft: (text) => NativeChat.prefs.setDraft(room.id, text),
            replyTo: _replyTo,
            onCancelReply: () => setState(() => _replyTo = null),
          ),
        ],
      ),
    );
  }

  Widget _messages(ChatController chat, ChatRoom room) {
    if (!chat.isLoaded(room.id) && (chat.connection == ChatConnection.error || chat.sessionIssue)) {
      final reason = switch (chat.connection) {
        ChatConnection.noSession => 'Log in to Torn in the browser',
        ChatConnection.needsBrowser => 'Finish logging in to Torn in the browser',
        ChatConnection.twoFactor => 'Enter your 2FA code in the browser',
        _ => null,
      };
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded),
            if (reason != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                child: Text(reason, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
              ),
          ],
        ),
      );
    }
    if (!chat.isLoaded(room.id)) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5)),
            ChatLoadingPhrase(active: chat.starting),
          ],
        ),
      );
    }
    final all = chat.filteredMessagesFor(room.id).where((m) => !isChatFactionEvent(m)).toList();
    final shown = all.sublist(math.max(0, all.length - _shown));
    if (shown.isEmpty) {
      return Center(child: Text('No messages yet', style: Theme.of(context).textTheme.bodySmall));
    }
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: shown.length,
      itemBuilder: (context, index) {
        final i = shown.length - 1 - index;
        final m = shown[i];
        final older = i > 0 ? shown[i - 1] : null;
        final newer = i < shown.length - 1 ? shown[i + 1] : null;
        final reply = m.state == ChatMessageState.sent && chat.available && room.canWrite
            ? () => setState(() => _replyTo = m)
            : null;
        final mine = chat.myUserId != null && m.sender.id == chat.myUserId;
        final swipeLeft = chatSwipeLeft(m, mine: mine);
        return ChatSwipeReply(
          key: ValueKey(m.id),
          onReply: reply,
          onSwipeLeft: swipeLeft,
          child: ChatMessageBubble(
            message: m,
            isMine: mine,
            showSender: !room.isDm,
            highlighted: chat.highlightOf(m).on,
            highlightColor: chat.highlightOf(m).color,
            isFirstInGroup: older == null || older.isSystem || older.sender.id != m.sender.id,
            isLastInGroup: newer == null || newer.isSystem || newer.sender.id != m.sender.id,
            presence: ChatApi.hasRoster(room.id) ? chat.presenceOf(m.sender.id) : null,
            onReply: reply,
            onSwipeLeft: swipeLeft,
          ),
        );
      },
    );
  }
}

class _GripPainter extends CustomPainter {
  const _GripPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final w = size.width;
    final h = size.height;
    for (final d in [11.0, 18.0]) {
      canvas.drawLine(Offset(w - 6, h - d), Offset(w - d, h - 6), paint);
    }
  }

  @override
  bool shouldRepaint(_GripPainter old) => old.color != color;
}
