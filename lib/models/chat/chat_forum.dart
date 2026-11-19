import 'dart:math' as math;

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:torn_pda/models/chat/chat_links.dart';

enum ChatForumBlockKind { heading, subheading, paragraph, bullet, rule, image }

typedef ChatForumSpan = ({String text, bool bold, int? color, String? link});

class ChatForumBlock {
  final ChatForumBlockKind kind;
  final List<ChatForumSpan> spans;
  final String? image;
  final String? alt;
  final int? width;

  /// Inside a list item, under its bullet
  final bool nested;

  const ChatForumBlock(this.kind, {this.spans = const [], this.image, this.alt, this.width, this.nested = false});

  String get text => spans.map((s) => s.text).join();
}

class ChatForumPost {
  final int id;
  final int authorId;
  final String author;
  final int? karma;
  final DateTime createdAt;
  final String content;
  final bool edited;
  final bool pinned;
  final int likes;
  final int dislikes;
  final int? quotedPostId;

  const ChatForumPost({
    required this.id,
    required this.authorId,
    required this.author,
    required this.createdAt,
    required this.content,
    this.karma,
    this.edited = false,
    this.pinned = false,
    this.likes = 0,
    this.dislikes = 0,
    this.quotedPostId,
  });

  static ChatForumPost? fromJson(dynamic json) {
    if (json is! Map || json['id'] is! int) return null;
    final author = json['author'] is Map ? json['author'] as Map : const {};
    final created = json['created_time'];
    return ChatForumPost(
      id: json['id'] as int,
      authorId: author['id'] is int ? author['id'] as int : 0,
      author: '${author['username'] ?? ''}',
      createdAt: DateTime.fromMillisecondsSinceEpoch((created is int ? created : 0) * 1000),
      content: '${json['content'] ?? ''}',
      karma: author['karma'] is int ? author['karma'] as int : null,
      edited: json['is_edited'] == true,
      pinned: json['is_pinned'] == true,
      likes: json['likes'] is int ? json['likes'] as int : 0,
      dislikes: json['dislikes'] is int ? json['dislikes'] as int : 0,
      quotedPostId: json['quoted_post_id'] is int ? json['quoted_post_id'] as int : null,
    );
  }
}

class ChatForumPage {
  final List<ChatForumPost> posts;
  final bool hasNext;

  const ChatForumPage(this.posts, {required this.hasNext});

  static ChatForumPage? fromJson(dynamic json) {
    if (json is! Map || json['posts'] is! List) return null;
    final meta = json['_metadata'] is Map ? json['_metadata'] as Map : const {};
    final links = meta['links'] is Map ? meta['links'] as Map : const {};
    return ChatForumPage(
      (json['posts'] as List).map(ChatForumPost.fromJson).whereType<ChatForumPost>().toList(),
      hasNext: links['next'] is String && (links['next'] as String).isNotEmpty,
    );
  }
}

typedef ChatForumFind = ({ChatForumPost? post, int? number, bool failed});

class ChatForum {
  ChatForum._();

  /// Binary search, post ids grow with the page
  static Future<ChatForumFind> findPost(
    int id,
    int total,
    Future<ChatForumPage?> Function(int page) load, {
    Map<int, ChatForumPage>? cache,
  }) async {
    final pages = cache ?? <int, ChatForumPage>{};
    var low = 1;
    var high = ChatForum.pages(total);
    while (low <= high) {
      final middle = (low + high) ~/ 2;
      final page = pages[middle] ?? await load(middle);
      if (page == null) return (post: null, number: null, failed: true);
      pages[middle] = page;
      final posts = page.posts;
      if (posts.isEmpty) {
        high = middle - 1;
        continue;
      }
      final at = posts.indexWhere((post) => post.id == id);
      if (at >= 0) return (post: posts[at], number: offsetOf(middle) + at + 1, failed: false);
      // Pinned posts may repeat on top
      final ordered = [
        for (final post in posts)
          if (!post.pinned) post.id,
      ];
      final ids = ordered.isEmpty ? [for (final post in posts) post.id] : ordered;
      if (id < ids.reduce(math.min)) {
        high = middle - 1;
      } else if (id > ids.reduce(math.max)) {
        low = middle + 1;
      } else {
        break;
      }
    }
    return (post: null, number: null, failed: false);
  }

  // Fixed by the API
  static const int pageSize = 20;

  static int pageOf(int offset) => offset ~/ pageSize + 1;

  static int pages(int posts) => posts <= 0 ? 1 : (posts + pageSize - 1) ~/ pageSize;

  static int offsetOf(int page) => (page < 1 ? 0 : page - 1) * pageSize;

