import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/territory_map/map_pictures.dart';
import 'package:torn_pda/models/territory_map/map_views.dart';
import 'package:torn_pda/models/territory_map/map_state.dart';
import 'package:torn_pda/providers/territory_map_controller.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/user_helper.dart';
import 'package:torn_pda/widgets/territory_map/city_ground_painter.dart';
import 'package:torn_pda/widgets/territory_map/map_load_note.dart';
import 'package:torn_pda/widgets/territory_map/territory_base_painter.dart';

const _timeout = Duration(seconds: 15);
const _maxPixels = 1024;

// A part of the city, drawn once
class MapThumbnail extends StatefulWidget {
  const MapThumbnail({
    super.key,
    this.camera,
    this.factionId,
    required this.aspect,
    this.padding = EdgeInsets.zero,
    this.radius = BorderRadius.zero,
  }) : assert((camera == null) != (factionId == null));

  // Scene units
  final Rect? camera;

  // Its territories and wars, the rest grey
  final int? factionId;
  final double aspect;

  // Both gone when the faction has nothing
  final EdgeInsets padding;
  final BorderRadius radius;

  @override
  State<MapThumbnail> createState() => _MapThumbnailState();
}

class _MapThumbnailState extends State<MapThumbnail> {
  ui.Image? _image;
  int _width = 0;
  bool _failed = false;
  bool _empty = false;

  @override
  void initState() {
    super.initState();
    _empty = _knownEmpty();
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  bool _knownEmpty() {
    final faction = widget.factionId;
    final map = context.read<TerritoryMapController>();
    final file = map.territories;
    final state = map.state;
    if (faction == null || file == null || state == null) return false;
    return factionPicture(faction, state, file.territories, minSize: 0) == null;
  }

  Future<void> _load() async {
    if (_failed) setState(() => _failed = false);
    final map = context.read<TerritoryMapController>();
    final theme = context.read<ThemeProvider>();
    try {
      await map.openWithState(this, myFactionId: UserHelper.factionId, timeout: _timeout);
      final file = map.territories;
      final state = map.state;
      if (file == null || state == null) throw StateError('no map data');

      var area = widget.camera;
      Map<String, Shade>? shades;
      var wars = const <TerritoryWar>[];
      if (widget.factionId case final faction?) {
        final picture = factionPicture(faction, state, file.territories, minSize: smallestPicture(file.bounds));
        if (picture == null) {
          if (mounted) setState(() => _empty = true);
          return;
        }
        (area: area, shades: shades, wars: wars) = picture;
      }
      final shown = fitAspect(area!, widget.aspect);

      final lightTheme = theme.currentTheme == AppTheme.light;
      final ground = map.ground;
      final image = await renderFarImage(
        file: file,
        paths: map.paths,
        outlines: map.outlines,
        ownership: state.ownership,
        colors: map.colors,
        paints: TerritoryPaints(
          lightTheme: lightTheme,
          background: theme.canvas,
          ground: ground == null
              ? null
              : GroundPaints(ground: ground, cells: map.groundCells, lightTheme: lightTheme, background: theme.canvas),
        ),
        width: _width,
        area: shown,
        territories: map.index?.visibleIn(shown),
        shades: shades,
        wars: wars,
      );
      if (!mounted) return image.dispose();
      setState(() {
        _image?.dispose();
        _image = image;
      });
    } catch (e) {
      debugPrint('territory map: thumbnail failed: $e');
      if (mounted) setState(() => _failed = true);
    } finally {
      map.close(this);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_empty) return const SizedBox.shrink();
    return Padding(
      padding: widget.padding,
      child: ClipRRect(
        borderRadius: widget.radius,
        child: AspectRatio(
          aspectRatio: widget.aspect,
          child: LayoutBuilder(
            builder: (context, box) {
              if (_width == 0 && box.maxWidth > 0) {
                _width = math.min((box.maxWidth * MediaQuery.devicePixelRatioOf(context)).round(), _maxPixels);
                unawaited(_load());
              }
              final image = _image;
              if (image != null) return RawImage(image: image, fit: BoxFit.cover);
              return Center(
                child: _failed
                    ? MapLoadNote(error: 'Map not available', onRetry: _load)
                    : const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              );
            },
          ),
        ),
      ),
    );
  }
}
