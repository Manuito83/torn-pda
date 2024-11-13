import 'package:flutter/material.dart';

/// Fixes malformed HTML in Events
///
/// The HTML content received from the API may contain malformed `href` attributes,
/// multiple `http://www.torn.com/` prefixes, etc.
///
/// ** Incoming HTML:
/// ```html
/// <a href = http://www.torn.com/http://www.torn.com/profiles.php?XID=2561411>TugBoatTimm</a>
/// ```
///
/// ** Output:
/// ```html
/// <a href="http://www.torn.com/profiles.php?XID=2561411">TugBoatTimm</a>
/// ```
String fixHrefAttributes(String message) {
  RegExp hrefExp = RegExp(r'href\s*=\s*(.+?)(?=\s|>|\/>)', caseSensitive: false);

  message = message.replaceAllMapped(hrefExp, (match) {
    String hrefValue = match.group(1) ?? '';

    // Remove any leading and trailing quotes and spaces
    // Example found in:
    // <a href = http://www.torn.com/"http://www.torn.com/http://www.torn.com/profiles.php?XID=123456">
    hrefValue = hrefValue.trim().replaceAll('"', '').replaceAll("'", '');

    // Find the last occurrence of 'www.torn.com' in hrefValue
    int index = hrefValue.lastIndexOf('www.torn.com');
    if (index != -1) {
      // Substring after the last 'www.torn.com'
      String path = hrefValue.substring(index + 'www.torn.com'.length);

      // Add 'https://www.torn.com' in front
      return 'href="https://www.torn.com$path"';
    } else {
      // If 'www.torn.com' is not found, return the original href attribute
      return match.group(0) ?? '';
    }
  });

  return message;
}

Widget buildEventMessageWidget(String message, FontWeight fontWeight, Function launchBrowser) {
  String fixedMessage = fixHrefAttributes(message);
  List<InlineSpan> spans = [];

  RegExp exp = RegExp(r'<a\b[^>]*?href\s*=\s*"(.*?)"[^>]*>(.*?)<\/a>', caseSensitive: false);

  int currentIndex = 0;

  Iterable<RegExpMatch> matches = exp.allMatches(fixedMessage);

  for (final match in matches) {
    int matchStart = match.start;
    int matchEnd = match.end;

    // Add text before the match
    if (matchStart > currentIndex) {
      String text = fixedMessage.substring(currentIndex, matchStart);
      spans.add(TextSpan(text: text));
    }

    // Extract href and link text
    String href = match.group(1) ?? '';
    String linkText = match.group(2) ?? '';

    spans.add(WidgetSpan(
      child: GestureDetector(
        onTap: () {
          launchBrowser(url: href, shortTap: true);
        },
        onLongPress: () {
          launchBrowser(url: href, shortTap: false);
        },
        child: Text(
          linkText,
          style: TextStyle(
            color: Colors.blue,
            decoration: TextDecoration.none,
            fontWeight: fontWeight,
            fontSize: 12,
          ),
        ),
      ),
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
    ));

    currentIndex = matchEnd;
  }

  // Add any remaining text after the last match
  if (currentIndex < fixedMessage.length) {
    String text = fixedMessage.substring(currentIndex);
    spans.add(TextSpan(text: text));
  }

  return RichText(
    text: TextSpan(
      children: spans,
      style: TextStyle(
        fontSize: 12,
        fontWeight: fontWeight,
        color: Colors.black,
      ),
    ),
  );
}

String processEventMessage(String message) {
  String newMessage = message;

  Map<String, String> corrections = {
    'View the details here!': 'view',
    'Please click here to continue.': 'view',
    'Please click here.': 'view',
    'Please click here to collect your funds.': 'Collect',
  };

  corrections.forEach((error, correction) {
    newMessage = newMessage.replaceAll(error, correction);
  });

  // Regular expression to replace [view] with (view), preserving links
  RegExp bracketedViewExp = RegExp(
    r'\[\s*(<a\b[^>]*?>\s*view\s*<\/a>|\bview\b)\s*\]',
    caseSensitive: false,
  );

  newMessage = newMessage.replaceAllMapped(bracketedViewExp, (match) {
    String content = match.group(1) ?? '';
    return '($content)';
  });

  return newMessage;
}
