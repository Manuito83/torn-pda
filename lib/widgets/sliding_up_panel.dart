/*
Based on SlidingUpPanel by Akshath Jain
*/

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/physics.dart';

enum SlideDirection {
  UP,
  DOWN,
}

enum PanelState { OPEN, CLOSED }

class CustomSlidingUpPanel extends StatefulWidget {
  /// The Widget that slides into view. When the
  /// panel is collapsed and if [collapsed] is null,
  /// then top portion of this Widget will be displayed;
  /// otherwise, [collapsed] will be displayed overtop
  /// of this Widget. If [panel] and [panelBuilder] are both non-null,
  /// [panel] will be used.
  final Widget? panel;

  /// Provides a [ScrollController] and
  /// [ScrollPhysics] to attach to a scrollable object in the panel that links
  /// the panel position with the scroll position. Useful for implementing an
  /// infinite scroll behavior. If [panel] and [panelBuilder] are both non-null,
  /// [panel] will be used.
  final Widget Function(ScrollController sc)? panelBuilder;

  /// The Widget displayed overtop the [panel] when collapsed.
  /// This fades out as the panel is opened.
  final Widget? collapsed;

  /// The Widget that lies underneath the sliding panel.
  /// This Widget automatically sizes itself
  /// to fill the screen.
  final Widget? body;

  /// Optional persistent widget that floats above the [panel] and attaches
  /// to the top of the [panel]. Content at the top of the panel will be covered
  /// by this widget. Add padding to the bottom of the `panel` to
  /// avoid coverage.
  final Widget? header;

  /// Optional persistent widget that floats above the [panel] and
  /// attaches to the bottom of the [panel]. Content at the bottom of the panel
  /// will be covered by this widget. Add padding to the bottom of the `panel`
  /// to avoid coverage.
  final Widget? footer;

  /// The height of the sliding panel when fully collapsed.
  final double minHeight;

  /// The height of the sliding panel when fully open.
  final double maxHeight;

  /// A point between [minHeight] and [maxHeight] that the panel snaps to
  /// while animating. A fast swipe on the panel will disregard this point
  /// and go directly to the open/close position. This value is represented as a
  /// percentage of the total animation distance ([maxHeight] - [minHeight]),
  /// so it must be between 0.0 and 1.0, exclusive.
  final double? snapPoint;

  /// A border to draw around the sliding panel sheet.
  final Border? border;

  /// If non-null, the corners of the sliding panel sheet are rounded by this [BorderRadiusGeometry].
  final BorderRadiusGeometry? borderRadius;

  /// A list of shadows cast behind the sliding panel sheet.
  final List<BoxShadow>? boxShadow;

  /// The color to fill the background of the sliding panel sheet.
  final Color color;

  /// The amount to inset the children of the sliding panel sheet.
  final EdgeInsetsGeometry? padding;

  /// Empty space surrounding the sliding panel sheet.
  final EdgeInsetsGeometry? margin;

  /// Set to false to not to render the sheet the [panel] sits upon.
  /// This means that only the [body], [collapsed], and the [panel]
  /// Widgets will be rendered.
  /// Set this to false if you want to achieve a floating effect or
  /// want more customization over how the sliding panel
  /// looks like.
  final bool renderPanelSheet;

  /// Set to false to disable the panel from snapping open or closed.
  final bool panelSnapping;

  /// If non-null, this can be used to control the state of the panel.
  final CustomPanelController? controller;

  /// If non-null, shows a darkening shadow over the [body] as the panel slides open.
  final bool backdropEnabled;

  /// Shows a darkening shadow of this [Color] over the [body] as the panel slides open.
  final Color backdropColor;

  /// The opacity of the backdrop when the panel is fully open.
  /// This value can range from 0.0 to 1.0 where 0.0 is completely transparent
  /// and 1.0 is completely opaque.
  final double backdropOpacity;

  /// Flag that indicates whether or not tapping the
  /// backdrop closes the panel. Defaults to true.
  final bool backdropTapClosesPanel;

  /// If non-null, this callback
  /// is called as the panel slides around with the
  /// current position of the panel. The position is a double
  /// between 0.0 and 1.0 where 0.0 is fully collapsed and 1.0 is fully open.
  final void Function(double position)? onPanelSlide;

