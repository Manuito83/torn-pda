import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/territory_map/city_mesh.dart';
import 'package:torn_pda/models/territory_map/city_planes.dart';
import 'package:torn_pda/models/territory_map/city_scene.dart';
import 'package:torn_pda/models/territory_map/map_labels.dart';
import 'package:torn_pda/models/territory_map/map_views.dart';
import 'package:torn_pda/models/territory_map/surroundings.dart';
import 'package:torn_pda/models/territory_map/surroundings_relief.dart';
import 'package:torn_pda/models/territory_map/territory_file.dart';
import 'package:torn_pda/providers/city_life_controller.dart';
import 'package:torn_pda/providers/territory_history_controller.dart';
import 'package:torn_pda/providers/territory_map_3d_controller.dart';
import 'package:torn_pda/providers/territory_map_controller.dart';
import 'package:torn_pda/providers/territory_share_controller.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/widgets/territory_map/city_3d_painter.dart';
import 'package:torn_pda/widgets/territory_map/city_ground_painter.dart';
import 'package:torn_pda/widgets/territory_map/city_life_3d_painter.dart';
import 'package:torn_pda/widgets/territory_map/city_life_layer.dart';
import 'package:torn_pda/widgets/territory_map/city_life_shapes.dart';
import 'package:torn_pda/widgets/territory_map/map_load_note.dart';
import 'package:torn_pda/widgets/territory_map/short_animation.dart';
import 'package:torn_pda/widgets/territory_map/surroundings_3d_painter.dart';
import 'package:torn_pda/widgets/territory_map/surroundings_images.dart';
import 'package:torn_pda/widgets/territory_map/surroundings_layer.dart';
import 'package:torn_pda/widgets/territory_map/surroundings_strip_painter.dart';
import 'package:torn_pda/widgets/territory_map/territory_base_painter.dart';
import 'package:torn_pda/widgets/territory_map/territory_map_frame_stats.dart';

const _groundImageWidth = 3072;
const _frameStats = bool.fromEnvironment('TERRITORY_MAP_FRAME_STATS');

class TerritoryMap3dView extends StatefulWidget {
  const TerritoryMap3dView({super.key, this.showLife = true});

  final bool showLife;

  @override
  State<TerritoryMap3dView> createState() => _TerritoryMap3dViewState();
}

class _TerritoryMap3dViewState extends State<TerritoryMap3dView> with SingleTickerProviderStateMixin {
  late final TerritoryMapController _map;
  late final TerritoryMap3dController _scene;
  late final Ticker _ticker;
  late int _focusSeen;
  late final TerritoryShareController _share;
  int _shareSeen = 0;
  final _stats = _frameStats ? TerritoryMapFrameStats() : null;

  Int32List _colors = Int32List(0);
  Object? _colorsFor;
  TerritoryPaints? _paints;
  ({Uint8List full, Uint8List moving})? _ownLines;
  Object? _ownLinesFor;

  CityGroundGrid? _ground;
  Object? _groundFor;
  SurroundingsImages? _photos;
  SurroundingsTerrain? _terrain;
  Completer<void>? _terrainWait;

  final _pulse = ValueNotifier(1.0);
  int _pulseTicks = 0;
  late final _pulseRun = ShortAnimation(
    inView: () => _warsInView,
    onTick: () => _pulse.value = 0.5 + 0.5 * math.sin(++_pulseTicks * shortAnimationEvery.inMilliseconds / 340),
  );
  bool _wasMoving = false;

  CityLifeController? _life;
  double _lookedZoom = 0;
  final _shapes = CityLifeShapes();
  late final AppLifecycleListener _lifecycle;
  bool _shown = false;

  CityRoofs? _roofs;
  final _labels = <String, ui.Paragraph>{};
  final _labelSpace = LabelSpace();

  Offset _focal = Offset.zero;
  double _scale = 1;
  double _rotation = 0;
  int _pointers = 0;
  Offset _doubleTapAt = Offset.zero;

  @override
  void initState() {
    super.initState();
    _map = context.read<TerritoryMapController>();
    _lifecycle = AppLifecycleListener(onStateChange: (_) => _showLife());
    _focusSeen = _map.focusRequest;
    _scene = TerritoryMap3dController(_map)..addListener(_onScene);
    _share = context.read<TerritoryShareController>()
      ..addReader(_visibleArea)
      ..addPhotosWait(_terrainLoaded)
      ..addListener(_onShare);
    _shareSeen = _share.cameraRequest;
    _ticker = createTicker((_) {
      if (!_scene.step()) _ticker.stop();
    });
    SchedulerBinding.instance.addTimingsCallback(_scene.timed);
    unawaited(_map.loadGround());
    unawaited(_map.loadRelief());
    _stats
      ?..mode = '3d'
      ..start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pulseRun.showIn(context);
    _shown = animationsShown(context);
    _showLife();
  }

