import 'package:animations/animations.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:html/parser.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:torn_pda/widgets/crimes/crimes_widget.dart';
import 'package:torn_pda/widgets/crimes/crimes_options.dart';

class WebViewFull extends StatefulWidget {
  final String customTitle;
  final String customUrl;
  final Function customCallBack;

  WebViewFull({
    this.customTitle = '',
    this.customCallBack,
    this.customUrl,
  });

  @override
  _WebViewFullState createState() => _WebViewFullState();
}

class _WebViewFullState extends State<WebViewFull> {
  InAppWebViewController webView;
  String _initialUrl = "";
  String _pageTitle = "";
  String _currentUrl = '';

  var crimesActive = false;
  var crimesController = ExpandableController();

  @override
  void initState() {
    super.initState();
    _initialUrl = widget.customUrl;
    _pageTitle = widget.customTitle;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _willPopCallback,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                if (widget.customCallBack != null) {
                  widget.customCallBack();
                }
                Navigator.pop(context);
              }),
          title: Text(_pageTitle),
          actions: <Widget>[
            _crimesInfoIcon(),
            _crimesMenuIcon(),
          ],
        ),
        body: Container(
          color: Colors.grey[900],
          child: SafeArea(
            top: false,
            left: false,
            right: false,
            bottom: true,
            child: Column(
              children: [
                ExpandablePanel(
                  theme: ExpandableThemeData(
                  hasIcon: false,
                    tapBodyToCollapse: false,
                    tapHeaderToExpand: false,
                  ),
                  collapsed: SizedBox.shrink(),
                  controller: crimesController,
                  header: SizedBox.shrink(),
                  expanded: CrimesWidget(controller: webView),
                ),
                Expanded(
                  child: InAppWebView(
                    initialUrl: _initialUrl,
                    initialHeaders: {},
                    initialOptions: InAppWebViewGroupOptions(
                      crossPlatform: InAppWebViewOptions(
                        debuggingEnabled: true,
                        preferredContentMode: UserPreferredContentMode.DESKTOP,
                      ),
                      android: AndroidInAppWebViewOptions(
                        useWideViewPort: true,
                        loadWithOverviewMode: true,
                        builtInZoomControls: true,
                        displayZoomControls: true,
                      ),
                    ),
                    onWebViewCreated: (InAppWebViewController c) {
                      webView = c;
                    },
                    onLoadStop: (InAppWebViewController c, String url) {
                      _currentUrl = url;
                      _assessCrimes();
                    },
                    onConsoleMessage:
                        (InAppWebViewController c, consoleMessage) {
                      print("CONSOLE MESSAGE: " + consoleMessage.message);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _crimesInfoIcon() {
    if (crimesActive) {
      return IconButton(
        icon: Icon(Icons.info_outline),
        onPressed: () {
          BotToast.showText(
            text: 'If you need more information about a crime, maintain the '
                'quick crime button pressed for a few seconds and a tooltip '
                'will be shown!',
            textStyle: TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            contentColor: Colors.grey[700],
            duration: Duration(seconds: 8),
            contentPadding: EdgeInsets.all(10),
          );
        },
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Widget _crimesMenuIcon() {
    if (crimesActive) {
      return OpenContainer(
        transitionDuration: Duration(milliseconds: 500),
        transitionType: ContainerTransitionType.fadeThrough,
        openBuilder: (BuildContext context, VoidCallback _) {
          return CrimesOptions();
        },
        closedElevation: 0,
        closedShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(56 / 2),
          ),
        ),
        closedColor: Colors.transparent,
        closedBuilder: (BuildContext context, VoidCallback openContainer) {
          return Padding(
            padding: const EdgeInsets.only(right: 20),
            child: SizedBox(
              height: 20,
              width: 20,
              child: Icon(MdiIcons.fingerprint),
            ),
          );
        },
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Future _assessCrimes() async {
    // H4 is helpful to understand if we are in the correct page
    // Taking into account not logged in conditions and captcha
    var html = await webView.getHtml();
    var document = parse(html);
    var h4 = document
        .querySelector(".content-title > h4")
        .innerHtml
        .substring(0)
        .toLowerCase()
        .trim();

    setState(() {
      if (_currentUrl.contains('https://www.torn.com/crimes.php')
          && !h4.contains('please validate')
          && !h4.contains('error')
          && h4.contains('crimes')) {
        crimesController.expanded = true;
        crimesActive = true;
      } else {
        crimesController.expanded = false;
        crimesActive = false;
      }
    });
  }

  Future<bool> _willPopCallback() async {
    widget.customCallBack();
    return true;
  }
}
