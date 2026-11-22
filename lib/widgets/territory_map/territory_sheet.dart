import 'package:collection/collection.dart';
import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/territory_map/alert_subscriptions.dart';
import 'package:torn_pda/models/territory_map/map_dates.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';
import 'package:torn_pda/models/territory_map/map_views.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/territory_history_controller.dart';
import 'package:torn_pda/providers/territory_map_controller.dart';
import 'package:torn_pda/utils/timestamp_ago.dart';
import 'package:torn_pda/widgets/territory_map/assault_lock_line.dart';
import 'package:torn_pda/widgets/territory_map/assault_planner_section.dart';
import 'package:torn_pda/widgets/territory_map/map_sheet.dart';
import 'package:torn_pda/widgets/territory_map/territory_economy_section.dart';
import 'package:torn_pda/widgets/territory_map/territory_history_section.dart';
import 'package:torn_pda/widgets/territory_map/territory_view_section.dart';
import 'package:torn_pda/widgets/territory_map/war_sheet.dart';
import 'package:torn_pda/widgets/territory_map/watch_button.dart';

class TerritorySheet extends StatelessWidget {
  const TerritorySheet({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TerritoryMapController>();
    final zone = context.select<SettingsProvider, TimeZoneSetting>((s) => s.currentTimeZone);
    final territory = controller.territories?.territories[code];
    if (territory == null) return const SizedBox.shrink();
    final state = controller.state;
    final ownership = controller.displayOwnership[code];
    final owner = ownership?.factionId ?? 0;
    final ownerNow = state?.ownership[code]?.factionId ?? 0;
    final pastDay = controller.pastDay;
    final war = state?.wars.firstWhereOrNull((w) => w.territory == code);
    final bomb = state?.bombs.firstWhereOrNull((b) => b.territories.contains(code));
    final view = controller.shownView;

    // The assault leads in the war view
    final assault = [
      if (war != null)
        _AssaultSection(war: war, state: state!)
      else if (state?.recentWars.firstWhereOrNull((w) => w.territory == code) case final last?)
        _SeeAssaultButton(warId: last.id, label: 'See the last assault'),
    ];

    return MapSheet(
      title: Text(
        '$code - Sector ${territory.sector}',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      url: 'https://www.torn.com/city.php#terrName=$code',
      onClose: () => controller.select(null),
      children: [
        if (state != null) TerritoryViewSection(territory: territory, state: state),
        if (view == MapView.war) ...assault,
        if (pastDay != null)
          Text(
            'Owner when ${DateFormat('EEE d MMM').format(pastDay)} ended',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        if (owner == 0)
          const Text('No owner')
        else ...[
          InkWell(
            onTap: () => controller.showFaction(owner),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      factionLabel(
                        state,
                        owner,
                        names: pastDay == null ? null : context.read<TerritoryHistoryController>().factionNames,
                      ),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 20),
                ],
              ),
            ),
          ),
          if (ownership?.acquiredAt case final since?)
            Text(
              'Held since ${mapDate(since, zone)} '
              '(${readTimestamp(since.millisecondsSinceEpoch ~/ 1000)})',
            ),
          AssaultLockLine(code: code),
        ],
        if ((ownership?.irradiated ?? false) && view != MapView.irradiated)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              bomb == null
                  ? 'Irradiated'
                  : 'Irradiated by ${factionLabel(state, bomb.factionId)}, '
                        '${readTimestamp(bomb.detonatedAt.millisecondsSinceEpoch ~/ 1000)}',
              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
            ),
          ),
        WatchButton(target: AlertTarget.territory(code)),
        if (view != MapView.war) ...assault,
        TerritoryEconomySection(
          code: code,
          respect: territory.respect,
          state: state,
          showRacket: view != MapView.rackets,
        ),
        if (ownerNow != 0 && state != null)
          AssaultPlannerSection(
            key: ValueKey(code),
            slots: territory.slots,
            owner: ownerNow,
            state: state,
            locked: war == null && controller.locked.contains(code),
            war: war,
          ),
        SheetSection(
          'Neighbors',
          children: [
            mapChips([
              for (final neighbor in territory.neighbors)
                (_neighborLabel(state, neighbor), () => controller.focusTerritory(neighbor)),
            ]),
          ],
        ),
        SheetSection(
          'Territory',
          children: [
            Text('Size ${territory.size} - Density ${territory.density} - Slots ${territory.slots}'),
          ],
        ),
        TerritoryHistorySection(key: ValueKey(('history', code)), code: code),
      ],
    );
  }

  String _neighborLabel(MapState? state, String neighbor) {
    final factionId = state?.ownership[neighbor]?.factionId ?? 0;
    return state?.factions[factionId]?.tag == null ? neighbor : '$neighbor - ${factionTag(state, factionId)}';
  }
}

class _AssaultSection extends StatelessWidget {
  const _AssaultSection({required this.war, required this.state});

  final TerritoryWar war;
  final MapState state;

  @override
  Widget build(BuildContext context) {
    return SheetSection(
      'Assault',
      children: [
        Text('${factionLabel(state, war.aggressor.factionId)} attacking'),
        WarProgressLines(war: war),
        _SeeAssaultButton(warId: war.id, label: 'See the assault'),
      ],
    );
  }
}

class _SeeAssaultButton extends StatelessWidget {
  const _SeeAssaultButton({required this.warId, required this.label});

  final int warId;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      icon: const Icon(Icons.show_chart),
      label: Text(label),
      onPressed: () => context.read<TerritoryMapController>().showWar(warId),
    );
  }
}
