// Flutter imports:
import 'package:flutter/material.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

// Project imports:
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';

Future<void> openBrowserDialog(
  BuildContext _,
  String initUrl, {
  Function callBack,
  bool recallLastSession = false,
}) async {
  double width = MediaQuery.of(_).size.width;
  double hPad = 15;
  double frame = 6;

  if (width < 400) {
    hPad = 6;
    frame = 2;
  }

  String restoredTheme = await Prefs().getAppTheme();

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
        child: Container(
          color: restoredTheme == "extraDark" ? Color(0xFF131313) : Colors.transparent,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: frame),
            child: WebViewStackView(initUrl: initUrl, dialog: true, recallLastSession: recallLastSession),
          ),
        ),
      );
    },
  );
}
