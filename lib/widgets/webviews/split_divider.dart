import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/webview/split_layout.dart';
import 'package:torn_pda/providers/webview_provider.dart' show WebViewProvider;

export 'package:torn_pda/models/webview/split_layout.dart' show kSplitDividerWidth, kSplitSlotMinWidth, splitLeftSlotWidth;

const Duration kSplitDividerHoldDuration = Duration(milliseconds: 400);

/// Moves only after a long press
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
  late final ValueNotifier<Rect?> _screenRect = context.read<WebViewProvider>().splitDividerRect;

  void _publish(Duration _) {
    final box = mounted ? context.findRenderObject() as RenderBox? : null;
    if (box == null || !box.hasSize || !box.attached) return;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    _screenRect.value = rect;
    _published = rect;
  }

  @override
  void dispose() {
    final Rect? published = _published;
    if (published != null) {
      final screenRect = _screenRect;
      // Tree is locked while unmounting
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (screenRect.value == published) screenRect.value = null;
      });
    }
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
