import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/widgets/webviews/circular_menu/circular_menu_tabs.dart';
import 'package:torn_pda/widgets/webviews/circular_menu/circular_menu_item.dart';

class TabsList extends StatefulWidget {
  const TabsList({Key key}) : super(key: key);

  @override
  State<TabsList> createState() => _TabsListState();
}

class _TabsListState extends State<TabsList> with TickerProviderStateMixin {
  ThemeProvider _themeProvider;
  WebViewProvider _webViewProvider;

  Animation<double> _tabsOpacity;
  AnimationController _animationController;

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
  Widget build(BuildContext context) {
    _webViewProvider = Provider.of<WebViewProvider>(context, listen: true);
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);

    var tabs = <Widget>[];

    // Assign GlobalKeys as long as the tab number does not change so that state is kept when using setState
    if (_circularMenuKeys.isEmpty || _circularMenuKeys.length != _webViewProvider.tabList.length) {
      _circularMenuKeys = List.generate(
        _webViewProvider.tabList.length,
        (_) => GlobalKey<CircularMenuTabsState>(),
      );
    }

    for (var i = 0; i < _webViewProvider.tabList.length; i++) {
      _animationController.forward();

      bool isManuito = _webViewProvider.tabList[i].currentUrl.contains("sid=attack&user2ID=2225097") ||
          _webViewProvider.tabList[i].currentUrl.contains("profiles.php?XID=2225097") ||
          _webViewProvider.tabList[i].currentUrl.contains("https://www.torn.com/forums.php#/"
              "p=threads&f=67&t=16163503&b=0&a=0");

      tabs.add(
        Visibility(
          key: UniqueKey(),
          visible: i == 0 ? false : true, // Do not repeat tab #0 in the tabs list
          child: FadeTransition(
            opacity: _tabsOpacity,
            child: CircularMenuTabs(
              key: _circularMenuKeys[i],
              webViewProvider: _webViewProvider,
              tabIndex: i,
              alignment: Alignment.centerLeft,
              toggleButtonColor: Colors.transparent,
              toggleButtonIconColor: Colors.transparent,
              toggleButtonOnPressed: () {
                _webViewProvider.verticalMenuClose();
                _webViewProvider.activateTab(i);
              },
              backgroundWidget: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Container(
                    color: _webViewProvider.currentTab == i
                        ? _themeProvider.navSelected
                        : _themeProvider.currentTheme == AppTheme.extraDark
                            ? Colors.black
                            : _themeProvider.canvas,
                    child: Row(
                      children: [
                        Padding(
                          padding: _webViewProvider.useTabIcons
                              ? const EdgeInsets.all(10.0)
                              : const EdgeInsets.symmetric(horizontal: 5),
                          child: _webViewProvider.useTabIcons
                              ? SizedBox(width: 26, height: 20, child: _webViewProvider.getIcon(i, context))
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Container(
                                      constraints: const BoxConstraints(
                                        maxWidth: 100,
                                        minWidth: 34,
                                      ),
                                      child: Text(
                                        _webViewProvider.tabList[i].pageTitle,
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
                CircularMenuItem(
                  onTap: () {
                    _webViewProvider.verticalMenuClose();
                    _webViewProvider.removeTab(position: i);
                  },
                  icon: Icons.delete_forever_outlined,
                  color: Colors.red[700],
                  iconColor: Colors.white,
                ),
                CircularMenuItem(
                  icon: Icons.copy_all_outlined,
                  onTap: () {
                    _webViewProvider.duplicateTab(i);
                  },
                ),
                if (_webViewProvider.currentTab == i)
                  CircularMenuItem(
                    icon: Icons.arrow_forward,
                    onTap: () {
                      _webViewProvider.tryGoForward();
                      _webViewProvider.verticalMenuClose();
                    },
                  ),
                if (_webViewProvider.currentTab == i)
                  CircularMenuItem(
                    icon: Icons.arrow_back,
                    onTap: () {
                      _webViewProvider.tryGoBack();
                      _webViewProvider.verticalMenuClose();
                    },
                  ),
                if (_webViewProvider.currentTab == i)
                  CircularMenuItem(
                    icon: Icons.home_outlined,
                    onTap: () {
                      _webViewProvider.verticalMenuClose();
                      _webViewProvider.loadCurrentTabUrl("https://www.torn.com");
                    },
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return ReorderableListView(
      proxyDecorator: _proxyDecorator,
      scrollDirection: Axis.horizontal,
      children: tabs,
      onReorder: (start, end) {
        if (start == 0 || end == 0) return;
        // Save where the current active tab is
        var activeKey = _webViewProvider.tabList[_webViewProvider.currentTab].webView.key;
        // Removing the item at oldIndex will shorten the list by 1
        if (start < end) end -= 1;
        // Do the move
        _webViewProvider.reorderTabs(_webViewProvider.tabList[start], start, end);
        // Make sure we continue in our previous active tab
        for (var i = 0; i < _webViewProvider.tabList.length; i++) {
          if (_webViewProvider.tabList[i].webView?.key == activeKey) {
            _webViewProvider.activateTab(i);
            break;
          }
        }

        // If the vertical menu is open over the moved tab, ensure it moves with it!
        if (_webViewProvider.verticalMenuIsOpen) {
          if (_webViewProvider.verticalMenuCurrentIndex == start) {
            _webViewProvider.verticalMenuCurrentIndex = end;
          }
        }
      },
    );
  }

  Widget _proxyDecorator(Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget child) {
        return Material(
          color: Colors.transparent,
          child: child,
        );
      },
      child: child,
    );
  }
}
