import 'package:material_ui/material_ui.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/territory_map/map_biography.dart';
import 'package:torn_pda/models/territory_map/map_dates.dart';
import 'package:torn_pda/models/territory_map/map_history.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/territory_history_controller.dart';
import 'package:torn_pda/widgets/territory_map/diary_sheet.dart';
import 'package:torn_pda/widgets/territory_map/map_load_note.dart';
import 'package:torn_pda/widgets/territory_map/map_sheet.dart';

class FactionHistorySection extends StatefulWidget {
  const FactionHistorySection({super.key, required this.factionId});

  final int factionId;

  @override
  State<FactionHistorySection> createState() => _FactionHistorySectionState();
}

class _FactionHistorySectionState extends State<FactionHistorySection> {
  @override
  void initState() {
    super.initState();
    context.read<TerritoryHistoryController>().loadYears();
  }

  @override
  Widget build(BuildContext context) {
    final record = context.select<TerritoryHistoryController, MapHistory?>((h) => h.record);
    final waiting = context.select<TerritoryHistoryController, bool>((h) => h.loadingYears || h.yearsFailed);
    final zone = context.select<SettingsProvider, TimeZoneSetting>((s) => s.currentTimeZone);
    if (record == null) {
      return waiting ? const SheetSection('History', children: [HistoryYearsNote()]) : const SizedBox.shrink();
    }
    final bio = factionBiography(record, widget.factionId);
    final since = mapDate(record.completeFrom, zone);
    final respect = NumberFormat('#,##0', 'en_US');

    return SheetSection(
      'History',
      children: [
        Text(
          'Last 12 months: ${bio.won} won - ${bio.lost} lost - ${bio.truces} ${bio.truces == 1 ? 'truce' : 'truces'}',
        ),
        Text(
          'Since $since: gained ${bio.conquered} by assault and ${bio.gainedOtherwise} otherwise - '
          'lost ${bio.lostToConquest} to assaults and ${bio.lostOtherwise} otherwise',
        ),
        const HistoryYearsNote(),
        for (final bomb in bio.bombs)
          DiaryRow(
            icon: MdiIcons.bomb,
            text: 'Dirty bomb on ${bomb.territories.join(', ')}: lost ${respect.format(bomb.respectLost)} respect',
            at: bomb.detonatedAt,
            withDate: true,
          ),
      ],
    );
  }
}
