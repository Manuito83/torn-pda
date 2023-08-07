// Dart imports:
import 'dart:async';

// Package imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:torn_pda/drawer.dart';
import 'package:torn_pda/models/chaining/chain_panic_target_model.dart';
import 'package:torn_pda/models/chaining/target_model.dart';
// Project imports:
import 'package:torn_pda/models/chaining/war_sort.dart';
import 'package:torn_pda/models/faction/faction_model.dart';
import 'package:torn_pda/pages/chaining/ranked_wars_page.dart';
import 'package:torn_pda/providers/api_caller.dart';
import 'package:torn_pda/providers/chain_status_provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/targets_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/war_controller.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/country_check.dart';
import 'package:torn_pda/utils/html_parser.dart';
import 'package:torn_pda/widgets/chaining/chain_widget.dart';
import 'package:torn_pda/widgets/chaining/war_card.dart';
import 'package:torn_pda/widgets/revive/nuke_revive_button.dart';
import 'package:torn_pda/widgets/revive/uhc_revive_button.dart';
import 'package:torn_pda/widgets/webviews/pda_browser_icon.dart';

class WarOptions {
  String? description;
  IconData? iconData;

  WarOptions({this.description}) {
    switch (description) {
      case "Toggle chain widget":
        iconData = MdiIcons.linkVariant;
      case "Hidden targets":
        iconData = Icons.undo_outlined;
      case "Nuke revive":
        // Own icon in widget
        break;
      case "UHC revive":
        // Own icon in widget
        break;
    }
  }
}

class WarPage extends StatefulWidget {
  //final Function tabCallback;

  const WarPage({
    super.key,
    //@required this.tabCallback,
  });

  @override
  WarPageState createState() => WarPageState();
}

class WarPageState extends State<WarPage> {
  final GlobalKey _showCaseAddFaction = GlobalKey();
  final GlobalKey _showCaseUpdate = GlobalKey();

  final _searchController = TextEditingController();
  final _addIdController = TextEditingController();

  final _addFormKey = GlobalKey<FormState>();

  final _chainWidgetKey = GlobalKey();

  final WarController _w = Get.put(WarController());
  ThemeProvider? _themeProvider;
  SettingsProvider? _settingsProvider;
  WebViewProvider? _webViewProvider;

  bool _quickUpdateActive = false;

  final _popupSortChoices = <WarSort>[
    WarSort(type: WarSortType.levelDes),
    WarSort(type: WarSortType.levelAsc),
    WarSort(type: WarSortType.respectDes),
    WarSort(type: WarSortType.respectAsc),
    WarSort(type: WarSortType.nameDes),
    WarSort(type: WarSortType.nameAsc),
    WarSort(type: WarSortType.lifeDes),
    WarSort(type: WarSortType.lifeAsc),
    WarSort(type: WarSortType.statsDes),
    WarSort(type: WarSortType.statsAsc),
    WarSort(type: WarSortType.onlineDes),
    WarSort(type: WarSortType.onlineAsc),
    WarSort(type: WarSortType.colorAsc),
    WarSort(type: WarSortType.colorDes),
    WarSort(type: WarSortType.notesDes),
    WarSort(type: WarSortType.notesAsc),
  ];

  final _popupOptionsChoices = <WarOptions>[
    //WarOptions(description: "Toggle chain widget"),
    WarOptions(description: "Hidden targets"),
    WarOptions(description: "Nuke revive"),
    WarOptions(description: "UHC revive"),
  ];

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _webViewProvider = context.read<WebViewProvider>();

    _performQuickUpdate(firstTime: true);

