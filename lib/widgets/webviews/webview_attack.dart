import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chaining/target_model.dart';
import 'package:torn_pda/providers/chain_status_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/utils/api_caller.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/chaining/chain_timer.dart';
import 'package:torn_pda/widgets/webviews/custom_appbar.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TornWebViewAttack extends StatefulWidget {
  final List<String> attackIdList;
  final List<String> attackNameList;
  final List<String> attackNotesList;
  final List<String> attackNotesColorList;
  final Function(List<String>) attacksCallback;
  final String userKey;

  /// [attackIdList] and [attackNameList] make sense for attacks series
  /// [attacksCallback] is used to update the targets card when we go back
  TornWebViewAttack({
    this.attackIdList = const [],
    this.attackNameList = const [],
    this.attackNotesList = const [],
    this.attackNotesColorList = const [],
    this.attacksCallback,
    @required this.userKey,
  });

  @override
  _TornWebViewAttackState createState() => _TornWebViewAttackState();
}

class _TornWebViewAttackState extends State<TornWebViewAttack> {
  WebViewController _webViewController;

  UserDetailsProvider _userProv;
  ChainStatusProvider _chainStatusProvider;

  String _initialUrl = "";
  String _currentPageTitle = "";

  bool _skippingEnabled = true;
  bool _showNotes = true;
  int _attackNumber = 0;
  List<String> _attackedIds = [];

  bool _backButtonPopsContext = true;
  String _goBackTitle = '';

  var _chainWidgetController = ExpandableController();

  bool _nextButtonPressed = false;

  final _popupChoices = <HealingPages>[
    HealingPages(description: "Personal"),
    HealingPages(description: "Faction"),
  ];

  @override
  void initState() {
    super.initState();

    // Enable hybrid composition
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();

    _loadPreferences();
    _userProv = Provider.of<UserDetailsProvider>(context, listen: false);
    _initialUrl = 'https://www.torn.com/loader.php?sid=attack&user2ID=${widget.attackIdList[0]}';
    _currentPageTitle = '${widget.attackNameList[0]}';
    _attackedIds.add(widget.attackIdList[0]);
    _chainStatusProvider = context.read<ChainStatusProvider>();
    if (_chainStatusProvider.watcherActive) {
      _chainWidgetController.expanded = true;
    }
  }

