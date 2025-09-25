// Dart imports:
import 'dart:async';

// Package imports:
import 'package:animations/animations.dart';
import 'package:bot_toast/bot_toast.dart';
// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
// Project imports:
import 'package:torn_pda/models/friends/friend_model.dart';
import 'package:torn_pda/pages/friends/friend_details_page.dart';
import 'package:torn_pda/providers/friends_provider.dart';
import 'package:torn_pda/providers/player_notes_controller.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/html_parser.dart';
import 'package:torn_pda/utils/user_helper.dart';
import 'package:torn_pda/widgets/player_notes_dialog.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';

class FriendCard extends StatefulWidget {
  final FriendModel friendModel;

  const FriendCard({required this.friendModel});

  @override
  FriendCardState createState() => FriendCardState();
}

class FriendCardState extends State<FriendCard> {
  FriendModel? _friend;
  late FriendsProvider _friendsProvider;
  late ThemeProvider _themeProvider;

  Timer? _ticker;

  String? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 60), (Timer t) => _timerUpdateInformation());
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
    _themeProvider = Provider.of<ThemeProvider>(context);
    return Slidable(
      startActionPane: ActionPane(
        extentRatio: 0.25,
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            label: 'Remove',
            backgroundColor: Colors.red,
            icon: Icons.delete,
            onPressed: (context) {
              BotToast.showText(
                text: 'Deleted ${_friend!.name}!',
                textStyle: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
                contentColor: Colors.orange[800]!,
                duration: const Duration(seconds: 3),
                contentPadding: const EdgeInsets.all(10),
              );
              Provider.of<FriendsProvider>(context, listen: false).deleteFriend(_friend);
            },
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Card(
          shape: RoundedRectangleBorder(
            side: BorderSide(color: _cardBorderColor(), width: 1.5),
            borderRadius: BorderRadius.circular(4.0),
          ),
          elevation: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // LINE 1
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(15, 5, 15, 0),
                child: Row(
                  children: <Widget>[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        _visitProfileIcon(),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                        ),
                        SizedBox(
                          width: 120,
                          child: Text(
                            '${_friend!.name}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          OpenContainer(
                            transitionDuration: const Duration(milliseconds: 300),
                            transitionType: ContainerTransitionType.fade,
                            openBuilder: (BuildContext context, VoidCallback _) {
                              return FriendDetailsPage(friend: _friend);
                            },
                            closedElevation: 0,
                            closedShape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(56 / 2),
                              ),
                            ),
                            closedColor: Colors.transparent,
                            openColor: _themeProvider.canvas,
                            closedBuilder: (BuildContext context, VoidCallback openContainer) {
                              return const SizedBox(
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
                              const SizedBox(width: 8),
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
                padding: const EdgeInsetsDirectional.fromSTEB(15, 5, 15, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text(
                          'Lvl ${_friend!.level}',
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
                padding: const EdgeInsetsDirectional.fromSTEB(17, 5, 15, 0),
                child: Row(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: _returnStatusColor(_friend!.lastAction!.status),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 12),
                          child: Text(
                            'Action: ',
                          ),
                        ),
                        Text(
                          _friend!.lastAction!.relative == "0 minutes ago"
                              ? 'now'
                              : _friend!.lastAction!.relative!.replaceAll(' ago', ''),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          Text('$_lastUpdated'),
                          const SizedBox(width: 8),
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
                padding: const EdgeInsetsDirectional.fromSTEB(15, 5, 15, 0),
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: IconButton(
                        padding: const EdgeInsets.all(0),
                        iconSize: 20,
                        icon: Icon(
                          MdiIcons.notebookEditOutline,
                          color: _returnFriendNoteColor(),
                        ),
                        onPressed: () {
                          _showNotesDialog();
                        },
                      ),
                    ),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(start: 8),
                        child: Row(
                          children: <Widget>[
                            const Text('Notes: '),
                            GetBuilder<PlayerNotesController>(
                              builder: (ctrl) {
                                final note = ctrl.getNoteForPlayer(_friend!.playerId.toString());
                                final text = note?.effectiveDisplayText ?? '';
                                return Flexible(
                                  child: Text(
                                    text,
                                    style: TextStyle(
                                      color: _returnFriendNoteColor(),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tradeIcon() {
    final tradeUrl = 'https://www.torn.com/trade.php#step=start&user'
        'ID=${_friend!.playerId}';
    return SizedBox(
      height: 20,
      width: 20,
      child: GestureDetector(
        child: const Icon(
          Icons.swap_horiz,
          size: 20,
        ),
        onTap: () async {
          await context.read<WebViewProvider>().openBrowserPreference(
                context: context,
                url: tradeUrl,
                browserTapType: BrowserTapType.short,
              );
        },
        onLongPress: () async {
          await context.read<WebViewProvider>().openBrowserPreference(
                context: context,
                url: tradeUrl,
                browserTapType: BrowserTapType.long,
              );
        },
      ),
    );
  }

  Widget _messageIcon() {
    final messageUrl = 'https://www.torn.com/messages.php#/p=compose&'
        'XID=${_friend!.playerId}';
    return SizedBox(
      height: 20,
      width: 20,
      child: GestureDetector(
        child: const Icon(
          Icons.email,
          size: 20,
        ),
        onTap: () async {
          await context.read<WebViewProvider>().openBrowserPreference(
                context: context,
                url: messageUrl,
                browserTapType: BrowserTapType.short,
              );
        },
        onLongPress: () async {
          await context.read<WebViewProvider>().openBrowserPreference(
                context: context,
                url: messageUrl,
                browserTapType: BrowserTapType.long,
              );
        },
      ),
    );
  }

  Widget _visitProfileIcon() {
    final String profileUrl = 'https://www.torn.com/profiles.php?XID=${_friend!.playerId}';
    return SizedBox(
      height: 20,
      width: 20,
      child: GestureDetector(
        child: const Icon(
          Icons.remove_red_eye,
          size: 20,
        ),
        onTap: () async {
          await context.read<WebViewProvider>().openBrowserPreference(
                context: context,
                url: profileUrl,
                browserTapType: BrowserTapType.short,
              );
        },
        onLongPress: () async {
          await context.read<WebViewProvider>().openBrowserPreference(
                context: context,
                url: profileUrl,
                browserTapType: BrowserTapType.long,
              );
        },
      ),
    );
  }

  Widget _refreshIcon() {
    if (_friend!.isUpdating) {
      return const Padding(
        padding: EdgeInsets.all(2.0),
        child: CircularProgressIndicator(),
      );
    } else {
      return IconButton(
        padding: const EdgeInsets.all(0.0),
        iconSize: 20,
        icon: const Icon(Icons.refresh),
        onPressed: () async {
          _updateThisFriend();
        },
      );
    }
  }

  Widget _factionIcon() {
    if (_friend!.hasFaction!) {
      Color? borderColor = Colors.transparent;
      Color? iconColor = _themeProvider.mainText;
      if (_friend!.faction!.factionId == UserHelper.factionId) {
        borderColor = iconColor = Colors.green[500];
      }

      void showFactionToast() {
        if (_friend!.faction!.factionId == UserHelper.factionId) {
          BotToast.showText(
            text: HtmlParser.fix("${_friend!.name} belongs to your same faction "
                "(${_friend!.faction!.factionName}) as "
                "${_friend!.faction!.position}"),
            textStyle: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            contentColor: Colors.green,
            duration: const Duration(seconds: 5),
            contentPadding: const EdgeInsets.all(10),
          );
        } else {
          BotToast.showText(
            text: HtmlParser.fix("${_friend!.name} belongs to faction "
                "${_friend!.faction!.factionName} as "
                "${_friend!.faction!.position}"),
            textStyle: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            contentColor: Colors.grey[600]!,
            duration: const Duration(seconds: 5),
            contentPadding: const EdgeInsets.all(10),
          );
        }
      }

      final Widget factionIcon = Material(
        type: MaterialType.transparency,
        child: Ink(
          decoration: BoxDecoration(
            border: Border.all(
              color: borderColor!,
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
              padding: const EdgeInsets.all(2),
              child: ImageIcon(
                const AssetImage('images/icons/faction.png'),
                size: 12,
                color: iconColor,
              ),
            ),
          ),
        ),
      );
      return factionIcon;
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _companyIcon() {
    void showCompanyToast() {
      BotToast.showText(
        text: HtmlParser.fix("${_friend!.name} belongs to your same company "
            "(${_friend!.job!.companyName}) as "
            "${_friend!.job!.job}"),
        textStyle: const TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
        contentColor: Colors.green,
        duration: const Duration(seconds: 5),
        contentPadding: const EdgeInsets.all(10),
      );
    }

    if (_friend!.job!.companyId == UserHelper.companyId) {
      final Widget companyIcon = Material(
        type: MaterialType.transparency,
        child: Ink(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.brown[400]!,
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
              padding: const EdgeInsets.all(1),
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
    return const SizedBox.shrink();
  }

  Widget _status() {
    Color? stateColor;
    if (_friend!.status!.color == 'red') {
      stateColor = Colors.red;
    } else if (_friend!.status!.color == 'green') {
      stateColor = Colors.green;
    } else if (_friend!.status!.color == 'blue') {
      stateColor = Colors.blue;
    }

    final Widget stateBall = Padding(
      padding: const EdgeInsets.only(left: 5, right: 3, top: 1),
      child: Container(
        width: 13,
        height: 13,
        decoration: BoxDecoration(color: stateColor, shape: BoxShape.circle, border: Border.all()),
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(_friend!.status!.state!),
        stateBall,
      ],
    );
  }

  Color _cardBorderColor() {
    if (_friend!.justUpdatedWithSuccess) {
      return Colors.green;
    } else if (_friend!.justUpdatedWithError) {
      return Colors.red;
    } else {
      return Colors.transparent;
    }
  }

  Color _returnStatusColor(String? status) {
    switch (status) {
      case 'Online':
        return Colors.green;
      case 'Idle':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _returnLastUpdated() {
    final timeDifference = DateTime.now().difference(_friend!.lastUpdated!);
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

  Color? _returnFriendNoteColor() {
    final noteColor = Get.find<PlayerNotesController>().getNoteForPlayer(_friend!.playerId.toString())?.color ?? '';
    switch (noteColor) {
      case 'red':
        return Colors.red;
      case 'orange':
        return Colors.orange[600];
      case 'green':
        return Colors.green;
      default:
        return _themeProvider.mainText;
    }
  }

  Future<void> _showNotesDialog() {
    return showPlayerNotesDialog(
      context: context,
      barrierDismissible: false,
      playerId: _friend?.playerId.toString() ?? '',
      playerName: _friend?.name ?? '',
    );
  }

  Future<void> _updateThisFriend() async {
    final bool updateWorked = await _friendsProvider.updateFriend(_friend!);
    if (updateWorked) {
    } else {
      BotToast.showText(
        text: "Error updating ${_friend!.name}!",
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

  void _timerUpdateInformation() {
    setState(() {
      _returnLastUpdated();
    });
  }
}
