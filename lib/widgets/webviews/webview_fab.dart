import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/multitab_detector.dart';

class WebviewFab extends StatelessWidget {
  const WebviewFab({super.key});

  @override
  Widget build(BuildContext context) {
    final webviewProvider = context.read<WebViewProvider>();

    // Helper function to create styled ActionButton
    Widget createStyledActionButton({
      required VoidCallback? onPressed,
      required IconData icon,
      Color backgroundColor = Colors.blue,
      Color iconColor = Colors.white,
    }) {
      return SizedBox(
        height: 40,
        width: 40,
        child: Material(
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          color: backgroundColor,
          elevation: 4,
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon, color: iconColor),
          ),
        ),
      );
    }

    bool canGoBack = webviewProvider.tabList[webviewProvider.currentTab].historyBack.isNotEmpty;
    bool canGoForward = webviewProvider.tabList[webviewProvider.currentTab].historyForward.isNotEmpty;
    return ExpandableFab(
      distance: 75,
      children: [
        createStyledActionButton(
          onPressed: () {
            webviewProvider.loadCurrentTabUrl("https://www.torn.com");
            final state = context.findAncestorStateOfType<_ExpandableFabState>();
            state?._toggle();
          },
          icon: Icons.home,
          backgroundColor: Colors.blueGrey,
          iconColor: Colors.white,
        ),
        createStyledActionButton(
          onPressed: !canGoBack
              ? () {}
              : () {
                  webviewProvider.tryGoBack();
                  final state = context.findAncestorStateOfType<_ExpandableFabState>();
                  state?._toggle();
                },
          icon: Icons.arrow_back,
          backgroundColor: !canGoBack ? Colors.grey : Colors.blueGrey,
          iconColor: Colors.white,
        ),
        createStyledActionButton(
          onPressed: !canGoForward
              ? () {}
              : () {
                  webviewProvider.tryGoForward();
                  final state = context.findAncestorStateOfType<_ExpandableFabState>();
                  state?._toggle();
                },
          icon: Icons.arrow_forward,
          backgroundColor: !canGoForward ? Colors.grey : Colors.blueGrey,
          iconColor: Colors.white,
        ),
        createStyledActionButton(
          onPressed: () {
            webviewProvider.reloadFromOutside();
            final state = context.findAncestorStateOfType<_ExpandableFabState>();
            state?._toggle();
          },
          icon: Icons.refresh,
          backgroundColor: Colors.blueGrey,
          iconColor: Colors.white,
        ),
      ],
    );
  }
}

@immutable
class ExpandableFab extends StatefulWidget {
  const ExpandableFab({
    super.key,
    this.initialOpen,
    required this.distance,
    required this.children,
  });

  final bool? initialOpen;
  final double distance;
  final List<Widget> children;

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  bool _open = false;

  late WebViewProvider _webviewProvider;

  final double _fabSize = 40;
  Offset _fabPosition = const Offset(100, 100);
  Offset _dragStartPos = Offset.zero;
  Offset _initialFabPos = Offset.zero;

  MultiTapDetector multiTapDetector = MultiTapDetector();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _open = widget.initialOpen ?? false;
    _controller = AnimationController(
      value: _open ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.easeOutQuad,
      parent: _controller,
    );

    // We add a listener to force rebuild (on Android the FAB is not expanding)
    _controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    // Attempt to restore FAB position from saved state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _webviewProvider = context.read<WebViewProvider>();
        // Restores saved position if it is within boundaries
        final savedX = _webviewProvider.fabSavedPositionXY[0].toDouble();
        final savedY = _webviewProvider.fabSavedPositionXY[1].toDouble();
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final bounds = _calculateFabBounds(screenWidth, screenHeight);

