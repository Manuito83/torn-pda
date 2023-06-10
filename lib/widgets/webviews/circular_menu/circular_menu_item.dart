import 'package:flutter/material.dart';

class CircularMenuItem extends StatelessWidget {
  /// if icon and animatedIcon are passed, icon will be ignored
  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final VoidCallback onLongPress;
  final double iconSize;
  final double padding;
  final double margin;
  final List<BoxShadow> boxShadow;

  /// if animatedIcon and icon are passed, icon will be ignored
  final AnimatedIcon animatedIcon;

  /// creates a menu item .
  /// [onTap] must not be null.
  /// [padding] and [margin]  must be equal or greater than zero.
  const CircularMenuItem({
    @required this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.icon,
    this.color,
    this.iconSize = 25,
    this.boxShadow,
    this.iconColor,
    this.animatedIcon,
    this.padding = 10,
    this.margin = 10,
  });

  Widget _buildCircularMenuItem(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: color ?? Colors.grey,
                blurRadius: 2,
              ),
            ],
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: Material(
          color: color ?? Theme.of(context).primaryColor,
          child: InkWell(
            onTap: onTap,
            onDoubleTap: onDoubleTap,
            onLongPress: onLongPress,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: animatedIcon ??
                  Icon(
                    icon,
                    size: iconSize,
                    color: iconColor ?? Colors.white,
                  ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildCircularMenuItem(context);
  }
}
