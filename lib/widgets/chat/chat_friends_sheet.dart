import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_status.dart';
import 'package:torn_pda/providers/chat/chat_api.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';
import 'package:torn_pda/providers/chat/chat_faction_roster.dart';
import 'package:torn_pda/providers/friends_provider.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/utils/country_check.dart';
import 'package:torn_pda/widgets/chat/chat_link_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

typedef _Row = (ChatUser, ChatPresence?, DateTime?);

const _tabs = ['torn', 'pda', 'chat', 'faction', 'company'];

const _sorts = [
  ('status', 'Status', Icon(Icons.monitor_heart_outlined, size: 18)),
  ('online', 'Online', Icon(Icons.circle, size: 12, color: Colors.green)),
  ('name', 'Name', Icon(Icons.sort_by_alpha_rounded, size: 18)),
];

@visibleForTesting
(DateTime, int, List<(ChatUser, ChatLastAction)>)? chatCompanyCache;

/// Pops with the chosen friend
class ChatFriendsSheet extends StatefulWidget {
  const ChatFriendsSheet({super.key, this.api});

  final ChatApi? api;

  @override
  State<ChatFriendsSheet> createState() => _ChatFriendsSheetState();
}

class _ChatFriendsSheetState extends State<ChatFriendsSheet> with SingleTickerProviderStateMixin {
  Timer? _timer;
  Timer? _tick;
  final _now = ValueNotifier(DateTime.now());
  late final TabController _tab;
  bool _askedSaved = false;
  int? _asking;
  late final ChatApi _api = widget.api ?? TornChatApi();