    routeWithDrawer = true;
    routeName = "chaining_war";
  }

  @override
  Future dispose() async {
    _addIdController.dispose();
    _searchController.dispose();
    _w.stopUpdate();
    Get.delete<WarController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context);
    return ShowCaseWidget(
      builder: Builder(
        builder: (_) {
          if (_w.showCaseStart) {
            // Delaying also (even Duration.zero works) to avoid state conflicts with build
            Future.delayed(const Duration(seconds: 1), () async {
              ShowCaseWidget.of(_).startShowCase([_showCaseAddFaction, _showCaseUpdate]);
              _w.showCaseStart = false;
            });
          }
          return Scaffold(
            backgroundColor: _themeProvider!.canvas,
            drawer: const Drawer(),
            appBar: _settingsProvider!.appBarTop ? buildAppBar(_) : null,
            bottomNavigationBar: !_settingsProvider!.appBarTop
                ? SizedBox(
                    height: AppBar().preferredSize.height,
                    child: buildAppBar(_),
                  )
                : null,
            body: Container(
              color: _themeProvider!.currentTheme == AppTheme.extraDark ? Colors.black : Colors.transparent,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
                child: MediaQuery.of(context).orientation == Orientation.portrait
                    ? _mainColumn()
                    : SingleChildScrollView(
                        child: _mainColumn(),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _mainColumn() {
    return GetBuilder<WarController>(
      init: _w,
      builder: (w) {
        final int hiddenMembers = w.getHiddenMembersNumber();
        return Column(
          children: <Widget>[
            if (w.factions.where((f) => f.hidden!).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  "${w.factions.where((f) => f.hidden!).length} "
                  "${w.factions.where((f) => f.hidden!).length == 1 ? 'faction is' : 'factions are'} filtered out",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
                  ),
                ),
              ),
            if (hiddenMembers > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  "$hiddenMembers ${hiddenMembers == 1 ? 'target is' : 'targets are'} hidden",
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 5),
            if (w.showChainWidget)
              ChainWidget(
                key: _chainWidgetKey,
                alwaysDarkBackground: false,
                callBackOptions: _callBackChainOptions,
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _onlineFilter(),
                const SizedBox(width: 10),
                _okayFilter(w),
                const SizedBox(width: 10),
                _countryFilter(w),
                const SizedBox(width: 5),
                _travelingFilter(w),
                const SizedBox(width: 10),
                _chainWidgetToggler(w),
              ],
            ),
            const SizedBox(height: 5),
            if (context.orientation == Orientation.portrait)
              Flexible(
                child: WarTargetsList(
                  warController: w,
                  offlineSelector: w.onlineFilter,
                  okayFilterActive: w.okayFilter,
                  countryFilterActive: w.countryFilter,
                  travelingFilterActive: w.travelingFilter,
                ),
              )
            else
              WarTargetsList(
                warController: w,
                offlineSelector: w.onlineFilter,
                okayFilterActive: w.okayFilter,
                countryFilterActive: w.countryFilter,
                travelingFilterActive: w.travelingFilter,
              ),
            if (_settingsProvider!.appBarTop) const SizedBox(height: 50),
          ],
        );
      },
    );
  }

  Widget _onlineFilter() {
    return SizedBox(
      height: 25,
      child: ToggleSwitch(
        customWidths: const [32, 32],
        borderWidth: 1,
        cornerRadius: 5,
        doubleTapDisable: true,
        borderColor: _themeProvider!.currentTheme == AppTheme.light ? [Colors.blueGrey] : [Colors.grey[900]!],
        initialLabelIndex: _w.onlineFilter == 0
            ? null
            : _w.onlineFilter == 1
                ? 0
                : 1,
        activeBgColor: _themeProvider!.currentTheme == AppTheme.light
            ? [Colors.blueGrey]
            : _themeProvider!.currentTheme == AppTheme.dark
                ? [Colors.blueGrey]
                : [Colors.blueGrey[900]!],
        activeFgColor: _themeProvider!.currentTheme == AppTheme.light ? Colors.black : Colors.white,
        inactiveBgColor: _themeProvider!.currentTheme == AppTheme.light
            ? Colors.white
            : _themeProvider!.currentTheme == AppTheme.dark
                ? Colors.grey[800]
                : Colors.black,
        inactiveFgColor: _themeProvider!.currentTheme == AppTheme.light ? Colors.black : Colors.white,
        totalSwitches: 2,
        animate: true,
        animationDuration: 500,
        customIcons: const [
          Icon(
            Icons.circle,
            color: Colors.green,
            size: 12,
          ),
          Icon(
            Icons.circle,
            color: Colors.red,
            size: 12,
          )
        ],
        onToggle: (index) async {
          await _performQuickUpdate();

          if (index == null) {
            _w.setOnlineFilter(0);
          } else if (index == 0) {
            _w.setOnlineFilter(1);
          } else if (index == 1) {
            _w.setOnlineFilter(2);
          }

          String message;

          if (_w.activeFilters.isEmpty) {
            message = "Showing all targets";
          } else {
            message = "Filters: ${_w.activeFilters.join(", ")}";
          }

          BotToast.showText(
            clickClose: true,
            text: message,
            textStyle: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            contentColor: Colors.grey[700]!,
            duration: const Duration(seconds: 3),
            contentPadding: const EdgeInsets.all(10),
          );
        },
      ),
    );
  }

  Widget _okayFilter(WarController w) {
    return SizedBox(
      height: 25,
      child: ToggleSwitch(
        customWidths: const [32],
        borderWidth: 1,
        cornerRadius: 5,
        doubleTapDisable: true,
        borderColor: _themeProvider!.currentTheme == AppTheme.light ? [Colors.blueGrey] : [Colors.grey[900]!],
        initialLabelIndex: !w.okayFilter ? null : 0,
        activeBgColor: _themeProvider!.currentTheme == AppTheme.light
            ? [Colors.blueGrey]
            : _themeProvider!.currentTheme == AppTheme.dark
                ? [Colors.blueGrey]
                : [Colors.blueGrey[900]!],
        activeFgColor: _themeProvider!.currentTheme == AppTheme.light ? Colors.black : Colors.white,
        inactiveBgColor: _themeProvider!.currentTheme == AppTheme.light
            ? Colors.white
            : _themeProvider!.currentTheme == AppTheme.dark
                ? Colors.grey[800]
                : Colors.black,
        inactiveFgColor: _themeProvider!.currentTheme == AppTheme.light ? Colors.black : Colors.white,
        totalSwitches: 1,
        animate: true,
        animationDuration: 500,
        customIcons: const [
          Icon(
            MdiIcons.accountCheckOutline,
            size: 12,
          ),
        ],
        onToggle: (index) async {
          await _performQuickUpdate();

          if (index == null) {
            _w.setOkayFilterActive(false);
          } else {
            _w.setOkayFilterActive(true);
          }

          String message;

          if (_w.activeFilters.isEmpty) {
            message = "Showing all targets";
          } else {
            message = "Filters: ${_w.activeFilters.join(", ")}";
          }

          BotToast.showText(
            clickClose: true,
            text: message,
            textStyle: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            contentColor: Colors.grey[700]!,
            duration: const Duration(seconds: 3),
            contentPadding: const EdgeInsets.all(10),
          );
        },
      ),
    );
  }

  Widget _countryFilter(WarController w) {
    return SizedBox(
      height: 25,
      child: ToggleSwitch(
        customWidths: const [32],
        borderWidth: 1,
        cornerRadius: 5,
        doubleTapDisable: true,
        borderColor: _themeProvider!.currentTheme == AppTheme.light ? [Colors.blueGrey] : [Colors.grey[900]!],
        initialLabelIndex: !w.countryFilter ? null : 0,
        activeBgColor: _themeProvider!.currentTheme == AppTheme.light
            ? [Colors.blueGrey]
            : _themeProvider!.currentTheme == AppTheme.dark
                ? [Colors.blueGrey]
                : [Colors.blueGrey[900]!],
        activeFgColor: _themeProvider!.currentTheme == AppTheme.light ? Colors.black : Colors.white,
        inactiveBgColor: _themeProvider!.currentTheme == AppTheme.light
            ? Colors.white
            : _themeProvider!.currentTheme == AppTheme.dark
                ? Colors.grey[800]
                : Colors.black,
        inactiveFgColor: _themeProvider!.currentTheme == AppTheme.light ? Colors.black : Colors.white,
        totalSwitches: 1,
        animate: true,
        animationDuration: 500,
        customIcons: const [
          Icon(
            MdiIcons.earth,
            size: 12,
          ),
        ],
        onToggle: (index) async {
          await _performQuickUpdate();

          if (index == null) {
            w.setCountryFilterActive(false);
          } else {
            w.setCountryFilterActive(true);
          }

          String message;

          if (_w.activeFilters.isEmpty) {
            message = "Showing all targets";
          } else {
            message = "Filters: ${_w.activeFilters.join(", ")}";
          }

          BotToast.showText(
            clickClose: true,
            text: message,
            textStyle: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            contentColor: Colors.grey[700]!,
            duration: const Duration(seconds: 3),
            contentPadding: const EdgeInsets.all(10),
          );
        },
      ),
    );
  }

  Widget _travelingFilter(WarController w) {
    return SizedBox(
      height: 25,
      child: ToggleSwitch(
        customWidths: const [32],
        borderWidth: 1,
        cornerRadius: 5,
        doubleTapDisable: true,
        borderColor: _themeProvider!.currentTheme == AppTheme.light ? [Colors.blueGrey] : [Colors.grey[900]!],
        initialLabelIndex: !w.travelingFilter ? null : 0,
        activeBgColor: _themeProvider!.currentTheme == AppTheme.light
            ? [Colors.red[200]!]
            : _themeProvider!.currentTheme == AppTheme.dark
                ? [Colors.red[500]!]
                : [Colors.red[900]!],
        activeFgColor: _themeProvider!.currentTheme == AppTheme.light ? Colors.black : Colors.white,
        inactiveBgColor: _themeProvider!.currentTheme == AppTheme.light
            ? Colors.white
            : _themeProvider!.currentTheme == AppTheme.dark
                ? Colors.grey[800]
                : Colors.black,
        inactiveFgColor: _themeProvider!.currentTheme == AppTheme.light ? Colors.black : Colors.white,
        totalSwitches: 1,
        animate: true,
        animationDuration: 500,
        customIcons: const [
          Icon(
            MdiIcons.airplane,
            size: 12,
          ),
        ],
        onToggle: (index) async {
          await _performQuickUpdate();

          if (index == null) {
            w.setTravelingFilterActive(false);
          } else {
            w.setTravelingFilterActive(true);
          }

          String message;

          if (_w.activeFilters.isEmpty) {
            message = "Hiding traveling targets";
          } else {
            message = "Filters: ${_w.activeFilters.join(", ")}";
          }

          BotToast.showText(
            clickClose: true,
            text: message,
            textStyle: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            contentColor: Colors.grey[700]!,
            duration: const Duration(seconds: 3),
            contentPadding: const EdgeInsets.all(10),
          );
        },
      ),
    );
  }

  Widget _chainWidgetToggler(WarController w) {
    return SizedBox(
      height: 25,
      child: ToggleSwitch(
        customWidths: const [32],
        borderWidth: 1,
        cornerRadius: 5,
        doubleTapDisable: true,
        borderColor: _themeProvider!.currentTheme == AppTheme.light ? [Colors.blueGrey] : [Colors.grey[900]!],
        initialLabelIndex: !w.showChainWidget ? null : 0,
        activeBgColor: _themeProvider!.currentTheme == AppTheme.light
            ? [Colors.blueGrey]
            : _themeProvider!.currentTheme == AppTheme.dark
                ? [Colors.blueGrey]
                : [Colors.blueGrey[900]!],
        activeFgColor: _themeProvider!.currentTheme == AppTheme.light ? Colors.black : Colors.white,
        inactiveBgColor: _themeProvider!.currentTheme == AppTheme.light
            ? Colors.white
            : _themeProvider!.currentTheme == AppTheme.dark
                ? Colors.grey[800]
                : Colors.black,
        inactiveFgColor: _themeProvider!.currentTheme == AppTheme.light ? Colors.black : Colors.white,
        totalSwitches: 1,
        animate: true,
        animationDuration: 500,
        customIcons: const [
          Icon(
            MdiIcons.linkVariant,
            size: 12,
          ),
        ],
        onToggle: (index) async {
          _w.toggleChainWidget();
        },
      ),
    );
  }

  AppBar buildAppBar(BuildContext _) {
    return AppBar(
      //brightness: Brightness.dark, // For downgrade to Flutter 2.2.3
      elevation: _settingsProvider!.appBarTop ? 2 : 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      title: const Text("War"),
      leadingWidth: 80,
      leading: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              final ScaffoldState? scaffoldState = context.findRootAncestorStateOfType();
              if (scaffoldState != null) {
                scaffoldState.openDrawer();
              }
            },
          ),
          const PdaBrowserIcon(),
        ],
      ),
      actions: <Widget>[
        Showcase(
          disableMovingAnimation: true,
          key: _showCaseAddFaction,
          title: 'Welcome to War!',
          description: "\nThe first thing you'll want to do is to add an enemy faction to your list. You can do so by "
              "tapping this icon."
              "\n\nIf you don't know the faction's ID, you can optionally insert one of it's members' "
              "ID (look for the 'person' icon)."
              "\n\nMake sure to have a look at the Tips section in the main menu for more information and tricks!",
          textColor: _themeProvider!.mainText!,
          tooltipBackgroundColor: _themeProvider!.secondBackground!,
          descTextStyle: const TextStyle(fontSize: 13),
          tooltipPadding: const EdgeInsets.all(20),
          child: IconButton(
            icon: Image.asset(
              'images/icons/faction.png',
              width: 18,
              height: 18,
              color: Colors.white,
            ),
            onPressed: () {
              _showAddDialog(context);
            },
          ),
        ),
        Showcase(
          disableMovingAnimation: true,
          key: _showCaseUpdate,
          title: 'Updating targets!',
          description: "\nThere are a couple of ways to update war targets.\n\nWith a short tap, you can perform "
              "a quick update with minimal target information (some stats and life information won't be available).\n\n"
              "A long-press will start a slower but full update of all targets.\n\n"
              "Alternatively, you can update targets individually.",
          textColor: _themeProvider!.mainText!,
          tooltipBackgroundColor: _themeProvider!.secondBackground!,
          descTextStyle: const TextStyle(fontSize: 13),
          tooltipPadding: const EdgeInsets.all(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: GetBuilder<WarController>(
              builder: (w) {
                if (w.updating) {
                  return GestureDetector(
                    child: Icon(
                      MdiIcons.closeOctagonOutline,
                      color: Colors.orange[700],
                    ),
                    onTap: () async {
                      _w.stopUpdate();
                    },
                  );
                } else {
                  return GestureDetector(
                    onTap: _quickUpdateActive
                        ? null
                        : () {
                            _performQuickUpdate();
                          },
                    // Full update
                    onLongPress: () async {
                      String message = "";
                      Color? messageColor = Colors.green;
                      // Count all members
                      int allMembers = _w.orderedCardsDetails.length;
                      int updatedMembers = 0;

                      if (allMembers == 0) {
                        message = "No targets to update!";
                        messageColor = Colors.orange[700];
                      } else {
                        if (allMembers > 60) {
                          BotToast.showText(
                            clickClose: true,
                            text:
                                "Updating $allMembers war targets, this might take a while. Extra time needed to avoid "
                                "issues with API request limits!",
                            textStyle: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                            contentColor: messageColor,
                            duration: const Duration(seconds: 3),
                            contentPadding: const EdgeInsets.all(10),
                          );
                        }
                        List<int> result = await _w.updateAllMembersFull();
                        allMembers =
                            result[0]; // This might have changed if new members are added with integrityCheck()
                        updatedMembers = result[1];
                      }

                      if (updatedMembers > 0 && updatedMembers == allMembers) {
                        message = 'Successfully updated $updatedMembers war targets!';
                      } else if (updatedMembers > 0 && updatedMembers < allMembers) {
                        message = 'Updated $updatedMembers war targets, but ${allMembers - updatedMembers} failed!';
                        messageColor = Colors.orange[700];
                      }

                      if (mounted) {
                        BotToast.showText(
                          clickClose: true,
                          text: message,
                          textStyle: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                          contentColor: messageColor!,
                          duration: const Duration(seconds: 3),
                          contentPadding: const EdgeInsets.all(10),
                        );
                      }
                    },
                    child: Icon(Icons.refresh, color: _quickUpdateActive ? Colors.grey : Colors.white),
                  );
                }
              },
            ),
          ),
        ),
        PopupMenuButton<WarSort>(
          icon: const Icon(
            Icons.sort,
          ),
          onSelected: _selectSortPopup,
          itemBuilder: (BuildContext context) {
            return _popupSortChoices.map((WarSort choice) {
              return PopupMenuItem<WarSort>(
                value: choice,
                child: Text(
                  choice.description,
                  style: const TextStyle(
                    fontSize: 13,
                  ),
                ),
              );
            }).toList();
          },
        ),
        PopupMenuButton<WarOptions>(
          icon: const Icon(Icons.settings),
          onSelected: (selection) {
            switch (selection.description) {
              /*
              case "Toggle chain widget":
                _w.toggleChainWidget();
                break;
              */
              case "Hidden targets":
                _showHiddenMembersDialogs(context);
              case "Nuke revive":
                // Gesture not activated
                break;
            }
          },
          itemBuilder: (BuildContext context) {
            return _popupOptionsChoices.map((WarOptions choice) {
              // Don't return hidden members option if there is none
              if (choice.description!.contains("Hidden") && _w.getHiddenMembersNumber() == 0) {
                return null;
              }
              // Nuke revive
              if (choice.description!.contains("Nuke")) {
                if (!_w.nukeReviveActive) {
                  return null;
                }
                return PopupMenuItem<WarOptions>(
                  value: choice,
                  child: NukeReviveButton(
                    themeProvider: _themeProvider,
                    settingsProvider: _settingsProvider,
                    webViewProvider: _webViewProvider,
                  ),
                );
              }
              // UHC revive
              if (choice.description!.contains("UHC")) {
                if (!_w.uhcReviveActive) {
                  return null;
                }
                return PopupMenuItem<WarOptions>(
                  value: choice,
                  child: UhcReviveButton(
                    themeProvider: _themeProvider,
                    settingsProvider: _settingsProvider,
                    webViewProvider: _webViewProvider,
                  ),
                );
              }
              // Everything else
              return PopupMenuItem<WarOptions>(
                value: choice,
                child: Row(
                  children: [
                    Icon(choice.iconData, size: 20, color: _themeProvider!.mainText),
                    const SizedBox(width: 10),
                    Text(choice.description!),
                  ],
                ),
              );
            }).toList() as List<PopupMenuEntry<WarOptions>>;
          },
        ),
        IconButton(
          icon: const Icon(MdiIcons.earth),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (BuildContext context) => const RankedWarsPage(),
              ),
            );
            //Get.to(() => RankedWarsPage());
          },
        ),
      ],
    );
  }

  Future<void> _performQuickUpdate({bool firstTime = false}) async {
    try {
      setState(() {
        _quickUpdateActive = true;
      });

      if (mounted && !firstTime) {
        BotToast.showText(
          clickClose: true,
          text: "Fetching information, please wait...",
          textStyle: const TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
          contentColor: Colors.grey[700]!,
          duration: const Duration(seconds: 3),
          contentPadding: const EdgeInsets.all(10),
        );
      }

      final int updatedMembers = await _w.updateAllMembersEasy();

      String message = "";
      Color? messageColor = Colors.green;
      // Count all members
      final int allMembers = _w.orderedCardsDetails.length;

      if (allMembers == -1) {
        message = "There was a problem getting information from the API, please try again later!";
        messageColor = Colors.orange[700];
      } else if (allMembers == 0) {
        message = "No targets to update!";
        messageColor = Colors.orange[700];
      } else if (updatedMembers > 0 && updatedMembers >= allMembers) {
        message = 'Successfully updated $updatedMembers war targets!\n\n'
            'A quick update was performed (only stats, state and online status).';
      } else if (updatedMembers > 0 && updatedMembers < allMembers) {
        message = 'Updated $updatedMembers war targets, but ${allMembers - updatedMembers} failed!\n\n'
            'A quick update was performed (only stats, state and online status).';
        messageColor = Colors.orange[700];
      }

      if (mounted && !firstTime) {
        BotToast.showText(
          clickClose: true,
          text: message,
          textStyle: const TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
          contentColor: messageColor!,
          duration: const Duration(seconds: 5),
          contentPadding: const EdgeInsets.all(10),
        );
      }

      if (mounted) {
        setState(() {
          _quickUpdateActive = false;
        });
      }
    } catch (e, trace) {
      FirebaseCrashlytics.instance.log("PDA Crash at War Quick Update");
      FirebaseCrashlytics.instance.recordError("PDA Error: $e", trace);
    }
  }

  Future<void> _showAddDialog(BuildContext _) {
    return showDialog<void>(
      context: _,
      builder: (BuildContext context) {
        return GetBuilder<WarController>(
          builder: (w) => AddFactionDialog(
            themeProvider: _themeProvider,
            addFormKey: _addFormKey,
            addIdController: _addIdController,
            warController: w,
          ),
        );
      },
    );
  }

  Future<void> _showHiddenMembersDialogs(BuildContext _) {
    return showDialog<void>(
      context: _,
      builder: (BuildContext context) {
        return GetBuilder<WarController>(
          builder: (w) => HiddenMembersDialog(
            themeProvider: _themeProvider,
            warController: w,
          ),
        );
      },
    );
  }

  void _selectSortPopup(WarSort choice) {
    switch (choice.type) {
      case WarSortType.levelDes:
        _w.sortTargets(WarSortType.levelDes);
      case WarSortType.levelAsc:
        _w.sortTargets(WarSortType.levelAsc);
      case WarSortType.respectDes:
        _w.sortTargets(WarSortType.respectDes);
      case WarSortType.respectAsc:
        _w.sortTargets(WarSortType.respectAsc);
      case WarSortType.nameDes:
        _w.sortTargets(WarSortType.nameDes);
      case WarSortType.nameAsc:
        _w.sortTargets(WarSortType.nameAsc);
      case WarSortType.lifeDes:
        _w.sortTargets(WarSortType.lifeDes);
      case WarSortType.lifeAsc:
        _w.sortTargets(WarSortType.lifeAsc);
      case WarSortType.statsDes:
        _w.sortTargets(WarSortType.statsDes);
      case WarSortType.statsAsc:
        _w.sortTargets(WarSortType.statsAsc);
      case WarSortType.onlineDes:
        _w.sortTargets(WarSortType.onlineDes);
      case WarSortType.onlineAsc:
        _w.sortTargets(WarSortType.onlineAsc);
      case WarSortType.colorDes:
        _w.sortTargets(WarSortType.colorDes);
      case WarSortType.colorAsc:
        _w.sortTargets(WarSortType.colorAsc);
      case WarSortType.notesDes:
        _w.sortTargets(WarSortType.notesDes);
      case WarSortType.notesAsc:
        _w.sortTargets(WarSortType.notesAsc);
      default:
        _w.sortTargets(WarSortType.nameAsc);
        break;
    }
  }

  void _callBackChainOptions() {
    setState(() {
      // Makes sure to update cards' border when out of panic options
    });
  }
}

