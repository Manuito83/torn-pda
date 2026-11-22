import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/territory_map/faction_targets.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/territory_map_controller.dart';
import 'package:torn_pda/utils/number_formatter.dart';
import 'package:torn_pda/utils/time_formatter.dart';
import 'package:torn_pda/widgets/territory_map/map_sheet.dart';

const _shownFirst = 8;

class MyFactionTargetsSection extends StatefulWidget {
  const MyFactionTargetsSection({super.key, required this.factionId});

  final int factionId;

  @override
  State<MyFactionTargetsSection> createState() => _MyFactionTargetsSectionState();
}

class _MyFactionTargetsSectionState extends State<MyFactionTargetsSection> {
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TerritoryMapController>();
    final settings = context.watch<SettingsProvider>();
    final state = controller.state;
    final territories = controller.territories?.territories;
    if (state == null || territories == null) return const SizedBox.shrink();
    final targets = factionTargets(widget.factionId, state, territories, DateTime.now().toUtc());
    if (targets.isEmpty) return const SizedBox.shrink();

    String opens(FactionTarget target) {
      final until = target.lockedUntil;
      if (until == null) return 'open now';
      final time = TimeFormatter(
        inputTime: until,
        timeFormatSetting: settings.currentTimeFormat,
        timeZoneSetting: settings.currentTimeZone,
      );
      return 'opens ${time.formatHour} ${time.formatDayWeek}';
    }

    return SheetSection(
      'Targets',
      children: [
        for (final target in _all ? targets : targets.take(_shownFirst))
          InkWell(
            onTap: () => controller.focusTerritory(target.code),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${target.code} - ${target.ownerId == 0 ? 'No owner' : factionLabel(state, target.ownerId)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(opens(target), style: TextStyle(color: target.isOpen ? Colors.green : Colors.orange[800])),
                    ],
                  ),
                  Text(
                    [
                      '${territories[target.code]?.slots} slots',
                      '${target.respect} respect/day',
                      if (target.racketValue case final money?) '\$${formatBigNumbers(money)}/day',
                    ].join(' - '),
                  ),
                ],
              ),
            ),
          ),
        if (!_all && targets.length > _shownFirst)
          TextButton(onPressed: () => setState(() => _all = true), child: Text('Show all ${targets.length}')),
      ],
    );
  }
}
