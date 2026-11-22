import 'dart:math' as math;
import 'dart:typed_data';

import 'package:torn_pda/models/territory_map/city_mesh.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';
import 'package:torn_pda/models/territory_map/territory_file.dart';

enum CityHeight { respect, size, slots, held, flat }

Float32List cityHeights(
  CityHeight height,
  CityMesh mesh,
  Map<String, Territory> territories,
  Map<String, Ownership> owners,
  DateTime now,
) {
  final out = Float32List(mesh.length);
  var maxDays = 1.0;
  if (height == CityHeight.held) {
    for (final o in owners.values) {
      if (o.acquiredAt case final at?) maxDays = math.max(maxDays, now.difference(at).inSeconds / 86400);
    }
  }
  for (var i = 0; i < mesh.length; i++) {
    final t = territories[mesh.codes[i]];
    if (t == null) continue;
    out[i] = switch (height) {
      CityHeight.respect => 16 + (t.respect - 15) / 210 * 330,
      CityHeight.size => t.size * 62.0,
      CityHeight.slots => 16 + (t.slots - 5) / 25 * 320,
      CityHeight.held => switch (owners[t.code]?.acquiredAt) {
        final at? => 10 + math.sqrt(math.max(0, now.difference(at).inSeconds / 86400)) / math.sqrt(maxDays) * 340,
        null => 5,
      },
      CityHeight.flat => 0,
    };
  }
  return out;
}