  /// If non-null, this callback is called when the
  /// panel is fully opened
  final VoidCallback? onPanelOpened;

  /// If non-null, this callback is called when the panel
  /// is fully collapsed.
  final VoidCallback? onPanelClosed;

  /// If non-null and true, the SlidingUpPanel exhibits a
  /// parallax effect as the panel slides up. Essentially,
  /// the body slides up as the panel slides up.
  final bool parallaxEnabled;

  /// Allows for specifying the extent of the parallax effect in terms
  /// of the percentage the panel has slid up/down. Recommended values are
  /// within 0.0 and 1.0 where 0.0 is no parallax and 1.0 mimics a
  /// one-to-one scrolling effect. Defaults to a 10% parallax.
  final double parallaxOffset;

  /// Allows toggling of the draggability of the SlidingUpPanel.
  /// Set this to false to prevent the user from being able to drag
  /// the panel up and down. Defaults to true.
  final bool isDraggable;

  /// Either SlideDirection.UP or SlideDirection.DOWN. Indicates which way
  /// the panel should slide. Defaults to UP. If set to DOWN, the panel attaches
  /// itself to the top of the screen and is fully opened when the user swipes
  /// down on the panel.
  final SlideDirection slideDirection;

  /// The default state of the panel; either PanelState.OPEN or PanelState.CLOSED.
  /// This value defaults to PanelState.CLOSED which indicates that the panel is
  /// in the closed position and must be opened. PanelState.OPEN indicates that
  /// by default the Panel is open and must be swiped closed by the user.
  final PanelState defaultPanelState;

  final Widget? floatingActionButton;
  final double floatingActionButtonOffset;

  CustomSlidingUpPanel({
    super.key,
    this.panel,
    this.panelBuilder,
    this.body,
    this.collapsed,
    this.minHeight = 100.0,
    this.maxHeight = 500.0,
    this.snapPoint,
    this.border,
    this.borderRadius,
    this.boxShadow = const <BoxShadow>[
      BoxShadow(
        blurRadius: 8.0,
        color: Color.fromRGBO(0, 0, 0, 0.25),
      ),
    ],
    this.color = Colors.white,
    this.padding,
    this.margin,
    this.renderPanelSheet = true,
    this.panelSnapping = true,
    this.controller,
    this.backdropEnabled = false,
    this.backdropColor = Colors.black,
    this.backdropOpacity = 0.5,
    this.backdropTapClosesPanel = true,
    this.onPanelSlide,
    this.onPanelOpened,
    this.onPanelClosed,
    this.parallaxEnabled = false,
    this.parallaxOffset = 0.1,
    this.isDraggable = true,
    this.slideDirection = SlideDirection.UP,
    this.defaultPanelState = PanelState.CLOSED,
    this.header,
    this.footer,
    this.floatingActionButton,
    this.floatingActionButtonOffset = 25.0,
  })  : assert(panel != null || panelBuilder != null),
        assert(0 <= backdropOpacity && backdropOpacity <= 1.0),
        assert(snapPoint == null || 0 < snapPoint && snapPoint < 1.0);

  @override
  CustomSlidingUpPanelState createState() => CustomSlidingUpPanelState();
}

class CustomSlidingUpPanelState extends State<CustomSlidingUpPanel> with SingleTickerProviderStateMixin {
  late AnimationController _ac;
  late ScrollController _sc;

  bool _scrollingEnabled = false;
  final VelocityTracker _vt = VelocityTracker.withKind(PointerDeviceKind.touch);

  bool _isPanelVisible = true;

  @override
  void initState() {
    super.initState();

    _ac = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
        value: widget.defaultPanelState == PanelState.CLOSED ? 0.0 : 1.0)
      ..addListener(() {
        if (widget.onPanelSlide != null) widget.onPanelSlide!(_ac.value);
        if (widget.onPanelOpened != null && _isPanelOpen) {
          widget.onPanelOpened!();
        }
        if (widget.onPanelClosed != null && _isPanelClosed) {
          widget.onPanelClosed!();
        }
        setState(() {});
      });

    _sc = ScrollController();
    _sc.addListener(() {
      if (widget.isDraggable && !_scrollingEnabled) _sc.jumpTo(0);
    });

    widget.controller?._addState(this);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final fabBottomPosition = _ac.value * (widget.maxHeight - widget.minHeight) + widget.floatingActionButtonOffset;

