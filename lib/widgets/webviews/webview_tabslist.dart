import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/responsive_text.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/utils/webview_dialog_helper.dart';
import 'package:torn_pda/widgets/webviews/circular_menu/circular_menu_item.dart';
import 'package:torn_pda/widgets/webviews/circular_menu/circular_menu_tabs.dart';
import 'package:torn_pda/widgets/webviews/tabs_lock_dialog.dart';
import 'package:torn_pda/widgets/webviews/tabs_name_dialog.dart';

// Indexes are global: the other group's tabs are hidden children
(int, int)? splitGroupReorderIndexes(List<int> groupTabs, int start, int dropBefore, {bool firstIsFixed = false}) {
  final int oldGroupIndex = groupTabs.indexOf(start);
  if (oldGroupIndex < 0) return null;
  final int dropGroupIndex = groupTabs.where((t) => t < dropBefore).length;
  final int newGroupIndex = dropGroupIndex > oldGroupIndex ? dropGroupIndex - 1 : dropGroupIndex;
  if (newGroupIndex == oldGroupIndex || (firstIsFixed && (oldGroupIndex == 0 || newGroupIndex == 0))) return null;
  return (oldGroupIndex, newGroupIndex);
}

class TabDropZone extends StatefulWidget {
  final String label;

  const TabDropZone({super.key, required this.label});

  @override
  State<TabDropZone> createState() => _TabDropZoneState();
}

