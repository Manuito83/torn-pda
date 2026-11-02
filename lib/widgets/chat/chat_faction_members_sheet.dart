import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/api_v2/torn_v2.swagger.dart';
import 'package:torn_pda/models/chat/chat_faction_roster.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_status.dart';
import 'package:torn_pda/providers/chat/chat_faction_roster.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/country_check.dart';
import 'package:torn_pda/widgets/chat/chat_link_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

typedef _Look = ({Color border, Color active, Color idle, Color fg});

const _sorts = {
  'status': ('Status', 'Status', Icons.monitor_heart_outlined),
  'hospital': ('Leaves hospital first', 'Hospital', Icons.local_hospital_outlined),
  'action': ('Last action', 'Action', Icons.schedule_rounded),
  'level': ('Level', 'Level', Icons.trending_up_rounded),
  'position': ('Position', 'Position', Icons.badge_outlined),
  'days': ('Days in faction', 'Days', Icons.event_outlined),
  'name': ('Name', 'Name', Icons.sort_by_alpha_rounded),
};

class ChatFactionMembersSheet extends StatefulWidget {
  const ChatFactionMembersSheet({super.key, required this.roster, required this.prefs});

  final ChatFactionRoster roster;
  final ChatPrefs prefs;

  @override
  State<ChatFactionMembersSheet> createState() => _ChatFactionMembersSheetState();
}

class _ChatFactionMembersSheetState extends State<ChatFactionMembersSheet> {
  final _search = TextEditingController();
  late final Timer _tick;

