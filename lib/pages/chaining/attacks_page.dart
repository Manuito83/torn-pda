// Dart imports:
import 'dart:async';

// Package imports:
import 'package:bot_toast/bot_toast.dart';
// Flutter imports:
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/drawer.dart';
// Project imports:
import 'package:torn_pda/models/chaining/attack_sort.dart';
import 'package:torn_pda/providers/attacks_provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/widgets/chaining/attacks_list.dart';
import 'package:torn_pda/widgets/webviews/pda_browser_icon.dart';

class AttacksPage extends StatefulWidget {
  const AttacksPage({super.key});

  @override
  AttacksPageState createState() => AttacksPageState();
}

class AttacksPageState extends State<AttacksPage> {
  final _searchController = TextEditingController();

  late AttacksProvider _attacksProvider;
  late ThemeProvider _themeProvider;
  late SettingsProvider _settingsProvider;

  Color? _filterTypeColor;
  Text _filterText = const Text('');

  final _popupChoices = <AttackSort>[
    AttackSort(type: AttackSortType.levelDes),
    AttackSort(type: AttackSortType.levelAsc),
    AttackSort(type: AttackSortType.respectDes),
    AttackSort(type: AttackSortType.respectAsc),
    AttackSort(type: AttackSortType.dateDes),
    AttackSort(type: AttackSortType.dateAsc),
  ];

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _searchController.addListener(onSearchInputTextChange);
    _attacksProvider = Provider.of<AttacksProvider>(context, listen: false);
    _changeFilterColorAndText();
    routeWithDrawer = true;
    routeName = "chaining_attacks";
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: _themeProvider.canvas,
      drawer: const Drawer(),
      appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
      bottomNavigationBar: !_settingsProvider.appBarTop
          ? SizedBox(
              height: AppBar().preferredSize.height,
              child: buildAppBar(),
            )
          : null,
      body: FutureBuilder(
        future: _attacksProvider.initializeAttacks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Container(
              color: _themeProvider.canvas,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
                child: Column(
                  children: <Widget>[
                    Form(
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
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        labelText: "Search",
                                        prefixIcon: Icon(Icons.search),
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: _filterText,
                    ),
                    Flexible(
                      child: Consumer<AttacksProvider>(
                        builder: (context, attacksProvider, child) => AttacksList(
                          attacks: attacksProvider.allAttacks,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      //brightness: Brightness.dark, // For downgrade to Flutter 2.2.3
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      title: const Text('Attacks'),
      leadingWidth: context.read<WebViewProvider>().webViewSplitActive ? 50 : 80,
      leading: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              final ScaffoldState? scaffoldState = context.findRootAncestorStateOfType();
              if (scaffoldState != null) {
                if (context.read<WebViewProvider>().webViewSplitActive &&
                    context.read<WebViewProvider>().splitScreenPosition == WebViewSplitPosition.left) {
                  scaffoldState.openEndDrawer();
                } else {
                  scaffoldState.openDrawer();
                }
              }
            },
          ),
          if (!context.read<WebViewProvider>().webViewSplitActive) PdaBrowserIcon(),
        ],
      ),
      actions: <Widget>[
        IconButton(
          icon: Icon(
            Icons.refresh,
            color: _themeProvider.buttonText,
          ),
          onPressed: () async {
            _attacksProvider.initializeAttacks();

            BotToast.showText(
              text: 'Updated with latest attacks!',
              textStyle: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
              contentColor: Colors.green,
              duration: const Duration(seconds: 3),
              contentPadding: const EdgeInsets.all(10),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.accessibility),
          color: _filterTypeColor,
          onPressed: () {
            final filterType = _attacksProvider.currentTypeFilter;
            if (filterType == AttackTypeFilter.all) {
              _attacksProvider.setFilterType(AttackTypeFilter.unknownTargets);
              setState(() {
                _changeFilterColorAndText();
              });

              BotToast.showText(
                text: 'Hiding people already added to the target list!',
                textStyle: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
                contentColor: Colors.green,
                duration: const Duration(seconds: 3),
                contentPadding: const EdgeInsets.all(10),
              );
            } else {
              _attacksProvider.setFilterType(AttackTypeFilter.all);
              setState(() {
                _changeFilterColorAndText();
              });

              BotToast.showText(
                text: 'Showing all recent attacks!',
                textStyle: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
                contentColor: Colors.green,
                duration: const Duration(seconds: 3),
                contentPadding: const EdgeInsets.all(10),
              );
            }
          },
        ),
        PopupMenuButton<AttackSort>(
          icon: const Icon(
            Icons.sort,
          ),
          onSelected: _selectSortPopup,
          // Not using initial value yet, see
          // https://github.com/flutter/flutter/issues/19954
          // initialValue: _popupChoices[0],
          itemBuilder: (BuildContext context) {
            return _popupChoices.map((AttackSort choice) {
              return PopupMenuItem<AttackSort>(
                value: choice,
                child: Text(choice.description),
              );
            }).toList();
          },
        ),
      ],
    );
  }

  @override
  Future dispose() async {
    _searchController.dispose();
    super.dispose();
  }

  void onSearchInputTextChange() {
    Provider.of<AttacksProvider>(context, listen: false).setFilterText(_searchController.text);
  }

  void _selectSortPopup(AttackSort choice) {
    switch (choice.type) {
      case AttackSortType.levelDes:
        _attacksProvider.sortAttacks(AttackSortType.levelDes);
      case AttackSortType.levelAsc:
        _attacksProvider.sortAttacks(AttackSortType.levelAsc);
      case AttackSortType.respectDes:
        _attacksProvider.sortAttacks(AttackSortType.respectDes);
      case AttackSortType.respectAsc:
        _attacksProvider.sortAttacks(AttackSortType.respectAsc);
      case AttackSortType.dateDes:
        _attacksProvider.sortAttacks(AttackSortType.dateDes);
      case AttackSortType.dateAsc:
        _attacksProvider.sortAttacks(AttackSortType.dateAsc);
      default:
        _attacksProvider.sortAttacks(AttackSortType.dateDes);
    }
  }

  void _changeFilterColorAndText() {
    if (_attacksProvider.currentTypeFilter == AttackTypeFilter.all) {
      _filterTypeColor = Colors.white;
      _filterText = const Text('Showing all recent attacks and targets');
    } else {
      _filterTypeColor = Colors.orange[200];
      _filterText = Text(
        'Filtering out existing targets',
        style: TextStyle(color: Colors.orange[400]),
      );
    }
  }
}
