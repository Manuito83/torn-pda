import 'package:flutter/material.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:get/get.dart';
import 'package:torn_pda/models/chat/chat_chain_report.dart';
import 'package:torn_pda/models/chat/chat_faction_now.dart';
import 'package:torn_pda/models/chat/chat_faction_ops.dart';
import 'package:torn_pda/models/chat/chat_watch.dart';
import 'package:torn_pda/providers/chain_status_controller.dart';
import 'package:torn_pda/providers/chat/chat_faction_ops.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/providers/profile_api_calls_controller.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/utils/user_helper.dart';
import 'package:torn_pda/widgets/chaining/chain_attack.dart';
import 'package:torn_pda/widgets/chat/chat_chain_sheets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

bool _onDark(BuildContext context, [Color? foreground]) {
  final color = foreground ?? DefaultTextStyle.of(context).style.color ?? Theme.of(context).colorScheme.onSurface;
  return ThemeData.estimateBrightnessForColor(color) == Brightness.light;
}

Color chatChainColor(BuildContext context, ChatChainLevel level, [Color? foreground]) {
  final dark = _onDark(context, foreground);
  return switch (level) {
    ChatChainLevel.danger => dark ? Colors.red[300]! : Colors.red[800]!,
    ChatChainLevel.caution => dark ? Colors.orange[300]! : Colors.orange[900]!,
    ChatChainLevel.ok => dark ? Colors.green[300]! : Colors.green[800]!,
    ChatChainLevel.cooldown => dark ? Colors.lightBlue[200]! : Colors.lightBlue[900]!,
  };
}

Color chatWarColor(BuildContext context, [Color? foreground]) =>
    _onDark(context, foreground) ? Colors.orange[300]! : Colors.orange[800]!;

Color chatScoreColor(BuildContext context, {required bool ahead}) => _onDark(context)
    ? (ahead ? Colors.green[300]! : Colors.red[300]!)
    : (ahead ? Colors.green[800]! : Colors.red[800]!);

class ChatFactionOpsBuilder extends StatelessWidget {
  const ChatFactionOpsBuilder({super.key, required this.prefs, required this.builder});

  final ChatPrefs prefs;
  final Widget Function(BuildContext context, ChatFactionNow now) builder;

  @override
  Widget build(BuildContext context) {
    Widget withWar(ChainStatusController? chain) =>
        Get.isRegistered<ProfileApiCallsController>() && Get.isRegistered<UserController>()
        ? GetBuilder<ProfileApiCallsController>(builder: (p) => builder(context, _now(chain, p)))
        : builder(context, _now(chain, null));
    return ListenableBuilder(
      listenable: Listenable.merge([prefs, NativeChat.factionOps.simulated, NativeChat.factionOps.watch]),
      builder: (context, _) => Get.isRegistered<ChainStatusController>()
          ? GetBuilder<ChainStatusController>(builder: withWar)
          : withWar(null),
    );
  }

  ChatFactionNow _now(ChainStatusController? c, ProfileApiCallsController? p) {
    final ops = NativeChat.factionOps;
    final chain = prefs.factionChain ? ops.chainOf(c) : null;
    final shown = chain != null && chain.shown ? chain : null;
    final simulated = ops.simulated.value != null;
    return ChatFactionNow(
      chain: shown,
      war: p == null || !prefs.factionWar ? null : warOf(p.factionRankedWar, UserHelper.factionId, DateTime.now()),
      live: (simulated ? ops.simulatedLive : c?.webLive ?? false) && !(shown?.cooldown ?? false),
      watcher: c?.watcherActive ?? false,
      panic: c?.panicModeActive ?? false,
      panicReady: c?.panicModeEnabled ?? false,
      watches: NativeChat.factionOps.watch.value,
      me: NativeChat.controller.myUserId,
    );
  }
}

/// Gray, orange for relief, red when nobody
Color? _watchColor(BuildContext context, ChatWatchState state, ChatChain? chain) {
  if (state.reliefs.isNotEmpty) return chatChainColor(context, ChatChainLevel.caution);
  if (state.watchers.isEmpty && chain != null && chain.running && chain.hits >= 10) {
    return chatChainColor(context, ChatChainLevel.danger);
  }
  return null;
}

/// Live, watcher, panic and watch icons
List<Widget> chatChainFlags(
  BuildContext context,
  ChatFactionNow now, {
  required String roomId,
  required double size,
  Color? color,
}) {
  final muted = color ?? DefaultTextStyle.of(context).style.color?.withValues(alpha: 0.75);
  final watch = now.watchShownIn(roomId) ? now.watches[roomId] : null;
  final watchColor = watch == null ? null : _watchColor(context, watch.state, now.chain) ?? muted;
  return [
    if (now.live) ...[
      SizedBox(width: size / 4),
      Icon(Icons.sensors_rounded, size: size, color: muted),
    ],
    if (now.watcher) ...[
      SizedBox(width: size / 4),
      Icon(MdiIcons.eyeOutline, size: size, color: muted),
    ],
    if (now.panic) ...[
      SizedBox(width: size / 4),
      Icon(MdiIcons.alphaPCircleOutline, size: size, color: chatChainColor(context, ChatChainLevel.caution)),
    ],
    if (watch != null) ...[
      SizedBox(width: size / 4),
      Icon(now.onWatchIn(roomId) ? MdiIcons.shield : MdiIcons.shieldOutline, size: size, color: watchColor),
      Text(
        '${watch.short ? '~' : ''}${watch.state.watchers.length}',
        style: TextStyle(color: watchColor, fontSize: size),
      ),
    ],
  ];
}

class ChatFactionPills extends StatelessWidget {
  const ChatFactionPills({super.key, required this.now, this.chainOnly = false, this.roomId = ChatFactionOps.roomId});

