import 'package:material_ui/material_ui.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/territory_map/city_records.dart';
import 'package:torn_pda/models/territory_map/map_history.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';
import 'package:torn_pda/providers/territory_history_controller.dart';
import 'package:torn_pda/providers/territory_map_controller.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/widgets/territory_map/diary_sheet.dart';
import 'package:torn_pda/widgets/territory_map/map_load_note.dart';
import 'package:torn_pda/widgets/territory_map/map_sheet.dart';

class CityRecordsSection extends StatelessWidget {
  const CityRecordsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final color = context.watch<ThemeProvider>().mainText;
    return ExpansionTile(
      textColor: color,
      collapsedTextColor: color,
      iconColor: color,
      collapsedIconColor: color,
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      title: const Text('City records', style: TextStyle(fontWeight: FontWeight.bold)),
      onExpansionChanged: (open) {
        if (open) context.read<TerritoryHistoryController>().loadYears();
      },
      children: const [_CityRecords()],
    );
  }
}

class _CityRecords extends StatelessWidget {
  const _CityRecords();

  @override
  Widget build(BuildContext context) {
    final history = context.watch<TerritoryHistoryController>();
    final state = context.select<TerritoryMapController, MapState?>((c) => c.state);
    final record = history.record;
    if (record == null || state == null) {
      return history.loadingYears || history.yearsFailed
          ? const HistoryYearsNote()
          : const Text('Nothing recorded yet');
    }
    final records = cityRecords(record, state.ownership);
    final names = history.factionNames;
    String tag(int id) => factionTag(state, id, names: names);
    final mostAssaulted = records.mostAssaulted;
    final longest = records.longestWar;
    final oldest = records.oldestOwner;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HistoryYearsNote(),
        if (mostAssaulted != null)
          DiaryRow(
            icon: MdiIcons.swordCross,
            text: 'Most assaulted: ${mostAssaulted.code} - ${mostAssaulted.assaults} times in 12 months',
            onTap: (controller) => controller.focusTerritory(mostAssaulted.code),
          ),
        if (longest != null)
          DiaryRow(
            icon: Icons.timer_outlined,
            text: 'Longest war: ${longest.territory} - ${historyWarText(longest, tag)}',
            at: longest.start,
            withDate: true,
            onTap: (controller) {
              controller.focusTerritory(longest.territory);
              if (longest.hasReport) controller.showWar(longest.id);
            },
          ),
        if (oldest != null)
          DiaryRow(
            icon: Icons.flag_outlined,
            text: 'Oldest owner: ${tag(oldest.factionId)} on ${oldest.code} since',
            at: oldest.since,
            withDate: true,
            onTap: (controller) => controller.focusTerritory(oldest.code),
          ),
        if (records.topConquerors.isNotEmpty) ...[
          const Padding(padding: EdgeInsets.only(top: 4), child: Text('Most conquests')),
          mapChips([
            for (final top in records.topConquerors)
              (
                '${tag(top.factionId)} ${top.conquests}',
                () => context.read<TerritoryMapController>().showFaction(top.factionId),
              ),
          ]),
        ],
      ],
    );
  }
}