class _TabDropZoneState extends State<TabDropZone> {
  static final Set<_TabDropZoneState> _zones = {};
  static final ValueNotifier<_TabDropZoneState?> _hovered = ValueNotifier(null);
  static final ValueNotifier<bool> _labelAtBottom = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _zones.add(this);
  }

  @override
  void dispose() {
    _zones.remove(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ListenableBuilder(
        listenable: Listenable.merge([_hovered, _labelAtBottom]),
        builder: (context, _) {
          if (_hovered.value != this) return const SizedBox.expand();
          return Container(
            alignment: Alignment(0, _labelAtBottom.value ? 0.5 : -0.5),
            decoration: BoxDecoration(
              color: Colors.blue[400]!.withValues(alpha: 0.25),
              border: Border.all(color: Colors.blue[400]!, width: 2),
            ),
            child: Material(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Text(
                  TabsListState._mainTabGhost.value != null ? "Copy here" : widget.label,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class TabsList extends StatefulWidget {
  final SplitGroup group;
  final Widget? leading;

  const TabsList({super.key, this.group = SplitGroup.main, this.leading});

  @override
  State<TabsList> createState() => TabsListState();
}

class TabsListState extends State<TabsList> with TickerProviderStateMixin, WidgetsBindingObserver {
  late ThemeProvider _themeProvider;
  WebViewProvider? _webViewProvider;

  late Animation<double> _tabsOpacity;
  late AnimationController _animationController;

  List<GlobalKey<CircularMenuTabsState>> _circularMenuKeys = <GlobalKey<CircularMenuTabsState>>[];

  ToastificationItem? _lockToast;

  static const double _dragOutMargin = 72;

  final Set<int> _pointersDown = {};
  String? _dragUid;
  int? _dragPointer;
  Offset _dragStart = Offset.zero;
  final ValueNotifier<double?> _ghostShift = ValueNotifier(null);
  bool _dragOut = false;
  Size? _reorderScreen;

  static final ValueNotifier<Offset?> _mainTabGhost = ValueNotifier(null);
  final OverlayPortalController _mainTabGhostPortal = OverlayPortalController()..show();
  Offset _mainTabOrigin = Offset.zero;
  Size _mainTabSize = Size.zero;
  late final AnimationController _mainTabDrop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );
  Offset _mainTabDropFrom = Offset.zero;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

    _tabsOpacity = CurvedAnimation(parent: _animationController, curve: Curves.easeIn);

    _ghostShift.addListener(() {
      if ((_ghostShift.value != null) != _dragOut) setState(() => _dragOut = !_dragOut);
    });

    _mainTabDrop
      ..addListener(() {
        _mainTabGhost.value = Offset.lerp(
          _mainTabOrigin,
          _mainTabDropFrom,
          Curves.easeOut.transform(_mainTabDrop.value),
        );
      })
      ..addStatusListener((status) {
        if (status.isDismissed) _mainTabGhost.value = null;
      });

    WidgetsBinding.instance.addObserver(this);
  }

  // Rotating mid-reorder breaks the SDK reorder
  @override
  void didChangeMetrics() {
    if (_reorderScreen == null) return;
    if (View.of(context).physicalSize == _reorderScreen) return;
    _dragUid = null;
    _dragPointer = null;
    _TabDropZoneState._hovered.value = null;
    _ghostShift.value = null;
    _mainTabGhost.value = null;
    _cancelReorder();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _ghostShift.dispose();
    if (_dragPointer != null || _mainTabDrop.isAnimating) {
      scheduleMicrotask(() {
        _TabDropZoneState._hovered.value = null;
        _mainTabGhost.value = null;
      });
    }
    _mainTabDrop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _webViewProvider = Provider.of<WebViewProvider>(context);
    _themeProvider = Provider.of<ThemeProvider>(context);

    final tabs = <Widget>[];
    final List<int> groupTabs = _webViewProvider!.tabIndexesForGroup(widget.group);
    final bool bothBrowsersShown =
        _webViewProvider!.splitBrowsersActive &&
        _webViewProvider!.splitLeftSlot != SplitSlotContent.app &&
        _webViewProvider!.splitRightSlot != SplitSlotContent.app;

    // Assign GlobalKeys as long as the tab number does not change so that state is kept when using setState
    if (_circularMenuKeys.isEmpty || _circularMenuKeys.length != _webViewProvider!.tabList.length) {
      _circularMenuKeys = List.generate(_webViewProvider!.tabList.length, (_) => GlobalKey<CircularMenuTabsState>());
    }

    for (var i = 0; i < _webViewProvider!.tabList.length; i++) {
      _animationController.forward();

      // Get special user color for text styling (if any)
      Color? specialColor;
      final currentUrl = _webViewProvider!.tabList[i].currentUrl!;

      // Check if this URL belongs to a special user
      for (final userId in _webViewProvider!.getSpecialUserInfo()) {
        if (currentUrl.contains("sid=attack&user2ID=$userId") ||
            currentUrl.contains("profiles.php?XID=$userId") ||
            currentUrl.contains("https://www.torn.com/forums.php#/p=threads&f=67&t=16163503&b=0&a=0")) {
          specialColor = _webViewProvider!.getSpecialUserColor(userId);
          break;
        }
      }

      bool tabCustomNameShown =
          _webViewProvider!.tabList[i].customName.isNotEmpty && _webViewProvider!.tabList[i].customNameInTab;

      final List<Widget> menuOptions = [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: CircularMenuItem(
            icon: _webViewProvider!.tabList[i].isLocked ? Icons.lock : Icons.lock_open,
            onTap: () async {
              final tabLockAlerted = await Prefs().getFirstTabLockAlerted();
              if (!tabLockAlerted) {
                Prefs().setFirstTabLockAlerted(true);
                showWebviewDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return const TabsLockDialog();
                  },
                );
              }

              if (!_webViewProvider!.tabList[i].isLocked && context.read<SettingsProvider>().showTabLockWarnings) {
                if (_lockToast != null) toastification.dismiss(_lockToast!);
                _lockToast = toastification.show(
                  closeOnClick: true,
                  alignment: Alignment.bottomCenter,
                  margin: const EdgeInsets.only(bottom: 50),
                  title: Column(
                    children: [
                      const Icon(Icons.lock, color: Colors.orange),
                      const SizedBox(height: 10),
                      Text("Positional Lock", style: TextStyle(color: _themeProvider.mainText)),
                    ],
                  ),
                  autoCloseDuration: const Duration(milliseconds: 1500),
                  backgroundColor: _themeProvider.canvas,
                  closeButton: ToastCloseButton(
                    buttonBuilder: (context, onClose) {
                      return Icon(Icons.close, color: _themeProvider.mainText);
                    },
                  ),
                  animationDuration: const Duration(milliseconds: 0),
                  type: ToastificationType.info,
                  style: ToastificationStyle.simple,
                  borderSide: BorderSide(width: 1, color: Colors.grey[700]!),
                );
              }

              // Make the change after alerting, so that we take the correct index (before changing it)
              _webViewProvider!.toggleTabLock(tab: _webViewProvider!.tabList[i]);
              _webViewProvider!.verticalMenuClose();
            },
            onLongPress: () async {
              final tabLockAlerted = await Prefs().getFirstTabLockAlerted();
              if (!tabLockAlerted) {
                Prefs().setFirstTabLockAlerted(true);
                showWebviewDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return const TabsLockDialog();
                  },
                );
              }

              if (context.read<SettingsProvider>().showTabLockWarnings) {
                if (_lockToast != null) toastification.dismiss(_lockToast!);
                _lockToast = toastification.show(
                  closeOnClick: true,
                  alignment: Alignment.bottomCenter,
                  margin: const EdgeInsets.only(bottom: 50),
                  title: Column(
                    children: [
                      Icon(Icons.lock, color: _webViewProvider!.tabList[i].isLockFull ? Colors.orange : Colors.red),
                      const SizedBox(height: 10),
                      Text(
                        _webViewProvider!.tabList[i].isLockFull ? "Positional Lock" : "Full Lock",
                        style: TextStyle(color: _themeProvider.mainText),
                      ),
                    ],
                  ),
                  autoCloseDuration: const Duration(milliseconds: 1500),
                  animationDuration: const Duration(milliseconds: 0),
                  backgroundColor: _themeProvider.canvas,
                  closeButton: ToastCloseButton(
                    buttonBuilder: (context, onClose) {
                      return Icon(Icons.close, color: _themeProvider.mainText);
                    },
                  ),
                  type: ToastificationType.info,
                  style: ToastificationStyle.simple,
                  borderSide: BorderSide(width: 1, color: Colors.grey[700]!),
                );
              }

              // Make the change after alerting, so that we take the correct index (before changing it)
              _webViewProvider!.toggleTabLock(
                tab: _webViewProvider!.tabList[i],
                forceLock: true, // Long press always locks full
                isLockFull: !_webViewProvider!.tabList[i].isLockFull,
              );
              _webViewProvider!.verticalMenuClose();
            },
            color: _webViewProvider!.tabList[i].isLockFull ? Colors.red[700] : null,
            iconColor: _webViewProvider!.tabList[i].isLocked && !_webViewProvider!.tabList[i].isLockFull
                ? Colors.orange
                : null,
            boxShadow: _webViewProvider!.tabList[i].isLocked && !_webViewProvider!.tabList[i].isLockFull
                ? [const BoxShadow(color: Colors.orange, blurRadius: 4)]
                : null,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: CircularMenuItem(
            icon: MdiIcons.text,
            onTap: () async {
              _webViewProvider!.verticalMenuClose();
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return EditTabDialog(
                    tabDetails: _webViewProvider!.tabList[i],
                    onSave: (customName, customNameInTitle, customNameInTab) {
                      _webViewProvider!.setTabCustomName(
                        tab: _webViewProvider!.tabList[i],
                        customName: customName,
                        customNameInTitle: customNameInTitle,
                        customNameInTab: customNameInTab,
                      );
                    },
                  );
                },
              );
            },
            iconColor: _webViewProvider!.tabList[i].customName.isNotEmpty ? Colors.lime : null,
            boxShadow: _webViewProvider!.tabList[i].customName.isNotEmpty
                ? [const BoxShadow(color: Colors.lime, blurRadius: 4)]
                : null,
          ),
        ),
        if (_webViewProvider!.currentTab == i && !_webViewProvider!.tabList[i].isLockFull)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: CircularMenuItem(
              icon: Icons.home_outlined,
              onTap: () {
                _webViewProvider!.verticalMenuClose();
                _webViewProvider!.loadCurrentTabUrl("https://www.torn.com");
              },
            ),
          ),
        if (_webViewProvider!.currentTab == i && !_webViewProvider!.tabList[i].isLockFull)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: CircularMenuItem(
              icon: Icons.arrow_back,
              onTap: () {
                _webViewProvider!.tryGoBack();
                _webViewProvider!.verticalMenuClose();
              },
            ),
          ),
        if (_webViewProvider!.currentTab == i && !_webViewProvider!.tabList[i].isLockFull)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: CircularMenuItem(
              icon: Icons.arrow_forward,
              onTap: () {
                _webViewProvider!.tryGoForward();
                _webViewProvider!.verticalMenuClose();
              },
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: CircularMenuItem(
            icon: Icons.copy_all_outlined,
            onTap: () {
              _webViewProvider!.duplicateTab(i);
            },
          ),
        ),
        if (_webViewProvider!.splitScreenWide && _webViewProvider!.splitBrowsersAllowed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Tooltip(
              message: bothBrowsersShown ? "Move to other panel" : "Open in split panel",
              child: CircularMenuItem(
                icon: bothBrowsersShown ? MdiIcons.swapHorizontal : MdiIcons.viewSplitVertical,
                onTap: () {
                  _webViewProvider!.verticalMenuClose();
                  if (_webViewProvider!.tabList[i].isLocked && context.read<SettingsProvider>().showTabLockWarnings) {
                    _showLockedExchangeWarning(i, i, message: "A locked tab cannot be moved to the other panel!");
                    return;
                  }
                  _webViewProvider!.moveTabToOtherGroup(i);
                },
              ),
            ),
          ),
        if (!_webViewProvider!.tabList[i].isLocked)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: CircularMenuItem(
              onTap: () {
                _webViewProvider!.verticalMenuClose();
                _webViewProvider!.removeTab(position: i);
              },
              icon: Icons.delete_forever_outlined,
              color: Colors.red[700],
              iconColor: Colors.white,
            ),
          ),
      ];
      if (i != 0 && _webViewProvider!.verticalMenuIsOpen && _webViewProvider!.verticalMenuCurrentIndex == i) {
        _webViewProvider!.reportVerticalMenuItems(menuOptions.length);
      }

      tabs.add(
        Visibility(
          key: ValueKey(_webViewProvider!.tabList[i].id),
          visible:
              i != 0 && groupTabs.contains(i), // Do not repeat tab #0 in the tabs list
          child: FadeTransition(
            opacity: _tabsOpacity,
            child: CircularMenuTabs(
              webViewProvider: _webViewProvider,
              tabIndex: i,
              alignment: Alignment.centerLeft,
              toggleButtonColor: Colors.transparent,
              toggleButtonIconColor: Colors.transparent,
              toggleButtonOnPressed: () {
                _webViewProvider!.verticalMenuClose();
                _webViewProvider!.activateTab(i);
              },
              backgroundWidget: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    color: _webViewProvider!.isTabVisible(i)
                        ? _themeProvider.navSelected
                        : _themeProvider.currentTheme == AppTheme.extraDark
                        ? Colors.black
                        : _themeProvider.canvas,
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            Padding(
                              padding: tabCustomNameShown
                                  // If we use custom names, we allow the container to move the box a little bit upwards
                                  ? EdgeInsets.fromLTRB(
                                      8,
                                      _webViewProvider!.tabList[i].isLocked || tabCustomNameShown ? 1 : 3,
                                      8,
                                      _webViewProvider!.tabList[i].isLocked || tabCustomNameShown ? 7 : 5,
                                    )
                                  // Otherwise, it will be icons or page title
                                  : _webViewProvider!.useTabIcons
                                  ? const EdgeInsets.all(10.0)
                                  : const EdgeInsets.symmetric(horizontal: 5),
                              child:
                                  // Using custom names
                                  tabCustomNameShown
                                  ? Container(
                                      constraints: const BoxConstraints(minWidth: 30, maxWidth: 70),
                                      height: 32,
                                      child: Align(
                                        widthFactor: 1,
                                        child: ResponsiveText(
                                          text: _webViewProvider!.tabList[i].customName,
                                          maxLines: 3,
                                          maxFontSize: 11,
                                          minFontSize: 8,
                                          textAlign: TextAlign.center,
                                          avoidWordBreak: true,
                                          style: const TextStyle(height: 0.9, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    )
                                  // Using icons:
                                  : _webViewProvider!.useTabIcons
                                  ? SizedBox(
                                      width: 26,
                                      height: 20,
                                      child: Consumer<WebViewProvider>(
                                        builder: (context, provider, child) {
                                          return provider.getTabIcon(i, context);
                                        },
                                      ),
                                    )
                                  // Using page titles
                                  : SizedBox(
                                      height: 40,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            constraints: const BoxConstraints(maxWidth: 100, minWidth: 34),
                                            child: Text(
                                              _webViewProvider!.tabList[i].pageTitle!,
                                              overflow: TextOverflow.clip,
                                              maxLines: 2,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: specialColor ?? _themeProvider.mainText,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                            if (_webViewProvider!.tabList[i].isLocked)
                              Positioned(
                                bottom: 1,
                                right: 1,
                                child: Icon(
                                  Icons.lock,
                                  color: _webViewProvider!.tabList[i].isLockFull
                                      ? Colors.red
                                      : !_webViewProvider!.tabList[i].isLockFull &&
                                            _webViewProvider!.tabList[i].isLocked
                                      ? Colors.orange
                                      : _themeProvider.mainText,
                                  size: 9,
                                ),
                              ),
                            if (_webViewProvider!.tabList[i].customName.isNotEmpty)
                              Positioned(
                                bottom: 1,
                                left: 1,
                                child: Icon(
                                  MdiIcons.text,
                                  color:
                                      (_themeProvider.currentTheme == AppTheme.extraDark ||
                                          _themeProvider.currentTheme == AppTheme.dark)
                                      ? Colors.lime[100]
                                      : const Color.fromARGB(255, 107, 97, 2),
                                  size: 9,
                                ),
                              ),
                            if (_webViewProvider!.tabNumbersFrom > 0 &&
                                _webViewProvider!.tabList.length >= _webViewProvider!.tabNumbersFrom)
                              Positioned(
                                bottom: 0,
                                left: _webViewProvider!.tabList[i].customName.isNotEmpty ? 11 : 2,
                                child: IgnorePointer(
                                  child: Text(
                                    "${i + 1}",
                                    style: TextStyle(
                                      fontSize: 8,
                                      height: 1,
                                      color: _themeProvider.mainText.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 40, child: VerticalDivider(width: 1, thickness: 1, color: Colors.grey[400])),
                      ],
                    ),
                  ),
                ],
              ),
              items: [
                SingleChildScrollView(
                  reverse: true,
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: menuOptions),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final reorderableList = ReorderableListView(
      proxyDecorator: _proxyDecorator,
      buildDefaultDragHandles: false,
      scrollDirection: Axis.horizontal,
      // No auto scroll while dragging out
      physics: _dragOut ? const NeverScrollableScrollPhysics() : null,
      children: tabs,
      onReorderStart: (index) {
        _reorderScreen = View.of(context).physicalSize;
        _dragPointer = _pointersDown.length == 1 ? _pointersDown.first : null;
        _dragUid = _dragPointer == null ? null : _webViewProvider!.tabList[index].id;
      },
      onReorderEnd: (_) {
        _reorderScreen = null;
        _dragUid = null;
      },
      onReorderItem: (start, end) {
        // Flutter 3.44: onReorderItem already corrects `end` for the shortening
        // caused by removing oldIndex. Reverse it so the rest of this function
        // keeps its original semantics (the `end == 0` guard inspects the raw
        // drop target, then `end` is re-decremented before use).
        if (start < end) end += 1;

        if (_webViewProvider!.splitBrowsersActive) {
          final move = splitGroupReorderIndexes(groupTabs, start, end, firstIsFixed: widget.group == SplitGroup.main);
          if (move == null) return;
          final (oldGroupIndex, newGroupIndex) = move;
          if (_webViewProvider!.tabList[start].isLocked !=
                  _webViewProvider!.tabList[groupTabs[newGroupIndex]].isLocked &&
              context.read<SettingsProvider>().showTabLockWarnings) {
            _showLockedExchangeWarning(start, groupTabs[newGroupIndex]);
            return;
          }
          final String movedUid = _webViewProvider!.tabList[start].id;
          _webViewProvider!.reorderTabsInGroup(widget.group, oldGroupIndex, newGroupIndex);
          if (_webViewProvider!.verticalMenuIsOpen && _webViewProvider!.verticalMenuCurrentIndex == start) {
            _webViewProvider!.verticalMenuCurrentIndex = _webViewProvider!.tabList.indexWhere((t) => t.id == movedUid);
          }
          return;
        }

        if (start == 0 || end == 0) return;

        // Save where the current active tab is
        final activeKey = _webViewProvider!.tabList[_webViewProvider!.currentTab].webView!.key;
        // Removing the item at oldIndex will shorten the list by 1
        if (start < end) end -= 1;

        // Prevent the move if one tab is locked and the other unlocked
        // (but allow two locked tabs to exchange positions)
        if (_webViewProvider!.tabList[start].isLocked != _webViewProvider!.tabList[end].isLocked &&
            context.read<SettingsProvider>().showTabLockWarnings) {
          _showLockedExchangeWarning(start, end);
          return;
        }

        // Do the move
        _webViewProvider!.reorderTabs(_webViewProvider!.tabList[start], start, end);
        // Make sure we continue in our previous active tab
        for (var i = 0; i < _webViewProvider!.tabList.length; i++) {
          if (_webViewProvider!.tabList[i].webView?.key == activeKey) {
            _webViewProvider!.activateTab(i);
            break;
          }
        }

        // If the vertical menu is open over the moved tab, ensure it moves with it!
        if (_webViewProvider!.verticalMenuIsOpen) {
          if (_webViewProvider!.verticalMenuCurrentIndex == start) {
            _webViewProvider!.verticalMenuCurrentIndex = end;
          }
        }
      },
    );

    return Listener(
      onPointerDown: (event) {
        _pointersDown.add(event.pointer);
        _dragStart = event.position;
        if (_dragPointer == null) return;
        if (_mainTabGhost.value != null) _reorderScreen = null;
        _dragPointer = null;
        _dragUid = null;
        _TabDropZoneState._hovered.value = null;
        _ghostShift.value = null;
        _mainTabGhost.value = null;
      },
      onPointerMove: (event) {
        if (!mounted || _dragUid == null || event.pointer != _dragPointer) return;
        if (_mainTabGhost.value != null) {
          _mainTabGhost.value = _mainTabOrigin.translate(event.position.dx - _dragStart.dx, 0);
        }
        if (!_webViewProvider!.splitScreenWide || !_webViewProvider!.splitBrowsersAllowed) {
          _TabDropZoneState._hovered.value = null;
          _ghostShift.value = null;
          return;
        }
        final RenderBox bar = context.findRenderObject() as RenderBox;
        final Rect barRect = bar.localToGlobal(Offset.zero) & bar.size;
        _TabDropZoneState? zone;
        for (final candidate in _TabDropZoneState._zones) {
          final RenderBox? box = candidate.context.findRenderObject() as RenderBox?;
          if (box == null || !box.attached || !box.hasSize) continue;
          final Rect rect = box.localToGlobal(Offset.zero) & box.size;
          if (rect.contains(event.position) && !rect.contains(barRect.center)) {
            zone = candidate;
            _TabDropZoneState._labelAtBottom.value = event.position.dy < rect.center.dy;
            break;
          }
        }
        final bool out =
            zone != null || (event.position.dy - barRect.center.dy).abs() > barRect.height / 2 + _dragOutMargin;
        final bool wasOut = _ghostShift.value != null;
        if ((out && !wasOut) || (zone != null && zone != _TabDropZoneState._hovered.value)) {
          if (Platform.isAndroid || Platform.isIOS) HapticFeedback.selectionClick();
        }
        _TabDropZoneState._hovered.value = zone;
        _ghostShift.value = out ? event.position.dy - _dragStart.dy : null;
      },
      onPointerUp: (event) {
        _pointersDown.remove(event.pointer);
        if (!mounted || event.pointer != _dragPointer) return;
        final String? uid = _dragUid;
        final _TabDropZoneState? zone = _TabDropZoneState._hovered.value;
        final bool out = _ghostShift.value != null;
        final Offset? mainTabGhost = _mainTabGhost.value;
        if (mainTabGhost != null) _reorderScreen = null;
        _dragUid = null;
        _dragPointer = null;
        _TabDropZoneState._hovered.value = null;
        _ghostShift.value = null;
        if (mainTabGhost != null && !out) {
          _mainTabDropFrom = mainTabGhost;
          _mainTabDrop.reverse(from: 1);
        } else {
          _mainTabGhost.value = null;
        }
        if (uid == null || !out) return;
        // Before the list changes
        _cancelReorder();
        if (zone == null || !zone.mounted) return;
        if (!_webViewProvider!.splitScreenWide || !_webViewProvider!.splitBrowsersAllowed) return;
        _webViewProvider!.verticalMenuClose();
        final int index = _webViewProvider!.tabList.indexWhere((t) => t.id == uid);
        if (index == 0) {
          final int tabsBefore = _webViewProvider!.tabList.length;
          _webViewProvider!.duplicateTab(0);
          if (_webViewProvider!.tabList.length > tabsBefore) {
            _webViewProvider!.moveTabToOtherGroup(_webViewProvider!.tabList.length - 1);
          }
          return;
        }
        if (_webViewProvider!.tabList[index].isLocked && context.read<SettingsProvider>().showTabLockWarnings) {
          _showLockedExchangeWarning(index, index, message: "A locked tab cannot be moved to the other panel!");
          return;
        }
        _webViewProvider!.moveTabToOtherGroup(index);
      },
      onPointerCancel: (event) {
        _pointersDown.remove(event.pointer);
        if (!mounted || event.pointer != _dragPointer) return;
        _reorderScreen = null;
        _dragUid = null;
        _dragPointer = null;
        _TabDropZoneState._hovered.value = null;
        _ghostShift.value = null;
        _mainTabGhost.value = null;
      },
      child: widget.leading == null
          ? reorderableList
          : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Builder(
                  builder: (leadingContext) => GestureDetector(
                    onLongPressStart: _webViewProvider!.splitScreenWide && _webViewProvider!.splitBrowsersAllowed
                        ? (details) {
                            if (_pointersDown.length != 1) return;
                            // Same press area as the other tabs
                            Rect? dragArea;
                            void findDragArea(Element element) {
                              if (dragArea != null) return;
                              if (element.widget is ReorderableDelayedDragStartListener) {
                                final RenderBox area = element.renderObject! as RenderBox;
                                dragArea = area.localToGlobal(Offset.zero) & area.size;
                              } else {
                                element.visitChildren(findDragArea);
                              }
                            }

                            leadingContext.visitChildElements(findDragArea);
                            if (dragArea == null || !dragArea!.contains(_dragStart)) return;
                            final RenderBox box = leadingContext.findRenderObject() as RenderBox;
                            _mainTabDrop.stop();
                            _reorderScreen = View.of(context).physicalSize;
                            _dragPointer = _pointersDown.first;
                            _dragUid = _webViewProvider!.tabList[0].id;
                            _mainTabOrigin = box.localToGlobal(Offset.zero);
                            _mainTabSize = box.size;
                            _mainTabGhost.value = _mainTabOrigin.translate(
                              details.globalPosition.dx - _dragStart.dx,
                              0,
                            );
                          }
                        : null,
                    child: OverlayPortal(
                      controller: _mainTabGhostPortal,
                      overlayChildBuilder: (overlayContext) => ValueListenableBuilder<Offset?>(
                        valueListenable: _mainTabGhost,
                        builder: (_, ghost, _) {
                          if (ghost == null || (_dragUid == null && !_mainTabDrop.isAnimating)) {
                            return const SizedBox.shrink();
                          }
                          final RenderBox overlay = Overlay.of(overlayContext).context.findRenderObject() as RenderBox;
                          final Offset topLeft = overlay.globalToLocal(ghost);
                          return Positioned(
                            left: topLeft.dx,
                            top: topLeft.dy,
                            child: IgnorePointer(
                              child: SizedBox.fromSize(
                                size: _mainTabSize,
                                child: _proxyDecorator(widget.leading!, 0, kAlwaysCompleteAnimation),
                              ),
                            ),
                          );
                        },
                      ),
                      child: widget.leading,
                    ),
                  ),
                ),
                SizedBox(height: 40, child: VerticalDivider(width: 2, thickness: 2, color: _themeProvider.mainText)),
                Flexible(child: reorderableList),
              ],
            ),
    );
  }

  void _cancelReorder() {
    _reorderScreen = null;
    void cancel(Element element) {
      if (element is StatefulElement && element.state is SliverReorderableListState) {
        (element.state as SliverReorderableListState).cancelReorder();
      } else {
        element.visitChildren(cancel);
      }
    }

    context.visitChildElements(cancel);
  }

  void _showLockedExchangeWarning(
    int first,
    int second, {
    String message = "A locked tab cannot be exchanged with an unlocked one!",
  }) {
    toastification.show(
      closeOnClick: true,
      alignment: Alignment.bottomCenter,
      margin: const EdgeInsets.only(bottom: 50),
      title: SizedBox(
        child: Column(
          children: [
            Icon(
              Icons.lock,
              color: _webViewProvider!.tabList[first].isLockFull || _webViewProvider!.tabList[second].isLockFull
                  ? Colors.red
                  : Colors.orange,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              maxLines: 5,
              textAlign: TextAlign.center,
              style: TextStyle(color: _themeProvider.mainText),
            ),
          ],
        ),
      ),
      autoCloseDuration: const Duration(seconds: 3),
      animationDuration: const Duration(milliseconds: 0),
      backgroundColor: _themeProvider.canvas,
      closeButton: ToastCloseButton(
        buttonBuilder: (context, onClose) {
          return Icon(Icons.close, color: _themeProvider.mainText);
        },
      ),
      type: ToastificationType.info,
      style: ToastificationStyle.simple,
      borderSide: BorderSide(width: 1, color: Colors.grey[700]!),
    );
  }

  Widget _proxyDecorator(Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: Listenable.merge([animation, _ghostShift]),
      builder: (BuildContext context, Widget? child) {
        return Transform.translate(
          offset: Offset(0, _ghostShift.value ?? 0),
          child: Material(color: Colors.transparent, child: child),
        );
      },
      child: child,
    );
  }
}
