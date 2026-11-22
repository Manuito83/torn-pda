import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/territory_map/map_dates.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';
import 'package:torn_pda/models/territory_map/territory_file.dart';
import 'package:torn_pda/models/territory_map/territory_view_facts.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/territory_history_controller.dart';
import 'package:torn_pda/providers/territory_map_controller.dart';
import 'package:torn_pda/widgets/territory_map/map_sheet.dart';

class TerritoryViewSection extends StatelessWidget {
  const TerritoryViewSection({super.key, required this.territory, required this.state});

  final Territory territory;
  final MapState state;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TerritoryMapController>();
    final zone = context.select<SettingsProvider, TimeZoneSetting>((s) => s.currentTimeZone);
    final history = context.watch<TerritoryHistoryController>();
    final facts = territoryViewFacts(
      controller.shownView,
      territory: territory,
      territories: controller.territories?.territories ?? const {},
      state: state,
      span: controller.activitySpan,
      now: DateTime.now().toUtc(),
      ended: [...state.recentWars, ...?history.record?.wars],
      irradiated: controller.displayOwnership[territory.code]?.irradiated ?? false,
      pastDay: controller.pastDay,
      date: (at) => mapDate(at, zone, pattern: 'EEE d MMM HH:mm'),
      faction: (id) => factionTag(state, id, names: history.factionNames),
    );
    if (facts == null) return const SizedBox.shrink();
    return SheetSection(facts.title, children: [for (final line in facts.lines) _row(controller, line)]);
  }

  Widget _row(TerritoryMapController controller, ViewLine line) {
    final warId = line.warId;
    if (warId == null) return Text(line.text);
    return InkWell(
      onTap: () => controller.showWar(warId),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(line.text)),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    );
  }
}
