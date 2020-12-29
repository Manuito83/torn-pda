import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/friends_provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/widgets/friends/friends_list.dart';
import 'package:torn_pda/pages/friends/friends_backup_page.dart';
import 'package:torn_pda/models/friends/friends_sort.dart';

import '../main.dart';

class FriendsPage extends StatefulWidget {
  @override
  _FriendsPageState createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  ThemeProvider _themeProvider;
  FriendsProvider _friendsProvider;
  SettingsProvider _settingsProvider;

  final _searchController = new TextEditingController();
  final _addIdController = new TextEditingController();

  var _addFormKey = GlobalKey<FormState>();

  // For appBar search
  Icon _searchIcon = Icon(Icons.search);
  Widget _appBarText = Text("Friends");
  var _focusSearch = new FocusNode();

  final _popupChoices = <FriendSort>[
    FriendSort(type: FriendSortType.levelDes),
    FriendSort(type: FriendSortType.levelAsc),
    FriendSort(type: FriendSortType.factionDes),
    FriendSort(type: FriendSortType.factionAsc),
    FriendSort(type: FriendSortType.nameDes),
    FriendSort(type: FriendSortType.nameAsc),
  ];

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _searchController.addListener(onSearchInputTextChange);
    // Reset the filter so that we get all the targets
    SchedulerBinding.instance.addPostFrameCallback((_) {
      Provider.of<FriendsProvider>(context, listen: false).setFilterText('');
    });
    analytics
        .logEvent(name: 'section_changed', parameters: {'section': 'friends'});
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    _friendsProvider = Provider.of<FriendsProvider>(context, listen: false);
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
                          await _friendsProvider.updateAllFriends();
                      if (updateResult.success) {
                        BotToast.showText(
                          text: updateResult.numberSuccessful > 0
                              ? 'Successfully updated '
                                  '${updateResult.numberSuccessful} '
                                  'friends!'
                              : 'No friends to update!',
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
                              'total friends!',
                          textStyle: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                          contentColor: Colors.red,
                          duration: Duration(seconds: 3),
                          contentPadding: EdgeInsets.all(10),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),
            Flexible(
              child: Consumer<FriendsProvider>(
                builder: (context, friendsModel, child) => FriendsList(
                  friends: friendsModel.allFriends,
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
      leading: IconButton(
        icon: Icon(Icons.menu),
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
                                    hintText: "search friends",
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
                _appBarText = Text("Friends");
              }
            });
          },
        ),
        PopupMenuButton<FriendSort>(
          icon: Icon(
            Icons.sort,
          ),
          onSelected: _selectSortPopup,
          itemBuilder: (BuildContext context) {
            return _popupChoices.map((FriendSort choice) {
              return PopupMenuItem<FriendSort>(
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
                builder: (context) => FriendsBackupPage(),
              ),
            );
          },
        ),
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
    var friendsProvider = Provider.of<FriendsProvider>(context, listen: false);
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
                              labelText: 'Insert friend ID',
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
                                    AddFriendResult tryAddFriend =
                                        await friendsProvider
                                            .addFriend(inputId);
                                    if (tryAddFriend.success) {
                                      BotToast.showText(
                                        text:
                                            'Added ${tryAddFriend.friendName} '
                                            '[${tryAddFriend.friendId}]',
                                        textStyle: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                        contentColor: Colors.green,
                                        duration: Duration(seconds: 3),
                                        contentPadding: EdgeInsets.all(10),
                                      );
                                    } else if (!tryAddFriend.success) {
                                      BotToast.showText(
                                        text: 'Error adding $inputId.'
                                            ' ${tryAddFriend.errorReason}',
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
                        child: Icon(Icons.people),
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
    Provider.of<FriendsProvider>(context, listen: false)
        .setFilterText(_searchController.text);

    setState(() {
      if (_searchController.text != '') {
        if (_searchIcon.icon == Icons.search) {
          _searchIcon = Icon(
            Icons.search,
            color: Colors.orange[500],
          );
        } else {
          _searchIcon = Icon(
            Icons.cancel,
            color: Colors.orange[500],
          );
        }
      } else {
        if (_searchIcon.icon == Icons.search) {
          _searchIcon = Icon(
            Icons.search,
            color: Colors.white,
          );
        } else {
          _searchIcon = Icon(
            Icons.cancel,
            color: Colors.white,
          );
        }
      }
    });
  }

  void _selectSortPopup(FriendSort choice) {
    switch (choice.type) {
      case FriendSortType.levelDes:
        _friendsProvider.sortTargets(FriendSortType.levelDes);
        break;
      case FriendSortType.levelAsc:
        _friendsProvider.sortTargets(FriendSortType.levelAsc);
        break;
      case FriendSortType.factionDes:
        _friendsProvider.sortTargets(FriendSortType.factionDes);
        break;
      case FriendSortType.factionAsc:
        _friendsProvider.sortTargets(FriendSortType.factionAsc);
        break;
      case FriendSortType.nameDes:
        _friendsProvider.sortTargets(FriendSortType.nameDes);
        break;
      case FriendSortType.nameAsc:
        _friendsProvider.sortTargets(FriendSortType.nameAsc);
        break;
    }
  }
}
