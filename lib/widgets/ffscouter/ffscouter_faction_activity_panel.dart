import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:torn_pda/models/chaining/ffscouter/ffscouter_activity_model.dart';
import 'package:torn_pda/models/faction/faction_model.dart';
import 'package:torn_pda/providers/ffscouter_activity_controller.dart';
import 'package:torn_pda/providers/ffscouter_premium_controller.dart';
import 'package:torn_pda/providers/war_controller.dart';
import 'package:torn_pda/utils/number_formatter.dart';
import 'package:torn_pda/utils/user_helper.dart';
import 'package:torn_pda/widgets/ffscouter/ffscouter_activity_badge.dart';

/// Collapsible war-page panel: per enemy faction, a 24h activity heatmap (TCT)
/// and the most-active members. Premium only
class FFScouterFactionActivityPanel extends StatelessWidget {
  const FFScouterFactionActivityPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<WarController>(
      builder: (w) => GetBuilder<FFScouterPremiumController>(
        builder: (premium) {
          if (!premium.isPremium || !premium.activityEnabled) return const SizedBox.shrink();
          // Respect the faction filter: only show factions not hidden in the main list
          final factions = w.factions.where((f) => !(f.hidden ?? false)).toList();
          if (factions.isEmpty) return const SizedBox.shrink();
          return Material(
            type: MaterialType.transparency,
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: const Icon(Icons.access_time, size: 20),
                title: const Text("Enemy activity", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                children: [
                  const _Legend(),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          for (final f in factions) _FactionActivityCard(key: ValueKey(f.id), faction: f),
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Text("Provided by FFScouter", style: TextStyle(fontSize: 9, color: Colors.grey)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Likely online right now (from their usual daily pattern)",
            style: TextStyle(fontSize: 9, color: Colors.grey[600], fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 3),
          Wrap(
            spacing: 12,
            runSpacing: 2,
            children: [
              _item(Icons.bar_chart_rounded, Colors.green, "rarely"),
              _item(Icons.bar_chart_rounded, Colors.orange, "sometimes"),
              _item(Icons.bar_chart_rounded, Colors.red, "usually"),
              _item(Icons.local_fire_department, Colors.red, "usually + strong"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _item(IconData icon, Color c, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: c),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 9, color: Colors.grey[600])),
      ],
    );
  }
}

class _FactionActivityCard extends StatefulWidget {
  final FactionModel faction;
  const _FactionActivityCard({super.key, required this.faction});

  @override
  State<_FactionActivityCard> createState() => _FactionActivityCardState();
}

class _FactionActivityCardState extends State<_FactionActivityCard> {
  FFScouterActivityPattern? _pattern;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = widget.faction.id;
    if (id == null) {
      setState(() => _loaded = true);
      return;
    }
    final p = await Get.find<FFScouterActivityController>().factionPattern(id);
    if (!mounted) return;
    setState(() {
      _pattern = p;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = _pattern;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.faction.name ?? "Faction ${widget.faction.id}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          if (!_loaded)
            const SizedBox(
              height: 18,
              child: Center(child: SizedBox(height: 12, width: 12, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else if (p == null || !p.hasData)
            Text("No activity data", style: TextStyle(fontSize: 11, color: Colors.grey[600]))
          else
            _Heatmap(hourly: p.hourly()),
          _MostActive(faction: widget.faction),
        ],
      ),
    );
  }
}

/// 24-cell hour-of-day strip (TCT), cell colour by intensity, current hour outlined
class _Heatmap extends StatelessWidget {
  final List<double> hourly;
  const _Heatmap({required this.hourly});

  @override
  Widget build(BuildContext context) {
    final nowHour = DateTime.now().toUtc().hour;
    final minV = hourly.reduce((a, b) => a < b ? a : b);
    final maxV = hourly.reduce((a, b) => a > b ? a : b);
    final range = maxV - minV;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(24, (h) {
            // min-max stretch + gamma so even a flat-ish big faction pops
            final stretched = range <= 0 ? 0.0 : ((hourly[h] - minV) / range).clamp(0.0, 1.0);
            final norm = math.pow(stretched, 1.5).toDouble();
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0.5),
                child: Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: Color.lerp(Colors.indigo.withValues(alpha: 0.08), Colors.indigo, norm),
                    borderRadius: BorderRadius.circular(2),
                    border: h == nowHour ? Border.all(color: Colors.orange, width: 1.5) : null,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("00", style: TextStyle(fontSize: 9, color: Colors.grey[600])),
            Text("06", style: TextStyle(fontSize: 9, color: Colors.grey[600])),
            Text("12", style: TextStyle(fontSize: 9, color: Colors.grey[600])),
            Text("18", style: TextStyle(fontSize: 9, color: Colors.grey[600])),
            Text("23 TCT", style: TextStyle(fontSize: 9, color: Colors.grey[600])),
          ],
        ),
      ],
    );
  }
}

/// Faction members ranked by FFScouter activity (most online first), with a
/// strength chip (their stats vs yours). Only the strongest few are queried,
/// then re-ranked by activity, to keep the number of premium calls small
class _MostActive extends StatefulWidget {
  final FactionModel faction;
  const _MostActive({required this.faction});

  @override
  State<_MostActive> createState() => _MostActiveState();
}

class _MostActiveState extends State<_MostActive> {
  List<_RankedMember>? _ranked;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final w = Get.find<WarController>();
    final activity = Get.find<FFScouterActivityController>();
    final members =
        (widget.faction.members?.values.whereType<Member>().toList() ?? [])
            .where((m) => (m.memberId ?? 0) > 0 && w.getMemberTotalStatsWithFFS(m) > 0)
            .toList()
          ..sort((a, b) => w.getMemberTotalStatsWithFFS(b).compareTo(w.getMemberTotalStatsWithFFS(a)));
    final candidates = members.take(15).toList();

    final results = <_RankedMember>[];
    await Future.wait(
      candidates.map((m) async {
        final p = await activity.playerPattern(m.memberId!);
        results.add(_RankedMember(m, p?.overallActivity ?? 0));
      }),
    );
    if (!mounted) return;
    results.sort((a, b) => b.activity.compareTo(a.activity));
    setState(() => _ranked = results.where((r) => r.activity > 0).take(8).toList());
  }

  @override
  Widget build(BuildContext context) {
    final ranked = _ranked;
    if (ranked == null) {
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (ranked.isEmpty) return const SizedBox.shrink();
    final w = Get.find<WarController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          "Most active",
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[600]),
        ),
        for (final r in ranked)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Row(
              children: [
                FFScouterActivityBadge(
                  playerId: r.member.memberId!,
                  playerName: r.member.name,
                  isTopHitter: w.getMemberTotalStatsWithFFS(r.member) > UserHelper.totalStats,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    r.member.name ?? "${r.member.memberId}",
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _strengthChip(w.getMemberTotalStatsWithFFS(r.member)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _strengthChip(double stats) {
    final u = UserHelper.totalStats.toDouble();
    Color c;
    if (u <= 0) {
      c = Colors.grey;
    } else if (stats > u * 1.1) {
      c = Colors.red;
    } else if (stats < u * 0.9) {
      c = Colors.green;
    } else {
      c = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: c.withValues(alpha: 0.5)),
      ),
      child: Text(
        formatBigNumbers(stats.round()),
        style: TextStyle(fontSize: 10, color: c, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _RankedMember {
  final Member member;
  final double activity;
  _RankedMember(this.member, this.activity);
}
