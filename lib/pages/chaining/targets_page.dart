// Dart imports:
import 'dart:async';

// Package imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:get/get.dart';
// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/drawer.dart';
// Project imports:
import 'package:torn_pda/models/chaining/target_sort.dart';
import 'package:torn_pda/models/chaining/yata/yata_distribution_models.dart';
import 'package:torn_pda/models/chaining/yata/yata_targets_import.dart';
import 'package:torn_pda/pages/chaining/targets_backup_page.dart';
import 'package:torn_pda/pages/chaining/targets_options_page.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/targets_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/providers/player_notes_controller.dart';
import 'package:torn_pda/widgets/chaining/chain_widget.dart';
import 'package:torn_pda/widgets/chaining/color_filter_dialog.dart';
import 'package:torn_pda/widgets/chaining/targets_list.dart';
import 'package:torn_pda/widgets/chaining/yata/yata_targets_dialog.dart';
import 'package:torn_pda/widgets/pda_browser_icon.dart';

class TargetsOptions {
  String? description;
  IconData? iconData;

  TargetsOptions({this.description}) {
    switch (description) {
      case "Options":
        iconData = Icons.settings;
      case "Filter Color":
        iconData = Icons.filter_list;
      case "Backup":
        iconData = Icons.save;
      case "Wipe":
        iconData = Icons.delete_forever_outlined;
    }
  }
}

class TargetsPage extends StatefulWidget {
  final Function retaliationCallback;
  //final Function tabCallback;

  const TargetsPage({
    super.key,
    required this.retaliationCallback,
    //@required this.tabCallback,
  });

  @override
  TargetsPageState createState() => TargetsPageState();
}

class TargetsPageState extends State<TargetsPage> {
  final _searchController = TextEditingController();
  final _addIdController = TextEditingController();

  final _addFormKey = GlobalKey<FormState>();

  Future? _preferencesLoaded;

  final _chainWidgetKey = GlobalKey();

  late TargetsProvider _targetsProvider;
  late ThemeProvider _themeProvider;
  late SettingsProvider _settingsProvider;
  late WebViewProvider _webViewProvider;

  // For appBar search
  Icon _searchIcon = const Icon(Icons.search);
  Widget _appBarText = const Text("Targets");
  final _focusSearch = FocusNode();

  /// Strictly whether we button is enabled in options
  bool _yataButtonInProgress = true;

  /// Dictates if it has been pressed and is showing a circular
  /// progress indicator while fetching data from Yata
  bool? _yataButtonEnabled = true;

  final _popupSortChoices = <TargetSort>[
    TargetSort(type: TargetSortType.levelDes),
    TargetSort(type: TargetSortType.levelAsc),
    TargetSort(type: TargetSortType.respectDes),
    TargetSort(type: TargetSortType.respectAsc),
    TargetSort(type: TargetSortType.ffDes),
    TargetSort(type: TargetSortType.ffAsc),
    TargetSort(type: TargetSortType.nameDes),
    TargetSort(type: TargetSortType.nameAsc),
    TargetSort(type: TargetSortType.lifeDes),
    TargetSort(type: TargetSortType.lifeAsc),
    TargetSort(type: TargetSortType.hospitalDes),
    TargetSort(type: TargetSortType.hospitalAsc),
    TargetSort(type: TargetSortType.onlineAsc),
    TargetSort(type: TargetSortType.onlineDes),
    TargetSort(type: TargetSortType.colorAsc),
    TargetSort(type: TargetSortType.colorDes),
    TargetSort(type: TargetSortType.notesDes),
    TargetSort(type: TargetSortType.notesAsc),
    TargetSort(type: TargetSortType.bounty),
    TargetSort(type: TargetSortType.timeAddedDes),
    TargetSort(type: TargetSortType.timeAddedAsc),
  ];

  final _popupOptionsChoices = <TargetsOptions>[
    TargetsOptions(description: "Options"),
    TargetsOptions(description: "Filter Color"),
    TargetsOptions(description: "Backup"),
    TargetsOptions(description: "Wipe"),
  ];

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _preferencesLoaded = _restorePreferences();
    _searchController.addListener(onSearchInputTextChange);
    // Reset the filter so that we get all the targets
    SchedulerBinding.instance.addPostFrameCallback((_) {
      Provider.of<TargetsProvider>(context, listen: false).setFilterText('');
    });

