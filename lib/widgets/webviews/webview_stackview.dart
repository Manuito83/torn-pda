import 'package:bot_toast/bot_toast.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';

import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/shortcuts_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/widgets/animated_indexedstack.dart';

class WebViewStackView extends StatefulWidget {
  final String initUrl;
  final bool dialog;
  final bool recallLastSession;

  const WebViewStackView({
    this.initUrl = "https://www.torn.com",
    this.dialog = false,
    this.recallLastSession = false,
    Key key,
  }) : super(key: key);

  @override
  _WebViewStackViewState createState() => _WebViewStackViewState();
}

class _WebViewStackViewState extends State<WebViewStackView> with TickerProviderStateMixin {
  GlobalKey _showcaseTabsGeneral = GlobalKey();

  ThemeProvider _themeProvider;
  WebViewProvider _webViewProvider;
  SettingsProvider _settingsProvider;

  bool _useTabs = false;

  Future providerInitialised;
  bool secondaryInitialised = false;

  AnimationController _animationController;
  Animation<double> _secondaryTabsOpacity;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _secondaryTabsOpacity = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    // Assess if we need to use tabs based on the combination
    _settingsProvider = context.read<SettingsProvider>();
    if ((widget.dialog && _settingsProvider.useTabsBrowserDialog) ||
        (!widget.dialog && _settingsProvider.useTabsFullBrowser)) {
      _useTabs = true;
    }

