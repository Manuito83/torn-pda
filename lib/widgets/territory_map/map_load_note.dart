import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/territory_history_controller.dart';
import 'package:torn_pda/providers/territory_map_controller.dart';
import 'package:torn_pda/providers/theme_provider.dart';

const _small = 12.0;

// Progress, or a small error with retry
class MapLoadNote extends StatelessWidget {
  const MapLoadNote({super.key, this.loading = false, this.label, this.error, this.onRetry});

  final bool loading;

  // With a spinner, else thin bar
  final String? label;
  final String? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final error = this.error;
    final label = this.label;
    if (loading && label == null) {
      return const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: LinearProgressIndicator(minHeight: 2));
    }
    if (loading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox.square(dimension: _small, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(label!, style: const TextStyle(fontSize: _small)),
          ),
        ],
      );
    }
    if (error == null) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            error,
            style: const TextStyle(color: Colors.grey, fontSize: _small),
          ),
        ),
        if (onRetry != null)
          TextButton(
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: onRetry,
            child: const Text('Retry', style: TextStyle(fontSize: _small)),
          ),
      ],
    );
  }
}

// The same note, floating over the map
class MapLoadChip extends StatelessWidget {
  const MapLoadChip({super.key, this.loading = false, this.label, this.error, this.onRetry});

  final bool loading;
  final String? label;
  final String? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (!loading && error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Material(
        color: context.watch<ThemeProvider>().secondBackground.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: MapLoadNote(loading: loading, label: label, error: error, onRetry: onRetry),
        ),
      ),
    );
  }
}

class HistoryYearsNote extends StatelessWidget {
  const HistoryYearsNote({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<TerritoryHistoryController>();
    return MapLoadNote(
      loading: history.loadingYears,
      error: history.yearsFailed ? 'Older history could not be loaded' : null,
      onRetry: history.loadYears,
    );
  }
}

class HistoryDaysNote extends StatelessWidget {
  const HistoryDaysNote({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<TerritoryHistoryController>();
    return MapLoadNote(
      loading: history.loading,
      error: history.failed ? 'Could not load every day' : null,
      onRetry: history.retryDays,
    );
  }
}

// For views painted from the history
class MapHistoryChip extends StatelessWidget {
  const MapHistoryChip({super.key, required this.years});

  final bool years;

  @override
  Widget build(BuildContext context) {
    final history = context.watch<TerritoryHistoryController>();
    final failed = years ? history.yearsFailed : history.failed;
    return MapLoadChip(
      loading: years ? history.loadingYears : history.loading,
      label: 'Loading history',
      error: failed ? 'History could not be loaded' : null,
      onRetry: years ? history.loadYears : history.retryDays,
    );
  }
}

// Lists read from the map data
class MapStateNote extends StatelessWidget {
  const MapStateNote({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TerritoryMapController>();
    if (!controller.refreshing && controller.lastError == null) return const Text('No data yet');
    return MapLoadNote(
      loading: controller.refreshing,
      error: controller.lastError == null ? null : 'Could not load the map data',
      onRetry: controller.retry,
    );
  }
}
