// ignore: unused_import
import 'dart:developer';
import 'dart:io';
import 'package:bot_toast/bot_toast.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:torn_pda/main.dart';
import 'package:torn_pda/providers/chain_status_provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/animated_indexedstack.dart';
import 'package:torn_pda/widgets/status_color_counter.dart';
import 'package:torn_pda/widgets/webviews/chaining_payload.dart';
import 'package:torn_pda/widgets/webviews/circular_menu/circular_menu_fixed.dart';
import 'package:torn_pda/widgets/webviews/circular_menu/circular_menu_item.dart';
import 'package:torn_pda/widgets/webviews/circular_menu/circular_menu_tabs.dart';
import 'package:torn_pda/widgets/webviews/custom_appbar.dart';
import 'package:torn_pda/widgets/webviews/fullscreen_explanation.dart';
import 'package:torn_pda/widgets/webviews/tabs_excess_dialog.dart';
import 'package:torn_pda/widgets/webviews/tabs_wipe_dialog.dart';
import 'package:torn_pda/widgets/webviews/webview_fab.dart';
import 'package:torn_pda/widgets/webviews/webview_full.dart';
import 'package:torn_pda/widgets/webviews/webview_shortcuts_dialog.dart';
import 'package:torn_pda/widgets/webviews/webview_tabslist.dart';
import 'package:torn_pda/widgets/webviews/webview_url_dialog.dart';

enum BrowserTapType {
  short,
  long,
  chainShort,
  chainLong,
  notification,
  deeplink,
  quickItem,
}

class WebViewStackView extends StatefulWidget {
  final String? initUrl;
  final bool recallLastSession;

  // Chaining
  final bool isChainingBrowser;
  final ChainingPayload? chainingPayload;

  const WebViewStackView({
    this.initUrl = "https://www.torn.com",
    this.recallLastSession = false,

    // Chaining
    this.isChainingBrowser = false,
    this.chainingPayload,
    super.key,
  });

  @override
  WebViewStackViewState createState() => WebViewStackViewState();
}

