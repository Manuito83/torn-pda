import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/multitab_detector.dart';
import 'circular_menu_item.dart';

class CircularMenuTabs extends StatefulWidget {
  /// Global key to control animation
  final GlobalKey<CircularMenuTabsState> key;

  /// List of CircularMenuItem contains at least two items.
  final List<CircularMenuItem> items;

  /// Menu alignment
  final AlignmentGeometry alignment;

  /// Menu radius
  final double radius;

  /// Widget holds actual page content
  final Widget backgroundWidget;

  /// Animation duration
  final Duration animationDuration;

  /// Animation curve in forward
  final Curve curve;

  /// Animation curve in reverse
  final Curve reverseCurve;

  /// Callback
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
  final int tabIndex;

  /// creates a circular menu with specific [radius] and [alignment] .
  /// [toggleButtonElevation] ,[toggleButtonPadding] and [toggleButtonMargin] must be
  /// equal or greater than zero.
  /// [items] must not be null and it must contains two elements at least.
  CircularMenuTabs({
    @required this.items,
    @required this.webViewProvider,
    @required this.tabIndex,
    this.doubleTapped,
    this.alignment = Alignment.bottomCenter,
    this.radius = 50,
    this.backgroundWidget,
    this.animationDuration = const Duration(milliseconds: 0),
    this.curve = Curves.decelerate,
    this.reverseCurve = Curves.decelerate,
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
  CircularMenuTabsState createState() => CircularMenuTabsState();
}

class CircularMenuTabsState extends State<CircularMenuTabs> with SingleTickerProviderStateMixin {
  AnimationController _animationController;
  Animation<double> _animation;

  // Keep track of taps in 450 ms to allow for triple tabs
  MultiTapDetector multiTapDetector = MultiTapDetector();

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
          visible: widget.webViewProvider.verticalMenuCurrentIndex == widget.tabIndex,
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
            multiTapDetector.onTap((numTaps) {
              if (numTaps == 1) {
                
                // Single tap
                if (widget.toggleButtonOnPressed != null) {
                  widget.toggleButtonOnPressed();
                }
                
              } else if (numTaps == 2) {
                // Double tab
                // Opens the menu
                if (_animationController.status == AnimationStatus.dismissed) {
                  widget.webViewProvider.verticalMenuOpen();
                } else {
                  // Closes the menu but permits the menu to shift from one tab to another
                  // without the user noticing (closes and reopens the new tapped tab)
                  widget.webViewProvider.verticalMenuClose();
                  if (widget.webViewProvider.verticalMenuCurrentIndex != widget.tabIndex) {
                    widget.webViewProvider.verticalMenuCurrentIndex = widget.tabIndex;
                    widget.webViewProvider.verticalMenuOpen();
                  }
                }
                widget.webViewProvider.verticalMenuCurrentIndex = widget.tabIndex;
              } else if (numTaps == 3) {
                // Triple tab
                widget.webViewProvider.removeTab(position: widget.tabIndex);
              }
            });
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
    if (widget.webViewProvider.verticalMenuIsOpen) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
    return Stack(
      children: <Widget>[
        AnimatedBuilder(
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
        ),
      ],
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
