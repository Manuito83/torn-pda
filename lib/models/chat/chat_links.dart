import 'dart:io';

enum ChatLinkKind {
  player,
  bazaar,
  attack,
  attackLog,
  chainReport,
  warReport,
  trade,
  faction,
  company,
  forum,
  item,
  torn,
  external,
}

class ChatLink {
  final Uri uri;
  final String raw;
  final ChatLinkKind kind;
  final String title;
  final String? detail;

  /// Player, item, thread, faction, company or report
  final int? id;

  /// Forum section of a forum link
  final int? forumId;

  final String? label;

  /// Why it may be phishing
  final String? warning;

  const ChatLink({
    required this.uri,
    required this.raw,
    required this.kind,
    required this.title,
    this.detail,
    this.id,
    this.forumId,
    this.label,
    this.warning,
  });

  static const String lookalikeWarning = "Looks like Torn but isn't";

  bool get isTorn => kind != ChatLinkKind.external;

  static final RegExp _logCode = RegExp(r'^[0-9a-f]{32}$', caseSensitive: false);

  String? get logCode => kind == ChatLinkKind.attackLog ? _codeOf(uri) : null;

  static String? _codeOf(Uri uri) {
    try {
      for (final e in uri.queryParameters.entries) {
        if (e.key.toLowerCase() == 'id' && _logCode.hasMatch(e.value)) return e.value.toLowerCase();
      }
    } catch (_) {}
    return null;
  }

  String get url => uri.toString();

  static final RegExp _imagePath = RegExp(r'\.(png|jpe?g|gif|webp)$', caseSensitive: false);

  bool get isImage => _imagePath.hasMatch(uri.path);

  static final RegExp _videoId = RegExp(r'^[A-Za-z0-9_-]{11}$');

  String? get videoId {
    if (kind != ChatLinkKind.external || warning != null || uri.userInfo.isNotEmpty) return null;
    final host = uri.host.toLowerCase().replaceFirst(RegExp(r'^(www|m|music)\.'), '');
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    String? id;
    if (host == 'youtu.be') {
      id = segments.firstOrNull;
    } else if ((host == 'youtube.com' || host == 'youtube-nocookie.com') && segments.isNotEmpty) {
      if (segments.first == 'watch') {
        id = RegExp(r'(?:^|&)v=([^&#]*)').firstMatch(uri.query)?.group(1);
      } else if (segments.length > 1 && const ['shorts', 'live', 'embed', 'v'].contains(segments.first)) {
        id = segments[1];
      }
    }
    return id != null && _videoId.hasMatch(id) ? id : null;
  }

  // URLs end at the first non ASCII
  static final RegExp _pattern = RegExp(
    r'\[([^\[\]\n]{1,200})\]\(((?:https?://|www\.)[\x21\x23-\x27\x2A-\x3B\x3D\x3F-\x7E]+)\)'
    r'|(?:https?://|www\.|torn\.com/)[\x21\x23-\x3B\x3D\x3F-\x7E]+',
    caseSensitive: false,
  );
  static const String _trailing = '.,!?;:\'"*';

  static List<Object> split(String text) {
    final parts = <Object>[];
    var last = 0;
    for (final (start, end, link) in _found(text)) {
      if (start > last) parts.add(text.substring(last, start));
      parts.add(link);
      last = end;
    }
    if (last < text.length) parts.add(text.substring(last));
    return parts;
  }

  /// Start and end of each link
  static List<(int, int)> ranges(String text) => [for (final (start, end, _) in _found(text)) (start, end)];

  static Iterable<(int, int, ChatLink)> _found(String text) sync* {
    for (final match in _pattern.allMatches(text)) {
      final markdown = match.group(2) != null;
      var raw = match.group(2) ?? match.group(0)!;
      var end = match.end;
      if (!markdown) {
        if (match.start > 0 && RegExp(r'[\w.@/-]').hasMatch(text[match.start - 1])) continue;
        while (raw.isNotEmpty) {
          final c = raw[raw.length - 1];
          final unbalanced =
              (c == ')' && '('.allMatches(raw).length < ')'.allMatches(raw).length) ||
              (c == ']' && '['.allMatches(raw).length < ']'.allMatches(raw).length);
          if (!_trailing.contains(c) && !unbalanced) break;
          raw = raw.substring(0, raw.length - 1);
        }
        end = match.start + raw.length;
      }
      var link = parse(raw);
      if (link == null) continue;
      if (markdown) {
        final label = match.group(1)!.replaceAll(RegExp(r'\*\*|__'), '').trim();
        link = ChatLink(
          uri: link.uri,
          raw: link.raw,
          kind: link.kind,
          title: link.title,
          detail: link.detail,
          id: link.id,
          forumId: link.forumId,
          label: label.isEmpty ? null : label,
          warning: link.warning ?? (!link.isTorn && label.toLowerCase().contains('torn.com') ? lookalikeWarning : null),
        );
      }
      yield (match.start, end, link);
    }
  }

