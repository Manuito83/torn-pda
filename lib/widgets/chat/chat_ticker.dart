import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:torn_pda/models/chat/chat_alerts.dart';
import 'package:torn_pda/models/chat/chat_format.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_rooms.dart';
import 'package:torn_pda/models/chat/chat_tone.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/torn-pda-native/stats/stats_controller.dart';
import 'package:torn_pda/providers/chat/chat_ticker_queue.dart';
import 'package:torn_pda/widgets/chat/chat_widgets.dart';
import 'package:vibration/vibration.dart';

class ChatTicker extends StatefulWidget {
  const ChatTicker({
    super.key,
    required this.chat,
    required this.prefs,
    required this.onOpen,
    this.onReply,
    this.live = true,
    this.demo,
  });

  final ChatController chat;
  final ChatPrefs prefs;
  final ValueChanged<String> onOpen;

  /// Focuses the composer, else [onOpen]
  final ValueChanged<String>? onReply;

  /// Off, only the preview shows
  final bool live;
  final ChatTickerDemo? demo;

  @override
  State<ChatTicker> createState() => _ChatTickerState();
}

String _tickerLabel(ChatController chat, ChatAlert alert) {
  final m = alert.message;
  final room = chat.roomById(m.roomId);
  return [
    if (alert.match != null) 'Mention',
    room.isDm ? m.sender.name : '${m.sender.name} in ${room.name}',
    ChatFormat.plain(m.content),
  ].join(', ');
}

class _ChatTickerState extends State<ChatTicker> {
  final ChatTickerQueue _queue = ChatTickerQueue();
  StreamSubscription<ChatAlert>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.chat.incomingStream.listen(_onMessage);
    widget.demo?.addListener(_drainDemo);
    WidgetsBinding.instance.addPostFrameCallback((_) => _drainDemo());
  }

  @override
  void didUpdateWidget(ChatTicker old) {
    super.didUpdateWidget(old);
    if (old.demo != widget.demo) {
      old.demo?.removeListener(_drainDemo);
      widget.demo?.addListener(_drainDemo);
    }
    if (old.chat == widget.chat) return;
    _subscription?.cancel();
    _subscription = widget.chat.incomingStream.listen(_onMessage);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    widget.demo
      ?..removeListener(_drainDemo)
      ..shown = 0;
    super.dispose();
  }

  void _onMessage(ChatAlert alert) {
    if (!widget.live) return;
    final m = alert.message;
    if (!widget.prefs.tickerShows(m.roomId, alert.match)) return;
    final prefs = widget.prefs;
    if (alert.match == null &&
        !m.isSystem &&
        !m.roomId.startsWith('dm:') &&
        prefs.filterOf(m.roomId).hides(m.content)) {
      return;
    }
    if (prefs.alertVibrate && !prefs.isQuietAt(DateTime.now())) {
      _vibrate(prefs.toneForAlert(alert).vibration);
    }
    if (MediaQuery.accessibleNavigationOf(context) &&
        (alert.match != null || widget.chat.roomById(alert.message.roomId).isDm)) {
      SemanticsService.sendAnnouncement(View.of(context), _tickerLabel(widget.chat, alert), Directionality.of(context));
    }
    _enqueue(alert);
  }

  void _drainDemo() {
    final demo = widget.demo;
    if (!mounted || demo == null) return;
    for (final alert in demo.take()) {
      _enqueue(alert);
      demo.announce(alert);
    }
  }

  void _enqueue(ChatAlert alert) {
    setState(() => _queue.add(alert, widget.prefs.tickerMax));
    _syncDemo();
  }

  void _syncDemo() => widget.demo?.setShown(_queue.entries.where((e) => e.alert.demo).length);

  Future<void> _vibrate(ChatVibration vibration) async {
    if (vibration == ChatVibration.none || !await Vibration.hasVibrator()) return;
    Vibration.vibrate(pattern: vibration.pattern ?? ChatVibration.short.pattern!);
  }

  void _remove(ChatTickerEntry entry) {
    if (!mounted || !_queue.entries.contains(entry)) return;
    setState(() => _queue.entries.remove(entry));
    _syncDemo();
  }

  // A made up caption only closes
  void _open(ChatTickerEntry entry, {bool reply = false}) {
    final roomId = entry.alert.message.roomId;
    setState(() => entry.alert.demo ? _queue.entries.remove(entry) : _queue.removeRoom(roomId));
    _syncDemo();
    if (entry.alert.demo) return;
    StatsController.chat.count('ticker_open');
    (reply ? widget.onReply ?? widget.onOpen : widget.onOpen)(roomId);
  }

  void _expand(ChatTickerEntry entry) {
    if (!entry.expanded) setState(() => _queue.expand(entry));
  }

  void _act(ChatTickerEntry entry, ChatTickerTap action) =>
      action == ChatTickerTap.expand ? _expand(entry) : _open(entry);

  @override
  Widget build(BuildContext context) {
    final prefs = widget.prefs;
    final media = MediaQuery.of(context);
    final tap = prefs.tickerTap;
    return MediaQuery(
      data: media.copyWith(textScaler: TextScaler.linear(media.textScaler.scale(1) * prefs.textScale)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final e in _queue.arranged(top: prefs.tickerTop))
            _TickerCaption(
              key: ObjectKey(e),
              chat: widget.chat,
              alert: e.alert,
              leaving: e.leaving,
              expanded: e.expanded,
              shownFor: prefs.tickerSeconds == 0 ? null : Duration(seconds: prefs.tickerSeconds),
              lines: prefs.tickerLines,
              opensByTap: tap == ChatTickerTap.window,
              onGone: () => _remove(e),
              onTap: () => _act(e, tap),
              onLongPress: () => _act(e, tap == ChatTickerTap.window ? ChatTickerTap.expand : ChatTickerTap.window),
              onOpen: () => _open(e),
              onReply: () => _open(e, reply: true),
              onExpand: () => _expand(e),
            ),
        ],
      ),
    );
  }
}

