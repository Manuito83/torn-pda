// Dart imports:
import 'dart:async';
import 'dart:io';

// Flutter imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

// Package imports:
import 'package:provider/provider.dart';
import 'package:torn_pda/drawer.dart';
import 'package:torn_pda/main.dart';

// Project imports:
import 'package:torn_pda/pages/settings/friendly_factions.dart';
import 'package:torn_pda/pages/settings/userscripts_page.dart';
import 'package:torn_pda/pages/settings_page.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/providers/userscripts_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/settings/chat_highlight_word_dialog.dart';
import 'package:torn_pda/widgets/pda_browser_icon.dart';
import 'package:torn_pda/pages/settings/locked_tab_exceptions_page.dart';
import 'package:torn_pda/widgets/webviews/tabs_wipe_dialog.dart';
import 'package:torn_pda/widgets/webviews/webview_fab.dart';

class SettingsBrowserPage extends StatefulWidget {
  final UserDetailsProvider userDetailsProvider;

  const SettingsBrowserPage({required this.userDetailsProvider, super.key});

  @override
  SettingsBrowserPageState createState() => SettingsBrowserPageState();
}

class SettingsBrowserPageState extends State<SettingsBrowserPage> {
  Timer? _ticker;

  Future? _preferencesRestored;

  late bool _highlightChat;
  Color _highlightColor = const Color(0xff7ca900);

  int? _browserStyle = 0;

  final _travelMoneyWarningFormKey = GlobalKey<FormState>();

  late ThemeProvider _themeProvider;
  late SettingsProvider _settingsProvider;
  late UserScriptsProvider _userScriptsProvider;
  late WebViewProvider _webViewProvider;

  final List<TabsWipeTimeRange> tabsRemoveTimeRangesList = [
    TabsWipeTimeRange.oneDay,
    TabsWipeTimeRange.twoDays,
    TabsWipeTimeRange.threeDays,
    TabsWipeTimeRange.fiveDays,
    TabsWipeTimeRange.sevenDays,
    TabsWipeTimeRange.fifteenDays,
    TabsWipeTimeRange.oneMonth,
  ];

  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _userScriptsProvider = Provider.of<UserScriptsProvider>(context, listen: false);

    _preferencesRestored = _restorePreferences();

