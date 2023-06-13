import 'dart:developer';

import 'package:bot_toast/bot_toast.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/animated_indexedstack.dart';
import 'package:torn_pda/widgets/webviews/chaining_payload.dart';
import 'package:torn_pda/widgets/webviews/circular_menu/circular_menu_fixed.dart';
import 'package:torn_pda/widgets/webviews/circular_menu/circular_menu_item.dart';
import 'package:torn_pda/widgets/webviews/circular_menu/circular_menu_tabs.dart';
import 'package:torn_pda/widgets/webviews/fullscreen_explanation.dart';
import 'package:torn_pda/widgets/webviews/tabs_excess_dialog.dart';
import 'package:torn_pda/widgets/webviews/tabs_wipe_dialog.dart';
import 'package:torn_pda/widgets/webviews/webview_shortcuts_dialog.dart';
import 'package:torn_pda/widgets/webviews/webview_tabslist.dart';
import 'package:torn_pda/widgets/webviews/webview_url_dialog.dart';

enum BrowserTapType {
  short,
  long,
  chain,
  notification,
  deeplink,
  quickItem,
}

class WebViewStackView extends StatefulWidget {
  final String initUrl;
  final bool recallLastSession;

  // Chaining
  final bool isChainingBrowser;
  final ChainingPayload chainingPayload;

  const WebViewStackView({
    this.initUrl = "https://www.torn.com",
    this.recallLastSession = false,

    // Chaining
    this.isChainingBrowser = false,
    this.chainingPayload,
    Key key,
  }) : super(key: key);

  @override
  _WebViewStackViewState createState() => _WebViewStackViewState();
}

