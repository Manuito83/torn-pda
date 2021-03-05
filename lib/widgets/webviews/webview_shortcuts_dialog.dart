import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:torn_pda/providers/shortcuts_provider.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/models/profile/shortcuts_model.dart';

class WebviewShortcutsDialog extends StatefulWidget {
  final InAppWebViewController webview;

  WebviewShortcutsDialog({
    @required this.webview,
  });

  @override
  _WebviewShortcutsDialogState createState() => _WebviewShortcutsDialogState();
}

class _WebviewShortcutsDialogState extends State<WebviewShortcutsDialog> {
  ThemeProvider _themeProvider;
  ShortcutsProvider _shortcutsProvider;

  @override
  void initState() {
    super.initState();

    _shortcutsProvider = Provider.of<ShortcutsProvider>(context, listen: false);
    _themeProvider = Provider.of<ThemeProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0.0,
      backgroundColor: _themeProvider.background,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              child: _shortcutsWrap(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          child: Text("Close"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  Wrap _shortcutsWrap() {
    var shortcuts = <Widget>[];

    for (var short in _shortcutsProvider.activeShortcuts) {
      shortcuts.add(
        Container(
          height: 60,
          width: 70,
          child: shortcutTile(short),
        ),
      );
    }

    return Wrap(children: shortcuts);
  }

  Widget shortcutTile(Shortcut thisShortcut) {
    Widget tile = Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 18,
            child: Image.asset(
              thisShortcut.iconUrl,
              width: 16,
              color: _themeProvider.mainText,
            ),
          ),
          SizedBox(height: 3),
          Flexible(
            child: Container(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: SizedBox(
                  width: 55,
                  child: Text(
                    thisShortcut.nickname.toUpperCase(),
                    style: TextStyle(fontSize: 9),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.fade,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return InkWell(
      onTap: () async {
        widget.webview.loadUrl(
          urlRequest: URLRequest(
            url: Uri.parse(thisShortcut.url),
          ),
        );
        Navigator.of(context).pop();
      },
      child: Card(
        shape: RoundedRectangleBorder(
          side: BorderSide(color: thisShortcut.color, width: 1.5),
          borderRadius: BorderRadius.circular(4.0),
        ),
        elevation: 2,
        child: tile,
      ),
    );
  }
}
