import 'dart:async';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chaining/attack_sort.dart';
import 'package:torn_pda/providers/attacks_provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/widgets/chaining/attacks_list.dart';

class AttacksPage extends StatefulWidget {
  final String userKey;

  const AttacksPage({Key key, @required this.userKey}) : super(key: key);

  @override
  _AttacksPageState createState() => _AttacksPageState();
}

class _AttacksPageState extends State<AttacksPage> {
  final _searchController = new TextEditingController();

  AttacksProvider _attacksProvider;
  ThemeProvider _themeProvider;
  SettingsProvider _settingsProvider;

  Color _filterTypeColor;
  Text _filterText = Text('');

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
    // Reset the filter so that we get all the targets
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _attacksProvider = Provider.of<AttacksProvider>(context, listen: false);
      _attacksProvider.initializeAttacks();
      _changeFilterColorAndText();
    });
  }

  @override
  Widget build(BuildContext context) {
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
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
  }

  AppBar buildAppBar() {
    return AppBar(
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      brightness: Brightness.dark,
      title: Text('Attacks'),
      leading: new IconButton(
        icon: new Icon(Icons.menu),
        onPressed: () {
          final ScaffoldState scaffoldState = context.findRootAncestorStateOfType();
          scaffoldState.openDrawer();
        },
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
              textStyle: TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
              contentColor: Colors.green,
              duration: Duration(seconds: 3),
              contentPadding: EdgeInsets.all(10),
            );

          },
        ),
        IconButton(
          icon: Icon(Icons.accessibility),
          color: _filterTypeColor,
          onPressed: () {
            var filterType = _attacksProvider.currentTypeFilter;
            if (filterType == AttackTypeFilter.all) {
              _attacksProvider.setFilterType(AttackTypeFilter.unknownTargets);
              _changeFilterColorAndText();

              BotToast.showText(
                text: 'Hiding people already added to the target list!',
                textStyle: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
                contentColor: Colors.green,
                duration: Duration(seconds: 3),
                contentPadding: EdgeInsets.all(10),
              );

            } else {
              _attacksProvider.setFilterType(AttackTypeFilter.all);
              _changeFilterColorAndText();

              BotToast.showText(
                text: 'Showing all recent attacks!',
                textStyle: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
                contentColor: Colors.green,
                duration: Duration(seconds: 3),
                contentPadding: EdgeInsets.all(10),
              );

            }
          },
        ),
        PopupMenuButton<AttackSort>(
          icon: Icon(
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
        break;
      case AttackSortType.levelAsc:
        _attacksProvider.sortAttacks(AttackSortType.levelAsc);
        break;
      case AttackSortType.respectDes:
        _attacksProvider.sortAttacks(AttackSortType.respectDes);
        break;
      case AttackSortType.respectAsc:
        _attacksProvider.sortAttacks(AttackSortType.respectAsc);
        break;
      case AttackSortType.dateDes:
        _attacksProvider.sortAttacks(AttackSortType.dateDes);
        break;
      case AttackSortType.dateAsc:
        _attacksProvider.sortAttacks(AttackSortType.dateAsc);
        break;
    }
  }

  void _changeFilterColorAndText() {
    setState(() {
      if (_attacksProvider.currentTypeFilter == AttackTypeFilter.all) {
        _filterTypeColor = Colors.white;
        _filterText = Text('Showing all recent attacks and targets');
      } else {
        _filterTypeColor = Colors.orange[200];
        _filterText = Text(
          'Filtering out existing targets',
          style: TextStyle(color: Colors.orange[400]),
        );
      }
    });
  }
}
