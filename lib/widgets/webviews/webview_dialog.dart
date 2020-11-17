import 'package:flutter/material.dart';
import 'package:torn_pda/widgets/webviews/webview_full.dart';

class WebViewDialog extends StatefulWidget {
  String initUrl;

  WebViewDialog({@required this.initUrl});

  @override
  _WebViewDialogState createState() => _WebViewDialogState();
}

class _WebViewDialogState extends State<WebViewDialog> {

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: WebViewFull(
            customUrl: widget.initUrl,
            dialog: true,
          ),
        ),
        SizedBox(height: 5),
        SizedBox(
          height: 35,
          child: FlatButton(
            child: Text("Close"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
      ],
    );
  }
}
