import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/drawer.dart';
import 'package:torn_pda/models/chaining/chain_bonus.dart';
import 'package:torn_pda/models/chaining/ffscouter/ffscouter_targets_cache.dart';
import 'package:torn_pda/models/chaining/ffscouter/ffscouter_targets_model.dart';
import 'package:torn_pda/models/chaining/target_model.dart';
import 'package:torn_pda/models/chaining/watch_notices.dart';
import 'package:torn_pda/models/chat/chat_faction_now.dart';
import 'package:torn_pda/models/chat/chat_faction_ops.dart';
import 'package:torn_pda/models/chat/chat_hit_target.dart';
import 'package:torn_pda/models/chat/chat_known_targets.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_money.dart';
import 'package:torn_pda/models/chat/chat_time.dart';
import 'package:torn_pda/models/chat/chat_watch.dart';
import 'package:torn_pda/models/faction/faction_model.dart';
import 'package:torn_pda/providers/chain_status_controller.dart';
import 'package:torn_pda/providers/chat/chat_faction_ops.dart';
import 'package:torn_pda/providers/retals_controller.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/targets_provider.dart';
import 'package:torn_pda/providers/war_controller.dart';
import 'package:torn_pda/torn-pda-native/stats/stats_controller.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/chaining/chain_attack.dart';
import 'package:torn_pda/widgets/chaining/chain_widget_options.dart';
import 'package:torn_pda/widgets/chaining/ffscouter_target_card.dart';
import 'package:torn_pda/widgets/chaining/retal_card.dart';
import 'package:torn_pda/widgets/chaining/target_card.dart';
import 'package:torn_pda/widgets/chaining/targets_list.dart';
import 'package:torn_pda/widgets/chaining/war_card.dart';
import 'package:torn_pda/widgets/chat/chat_chain_report_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_faction_ops_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_hit_picker.dart';
import 'package:torn_pda/widgets/chat/chat_motion.dart';
import 'package:torn_pda/widgets/chat/chat_theme.dart';
import 'package:torn_pda/widgets/chat/chat_toast.dart';
import 'package:torn_pda/widgets/chat/chat_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

enum _Tab { targets, war, retals, finder }

/// Opens on the tab picked last time
Future<void> showChatChainSheet(BuildContext context, {String roomId = ChatFactionOps.roomId}) {
  final tab = NativeChat.prefs.chainSheetTab;
  return _showSheet(context, tab: _Tab.values[tab.clamp(0, _Tab.values.length - 1)], roomId: roomId);
}

Future<void> showChatWarSheet(BuildContext context, {String roomId = ChatFactionOps.roomId}) =>
    _showSheet(context, tab: _Tab.war, roomId: roomId);

Future<void> showChatRetalsSheet(BuildContext context, {String roomId = ChatFactionOps.roomId}) =>
    _showSheet(context, tab: _Tab.retals, roomId: roomId);

Future<void> _showSheet(BuildContext context, {required _Tab tab, required String roomId}) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: BoxConstraints(maxWidth: 640, maxHeight: MediaQuery.sizeOf(context).height * 0.92),
      builder: (context) => _FactionOpsSheet(tab: tab, roomId: roomId),
    );

Future<void> _leaveChatFor(BuildContext sheet, String roomId, Future<void> Function(BuildContext app) go) async {
  Navigator.of(sheet).pop();
  // Attacking by hand drops a pending join
  NativeChat.factionOps.dropJoin();
  final navigator = NativeChat.leaveForBrowser(backTo: roomId);
  if (navigator != null) await go(navigator.context);
}

void _openChaining(BuildContext sheet, {required bool war}) {
  Navigator.of(sheet).pop();
  NativeChat.openChaining(war: war);
}

/// To the room that shows the card
void _closeToRoom(BuildContext sheet, String roomId) {
  Navigator.of(sheet).pop();
  if (NativeChat.controller.isOnScreen(roomId)) return;
  final navigator = NativeChat.navigatorKey?.currentState;
  if (navigator != null) unawaited(NativeChat.open(navigator, roomId: roomId));
}

// Route flags the options page overwrites
Future<void> openChainOptions(BuildContext context) async {
  final (drawer, name) = (routeWithDrawer, routeName);
  await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ChainWidgetOptions(callBackOptions: () {})));
  routeWithDrawer = drawer;
  routeName = name;
}

