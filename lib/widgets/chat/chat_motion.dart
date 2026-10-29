import 'package:flutter/material.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

/// Timings of the chat animations for one option
class ChatMotionSet {
  const ChatMotionSet({
    required this.fade,
    required this.rise,
    required this.fadeCurve,
    required this.push,
    required this.slide,
    required this.slideCurve,
    required this.line,
  });

  /// Arrival fade and the px it rises
  final Duration fade;
  final double rise;
  final Curve fadeCurve;

  final Duration push;

  final Duration slide;
  final Curve slideCurve;

  final Duration line;

  static const _easeOutQuint = Cubic(0.22, 1, 0.36, 1);

  static const _still = ChatMotionSet(
    fade: Duration.zero,
    rise: 0,
    fadeCurve: Curves.linear,
    push: Duration.zero,
    slide: Duration.zero,
    slideCurve: Curves.linear,
    line: Duration.zero,
  );

  static ChatMotionSet of(ChatAnimations option, {bool disabled = false}) {
    if (disabled) return _still;
    return switch (option) {
      ChatAnimations.quick => const ChatMotionSet(
        fade: Duration(milliseconds: 220),
        rise: 8,
        fadeCurve: Curves.easeOut,
        push: Duration(milliseconds: 300),
        slide: Duration(milliseconds: 320),
        slideCurve: Curves.easeInOutCubic,
        line: Duration(milliseconds: 180),
      ),
      ChatAnimations.smooth => const ChatMotionSet(
        fade: Duration(milliseconds: 380),
        rise: 4,
        fadeCurve: Curves.easeOutCubic,
        push: Duration(milliseconds: 320),
        slide: Duration(milliseconds: 480),
        slideCurve: Curves.fastOutSlowIn,
        line: Duration(milliseconds: 260),
      ),
      ChatAnimations.verySmooth => const ChatMotionSet(
        fade: Duration(milliseconds: 520),
        rise: 3,
        fadeCurve: _easeOutQuint,
        push: Duration(milliseconds: 420),
        slide: Duration(milliseconds: 620),
        slideCurve: Curves.easeInOutCubic,
        line: Duration(milliseconds: 340),
      ),
    };
  }
}

ChatMotionSet chatMotionSet(BuildContext context) =>
    ChatMotionSet.of(NativeChat.prefs.animations, disabled: MediaQuery.disableAnimationsOf(context));