  ChatPrefs get _prefs => widget.prefs;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.roster.refresh());
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      widget.roster.keepFresh();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick.cancel();
    _search.dispose();
    super.dispose();
  }

  void _toggle(String group, String value) {
    final next = {..._prefs.rosterFilters};
    if (next[group] == value) {
      next.remove(group);
    } else {
      next[group] = value;
    }
    setState(() => _prefs.setRosterFilters(next));
  }

  void _clear() {
    _search.clear();
    setState(() => _prefs.setRosterFilters({}));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: SizedBox(
        height: math.min(size.height * 0.8, size.height - inset - MediaQuery.paddingOf(context).top - 72),
        child: ListenableBuilder(listenable: widget.roster, builder: (context, _) => _sheet(context)),
      ),
    );
  }

  Widget _sheet(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final all = widget.roster.members;
    final filters = _prefs.rosterFilters;
    final filtered = filters.isNotEmpty || _search.text.trim().isNotEmpty;
    final shown = chatRosterSorted(
      [
        for (final m in all)
          if (chatRosterMatches(m, filters, _search.text)) m,
      ],
      _prefs.rosterSort,
      reversed: _prefs.rosterReversed,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(theme, filtered ? '${shown.length}/${all.length} members' : '${all.length} members'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: SizedBox(
            height: 40,
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                hintText: 'Search name or ID',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: _search.clear,
                      ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 8, 0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              children: [
                Expanded(child: _counters(all)),
                if (filtered) TextButton(onPressed: _clear, child: const Text('Clear filters')),
              ],
            ),
          ),
        ),
        Padding(padding: const EdgeInsets.fromLTRB(16, 6, 16, 8), child: _toggles(context, all)),
        const Divider(height: 1),
        Expanded(
          child: shown.isEmpty
              ? const ChatStateMessage(icon: Icons.people_outline_rounded, title: 'Nobody to show')
              : ListView.builder(
                  padding: EdgeInsets.only(bottom: MediaQuery.viewPaddingOf(context).bottom),
                  itemCount: shown.length,
                  itemBuilder: (context, i) => _row(context, shown[i], now),
                ),
        ),
      ],
    );
  }

  Widget _header(ThemeData theme, String title) {
    final roster = widget.roster;
    final (_, short, _) = _sorts[_prefs.rosterSort] ?? _sorts['status']!;
    final primary = theme.colorScheme.primary;
    final at = roster.membersAt;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 4, 0),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.fade,
                    style: theme.textTheme.titleMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                ),
                if (at != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${ChatStatus.duration(DateTime.now().difference(at).inSeconds)} ago',
                    maxLines: 1,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: roster.refreshFailed ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Sort by',
            initialValue: _prefs.rosterSort,
            onSelected: (value) => setState(() => _prefs.setRosterSort(value)),
            itemBuilder: (_) => [
              for (final MapEntry(key: value, value: (label, _, icon)) in _sorts.entries)
                PopupMenuItem(
                  value: value,
                  child: Row(children: [Icon(icon, size: 18), const SizedBox(width: 12), Text(label)]),
                ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swap_vert_rounded, size: 18, color: primary),
                  const SizedBox(width: 4),
                  Text(short, style: theme.textTheme.labelLarge?.copyWith(color: primary)),
                ],
              ),
            ),
          ),
          Semantics(
            toggled: _prefs.rosterReversed,
            child: IconButton(
              tooltip: 'Reverse order',
              icon: Icon(_prefs.rosterReversed ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 20),
              onPressed: () => setState(() => _prefs.setRosterReversed(!_prefs.rosterReversed)),
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: roster.refreshing
                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh_rounded, size: 22),
            onPressed: roster.canRefresh ? roster.refresh : null,
          ),
        ],
      ),
    );
  }

  Widget _counters(List<FactionMember> all) {
    final online = all.where((m) => m.lastAction.status == 'Online').length;
    final hospital = all.where((m) => m.status.state == 'Hospital').length;
    final abroad = all.where(chatRosterAway).length;
    Widget chip(String label, String group, String value) => FilterChip(
      label: Text(label),
      labelStyle: Theme.of(context).textTheme.labelMedium,
      selected: _prefs.rosterFilters[group] == value,
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onSelected: (_) => _toggle(group, value),
    );
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        chip('$online online', 'presence', 'online'),
        if (hospital > 0) chip('$hospital in hospital', 'state', 'hospital'),
        if (abroad > 0) chip('$abroad abroad', 'travel', 'away'),
      ],
    );
  }

  Widget _toggles(BuildContext context, List<FactionMember> all) {
    final app =
        context.watch<ThemeProvider?>()?.currentTheme ??
        (Theme.of(context).brightness == Brightness.dark ? AppTheme.dark : AppTheme.light);
    Color tone(MaterialColor color) => switch (app) {
      AppTheme.light => color.shade200,
      AppTheme.dark => color.shade500,
      AppTheme.extraDark => color.shade900,
    };
    final look = (
      border: app == AppTheme.light ? Colors.blueGrey : Colors.grey[900]!,
      active: app == AppTheme.extraDark ? Colors.blueGrey[900]! : Colors.blueGrey,
      idle: switch (app) {
        AppTheme.light => Colors.white,
        AppTheme.dark => Colors.grey[800]!,
        AppTheme.extraDark => Colors.black,
      },
      fg: app == AppTheme.light ? Colors.black : Colors.white,
    );
    Widget dot(Color color) => Icon(Icons.circle, size: 12, color: color);
    final travel = _prefs.rosterFilters['travel'];
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        _group(look, 'presence', [
          ('online', 'Online', dot(Colors.green)),
          ('idle', 'Idle', dot(Colors.amber.shade700)),
          ('offline', 'Offline', ChatPresenceDot(presence: ChatPresence.offline, foreground: look.fg, size: 12)),
        ]),
        _group(look, 'state', [
          ('okay', 'Okay', const Icon(MdiIcons.check, size: 12, color: Colors.green)),
          ('hospital', 'Hospital', const Icon(MdiIcons.hospital, size: 12, color: Colors.red)),
          ('jail', 'Jail', Icon(MdiIcons.handcuffs, size: 12, color: Colors.orange[300])),
        ]),
        _group(look, 'travel', active: tone(travel == 'away' ? Colors.blue : Colors.red), [
          ('away', 'Abroad or traveling', Icon(MdiIcons.airplane, size: 12, color: look.fg)),
          ('home', 'In Torn', Icon(MdiIcons.airplaneOff, size: 12, color: look.fg)),
        ]),
        Builder(builder: (anchor) => _country(anchor, look, all)),
      ],
    );
  }

  Widget _group(_Look look, String group, List<(String, String, Widget)> options, {Color? active}) {
    final on = [for (final (value, _, _) in options) _prefs.rosterFilters[group] == value];
    return _box(look, [
      for (final (i, (value, label, child)) in options.indexed) ...[
        if (i > 0) Container(width: 1, height: 9, color: on[i - 1] || on[i] ? Colors.transparent : Colors.white30),
        _segment(look, on: on[i], label: label, active: active, onTap: () => _toggle(group, value), child: child),
      ],
    ]);
  }

  Widget _box(_Look look, List<Widget> segments) => Container(
    padding: const EdgeInsets.all(1),
    decoration: BoxDecoration(
      color: look.idle,
      border: Border.all(color: look.border),
      borderRadius: BorderRadius.circular(5),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Row(mainAxisSize: MainAxisSize.min, children: segments),
    ),
  );

  Widget _segment(
    _Look look, {
    required bool on,
    required String label,
    required VoidCallback onTap,
    required Widget child,
    Color? active,
  }) => Semantics(
    button: true,
    selected: on,
    label: label,
    excludeSemantics: true,
    onTap: onTap,
    child: Tooltip(
      message: label,
      child: Material(
        color: on ? active ?? look.active : look.idle,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 32, minHeight: 25),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Center(widthFactor: 1, child: child),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _country(BuildContext anchor, _Look look, List<FactionMember> all) {
    final picked = _prefs.rosterFilters['country'];
    return _box(look, [
      _segment(
        look,
        on: picked != null,
        label: picked == null ? 'Country' : 'Country: $picked',
        onTap: () => picked != null ? _toggle('country', picked) : _pickCountry(anchor, all),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(MdiIcons.mapMarker, size: 12, color: look.fg),
            if (picked != null) ...[
              const SizedBox(width: 4),
              Text(
                picked,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: look.fg),
              ),
            ],
          ],
        ),
      ),
    ]);
  }

  Future<void> _pickCountry(BuildContext anchor, List<FactionMember> all) async {
    final counts = <String, int>{};
    for (final m in all) {
      final country = chatRosterCountry(m);
      if (country != 'error') counts[country] = (counts[country] ?? 0) + 1;
    }
    final countries = counts.entries.toList()
      ..sort((a, b) => b.value != a.value ? b.value.compareTo(a.value) : a.key.compareTo(b.key));
    final box = anchor.findRenderObject()! as RenderBox;
    final overlay = Overlay.of(anchor).context.findRenderObject()! as RenderBox;
    final picked = await showMenu<String>(
      context: anchor,
      position: RelativeRect.fromRect(
        box.localToGlobal(Offset.zero, ancestor: overlay) & box.size,
        Offset.zero & overlay.size,
      ),
      items: [
        for (final MapEntry(key: country, value: count) in countries)
          PopupMenuItem(
            value: country,
            child: Row(
              children: [
                if (_flag(country) case final flag?) ...[
                  Image.asset(flag, width: 18, height: 18, excludeFromSemantics: true),
                  const SizedBox(width: 10),
                ],
                Expanded(child: Text(country)),
                const SizedBox(width: 16),
                Text('$count'),
              ],
            ),
          ),
      ],
    );
    if (picked != null && mounted) _toggle('country', picked);
  }

  Widget _row(BuildContext context, FactionMember m, DateTime now) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final user = ChatUser(id: m.id, name: m.name);
    final presence = ChatPresence.parse(m.lastAction.status);
    final ago = ChatLastAction.ago(DateTime.fromMillisecondsSinceEpoch(m.lastAction.timestamp * 1000), now);
    final position = m.position.trim().isEmpty ? null : m.position;
    final leads = chatIsLead(m.position);
    final MaterialColor base = switch (m.status.state) {
      'Okay' => Colors.green,
      'Traveling' || 'Abroad' => Colors.blue,
      'Hospital' || 'Jail' || 'Federal' => Colors.red,
      _ => Colors.grey,
    };
    final marks = ['L${m.level}', chatRosterTenure(m.daysInFaction)];
    final trip = chatRosterTrip(m);
    final flag = trip == null ? null : _flag(trip.$1);
    final tone = dark ? base.shade300 : base.shade700;
    final cause = chatRosterCause(m);
    final byId = cause?.byId;
    final spoken = [
      m.name,
      ?position,
      'level ${m.level}',
      chatRosterStatus(m, now, spoken: true),
      if (cause != null) '${cause.before}${cause.by}${cause.after}',
      if (presence != null) '${presence.name} ${m.lastAction.relative}',
    ].join(', ');
    void open() => showChatPlayerActions(context, user);
    void openBy() {
      Navigator.of(context).pop();
      NativeChat.openLink(chatPlayerUrl('profile', byId!)!, always: true);
    }
    final statusStyle = theme.textTheme.bodySmall?.copyWith(
      color: tone,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Semantics(
      button: true,
      label: spoken,
      excludeSemantics: true,
      onTap: open,
      customSemanticsActions: {
        if (byId != null) CustomSemanticsAction(label: 'Open ${cause!.by} profile'): openBy,
      },
      child: InkWell(
        onTap: open,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ChatAvatar(user: user, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            m.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (position != null) ...[
                          const SizedBox(width: 6),
                          _tag(
                            theme,
                            position,
                            leads ? (dark ? Colors.amber.shade300 : Colors.orange.shade800) : scheme.onSurfaceVariant,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (trip case (_, final direction) when direction != TravelDirection.none) ...[
                          RotatedBox(
                            quarterTurns: direction == TravelDirection.outbound ? 1 : 3,
                            child: Icon(Icons.flight_rounded, size: 14, color: tone),
                          ),
                          const SizedBox(width: 2),
                        ],
                        if (flag != null) ...[
                          Image.asset(flag, width: 14, height: 14, excludeFromSemantics: true),
                          const SizedBox(width: 5),
                        ],
                        Flexible(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: chatRosterStatus(m, now)),
                                if (cause != null) ...[
                                  TextSpan(text: ' - ${cause.before}'),
                                  if (byId != null)
                                    WidgetSpan(
                                      alignment: PlaceholderAlignment.baseline,
                                      baseline: TextBaseline.alphabetic,
                                      child: InkWell(
                                        onTap: openBy,
                                        child: Text(
                                          cause.by,
                                          style: statusStyle?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            decoration: TextDecoration.underline,
                                            decorationColor: tone,
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    TextSpan(text: cause.by),
                                  TextSpan(text: cause.after),
                                ],
                              ],
                            ),
                            style: statusStyle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [for (final mark in marks) _tag(theme, mark, scheme.onSurfaceVariant)],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (presence != null) ChatPresenceDot(presence: presence, foreground: scheme.onSurface),
                  const SizedBox(width: 6),
                  Text(ago ?? 'now', style: theme.textTheme.labelMedium),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _flag(String country) => country == 'Torn' ? 'images/flags/ball/ball_torn.png' : chatCountryFlag(country);

  Widget _tag(ThemeData theme, String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
    decoration: BoxDecoration(
      border: Border.all(color: color.withValues(alpha: 0.6)),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(text, style: theme.textTheme.labelSmall?.copyWith(color: color, letterSpacing: 0.2)),
  );
}
