import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:torn_pda/models/territory_map/territory_file.dart';
import 'package:torn_pda/widgets/territory_map/short_animation.dart';

const _framesPerStripe = 16;
const _stripePixels = 16.0;

// Moving stripes over the irradiated, own layer
class IrradiatedGlow extends StatefulWidget {
  const IrradiatedGlow({
    super.key,
    required this.codes,
    required this.territories,
    required this.paths,
    required this.visible,
    required this.scale,
  });

  final List<String> codes;
  final Map<String, Territory> territories;
  final Map<String, Path> paths;
  final Rect visible;
  final double scale;

  @override
  State<IrradiatedGlow> createState() => _IrradiatedGlowState();
}

class _IrradiatedGlowState extends State<IrradiatedGlow> {
  final _frame = ValueNotifier(0);
  late final _run = ShortAnimation(inView: () => _inView, onTick: () => _frame.value++);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _run.showIn(context);
  }

  // Moving the map runs it again
  @override
  void didUpdateWidget(IrradiatedGlow old) {
    super.didUpdateWidget(old);
    if (old.visible != widget.visible || old.scale != widget.scale) _run.restart();
    _run.sync();
  }

  bool get _inView => widget.codes.any((code) {
    final bounds = widget.territories[code]?.bounds;
    return bounds != null && widget.visible.overlaps(bounds);
  });

  @override
  void dispose() {
    _run.dispose();
    _frame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(size: Size.infinite, painter: _GlowPainter(widget, _frame)),
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  _GlowPainter(this.glow, this.frame) : super(repaint: frame);

  final IrradiatedGlow glow;
  final ValueNotifier<int> frame;
  final _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final period = _stripePixels / glow.scale;
    final shift = period * (frame.value % _framesPerStripe) / _framesPerStripe;
    const light = Color(0x80FFFFFF);
    final shader = ui.Gradient.linear(
      Offset(shift, shift),
      Offset(shift + period, shift + period),
      [Colors.transparent, light, Colors.transparent],
      [0.2, 0.5, 0.8],
      TileMode.repeated,
    );
    _paint.shader = shader;
    for (final code in glow.codes) {
      final bounds = glow.territories[code]?.bounds;
      final path = glow.paths[code];
      if (bounds == null || path == null || !glow.visible.overlaps(bounds)) continue;
      canvas.drawPath(path, _paint);
    }
    shader.dispose();
  }

  @override
  bool shouldRepaint(_GlowPainter old) =>
      old.glow.codes != glow.codes || old.glow.visible != glow.visible || old.glow.scale != glow.scale;
}
