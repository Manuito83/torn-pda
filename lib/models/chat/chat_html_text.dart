import 'package:html/parser.dart' as html;

/// Torn's HTML as plain text
String chatHtmlText(String raw) {
  if (!raw.contains('&') && !raw.contains('<')) return raw;
  return html.parseFragment(raw).text ?? raw;
}

/// Entities decoded, tags kept as text
String chatHtmlUnescape(String raw) => chatHtmlText(raw.replaceAll('<', '&lt;'));