class _TickerCaption extends StatefulWidget {
  const _TickerCaption({
    super.key,
    required this.chat,
    required this.alert,
    required this.leaving,
    required this.expanded,
    required this.shownFor,
    required this.lines,
    required this.opensByTap,
    required this.onGone,
    required this.onTap,
    required this.onLongPress,
    required this.onOpen,
    required this.onReply,
    required this.onExpand,
  });

  final ChatController chat;
  final ChatAlert alert;
  final bool leaving;
  final bool expanded;

  /// Null stays until dismissed
  final Duration? shownFor;
  final int lines;
  final bool opensByTap;
  final VoidCallback onGone;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onOpen;
  final VoidCallback onReply;
  final VoidCallback onExpand;

  @override
  State<_TickerCaption> createState() => _TickerCaptionState();
}

class _TickerCaptionState extends State<_TickerCaption> with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(vsync: this);
  late final Animation<double> _curve = CurvedAnimation(parent: _animation, curve: Curves.easeOut);
  Timer? _timer;
  bool? _screenReader;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.disableAnimationsOf(context);
    _animation
      ..duration = still ? Duration.zero : const Duration(milliseconds: 220)
      ..reverseDuration = still ? Duration.zero : const Duration(milliseconds: 260);
    if (!_started) {
      _started = true;
      widget.leaving ? _leave() : _animation.forward();
    }
    final on = MediaQuery.accessibleNavigationOf(context);
    if (on == _screenReader) return;
    _screenReader = on;
    _arm();
  }

  @override
  void didUpdateWidget(_TickerCaption old) {
    super.didUpdateWidget(old);
    if (widget.leaving && !old.leaving) _leave();
    if (widget.expanded != old.expanded) _arm();
  }

  void _arm() {
    _timer?.cancel();
    final shownFor = widget.shownFor;
    if (widget.leaving || widget.expanded || shownFor == null || (_screenReader ?? false)) return;
    _timer = Timer(shownFor, _leave);
  }

  void _leave() {
    _timer?.cancel();
    if (_animation.status == AnimationStatus.reverse) return;
    _animation.reverse().whenCompleteOrCancel(widget.onGone);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final m = widget.alert.message;
    final room = widget.alert.demo ? ChatTickerDemo.roomOf(m.roomId) : widget.chat.roomById(m.roomId);
    final accent = chatGroupColors(ChatRooms.group(m.roomId), theme.brightness).$1;
    final style = theme.textTheme.bodySmall?.copyWith(color: scheme.onInverseSurface, height: 1.25);
    final title = TextSpan(
      children: [
        if (widget.alert.match != null)
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.only(right: 3),
              child: Icon(Icons.alternate_email_rounded, size: 13, color: scheme.onInverseSurface),
            ),
          ),
        TextSpan(
          text: room.isDm ? m.sender.name : '${m.sender.name} in ${room.name}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    );
    final content = widget.expanded
        ? _expanded(context, room, title, style)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ChatRoomAvatar(room: room, size: 24),
              const SizedBox(width: 8),
              Flexible(
                child: Text.rich(
                  TextSpan(
                    children: [
                      title,
                      TextSpan(text: '  ${m.content.replaceAll('\n', ' ')}'),
                    ],
                  ),
                  maxLines: widget.lines,
                  overflow: TextOverflow.ellipsis,
                  style: style,
                ),
              ),
            ],
          );
    return SizeTransition(
      sizeFactor: _curve,
      alignment: AlignmentDirectional.topStart,
      child: FadeTransition(
        opacity: _curve,
        child: Semantics(
          container: true,
          excludeSemantics: !widget.expanded,
          button: !widget.expanded,
          label: _tickerLabel(widget.chat, widget.alert),
          onTap: widget.expanded ? null : widget.onTap,
          customSemanticsActions: {
            const CustomSemanticsAction(label: 'Dismiss'): _leave,
            if (!widget.expanded)
              CustomSemanticsAction(label: widget.opensByTap ? 'Expand' : 'Open'): widget.opensByTap
                  ? widget.onExpand
                  : widget.onOpen,
          },
          child: Dismissible(
            key: ObjectKey(widget.alert),
            onDismissed: (_) => widget.onGone(),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: scheme.inverseSurface.withValues(alpha: 0.9),
                elevation: 2,
                shadowColor: Colors.black45,
                clipBehavior: Clip.antiAlias,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: widget.expanded ? null : widget.onTap,
                  onLongPress: widget.expanded ? null : widget.onLongPress,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(left: BorderSide(color: accent, width: 3)),
                    ),
                    padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
                    child: content,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _expanded(BuildContext context, ChatRoom room, TextSpan title, TextStyle? style) {
    final scheme = Theme.of(context).colorScheme;
    final buttons = TextButton.styleFrom(foregroundColor: scheme.inversePrimary, visualDensity: VisualDensity.compact);
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height / 3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ChatRoomAvatar(room: room, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(title, style: style),
                      const SizedBox(height: 2),
                      Flexible(
                        child: SingleChildScrollView(child: Text(widget.alert.message.content, style: style)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(style: buttons, onPressed: widget.onOpen, child: const Text('Open')),
              TextButton.icon(
                style: buttons,
                onPressed: widget.onReply,
                icon: const Icon(Icons.reply_rounded, size: 16),
                label: const Text('Reply'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
