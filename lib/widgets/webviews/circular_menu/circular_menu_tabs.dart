import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/multitab_detector.dart';
import 'package:torn_pda/widgets/webviews/circular_menu/circular_menu_item.dart';

class CircularMenuTabs extends StatefulWidget {
  /// List of CircularMenuItem contains at least two items.
  final List<Widget> items;

  /// Menu alignment
  final AlignmentGeometry alignment;

  /// Menu radius
  final double radius;

  /// Widget holds actual page content
  final Widget? backgroundWidget;

  /// Animation duration
  final Duration animationDuration;

  /// Animation curve in forward
  final Curve curve;

  /// Animation curve in reverse
  final Curve reverseCurve;

  /// Callback
  final VoidCallback? toggleButtonOnPressed;
  final VoidCallback? doubleTapped;
  final Color? toggleButtonColor;
  final double toggleButtonSize;
  final List<BoxShadow>? toggleButtonBoxShadow;
  final double toggleButtonPadding;
  final double toggleButtonMargin;
  final Color? toggleButtonIconColor;
  final AnimatedIconData toggleButtonAnimatedIconData;

  final WebViewProvider? webViewProvider;
  final int tabIndex;

  /// creates a circular menu with specific [radius] and [alignment] .
  /// [toggleButtonElevation] ,[toggleButtonPadding] and [toggleButtonMargin] must be
  /// equal or greater than zero.
  /// [items] must not be null and it must contains two elements at least.
  CircularMenuTabs({
    required this.items,
    required this.webViewProvider,
    required this.tabIndex,
    this.doubleTapped,
    this.alignment = Alignment.bottomCenter,
    this.radius = 50,
    this.backgroundWidget,
    this.animationDuration = const Duration(),
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
  }) : assert(items.isNotEmpty, 'items can not be empty list');

  @override
  CircularMenuTabsState createState() => CircularMenuTabsState();
}

class CircularMenuTabsState extends State<CircularMenuTabs> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.webViewProvider!.verticalMenuIsOpen) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
    return Stack(
      alignment: AlignmentDirectional.bottomCenter,
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
        Material(
          color: Colors.transparent,
          clipBehavior: Clip.none,
          child: SizedBox(
            height: 40,
            width: 40,
            child: InkWell(
              hoverColor: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                if (!mounted) return;
                _onTabTapped(context);
              },
              child: ReorderableDelayedDragStartListener(
                index: widget.tabIndex,
                child: Container(
                  alignment: Alignment.center,
                  color: Colors.transparent,
                ),
              ),
            ),
          ),
        )
      ],
    );
  }

  List<Widget> _buildMenuItems() {
    List<Widget> items = [];
    widget.items.asMap().forEach((index, item) {
      items.add(
        Visibility(
          visible: widget.webViewProvider!.verticalMenuCurrentIndex == widget.tabIndex,
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
          onTap: () {
            if (!mounted) return;
            _onTabTapped(context);
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

  void _onTabTapped(BuildContext context) {
    multiTapDetector.onTap((numTaps) {
      if (numTaps == 1) {
        // Single tap
        if (widget.toggleButtonOnPressed != null) {
          widget.toggleButtonOnPressed!();
        }
      } else if (numTaps == 2) {
        // Double tab
        // Opens the menu
        if (_animationController.status == AnimationStatus.dismissed) {
          widget.webViewProvider!.verticalMenuOpen();
        } else {
          // Closes the menu but permits the menu to shift from one tab to another
          // without the user noticing (closes and reopens the new tapped tab)
          widget.webViewProvider!.verticalMenuClose();
          if (widget.webViewProvider!.verticalMenuCurrentIndex != widget.tabIndex) {
            widget.webViewProvider!.verticalMenuCurrentIndex = widget.tabIndex;
            widget.webViewProvider!.verticalMenuOpen();
          }
        }
        widget.webViewProvider!.verticalMenuCurrentIndex = widget.tabIndex;
      } else if (numTaps == 3) {
        // Triple tab
        if (!widget.webViewProvider!.tabList[widget.tabIndex].isLocked) {
          widget.webViewProvider!.removeTab(position: widget.tabIndex);
        } else {
          if (context.read<SettingsProvider>().showTabLockWarnings) {
            toastification.show(
              alignment: Alignment.bottomCenter,
              title: Icon(
                Icons.lock,
                color: widget.webViewProvider!.tabList[widget.tabIndex].isLockFull ? Colors.red : Colors.orange,
              ),
              autoCloseDuration: const Duration(seconds: 2),
              animationDuration: const Duration(milliseconds: 0),
              showProgressBar: false,
              style: ToastificationStyle.simple,
              borderSide: BorderSide(width: 1, color: Colors.grey[700]!),
            );
          }
        }
      }
    });
  }
}
