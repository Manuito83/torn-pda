import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';

class WebViewStackView extends StatefulWidget {
  const WebViewStackView({Key key}) : super(key: key);

  @override
  _WebViewStackViewState createState() => _WebViewStackViewState();
}

class _WebViewStackViewState extends State<WebViewStackView> {
  PageController _bottomNavPageController;

  ThemeProvider _themeProvider;
  WebViewProvider _webViewProvider;

  @override
  void initState() {
    super.initState();
    _bottomNavPageController = PageController(initialPage: 0);
  }

  @override
  Widget build(BuildContext context) {
    _webViewProvider = Provider.of<WebViewProvider>(context, listen: true);
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return Scaffold(
      body: IndexedStack(
        index: _webViewProvider.currentTab,
        children: _webViewProvider.webViewList,
      ),
      bottomNavigationBar: _bottomNavBar(),
    );
  }

  @override
  Future dispose() async {
    _bottomNavPageController.dispose();
    super.dispose();
  }

  Widget _bottomNavBar() {
    var firstButton = Container(
      key: UniqueKey(),
      color: _webViewProvider.currentTab == 0 ? _themeProvider.navSelected : Colors.transparent,
      child: GestureDetector(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(
            Icons.web,
            color: _themeProvider.mainText,
          ),
        ),
        onTap: () {
          _webViewProvider.activateTab(0);
        },
        onDoubleTap: () {
          if (_webViewProvider.webViewList.length > 0) {
            _webViewProvider.removeWebView(0);
          }
        },
      ),
    );

    var staticButtons = <Widget>[];
    for (var i = 0; i < _webViewProvider.webViewList.length; i++) {

      if (i == 0) {
        staticButtons.add(
          Container(
            key: UniqueKey(),
            child: SizedBox.shrink(),
          ),
        );
        continue;
      }

      Widget button = Container(
        key: UniqueKey(),
        color: _webViewProvider.currentTab == i ? _themeProvider.navSelected : Colors.transparent,
        child: GestureDetector(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              Icons.web,
              color: _themeProvider.mainText,
            ),
          ),
          onTap: () {
            _webViewProvider.activateTab(i);
          },
          onDoubleTap: () {
            if (_webViewProvider.webViewList.length > 0) {
              _webViewProvider.removeWebView(i);
            }
          },
        ),
      );
      staticButtons.add(button);
    }

    return Container(
      height: 40,
      decoration: new BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Flexible(
            child: Row(
              children: [
                firstButton,
                VerticalDivider(
                  width: 2,
                  thickness: 2,
                  color: _themeProvider.mainText,
                ),
                Expanded(
                  child: ReorderableListView(
                    scrollDirection: Axis.horizontal,
                    children: staticButtons,
                    onReorder: (start, end) {
                      if (start == 0 || end == 0) return;
                      // Save where the current active tab is
                      var activeKey = _webViewProvider.webViewList[_webViewProvider.currentTab].key;
                      // Removing the item at oldIndex will shorten the list by 1
                      if (start < end) end -= 1;
                      // Do the move
                      _webViewProvider.reorderTabs(_webViewProvider.webViewList[start], start, end);
                      // Make sure we continue in our previous active tab
                      for (var i = 0; i < _webViewProvider.webViewList.length; i++) {
                        if (_webViewProvider.webViewList[i].key == activeKey) {
                          _webViewProvider.activateTab(i);
                          break;
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: Container(
              color: _themeProvider.navSelected,
              child: IconButton(
                icon: Icon(
                  Icons.add,
                  color: _themeProvider.mainText,
                ),
                onPressed: () {
                  _webViewProvider.addWebView();
                  _webViewProvider.activateTab(_webViewProvider.webViewList.length - 1);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
