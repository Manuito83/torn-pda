import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:torn_pda/widgets/chat/chat_motion.dart';

class ChatSlideToPlace extends StatefulWidget {
  const ChatSlideToPlace({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<ChatSlideToPlace> createState() => _ChatSlideToPlaceState();
}

class _ChatSlideToPlaceState extends State<ChatSlideToPlace> with SingleTickerProviderStateMixin {
  late final AnimationController _move = AnimationController(vsync: this);
  double _shift = 0;
  double? _slot;
  bool _moved = false;
  Curve _curve = Curves.easeInOutCubic;

  @override
  void dispose() {
    _move.dispose();
    super.dispose();
  }

  double _current() => _shift * (1 - _curve.transform(_move.value));

  // Slot in content, not on screen
  double? _slotNow() {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return RenderAbstractViewport.maybeOf(box)?.getOffsetToReveal(box, 0).offset;
  }

  @override
  void didUpdateWidget(ChatSlideToPlace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) _moved = true;
  }

  void _track() {
    if (!mounted) return;
    final now = _slotNow();
    if (now == null) return;
    final before = _slot;
    final moved = _moved;
    _slot = now;
    _moved = false;
    if (!moved || before == null || (before - now).abs() < 1) return;
    _shift = _current() + before - now;
    _move.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final motion = chatMotionSet(context);
    _move.duration = motion.slide;
    _curve = motion.slideCurve;
    WidgetsBinding.instance.addPostFrameCallback((_) => _track());
    return AnimatedBuilder(
      animation: _move,
      child: widget.child,
      builder: (_, child) => Transform.translate(offset: Offset(0, _current()), child: child),
    );
  }
}
