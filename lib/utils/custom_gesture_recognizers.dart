import 'package:flutter/gestures.dart';

class AllowMultipleVerticalDragGestureRecognizer extends HorizontalDragGestureRecognizer {
  @override
  void rejectGesture(int pointer) {
    acceptGesture(pointer);
  }
}
