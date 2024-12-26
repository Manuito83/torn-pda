// Dart imports:
import 'dart:async';
import 'dart:convert';
import 'dart:io';

// Package imports:
import 'package:bot_toast/bot_toast.dart';
// Flutter imports:
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/config/webview_config.dart';
// Project imports:
import 'package:torn_pda/models/chaining/target_model.dart';
import 'package:torn_pda/providers/api/api_v1_calls.dart';
import 'package:torn_pda/providers/chain_status_provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/utils/js_snippets.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/chaining/chain_widget.dart';
import 'package:torn_pda/widgets/dotted_border.dart';
import 'package:torn_pda/widgets/profile_check/profile_check.dart';
import 'package:torn_pda/widgets/webviews/custom_appbar.dart';
import 'package:torn_pda/widgets/webviews/webview_url_dialog.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewPanic extends StatefulWidget {
  final List<String> attackIdList;
  final List<String?> attackNameList;
  final List<String> attackNotesList;
  final List<String> attackNotesColorList;
  final Function(List<String>)? attacksCallback;
  final bool war;
  final bool panic;
  final bool showNotes;
  final bool showBlankNotes;
  final bool showOnlineFactionWarning;

  /// [attackIdList] and [attackNameList] make sense for attacks series
  /// [attacksCallback] is used to update the targets card when we go back
  const WebViewPanic({
    required this.attackIdList,
    required this.attackNameList,
    required this.attackNotesList,
    required this.attackNotesColorList,
    this.attacksCallback,
    this.war = false,
    this.panic = false,
    required this.showNotes,
    required this.showBlankNotes,
    required this.showOnlineFactionWarning,
  });

  @override
  WebViewPanicState createState() => WebViewPanicState();
}

class WebViewPanicState extends State<WebViewPanic> {
  WebViewController? _webViewController;

  UserDetailsProvider? _userProv;
  late ChainStatusProvider _chainStatusProvider;
  late SettingsProvider _settingsProvider;
  ThemeProvider? _themeProvider;

  final _chainWidgetKey = GlobalKey();

  String _initialUrl = "";
  String _currentPageTitle = "";

  var _chatRemovalEnabled = true;
  var _chatRemovalActive = false;

  int _attackNumber = 0;
  final List<String> _attackedIds = [];

  String? _factionName = "";
  int? _lastOnline = 0;

  bool _backButtonPopsContext = true;
  String _goBackTitle = '';

  final _chainWidgetController = ExpandableController();

  bool _nextButtonPressed = false;

  final _popupChoices = <HealingPages>[
    HealingPages(description: "Personal"),
    HealingPages(description: "Faction"),
  ];

  Widget _profileAttackWidget = const SizedBox.shrink();
  var _lastProfileVisited = "";

