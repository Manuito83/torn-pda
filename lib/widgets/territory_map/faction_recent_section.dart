import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/territory_map/map_diary.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';
import 'package:torn_pda/providers/territory_history_controller.dart';
import 'package:torn_pda/providers/territory_map_controller.dart';
import 'package:torn_pda/widgets/territory_map/diary_sheet.dart';
import 'package:torn_pda/widgets/territory_map/map_load_note.dart';
import 'package:torn_pda/widgets/territory_map/map_sheet.dart';

const _recentDays = 7;
const _recentRows = 8;

class FactionRecentSection extends StatefulWidget {
  const FactionRecentSection({super.key, required this.factionId});

  final int factionId;

  @override
  State<FactionRecentSection> createState() => _FactionRecentSectionState();
}

class _FactionRecentSectionState extends State<FactionRecentSection> {
  @override
  void initState() {
    super.initState();
    final from = DateTime.now().toUtc().subtract(const Duration(days: _recentDays));
    context.read<TerritoryHistoryController>().load(from);
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<TerritoryHistoryController>();
    final state = context.select<TerritoryMapController, MapState?>((c) => c.state);
    final id = widget.factionId;
    final since = DateTime.now().toUtc().subtract(const Duration(days: _recentDays));
    final (:rows, :won, :lost) = factionRecent(history.changesSince(since), id);
    if (rows.isEmpty && (history.loading || history.failed)) {
      return const SheetSection('Recent', children: [HistoryDaysNote()]);
    }
    final names = history.factionNames;

    return SheetSection(
      'Recent',
      children: [
        Text(
          rows.isEmpty
              ? 'Nothing in the last $_recentDays days'
              : 'Last $_recentDays days: ${territoryCount(won)} won, $lost lost',
        ),
        for (final (change, kind) in rows.take(_recentRows))
          DiaryRow.change(change, kind, (factionId) => factionTag(state, factionId, names: names)),
      ],
    );
  }
}
