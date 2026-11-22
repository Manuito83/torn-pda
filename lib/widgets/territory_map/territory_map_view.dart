import 'dart:async';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/territory_map/horizon.dart';
import 'package:torn_pda/models/territory_map/map_coordinates.dart';
import 'package:torn_pda/models/territory_map/map_views.dart';
import 'package:torn_pda/models/territory_map/surroundings.dart';
import 'package:torn_pda/models/territory_map/territory_file.dart';
import 'package:torn_pda/providers/city_life_controller.dart';
import 'package:torn_pda/providers/territory_history_controller.dart';
import 'package:torn_pda/providers/territory_map_controller.dart';
import 'package:torn_pda/providers/territory_share_controller.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/widgets/territory_map/city_ground_painter.dart';
import 'package:torn_pda/widgets/territory_map/city_life_layer.dart';
import 'package:torn_pda/widgets/territory_map/city_night_layer.dart';
import 'package:torn_pda/widgets/territory_map/irradiated_glow.dart';
import 'package:torn_pda/widgets/territory_map/map_layer.dart';
import 'package:torn_pda/widgets/territory_map/map_load_note.dart';
import 'package:torn_pda/widgets/territory_map/surroundings_images.dart';
import 'package:torn_pda/widgets/territory_map/surroundings_layer.dart';
import 'package:torn_pda/widgets/territory_map/surroundings_strip_painter.dart';
import 'package:torn_pda/widgets/territory_map/territory_base_painter.dart';
import 'package:torn_pda/widgets/territory_map/territory_map_frame_stats.dart';
import 'package:torn_pda/widgets/territory_map/territory_map_raster.dart';
import 'package:torn_pda/widgets/territory_map/territory_overlay_painter.dart';

const _maxScale = 6.0;
const _doubleTapZoom = 2.5;
const _maxFarImageWidth = 3072;
const _focusMaxScale = 3.0;
const _frameStats = bool.fromEnvironment('TERRITORY_MAP_FRAME_STATS');

class TerritoryMapView extends StatefulWidget {
  const TerritoryMapView({super.key, this.extraLayers = const [], this.onLayerTap, this.showLife = true});

  final List<MapLayer> extraLayers;
  final ValueChanged<Object>? onLayerTap;
  final bool showLife;

  @override
  State<TerritoryMapView> createState() => _TerritoryMapViewState();
}

class _TerritoryMapViewState extends State<TerritoryMapView> with SingleTickerProviderStateMixin {
  final _transform = TransformationController();
  late final AnimationController _zoom = AnimationController(vsync: this, duration: const Duration(milliseconds: 250))
    ..addListener(() => _transform.value = _zoomTween.evaluate(_zoom));
  var _zoomTween = Matrix4Tween();
  Offset _doubleTapAt = Offset.zero;

  late final TerritoryMapController _controller;
  late final TerritoryMapRaster _raster;
  late final _photos = SurroundingsImages(_controller.surroundingsPhoto, () {
    if (mounted) setState(() {});
  });
  bool _cameraSet = false;
  late int _focusSeen = _controller.focusRequest;
  late final TerritoryShareController _share;
  int _shareSeen = 0;
  final _labels = <String, ui.Paragraph>{};

  final _opened = Stopwatch()..start();
  bool _firstFrameLogged = false;
  final _stats = _frameStats ? TerritoryMapFrameStats() : null;
  CityLifeController? _life;

  @override
  void initState() {
    super.initState();
    _controller = context.read<TerritoryMapController>();
    unawaited(_controller.loadGround());
    _share = context.read<TerritoryShareController>()
      ..addReader(_visibleScene)
      ..addPhotosWait(_photosLoaded)
      ..addListener(_onShare);
    _shareSeen = _share.cameraRequest;
    _raster = TerritoryMapRaster(_controller, _transform, () {
      if (mounted) setState(() {});
    });
    _transform.addListener(() {
      _keepCityInView();
      _raster.onMove();
      _life?.wake();
    });
    _stats?.start();
  }

