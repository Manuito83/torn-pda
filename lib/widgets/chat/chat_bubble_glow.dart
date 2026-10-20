import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:torn_pda/models/chat/chat_alerts.dart';
import 'package:torn_pda/models/chat/chat_rooms.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/providers/chat/chat_ticker_queue.dart';
import 'package:torn_pda/widgets/chat/chat_widgets.dart';

/// Halo behind the bubble
class ChatBubbleGlow extends StatefulWidget {
  const ChatBubbleGlow({super.key, required this.chat, required this.prefs, this.demo});

  final ChatController chat;
  final ChatPrefs prefs;
  final ChatTickerDemo? demo;

  @override
  State<ChatBubbleGlow> createState() => _ChatBubbleGlowState();
}

class _ChatBubbleGlowState extends State<ChatBubbleGlow> with SingleTickerProviderStateMixin {
  late final AnimationController _flash = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  final List<StreamSubscription<ChatAlert>> _subscriptions = [];
  Color _color = Colors.transparent;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  @override
  void didUpdateWidget(ChatBubbleGlow old) {
    super.didUpdateWidget(old);
    if (old.chat == widget.chat && old.demo == widget.demo) return;
    _cancel();
    _listen();
  }

  void _listen() {
    _subscriptions.add(widget.chat.incomingStream.listen(_onAlert));
    if (widget.demo?.arrived case final arrived?) _subscriptions.add(arrived.listen(_onAlert));
  }

  void _cancel() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    _subscriptions.clear();
  }

  @override
  void dispose() {
    _cancel();
    _flash.dispose();
    super.dispose();
  }

  void _onAlert(ChatAlert alert) {
    final m = alert.message;
    if (!alert.demo && !widget.prefs.glowShows(m.roomId, alert.match)) return;
    if (MediaQuery.disableAnimationsOf(context)) return;
    _color = chatGroupColors(ChatRooms.group(m.roomId), Theme.of(context).brightness).$1;
    _flash.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _flash,
        builder: (context, _) {
          final t = _flash.value;
          if (t == 0 || t == 1) return const SizedBox.shrink();
          return DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _color.withValues(alpha: 0.9 * math.sin(math.pi * t)),
                  blurRadius: 10 + 14 * t,
                  spreadRadius: 2 + 8 * t,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