  static ChatLink? parse(String raw) {
    final withScheme = raw.toLowerCase().startsWith('http') ? raw : 'https://$raw';
    final uri = Uri.tryParse(withScheme);
    if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http') || uri.host.isEmpty) return null;
    if (!uri.host.contains('.')) return null;
    final host = uri.host.toLowerCase();
    final torn = uri.userInfo.isEmpty && (host == 'torn.com' || host.endsWith('.torn.com'));
    if (!torn) {
      final path = uri.path.length > 1 || uri.hasQuery ? '${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}' : null;
      return ChatLink(
        uri: uri,
        raw: raw,
        kind: ChatLinkKind.external,
        title: host,
        detail: path,
        warning: _warning(uri, host),
      );
    }

    final page = uri.pathSegments.isEmpty ? '' : uri.pathSegments.last.toLowerCase();
    final p = <String, String>{};
    for (final source in [uri.query, uri.fragment.replaceFirst(RegExp(r'^[/!]+'), '')]) {
      try {
        Uri.splitQueryString(source).forEach((k, v) => p[k.toLowerCase()] = v);
      } catch (_) {}
    }
    int? id(String key) => int.tryParse(p[key] ?? '');
    ChatLink card(ChatLinkKind kind, String title, [String? detail, int? id, int? forumId]) =>
        ChatLink(uri: uri, raw: raw, kind: kind, title: title, detail: detail, id: id, forumId: forumId);

    switch (page) {
      case 'profiles.php':
        final player = id('xid') ?? id('userid');
        if (player != null) return card(ChatLinkKind.player, 'Player [$player]', null, player);
      case 'bazaar.php':
        final player = id('userid');
        if (player != null) return card(ChatLinkKind.bazaar, 'Bazaar of [$player]', null, player);
      case 'loader.php':
        final player = id('user2id');
        final sid = p['sid']?.toLowerCase();
        if (sid == 'attack' && player != null) return card(ChatLinkKind.attack, 'Attack [$player]', null, player);
        if (sid == 'attacklog' && _codeOf(uri) != null) return card(ChatLinkKind.attackLog, 'Attack log');
      case 'war.php':
        final war = id('rankid');
        if (p['step']?.toLowerCase() == 'rankreport' && war != null) {
          return card(ChatLinkKind.warReport, 'War report #$war', null, war);
        }
        final warChain = id('chainid');
        if (p['step']?.toLowerCase() == 'chainreport' && warChain != null) {
          return card(ChatLinkKind.chainReport, 'Chain report #$warChain', null, warChain);
        }
      case 'trade.php':
        final trade = id('id');
        if (trade != null) return card(ChatLinkKind.trade, 'Trade #$trade');
        final player = id('userid');
        if (player != null) return card(ChatLinkKind.trade, 'Start a trade with [$player]');
      case 'factions.php':
        final chain = id('chainid');
        if (p['step']?.toLowerCase() == 'chainreport' && chain != null) {
          return card(ChatLinkKind.chainReport, 'Chain report #$chain', null, chain);
        }
        final faction = id('id');
        if (faction != null) return card(ChatLinkKind.faction, 'Faction [$faction]', null, faction);
      case 'joblist.php':
      case 'companies.php':
        final company = id('id');
        final owner = id('userid');
        if (company != null) return card(ChatLinkKind.company, 'Company [$company]', null, company);
        if (owner != null) return card(ChatLinkKind.company, 'Company of [$owner]');
        if (p['p'] == 'corpinfo') return card(ChatLinkKind.company, 'Company');
      case 'forums.php':
        final thread = id('t');
        final forum = id('f');
        if (thread != null) return card(ChatLinkKind.forum, 'Forum thread #$thread', null, thread, forum);
        if (forum != null) return card(ChatLinkKind.forum, 'Forum section #$forum', null, null, forum);
        return card(ChatLinkKind.forum, 'Forums');
      case 'imarket.php':
      case 'page.php':
        if (page == 'page.php' && p['sid']?.toLowerCase() == 'attacklog' && _codeOf(uri) != null) {
          return card(ChatLinkKind.attackLog, 'Attack log');
        }
        if (page == 'page.php' && p['sid']?.toLowerCase() != 'itemmarket') break;
        final name = (p['itemname'] ?? p['searchname'])?.trim();
        final item = id('itemid');
        if (name != null && name.isNotEmpty) return card(ChatLinkKind.item, name, 'Item market', item);
        if (item != null) return card(ChatLinkKind.item, 'Item #$item', 'Item market', item);
        return card(ChatLinkKind.item, 'Item market');
    }
    final path = uri.path.length > 1 ? uri.path.substring(1) : host;
    return card(ChatLinkKind.torn, path, uri.hasQuery ? uri.query : null);
  }