  @override
  void didUpdateWidget(TerritoryMap3dView old) {
    super.didUpdateWidget(old);
    _showLife();
  }

  void _showLife() => _life?.show(_shown && appResumed && widget.showLife);

  void _lookAt() {
    final life = _life;
    if (life == null || _scene.mesh == null || _scene.size.isEmpty) return;
    final p = _scene.projection;
    _lookedZoom = p.camera.zoom;
    life.lookAt(p.groundInView(), _lookedZoom);
  }

  void _syncLife(TerritoryMapController controller, TerritoryFile file) {
    final ground = controller.ground;
    if (!controller.cityLife || ground == null) {
      final old = _life;
      _life = null;
      if (old != null) WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
      return;
    }
    if (_life == null) {
      _life = CityLifeController(ground, file, withWindows: false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _lookAt();
        _showLife();
      });
    }
    _life!.follow(controller);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _life?.dispose();
    _stats?.stop();
    _share
      ..removeListener(_onShare)
      ..removeReader(_visibleArea)
      ..removePhotosWait(_terrainLoaded);
    SchedulerBinding.instance.removeTimingsCallback(_scene.timed);
    _pulseRun.dispose();
    _pulse.dispose();
    _ticker.dispose();
    _scene
      ..removeListener(_onScene)
      ..dispose();
    _ground?.dispose();
    _photos?.dispose();
    _terrain?.dispose();
    _terrainDrawn();
    super.dispose();
  }

  void _kick() {
    if (!_ticker.isActive) _ticker.start();
  }

  // Ground around the camera target, for links
  Rect? _visibleArea() {
    if (_scene.mesh == null || _scene.size.isEmpty) return null;
    final camera = _scene.camera;
    final size = _scene.size / camera.zoom;
    return Rect.fromCenter(center: Offset(camera.x, camera.y), width: size.width, height: size.height);
  }

  void _onShare() {
    final camera = _share.camera;
    if (_share.cameraRequest == _shareSeen || camera == null || _scene.mesh == null) return;
    _shareSeen = _share.cameraRequest;
    _scene.focusOn(camera, sheetOpen: false);
    _kick();
  }

  void _onScene() {
    _stats?.mode = _scene.low ? '3d low' : '3d';
    if (_scene.active) _kick();
    if (_scene.moving && !_wasMoving) _life?.wake();
    if (!_scene.moving || _scene.camera.zoom != _lookedZoom) _lookAt();
    if (_scene.mesh?.length case final count? when count != _colors.length) {
      setState(() {});
      _onShare();
    }
    // Settling runs the pulse again
    if (_wasMoving && !_scene.moving) {
      _life?.wake();
      _pulseRun
        ..restart()
        ..sync();
    }
    _wasMoving = _scene.moving;
  }

  bool get _warsInView {
    final mesh = _scene.mesh;
    if (mesh == null || _scene.size.isEmpty) return false;
    final p = _scene.projection;
    final screen = Offset.zero & _scene.size;
    return _map.shownWars.any((war) {
      final t = mesh.indexOf[war.territory];
      if (t == null) return false;
      final at = p.project(mesh.centerX[t], mesh.centerY[t], _scene.heights[t]);
      return at != null && screen.contains(at);
    });
  }

  // Flat map fills, made opaque
  Int32List _territoryColors(CityMesh mesh, TerritoryPaints paints, Color background) {
    final out = Int32List(mesh.length);
    final shades = _map.shades;
    final owners = _map.displayOwnership;
    for (var t = 0; t < mesh.length; t++) {
      final code = mesh.codes[t];
      final owner = owners[code];
      final color = _map.colors[owner?.factionId];
      final fill = shades != null
          ? paints.shadeOf(shades[code], color).color
          : (owner?.irradiated ?? false)
          ? paints.glow.color
          : paints.fillOf(color).color;
      var argb = Color.alphaBlend(fill, background).toARGB32();
      if (code == _map.selected) argb = shadeColor(argb, 1, 0.4, 0xFFFFFFFF);
      out[t] = argb;
    }
    return out;
  }

  void _syncGround(TerritoryMapController controller, CityMesh mesh, bool lightTheme, Color background) {
    final ground = controller.ground;
    final key = (ground, controller.surroundings, controller.relief, lightTheme, background);
    if (ground == null || key == _groundFor) return;
    _groundFor = key;
    final paints = GroundPaints(
      ground: ground,
      cells: controller.groundCells,
      lightTheme: lightTheme,
      background: background,
    );
    renderCityGround(paints, mesh.bounds, background, _groundImageWidth).then((image) {
      if (!mounted || _groundFor != key) return image.dispose();
      setState(() {
        _ground?.dispose();
        _ground = CityGroundGrid(image, mesh.bounds);
      });
    });
    _syncTerrain(controller, paints, lightTheme, key);
  }

  // Photos go once the atlas is drawn
  void _syncTerrain(TerritoryMapController controller, GroundPaints paints, bool lightTheme, Object key) {
    _photos?.dispose();
    _photos = null;
    final surroundings = controller.surroundings, relief = controller.relief;
    if (surroundings == null || relief == null) return _terrainDrawn();
    final strip = StripPaints(
      ground: paints,
      surroundings: surroundings,
      cells: controller.stripCells,
      lightTheme: lightTheme,
    );
    final reliefMesh = ReliefMesh(relief, surroundings, resolution: controller.surroundingsQuality.atlasShare);
    var drawing = false;
    late final SurroundingsImages photos;
    photos = _photos = SurroundingsImages(controller.surroundingsPhoto, () {
      if (drawing || !photos.photosReady || !identical(_photos, photos)) return;
      drawing = true;
      renderSurroundingsAtlas(photos.far!, photos.mid, strip, reliefMesh).then((atlas) {
        if (!mounted || _groundFor != key) return atlas.dispose();
        _photos = null;
        photos.dispose();
        setState(() {
          _terrain?.dispose();
          _terrain = SurroundingsTerrain(atlas, reliefMesh, surroundingsAir(lightTheme: lightTheme));
        });
        _terrainDrawn();
      });
    })..show(lightTheme: lightTheme, pixelsPerUnit: 0, quality: controller.surroundingsQuality);
  }

  Future<void> _terrainLoaded() async {
    await _map.loadGround();
    await _map.loadRelief();
    await SchedulerBinding.instance.endOfFrame;
    if (_photos != null) await (_terrainWait ??= Completer()).future;
  }

  void _terrainDrawn() {
    _terrainWait?.complete();
    _terrainWait = null;
  }

  void _onTap(TapUpDetails details) {
    _life?.wake();
    if (_life case final life? when widget.showLife) {
      if (life.tapPlane(planeOnScreen(life.planes, details.localPosition, _scene.projection)) case final joke?) {
        return showPlaneJoke(joke);
      }
    }
    var code = _scene.territoryAt(details.localPosition);
    if (code == null && _map.surroundings != null) {
      code = closureAt(_map.surroundings!, _scene.projection.groundAt(details.localPosition));
    }
    _map.select(code == _map.selected ? null : code);
  }

  void _onScaleStart(ScaleStartDetails details) {
    _life?.wake();
    _scene.hold();
    _focal = details.localFocalPoint;
    _scale = 1;
    _rotation = 0;
    _pointers = details.pointerCount;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount >= 2) {
      _scene.pinch(_focal, details.localFocalPoint, details.scale / _scale, details.rotation - _rotation);
      _scale = details.scale;
      _rotation = details.rotation;
    } else {
      _scene.orbit(details.focalPointDelta);
    }
    _focal = details.localFocalPoint;
    _pointers = details.pointerCount;
    _kick();
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (_pointers == 1) _scene.fling(details.velocity.pixelsPerSecond);
    _kick();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TerritoryMapController>();
    final themeProvider = context.watch<ThemeProvider>();
    final file = controller.territories;
    if (file == null) {
      return Center(
        child: controller.lastError == null
            ? const CircularProgressIndicator()
            : MapLoadNote(error: 'Could not load the map', onRetry: controller.retry),
      );
    }
    unawaited(_scene.load());
    _syncLife(controller, file);
    final life = widget.showLife ? _life : null;

    final lightTheme = themeProvider.currentTheme == AppTheme.light;
    final background = themeProvider.canvas;
    final mesh = _scene.mesh;
    if (mesh != null) {
      if (_roofs?.territory.length != mesh.length) _roofs = CityRoofs(mesh.length);
      if (_scene.syncHeights()) _kick();
      if (_paints?.lightTheme != lightTheme || _paints?.background != background) {
        _paints = TerritoryPaints(lightTheme: lightTheme, background: background);
      }
      final key = (controller.dataVersion, controller.selected, _paints, controller.colors);
      if (key != _colorsFor) {
        _colorsFor = key;
        _colors = _territoryColors(mesh, _paints!, background);
      }
      final linesKey = (mesh, controller.dataVersion, controller.myFactionId);
      if (linesKey != _ownLinesFor) {
        _ownLinesFor = linesKey;
        final mine = [
          for (final code in borderedMine(
            controller.owned[controller.myFactionId] ?? const [],
            controller.shownWars,
            controller.shades,
          ))
            ?mesh.indexOf[code],
        ];
        _ownLines = controller.myFactionId == 0 || mine.isEmpty
            ? null
            : (full: outlineEdges(mesh.full, mine, file.bounds), moving: outlineEdges(mesh.moving, mine, file.bounds));
        _scene.fitOutline(_ownLines);
      }
      _syncGround(controller, mesh, lightTheme, background);
      final focus = controller.focus;
      if (controller.focusRequest != _focusSeen && focus != null) {
        _focusSeen = controller.focusRequest;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _scene.focusOn(focus, sheetOpen: _map.selected != null || _map.openFaction != null);
          _kick();
        });
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _pulseRun.sync();
      });
    }
    final selected = mesh?.indexOf[controller.selected] ?? -1;
    final wars = [
      if (mesh != null)
        for (final war in controller.shownWars) ?mesh.indexOf[war.territory],
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        _scene.size = constraints.biggest;
        return GestureDetector(
          onTapUp: _onTap,
          onDoubleTapDown: (details) => _doubleTapAt = details.localPosition,
          onDoubleTap: () {
            _scene.zoomAt(_doubleTapAt);
            _kick();
          },
          onScaleStart: _onScaleStart,
          onScaleUpdate: _onScaleUpdate,
          onScaleEnd: _onScaleEnd,
          child: Stack(
            fit: StackFit.expand,
            children: [
              RepaintBoundary(
                child: CustomPaint(
                  painter: City3dGroundPainter(
                    scene: _scene,
                    background: background,
                    ground: _ground,
                    terrain: _terrain,
                    lightTheme: lightTheme,
                  ),
                ),
              ),
              if (life != null)
                RepaintBoundary(
                  child: CustomPaint(
                    painter: CityLife3dGroundPainter(
                      life: life,
                      scene: _scene,
                      shapes: _shapes,
                      lightTheme: lightTheme,
                    ),
                  ),
                ),
              RepaintBoundary(
                child: CustomPaint(
                  painter: City3dPainter(
                    scene: _scene,
                    colors: _colors,
                    background: background,
                    pixelRatio: MediaQuery.devicePixelRatioOf(context),
                    lightTheme: lightTheme,
                    night: life?.night.level,
                    ownLines: _ownLines,
                  ),
                ),
              ),
              RepaintBoundary(
                child: CustomPaint(
                  painter: City3dOverlayPainter(scene: _scene, wars: wars, selected: selected, pulse: _pulse),
                ),
              ),
              if (_roofs case final roofs?)
                RepaintBoundary(
                  child: CustomPaint(
                    painter: City3dLabelsPainter(
                      scene: _scene,
                      roofs: roofs,
                      labels: _labels,
                      space: _labelSpace,
                      state: controller.state,
                      ownership: controller.displayOwnership,
                      names: controller.pastDay == null
                          ? const {}
                          : context.read<TerritoryHistoryController>().factionNames,
                      showNames: controller.factionNames,
                      shades: controller.shades,
                      dataVersion: controller.dataVersion,
                    ),
                  ),
                ),
              if (life != null)
                RepaintBoundary(
                  child: CustomPaint(
                    painter: CityLife3dSkyPainter(life: life, scene: _scene, shapes: _shapes, lightTheme: lightTheme),
                  ),
                ),
              if (mesh == null)
                ListenableBuilder(
                  listenable: _scene,
                  builder: (context, _) => Center(
                    child: _scene.failed
                        ? MapLoadNote(error: 'Could not load the 3D map', onRetry: _scene.retry)
                        : const CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
