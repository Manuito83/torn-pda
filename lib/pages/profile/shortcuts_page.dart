import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/profile/shortcuts_model.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/shortcuts_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:flutter/services.dart';

class ShortcutsPage extends StatefulWidget {
  @override
  _ShortcutsPageState createState() => _ShortcutsPageState();
}

class _ShortcutsPageState extends State<ShortcutsPage> {
  SettingsProvider _settingsProvider;
  ShortcutsProvider _shortcutsProvider;
  ThemeProvider _themeProvider;

  final _customNameController = new TextEditingController();
  final _customURLController = new TextEditingController();
  var _customNameKey = GlobalKey<FormState>();
  var _customURLKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    _shortcutsProvider = Provider.of<ShortcutsProvider>(context, listen: true);
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return WillPopScope(
      onWillPop: _willPopCallback,
      child: Container(
        color: _themeProvider.currentTheme == AppTheme.light
            ? Colors.blueGrey
            : Colors.grey[900],
        child: SafeArea(
          top: _settingsProvider.appBarTop ? false : true,
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              "Shortcut menu",
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 20),
                          ),
                          Flexible(
                            flex: 2,
                            child: _shortcutMenuDropdown(),
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
                            Text("ACTIVE SHORTCUTS"),
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
                      child: Text("ALL SHORTCUTS"),
                    ),
                    SizedBox(height: 10),
                    _customCard(),
                    _allCardsList(),
                    SizedBox(height: 40),
                  ],
                ),
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
                key: UniqueKey(),
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

  Padding _customCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        height: 50,
        child: Card(
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.orange[500], width: 1.5),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Padding(
                  padding: EdgeInsets.all(2),
                  child: Image.asset(
                    "images/icons/pda_icon.png",
                    width: 18,
                    height: 18,
                    color: _themeProvider.mainText,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(child: Text('Custom shortcut')),
                      TextButton(
                        onPressed: () {
                          _openCustomDialog();
                        },
                        child: Text(
                          'ADD',
                          style: TextStyle(color: Colors.green[500]),
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
                                        onPressed: !short.visible
                                            // Avoid double press
                                            ? null
                                            : () async {
                                                // Start animation
                                                setState(() {
                                                  short.visible = false;
                                                });

                                                await Future.delayed(Duration(
                                                    milliseconds: 300));

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
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      brightness: Brightness.dark,
      title: Text("Shortcuts"),
      leading: new IconButton(
        icon: new Icon(Icons.arrow_back),
        onPressed: () {
          _willPopCallback();
        },
      ),
      actions: <Widget>[
        IconButton(
          icon: Icon(
            Icons.delete,
            color: _themeProvider.buttonText,
          ),
          onPressed: () async {
            if (_shortcutsProvider.activeShortcuts.length == 0) {
              BotToast.showText(
                text: 'You have no active shortcuts, activate some!',
                textStyle: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
                contentColor: Colors.orange[800],
                duration: Duration(seconds: 2),
                contentPadding: EdgeInsets.all(10),
              );
            } else {
              _openWipeDialog();
            }
          },
        ),
      ],
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

  DropdownButton _shortcutMenuDropdown() {
    return DropdownButton<String>(
      value: _shortcutsProvider.shortcutMenu,
      items: [
        DropdownMenuItem(
          value: "carousel",
          child: SizedBox(
            width: 67,
            child: Text(
              "Carousel",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "grid",
          child: SizedBox(
            width: 67,
            child: Text(
              "Grid",
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
          _shortcutsProvider.changeShortcutMenu(value);
        });
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
                      mainAxisSize:
                          MainAxisSize.min, // To make the card compact
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            "This will reset all your active shortcuts and order, "
                            "are you sure?",
                            style: TextStyle(
                                fontSize: 12, color: _themeProvider.mainText),
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            FlatButton(
                              child: Text("Reset!"),
                              onPressed: () {
                                _shortcutsProvider.wipeAllShortcuts();
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

  Future<void> _openCustomDialog() {
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
                            "Add a name and URL for your custom shortcut. Note: "
                            "ensure URL begins with 'https://'",
                            style: TextStyle(
                                fontSize: 12, color: _themeProvider.mainText),
                          ),
                        ),
                        SizedBox(height: 15),
                        Form(
                          key: _customNameKey,
                          child: Column(
                            mainAxisSize:
                                MainAxisSize.min, // To make the card compact
                            children: <Widget>[
                              TextFormField(
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _themeProvider.mainText,
                                ),
                                textCapitalization:
                                    TextCapitalization.sentences,
                                controller: _customNameController,
                                maxLength: 20,
                                maxLines: 1,
                                decoration: InputDecoration(
                                  counterText: "",
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  labelText: 'Name',
                                ),
                                validator: (value) {
                                  if (value.replaceAll(' ', '').isEmpty) {
                                    return "Cannot be empty!";
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 15),
                        Row(
                          children: [
                            Flexible(
                              child: Form(
                                key: _customURLKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize
                                      .min, // To make the card compact
                                  children: <Widget>[
                                    TextFormField(
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _themeProvider.mainText,
                                      ),
                                      controller: _customURLController,
                                      maxLength: 300,
                                      maxLines: 1,
                                      decoration: InputDecoration(
                                        counterText: "",
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                        labelText: 'URL',
                                      ),
                                      validator: (value) {
                                        if (value.replaceAll(' ', '').isEmpty) {
                                          return "Cannot be empty!";
                                        }
                                        if (!value
                                            .toLowerCase()
                                            .contains('https://')) {
                                          if (value
                                              .toLowerCase()
                                              .contains('http://')) {
                                            return "Invalid, HTTPS needed!";
                                          }
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.paste),
                              onPressed: () async {
                                ClipboardData data =
                                    await Clipboard.getData('text/plain');
                                _customURLController.text = data.text;
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Flexible(
                          child: Text(
                            "Tip: long-press the app bar in the browser to copy the "
                            "current URL you are visiting. Then paste it here.",
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            FlatButton(
                              child: Text("Add"),
                              onPressed: () {
                                if (!_customNameKey.currentState.validate()) {
                                  return;
                                }
                                if (!_customURLKey.currentState.validate()) {
                                  return;
                                }

                                var customShortcut = Shortcut()
                                  ..name = _customNameController.text
                                  ..nickname = _customNameController.text
                                  ..url = _customURLController.text
                                  ..iconUrl = 'images/icons/pda_icon.png'
                                  ..color = Colors.orange[500]
                                  ..isCustom = true;

                                _shortcutsProvider
                                    .activateShortcut(customShortcut);
                                Navigator.of(context).pop();
                                _customNameController.text = '';
                                _customURLController.text = '';
                              },
                            ),
                            FlatButton(
                              child: Text("Close"),
                              onPressed: () {
                                Navigator.of(context).pop();
                                _customNameController.text = '';
                                _customURLController.text = '';
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
                        height: 25,
                        width: 25,
                        child: Image.asset(
                          "images/icons/pda_icon.png",
                          width: 18,
                          height: 18,
                          color: _themeProvider.mainText,
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

  Future<bool> _willPopCallback() async {
    Navigator.of(context).pop();
    return true;
  }
}
