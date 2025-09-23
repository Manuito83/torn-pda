// Dart imports:
import 'dart:async';
import 'dart:io';

// Package imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:torn_pda/drawer.dart';
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/chaining/chain_panic_target_model.dart';
import 'package:torn_pda/models/chaining/target_model.dart';
// Project imports:
import 'package:torn_pda/models/chaining/war_sort.dart';
import 'package:torn_pda/models/faction/faction_model.dart';
import 'package:torn_pda/pages/chaining/ranked_wars_page.dart';
import 'package:torn_pda/providers/api/api_v1_calls.dart';
import 'package:torn_pda/providers/chain_status_controller.dart';
import 'package:torn_pda/providers/player_notes_controller.dart';
import 'package:torn_pda/providers/player_notes_controller.dart' show PlayerNoteColor;
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/spies_controller.dart';
import 'package:torn_pda/providers/targets_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/war_controller.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/country_check.dart';
import 'package:torn_pda/utils/html_parser.dart';
import 'package:torn_pda/widgets/chaining/chain_widget.dart';
import 'package:torn_pda/widgets/chaining/share_stats_dialog.dart';
import 'package:torn_pda/widgets/chaining/war_card.dart';
import 'package:torn_pda/widgets/revive/hela_revive_button.dart';
import 'package:torn_pda/widgets/revive/midnightx_revive_button.dart';
import 'package:torn_pda/widgets/revive/nuke_revive_button.dart';
import 'package:torn_pda/widgets/revive/uhc_revive_button.dart';
import 'package:torn_pda/widgets/revive/wtf_revive_button.dart';
import 'package:torn_pda/widgets/spies/spies_management_dialog.dart';
import 'package:torn_pda/widgets/pda_browser_icon.dart';

class WarOptions {
  String? description;
  IconData? iconData;

  WarOptions({this.description}) {
    switch (description) {
      case "Manage Spies":
        iconData = MdiIcons.incognito;
      case "Share stats":
      // Own icon in widget
      case "Hidden targets":
        iconData = Icons.undo_outlined;
      case "Nuke revive":
        // Own icon in widget
        break;
      case "UHC revive":
        // Own icon in widget
        break;
      case "HeLa revive":
        // Own icon in widget
        break;
      case "WTF revive":
        // Own icon in widget
        break;
      case "Midnight X revive":
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

  Timer? _updatedTicker;

  final WarController _w = Get.find<WarController>();
  ThemeProvider? _themeProvider;
  SettingsProvider? _settingsProvider;
  late WebViewProvider _webViewProvider;

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
    WarSort(type: WarSortType.hospitalDes),
    WarSort(type: WarSortType.hospitalAsc),
    WarSort(type: WarSortType.statsDes),
    WarSort(type: WarSortType.statsAsc),
    WarSort(type: WarSortType.onlineDes),
    WarSort(type: WarSortType.onlineAsc),
    WarSort(type: WarSortType.colorAsc),
    WarSort(type: WarSortType.colorDes),
    WarSort(type: WarSortType.notesDes),
    WarSort(type: WarSortType.notesAsc),
    WarSort(type: WarSortType.bounty),
    WarSort(type: WarSortType.travelDistanceDesc),
    WarSort(type: WarSortType.travelDistanceAsc),
  ];

  final _popupOptionsChoices = <WarOptions>[
    WarOptions(description: "Manage Spies"),
    WarOptions(description: "Share stats"),
    WarOptions(description: "Hidden targets"),
    WarOptions(description: "Nuke revive"),
    WarOptions(description: "UHC revive"),
    WarOptions(description: "HeLa revive"),
    WarOptions(description: "WTF revive"),
    WarOptions(description: "Midnight X revive"),
  ];

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    _performQuickUpdate(firstTime: true);

    _updatedTicker = Timer.periodic(const Duration(seconds: 30), (Timer t) => _w.assessPendingNotifications());

    routeWithDrawer = true;
    routeName = "chaining_war";
  }

