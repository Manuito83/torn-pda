import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';

class WebViewStackView extends StatefulWidget {
  final String initUrl;

  const WebViewStackView({
    @required this.initUrl,
    Key key,
  }) : super(key: key);

  @override
  _WebViewStackViewState createState() => _WebViewStackViewState();
}

class _WebViewStackViewState extends State<WebViewStackView> {
  ThemeProvider _themeProvider;
  WebViewProvider _webViewProvider;

  Future providerInitialised;

  @override
  void initState() {
    super.initState();
    providerInitialised = Provider.of<WebViewProvider>(context, listen: false).initialise(initUrl: widget.initUrl);
  }

  @override
  Widget build(BuildContext context) {
    _webViewProvider = Provider.of<WebViewProvider>(context, listen: true);
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);

    var allWebViews = <Widget>[];
    for (var tab in _webViewProvider.tabList) {
      allWebViews.add(tab.webView);
    }

    return Scaffold(
      body: FutureBuilder(
        future: providerInitialised,
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return IndexedStack(
              index: _webViewProvider.currentTab,
              children: allWebViews,
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      bottomNavigationBar: FutureBuilder(
        future: providerInitialised,
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return _bottomNavBar();
          } else {
            return SizedBox.shrink();
          }
        },
      ),
    );
  }

  @override
  Future dispose() async {
    _webViewProvider.clearOnDispose();
    super.dispose();
  }

  Widget _bottomNavBar() {
    var mainTab = Container(
      key: UniqueKey(),
      color: _webViewProvider.currentTab == 0 ? _themeProvider.navSelected : Colors.transparent,
      child: GestureDetector(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: _getIcon(0),
        ),
        onTap: () {
          _webViewProvider.activateTab(0);
        },
        onDoubleTap: () {
          if (_webViewProvider.tabList.length > 0) {
            _webViewProvider.removeTab(0);
          }
        },
      ),
    );

    var secondaryTabs = <Widget>[];
    for (var i = 0; i < _webViewProvider.tabList.length; i++) {
      if (i == 0) {
        secondaryTabs.add(
          Container(
            key: UniqueKey(),
            child: SizedBox.shrink(),
          ),
        );
        continue;
      }

      Widget secondaryTab = Container(
        key: UniqueKey(),
        color: _webViewProvider.currentTab == i ? _themeProvider.navSelected : Colors.transparent,
        child: GestureDetector(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: _getIcon(i),
          ),
          onTap: () {
            _webViewProvider.activateTab(i);
          },
          onDoubleTap: () {
            if (_webViewProvider.tabList.length > 0) {
              _webViewProvider.removeTab(i);
            }
          },
        ),
      );
      secondaryTabs.add(secondaryTab);
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
          Expanded(
            child: Row(
              children: [
                mainTab,
                VerticalDivider(
                  width: 2,
                  thickness: 2,
                  color: _themeProvider.mainText,
                ),
                Expanded(
                  child: ReorderableListView(
                    scrollDirection: Axis.horizontal,
                    children: secondaryTabs,
                    onReorder: (start, end) {
                      if (start == 0 || end == 0) return;
                      // Save where the current active tab is
                      var activeKey = _webViewProvider.tabList[_webViewProvider.currentTab].webView.key;
                      // Removing the item at oldIndex will shorten the list by 1
                      if (start < end) end -= 1;
                      // Do the move
                      _webViewProvider.reorderTabs(_webViewProvider.tabList[start], start, end);
                      // Make sure we continue in our previous active tab
                      for (var i = 0; i < _webViewProvider.tabList.length; i++) {
                        if (_webViewProvider.tabList[i].webView.key == activeKey) {
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
          Row(
            children: [
              VerticalDivider(
                width: 2,
                thickness: 2,
                color: _themeProvider.mainText,
              ),
              Container(
                color: _themeProvider.navSelected,
                child: IconButton(
                  icon: Icon(
                    Icons.add,
                    color: _themeProvider.mainText,
                  ),
                  onPressed: () {
                    _webViewProvider.addTab();
                    _webViewProvider.activateTab(_webViewProvider.tabList.length - 1);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _getIcon(int i) {
    // TODO: ADD ICONS
    if (_webViewProvider.tabList[i].tabUrlType == TabUrlType.profile) {
      return Icon(Icons.person, color: _themeProvider.mainText);
    } else {
      return ImageIcon(AssetImage('images/icons/pda_icon.png'));
    }
  }
}
