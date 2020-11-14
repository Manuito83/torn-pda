import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/shortcuts_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';

class ShortcutsPage extends StatefulWidget {
  @override
  _ShortcutsPageState createState() => _ShortcutsPageState();
}

class _ShortcutsPageState extends State<ShortcutsPage> {
  SettingsProvider _settingsProvider;
  ShortcutsProvider _shortcutsProvider;
  ThemeProvider _themeProvider;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _shortcutsProvider = Provider.of<ShortcutsProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return WillPopScope(
      onWillPop: _willPopCallback,
      child: SafeArea(
        bottom: true,
        child: Scaffold(
          appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
          bottomNavigationBar: !_settingsProvider.appBarTop
              ? SizedBox(
                  height: AppBar().preferredSize.height,
                  child: buildAppBar(),
                )
              : null,
          body: Container(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            "Shortcut tile",
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: 20),
                        ),
                        Flexible(
                          flex: 2,
                          child: _shortcutTileDropdown(),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: SizedBox(
                      width: 200,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text("Active shortcuts"),
                          Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Text(
                              'SWIPE TO REMOVE',
                              style: TextStyle(fontSize: 10),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Text(
                              'LONG-PRESS TO SORT',
                              style: TextStyle(fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  if (_shortcutsProvider.activeShortcuts.length == 0)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(40, 10, 0, 10),
                      child: Text(
                        'No active shortcuts, add some below!',
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                        ),
                      ),
                    )
                  else
                    _activeCardsList(),
                  SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Text("All shortcuts"),
                  ),
                  SizedBox(height: 10),
                  _allCardsList(),
                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Padding _activeCardsList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Consumer<ShortcutsProvider>(
        builder: (context, shortcutProvider, child) {
          var activeShortcuts = List<Widget>();
          for (var short in shortcutProvider.activeShortcuts) {
            activeShortcuts.add(
              Slidable(
                key: ValueKey(short.name),
                actionPane: SlidableDrawerActionPane(),
                actionExtentRatio: 0.25,
                actions: <Widget>[
                  IconSlideAction(
                    color: Colors.red,
                    icon: Icons.remove_circle_outline_outlined,
                    onTap: () {
                      _shortcutsProvider.deactivateShortcut(short);
                    },
                  ),
                ],
                child: Container(
                  height: 50,
                  child: Card(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: short.color, width: 1.5),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.0, vertical: 5),
                      child: Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.all(2),
                            child: Image.asset(
                              short.iconUrl,
                              width: 18,
                              height: 18,
                              color: _themeProvider.mainText,
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Flexible(child: Text(short.name)),
                                Icon(Icons.reorder),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          return Container(
            // TODO: watch out or ReorderableListView for updates to fix:
            // Issue 1: ReorderableListView should be getting a shrinkWrap and
            //   physics as in https://github.com/flutter/flutter/issues/66080
            // Issue 2: Height 100 as the reorderableListView leaves that gap at the
            //   bottom in '_defaultDropAreaExtent'. We extend the container by that size
            //   Otherwise, we just assign 40 as a margin with the list below
            height: _shortcutsProvider.activeShortcuts.length > 0
                ? _shortcutsProvider.activeShortcuts.length * 50 + 100.0
                : 20.0,
            child: ReorderableListView(
              //shrinkWrap: true,
              //physics: NeverScrollableScrollPhysics(),
              onReorder: (int oldIndex, int newIndex) {
                if (oldIndex < newIndex) {
                  // removing the item at oldIndex will shorten the list by 1
                  newIndex -= 1;
                }
                _shortcutsProvider.reorderShortcut(
                  _shortcutsProvider.activeShortcuts[oldIndex],
                  oldIndex,
                  newIndex,
                );
              },
              children: activeShortcuts,
            ),
          );
        },
      ),
    );
  }

  Padding _allCardsList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Consumer<ShortcutsProvider>(
        builder: (context, shortcutProvider, child) {
          var allShortcuts = List<Widget>();
          for (var short in shortcutProvider.allShortcuts) {
            allShortcuts.add(
              // Don't show those that are active
              !short.active
                  ? AnimatedOpacity(
                      opacity: short.visible ? 1 : 0,
                      duration: Duration(milliseconds: 300),
                      child: Container(
                        height: 50,
                        child: Card(
                          shape: RoundedRectangleBorder(
                            side: BorderSide(color: short.color, width: 1.5),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Row(
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(2),
                                  child: Image.asset(
                                    short.iconUrl,
                                    width: 18,
                                    height: 18,
                                    color: _themeProvider.mainText,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(child: Text(short.name)),
                                      TextButton(
                                        onPressed: () async {
                                          // Start animation
                                          setState(() {
                                            short.visible = false;
                                          });

                                          await Future.delayed(
                                              Duration(milliseconds: 300));

                                          setState(() {
                                            shortcutProvider
                                                .activateShortcut(short);
                                          });

                                          // Reset visibility after animation
                                          short.visible = true;
                                        },
                                        child: Text(
                                          'ADD',
                                          style: TextStyle(
                                              color: Colors.green[500]),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  : SizedBox(),
            );
          }
          return ListView(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            children: allShortcuts,
          );
        },
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      title: Text("Shortcuts"),
      leading: new IconButton(
        icon: new Icon(Icons.arrow_back),
        onPressed: () {
          _willPopCallback();
        },
      ),
    );
  }

  DropdownButton _shortcutTileDropdown() {
    return DropdownButton<String>(
      value: _shortcutsProvider.shortcutTile,
      items: [
        DropdownMenuItem(
          value: "both",
          child: SizedBox(
            width: 90,
            child: Text(
              "Icon and text",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "icon",
          child: SizedBox(
            width: 90,
            child: Text(
              "Only icon",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "text",
          child: SizedBox(
            width: 90,
            child: Text(
              "Only text",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _shortcutsProvider.changeShortcutTile(value);
        });
      },
    );
  }

  Future<bool> _willPopCallback() async {
    Navigator.of(context).pop();
    return true;
  }
}