  @override
  void dispose() {
    _share.removeListener(_onShare);
    _share
      ..removeReader(_visibleScene)
      ..removePhotosWait(_photosLoaded);
    final size = _raster.size;
    if (_cameraSet && size != null) {
      final center = _transform.toScene(size.center(Offset.zero));
      _controller.saveCamera('${center.dx},${center.dy},${_transform.value.getMaxScaleOnAxis()}');
    }
    _stats?.stop();
    _life?.dispose();
    _zoom.dispose();
    _transform.dispose();
    _raster.dispose();
    _photos.dispose();
    super.dispose();
  }

  void _keepCityInView() {
    final size = _raster.size;
    final file = _controller.territories;
    if (size == null || file == null) return;
    final matrix = _transform.value;
    final translation = Offset(matrix.storage[12], matrix.storage[13]);
    final around = _controller.surroundings;
    final clamped = clampTranslation(
      translation,
      matrix.getMaxScaleOnAxis(),
      file.bounds,
      size,
      reach: around == null ? null : viewReach(around.bounds, around.horizon, around.far),
    );
    if (clamped != translation) _transform.value = matrix.clone()..setTranslationRaw(clamped.dx, clamped.dy, 0);
  }

  void _keepCenter(Size before, Size size, Rect bounds) {
    if (!mounted) return;
    final center = _transform.toScene(before.center(Offset.zero));
    final scale = _transform.value.getMaxScaleOnAxis().clamp(fitScale(bounds, size) * 0.9, _maxScale);
    final translation = size.center(Offset.zero) - center * scale;
    _transform.value = Matrix4.identity()
      ..setTranslationRaw(translation.dx, translation.dy, 0)
      ..scaleByDouble(scale, scale, scale, 1);
  }

  void _setCamera(Size size, Rect bounds) {
    var camera = cameraToFit(bounds, size);
    final saved = _controller.savedCamera.split(',').map(double.tryParse).toList();
    if (saved.length == 3 && !saved.contains(null)) {
      final scale = saved[2]!.clamp(camera.scale, _maxScale);
      camera = (scale: scale, translation: size.center(Offset.zero) - Offset(saved[0]!, saved[1]!) * scale);
    }
    _transform.value = Matrix4.identity()
      ..setTranslationRaw(camera.translation.dx, camera.translation.dy, 0)
      ..scaleByDouble(camera.scale, camera.scale, camera.scale, 1);
    _cameraSet = true;
  }

  void _onTap(TapUpDetails details) {
    final point = _transform.toScene(details.localPosition);
    final scale = _transform.value.getMaxScaleOnAxis();
    for (final layer in widget.extraLayers) {
      final hit = layer.hitTest(point, scale);
      if (hit != null) return widget.onLayerTap?.call(hit);
    }
    if (_life?.tap(point, scale) case final joke?) return showPlaneJoke(joke);
    final around = _controller.surroundings;
    final code = _controller.index?.territoryAt(point)?.code ?? (around == null ? null : closureAt(around, point));
    _controller.select(code == _controller.selected ? null : code);
  }

  void _onDoubleTap() {
    final scale = _transform.value.getMaxScaleOnAxis();
    final target = (scale * _doubleTapZoom).clamp(scale, _maxScale);
    final point = _transform.toScene(_doubleTapAt);
    _animateCamera(target, _doubleTapAt - point * target);
  }

  // Room for chip and sheet
  void _focusOn(Rect area) {
    final size = _raster.size;
    final file = _controller.territories;
    if (!mounted || size == null || file == null) return;
    final sheetOpen = _controller.selected != null || _controller.openFaction != null;
    final room = Rect.fromLTRB(24, 48, size.width - 24, size.height * (sheetOpen ? 0.55 : 1) - 24);
    final camera = cameraToFit(area, room.size, maxScale: _focusMaxScale);
    final scale = camera.scale.clamp(fitScale(file.bounds, size) * 0.9, _maxScale);
    _animateCamera(scale, room.topLeft + room.size.center(Offset.zero) - area.center * scale);
  }

  Rect? _visibleScene() => _raster.visibleScene;

  Future<void> _photosLoaded() async {
    await _controller.loadGround();
    await WidgetsBinding.instance.endOfFrame;
    await _photos.loaded;
  }