    // Initialise WebViewProvider
    providerInitialised = Provider.of<WebViewProvider>(context, listen: false).initialiseMain(
      initUrl: widget.initUrl,
      dialog: widget.dialog,
      recallLastSession: widget.recallLastSession,
    );
  }

  @override
  Widget build(BuildContext context) {
    _webViewProvider = Provider.of<WebViewProvider>(context, listen: true);
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);

    return Container(
      color: _themeProvider.currentTheme == AppTheme.light
          ? MediaQuery.of(context).orientation == Orientation.portrait
              ? Colors.blueGrey
              : Colors.grey[900]
          : _themeProvider.currentTheme == AppTheme.dark
              ? Colors.grey[900]
              : Colors.black,
      child: SafeArea(
        top: _settingsProvider.appBarTop ? false : true,
        bottom: true,
        child: ShowCaseWidget(
          builder: Builder(
            builder: (_) => Scaffold(
              backgroundColor: _themeProvider.basicBackground,
              body: FutureBuilder(
                future: providerInitialised,
                builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    var allWebViews = <Widget>[];
                    for (var tab in _webViewProvider.tabList) {
                      allWebViews.add(tab.webView);
                    }

                    if (allWebViews.isEmpty) _closeWithError();

                    if (!secondaryInitialised) {
                      secondaryInitialised = true;
                      _initialiseSecondary();
                    }

                    if (_useTabs) {
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
                        return IndexedStack(
                          index: 0,
                          children: [
                            allWebViews[0],
                          ],
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
              bottomNavigationBar: FutureBuilder(
                future: providerInitialised,
                builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                  if (snapshot.connectionState == ConnectionState.done && _useTabs) {
                    if (_webViewProvider.hideTabs) {
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
            ),
          ),
        ),
      ),
    );
  }

  void _closeWithError() {
    BotToast.showText(
      clickClose: true,
      crossPage: true,
      text: "Something went wrong, please try again :(",
      textStyle: TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
      contentColor: Colors.deepOrangeAccent,
      duration: Duration(seconds: 2),
      contentPadding: EdgeInsets.all(10),
    );

    Get.back();
  }

  void _initialiseSecondary() async {
    await Future.delayed(Duration(milliseconds: 1000));
    if (!mounted) return;
    Provider.of<WebViewProvider>(context, listen: false).initialiseSecondary(
      useTabs: _useTabs,
      recallLastSession: widget.recallLastSession,
    );
  }

  @override
  Future dispose() async {
    _webViewProvider.clearOnDispose();
    _animationController.dispose();
    super.dispose();
  }

  Widget _bottomNavBar(BuildContext _) {
    var mainTab = GestureDetector(
      key: UniqueKey(),
      onTap: () {
        _webViewProvider.activateTab(0);
      },
      onLongPress: () {
        _webViewProvider.addTab(
          url: _webViewProvider.tabList[0].currentUrl,
          chatRemovalActive: _webViewProvider.tabList[0].chatRemovalActiveTab,
          historyBack: _webViewProvider.tabList[0].historyBack,
          historyForward: _webViewProvider.tabList[0].historyForward,
        );

        BotToast.showText(
          crossPage: false,
          text: "Added duplicated tab!",
          textStyle: TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
          contentColor: Colors.blue,
          duration: Duration(seconds: 1),
          contentPadding: EdgeInsets.all(10),
        );
      },
      child: Container(
        color: _webViewProvider.currentTab == 0
            ? _themeProvider.navSelected
            : _themeProvider.currentTheme == AppTheme.extraDark
                ? Colors.black
                : Colors.transparent,
        child: Row(
          children: [
            Padding(
              padding: _webViewProvider.useTabIcons
                  ? const EdgeInsets.all(10.0)
                  : const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              child: _webViewProvider.useTabIcons
                  ? SizedBox(width: 24, child: _getIcon(0))
                  : Container(
                      constraints: BoxConstraints(maxWidth: 100, minWidth: 24),
                      child: Text(
                        _webViewProvider.tabList[0].pageTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: _webViewProvider.tabList[0].currentUrl.contains("sid=attack&user2ID=2225097") ||
                                  _webViewProvider.tabList[0].currentUrl.contains("profiles.php?XID=2225097") ||
                                  _webViewProvider.tabList[0].currentUrl.contains("https://www.torn.com/forums.php#/"
                                      "p=threads&f=67&t=16163503&b=0&a=0")
                              ? Colors.pink
                              : _themeProvider.mainText,
                        ),
                      ),
                    ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );

    var secondaryTabs = <Widget>[];
    for (var i = 0; i < _webViewProvider.tabList.length; i++) {
      // Don't add main again
      if (i == 0) {
        secondaryTabs.add(
          Container(
            key: UniqueKey(),
            child: SizedBox.shrink(),
          ),
        );
        continue;
      }

      _animationController.forward();
      Widget secondaryTab = FadeTransition(
        key: UniqueKey(),
        opacity: _secondaryTabsOpacity,
        child: GestureDetector(
          onTap: () {
            _webViewProvider.activateTab(i);
          },
          onDoubleTap: () {
            if (_webViewProvider.tabList.length > 0) {
              _webViewProvider.removeTab(i);
            }
          },
          child: Container(
            color: _webViewProvider.currentTab == i
                ? _themeProvider.navSelected
                : _themeProvider.currentTheme == AppTheme.extraDark
                    ? Colors.black
                    : Colors.transparent,
            child: Row(
              children: [
                Padding(
                  padding: _webViewProvider.useTabIcons
                      ? const EdgeInsets.all(10.0)
                      : const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  child: _webViewProvider.useTabIcons
                      ? SizedBox(width: 24, child: _getIcon(i))
                      : Container(
                          constraints: BoxConstraints(maxWidth: 100, minWidth: 34),
                          child: Text(
                            _webViewProvider.tabList[i].pageTitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: _webViewProvider.tabList[i].currentUrl.contains("sid=attack&user2ID=2225097") ||
                                      _webViewProvider.tabList[i].currentUrl.contains("profiles.php?XID=2225097") ||
                                      _webViewProvider.tabList[i].currentUrl
                                          .contains("https://www.torn.com/forums.php#/"
                                              "p=threads&f=67&t=16163503&b=0&a=0")
                                  ? Colors.pink
                                  : _themeProvider.mainText,
                            ),
                          ),
                        ),
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      );

      secondaryTabs.add(secondaryTab);
    }

    return Showcase(
      textColor: _themeProvider.mainText,
      showcaseBackgroundColor: _themeProvider.secondBackground,
      key: _showcaseTabsGeneral,
      title: 'Tab bar',
      description: "\nYou've opened your first tab; remember you can close tabs (except for the first one) by double "
          "taping them. You can also rearrange tabs, duplicate the first one, etc."
          "\n\nVisit the Tips section for more information!\n",
      descTextStyle: TextStyle(fontSize: 13),
      contentPadding: EdgeInsets.all(20),
      child: Container(
        height: 40,
        decoration: new BoxDecoration(
          color: _themeProvider.currentTheme == AppTheme.extraDark ? Colors.black : Colors.transparent,
          border: Border(
            top: BorderSide(
              color: Colors.grey,
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Row(
                children: [
                  mainTab,
                  VerticalDivider(
                    width: 2,
                    thickness: 2,
                    color: _themeProvider.mainText,
                  ),
                  Expanded(
                    child: ReorderableListView(
                      scrollDirection: Axis.horizontal,
                      children: secondaryTabs,
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
                          if (_webViewProvider.tabList[i].webView.key == activeKey) {
                            _webViewProvider.activateTab(i);
                            break;
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                VerticalDivider(
                  width: 2,
                  thickness: 2,
                  color: _themeProvider.mainText,
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
                    if (!_settingsProvider.showCases.contains("tabs_general")) {
                      ShowCaseWidget.of(_).startShowCase([_showcaseTabsGeneral]);
                      _settingsProvider.addShowCase = "tabs_general";
                    }
                  },
                  onLongPress: () {
                    _webViewProvider.useTabIcons
                        ? _webViewProvider.changeUseTabIcons(false)
                        : _webViewProvider.changeUseTabIcons(true);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Uses the already generated shortcuts list
  Widget _getIcon(int i) {
    var url = _webViewProvider.tabList[i].currentUrl;

    // Find some icons manually first, as they might trigger errors with shortcuts
    if (url.contains("sid=attack&user2ID=2225097")) {
      return Icon(MdiIcons.pistol, color: Colors.pink);
    } else if (url.contains("sid=attack&user2ID=")) {
      return Icon(Icons.person);
    } else if (url.contains("profiles.php?XID=2225097")) {
      return Icon(Icons.person, color: Colors.pink);
    } else if (url.contains("profiles.php")) {
      return Icon(Icons.person, color: _themeProvider.mainText);
    } else if (url.contains("companies.php") || url.contains("joblist.php")) {
      return ImageIcon(AssetImage('images/icons/home/job.png'));
    } else if (url.contains("https://www.torn.com/forums.php#/p=threads&f=67&t=16163503&b=0&a=0")) {
      return ImageIcon(AssetImage('images/icons/home/forums.png'), color: Colors.pink);
    } else if (url.contains("https://www.torn.com/forums.php")) {
      return ImageIcon(AssetImage('images/icons/home/forums.png'));
    } else if (url.contains("yata.yt")) {
      return Image.asset('images/icons/yata_logo.png');
    } else if (url.contains("jailview.php")) {
      return Image.asset('images/icons/map/jail.png', color: _themeProvider.mainText);
    } else if (url.contains("hospitalview.php")) {
      return Image.asset('images/icons/map/hospital.png', color: _themeProvider.mainText);
    } else if (url.contains("events.php")) {
      return Image.asset('images/icons/home/events.png', color: _themeProvider.mainText);
    } else if (url.contains("properties.php")) {
      return Image.asset('images/icons/map/property.png', color: _themeProvider.mainText);
    } else if (url.contains("tornstats.com/")) {
      return Image.asset('images/icons/tornstats_logo.png');
    } else if (url.contains("arsonwarehouse.com/")) {
      return Image.asset('images/icons/awh_logo2.png');
    } else if (url.contains("index.php?page=hunting")) {
      return Icon(MdiIcons.target, size: 20);
    } else if (url.contains("index.php")) {
      return ImageIcon(AssetImage('images/icons/home/home.png'));
    }

    // Try to find by using shortcuts list
    // Note: some are not found because the value that comes from OnLoadStop in the WebView differs from
    // the standard URL in shortcuts. That's why there are some more in the list above.
    var shortProvider = context.read<ShortcutsProvider>();
    for (var short in shortProvider.allShortcuts) {
      if (short.url.contains(url)) {
        return ImageIcon(AssetImage(short.iconUrl));
      }
    }

    return ImageIcon(AssetImage('images/icons/pda_icon.png'));
  }
}
