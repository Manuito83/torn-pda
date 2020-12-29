import 'package:flutter/material.dart';
import 'dart:math';

class FlippingYata extends StatefulWidget {
  @override
  _FlippingYataState createState() => _FlippingYataState();
}

class _FlippingYataState extends State<FlippingYata>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Animation _flip_anim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    _flip_anim = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 1, curve: Curves.linear),
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
        builder: (BuildContext context, Widget child) {
          return Center(
            child: Container(
              child: Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.002)
                  ..rotateY(2 * pi * _flip_anim.value),
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
