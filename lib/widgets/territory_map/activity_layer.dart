import 'package:material_ui/material_ui.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';
import 'package:torn_pda/models/territory_map/map_views.dart';
import 'package:torn_pda/providers/territory_history_controller.dart';
import 'package:torn_pda/providers/territory_map_controller.dart';
import 'package:torn_pda/widgets/territory_map/map_layer.dart';

const activityColor = Color(0xFFFF5722);

// Repaints when history arrives
class ActivityLayer extends RefreshedMapLayer {
  ActivityLayer(this.controller, this.history) : super(history);

  final TerritoryMapController controller;
  final TerritoryHistoryController history;

  List<ActivitySpot> _spots = const [];

  final _fill = Paint();
  final _ring = Paint()
    ..style = PaintingStyle.stroke
    ..color = Colors.white;

  void _refresh(MapState state, DateTime now) {
    final record = history.record;
    final span = controller.activitySpan;
    if (!outdated([state, record, span], now)) return;
    _spots = activitySpots(span, now, current: state.wars, ended: [...state.recentWars, ...?record?.wars]);
  }

  @override
  void paint(Canvas canvas, MapViewport viewport) {
    final state = controller.state;
    final territories = controller.territories?.territories;
    if (state == null || territories == null) return;
    final now = DateTime.now().toUtc();
    _refresh(state, now);
    final span = controller.activitySpan;
    _ring.strokeWidth = 1.5 / viewport.scale;

    for (final spot in _spots) {
      final center = territories[spot.code]?.label;
      final radius = spotRadius(spot.assaults) / viewport.scale;
      if (center == null || !viewport.visible.inflate(radius).contains(center)) continue;
      _fill.color = activityColor.withValues(alpha: spotAlpha(spot.last, now, span));
      canvas
        ..drawCircle(center, radius, _fill)
        ..drawCircle(center, radius, _ring);
    }
  }

  @override
  Object? hitTest(Offset mapPoint, double scale) => null;
}
