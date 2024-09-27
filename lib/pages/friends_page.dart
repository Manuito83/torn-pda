// Flutter imports:
// Package imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/drawer.dart';
import 'package:torn_pda/main.dart';
// Project imports:
import 'package:torn_pda/models/friends/friends_sort.dart';
import 'package:torn_pda/pages/friends/friends_backup_page.dart';
import 'package:torn_pda/providers/friends_provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/widgets/friends/friends_list.dart';
import 'package:torn_pda/widgets/pda_browser_icon.dart';

class FriendsPage extends StatefulWidget {
  @override
  FriendsPageState createState() => FriendsPageState();
}

class FriendsPageState extends State<FriendsPage> {
  late ThemeProvider _themeProvider;
  late FriendsProvider _friendsProvider;
  late SettingsProvider _settingsProvider;
  late WebViewProvider _webViewProvider;

  final _searchController = TextEditingController();
  final _addIdController = TextEditingController();

  final _addFormKey = GlobalKey<FormState>();

  // For appBar search
  Icon _searchIcon = const Icon(Icons.search);
  Widget _appBarText = const Text("Friends");
  final _focusSearch = FocusNode();

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
    _restoreFriends();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _searchController.addListener(onSearchInputTextChange);
    // Reset the filter so that we get all the targets
    SchedulerBinding.instance.addPostFrameCallback((_) {
      Provider.of<FriendsProvider>(context, listen: false).setFilterText('');
    });
    analytics?.logScreenView(screenName: 'friends');