  final ChatFactionNow now;

  /// War left out when both are on
  final bool chainOnly;

  /// Where the sheet sends calls
  final String roomId;

  @override
  Widget build(BuildContext context) {
    final chain = now.chain;
    final war = chainOnly && chain != null ? null : now.war;
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (chain != null)
          ValueListenableBuilder<ChatReportView?>(
            valueListenable: NativeChat.factionOps.chainReport,
            builder: (context, report, _) {
              final ready = chain.cooldown && report?.status == ChatReportStatus.ready;
              return _Pill(
                color: chatChainColor(context, chain.level),
                label: '${chatChainSpoken(chain, now, roomId)}${ready ? ', report ready' : ''}',
                hint: ready ? 'Chain report' : 'Chain options',
                onTap: () => showChatChainSheet(context, roomId: roomId),
                children: [
                  Icon(Icons.link_rounded, size: 12, color: chatChainColor(context, chain.level)),
                  const SizedBox(width: 3),
                  Text(chatChainCount(chain)),
                  if (!chain.cooldown) ...[
                    const SizedBox(width: 5),
                    Text(chatClock(Duration(seconds: chain.seconds))),
                  ],
                  ...chatChainFlags(context, now, roomId: roomId, size: 11),
                  if (ready) const _ReportReady(),
                ],
              );
            },
          ),
        if (war != null)
          _Pill(
            color: chatWarColor(context),
            label: 'Ranked war, ${war.ours} to ${war.theirs}',
            hint: 'War options',
            onTap: () => showChatWarSheet(context, roomId: roomId),
            children: [
              Icon(MaterialCommunityIcons.sword_cross, size: 12, color: chatWarColor(context)),
              const SizedBox(width: 4),
              Text(chatWarScore(war)),
            ],
          ),
      ],
    );
  }
}

class ChatFactionFooter extends StatelessWidget {
  const ChatFactionFooter({super.key, required this.prefs});

  final ChatPrefs prefs;

  @override
  Widget build(BuildContext context) => ChatFactionOpsBuilder(
    prefs: prefs,
    builder: (context, now) => now.isEmpty
        ? const SizedBox(height: 10)
        : Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 10),
            child: ChatFactionPills(now: now),
          ),
  );
}

/// Only while testing
class ChatTestStrip extends StatelessWidget {
  const ChatTestStrip({super.key, required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context) {
    final prefs = NativeChat.prefs;
    return ListenableBuilder(
      listenable: Listenable.merge([prefs, NativeChat.factionOps.simulated]),
      builder: (context, _) {
        final text = [
          if (roomId == prefs.testFactionRoom) 'Test faction',
          if (prefs.isFactionRoom(roomId) && NativeChat.factionOps.simulated.value != null) 'Simulated chain',
        ].join(' - ');
        if (text.isEmpty) return const SizedBox.shrink();
        final scheme = Theme.of(context).colorScheme;
        return Container(
          width: double.infinity,
          color: scheme.tertiaryContainer,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onTertiaryContainer),
          ),
        );
      },
    );
  }
}

class _ReportReady extends StatelessWidget {
  const _ReportReady();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: dark ? Colors.green[300] : Colors.green[800],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'REPORT READY',
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: dark ? Colors.black : Colors.white,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.color,
    required this.label,
    required this.hint,
    required this.onTap,
    required this.children,
  });

  final Color color;
  final String label;
  final String hint;
  final VoidCallback onTap;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: color,
      fontWeight: FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final radius = BorderRadius.circular(999);
    return Semantics(
      button: true,
      label: label,
      hint: hint,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: radius),
            child: DefaultTextStyle.merge(
              style: style,
              // Narrow headers shrink it
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(mainAxisSize: MainAxisSize.min, children: children),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Like the chain sheet, back to the room
Future<void> chatAttackRetal(int id, String name, String roomId) async {
  NativeChat.factionOps.dropJoin();
  final navigator = NativeChat.leaveForBrowser(backTo: roomId);
  if (navigator != null) await attackFromWar(navigator.context, id, name, shortTap: true);
}

class ChatRetalWatchSwitch extends StatelessWidget {
  const ChatRetalWatchSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final ops = NativeChat.factionOps;
    return ListenableBuilder(
      listenable: Listenable.merge([NativeChat.prefs, ops.retalDenied]),
      builder: (context, _) => SwitchListTile(
        secondary: const Icon(MdiIcons.radar),
        title: const Text('Watch retals'),
        subtitle: ops.retalDenied.value ? const Text('Retals need faction API access') : null,
        value: NativeChat.prefs.watchRetals,
        onChanged: ops.retalDenied.value ? null : ops.setRetalWatch,
      ),
    );
  }
}

/// Shown while watching, opens the Retals tab
class ChatRetalRadar extends StatelessWidget {
  const ChatRetalRadar({super.key, required this.prefs, required this.roomId});

  final ChatPrefs prefs;
  final String roomId;

  @override
  Widget build(BuildContext context) {
    final ops = NativeChat.factionOps;
    return ListenableBuilder(
      listenable: Listenable.merge([prefs, ops.retalsLive]),
      builder: (context, _) {
        if (!prefs.watchRetals) return const SizedBox.shrink();
        final count = ops.retalsLive.value;
        final color = chatWarColor(context);
        return Semantics(
          button: true,
          label: count == 0 ? 'Retals' : 'Retals, $count',
          excludeSemantics: true,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => showChatRetalsSheet(context, roomId: roomId),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(MdiIcons.radar, size: 18, color: color),
                  if (count > 0) ...[
                    const SizedBox(width: 3),
                    Text(
                      '$count',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
