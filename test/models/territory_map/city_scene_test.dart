import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/territory_map/city_camera.dart';
import 'package:torn_pda/models/territory_map/city_heights.dart';
import 'package:torn_pda/models/territory_map/city_mesh.dart';
import 'package:torn_pda/models/territory_map/city_scene.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';
import 'package:torn_pda/models/territory_map/territory_file.dart';

const _screen = Size(400, 800);

String _square(String code, double x, double y) =>
    '''
  "$code": {"sector": 1, "size": 1, "density": 1, "slots": 5, "respect": 15, "label": [$x, $y], "neighbors": [],
    "path": ["M", $x, $y, "L", ${x + 100}, $y, "L", ${x + 100}, ${y + 100}, "L", $x, ${y + 100}, "Z"]}''';

// Front side in teeth facing the camera
String _saw(String code, double x, double y) {
  final teeth = [
    for (var i = 0; i < 10; i++) '"L", ${x + 95 - i * 10}, ${y + 97}, "L", ${x + 90 - i * 10}, ${y + 100}',
  ];
  return '''
  "$code": {"sector": 1, "size": 1, "density": 1, "slots": 5, "respect": 15, "label": [$x, $y], "neighbors": [],
    "path": ["M", $x, $y, "L", ${x + 100}, $y, "L", ${x + 100}, ${y + 100}, ${teeth.join(', ')}, "Z"]}''';
}

CityMesh _twoBlocks() => buildCityMesh(
  parseTerritoryFile('''
    {"format": 1, "version": 1, "bounds": [0, 0, 100, 400], "territories": {
      ${_square('FAR', 0, 0)}, ${_square('NEA', 0, 200)}}}'''),
);