        double newX = savedX.clamp(bounds['minX']!, bounds['maxX']!);
        double newY = savedY.clamp(bounds['minY']!, bounds['maxY']!);
        setState(() {
          _fabPosition = Offset(newX, newY);
        });
        // If the clamped position changed the original, update it
        if (newX != savedX || newY != savedY) {
          _saveFabPosition(newX, newY);
        }
      }
    });
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _repositionFABafterRotation();
      });
    });
  }

  @override
  void dispose() {
    if (mounted) {
      _controller.dispose();
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _open = !_open;
      if (_open) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  double _calculateExpandedWidth() {
    return widget.distance * 2 + _fabSize;
  }

  double _calculateExpandedHeight() {
    return widget.distance * 2 + _fabSize;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    _webviewProvider = context.read<WebViewProvider>();

    double fanAngle;
    if (_webviewProvider.fabDirection == "center") {
      fanAngle = 140;
    } else {
      fanAngle = 120;
    }

    return Positioned(
      left: _open ? _fabPosition.dx - widget.distance : _fabPosition.dx,
      top: _open ? _fabPosition.dy - widget.distance : _fabPosition.dy,
      child: GestureDetector(
        onPanStart: (details) {
          _dragStartPos = details.globalPosition;
          _initialFabPos = _fabPosition;
        },
        onPanUpdate: (details) {
          setState(() {
            final dx = details.globalPosition.dx - _dragStartPos.dx;
            final dy = details.globalPosition.dy - _dragStartPos.dy;

            final screenWidth = MediaQuery.of(context).size.width;
            final screenHeight = MediaQuery.of(context).size.height;

            double newX = _initialFabPos.dx + dx;
            double newY = _initialFabPos.dy + dy;

            final bounds = _calculateFabBounds(screenWidth, screenHeight);
            final minX = bounds['minX']!;
            final maxX = bounds['maxX']!;
            final minY = bounds['minY']!;
            final maxY = bounds['maxY']!;

            newX = newX.clamp(minX, maxX);
            newY = newY.clamp(minY, maxY);

            _fabPosition = Offset(newX, newY);
          });
        },
        onPanEnd: (_) {
          // Save FAB position after dragging ends
          _saveFabPosition(_fabPosition.dx, _fabPosition.dy);
        },
        child: SizedBox(
          width: _open ? _calculateExpandedWidth() : _fabSize,
          height: _open ? _calculateExpandedHeight() : _fabSize,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final containerWidth = constraints.maxWidth;
              final containerHeight = constraints.maxHeight;

              return Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  if (_open)
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: _toggle,
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                  _buildTapToCloseFab(),
                  ..._buildExpandingActionButtons(
                    fanAngle: fanAngle,
                    containerWidth: containerWidth,
                    containerHeight: containerHeight,
                  ),
                  _buildTapToOpenFab(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTapToCloseFab() {
    return SizedBox(
      width: _fabSize,
      height: _fabSize,
      child: Center(
        child: Material(
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          elevation: 4,
          child: InkWell(
            onTap: _toggle,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(7),
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildExpandingActionButtons({
    required double fanAngle,
    required double containerWidth,
    required double containerHeight,
  }) {
    final children = <Widget>[];
    final count = widget.children.length;

    double startAngle;
    if (_webviewProvider.fabDirection == "center") {
      startAngle = 270 - (fanAngle / 2); // Positioned upwards
    } else if (_webviewProvider.fabDirection == "right") {
      startAngle = 0 - (fanAngle / 2); // Positioned to the right
    } else {
      startAngle = 180 - (fanAngle / 2); // Positioned to the left
    }

    final step = fanAngle / (count - 1);

    for (var i = 0; i < count; i++) {
      final angleInDegrees = startAngle + (step * i);
      children.add(
        _ExpandingActionButton(
          directionInDegrees: angleInDegrees,
          maxDistance: widget.distance,
          progress: _expandAnimation,
          child: widget.children[i],
          containerWidth: containerWidth,
          containerHeight: containerHeight,
          fabSize: _fabSize,
          // Close FAB when an ActionButton is pressed
          onPressedAction: () {
            _toggle();
          },
        ),
      );
    }
    return children;
  }

  Widget _buildTapToOpenFab() {
    return IgnorePointer(
      ignoring: _open,
      child: AnimatedContainer(
        transformAlignment: Alignment.center,
        transform: Matrix4.diagonal3Values(
          _open ? 0.7 : 1.0,
          _open ? 0.7 : 1.0,
          1.0,
        ),
        duration: const Duration(milliseconds: 250),
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        child: AnimatedOpacity(
          opacity: _open ? 0.0 : 1.0,
          curve: const Interval(0.25, 1.0, curve: Curves.easeInOut),
          duration: const Duration(milliseconds: 250),
          child: InkWell(
            onLongPress: () {
              _webviewProvider.fabShownNow = false;
            },
            child: FloatingActionButton(
              onPressed: _onFabTapped,
              backgroundColor: Colors.blueGrey,
              child: const Icon(
                Icons.tab_outlined,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onFabTapped() {
    multiTapDetector.onTap((numTaps) {
      if (numTaps == 1) {
        _toggle();
        if (_webviewProvider.verticalMenuIsOpen) {
          _webviewProvider.verticalMenuClose();
        }
      } else if (numTaps == 2) {
        // Double tap
        _webviewProvider.verticalMenuCurrentIndex = _webviewProvider.currentTab;
        if (_webviewProvider.verticalMenuIsOpen) {
          _webviewProvider.verticalMenuClose();
        } else {
          _webviewProvider.verticalMenuOpen();
        }
      } else if (numTaps == 3) {
        // Triple tap
        if (!_webviewProvider.tabList[_webviewProvider.currentTab].isLocked) {
          _webviewProvider.removeTab(position: _webviewProvider.currentTab);
        } else {
          if (context.read<SettingsProvider>().showTabLockWarnings) {
            toastification.show(
              alignment: Alignment.bottomCenter,
              title: Icon(
                Icons.lock,
                color: _webviewProvider.tabList[_webviewProvider.currentTab].isLockFull ? Colors.red : Colors.orange,
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

  Map<String, double> _calculateFabBounds(double screenWidth, double screenHeight) {
    double minX, maxX, minY, maxY;

    if (_webviewProvider.webViewSplitActive) {
      minX = 0;
      maxX = screenWidth / 2 - _fabSize * 2;
    } else {
      minX = 0;
      maxX = screenWidth - _fabSize;
    }

    minY = 0;
    maxY = screenHeight - _fabSize;

    return {'minX': minX, 'maxX': maxX, 'minY': minY, 'maxY': maxY};
  }

  void _repositionFABafterRotation() {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;

    final bounds = _calculateFabBounds(screenWidth, screenHeight);
    final minX = bounds['minX']!;
    final maxX = bounds['maxX']!;
    final minY = bounds['minY']!;
    final maxY = bounds['maxY']!;

    double newX = _fabPosition.dx;
    double newY = _fabPosition.dy;
    bool needsUpdate = false;

    if (_fabPosition.dx < minX) {
      newX = minX;
      needsUpdate = true;
    } else if (_fabPosition.dx > maxX) {
      newX = maxX;
      needsUpdate = true;
    }

    if (_fabPosition.dy < minY) {
      newY = minY;
      needsUpdate = true;
    } else if (_fabPosition.dy > maxY) {
      newY = maxY;
      needsUpdate = true;
    }

    if (needsUpdate) {
      setState(() {
        _fabPosition = Offset(newX, newY);
        _saveFabPosition(newX, newY);
      });
    }
  }

  void _saveFabPosition(double x, double y) {
    // Saves the FAB for persistence
    final arr = [x.toInt(), y.toInt()];
    _webviewProvider.fabSavedPositionXY = arr;
  }
}

@immutable
class _ExpandingActionButton extends StatelessWidget {
  const _ExpandingActionButton({
    required this.directionInDegrees,
    required this.maxDistance,
    required this.progress,
    required this.child,
    required this.containerWidth,
    required this.containerHeight,
    required this.fabSize,
    this.onPressedAction,
  });

  final double directionInDegrees;
  final double maxDistance;
  final Animation<double> progress;
  final Widget child;
  final double containerWidth;
  final double containerHeight;
  final double fabSize;
  final VoidCallback? onPressedAction;

  @override
  Widget build(BuildContext context) {
    // Converting degrees to radians
    final angleRad = directionInDegrees * (math.pi / 180.0);
    final offset = Offset.fromDirection(angleRad, progress.value * maxDistance);

    // Center of the container
    final centerX = containerWidth / 2;
    final centerY = containerHeight / 2;

    // Adjusting the positioning offset to center the action buttons properly
    final buttonX = centerX + offset.dx - 20;
    final buttonY = centerY + offset.dy - 20;

    return Positioned(
      left: buttonX,
      top: buttonY,
      child: Transform.rotate(
        angle: (1.0 - progress.value) * math.pi / 2,
        child: FadeTransition(
          opacity: progress,
          child: GestureDetector(
            onTap: () {
              // Close FAB if an ActionButton is pressed
              if (onPressedAction != null) {
                onPressedAction!();
              }
              // Dispatch the original child's onPressed if it exists
              if (child is ActionButton) {
                final actionButton = child as ActionButton;
                if (actionButton.onPressed != null) {
                  actionButton.onPressed!();
                }
              }
            },
            child: child,
          ),
        ),
      ),
    );
  }
}

@immutable
class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    this.onPressed,
    required this.icon,
  });

  final VoidCallback? onPressed;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      color: theme.colorScheme.secondary,
      elevation: 4,
      child: IconButton(
        onPressed: onPressed,
        icon: icon,
        color: theme.colorScheme.onSecondary,
      ),
    );
  }
}