  /// Torn's web page, at [start] or at post [to]
  static String webLink(int thread, {int? forum, int start = 0, int? to}) =>
      'https://www.torn.com/forums.php#/p=threads${forum == null ? '' : '&f=$forum'}&t=$thread&b=0&a=0'
      '${to == null ? '&start=$start' : '&to=$to'}';

  /// Page offset from the web link's start
  static int startOf(Uri uri) {
    final start = int.tryParse(tornLinkParams(uri)['start'] ?? '') ?? 0;
    return start <= 0 ? 0 : start - start % pageSize;
  }

  static final Uri _torn = Uri.parse('https://www.torn.com/');

  // Relative to Torn, http(s) only
  static String? _web(String? raw) {
    final uri = Uri.tryParse(raw?.trim() ?? '');
    if (uri == null || (uri.hasScheme && uri.scheme != 'https' && uri.scheme != 'http')) return null;
    if (!uri.hasScheme && (uri.path.isEmpty && !uri.hasQuery && !uri.hasFragment)) return null;
    return uri.hasScheme ? '$uri' : '${_torn.resolveUri(uri)}';
  }

  static final RegExp _color = RegExp(r'(?:^|;)\s*color\s*:\s*#([0-9a-f]{6}|[0-9a-f]{3})\b', caseSensitive: false);

  static int? colorOf(String? style) {
    final hex = _color.firstMatch(style ?? '')?.group(1);
    if (hex == null) return null;
    final full = hex.length == 3 ? hex.split('').map((c) => '$c$c').join() : hex;
    return 0xFF000000 | int.parse(full, radix: 16);
  }

  static List<ChatForumBlock> blocks(String source) {
    final blocks = <ChatForumBlock>[];
    var kind = ChatForumBlockKind.paragraph;
    var spans = <ChatForumSpan>[];
    var inList = 0;

    void flush() {
      while (spans.isNotEmpty && spans.first.text.trim().isEmpty) {
        spans.removeAt(0);
      }
      while (spans.isNotEmpty && spans.last.text.trim().isEmpty) {
        spans.removeLast();
      }
      if (spans.isNotEmpty) {
        final first = spans.first;
        spans[0] = (text: first.text.trimLeft(), bold: first.bold, color: first.color, link: first.link);
        final last = spans.last;
        spans[spans.length - 1] = (text: last.text.trimRight(), bold: last.bold, color: last.color, link: last.link);
        blocks.add(ChatForumBlock(kind, spans: spans, nested: inList > 0 && kind != ChatForumBlockKind.bullet));
      }
      spans = [];
      kind = ChatForumBlockKind.paragraph;
    }

    void walk(dom.Node node, {bool bold = false, int? color, String? link}) {
      void children({bool? asBold, int? withColor, String? toLink}) {
        for (final child in node.nodes) {
          walk(child, bold: asBold ?? bold, color: withColor ?? color, link: toLink ?? link);
        }
      }

      void block(ChatForumBlockKind as) {
        // A list item's text may come wrapped
        final bullet = kind == ChatForumBlockKind.bullet && spans.every((s) => s.text.trim().isEmpty);
        flush();
        kind = bullet ? ChatForumBlockKind.bullet : as;
        children();
        flush();
      }

      if (node is dom.Text) {
        final text = node.text.replaceAll(RegExp(r'\s+'), ' ');
        if (text.isNotEmpty) spans.add((text: text, bold: bold, color: color, link: link));
        return;
      }
      if (node is! dom.Element) return;
      switch (node.localName) {
        case 'br':
          spans.add((text: '\n', bold: bold, color: color, link: link));
        case 'hr':
          flush();
          blocks.add(ChatForumBlock(ChatForumBlockKind.rule, nested: inList > 0));
        case 'style' || 'script' || 'noscript' || 'template':
          return;
        case 'img':
          final src = _web(node.attributes['src']);
          if (src == null) return;
          flush();
          blocks.add(
            ChatForumBlock(
              ChatForumBlockKind.image,
              image: src,
              alt: node.attributes['alt'],
              width: int.tryParse(node.attributes['width'] ?? ''),
              nested: inList > 0,
            ),
          );
        case 'h1' || 'h2':
          block(ChatForumBlockKind.heading);
        case 'h3' || 'h4' || 'h5' || 'h6':
          block(ChatForumBlockKind.subheading);
        case 'li':
          flush();
          kind = ChatForumBlockKind.bullet;
          inList++;
          children();
          flush();
          inList--;
        case 'p' || 'div' || 'blockquote':
          block(ChatForumBlockKind.paragraph);
        case 'strong' || 'b':
          children(asBold: true);
        case 'span' || 'font':
          children(withColor: colorOf(node.attributes['style']));
        case 'a':
          children(toLink: _web(node.attributes['href']));
        default:
          children();
      }
    }

    for (final node in html.parseFragment(source).nodes) {
      walk(node);
    }
    flush();
    return blocks;
  }
}
