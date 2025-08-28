// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
// ignore: depend_on_referenced_packages
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';

// Project imports:
import 'package:torn_pda/models/profile/shortcuts_model.dart';
import 'package:torn_pda/pages/profile/shortcuts_page.dart';
import 'package:torn_pda/providers/shortcuts_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/user_helper.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebviewShortcutsDialog extends StatefulWidget {
  final InAppWebViewController? inAppWebView;
  final WebViewController? stockWebview;
  final bool? fromShortcut;

  const WebviewShortcutsDialog({
    this.inAppWebView,
    this.stockWebview,
    this.fromShortcut,
  }) : assert(inAppWebView != null || stockWebview != null || fromShortcut != null,
            "If not coming from a shortcuts, this needs a webview attached!");

  @override
  WebviewShortcutsDialogState createState() => WebviewShortcutsDialogState();
}

class WebviewShortcutsDialogState extends State<WebviewShortcutsDialog> {
  late ThemeProvider _themeProvider;
  late ShortcutsProvider _shortcutsProvider;
  
  late WebViewProvider _webViewProvider;

  @override
  void initState() {
    super.initState();

    
    _shortcutsProvider = Provider.of<ShortcutsProvider>(context, listen: false);
    _themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    _webViewProvider = Provider.of<WebViewProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0.0,
      backgroundColor: _themeProvider.secondBackground,
      content: _shortcutsProvider.activeShortcuts.isEmpty
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'No shortcuts configured, add some!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.orange[900],
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Tap the icon to configure',
                        style: TextStyle(
                          color: Colors.orange[900],
                          fontStyle: FontStyle.italic,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  child: IconButton(
                    icon: const Icon(Icons.switch_access_shortcut_outlined),
                    color: Colors.orange[900],
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (BuildContext context) => ShortcutsPage(),
                        ),
                      );
                      setState(() {
                        // Update shortcuts
                      });
                    },
                  ),
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 5.0),
                  child: Text(
                    "TAP: load in current tab\nLONG PRESS: open a new tab",
                    style: TextStyle(
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: List<Widget>.generate(
                        _shortcutsProvider.activeShortcuts.length,
                        (index) {
                          return shortcutTile(_shortcutsProvider.activeShortcuts[index]);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
      actions: [
        TextButton(
          child: const Text("Close"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  Widget shortcutTile(Shortcut thisShortcut) {
    Widget tile;

    tile = Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 25,
            child: Image.asset(
              thisShortcut.iconUrl!,
              width: 16,
              color: _themeProvider.mainText,
            ),
          ),
          const SizedBox(height: 3),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                thisShortcut.nickname!.toUpperCase(),
                style: const TextStyle(fontSize: 9),
                textAlign: TextAlign.center,
                overflow: TextOverflow.fade,
              ),
            ),
          ),
        ],
      ),
    );

    return InkWell(
      onLongPress: () {
        String? url = thisShortcut.url;

        if (thisShortcut.addPlayerId != null) {
          if (thisShortcut.addPlayerId!) {
            url = url!.replaceAll("##P##", UserHelper.playerId.toString());
          }
          if (thisShortcut.addFactionId!) {
            url = url!.replaceAll("##F##", UserHelper.factionId.toString());
          }
          if (thisShortcut.addCompanyId!) {
            url = url!.replaceAll("##C##", UserHelper.companyId.toString());
          }
        }

        if (widget.inAppWebView != null) {
          _webViewProvider.addTab(url: url);
          _webViewProvider.activateTab(_webViewProvider.tabList.length - 1);
        } else if (widget.stockWebview != null) {
          widget.stockWebview!.loadRequest(Uri.parse(url!));
        } else if (widget.fromShortcut!) {
          _webViewProvider.addTab(url: url);
          _webViewProvider.activateTab(_webViewProvider.tabList.length - 1);
        }

        Navigator.of(context).pop();
      },
      onTap: () async {
        String? url = thisShortcut.url;

        if (thisShortcut.addPlayerId != null) {
          if (thisShortcut.addPlayerId!) {
            url = url!.replaceAll("##P##", UserHelper.playerId.toString());
          }
          if (thisShortcut.addFactionId!) {
            url = url!.replaceAll("##F##", UserHelper.factionId.toString());
          }
          if (thisShortcut.addCompanyId!) {
            url = url!.replaceAll("##C##", UserHelper.companyId.toString());
          }
        }

        if (widget.inAppWebView != null) {
          widget.inAppWebView!.loadUrl(
            urlRequest: URLRequest(url: WebUri(url!)),
          );
        } else if (widget.stockWebview != null) {
          widget.stockWebview!.loadRequest(Uri.parse(url!));
        } else if (widget.fromShortcut!) {
          _webViewProvider.loadCurrentTabUrl(url);
        }

        Navigator.of(context).pop();
      },
      child: Card(
        shape: RoundedRectangleBorder(
          side: BorderSide(color: thisShortcut.color!, width: 1.5),
          borderRadius: BorderRadius.circular(4.0),
        ),
        elevation: 2,
        child: tile,
      ),
    );
  }
}
