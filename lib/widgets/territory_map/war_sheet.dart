import 'package:collection/collection.dart';
import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chat/chat_faction_ops.dart';
import 'package:torn_pda/models/territory_map/assault_math.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';
import 'package:torn_pda/models/territory_map/war_file.dart';
import 'package:torn_pda/models/territory_map/war_progress.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/territory_map_controller.dart';
import 'package:torn_pda/providers/territory_wars_controller.dart';
import 'package:torn_pda/utils/time_formatter.dart';
import 'package:torn_pda/utils/timestamp_ago.dart';
import 'package:torn_pda/widgets/territory_map/map_load_note.dart';
import 'package:torn_pda/widgets/territory_map/map_sheet.dart';
import 'package:torn_pda/widgets/territory_map/war_chart.dart';

final _points = NumberFormat('#,##0', 'en_US');

class WarProgressLines extends StatelessWidget {
  const WarProgressLines({super.key, required this.war});

  final TerritoryWar war;

  @override
  Widget build(BuildContext context) {
    final progress = warProgressAt(war, DateTime.now().toUtc());
    final perMinute = pace(war.aggressor.wall, war.defender.wall);
    final left = chatSpan(progress.remaining);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.score / war.target,
            minHeight: 8,
            color: Colors.red,
            backgroundColor: Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${_points.format(progress.score)} / ${_points.format(war.target)}'
          '${perMinute > 0
              ? ' - +$perMinute/min'
              : perMinute < 0 && progress.score > 0
              ? ' - falling ${-perMinute}/min'
              : ''}',
        ),
        Text('${war.aggressor.wall} vs ${war.defender.wall} on the wall'),
        Text(
          progress.remaining == Duration.zero
              ? 'Ending now'
              : progress.reachesTarget
              ? 'Attackers win in $left at this pace'
              : 'Defenders win in $left unless the target is reached',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class WarSheet extends StatefulWidget {
  const WarSheet({super.key, required this.warId});

  final int warId;

  @override
  State<WarSheet> createState() => _WarSheetState();
}

class _WarSheetState extends State<WarSheet> {
  late final TerritoryWarsController _wars;

  @override
  void initState() {
    super.initState();
    _wars = context.read<TerritoryWarsController>()..open(widget.warId);
  }

  @override
  void dispose() {
    _wars.close(widget.warId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TerritoryMapController>();
    final wars = context.watch<TerritoryWarsController>();
    final settings = context.watch<SettingsProvider>();
    final id = widget.warId;
    final state = controller.state;
    final live = state?.wars.firstWhereOrNull((w) => w.id == id);
    final recent = state?.recentWars.firstWhereOrNull((w) => w.id == id);
    final file = wars.warFile(id);
    final code = live?.territory ?? recent?.territory ?? file?.territory ?? '';
    final aggressor = live?.aggressor.factionId ?? recent?.aggressorId ?? file?.aggressorId;
    final defender = live?.defender.factionId ?? recent?.defenderId ?? file?.defenderId;
    final start = live?.start ?? recent?.start ?? file?.start;
    final target = live?.target ?? recent?.target ?? file?.target;
    final endedAt = warEndedAt(file, recent);
    final result = live != null ? WarResult.inProgress : recent?.result ?? file?.result ?? WarResult.unknown;
    final now = DateTime.now().toUtc();
    final samples = warChartSamples(file, live, recent);
    final paceHour = live == null ? null : paceLastHour(samples, live.scoreAt);

    Widget faction(int factionId) => InkWell(
      onTap: () => controller.showFaction(factionId),
      child: Text(factionLabel(state, factionId), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
    );

    String clock(DateTime at) =>
        TimeFormatter(
          inputTime: at,
          timeFormatSetting: settings.currentTimeFormat,
          timeZoneSetting: settings.currentTimeZone,
        ).formatHour ??
        '';

    final Widget chart;
    if (start != null && target != null && samples.length >= 2) {
      chart = WarChart(start: start, target: target, samples: samples);
    } else if (wars.isLoading(id) || wars.hasFailed(id)) {
      chart = MapLoadNote(
        loading: wars.isLoading(id),
        error: wars.hasFailed(id) ? "Couldn't load the history" : null,
        onRetry: () => wars.retry(id),
      );
    } else {
      chart = Text(wars.isMissing(id) ? 'History not published yet' : 'No samples yet');
    }

    return MapSheet(
      title: Text('Assault on $code', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      url: 'https://www.torn.com/city.php#terrName=$code',
      onClose: () => controller.showWar(null),
      children: [
        if (aggressor != null && defender != null)
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [faction(aggressor), const Text('  →  '), faction(defender)],
          ),
        if (live != null) ...[
          WarProgressLines(war: live),
          if (paceHour != null) Text('Pace last hour: ${paceHour >= 0 ? '+' : ''}${paceHour.round()}/min'),
          if (live.aggressor.ratePerMinute != 0)
            Text('Measured ${live.aggressor.ratePerMinute.round()}/min last 10 min'),
          if (isStalled(live, now))
            Text(
              warStalledText(live, now, clock),
              style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.w600),
            ),
        ] else
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '${warResultText(result, code)}'
              '${endedAt == null ? '' : ', ${readTimestamp(endedAt.millisecondsSinceEpoch ~/ 1000)}'}'
              '${endedAt == null || start == null ? '' : ' after ${chatSpan(endedAt.difference(start))}'}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        SheetSection('Score and walls', children: [chart]),
        if (live == null && file != null)
          SheetSection(
            "Torn's report",
            children: [
              if (file.report case final report?) ...[
                Text('Attackers: ${warReportText(report.aggressor)}'),
                Text('Defenders: ${warReportText(report.defender)}'),
              ] else
                Text(wars.isFinal(id) ? "Torn didn't publish one" : 'Not in yet'),
            ],
          ),
      ],
    );
  }
}
