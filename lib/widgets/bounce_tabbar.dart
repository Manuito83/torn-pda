import 'package:flutter/material.dart';
import 'package:torn_pda/providers/theme_provider.dart';

class BounceTabBar extends StatefulWidget {
  final ThemeProvider? themeProvider;
  final List<Widget> items;
  final ValueChanged<int> onTabChanged;
  final int initialIndex;
  final double movement;
  final bool locationTop;

  const BounceTabBar({
    Key? key,
    this.themeProvider,
    required this.items,
    required this.onTabChanged,
    this.initialIndex = 0,
    this.movement = 150,
    required this.locationTop,
  }) : super(key: key);

  @override
  _BounceTabBarState createState() => _BounceTabBarState();
}

class _BounceTabBarState extends State<BounceTabBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation _animTabBarIn;
  late Animation _animTabBarOut;
  late Animation _animCircleItem;
  late Animation _animElevationIn;
  late Animation _animElevationOut;

  int? _currentIndex;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _animTabBarIn = CurveTween(
      curve: Interval(
        0.1,
        0.6,
        curve: Curves.decelerate,
      ),
    ).animate(_controller);

    _animTabBarOut = CurveTween(
      curve: Interval(
        0.6,
        1.0,
        curve: Curves.bounceOut,
      ),
    ).animate(_controller);

    _animCircleItem = CurveTween(
      curve: Interval(
        0.0,
        0.5,
      ),
    ).animate(_controller);

    _animElevationIn = CurveTween(
      curve: Interval(
        0.3,
        0.5,
        curve: Curves.decelerate,
      ),
    ).animate(_controller);

    _animElevationOut = CurveTween(
      curve: Interval(
        0.55,
        1.0,
        curve: Curves.bounceOut,
      ),
    ).animate(_controller);

    _currentIndex = widget.initialIndex;
    _controller.forward(from: 1.0);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    double currentWidth = width;
    double currentElevation = 0.0;
    final movement = widget.movement;
    return SizedBox(
      height: 45,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          currentWidth = width - movement * _animTabBarIn.value + movement * _animTabBarOut.value;

          currentElevation = -movement * _animElevationIn.value / 2 +
              (movement - kBottomNavigationBarHeight / 2) * _animElevationOut.value / 2;

          return Center(
            child: Container(
              width: currentWidth,
              decoration: BoxDecoration(
                color: widget.themeProvider!.statusBar,
                borderRadius: BorderRadius.vertical(
                  top: widget.locationTop ? Radius.zero : Radius.circular(20),
                  bottom: widget.locationTop ? Radius.circular(20) : Radius.zero,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  widget.items.length,
                  (index) {
                    final child = widget.items[index];
                    final innerWidget = CircleAvatar(
                      radius: 25.0,
                      backgroundColor: widget.themeProvider!.statusBar,
                      child: child,
                    );
                    if (index == _currentIndex) {
                      return Expanded(
                        child: CustomPaint(
                          foregroundPainter: _CircleItemPainter(_animCircleItem.value),
                          child: Transform.translate(
                            offset: widget.locationTop ? Offset(0.0, -currentElevation) : Offset(0.0, currentElevation),
                            child: innerWidget,
                          ),
                        ),
                      );
                    } else {
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            widget.onTabChanged(index);
                            setState(() {
                              _currentIndex = index;
                            });
                            _controller.forward(from: 0.0);
                          },
                          child: innerWidget,
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CircleItemPainter extends CustomPainter {
  final double progress;

  _CircleItemPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = 20.0 * progress;
    final strokeWidth = 10.0;
    final currentStrokeWidth = strokeWidth * (1 - progress);
    if (progress < 1.0) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = currentStrokeWidth,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
