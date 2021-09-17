// Dart imports:
import 'dart:async';

// Package imports:
import 'package:bot_toast/bot_toast.dart';
// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
// Project imports:
import 'package:torn_pda/models/chaining/target_sort.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/providers/war_controller.dart';
import 'package:torn_pda/widgets/chaining/chain_widget.dart';
import 'package:torn_pda/widgets/chaining/targets_list.dart';

import '../../main.dart';

class WarPage extends StatefulWidget {
  final String userKey;
  //final Function tabCallback;

  const WarPage({
    Key key,
    @required this.userKey,
    //@required this.tabCallback,
  }) : super(key: key);

  @override
  _WarPageState createState() => _WarPageState();
}

class _WarPageState extends State<WarPage> {
  final _searchController = TextEditingController();
  final _addIdController = TextEditingController();

  final _addFormKey = GlobalKey<FormState>();

  Future _preferencesLoaded;

  final _chainWidgetKey = GlobalKey();

  final WarController _w = Get.put(WarController());
  ThemeProvider _themeProvider;
  SettingsProvider _settingsProvider;

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

/*
  final _popupOptionsChoices = <TargetsOptions>[
    TargetsOptions(description: "Options"),
    TargetsOptions(description: "Filter"),
    TargetsOptions(description: "Backup"),
    TargetsOptions(description: "Wipe"),
  ];
*/

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _preferencesLoaded = _restorePreferences();

    analytics.logEvent(name: 'section_changed', parameters: {'section': 'war'});
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return Scaffold(
      drawer: const Drawer(),
      appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
      bottomNavigationBar: !_settingsProvider.appBarTop
          ? SizedBox(
              height: AppBar().preferredSize.height,
              child: buildAppBar(),
            )
          : null,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
        child: MediaQuery.of(context).orientation == Orientation.portrait
            ? _mainColumn()
            : SingleChildScrollView(
                child: _mainColumn(),
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
                  primary: _themeProvider.background,
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
                  primary: _themeProvider.background,
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
                  /*
                  final updateResult = await _targetsProvider.updateAllTargets();
                  if (mounted) {
                    if (updateResult.success) {
                      BotToast.showText(
                        text: updateResult.numberSuccessful > 0
                            ? 'Successfully updated '
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
                  */
                },
              ),
            ),
          ],
        ),
        ChainWidget(
          key: _chainWidgetKey,
          userKey: widget.userKey,
          alwaysDarkBackground: false,
        ),
        // TODO: CONSUMER
      ],
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      brightness: Brightness.dark,
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      title: const Text("War"),
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () {
          final ScaffoldState scaffoldState = context.findRootAncestorStateOfType();
          scaffoldState.openDrawer();
        },
      ),
      actions: const <Widget>[
        // TODO
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
    // TODO: final targetsProvider = Provider.of<TargetsProvider>(context, listen: false);
    return showDialog<void>(
      context: _,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AddFactionDialog(
          themeProvider: _themeProvider,
          addFormKey: _addFormKey,
          addIdController: _addIdController,
          //TODO targetsProvider: targetsProvider,
        );
      },
    );
  }

  /*
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
  */

  Future _restorePreferences() async {
    // TODO
  }
}

class AddFactionDialog extends StatelessWidget {
  const AddFactionDialog({
    Key key,
    @required this.themeProvider,
    @required this.addFormKey,
    @required this.addIdController,
  }) : super(key: key);

  final ThemeProvider themeProvider;
  final GlobalKey<FormState> addFormKey;
  final TextEditingController addIdController;

  @override
  Widget build(BuildContext context) {
    final apiKey = context.read<UserDetailsProvider>().basic.userApiKey;
    final WarController w = Get.find();
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
                  color: themeProvider.background,
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
                      TextFormField(
                        style: const TextStyle(fontSize: 14),
                        controller: addIdController,
                        maxLength: 10,
                        minLines: 1,
                        maxLines: 2,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          counterText: "",
                          border: OutlineInputBorder(),
                          labelText: 'Insert faction ID',
                        ),
                        validator: (value) {
                          if (value.isEmpty) {
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
                      const SizedBox(height: 16.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          TextButton(
                            child: const Text("Add"),
                            onPressed: () async {
                              if (addFormKey.currentState.validate()) {
                                // Copy controller's text ot local variable
                                // early and delete the global, so that text
                                // does not appear again in case of failure
                                final inputId = addIdController.text;
                                addIdController.text = '';

                                final addFactionResult = w.addFaction(apiKey, inputId);

                                BotToast.showText(
                                  text: addFactionResult.isNotEmpty
                                      ? 'Added $addFactionResult [$inputId]'
                                      : 'Error adding $inputId.',
                                  textStyle: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                  contentColor: addFactionResult.isNotEmpty ? Colors.green : Colors.orange[700],
                                  duration: const Duration(seconds: 3),
                                  contentPadding: const EdgeInsets.all(10),
                                );
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
                backgroundColor: themeProvider.background,
                child: CircleAvatar(
                  backgroundColor: themeProvider.mainText,
                  radius: 22,
                  child: SizedBox(
                    height: 28,
                    width: 28,
                    child: Image.asset(
                      'images/icons/ic_target_account_black_48dp.png',
                      color: themeProvider.background,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
