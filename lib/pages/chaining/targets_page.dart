import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chaining/target_sort.dart';
import 'package:torn_pda/pages/chaining/targets_backup_page.dart';
import 'package:torn_pda/providers/targets_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/widgets/chain_timer.dart';
import 'package:torn_pda/widgets/targets_list.dart';

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

  final _popupChoices = <TargetSort>[
    TargetSort(type: TargetSortType.levelDes),
    TargetSort(type: TargetSortType.levelAsc),
    TargetSort(type: TargetSortType.respectDes),
    TargetSort(type: TargetSortType.respectAsc),
    TargetSort(type: TargetSortType.nameDes),
    TargetSort(type: TargetSortType.nameAsc),
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
        title: Text('Targets'),
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
            icon: Icon(
              Icons.add,
              color: _themeProvider.buttonText,
            ),
            onPressed: () {
              _showAddDialog(context);
            },
          ),
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: _themeProvider.buttonText,
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
          PopupMenuButton<TargetSort>(
            icon: Icon(
              Icons.sort,
            ),
            onSelected: _selectSortPopup,
            itemBuilder: (BuildContext context) {
              return _popupChoices.map((TargetSort choice) {
                return PopupMenuItem<TargetSort>(
                  value: choice,
                  child: Text(choice.description),
                );
              }).toList();
            },
          ),
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TargetsBackupPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).requestFocus(new FocusNode()),
        child: Column(
          children: <Widget>[
            Form(
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
                              decoration: InputDecoration(
                                isDense: true,
                                labelText: "Search",
                                prefixIcon: Icon(
                                  Icons.search,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12.0),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ChainTimer(userKey: widget.userKey),
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
                                if(n == null) {
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
                                          await targetsProvider
                                              .addTarget(inputId);
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
    }
  }
}