class AddFactionDialog extends StatelessWidget {
  const AddFactionDialog({
    super.key,
    required this.themeProvider,
    required this.addFormKey,
    required this.addIdController,
    required this.warController,
  });

  final ThemeProvider? themeProvider;
  final GlobalKey<FormState> addFormKey;
  final TextEditingController addIdController;
  final WarController warController;

  @override
  Widget build(BuildContext context) {
    final targets = context.read<TargetsProvider>().allTargets; // To retrieve existing notes and FF/R
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0.0,
      backgroundColor: Colors.transparent,
      content: Container(
        width: double.maxFinite,
        padding: const EdgeInsets.only(
          top: 45,
          bottom: 16,
          left: 16,
          right: 16,
        ),
        margin: const EdgeInsets.only(top: 30),
        decoration: BoxDecoration(
          color: themeProvider!.secondBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10.0,
              offset: Offset(0.0, 10.0),
            ),
          ],
        ),
        child: Form(
          key: addFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min, // To make the card compact
            children: <Widget>[
              const Text(
                "Add Faction to War",
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 5),
              Text(
                "Press the icon to the right to switch between faction ID or player ID input",
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Flexible(
                    child: TextFormField(
                      style: const TextStyle(fontSize: 14),
                      controller: addIdController,
                      maxLength: 10,
                      minLines: 1,
                      maxLines: 2,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        isDense: true,
                        counterText: "",
                        border: const OutlineInputBorder(),
                        labelText: !warController.addFromUserId ? 'Insert faction ID' : 'Insert user ID',
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return "Cannot be empty!";
                        }
                        final n = num.tryParse(value);
                        if (n == null) {
                          return '$value is not a valid ID!';
                        }
                        addIdController.text = value.trim();
                        return null;
                      },
                    ),
                  ),
                  IconButton(
                    icon: warController.addFromUserId
                        ? Image.asset(
                            'images/icons/faction.png',
                            color: themeProvider!.mainText,
                            width: 16,
                          )
                        : const Icon(Icons.person),
                    onPressed: () {
                      warController.toggleAddFromUserId();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              if (warController.toggleAddUserActive)
                const Padding(
                  padding: EdgeInsets.only(bottom: 5),
                  child: CircularProgressIndicator(),
                ),
              Flexible(
                child: factionCards(),
              ),
              const SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton(
                    child: const Text("Add"),
                    onPressed: () async {
                      if (addFormKey.currentState!.validate()) {
                        warController.setAddUserActive(true);

                        BotToast.showText(
                          clickClose: true,
                          text: "Fetching information, please wait...",
                          textStyle: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                          contentColor: Colors.grey[700]!,
                          duration: const Duration(seconds: 3),
                          contentPadding: const EdgeInsets.all(10),
                        );

                        final FocusScopeNode currentFocus = FocusScope.of(context);
                        if (!currentFocus.hasPrimaryFocus) {
                          currentFocus.unfocus();
                        }
                        // Copy controller's text ot local variable
                        // early and delete the global, so that text
                        // does not appear again in case of failure
                        String inputId = addIdController.text;
                        addIdController.text = '';

                        // If an user ID was inserted, we need to transform it first
                        if (warController.addFromUserId) {
                          final dynamic target = await Get.find<ApiCallerController>().getTarget(playerId: inputId);
                          String convertError = "";
                          if (target is TargetModel) {
                            inputId = target.faction!.factionId.toString();
                            if (inputId == "0") {
                              convertError = "${target.name} does not belong to a faction!";
                            }
                          } else {
                            convertError = "Can't locate the given target!";
                          }

                          if (convertError.isNotEmpty) {
                            BotToast.showText(
                              clickClose: true,
                              text: convertError,
                              textStyle: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                              contentColor: Colors.orange[700]!,
                              duration: const Duration(seconds: 3),
                              contentPadding: const EdgeInsets.all(10),
                            );
                            warController.setAddUserActive(false);
                            return;
                          }
                        }

                        final addFactionResult = (await warController.addFaction(inputId, targets))!;

                        Color? messageColor = Colors.green;
                        if (addFactionResult.isEmpty || addFactionResult == "error_existing") {
                          messageColor = Colors.orange[700];
                        }

                        int time = 5;
                        String message = 'Added $addFactionResult [$inputId]!'
                            '\n\nUpdate members/global to get more information (life, stats).';

                        if (addFactionResult.isEmpty) {
                          message = 'Error adding $inputId';
                          time = 3;
                        } else if (addFactionResult == "error_existing") {
                          message = 'Faction $inputId is already in the list!';
                          time = 3;
                        }

                        BotToast.showText(
                          clickClose: true,
                          text: message,
                          textStyle: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                          contentColor: messageColor!,
                          duration: Duration(seconds: time),
                          contentPadding: const EdgeInsets.all(10),
                        );
                        warController.setAddUserActive(false);
                      }
                    },
                  ),
                  TextButton(
                    child: const Text("Close"),
                    onPressed: () {
                      Navigator.of(context).pop();
                      addIdController.text = '';
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget factionCards() {
    List<Widget> factionCards = <Widget>[];
    for (final FactionModel faction in warController.factions) {
      factionCards.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () {
                warController.filterFaction(faction.id);
              },
              child: Icon(
                Icons.remove_red_eye_outlined,
                color: faction.hidden! ? Colors.red : themeProvider!.mainText,
              ),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Card(
                color: themeProvider!.cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text(
                        HtmlParser.fix(faction.name),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        "[${faction.id}]",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 5),
            GestureDetector(
              onTap: () {
                warController.removeFaction(faction.id);
              },
              child: const Icon(Icons.delete_forever_outlined),
            ),
          ],
        ),
      );
    }
    return ListView(shrinkWrap: true, children: factionCards);
  }
}

class HiddenMembersDialog extends StatelessWidget {
  const HiddenMembersDialog({
    super.key,
    required this.themeProvider,
    required this.warController,
  });

  final ThemeProvider? themeProvider;
  final WarController warController;

  @override
  Widget build(BuildContext context) {
    final List<Member?> hiddenMembers = warController.getHiddenMembersDetails();
    List<Widget> hiddenCards = buildCards(hiddenMembers, context);
    return AlertDialog(
      backgroundColor: themeProvider!.secondBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      actions: [
        TextButton(
          child: const Text("Close"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
      elevation: 0.0,
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Reset hidden targets",
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: hiddenCards,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> buildCards(List<Member?> hiddenMembers, BuildContext context) {
    List<Widget> hiddenCards = <Widget>[];
    for (final Member? m in hiddenMembers) {
      hiddenCards.add(
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: () {
                warController.unhideMember(m);
                if (warController.getHiddenMembersNumber() == 0) {
                  Navigator.of(context).pop();
                }
              },
            ),
            Expanded(
              child: Card(
                color: themeProvider!.cardColor,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 3, 8, 3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            m!.name!,
                            style: const TextStyle(fontSize: 13),
                          ),
                          Text(
                            "Level ${m.level}",
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Image.asset(
                            'images/icons/faction.png',
                            width: 11,
                            height: 11,
                            color: themeProvider!.mainText,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            m.factionName!,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return hiddenCards;
  }
}

class WarTargetsList extends StatefulWidget {
  const WarTargetsList({
    required this.warController,
    required this.offlineSelector,
    required this.okayFilterActive,
    required this.countryFilterActive,
    required this.travelingFilterActive,
  });

  final WarController warController;
  final int offlineSelector;
  final bool okayFilterActive;
  final bool countryFilterActive;
  final bool travelingFilterActive;

  @override
  State<WarTargetsList> createState() => WarTargetsListState();
}

class WarTargetsListState extends State<WarTargetsList> {
  late ChainStatusProvider _chainStatusProvider;

  @override
  void initState() {
    super.initState();
    _chainStatusProvider = Provider.of<ChainStatusProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    List<WarCard> filteredCards = getChildrenTarget();

    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      return ListView.builder(
        shrinkWrap: true,
        itemCount: filteredCards.length,
        itemBuilder: (context, index) {
          return SlidableCard(filteredCards[index]);
        },
      );
    } else {
      return ListView.builder(
        shrinkWrap: true,
        itemCount: filteredCards.length,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return SlidableCard(filteredCards[index]);
        },
      );
    }
  }

  List<WarCard> getChildrenTarget() {
    List<Member?> members = <Member?>[];
    List<WarCard> filteredCards = <WarCard>[];

    for (final faction in widget.warController.factions) {
      if (!faction.hidden!) {
        faction.members!.forEach((key, value) {
          value!.memberId = int.parse(key);
          value.factionName = faction.name;
          value.factionLeader = faction.leader;
          value.factionColeader = faction.coLeader;
          members.add(value);
        });
      }
    }

    for (final Member? thisMember in members) {
      if (thisMember!.hidden!) continue;
      if (thisMember.status!.state!.contains("Federal") && thisMember.status!.state!.contains("Fallen")) continue;

      if ((thisMember.lastAction!.status!.contains("Online") || thisMember.lastAction!.status!.contains("Idle")) &&
          widget.offlineSelector == 2) {
        continue;
      }

      if (thisMember.lastAction!.status!.contains("Offline") && widget.offlineSelector == 1) {
        continue;
      }

      if (widget.okayFilterActive && thisMember.status!.color == "red") {
        continue;
      }

      if (widget.countryFilterActive &&
          countryCheck(
                state: thisMember.status!.state,
                description: thisMember.status!.description,
              ) !=
              widget.warController.playerLocation) {
        continue;
      }

      if (widget.travelingFilterActive && travelingCheck(state: thisMember.status!.state)) {
        continue;
      }

      filteredCards.add(WarCard(memberModel: thisMember));
    }

    switch (widget.warController.currentSort) {
      case WarSortType.levelDes:
        filteredCards.sort((a, b) => b.memberModel!.level!.compareTo(a.memberModel!.level!));
      case WarSortType.levelAsc:
        filteredCards.sort((a, b) => a.memberModel!.level!.compareTo(b.memberModel!.level!));
      case WarSortType.respectDes:
        filteredCards.sort((a, b) => b.memberModel!.respectGain!.compareTo(a.memberModel!.respectGain!));
      case WarSortType.respectAsc:
        filteredCards.sort((a, b) => a.memberModel!.respectGain!.compareTo(b.memberModel!.respectGain!));
      case WarSortType.nameDes:
        filteredCards.sort((a, b) => b.memberModel!.name!.toLowerCase().compareTo(a.memberModel!.name!.toLowerCase()));
      case WarSortType.nameAsc:
        filteredCards.sort((a, b) => a.memberModel!.name!.toLowerCase().compareTo(b.memberModel!.name!.toLowerCase()));
      case WarSortType.lifeDes:
        filteredCards.sort((a, b) => b.memberModel!.lifeSort!.compareTo(a.memberModel!.lifeSort!));
      case WarSortType.lifeAsc:
        filteredCards.sort((a, b) => a.memberModel!.lifeSort!.compareTo(b.memberModel!.lifeSort!));
      case WarSortType.statsDes:
        filteredCards.sort((a, b) => b.memberModel!.statsSort!.compareTo(a.memberModel!.statsSort!));
      case WarSortType.statsAsc:
        filteredCards.sort((a, b) => a.memberModel!.statsSort!.compareTo(b.memberModel!.statsSort!));
      case WarSortType.onlineDes:
        filteredCards
            .sort((a, b) => b.memberModel!.lastAction!.timestamp!.compareTo(a.memberModel!.lastAction!.timestamp!));
      case WarSortType.onlineAsc:
        filteredCards
            .sort((a, b) => a.memberModel!.lastAction!.timestamp!.compareTo(b.memberModel!.lastAction!.timestamp!));
      case WarSortType.colorDes:
        filteredCards.sort(
          (a, b) => b.memberModel!.personalNoteColor!
              .toLowerCase()
              .compareTo(a.memberModel!.personalNoteColor!.toLowerCase()),
        );
      case WarSortType.colorAsc:
        filteredCards.sort(
          (a, b) => a.memberModel!.personalNoteColor!
              .toLowerCase()
              .compareTo(b.memberModel!.personalNoteColor!.toLowerCase()),
        );
      case WarSortType.notesDes:
        filteredCards.sort(
          (a, b) => b.memberModel!.personalNote!.toLowerCase().compareTo(a.memberModel!.personalNote!.toLowerCase()),
        );
      case WarSortType.notesAsc:
        filteredCards.sort((a, b) {
          if (a.memberModel!.personalNote!.isEmpty && b.memberModel!.personalNote!.isNotEmpty) {
            return 1;
          } else if (a.memberModel!.personalNote!.isNotEmpty && b.memberModel!.personalNote!.isEmpty) {
            return -1;
          } else if (a.memberModel!.personalNote!.isEmpty && b.memberModel!.personalNote!.isEmpty) {
            return 0;
          } else {
            return a.memberModel!.personalNote!.toLowerCase().compareTo(b.memberModel!.personalNote!.toLowerCase());
          }
        });
      default:
        filteredCards.sort((a, b) => a.memberModel!.name!.toLowerCase().compareTo(b.memberModel!.name!.toLowerCase()));
        break;
    }

    widget.warController.orderedCardsDetails.clear();
    for (int i = 0; i < filteredCards.length; i++) {
      final WarCardDetails details = WarCardDetails()
        ..cardPosition = i + 1
        ..memberId = filteredCards[i].memberModel!.memberId
        ..name = filteredCards[i].memberModel!.name
        ..personalNote = filteredCards[i].memberModel!.personalNote
        ..personalNoteColor = filteredCards[i].memberModel!.personalNoteColor;

      widget.warController.orderedCardsDetails.add(details);
    }

    return filteredCards;
  }

  Widget SlidableCard(WarCard filteredCard) {
    return Slidable(
      closeOnScroll: false,
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            label: 'Hide',
            backgroundColor: Colors.blue,
            icon: Icons.delete,
            onPressed: (context) {
              widget.warController.hideMember(filteredCard.memberModel);
            },
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          if (_chainStatusProvider.panicTargets.where((t) => t.name == filteredCard.memberModel!.name).isEmpty)
            SlidableAction(
              label: 'Add to panic!',
              backgroundColor: Colors.blue,
              icon: MdiIcons.alphaPCircleOutline,
              onPressed: (context) {
                String message = "Added ${filteredCard.memberModel!.name} as a Panic Mode target!";
                Color? messageColor = Colors.green;

                if (_chainStatusProvider.panicTargets.length < 10) {
                  setState(() {
                    _chainStatusProvider.addPanicTarget(
                      PanicTargetModel()
                        ..name = filteredCard.memberModel!.name
                        ..level = filteredCard.memberModel!.level
                        ..id = filteredCard.memberModel!.memberId
                        ..factionName = filteredCard.memberModel!.factionName,
                    );
                    // Convert to target with the needed fields
                  });
                } else {
                  message = "There are already 10 targets in the Panic Mode list, remove some!";
                  messageColor = Colors.orange[700];
                }

                BotToast.showText(
                  clickClose: true,
                  text: message,
                  textStyle: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  contentColor: messageColor!,
                  duration: const Duration(seconds: 5),
                  contentPadding: const EdgeInsets.all(10),
                );
              },
            )
          else
            SlidableAction(
              label: 'PANIC TARGET',
              backgroundColor: Colors.blue,
              icon: MdiIcons.alphaPCircleOutline,
              onPressed: (context) {
                final String message = "Removed ${filteredCard.memberModel!.name} as a Panic Mode target!";
                const Color messageColor = Colors.green;

                setState(() {
                  _chainStatusProvider.removePanicTarget(
                    PanicTargetModel()
                      ..name = filteredCard.memberModel!.name
                      ..level = filteredCard.memberModel!.level
                      ..id = filteredCard.memberModel!.memberId
                      ..factionName = filteredCard.memberModel!.factionName,
                  );
                });

                BotToast.showText(
                  clickClose: true,
                  text: message,
                  textStyle: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  contentColor: messageColor,
                  duration: const Duration(seconds: 5),
                  contentPadding: const EdgeInsets.all(10),
                );
              },
            ),
        ],
      ),
      child: filteredCard,
    );
  }
}
