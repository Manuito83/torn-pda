import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:torn_pda/providers/webview_provider.dart';

import 'package:torn_pda/widgets/webviews/circular_menu/circular_menu_item.dart';

class CircularMenuFixed extends StatefulWidget {
  /// list of CircularMenuItem contains at least two items.
  final List<CircularMenuItem> items;

  /// menu alignment
  final AlignmentGeometry alignment;

  /// menu radius
  final double radius;

  /// widget holds actual page content
  final Widget? backgroundWidget;

  /// animation duration
  final Duration animationDuration;

  /// animation curve in forward
  final Curve curve;

  /// animation curve in reverse
  final Curve reverseCurve;

  /// callback
  final VoidCallback? doubleTapped;
  final VoidCallback? longPressed;
  final Color? toggleButtonColor;
  final double toggleButtonSize;
  final List<BoxShadow>? toggleButtonBoxShadow;
  final double toggleButtonPadding;
  final double toggleButtonMargin;
  final Color? toggleButtonIconColor;
  final AnimatedIconData toggleButtonAnimatedIconData;

  final WebViewProvider? webViewProvider;

  CircularMenuFixed({
    required this.items,
    required this.webViewProvider,
    this.doubleTapped,
    this.longPressed,
    this.alignment = Alignment.bottomCenter,
    this.radius = 50,
    this.backgroundWidget,
    this.animationDuration = const Duration(),
    this.curve = Curves.decelerate,
    this.reverseCurve = Curves.decelerate,
    this.toggleButtonColor,
    this.toggleButtonBoxShadow,
    this.toggleButtonMargin = 10,
    this.toggleButtonPadding = 10,
    this.toggleButtonSize = 40,
    this.toggleButtonIconColor,
    this.toggleButtonAnimatedIconData = AnimatedIcons.menu_close,
  }) : assert(items.isNotEmpty, 'items can not be empty list');

  @override
  CircularMenuFixedState createState() => CircularMenuFixedState();
}

class CircularMenuFixedState extends State<CircularMenuFixed> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _animation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: widget.curve,
        reverseCurve: widget.reverseCurve,
      ),
    );

    super.initState();
  }

  List<Widget> _buildMenuItems() {
    List<Widget> items = [];
    widget.items.asMap().forEach((index, item) {
      items.add(
        Visibility(
          visible: widget.webViewProvider!.verticalMenuCurrentIndex == -1,
          child: Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Transform.translate(
                offset: Offset.fromDirection(-math.pi / 2, _animation.value * widget.radius + (50 * index)),
                child: Transform.scale(
                  scale: _animation.value,
                  child: Transform.rotate(
                    angle: _animation.value * (math.pi * 2),
                    child: item,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
    return items;
  }

  Widget _buildMenuButton(BuildContext context) {
    return Positioned.fill(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: CircularMenuItem(
          margin: widget.toggleButtonMargin,
          color: widget.toggleButtonColor ?? Theme.of(context).primaryColor,
          padding: 50,
          onTap: () async {
            if (!mounted) return;
            // Opens the menu
            if (_animationController.status == AnimationStatus.dismissed) {
              widget.webViewProvider!.verticalMenuOpen();
            } else {
              // Closes the menu but permits the menu to shift from one tab to another
              // without the user noticing (closes and reopens the new tapped tab)
              widget.webViewProvider!.verticalMenuClose();
              if (widget.webViewProvider!.verticalMenuCurrentIndex != -1) {
                widget.webViewProvider!.verticalMenuCurrentIndex = -1;
                widget.webViewProvider!.verticalMenuOpen();
              }
            }
            widget.webViewProvider!.verticalMenuCurrentIndex = -1;
          },
          onDoubleTap: () async {
            if (widget.doubleTapped != null) {
              widget.doubleTapped!();
              return;
            }
          },
          onLongPress: () {
            // We might want to close the fullscreen mode
            if (widget.longPressed != null) {
              widget.longPressed!();
              return;
            }

            // ... otherwise, do as with 'onTap'
            if (_animationController.status == AnimationStatus.dismissed) {
              widget.webViewProvider!.verticalMenuOpen();
            } else {
              widget.webViewProvider!.verticalMenuClose();
              if (widget.webViewProvider!.verticalMenuCurrentIndex != -1) {
                widget.webViewProvider!.verticalMenuCurrentIndex = -1;
                widget.webViewProvider!.verticalMenuOpen();
              }
            }
            widget.webViewProvider!.verticalMenuCurrentIndex = -1;
          },
          boxShadow: widget.toggleButtonBoxShadow,
          animatedIcon: AnimatedIcon(
            icon: widget.toggleButtonAnimatedIconData,
            size: widget.toggleButtonSize,
            color: widget.toggleButtonIconColor ?? Colors.white,
            progress: _animation,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.webViewProvider!.verticalMenuIsOpen) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          children: [
            widget.backgroundWidget ?? Container(),
            ..._buildMenuItems(),
            _buildMenuButton(context),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