    routeWithDrawer = true;
    routeName = "friends";
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context);
    _webViewProvider = Provider.of<WebViewProvider>(context);

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
      body: Container(
        color: _themeProvider.canvas,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
          child: MediaQuery.orientationOf(context) == Orientation.portrait
              ? _mainColumn()
              : SingleChildScrollView(
                  child: _mainColumn(),
                ),
        ),
      ),
    );
  }

  Column _mainColumn() {
    return Column(
      children: <Widget>[
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ButtonTheme(
              minWidth: 1.0,
              child: ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all<Color?>(_themeProvider.secondBackground),
                  shape: WidgetStateProperty.all<OutlinedBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(width: 2, color: Colors.blueGrey),
                    ),
                  ),
                ),
                child: Icon(
                  Icons.add,
                  size: 20,
                  color: _themeProvider.mainText,
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
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all<Color?>(_themeProvider.secondBackground),
                  shape: WidgetStateProperty.all<OutlinedBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(width: 2, color: Colors.blueGrey),
                    ),
                  ),
                ),
                child: Icon(
                  Icons.refresh,
                  size: 20,
                  color: _themeProvider.mainText,
                ),
                onPressed: () async {
                  final updateResult = await _friendsProvider.updateAllFriends();
                  if (updateResult.success) {
                    BotToast.showText(
                      text: updateResult.numberSuccessful > 0
                          ? 'Successfully updated '
                              '${updateResult.numberSuccessful} '
                              'friends!'
                          : 'No friends to update!',
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
                          'total friends!',
                      textStyle: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                      contentColor: Colors.red,
                      duration: const Duration(seconds: 3),
                      contentPadding: const EdgeInsets.all(10),
                    );
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Consumer<FriendsProvider>(
          builder: (context, targetsModel, child) => MediaQuery.orientationOf(context) == Orientation.portrait
              ? Flexible(child: FriendsList(friends: targetsModel.allFriends))
              : FriendsList(friends: targetsModel.allFriends),
        ),
      ],
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      iconTheme: IconThemeData(color: Colors.white),
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      title: _appBarText,
      leadingWidth: _webViewProvider.webViewSplitActive ? 50 : 88,
      leading: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              final ScaffoldState? scaffoldState = context.findRootAncestorStateOfType();
              if (scaffoldState != null) {
                if (_webViewProvider.webViewSplitActive &&
                    _webViewProvider.splitScreenPosition == WebViewSplitPosition.left) {
                  scaffoldState.openEndDrawer();
                } else {
                  scaffoldState.openDrawer();
                }
              }
            },
          ),
          if (!_webViewProvider.webViewSplitActive) PdaBrowserIcon(),
        ],
      ),
      actions: <Widget>[
        IconButton(
          icon: _searchIcon,
          onPressed: () {
            setState(() {
              Color? myColor = Colors.white;
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
                        padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
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
                                    hintStyle:
                                        TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[300], fontSize: 12),
                                  ),
                                  style: const TextStyle(
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
                _appBarText = const Text("Friends");
              }
            });
          },
        ),
        PopupMenuButton<FriendSort>(
          icon: const Icon(
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
          icon: const Icon(Icons.save),
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
    final friendsProvider = Provider.of<FriendsProvider>(context, listen: false);
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
                    padding: const EdgeInsets.only(
                      top: 45,
                      bottom: 16,
                      left: 16,
                      right: 16,
                    ),
                    margin: const EdgeInsets.only(top: 30),
                    decoration: BoxDecoration(
                      color: _themeProvider.secondBackground,
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
                      key: _addFormKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // To make the card compact
                        children: <Widget>[
                          TextFormField(
                            style: const TextStyle(fontSize: 14),
                            controller: _addIdController,
                            maxLength: 10,
                            minLines: 1,
                            maxLines: 2,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              counterText: "",
                              border: OutlineInputBorder(),
                              labelText: 'Insert friend ID',
                            ),
                            validator: (value) {
                              if (value!.isEmpty) {
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
                          const SizedBox(height: 16.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              TextButton(
                                child: const Text("Add"),
                                onPressed: () async {
                                  if (_addFormKey.currentState!.validate()) {
                                    // Get rid of dialog first, so that it can't
                                    // be pressed twice
                                    Navigator.of(context).pop();
                                    // Copy controller's text ot local variable
                                    // early and delete the global, so that text
                                    // does not appear again in case of failure
                                    final inputId = _addIdController.text;
                                    _addIdController.text = '';
                                    final AddFriendResult tryAddFriend = await friendsProvider.addFriend(inputId);
                                    if (tryAddFriend.success) {
                                      BotToast.showText(
                                        text: 'Added ${tryAddFriend.friendName} '
                                            '[${tryAddFriend.friendId}]',
                                        textStyle: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                        contentColor: Colors.green,
                                        duration: const Duration(seconds: 3),
                                        contentPadding: const EdgeInsets.all(10),
                                      );
                                    } else if (!tryAddFriend.success) {
                                      BotToast.showText(
                                        text: 'Error adding $inputId.'
                                            ' ${tryAddFriend.errorReason}',
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
                                },
                              ),
                              TextButton(
                                child: const Text("Cancel"),
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
                    backgroundColor: _themeProvider.secondBackground,
                    child: CircleAvatar(
                      backgroundColor: _themeProvider.mainText,
                      radius: 22,
                      child: const SizedBox(
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
    Provider.of<FriendsProvider>(context, listen: false).setFilterText(_searchController.text);

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
          _searchIcon = const Icon(
            Icons.search,
            color: Colors.white,
          );
        } else {
          _searchIcon = const Icon(
            Icons.cancel,
            color: Colors.white,
          );
        }
      }
    });
  }

  void _selectSortPopup(FriendSort choice) {
    switch (choice.type!) {
      case FriendSortType.levelDes:
        _friendsProvider.sortTargets(FriendSortType.levelDes);
      case FriendSortType.levelAsc:
        _friendsProvider.sortTargets(FriendSortType.levelAsc);
      case FriendSortType.factionDes:
        _friendsProvider.sortTargets(FriendSortType.factionDes);
      case FriendSortType.factionAsc:
        _friendsProvider.sortTargets(FriendSortType.factionAsc);
      case FriendSortType.nameDes:
        _friendsProvider.sortTargets(FriendSortType.nameDes);
      case FriendSortType.nameAsc:
        _friendsProvider.sortTargets(FriendSortType.nameAsc);
    }
  }

  Future _restoreFriends() async {
    _friendsProvider = context.read<FriendsProvider>();
    if (!_friendsProvider.initialized) {
      _friendsProvider.initFriends();
    }
  }
}
