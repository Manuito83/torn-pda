/// Same section, for fully locked tabs
bool isSameLockedSection(String currentUrl, String incomingUrl) {
  final current = Uri.tryParse(currentUrl);
  final incoming = Uri.tryParse(incomingUrl);
  if (current == null || incoming == null) return true;

  String host(Uri uri) => uri.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
  String path(Uri uri) => uri.path.isEmpty || uri.path == '/index.php' ? '/' : uri.path;
  if (host(current) != host(incoming) || path(current) != path(incoming)) return false;

  // page.php sections differ by sid
  String sid(Uri uri) => (uri.queryParameters['sid'] ?? '').toLowerCase();
  return sid(current) == sid(incoming);
}
