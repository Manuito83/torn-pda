import 'package:torn_pda/models/chat/chat_links.dart';
import 'package:torn_pda/models/userscripts/script_catalog_model.dart';

class ChatScriptLink {
  const ChatScriptLink({required this.installUrl, required this.host, required this.name, required this.trusted});

  final String installUrl;
  final String host;
  final String? name;
  final bool trusted;

  static const List<String> _trustedHosts = ['greasyfork.org', 'github.com', 'raw.githubusercontent.com'];

  static ChatScriptLink? of(ChatLink link) {
    final uri = link.uri;
    if (link.kind != ChatLinkKind.external || link.warning != null || !uri.hasAuthority) return null;
    if (uri.scheme != 'https' || uri.userInfo.isNotEmpty) return null;
    final host = uri.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    final trusted = _trustedHosts.any((h) => host == h || host.endsWith('.$h'));
    if (segments.isNotEmpty && segments.last.toLowerCase().endsWith('.user.js')) {
      final file = segments.last;
      return ChatScriptLink(
        installUrl: link.url,
        host: host,
        name: _tidy(file.substring(0, file.length - '.user.js'.length)),
        trusted: trusted,
      );
    }
    if (host != 'greasyfork.org') return null;
    final at = segments.indexOf('scripts');
    if (at < 0 || at + 1 >= segments.length) return null;
    final id = CatalogScript.greasyforkIdFromUrl('greasyfork.org/scripts/${segments[at + 1]}');
    if (id == null) return null;
    final slug = segments[at + 1].replaceFirst(RegExp(r'^\d+-?'), '');
    return ChatScriptLink(
      installUrl: 'https://greasyfork.org/scripts/$id/code/${slug.isEmpty ? id : slug}.user.js',
      host: host,
      name: _tidy(slug),
      trusted: true,
    );
  }

  static String? _tidy(String raw) {
    var text = raw;
    try {
      text = Uri.decodeComponent(raw);
    } catch (_) {}
    text = text.replaceAll(RegExp(r'[-_+]+'), ' ').trim();
    return text.isEmpty ? null : text;
  }

  bool installedIn(Iterable<String?> urls) {
    final id = CatalogScript.greasyforkIdFromUrl(installUrl);
    return urls.any((u) => u == installUrl || (id != null && CatalogScript.greasyforkIdFromUrl(u) == id));
  }
}