  @override
  void dispose() {
    _chainWidgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _willPopCallback,
      child: Scaffold(
        appBar: CustomAppBar(
          onHorizontalDragEnd: (DragEndDetails details) async {
            await _goBackOrForward(details);
          },
          genericAppBar: AppBar(
            leading: IconButton(
                icon: _backButtonPopsContext ? Icon(Icons.close) : Icon(Icons.arrow_back_ios),
                onPressed: () async {
                  // Normal behaviour is just to pop and go to previous page
                  if (_backButtonPopsContext) {
                    _willPopCallback();
                    Navigator.pop(context);
                  } else {
                    // But we can change and go back to previous page in certain
                    // situations (e.g. when going for medical items during an
                    // attack), in which case we need to return to previous target
                    var backPossible = await _webViewController.canGoBack();
                    if (backPossible) {
                      _webViewController.goBack();
                      setState(() {
                        _currentPageTitle = _goBackTitle;
                      });
                    } else {
                      Navigator.pop(context);
                    }
                    _backButtonPopsContext = true;
                  }
                }),
            title: GestureDetector(
              child: Text(_currentPageTitle),
              onLongPress: () async {
                var url = await _webViewController.currentUrl();
                Clipboard.setData(ClipboardData(text: url));
                if (url.length > 60) {
                  url = url.substring(0, 60) + "...";
                }
                BotToast.showText(
                  text: "Current URL copied to the clipboard [$url]",
                  textStyle: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  contentColor: Colors.green,
                  duration: Duration(seconds: 5),
                  contentPadding: EdgeInsets.all(10),
                );
              },
            ),
            actions: _actionButtons(),
          ),
        ),
        body: Container(
          color: Colors.grey[900],
          child: SafeArea(
            top: false,
            right: false,
            left: false,
            bottom: true,
            child: Builder(
              builder: (BuildContext context) {
                return Column(
                  children: [
                    ExpandablePanel(
                      theme: ExpandableThemeData(
                        hasIcon: false,
                        tapBodyToCollapse: false,
                        tapHeaderToExpand: false,
                      ),
                      collapsed: SizedBox.shrink(),
                      controller: _chainWidgetController,
                      header: SizedBox.shrink(),
                      expanded: ChainTimer(
                        userKey: widget.userKey,
                        alwaysDarkBackground: true,
                        chainTimerParent: ChainTimerParent.webView,
                      ),
                    ),
                    Expanded(
                      child: WebView(
                        initialUrl: _initialUrl,
                        javascriptMode: JavascriptMode.unrestricted,
                        onWebViewCreated: (WebViewController c) {
                          _webViewController = c;
                        },
                        gestureNavigationEnabled: true,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future _goBackOrForward(DragEndDetails details) async {
    if (details.primaryVelocity < 0) {
      var canForward = await _webViewController.canGoForward();
      if (canForward) {
        await _webViewController.goForward();
        BotToast.showText(
          text: "Forward",
          textStyle: TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
          contentColor: Colors.grey[600],
          duration: Duration(seconds: 1),
          contentPadding: EdgeInsets.all(10),
        );
      } else {
        BotToast.showText(
          text: "Can\'t go forward!",
          textStyle: TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
          contentColor: Colors.grey[600],
          duration: Duration(seconds: 1),
          contentPadding: EdgeInsets.all(10),
        );
      }
    } else if (details.primaryVelocity > 0) {
      var canBack = await _webViewController.canGoBack();
      if (canBack) {
        await _webViewController.goBack();
        BotToast.showText(
          text: "Back",
          textStyle: TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
          contentColor: Colors.grey[600],
          duration: Duration(seconds: 1),
          contentPadding: EdgeInsets.all(10),
        );
      } else {
        BotToast.showText(
          text: "Can\'t go back!",
          textStyle: TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
          contentColor: Colors.grey[600],
          duration: Duration(seconds: 1),
          contentPadding: EdgeInsets.all(10),
        );
      }
    }
  }

  List<Widget> _actionButtons() {
    List<Widget> myButtons = List<Widget>();

    myButtons.add(
      IconButton(
        icon: Icon(MdiIcons.refresh),
        onPressed: () async {
          await _webViewController.reload();
        },
      ),
    );

    myButtons.add(
      IconButton(
        icon: Icon(MdiIcons.linkVariant),
        onPressed: () {
          _chainWidgetController.expanded
              ? _chainWidgetController.expanded = false
              : _chainWidgetController.expanded = true;
        },
      ),
    );

    myButtons.add(_medicalActionButton());

    if (_attackNumber < widget.attackIdList.length - 1) {
      myButtons.add(_nextAttackActionButton());
    } else {
      myButtons.add(SizedBox.shrink());
    }

    return myButtons;
  }

  Widget _nextAttackActionButton() {
    var nextBaseUrl = 'https://www.torn.com/loader.php?sid=attack&user2ID=';
    return IconButton(
      icon: Icon(Icons.skip_next),
      onPressed: _nextButtonPressed
          ? null
          : () async {
              // Turn button grey
              setState(() {
                _nextButtonPressed = true;
              });

              if (_skippingEnabled) {
                // Counters for target skipping
                int targetsSkipped = 0;
                var originalPosition = _attackNumber;
                bool reachedEnd = false;
                var skippedNames = List<String>();

                // We'll skip maximum of 3 targets
                for (var i = 0; i < 3; i++) {
                  // Get the status of our next target
                  var nextTarget = await TornApiCaller.target(
                          _userProv.myUser.userApiKey, widget.attackIdList[_attackNumber + 1])
                      .getTarget;

                  if (nextTarget is TargetModel) {
                    // If in hospital or jail (even in a different country), we skip
                    if (nextTarget.status.color == "red") {
                      targetsSkipped++;
                      skippedNames.add(nextTarget.name);
                      _attackNumber++;
                    }
                    // If flying, we need to see if he is in a different country (if we are in the same
                    // place, we can attack him)
                    else if (nextTarget.status.color == "blue") {
                      var user = await TornApiCaller.target(
                              _userProv.myUser.userApiKey, _userProv.myUser.playerId.toString())
                          .getTarget;
                      if (user is TargetModel) {
                        if (user.status.description != nextTarget.status.description) {
                          targetsSkipped++;
                          skippedNames.add(nextTarget.name);
                          _attackNumber++;
                        }
                      }
                    }
                    // If we found a good target, we break here
                    else {
                      break;
                    }
                    // If after looping we are over the target limit, it means we have reached the end
                    // in which case we reset the position to the last target we attacked, and break
                    if (_attackNumber >= widget.attackIdList.length - 1) {
                      _attackNumber = originalPosition;
                      reachedEnd = true;
                      break;
                    }
                  }
                  // If there is an error getting a target, don't skip
                  else {
                    break;
                  }
                }

                if (targetsSkipped > 0 && !reachedEnd) {
                  BotToast.showText(
                    text:
                        "Skipped ${skippedNames.join(", ")}, either in jail, hospital or in a different "
                        "country",
                    textStyle: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    contentColor: Colors.grey[600],
                    duration: Duration(seconds: 5),
                    contentPadding: EdgeInsets.all(10),
                  );
                }

                if (targetsSkipped > 0 && reachedEnd) {
                  BotToast.showText(
                    text:
                        "No more targets, all remaining are either in jail, hospital or in a different "
                        "country (${skippedNames.join(", ")})",
                    textStyle: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    contentColor: Colors.grey[600],
                    duration: Duration(seconds: 5),
                    contentPadding: EdgeInsets.all(10),
                  );

                  setState(() {
                    _nextButtonPressed = false;
                  });
                  return;
                }
              }

              _attackNumber++;
              await _webViewController.loadUrl('$nextBaseUrl${widget.attackIdList[_attackNumber]}');
              _attackedIds.add(widget.attackIdList[_attackNumber]);
              setState(() {
                _currentPageTitle = '${widget.attackNameList[_attackNumber]}';
              });
              _backButtonPopsContext = true;

              // Turn button back to usable
              setState(() {
                _nextButtonPressed = false;
              });

              // Show note for next target
              if (_showNotes) {
                _showNoteToast();
              }
            },
    );
  }

  Widget _medicalActionButton() {
    return PopupMenuButton<HealingPages>(
      icon: Icon(Icons.healing),
      onSelected: _openHealingPage,
      itemBuilder: (BuildContext context) {
        return _popupChoices.map((HealingPages choice) {
          return PopupMenuItem<HealingPages>(
            value: choice,
            child: Text(choice.description),
          );
        }).toList();
      },
    );
  }

  void _openHealingPage(HealingPages choice) async {
    _goBackTitle = _currentPageTitle;
    // Check if the proper page loads (e.g. if we have started an attack,
    // it won't let us change to another page!). Note: this is something
    // that can't be done from one target to another, but only between
    // different sections (not sure why).
    await _webViewController.loadUrl('${choice.url}');
    await Future.delayed(const Duration(seconds: 1), () {});
    var newUrl = await _webViewController.currentUrl();
    if (newUrl == '${choice.url}') {
      setState(() {
        _currentPageTitle = 'Items';
      });
      _backButtonPopsContext = false;
    }
  }

  void _showNoteToast() {
    // Do nothing if note is empty
    if (widget.attackNotesList[_attackNumber].isEmpty) {
      return;
    }

    Color cardColor;
    switch (widget.attackNotesColorList[_attackNumber]) {
      case '':
        cardColor = Colors.grey[700];
        break;
      case 'green':
        cardColor = Colors.green[900];
        break;
      case 'orange':
        cardColor = Colors.orange[900];
        break;
      case 'red':
        cardColor = Colors.red[900];
        break;
    }

    BotToast.showCustomText(
      clickClose: true,
      ignoreContentClick: true,
      duration: Duration(seconds: 5),
      toastBuilder: (textCancel) => Align(
        alignment: Alignment(0, 0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Card(
            color: cardColor,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        MdiIcons.notebookOutline,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Note for ${widget.attackNameList[_attackNumber]}',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  SizedBox(height: 2),
                  SizedBox(height: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          '${widget.attackNotesList[_attackNumber]}',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future _loadPreferences() async {
    _skippingEnabled = await SharedPreferencesModel().getTargetSkipping();
    _showNotes = await SharedPreferencesModel().getShowTargetsNotes();

    // This will show the note of the first target, if applicable
    if (_showNotes) {
      _showNoteToast();
    }
  }

  Future<bool> _willPopCallback() async {
    widget.attacksCallback(_attackedIds);
    _chainStatusProvider.watcherAssignParent(newParent: ChainTimerParent.targets);
    return true;
  }
}

class HealingPages {
  String description;
  String url;

  HealingPages({this.description}) {
    switch (description) {
      case "Personal":
        url = 'https://www.torn.com/item.php#medical-items';
        break;
      case "Faction":
        url = 'https://www.torn.com/factions.php?step=your#/tab=armoury&start=0&sub=medical';
        break;
    }
  }
}
