import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:html/parser.dart';

class WebViewUtils {
  /// Checks for a specific element by [selector] in the HTML from [webViewController]
  /// It will attempt to find the element(s) up to [maxSeconds] total, checking every [intervalSeconds]
  ///
  /// If [returnElements] is true, it returns a tuple-like result:
  /// {
  ///   'document': dom.Document,
  ///   'elements': List<dom.Element>
  /// }
  ///
  /// Otherwise, it only returns the [dom.Document]
  ///
  /// If the element is never found, returns null
  static Future<Map<String, dynamic>?> waitForElement({
    required InAppWebViewController webViewController,
    required String selector,
    int maxSeconds = 6,
    int intervalSeconds = 1,
    bool returnElements = false,
  }) async {
    final int attempts = (maxSeconds / intervalSeconds).ceil();

    for (int attempt = 0; attempt < attempts; attempt++) {
      await Future.delayed(Duration(seconds: intervalSeconds));

      final html = await webViewController.getHtml();
      final document = parse(html);
      final elements = document.querySelectorAll(selector);

      if (elements.isNotEmpty) {
        if (returnElements) {
          return {'document': document, 'elements': elements};
        } else {
          return {'document': document};
        }
      }
    }

    return null;
  }
}