  @override
  void initState() {
    super.initState();
    final chat = context.read<ChatController>();
    WidgetsBinding.instance.addPostFrameCallback((_) => chat.refreshFriends());
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      chat.refreshFriends(force: true);
      _ask(_tab.index);
    });
    int saved;
    try {
      saved = context.read<FriendsProvider>().allFriends.length;
    } on ProviderNotFoundException {
      saved = 0;
    }
    // Unknown Torn list counts as having rows
    final hasRows = [
      chat.friends?.isNotEmpty ?? !chat.friendsFailed,
      saved > 0,
      NativeChat.prefs.chatFriends.isNotEmpty,
      _has('faction'),
      _has('company'),
    ];
    final last = _tabs.indexOf(NativeChat.prefs.friendsTab);
    final first = hasRows.indexOf(true);
    _tab =
        TabController(length: 5, vsync: this, initialIndex: last >= 0 && hasRows[last] ? last : (first < 0 ? 0 : first))
          ..addListener(() {
            if (_tab.indexIsChanging) return;
            NativeChat.prefs.setFriendsTab(_tabs[_tab.index]);
            setState(() {});
            _ask(_tab.index);
          });
    WidgetsBinding.instance.addPostFrameCallback((_) => _ask(_tab.index));
  }

  // Unknown membership counts as having one
  bool _has(String tab) {
    if (!Get.isRegistered<UserController>()) return true;
    final user = Get.find<UserController>();
    return (tab == 'faction' ? user.factionId : user.companyId) != 0;
  }

  int get _me => Get.isRegistered<UserController>() ? Get.find<UserController>().playerId : 0;

  (DateTime, int, List<(ChatUser, ChatLastAction)>)? get _company =>
      chatCompanyCache?.$2 == _me ? chatCompanyCache : null;

  Future<void> _ask(int index) async {
    final tab = _tabs[index];
    if (index < 3 || _asking == index || !_has(tab)) return;
    final faction = tab == 'faction';
    final at = faction ? ChatFactionRoster.shared.membersAt : _company?.$1;
    if (at != null &&
        DateTime.now().difference(at) < (faction ? const Duration(seconds: 25) : const Duration(minutes: 5))) {
      return;
    }
    setState(() => _asking = index);
    try {
      final rows = await _api.roster(tab);
      if (!faction) chatCompanyCache = (DateTime.now(), _me, rows ?? _company?.$3 ?? const []);
    } finally {
      if (mounted) setState(() => _asking = null);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tick?.cancel();
    _now.dispose();
    _tab.dispose();
    super.dispose();
  }

  List<_Row> _saved() {
    final FriendsProvider provider;
    try {
      provider = context.watch<FriendsProvider>();
    } on ProviderNotFoundException {
      return [];
    }
    if (!provider.initialized) {
      if (!_askedSaved) WidgetsBinding.instance.addPostFrameCallback((_) => provider.initFriends());
      _askedSaved = true;
      return [];
    }
    return [
      for (final f in provider.allFriends)
        if ((f.playerId, f.name) case (final int id, final String name))
          (
            ChatUser(id: id, name: name),
            ChatPresence.parse(f.lastAction?.status),
            (f.lastAction?.timestamp ?? 0) > 0
                ? DateTime.fromMillisecondsSinceEpoch(f.lastAction!.timestamp! * 1000)
                : null,
          ),
    ];
  }

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: NativeChat.prefs, builder: (context, _) => _sheet(context));

  Widget _sheet(BuildContext context) {
    final chat = context.watch<ChatController>();
    final theme = Theme.of(context);
    final now = DateTime.now();
    final small = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    int byName(_Row a, _Row b) => a.$1.name.toLowerCase().compareTo(b.$1.name.toLowerCase());
    int byPresence(_Row a, _Row b) =>
        (a.$2?.index ?? 3) != (b.$2?.index ?? 3) ? (a.$2?.index ?? 3).compareTo(b.$2?.index ?? 3) : byName(a, b);
    int byStatus(_Row a, _Row b) {
      final status = ChatPlayerStatus.compare(a.$1.playerStatus, b.$1.playerStatus, now);
      return status != 0 ? status : byPresence(a, b);
    }

    final sort = NativeChat.prefs.friendsSort;
    final byChoice = switch (sort) {
      'name' => byName,
      'online' => byPresence,
      _ => byStatus,
    };
    final lists = <List<_Row>>[
      [for (final u in chat.friends ?? const <ChatUser>[]) (u, chat.presenceOf(u.id), chat.lastSeenOf(u.id))],
      _saved()..sort(byPresence),
      [
        for (final e in NativeChat.prefs.chatFriends.entries)
          (ChatUser(id: e.key, name: e.value), chat.presenceOf(e.key), chat.lastSeenOf(e.key)),
      ]..sort(byPresence),
      [
        for (final m in ChatFactionRoster.shared.members)
          (
            ChatUser(
              id: m.id,
              name: m.name,
              playerStatus: ChatPlayerStatus.from(m.status.state, m.status.description, m.status.until),
            ),
            ChatPresence.parse(m.lastAction.status),
            DateTime.fromMillisecondsSinceEpoch(m.lastAction.timestamp * 1000),
          ),
      ]..sort(byChoice),
      [for (final (u, a) in _company?.$3 ?? const <(ChatUser, ChatLastAction)>[]) (u, a.presence, a.at)]
        ..sort(byChoice),
    ];
    final shown = lists[_tab.index];
    final online = shown.where((r) => r.$2 == ChatPresence.online).length;

    if (shown.any((r) => r.$1.playerStatus?.left(now) != null)) {
      _tick ??= Timer.periodic(const Duration(seconds: 1), (_) => _now.value = DateTime.now());
    } else {
      _tick?.cancel();
      _tick = null;
    }

    Widget list(int index) {
      final rows = lists[index];
      if (index == 0 && chat.friends == null) {
        if (!chat.friendsFailed) return const SizedBox.shrink();
        return const ChatStateMessage(
          icon: Icons.key_off_outlined,
          title: 'Torn friends not available',
          subtitle: 'Your API key cannot read your Torn friends list',
        );
      }
      if (rows.isEmpty) {
        return ChatStateMessage(
          icon: Icons.people_outline_rounded,
          title: index > 2 ? 'Nobody to show' : 'No friends to show',
          subtitle: index == 2 ? 'Add them from a player\'s details' : null,
        );
      }
      return ListView(
        children: [
          for (final (user, presence, seen) in rows)
            ListTile(
              leading: ChatAvatar(user: user, size: 40),
              title: switch (user.playerStatus) {
                null => Text(user.name),
                final status => Row(
                  children: [
                    Expanded(child: Text(user.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    ValueListenableBuilder(
                      valueListenable: _now,
                      builder: (_, now, _) => _pill(status, now, theme),
                    ),
                  ],
                ),
              },
              subtitle: presence == null
                  ? Text('[${user.id}]', style: small)
                  : ChatConnectionLine(state: ChatConnection.connected, presence: presence, lastSeen: seen),
              trailing: IconButton(
                tooltip: 'Player actions',
                icon: const Icon(Icons.more_vert_rounded),
                onPressed: () => showChatPlayerActions(context, user),
              ),
              onTap: chat.ready ? () => Navigator.pop(context, user) : null,
              onLongPress: () => showChatPlayerActions(context, user),
            ),
        ],
      );
    }

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
            child: SizedBox(
              height: 32,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      shown.isEmpty ? 'Friends' : 'Friends - $online online',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  if (_tab.index >= 3)
                    PopupMenuButton<String>(
                      tooltip: 'Sort by',
                      initialValue: sort,
                      onSelected: (value) => setState(() => NativeChat.prefs.setFriendsSort(value)),
                      itemBuilder: (_) => [
                        for (final (value, label, icon) in _sorts)
                          PopupMenuItem(
                            value: value,
                            child: Row(
                              children: [
                                SizedBox(width: 18, child: Center(child: icon)),
                                const SizedBox(width: 12),
                                Text(label),
                              ],
                            ),
                          ),
                      ],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.swap_vert_rounded, size: 18, color: theme.colorScheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              _sorts.firstWhere((s) => s.$1 == sort, orElse: () => _sorts.first).$2,
                              style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          TabBar(
            controller: _tab,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelPadding: const EdgeInsets.symmetric(horizontal: 14),
            tabs: const [
              Tab(text: 'Torn', height: 40),
              Tab(text: 'Torn PDA', height: 40),
              Tab(text: 'Chat', height: 40),
              Tab(text: 'Faction', height: 40),
              Tab(text: 'Company', height: 40),
            ],
          ),
          SizedBox(
            height: 2,
            child: (_tab.index == 0 ? chat.loadingFriends : _asking == _tab.index)
                ? const LinearProgressIndicator()
                : null,
          ),
          Expanded(
            child: TabBarView(controller: _tab, children: [for (var i = 0; i < _tabs.length; i++) list(i)]),
          ),
        ],
      ),
    );
  }

  Widget _pill(ChatPlayerStatus status, DateTime now, ThemeData theme) {
    final (MaterialColor base, IconData icon) = switch (status.state) {
      'Okay' => (Colors.green, Icons.check_rounded),
      'Hospital' => (Colors.red, Icons.local_hospital_rounded),
      'Jail' => (Colors.brown, Icons.lock_rounded),
      'Traveling' => (Colors.blue, Icons.flight_rounded),
      'Abroad' => (Colors.blue, Icons.location_city_rounded),
      'Federal' => (Colors.blueGrey, Icons.gavel_rounded),
      _ => (Colors.grey, Icons.help_outline_rounded),
    };
    final dark = theme.brightness == Brightness.dark;
    final tone = dark ? base.shade300 : base.shade700;
    final turns = switch (getTravelDirection(description: status.description)) {
      TravelDirection.outbound => 1,
      TravelDirection.returning => 3,
      TravelDirection.none => 0,
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 2, 8, 2),
      decoration: BoxDecoration(
        color: base.withValues(alpha: dark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RotatedBox(
            quarterTurns: turns,
            child: Icon(icon, size: 13, color: tone),
          ),
          const SizedBox(width: 4),
          Text(
            status.label(now),
            style: theme.textTheme.labelSmall?.copyWith(color: tone, fontWeight: FontWeight.normal),
          ),
        ],
      ),
    );
  }
}
