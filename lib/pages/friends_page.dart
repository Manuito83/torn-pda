import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/friends_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/widgets/friends_list.dart';

class FriendsPage extends StatefulWidget {
  @override
  _FriendsPageState createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  ThemeProvider _themeProvider;
  FriendsProvider _friendsProvider;

  final _searchController = new TextEditingController();
  final _addIdController = new TextEditingController();

  var _addFormKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    _friendsProvider = Provider.of<FriendsProvider>(context, listen: false);
    return Scaffold(
      drawer: new Drawer(),
      appBar: AppBar(
        title: Text('Friends'),
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
              //color: _themeProvider.buttonText,
            ),
            onPressed: () async {
              /*var updateResult = await _targetsProvider.updateAllTargets();
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
              }*/
            },
          ),
/*          PopupMenuButton<TargetSortPopup>(
            icon: Icon(
              Icons.sort,
            ),
            onSelected: _selectSortPopup,
            itemBuilder: (BuildContext context) {
              return _popupChoices.map((TargetSortPopup choice) {
                return PopupMenuItem<TargetSortPopup>(
                  value: choice,
                  child: Text(choice.description),
                );
              }).toList();
            },
          ),*/
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () {
/*              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TargetsBackupPage(),
                ),
              );*/
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
                              //controller: _searchController,
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

  @override
  Future dispose() async {
    //_addIdController.dispose();
    //_searchController.dispose();
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
                                      AddFriendResult tryAddFriend =
                                      await friendsProvider
                                          .addFriend(inputId);
                                      if (tryAddFriend.success) {
                                        Scaffold.of(_).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Added ${tryAddFriend.friendName} '
                                                  '[${tryAddFriend.friendId}]',
                                            ),
                                          ),
                                        );
                                      } else if (!tryAddFriend.success) {
                                        Scaffold.of(_).showSnackBar(
                                          SnackBar(
                                            backgroundColor: Colors.red,
                                            content: Text(
                                              'Error adding $inputId.'
                                                  ' ${tryAddFriend.errorReason}',
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

}
