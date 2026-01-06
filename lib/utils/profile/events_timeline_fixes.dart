import 'package:flutter/material.dart';
import 'package:torn_pda/providers/theme_provider.dart';

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

    // Remove any leading/trailing quotes/spaces and stray spaces after commas in query params
    // Example found in:
    // <a href = http://www.torn.com/"http://www.torn.com/http://www.torn.com/profiles.php?XID=123456">
    hrefValue = hrefValue.trim().replaceAll('"', '').replaceAll("'", '');
    hrefValue = hrefValue.replaceAll(RegExp(r',\s+'), ',');

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

  // Convert [view] to (view) while preserving links
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

String stripUnsupportedHtmlTags(String message) {
  // Turn line breaks into actual new lines for readability.
  final breakFixed = message.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');

  // Strip everything except <a> and <b> tags.
  final cleaned = breakFixed.replaceAll(RegExp(r'<(?!/?(?:a|b)\b)[^>]+>', caseSensitive: false), '');

  return cleaned;
}

String _normalizePunctuationSpacing(String text) {
  // Remove stray spaces before punctuation such as commas.
  return text.replaceAll(RegExp(r'\s+([,.;:!?])'), r'$1');
}

Widget buildEventMessageWidget(
  String message,
  FontWeight fontWeight,
  Function launchBrowser,
  ThemeProvider themeProvider,
) {
  String fixedMessage = stripUnsupportedHtmlTags(fixHrefAttributes(message));
  List<InlineSpan> spans = [];

  // Regular expression for detecting <a> tags
  RegExp linkExp = RegExp(r'<a\b[^>]*?href\s*=\s*"(.*?)"[^>]*>(.*?)<\/a>', caseSensitive: false);

  int currentIndex = 0;

  // Find all <a> tags in the message
  Iterable<RegExpMatch> linkMatches = linkExp.allMatches(fixedMessage);

  for (final match in linkMatches) {
    int matchStart = match.start;
    int matchEnd = match.end;

    // Add any text before the <a> tag
    if (matchStart > currentIndex) {
      String textBeforeLink = _normalizePunctuationSpacing(fixedMessage.substring(currentIndex, matchStart));

      // Parse and add bold text spans if <b> tags are found within textBeforeLink
      spans.addAll(_parseBoldText(textBeforeLink, fontWeight));
    }

    // Extract href and link text for <a> tag
    String href = match.group(1) ?? '';
    String linkText = _normalizePunctuationSpacing(match.group(2) ?? '');

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

  // Add any remaining text after the last <a> tag
  if (currentIndex < fixedMessage.length) {
    String textAfterLastLink = _normalizePunctuationSpacing(fixedMessage.substring(currentIndex));
    spans.addAll(_parseBoldText(textAfterLastLink, fontWeight));
  }

  return RichText(
    text: TextSpan(
      children: spans,
      style: TextStyle(
        fontSize: 12,
        fontWeight: fontWeight,
        color: themeProvider.mainText,
      ),
    ),
  );
}

/// Helper function to parse text with <b> tags and apply bold styling
List<InlineSpan> _parseBoldText(String text, FontWeight fontWeight) {
  List<InlineSpan> spans = [];

  RegExp boldExp = RegExp(r'<b>(.*?)<\/b>', caseSensitive: false);
  int currentIndex = 0;

  // Iterate over bold matches
  for (final match in boldExp.allMatches(text)) {
    int matchStart = match.start;
    int matchEnd = match.end;

    // Add any text before <b> tag
    if (matchStart > currentIndex) {
      spans.add(TextSpan(text: text.substring(currentIndex, matchStart), style: TextStyle(fontWeight: fontWeight)));
    }

    // Add bold text
    String boldText = match.group(1) ?? '';
    spans.add(TextSpan(text: boldText, style: const TextStyle(fontWeight: FontWeight.bold)));

    currentIndex = matchEnd;
  }

  // Add any remaining text after the last <b> tag
  if (currentIndex < text.length) {
    spans.add(TextSpan(text: text.substring(currentIndex), style: TextStyle(fontWeight: fontWeight)));
  }

  return spans;
}
