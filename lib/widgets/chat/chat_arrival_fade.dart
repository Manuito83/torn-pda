import 'package:flutter/material.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/widgets/chat/chat_motion.dart';

const _window = Duration(seconds: 1);

class ChatArrivalTracker {
  ChatArrivalTracker({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  final Set<String> _known = {};
  final Map<String, DateTime> _fresh = {};
  String? _room;
  String? _tail;
  int _count = 0;
  DateTime _since = DateTime.fromMillisecondsSinceEpoch(0);

  /// Same key for a local message and its confirmed copy
  static String keyOf(ChatMessage m) => m.reqId ?? m.id;

  /// [messages] oldest first, safe to call on every build
  void update(String roomId, List<ChatMessage> messages) {
    final tail = _tail;
    if (_room != roomId) return _seed(roomId, messages);
    var from = 0;
    if (tail != null) {
      final at = messages.lastIndexWhere((m) => keyOf(m) == tail);
      if (at < 0) return _seed(roomId, messages);
      from = at + 1;
    }
    final now = _clock();
    _fresh.removeWhere((_, at) => now.difference(at) > _window);
    for (var i = from; i < messages.length; i++) {
      final m = messages[i];
      if (_known.add(keyOf(m)) && m.createdAt.isAfter(_since)) _fresh[keyOf(m)] = now;
    }
    // History grew, mark all known
    if (messages.length != _count) _known.addAll(messages.map(keyOf));
    _count = messages.length;
    _tail = messages.isEmpty ? null : keyOf(messages.last);
  }

  bool take(String key) {
    final at = _fresh.remove(key);
    return at != null && _clock().difference(at) <= _window;
  }

  void _seed(String roomId, List<ChatMessage> messages) {
    final now = _clock();
    final last = messages.lastOrNull?.createdAt;
    _room = roomId;
    _since = last != null && last.isAfter(now) ? last : now;
    _known
      ..clear()
      ..addAll(messages.map(keyOf));
    _fresh.clear();
    _count = messages.length;
    _tail = messages.isEmpty ? null : keyOf(messages.last);
  }
}

class ChatArrivalFade extends StatefulWidget {
  const ChatArrivalFade({super.key, required this.animate, required this.child});

  /// Read once
  final bool animate;
  final Widget child;

  @override
  State<ChatArrivalFade> createState() => _ChatArrivalFadeState();
}

class _ChatArrivalFadeState extends State<ChatArrivalFade> with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double> _fade = kAlwaysCompleteAnimation;
  Animation<double> _grow = kAlwaysCompleteAnimation;
  double _rise = 0;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final motion = chatMotionSet(context);
    if (!widget.animate || motion.fade == Duration.zero) return;
    final total = motion.fade > motion.push ? motion.fade : motion.push;
    double share(Duration part) => part.inMicroseconds / total.inMicroseconds;
    final controller = _controller = AnimationController(vsync: this, duration: total)..forward();
    _rise = motion.rise;
    _fade = controller.drive(CurveTween(curve: Interval(0, share(motion.fade), curve: motion.fadeCurve)));
    if (motion.push > Duration.zero) {
      _grow = controller.drive(CurveTween(curve: Interval(0, share(motion.push), curve: motion.slideCurve)));
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) return widget.child;
    return AnimatedBuilder(
      animation: _grow,
      builder: (_, child) => ClipRect(
        clipBehavior: _grow.value < 1 ? Clip.hardEdge : Clip.none,
        child: Align(
          alignment: Alignment.bottomCenter,
          heightFactor: _grow.value.clamp(0.001, 1.0),
          child: child,
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: FadeTransition(
          opacity: _fade,
          // Readable from the first frame
          alwaysIncludeSemantics: true,
          child: AnimatedBuilder(
            animation: _fade,
            child: widget.child,
            builder: (_, child) => Transform.translate(offset: Offset(0, _rise * (1 - _fade.value)), child: child),
          ),
        ),
      ),
    );
  }
}
