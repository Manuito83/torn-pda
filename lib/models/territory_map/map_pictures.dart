import 'dart:math' as math;
import 'dart:ui';

import 'package:torn_pda/models/territory_map/map_state.dart';
import 'package:torn_pda/models/territory_map/map_views.dart';
import 'package:torn_pda/models/territory_map/territory_file.dart';

// Grown around its center
Rect fitAspect(Rect area, double aspect) {
  final width = math.max(area.width, area.height * aspect);
  return Rect.fromCenter(center: area.center, width: width, height: width / aspect);
}

double smallestPicture(Rect city) => city.shortestSide / 6;

Rect roomAround(Rect area, {required double minSize}) => Rect.fromCenter(
  center: area.center,
  width: math.max(area.width * 1.2, minSize),
  height: math.max(area.height * 1.2, minSize),
);

Rect? boundsOf(Iterable<String> codes, Map<String, Territory> territories) {
  Rect? area;
  for (final code in codes) {
    final bounds = territories[code]?.bounds;
    if (bounds != null) area = area?.expandToInclude(bounds) ?? bounds;
  }
  return area;
}

typedef FactionPicture = ({Rect area, Map<String, Shade> shades, List<TerritoryWar> wars});

// Null when it holds and fights nothing
FactionPicture? factionPicture(
  int factionId,
  MapState state,
  Map<String, Territory> territories, {
  required double minSize,
}) {
  final wars = [
    for (final war in state.wars)
      if (war.aggressor.factionId == factionId || war.defender.factionId == factionId) war,
  ];
  final codes = {
    for (final e in state.ownership.entries)
      if (e.value.factionId == factionId) e.key,
    for (final war in wars) war.territory,
  };
  final area = boundsOf(codes, territories);
  if (area == null) return null;
  return (
    area: roomAround(area, minSize: minSize),
    shades: {for (final code in codes) code: (kind: ShadeKind.faction, step: 0)},
    wars: wars,
  );
}