  // Shows what another player shared
  void _onShare() {
    final camera = _share.camera;
    final size = _raster.size;
    final file = _controller.territories;
    if (_share.cameraRequest == _shareSeen || camera == null || size == null || file == null) return;
    _shareSeen = _share.cameraRequest;
    final scale = cameraToFit(camera, size).scale.clamp(fitScale(file.bounds, size) * 0.9, _maxScale);
    _animateCamera(scale, size.center(Offset.zero) - camera.center * scale);
  }

  void _syncLife(TerritoryMapController controller, TerritoryFile file) {
    final ground = controller.ground;
    final old = _life;
    if (!controller.cityLife || ground == null || old?.surroundings != controller.surroundings) {
      _life = null;
      if (old != null) WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    }
    if (!controller.cityLife || ground == null) return;
    (_life ??= CityLifeController(
      ground,
      file,
      surroundings: controller.surroundings,
      budget: controller.surroundingsQuality.outside,
    )).follow(controller);
  }

  void _animateCamera(double scale, Offset translation) {
    _zoomTween = Matrix4Tween(
      begin: _transform.value.clone(),
      end: Matrix4.identity()
        ..setTranslationRaw(translation.dx, translation.dy, 0)
        ..scaleByDouble(scale, scale, scale, 1),
    );
    _zoom.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TerritoryMapController>();
    final themeProvider = context.watch<ThemeProvider>();
    final file = controller.territories;
    final index = controller.index;
    if (file == null || index == null) {
      return Center(
        child: controller.lastError == null
            ? const CircularProgressIndicator()
            : MapLoadNote(error: 'Could not load the map', onRetry: controller.retry),
      );
    }

    final lightTheme = themeProvider.currentTheme == AppTheme.light;
    final background = themeProvider.canvas;
    final ground = controller.ground;
    final surroundings = controller.surroundings;
    final old = _raster.paints;
    if (old?.lightTheme != lightTheme ||
        old?.background != background ||
        old?.ground?.ground != ground ||
        old?.strip?.surroundings != surroundings) {
      final groundPaints = ground == null
          ? null
          : GroundPaints(ground: ground, cells: controller.groundCells, lightTheme: lightTheme, background: background);
      _raster.paints = TerritoryPaints(
        lightTheme: lightTheme,
        background: background,
        ground: groundPaints,
        strip: groundPaints == null || surroundings == null
            ? null
            : StripPaints(
                ground: groundPaints,
                surroundings: surroundings,
                cells: controller.stripCells,
                lightTheme: lightTheme,
              ),
      );
    }
    _syncLife(controller, file);
    final life = widget.showLife ? _life : null;
    final paints = _raster.paints!;
    _raster
      ..holdStill = life != null
      ..dropSnapshot();
    final glowing = glowingCodes(controller.shades);

    final focus = controller.focus;
    if (controller.focusRequest != _focusSeen && focus != null) {
      _focusSeen = controller.focusRequest;
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusOn(focus));
    }