TextStyle? chatBigStyle(ThemeData theme) => theme.textTheme.titleLarge?.copyWith(
  fontWeight: FontWeight.w700,
  fontFeatures: const [FontFeature.tabularFigures()],
);

void _toast(WatchNotice notice) => chatToast(notice.text, seconds: notice.seconds);

/// Toasts what a watch button did
void chatWatchSent(ChatWatchSend result) {
  switch (result) {
    case ChatWatchSend.watcherOn:
      _toast(watcherNotice(true));
    case ChatWatchSend.watcherOff:
      _toast(watcherNotice(false));
    case ChatWatchSend.tooSoon:
      chatToast('One watch message a minute', seconds: 3);
    case ChatWatchSend.sent || ChatWatchSend.nothing:
      return;
  }
}

class _FactionOpsSheet extends StatefulWidget {
  const _FactionOpsSheet({required this.tab, required this.roomId});

  final _Tab tab;
  final String roomId;

  @override
  State<_FactionOpsSheet> createState() => _FactionOpsSheetState();
}

class _FactionOpsSheetState extends State<_FactionOpsSheet> {
  late _Tab _tab = widget.tab;

  @override
  void initState() {
    super.initState();
    NativeChat.factionOps.sheetOpen = true;
    StatsController.chat.count('chain_sheet');
  }

  @override
  void dispose() {
    NativeChat.factionOps.sheetOpen = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      // Tab heights differ, no jump
      child: AnimatedSize(
        duration: chatMotion(context, const Duration(milliseconds: 200)),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ChatTestStrip(roomId: widget.roomId),
            Flexible(
              child: _ChainWhen(
                of: (chain) => chain?.cooldown ?? false,
                builder: (context, cooling) => _ops(context, cooldown: cooling),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ops(BuildContext context, {required bool cooldown}) {
    final tabs = _tabs(context);
    final above = cooldown ? [const ChatChainReportSection(), tabs] : const <Widget>[];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChatFactionOpsBuilder(
          prefs: NativeChat.prefs,
          builder: (context, now) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (cooldown) const _ChainCooldown() else _ChainHead(now: now, roomId: widget.roomId),
              if (now.chain?.running ?? false) _WatchRow(now: now, roomId: widget.roomId),
              _ChainSwitches(now: now),
            ],
          ),
        ),
        if (!cooldown) tabs,
        Flexible(
          child: switch (_tab) {
            _Tab.targets => _ChainTargets(roomId: widget.roomId, above: above),
            _Tab.war => _WarTargets(roomId: widget.roomId, above: above),
            _Tab.retals => _RetalTargets(roomId: widget.roomId, above: above),
            _Tab.finder => _FinderTargets(roomId: widget.roomId, above: above),
          },
        ),
      ],
    );
  }

