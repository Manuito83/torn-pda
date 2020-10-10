import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/widgets/webviews/webview_full.dart';

class WebViewDialog extends StatefulWidget {
  String initUrl;

  WebViewDialog({@required this.initUrl});

  @override
  _WebViewDialogState createState() => _WebViewDialogState();
}

class _WebViewDialogState extends State<WebViewDialog> {
  ThemeProvider _themeProvider;

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return Container(
      padding: EdgeInsets.only(
        top: 15,
        bottom: 15,
        left: 15,
        right: 15,
      ),
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 60),
      decoration: new BoxDecoration(
        color: _themeProvider.background,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10.0,
            offset: const Offset(0.0, 10.0),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: WebViewFull(
              customUrl: widget.initUrl,
              dialog: true,
            ),
          ),
          FlatButton(
            child: Text("Close"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