    if (_stats != null && !_firstFrameLogged) {
      _firstFrameLogged = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint('territory map: first frame in ${_opened.elapsedMilliseconds} ms');
      });
    }

    final pixelRatio = _raster.pixelRatio = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final before = _raster.size;
        _raster.size = size;
        if (!_cameraSet) {
          _setCamera(size, file.bounds);
        } else if (before != null && (before.width > before.height) != (size.width > size.height)) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _keepCenter(before, size, file.bounds));
        }

        final imageWidth = (3 * size.width * pixelRatio).clamp(1024, _maxFarImageWidth).round();
        _raster
          ..drawFarImage(imageWidth)
          ..keepStill();
        if (paints.strip case final strip?) _photos.drawStrip(strip, controller.surroundingsQuality);

        // Air past the horizon
        return ColoredBox(
          color: surroundingsAir(lightTheme: lightTheme),
          child: GestureDetector(
            onTapUp: _onTap,
            onDoubleTapDown: (details) => _doubleTapAt = details.localPosition,
            onDoubleTap: _onDoubleTap,
            child: InteractiveViewer.builder(
              transformationController: _transform,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              minScale: fitScale(file.bounds, size) * 0.9,
              maxScale: _maxScale,
              builder: (context, quad) {
                final visible = Rect.fromPoints(
                  Offset(quad.point0.x, quad.point0.y),
                  Offset(quad.point2.x, quad.point2.y),
                );
                final scale = _transform.value.getMaxScaleOnAxis();
                final image = _raster.farImage;
                final snapshot = _raster.snapshot;
                final useImage = image != null && scale * pixelRatio <= image.width / file.bounds.width;
                final farStrip = useImage || (snapshot != null && !_raster.still);
                if (surroundings != null) {
                  _photos.show(
                    lightTheme: lightTheme,
                    pixelsPerUnit: scale * pixelRatio,
                    quality: controller.surroundingsQuality,
                  );
                }
                _stats?.mode = useImage
                    ? 'image'
                    : snapshot != null
                    ? 'snapshot'
                    : 'vectors';

                return SizedBox(
                  width: file.bounds.right,
                  height: file.bounds.bottom,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      SurroundingsLayer(
                        images: _photos,
                        surroundings: surroundings,
                        bounds: file.bounds,
                        background: paints.backgroundFill,
                        strip: paints.strip,
                        mode: farStrip
                            ? StripMode.tiles
                            : snapshot == null
                            ? StripMode.vectors
                            : StripMode.none,
                        visible: visible,
                        scale: scale,
                        snapshotRect: snapshot == null ? null : _raster.snapshotRect,
                      ),
                      RepaintBoundary(
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: useImage || snapshot != null
                              ? null
                              : paints.ground != null
                              ? CityGroundPainter(
                                  paints: paints.ground!,
                                  bounds: file.bounds,
                                  visible: visible,
                                  scale: scale,
                                )
                              : null,
                        ),
                      ),
                      RepaintBoundary(
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: TerritoryBasePainter(
                            file: file,
                            paths: controller.paths,
                            outlines: controller.outlines,
                            index: index,
                            ownership: controller.displayOwnership,
                            wars: controller.shownWars,
                            colors: controller.colors,
                            paints: paints,
                            dataVersion: controller.dataVersion,
                            visible: visible,
                            scale: scale,
                            farImage: useImage || (snapshot != null && !_raster.still) ? image : null,
                            snapshot: snapshot,
                            snapshotRect: _raster.snapshotRect,
                            shades: controller.shades,
                          ),
                        ),
                      ),
                      if (life != null && life.night.on)
                        CityNightLayer(
                          night: life.night,
                          index: index,
                          visible: visible,
                          scale: scale,
                          lightTheme: lightTheme,
                          surroundings: surroundings,
                          photos: _photos,
                        ),
                      if (glowing.isNotEmpty)
                        IrradiatedGlow(
                          codes: glowing,
                          territories: file.territories,
                          paths: controller.paths,
                          visible: visible,
                          scale: scale,
                        ),
                      if (life != null)
                        CityLifeLayer(life: life, visible: visible, scale: scale, lightTheme: lightTheme),
                      CustomPaint(
                        size: Size.infinite,
                        painter: TerritoryOverlayPainter(
                          file: file,
                          paths: controller.paths,
                          outlines: controller.outlines,
                          closures: controller.closurePaths,
                          index: index,
                          state: controller.state,
                          ownership: controller.displayOwnership,
                          wars: controller.shownWars,
                          names: controller.pastDay == null
                              ? const {}
                              : context.read<TerritoryHistoryController>().factionNames,
                          dataVersion: controller.dataVersion,
                          selected: controller.selected,
                          highlighted: controller.owned[controller.highlighted],
                          lightTheme: lightTheme,
                          visible: visible,
                          scale: scale,
                          labels: _labels,
                          mine: controller.myFactionId == 0
                              ? const []
                              : controller.owned[controller.myFactionId] ?? const [],
                          showNames: controller.factionNames,
                          shades: controller.shades,
                        ),
                        foregroundPainter: widget.extraLayers.isEmpty
                            ? null
                            : MapLayersPainter(widget.extraLayers, MapViewport(visible, scale)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