void main() {
  test('a ground point projects back onto itself', () {
    for (final camera in [
      (yaw: 0.0, pitch: 0.0, zoom: 0.5, x: 100.0, y: 50.0),
      (yaw: -0.5, pitch: 0.85, zoom: 0.2, x: 3000.0, y: 1700.0),
      (yaw: 2.4, pitch: 1.2, zoom: 3.0, x: 10.0, y: -40.0),
    ]) {
      final p = CityProjection(camera, _screen);
      for (final ground in [Offset(camera.x, camera.y), Offset(camera.x + 37, camera.y - 12)]) {
        final back = p.groundAt(p.project(ground.dx, ground.dy, 0)!);
        expect((back - ground).distance, lessThan(1e-6));
      }
    }
  });

  test('pinching keeps the ground under the fingers', () {
    const bounds = Rect.fromLTWH(0, 0, 6000, 3400);
    const camera = (yaw: 0.7, pitch: 0.9, zoom: 0.3, x: 3000.0, y: 1700.0);
    const from = Offset(120, 610), to = Offset(150, 560);
    final before = CityProjection(camera, _screen).groundAt(from);
    final pinched = pinchCamera(camera, _screen, from, to, 2, 0.4, bounds);
    expect(pinched.zoom, closeTo(0.6, 1e-9));
    expect(pinched.yaw, closeTo(1.1, 1e-9));
    expect((CityProjection(pinched, _screen).groundAt(to) - before).distance, lessThan(1e-6));
  });

  test('a tap above the horizon stays in front of the camera', () {
    const camera = (yaw: 0.0, pitch: maxPitch, zoom: 0.3, x: 3000.0, y: 1700.0);
    final p = CityProjection(camera, const Size(412, 800));
    final ground = p.groundAt(const Offset(206, 120));
    expect(p.project(ground.dx, ground.dy, 0), isNotNull);
    expect(ground.dy, lessThan(camera.y));
  });

  test('farthest first, and a tall block in front takes the tap', () {
    final mesh = _twoBlocks();
    final far = mesh.indexOf['FAR']!, near = mesh.indexOf['NEA']!;
    final heights = Float32List(2)
      ..[far] = 20
      ..[near] = 300;
    const camera = (yaw: 0.0, pitch: 1.0, zoom: 1.0, x: 50.0, y: 200.0);
    final p = CityProjection(camera, _screen);
    final order = CityOrder(2);
    final frame = CityFrame(mesh.full);

    sortVisible(mesh, p, heights, order);
    expect(order.count, 2);
    expect(order.order.sublist(0, 2), [far, near]);

    final hidden = p.project(50, 50, 20)!;
    expect(cityTerritoryAt(mesh, p, heights, hidden, order: order, frame: frame), near);

    heights[near] = 0;
    expect(cityTerritoryAt(mesh, p, heights, hidden, order: order, frame: frame), far);
    expect(cityTerritoryAt(mesh, p, heights, const Offset(5, 5), order: order, frame: frame), -1);
  });

  test('a roof behind a taller block gets no name, nor one too small', () {
    final mesh = _twoBlocks();
    final far = mesh.indexOf['FAR']!, near = mesh.indexOf['NEA']!;
    final heights = Float32List(2)
      ..[far] = 20
      ..[near] = 300;
    final p = CityProjection((yaw: 0.0, pitch: 1.0, zoom: 1.0, x: 50.0, y: 200.0), _screen);
    final order = CityOrder(2);
    final frame = CityFrame(mesh.full);
    final roofs = CityRoofs(2);

    expect(roofsInSight(mesh, p, heights, order: order, frame: frame, out: roofs, minWidth: 36), 1);
    expect(roofs.territory[0], near);
    final roof = p.project(mesh.centerX[near], mesh.centerY[near], 300)!;
    expect((Offset(roofs.x[0], roofs.y[0]) - roof).distance, lessThan(0.01));

    heights[near] = 0;
    expect(roofsInSight(mesh, p, heights, order: order, frame: frame, out: roofs, minWidth: 36), 2);
    expect(roofs.territory.sublist(0, 2), [near, far]);
    expect(roofsInSight(mesh, p, heights, order: order, frame: frame, out: roofs, minWidth: 1000), 0);
    expect(roofsInSight(mesh, p, heights, order: order, frame: frame, out: roofs, minWidth: 36, minScale: 5), 0);
  });

  test('only walls facing the camera, then the top', () {
    final mesh = _twoBlocks();
    final near = mesh.indexOf['NEA']!;
    final heights = Float32List(2)..fillRange(0, 2, 100);
    final colors = Int32List(2)..[near] = 0xFF2080C0.toSigned(32);
    final p = CityProjection((yaw: 0.0, pitch: 1.0, zoom: 1.0, x: 50.0, y: 200.0), _screen);
    final order = CityOrder(2);
    final frame = CityFrame(mesh.full);
    sortVisible(mesh, p, heights, order);
    fillCityFrame(frame, mesh, p, heights, order, colors, 0xFF000000);

    expect(frame.walls, 2);
    expect(frame.vertices, 2 * 6 + mesh.full.triangles.length);
    final top = shadeColor(colors[near], 1, order.fog[near], 0xFF000000);
    expect(frame.colors.sublist(frame.vertices - 6, frame.vertices), everyElement(top));
  });

  test('outline skips the city border and other territories', () {
    final mesh = _twoBlocks();
    final level = mesh.full;
    final near = mesh.indexOf['NEA']!;
    final edges = outlineEdges(level, [near], const Rect.fromLTRB(0, 0, 100, 400));
    final from = level.ringStart[level.firstRing[near]], to = level.ringStart[level.firstRing[near + 1]];
    final marked = [
      for (var v = 0; v < level.vertexCount; v++)
        if (edges[v] == 1) v,
    ];

    expect(marked, everyElement(inInclusiveRange(from, to - 1)));
    expect([for (final v in marked) level.y[v]]..sort(), [200, 300]);
  });

  test('a long own outline fits the frame', () {
    final file = parseTerritoryFile('''
      {"format": 1, "version": 1, "bounds": [-50, -50, 150, 450], "territories": {
        ${_saw('FAR', 0, 0)}, ${_saw('NEA', 0, 200)}}}''');
    final mesh = buildCityMesh(file);
    final heights = Float32List(2)..fillRange(0, 2, 100);
    final p = CityProjection((yaw: 0.0, pitch: 1.0, zoom: 1.0, x: 50.0, y: 200.0), _screen);
    final order = CityOrder(2);
    final lines = outlineEdges(mesh.full, [0, 1], file.bounds);
    final frame = CityFrame(mesh.full, outline: lines);
    sortVisible(mesh, p, heights, order);
    fillCityFrame(frame, mesh, p, heights, order, Int32List(2), 0xFF000000, borderWidth: 1, lines: lines, lineWidth: 2);

    expect(frame.walls, greaterThan(mesh.full.vertexCount * 3 ~/ 4));
    expect(frame.vertices, frame.walls * 6 + mesh.full.triangles.length + mesh.full.vertexCount * 12);
  });

  test('held grows with time owned', () {
    final file = parseTerritoryFile('''
      {"format": 1, "version": 1, "bounds": [0, 0, 100, 400], "territories": {
        ${_square('FAR', 0, 0)}, ${_square('NEA', 0, 200)}}}''');
    final mesh = buildCityMesh(file);
    final now = DateTime.utc(2026, 11, 10);
    final owners = {
      'FAR': Ownership(factionId: 1, acquiredAt: now.subtract(const Duration(days: 100)), irradiated: false),
      'NEA': Ownership(factionId: 2, acquiredAt: now.subtract(const Duration(days: 1)), irradiated: false),
    };
    final held = cityHeights(CityHeight.held, mesh, file.territories, owners, now);
    expect(held[mesh.indexOf['FAR']!], closeTo(350, 1e-3));
    expect(held[mesh.indexOf['NEA']!], closeTo(44, 1e-3));
  });
}
