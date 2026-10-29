import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:torn_pda/models/chat/chat_faction_roster.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/providers/chat/chat_faction_ops.dart';
import 'package:torn_pda/providers/chat/chat_faction_roster.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/providers/profile_api_calls_controller.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/utils/user_helper.dart';
import 'package:torn_pda/widgets/chat/chat_link_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_widgets.dart';

class ChatFactionRosterLines extends StatefulWidget {
  const ChatFactionRosterLines({super.key, required this.prefs, this.roster});

  final ChatPrefs prefs;
  final ChatFactionRoster? roster;

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
    final war = ChatFactionOps.warOf(ranked, UserHelper.factionId, DateTime.now());
    _roster.sync(widget.prefs, enemyId: war?.enemyId);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.prefs, _roster]),
      builder: (context, _) {
        final chain = widget.prefs.factionEnemyChain ? chatEnemyChainLine(_roster.chain, DateTime.now()) : null;
        final roster = widget.prefs.factionRoster ? chatRosterLine(_roster.members) : null;
        if (chain == null && roster == null) return const SizedBox.shrink();
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final dark = theme.brightness == Brightness.dark;
        final label = theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant);
        return Material(
          color: scheme.surfaceContainerHigh,
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
                if (roster != null)
                  Semantics(
                    button: true,
                    label: 'Faction members: $roster',
                    excludeSemantics: true,
                    child: InkWell(
                      onTap: () => _showChatFactionRoster(context, _roster),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 40),
                        child: Row(
                          children: [
                            Icon(Icons.groups_rounded, size: 16, color: scheme.onSurfaceVariant),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(roster, maxLines: 1, overflow: TextOverflow.ellipsis, style: label),
                            ),
                            Icon(Icons.chevron_right_rounded, size: 18, color: scheme.onSurfaceVariant),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Future<void> _showChatFactionRoster(BuildContext context, ChatFactionRoster roster) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => ChatFactionRosterSheet(roster: roster),
);

class ChatFactionRosterSheet extends StatelessWidget {
  const ChatFactionRosterSheet({super.key, required this.roster});

  final ChatFactionRoster roster;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListenableBuilder(
      listenable: roster,
      builder: (context, _) {
        final members = chatRosterByAction(roster.members);
        final now = DateTime.now();
        return SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(chatRosterLine(members) ?? 'Faction members', style: theme.textTheme.titleMedium),
              ),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.only(bottom: MediaQuery.viewPaddingOf(context).bottom),
                  itemCount: members.length,
                  itemBuilder: (context, i) {
                    final m = members[i];
                    final user = ChatUser(id: m.id, name: m.name);
                    final presence = ChatPresence.parse(m.lastAction.status);
                    final ago = ChatLastAction.ago(
                      DateTime.fromMillisecondsSinceEpoch(m.lastAction.timestamp * 1000),
                      now,
                    );
                    return ListTile(
                      leading: ChatAvatar(user: user, size: 40),
                      title: Text(m.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(m.status.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (presence != null)
                            ChatPresenceDot(presence: presence, foreground: scheme.onSurface, spoken: true),
                          const SizedBox(width: 6),
                          Text(ago ?? 'now', style: theme.textTheme.labelMedium),
                        ],
                      ),
                      onTap: () => showChatPlayerActions(context, user),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