  @override
  void initState() {
    super.initState();

    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    _loadPreferences();
    _userProv = Provider.of<UserDetailsProvider>(context, listen: false);
    _initialUrl = 'https://www.torn.com/loader.php?sid=attack&user2ID=${widget.attackIdList[0]}';
    _currentPageTitle = '${widget.attackNameList[0]}';
    _attackedIds.add(widget.attackIdList[0]);
    _chainStatusProvider = context.read<ChainStatusProvider>();
    if (_chainStatusProvider.watcherActive) {
      _chainWidgetController.expanded = true;
    }

    // Decide if voluntarily skipping first target (always when it's a panic target)
    _assessFirstTargetsOnLaunch();

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setUserAgent(
        Platform.isAndroid
            ? "Mozilla/5.0 (Linux; Android Torn PDA) AppleWebKit/537.36 "
                "(KHTML, like Gecko) Version/4.0 Chrome/91.0.4472.114 Mobile Safari/537.36 ${WebviewConfig.agent}"
            : "Mozilla/5.0 (iPhone; CPU iPhone OS 15_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) "
                "CriOS/103.0.5060.54 Mobile/15E148 Safari/604.1 ${WebviewConfig.agent}",
      )
      ..addJavaScriptChannel(
        'loadoutChangeHandler',
        onMessageReceived: (JavaScriptMessage message) async {
          if (message.message.contains("equippedSet")) {
            final regex = RegExp(r'"equippedSet":(\d)');
            final match = regex.firstMatch(message.message)!;
            final loadout = match.group(1);
            _webViewController!.reload();
            BotToast.showText(
              text: "Loadout $loadout activated!",
              textStyle: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
              contentColor: Colors.blue[600]!,
              duration: const Duration(seconds: 1),
              contentPadding: const EdgeInsets.all(10),
            );
          } else {
            BotToast.showText(
              text: "There was a problem activating the loadout, are you already using it?",
              textStyle: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
              contentColor: Colors.red[600]!,
              contentPadding: const EdgeInsets.all(10),
            );
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (page) {
            _hideChat();
            _assessProfileAttack(page);
          },
          onPageFinished: (page) {
            _hideChat();
            _highlightChat(page);
          },
        ),
      )
      ..loadRequest(Uri.parse(_initialUrl));
  }

  @override
  void dispose() {
    _chainWidgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context);
    return WillPopScope(
      onWillPop: _willPopCallback,
      child: Container(
        color: _themeProvider!.currentTheme == AppTheme.light
            ? MediaQuery.orientationOf(context) == Orientation.portrait
                ? Colors.blueGrey
                : _themeProvider!.canvas
            : _themeProvider!.canvas,
        child: SafeArea(
          child: Scaffold(
            backgroundColor: _themeProvider!.canvas,
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
                  color: _themeProvider!.currentTheme == AppTheme.extraDark ? Colors.black : Colors.grey[900],
                  child: Column(
                    children: [
                      ExpandablePanel(
                        theme: const ExpandableThemeData(
                          hasIcon: false,
                          tapBodyToCollapse: false,
                          tapHeaderToExpand: false,
                        ),
                        collapsed: const SizedBox.shrink(),
                        controller: _chainWidgetController,
                        header: const SizedBox.shrink(),
                        expanded: ChainWidget(
                          key: _chainWidgetKey,
                          alwaysDarkBackground: true,
                        ),
                      ),
                      _profileAttackWidget,
                      Expanded(
                        child: WebViewWidget(
                          controller: _webViewController!,
                        ),
                      ),
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

    final intColor = Color(_settingsProvider.highlightColor);
    final background = 'rgba(${intColor.red}, ${intColor.green}, ${intColor.blue}, ${intColor.opacity})';
    final senderColor = 'rgba(${intColor.red}, ${intColor.green}, ${intColor.blue}, 1)';
    final String hlMap = '[ "${_userProv!.basic!.name}", ...${jsonEncode(_settingsProvider.highlightWordList)} ]';
    final String css = chatHighlightCSS(background: background, senderColor: senderColor);

    if (_settingsProvider.highlightChat) {
      _webViewController!.runJavaScript(
        chatHighlightJS(highlights: hlMap),
      );
      _webViewController!.runJavaScript("const x = document.createElement('style');"
          "x.innerHTML = `$css`;"
          "document.head.appendChild(x);");
    }
  }

  void _hideChat() {
    if (_chatRemovalEnabled && _chatRemovalActive) {
      _webViewController!.runJavaScript(removeChatOnLoadStartJS());
    }
  }

  CustomAppBar buildCustomAppBar() {
    return CustomAppBar(
      onHorizontalDragEnd: (DragEndDetails details) async {
        await _goBackOrForward(details);
      },
      genericAppBar: AppBar(
        //brightness: Brightness.dark,
        leading: IconButton(
          icon: _backButtonPopsContext ? const Icon(Icons.close) : const Icon(Icons.arrow_back_ios),
          onPressed: () async {
            // Normal behavior is just to pop and go to previous page
            if (_backButtonPopsContext) {
              if (widget.attacksCallback != null) {
                widget.attacksCallback!(_attackedIds);
              }
              Navigator.pop(context);
            } else {
              // But we can change and go back to previous page in certain
              // situations (e.g. when going for medical items during an
              // attack), in which case we need to return to previous target
              final backPossible = await _webViewController!.canGoBack();
              if (backPossible) {
                _webViewController!.goBack();
                setState(() {
                  _currentPageTitle = _goBackTitle;
                });
              } else {
                Navigator.pop(context);
              }
              _backButtonPopsContext = true;
            }
          },
        ),
        title: GestureDetector(
          onTap: () {
            _openUrlDialog();
          },
          child: DottedBorder(
            padding: const EdgeInsets.all(6),
            dashPattern: const [1, 4],
            color: Colors.white70,
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      _currentPageTitle,
                      overflow: TextOverflow.fade,
                    ),
                  ),
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
    if (details.primaryVelocity! < 0) {
      await _tryGoForward();
    } else if (details.primaryVelocity! > 0) {
      await _tryGoBack();
    }
  }

  Future _tryGoForward() async {
    final canForward = await _webViewController!.canGoForward();
    if (canForward) {
      await _webViewController!.goForward();
      BotToast.showText(
        text: "Forward",
        textStyle: const TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
        contentColor: Colors.grey[600]!,
        duration: const Duration(seconds: 1),
        contentPadding: const EdgeInsets.all(10),
      );
    } else {
      BotToast.showText(
        text: "Can't go forward!",
        textStyle: const TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
        contentColor: Colors.grey[600]!,
        duration: const Duration(seconds: 1),
        contentPadding: const EdgeInsets.all(10),
      );
    }
  }

  Future _tryGoBack() async {
    final canBack = await _webViewController!.canGoBack();
    if (canBack) {
      await _webViewController!.goBack();
      BotToast.showText(
        text: "Back",
        textStyle: const TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
        contentColor: Colors.grey[600]!,
        duration: const Duration(seconds: 1),
        contentPadding: const EdgeInsets.all(10),
      );
    } else {
      BotToast.showText(
        text: "Can't go back!",
        textStyle: const TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
        contentColor: Colors.grey[600]!,
        duration: const Duration(seconds: 1),
        contentPadding: const EdgeInsets.all(10),
      );
    }
  }

  Future<void> _openUrlDialog() async {
    final url = await _webViewController!.currentUrl();
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return WebviewUrlDialog(
          title: _currentPageTitle,
          url: url.toString(),
          stockWebView: _webViewController,
          userProvider: _userProv,
        );
      },
    );
  }

  List<Widget> _actionButtons() {
    List<Widget> myButtons = [];

    Widget hideChatIcon = const SizedBox.shrink();
    if (!_chatRemovalActive && _chatRemovalEnabled) {
      hideChatIcon = Padding(
        padding: const EdgeInsets.only(left: 15),
        child: GestureDetector(
          child: Icon(MdiIcons.chatOutline),
          onTap: () async {
            _webViewController!.runJavaScript(removeChatJS());
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
            _webViewController!.runJavaScript(restoreChatJS());
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
            await _webViewController!.reload();

            BotToast.showText(
              text: "Reloading...",
              textStyle: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
              contentColor: Colors.grey[600]!,
              duration: const Duration(seconds: 1),
              contentPadding: const EdgeInsets.all(10),
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
      myButtons.add(const SizedBox.shrink());
    }

    return myButtons;
  }

  Widget _nextAttackActionButton() {
    return IconButton(
      icon: const Icon(Icons.skip_next),
      onPressed: _nextButtonPressed ? null : () => _launchNextAttack(),
    );
  }

  Future<void> _assessFirstTargetsOnLaunch() async {
    if (widget.panic || (_settingsProvider.targetSkippingAll && _settingsProvider.targetSkippingFirst)) {
      // Counters for target skipping
      int targetsSkipped = 0;
      final originalPosition = _attackNumber;
      bool reachedEnd = false;
      final skippedNames = [];

      // We'll skip maximum of 10 targets
      for (var i = 0; i < 10; i++) {
        // Get the status of our next target
        final nextTarget = await ApiCallsV1.getTarget(playerId: widget.attackIdList[i]);

        if (nextTarget is TargetModel) {
          // If in hospital or jail (even in a different country), we skip
          if (nextTarget.status!.color == "red") {
            targetsSkipped++;
            skippedNames.add(nextTarget.name);
            _attackNumber++;
          }
          // If flying, we need to see if he is in a different country (if we are in the same
          // place, we can attack him)
          else if (nextTarget.status!.color == "blue") {
            final user = await ApiCallsV1.getTarget(playerId: _userProv!.basic!.playerId.toString());
            if (user is TargetModel) {
              if (user.status!.description != nextTarget.status!.description) {
                targetsSkipped++;
                skippedNames.add(nextTarget.name);
                _attackNumber++;
              }
            }
          }
          // If we found a good target, we break here. But before, we gather
          // some more details if option is enabled
          else {
            if (widget.showOnlineFactionWarning) {
              _factionName = nextTarget.faction!.factionName;
              _lastOnline = nextTarget.lastAction!.timestamp;
            }
            break;
          }
          // If after looping we are over the target limit, it means we have reached the end
          // in which case we reset the position to the last target we attacked, and break
          if (_attackNumber >= widget.attackIdList.length) {
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
          text: "Skipped ${skippedNames.join(", ")}, either in jail, hospital or in a different "
              "country",
          textStyle: const TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
          contentColor: Colors.grey[600]!,
          duration: const Duration(seconds: 5),
          contentPadding: const EdgeInsets.all(10),
        );

        const nextBaseUrl = 'https://www.torn.com/loader.php?sid=attack&user2ID=';
        if (!mounted) return;
        await _webViewController!.loadRequest(Uri.parse('$nextBaseUrl${widget.attackIdList[_attackNumber]}'));
        _attackedIds.add(widget.attackIdList[_attackNumber]);
        setState(() {
          _currentPageTitle = '${widget.attackNameList[_attackNumber]}';
        });

        // Show note for next target
        if (widget.showNotes) {
          _showNoteToast();
        }

        return;
      }

      if (targetsSkipped > 0 && reachedEnd) {
        BotToast.showText(
          text: "No more targets, all remaining are either in jail, hospital or in a different "
              "country (${skippedNames.join(", ")})\n\nPress and hold the play/pause button to stop the chaining mode",
          textStyle: const TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
          contentColor: Colors.grey[600]!,
          duration: const Duration(seconds: 5),
          contentPadding: const EdgeInsets.all(10),
        );

        return;
      }
    }

    // This will show the note of the first target, if applicable
    if (widget.showNotes) {
      if (widget.showOnlineFactionWarning) {
        final nextTarget = await ApiCallsV1.getTarget(playerId: widget.attackIdList[0]);
        if (nextTarget is TargetModel) {
          _factionName = nextTarget.faction!.factionName;
          _lastOnline = nextTarget.lastAction!.timestamp;
        }
      }
      _showNoteToast();
    }
  }

  /// Not to be used right after launch
  Future<void> _launchNextAttack() async {
    const nextBaseUrl = 'https://www.torn.com/loader.php?sid=attack&user2ID=';
    // Turn button grey
    setState(() {
      _nextButtonPressed = true;
    });

    if (widget.panic || _settingsProvider.targetSkippingAll) {
      // Counters for target skipping
      int targetsSkipped = 0;
      final originalPosition = _attackNumber;
      bool reachedEnd = false;
      final skippedNames = [];

      // We'll skip maximum of 3 targets
      for (var i = 0; i < 3; i++) {
        // Get the status of our next target
        final nextTarget = await ApiCallsV1.getTarget(playerId: widget.attackIdList[_attackNumber + 1]);

        if (nextTarget is TargetModel) {
          // If in hospital or jail (even in a different country), we skip
          if (nextTarget.status!.color == "red") {
            targetsSkipped++;
            skippedNames.add(nextTarget.name);
            _attackNumber++;
          }
          // If flying, we need to see if he is in a different country (if we are in the same
          // place, we can attack him)
          else if (nextTarget.status!.color == "blue") {
            final user = await ApiCallsV1.getTarget(playerId: _userProv!.basic!.playerId.toString());
            if (user is TargetModel) {
              if (user.status!.description != nextTarget.status!.description) {
                targetsSkipped++;
                skippedNames.add(nextTarget.name);
                _attackNumber++;
              }
            }
          }
          // If we found a good target, we break here. But before, we gather
          // some more details if option is enabled
          else {
            if (widget.showOnlineFactionWarning) {
              _factionName = nextTarget.faction!.factionName;
              _lastOnline = nextTarget.lastAction!.timestamp;
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
          text: "Skipped ${skippedNames.join(", ")}, either in jail, hospital or in a different "
              "country",
          textStyle: const TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
          contentColor: Colors.grey[600]!,
          duration: const Duration(seconds: 5),
          contentPadding: const EdgeInsets.all(10),
        );
      }

      if (targetsSkipped > 0 && reachedEnd) {
        BotToast.showText(
          text: "No more targets, all remaining are either in jail, hospital or in a different "
              "country (${skippedNames.join(", ")})\n\nPress and hold the play/pause button to stop the chaining mode",
          textStyle: const TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
          contentColor: Colors.grey[600]!,
          duration: const Duration(seconds: 5),
          contentPadding: const EdgeInsets.all(10),
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
      if (widget.showOnlineFactionWarning) {
        final nextTarget = await ApiCallsV1.getTarget(playerId: widget.attackIdList[_attackNumber + 1]);

        if (nextTarget is TargetModel) {
          _factionName = nextTarget.faction!.factionName;
          _lastOnline = nextTarget.lastAction!.timestamp;
        } else {
          _factionName = "";
          _lastOnline = 0;
        }
      }
    }

    _attackNumber++;
    if (!mounted) return;
    await _webViewController!.loadRequest(Uri.parse('$nextBaseUrl${widget.attackIdList[_attackNumber]}'));
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
    if (widget.showNotes) {
      _showNoteToast();
    }
  }

  Widget _medicalActionButton() {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: PopupMenuButton<HealingPages>(
        icon: const Icon(Icons.healing),
        onSelected: _openHealingPage,
        itemBuilder: (BuildContext context) {
          return _popupChoices.map((HealingPages choice) {
            return PopupMenuItem<HealingPages>(
              value: choice,
              child: Text(choice.description!),
            );
          }).toList();
        },
      ),
    );
  }

  Future<void> _openHealingPage(HealingPages choice) async {
    _goBackTitle = _currentPageTitle;
    // Check if the proper page loads (e.g. if we have started an attack,
    // it won't let us change to another page!). Note: this is something
    // that can't be done from one target to another, but only between
    // different sections (not sure why).
    await _webViewController!.loadRequest(Uri.parse('${choice.url}'));
    await Future.delayed(const Duration(seconds: 1), () {});
    final newUrl = await _webViewController!.currentUrl();
    if (newUrl == '${choice.url}') {
      setState(() {
        _currentPageTitle = 'Items';
      });
      _backButtonPopsContext = false;
    }
  }

  /// Use [onlyOne] when we want to get rid of several notes (e.g. to skip the very first target(s)
  /// without showing the notes for the ones skipped)
  void _showNoteToast() {
    Color? cardColor;
    switch (widget.attackNotesColorList[_attackNumber]) {
      case 'z':
        cardColor = Colors.grey[700];
      case 'green':
        cardColor = Colors.green[900];
      case 'orange':
        cardColor = Colors.orange[900];
      case 'red':
        cardColor = Colors.red[900];
      default:
        cardColor = Colors.grey[700];
    }

    String extraInfo = "";
    if (_lastOnline! > 0 && !widget.war) {
      final now = DateTime.now();
      final lastOnlineDiff = now.difference(DateTime.fromMillisecondsSinceEpoch(_lastOnline! * 1000));
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
    if (widget.attackNotesList[_attackNumber].isEmpty && !widget.showBlankNotes && extraInfo.isEmpty) {
      return;
    }

    BotToast.showCustomText(
      clickClose: true,
      ignoreContentClick: true,
      duration: const Duration(seconds: 5),
      toastBuilder: (textCancel) => Align(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Card(
            color: cardColor,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                        const SizedBox(width: 5),
                        Text(
                          'Note for ${widget.attackNameList[_attackNumber]}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  if (widget.attackNotesList[_attackNumber].isNotEmpty) const SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          '${widget.attackNotesList[_attackNumber]}$extraInfo',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
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

  // ASSESS PROFILES
  Future _assessProfileAttack(String page) async {
    if (mounted) {
      if (!page.contains('loader.php?sid=attack&user2ID=') &&
          !page.contains('loader2.php?sid=getInAttack&user2ID=') &&
          !page.contains('torn.com/profiles.php?XID=')) {
        _profileAttackWidget = const SizedBox.shrink();
        _lastProfileVisited = "";
        return;
      }

      int userId = 0;

      if (page.contains('torn.com/profiles.php?')) {
        if (page == _lastProfileVisited) {
          return;
        }
        _lastProfileVisited = page;

        try {
          final RegExp regId = RegExp(r"php\?XID=([0-9]+)");
          final matches = regId.allMatches(page);
          userId = int.parse(matches.elementAt(0).group(1)!);
          setState(() {
            _profileAttackWidget = ProfileAttackCheckWidget(
              key: UniqueKey(),
              profileId: userId,
              apiKey: _userProv!.basic!.userApiKey,
              profileCheckType: ProfileCheckType.profile,
              themeProvider: _themeProvider,
            );
          });
        } catch (e) {
          userId = 0;
        }
      } else if (page.contains('loader.php?sid=attack&user2ID=') ||
          page.contains('loader2.php?sid=getInAttack&user2ID=')) {
        if (page == _lastProfileVisited) {
          return;
        }
        _lastProfileVisited = page;

        try {
          final RegExp regId = RegExp("&user2ID=([0-9]+)");
          final matches = regId.allMatches(page);
          userId = int.parse(matches.elementAt(0).group(1)!);
          setState(() {
            _profileAttackWidget = ProfileAttackCheckWidget(
              key: UniqueKey(),
              profileId: userId,
              apiKey: _userProv!.basic!.userApiKey,
              profileCheckType: ProfileCheckType.attack,
              themeProvider: _themeProvider,
            );
          });
        } catch (e) {
          userId = 0;
        }
      }
    }
  }

  Future _loadPreferences() async {
    final removalEnabled = await Prefs().getChatRemovalEnabled();
    final removalActive = await Prefs().getChatRemovalActive();

    setState(() {
      _chatRemovalEnabled = removalEnabled;
      _chatRemovalActive = removalActive;
    });
  }

  Future<bool> _willPopCallback() async {
    await _tryGoBack();
    return false;
  }
}

class HealingPages {
  String? description;
  String? url;

  HealingPages({this.description}) {
    switch (description) {
      case "Personal":
        url = 'https://www.torn.com/item.php#medical-items';
      case "Faction":
        url = 'https://www.torn.com/factions.php?step=your#/tab=armoury&start=0&sub=medical';
    }
  }
}
