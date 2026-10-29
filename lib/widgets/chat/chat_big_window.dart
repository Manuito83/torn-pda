import 'dart:math' as math;
import 'dart:ui' show FlutterView;

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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
    this.moves,
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
  final Map<CustomSemanticsAction, VoidCallback>? moves;

  @override
  State<ChatBigWindowView> createState() => _ChatBigWindowViewState();
}

/// Field blurred before the keyboard settles
class BigWindowKeyboardProbe with WidgetsBindingObserver {
  BigWindowKeyboardProbe(this._send, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  static BigWindowKeyboardProbe instance = BigWindowKeyboardProbe(
    (reason) => FirebaseCrashlytics.instance.recordError(
      StateError('Big window keyboard closed'),
      StackTrace.current,
      reason: reason,
    ),
  );

  final void Function(String reason) _send;
  final DateTime Function() _clock;
  int conversations = 0;
  DateTime? _since;
  double _height = 0;
  double _insetBefore = 0;
  double _insetMax = 0;
  int _metrics = 0;
  final List<String> _states = [];
  bool _sent = false;
  bool _watching = false;

  static FlutterView? get _view => WidgetsBinding.instance.platformDispatcher.implicitView;

  static double get _inset => switch (_view) {
    final view? => view.viewInsets.bottom / view.devicePixelRatio,
    null => 0,
  };

  void focused() {
    if (_sent) return;
    if (!_watching) {
      _watching = true;
      WidgetsBinding.instance.addObserver(this);
    }
    final view = _view;
    _since = _clock();
    _height = view == null ? 0 : view.physicalSize.height / view.devicePixelRatio;
    _insetBefore = _insetMax = _inset;
    _metrics = 0;
    _states.clear();
  }

  void lost({required bool fieldGone, required bool fullscreen, bool disposed = false}) {
    final since = _since;
    _since = null;
    if (since == null || _sent || _insetBefore > 0) return;
    final ms = _clock().difference(since).inMilliseconds;
    if (ms > 1500 || disposed) return;
    _sent = true;
    _send(
      'PDA: big window field lost focus early (ms: $ms, height: ${_height.round()}, '
      'insetMax: ${_insetMax.round()}, insetAfter: ${_inset.round()}, metrics: $_metrics, '
      'lifecycle: ${_states.isEmpty ? 'none' : _states.join('>')}, fieldGone: $fieldGone, '
      'fullscreen: $fullscreen, conversations: $conversations)',
    );
  }

  @override
  void didChangeMetrics() {
    if (_since == null) return;
    _metrics++;
    _insetMax = math.max(_insetMax, _inset);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_since != null) _states.add(state.name);
  }
}

class _ChatBigWindowViewState extends State<ChatBigWindowView> {
  EditableTextState? _field;
  FocusScopeNode? _scope;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scope = FocusScope.of(context);
  }

  void _watchField() {
    final node = FocusManager.instance.primaryFocus;
    final field = node?.context?.findAncestorStateOfType<EditableTextState>();
    final inside = field != null && node!.ancestors.contains(_scope);
    final now = inside ? field : null;
    if (now == _field) return;
    final old = _field;
    _field = now;
    if (old != null) BigWindowKeyboardProbe.instance.lost(fieldGone: !old.mounted, fullscreen: widget.fullscreen);
    if (now != null) BigWindowKeyboardProbe.instance.focused();
  }

  @override
  void initState() {
    super.initState();
    if (widget.roomId != null) BigWindowKeyboardProbe.instance.conversations++;
    if (defaultTargetPlatform == TargetPlatform.android) FocusManager.instance.addListener(_watchField);
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
    if (widget.roomId != null) BigWindowKeyboardProbe.instance.conversations++;
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
    if (defaultTargetPlatform == TargetPlatform.android) FocusManager.instance.removeListener(_watchField);
    if (_field != null) {
      BigWindowKeyboardProbe.instance.lost(fieldGone: true, disposed: true, fullscreen: widget.fullscreen);
    }
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
      onDismiss: NativeChat.bigWindowBack,
      moves: widget.moves,
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
