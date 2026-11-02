import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chat/chat_faction_ops.dart';
import 'package:torn_pda/models/chat/chat_faction_roster.dart';
import 'package:torn_pda/providers/chat/chat_faction_ops.dart';
import 'package:torn_pda/providers/chat/chat_faction_roster.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/providers/profile_api_calls_controller.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/utils/user_helper.dart';
import 'package:torn_pda/widgets/chat/chat_chain_sheets.dart';
import 'package:torn_pda/widgets/chat/chat_faction_members_sheet.dart';
import 'package:torn_pda/widgets/chat/chat_faction_ops_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_motion.dart';

class ChatFactionRosterLines extends StatefulWidget {
  const ChatFactionRosterLines({super.key, required this.prefs, this.roster, this.roomId = ChatFactionOps.roomId});

  final ChatPrefs prefs;
  final ChatFactionRoster? roster;
  final String roomId;

  @override
  State<ChatFactionRosterLines> createState() => _ChatFactionRosterLinesState();
}

class _ChatFactionRosterLinesState extends State<ChatFactionRosterLines> {
  late final ChatFactionRoster _roster = widget.roster ?? ChatFactionRoster.shared;
  late final Timer _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _sync();
      if (_roster.chain != null && mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  void _sync() {
    if (!mounted || !TickerMode.valuesOf(context).enabled || !Get.isRegistered<UserController>()) return;
    final ranked = Get.isRegistered<ProfileApiCallsController>()
        ? Get.find<ProfileApiCallsController>().factionRankedWar
        : null;
    final war = warOf(ranked, UserHelper.factionId, DateTime.now());
    _roster.sync(widget.prefs, enemyId: war?.enemyId);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.prefs, _roster]),
      builder: (context, _) {
        final chain = widget.prefs.factionEnemyChain ? chatEnemyChainLine(_roster.chain, DateTime.now()) : null;
        final counts = chatRosterCounts(_roster.members);
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final dark = theme.brightness == Brightness.dark;
        final label = theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant);
        final app = context.watch<ThemeProvider?>()?.currentTheme ?? (dark ? AppTheme.dark : AppTheme.light);
        final (background, edge) = switch (app) {
          AppTheme.light => (Colors.blueGrey.shade50, Colors.blueGrey.shade100),
          AppTheme.dark => (Colors.blueGrey.shade900, Colors.blueGrey.shade700),
          AppTheme.extraDark => (const Color(0xFF111A1E), Colors.blueGrey.shade900),
        };
        return Material(
          color: background,
          shape: Border(bottom: BorderSide(color: edge)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                if (chain != null)
                  Semantics(
                    label: chain,
                    excludeSemantics: true,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.link_rounded, size: 16, color: dark ? Colors.red[300] : Colors.red[800]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              chain,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: label?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: counts.isEmpty
                          ? const SizedBox.shrink()
                          : Semantics(
                              button: true,
                              label: 'Faction members: ${counts.map((c) => '${c.count} ${c.label}').join(' - ')}',
                              excludeSemantics: true,
                              child: InkWell(
                                onTap: () => showChatFactionMembers(context, prefs: widget.prefs, roster: _roster),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(minHeight: 40),
                                  child: Row(
                                    children: [
                                      Icon(Icons.groups_rounded, size: 16, color: scheme.onSurfaceVariant),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _RosterCounts(
                                          counts: counts,
                                          style: label?.copyWith(
                                            color: scheme.onSurface,
                                            fontWeight: FontWeight.w600,
                                            fontFeatures: const [FontFeature.tabularFigures()],
                                          ),
                                          edge: edge,
                                          glow: dark ? Colors.lightBlue.shade200 : Colors.blue.shade700,
                                        ),
                                      ),
                                      Icon(Icons.chevron_right_rounded, size: 18, color: scheme.onSurfaceVariant),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                    ),
                    if (counts.isNotEmpty)
                      Container(
                        width: 1,
                        height: 22,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        color: edge,
                      ),
                    ChatRetalRadar(prefs: widget.prefs, roomId: widget.roomId),
                    Semantics(
                      button: true,
                      label: 'Chain options',
                      excludeSemantics: true,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => showChatChainSheet(context, roomId: widget.roomId),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                          child: Icon(MaterialCommunityIcons.sword_cross, size: 20, color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Each changed count glows a moment
class _RosterCounts extends StatefulWidget {
  const _RosterCounts({required this.counts, required this.style, required this.edge, required this.glow});

  final List<({String label, int count})> counts;
  final TextStyle? style;
  final Color edge;
  final Color glow;

  @override
  State<_RosterCounts> createState() => _RosterCountsState();
}

class _RosterCountsState extends State<_RosterCounts> with TickerProviderStateMixin {
  final Map<String, AnimationController> _glows = {};

  @override
  void didUpdateWidget(_RosterCounts old) {
    super.didUpdateWidget(old);
    final duration = chatMotion(context, const Duration(seconds: 1));
    if (duration == Duration.zero) return;
    final before = {for (final c in old.counts) c.label: c.count};
    for (final c in widget.counts) {
      if (before[c.label] == c.count) continue;
      (_glows[c.label] ??= AnimationController(vsync: this))
        ..duration = duration
        ..forward(from: 0);
    }
  }

  @override
  void dispose() {
    for (final glow in _glows.values) {
      glow.dispose();
    }
    super.dispose();
  }

  TextStyle? _lit(String label, Curve fall) {
    final glow = _glows[label];
    if (glow == null || !glow.isAnimating) return null;
    final v = glow.value;
    final t = switch (v) {
      < 0.15 => Curves.easeOut.transform(v / 0.15),
      < 0.4 => 1.0,
      _ => 1 - fall.transform((v - 0.4) / 0.6),
    };
    return TextStyle(
      color: Color.lerp(widget.style?.color, widget.glow, t),
      shadows: [Shadow(color: widget.glow.withValues(alpha: 0.6 * t), blurRadius: 8)],
    );
  }

  @override
  Widget build(BuildContext context) {
    final fall = chatMotionSet(context).fadeCurve;
    final style = widget.style;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: Listenable.merge(_glows.values.toList()),
      builder: (context, _) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (i, c) in widget.counts.indexed) ...[
              if (i > 0) const SizedBox(width: 6),
              Container(
                constraints: const BoxConstraints(minHeight: 24),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: widget.edge),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    switch (c.label) {
                      'online' => const Icon(Icons.circle, size: 9, color: Colors.green),
                      'in hospital' => const Icon(MdiIcons.hospital, size: 13, color: Colors.red),
                      _ => Icon(MdiIcons.airplane, size: 13, color: dark ? Colors.blue.shade300 : Colors.blue.shade600),
                    },
                    const SizedBox(width: 5),
                    Text('${c.count}', style: style?.merge(_lit(c.label, fall))),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Future<void> showChatFactionMembers(BuildContext context, {required ChatPrefs prefs, ChatFactionRoster? roster}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => ChatFactionMembersSheet(roster: roster ?? ChatFactionRoster.shared, prefs: prefs),
    );
