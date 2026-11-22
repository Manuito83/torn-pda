import 'package:material_ui/material_ui.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/territory_map/map_changes.dart';
import 'package:torn_pda/models/territory_map/map_dates.dart';
import 'package:torn_pda/models/territory_map/map_diary.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/territory_history_controller.dart';
import 'package:torn_pda/providers/territory_map_controller.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/time_formatter.dart';
import 'package:torn_pda/widgets/territory_map/city_records_section.dart';
import 'package:torn_pda/widgets/territory_map/map_load_note.dart';
import 'package:torn_pda/widgets/territory_map/map_sheet.dart';

IconData diaryIcon(ChangeKind kind) => switch (kind) {
  ChangeKind.conquest => MdiIcons.flag,
  ChangeKind.transfer => Icons.swap_horiz,
  ChangeKind.abandoned => Icons.outlined_flag,
  ChangeKind.claimed => Icons.add_location_alt_outlined,
  ChangeKind.reacquired => Icons.replay,
  ChangeKind.irradiated => MdiIcons.radioactive,
  ChangeKind.assaultStarted => MdiIcons.swordCross,
  ChangeKind.assaultSucceeded => Icons.emoji_events_outlined,
  ChangeKind.assaultFailed => Icons.shield_outlined,
  ChangeKind.assaultTruce => MdiIcons.handshake,
  ChangeKind.assaultEnded => Icons.stop_circle_outlined,
  ChangeKind.racketNew => Icons.add_business_outlined,
  ChangeKind.racketUp => Icons.trending_up,
  ChangeKind.racketDown => Icons.trending_down,
  ChangeKind.racketLevel => Icons.trending_flat,
  ChangeKind.racketLost => Icons.remove_circle_outline,
  ChangeKind.bomb => MdiIcons.bomb,
};

void showDiaryChange(TerritoryMapController controller, MapChange change) {
  final code = change.territory;
  if (code == null) return controller.showFaction(change.factionId);
  controller.focusTerritory(code);
  final war = change.warId;
  if (change.source == 'war' && war != null) controller.showWar(war);
}

class DiaryRow extends StatelessWidget {
  const DiaryRow({super.key, required this.icon, required this.text, this.at, this.withDate = false, this.onTap});

  DiaryRow.change(MapChange change, ChangeKind kind, String Function(int factionId) tag, {super.key})
    : icon = diaryIcon(kind),
      text = diaryText(change, kind, tag),
      at = change.at,
      withDate = false,
      onTap = ((controller) => showDiaryChange(controller, change));