    routeWithDrawer = true;
    routeName = "chaining_targets";
  }

  @override
  Widget build(BuildContext context) {
    _targetsProvider = Provider.of<TargetsProvider>(context);
    _themeProvider = Provider.of<ThemeProvider>(context);
    _webViewProvider = Provider.of<WebViewProvider>(context);
    return Scaffold(
      backgroundColor: _themeProvider.canvas,
      drawer: !_webViewProvider.splitScreenAndBrowserLeft() ? const Drawer() : null,
      appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
      bottomNavigationBar: !_settingsProvider.appBarTop
          ? SizedBox(
              height: AppBar().preferredSize.height,
              child: buildAppBar(),
            )
          : null,
      body: Container(
        color: _themeProvider.canvas,
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
  }

  Widget _mainColumn() {
    return Column(
      children: <Widget>[
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ButtonTheme(
              minWidth: 1.0,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 2,
                  backgroundColor: _themeProvider.secondBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: const BorderSide(width: 2, color: Colors.blueGrey),
                  ),
                ),
                child: Icon(
                  Icons.add,
                  color: _themeProvider.mainText,
                  size: 20,
                ),
                onPressed: () {
                  _showAddDialog(context);
                },
              ),
            ),
            const SizedBox(width: 15),
            ButtonTheme(
              minWidth: 1.0,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 2,
                  backgroundColor: _themeProvider.secondBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: const BorderSide(width: 2, color: Colors.blueGrey),
                  ),
                ),
                child: Icon(
                  Icons.refresh,
                  color: _themeProvider.mainText,
                  size: 20,
                ),
                onPressed: () async {
                  final updateResult = await _targetsProvider.updateAllTargets();
                  if (mounted) {
                    if (updateResult.success) {
                      _targetsProvider.sortTargets(_targetsProvider.currentSort);
                      BotToast.showText(
                        text: updateResult.numberSuccessful > 0
                            ? 'Successfully updated and sorted '
                                '${updateResult.numberSuccessful} targets!'
                            : 'No targets to update!',
                        textStyle: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                        contentColor: updateResult.numberSuccessful > 0 ? Colors.green : Colors.red,
                        duration: const Duration(seconds: 3),
                        contentPadding: const EdgeInsets.all(10),
                      );
                    } else {
                      BotToast.showText(
                        text: 'Update with errors: ${updateResult.numberErrors} errors '
                            'out of ${updateResult.numberErrors + updateResult.numberSuccessful} '
                            'total targets!',
                        textStyle: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                        contentColor: Colors.red,
                        duration: const Duration(seconds: 3),
                        contentPadding: const EdgeInsets.all(10),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
        ChainWidget(
          key: _chainWidgetKey,
          alwaysDarkBackground: false,
          callBackOptions: _callBackChainOptions,
        ),
        if (_targetsProvider.currentColorFilterOut.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              "NOTE: there is an active color filter!",
              style: TextStyle(color: Colors.orange[800], fontSize: 12),
            ),
          ),
        Consumer<TargetsProvider>(
          builder: (context, targetsModel, child) => MediaQuery.orientationOf(context) == Orientation.portrait
              ? Flexible(
                  child: TargetsList(
                    targets: targetsModel.allTargets,
                  ),
                )
              : TargetsList(
                  targets: targetsModel.allTargets,
                ),
        ),
      ],
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      title: _appBarText,
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
        IconButton(
          icon: _searchIcon,
          onPressed: () {
            setState(() {
              Color? myColor = Colors.white;
              if (_searchController.text != '') {
                myColor = Colors.orange[500];
              }
              if (_searchIcon.icon == Icons.search) {
                _searchIcon = Icon(
                  Icons.cancel,
                  color: myColor,
                );
                _appBarText = Form(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                        child: Row(
                          children: <Widget>[
                            Flexible(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TextField(
                                  controller: _searchController,
                                  focusNode: _focusSearch,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: "search targets",
                                    hintStyle: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey[300],
                                      fontSize: 12,
                                    ),
                                  ),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
                _focusSearch.requestFocus();
              } else {
                _searchIcon = Icon(
                  Icons.search,
                  color: myColor,
                );
                _appBarText = const Text("Targets");
              }
            });
          },
        ),

        /// FutureBuilder for YATA button
        FutureBuilder(
          future: _preferencesLoaded,
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (_yataButtonEnabled!) {
                if (_yataButtonInProgress) {
                  return IconButton(
                    icon: const Icon(MdiIcons.alphaYCircleOutline),
                    onPressed: () async {
                      setState(() {
                        _yataButtonInProgress = false;
                      });
                      final yataTargets = await _targetsProvider.getTargetsFromYata();
                      if (!yataTargets.errorConnection && !yataTargets.errorPlayer) {
                        _openYataDialog(yataTargets);
                      } else {
                        String error;
                        if (yataTargets.errorPlayer) {
                          error = "We could not find your user in Yata, do you have an account?";
                        } else {
                          error = "There was an error contacting YATA, please try again later!";
                          if (yataTargets.errorReason.isNotEmpty) {
                            error += "\n\nError code is ${yataTargets.errorReason}";
                          }
                        }
                        BotToast.showText(
                          text: error,
                          textStyle: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                          ),
                          contentColor: Colors.red[800]!,
                          duration: const Duration(seconds: 5),
                          contentPadding: const EdgeInsets.all(10),
                        );
                      }
                      setState(() {
                        _yataButtonInProgress = true;
                      });
                    },
                  );
                } else {
                  return Theme(
                    data: ThemeData(),
                    child: const SizedBox(
                      width: 45,
                      child: Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  );
                }
              } else {
                return const SizedBox.shrink();
              }
            } else {
              return const SizedBox.shrink();
            }
          },
        ),
        PopupMenuButton<TargetSort>(
          icon: const Icon(
            Icons.sort,
          ),
          onSelected: _selectSortPopup,
          itemBuilder: (BuildContext context) {
            return _popupSortChoices.map((TargetSort choice) {
              return PopupMenuItem<TargetSort>(
                value: choice,
                child: Row(
                  children: [
                    if (_targetsProvider.currentSort == choice.type)
                      Padding(
                        padding: const EdgeInsets.only(right: 5),
                        child: Icon(
                          Icons.arrow_forward_ios_outlined,
                          color: _themeProvider.mainText,
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
        _optionsPopUp(),
      ],
    );
  }

  @override
  Future dispose() async {
    _addIdController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showAddDialog(BuildContext _) {
    final targetsProvider = Provider.of<TargetsProvider>(context, listen: false);
    return showDialog<void>(
      context: _,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0.0,
          backgroundColor: Colors.transparent,
          content: SingleChildScrollView(
            child: Stack(
              children: <Widget>[
                SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.only(
                      top: 45,
                      bottom: 16,
                      left: 16,
                      right: 16,
                    ),
                    margin: const EdgeInsets.only(top: 30),
                    decoration: BoxDecoration(
                      color: _themeProvider.secondBackground,
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
                      key: _addFormKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // To make the card compact
                        children: <Widget>[
                          TextFormField(
                            style: const TextStyle(fontSize: 14),
                            controller: _addIdController,
                            maxLength: 10,
                            minLines: 1,
                            maxLines: 2,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              counterText: "",
                              border: OutlineInputBorder(),
                              labelText: 'Insert player ID',
                            ),
                            validator: (value) {
                              if (value!.isEmpty) {
                                return "Cannot be empty!";
                              }
                              final n = num.tryParse(value);
                              if (n == null) {
                                return '$value is not a valid ID!';
                              }
                              _addIdController.text = value.trim();
                              return null;
                            },
                          ),
                          const SizedBox(height: 16.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              TextButton(
                                child: const Text("Add"),
                                onPressed: () async {
                                  if (_addFormKey.currentState!.validate()) {
                                    // Get rid of dialog first, so that it can't
                                    // be pressed twice
                                    Navigator.of(context).pop();
                                    // Copy controller's text ot local variable
                                    // early and delete the global, so that text
                                    // does not appear again in case of failure
                                    final inputId = _addIdController.text;
                                    _addIdController.text = '';

                                    final AddTargetResult tryAddTarget = await targetsProvider.addTarget(
                                      targetId: inputId,
                                      attacks: await _targetsProvider.getAttacks(),
                                    );

                                    BotToast.showText(
                                      text: tryAddTarget.success
                                          ? 'Added ${tryAddTarget.targetName} [${tryAddTarget.targetId}]'
                                          : 'Error adding $inputId. ${tryAddTarget.errorReason}',
                                      textStyle: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                      contentColor: tryAddTarget.success ? Colors.green : Colors.orange[700]!,
                                      duration: const Duration(seconds: 3),
                                      contentPadding: const EdgeInsets.all(10),
                                    );
                                  }
                                },
                              ),
                              TextButton(
                                child: const Text("Cancel"),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  _addIdController.text = '';
                                },
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: _themeProvider.secondBackground,
                    child: CircleAvatar(
                      backgroundColor: _themeProvider.mainText,
                      radius: 22,
                      child: SizedBox(
                        height: 28,
                        width: 28,
                        child: Image.asset(
                          'images/icons/ic_target_account_black_48dp.png',
                          color: _themeProvider.secondBackground,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void onSearchInputTextChange() {
    Provider.of<TargetsProvider>(context, listen: false).setFilterText(_searchController.text);
  }

  void _selectSortPopup(TargetSort choice) {
    switch (choice.type) {
      case TargetSortType.levelDes:
        _targetsProvider.sortTargets(TargetSortType.levelDes);
      case TargetSortType.levelAsc:
        _targetsProvider.sortTargets(TargetSortType.levelAsc);
      case TargetSortType.respectDes:
        _targetsProvider.sortTargets(TargetSortType.respectDes);
      case TargetSortType.respectAsc:
        _targetsProvider.sortTargets(TargetSortType.respectAsc);
      case TargetSortType.ffDes:
        _targetsProvider.sortTargets(TargetSortType.ffDes);
      case TargetSortType.ffAsc:
        _targetsProvider.sortTargets(TargetSortType.ffAsc);
      case TargetSortType.nameDes:
        _targetsProvider.sortTargets(TargetSortType.nameDes);
      case TargetSortType.nameAsc:
        _targetsProvider.sortTargets(TargetSortType.nameAsc);
      case TargetSortType.lifeDes:
        _targetsProvider.sortTargets(TargetSortType.lifeDes);
      case TargetSortType.lifeAsc:
        _targetsProvider.sortTargets(TargetSortType.lifeAsc);
      case TargetSortType.hospitalDes:
        _targetsProvider.sortTargets(TargetSortType.hospitalDes);
      case TargetSortType.hospitalAsc:
        _targetsProvider.sortTargets(TargetSortType.hospitalAsc);
      case TargetSortType.colorDes:
        _targetsProvider.sortTargets(TargetSortType.colorDes);
      case TargetSortType.colorAsc:
        _targetsProvider.sortTargets(TargetSortType.colorAsc);
      case TargetSortType.onlineDes:
        _targetsProvider.sortTargets(TargetSortType.onlineDes);
      case TargetSortType.onlineAsc:
        _targetsProvider.sortTargets(TargetSortType.onlineAsc);
      case TargetSortType.notesDes:
        _targetsProvider.sortTargets(TargetSortType.notesDes);
      case TargetSortType.notesAsc:
        _targetsProvider.sortTargets(TargetSortType.notesAsc);
      case TargetSortType.bounty:
        _targetsProvider.sortTargets(TargetSortType.bounty);
      case TargetSortType.timeAddedDes:
        _targetsProvider.sortTargets(TargetSortType.timeAddedDes);
      case TargetSortType.timeAddedAsc:
        _targetsProvider.sortTargets(TargetSortType.timeAddedAsc);

      default:
        _targetsProvider.sortTargets(TargetSortType.ffAsc);
        break;
    }
  }

  Widget _optionsPopUp() {
    return PopupMenuButton<TargetsOptions>(
      icon: const Icon(Icons.settings),
      onSelected: _openOption,
      itemBuilder: (BuildContext context) {
        return _popupOptionsChoices.map((TargetsOptions choice) {
          return PopupMenuItem<TargetsOptions>(
            value: choice,
            child: Row(
              children: [
                Icon(choice.iconData, size: 20, color: _themeProvider.mainText),
                const SizedBox(width: 10),
                Text(choice.description!),
              ],
            ),
          );
        }).toList();
      },
    );
  }

  Future _openOption(TargetsOptions choice) async {
    switch (choice.description) {
      case "Options":
        final TargetsOptionsReturn newOptions = await (Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TargetsOptionsPage(),
          ),
        ));
        setState(() {
          _yataButtonEnabled = newOptions.yataEnabled;
        });
        widget.retaliationCallback(newOptions.retaliationEnabled);
      //widget.tabCallback(newOptions.tacEnabled);
      case "Filter Color":
        showDialog(
          useRootNavigator: false,
          context: context,
          builder: (BuildContext context) {
            return ColorFilterDialog();
          },
        );
      case "Backup":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TargetsBackupPage(),
          ),
        );
      case "Wipe":
        _openWipeDialog();
    }
  }

  Future<void> _openYataDialog(YataTargetsImportModel importedTargets) {
    // Before opening the dialog, we'll see how many new targets we have, so that we can
    // show a count and some details before importing/exporting
    final List<TargetsOnlyYata> onlyYata = [];
    final List<TargetsOnlyLocal> onlyLocal = [];
    final List<TargetsBothSides> bothSides = [];
    // If we have no targets locally, we'll import all incoming (we assume that [bothSides] and
    // [onlyLocal] are zero
    if (_targetsProvider.allTargets.isEmpty) {
      importedTargets.targets!.forEach((key, yataTarget) {
        onlyYata.add(
          TargetsOnlyYata()
            ..id = key
            ..name = yataTarget.name
            ..noteYata = yataTarget.note
            ..colorYata = yataTarget.color,
        );
      });
    }
    // Otherwise, we'll see how many are new or only local
    else {
      importedTargets.targets!.forEach((key, yataTarget) {
        bool foundLocally = false;
        for (final localTarget in _targetsProvider.allTargets) {
          if (!foundLocally) {
            if (key == localTarget.playerId.toString()) {
              final playerNotesController = Get.find<PlayerNotesController>();
              final playerNote = playerNotesController.getNoteForPlayer(localTarget.playerId.toString());
              bothSides.add(
                TargetsBothSides()
                  ..id = key
                  ..name = yataTarget.name
                  ..noteYata = yataTarget.note
                  ..noteLocal = playerNote?.note ?? ''
                  ..colorLocal = _yataColorCode(playerNote?.color)
                  ..colorYata = yataTarget.color,
              );
              foundLocally = true;
            }
          }
        }
        if (!foundLocally) {
          onlyYata.add(
            TargetsOnlyYata()
              ..id = key
              ..name = yataTarget.name
              ..noteYata = yataTarget.note
              ..colorYata = yataTarget.color,
          );
        }
      });

      for (final localTarget in _targetsProvider.allTargets) {
        bool foundInYata = false;
        importedTargets.targets!.forEach((key, yataTarget) {
          if (!foundInYata) {
            if (localTarget.playerId.toString() == key) {
              foundInYata = true;
            }
          }
        });
        if (!foundInYata) {
          final playerNotesController = Get.find<PlayerNotesController>();
          final playerNote = playerNotesController.getNoteForPlayer(localTarget.playerId.toString());
          onlyLocal.add(
            TargetsOnlyLocal()
              ..id = localTarget.playerId.toString()
              ..name = localTarget.name
              ..noteLocal = playerNote?.note ?? ''
              ..colorLocal = _yataColorCode(playerNote?.color),
          );
        }
      }
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return YataTargetsDialog(
          bothSides: bothSides,
          onlyYata: onlyYata,
          onlyLocal: onlyLocal,
        );
      },
    );
  }

  int _yataColorCode(String? colorString) {
    switch (colorString) {
      case "z":
        return 0;
      case "green":
        return 1;
      case "orange":
        return 2;
      case "red":
        return 3;
    }
    return 0;
  }

  Future<void> _openWipeDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0.0,
          backgroundColor: Colors.transparent,
          content: SingleChildScrollView(
            child: Stack(
              children: <Widget>[
                SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.only(
                      top: 45,
                      bottom: 16,
                      left: 16,
                      right: 16,
                    ),
                    margin: const EdgeInsets.only(top: 15),
                    decoration: BoxDecoration(
                      color: _themeProvider.secondBackground,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10.0,
                          offset: Offset(0.0, 10.0),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // To make the card compact
                      children: <Widget>[
                        const Flexible(
                          child: Text(
                            "CAUTION",
                            style: TextStyle(fontSize: 13, color: Colors.red),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Flexible(
                          child: Text(
                            "This will wipe all your targets (consider performing a backup or "
                            "exporting to YATA).",
                            style: TextStyle(fontSize: 12, color: _themeProvider.mainText),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Flexible(
                          child: Text(
                            "Are you sure?",
                            style: TextStyle(fontSize: 12, color: _themeProvider.mainText),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            TextButton(
                              child: const Text("Wipe!"),
                              onPressed: () {
                                _targetsProvider.wipeAllTargets();
                                Navigator.of(context).pop();
                              },
                            ),
                            TextButton(
                              child: const Text("Oh no!"),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: _themeProvider.secondBackground,
                    child: CircleAvatar(
                      backgroundColor: _themeProvider.secondBackground,
                      radius: 22,
                      child: const SizedBox(
                        height: 34,
                        width: 34,
                        child: Icon(Icons.delete_forever_outlined),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future _restorePreferences() async {
    _yataButtonEnabled = await Prefs().getYataTargetsEnabled();
  }

  void _callBackChainOptions() {
    setState(() {
      // Makes sure to update cards' border when out of panic options
    });
  }
}
