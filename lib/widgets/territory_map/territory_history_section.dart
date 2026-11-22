import 'package:material_ui/material_ui.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chat/chat_faction_ops.dart';
import 'package:torn_pda/models/territory_map/map_changes.dart';
import 'package:torn_pda/models/territory_map/map_diary.dart';
import 'package:torn_pda/models/territory_map/map_biography.dart';
import 'package:torn_pda/models/territory_map/map_dates.dart';
import 'package:torn_pda/models/territory_map/map_history.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/territory_history_controller.dart';
import 'package:torn_pda/providers/territory_map_controller.dart';
import 'package:torn_pda/widgets/territory_map/diary_sheet.dart';
import 'package:torn_pda/widgets/territory_map/map_load_note.dart';
import 'package:torn_pda/widgets/territory_map/map_sheet.dart';

const _rows = 10;

class TerritoryHistorySection extends StatefulWidget {
  const TerritoryHistorySection({super.key, required this.code});

  final String code;

  @override
  State<TerritoryHistorySection> createState() => _TerritoryHistorySectionState();
}

class _TerritoryHistorySectionState extends State<TerritoryHistorySection> {
  bool _all = false;

  @override
  void initState() {
    super.initState();
    context.read<TerritoryHistoryController>().loadYears();
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<TerritoryHistoryController>();
    final state = context.select<TerritoryMapController, MapState?>((c) => c.state);
    final zone = context.select<SettingsProvider, TimeZoneSetting>((s) => s.currentTimeZone);
    final record = history.record;
    if (record == null) {
      return history.loadingYears || history.yearsFailed
          ? const SheetSection('History', children: [HistoryYearsNote()])
          : const SizedBox.shrink();
    }

    final code = widget.code;
    final current = state?.ownership[code];
    final bio = territoryBiography(record, code, owner: current?.factionId ?? 0);
    final names = history.factionNames;
    String tag(int id) => factionTag(state, id, names: names);
    final longest = bio.longestWar?.duration;
    final respect = NumberFormat('#,##0', 'en_US');

    final lines = [
      for (final entry in territoryTimeline(bio))
        switch (entry.event) {
          final MapChange change => DiaryRow(
            icon: diaryIcon(classify(change)!),
            text: diaryText(change, classify(change)!, tag),
            at: entry.at,
            withDate: true,
            onTap: change.warId == null ? null : (controller) => controller.showWar(change.warId),
          ),
          final RecentWar war => DiaryRow(
            icon: MdiIcons.swordCross,
            text: historyWarText(war, tag),
            at: entry.at,
            withDate: true,
            onTap: war.hasReport ? (controller) => controller.showWar(war.id) : null,
          ),
          final DirtyBomb bomb => DiaryRow(
            icon: MdiIcons.bomb,
            text: 'Dirty bomb: ${tag(bomb.factionId)} lost ${respect.format(bomb.respectLost)} respect',
            at: entry.at,
            withDate: true,
          ),
          _ => const SizedBox.shrink(),
        },
    ];

    return SheetSection(
      'History',
      children: [
        Text(
          'Assaulted ${bio.wars.length} ${bio.wars.length == 1 ? 'time' : 'times'} in 12 months '
          '(${bio.conquests} successful)${longest == null ? '' : ' - longest war ${chatSpan(longest)}'} - '
          '${bio.ownerCount} ${bio.ownerCount == 1 ? 'owner' : 'owners'} '
          'since ${mapDate(record.completeFrom, zone, pattern: 'MMM y')}',
        ),
        const HistoryYearsNote(),
        if (bio.owners.isEmpty && current?.acquiredAt != null && current!.factionId != 0)
          DiaryRow(
            icon: Icons.flag_outlined,
            text: 'Held by ${tag(current.factionId)} since',
            at: current.acquiredAt,
            withDate: true,
          ),
        ...(_all ? lines : lines.take(_rows)),
        if (!_all && lines.length > _rows)
          TextButton(onPressed: () => setState(() => _all = true), child: Text('Show all ${lines.length}')),
      ],
    );
  }
}
