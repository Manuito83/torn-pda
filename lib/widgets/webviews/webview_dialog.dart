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
  String restoredTheme = await Prefs().getAppTheme();

  return showDialog(
    context: _,
    // Allows WebViewStack and WebViewFill to control the SafeArea for fullscreen mode
    useSafeArea: false,
    // Avoids browser going back if user taps the screen side (in which case, willPopCallback triggers as)
    barrierDismissible: false,
    builder: (BuildContext context) {
      return WebViewStackView(
        initUrl: initUrl,
        dialog: true,
        recallLastSession: recallLastSession,
        restoredTheme: restoredTheme,
      );
    },
  );
}
