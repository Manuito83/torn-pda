import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class ChatEdgeBack extends StatelessWidget {
  const ChatEdgeBack({super.key, required this.onBack, required this.child});

  static const double zone = kMinInteractiveDimension;

  static const double travel = kMinInteractiveDimension;

  final VoidCallback onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // Past what the system already takes
    final system = MediaQuery.systemGestureInsetsOf(context);
    return Stack(
      fit: StackFit.passthrough,
      children: [
        child,
        PositionedDirectional(
          start: rtl ? system.right : system.left,
          top: 0,
          bottom: 0,
          width: zone,
          child: _EdgeDrag(onBack: onBack, inward: rtl ? -1 : 1),
        ),
      ],
    );
  }
}

class _EdgeDrag extends StatefulWidget {
  const _EdgeDrag({required this.onBack, required this.inward});

  final VoidCallback onBack;
  final double inward;

  @override
  State<_EdgeDrag> createState() => _EdgeDragState();
}

class _EdgeDragState extends State<_EdgeDrag> {
  double _from = 0;
  bool _cancelled = false;

  // A cancelled pointer still ends the drag
  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerCancel: (_) => _cancelled = true,
    child: GestureDetector(
      behavior: HitTestBehavior.translucent,
      excludeFromSemantics: true,
      dragStartBehavior: DragStartBehavior.down,
      onHorizontalDragStart: (d) {
        _from = d.localPosition.dx;
        _cancelled = false;
      },
      onHorizontalDragEnd: (d) {
        if (!_cancelled && (d.localPosition.dx - _from) * widget.inward >= ChatEdgeBack.travel) widget.onBack();
      },
      child: const SizedBox.expand(),
    ),
  );
}
