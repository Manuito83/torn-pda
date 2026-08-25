import 'dart:math' as math;

import 'package:flutter/material.dart';

class GoldStorageIcon extends StatefulWidget {
  const GoldStorageIcon({this.size = 20, super.key});

  final double size;

  @override
  State<GoldStorageIcon> createState() => _GoldStorageIconState();
}

class _GoldStorageIconState extends State<GoldStorageIcon> with SingleTickerProviderStateMixin {
  // Full cycle is 4s; the shine sweep and sparkle only play during the first fraction
  static const _sweepFraction = 0.35;

  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4))
    ..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = Icon(Icons.sd_storage, size: widget.size, color: Colors.white);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final sweep = (_controller.value / _sweepFraction).clamp(0.0, 1.0);
        final p = -0.4 + 1.8 * sweep;
        final twinkle = math.sin(math.pi * sweep);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFD54F), Color(0xFFE0A80D), Color(0xFFB8860B)],
              ).createShader(bounds),
              child: icon,
            ),
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: const [Colors.transparent, Colors.white70, Colors.transparent],
                stops: [(p - 0.25).clamp(0.0, 1.0), p.clamp(0.0, 1.0), (p + 0.25).clamp(0.0, 1.0)],
              ).createShader(bounds),
              child: icon,
            ),
            Positioned(
              top: -widget.size * 0.18,
              right: -widget.size * 0.18,
              child: Opacity(
                opacity: twinkle,
                child: Icon(Icons.auto_awesome, size: widget.size * 0.5, color: const Color(0xFFFFF176)),
              ),
            ),
          ],
        );
      },
    );
  }
}
