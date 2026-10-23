/// Third party exceptions embed the full request URI, and those carry user API keys,
/// so strip them before it reaches Crashlytics
String redactUrlQueries(String input) {
  return input.replaceAllMapped(RegExp(r'''(https?://[^\s?'"]+)\?[^\s'"]*'''), (match) => '${match[1]}?<redacted>');
}

String scrub(String text) => redactUrlQueries(text)
    .replaceAll(RegExp(r'''key=[^&\s'"]*''', caseSensitive: false), 'key=<redacted>')
    .replaceAll(RegExp(r'\b[A-Za-z0-9]{16}\b'), '<redacted>');
