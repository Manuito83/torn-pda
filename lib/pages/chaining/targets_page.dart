import 'dart:async';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chaining/target_sort.dart';
import 'package:torn_pda/models/chaining/yata/yata_distribution_models.dart';
import 'package:torn_pda/models/chaining/yata/yata_targets_import.dart';
import 'package:torn_pda/pages/chaining/targets_backup_page.dart';
import 'package:torn_pda/pages/chaining/targets_options_page.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/targets_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/chaining/chain_timer.dart';
import 'package:torn_pda/widgets/chaining/targets_list.dart';
import 'package:torn_pda/widgets/chaining/yata/yata_targets_dialog.dart';

class TargetsOptions {
  String description;
  IconData iconData;

  TargetsOptions({this.description}) {
    switch (description) {
      case "Options":
        iconData = Icons.settings;
        break;
      case "Backup":
        iconData = Icons.save;
        break;
      case "Wipe":
        iconData = Icons.delete_forever_outlined;
        break;
    }
  }
}

class TargetsPage extends StatefulWidget {
  final String userKey;

  const TargetsPage({Key key, @required this.userKey}) : super(key: key);

  @override
  _TargetsPageState createState() => _TargetsPageState();
}

class _TargetsPageState extends State<TargetsPage> {
  final _searchController = new TextEditingController();
  final _addIdController = new TextEditingController();

  var _addFormKey = GlobalKey<FormState>();

  Future _preferencesLoaded;

  TargetsProvider _targetsProvider;
  ThemeProvider _themeProvider;
  SettingsProvider _settingsProvider;

  // For appBar search
  Icon _searchIcon = Icon(Icons.search);
  Widget _appBarText = Text("Targets");
  var _focusSearch = new FocusNode();

  /// Strictly whether we button is enabled in options
  bool _yataButtonInProgress = true;

  /// Dictates if it has been pressed and is showing a circular
  /// progress indicator while fetching data from Yata
  bool _yataButtonEnabled = true;

  final _popupSortChoices = <TargetSort>[
    TargetSort(type: TargetSortType.levelDes),
    TargetSort(type: TargetSortType.levelAsc),
    TargetSort(type: TargetSortType.respectDes),
    TargetSort(type: TargetSortType.respectAsc),
    TargetSort(type: TargetSortType.nameDes),
    TargetSort(type: TargetSortType.nameAsc),
    TargetSort(type: TargetSortType.colorAsc),
    TargetSort(type: TargetSortType.colorDes),
  ];

  final _popupOptionsChoices = <TargetsOptions>[
    TargetsOptions(description: "Options"),
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
  }

