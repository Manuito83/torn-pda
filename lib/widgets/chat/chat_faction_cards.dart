import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:intl/intl.dart';
import 'package:torn_pda/models/chat/chat_faction_ops.dart';
import 'package:torn_pda/models/chat/chat_hit_target.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_retal.dart';
import 'package:torn_pda/models/chat/chat_short_text.dart';
import 'package:torn_pda/models/chat/chat_time.dart';
import 'package:torn_pda/models/chat/chat_watch.dart';
import 'package:torn_pda/providers/chat/chat_faction_ops.dart';
import 'package:torn_pda/providers/chat/chat_faction_roster.dart';
import 'package:torn_pda/widgets/chat/chat_chain_sheets.dart';
import 'package:torn_pda/widgets/chat/chat_faction_ops_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_link_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_motion.dart';
import 'package:torn_pda/widgets/chat/chat_player_card_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

class ChatHitCard extends StatelessWidget {
  const ChatHitCard({
    super.key,
    required this.message,
    required this.call,
    required this.color,
    required this.isMine,
    this.ops,
  });

  final ChatMessage message;
  final ChatHitCall call;
  final Color color;
  final bool isMine;

  /// The app's when null
  final ChatFactionOps? ops;

  @override
  Widget build(BuildContext context) {
    final ops = this.ops ?? NativeChat.factionOps;
    return ValueListenableBuilder<ChatHitJoin?>(
      valueListenable: ops.joined,
      builder: (context, _, _) => ChatTicking(
        until: call.at.add(const Duration(seconds: 3)),
        builder: (context) => _card(context, ops, ops.joinFor(message)),
      ),
    );
  }

  Widget _card(BuildContext context, ChatFactionOps ops, ChatHitJoin? join) {
    final theme = Theme.of(context);
    final count = chatHitCountdown(call, DateTime.now());
    final big = theme.textTheme.headlineSmall?.copyWith(
      color: color,
      fontWeight: FontWeight.w600,
      height: 1.1,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final small = theme.textTheme.labelMedium?.copyWith(color: color.withValues(alpha: 0.8));
    final still = chatMotionSet(context).line == Duration.zero;
    final counting = count.phase == ChatHitPhase.counting;
    final missed = join?.state == ChatHitJoinState.missed;
    final clock = TextSpan(text: chatClock(Duration(seconds: count.seconds)), style: big);
    final id = chatJoinTargetOf(call, ops.knownTargets);
    final button = !counting || isMine || id == null || join != null
        ? null
        : _button(theme, 'Join', () => ops.join(message.id, call, id, room: message.roomId));
    final armed = join?.state == ChatHitJoinState.armed;
    final actions = join == null || !join.pending
        ? null
        : Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Semantics(
                hint: armed ? 'Attack now' : null,
                child: OutlinedButton.icon(
                  onPressed: ops.attackNow,
                  style: _buttonStyle(theme, color),
                  icon: Icon(armed ? Icons.alarm_on_rounded : MaterialCommunityIcons.sword_cross, size: 16),
                  label: Text(armed ? 'Armed - opens at ${_seconds(chatClockOf(context), join.opens)}' : 'Attack'),
                ),
              ),
              if (armed)
                _textButton(theme, 'Disarm', ops.disarm)
              else if (!join.own && counting)
                _textButton(theme, 'Cancel', ops.cancelJoin),
            ],
          );
    final joiners = ops.joinersOf(message, call);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 170),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(MaterialCommunityIcons.sword_cross, size: 16, color: chatWarColor(context, color)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Hitting ${call.name}',
                  style: theme.textTheme.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: switch (count.phase) {
                  ChatHitPhase.counting when join != null => Text.rich(
                    TextSpan(children: [TextSpan(text: 'Attacking in ', style: small), clock]),
                  ),
                  ChatHitPhase.counting => Text.rich(
                    TextSpan(children: [clock, TextSpan(text: ' to go', style: small)]),
                  ),
                  ChatHitPhase.now => Text(missed ? 'missed' : 'now', style: big),
                  ChatHitPhase.done => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(missed ? Icons.close_rounded : Icons.done_rounded, size: 14, color: small?.color),
                      const SizedBox(width: 4),
                      Text(missed ? 'missed' : 'at ${chatClockOf(context).clock(call.at)}', style: small),
                    ],
                  ),
                },
              ),
              if (button != null) ...[const SizedBox(width: 12), Semantics(container: true, child: button)],
            ],
          ),
          if (counting) ...[
            const SizedBox(height: 5),
            TweenAnimationBuilder<double>(
              tween: Tween(end: count.fill),
              duration: still ? Duration.zero : const Duration(seconds: 1),
              builder: (context, fill, _) => ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: fill,
                  minHeight: 4,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.25),
                ),
              ),
            ),
          ],
          if (actions != null) ...[const SizedBox(height: 6), Semantics(container: true, child: actions)],
          if (joiners.isNotEmpty) ...[
            const SizedBox(height: 4),
            Tooltip(
              message: joiners.map((u) => u.name).join(', '),
              triggerMode: TooltipTriggerMode.tap,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.group_rounded, size: 14, color: small?.color),
                  const SizedBox(width: 4),
                  Text('${joiners.length} joined', style: small),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static ButtonStyle _buttonStyle(ThemeData theme, Color color) => OutlinedButton.styleFrom(
    foregroundColor: color,
    side: BorderSide(color: color.withValues(alpha: 0.6)),
    visualDensity: VisualDensity.compact,
    minimumSize: const Size(0, 30),
    padding: const EdgeInsets.symmetric(horizontal: 12),
    textStyle: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
  );

  Widget _button(ThemeData theme, String label, VoidCallback onTap) =>
      OutlinedButton(onPressed: onTap, style: _buttonStyle(theme, color), child: Text(label));

  Widget _textButton(ThemeData theme, String label, VoidCallback onTap) => TextButton(
    onPressed: onTap,
    style: TextButton.styleFrom(
      foregroundColor: color,
      visualDensity: VisualDensity.compact,
      minimumSize: const Size(0, 30),
      textStyle: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
    ),
    child: Text(label),
  );

  static String _seconds(ChatClock clock, DateTime at) =>
      DateFormat(clock.h12 ? 'h:mm:ss a' : 'HH:mm:ss').format(clock.wallClock(at));
}

