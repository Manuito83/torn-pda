import 'dart:typed_data';
import 'dart:ui';

import 'package:torn_pda/models/territory_map/city_ground.dart';
import 'package:torn_pda/models/territory_map/horizon.dart';
import 'package:torn_pda/models/territory_map/surroundings.dart';

const _portalRoadsReach = 7000.0;
const _hazeEatsCars = 1.5;

// Cars go out by the exits
RoadGraph joinRoads(RoadGraph city, Surroundings s) {
  final out = s.roads;
  final nodes = [...city.nodes];
  final ids = <int>[];
  for (var i = 0; i < out.nodeCount; i++) {
    if (s.exits[i] case final exit?) {
      ids.add(exit);
      continue;
    }
    ids.add(nodes.length ~/ 2);
    final at = squeezed(Offset(out.nodes[i * 2], out.nodes[i * 2 + 1]), s.bounds, s.horizon).at;
    nodes.addAll([at.dx, at.dy]);
  }

  final edges = [...city.edges];
  final portals = <int>{};
  for (final e in out.edges) {
    final count = e.xs.length;
    bool far(int k) => distanceToRect(Offset(e.xs[k], e.ys[k]), s.bounds) > _portalRoadsReach;
    // Portal roads: only the near end
    var first = 0, last = count - 1;
    int? portal;
    if (out.portals.contains(e.b)) {
      portal = ids[e.b];
      last = 0;
      while (last + 1 < count && !far(last + 1)) {
        last++;
      }
    } else if (out.portals.contains(e.a)) {
      portal = ids[e.a];
      first = count - 1;
      while (first > 0 && !far(first - 1)) {
        first--;
      }
    }
    final n = last - first + 1;
    if (n < 2) continue;

    final xs = Float32List(n), ys = Float32List(n), cumulative = Float32List(n);
    final sizes = Float32List(n), fades = Float32List(n);
    for (var j = 0; j < n; j++) {
      final k = first + j;
      final view = squeezed(Offset(e.xs[k], e.ys[k]), s.bounds, s.horizon);
      xs[j] = view.at.dx;
      ys[j] = view.at.dy;
      sizes[j] = view.size;
      fades[j] = hazeFade(view.distance, _hazeEatsCars);
      cumulative[j] = e.cumulative[k] - e.cumulative[first];
    }
    if (portal != null) {
      final end = portal == ids[e.a] ? 0 : n - 1;
      nodes
        ..[portal * 2] = xs[end]
        ..[portal * 2 + 1] = ys[end];
      portals.add(portal);
    }
    edges.add(RoadEdge(ids[e.a], ids[e.b], xs, ys, cumulative, kind: e.kind, sizes: sizes, fades: fades));
  }
  return RoadGraph(Float32List.fromList(nodes), edges, portals: portals.toList(), cityEdges: city.edges.length);
}
