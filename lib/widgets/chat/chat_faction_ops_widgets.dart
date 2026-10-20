import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'package:get/get.dart';
import 'package:torn_pda/models/chat/chat_faction_ops.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/providers/chain_status_controller.dart';
import 'package:torn_pda/providers/chat/chat_faction_ops.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/providers/profile_api_calls_controller.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/utils/user_helper.dart';
import 'package:torn_pda/widgets/chat/chat_link_widgets.dart';

Color _chatChainColor(ChatChainLevel level, {required bool onDark}) => switch (level) {
  ChatChainLevel.danger => onDark ? Colors.red[300]! : Colors.red[800]!,
  ChatChainLevel.caution => onDark ? Colors.orange[300]! : Colors.orange[900]!,
  ChatChainLevel.ok => onDark ? Colors.green[300]! : Colors.green[800]!,
  ChatChainLevel.cooldown => onDark ? Colors.lightBlue[200]! : Colors.lightBlue[900]!,
};

/// Hits and timeout for the room header
class ChatChainLine extends StatelessWidget {
  const ChatChainLine({super.key, required this.prefs});

  final ChatPrefs prefs;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ChainStatusController>()) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: prefs,
      builder: (context, _) => GetBuilder<ChainStatusController>(
        builder: (c) {
          final chain = ChatFactionOps.chainOf(c);
          if (!prefs.factionChain || chain == null || !chain.running) return const SizedBox.shrink();
          return ChatChainChip(chain: chain);
        },
      ),
    );
  }
}

class ChatChainChip extends StatelessWidget {
  const ChatChainChip({super.key, required this.chain});

  final ChatChain chain;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = DefaultTextStyle.of(context).style.color ?? theme.colorScheme.onSurface;
    final onDark = ThemeData.estimateBrightnessForColor(foreground) == Brightness.light;
    final color = _chatChainColor(chain.level, onDark: onDark);
    final clock = chatClock(Duration(seconds: chain.seconds));
    final style = theme.textTheme.labelMedium?.copyWith(color: foreground.withValues(alpha: 0.8));
    return Semantics(
      label: 'Chain ${chain.hits} hits, $clock left',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(left: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.link_rounded, size: 14, color: color),
            const SizedBox(width: 3),
            Text('${chain.hits}', style: style),
            const SizedBox(width: 6),
            Text(
              clock,
              style: style?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ranked war score above the faction room
class ChatWarStrip extends StatefulWidget {
  const ChatWarStrip({super.key, required this.prefs});

  final ChatPrefs prefs;

  @override
  State<ChatWarStrip> createState() => _ChatWarStripState();
}

class _ChatWarStripState extends State<ChatWarStrip> {
  late final Timer _clock;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 30), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _clock.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ProfileApiCallsController>() || !Get.isRegistered<UserController>()) {
      return const SizedBox.shrink();
    }
    return ListenableBuilder(
      listenable: widget.prefs,
      builder: (context, _) => GetBuilder<ProfileApiCallsController>(
        builder: (p) {
          final war = ChatFactionOps.warOf(p.factionRankedWar, UserHelper.factionId, DateTime.now());
          if (!widget.prefs.factionWar || war == null) return const SizedBox.shrink();
          return ChatWarBar(war: war, now: DateTime.now());
        },
      ),
    );
  }
}

class ChatWarBar extends StatelessWidget {
  const ChatWarBar({super.key, required this.war, required this.now});

  final ChatWar war;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final ahead = war.ours >= war.theirs;
    final good = dark ? Colors.green[300]! : Colors.green[800]!;
    final bad = dark ? Colors.red[300]! : Colors.red[800]!;
    final span = chatSpan(now.difference(war.start));
    final label = theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant);
    final score = theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold);
    return Semantics(
      container: true,
      label: 'Ranked war against ${war.enemy}: ${war.ours} to ${war.theirs}, $span in',
      excludeSemantics: true,
      child: Material(
        color: scheme.surfaceContainerHigh,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Icon(MaterialCommunityIcons.sword_cross, size: 16, color: dark ? Colors.orange[300] : Colors.orange[800]),
              const SizedBox(width: 8),
              Expanded(
                child: Text('vs ${war.enemy}', maxLines: 1, overflow: TextOverflow.ellipsis, style: label),
              ),
              const SizedBox(width: 8),
              Text('${war.ours}', style: score?.copyWith(color: ahead ? good : bad)),
              Text(' : ', style: label),
              Text('${war.theirs}', style: score?.copyWith(color: ahead ? bad : good)),
              const SizedBox(width: 10),
              Text(span, style: label),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatLocalLine extends StatelessWidget {
  const ChatLocalLine({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final style = theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final player = message.sender.id > 0 ? message.sender : null;
    final at = player == null ? -1 : message.content.indexOf(player.name);
    final text = Text.rich(
      at < 0
          ? TextSpan(text: message.content)
          : TextSpan(
              children: [
                TextSpan(text: message.content.substring(0, at)),
                TextSpan(
                  text: player!.name,
                  style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
                TextSpan(text: message.content.substring(at + player.name.length)),
              ],
            ),
      textAlign: TextAlign.center,
      style: style,
    );
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        text,
        Text(
          'Only you see this',
          style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant.withValues(alpha: 0.7)),
        ),
      ],
    );
    if (player == null) return body;
    return Semantics(
      button: true,
      hint: 'Player options',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showChatPlayerActions(context, player),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Center(widthFactor: 1, heightFactor: 1, child: body),
        ),
      ),
    );
  }
}
