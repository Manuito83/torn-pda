import 'package:flutter/painting.dart';
import 'package:torn_pda/models/territory_map/faction_graph.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';
import 'package:torn_pda/models/territory_map/territory_file.dart';

const paletteSize = 30;
const mineColor = -1;

const unownedFill = Color(0x599E9E9E);
Color irradiatedFill({required bool lightTheme}) => lightTheme ? const Color(0xFF3D8C00) : const Color(0xFF76FF03);

// Saturation and lightness of each ring
const _rings = [(0.70, 0.55), (0.65, 0.42), (0.80, 0.68)];

const _similarBelow = 3;

// Mine sits at slot 10, 300 degrees
int _hueSlot(int color) => color == mineColor ? 10 : color % 10;

int colorDistance(int a, int b) {
  final steps = (_hueSlot(a) - _hueSlot(b)).abs();
  final hueSteps = steps < 12 - steps ? steps : 12 - steps;
  if (a == mineColor || b == mineColor) return hueSteps + 1;
  return hueSteps + (a ~/ 10 == b ~/ 10 ? 0 : 2);
}

bool similar(int a, int b) => colorDistance(a, b) < _similarBelow;

int preferredColor(int factionId) => ((factionId * 2654435761) & 0xFFFFFFFF) % paletteSize;

Map<int, int> assignFactionColors(
  Map<String, Ownership> ownership,
  Map<String, Territory> territories, {
  int myFactionId = 0,
  Map<int, int> keep = const {},
}) {
  final adjacency = factionAdjacency(ownership, territories);
  final counts = {for (final e in territoriesOf(ownership).entries) e.key: e.value.length};
  final order = counts.keys.toList()
    ..sort((a, b) {
      final byCount = counts[b]!.compareTo(counts[a]!);
      return byCount != 0 ? byCount : a.compareTo(b);
    });

  final result = <int, int>{};
  if (myFactionId != 0 && counts.containsKey(myFactionId)) result[myFactionId] = mineColor;

  List<int> takenBy(int faction) => [
    for (final other in adjacency[faction] ?? const <int>{})
      if (result[other] != null) result[other]!,
  ];

  // Kept colors first, unless neighbors clash
  for (final faction in order) {
    final color = keep[faction];
    if (faction == myFactionId || color == null || color == mineColor) continue;
    if (!takenBy(faction).any((t) => similar(color, t))) result[faction] = color;
  }

  for (final faction in order) {
    if (result.containsKey(faction)) continue;
    final preferred = preferredColor(faction);
    final taken = takenBy(faction);

    int? chosen;
    var bestColor = preferred;
    var bestDistance = -1;
    for (var k = 0; k < paletteSize; k++) {
      // Coprime with 30: visits every color
      final color = (preferred + k * 11) % paletteSize;
      var nearest = 1 << 30;
      for (final t in taken) {
        final d = colorDistance(color, t);
        if (d < nearest) nearest = d;
      }
      if (nearest >= _similarBelow) {
        chosen = color;
        break;
      }
      if (nearest > bestDistance) {
        bestDistance = nearest;
        bestColor = color;
      }
    }
    result[faction] = chosen ?? bestColor;
  }
  return result;
}

Color fillColor(int color, {required bool lightTheme}) {
  if (color == mineColor) return const HSLColor.fromAHSL(0.9, 300, 0.90, 0.60).toColor();
  final (saturation, lightness) = _rings[color ~/ 10];
  return HSLColor.fromAHSL(0.8, (color % 10) * 30, saturation, lightTheme ? lightness - 0.06 : lightness).toColor();
}