  @override
  Widget build(BuildContext context) {
    _targetsProvider = Provider.of<TargetsProvider>(context, listen: false);
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return Scaffold(
      drawer: Drawer(),
      appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
      bottomNavigationBar: !_settingsProvider.appBarTop
          ? SizedBox(
              height: AppBar().preferredSize.height,
              child: buildAppBar(),
            )
          : null,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).requestFocus(new FocusNode()),
        child: Column(
          children: <Widget>[
            SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ButtonTheme(
                  minWidth: 1.0,
                  child: RaisedButton(
                    color: _themeProvider.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(width: 2, color: Colors.blueGrey),
                    ),
                    child: Icon(
                      Icons.add,
                      size: 20,
                    ),
                    onPressed: () {
                      _showAddDialog(context);
                    },
                  ),
                ),
                SizedBox(width: 15),
                ButtonTheme(
                  minWidth: 1.0,
                  child: RaisedButton(
                    color: _themeProvider.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(width: 2, color: Colors.blueGrey),
                    ),
                    child: Icon(
                      Icons.refresh,
                      size: 20,
                    ),
                    onPressed: () async {
                      var updateResult =
                          await _targetsProvider.updateAllTargets();
                      if (mounted) {
                        if (updateResult.success) {
                          BotToast.showText(
                            text: updateResult.numberSuccessful > 0
                                ? 'Successfully updated '
                                    '${updateResult.numberSuccessful} targets!'
                                : 'No targets to update!',
                            textStyle: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                            contentColor: updateResult.numberSuccessful > 0
                                ? Colors.green
                                : Colors.red,
                            duration: Duration(seconds: 3),
                            contentPadding: EdgeInsets.all(10),
                          );
                        } else {
                          BotToast.showText(
                            text:
                                'Update with errors: ${updateResult.numberErrors} errors '
                                'out of ${updateResult.numberErrors + updateResult.numberSuccessful} '
                                'total targets!',
                            textStyle: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                            contentColor: Colors.red,
                            duration: Duration(seconds: 3),
                            contentPadding: EdgeInsets.all(10),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 5),
            ChainTimer(
              userKey: widget.userKey,
              alwaysDarkBackground: false,
              chainTimerParent: ChainTimerParent.targets,
            ),
            Flexible(
              child: Consumer<TargetsProvider>(
                builder: (context, targetsModel, child) => TargetsList(
                  targets: targetsModel.allTargets,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      brightness: Brightness.dark,
      title: _appBarText,
      leading: new IconButton(
        icon: new Icon(Icons.menu),
        onPressed: () {
          final ScaffoldState scaffoldState =
              context.findRootAncestorStateOfType();
          scaffoldState.openDrawer();
        },
      ),
      actions: <Widget>[
        IconButton(
          icon: _searchIcon,
          onPressed: () {
            setState(() {
              Color myColor = Colors.white;
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
                        padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
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
                                        fontSize: 12),
                                  ),
                                  style: TextStyle(
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
                _appBarText = Text("Targets");
              }
            });
          },
        ),

        /// FutureBuilder for YATA button
        FutureBuilder(
          future: _preferencesLoaded,
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (_yataButtonEnabled) {
                if (_yataButtonInProgress) {
                  return IconButton(
                    icon: Icon(MdiIcons.alphaYCircleOutline),
                    onPressed: () async {
                      setState(() {
                        _yataButtonInProgress = false;
                      });
                      var yataTargets =
                          await _targetsProvider.getTargetsFromYata();
                      if (!yataTargets.errorConnection &&
                          !yataTargets.errorPlayer) {
                        _openYataDialog(yataTargets);
                      } else {
                        String error;
                        if (yataTargets.errorPlayer) {
                          error =
                              "We could not find your user in Yata, do you have an account?";
                        } else {
                          error =
                              "There was an error contacting YATA, please try again later!";
                        }
                        BotToast.showText(
                          text: error,
                          textStyle: TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                          ),
                          contentColor: Colors.red[800],
                          duration: Duration(seconds: 5),
                          contentPadding: EdgeInsets.all(10),
                        );
                      }
                      setState(() {
                        _yataButtonInProgress = true;
                      });
                    },
                  );
                } else {
                  return Theme(
                    data: Theme.of(context).copyWith(accentColor: Colors.white),
                    child: SizedBox(
                      width: 45,
                      child: Center(
                        child: Container(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                  );
                }
              } else {
                return SizedBox.shrink();
              }
            } else {
              return SizedBox.shrink();
            }
          },
        ),
        PopupMenuButton<TargetSort>(
          icon: Icon(
            Icons.sort,
          ),
          onSelected: _selectSortPopup,
          itemBuilder: (BuildContext context) {
            return _popupSortChoices.map((TargetSort choice) {
              return PopupMenuItem<TargetSort>(
                value: choice,
                child: Text(
                  choice.description,
                  style: TextStyle(
                    fontSize: 13,
                  ),
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
    var targetsProvider = Provider.of<TargetsProvider>(context, listen: false);
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
                      padding: EdgeInsets.only(
                        top: 45,
                        bottom: 16,
                        left: 16,
                        right: 16,
                      ),
                      margin: EdgeInsets.only(top: 30),
                      decoration: new BoxDecoration(
                        color: _themeProvider.background,
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10.0,
                            offset: const Offset(0.0, 10.0),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _addFormKey,
                        child: Column(
                          mainAxisSize:
                              MainAxisSize.min, // To make the card compact
                          children: <Widget>[
                            TextFormField(
                              style: TextStyle(fontSize: 14),
                              controller: _addIdController,
                              maxLength: 10,
                              minLines: 1,
                              maxLines: 2,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                counterText: "",
                                border: OutlineInputBorder(),
                                labelText: 'Insert player ID',
                              ),
                              validator: (value) {
                                if (value.isEmpty) {
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
                            SizedBox(height: 16.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: <Widget>[
                                FlatButton(
                                  child: Text("Add"),
                                  onPressed: () async {
                                    if (_addFormKey.currentState.validate()) {
                                      // Get rid of dialog first, so that it can't
                                      // be pressed twice
                                      Navigator.of(context).pop();
                                      // Copy controller's text ot local variable
                                      // early and delete the global, so that text
                                      // does not appear again in case of failure
                                      var inputId = _addIdController.text;
                                      _addIdController.text = '';
                                      dynamic attacksFull =
                                          await _targetsProvider
                                              .getAttacksFull();
                                      AddTargetResult tryAddTarget =
                                          await targetsProvider.addTarget(
                                        targetId: inputId,
                                        attacksFull: attacksFull,
                                      );
                                      if (tryAddTarget.success) {
                                        BotToast.showText(
                                          text:
                                              'Added ${tryAddTarget.targetName} '
                                              '[${tryAddTarget.targetId}]',
                                          textStyle: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white,
                                          ),
                                          contentColor: Colors.green,
                                          duration: Duration(seconds: 3),
                                          contentPadding: EdgeInsets.all(10),
                                        );
                                      } else if (!tryAddTarget.success) {
                                        BotToast.showText(
                                          text: 'Error adding $inputId.'
                                              ' ${tryAddTarget.errorReason}',
                                          textStyle: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white,
                                          ),
                                          contentColor: Colors.green,
                                          duration: Duration(seconds: 3),
                                          contentPadding: EdgeInsets.all(10),
                                        );
                                      }
                                    }
                                  },
                                ),
                                FlatButton(
                                  child: Text("Cancel"),
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
                      backgroundColor: _themeProvider.background,
                      child: CircleAvatar(
                        backgroundColor: _themeProvider.mainText,
                        radius: 22,
                        child: SizedBox(
                          height: 28,
                          width: 28,
                          child: Image.asset(
                            'images/icons/ic_target_account_black_48dp.png',
                            color: _themeProvider.background,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  void onSearchInputTextChange() {
    Provider.of<TargetsProvider>(context, listen: false)
        .setFilterText(_searchController.text);
  }

  void _selectSortPopup(TargetSort choice) {
    switch (choice.type) {
      case TargetSortType.levelDes:
        _targetsProvider.sortTargets(TargetSortType.levelDes);
        break;
      case TargetSortType.levelAsc:
        _targetsProvider.sortTargets(TargetSortType.levelAsc);
        break;
      case TargetSortType.respectDes:
        _targetsProvider.sortTargets(TargetSortType.respectDes);
        break;
      case TargetSortType.respectAsc:
        _targetsProvider.sortTargets(TargetSortType.respectAsc);
        break;
      case TargetSortType.nameDes:
        _targetsProvider.sortTargets(TargetSortType.nameDes);
        break;
      case TargetSortType.nameAsc:
        _targetsProvider.sortTargets(TargetSortType.nameAsc);
        break;
      case TargetSortType.colorDes:
        _targetsProvider.sortTargets(TargetSortType.colorDes);
        break;
      case TargetSortType.colorAsc:
        _targetsProvider.sortTargets(TargetSortType.colorAsc);
        break;
    }
  }

  Widget _optionsPopUp() {
    return PopupMenuButton<TargetsOptions>(
      icon: Icon(Icons.settings),
      onSelected: _openOption,
      itemBuilder: (BuildContext context) {
        return _popupOptionsChoices.map((TargetsOptions choice) {
          return PopupMenuItem<TargetsOptions>(
            value: choice,
            child: Row(
              children: [
                Icon(choice.iconData, size: 20, color: _themeProvider.mainText),
                SizedBox(width: 10),
                Text(choice.description),
              ],
            ),
          );
        }).toList();
      },
    );
  }

  void _openOption(TargetsOptions choice) async {
    switch (choice.description) {
      case "Options":
        TargetsOptionsReturn newOptions = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TargetsOptionsPage(),
          ),
        );
        setState(() {
          _yataButtonEnabled = newOptions.yataEnabled;
        });
        break;
      case "Backup":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TargetsBackupPage(),
          ),
        );
        break;
      case "Wipe":
        _openWipeDialog();
        break;
    }
  }

  Future<void> _openYataDialog(YataTargetsImportModel importedTargets) {
    // Before opening the dialog, we'll see how many new targets we have, so that we can
    // show a count and some details before importing/exporting
    List<TargetsOnlyYata> onlyYata = [];
    List<TargetsOnlyLocal> onlyLocal = [];
    List<TargetsBothSides> bothSides = [];
    // If we have no targets locally, we'll import all incoming (we assume that [bothSides] and
    // [onlyLocal] are zero
    if (_targetsProvider.allTargets.isEmpty) {
      importedTargets.targets.forEach((key, yataTarget) {
        onlyYata.add(TargetsOnlyYata()
          ..id = key
          ..name = yataTarget.name
          ..noteYata = yataTarget.note
          ..colorYata = yataTarget.color);
      });
    }
    // Otherwise, we'll see how many are new or only local
    else {
      importedTargets.targets.forEach((key, yataTarget) {
        bool foundLocally = false;
        _targetsProvider.allTargets.forEach((localTarget) {
          if (!foundLocally) {
            if (key == localTarget.playerId.toString()) {
              bothSides.add(TargetsBothSides()
                ..id = key
                ..name = yataTarget.name
                ..noteYata = yataTarget.note
                ..noteLocal = localTarget.personalNote
                ..colorLocal = _yataColorCode(localTarget.personalNoteColor)
                ..colorYata = yataTarget.color);
              foundLocally = true;
            }
          }
        });
        if (!foundLocally) {
          onlyYata.add(TargetsOnlyYata()
            ..id = key
            ..name = yataTarget.name
            ..noteYata = yataTarget.note
            ..colorYata = yataTarget.color);
        }
      });

      _targetsProvider.allTargets.forEach((localTarget) {
        bool foundInYata = false;
        importedTargets.targets.forEach((key, yataTarget) {
          if (!foundInYata) {
            if (localTarget.playerId.toString() == key) {
              foundInYata = true;
            }
          }
        });
        if (!foundInYata) {
          onlyLocal.add(TargetsOnlyLocal()
            ..id = localTarget.playerId.toString()
            ..name = localTarget.name
            ..noteLocal = localTarget.personalNote
            ..colorLocal = _yataColorCode(localTarget.personalNoteColor));
        }
      });
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

  int _yataColorCode(String colorString) {
    switch (colorString) {
      case "":
        return 0;
        break;
      case "green":
        return 1;
        break;
      case "orange":
        return 2;
        break;
      case "red":
        return 3;
        break;
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
                    padding: EdgeInsets.only(
                      top: 45,
                      bottom: 16,
                      left: 16,
                      right: 16,
                    ),
                    margin: EdgeInsets.only(top: 15),
                    decoration: new BoxDecoration(
                      color: _themeProvider.background,
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10.0,
                          offset: const Offset(0.0, 10.0),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min, // To make the card compact
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            "CAUTION",
                            style: TextStyle(fontSize: 13, color: Colors.red),
                          ),
                        ),
                        SizedBox(height: 10),
                        Flexible(
                          child: Text(
                            "This will wipe all your targets (consider performing a backup or "
                            "exporting to YATA).",
                            style: TextStyle(
                                fontSize: 12, color: _themeProvider.mainText),
                          ),
                        ),
                        SizedBox(height: 10),
                        Flexible(
                          child: Text(
                            "Are you sure?",
                            style: TextStyle(
                                fontSize: 12, color: _themeProvider.mainText),
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            FlatButton(
                              child: Text("Wipe!"),
                              onPressed: () {
                                _targetsProvider.wipeAllTargets();
                                Navigator.of(context).pop();
                              },
                            ),
                            FlatButton(
                              child: Text("Oh no!"),
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
                    backgroundColor: _themeProvider.background,
                    child: CircleAvatar(
                      backgroundColor: _themeProvider.background,
                      radius: 22,
                      child: SizedBox(
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
    _yataButtonEnabled = await SharedPreferencesModel().getYataTargetsEnabled();
  }
}
