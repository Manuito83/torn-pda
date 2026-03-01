// Flutter imports:
import 'package:flutter/material.dart';

class CustomOffsetAnimation extends StatefulWidget {
  final AnimationController? controller;
  final Widget? child;

  const CustomOffsetAnimation({super.key, this.controller, this.child});

  @override
  CustomOffsetAnimationState createState() => CustomOffsetAnimationState();
}

class CustomOffsetAnimationState extends State<CustomOffsetAnimation> {
  late Tween<Offset> tweenOffset;
  late Tween<double> tweenScale;

  late CurvedAnimation animation;

  @override
  void initState() {
    tweenOffset = Tween<Offset>(
      begin: const Offset(0.0, 0.8),
      end: Offset.zero,
    );
    tweenScale = Tween<double>(begin: 0.3, end: 1.0);
    animation = CurvedAnimation(parent: widget.controller!, curve: Curves.decelerate);
    super.initState();
  }

  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller!,
      builder: (BuildContext context, Widget? child) {
        return FractionalTranslation(
          translation: tweenOffset.evaluate(animation),
          child: ClipRect(
            child: Transform.scale(
              scale: tweenScale.evaluate(animation),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}