      return ClipRect(
        child: Stack(
          alignment: widget.slideDirection == SlideDirection.UP ? Alignment.bottomCenter : Alignment.topCenter,
          children: <Widget>[
            if (widget.body != null)

              // Body
              AnimatedBuilder(
                animation: _ac,
                builder: (context, child) {
                  if (widget.parallaxEnabled) {
                    return Transform.translate(
                      offset: Offset(0.0, _getParallax()),
                      child: child,
                    );
                  }
                  return child ?? const SizedBox.shrink();
                },
                child: widget.body,
              )
            else
              Container(),

            // Backdrop
            if (widget.backdropEnabled)
              GestureDetector(
                onVerticalDragEnd: widget.backdropTapClosesPanel
                    ? (DragEndDetails dets) {
                        if ((widget.slideDirection == SlideDirection.UP ? 1 : -1) * dets.velocity.pixelsPerSecond.dy >
                            0) {
                          _close();
                        }
                      }
                    : null,
                onTap: widget.backdropTapClosesPanel ? () => _close() : null,
                child: AnimatedBuilder(
                    animation: _ac,
                    builder: (context, _) {
                      return Container(
                        height: MediaQuery.of(context).size.height,
                        width: MediaQuery.of(context).size.width,
                        color: _ac.value == 0.0
                            ? null
                            : widget.backdropColor.withAlpha(
                                (255 * widget.backdropOpacity * _ac.value).round(),
                              ),
                      );
                    }),
              )
            else
              Container(),

            // Sliding panel
            if (_isPanelVisible)
              _gestureHandler(
                child: AnimatedBuilder(
                  animation: _ac,
                  builder: (context, child) {
                    BorderRadius? animatedBorderRadius;
                    if (widget.borderRadius != null) {
                      animatedBorderRadius = BorderRadius.lerp(widget.borderRadius as BorderRadius,
                          BorderRadius.circular((widget.borderRadius as BorderRadius).topLeft.x / 2), _ac.value);
                    }

                    return Container(
                      height: _ac.value * (widget.maxHeight - widget.minHeight) + widget.minHeight,
                      margin: widget.margin,
                      padding: widget.padding,
                      decoration: widget.renderPanelSheet
                          ? BoxDecoration(
                              border: widget.border,
                              borderRadius: animatedBorderRadius,
                              boxShadow: widget.boxShadow,
                              color: widget.color,
                            )
                          : null,
                      child: child,
                    );
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      Positioned(
                          top: widget.slideDirection == SlideDirection.UP ? 0.0 : null,
                          bottom: widget.slideDirection == SlideDirection.DOWN ? 0.0 : null,
                          width: constraints.maxWidth -
                              (widget.margin != null ? widget.margin!.horizontal : 0) -
                              (widget.padding != null ? widget.padding!.horizontal : 0),
                          child: Container(
                            height: widget.maxHeight,
                            child: widget.panel ?? widget.panelBuilder!(_sc),
                          )),

                      // Header
                      if (widget.header != null)
                        Positioned(
                          top: widget.slideDirection == SlideDirection.UP ? 0.0 : null,
                          bottom: widget.slideDirection == SlideDirection.DOWN ? 0.0 : null,
                          child: widget.header!,
                        )
                      else
                        Container(),

                      // Footer
                      if (widget.footer != null)
                        Positioned(
                            top: widget.slideDirection == SlideDirection.UP ? null : 0.0,
                            bottom: widget.slideDirection == SlideDirection.DOWN ? null : 0.0,
                            child: widget.footer!)
                      else
                        Container(),

                      // Collapsed widget
                      Positioned(
                        top: widget.slideDirection == SlideDirection.UP ? 0.0 : null,
                        bottom: widget.slideDirection == SlideDirection.DOWN ? 0.0 : null,
                        width: constraints.maxWidth -
                            (widget.margin != null ? widget.margin!.horizontal : 0) -
                            (widget.padding != null ? widget.padding!.horizontal : 0),
                        child: Container(
                          height: widget.minHeight,
                          child: widget.collapsed == null
                              ? Container()
                              : FadeTransition(
                                  opacity: Tween(begin: 1.0, end: 0.0).animate(_ac),
                                  child: IgnorePointer(ignoring: _isPanelOpen, child: widget.collapsed),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(),

            // FAB
            if (widget.floatingActionButton != null)
              Positioned(
                right: 35.0,
                bottom: fabBottomPosition,
                child: widget.floatingActionButton!,
              ),
          ],
        ),
      );
    });
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  double _getParallax() {
    if (widget.slideDirection == SlideDirection.UP) {
      return -_ac.value * (widget.maxHeight - widget.minHeight) * widget.parallaxOffset;
    } else {
      return _ac.value * (widget.maxHeight - widget.minHeight) * widget.parallaxOffset;
    }
  }

  Widget _gestureHandler({required Widget child}) {
    if (!widget.isDraggable) return child;

    if (widget.panel != null) {
      return GestureDetector(
        onVerticalDragUpdate: (DragUpdateDetails dets) => _onGestureSlide(dets.delta.dy),
        onVerticalDragEnd: (DragEndDetails dets) => _onGestureEnd(dets.velocity),
        child: child,
      );
    }

    return Listener(
      onPointerDown: (PointerDownEvent p) => _vt.addPosition(p.timeStamp, p.position),
      onPointerMove: (PointerMoveEvent p) {
        _vt.addPosition(p.timeStamp, p.position);
        _onGestureSlide(p.delta.dy);
      },
      onPointerUp: (PointerUpEvent p) => _onGestureEnd(_vt.getVelocity()),
      child: child,
    );
  }

  void _onGestureSlide(double dy) {
    if (_ac.isAnimating) return;
    if (!_scrollingEnabled) {
      if (widget.slideDirection == SlideDirection.UP) {
        _ac.value -= dy / (widget.maxHeight - widget.minHeight);
      } else {
        _ac.value += dy / (widget.maxHeight - widget.minHeight);
      }
    }

    if (_isPanelOpen && _sc.hasClients && _sc.offset <= 0) {
      setState(() {
        if (dy < 0) {
          _scrollingEnabled = true;
        } else {
          _scrollingEnabled = false;
        }
      });
    }
  }

  void _onGestureEnd(Velocity v) {
    const double minFlingVelocity = 365.0;
    const double kSnap = 8;

    if (_ac.isAnimating) return;
    if (_isPanelOpen && _scrollingEnabled) return;

    double visualVelocity = -v.pixelsPerSecond.dy / (widget.maxHeight - widget.minHeight);

    if (widget.slideDirection == SlideDirection.DOWN) {
      visualVelocity = -visualVelocity;
    }

    final double d2Close = _ac.value;
    final double d2Open = 1 - _ac.value;
    final double d2Snap = ((widget.snapPoint ?? 3) - _ac.value).abs();
    final double minDistance = min(d2Close, min(d2Snap, d2Open));

    if (v.pixelsPerSecond.dy.abs() >= minFlingVelocity) {
      if (widget.panelSnapping && widget.snapPoint != null) {
        if (v.pixelsPerSecond.dy.abs() >= kSnap * minFlingVelocity || minDistance == d2Snap) {
          _ac.fling(velocity: visualVelocity);
        } else {
          _flingPanelToPosition(widget.snapPoint!, visualVelocity);
        }
      } else if (widget.panelSnapping) {
        final target = visualVelocity > 0 ? 1.0 : 0.0;
        _ac.animateWith(SpringSimulation(
          const SpringDescription(mass: 1.0, stiffness: 500.0, damping: 22.0),
          _ac.value,
          target,
          visualVelocity,
        ));
      } else {
        _ac.animateTo(
          _ac.value + visualVelocity * 0.16,
          duration: const Duration(milliseconds: 410),
          curve: Curves.decelerate,
        );
      }
      return;
    }

    if (widget.panelSnapping) {
      if (minDistance == d2Close) {
        _close();
      } else if (minDistance == d2Snap) {
        _flingPanelToPosition(widget.snapPoint!, visualVelocity);
      } else {
        _open();
      }
    }
  }

  void _flingPanelToPosition(double targetPos, double velocity) {
    final Simulation simulation = SpringSimulation(
        SpringDescription.withDampingRatio(
          mass: 1.0,
          stiffness: 600.0,
          ratio: 1.0,
        ),
        _ac.value,
        targetPos,
        velocity);
    _ac.animateWith(simulation);
  }

  Future<void> _close() {
    if (_ac.isAnimating) return Future.value();
    return _ac.animateWith(
      SpringSimulation(
        const SpringDescription(mass: 1.0, stiffness: 500.0, damping: 22.0),
        _ac.value,
        0.0,
        -1.0,
      ),
    );
  }

  Future<void> _open() {
    if (_ac.isAnimating) return Future.value();
    return _ac.animateWith(
      SpringSimulation(
        const SpringDescription(mass: 1.0, stiffness: 500.0, damping: 22.0),
        _ac.value,
        1.0,
        1.0,
      ),
    );
  }

  Future<void> _hide() {
    return _ac.fling(velocity: -1.0).then((x) {
      if (mounted) setState(() => _isPanelVisible = false);
    });
  }

  Future<void> _show() {
    return _ac.fling(velocity: -1.0).then((x) {
      if (mounted) setState(() => _isPanelVisible = true);
    });
  }

  Future<void> _animatePanelToPosition(double value, {Duration? duration, Curve curve = Curves.linear}) =>
      _ac.animateTo(value, duration: duration, curve: curve);

  Future<void> _animatePanelToSnapPoint({Duration? duration, Curve curve = Curves.linear}) {
    assert(widget.snapPoint != null);
    return _ac.animateTo(widget.snapPoint!, duration: duration, curve: curve);
  }

  set _panelPosition(double value) {
    assert(0.0 <= value && value <= 1.0);
    _ac.value = value;
  }

  double get _panelPosition => _ac.value;
  bool get _isPanelAnimating => _ac.isAnimating;
  bool get _isPanelOpen => _ac.value >= 0.99;
  bool get _isPanelClosed => _ac.value <= 0.01;
  bool get _isPanelShown => _isPanelVisible;
}

class CustomPanelController {
  CustomSlidingUpPanelState? _panelState;

  void _addState(CustomSlidingUpPanelState panelState) {
    _panelState = panelState;
  }

  bool get isAttached => _panelState != null;

  Future<void> close() {
    assert(isAttached, "PanelController must be attached to a SlidingUpPanel");
    return _panelState!._close();
  }

  Future<void> open() {
    assert(isAttached, "PanelController must be attached to a SlidingUpPanel");
    return _panelState!._open();
  }

  Future<void> hide() {
    assert(isAttached, "PanelController must be attached to a SlidingUpPanel");
    return _panelState!._hide();
  }

  Future<void> show() {
    assert(isAttached, "PanelController must be attached to a SlidingUpPanel");
    return _panelState!._show();
  }

  Future<void> animatePanelToPosition(double value, {Duration? duration, Curve curve = Curves.linear}) {
    assert(isAttached, "PanelController must be attached to a SlidingUpPanel");
    assert(0.0 <= value && value <= 1.0);
    return _panelState!._animatePanelToPosition(value, duration: duration, curve: curve);
  }

  Future<void> animatePanelToSnapPoint({Duration? duration, Curve curve = Curves.linear}) {
    assert(isAttached, "PanelController must be attached to a SlidingUpPanel");
    assert(_panelState!.widget.snapPoint != null, "SlidingUpPanel snapPoint property must not be null");
    return _panelState!._animatePanelToSnapPoint(duration: duration, curve: curve);
  }

  set panelPosition(double value) {
    assert(isAttached, "PanelController must be attached to a SlidingUpPanel");
    assert(0.0 <= value && value <= 1.0);
    _panelState!._panelPosition = value;
  }

  double get panelPosition {
    assert(isAttached, "PanelController must be attached to a SlidingUpPanel");
    return _panelState!._panelPosition;
  }

  bool get isPanelAnimating {
    assert(isAttached, "PanelController must be attached to a SlidingUpPanel");
    return _panelState!._isPanelAnimating;
  }

  bool get isPanelOpen {
    assert(isAttached, "PanelController must be attached to a SlidingUpPanel");
    return _panelState!._isPanelOpen;
  }

  bool get isPanelClosed {
    assert(isAttached, "PanelController must be attached to a SlidingUpPanel");
    return _panelState!._isPanelClosed;
  }

  bool get isPanelShown {
    assert(isAttached, "PanelController must be attached to a SlidingUpPanel");
    return _panelState!._isPanelShown;
  }
}
