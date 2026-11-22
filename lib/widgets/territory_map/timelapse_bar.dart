import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/territory_map/map_diary.dart';
import 'package:torn_pda/providers/territory_history_controller.dart';
import 'package:torn_pda/providers/territory_timelapse_controller.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/widgets/territory_map/map_load_note.dart';

class TimelapseBar extends StatelessWidget {
  const TimelapseBar({super.key, required this.timelapse, required this.onClose});

  final TerritoryTimelapseController timelapse;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final loading = context.select<TerritoryHistoryController, bool>((h) => h.loadingYears || h.loading);
    final failed = context.select<TerritoryHistoryController, bool>((h) => h.yearsFailed);
    final style = TextStyle(color: themeProvider.mainText, fontSize: 12);
    return Material(
      color: themeProvider.secondBackground,
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: ListenableBuilder(
        listenable: timelapse,
        builder: (context, _) {
          final days = timelapse.days;
          final enough = days.length > 1;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading) const LinearProgressIndicator(minHeight: 2),
              Row(
                children: [
                  IconButton(
                    icon: Icon(timelapse.playing ? Icons.pause : Icons.play_arrow, color: themeProvider.mainText),
                    tooltip: timelapse.playing ? 'Pause' : 'Play',
                    onPressed: !enough
                        ? null
                        : timelapse.playing
                        ? timelapse.pause
                        : timelapse.play,
                  ),
                  Expanded(
                    child: enough
                        ? Slider(
                            value: timelapse.selected.toDouble(),
                            max: (days.length - 1).toDouble(),
                            divisions: days.length - 1,
                            onChangeStart: (_) => timelapse.pause(),
                            onChanged: (value) => timelapse.select(value.round()),
                          )
                        : loading || failed
                        ? MapLoadNote(
                            loading: loading,
                            label: 'Loading history',
                            error: failed ? 'Could not load the history' : null,
                            onRetry: context.read<TerritoryHistoryController>().loadYears,
                          )
                        : Text('Only today recorded so far', style: style),
                  ),
                  SizedBox(
                    width: 72,
                    child: Text(
                      timelapse.atPresent ? 'Now' : DateFormat('EEE d MMM').format(dayStart(days[timelapse.selected])),
                      style: style.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: themeProvider.mainText),
                    tooltip: 'Back to now',
                    onPressed: onClose,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
