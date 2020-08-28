import 'package:bot_toast/bot_toast.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:torn_pda/widgets/chaining/chain_timer.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TornWebViewAttack extends StatefulWidget {
  final List<String> attackIdList;
  final List<String> attackNameList;
  final Function(List<String>) attacksCallback;
  final String userKey;

  /// [attackIdList] and [attackNameList] make sense for attacks series
  /// [attacksCallback] is used to update the targets card when we go back
  TornWebViewAttack({
    this.attackIdList = const [],
    this.attackNameList = const [],
    this.attacksCallback,
    @required this.userKey,
  });

  @override
  _TornWebViewAttackState createState() => _TornWebViewAttackState();
}

class _TornWebViewAttackState extends State<TornWebViewAttack> {
  WebViewController _webViewController;

  String _initialUrl = "";
  String _currentPageTitle = "";

  int _attackNumber = 0;
  List<String> _attackedIds = [];

  bool _backButtonPopsContext = true;
  String _goBackTitle = '';

  var _chainWidgetController = ExpandableController();

  final _popupChoices = <HealingPages>[
    HealingPages(description: "Personal"),
    HealingPages(description: "Faction"),
  ];

  @override
  void initState() {
    super.initState();
    _initialUrl = 'https://www.torn.com/loader.php?sid=attack&user2'
        'ID=${widget.attackIdList[0]}';
    _currentPageTitle = '${widget.attackNameList[0]}';
    _attackedIds.add(widget.attackIdList[0]);
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
        appBar: AppBar(
            leading: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () async {
                  // Normal behaviour is just to pop and go to previous page
                  if (_backButtonPopsContext) {
                    widget.attacksCallback(_attackedIds);
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
            actions: _actionButtons()),
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
      onPressed: () async {
        _attackNumber++;
        await _webViewController.loadUrl('$nextBaseUrl${widget.attackIdList[_attackNumber]}');
        _attackedIds.add(widget.attackIdList[_attackNumber]);
        setState(() {
          _currentPageTitle = '${widget.attackNameList[_attackNumber]}';
        });
        _backButtonPopsContext = true;
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

  Future<bool> _willPopCallback() async {
    widget.attacksCallback(_attackedIds);
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