  @override
  Future dispose() async {
    _addIdController.dispose();
    _searchController.dispose();
    _updatedTicker?.cancel();
    _w.stopUpdate();
    Get.delete<WarController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context);
    _webViewProvider = Provider.of<WebViewProvider>(context);

    return ShowCaseWidget(
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
          drawer: !_webViewProvider.splitScreenAndBrowserLeft() ? const Drawer() : null,
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
              child: MediaQuery.orientationOf(context) == Orientation.portrait
                  ? _mainColumn()
                  : SingleChildScrollView(
                      child: _mainColumn(),
                    ),
            ),
          ),
        );
      },
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
                _okayRedFilter(w),
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
                  okayRedFilterActive: w.okayRedFilter,
                  countryFilterActive: w.countryFilter,
                  abroadFilterActive: w.abroadFilter,
                ),
              )
            else
              WarTargetsList(
                warController: w,
                offlineSelector: w.onlineFilter,
                okayRedFilterActive: w.okayRedFilter,
                countryFilterActive: w.countryFilter,
                abroadFilterActive: w.abroadFilter,
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
          await _performQuickUpdate(forceIntegrityCheck: false);

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

  Widget _okayRedFilter(WarController w) {
    return SizedBox(
      height: 25,
      child: ToggleSwitch(
        customWidths: const [32, 32],
        borderWidth: 1,
        cornerRadius: 5,
        doubleTapDisable: true,
        borderColor: _themeProvider!.currentTheme == AppTheme.light ? [Colors.blueGrey] : [Colors.grey[900]!],
        initialLabelIndex: _w.okayRedFilter == 0
            ? null
            : _w.okayRedFilter == 1
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
        customIcons: [
          const Icon(
            MdiIcons.check,
            size: 12,
            color: Colors.green,
          ),
          const Icon(
            MdiIcons.hospital,
            size: 12,
            color: Colors.red,
          ),
        ],
        onToggle: (index) async {
          await _performQuickUpdate(forceIntegrityCheck: false);

          if (index == null) {
            _w.setOkayRedFilter(0);
          } else if (index == 0) {
            _w.setOkayRedFilter(1);
          } else if (index == 1) {
            _w.setOkayRedFilter(2);
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
        customIcons: [
          const Icon(
            MdiIcons.mapMarker,
            size: 12,
          ),
        ],
        onToggle: (index) async {
          await _performQuickUpdate(forceIntegrityCheck: false);

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
        customWidths: const [32, 32],
        borderWidth: 1,
        cornerRadius: 5,
        doubleTapDisable: true,
        borderColor: _themeProvider!.currentTheme == AppTheme.light ? [Colors.blueGrey] : [Colors.grey[900]!],
        initialLabelIndex: _w.abroadFilter == 0
            ? null
            : _w.abroadFilter == 1
                ? 0
                : 1,
        activeBgColor: _w.abroadFilter == 1
            ? _themeProvider!.currentTheme == AppTheme.light
                ? [Colors.blue[200]!]
                : _themeProvider!.currentTheme == AppTheme.dark
                    ? [Colors.blue[500]!]
                    : [Colors.blue[900]!]
            : _themeProvider!.currentTheme == AppTheme.light
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
        totalSwitches: 2,
        animate: true,
        animationDuration: 500,
        customIcons: [
          const Icon(
            MdiIcons.airplane,
            size: 12,
          ),
          const Icon(
            MdiIcons.airplaneOff,
            size: 12,
          ),
        ],
        onToggle: (index) async {
          await _performQuickUpdate(forceIntegrityCheck: false);

          if (index == null) {
            _w.setTravelingFilterStatus(0);
          } else if (index == 0) {
            _w.setTravelingFilterStatus(1);
          } else if (index == 1) {
            _w.setTravelingFilterStatus(2);
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
        customIcons: [
          Icon(
            MdiIcons.linkVariant,
            color: w.showChainWidget
                ? Colors.white
                : _themeProvider!.currentTheme != AppTheme.light
                    ? Colors.white
                    : Colors.black,
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
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: _settingsProvider!.appBarTop ? 2 : 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      title: const Text("War", style: TextStyle(color: Colors.white)),
      leadingWidth: _webViewProvider.webViewSplitActive ? 50 : 88,
      leading: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              final ScaffoldState? scaffoldState = context.findRootAncestorStateOfType();
              if (scaffoldState != null) {
                if (_webViewProvider.splitScreenAndBrowserLeft()) {
                  scaffoldState.openEndDrawer();
                } else {
                  scaffoldState.openDrawer();
                }
              }
            },
          ),
          if (!_webViewProvider.webViewSplitActive) const PdaBrowserIcon(),
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
          textColor: _themeProvider!.mainText,
          tooltipBackgroundColor: _themeProvider!.secondBackground,
          descTextStyle: const TextStyle(fontSize: 13),
          tooltipPadding: const EdgeInsets.all(20),
          child: IconButton(
            icon: Image.asset(
              'images/icons/faction_add.png',
              width: 20,
              height: 20,
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
          textColor: _themeProvider!.mainText,
          tooltipBackgroundColor: _themeProvider!.secondBackground,
          descTextStyle: const TextStyle(fontSize: 13),
          tooltipPadding: const EdgeInsets.all(20),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(3, 0, 6, 0),
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
                            text: "Updating $allMembers war targets, this might take a while. Extra time needed to "
                                "avoid issues with API request limits!",
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
                        // This might have changed if new members are added with integrityCheck()
                        allMembers = result[0];
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
                child: Row(
                  children: [
                    if (_w.currentSort == choice.type)
                      Padding(
                        padding: const EdgeInsets.only(right: 5),
                        child: Icon(
                          Icons.arrow_forward_ios_outlined,
                          color: _themeProvider!.mainText,
                          size: 15,
                        ),
                      ),
                    Flexible(
                      child: Text(
                        choice.description,
                        style: const TextStyle(
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList();
          },
        ),
        PopupMenuButton<WarOptions>(
          icon: const Icon(Icons.settings),
          onSelected: (selection) {
            switch (selection.description) {
              case "Manage Spies":
                showDialog(
                  barrierDismissible: false,
                  useRootNavigator: false,
                  context: context,
                  builder: (BuildContext context) {
                    return SpiesManagementDialog();
                  },
                );
                break;
              case "Share stats":
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return ShareStatsDialog();
                  },
                );
                break;
              case "Hidden targets":
                _showHiddenMembersDialogs(context);
                break;
              case "Nuke revive":
                openNukeReviveDialog(context, _themeProvider!, null);
              case "UHC revive":
                openUhcReviveDialog(context, _themeProvider!, null);
              case "HeLa revive":
                openHelaReviveDialog(context, _themeProvider!, null);
              case "WTF revive":
                openWtfReviveDialog(context, _themeProvider!, null);
              case "Midnight X revive":
                openMidnightXReviveDialog(context, _themeProvider!, null);
            }
          },
          itemBuilder: (BuildContext context) {
            final spyController = Get.find<SpiesController>();
            String lastUpdated = "Never updated";
            int lastUpdatedTs = 0;

            if (spyController.spiesSource == SpiesSource.yata && spyController.yataSpiesTime != null) {
              lastUpdatedTs = spyController.yataSpiesTime!.millisecondsSinceEpoch;
              if (lastUpdatedTs > 0) {
                lastUpdated = spyController.statsOld((lastUpdatedTs / 1000).round());
              }
            } else if (spyController.spiesSource == SpiesSource.tornStats && spyController.tornStatsSpiesTime != null) {
              lastUpdatedTs = spyController.tornStatsSpiesTime!.millisecondsSinceEpoch;
              if (lastUpdatedTs > 0) {
                lastUpdated = spyController.statsOld((lastUpdatedTs / 1000).round());
              }
            }

            Color spiesUpdateColor = Colors.blue;
            if (lastUpdatedTs > 0) {
              final currentTime = DateTime.now().millisecondsSinceEpoch;
              final oneMonthAgo = currentTime - (30.44 * 24 * 60 * 60 * 1000).round();
              spiesUpdateColor = (lastUpdatedTs < oneMonthAgo) ? Colors.red : _themeProvider!.mainText;
            }

            return _popupOptionsChoices.where((WarOptions choice) {
              // Don't return hidden members option if there is none
              if (choice.description!.contains("Hidden") && _w.getHiddenMembersNumber() == 0) {
                return false;
              }
              // Revives
              if (choice.description!.contains("Nuke") && !_w.nukeReviveActive) {
                return false;
              }
              if (choice.description!.contains("UHC") && !_w.uhcReviveActive) {
                return false;
              }
              if (choice.description!.contains("HeLa") && !_w.helaReviveActive) {
                return false;
              }
              if (choice.description!.contains("WTF") && !_w.wtfReviveActive) {
                return false;
              }
              if (choice.description!.contains("Midnight X") && !_w.midnightXReviveActive) {
                return false;
              }
              return true;
            }).map((WarOptions choice) {
              // Spies
              if (choice.description!.contains("Manage Spies")) {
                return PopupMenuItem<WarOptions>(
                  value: choice,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 13),
                        child: Icon(
                          MdiIcons.incognito,
                          size: 24,
                          color: _themeProvider!.mainText,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text("Manage Spies"),
                                const SizedBox(width: 8),
                                SizedBox(
                                  height: 25,
                                  width: 25,
                                  child: Image.asset(
                                    spyController.spiesSource == SpiesSource.yata
                                        ? 'images/icons/yata_logo.png'
                                        : 'images/icons/tornstats_logo.png',
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              lastUpdated,
                              style: TextStyle(fontSize: 11, color: spiesUpdateColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
              // Share stats
              if (choice.description!.contains("Share stats")) {
                return PopupMenuItem<WarOptions>(
                  value: choice,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 13),
                        child: Icon(
                          Icons.share,
                          size: 24,
                          color: _themeProvider!.mainText,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Flexible(child: Text("Share stats")),
                    ],
                  ),
                );
              }
              // Reviving services
              if (choice.description!.contains("Nuke")) {
                return PopupMenuItem<WarOptions>(
                  value: choice,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 13),
                        child: Image.asset('images/icons/nuke-revive.png', width: 24),
                      ),
                      const SizedBox(width: 10),
                      const Flexible(child: Text("Request a revive (Nuke)")),
                    ],
                  ),
                );
              }
              if (choice.description!.contains("UHC")) {
                return PopupMenuItem<WarOptions>(
                  value: choice,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 13),
                        child: Image.asset('images/icons/uhc_revive.png', width: 24),
                      ),
                      const SizedBox(width: 10),
                      const Flexible(child: Text("Request a revive (UHC)")),
                    ],
                  ),
                );
              }
              if (choice.description!.contains("HeLa")) {
                return PopupMenuItem<WarOptions>(
                  value: choice,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 13),
                        child: Image.asset('images/icons/hela_revive.png', width: 24),
                      ),
                      const SizedBox(width: 10),
                      const Flexible(child: Text("Request a revive (HeLa)")),
                    ],
                  ),
                );
              }
              if (choice.description!.contains("WTF")) {
                return PopupMenuItem<WarOptions>(
                  value: choice,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 13),
                        child: Image.asset('images/icons/wtf_revive.png', width: 24),
                      ),
                      const SizedBox(width: 10),
                      const Flexible(child: Text("Request a revive (WTF)")),
                    ],
                  ),
                );
              }
              if (choice.description!.contains("Midnight X")) {
                return PopupMenuItem<WarOptions>(
                  value: choice,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 13),
                        child: Image.asset('images/icons/midnightx_revive.png', width: 24),
                      ),
                      const SizedBox(width: 10),
                      const Flexible(child: Text("Request a revive (Midnight X)")),
                    ],
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
            }).toList();
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
          },
        ),
      ],
    );
  }

  Future<void> _performQuickUpdate({bool firstTime = false, bool forceIntegrityCheck = true}) async {
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

      final int updatedMembers = await _w.updateAllMembersEasy(forceIntegrityCheck: forceIntegrityCheck);

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

      bool additionalSortingIssue = false;
      String sort = "";
      if (_w.currentSort == WarSortType.lifeAsc) {
        additionalSortingIssue = true;
        sort = "Life Ascending";
      } else if (_w.currentSort == WarSortType.lifeDes) {
        additionalSortingIssue = true;
        sort = "Life Descending";
      } else if (_w.currentSort == WarSortType.bounty) {
        additionalSortingIssue = true;
        sort = "Bounty Amount";
      }

      if (additionalSortingIssue) {
        if (!firstTime) {
          message += "\n\nNOTE: your current SORT selection ($sort) requires a FULL UPDATE (LONG-PRESS) to retrieve "
              "the necessary details!";
        } else {
          message = "Your current SORT selection ($sort) requires a FULL UPDATE (LONG-PRESS) to retrieve "
              "the necessary details!";
        }
      }

      // Triggers after a normal quick update (with or without sorting issues), or during the first-time check
      // but only if there's a sorting issue
      if (mounted && (!firstTime || (firstTime && additionalSortingIssue))) {
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
      if (!Platform.isWindows) FirebaseCrashlytics.instance.log("PDA Crash at War Quick Update");
      if (!Platform.isWindows) FirebaseCrashlytics.instance.recordError("PDA Error: $e", trace);
      logToUser("PDA Error at War Quick Update: $e, $trace");
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
      case WarSortType.hospitalDes:
        _w.sortTargets(WarSortType.hospitalDes);
      case WarSortType.hospitalAsc:
        _w.sortTargets(WarSortType.hospitalAsc);
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
      case WarSortType.bounty:
        _w.sortTargets(WarSortType.bounty);
      case WarSortType.travelDistanceDesc:
        _w.sortTargets(WarSortType.travelDistanceDesc);
      case WarSortType.travelDistanceAsc:
        _w.sortTargets(WarSortType.travelDistanceAsc);
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
                          final dynamic target = await ApiCallsV1.getTarget(playerId: inputId);
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
    required this.okayRedFilterActive,
    required this.countryFilterActive,
    required this.abroadFilterActive,
  });

  final WarController warController;
  final int offlineSelector;
  final int okayRedFilterActive;
  final bool countryFilterActive;
  final int abroadFilterActive;

  @override
  State<WarTargetsList> createState() => WarTargetsListState();
}