  final IconData icon;
  final String text;
  final DateTime? at;
  final bool withDate;
  final void Function(TerritoryMapController controller)? onTap;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final at = this.at;
    final onTap = this.onTap;
    final time = at == null
        ? null
        : withDate
        ? mapDate(at, settings.currentTimeZone)
        : TimeFormatter(
            inputTime: at,
            timeFormatSetting: settings.currentTimeFormat,
            timeZoneSetting: settings.currentTimeZone,
          ).formatHour;
    return InkWell(
      onTap: onTap == null ? null : () => onTap(context.read<TerritoryMapController>()),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
            if (time != null) Text(time, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class DiarySheet extends StatefulWidget {
  const DiarySheet({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  State<DiarySheet> createState() => _DiarySheetState();
}

class _DiarySheetState extends State<DiarySheet> {
  final _search = TextEditingController();
  int _period = 7;
  bool _mine = false;

  @override
  void initState() {
    super.initState();
    final from = DateTime.now().toUtc().subtract(const Duration(days: diaryMaxDays));
    context.read<TerritoryHistoryController>().load(from);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<TerritoryHistoryController>();
    final controller = context.watch<TerritoryMapController>();
    final state = controller.state;
    final names = history.factionNames;
    String tag(int id) => factionTag(state, id, names: names);
    final myFaction = controller.myFactionId;
    final mine = _mine && myFaction != 0;
    final query = _search.text.trim();
    final filtering = mine || query.isNotEmpty;
    List<(MapChange, ChangeKind)> rowsOf(DayChanges day) => diaryRows(
      day,
      query: query,
      factionId: mine ? myFaction : 0,
      faction: (id) => state?.factions[id] ?? names[id],
    );

    if (filtering) {
      final found = [
        for (final day in history.days)
          if (rowsOf(day) case final rows when rows.isNotEmpty) (day.day, rows),
      ];
      return MapSheet(
        title: const Text('History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        onClose: widget.onClose,
        children: [
          _searchBar(myFaction),
          const HistoryDaysNote(),
          if (found.isEmpty && !history.loading && !history.failed)
            const Text('Nothing found in the last $diaryMaxDays days'),
          for (final (i, (day, rows)) in found.indexed)
            _DiaryDay(key: ValueKey((day, query, mine)), day: day, rows: rows, expanded: i == 0, tag: tag),
        ],
      );
    }

    final since = DateTime.now().toUtc().subtract(Duration(days: _period));
    final stats = periodStats(history.changesSince(since), since);
    final summary = diarySummary(stats.counts);

    Widget ground(String title, List<MapEntry<int, int>> factions) => SheetSection(
      title,
      children: [
        mapChips([
          for (final e in factions)
            ('${tag(e.key)} ${e.value > 0 ? '+' : ''}${e.value}', () => controller.showFaction(e.key)),
        ]),
      ],
    );

    return MapSheet(
      title: const Text('History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      onClose: widget.onClose,
      children: [
        _searchBar(myFaction),
        Wrap(
          spacing: 6,
          children: [
            for (final days in const [7, 30])
              ChoiceChip(
                visualDensity: VisualDensity.compact,
                label: Text('$days days'),
                selected: _period == days,
                onSelected: (_) => setState(() => _period = days),
              ),
          ],
        ),
        const HistoryDaysNote(),
        if (summary.isNotEmpty || !(history.loading || history.failed))
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(summary.isEmpty ? 'Nothing recorded yet' : summary),
          ),
        if (history.someDaysMissing) const Text('Some days missing', style: TextStyle(color: Colors.grey)),
        if (stats.gainers.isNotEmpty) ground('Gaining ground', stats.gainers),
        if (stats.losers.isNotEmpty) ground('Losing ground', stats.losers),
        const CityRecordsSection(),
        for (final (i, day) in history.days.indexed)
          _DiaryDay(key: ValueKey(day.day), day: day.day, rows: rowsOf(day), expanded: i == 0, tag: tag),
      ],
    );
  }

  Widget _searchBar(int myFaction) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Territory, faction or event',
                prefixIcon: const Icon(Icons.search, size: 18),
                prefixIconConstraints: const BoxConstraints(minWidth: 32),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(_search.clear),
                      ),
              ),
            ),
          ),
          if (myFaction != 0) ...[
            const SizedBox(width: 8),
            FilterChip(
              visualDensity: VisualDensity.compact,
              label: const Text('My faction'),
              selected: _mine,
              onSelected: (on) => setState(() => _mine = on),
            ),
          ],
        ],
      ),
    );
  }
}

class _DiaryDay extends StatelessWidget {
  const _DiaryDay({super.key, required this.day, required this.rows, required this.expanded, required this.tag});

  final String day;
  final List<(MapChange, ChangeKind)> rows;
  final bool expanded;
  final String Function(int factionId) tag;

  @override
  Widget build(BuildContext context) {
    final color = context.watch<ThemeProvider>().mainText;
    final title = Text(
      DateFormat('EEE d MMM').format(dayStart(day)),
      style: const TextStyle(fontWeight: FontWeight.bold),
    );
    if (rows.isEmpty) {
      final quiet = day == dayKey(DateTime.now()) ? 'All quiet so far' : 'All quiet';
      return ListTile(contentPadding: EdgeInsets.zero, textColor: color, title: title, subtitle: Text(quiet));
    }
    return ExpansionTile(
      initiallyExpanded: expanded,
      textColor: color,
      collapsedTextColor: color,
      iconColor: color,
      collapsedIconColor: color,
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      title: title,
      subtitle: Text(diarySummary(summarize([for (final (change, _) in rows) change], dayStart(day)))),
      children: [for (final (change, kind) in rows) DiaryRow.change(change, kind, tag)],
    );
  }
}
