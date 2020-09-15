import 'dart:async';
import 'package:animations/animations.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chaining/target_sort.dart';
import 'package:torn_pda/models/chaining/yata/yata_targets_import.dart';
import 'package:torn_pda/pages/chaining/targets_backup_page.dart';
import 'package:torn_pda/pages/chaining/targets_options_page.dart';
import 'package:torn_pda/pages/chaining/yata/yata_targets_distribution.dart';
import 'package:torn_pda/providers/targets_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/widgets/chaining/chain_timer.dart';
import 'package:torn_pda/widgets/chaining/targets_list.dart';

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

  TargetsProvider _targetsProvider;
  ThemeProvider _themeProvider;

  // For appBar search
  Icon _searchIcon = Icon(Icons.search);
  Widget _appBarText = Text("Targets");
  var _focusSearch = new FocusNode();

  bool _yataButtonActive = true;

  final _popupSortChoices = <TargetSort>[
    TargetSort(type: TargetSortType.levelDes),
    TargetSort(type: TargetSortType.levelAsc),
    TargetSort(type: TargetSortType.respectDes),
    TargetSort(type: TargetSortType.respectAsc),
    TargetSort(type: TargetSortType.nameDes),
    TargetSort(type: TargetSortType.nameAsc),
  ];

  final _popupOptionsChoices = <TargetsOptions>[
    TargetsOptions(description: "Options"),
    TargetsOptions(description: "Backup"),
    TargetsOptions(description: "Wipe"),
  ];

  @override
  void initState() {
    super.initState();
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
      appBar: AppBar(
        title: _appBarText,
        leading: new IconButton(
          icon: new Icon(Icons.menu),
          onPressed: () {
            final ScaffoldState scaffoldState = context.findRootAncestorStateOfType();
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
          IconButton(
            icon: Icon(MdiIcons.alphaYCircleOutline),
            onPressed: _yataButtonActive
                ? () async {
                    setState(() {
                      _yataButtonActive = false;
                    });
                    var yataTargets = await _targetsProvider.getTargetsFromYata();
                    if (!yataTargets.errorConnection && !yataTargets.errorPlayer) {
                      _openYataDialog(yataTargets);
                    } else {
                      String error;
                      if (yataTargets.errorPlayer) {
                        error = "We could not find your user in Yata, do you have an account?";
                      } else {
                        error = "There was an error contacting YATA, please try again later!";
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
                      _yataButtonActive = true;
                    });
                  }
                : null,
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
                  child: Text(choice.description),
                );
              }).toList();
            },
          ),
          _optionsPopUp(),
        ],
      ),
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
                      var updateResult = await _targetsProvider.updateAllTargets();
                      if (updateResult.success) {
                        Scaffold.of(context).showSnackBar(
                          SnackBar(
                            content: Text(updateResult.numberSuccessful > 0
                                ? 'Successfully updated '
                                    '${updateResult.numberSuccessful} '
                                    'targets!'
                                : 'No targets to update!'),
                          ),
                        );
                      } else {
                        Scaffold.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.red,
                            content: Text(
                              'Update with errors: ${updateResult.numberErrors} errors '
                              'out of ${updateResult.numberErrors + updateResult.numberSuccessful} '
                              'total targets!',
                            ),
                          ),
                        );
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
                          mainAxisSize: MainAxisSize.min, // To make the card compact
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
                                      AddTargetResult tryAddTarget =
                                          await targetsProvider.addTarget(inputId);
                                      if (tryAddTarget.success) {
                                        Scaffold.of(_).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Added ${tryAddTarget.targetName} '
                                              '[${tryAddTarget.targetId}]',
                                            ),
                                          ),
                                        );
                                      } else if (!tryAddTarget.success) {
                                        Scaffold.of(_).showSnackBar(
                                          SnackBar(
                                            backgroundColor: Colors.red,
                                            content: Text(
                                              'Error adding $inputId.'
                                              ' ${tryAddTarget.errorReason}',
                                            ),
                                          ),
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
    Provider.of<TargetsProvider>(context, listen: false).setFilterText(_searchController.text);
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
                Icon(choice.iconData, size: 20),
                SizedBox(width: 10),
                Text(choice.description),
              ],
            ),
          );
        }).toList();
      },
    );
  }

  void _openOption(TargetsOptions choice) {
    switch (choice.description) {
      case "Options":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TargetsOptionsPage(),
          ),
        );
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
    Map<String, String> onlyYata = {};
    // We are using Map<ID <Name, Notes>> for targets distribution and also for exporting
    Map<String, Map<String, String>> onlyLocal = {};
    Map<String, Map<String, String>> bothSides = {};
    // If we have no targets locally, we'll import all incoming (we assume that [bothSides] and
    // [onlyLocal] are zero
    if (_targetsProvider.allTargets.isEmpty) {
      importedTargets.targets.forEach((key, value) {
        onlyYata.addAll({key: value.name});
      });
    }
    // Otherwise, we'll see how many are new or only local
    else {
      importedTargets.targets.forEach((key, value) {
        bool foundLocally = false;
        _targetsProvider.allTargets.forEach((element) {
          if (!foundLocally) {
            if (key == element.playerId.toString()) {
              bothSides.addAll(
                {
                  key: {
                    // We use the Torn PDA note in case that we export (we'll export our note)
                    value.name: element.personalNote,
                  },
                },
              );
              foundLocally = true;
            }
          }
        });
        if (!foundLocally) {
          onlyYata.addAll({key: value.name});
        }
      });

      _targetsProvider.allTargets.forEach((element) {
        bool foundInYata = false;
        importedTargets.targets.forEach((key, value) {
          if (!foundInYata) {
            if (element.playerId.toString() == key) {
              foundInYata = true;
            }
          }
        });
        if (!foundInYata) {
          onlyLocal.addAll(
            {
              element.playerId.toString(): {
                element.name: element.personalNote,
              },
            },
          );
        }
      });
    }

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
                      mainAxisSize: MainAxisSize.min, // To make the card compact
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            "TARGETS DISTRIBUTION",
                            style: TextStyle(fontSize: 11, color: _themeProvider.mainText),
                          ),
                        ),
                        SizedBox(height: 10),
                        Flexible(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(width: 25),
                              Column(
                                children: [
                                  Text(
                                    "${onlyYata.length} only in YATA",
                                    style: TextStyle(fontSize: 12, color: _themeProvider.mainText),
                                  ),
                                  Text(
                                    "${bothSides.length} common targets",
                                    style: TextStyle(fontSize: 12, color: _themeProvider.mainText),
                                  ),
                                  Text(
                                    "${onlyLocal.length} only in Torn PDA",
                                    style: TextStyle(fontSize: 12, color: _themeProvider.mainText),
                                  ),
                                ],
                              ),
                              SizedBox(width: 10),
                              OpenContainer(
                                transitionDuration: Duration(milliseconds: 500),
                                transitionType: ContainerTransitionType.fadeThrough,
                                openBuilder: (BuildContext context, VoidCallback _) {
                                  return YataTargetsDistribution(
                                    bothSides: bothSides,
                                    onlyYata: onlyYata,
                                    onlyLocal: onlyLocal,
                                  );
                                },
                                closedElevation: 0,
                                closedShape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(56 / 2),
                                  ),
                                ),
                                closedColor: Colors.transparent,
                                closedBuilder: (BuildContext context, VoidCallback openContainer) {
                                  return SizedBox(
                                    width: 20,
                                    child: Icon(
                                      Icons.info_outline,
                                      size: 20,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 8),
                        Divider(),
                        SizedBox(height: 5),
                        RaisedButton(
                          child: Column(
                            children: [
                              Text(
                                "IMPORT",
                                style: TextStyle(fontSize: 11),
                              ),
                              Text(
                                "FROM YATA",
                                style: TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                          onPressed: () {},
                        ),
                        SizedBox(height: 10),
                        RaisedButton(
                          child: Column(
                            children: [
                              Text(
                                "EXPORT",
                                style: TextStyle(fontSize: 11),
                              ),
                              Text(
                                "TO YATA",
                                style: TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                          onPressed: () async {
                            Navigator.of(context).pop();
                            var exportResult = await _targetsProvider.postTargetsToYata(
                              onlyLocal: onlyLocal,
                              bothSides: bothSides,
                            );
                            if (exportResult == "") {
                              BotToast.showText(
                                text: "There was an error exporting!",
                                textStyle: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white,
                                ),
                                contentColor: Colors.red[800],
                                duration: Duration(seconds: 5),
                                contentPadding: EdgeInsets.all(10),
                              );
                            } else {
                              BotToast.showText(
                                text: exportResult,
                                textStyle: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white,
                                ),
                                contentColor: Colors.green[800],
                                duration: Duration(seconds: 5),
                                contentPadding: EdgeInsets.all(10),
                              );
                            }
                          },
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            FlatButton(
                              child: Text("Cancel"),
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
                        child: Image.asset(
                          'images/icons/yata_logo.png',
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
                      mainAxisSize: MainAxisSize.min, // To make the card compact
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
                            style: TextStyle(fontSize: 12, color: _themeProvider.mainText),
                          ),
                        ),
                        SizedBox(height: 10),
                        Flexible(
                          child: Text(
                            "Are you sure?",
                            style: TextStyle(fontSize: 12, color: _themeProvider.mainText),
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
}
