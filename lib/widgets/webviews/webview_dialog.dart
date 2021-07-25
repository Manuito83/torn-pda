// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:torn_pda/widgets/webviews/webview_full.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';

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
    // Avoids browser going back if user taps the screen side (in which case, willPopCallback
    // triggers as if the back button had been pressed
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: hPad, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: frame),
          child: WebViewStackView(initUrl: 'https://www.torn.com'),
          ),
      );
    },
  );
}