/// Live clock under the threshold
class _ChainCountdown extends StatelessWidget {
  const _ChainCountdown({required this.at, required this.note});

  final DateTime at;
  final Widget note;

  @override
  Widget build(BuildContext context) => ChatTicking(
    until: at,
    builder: (context) {
      final left = math.max(0, (at.difference(DateTime.now()).inMilliseconds / 1000).ceil());
      final color = chatChainColor(context, chatChainLevelAt(left));
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.link_rounded, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                chatChainLine(left),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          note,
        ],
      );
    },
  );
}

class ChatLocalLine extends StatelessWidget {
  const ChatLocalLine({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final note = Text(
      'Only you see this',
      style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant.withValues(alpha: 0.7)),
    );
    if (chatChainLineAt(message.id) case final at?) return _ChainCountdown(at: at, note: note);
    if (chatRetalLineOf(message.id) case final retal?) {
      return _RetalLine(message: message, until: retal.expiry, note: note);
    }
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
    final body = Column(mainAxisSize: MainAxisSize.min, children: [text, note]);
    final line = player == null
        ? body
        : Semantics(
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
    final kind = chatWatchLineOf(message.id);
    if (kind == null) return line;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        line,
        Wrap(
          spacing: 8,
          children: [
            for (final (label, action) in _watchActions(kind, message.roomId))
              TextButton(
                onPressed: () => chatWatchSent(action()),
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                child: Text(label),
              ),
          ],
        ),
      ],
    );
  }

  static List<(String, ChatWatchSend Function())> _watchActions(ChatWatchLine kind, String room) {
    final ops = NativeChat.factionOps;
    ChatWatchSend take() => ops.takeWatch(room, DateTime.now().add(Duration(hours: NativeChat.prefs.watchHours)));
    ChatWatchSend leave() => ops.leaveWatch(room);
    ChatWatchSend extend() =>
        ops.takeWatch(room, (ops.myWatch(room)?.until ?? DateTime.now()).add(const Duration(hours: 1)));
    return switch (kind) {
      ChatWatchLine.relief || ChatWatchLine.nobody || ChatWatchLine.ended => [('Take watch', take)],
      ChatWatchLine.soon => [('Extend 1h', extend), ('Leave watch', leave)],
      ChatWatchLine.over => [('Leave now', leave)],
      ChatWatchLine.cooldown => [('Leave watch', leave)],
    };
  }
}

class _RetalLine extends StatelessWidget {
  const _RetalLine({required this.message, required this.until, required this.note});

  final ChatMessage message;
  final DateTime until;
  final Widget note;

