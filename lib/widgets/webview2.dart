import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

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

  @override
  void initState() {
    super.initState();
    _initialUrl = widget.customUrl;
    _pageTitle = widget.customTitle;
  }

  @override
  void dispose() {
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
              onPressed: () {
                if (widget.customCallBack != null) {
                  widget.customCallBack();
                }
                Navigator.pop(context);
              }),
          title: Text(_pageTitle),
        ),
        body: Container(
          color: Colors.black,
          child: SafeArea(
            top: false,
            left: false,
            right: false,
            bottom: true,
            child: Column(
              children: [
                RaisedButton(
                  child: Text('lala'),
                  onPressed: () async {

                    await webView.evaluateJavascript(source: """

                      var first_load = true;
                      
                      if (first_load) {
                        var loadingPlaceholderContent = `
                          <div class="content-title m-bottom10">
                            <h4 class="left">Crimes</h4>
                            <hr class="page-head-delimiter">
                            <div class="clear"></div>
                          </div>`
                          
                        first_load = false;
                      }
                      
                      loadingPlaceholderContent += `<img class="ajax-placeholder" src="/images/v2/main/ajax-loader.gif"/>`;
                      
                      window.location.hash = "#";
                      \$(".content-wrapper").html(loadingPlaceholderContent);
                      
                      var action = 'https://www.torn.com/crimes.php?step=docrime2&timestamp=' + Date.now();
                      
                      ajaxWrapper({
                        url: action,
                        type: 'POST',
                        data: 'nervetake=2&crime=searchtrainstation',
                        oncomplete: function(resp) {
                          \$(".content-wrapper").html(resp.responseText);
                        
                        var steps = action.split("?"),
                        step = steps[1] ? steps[1].split("=")[1] : "";
                        if (step == "docrime2" || step == "docrime4") refreshTopOfSidebar();
                        if (animElement) clearTimeout(animElement);
                        highlightElement("/" + step + ".php");
                        },
                        onerror: function(e) {
                          console.error(e)
                        }
                      });

                  """);
                  },
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
                    onWebViewCreated: (InAppWebViewController controller) {
                      webView = controller;
                    },
                    onConsoleMessage: (controller, consoleMessage) {
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

  Future<bool> _willPopCallback() async {
    widget.customCallBack();
    return true;
  }
}