class _WebViewStackViewState extends State<WebViewStackView>
    with WidgetsBindingObserver, TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  ThemeProvider _themeProvider;
  WebViewProvider _webViewProvider;
  SettingsProvider _settingsProvider;

  //bool _useTabs = false;

  Future providerInitialised;
  bool secondaryInitialised = false;

  // Showcases
  DateTime _lastShowCasesCheck;
  GlobalKey _showcaseTabsGeneral = GlobalKey();
  GlobalKey _showQuickMenuButton = GlobalKey();
  GlobalKey _showCaseNewTabButton = GlobalKey();
  GlobalKey<CircularMenuFixedState> _circularMenuKey = GlobalKey();

  Animation<double> _menuTabOpacity;
  AnimationController _menuTabAnimationController;

  bool _keyboardVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _settingsProvider = context.read<SettingsProvider>();

    // Initialise WebViewProvider
    providerInitialised = Provider.of<WebViewProvider>(context, listen: false).initialiseMain(
      initUrl: widget.initUrl,
      recallLastSession: widget.recallLastSession,
      isChainingBrowser: widget.isChainingBrowser,
      chainingPayload: widget.chainingPayload,
      restoreSessionCookie: _settingsProvider.restoreSessionCookie,
      context: context,
    );

    _menuTabAnimationController = AnimationController(
      vsync: this,
      value: 1,
    );

    _menuTabOpacity = CurvedAnimation(
      parent: _menuTabAnimationController,
      curve: Curves.easeIn,
    );
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _keyboardVisible = WidgetsBinding.instance.window.viewInsets.bottom > 0;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _webViewProvider = Provider.of<WebViewProvider>(context, listen: true);
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);

    if (_webViewProvider.bottomBarStyleEnabled && _webViewProvider.bottomBarStyleType == 2) {
      return Dialog(
        insetPadding: EdgeInsets.only(
          top: _webViewProvider.currentUiMode == UiMode.window ? 45 : 0,
          bottom: _webViewProvider.currentUiMode == UiMode.window
              ? _keyboardVisible
                  ? 0
                  : 45
              : 0,
          left: _webViewProvider.currentUiMode == UiMode.window ? 8 : 0,
          right: _webViewProvider.currentUiMode == UiMode.window ? 8 : 0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        child: Container(
          color: _themeProvider.currentTheme == AppTheme.extraDark ? Color(0xFF131313) : Colors.transparent,
          child: Padding(
            padding: EdgeInsets.only(
              top: _webViewProvider.currentUiMode == UiMode.window ? 6 : 0,
              bottom: _webViewProvider.currentUiMode == UiMode.window
                  ? _themeProvider.currentTheme == AppTheme.extraDark
                      ? 6
                      : 4
                  : 0,
              left: _webViewProvider.currentUiMode == UiMode.window ? 5 : 0,
              right: _webViewProvider.currentUiMode == UiMode.window ? 5 : 0,
            ),
            child: stackView(),
          ),
        ),
      );
    }

    return stackView();
  }

  Widget stackView() {
    bool dialog = _webViewProvider.bottomBarStyleEnabled && _webViewProvider.bottomBarStyleType == 2;

    return MediaQuery.removePadding(
      context: context,
      removeTop: true,  // Always needed in dialog to allow top bar taps
      child: Container(
        color: _themeProvider.currentTheme == AppTheme.light
            ? MediaQuery.of(context).orientation == Orientation.portrait
                ? Colors.blueGrey
                : Colors.grey[900]
            : _themeProvider.currentTheme == AppTheme.dark
                ? Colors.grey[900]
                : Colors.black,
        child: SafeArea(
          top: !dialog &&
              !(_settingsProvider.fullScreenOverNotch && _webViewProvider.currentUiMode == UiMode.fullScreen),
          bottom: !dialog &&
              !(_settingsProvider.fullScreenOverBottom && _webViewProvider.currentUiMode == UiMode.fullScreen),
          left: !dialog &&
              !(_settingsProvider.fullScreenOverSides && _webViewProvider.currentUiMode == UiMode.fullScreen),
          right: !dialog &&
              !(_settingsProvider.fullScreenOverSides && _webViewProvider.currentUiMode == UiMode.fullScreen),
          child: ShowCaseWidget(
            builder: Builder(builder: (_) {
              if (_webViewProvider.browserShowInForeground) {
                _launchShowCases(_);
              }
              return Scaffold(
                // Dialog displaces the webview up by default
                resizeToAvoidBottomInset:
                    !(_webViewProvider.bottomBarStyleEnabled && _webViewProvider.bottomBarStyleType == 2),
                backgroundColor: _themeProvider.statusBar,
                body: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    FutureBuilder(
                      future: providerInitialised,
                      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          var allWebViews = <Widget>[];
                          for (var tab in _webViewProvider.tabList) {
                            if (tab.webView == null) {
                              allWebViews.add(SizedBox.shrink());
                            } else {
                              allWebViews.add(tab.webView);
                            }
                          }

                          if (allWebViews.isEmpty) _closeWithError();

                          if (!secondaryInitialised) {
                            secondaryInitialised = true;
                            _initialiseSecondary();
                          }

                          if (_settingsProvider.useTabsFullBrowser) {
                            try {
                              return AnimatedIndexedStack(
                                index: _webViewProvider.currentTab,
                                children: allWebViews,
                                duration: 100,
                                errorCallback: _closeWithError,
                              );
                            } catch (e) {
                              FirebaseCrashlytics.instance.log("PDA Crash at StackView (webview with tabs): $e");
                              FirebaseCrashlytics.instance.recordError(e.toString(), null);
                              _closeWithError();
                            }
                          } else {
                            try {
                              return AnimatedIndexedStack(
                                index: 0,
                                children: [
                                  allWebViews[0],
                                ],
                                duration: 100,
                                errorCallback: _closeWithError,
                              );
                            } catch (e) {
                              FirebaseCrashlytics.instance.log("PDA Crash at StackView (webview with no tabs): $e");
                              FirebaseCrashlytics.instance.recordError(e.toString(), null);
                              _closeWithError();
                            }
                          }
                        } else {
                          return Center(child: CircularProgressIndicator());
                        }
                        return SizedBox.shrink();
                      },
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        bottom:
                            _webViewProvider.bottomBarStyleEnabled && _webViewProvider.currentUiMode == UiMode.window
                                ? 38
                                : 0,
                      ),
                      child: FutureBuilder(
                        future: providerInitialised,
                        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                          if (snapshot.connectionState == ConnectionState.done &&
                              _settingsProvider.useTabsFullBrowser) {
                            // Don't hide to hide tabs on fullscreen, or we might not be able to return to the app!
                            if (_webViewProvider.hideTabs && _webViewProvider.currentUiMode == UiMode.window) {
                              return Divider(
                                color: Color(_settingsProvider.tabsHideBarColor),
                                thickness: 4,
                                height: 4,
                              );
                            } else {
                              return _bottomNavBar(_);
                            }
                          } else {
                            return SizedBox.shrink();
                          }
                        },
                      ),
                    )
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  void _launchShowCases(BuildContext _) {
    if (!_webViewProvider.browserShowInForeground) return;

    // Ensure only one execution per minute, so that showcases wait even if the first mandatory ones are shown
    DateTime now = DateTime.now();
    if (_lastShowCasesCheck != null && now.difference(_lastShowCasesCheck).inSeconds < 60) {
      return;
    }
    _lastShowCasesCheck = now;

    Future.delayed(Duration(seconds: 1), () async {
      bool showCasesNeedToWait = false;

      List showCases = <GlobalKey<State<StatefulWidget>>>[];
      // Check that there is no pending showcases to show by the browser
      // If there is, wait until we open the browser for the next time
      if ((_webViewProvider.bottomBarStyleEnabled && !_settingsProvider.showCases.contains("webview_closeButton")) ||
          (!_webViewProvider.bottomBarStyleEnabled && !_settingsProvider.showCases.contains("webview_titleBar")) ||
          (_webViewProvider.tabList[0].isChainingBrowser &&
              _webViewProvider.currentTab == 0 &&
              !_settingsProvider.showCases.contains("webview_playPauseChain"))) {
        showCasesNeedToWait = true;
      }

      // Show tab bar showcases
      if (!showCasesNeedToWait) {
        if (!_settingsProvider.showCases.contains("tabs_quickMenuButton2")) {
          _settingsProvider.addShowCase = "tabs_quickMenuButton2";
          showCases.add(_showQuickMenuButton);
        }
        if (!_settingsProvider.showCases.contains("tabs_newTabButton")) {
          _settingsProvider.addShowCase = "tabs_newTabButton";
          showCases.add(_showCaseNewTabButton);
        }
      }

      if (showCases.isNotEmpty) {
        ShowCaseWidget.of(_).startShowCase(showCases);
      }
    });
  }

  void _closeWithError() {
    BotToast.showText(
      clickClose: true,
      crossPage: true,
      text: "Something went wrong, please try again. "
          "If tabs are stuck, consider resetting the browser cache in Settings.",
      textStyle: TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
      contentColor: Colors.deepOrangeAccent,
      duration: Duration(seconds: 4),
      contentPadding: EdgeInsets.all(10),
    );

    Get.back();
  }

  void _initialiseSecondary() async {
    await Future.delayed(Duration(milliseconds: 1000));
    if (!mounted) return;
    Provider.of<WebViewProvider>(context, listen: false).initialiseSecondary(
      useTabs: _settingsProvider.useTabsFullBrowser,
      recallLastSession: widget.recallLastSession,
    );
  }

  @override
  Future dispose() async {
    _webViewProvider.clearOnDispose();
    _webViewProvider.verticalMenuIsOpen = false;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Widget _bottomNavBar(BuildContext _) {
    bool isManuito = _webViewProvider.tabList[0].currentUrl.contains("sid=attack&user2ID=2225097") ||
        _webViewProvider.tabList[0].currentUrl.contains("profiles.php?XID=2225097") ||
        _webViewProvider.tabList[0].currentUrl.contains("https://www.torn.com/forums.php#/"
            "p=threads&f=67&t=16163503&b=0&a=0");

    var mainTab = FadeTransition(
      key: UniqueKey(),
      opacity: _menuTabOpacity,
      child: CircularMenuTabs(
        tabIndex: 0,
        webViewProvider: _webViewProvider,
        alignment: Alignment.centerLeft,
        toggleButtonColor: Colors.transparent,
        toggleButtonIconColor: Colors.transparent,
        toggleButtonOnPressed: () {
          _webViewProvider.verticalMenuClose();
          _webViewProvider.activateTab(0);
        },
        backgroundWidget: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              color: _webViewProvider.currentTab == 0
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
                        ? SizedBox(width: 26, height: 20, child: _webViewProvider.getIcon(0, context))
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 100,
                                  minWidth: 34,
                                ),
                                child: Column(
                                  children: [
                                    if (_webViewProvider.tabList[0].isChainingBrowser)
                                      Text(
                                        "CHAIN",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 8,
                                          color: Colors.red[800],
                                        ),
                                      ),
                                    Text(
                                      _webViewProvider.tabList[0].pageTitle,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isManuito ? Colors.pink : _themeProvider.mainText,
                                      ),
                                    ),
                                  ],
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
            icon: Icons.copy_all_outlined,
            onTap: () {
              _webViewProvider.duplicateTab(0);
            },
          ),
          if (_webViewProvider.currentTab == 0)
            CircularMenuItem(
              icon: Icons.arrow_forward,
              onTap: () {
                _webViewProvider.tryGoForward();
                _webViewProvider.verticalMenuClose();
              },
            ),
          if (_webViewProvider.currentTab == 0)
            CircularMenuItem(
              icon: Icons.arrow_back,
              onTap: () {
                _webViewProvider.tryGoBack();
                _webViewProvider.verticalMenuClose();
              },
            ),
          if (_webViewProvider.currentTab == 0)
            CircularMenuItem(
              icon: Icons.home_outlined,
              onTap: () {
                _webViewProvider.verticalMenuClose();
                _webViewProvider.loadCurrentTabUrl("https://www.torn.com");
              },
            ),
        ],
      ),
    );

    return Showcase(
      disableMovingAnimation: true,
      textColor: _themeProvider.mainText,
      tooltipBackgroundColor: _themeProvider.secondBackground,
      key: _showcaseTabsGeneral,
      title: 'New tab...!',
      description: "\nYou've opened a new tab!\n\nThere are two important things to remember: a DOUBLE TAP will "
          "open a menu with a few options (including navigation arrows which might be useful in full screen "
          "mode!), and a TRIPLE TAP will instantly remove a tab (except for the first one, which is persistent)."
          "\n\nVisit the Tips section for more information!\n",
      descTextStyle: TextStyle(fontSize: 13),
      tooltipPadding: EdgeInsets.all(20),
      child: GestureDetector(
        onTap: () => _webViewProvider.verticalMenuClose(),
        child: Container(
          color: Colors.transparent,
          height: _webViewProvider.verticalMenuIsOpen ? 300 : 40,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                height: 40,
                color: _themeProvider.canvas,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Flexible(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        mainTab,
                        SizedBox(
                          height: 40,
                          child: VerticalDivider(
                            width: 2,
                            thickness: 2,
                            color: _themeProvider.mainText,
                          ),
                        ),
                        // Main tabs widget
                        Flexible(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: const [
                              Flexible(
                                child: TabsList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Showcase(
                    key: _showQuickMenuButton,
                    title: 'Quick menu',
                    description: '\nTap to show a quick list of quick actions, including shortcuts, '
                        'fullscreen mode and more! Some quick shortcuts are:\n\n'
                        'Double tap to get quick access to shortcuts\n\n'
                        'When in full screen mode, long-press to revert to windowed mode immediately',
                    targetPadding: const EdgeInsets.all(10),
                    disableMovingAnimation: true,
                    textColor: _themeProvider.mainText,
                    tooltipBackgroundColor: _themeProvider.secondBackground,
                    descTextStyle: TextStyle(fontSize: 13),
                    tooltipPadding: EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SizedBox(
                          height: 40,
                          child: VerticalDivider(
                            width: 2,
                            thickness: 2,
                            color: _themeProvider.mainText,
                          ),
                        ),
                        FadeTransition(
                          key: UniqueKey(),
                          opacity: _menuTabOpacity,
                          child: CircularMenuFixed(
                            key: _circularMenuKey,
                            webViewProvider: _webViewProvider,
                            alignment: Alignment.centerLeft,
                            toggleButtonColor: Colors.transparent,
                            toggleButtonIconColor: Colors.transparent,
                            // Adds a return to windowed mode if we are in fullscreen with a double tap
                            // Otherwise, the default double tap behavior applies
                            longPressed: _webViewProvider.currentUiMode == UiMode.window
                                ? null
                                : () {
                                    _webViewProvider.verticalMenuClose();
                                    _webViewProvider.setCurrentUiMode(UiMode.window, context);
                                    if (_settingsProvider.fullScreenRemovesChat) {
                                      _webViewProvider.showAllChatsFullScreen();
                                    }
                                  },
                            doubleTapped: () {
                              _webViewProvider.verticalMenuClose();
                              return showDialog<void>(
                                context: context,
                                barrierDismissible: true,
                                builder: (BuildContext context) {
                                  return WebviewShortcutsDialog(fromShortcut: true);
                                },
                              );
                            },
                            backgroundWidget: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Container(
                                  color: _themeProvider.navSelected,
                                  child: Row(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                                        child: _webViewProvider.currentUiMode == UiMode.window
                                            ? Icon(MdiIcons.dotsHorizontal)
                                            : Icon(
                                                MdiIcons.dotsHorizontalCircleOutline,
                                                color: Colors.orange[800],
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
                                icon: MdiIcons.heartOutline,
                                onTap: () {
                                  _webViewProvider.verticalMenuClose();
                                  return showDialog<void>(
                                    context: context,
                                    barrierDismissible: true,
                                    builder: (BuildContext context) {
                                      return WebviewShortcutsDialog(fromShortcut: true);
                                    },
                                  );
                                },
                              ),
                              CircularMenuItem(
                                icon: MdiIcons.heartPlusOutline,
                                onTap: () {
                                  _webViewProvider.verticalMenuClose();
                                  return showDialog<void>(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (BuildContext context) {
                                      return CustomShortcutDialog(
                                        themeProvider: _themeProvider,
                                        title: _webViewProvider.currentTabTitle(),
                                        url: _webViewProvider.currentTabUrl(),
                                      );
                                    },
                                  );
                                },
                              ),
                              CircularMenuItem(
                                icon: _webViewProvider.currentUiMode == UiMode.window
                                    ? MdiIcons.fullscreen
                                    : MdiIcons.fullscreenExit,
                                color: _webViewProvider.currentUiMode == UiMode.window ? null : Colors.orange,
                                onTap: () async {
                                  _webViewProvider.verticalMenuClose();
                                  await Future.delayed(Duration(milliseconds: 150));
                                  if (_webViewProvider.currentUiMode == UiMode.window) {
                                    _webViewProvider.setCurrentUiMode(UiMode.fullScreen, context);
                                    if (_settingsProvider.fullScreenRemovesChat) {
                                      _webViewProvider.removeAllChatsFullScreen();
                                    }

                                    if (!await Prefs().getFullScreenExplanationShown()) {
                                      Prefs().setFullScreenExplanationShown(true);
                                      return showDialog<void>(
                                        context: _,
                                        barrierDismissible: false,
                                        builder: (BuildContext context) {
                                          return const FullScreenExplanationDialog();
                                        },
                                      );
                                    }
                                  } else {
                                    _webViewProvider.setCurrentUiMode(UiMode.window, context);
                                    if (_settingsProvider.fullScreenRemovesChat) {
                                      _webViewProvider.showAllChatsFullScreen();
                                    }
                                  }
                                },
                              ),
                              if (_webViewProvider.currentUiMode == UiMode.fullScreen)
                                CircularMenuItem(
                                  icon: Icons.close,
                                  color: Colors.orange[900],
                                  onTap: () {
                                    _webViewProvider.verticalMenuClose();
                                    _webViewProvider.closeWebViewFromOutside();
                                  },
                                ),
                              CircularMenuItem(
                                icon: Icons.delete_forever_outlined,
                                color: Colors.red[800],
                                onTap: () {
                                  _webViewProvider.verticalMenuClose();
                                  return showDialog<void>(
                                    context: _,
                                    barrierDismissible: false,
                                    builder: (BuildContext context) {
                                      return const TabsWipeDialog();
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Showcase(
                    key: _showCaseNewTabButton,
                    title: 'New tab button',
                    description: '\nTap to add a new tab.'
                        '\n\nLong-press to change between icons and page titles in your tabs.',
                    targetPadding: const EdgeInsets.all(10),
                    disableMovingAnimation: true,
                    textColor: _themeProvider.mainText,
                    tooltipBackgroundColor: _themeProvider.secondBackground,
                    descTextStyle: TextStyle(fontSize: 13),
                    tooltipPadding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              height: 40,
                              child: VerticalDivider(
                                width: 1,
                                thickness: 1,
                                color: _themeProvider.mainText,
                              ),
                            ),
                            GestureDetector(
                              child: Container(
                                color: _themeProvider.navSelected,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: SizedBox(
                                    width: 24,
                                    child: Icon(
                                      Icons.add_circle_outline,
                                      color: _themeProvider.mainText,
                                    ),
                                  ),
                                ),
                              ),
                              onTap: () async {
                                _webViewProvider.addTab();
                                _webViewProvider.activateTab(_webViewProvider.tabList.length - 1);
                                if (_settingsProvider.showCases.contains("tabs_general2")) {
                                  ShowCaseWidget.of(_).startShowCase([_showcaseTabsGeneral]);
                                  //_settingsProvider.addShowCase = "tabs_general2";
                                }

                                if (_webViewProvider.tabList.length > 4 && !await Prefs().getExcessTabsAlerted()) {
                                  Prefs().setExcessTabsAlerted(true);
                                  return showDialog<void>(
                                    context: _,
                                    barrierDismissible: false,
                                    builder: (BuildContext context) {
                                      return const TabsExcessDialog();
                                    },
                                  );
                                }
                                _webViewProvider.verticalMenuClose();
                              },
                              onLongPress: () {
                                _webViewProvider.useTabIcons
                                    ? _webViewProvider.changeUseTabIcons(false)
                                    : _webViewProvider.changeUseTabIcons(true);
                                _webViewProvider.verticalMenuClose();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
