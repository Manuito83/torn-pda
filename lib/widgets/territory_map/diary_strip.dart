import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chat/chat_player_card.dart';
import 'package:torn_pda/models/territory_map/map_changes.dart';
import 'package:torn_pda/models/territory_map/map_diary.dart';
import 'package:torn_pda/providers/territory_history_controller.dart';
import 'package:torn_pda/providers/theme_provider.dart';

class DiaryStrip extends StatefulWidget {
  const DiaryStrip({super.key, required this.onOpen});

  final VoidCallback onOpen;

  @override
  State<DiaryStrip> createState() => _DiaryStripState();
}

class _DiaryStripState extends State<DiaryStrip> {
  bool _folded = false;

  @override
  Widget build(BuildContext context) {
    final history = context.watch<TerritoryHistoryController>();
    final themeProvider = context.watch<ThemeProvider>();
    final now = DateTime.now().toUtc();
    final since = history.since;
    final from = since ?? now.subtract(const Duration(days: diaryMaxDays));
    final summary = diarySummary(summarize(history.changesSince(from), from));
    if (summary.isEmpty && history.loading) return const SizedBox.shrink();
    final news = summary.isNotEmpty ? summary : (history.failed ? 'could not load' : 'all quiet');

    final label = since == null
        ? 'Last $diaryMaxDays days'
        : 'Since you last looked (${ChatPlayerCard.span(now.difference(since))})';
    return Material(
      color: themeProvider.secondBackground,
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: widget.onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 0, 4),
          child: Row(
            mainAxisSize: _folded ? MainAxisSize.min : MainAxisSize.max,
            children: [
              Icon(Icons.history, size: 18, color: themeProvider.mainText),
              const SizedBox(width: 8),
              if (!_folded)
                Expanded(
                  child: Text(
                    '$label: $news${history.someDaysMissing ? ' (some days missing)' : ''}',
                    style: TextStyle(color: themeProvider.mainText, fontSize: 12),
                  ),
                ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(_folded ? Icons.chevron_right : Icons.chevron_left, color: themeProvider.mainText),
                onPressed: () => setState(() => _folded = !_folded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