  @override
  Widget build(BuildContext context) {
    final ops = NativeChat.factionOps;
    final player = message.sender;
    final stats = ' - ${ops.retalOf(message.id)?.stats ?? 'stats unknown'}';
    return ValueListenableBuilder<Set<String>>(
      valueListenable: ops.retalShared,
      builder: (context, shared, _) => ChatTicking(
        until: until,
        builder: (context) {
          final theme = Theme.of(context);
          final color = chatWarColor(context);
          final left = Duration(seconds: math.max(0, (until.difference(DateTime.now()).inMilliseconds / 1000).ceil()));
          final sent = shared.contains(message.id);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => showChatPlayerActions(context, player),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(MaterialCommunityIcons.sword_cross, size: 14, color: color),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Retal: ${player.name} - ${chatClock(left)}$stats',
                        semanticsLabel: 'Retal on ${player.name}, ${chatClock(left)} left$stats, player options',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              note,
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => chatAttackRetal(player.id, player.name, message.roomId),
                    style: ChatHitCard._buttonStyle(theme, color),
                    icon: const Icon(MaterialCommunityIcons.sword_cross, size: 16),
                    label: const Text('Attack'),
                  ),
                  OutlinedButton.icon(
                    onPressed: sent ? null : () => ops.shareRetal(message.roomId, message.id),
                    style: ChatHitCard._buttonStyle(theme, color),
                    icon: Icon(sent ? Icons.done_rounded : Icons.campaign_outlined, size: 16),
                    label: Text(sent ? 'Shared' : 'Share'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A retal someone shared
class ChatRetalCard extends StatelessWidget {
  const ChatRetalCard({super.key, required this.message, required this.call, required this.color});

  final ChatMessage message;
  final ChatRetalCall call;
  final Color color;

  @override
  Widget build(BuildContext context) => ChatTicking(
    until: call.until,
    builder: (context) {
      final theme = Theme.of(context);
      final left = call.until.difference(DateTime.now());
      final live = left > Duration.zero;
      final small = theme.textTheme.labelMedium?.copyWith(color: color.withValues(alpha: 0.8));
      final big = theme.textTheme.headlineSmall?.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
        height: 1.1,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
      final seconds = Duration(seconds: (left.inMilliseconds / 1000).ceil());
      return ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 170),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(MaterialCommunityIcons.sword_cross, size: 16, color: chatWarColor(context, color)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Retal: ${call.name}',
                    style: theme.textTheme.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            if (call.stats case final stats?) Text(stats, style: small),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: live
                      ? Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: chatClock(seconds), style: big),
                              TextSpan(text: ' left', style: small),
                            ],
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.done_rounded, size: 14, color: small?.color),
                            const SizedBox(width: 4),
                            Text('ended at ${chatClockOf(context).clock(call.until)}', style: small),
                          ],
                        ),
                ),
                if (live && !ChatFactionRoster.shared.members.any((m) => m.id == call.id)) ...[
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => chatAttackRetal(call.id, call.name, message.roomId),
                    style: ChatHitCard._buttonStyle(theme, color),
                    child: const Text('Attack'),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
    },
  );
}

/// Live list on the last watch line
class ChatWatchCard extends StatelessWidget {
  const ChatWatchCard({super.key, required this.message, required this.color});

  final ChatMessage message;
  final Color color;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Map<String, ChatWatchRoom>>(
    valueListenable: NativeChat.factionOps.watch,
    builder: (context, rooms, _) => _card(context, rooms[message.roomId]?.state),
  );

  Widget _card(BuildContext context, ChatWatchState? state) {
    final theme = Theme.of(context);
    final clock = chatClockOf(context);
    final small = theme.textTheme.labelMedium?.copyWith(color: color.withValues(alpha: 0.8));
    final me = NativeChat.controller.myUserId;
    final title = chatShortText(message.content, message.createdAt, clock: clock.clock);
    final watchers = state?.watchers ?? const <ChatWatcher>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(MdiIcons.shieldOutline, size: 16, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        if (state != null) ...[
          const SizedBox(height: 2),
          Text(
            state.cooldown
                ? 'Cooldown - no watch needed'
                : watchers.isEmpty
                ? 'No one on watch'
                : '${watchers.length} on watch',
            style: small,
          ),
          for (final w in watchers)
            Text(
              '${w.user.id == me ? 'You' : NativeChat.prefs.displayName(w.user.id, w.user.name)}'
              ' - from ${clock.clock(w.since)} to ${clock.clock(w.until)}',
              style: w.user.id == me ? small?.copyWith(fontWeight: FontWeight.w700) : small,
            ),
        ],
      ],
    );
  }
}
