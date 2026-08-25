/// Third party exceptions embed the full request URI, and those carry user API keys,
/// so strip them before it reaches Crashlytics
String redactUrlQueries(String input) {
  return input.replaceAllMapped(RegExp(r'''(https?://[^\s?'"]+)\?[^\s'"]*'''), (match) => '${match[1]}?<redacted>');
}
