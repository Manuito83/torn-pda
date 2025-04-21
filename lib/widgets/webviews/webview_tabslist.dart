import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/responsive_text.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/webviews/circular_menu/circular_menu_item.dart';
import 'package:torn_pda/widgets/webviews/circular_menu/circular_menu_tabs.dart';
import 'package:torn_pda/widgets/webviews/tabs_lock_dialog.dart';
import 'package:torn_pda/widgets/webviews/tabs_name_dialog.dart';

class TabsList extends StatefulWidget {
  const TabsList({super.key});

  @override
  State<TabsList> createState() => TabsListState();
}

class TabsListState extends State<TabsList> with TickerProviderStateMixin {
  late ThemeProvider _themeProvider;
  WebViewProvider? _webViewProvider;

  late Animation<double> _tabsOpacity;
  late AnimationController _animationController;

  List<GlobalKey<CircularMenuTabsState>> _circularMenuKeys = <GlobalKey<CircularMenuTabsState>>[];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _tabsOpacity = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _webViewProvider = Provider.of<WebViewProvider>(context);
    _themeProvider = Provider.of<ThemeProvider>(context);

    final tabs = <Widget>[];

    // Assign GlobalKeys as long as the tab number does not change so that state is kept when using setState
    if (_circularMenuKeys.isEmpty || _circularMenuKeys.length != _webViewProvider!.tabList.length) {
      _circularMenuKeys = List.generate(
        _webViewProvider!.tabList.length,
        (_) => GlobalKey<CircularMenuTabsState>(),
      );
    }

    for (var i = 0; i < _webViewProvider!.tabList.length; i++) {
      _animationController.forward();

      final bool isManuito = _webViewProvider!.tabList[i].currentUrl!.contains("sid=attack&user2ID=2225097") ||
          _webViewProvider!.tabList[i].currentUrl!.contains("profiles.php?XID=2225097") ||
          _webViewProvider!.tabList[i].currentUrl!.contains("https://www.torn.com/forums.php#/"
              "p=threads&f=67&t=16163503&b=0&a=0");

      bool tabCustomNameShown =
          _webViewProvider!.tabList[i].customName.isNotEmpty && _webViewProvider!.tabList[i].customNameInTab;

      tabs.add(
        Visibility(
          key: UniqueKey(),
          visible: i == 0 ? false : true, // Do not repeat tab #0 in the tabs list
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
                    color: _webViewProvider!.currentTab == i
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
                                          width: 30,
                                          height: 32,
                                          child: Center(
                                            child: ResponsiveText(
                                              text: _webViewProvider!.tabList[i].customName,
                                              maxLines: 3,
                                              maxFontSize: 11,
                                              minFontSize: 8,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                height: 0.9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        )
                                      // Using icons:
                                      : _webViewProvider!.useTabIcons
                                          ? SizedBox(
                                              width: 26,
                                              height: 20,
                                              child: _webViewProvider!.getIcon(i, context),
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
                                                        color: isManuito ? Colors.pink : _themeProvider.mainText,
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
                                  color: (_themeProvider.currentTheme == AppTheme.extraDark ||
                                          _themeProvider.currentTheme == AppTheme.dark)
                                      ? Colors.lime[100]
                                      : const Color.fromARGB(255, 107, 97, 2),
                                  size: 9,
                                ),
                              ),
                          ],
                        ),
                        SizedBox(
                          height: 40,
                          child: VerticalDivider(
                            width: 1,
                            thickness: 1,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              items: [
                SingleChildScrollView(
                  reverse: true,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: CircularMenuItem(
                          icon: _webViewProvider!.tabList[i].isLocked ? Icons.lock : Icons.lock_open,
                          onTap: () async {
                            final tabLockAlerted = await Prefs().getFirstTabLockAlerted();
                            if (!tabLockAlerted) {
                              Prefs().setFirstTabLockAlerted(true);
                              showDialog<void>(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext context) {
                                  return const TabsLockDialog();
                                },
                              );
                            }

                            if (!_webViewProvider!.tabList[i].isLocked &&
                                context.read<SettingsProvider>().showTabLockWarnings) {
                              toastification.dismissAll();
                              toastification.show(
                                closeOnClick: true,
                                alignment: Alignment.bottomCenter,
                                title: const Column(
                                  children: [
                                    Icon(
                                      Icons.lock,
                                      color: Colors.orange,
                                    ),
                                    SizedBox(height: 10),
                                    Text("Positional Lock"),
                                  ],
                                ),
                                autoCloseDuration: const Duration(milliseconds: 1500),
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
                              showDialog<void>(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext context) {
                                  return const TabsLockDialog();
                                },
                              );
                            }

                            if (context.read<SettingsProvider>().showTabLockWarnings) {
                              toastification.dismissAll();
                              toastification.show(
                                closeOnClick: true,
                                alignment: Alignment.bottomCenter,
                                title: Column(
                                  children: [
                                    Icon(
                                      Icons.lock,
                                      color: _webViewProvider!.tabList[i].isLockFull ? Colors.orange : Colors.red,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(_webViewProvider!.tabList[i].isLockFull ? "Positional Lock" : "Full Lock"),
                                  ],
                                ),
                                autoCloseDuration: const Duration(milliseconds: 1500),
                                animationDuration: const Duration(milliseconds: 0),
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
                              ? [
                                  const BoxShadow(color: Colors.orange, blurRadius: 4),
                                ]
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
                              ? [
                                  const BoxShadow(color: Colors.lime, blurRadius: 4),
                                ]
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ReorderableListView(
      proxyDecorator: _proxyDecorator,
      buildDefaultDragHandles: false,
      scrollDirection: Axis.horizontal,
      children: tabs,
      onReorder: (start, end) {
        if (start == 0 || end == 0) return;

        // Save where the current active tab is
        final activeKey = _webViewProvider!.tabList[_webViewProvider!.currentTab].webView!.key;
        // Removing the item at oldIndex will shorten the list by 1
        if (start < end) end -= 1;

        // Prevent the move if one tab is locked and the other unlocked
        // (but allow two locked tabs to exchange positions)
        if (_webViewProvider!.tabList[start].isLocked != _webViewProvider!.tabList[end].isLocked &&
            context.read<SettingsProvider>().showTabLockWarnings) {
          toastification.show(
            closeOnClick: true,
            alignment: Alignment.bottomCenter,
            title: SizedBox(
              child: Column(
                children: [
                  Icon(
                    Icons.lock,
                    color: _webViewProvider!.tabList[start].isLockFull || _webViewProvider!.tabList[end].isLockFull
                        ? Colors.red
                        : Colors.orange,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "A locked tab cannot be exchanged with an unlocked one!",
                    maxLines: 5,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            autoCloseDuration: const Duration(seconds: 3),
            animationDuration: const Duration(milliseconds: 0),
            type: ToastificationType.info,
            style: ToastificationStyle.simple,
            borderSide: BorderSide(width: 1, color: Colors.grey[700]!),
          );

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
  }

  Widget _proxyDecorator(Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        return Material(
          color: Colors.transparent,
          child: child,
        );
      },
      child: child,
    );
  }
}