class WarTargetsListState extends State<WarTargetsList> {
  final ChainStatusController _chainStatusProvider = Get.find<ChainStatusController>();

  @override
  Widget build(BuildContext context) {
    List<WarCard> filteredCards = getChildrenTarget();

    // Count pinned members to add separator
    final pinnedMembersCount = filteredCards.where((member) => member.memberModel.pinned).length;
    Widget separator = const Row(
      children: [
        Flexible(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 5, horizontal: 30),
            child: Divider(color: Colors.grey),
          ),
        ),
        Text("UNPINNED", style: TextStyle(fontSize: 12, color: Colors.grey)),
        Flexible(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 5, horizontal: 30),
            child: Divider(color: Colors.grey),
          ),
        ),
      ],
    );

    final orientationPortrait = MediaQuery.orientationOf(context) == Orientation.portrait;
    return ListView.builder(
      shrinkWrap: true,
      itemCount: filteredCards.length,
      physics: orientationPortrait ? null : const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        if (index == pinnedMembersCount && index != 0) {
          // Add the first unpinned card preceded by the separator
          return Column(
            children: [
              separator,
              slidableCard(filteredCards[index]),
            ],
          );
        }
        return slidableCard(filteredCards[index]);
      },
    );
  }

  List<WarCard> getChildrenTarget() {
    List<Member?> members = <Member?>[];
    List<WarCard> filteredCards = <WarCard>[];

    List<WarCard> pinnedMembers = [];
    List<WarCard> nonPinnedMembers = [];

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

      if (widget.okayRedFilterActive == 1 && thisMember.status!.color == "red") {
        continue;
      }

      if (widget.okayRedFilterActive == 2 && thisMember.status!.color != "red") {
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

      // Filter out not traveling
      if (widget.abroadFilterActive == 1) {
        if (countryCheck(state: thisMember.status!.state, description: thisMember.status!.description) == "Torn" &&
            !isTraveling(state: thisMember.status!.state)) {
          continue;
        }
      }

      // Filter out traveling
      if (widget.abroadFilterActive == 2) {
        if (countryCheck(state: thisMember.status!.state, description: thisMember.status!.description) != "Torn" ||
            isTraveling(state: thisMember.status!.state)) {
          continue;
        }
      }

      //filteredCards.add(WarCard(memberModel: thisMember));
      if (thisMember.pinned) {
        pinnedMembers.add(
          WarCard(memberModel: thisMember),
        );
      } else {
        nonPinnedMembers.add(
          WarCard(memberModel: thisMember),
        );
      }
    }

    // Apply sorting to both lists
    widget.warController.sortWarCards(pinnedMembers);
    widget.warController.sortWarCards(nonPinnedMembers);

    // Combine the sorted lists
    filteredCards = [...pinnedMembers, ...nonPinnedMembers];

    widget.warController.orderedCardsDetails.clear();
    for (int i = 0; i < filteredCards.length; i++) {
      final playerNotesController = Get.find<PlayerNotesController>();
      final playerNote = playerNotesController.getNoteForPlayer(filteredCards[i].memberModel.memberId.toString());

      final WarCardDetails details = WarCardDetails()
        ..cardPosition = i + 1
        ..memberId = filteredCards[i].memberModel.memberId
        ..name = filteredCards[i].memberModel.name
        ..personalNote = playerNote?.note ?? ''
        ..personalNoteColor = playerNote?.color ?? PlayerNoteColor.none;

      widget.warController.orderedCardsDetails.add(details);
    }

    return filteredCards;
  }

  Widget slidableCard(WarCard filteredCard) {
    return Slidable(
      key: ValueKey(filteredCard.memberModel.memberId),
      closeOnScroll: false,
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            label: 'Hide',
            backgroundColor: Colors.grey,
            icon: Icons.delete,
            onPressed: (context) {
              widget.warController.hideMember(filteredCard.memberModel);
            },
          ),
          SlidableAction(
            label: filteredCard.memberModel.pinned ? 'Unpin' : 'Pin',
            backgroundColor: Colors.green[800]!,
            icon: filteredCard.memberModel.pinned ? MdiIcons.pinOffOutline : MdiIcons.pinOutline,
            onPressed: (context) {
              if (filteredCard.memberModel.pinned) {
                widget.warController.unpinMember(filteredCard.memberModel);
              } else {
                widget.warController.pinMember(filteredCard.memberModel);
              }
            },
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          if (_chainStatusProvider.panicTargets.where((t) => t.name == filteredCard.memberModel.name).isEmpty)
            SlidableAction(
              label: 'Add to panic!',
              backgroundColor: Colors.blue,
              icon: MdiIcons.alphaPCircleOutline,
              onPressed: (context) {
                String message = "Added ${filteredCard.memberModel.name} as a Panic Mode target!";
                Color? messageColor = Colors.green;

                if (_chainStatusProvider.panicTargets.length < 10) {
                  setState(() {
                    _chainStatusProvider.addPanicTarget(
                      PanicTargetModel()
                        ..name = filteredCard.memberModel.name
                        ..level = filteredCard.memberModel.level
                        ..id = filteredCard.memberModel.memberId
                        ..factionName = filteredCard.memberModel.factionName,
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
                final String message = "Removed ${filteredCard.memberModel.name} as a Panic Mode target!";
                const Color messageColor = Colors.green;

                setState(() {
                  _chainStatusProvider.removePanicTarget(
                    PanicTargetModel()
                      ..name = filteredCard.memberModel.name
                      ..level = filteredCard.memberModel.level
                      ..id = filteredCard.memberModel.memberId
                      ..factionName = filteredCard.memberModel.factionName,
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
