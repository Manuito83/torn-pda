import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/territory_map/alert_subscriptions.dart';
import 'package:torn_pda/models/territory_map/map_economy.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';
import 'package:torn_pda/providers/territory_history_controller.dart';
import 'package:torn_pda/providers/territory_map_controller.dart';
import 'package:torn_pda/utils/number_formatter.dart';
import 'package:torn_pda/widgets/territory_map/faction_history_section.dart';
import 'package:torn_pda/widgets/territory_map/faction_recent_section.dart';
import 'package:torn_pda/widgets/territory_map/map_sheet.dart';
import 'package:torn_pda/widgets/territory_map/my_faction_targets_section.dart';
import 'package:torn_pda/widgets/territory_map/watch_button.dart';

class FactionSheet extends StatelessWidget {
  const FactionSheet({super.key, required this.factionId});

  final int factionId;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TerritoryMapController>();
    final state = controller.state;
    final dayName = context.select<TerritoryHistoryController, MapFaction?>((h) => h.factionNames[factionId]);
    final faction = state?.factions[factionId];
    final codes = controller.owned[factionId] ?? const <String>[];
    final wars = [
      ...?state?.wars.where((w) => w.aggressor.factionId == factionId || w.defender.factionId == factionId),
    ];
    final rackets = [...?state?.rackets.values.where((r) => r.factionId == factionId)];
    final file = controller.territories;
    final borders = [...?controller.borders[factionId]]
      ..sort((a, b) => (controller.owned[b]?.length ?? 0).compareTo(controller.owned[a]?.length ?? 0));
    final income = state == null || file == null || codes.isEmpty
        ? null
        : factionIncome(factionId, state, file.territories);

    return MapSheet(
      title: Text(
        factionLabel(state, factionId, names: {factionId: ?dayName}),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      url: 'https://www.torn.com/factions.php?step=profile&ID=$factionId',
      onClose: () => controller.showFaction(null),
      children: [
        Text(
          [
            if (faction?.respect != null) 'Respect ${formatBigNumbers(faction!.respect!)}',
            if (faction?.members != null) '${faction!.members} members',
            territoryCount(codes.length),
          ].join(' - '),
        ),
        if (income != null)
          Text(
            'Rackets: \$${formatBigNumbers(income.money)}/day - '
            'Respect: ${NumberFormat('#,##0', 'en_US').format(income.respect)}/day',
          ),
        if (factionId != 0) WatchButton(target: AlertTarget.faction(factionId)),
        if (codes.isNotEmpty) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.center_focus_strong),
              label: const Text('Show on map'),
              onPressed: () => controller.focusFaction(factionId),
            ),
          ),
          SheetSection(
            'Territories',
            children: [
              mapChips([for (final code in codes) (code, () => controller.focusTerritory(code))]),
            ],
          ),
        ],
        if (factionId != 0 && factionId == controller.myFactionId) MyFactionTargetsSection(factionId: factionId),
        if (wars.isNotEmpty)
          SheetSection(
            'Assaults',
            children: [
              for (final war in wars)
                InkWell(
                  onTap: () => controller
                    ..focusTerritory(war.territory)
                    ..showWar(war.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text(
                      war.aggressor.factionId == factionId
                          ? 'Attacking ${war.territory} (${factionLabel(state, war.defender.factionId)})'
                          : 'Defending ${war.territory} from ${factionLabel(state, war.aggressor.factionId)}',
                    ),
                  ),
                ),
            ],
          ),
        if (rackets.isNotEmpty)
          SheetSection(
            'Rackets',
            children: [
              for (final racket in rackets)
                InkWell(
                  onTap: () => controller.focusTerritory(racket.territory),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text('${racket.territory}: ${racket.name} (level ${racket.level})'),
                  ),
                ),
            ],
          ),
        if (borders.isNotEmpty)
          SheetSection(
            'Borders',
            children: [
              mapChips([
                for (final other in borders)
                  (factionTag(state, other), () => controller.showFaction(other)),
              ]),
            ],
          ),
        if (factionId != 0) FactionRecentSection(key: ValueKey(factionId), factionId: factionId),
        if (factionId != 0) FactionHistorySection(key: ValueKey(('history', factionId)), factionId: factionId),
      ],
    );
  }
}
