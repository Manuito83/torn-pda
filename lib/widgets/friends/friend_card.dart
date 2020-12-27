import 'dart:async';
import 'package:animations/animations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/friends/friend_model.dart';
import 'package:torn_pda/pages/friends/friend_details_page.dart';
import 'package:torn_pda/providers/friends_provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/utils/html_parser.dart';
import 'package:torn_pda/widgets/webviews/webview_full.dart';
import 'package:url_launcher/url_launcher.dart';
import '../notes_dialog.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:torn_pda/widgets/webviews/webview_dialog.dart';

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
              BotToast.showText(
                text: 'Deleted ${_friend.name}!',
                textStyle: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
                contentColor: Colors.orange[800],
                duration: Duration(seconds: 3),
                contentPadding: EdgeInsets.all(10),
              );
            }),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        child: Card(
          shape: RoundedRectangleBorder(
              side: BorderSide(color: _cardBorderColor(), width: 1.5),
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        _visitProfileIcon(),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                        ),
                        SizedBox(
                          width: 120,
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
                          OpenContainer(
                            transitionDuration: Duration(milliseconds: 500),
                            transitionType: ContainerTransitionType.fadeThrough,
                            openBuilder:
                                (BuildContext context, VoidCallback _) {
                              return FriendDetailsPage(friend: _friend);
                            },
                            closedElevation: 0,
                            closedShape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(56 / 2),
                              ),
                            ),
                            closedColor: Colors.transparent,
                            closedBuilder: (BuildContext context,
                                VoidCallback openContainer) {
                              return SizedBox(
                                height: 20,
                                width: 20,
                                child: Icon(
                                  Icons.info_outline,
                                  size: 20,
                                ),
                              );
                            },
                          ),
                          Row(
                            children: <Widget>[
                              _tradeIcon(),
                              SizedBox(width: 8),
                              _messageIcon(),
                            ],
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text(
                          'Lvl ${_friend.level}',
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 15),
                          child: _factionIcon(),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: _companyIcon(),
                        ),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(left: 15),
                          child: _status(),
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
                        icon: Icon(MdiIcons.notebookEditOutline),
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

  Widget _tradeIcon() {
    var tradeUrl = 'https://www.torn.com/trade.php#step=start&user'
        'ID=${_friend.playerId}';
    return SizedBox(
      height: 20,
      width: 20,
      child: GestureDetector(
        child: Icon(
          Icons.swap_horiz,
          size: 20,
        ),
        onTap: () async {
          _settingsProvider.useQuickBrowser
              ? openBrowserDialog(context, tradeUrl)
              : _openTornBrowser(tradeUrl);
        },
        onLongPress: () async {
          _openTornBrowser(tradeUrl);
        },
      ),
    );
  }

  Widget _messageIcon() {
    var messageUrl = 'https://www.torn.com/messages.php#/p=compose&'
        'XID=${_friend.playerId}';
    return SizedBox(
      height: 20,
      width: 20,
      child: GestureDetector(
        child: Icon(
          Icons.email,
          size: 20,
        ),
        onTap: () async {
          _settingsProvider.useQuickBrowser
              ? openBrowserDialog(context, messageUrl)
              : _openTornBrowser(messageUrl);
        },
        onLongPress: () async {
          _openTornBrowser(messageUrl);
        },
      ),
    );
  }

  Widget _visitProfileIcon() {
    String profileUrl =
        'https://www.torn.com/profiles.php?XID=${_friend.playerId}';
    return SizedBox(
      height: 20,
      width: 20,
      child: GestureDetector(
        child: Icon(
          Icons.remove_red_eye,
          size: 20,
        ),
        onTap: () async {
          _settingsProvider.useQuickBrowser
              ? openBrowserDialog(context, profileUrl)
              : _openTornBrowser(profileUrl);
        },
        onLongPress: () async {
          _openTornBrowser(profileUrl);
        },
      ),
    );
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
      Color borderColor = Colors.transparent;
      Color iconColor = _themeProvider.mainText;
      if (_friend.faction.factionId == _userProvider.myUser.faction.factionId) {
        borderColor = iconColor = Colors.green[500];
      }

      void showFactionToast() {
        if (_friend.faction.factionId ==
            _userProvider.myUser.faction.factionId) {
          BotToast.showText(
            text: HtmlParser.fix("${_friend.name} belongs to your same faction "
                "(${_friend.faction.factionName}) as "
                "${_friend.faction.position}"),
            textStyle: TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            contentColor: Colors.green,
            duration: Duration(seconds: 5),
            contentPadding: EdgeInsets.all(10),
          );
        } else {
          BotToast.showText(
            text: HtmlParser.fix("${_friend.name} belongs to faction "
                "${_friend.faction.factionName} as "
                "${_friend.faction.position}"),
            textStyle: TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            contentColor: Colors.grey[600],
            duration: Duration(seconds: 5),
            contentPadding: EdgeInsets.all(10),
          );
        }
      }

      Widget factionIcon = Material(
        type: MaterialType.transparency,
        child: Ink(
          decoration: BoxDecoration(
            border: Border.all(
              color: borderColor,
              width: 1.5,
            ),
            shape: BoxShape.circle,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(100),
            onTap: () {
              showFactionToast();
            },
            child: Padding(
              padding: EdgeInsets.all(2),
              child: ImageIcon(
                AssetImage('images/icons/faction.png'),
                size: 12,
                color: iconColor,
              ),
            ),
          ),
        ),
      );
      return factionIcon;
    } else {
      return SizedBox.shrink();
    }
  }

  Widget _companyIcon() {
    void showCompanyToast() {
      BotToast.showText(
        text: HtmlParser.fix("${_friend.name} belongs to your same company "
            "(${_friend.job.companyName}) as "
            "${_friend.job.position}"),
        textStyle: TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
        contentColor: Colors.green,
        duration: Duration(seconds: 5),
        contentPadding: EdgeInsets.all(10),
      );
    }

    if (_friend.job.companyId == _userProvider.myUser.job.companyId) {
      Widget companyIcon = Material(
        type: MaterialType.transparency,
        child: Ink(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.brown[400],
              width: 1.5,
            ),
            shape: BoxShape.circle,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(100),
            onTap: () {
              showCompanyToast();
            },
            child: Padding(
              padding: EdgeInsets.all(1),
              child: Icon(
                Icons.business_center,
                size: 14,
                color: Colors.brown[400],
              ),
            ),
          ),
        ),
      );
      return companyIcon;
    }
    return SizedBox.shrink();
  }

  Widget _status() {
    Color stateColor;
    if (_friend.status.color == 'red') {
      stateColor = Colors.red;
    } else if (_friend.status.color == 'green') {
      stateColor = Colors.green;
    } else if (_friend.status.color == 'blue') {
      stateColor = Colors.blue;
    }

    Widget stateBall = Padding(
      padding: EdgeInsets.only(left: 5, right: 3, top: 1),
      child: Container(
        width: 13,
        height: 13,
        decoration: BoxDecoration(
            color: stateColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black)),
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(_friend.status.state),
        stateBall,
      ],
    );
  }

  Color _cardBorderColor() {
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
      case 'orange':
        return Colors.orange[600];
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
      BotToast.showText(
        text: "Error updating ${_friend.name}!",
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

  void _timerUpdateInformation() {
    setState(() {
      _returnLastUpdated();
    });
  }

  Future _openTornBrowser(String page) async {
    var browserType = _settingsProvider.currentBrowser;

    switch (browserType) {
      case BrowserSetting.app:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext context) => WebViewFull(
              customUrl: page,
              customTitle: 'Torn',
            ),
          ),
        );
        break;
      case BrowserSetting.external:
        var url = page;
        if (await canLaunch(url)) {
          await launch(url, forceSafariVC: false);
        }
        break;
    }
  }

}
