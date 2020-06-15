import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/friend_model.dart';
import 'package:torn_pda/providers/friends_provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/widgets/webview_generic.dart';
import 'package:url_launcher/url_launcher.dart';
import 'notes_dialog.dart';

class FriendCard extends StatefulWidget {
  final FriendModel friendModel;

  FriendCard({@required this.friendModel});

  @override
  _FriendCardState createState() => _FriendCardState();
}

class _FriendCardState extends State<FriendCard> {
  FriendModel _friend;
  FriendsProvider _friendsProvider;
  ThemeProvider _themeProvider;
  SettingsProvider _settingsProvider;
  UserDetailsProvider _userProvider;

  Timer _ticker;

  String _lastUpdated;

  @override
  void initState() {
    super.initState();
    _ticker = new Timer.periodic(
        Duration(seconds: 60), (Timer t) => _timerUpdateInformation());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _friend = widget.friendModel;
    _returnLastUpdated();
    _friendsProvider = Provider.of<FriendsProvider>(context, listen: false);
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _userProvider = Provider.of<UserDetailsProvider>(context, listen: false);
    return Slidable(
      actionPane: SlidableDrawerActionPane(),
      actionExtentRatio: 0.25,
      actions: <Widget>[
        IconSlideAction(
            caption: 'Remove',
            color: Colors.red,
            icon: Icons.delete,
            onTap: () {
              Provider.of<FriendsProvider>(context, listen: false)
                  .deleteFriend(_friend);
              Scaffold.of(context).showSnackBar(
                SnackBar(
                  content: Text('Deleted ${_friend.name}!'),
                  action: SnackBarAction(
                    label: 'UNDO',
                    textColor: Colors.orange,
                    onPressed: () {
                      //_friendsProvider.restoredDeleted();
                    },
                  ),
                ),
              );
            }),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        child: Card(
          shape: RoundedRectangleBorder(
              side: BorderSide(color: _borderColor(), width: 1.5),
              borderRadius: BorderRadius.circular(4.0)),
          elevation: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // LINE 1
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(15, 5, 15, 0),
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      height: 20,
                      width: 20,
                      child: IconButton(
                        padding: EdgeInsets.all(0.0),
                        iconSize: 20,
                        icon: Icon(
                          Icons.remove_red_eye,
                        ),
                        onPressed: () async {
                          var browserType = _settingsProvider.currentBrowser;
                          switch (browserType) {
                            case BrowserSetting.app:
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (BuildContext context) =>
                                      TornWebViewGeneric(
                                    profileId: '${_friend.playerId}',
                                    profileName: _friend.name,
                                    webViewType: WebViewType.profile,
                                  ),
                                ),
                              );
                              break;
                            case BrowserSetting.external:
                              var url = 'https://www.torn.com/profiles.php?'
                                  'XID=${_friend.playerId}';
                              if (await canLaunch(url)) {
                                await launch(url, forceSafariVC: false);
                              }
                              break;
                          }
                        },
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        _attackIcon(),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                        ),
                        SizedBox(
                          width: 95,
                          child: Text(
                            '${_friend.name}',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.max,
                        children: <Widget>[
                          SizedBox(
                            width: 120,
                            child: Row(
                              children: <Widget>[
                                Text(
                                  ' [${_friend.playerId}]',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // LINE 2
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(15, 5, 15, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    Text(
                      'Lvl ${_friend.level}',
                    ),
                    Row(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(left: 15),
                          child: _factionIcon(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // LINE 3
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(17, 5, 15, 0),
                child: Row(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color:
                                _returnStatusColor(_friend.lastAction.status),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Text(
                            'Action: ',
                          ),
                        ),
                        Text(
                          _friend.lastAction.relative == "0 minutes ago"
                              ? 'now'
                              : _friend.lastAction.relative
                                  .replaceAll(' ago', ''),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          Text('$_lastUpdated'),
                          SizedBox(width: 8),
                          SizedBox(
                            height: 20,
                            width: 20,
                            child: _refreshIcon(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // LINE 4
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(15, 5, 15, 0),
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: IconButton(
                        padding: EdgeInsets.all(0),
                        iconSize: 20,
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          _showNotesDialog();
                        },
                      ),
                    ),
                    Flexible(
                      child: Padding(
                        padding: EdgeInsetsDirectional.only(start: 8),
                        child: Row(
                          children: <Widget>[
                            Text('Notes: '),
                            Flexible(
                              child: Text(
                                '${_friend.personalNote}',
                                style: TextStyle(
                                  color: _returnFriendNoteColor(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _attackIcon() {
    return SizedBox.shrink();
    // TODO: return same as in attacks to see profile
  }

  Widget _refreshIcon() {
    if (_friend.isUpdating) {
      return Padding(
        padding: const EdgeInsets.all(2.0),
        child: CircularProgressIndicator(),
      );
    } else {
      return IconButton(
        padding: EdgeInsets.all(0.0),
        iconSize: 20,
        icon: Icon(Icons.refresh),
        onPressed: () async {
          _updateThisFriend();
        },
      );
    }
  }

  Widget _factionIcon() {
    if (_friend.hasFaction) {
      Color iconColor;

      print('${_userProvider.myUser.userFactionId}');



      return Padding(
        padding: const EdgeInsets.only(right: 4),
        child: SizedBox(
          height: 13,
          width: 13,
          child: ImageIcon(
            AssetImage('images/icons/faction.png'),
          ),
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Color _borderColor() {
    if (_friend.justUpdatedWithSuccess) {
      return Colors.green;
    } else if (_friend.justUpdatedWithError) {
      return Colors.red;
    } else {
      return Colors.transparent;
    }
  }

  Color _returnStatusColor(String status) {
    switch (status) {
      case 'Online':
        return Colors.green;
        break;
      case 'Idle':
        return Colors.orange;
        break;
      default:
        return Colors.grey;
    }
  }

  void _returnLastUpdated() {
    var timeDifference = DateTime.now().difference(_friend.lastUpdated);
    if (timeDifference.inMinutes < 1) {
      _lastUpdated = 'now';
    } else if (timeDifference.inMinutes == 1 && timeDifference.inHours < 1) {
      _lastUpdated = '1 minute ago';
    } else if (timeDifference.inMinutes > 1 && timeDifference.inHours < 1) {
      _lastUpdated = '${timeDifference.inMinutes} minutes ago';
    } else if (timeDifference.inHours == 1 && timeDifference.inDays < 1) {
      _lastUpdated = '1 hour ago';
    } else if (timeDifference.inHours > 1 && timeDifference.inDays < 1) {
      _lastUpdated = '${timeDifference.inHours} hours ago';
    } else if (timeDifference.inDays == 1) {
      _lastUpdated = '1 day ago';
    } else {
      _lastUpdated = '${timeDifference.inDays} days ago';
    }
  }

  Color _returnFriendNoteColor() {
    switch (_friend.personalNoteColor) {
      case 'red':
        return Colors.red;
        break;
      case 'blue':
        return Colors.blue;
        break;
      case 'green':
        return Colors.green;
        break;
      default:
        return _themeProvider.mainText;
        break;
    }
  }

  Future<void> _showNotesDialog() {
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
              child: PersonalNotesDialog(
                noteType: PersonalNoteType.friend,
                friendModel: _friend,
              ),
            ),
          );
        });
  }

  void _updateThisFriend() async {
    bool updateWorked = await _friendsProvider.updateFriend(_friend);
    if (updateWorked) {
    } else {
      Scaffold.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Error updating ${_friend.name}!',
          ),
        ),
      );
    }
  }

  void _timerUpdateInformation() {
    setState(() {
      _returnLastUpdated();
    });
  }
}
