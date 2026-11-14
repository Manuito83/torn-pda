import 'dart:async';

import 'package:flutter/material.dart';
import 'package:torn_pda/models/chat/chat_chain_report.dart';
import 'package:torn_pda/models/chat/chat_faction_ops.dart';
import 'package:torn_pda/models/chat/chat_money.dart';
import 'package:torn_pda/providers/chat/chat_faction_roster.dart';
import 'package:torn_pda/widgets/chat/chat_chain_sheets.dart';
import 'package:torn_pda/widgets/chat/chat_faction_ops_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_link_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_player_card_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_theme.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

String _hitsText(int n) => n == 1 ? '1 hit' : '${chatCount(n)} hits';

void _openProfile(BuildContext context, int id) {
  Navigator.of(context).pop();
  NativeChat.openLink(chatPlayerUrl('profile', id)!, always: true);
}

class _Section extends StatelessWidget {
  const _Section({required this.title, this.sum, required this.child, this.fullWidth = false});

  final String title;
  final String? sum;
  final Widget child;

  /// Rows that paint edge to edge
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final side = fullWidth ? 0.0 : 20.0;
    return DecoratedBox(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: theme.dividerColor))),
      child: Padding(
        padding: EdgeInsets.fromLTRB(side, 12, side, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20 - side),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
                  if (sum != null)
                    Text(
                      sum!,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class ChatChainReportSection extends StatelessWidget {
  const ChatChainReportSection({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ChatReportView?>(
    valueListenable: NativeChat.factionOps.chainReport,
    builder: (context, view, _) => view?.report != null
        ? ChatChainReportBody(report: view!.report!)
        : _ReportWaiting(view: view ?? const ChatReportView(ChatReportStatus.waiting)),
  );
}

class _ReportWaiting extends StatelessWidget {
  const _ReportWaiting({required this.view});

  final ChatReportView view;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final failed = view.status == ChatReportStatus.failed;
    final next = view.next;
    final muted = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return _Section(
      title: 'Chain report',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!failed) ...[
            LinearProgressIndicator(
              value: MediaQuery.disableAnimationsOf(context) ? 0.5 : null,
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        failed ? "Couldn't load the report" : 'Report not ready yet',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: failed ? chatChainColor(context, ChatChainLevel.danger) : null,
                        ),
                      ),
                      if (failed && view.reason != null)
                        Text(view.reason!, maxLines: 2, overflow: TextOverflow.ellipsis, style: muted),
                    ],
                  ),
                ),
              ),
              ChatTicking(
                until: next,
                builder: (context) {
                  if (view.checking) return Text('Checking', style: muted);
                  if (next == null) return const SizedBox.shrink();
                  final left = chatClock(next.difference(DateTime.now()));
                  return Text(failed ? 'Retry in $left' : 'Next check $left', style: muted);
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ChatTicking(
              until: view.askedAt?.add(chatReportCheckGap),
              builder: (context) {
                final asked = view.askedAt;
                final soon = asked != null && DateTime.now().difference(asked) < chatReportCheckGap;
                return OutlinedButton(
                  style: chatSecondaryButton(theme.colorScheme),
                  onPressed: view.checking || soon ? null : () => NativeChat.factionOps.checkChainReport(),
                  child: Text(failed ? 'Retry' : 'Check now'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ChatChainReportBody extends StatefulWidget {
  const ChatChainReportBody({super.key, required this.report});

  final ChatChainReport report;

  @override
  State<ChatChainReportBody> createState() => _ChatChainReportBodyState();
}

class _ChatChainReportBodyState extends State<ChatChainReportBody> {
  bool _nonAttackersOpen = false;
  ChatAttackerSort _sort = ChatAttackerSort.hits;
  bool _descending = true;

  void _sortBy(ChatAttackerSort by) => setState(() {
    _descending = by == _sort ? !_descending : true;
    _sort = by;
  });

  Widget _sortHeader(ThemeData theme) {
    final scheme = theme.colorScheme;
    const labels = {
      ChatAttackerSort.hits: 'Hits',
      ChatAttackerSort.respect: 'Respect',
      ChatAttackerSort.average: 'Avg',
      ChatAttackerSort.best: 'Best',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Wrap(
        children: [
          for (final MapEntry(key: by, value: label) in labels.entries)
            Semantics(
              button: true,
              selected: by == _sort,
              label: by == _sort
                  ? 'Sort by $label, sorted ${_descending ? 'high to low' : 'low to high'}, tap to reverse'
                  : 'Sort by $label',
              excludeSemantics: true,
              onTap: () => _sortBy(by),
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => _sortBy(by),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: by == _sort ? scheme.primary : scheme.onSurfaceVariant,
                          fontWeight: by == _sort ? FontWeight.w700 : null,
                        ),
                      ),
                      if (by == _sort)
                        Icon(
                          _descending ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                          size: 14,
                          color: scheme.primary,
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (ChatFactionRoster.shared.members.isEmpty) unawaited(ChatFactionRoster.shared.refresh());
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: ChatFactionRoster.shared,
    builder: (context, _) => _build(context),
  );

  Widget _build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant;
    final small = theme.textTheme.bodySmall?.copyWith(color: muted);
    final tint = scheme.primary.withValues(alpha: 0.14);
    final bad = chatChainColor(context, ChatChainLevel.danger);
    final report = widget.report;
    final me = NativeChat.controller.myUserId;
    final roster = {for (final m in ChatFactionRoster.shared.members) m.id: m.name};
    String nameOf(int id) => id == me ? 'You' : NativeChat.prefs.displayName(id, roster[id] ?? '$id');

    final attackers = report.attackers;
    final rank = attackers.indexWhere((a) => a.id == me);
    final you = rank < 0 ? null : attackers[rank];
    final members = attackers.length + report.nonAttackers.length;
    final top = attackers.isEmpty ? 0.0 : attackers.first.respect;
    final bonusTotal = report.bonuses.fold<double>(0, (sum, b) => sum + b.respect);

    Widget tile(String value, String label, String strong) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, maxLines: 1, style: chatBigStyle(theme)),
          ),
          Text.rich(
            TextSpan(
              text: label,
              children: [TextSpan(text: strong, style: TextStyle(color: scheme.onSurface))],
            ),
            style: small,
          ),
        ],
      ),
    );

    final hits = report.hits;
    final dark = theme.brightness == Brightness.dark;
    final kinds = [
      ('Leave', hits.leave, dark ? Colors.lightBlue[300]! : Colors.lightBlue[700]!),
      ('Mug', hits.mug, dark ? Colors.orange[300]! : Colors.orange[800]!),
      ('Hospitalize', hits.hospitalize, dark ? Colors.pink[200]! : Colors.pink[600]!),
    ];
    Widget counts(List<(String, int)> list) => Text.rich(
      TextSpan(
        children: [
          for (final (i, (label, n)) in list.indexed) ...[
            if (i > 0) const TextSpan(text: ' - '),
            TextSpan(
              text: '$label ${chatCount(n)}',
              style: n == 0 ? TextStyle(color: muted) : null,
            ),
          ],
        ],
      ),
      style: theme.textTheme.bodyMedium,
    );

    final nonAttackers = [for (final id in report.nonAttackers) nameOf(id)]
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Section(
          title: 'Chain report',
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              tile(chatRespect(report.respect), 'respect', ''),
              tile(chatCount(attackers.length), 'attacked ', 'of ${chatCount(members)}'),
              tile(you == null ? '0' : chatRespect(you.respect), 'you', ''),
            ],
          ),
        ),
        Container(
          color: tint,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'You  ', style: TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(
                  text: you == null
                      ? "Didn't attack"
                      : [
                          '#${rank + 1} of ${attackers.length} by respect',
                          _hitsText(you.hits.won),
                          if (you.hits.bonuses > 0) '${you.hits.bonuses} bonus',
                          'avg ${chatRespect(you.average)}',
                        ].join(' - '),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (report.bonuses.isNotEmpty)
          _Section(
            title: 'Bonuses',
            sum: '${report.bonuses.length} - ${chatRespect(bonusTotal)}',
            child: Column(
              children: [
                for (final b in report.bonuses)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 60,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              chatCount(b.chain),
                              maxLines: 1,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  nameOf(b.attackerId),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: b.attackerId == me ? const TextStyle(fontWeight: FontWeight.w700) : null,
                                ),
                              ),
                              Semantics(
                                link: true,
                                label: 'against ${b.defenderId}, open profile',
                                excludeSemantics: true,
                                child: InkWell(
                                  onTap: () => _openProfile(context, b.defenderId),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                    child: Text(
                                      'vs ${b.defenderId}',
                                      style: small?.copyWith(
                                        color: scheme.primary,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(chatRespect(b.respect)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        _Section(
          title: 'Hits by type',
          sum: chatCount(hits.won),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hits.won > 0)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 8,
                    child: Row(
                      spacing: 2,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final (_, n, color) in kinds)
                          if (n > 0) Expanded(flex: n, child: ColoredBox(color: color)),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 4,
                children: [
                  for (final (i, (label, n, color)) in kinds.indexed)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (i > 0) const Text('- '),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
                        ),
                        const SizedBox(width: 6),
                        Text('$label ${chatCount(n)}'),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 4),
              counts([
                ('Retaliations', hits.retaliations),
                ('Overseas', hits.overseas),
                ('War', hits.war),
                ('Assists', hits.assists),
              ]),
              const SizedBox(height: 4),
              counts([('Losses', hits.losses), ('Draws', hits.draws), ('Escapes', hits.escapes)]),
              const SizedBox(height: 4),
              Text('Targets ${chatCount(report.targets)} - Best hit ${chatRespect(report.best)}'),
            ],
          ),
        ),
        _Section(
          title: 'Attackers',
          sum: '${attackers.length} - ${chatRespect(report.respect)}',
          fullWidth: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sortHeader(theme),
              for (final (i, a) in sortAttackers(attackers, _sort, _descending).indexed)
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
                  color: a.id == me ? tint : null,
                  child: MergeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 26,
                              child: Text('${i + 1}', textAlign: TextAlign.right, style: small),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                nameOf(a.id),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontWeight: a.id == me ? FontWeight.w700 : FontWeight.w500),
                              ),
                            ),
                            Text(
                              chatRespect(a.respect),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 34, top: 2),
                          child: Row(
                            children: [
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: FractionallySizedBox(
                                    widthFactor: top > 0 ? (a.respect / top).clamp(0.01, 1.0) : 0.01,
                                    child: Container(
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: a.id == me ? scheme.primary : muted.withValues(alpha: 0.4),
                                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(3)),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(_hitsText(a.hits.won), style: small),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 34, top: 2),
                          child: Text.rich(
                            TextSpan(
                              children: [
                                for (final (j, (text, failed)) in chatChainBreakdown(a).indexed) ...[
                                  if (j > 0) const TextSpan(text: ' - '),
                                  TextSpan(text: text, style: failed ? TextStyle(color: bad) : null),
                                ],
                              ],
                            ),
                            style: small,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (nonAttackers.isNotEmpty)
          DecoratedBox(
            decoration: BoxDecoration(border: Border(top: BorderSide(color: theme.dividerColor))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  onTap: () => setState(() => _nonAttackersOpen = !_nonAttackersOpen),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
                    child: Semantics(
                      expanded: _nonAttackersOpen,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text("${chatCount(nonAttackers.length)} didn't attack", style: theme.textTheme.titleMedium),
                          ),
                          AnimatedRotation(
                            turns: _nonAttackersOpen ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(Icons.expand_more_rounded, color: muted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_nonAttackersOpen)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                    child: Text(nonAttackers.join(' - '), style: small?.copyWith(height: 1.6)),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