  Widget _tabs(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        children: [
          SegmentedButton<_Tab>(
            segments: const [
              ButtonSegment(value: _Tab.targets, label: Text('Targets')),
              ButtonSegment(value: _Tab.war, label: Text('War')),
              ButtonSegment(value: _Tab.retals, label: Text('Retals')),
              ButtonSegment(value: _Tab.finder, label: Text('Finder')),
            ],
            selected: {_tab},
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            onSelectionChanged: (picked) {
              NativeChat.prefs.setChainSheetTab(picked.first.index);
              setState(() => _tab = picked.first);
            },
          ),
          TextButton(
            onPressed: () => _openChaining(context, war: _tab == _Tab.war),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_tab == _Tab.war ? 'Open War page' : 'Open Chaining'),
                const Icon(Icons.chevron_right_rounded, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChainTargets extends StatelessWidget {
  const _ChainTargets({required this.roomId, this.above = const []});

  final String roomId;
  final List<Widget> above;

  @override
  Widget build(BuildContext context) {
    final targets = context.watch<TargetsProvider?>();
    final shown = targets == null
        ? const <TargetModel>[]
        : [
            for (final t in targets.allTargets)
              if (targetShown(targets, t)) t,
          ];
    final byId = {
      for (final t in shown)
        if (t.playerId != null) t.playerId!: t,
    };
    Future<void> attack(int id, bool shortTap) =>
        _leaveChatFor(context, roomId, (app) => attackFromTargets(app, id, shortTap: shortTap));
    return _ChainWhen(
      of: (chain) => chain?.running ?? false,
      builder: (context, running) => ChatHitPicker(
        targets: targetsOf(shown),
        card: (t) =>
            TargetCard(key: ValueKey(t.id), targetModel: byId[t.id]!, onAttack: (short) => attack(t.id, short)),
        ops: NativeChat.factionOps,
        prefs: NativeChat.prefs,
        roomId: roomId,
        empty: 'No targets',
        header: above,
        canCall: running,
        onAttack: (t) => attack(t.id, true),
        onCalled: () => _closeToRoom(context, roomId),
      ),
    );
  }
}

class _WarTargets extends StatelessWidget {
  const _WarTargets({required this.roomId, this.above = const []});

  final String roomId;

  /// Scrolls with the list
  final List<Widget> above;

  @override
  Widget build(BuildContext context) {
    final head = ChatFactionOpsBuilder(
      prefs: NativeChat.prefs,
      builder: (context, now) => _WarHead(war: now.war),
    );
    Widget picker(List<Member> members) {
      final byId = {
        for (final m in members)
          if (m.memberId != null) m.memberId!: m,
      };
      Future<void> attack(ChatHitTarget t, bool shortTap) =>
          _leaveChatFor(context, roomId, (app) => attackFromWar(app, t.id, t.name, shortTap: shortTap));
      return ChatHitPicker(
        targets: enemiesOf(members),
        card: (t) => WarCard(key: ValueKey(t.id), memberModel: byId[t.id]!, onAttack: (short) => attack(t, short)),
        ops: NativeChat.factionOps,
        prefs: NativeChat.prefs,
        roomId: roomId,
        empty: 'No war targets',
        header: [...above, if (above.isNotEmpty) head],
        onAttack: (t) => attack(t, true),
        onCalled: () => _closeToRoom(context, roomId),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (above.isEmpty) head,
        Flexible(
          child: !Get.isRegistered<WarController>()
              ? picker(const [])
              : GetBuilder<WarController>(
                  builder: (w) => picker(
                    w.membersShown(
                      offlineSelector: w.onlineFilter,
                      okayRedFilterActive: w.okayRedFilter,
                      countryFilterActive: w.countryFilter,
                      abroadFilterActive: w.abroadFilter,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _RetalTargets extends StatefulWidget {
  const _RetalTargets({required this.roomId, this.above = const []});

  final String roomId;
  final List<Widget> above;

  @override
  State<_RetalTargets> createState() => _RetalTargetsState();
}

class _RetalTargetsState extends State<_RetalTargets> {
  @override
  void initState() {
    super.initState();
    Get.put(RetalsController());
    NativeChat.factionOps.retalTab(true);
  }

  @override
  void dispose() {
    NativeChat.factionOps.retalTab(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roomId = widget.roomId;
    return ValueListenableBuilder(
      valueListenable: NativeChat.factionOps.retalTabFailed,
      builder: (context, failed, _) => GetBuilder<RetalsController>(
        builder: (r) {
          final list = r.retaliationList;
          final byId = {
            for (final retal in list)
              if (retal.retalId != null) retal.retalId!: retal,
          };
          Future<void> attack(int id) => _leaveChatFor(context, roomId, (app) => attackFromRetals(app, byId[id]!));
          return ChatHitPicker(
            targets: retalHitTargets(list),
            card: (t) => RetalCard(
              key: ValueKey(t.id),
              retalModel: byId[t.id]!,
              expiryTimeStamp: byId[t.id]!.retalExpiry,
              onAttack: (_) => attack(t.id),
            ),
            ops: NativeChat.factionOps,
            prefs: NativeChat.prefs,
            roomId: roomId,
            header: [...widget.above, const ChatRetalWatchSwitch()],
            empty: switch (failed) {
              null => 'Checking',
              true => 'Retals not available',
              false => 'No retals',
            },
            onAttack: (t) => attack(t.id),
            onCalled: () => _closeToRoom(context, roomId),
          );
        },
      ),
    );
  }
}

class _FinderTargets extends StatefulWidget {
  const _FinderTargets({required this.roomId, this.above = const []});

  final String roomId;
  final List<Widget> above;

  @override
  State<_FinderTargets> createState() => _FinderTargetsState();
}

class _FinderTargetsState extends State<_FinderTargets> {
  List<FFScouterTarget> _found = const [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final found = decodeFFScouterTargets(await Prefs().getFFScouterTargetsCache());
    if (!mounted) return;
    setState(() {
      _found = found;
      _loaded = true;
    });
  }

  void _save() {
    setState(() {});
    Prefs().setFFScouterTargetsCache(encodeFFScouterTargets(_found));
  }

  @override
  Widget build(BuildContext context) {
    final roomId = widget.roomId;
    final settings = context.watch<SettingsProvider?>();
    final ready = settings != null && settings.ffScouterEnabledStatusRemoteConfig && settings.ffScouterEnabledStatus == 1;
    final found = ready ? _found : const <FFScouterTarget>[];
    final byId = {
      for (final t in found)
        if (t.playerId != null) t.playerId!: t,
    };
    Future<void> attack(int id, bool shortTap) => _leaveChatFor(
      context,
      roomId,
      (app) async => attackFromTargetFinder(app, found, byId[id]!, shortTap: shortTap),
    );
    return ChatHitPicker(
      targets: finderHitTargets(found),
      card: (t) => FFScouterTargetCard(
        key: ValueKey(t.id),
        target: byId[t.id]!,
        onAttack: (short) => attack(t.id, short),
        onChanged: _save,
      ),
      ops: NativeChat.factionOps,
      prefs: NativeChat.prefs,
      roomId: roomId,
      header: widget.above,
      empty: !ready
          ? 'Target finder not set up'
          : _loaded
          ? 'No targets'
          : 'Loading',
      onAttack: (t) => attack(t.id, true),
      onCalled: () => _closeToRoom(context, roomId),
    );
  }
}

/// Rebuilds only when [of] flips
class _ChainWhen extends StatelessWidget {
  const _ChainWhen({required this.of, required this.builder});

  final bool Function(ChatChain? chain) of;
  final Widget Function(BuildContext context, bool on) builder;

  bool _read(ChainStatusController? c) => NativeChat.prefs.factionChain && of(NativeChat.factionOps.chainOf(c));

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([NativeChat.prefs, NativeChat.factionOps.simulated]),
      builder: (context, _) => Get.isRegistered<ChainStatusController>()
          ? GetBuilder<ChainStatusController>(filter: _read, builder: (c) => builder(context, _read(c)))
          : builder(context, _read(null)),
    );
  }
}

class _ChainCooldown extends StatelessWidget {
  const _ChainCooldown();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final clock = chatClockOf(context);
    return ChatFactionOpsBuilder(
      prefs: NativeChat.prefs,
      builder: (context, now) {
        final chain = now.chain;
        if (chain == null || !chain.cooldown) return const SizedBox.shrink();
        final started = _startedAt();
        final bonus = chainBonusReached(chain.hits);
        final left = chatClock(Duration(seconds: chain.seconds));
        // Only the report knows how long it ran
        final lasted = NativeChat.factionOps.chainReport.value?.report?.length;
        final details = [
          '${chatCount(chain.hits)} hits',
          if (bonus != null) 'Bonus ${chatCount(bonus)} reached',
          if (started != null) 'Started ${clock.clock(started)}',
          if (lasted != null) 'Lasted ${chatClock(lasted)}',
        ].join(' - ');
        return Semantics(
          container: true,
          label: 'Chain cooldown, $left left, $details',
          excludeSemantics: true,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Cooldown', style: theme.textTheme.titleMedium)),
                    Text(left, style: chatBigStyle(theme)?.copyWith(color: chatChainColor(context, chain.level))),
                  ],
                ),
                const SizedBox(height: 4),
                Text(details, style: muted),
              ],
            ),
          ),
        );
      },
    );
  }

  static DateTime? _startedAt() {
    if (!Get.isRegistered<ChainStatusController>()) return null;
    final start = Get.find<ChainStatusController>().chainModel?.chain?.start ?? 0;
    return start > 0 ? DateTime.fromMillisecondsSinceEpoch(start * 1000) : null;
  }
}

class _ChainHead extends StatelessWidget {
  const _ChainHead({required this.now, required this.roomId});

  final ChatFactionNow now;
  final String roomId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chain = now.chain;
    final big = chatBigStyle(theme);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Semantics(
        container: true,
        label: chain == null ? 'No chain' : chatChainSpoken(chain, now, roomId),
        excludeSemantics: true,
        child: Row(
          children: [
            if (chain == null)
              Text('No chain', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))
            else ...[
              Text(chatChainCount(chain), style: big),
              const SizedBox(width: 12),
              Text(
                chatClock(Duration(seconds: chain.seconds)),
                style: big?.copyWith(color: chatChainColor(context, chain.level)),
              ),
            ],
            ...chatChainFlags(context, now, roomId: roomId, size: 18, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _WatchRow extends StatefulWidget {
  const _WatchRow({required this.now, required this.roomId});

  final ChatFactionNow now;
  final String roomId;

  @override
  State<_WatchRow> createState() => _WatchRowState();
}

class _WatchRowState extends State<_WatchRow> {
  static const _reliefIn = [null, Duration(minutes: 15), Duration(minutes: 30), Duration(hours: 1)];

  Duration? _relief;
  DateTime? _until;

  String _reliefLabel(Duration? d) => switch (d?.inMinutes) {
    null => 'now',
    60 => '1 h',
    final m => '$m min',
  };

  Future<void> _pickUntil(ChatClock clock) async {
    final now = DateTime.now();
    final initial = _until ?? now.add(Duration(hours: NativeChat.prefs.watchHours));
    final time = await showChatTimePicker(context, TimeOfDay.fromDateTime(clock.wallClock(initial)));
    if (time == null || !mounted) return;
    final at = clock.nextAt(time.hour, time.minute, DateTime.now());
    if (at.difference(DateTime.now()) > chatWatchWindow) {
      chatToast('A watch lasts 12 hours at most', seconds: 3);
      return;
    }
    setState(() => _until = at);
  }

  void _take(String room) {
    final until = _until ?? DateTime.now().add(Duration(hours: NativeChat.prefs.watchHours));
    if (!until.isAfter(DateTime.now())) {
      setState(() => _until = null);
      chatToast('That time has passed', seconds: 3);
      return;
    }
    chatWatchSent(NativeChat.factionOps.takeWatch(room, until));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final clock = chatClockOf(context);
    final prefs = NativeChat.prefs;
    final ops = NativeChat.factionOps;
    final now = widget.now;
    final room = widget.roomId;
    final watch = now.watches[room];
    final state = watch?.state ?? const ChatWatchState();
    final mine = state.of(now.me);
    final can = NativeChat.controller.available;
    void send(ChatWatchSend Function() action) => chatWatchSent(action());
    String name(ChatUser user) => user.id == now.me ? 'You' : prefs.displayName(user.id, user.name);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(mine == null ? MdiIcons.shieldOutline : MdiIcons.shield, size: 18),
              const SizedBox(width: 8),
              Text('On watch', style: theme.textTheme.titleSmall),
              const SizedBox(width: 12),
              if (watch?.short ?? false) Flexible(child: Text('Older messages still loading', style: muted)),
            ],
          ),
          const SizedBox(height: 4),
          if (state.watchers.isEmpty)
            Text('No one', style: muted)
          else
            for (final w in state.watchers)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name(w.user),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: w.user.id == now.me
                          ? TextStyle(color: chatScoreColor(context, ahead: true), fontWeight: FontWeight.w600)
                          : null,
                    ),
                  ),
                  Text('From ${clock.clock(w.since)} to ${clock.clock(w.until)}', style: muted),
                ],
              ),
          for (final r in state.reliefs)
            DefaultTextStyle.merge(
              style: muted?.copyWith(color: chatChainColor(context, ChatChainLevel.caution)),
              child: Row(
                children: [
                  Expanded(child: Text(name(r.user), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Text(switch ((state.isRelief(r), r.from)) {
                    (true, null) => 'Relief now',
                    (true, final from?) => 'Relief from ${clock.clock(from)}',
                    (false, null) => 'Needs a chain watcher',
                    (false, final from?) => 'Needs a chain watcher from ${clock.clock(from)}',
                  }),
                ],
              ),
            ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: mine == null
                ? [
                    for (final h in chatWatchHours)
                      ChoiceChip(
                        label: Text('${h}h'),
                        selected: _until == null && prefs.watchHours == h,
                        onSelected: (_) => setState(() {
                          _until = null;
                          prefs.setWatchHours(h);
                        }),
                      ),
                    ChoiceChip(
                      label: Text(
                        _until == null ? '...' : clock.clock(_until!),
                        semanticsLabel: _until == null ? 'Exact time' : null,
                      ),
                      selected: _until != null,
                      onSelected: (_) => _pickUntil(clock),
                    ),
                    FilledButton.tonal(
                      onPressed: can ? () => _take(room) : null,
                      child: const Text('Take watch'),
                    ),
                  ]
                : [
                    for (final d in _reliefIn)
                      ChoiceChip(
                        label: Text(_reliefLabel(d)),
                        selected: _relief == d,
                        onSelected: (_) => setState(() => _relief = d),
                      ),
                    OutlinedButton(
                      style: chatSecondaryButton(theme.colorScheme),
                      onPressed: can ? () => send(() => ops.askRelief(room, _relief)) : null,
                      child: const Text('Ask for relief'),
                    ),
                    FilledButton.tonal(
                      onPressed: can ? () => send(() => ops.leaveWatch(room)) : null,
                      child: const Text('Leave watch'),
                    ),
                  ],
          ),
        ],
      ),
    );
  }
}

class _ChainSwitches extends StatelessWidget {
  const _ChainSwitches({required this.now});

  final ChatFactionNow now;

  @override
  Widget build(BuildContext context) {
    final c = Get.isRegistered<ChainStatusController>() ? Get.find<ChainStatusController>() : null;
    final watcherOk = c != null && (!c.modelError || c.chainWatcherDefcon == WatchDefcon.apiFail);
    final panicOk = c != null && now.panicReady && !c.modelError;
    Widget half(IconData icon, String label, bool value, ValueChanged<bool>? onChanged) => Expanded(
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        secondary: Icon(icon),
        title: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        horizontalTitleGap: 8,
      ),
    );
    final line = BorderSide(color: Theme.of(context).dividerColor);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: line, bottom: line),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            half(MdiIcons.eyeOutline, 'Watcher', now.watcher, watcherOk ? (on) => _setWatcher(c, on) : null),
            const VerticalDivider(width: 1),
            if (now.panicReady)
              half(MdiIcons.alphaPCircleOutline, 'Panic', now.panic, panicOk ? (on) => _setPanic(c, on) : null)
            else
              Expanded(
                child: ListTile(
                  leading: const Icon(MdiIcons.alphaPCircleOutline),
                  title: const Text('Panic', maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: const Text('Set up in Chaining', maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  horizontalTitleGap: 8,
                  onTap: () => openChainOptions(context),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _setWatcher(ChainStatusController c, bool on) {
    c.setWatcher(on, fromChat: true);
    _toast(watcherNotice(on));
  }

  void _setPanic(ChainStatusController c, bool on) {
    final withWatcher = c.setPanic(on, fromChat: true);
    _toast(panicNotice(on, withWatcher: withWatcher));
  }
}

class _WarHead extends StatelessWidget {
  const _WarHead({required this.war});

  final ChatWar? war;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final war = this.war;
    if (war == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
        child: Text('No ranked war', style: theme.textTheme.titleMedium?.copyWith(color: muted)),
      );
    }
    final ahead = war.ours >= war.theirs;
    final big = chatBigStyle(theme);
    final span = chatSpan(DateTime.now().difference(war.start));
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
      child: Semantics(
        container: true,
        label:
            'Ranked war, ${war.ours} to ${war.theirs}, ${ahead ? 'ahead' : 'behind'} by '
            '${(war.ours - war.theirs).abs()}, $span in',
        excludeSemantics: true,
        child: Row(
          children: [
            Icon(MaterialCommunityIcons.sword_cross, size: 20, color: chatWarColor(context)),
            const SizedBox(width: 10),
            Text(
              chatCount(war.ours),
              style: big?.copyWith(color: chatScoreColor(context, ahead: ahead)),
            ),
            Text(
              ' : ',
              style: big?.copyWith(color: muted, fontWeight: FontWeight.w400),
            ),
            Text(chatCount(war.theirs), style: big),
            const Spacer(),
            Text(
              '${chatWarLead(war)} - $span',
              style: theme.textTheme.labelMedium?.copyWith(
                color: muted,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
