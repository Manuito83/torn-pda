import 'package:flutter/material.dart';
import 'package:torn_pda/widgets/webviews/webview_full.dart';

Future<void> openBrowserDialog(BuildContext _, String initUrl,
    {Function callBack}) {
  double width = MediaQuery.of(_).size.width;
  double hPad = 15;
  double frame = 6;
  if (width < 400) {
    hPad = 6;
    frame = 2;
  }
  return showDialog(
    context: _,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: hPad, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: frame),
          child: WebViewFull(
            customUrl: initUrl,
            dialog: true,
            customCallBack: callBack,
          ),
        ),
      );
    },
  );
}
