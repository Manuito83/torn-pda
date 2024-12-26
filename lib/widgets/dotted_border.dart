import 'dart:math';

import 'package:flutter/material.dart';

class DottedBorder extends StatelessWidget {
  final Widget child;
  final Color color;
  final double strokeWidth;
  final List<double> dashPattern;
  final EdgeInsetsGeometry padding;

  const DottedBorder({
    super.key,
    required this.child,
    required this.color,
    this.strokeWidth = 1.0,
    required this.dashPattern, // e.g. [4,2] means dash of 4px, gap of 2px
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DottedBorderPainter(
        color: color,
        strokeWidth: strokeWidth,
        dashPattern: dashPattern,
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class DottedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final List<double> dashPattern;

  DottedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashPattern,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // Draw four sides of dashed border
    _drawDashedLine(canvas, Offset(0, 0), Offset(size.width, 0), paint);
    _drawDashedLine(canvas, Offset(size.width, 0), Offset(size.width, size.height), paint);
    _drawDashedLine(canvas, Offset(0, size.height), Offset(size.width, size.height), paint);
    _drawDashedLine(canvas, Offset(0, 0), Offset(0, size.height), paint);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    final totalDistance = (end - start).distance;
    final direction = (end - start).direction;
    double distanceCovered = 0.0;
    Offset current = start;
    int patternIndex = 0;

    while (distanceCovered < totalDistance) {
      final currentDash = dashPattern[patternIndex % dashPattern.length];
      final remain = totalDistance - distanceCovered;
      // Determine the length to draw for the current segment
      final drawLength = remain < currentDash ? remain : currentDash;

      final endPoint = current.translate(
        drawLength * cos(direction),
        drawLength * sin(direction),
      );

      // Even indices are dashes, odd are gaps
      if (patternIndex % 2 == 0) {
        canvas.drawLine(current, endPoint, paint);
      }

      current = endPoint;
      distanceCovered += currentDash;
      patternIndex++;
    }
  }

  @override
  bool shouldRepaint(covariant DottedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashPattern != dashPattern;
  }
}
