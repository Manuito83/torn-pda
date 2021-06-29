// Dart imports:
import 'dart:async';
import 'dart:io';

// Flutter imports:
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:animations/animations.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:expandable/expandable.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/widgets/webviews/webview_url_dialog.dart';
import 'package:webview_flutter/webview_flutter.dart';

// Project imports:
import 'package:torn_pda/models/chaining/target_model.dart';
import 'package:torn_pda/pages/quick_items/quick_items_options.dart';
import 'package:torn_pda/providers/chain_status_provider.dart';
import 'package:torn_pda/providers/quick_items_provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/utils/api_caller.dart';
import 'package:torn_pda/utils/js_snippets.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/chaining/chain_widget.dart';
import 'package:torn_pda/widgets/other/profile_check.dart';
import 'package:torn_pda/widgets/quick_items/quick_items_widget.dart';
import 'package:torn_pda/widgets/webviews/custom_appbar.dart';

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
    @required this.attackIdList,
    @required this.attackNameList,
    @required this.attackNotesList,
    @required this.attackNotesColorList,
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
  SettingsProvider _settingsProvider;
  ThemeProvider _themeProvider;

  final _chainWidgetKey = GlobalKey();

  String _initialUrl = "";
  String _currentPageTitle = "";

  var _chatRemovalEnabled = true;
  var _chatRemovalActive = false;

  bool _skippingEnabled = true;
  bool _showNotes = true;
  bool _showOnlineFactionWarning = true;
  int _attackNumber = 0;
  List<String> _attackedIds = [];

  String _factionName = "";
  int _lastOnline = 0;

  bool _backButtonPopsContext = true;
  String _goBackTitle = '';

  var _chainWidgetController = ExpandableController();

  bool _nextButtonPressed = false;

  final _popupChoices = <HealingPages>[
    HealingPages(description: "Personal"),
    HealingPages(description: "Faction"),
  ];

  // NOT APPLICABLE UNLESS USING ON PROGRESS
  // bool _quickItemsTriggered = false;
  var _quickItemsActive = false;
  var _quickItemsController = ExpandableController();

  Widget _profileAttackWidget = SizedBox.shrink();
  var _lastProfileVisited = "";

  @override
  void initState() {
    super.initState();

    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

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
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return WillPopScope(
      onWillPop: _willPopCallback,
      child: Container(
        color: _themeProvider.currentTheme == AppTheme.light
            ? MediaQuery.of(context).orientation == Orientation.portrait
                ? Colors.blueGrey
                : Colors.grey[900]
            : Colors.grey[900],
        child: SafeArea(
          top: _settingsProvider.appBarTop ? false : true,
          bottom: true,
          child: Scaffold(
            appBar: _settingsProvider.appBarTop ? buildCustomAppBar() : null,
            bottomNavigationBar: !_settingsProvider.appBarTop
                ? SizedBox(
                    height: AppBar().preferredSize.height,
                    child: buildCustomAppBar(),
                  )
                : null,
            body: Builder(
              builder: (BuildContext context) {
                return Container(
                  // Background color for all browser widgets
                  color: Colors.grey[900],
                  child: Column(
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
                        expanded: ChainWidget(
                          key: _chainWidgetKey,
                          userKey: widget.userKey,
                          alwaysDarkBackground: true,
                        ),
                      ),
                      // Quick items widget. NOTE: this one will open at the bottom if
                      // appBar is at the bottom, so it's duplicated below the actual
                      // webView widget
                      _settingsProvider.appBarTop
                          ? ExpandablePanel(
                              theme: ExpandableThemeData(
                                hasIcon: false,
                                tapBodyToCollapse: false,
                                tapHeaderToExpand: false,
                              ),
                              collapsed: SizedBox.shrink(),
                              controller: _quickItemsController,
                              header: SizedBox.shrink(),
                              expanded: _quickItemsActive
                                  ? QuickItemsWidget(
                                      webViewController: _webViewController,
                                      appBarTop: _settingsProvider.appBarTop,
                                      browserDialog: false,
                                      webviewType: 'attacks',
                                    )
                                  : SizedBox.shrink(),
                            )
                          : SizedBox.shrink(),
                      _profileAttackWidget,
                      Expanded(
                        child: WebView(
                          initialUrl: _initialUrl,
                          javascriptMode: JavascriptMode.unrestricted,
                          onWebViewCreated: (WebViewController c) {
                            _webViewController = c;
                          },
                          onPageStarted: (page) {
                            _hideChat();
                            _assessProfileAttack(page);
                          },
                          onPageFinished: (page) {
                            _hideChat();
                            _highlightChat(page);
                            _assessQuickItems(page);
                          },
                          gestureNavigationEnabled: true,
                        ),
                      ),
                      !_settingsProvider.appBarTop
                          ? ExpandablePanel(
                              theme: ExpandableThemeData(
                                hasIcon: false,
                                tapBodyToCollapse: false,
                                tapHeaderToExpand: false,
                              ),
                              collapsed: SizedBox.shrink(),
                              controller: _quickItemsController,
                              header: SizedBox.shrink(),
                              expanded: _quickItemsActive
                                  ? QuickItemsWidget(
                                      webViewController: _webViewController,
                                      appBarTop: _settingsProvider.appBarTop,
                                      browserDialog: false,
                                      webviewType: 'attacks',
                                    )
                                  : SizedBox.shrink(),
                            )
                          : SizedBox.shrink(),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _highlightChat(String page) {
    if (!page.contains('torn.com')) return;

    var intColor = Color(_settingsProvider.highlightColor);
    var background =
        'rgba(${intColor.red}, ${intColor.green}, ${intColor.blue}, ${intColor.opacity})';
    var senderColor = 'rgba(${intColor.red}, ${intColor.green}, ${intColor.blue}, 1)';
    String hlMap =
        '[ { name: "${_userProv.basic.name}", highlight: "$background", sender: "$senderColor" } ]';

    if (_settingsProvider.highlightChat) {
      _webViewController.evaluateJavascript(
        chatHighlightJS(highlightMap: hlMap),
      );
    }
  }

  void _hideChat() {
    if (_chatRemovalEnabled && _chatRemovalActive) {
      _webViewController.evaluateJavascript(removeChatOnLoadStartJS());
    }
  }

  CustomAppBar buildCustomAppBar() {
    return CustomAppBar(
      onHorizontalDragEnd: (DragEndDetails details) async {
        await _goBackOrForward(details);
      },
      genericAppBar: AppBar(
        brightness: Brightness.dark,
        leading: IconButton(
            icon: _backButtonPopsContext ? Icon(Icons.close) : Icon(Icons.arrow_back_ios),
            onPressed: () async {
              // Normal behaviour is just to pop and go to previous page
              if (_backButtonPopsContext) {
                if (widget.attacksCallback != null) {
                  widget.attacksCallback(_attackedIds);
                }
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
          onTap: () {
            _openUrlDialog();
          },
          child: DottedBorder(
            borderType: BorderType.Rect,
            padding: EdgeInsets.all(6),
            dashPattern: [1, 4],
            color: Colors.white70,
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              child: Row(
                children: [
                  Flexible(
                      child: Text(
                    _currentPageTitle,
                    overflow: TextOverflow.fade,
                  )),
                ],
              ),
            ),
          ),
        ),
        actions: _actionButtons(),
      ),
    );
  }

  Future _goBackOrForward(DragEndDetails details) async {
    if (details.primaryVelocity < 0) {
      await _tryGoForward();
    } else if (details.primaryVelocity > 0) {
      await _tryGoBack();
    }
  }

  Future _tryGoForward() async {
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
  }

  Future _tryGoBack() async {
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

  Future<void> _openUrlDialog() async {
    var url = await _webViewController.currentUrl();
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return WebviewUrlDialog(
          title: _currentPageTitle,
          url: url.toString(),
          stockWebView: _webViewController,
        );
      },
    );
  }

  List<Widget> _actionButtons() {
    List<Widget> myButtons = [];

    myButtons.add(_quickItemsMenuIcon());

    Widget hideChatIcon = SizedBox.shrink();
    if (!_chatRemovalActive && _chatRemovalEnabled) {
      hideChatIcon = Padding(
        padding: const EdgeInsets.only(left: 15),
        child: GestureDetector(
          child: Icon(MdiIcons.chatOutline),
          onTap: () async {
            _webViewController.evaluateJavascript(removeChatJS());
            Prefs().setChatRemovalActive(true);
            setState(() {
              _chatRemovalActive = true;
            });
          },
        ),
      );
    } else if (_chatRemovalActive && _chatRemovalEnabled) {
      hideChatIcon = Padding(
        padding: const EdgeInsets.only(left: 15),
        child: GestureDetector(
          child: Icon(
            MdiIcons.chatRemoveOutline,
            color: Colors.orange[500],
          ),
          onTap: () async {
            _webViewController.evaluateJavascript(restoreChatJS());
            Prefs().setChatRemovalActive(false);
            setState(() {
              _chatRemovalActive = false;
            });
          },
        ),
      );
    }
    myButtons.add(hideChatIcon);

    myButtons.add(
      Padding(
        padding: const EdgeInsets.only(left: 15),
        child: GestureDetector(
          child: Icon(MdiIcons.refresh),
          onTap: () async {
            await _webViewController.reload();

            BotToast.showText(
              text: "Reloading...",
              textStyle: TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
              contentColor: Colors.grey[600],
              duration: Duration(seconds: 1),
              contentPadding: EdgeInsets.all(10),
            );
          },
        ),
      ),
    );

    myButtons.add(
      Padding(
        padding: const EdgeInsets.only(left: 15),
        child: GestureDetector(
          child: Icon(MdiIcons.linkVariant),
          onTap: () {
            _chainWidgetController.expanded
                ? _chainWidgetController.expanded = false
                : _chainWidgetController.expanded = true;
          },
        ),
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
                var skippedNames = [];

                // We'll skip maximum of 3 targets
                for (var i = 0; i < 3; i++) {
                  // Get the status of our next target
                  var nextTarget = await TornApiCaller.target(
                          _userProv.basic.userApiKey, widget.attackIdList[_attackNumber + 1])
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
                              _userProv.basic.userApiKey, _userProv.basic.playerId.toString())
                          .getTarget;
                      if (user is TargetModel) {
                        if (user.status.description != nextTarget.status.description) {
                          targetsSkipped++;
                          skippedNames.add(nextTarget.name);
                          _attackNumber++;
                        }
                      }
                    }
                    // If we found a good target, we break here. But before, we gather
                    // some more details if option is enabled
                    else {
                      if (_showOnlineFactionWarning) {
                        _factionName = nextTarget.faction.factionName;
                        _lastOnline = nextTarget.lastAction.timestamp;
                      }
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
                    _factionName = "";
                    _lastOnline = 0;
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
              // If skipping is disabled but notes are not, we still get information
              // from the API
              else {
                if (_showOnlineFactionWarning) {
                  var nextTarget = await TornApiCaller.target(
                          _userProv.basic.userApiKey, widget.attackIdList[_attackNumber + 1])
                      .getTarget;

                  if (nextTarget is TargetModel) {
                    _factionName = nextTarget.faction.factionName;
                    _lastOnline = nextTarget.lastAction.timestamp;
                  } else {
                    _factionName = "";
                    _lastOnline = 0;
                  }
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
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: PopupMenuButton<HealingPages>(
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
      ),
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
    Color cardColor;
    switch (widget.attackNotesColorList[_attackNumber]) {
      case 'z':
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
      default:
        cardColor = Colors.grey[700];
    }

    String extraInfo = "";
    if (_lastOnline > 0) {
      var now = DateTime.now();
      var lastOnlineDiff = now.difference(DateTime.fromMillisecondsSinceEpoch(_lastOnline * 1000));
      if (lastOnlineDiff.inDays < 7) {
        if (widget.attackNotesList[_attackNumber].isNotEmpty) {
          extraInfo += "\n\n";
        }
        if (lastOnlineDiff.inHours < 1) {
          extraInfo += "Online less than an hour ago!";
        } else if (lastOnlineDiff.inHours == 1) {
          extraInfo += "Online 1 hour ago!";
        } else if (lastOnlineDiff.inHours > 1 && lastOnlineDiff.inHours < 24) {
          extraInfo += "Online ${lastOnlineDiff.inHours} hours ago!";
        } else if (lastOnlineDiff.inDays == 1) {
          extraInfo += "Online yesterday!";
        } else if (lastOnlineDiff.inDays > 1) {
          extraInfo += "Online ${lastOnlineDiff.inDays} days ago!";
        }
        if (_factionName != "None" && _factionName != "") {
          extraInfo += "\nBelongs to faction $_factionName";
        }
      }
    }

    // Do nothing if note is empty
    if (widget.attackNotesList[_attackNumber].isEmpty && extraInfo.isEmpty) {
      return;
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (widget.attackNotesList[_attackNumber].isNotEmpty)
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
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  if (widget.attackNotesList[_attackNumber].isNotEmpty) SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          '${widget.attackNotesList[_attackNumber]}$extraInfo',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white),
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

  // QUICK ITEMS
  Future _assessQuickItems(String pageUrl) async {
    if (mounted) {
      //var pageTitle = (await _getPageTitle(document)).toLowerCase();
      if (!pageUrl.contains('item.php')) {
        setState(() {
          _quickItemsController.expanded = false;
          _quickItemsActive = false;
          // NOT APPLICABLE UNLESS USING ON PROGRESS
          // _quickItemsTriggered = false;
        });
        return;
      }

      var title = await _webViewController.getTitle();
      if (!title.contains('Items')) {
        return;
      }

      /* NOT APPLICABLE UNLESS USING ON PROGRESS
      // Stops any successive calls once we are sure that the section is the
      // correct one. onPageFinished will reset this for the future.
      // Otherwise we would call the API every time onProgressChanged ticks
      if (_quickItemsTriggered) {
        return;
      }
      _quickItemsTriggered = true;
      */

      var quickItemsProvider = context.read<QuickItemsProvider>();
      var key = _userProv.basic.userApiKey;
      quickItemsProvider.loadItems(apiKey: key);

      setState(() {
        _quickItemsController.expanded = true;
        _quickItemsActive = true;
      });
    }
  }

  Widget _quickItemsMenuIcon() {
    if (_quickItemsActive) {
      return Padding(
        padding: const EdgeInsets.only(right: 5),
        child: OpenContainer(
          transitionDuration: Duration(milliseconds: 500),
          transitionType: ContainerTransitionType.fadeThrough,
          openBuilder: (BuildContext context, VoidCallback _) {
            return QuickItemsOptions();
          },
          closedElevation: 0,
          closedShape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(56 / 2),
            ),
          ),
          closedColor: Colors.transparent,
          closedBuilder: (BuildContext context, VoidCallback openContainer) {
            return SizedBox(
              height: 20,
              width: 20,
              child: Image.asset('images/icons/quick_items.png', color: Colors.white),
            );
          },
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }

  // ASSESS PROFILES
  Future _assessProfileAttack(String page) async {
    if (mounted) {
      if (!page.contains('loader.php?sid=attack&user2ID=') &&
          !page.contains('torn.com/profiles.php?XID=')) {
        _profileAttackWidget = SizedBox.shrink();
        _lastProfileVisited = "";
        return;
      }

      int userId = 0;

      if (page.contains('torn.com/profiles.php?XID=')) {
        if (page == _lastProfileVisited) {
          return;
        }
        _lastProfileVisited = page;

        try {
          RegExp regId = new RegExp(r"php\?XID=([0-9]+)");
          var matches = regId.allMatches(page);
          userId = int.parse(matches.elementAt(0).group(1));
          setState(() {
            _profileAttackWidget = ProfileAttackCheckWidget(
              key: UniqueKey(),
              profileId: userId,
              apiKey: _userProv.basic.userApiKey,
              profileCheckType: ProfileCheckType.profile,
            );
          });
        } catch (e) {
          userId = 0;
        }
      } else if (page.contains('loader.php?sid=attack&user2ID=')) {
        if (page == _lastProfileVisited) {
          return;
        }
        _lastProfileVisited = page;

        try {
          RegExp regId = new RegExp(r"&user2ID=([0-9]+)");
          var matches = regId.allMatches(page);
          userId = int.parse(matches.elementAt(0).group(1));
          setState(() {
            _profileAttackWidget = ProfileAttackCheckWidget(
              key: UniqueKey(),
              profileId: userId,
              apiKey: _userProv.basic.userApiKey,
              profileCheckType: ProfileCheckType.attack,
            );
          });
        } catch (e) {
          userId = 0;
        }
      }
    }
  }

  Future _loadPreferences() async {
    var removalEnabled = await Prefs().getChatRemovalEnabled();
    var removalActive = await Prefs().getChatRemovalActive();

    setState(() {
      _chatRemovalEnabled = removalEnabled;
      _chatRemovalActive = removalActive;
    });

    _skippingEnabled = await Prefs().getTargetSkipping();
    _showNotes = await Prefs().getShowTargetsNotes();
    _showOnlineFactionWarning = await Prefs().getShowOnlineFactionWarning();

    // This will show the note of the first target, if applicable
    if (_showNotes) {
      if (_showOnlineFactionWarning) {
        var nextTarget =
            await TornApiCaller.target(_userProv.basic.userApiKey, widget.attackIdList[0])
                .getTarget;

        if (nextTarget is TargetModel) {
          _factionName = nextTarget.faction.factionName;
          _lastOnline = nextTarget.lastAction.timestamp;
        }
      }

      _showNoteToast();
    }
  }

  Future<bool> _willPopCallback() async {
    await _tryGoBack();
    return false;
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
