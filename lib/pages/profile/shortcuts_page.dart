import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/profile/shortcuts_model.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/shortcuts_provider.dart';

class ShortcutsPage extends StatefulWidget {
  @override
  _ShortcutsPageState createState() => _ShortcutsPageState();
}

class _ShortcutsPageState extends State<ShortcutsPage> {
  SettingsProvider _settingsProvider;
  ShortcutsProvider _shortcutsProvider;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _shortcutsProvider = Provider.of<ShortcutsProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
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
                  SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text("Active shortcuts (swipe to remove??)"),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  _activeCardsList(),
                  SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text("All shortcuts"),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  _allCardsList(),
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
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 5),
                      child: Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.all(2),
                            child: Image.asset(
                              short.iconUrl,
                              width: 16,
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
            allShortcuts.add(Card(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(2),
                      child: Image.asset(
                        short.iconUrl,
                        width: 16,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(child: Text(short.name)),
                          Switch(
                            value: short.active,
                            onChanged: (active) {
                              setState(() {
                                if (active) {
                                  shortcutProvider.activateShortcut(short);
                                } else {
                                  shortcutProvider.deactivateShortcut(short);
                                }
                              });
                            },
                            activeTrackColor: Colors.lightGreenAccent,
                            activeColor: Colors.green,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ));
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

  Future<bool> _willPopCallback() async {
    Navigator.of(context).pop();
    return true;
  }
}