    routeWithDrawer = false;
    routeName = "settings_browser";
    _settingsProvider.willPopShouldGoBackStream.stream.listen((event) {
      if (mounted && routeName == "settings_browser") _goBack();
    });
  }

  List<Widget> buildFilteredSections() {
    List<Widget> sections = [
      _general(),
      _userScripts(),
      _tabs(),
      _fab(),
      _downloads(),
      _fullScreen(),
      _textScale(),
      _chat(),
      _travel(),
      _energyExpenditureWarning(),
      _travelExpenditureWarning(),
      _profile(),
      if (Platform.isIOS) _linkPreview(),
      _gestures(),
      _maintenance(),
    ];

    // Filter out empty sections
    sections = sections.where((widget) => widget is! SizedBox).toList();

    if (sections.isEmpty) return sections;

    // If only one section is visible, return it without any divider
    if (sections.length == 1) return sections;

    List<Widget> finalSections = [];
    for (int i = 0; i < sections.length; i++) {
      if (i > 0) {
        finalSections.add(
          Column(
            children: [
              SizedBox(height: 20),
              Divider(),
              SizedBox(height: 10),
            ],
          ),
        );
      }

      finalSections.add(sections[i]);
    }
    return finalSections;
  }

  @override
  Widget build(BuildContext context) {
    _webViewProvider = Provider.of<WebViewProvider>(context, listen: true);
    _themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
      color: _themeProvider.currentTheme == AppTheme.light
          ? MediaQuery.orientationOf(context) == Orientation.portrait
              ? Colors.blueGrey
              : _themeProvider.canvas
          : _themeProvider.canvas,
      child: SafeArea(
        right: _webViewProvider.webViewSplitActive && _webViewProvider.splitScreenPosition == WebViewSplitPosition.left,
        left: _webViewProvider.webViewSplitActive && _webViewProvider.splitScreenPosition == WebViewSplitPosition.right,
        child: Scaffold(
          backgroundColor: _themeProvider.canvas,
          appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
          bottomNavigationBar: !_settingsProvider.appBarTop
              ? SizedBox(
                  height: AppBar().preferredSize.height,
                  child: buildAppBar(),
                )
              : null,
          body: Container(
            color: _themeProvider.canvas,
            child: FutureBuilder(
              future: _preferencesRestored,
              builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // SEARCH BOX
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextField(
                              decoration: const InputDecoration(
                                hintText: 'Search browser settings...',
                                prefixIcon: Icon(Icons.search),
                              ),
                              onChanged: (text) {
                                setState(() {
                                  _searchText = text;
                                });
                              },
                            ),
                          ),
                          SizedBox(height: 15),
                          ...buildFilteredSections(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  );
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _general() {
    List<SearchableRow> rows = [
      SearchableRow(
        label: "Browser style",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: const Text("Browser style")),
                  _browserStyleDropdown(),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  "There are three browser styles available, all sharing the same functionality. Please have a look at the Tips section for more information, or try them for yourself!",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      if (_webViewProvider.bottomBarStyleEnabled)
        SearchableRow(
          label: "Tabs below navigation bar",
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: const Text("Tabs below navigation bar")),
                    Switch(
                      value: _webViewProvider.browserBottomBarStylePlaceTabsAtBottom,
                      onChanged: (value) {
                        setState(() {
                          _webViewProvider.browserBottomBarStylePlaceTabsAtBottom = value;
                        });
                      },
                      activeTrackColor: Colors.lightGreenAccent,
                      activeColor: Colors.green,
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'If enabled, browser tabs will be placed at the very bottom of the browser window (below the "close" button and navigation controls)',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      SearchableRow(
        label: "Show load bar",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: const Text("Show load bar")),
              Switch(
                value: _settingsProvider.loadBarBrowser,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.changeLoadBarBrowser = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "Refresh method",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: const Text("Refresh method")),
                  _refreshMethodDropdown(),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'The browser has pull to refresh functionality. However, you can get an extra refresh icon if it\'s useful for certain situations (e.g. jail or hospital)',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
      if (_browserStyle == 0)
        SearchableRow(
          label: "Show navigation arrows",
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: const Text("Show navigation arrows")),
                    _navArrowsDropdown(),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'When using the default browser style, forward and backward navigation arrows will be shown by default when using a wide enough screen. You can disable them or make them also visible on narrower screens (bear in mind that this might interfere with the space available for page title)',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    ];

    return buildSectionWithRows(
      title: 'GENERAL',
      rows: rows,
      searchText: _searchText,
    );
  }

  Widget _userScripts() {
    List<SearchableRow> rows = [
      SearchableRow(
        label: "Enable custom user scripts",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: const Text("Enable custom user scripts")),
                  Switch(
                    value: _userScriptsProvider.userScriptsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _userScriptsProvider.setUserScriptsEnabled = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
              Text(
                'You can load custom user scripts in the browser (this feature does not currently work when using the browser for chaining)',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
      if (_userScriptsProvider.userScriptsEnabled)
        SearchableRow(
          label: "Notify for Script Updates",
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: const Text("Notify for Script Updates")),
                Switch(
                  value: _userScriptsProvider.userScriptsNotifyUpdates,
                  onChanged: (value) {
                    setState(() {
                      _userScriptsProvider.setUserScriptsNotifyUpdates = value;
                    });
                  },
                  activeTrackColor: Colors.lightGreenAccent,
                  activeColor: Colors.green,
                ),
              ],
            ),
          ),
        ),
      if (_userScriptsProvider.userScriptsEnabled)
        SearchableRow(
          label: "Manage scripts",
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: const Text("Manage scripts")),
                IconButton(
                  icon: Icon(MdiIcons.script),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (BuildContext context) => UserScriptsPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
    ];

    return buildSectionWithRows(
      title: 'USER SCRIPTS',
      rows: rows,
      searchText: _searchText,
    );
  }

  Widget _tabs() {
    List<SearchableRow> rows = [
      SearchableRow(
        label: "Tabs description",
        searchText: _searchText,
        filterable: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
          child: Text(
            'Tabs might increase memory and processor usage; be sure that you get familiar with how tabs work (see the Tips section). It is highly recommended to use tabs to improve your Torn PDA experience.',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
      SearchableRow(
        label: "Use tabs in browser",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: const Text("Use tabs in browser")),
              Switch(
                value: _settingsProvider.useTabsFullBrowser,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.changeUseTabsFullBrowser = value;
                  });
                  if (!value) {
                    Prefs().setHideTabs(false);
                  }
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
      ),
      if (_settingsProvider.useTabsFullBrowser)
        SearchableRow(
          label: "Automatically change to new tab from link",
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: const Text("Automatically change to new tab from link")),
                    Switch(
                      value: _webViewProvider.automaticChangeToNewTabFromURL,
                      onChanged: (value) {
                        _webViewProvider.automaticChangeToNewTabFromURL = value;
                      },
                      activeTrackColor: Colors.lightGreenAccent,
                      activeColor: Colors.green,
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    "By default, when you open a new tab via the 'open in new tab' option, when long-pressing a link, the browser will change to the newly created tab. If you disable this, the new tab will be created but you will remain in the current page",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      if (_settingsProvider.useTabsFullBrowser)
        SearchableRow(
          label: "Remove unused tabs",
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: const Text("Remove unused tabs")),
                    Switch(
                      value: _webViewProvider.removeUnusedTabs,
                      onChanged: (enabled) {
                        _webViewProvider.removeUnusedTabs = enabled;
                        _webViewProvider.togglePeriodicUnusedTabsRemovalRequest(enable: enabled);
                      },
                      activeTrackColor: Colors.lightGreenAccent,
                      activeColor: Colors.green,
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'Removes unused tabs periodically (checks are performed when the app starts and then once every 24 hours)',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                if (_webViewProvider.removeUnusedTabs)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 30, right: 20, top: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Row(
                                children: [
                                  Icon(Icons.keyboard_arrow_right_outlined),
                                  Flexible(child: const Text("Include locked tabs")),
                                ],
                              ),
                            ),
                            Switch(
                              value: _webViewProvider.removeUnusedTabsIncludesLocked,
                              onChanged: (value) {
                                _webViewProvider.removeUnusedTabsIncludesLocked = value;
                                _webViewProvider.togglePeriodicUnusedTabsRemovalRequest(enable: true);
                              },
                              activeTrackColor: Colors.lightGreenAccent,
                              activeColor: Colors.green,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 30, right: 20, top: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Row(
                                children: [
                                  Icon(Icons.keyboard_arrow_right_outlined),
                                  Flexible(child: const Text("Inactive for")),
                                ],
                              ),
                            ),
                            DropdownButton<TabsWipeTimeRange>(
                              value: _webViewProvider.removeUnusedTabsRangeDays,
                              items: tabsRemoveTimeRangesList.map((TabsWipeTimeRange range) {
                                return DropdownMenuItem<TabsWipeTimeRange>(
                                  value: range,
                                  child: Text(range.displayName),
                                );
                              }).toList(),
                              onChanged: (TabsWipeTimeRange? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _webViewProvider.removeUnusedTabsRangeDays = newValue;
                                  });
                                  _webViewProvider.togglePeriodicUnusedTabsRemovalRequest(enable: true);
                                }
                              },
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
      if (_settingsProvider.useTabsFullBrowser)
        SearchableRow(
          label: "Only load tabs when used",
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: const Text("Only load tabs when used")),
                    Switch(
                      value: _webViewProvider.onlyLoadTabsWhenUsed,
                      onChanged: (value) {
                        _webViewProvider.onlyLoadTabsWhenUsed = value;
                      },
                      activeTrackColor: Colors.lightGreenAccent,
                      activeColor: Colors.green,
                    ),
                  ],
                ),
                Text(
                  'If active (recommended) not all tabs will load in memory upon browser initialization. Instead, they will retrieve the web content when first used (tapped). This could add a small delay when the tab is pressed the first time, but should improve overall browser performance. Also, tabs that have not been used for 24 hours will be deactivated to reduce memory consumption, and will be reactivated when you switch back to them.',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      if (_settingsProvider.useTabsFullBrowser)
        SearchableRow(
          label: "Allow hiding tabs",
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: const Text("Allow hiding tabs")),
                    Switch(
                      value: _settingsProvider.useTabsHideFeature,
                      onChanged: (value) {
                        setState(() {
                          _settingsProvider.changeUseTabsHideFeature = value;
                        });
                        if (!value) {
                          Prefs().setHideTabs(false);
                        }
                      },
                      activeTrackColor: Colors.lightGreenAccent,
                      activeColor: Colors.green,
                    ),
                  ],
                ),
                Text(
                  'Allow to temporarily hide tabs by swiping up/down in the title bar',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      if (_settingsProvider.useTabsFullBrowser && _settingsProvider.useTabsHideFeature)
        SearchableRow(
          label: "Select hide bar color",
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 35, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: const Text("Select hide bar color"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(_settingsProvider.tabsHideBarColor).withAlpha(255),
                    foregroundColor: Colors.white,
                  ),
                  child: Icon(Icons.palette),
                  onPressed: () => _showColorPickerTabs(context),
                ),
              ],
            ),
          ),
        ),
      if (_settingsProvider.useTabsFullBrowser)
        SearchableRow(
          label: "Tab locks",
          searchText: _searchText,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('TAB LOCKS', style: TextStyle(fontSize: 10)),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: const Text("Show tab lock warnings")),
                    Switch(
                      value: _settingsProvider.showTabLockWarnings,
                      onChanged: (value) {
                        setState(() {
                          _settingsProvider.showTabLockWarnings = value;
                        });
                      },
                      activeTrackColor: Colors.lightGreenAccent,
                      activeColor: Colors.green,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 5),
                child: Text(
                  'If enabled, a short message with a lock icon will appear whenever the lock status of a tab is changed or when the app is impeding navigation or tab movement due to its lock condition. NOTE: without warning, you will NOT be able to override navigation with full locks!',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: const Text("Full lock navigation opens a new tab")),
                    Switch(
                      value: _settingsProvider.fullLockNavigationAttemptOpensNewTab,
                      onChanged: (value) {
                        setState(() {
                          _settingsProvider.fullLockNavigationAttemptOpensNewTab = value;
                        });
                      },
                      activeTrackColor: Colors.lightGreenAccent,
                      activeColor: Colors.green,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 5),
                child: Text(
                  'If enabled, a navigation attempt from a tab with a full lock will open a new tab in the background (the tab will be added but the browser will not switch to it automatically)',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      if (_settingsProvider.useTabsFullBrowser)
        SearchableRow(
          label: "Navigation exceptions for locked tabs",
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: const Text("Navigation exceptions for locked tabs")),
                ElevatedButton(
                  child: Icon(MdiIcons.lockRemoveOutline),
                  onPressed: () async {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (BuildContext context) => LockedTabsNavigationExceptionsPage(
                          settingsProvider: _settingsProvider,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
    ];

    return buildSectionWithRows(
      title: 'TABS',
      rows: rows,
      searchText: _searchText,
    );
  }

  Widget _fab() {
    List<SearchableRow> rows = [
      SearchableRow(
        label: "Enabled",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: const Text("Enabled")),
                  Switch(
                    value: _webViewProvider.fabEnabled,
                    onChanged: (value) {
                      _webViewProvider.fabEnabled = value;
                      if (value) {
                        _webViewProvider.fabSavedPositionXY = [100, 100];
                      }
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
              Text(
                "Shows a Floating Action Button while using the browser, which adds several action buttons and gestures to enhance navigation. NOTE: it is highly recommended that you read about how to use this button in the Tips section!",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
      if (_webViewProvider.fabEnabled)
        SearchableRow(
          label: "Expand direction",
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: const Text("Expand direction")),
                    _fabDirectionDropdown(),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 5),
                  child: Text(
                    "Dictates where to expand the option buttons when the FAB is tapped",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      if (_webViewProvider.fabEnabled)
        SearchableRow(
          label: "Only in fullscreen",
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: const Text("Only in fullscreen")),
                    Switch(
                      value: _webViewProvider.fabOnlyFullScreen,
                      onChanged: (value) {
                        _webViewProvider.fabOnlyFullScreen = value;
                      },
                      activeTrackColor: Colors.lightGreenAccent,
                      activeColor: Colors.green,
                    ),
                  ],
                ),
                Text(
                  "Only show the FAB when in full screen mode",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      if (_webViewProvider.fabEnabled)
        SearchableRow(
          label: "Number of buttons",
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: const Text("Number of buttons")),
                    Row(
                      children: [
                        Text(_webViewProvider.fabButtonCount.toString()),
                        Slider(
                          value: _webViewProvider.fabButtonCount.toDouble(),
                          min: FabSettings.minButtons.toDouble(),
                          max: FabSettings.maxButtons.toDouble(),
                          divisions: FabSettings.maxButtons - FabSettings.minButtons,
                          label: _webViewProvider.fabButtonCount.toString(),
                          onChanged: (value) {
                            setState(() {
                              _webViewProvider.fabButtonCount = value.toInt();
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  "Adjust the number of action buttons displayed when the FAB is expanded.",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      if (_webViewProvider.fabEnabled)
        ...List.generate(_webViewProvider.fabButtonCount, (index) {
          return SearchableRow(
            label: "FAB Button ${index + 1} action",
            searchText: _searchText,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text('FAB Button ${index + 1} action')),
                  DropdownButton<WebviewFabAction>(
                    value: _webViewProvider.fabButtonActions[index],
                    items: FabSettings.actions.map((action) {
                      return DropdownMenuItem(
                        value: action,
                        child: SizedBox(
                          width: 80,
                          child: Text(
                            action.fabActionName,
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (newAction) {
                      if (newAction != null) {
                        setState(() {
                          _webViewProvider.updateFabButtonAction(index, newAction);
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        }),
      if (_webViewProvider.fabEnabled)
        SearchableRow(
          label: "FAB Double tap action",
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: const Text("FAB Double tap action")),
                DropdownButton<WebviewFabAction>(
                  value: _webViewProvider.fabDoubleTapAction,
                  items: FabSettings.actions.map((action) {
                    return DropdownMenuItem(
                      value: action,
                      child: SizedBox(
                        width: 80,
                        child: Text(
                          action.fabActionName,
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (action) {
                    if (action != null) {
                      _webViewProvider.updateFabDoubleTapAction(action);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      if (_webViewProvider.fabEnabled)
        SearchableRow(
          label: "FAB Triple tap action",
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: const Text("FAB Triple tap action")),
                DropdownButton<WebviewFabAction>(
                  value: _webViewProvider.fabTripleTapAction,
                  items: FabSettings.actions.map((action) {
                    return DropdownMenuItem(
                      value: action,
                      child: SizedBox(
                        width: 80,
                        child: Text(
                          action.fabActionName,
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (action) {
                    if (action != null) {
                      _webViewProvider.updateFabTripleTapAction(action);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
    ];

    return buildSectionWithRows(
      title: 'FLOATING ACTION BUTON',
      rows: rows,
      searchText: _searchText,
    );
  }

  Widget _downloads() {
    List<SearchableRow> rows = [
      SearchableRow(
        label: "Download action",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: const Text("Download action")),
                  _downloadsDropdown(),
                ],
              ),
              Text(
                "Due to the operating system restrictions, Torn PDA can only download files to your app data folder (this is to avoid requesting unnecesary permissions). As this folder can be difficult to access in certain devices, the app can instead initiate a share request so that you can select whether to save your file locally or share it somewhere else",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    ];

    return buildSectionWithRows(
      title: 'DOWNLOADS',
      rows: rows,
      searchText: _searchText,
    );
  }

  Widget _fullScreen() {
    List<SearchableRow> rows = [
      SearchableRow(
        label: "Full screen note",
        searchText: _searchText,
        filterable: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
          child: Text(
            'NOTE: full screen mode is only accessible if using tabs and through the quick menu tab!',
            style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ),
      ),
      SearchableRow(
        label: "Full screen removes widgets",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: const Text("Full screen removes widgets")),
                  Switch(
                    value: _settingsProvider.fullScreenRemovesWidgets,
                    onChanged: (value) {
                      setState(() {
                        _settingsProvider.fullScreenRemovesWidgets = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
              Text(
                'Dictates whether full screen mode should also remove all Torn PDA widgets',
                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "Full screen removes chat",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: const Text("Full screen removes chat")),
                  Switch(
                    value: _settingsProvider.fullScreenRemovesChat,
                    onChanged: (value) {
                      setState(() {
                        _settingsProvider.fullScreenRemovesChat = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
              Text(
                'Dictates whether full screen mode should also remove all Torn chat bubbles',
                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "Add reload button to tab bar",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: const Text("Add reload button to tab bar")),
                  Switch(
                    value: _settingsProvider.fullScreenExtraReloadButton,
                    onChanged: (value) {
                      setState(() {
                        _settingsProvider.fullScreenExtraReloadButton = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
              Text(
                "When in full screen mode, adds an additional tab with a reload button for quicker access",
                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "Add close button to tab bar",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: const Text("Add close button to tab bar")),
                  Switch(
                    value: _settingsProvider.fullScreenExtraCloseButton,
                    onChanged: (value) {
                      setState(() {
                        _settingsProvider.fullScreenExtraCloseButton = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
              Text(
                "When in full screen mode, replaces the 'X' close button with an additional tab for quicker access",
                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "FULL SCREEN POSITIONING",
        searchText: _searchText,
        filterable: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [const Text("FULL SCREEN POSITIONING", style: TextStyle(fontSize: 10))],
          ),
        ),
      ),
      SearchableRow(
        label: "Full screen extends to top",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: const Text("Full screen extends to top")),
                  Switch(
                    value: _settingsProvider.fullScreenOverNotch,
                    onChanged: (value) {
                      setState(() {
                        _settingsProvider.fullScreenOverNotch = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
              Text(
                'Determines if full screen mode should extend to the top (including sensor area)',
                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "Full screen extends to bottom",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: const Text("Full screen extends to bottom")),
                  Switch(
                    value: _settingsProvider.fullScreenOverBottom,
                    onChanged: (value) {
                      setState(() {
                        _settingsProvider.fullScreenOverBottom = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
              Text(
                'Determines if full screen mode should extend to the bottom (might affect accessibility of corner tabs)',
                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "Full screen extends to sides",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: const Text("Full screen extends to sides")),
                  Switch(
                    value: _settingsProvider.fullScreenOverSides,
                    onChanged: (value) {
                      setState(() {
                        _settingsProvider.fullScreenOverSides = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
              Text(
                'Determines if full screen mode should extend to the sides, useful for landscape mode',
                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "FULL SCREEN INTERACTION",
        searchText: _searchText,
        filterable: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [const Text("FULL SCREEN INTERACTION", style: TextStyle(fontSize: 10))],
          ),
        ),
      ),
      SearchableRow(
        label: "Short tap opens full screen",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: const Text("Short tap opens full screen")),
                  Switch(
                    value: _settingsProvider.fullScreenByShortTap,
                    onChanged: (value) {
                      setState(() {
                        _settingsProvider.fullScreenByShortTap = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
              Text(
                "Opens full screen mode when an item is short-tapped. Defaults to OFF.",
                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "Long tap opens full screen",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: const Text("Long tap opens full screen")),
                  Switch(
                    value: _settingsProvider.fullScreenByLongTap,
                    onChanged: (value) {
                      setState(() {
                        _settingsProvider.fullScreenByLongTap = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
              Text(
                "Opens full screen mode when an item is long-tapped. Defaults to ON.",
                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "Short/long tap affect PDA icon",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: const Text("Short/long tap affect PDA icon")),
                  Switch(
                    value: _settingsProvider.fullScreenIncludesPDAButtonTap,
                    onChanged: (value) {
                      setState(() {
                        _settingsProvider.fullScreenIncludesPDAButtonTap = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
              Text(
                "When activated, the PDA icon will toggle the browser mode instead of restoring its previous state. Defaults to OFF.",
                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "Notifications open full screen",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: const Text("Notifications open full screen")),
                  Switch(
                    value: _settingsProvider.fullScreenByNotificationTap,
                    onChanged: (value) {
                      setState(() {
                        _settingsProvider.fullScreenByNotificationTap = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
              Text(
                "Opens full screen mode when a notification is tapped. Defaults to OFF.",
                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "Deep links open full screen",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: const Text("Deep links open full screen")),
                  Switch(
                    value: _settingsProvider.fullScreenByDeepLinkTap,
                    onChanged: (value) {
                      setState(() {
                        _settingsProvider.fullScreenByDeepLinkTap = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
              Text(
                "Opens full screen mode when triggered by a deep link. Defaults to OFF.",
                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "Quick items open full screen",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: const Text("Quick items open full screen")),
                  Switch(
                    value: _settingsProvider.fullScreenByQuickItemTap,
                    onChanged: (value) {
                      setState(() {
                        _settingsProvider.fullScreenByQuickItemTap = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
              Text(
                "Opens full screen mode when a quick item is tapped. Defaults to OFF.",
                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "Short tap opens full screen (Chaining)",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("[CHAINING BROWSER]", style: TextStyle(fontSize: 11)),
                        const Text("Short tap opens full screen"),
                      ],
                    ),
                  ),
                  Switch(
                    value: _settingsProvider.fullScreenByShortChainingTap,
                    onChanged: (value) {
                      setState(() {
                        _settingsProvider.fullScreenByShortChainingTap = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
              Text(
                "Opens full screen mode when a target is short-tapped in the Chaining section. Defaults to OFF. You can still access the chaining controls by double tapping the main tab.",
                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "Long tap opens full screen (Chaining)",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("[CHAINING BROWSER]", style: TextStyle(fontSize: 11)),
                        const Text("Long tap opens full screen"),
                      ],
                    ),
                  ),
                  Switch(
                    value: _settingsProvider.fullScreenByLongChainingTap,
                    onChanged: (value) {
                      setState(() {
                        _settingsProvider.fullScreenByLongChainingTap = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
              Text(
                "Opens full screen mode when a target is long-pressed in the Chaining section. Defaults to OFF. You can still access the chaining controls by double tapping the main tab.",
                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    ];

    return buildSectionWithRows(
      title: 'FULL SCREEN BEHAVIOR',
      rows: rows,
      searchText: _searchText,
    );
  }

  Widget _textScale() {
    List<SearchableRow> rows = [
      SearchableRow(
        label: "Browser text scale",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(child: Text("Browser text scale")),
                  Row(
                    children: [
                      Text(
                        _settingsProvider.androidBrowserTextScale.toString(),
                        style: const TextStyle(fontSize: 12),
                      ),
                      Slider(
                        min: 8,
                        max: 20,
                        divisions: 12,
                        value: _settingsProvider.androidBrowserTextScale.toDouble(),
                        onChanged: (double value) {
                          setState(() {
                            _settingsProvider.changeAndroidBrowserTextScale = value.floor();
                          });
                          _webViewProvider.changeTextScale(value.floor());
                        },
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                "You can adjust the text scale in the browser to make it easier to read. Be advised that Torn might not follow this setting properly for all fonts in game, so some text might be unreadable.",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    ];

    return buildSectionWithRows(
      title: 'TEXT SCALE',
      rows: rows,
      searchText: _searchText,
    );
  }

  Widget _chat() {
    List<SearchableRow> rows = [
      SearchableRow(
        label: "Show chat remove icon",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(child: Text("Show chat remove icon")),
              Switch(
                value: _settingsProvider.chatRemoveEnabled,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.changeChatRemoveEnabled = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "Highlight messages in chat",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(child: Text("Highlight messages in chat")),
              Switch(
                value: _settingsProvider.highlightChat,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.changeHighlightChat = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
      ),
      if (_highlightChat)
        SearchableRow(
          label: "Select words to highlight",
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(child: Text("Select words to highlight")),
                ElevatedButton(
                  child: const Icon(Icons.drive_file_rename_outline_sharp),
                  onPressed: () => _showHighlightSelectorChat(context),
                ),
              ],
            ),
          ),
        ),
      if (_highlightChat)
        SearchableRow(
          label: "Select highlight color",
          searchText: _searchText,
          filterable: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(child: Text("Select highlight color")),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _highlightColor.withAlpha(255),
                    foregroundColor: Colors.white,
                  ),
                  child: const Icon(Icons.palette),
                  onPressed: () => _showColorPickerChat(context),
                ),
              ],
            ),
          ),
        ),
    ];

    return buildSectionWithRows(
      title: 'CHAT',
      rows: rows,
      searchText: _searchText,
    );
  }

  Widget _travel() {
    List<SearchableRow> rows = [
      SearchableRow(
        label: "Remove airplane",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: const Text("Remove airplane")),
                  Switch(
                    value: _settingsProvider.removeAirplane,
                    onChanged: (value) {
                      setState(() {
                        _settingsProvider.changeRemoveAirplane = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
              Text(
                'Removes airplane and cloud animation when traveling',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "Remove quick return button",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(child: Text("Remove quick return button")),
                  Switch(
                    value: _settingsProvider.removeTravelQuickReturnButton,
                    onChanged: (value) {
                      setState(() {
                        _settingsProvider.removeTravelQuickReturnButton = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
              Text(
                "By default, when abroad, you'll see a home icon button that you can double-tap to initiate your travel back to Torn. You can optionally disable it by using this option",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    ];
    return buildSectionWithRows(
      title: 'TRAVEL',
      rows: rows,
      searchText: _searchText,
    );
  }

  Widget _energyExpenditureWarning() {
    List<SearchableRow> rows = [
      SearchableRow(
        label: "Warn about chains",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: const Text("Warn about chains")),
                  Switch(
                    value: _settingsProvider.warnAboutChains,
                    onChanged: (value) {
                      setState(() {
                        _settingsProvider.changeWarnAboutChains = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
              Text(
                "If active, you'll get a message and a chain icon beside the energy bar to warn you of chaining.",
                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "Warn about stacking",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: const Text("Warn about stacking")),
                  Switch(
                    value: _settingsProvider.warnAboutExcessEnergy,
                    onChanged: (value) {
                      setState(() {
                        _settingsProvider.changeWarnAboutExcessEnergy = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
              Text(
                "If active, you'll be alerted when energy reaches or exceeds your selected threshold.",
                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
      if (_settingsProvider.warnAboutExcessEnergy)
        SearchableRow(
          label: "Threshold",
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Threshold", style: TextStyle(fontSize: 12)),
                Row(
                  children: [
                    Text(_settingsProvider.warnAboutExcessEnergyThreshold.toString(),
                        style: const TextStyle(fontSize: 12)),
                    Slider(
                      min: 200,
                      max: 1000,
                      divisions: 16,
                      value: _settingsProvider.warnAboutExcessEnergyThreshold.toDouble(),
                      onChanged: (double value) {
                        setState(() {
                          _settingsProvider.changeWarnAboutExcessEnergyThreshold = value.floor();
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
    ];
    return buildSectionWithRows(
      title: 'GYM ENERGY EXPENDITURE WARNING',
      rows: rows,
      searchText: _searchText,
    );
  }

  Widget _travelExpenditureWarning() {
    final currentEnergyMax = widget.userDetailsProvider.basic?.energy?.maximum ?? -1;
    final currentNerveMax = widget.userDetailsProvider.basic?.nerve?.maximum ?? -1;
    final currentLifeMax = widget.userDetailsProvider.basic?.life?.maximum ?? -1;
    List<SearchableRow> rows = [
      SearchableRow(
        label: "Energy excess warning",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Energy excess warning"),
                  Switch(
                    value: _settingsProvider.travelEnergyExcessWarning,
                    onChanged: (value) {
                      setState(() {
                        _settingsProvider.travelEnergyExcessWarning = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
              Text(
                "Warns when your Energy Bar is between a set range to avoid waste before boarding.",
                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
      if (_settingsProvider.travelEnergyExcessWarning)
        SearchableRow(
          label: "Range",
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.only(left: 25),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Range", style: TextStyle(fontSize: 12)),
                Row(
                  children: [
                    Text(
                      _settingsProvider.travelEnergyRangeWarningThreshold.end >= 110
                          ? "> ${_settingsProvider.travelEnergyRangeWarningThreshold.start.round()}%"
                          : "${_settingsProvider.travelEnergyRangeWarningThreshold.start.round()}% to ${_settingsProvider.travelEnergyRangeWarningThreshold.end.round()}%",
                      style: const TextStyle(fontSize: 12),
                    ),
                    RangeSlider(
                      min: 0,
                      max: 110,
                      divisions: 11,
                      values: _settingsProvider.travelEnergyRangeWarningThreshold,
                      labels: RangeLabels(
                        _buildRangeLabel(
                          _settingsProvider.travelEnergyRangeWarningThreshold.start,
                          currentEnergyMax,
                          "E",
                        ),
                        _buildRangeLabel(
                          _settingsProvider.travelEnergyRangeWarningThreshold.end,
                          currentEnergyMax,
                          "E",
                        ),
                      ),
                      onChanged: (RangeValues values) {
                        setState(() {
                          double startValue = values.start.roundToDouble();
                          double endValue = values.end.roundToDouble();
                          if (endValue - startValue >= 10) {
                            _settingsProvider.travelEnergyRangeWarningThreshold = RangeValues(startValue, endValue);
                          }
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      SearchableRow(
        label: "Nerve excess warning",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Nerve excess warning"),
              Switch(
                value: _settingsProvider.travelNerveExcessWarning,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.travelNerveExcessWarning = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "Nerve excess warning description",
        searchText: _searchText,
        filterable: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Text(
            "Warns when your Nerve Bar exceeds a certain threshold to avoid waste.",
            style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ),
      ),
      if (_settingsProvider.travelNerveExcessWarning)
        SearchableRow(
          label: "Threshold",
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.only(left: 25),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Threshold", style: TextStyle(fontSize: 12)),
                Row(
                  children: [
                    Text(
                      _settingsProvider.travelNerveExcessWarningThreshold >= 110
                          ? "> max"
                          : "${(_settingsProvider.travelNerveExcessWarningThreshold ~/ 10 * 10)}%",
                      style: const TextStyle(fontSize: 12),
                    ),
                    Slider(
                      min: 0,
                      max: 110,
                      divisions: 11,
                      value: _settingsProvider.travelNerveExcessWarningThreshold.toDouble(),
                      label: _buildSingleLabel(
                        _settingsProvider.travelNerveExcessWarningThreshold.toDouble(),
                        currentNerveMax,
                        "N",
                      ),
                      onChanged: (double value) {
                        setState(() {
                          _settingsProvider.travelNerveExcessWarningThreshold = (value.round() ~/ 10 * 10);
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      SearchableRow(
        label: "Life excess warning",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Life excess warning"),
              Switch(
                value: _settingsProvider.travelLifeExcessWarning,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.travelLifeExcessWarning = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "Life excess warning description",
        searchText: _searchText,
        filterable: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Text(
            "Warns when your Life Bar exceeds a certain threshold to avoid waste.",
            style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ),
      ),
      if (_settingsProvider.travelLifeExcessWarning)
        SearchableRow(
          label: "Threshold",
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.only(left: 25),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Threshold", style: TextStyle(fontSize: 12)),
                Row(
                  children: [
                    Text(
                      _settingsProvider.travelLifeExcessWarningThreshold >= 110
                          ? "> max"
                          : "${(_settingsProvider.travelLifeExcessWarningThreshold ~/ 10 * 10)}%",
                      style: const TextStyle(fontSize: 12),
                    ),
                    Slider(
                      min: 0,
                      max: 110,
                      divisions: 11,
                      value: _settingsProvider.travelLifeExcessWarningThreshold.toDouble(),
                      label: _buildSingleLabel(
                        _settingsProvider.travelLifeExcessWarningThreshold.toDouble(),
                        currentLifeMax,
                        "L",
                      ),
                      onChanged: (double value) {
                        setState(() {
                          _settingsProvider.travelLifeExcessWarningThreshold = (value.round() ~/ 10 * 10);
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      SearchableRow(
        label: "Low wallet money",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Low wallet money"),
              Switch(
                value: _settingsProvider.travelWalletMoneyWarning,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.travelWalletMoneyWarning = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
      ),
      if (_settingsProvider.travelWalletMoneyWarning)
        SearchableRow(
          label: "Minimum cash",
          searchText: _searchText,
          filterable: false,
          child: Padding(
            padding: const EdgeInsets.only(left: 50, right: 10, bottom: 15),
            child: Form(
              key: _travelMoneyWarningFormKey,
              child: TextFormField(
                maxLength: 10,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Minimum cash",
                  isDense: true,
                  counterText: '',
                ),
                initialValue: _settingsProvider.travelWalletMoneyWarningThreshold.toString(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "This field cannot be empty";
                  }
                  final parsedValue = int.tryParse(value);
                  if (parsedValue == null || parsedValue < 0) {
                    return "Invalid number";
                  }
                  if (parsedValue > 1000000000) {
                    return "Max 1 billion!";
                  }
                  return null;
                },
                onSaved: (value) {
                  if (value != null && value.isNotEmpty) {
                    _settingsProvider.travelWalletMoneyWarningThreshold = int.parse(value);
                  }
                },
              ),
            ),
          ),
        ),
      SearchableRow(
        label: "Drug cooldown warning",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Drug cooldown warning"),
              Switch(
                value: _settingsProvider.travelDrugCooldownWarning,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.travelDrugCooldownWarning = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "Drug cooldown warning description",
        searchText: _searchText,
        filterable: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Text(
            "If enabled, you'll get a warning when you access the Travel Agency with no drug cooldown time, just in case you forgot",
            style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ),
      ),
      SearchableRow(
        label: "Booster cooldown warning",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Booster cooldown warning"),
              Switch(
                value: _settingsProvider.travelBoosterCooldownWarning,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.travelBoosterCooldownWarning = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "Booster cooldown warning description",
        searchText: _searchText,
        filterable: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Text(
            "If enabled, you'll get a warning when you access the Travel Agency with no booster cooldown time, just in case you forgot",
            style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ),
      ),
    ];
    return buildSectionWithRows(
      title: 'TRAVEL EXPENDITURE WARNING',
      rows: rows,
      searchText: _searchText,
    );
  }

  Widget _profile() {
    List<SearchableRow> rows = [
      SearchableRow(
        label: "Extra player information",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: const Text("Extra player information")),
                  Switch(
                    value: _settingsProvider.extraPlayerInformation,
                    onChanged: (value) {
                      setState(() {
                        _settingsProvider.changeExtraPlayerInformation = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
              Text(
                'Add additional player information when visiting a profile or attacking someone (e.g. same faction, friendly faction, friends) and estimated stats',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
      if (_settingsProvider.extraPlayerInformation)
        SearchableRow(
          label: "Friendly factions",
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: const Text("Friendly factions")),
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_right_outlined),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (BuildContext context) => FriendlyFactionsPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                Text(
                  'You will see a note if you are visiting the profile of a friendly faction\'s player, or a warning if you are about to attack',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      if (_settingsProvider.extraPlayerInformation)
        SearchableRow(
          label: "Show player notes",
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: const Text("Show player notes")),
                    Switch(
                      value: _settingsProvider.notesWidgetEnabledProfile,
                      onChanged: (value) {
                        setState(() {
                          _settingsProvider.changeNotesWidgetEnabledProfile = value;
                        });
                      },
                      activeTrackColor: Colors.lightGreenAccent,
                      activeColor: Colors.green,
                    ),
                  ],
                ),
                Text(
                  "If enabled, this will show a notes widget in the profile page for those players that you have added notes to (as friends, stakeouts or targets). The notes icon is actionable (tap to change notes)",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      if (_settingsProvider.extraPlayerInformation)
        SearchableRow(
          label: "Show networth",
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: const Text("Show networth")),
                    Switch(
                      value: _settingsProvider.extraPlayerNetworth,
                      onChanged: (value) {
                        setState(() {
                          _settingsProvider.changeExtraPlayerNetworth = value;
                        });
                      },
                      activeTrackColor: Colors.lightGreenAccent,
                      activeColor: Colors.green,
                    ),
                  ],
                ),
                Text(
                  'If enabled, this will show an additional line with the networth of the player you are visiting',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      SearchableRow(
        label: "Mini-profile name tap opens new tab",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: const Text("Mini-profile name tap opens new tab")),
                  Switch(
                    value: _settingsProvider.hitInMiniProfileOpensNewTab,
                    onChanged: (value) {
                      setState(() {
                        _settingsProvider.hitInMiniProfileOpensNewTab = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
              Text(
                'If enabled, tapping a player name in a mini-profile window will open a new tab, instead of loading the profile in the same window',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
      if (_settingsProvider.hitInMiniProfileOpensNewTab)
        SearchableRow(
          label: "Automatically change to new tab",
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(30, 0, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        children: [
                          Icon(Icons.arrow_forward_ios_outlined, size: 16),
                          SizedBox(width: 5),
                          Flexible(child: const Text("Automatically change to new tab")),
                        ],
                      ),
                    ),
                    Switch(
                      value: _settingsProvider.hitInMiniProfileOpensNewTabAndChangeTab,
                      onChanged: (value) {
                        setState(() {
                          _settingsProvider.hitInMiniProfileOpensNewTabAndChangeTab = value;
                        });
                      },
                      activeTrackColor: Colors.lightGreenAccent,
                      activeColor: Colors.green,
                    ),
                  ],
                ),
                Text(
                  'By using this switch you can select if the browser should automatically change to the newly generated tab after tapping a player\'s name in a mini-profile. By setting it to off, you can open several tabs in a row from different mini-profiles.',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
    ];
    return buildSectionWithRows(
      title: 'PLAYER PROFILES',
      rows: rows,
      searchText: _searchText,
    );
  }

  Widget _linkPreview() {
    List<SearchableRow> rows = [
      SearchableRow(
        label: "Allow links preview",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Allow links preview"),
              Switch(
                value: _settingsProvider.iosAllowLinkPreview,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.changeIosAllowLinkPreview = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "Allow links preview description",
        searchText: _searchText,
        filterable: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Allow browser to open an iOS native preview window when long-pressing a link (only iOS 9+)',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    ];
    return buildSectionWithRows(
      title: 'LINKS PREVIEW',
      rows: rows,
      searchText: _searchText,
    );
  }

  Widget _maintenance() {
    List<SearchableRow> rows = [
      SearchableRow(
        label: "Cache enabled",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: const Text("Cache enabled")),
                  Switch(
                    value: Platform.isWindows
                        ? true
                        : _settingsProvider.webviewCacheEnabledRemoteConfig == "user"
                            ? _settingsProvider.webviewCacheEnabled
                            : _settingsProvider.webviewCacheEnabledRemoteConfig == "on"
                                ? true
                                : false,
                    onChanged: Platform.isWindows
                        ? null
                        : _settingsProvider.webviewCacheEnabledRemoteConfig != "user"
                            ? null
                            : (value) {
                                setState(() {
                                  _settingsProvider.webviewCacheEnabled = value;
                                });
                              },
                    activeTrackColor: Platform.isWindows
                        ? Colors.grey[700]
                        : _settingsProvider.webviewCacheEnabledRemoteConfig == "user"
                            ? Colors.lightGreenAccent
                            : Colors.grey[700],
                    activeColor: Platform.isWindows
                        ? Colors.grey[700]
                        : _settingsProvider.webviewCacheEnabledRemoteConfig == "user"
                            ? Colors.green
                            : Colors.grey[700],
                    inactiveThumbColor: Platform.isWindows
                        ? Colors.grey[800]
                        : _settingsProvider.webviewCacheEnabledRemoteConfig == "user"
                            ? null
                            : Colors.grey[800],
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Platform.isWindows
                    ? Text(
                        "Cache is enabled from PDA and can't be changed right now",
                        style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
                      )
                    : _settingsProvider.webviewCacheEnabledRemoteConfig == "user"
                        ? Text(
                            "Enable webview cache to improve performance (recommended). Disabling this might be useful if you experience issues with Torn's website cache, such as images loading incorrectly, increased app cached data, chat issues, etc. NOTE: this will only take effect after you restart the app.",
                            style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
                          )
                        : _settingsProvider.webviewCacheEnabledRemoteConfig == "on"
                            ? Text(
                                "Cache is enabled from PDA and can't be changed right now",
                                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
                              )
                            : Text(
                                "Cache is disabled from PDA and can't be changed right now",
                                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
                              ),
              ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "Browser cache",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Browser cache"),
                  ElevatedButton(
                    child: const Text("Clear"),
                    onPressed: () async {
                      _webViewProvider.clearCacheAndTabs();
                      BotToast.showText(
                        text: "Browser cache and tabs have been reset!",
                        textStyle: const TextStyle(fontSize: 14, color: Colors.white),
                        contentColor: Colors.grey[600]!,
                        duration: const Duration(seconds: 3),
                        contentPadding: const EdgeInsets.all(10),
                      );
                    },
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  "Note: this will clear your browser's cache and current tabs. It can be useful in case of errors (sections not loading correctly, etc.). You'll be logged out from Torn and all other sites",
                  style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "Restore session cookie",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Restore session cookie"),
                  Switch(
                    value: _settingsProvider.restoreSessionCookie,
                    onChanged: (value) {
                      setState(() {
                        _settingsProvider.restoreSessionCookie = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  "Enable this option if you are getting logged out from Torn consistently; Torn PDA will try to reestablish your session ID when the browser opens",
                  style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "Do not pause webviews",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(child: Text("Do not pause webviews")),
                  Switch(
                    value: _webViewProvider.browserDoNotPauseWebview,
                    onChanged: (value) {
                      setState(() {
                        _webViewProvider.browserDoNotPauseWebview = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  "This will prevent the browser from pausing when the app or browser are in the background. NOTE: it is NOT recommended to activate this setting, as it will consume more battery and resources",
                  style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ),
      ),
    ];
    return buildSectionWithRows(
      title: 'MAINTENANCE',
      rows: rows,
      searchText: _searchText,
    );
  }

  Widget _gestures() {
    List<SearchableRow> rows = [
      if (Platform.isIOS)
        SearchableRow(
          label: "Zoom in/out pinch gestures",
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: const Text("Zoom in/out pinch gestures")),
                Switch(
                  value: _settingsProvider.iosBrowserPinch,
                  onChanged: (value) {
                    setState(() {
                      _settingsProvider.setIosBrowserPinch = value;
                    });
                  },
                  activeTrackColor: Colors.lightGreenAccent,
                  activeColor: Colors.green,
                ),
              ],
            ),
          ),
        ),
      if (Platform.isIOS)
        SearchableRow(
          label: "Disallow overscroll",
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: const Text("Disallow overscroll")),
                    Switch(
                      value: _settingsProvider.iosDisallowOverscroll,
                      onChanged: (value) {
                        setState(() {
                          _settingsProvider.setIosDisallowOverscroll = value;
                        });
                      },
                      activeTrackColor: Colors.lightGreenAccent,
                      activeColor: Colors.green,
                    ),
                  ],
                ),
                Text(
                  'Certain iOS versions (e.g.: iOS 16) may experience overscroll issues; enabling this may prevent that behavior.',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      SearchableRow(
        label: "Reverse navigation swipe",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: const Text("Reverse navigation swipe")),
                  Switch(
                    value: _settingsProvider.browserReverseNavitagtionSwipe,
                    onChanged: (value) {
                      setState(() {
                        _settingsProvider.browserReverseNavigationSwipe = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
              Text(
                'Swiping left-to-right navigates backwards and right-to-left forwards; enable to reverse these actions.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: "Center text field when editing",
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: const Text("Center text field when editing")),
                  Switch(
                    value: _settingsProvider.browserCenterEditingTextField,
                    onChanged: (value) {
                      setState(() {
                        _settingsProvider.browserCenterEditingTextField = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeColor: Colors.green,
                  ),
                ],
              ),
              Text(
                "Automatically scrolls to keep the text field visible when editing.",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    ];
    return buildSectionWithRows(
      title: "GESTURES",
      rows: rows,
      searchText: _searchText,
    );
  }

  String _buildSingleLabel(double percentage, int currentMax, String type) {
    if (percentage >= 110) {
      return "> max\n> $currentMax $type";
    } else if (currentMax == -1) {
      return "${percentage.round()}%";
    } else {
      final realValue = (percentage / 100 * currentMax).round();
      return "${percentage.round()}%\n$realValue $type";
    }
  }

  String _buildRangeLabel(double percentage, int currentMax, String type) {
    if (percentage >= 110) {
      return "> max\n> $currentMax $type";
    } else if (currentMax == -1) {
      return "${percentage.round()}%";
    } else {
      final realValue = (percentage / 100 * currentMax).round();
      return "${percentage.round()}%\n$realValue $type";
    }
  }

  void _showColorPickerTabs(BuildContext context) async {
    showDialog(
      useRootNavigator: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a color!'),
          content: SingleChildScrollView(
            child: ColorPicker(
              color: Color(_settingsProvider.tabsHideBarColor),
              onColorChanged: (color) {
                setState(() {
                  _settingsProvider.changeTabsHideBarColor = color.value;
                });
              },
              width: 40,
              height: 40,
              borderRadius: 4,
              spacing: 5,
              runSpacing: 5,
              wheelDiameter: 155,
              heading: Text(
                'Select color',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              subheading: Text(
                'Select color shade',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              wheelSubheading: Text(
                'Selected color and its shades',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              showMaterialName: true,
              showColorName: true,
              showColorCode: true,
              copyPasteBehavior: const ColorPickerCopyPasteBehavior(
                longPressMenu: true,
              ),
              materialNameTextStyle: Theme.of(context).textTheme.bodySmall,
              colorNameTextStyle: Theme.of(context).textTheme.bodySmall,
              colorCodeTextStyle: Theme.of(context).textTheme.bodySmall,
              pickersEnabled: const <ColorPickerType, bool>{
                ColorPickerType.both: false,
                ColorPickerType.primary: true,
                ColorPickerType.accent: true,
                ColorPickerType.bw: false,
                ColorPickerType.custom: true,
                ColorPickerType.wheel: true,
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Got it'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showHighlightSelectorChat(BuildContext context) {
    showDialog(useRootNavigator: false, context: context, builder: (c) => ChatHighlightAddWordsDialog());
  }

  void _showColorPickerChat(BuildContext context) {
    var pickerColor = _highlightColor;
    showDialog(
      useRootNavigator: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a color!'),
          content: SingleChildScrollView(
            child: ColorPicker(
              color: _highlightColor,
              onColorChanged: (color) {
                _settingsProvider.changeHighlightColor = color.value;
                setState(() {
                  pickerColor = color;
                });
              },
              width: 40,
              height: 40,
              borderRadius: 4,
              spacing: 5,
              runSpacing: 5,
              wheelDiameter: 155,
              heading: Text(
                'Select color',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              subheading: Text(
                'Select color shade',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              wheelSubheading: Text(
                'Selected color and its shades',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              showMaterialName: true,
              showColorName: true,
              showColorCode: true,
              copyPasteBehavior: const ColorPickerCopyPasteBehavior(
                longPressMenu: true,
              ),
              materialNameTextStyle: Theme.of(context).textTheme.bodySmall,
              colorNameTextStyle: Theme.of(context).textTheme.bodySmall,
              colorCodeTextStyle: Theme.of(context).textTheme.bodySmall,
              pickersEnabled: const <ColorPickerType, bool>{
                ColorPickerType.both: false,
                ColorPickerType.primary: true,
                ColorPickerType.accent: true,
                ColorPickerType.bw: false,
                ColorPickerType.custom: true,
                ColorPickerType.wheel: true,
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Got it'),
              onPressed: () {
                setState(() => _highlightColor = pickerColor);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      iconTheme: IconThemeData(color: Colors.white),
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      toolbarHeight: 50,
      title: const Text('Browser settings', style: TextStyle(color: Colors.white)),
      leadingWidth: _webViewProvider.webViewSplitActive ? 50 : 88,
      leading: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              _goBack();
            },
          ),
          if (!_webViewProvider.webViewSplitActive) PdaBrowserIcon(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Widget _browserStyleDropdown() {
    return DropdownButton<int>(
      value: _browserStyle,
      items: const [
        DropdownMenuItem(
          value: 0,
          child: SizedBox(
            width: 80,
            child: Text(
              "Default",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: 1,
          child: SizedBox(
            width: 80,
            child: Text(
              "Bottom bar",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: 2,
          child: SizedBox(
            width: 80,
            child: Text(
              "Dialog",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        _browserStyle = value;

        switch (value) {
          case 0:
            analytics?.setUserProperty(name: "browser_style", value: "default");
            _webViewProvider.bottomBarStyleEnabled = false;
          case 1:
            analytics?.setUserProperty(name: "browser_style", value: "bottom_bar");
            _webViewProvider.bottomBarStyleEnabled = true;
            _webViewProvider.bottomBarStyleType = 1;
          case 2:
            analytics?.setUserProperty(name: "browser_style", value: "dialog");
            _webViewProvider.bottomBarStyleEnabled = true;
            _webViewProvider.bottomBarStyleType = 2;
        }
      },
    );
  }

  Widget _fabDirectionDropdown() {
    return DropdownButton<String>(
      value: _webViewProvider.fabDirection,
      items: const [
        DropdownMenuItem(
          value: "center",
          child: SizedBox(
            width: 70,
            child: Text(
              "Top",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "left",
          child: SizedBox(
            width: 70,
            child: Text(
              "Left",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "right",
          child: SizedBox(
            width: 70,
            child: Text(
              "Right",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _webViewProvider.fabDirection = value!;
        });
      },
    );
  }

  Widget _downloadsDropdown() {
    return DropdownButton<bool>(
      value: _settingsProvider.downloadActionShare,
      items: const [
        DropdownMenuItem(
          value: true,
          child: SizedBox(
            width: 70,
            child: Text(
              "Share",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: false,
          child: SizedBox(
            width: 70,
            child: Text(
              "Save",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _settingsProvider.downloadActionShare = value!;
        });
      },
    );
  }

  Widget _refreshMethodDropdown() {
    return DropdownButton<BrowserRefreshSetting>(
      value: _settingsProvider.browserRefreshMethod,
      items: const [
        DropdownMenuItem(
          value: BrowserRefreshSetting.icon,
          child: SizedBox(
            width: 100,
            child: Text(
              "Icon",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: BrowserRefreshSetting.pull,
          child: SizedBox(
            width: 100,
            child: Text(
              "Pull to refresh",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: BrowserRefreshSetting.both,
          child: SizedBox(
            width: 100,
            child: Text(
              "Both",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _settingsProvider.changeBrowserRefreshMethod = value;
          _webViewProvider.updatePullToRefresh(value);
        });
      },
    );
  }

  Widget _navArrowsDropdown() {
    return DropdownButton<String>(
      value: _settingsProvider.browserShowNavArrowsAppbar,
      items: const [
        DropdownMenuItem(
          value: "off",
          child: SizedBox(
            width: 100,
            child: Text(
              "Off",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "narrow",
          child: SizedBox(
            width: 100,
            child: Text(
              "Always",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "wide",
          child: SizedBox(
            width: 100,
            child: Text(
              "Wide screen",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _settingsProvider.browserShowNavArrowsAppbar = value;
        });

        if (_settingsProvider.browserShowNavArrowsAppbar == "narrow") {
          double width = MediaQuery.of(context).size.width;
          if (width < 500) {
            BotToast.showText(
              clickClose: true,
              text: "Please note that your current screen configuration (${width.round()} DPI) might "
                  "not be wide enough to display the navigation arrows in all circumstances (e.g. when other "
                  "icons are present, such as when chaining)."
                  "\n\nRemember you can always swipe left or right in the page title to navigate.",
              textStyle: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
              contentColor: Colors.blue[600]!,
              duration: const Duration(seconds: 15),
              contentPadding: const EdgeInsets.all(10),
            );
          }
        }
      },
    );
  }

  Future _restorePreferences() async {
    final alternativeBrowser = await Prefs().getBrowserBottomBarStyleEnabled();
    final alternativeType = await Prefs().getBrowserBottomBarStyleType();
    var style = 0;
    if (alternativeBrowser) {
      style = alternativeType == 2 ? 2 : 1;
    }

    setState(() {
      _highlightChat = _settingsProvider.highlightChat;
      _highlightColor = Color(_settingsProvider.highlightColor);
      _browserStyle = style;
    });
  }

  _goBack() {
    routeWithDrawer = true;
    routeName = "settings";
    Navigator.of(context).pop();
  }
}
