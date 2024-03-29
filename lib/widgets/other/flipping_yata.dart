// Dart imports:
import 'dart:math';

// Flutter imports:
import 'package:flutter/material.dart';

class FlippingYata extends StatefulWidget {
  @override
  FlippingYataState createState() => FlippingYataState();
}

class FlippingYataState extends State<FlippingYata> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation _flipAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _flipAnim = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1),
      ),
    );

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          return Center(
            child: Container(
              child: Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.002)
                  ..rotateY(2 * pi * _flipAnim.value),
                alignment: Alignment.center,
                child: Container(
                  child: Center(
                    child: Image.asset(
                      'images/icons/yata_logo.png',
                      width: 80,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
