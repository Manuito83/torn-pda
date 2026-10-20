import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const double kSplitDividerWidth = 12;
const double kSplitSlotMinWidth = 320;
const Duration kSplitDividerHoldDuration = Duration(milliseconds: 400);

// On screen, for the chat overlays
final ValueNotifier<Rect?> splitDividerRect = ValueNotifier(null);

double splitLeftSlotWidth(double width, double ratio, {double leftInset = 0, double rightInset = 0}) {
  final double available = width - kSplitDividerWidth;
  final double minLeft = kSplitSlotMinWidth + leftInset;
  final double minRight = kSplitSlotMinWidth + rightInset;
  if (available <= minLeft + minRight) return leftInset + (available - leftInset - rightInset) / 2;
  return (available * ratio).clamp(minLeft, available - minRight);
}

/// Only moves after a long press, so Torn swipes near the edge do not move it
class SplitDivider extends StatefulWidget {
  final double width;
  final double ratio;
  final ValueChanged<double> onRatioChanged;
  final double leftInset;
  final double rightInset;

  const SplitDivider({
    super.key,
    required this.width,
    required this.ratio,
    required this.onRatioChanged,
    this.leftInset = 0,
    this.rightInset = 0,
  });

  @override
  State<SplitDivider> createState() => _SplitDividerState();
}

class _SplitDividerState extends State<SplitDivider> {
  double? _dragOffset;
  Rect? _published;

  void _publish(Duration _) {
    final box = mounted ? context.findRenderObject() as RenderBox? : null;
    if (box == null || !box.hasSize || !box.attached) return;
    _published = box.localToGlobal(Offset.zero) & box.size;
    splitDividerRect.value = _published;
  }

  @override
  void dispose() {
    final Rect? published = _published;
    // Tree is locked while unmounting
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (splitDividerRect.value == published) splitDividerRect.value = null;
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback(_publish);
    final double leftWidth = splitLeftSlotWidth(
      widget.width,
      widget.ratio,
      leftInset: widget.leftInset,
      rightInset: widget.rightInset,
    );
    final double available = widget.width - kSplitDividerWidth;

    return Transform.translate(
      offset: Offset(_dragOffset ?? 0, 0),
      child: RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: {
          LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
            () => LongPressGestureRecognizer(duration: kSplitDividerHoldDuration),
            (recognizer) => recognizer
              ..onLongPressStart = (_) {
                if (Platform.isAndroid || Platform.isIOS) HapticFeedback.selectionClick();
                setState(() => _dragOffset = 0);
              }
              ..onLongPressMoveUpdate = (details) {
                final double target = splitLeftSlotWidth(
                  widget.width,
                  (leftWidth + details.offsetFromOrigin.dx) / available,
                  leftInset: widget.leftInset,
                  rightInset: widget.rightInset,
                );
                setState(() => _dragOffset = target - leftWidth);
              }
              ..onLongPressEnd = (_) {
                final double moved = _dragOffset ?? 0;
                setState(() => _dragOffset = null);
                if (moved != 0) widget.onRatioChanged((leftWidth + moved) / available);
              }
              ..onLongPressCancel = () => setState(() => _dragOffset = null),
          ),
        },
        child: Container(
          width: kSplitDividerWidth,
          color: Colors.grey[900],
          alignment: Alignment.center,
          child: Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: _dragOffset == null ? Colors.grey[600] : Colors.blue[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}
