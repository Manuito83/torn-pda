import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/territory_map/map_history.dart';
import 'package:torn_pda/models/territory_map/map_video.dart';
import 'package:torn_pda/providers/territory_history_controller.dart';
import 'package:torn_pda/providers/territory_video_controller.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/widgets/territory_map/map_load_note.dart';

// Days to record, null if closed
Future<int?> showVideoRangeDialog(BuildContext context, TerritoryHistoryController history) {
  final theme = context.read<ThemeProvider>();
  return showDialog<int>(
    context: context,
    builder: (_) => _VideoRangeDialog(history: history, theme: theme),
  );
}

class _VideoRangeDialog extends StatefulWidget {
  const _VideoRangeDialog({required this.history, required this.theme});

  final TerritoryHistoryController history;
  final ThemeProvider theme;

  @override
  State<_VideoRangeDialog> createState() => _VideoRangeDialogState();
}

class _VideoRangeDialogState extends State<_VideoRangeDialog> {
  bool _asked = false;

  @override
  void initState() {
    super.initState();
    widget.history.loadYears().catchError((_) {}).whenComplete(() {
      if (mounted) setState(() => _asked = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final history = widget.history;
    final text = TextStyle(color: theme.mainText);
    final muted = TextStyle(color: theme.mainText.withValues(alpha: 0.7), fontSize: 13);
    return AlertDialog(
      backgroundColor: theme.secondBackground,
      title: Text('Video of the map', style: text),
      content: ListenableBuilder(
        listenable: history,
        builder: (context, _) {
          final loading = !_asked || history.loadingYears || history.loading;
          final now = DateTime.now().toUtc();
          final recorded = timelapseDays(history.record?.completeFrom ?? now, now).length;
          final options = videoRangeOptions(recorded);
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Records the area you are looking at, day by day', style: muted),
              const SizedBox(height: 16),
              if (loading) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 8),
                Text('Loading the history', style: muted),
              ] else if (options.isEmpty)
                history.yearsFailed ? const HistoryYearsNote() : Text('Not enough days recorded yet', style: text)
              else
                for (final days in options)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.movie_outlined, color: theme.mainText),
                    title: Text('Last $days days', style: text),
                    onTap: () => Navigator.pop(context, days),
                  ),
            ],
          );
        },
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))],
    );
  }
}

// The caller closes it
Future<void> showVideoProgressDialog(BuildContext context, TerritoryVideoController video) {
  final theme = context.read<ThemeProvider>();
  final text = TextStyle(color: theme.mainText);
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: theme.secondBackground,
        title: Text('Recording the video', style: text),
        content: ListenableBuilder(
          listenable: video,
          builder: (_, _) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_progressLabel(video), style: text),
              const SizedBox(height: 12),
              LinearProgressIndicator(value: video.progress),
              const SizedBox(height: 12),
              Text(
                'Stay on this screen until it finishes',
                style: TextStyle(color: theme.mainText.withValues(alpha: 0.7), fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [TextButton(onPressed: video.cancel, child: const Text('Cancel'))],
      ),
    ),
  );
}

String _progressLabel(TerritoryVideoController video) {
  if (video.cancelled) return 'Stopping';
  if (video.finishing) return 'Saving the video';
  return 'Recording day ${math.max(1, video.day)} of ${video.total}';
}
