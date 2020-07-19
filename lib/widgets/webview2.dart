import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:html/parser.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:torn_pda/widgets/crimes/crimes_widget.dart';
import 'package:torn_pda/widgets/crimes/crimes_options.dart';

class WebView2 extends StatefulWidget {
  final String customTitle;
  final String customUrl;
  final Function customCallBack;

  WebView2({
    this.customTitle = '',
    this.customCallBack,
    this.customUrl,
  });

  @override
  _WebView2State createState() => _WebView2State();
}

class _WebView2State extends State<WebView2> {
  InAppWebViewController webView;
  String _initialUrl = "";
  String _pageTitle = "";
  String _currentUrl = '';

  Widget _crimesWidget = SizedBox.shrink();

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
            _crimesAppBar(),
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
                _crimesWidget,
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
                      if (_currentUrl.contains('https://www.torn.com/crimes.php')) {
                        _assessCrimes();
                      }
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

  Widget _crimesAppBar() {
    if (_currentUrl.contains('https://www.torn.com/crimes.php')) {
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
    // H4 is 'Please validate' with captcha or 'Crimes' without it
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
          && !h4.contains('please validate')) {
        _crimesWidget = CrimesWidget(
          controller: webView,
        );
      } else {
        _crimesWidget = SizedBox.shrink();
      }
    });
  }

  Future<bool> _willPopCallback() async {
    widget.customCallBack();
    return true;
  }
}