class WebViewStackViewState extends State<WebViewStackView> with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late ThemeProvider _themeProvider;
  late WebViewProvider _webViewProvider;
  late SettingsProvider _settingsProvider;

  //bool _useTabs = false;

  Future? providerInitialised;
  bool secondaryInitialised = false;

  // Showcases
  DateTime? _lastShowCasesCheck;
  final GlobalKey _showcaseTabsGeneral = GlobalKey();
  final GlobalKey _showQuickMenuButton = GlobalKey();
  final GlobalKey _showCaseNewTabButton = GlobalKey();

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
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _keyboardVisible = View.of(context).viewInsets.bottom > 0;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _webViewProvider = Provider.of<WebViewProvider>(context);
    _themeProvider = Provider.of<ThemeProvider>(context);
    _settingsProvider = Provider.of<SettingsProvider>(context);

    if (_webViewProvider.bottomBarStyleEnabled && _webViewProvider.bottomBarStyleType == 2) {
      return Container(
        color: _webViewProvider.webViewSplitActive ? _themeProvider.canvas : Colors.transparent,
        child: Dialog(
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
            color: _themeProvider.currentTheme == AppTheme.extraDark ? const Color(0xFF131313) : Colors.transparent,
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
        ),
      );
    }

    return stackView();
  }

  Widget stackView() {
    final bool dialog = _webViewProvider.bottomBarStyleEnabled && _webViewProvider.bottomBarStyleType == 2;

    bool shouldShowFab = false;
    if (_webViewProvider.fabEnabled) {
      if (!_webViewProvider.fabOnlyFullScreen) {
        shouldShowFab = true;
      } else if (_webViewProvider.fabOnlyFullScreen && _webViewProvider.currentUiMode == UiMode.fullScreen) {
        shouldShowFab = true;
      }

      if (!_webViewProvider.fabShownNow) {
        shouldShowFab = false;
      }
    }

    return MediaQuery.removePadding(
      context: context,
      removeTop:
          dialog || (_settingsProvider.fullScreenOverNotch && _webViewProvider.currentUiMode == UiMode.fullScreen),
      child: Container(
        color: _themeProvider.currentTheme == AppTheme.light
            ? MediaQuery.orientationOf(context) == Orientation.portrait
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
          left: assessSafeAreaSide(dialog, "left"),
          right: assessSafeAreaSide(dialog, "right"),
          child: ShowCaseWidget(
            builder: (_) {
              if (_webViewProvider.browserShowInForeground) {
                _launchShowCases(_);
              }
              return FutureBuilder(
                future: providerInitialised,
                builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                  return Scaffold(
                    resizeToAvoidBottomInset:
                        !(_webViewProvider.bottomBarStyleEnabled && _webViewProvider.bottomBarStyleType == 2),
                    backgroundColor: _themeProvider.statusBar,
                    appBar: snapshot.connectionState != ConnectionState.done ? buildCustomAppBar() : null,
                    body: snapshot.connectionState == ConnectionState.done
                        ? Stack(
                            children: [
                              buildMainContent(),
                              shouldShowFab ? const WebviewFab() : const SizedBox.shrink(),
                            ],
                          )
                        : Container(
                            color: Colors.blueGrey[800],
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget buildMainContent() {
    try {
      // Collect all the WebViews from the provider
      final allWebViews = <Widget>[];
      for (final tab in _webViewProvider.tabList) {
        if (tab.webView == null) {
          allWebViews.add(const SizedBox.shrink());
        } else {
          allWebViews.add(tab.webView!);
        }
      }

      // If no WebViews exist, close with an error
      if (allWebViews.isEmpty) _closeWithError();

      // Initialize secondary logic if needed
      if (!secondaryInitialised) {
        _initialiseSecondary();
        secondaryInitialised = true;
      }

      // Return the entire UI in a Stack
      return Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // --- MAIN WEBVIEW AREA ---
          if (_settingsProvider.useTabsFullBrowser)
            // If tabs are enabled, display an AnimatedIndexedStack for each tab
            AnimatedIndexedStack(
              index: _webViewProvider.currentTab,
              duration: 100,
              errorCallback: _closeWithError,
              children: allWebViews,
            )
          else
            // If tabs are disabled, just show the first one
            AnimatedIndexedStack(
              index: 0,
              duration: 100,
              errorCallback: _closeWithError,
              children: [
                allWebViews[0],
              ],
            ),

          // --- BOTTOM NAVIGATION / TABS BAR ---
          Padding(
            padding: EdgeInsets.only(
              bottom: _webViewProvider.bottomBarStyleEnabled && _webViewProvider.currentUiMode == UiMode.window
                  ? _webViewProvider.browserBottomBarStylePlaceTabsAtBottom
                      ? 0
                      : 38
                  : 0,
            ),
            child: _settingsProvider.useTabsFullBrowser
                ? (_webViewProvider.hideTabs && _webViewProvider.currentUiMode == UiMode.window
                    ? Divider(
                        color: Color(_settingsProvider.tabsHideBarColor),
                        thickness: 4,
                        height: 4,
                      )
                    : _bottomNavBar(context))
                : const SizedBox.shrink(),
          ),
        ],
      );
    } catch (e, stackTrace) {
      if (!Platform.isWindows) {
        FirebaseCrashlytics.instance.log("PDA Crash at StackView load: $e");
        FirebaseCrashlytics.instance.recordError(e, stackTrace);
      }
      logToUser("PDA Crash at StackView load: $e");
      return Scaffold(
        appBar: buildCustomAppBar(),
        body: Container(
          color: Colors.blueGrey[800],
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(50),
              child: Text(
                "There was an error loading the content: $e"
                "\n\nPlease reset your browser cache in Settings / Advanced Browser Settings and try again"
                "\n\nIf it reoccurs, you might have to force close the app and relaunch",
                style: const TextStyle(
                  color: Colors.amber,
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  bool assessSafeAreaSide(bool dialog, String safeSide) {
    if (safeSide == "left" &&
        _webViewProvider.webViewSplitActive &&
        _webViewProvider.splitScreenPosition == WebViewSplitPosition.right) {
      return false;
    } else if (safeSide == "right" &&
        _webViewProvider.webViewSplitActive &&
        _webViewProvider.splitScreenPosition == WebViewSplitPosition.left) {
      return false;
    } else {
      if (!dialog) {
        if (!(_settingsProvider.fullScreenOverSides && _webViewProvider.currentUiMode == UiMode.fullScreen)) {
          return true;
        } else {
          return false;
        }
      } else {
        return false;
      }
    }
  }

  void _launchShowCases(BuildContext _) {
    if (!_webViewProvider.browserShowInForeground) return;

    // Ensure only one execution per minute, so that showcases wait even if the first mandatory ones are shown
    final DateTime now = DateTime.now();
    if (_lastShowCasesCheck != null && now.difference(_lastShowCasesCheck!).inSeconds < 60) {
      return;
    }
    _lastShowCasesCheck = now;

    Future.delayed(const Duration(seconds: 1), () async {
      // Avoid errors when split view reverts with the browser in the background (as it's converted into a Container)
      if (_webViewProvider.tabList.isEmpty) return;

      bool showCasesNeedToWait = false;

      final List showCases = <GlobalKey<State<StatefulWidget>>>[];
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
        ShowCaseWidget.of(_).startShowCase(showCases as List<GlobalKey<State<StatefulWidget>>>);
      }
    });
  }

  void _closeWithError() {
    BotToast.showText(
      clickClose: true,
      text: "Something went wrong, please try again.",
      textStyle: const TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
      contentColor: Colors.deepOrangeAccent,
      duration: const Duration(seconds: 6),
      contentPadding: const EdgeInsets.all(10),
    );

    _webViewProvider.browserShowInForeground = false;
  }

  Future<bool> _initialiseSecondary() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return false;
    await Provider.of<WebViewProvider>(context, listen: false).initialiseSecondary(
      useTabs: _settingsProvider.useTabsFullBrowser,
      recallLastSession: widget.recallLastSession,
    );

    // Once secondary tabs are loaded for the first time, assess if any needs to be removes
    // due to the user's preferences for auto-removal (unused tabs)
    // Also start a periodic task if necessary
    _webViewProvider.assessPeriodidTabRemovalOnLaunch();

    return true;
  }

  @override
  Future dispose() async {
    _webViewProvider.verticalMenuIsOpen = false;
    _webViewProvider.clearOnDispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Widget _bottomNavBar(BuildContext _) {
    if (_webViewProvider.tabList.isEmpty) return const SizedBox.shrink();
    final bool isManuito = _webViewProvider.tabList[0].currentUrl!.contains("sid=attack&user2ID=2225097") ||
        _webViewProvider.tabList[0].currentUrl!.contains("profiles.php?XID=2225097") ||
        _webViewProvider.tabList[0].currentUrl!.contains("https://www.torn.com/forums.php#/"
            "p=threads&f=67&t=16163503&b=0&a=0");

    final mainTab = CircularMenuTabs(
      tabIndex: 0,
      webViewProvider: _webViewProvider,
      alignment: Alignment.centerLeft,
      toggleButtonColor: Colors.transparent,
      toggleButtonIconColor: Colors.transparent,
      toggleButtonOnPressed: () {
        if (_webViewProvider.currentTab == 0) {
          if (_webViewProvider.verticalMenuIsOpen) {
            _webViewProvider.verticalMenuClose();
          } else {
            _webViewProvider.verticalMenuCurrentIndex = 0;
            _webViewProvider.verticalMenuOpen();
          }
        } else {
          _webViewProvider.verticalMenuClose();
          _webViewProvider.activateTab(0);
        }
      },
      backgroundWidget: Column(
        mainAxisAlignment: MainAxisAlignment.end,
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
                                    _webViewProvider.tabList[0].pageTitle!,
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
        if (!_webViewProvider.tabList[0].isChainingBrowser)
          CircularMenuItem(
            icon: Icons.copy_all_outlined,
            onTap: () {
              _webViewProvider.duplicateTab(0);
            },
          ),
        /* ITEMS FOR CHAINING */
        if (_webViewProvider.tabList[0].isChainingBrowser)
          CircularMenuItem(
            icon: MdiIcons.playPause,
            onLongPress: () => _webViewProvider.cancelChainingBrowser(),
            onTap: () {
              _webViewProvider.passNextChainAttackFromOutside();
            },
          ),
        if (_webViewProvider.tabList[0].isChainingBrowser)
          // We simulate the same layout as for a normal CircularMenuItem
          Container(
            height: 38,
            width: 38,
            decoration: const BoxDecoration(
              color: Colors.transparent,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey,
                  blurRadius: 2,
                ),
              ],
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Material(
                color: Theme.of(context).primaryColor,
                child: InkWell(
                  child: PopupMenuButton<HealingPages>(
                    padding: const EdgeInsets.all(6),
                    icon: const Icon(
                      Icons.healing,
                      color: Colors.white,
                    ),
                    onSelected: (HealingPages choice) {
                      _webViewProvider.passHealingChoiceFromOutside(choice);
                    },
                    itemBuilder: (BuildContext context) {
                      return chainingAidPopupChoices.map((HealingPages choice) {
                        return PopupMenuItem<HealingPages>(
                          value: choice,
                          child: Text(choice.description!),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        if (_webViewProvider.tabList[0].isChainingBrowser)
          CircularMenuItem(
            icon: MdiIcons.linkVariant,
            onTap: () {
              _webViewProvider.passOpenCloseChainWidgetFromOutside();
              _webViewProvider.verticalMenuClose();
            },
          ),
        /* ITEMS FOR CHAINING */
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
      descTextStyle: const TextStyle(fontSize: 13),
      tooltipPadding: const EdgeInsets.all(20),
      child: GestureDetector(
        onTap: () => _webViewProvider.verticalMenuClose(),
        child: Container(
          color: Colors.transparent,
          height: _webViewProvider.verticalMenuIsOpen ? 390 : 40,
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
                        const Flexible(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
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
                    descTextStyle: const TextStyle(fontSize: 13),
                    tooltipPadding: const EdgeInsets.all(20),
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
                        Consumer<ChainStatusProvider>(
                          builder: (context, statusP, child) {
                            return CircularMenuFixed(
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
                                showDialog<void>(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return const WebviewShortcutsDialog(fromShortcut: true);
                                  },
                                );
                              },
                              backgroundWidget: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    color: _themeProvider.navSelected,
                                    child: Row(
                                      children: [
                                        Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.fromLTRB(
                                                8,
                                                0,
                                                8,
                                                statusP.statusColorIsShown ? 12 : 0,
                                              ),
                                              child: _webViewProvider.currentUiMode == UiMode.window
                                                  ? const Icon(MdiIcons.dotsHorizontal)
                                                  : Icon(
                                                      MdiIcons.dotsHorizontalCircleOutline,
                                                      color: Colors.orange[800],
                                                    ),
                                            ),
                                            if (statusP.statusColorIsShown && statusP.statusColorWidgetEnabled)
                                              const Padding(
                                                padding: EdgeInsets.only(top: 22.0),
                                                child: StatusColorCounter(),
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
                                if (statusP.statusColorIsShown)
                                  if (statusP.statusColorCurrent == PlayerStatusColor.hospital)
                                    CircularMenuItem(
                                      icon: MdiIcons.hospital,
                                      color: Colors.red[800],
                                      onTap: () {
                                        _webViewProvider.verticalMenuClose();
                                        _webViewProvider.loadCurrentTabUrl("https://www.torn.com/hospitalview.php");
                                      },
                                    )
                                  else if (statusP.statusColorCurrent == PlayerStatusColor.jail)
                                    CircularMenuItem(
                                      icon: MdiIcons.officeBuilding,
                                      color: Colors.brown,
                                      onTap: () {
                                        _webViewProvider.verticalMenuClose();
                                        _webViewProvider.loadCurrentTabUrl("https://www.torn.com/jailview.php");
                                      },
                                    )
                                  else if (statusP.statusColorCurrent == PlayerStatusColor.travel)
                                    CircularMenuItem(
                                      icon: MdiIcons.airplaneTakeoff,
                                      color: Colors.blue[800],
                                      onTap: () {
                                        _webViewProvider.verticalMenuClose();
                                        _webViewProvider.loadCurrentTabUrl("https://www.torn.com/");
                                      },
                                    ),
                                CircularMenuItem(
                                  icon: MdiIcons.heartOutline,
                                  onTap: () {
                                    _webViewProvider.verticalMenuClose();
                                    showDialog<void>(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return const WebviewShortcutsDialog(fromShortcut: true);
                                      },
                                    );
                                  },
                                ),
                                CircularMenuItem(
                                  icon: MdiIcons.heartPlusOutline,
                                  onTap: () {
                                    _webViewProvider.verticalMenuClose();
                                    showDialog<void>(
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
                                if (_webViewProvider.fabEnabled)
                                  CircularMenuItem(
                                    icon: MdiIcons.tab,
                                    color: _webViewProvider.fabShownNow ? Colors.amber[800] : Colors.blue,
                                    onTap: () {
                                      _webViewProvider.fabShownNow = !_webViewProvider.fabShownNow;
                                      _webViewProvider.verticalMenuClose();
                                    },
                                  ),
                                CircularMenuItem(
                                  icon: _webViewProvider.currentUiMode == UiMode.window
                                      ? MdiIcons.fullscreen
                                      : MdiIcons.fullscreenExit,
                                  color: _webViewProvider.currentUiMode == UiMode.window ? null : Colors.orange,
                                  onTap: () async {
                                    _webViewProvider.verticalMenuClose();
                                    await Future.delayed(const Duration(milliseconds: 150));
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
                                if (_webViewProvider.currentUiMode == UiMode.fullScreen &&
                                    !_settingsProvider.fullScreenExtraCloseButton)
                                  CircularMenuItem(
                                    icon: Icons.close,
                                    color: Colors.orange[900],
                                    onTap: () {
                                      _webViewProvider.verticalMenuClose();
                                      _webViewProvider.closeWebViewFromOutside();
                                    },
                                  ),
                                if (_webViewProvider.currentUiMode == UiMode.fullScreen)
                                  CircularMenuItem(
                                    icon: Icons.settings,
                                    color: Colors.blue,
                                    onTap: () {
                                      _webViewProvider.verticalMenuClose();
                                      _webViewProvider.openUrlDialog();
                                    },
                                  ),
                                if (_webViewProvider.tabList.length > 1)
                                  CircularMenuItem(
                                    icon: Icons.delete_forever_outlined,
                                    color: Colors.red[800],
                                    onTap: () {
                                      _webViewProvider.verticalMenuClose();
                                      showDialog<void>(
                                        context: _,
                                        barrierDismissible: false,
                                        builder: (BuildContext context) {
                                          return const TabsWipeDialog();
                                        },
                                      );
                                    },
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  if (_webViewProvider.currentUiMode == UiMode.fullScreen &&
                      _settingsProvider.fullScreenExtraReloadButton)
                    Column(
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
                                      Icons.refresh,
                                      color: _themeProvider.mainText,
                                    ),
                                  ),
                                ),
                              ),
                              onTap: () async {
                                _webViewProvider.reloadFromOutside();
                                _webViewProvider.verticalMenuClose();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  if (_webViewProvider.currentUiMode == UiMode.fullScreen &&
                      _settingsProvider.fullScreenExtraCloseButton)
                    Column(
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
                                      Icons.close,
                                      color: Colors.orange[900],
                                    ),
                                  ),
                                ),
                              ),
                              onTap: () async {
                                _webViewProvider.closeWebViewFromOutside();
                                _webViewProvider.verticalMenuClose();
                              },
                            ),
                          ],
                        ),
                      ],
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
                    descTextStyle: const TextStyle(fontSize: 13),
                    tooltipPadding: const EdgeInsets.all(20),
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

  CustomAppBar buildCustomAppBar() {
    return CustomAppBar(
      genericAppBar: AppBar(
        elevation: _settingsProvider.appBarTop ? 2 : 0,
        primary: !_webViewProvider.webViewSplitActive,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () async {
            _webViewProvider.browserShowInForeground = false;
          },
        ),
      ),
    );
  }
}