  static final RegExp _lookalikeLabel = RegExp(
    r'^(www)?torn(com|city)?$'
    r'|^torn(login|signin|secure|auth|verify|support|account|gift|reward|bonus|free|official|staff|admin|help|api|key)'
    r'|(login|signin|secure|auth|verify|support|account|gift|reward|bonus|free|official|staff|admin|help|api|key)torn$',
  );
  static final RegExp _credentialPath = RegExp(r'log-?in|sign-?in|password|api[-_]?key');

  static String? _warning(Uri uri, String host) {
    final userInfo = uri.userInfo.toLowerCase();
    if (userInfo.isNotEmpty) return userInfo.contains('torn') ? lookalikeWarning : 'Hidden address';
    final labels = host.split('.');
    final lookalike = labels
        .take(labels.length - 1)
        .map((l) => l.replaceAll('0', 'o').replaceAll(RegExp('[-_]'), ''))
        .any(_lookalikeLabel.hasMatch);
    if (lookalike) return lookalikeWarning;
    final rest = '${uri.path}?${uri.query}'.toLowerCase();
    if (rest.contains('torn') && _credentialPath.hasMatch(rest)) return lookalikeWarning;
    return null;
  }

  static final RegExp _numericHost = RegExp(r'^((0x[0-9a-f]*|[0-9]+)\.?)+$');
  static const List<String> _localSuffixes = ['.local', '.localhost', '.internal', '.lan', '.home.arpa'];

  /// Never the player's own network
  static bool isPublic(Uri uri) {
    if (uri.scheme != 'https' && uri.scheme != 'http') return false;
    if (uri.hasPort && uri.port != 80 && uri.port != 443) return false;
    final host = uri.host.toLowerCase().replaceFirst(RegExp(r'\.$'), '');
    final ip = InternetAddress.tryParse(host);
    if (ip != null) return _publicIp(ip);
    if (host == 'localhost' || !host.contains('.') || _localSuffixes.any(host.endsWith)) return false;
    return !_numericHost.hasMatch(host);
  }

  static bool _publicIp(InternetAddress ip) {
    if (ip.isLoopback || ip.isLinkLocal || ip.isMulticast) return false;
    final b = ip.rawAddress;
    if (ip.type == InternetAddressType.IPv4) return _publicV4(b);
    final mapped = b.take(10).every((x) => x == 0) && b[10] == 0xff && b[11] == 0xff;
    if (mapped) return _publicV4(b.sublist(12));
    if (b.every((x) => x == 0)) return false;
    return (b[0] & 0xfe) != 0xfc;
  }

  static bool _publicV4(List<int> b) {
    final (a, c) = (b[0], b[1]);
    if (a == 0 || a == 10 || a == 127 || a >= 224) return false;
    if (a == 100 && c >= 64 && c < 128) return false;
    if ((a == 169 && c == 254) || (a == 172 && c >= 16 && c < 32) || (a == 192 && c == 168)) return false;
    return true;
  }
}

class ChatPlayerRef {
  final int id;
  final String name;
  final String raw;

  const ChatPlayerRef(this.id, this.name, this.raw);

  static final RegExp _pattern = RegExp(r'(?<![\w-])([A-Za-z0-9_-]{1,16}) ?\[(\d{1,8})\]');

  static List<Object> split(String text) {
    final parts = <Object>[];
    var last = 0;
    for (final match in _pattern.allMatches(text)) {
      final id = int.parse(match.group(2)!);
      final name = match.group(1)!;
      if (id <= 0 || !name.contains(RegExp('[A-Za-z]'))) continue;
      if (match.start > last) parts.add(text.substring(last, match.start));
      parts.add(ChatPlayerRef(id, name, match.group(0)!));
      last = match.end;
    }
    if (last < text.length) parts.add(text.substring(last));
    return parts;
  }
}
