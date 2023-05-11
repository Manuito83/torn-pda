import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:torn_pda/providers/webview_provider.dart';

import 'circular_menu_item.dart';

class CircularMenuFixed extends StatefulWidget {
  /// use global key to control animation anywhere in the code
  final GlobalKey<CircularMenuFixedState> key;

  /// list of CircularMenuItem contains at least two items.
  final List<CircularMenuItem> items;

  /// menu alignment
  final AlignmentGeometry alignment;

  /// menu radius
  final double radius;

  /// widget holds actual page content
  final Widget backgroundWidget;

  /// animation duration
  final Duration animationDuration;

  /// animation curve in forward
  final Curve curve;

  /// animation curve in reverse
  final Curve reverseCurve;

  /// callback
  final VoidCallback toggleButtonOnPressed;
  final VoidCallback doubleTapped;
  final Color toggleButtonColor;
  final double toggleButtonSize;
  final List<BoxShadow> toggleButtonBoxShadow;
  final double toggleButtonPadding;
  final double toggleButtonMargin;
  final Color toggleButtonIconColor;
  final AnimatedIconData toggleButtonAnimatedIconData;

  final WebViewProvider webViewProvider;

  CircularMenuFixed({
    @required this.items,
    @required this.webViewProvider,
    this.doubleTapped,
    this.alignment = Alignment.bottomCenter,
    this.radius = 50,
    this.backgroundWidget,
    this.animationDuration = const Duration(milliseconds: 500),
    this.curve = Curves.bounceOut,
    this.reverseCurve = Curves.fastOutSlowIn,
    this.toggleButtonOnPressed,
    this.toggleButtonColor,
    this.toggleButtonBoxShadow,
    this.toggleButtonMargin = 10,
    this.toggleButtonPadding = 10,
    this.toggleButtonSize = 40,
    this.toggleButtonIconColor,
    this.toggleButtonAnimatedIconData = AnimatedIcons.menu_close,
    this.key,
  })  : assert(items.isNotEmpty, 'items can not be empty list'),
        super(key: key);

  @override
  CircularMenuFixedState createState() => CircularMenuFixedState();
}

class CircularMenuFixedState extends State<CircularMenuFixed> with SingleTickerProviderStateMixin {
  AnimationController _animationController;
  Animation<double> _animation;

  /// forward animation
  void forwardAnimation() {
    _animationController.forward();
  }

  /// reverse animation
  void reverseAnimation() {
    _animationController.reverse();
  }

  @override
  void initState() {
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    )..addListener(() {
        setState(() {});
      });
    _animation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: widget.curve, reverseCurve: widget.reverseCurve),
    );

    if (widget.webViewProvider.verticalMenuIsOpen) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }

    super.initState();
  }

  List<Widget> _buildMenuItems() {
    List<Widget> items = [];
    widget.items.asMap().forEach((index, item) {
      items.add(
        Visibility(
          visible: true,
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
          icon: null,
          margin: widget.toggleButtonMargin,
          color: widget.toggleButtonColor ?? Theme.of(context).primaryColor,
          padding: 50,
          onTap: () {
            if (_animationController.status == AnimationStatus.dismissed) {
              widget.webViewProvider.verticalMenuOpen();
            } else {
              widget.webViewProvider.verticalMenuClose();
            }
          },
          onDoubleTap: () async {
            if (widget.doubleTapped != null) {
              widget.doubleTapped();
              return;
            }
            if (_animationController.status == AnimationStatus.dismissed) {
              widget.webViewProvider.verticalMenuOpen();
            } else {
              widget.webViewProvider.verticalMenuClose();
            }
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
    return Stack(
      children: <Widget>[
        widget.backgroundWidget ?? Container(),
        ..._buildMenuItems(),
        _buildMenuButton(context),
      ],
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
