import 'dart:io';

import 'package:collection/collection.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:torn_pda/main.dart';
import 'package:torn_pda/widgets/webviews/split_divider.dart';
import 'package:torn_pda/widgets/webviews/webview_tabslist.dart';

// Tabs never change parent, so their webviews survive
class WebViewPanelsStack extends StatefulWidget {
  final List<Widget> children;

  final List<int?> panelTabs;

  final List<int> childPanels;

  final int? focusedPanel;
  final Widget? emptyPanel;
  final ValueChanged<int>? onTabPointerDown;
  final double splitRatio;
  final ValueChanged<double>? onSplitRatioChanged;

  final bool resizeFocusedPanelForKeyboard;
  final int duration;
  final Function errorCallback;

  const WebViewPanelsStack({
    super.key,
    required this.children,
    required this.panelTabs,
    required this.childPanels,
    required this.duration,
    required this.errorCallback,
    this.focusedPanel,
    this.emptyPanel,
    this.onTabPointerDown,
    this.splitRatio = 0.5,
    this.onSplitRatioChanged,
    this.resizeFocusedPanelForKeyboard = false,
  });

  @override
  WebViewPanelsStackState createState() => WebViewPanelsStackState();
}

class WebViewPanelsStackState extends State<WebViewPanelsStack> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.duration),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    super.initState();
  }

  @override
  void didUpdateWidget(WebViewPanelsStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!const ListEquality<int?>().equals(widget.panelTabs, oldWidget.panelTabs)) {
      _controller.reverse().then((_) {
        _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty) return const SizedBox.shrink();
    try {
      if (widget.panelTabs.isEmpty || widget.childPanels.length != widget.children.length) {
        throw "Forced panels stack throw!";
      }
      final List<int?> panelTabs = [for (final tab in widget.panelTabs) tab?.clamp(0, widget.children.length - 1)];

      return LayoutBuilder(
        builder: (context, constraints) {
          final MediaQueryData mediaQuery = MediaQuery.of(context);
          final double width = constraints.maxWidth;
          final bool divided = panelTabs.length > 1 && widget.onSplitRatioChanged != null;
          final double gap = divided ? kSplitDividerWidth : 0;
          final double leftWidth = divided ? splitLeftSlotWidth(width, widget.splitRatio) : width / panelTabs.length;
          final List<double> panelLeft = [0, leftWidth + gap];
          final List<double> panelWidth = [leftWidth, width - leftWidth - gap];
          final int? emptyPanel = panelTabs.contains(null) ? panelTabs.indexOf(null) : null;
          final int? focusedPanel = widget.focusedPanel;
          final double keyboardInset = widget.resizeFocusedPanelForKeyboard ? mediaQuery.viewInsets.bottom : 0;
          int panelOf(int child) => panelTabs.contains(child)
              ? panelTabs.indexOf(child)
              : widget.childPanels[child].clamp(0, panelTabs.length - 1);

          return AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.scale(scale: 0.995 + (_controller.value * 0.005), child: child);
            },
            child: Stack(
              children: [
                Stack(
                  children: [
                    for (var i = 0; i < widget.children.length; i++)
                      Positioned(
                        left: panelLeft[panelOf(i)],
                        top: 0,
                        bottom: panelOf(i) == focusedPanel ? keyboardInset : 0,
                        width: panelWidth[panelOf(i)],
                        child: Offstage(
                          offstage: !panelTabs.contains(i),
                          child: ExcludeFocus(
                            excluding: !panelTabs.contains(i),
                            child: Listener(
                              onPointerDown: (_) => widget.onTabPointerDown?.call(i),
                              child: MediaQuery(
                                data: mediaQuery.copyWith(
                                  size: Size(panelWidth[panelOf(i)], mediaQuery.size.height),
                                  viewInsets: widget.resizeFocusedPanelForKeyboard
                                      ? mediaQuery.viewInsets.copyWith(bottom: 0)
                                      : null,
                                ),
                                child: widget.children[i],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (emptyPanel != null && widget.emptyPanel != null)
                  Positioned(
                    key: const ValueKey("emptyPanel"),
                    left: panelLeft[emptyPanel],
                    top: 0,
                    bottom: 0,
                    width: panelWidth[emptyPanel],
                    child: widget.emptyPanel!,
                  ),
                if (divided)
                  Positioned(
                    key: const ValueKey("splitDivider"),
                    left: leftWidth,
                    top: 0,
                    bottom: 0,
                    width: kSplitDividerWidth,
                    child: SplitDivider(
                      width: width,
                      ratio: widget.splitRatio,
                      onRatioChanged: widget.onSplitRatioChanged!,
                    ),
                  ),
                if (panelTabs.length > 1 && focusedPanel != null)
                  Positioned(
                    key: const ValueKey("focusMark"),
                    left: panelLeft[focusedPanel],
                    top: 0,
                    width: panelWidth[focusedPanel],
                    height: 2,
                    child: IgnorePointer(child: ColoredBox(color: Colors.blue[400]!)),
                  ),
                if (panelTabs.length > 1)
                  for (var panel = 0; panel < panelTabs.length; panel++)
                    Positioned(
                      key: ValueKey("dropZone$panel"),
                      left: panelLeft[panel],
                      top: 0,
                      bottom: 0,
                      width: panelWidth[panel],
                      child: TabDropZone(label: panelTabs[panel] == null ? "Open here" : "Move here"),
                    ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      if (!Platform.isWindows) {
        FirebaseCrashlytics.instance.log(
          "PDA Crash at WebViewPanelsStack. Children number: ${widget.children.length}. "
          "Panels: ${widget.panelTabs}. Error: $e",
        );
        FirebaseCrashlytics.instance.recordError(e.toString(), null);
      }
      widget.errorCallback();
      logToUser(
        "PDA Crash at WebViewPanelsStack. Children number: ${widget.children.length}. "
        "Panels: ${widget.panelTabs}. Error: $e",
      );
    }
    return const SizedBox.shrink();
  }
}
