import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:torn_pda/models/chat/chat_forum.dart';
import 'package:torn_pda/models/chat/chat_links.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_money.dart';
import 'package:torn_pda/models/chat/chat_player_color.dart';
import 'package:torn_pda/providers/chat/chat_link_info.dart';
import 'package:torn_pda/torn-pda-native/stats/stats_controller.dart';
import 'package:torn_pda/widgets/chat/chat_image_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_link_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_toast.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

Future<void> showChatForumReader(BuildContext context, ChatLink link) {
  StatsController.chat.count('forum_reader');
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => ChatForumReader(link: link),
  );
}

class ChatForumReader extends StatefulWidget {
  const ChatForumReader({super.key, required this.link});

  final ChatLink link;

  @override
  State<ChatForumReader> createState() => _ChatForumReaderState();
}

class _ChatForumReaderState extends State<ChatForumReader> {
  late final int _thread = widget.link.id!;

  // Offset where the forward list starts
  late int _start = ChatForum.startOf(widget.link.uri);
  late int _next = _start;
  late int _prev = _start;
  late int _page = ChatForum.pageOf(_start);

  // Earlier posts, nearest first
  final List<ChatForumPost> _before = [];
  final List<ChatForumPost> _after = [];
  final Map<int, int> _numbers = {};
  final Map<int, GlobalKey> _keys = {};
  final GlobalKey _list = GlobalKey();
  final GlobalKey _center = GlobalKey();
  final ScrollController _scroll = ScrollController();
  String? _title;
  int? _total;
  bool _loadingNext = false;
  bool _loadingPrev = false;
  bool _failedNext = false;
  bool _failedPrev = false;
  bool _more = true;
  bool _scrolledUp = false;
  Future<void>? _busy;
  int? _seeking;
  final Map<int, ChatForumPage> _found = {};
  int? _flashed;
  Timer? _flash;

  // Bumped when jumping to another page
  int _run = 0;

  int? get _pages => _total == null ? null : ChatForum.pages(_total!);

  int get _shownPage => _pages == null ? _page : math.min(_page, _pages!);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadThread();
    _loadNext();
  }

  @override
  void dispose() {
    _flash?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _track(Future<void> Function() load) {
    final done = Completer<void>();
    _busy = done.future;
    return load().whenComplete(done.complete);
  }

  Future<void> _loadThread() async {
    try {
      final thread = await ChatLinkPreviews.fetchThread(_thread).timeout(const Duration(seconds: 20));
      if (!mounted || thread == null) return;
      setState(() {
        _title = thread.title;
        _total = thread.posts;
      });
      if (thread.posts > 0 && _start >= thread.posts) _goTo(ChatForum.pages(thread.posts));
    } catch (_) {}
  }

  void _onScroll() {
    final position = _scroll.position;
    if (position.userScrollDirection == ScrollDirection.forward) _scrolledUp = true;
    if (_scrolledUp && !_failedPrev && position.pixels < position.minScrollExtent + 300) _loadPrev();
    if (!_failedNext && position.pixels > position.maxScrollExtent - 600) _loadNext();
    _findPage();
  }

  // Page of the first post on screen
  void _findPage() {
    final list = _list.currentContext?.findRenderObject() as RenderBox?;
    if (list == null || !list.attached) return;
    for (final post in [..._before.reversed, ..._after]) {
      final box = _keys[post.id]?.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;
      if (box.localToGlobal(Offset(0, box.size.height), ancestor: list).dy <= 0) continue;
      final page = ChatForum.pageOf(_numbers[post.id]! - 1);
      if (page != _page) setState(() => _page = page);
      return;
    }
  }

  List<ChatForumPost> _fresh(List<ChatForumPost> posts) => posts.where((p) => !_numbers.containsKey(p.id)).toList();

  Future<void> _loadNext() async {
    if (_loadingNext || _loadingPrev || !_more) return;
    return _track(_fetchNext);
  }

  Future<void> _fetchNext() async {
    final run = _run;
    setState(() {
      _loadingNext = true;
      _failedNext = false;
    });
    final page = await ChatLinkPreviews.forumPage(_thread, _next);
    if (!mounted || run != _run) return;
    setState(() {
      _loadingNext = false;
      if (page == null) {
        _failedNext = true;
        return;
      }
      for (final (i, post) in page.posts.indexed) {
        if (_numbers.containsKey(post.id)) continue;
        _numbers[post.id] = _next + i + 1;
        _after.add(post);
      }
      _next += page.posts.length;
      _more = page.hasNext && page.posts.isNotEmpty;
    });
    // A short page may not scroll at all
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && run == _run && _scroll.hasClients) _onScroll();
    });
  }

  /// False when it did not start
  Future<bool> _loadPrev() async {
    if (_loadingPrev || _loadingNext || _prev <= 0) return false;
    await _track(_fetchPrev);
    return true;
  }

  Future<void> _fetchPrev() async {
    final run = _run;
    final offset = math.max(0, _prev - ChatForum.pageSize);
    setState(() {
      _loadingPrev = true;
      _failedPrev = false;
    });
    final page = await ChatLinkPreviews.forumPage(_thread, offset);
    if (!mounted || run != _run) return;
    setState(() {
      _loadingPrev = false;
      if (page == null) {
        _failedPrev = true;
        return;
      }
      final posts = _fresh(page.posts);
      for (final (i, post) in posts.indexed) {
        _numbers[post.id] = offset + i + 1;
      }
      _before.addAll(posts.reversed);
      _prev = offset;
    });
  }

  void _goTo(int page) {
    final last = _pages;
    final target = last == null ? math.max(1, page) : page.clamp(1, last);
    final offset = ChatForum.offsetOf(target);
    final first = [..._before.reversed, ..._after].where((p) => _numbers[p.id] == offset + 1).firstOrNull;
    final shown = first == null ? null : _keys[first.id]?.currentContext;
    if (shown != null) {
      Scrollable.ensureVisible(shown, duration: const Duration(milliseconds: 250));
      return;
    }
    setState(() {
      _run++;
      _before.clear();
      _after.clear();
      _numbers.clear();
      _keys.clear();
      _start = offset;
      _next = offset;
      _prev = offset;
      _page = target;
      _more = true;
      _failedNext = false;
      _failedPrev = false;
      _loadingNext = false;
      _loadingPrev = false;
      _scrolledUp = false;
      _seeking = null;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
    _loadNext();
  }

  Future<void> _reply(int id) async {
    final loaded = [..._before, ..._after].where((post) => post.id == id).firstOrNull;
    if (loaded != null) return _showQuoted(loaded, _numbers[id]!);
    if (_seeking != null) return;
    final run = _run;
    setState(() => _seeking = id);
    bool stale() => !mounted || run != _run || _seeking != id;
    if (_total == null) await _loadThread();
    if (stale()) return;
    final total = _total;
    final found = total == null
        ? (post: null, number: null, failed: true)
        : await ChatForum.findPost(
            id,
            total,
            (page) => ChatLinkPreviews.forumPage(_thread, ChatForum.offsetOf(page)),
            cache: _found,
          );
    if (stale()) return;
    setState(() => _seeking = null);
    final post = found.post;
    if (post != null) {
      _showQuoted(post, found.number!);
    } else if (found.failed) {
      _openInTorn(to: id);
    } else {
      chatToast('Quoted post is gone');
    }
  }

  Future<void> _showQuoted(ChatForumPost post, int number) async {
    final go = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _ForumPostView(
                  post: post,
                  number: number,
                  replyTo: post.quotedPostId == null ? null : _numbers[post.quotedPostId],
                  onReply: post.quotedPostId == null
                      ? null
                      : () {
                          Navigator.pop(context);
                          _reply(post.quotedPostId!);
                        },
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: FilledButton.tonalIcon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.forum_outlined, size: 18),
                  label: Text('Go to page ${ChatForum.pageOf(number - 1)}'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (go != true || !mounted) return;
    if (_numbers.containsKey(post.id)) return _reveal(post.id);
    _goTo(ChatForum.pageOf(number - 1));
    final run = _run;
    await _busy;
    if (!mounted || run != _run) return;
    await WidgetsBinding.instance.endOfFrame;
    if (mounted && run == _run) await _reveal(post.id);
  }

  // Earlier posts may not be built yet
  Future<void> _reveal(int id) async {
    final run = _run;
    for (var i = 0; i < 40 && mounted && run == _run; i++) {
      final shown = _keys[id]?.currentContext;
      if (shown != null) {
        await Scrollable.ensureVisible(shown, duration: const Duration(milliseconds: 250), alignment: 0.1);
        if (!mounted) return;
        _flash?.cancel();
        setState(() => _flashed = id);
        _flash = Timer(const Duration(milliseconds: 1500), () {
          if (mounted) setState(() => _flashed = null);
        });
        return;
      }
      if (!_scroll.hasClients) return;
      final position = _scroll.position;
      final up = (position.pixels - position.viewportDimension).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      if (up == position.pixels) return;
      _scroll.jumpTo(up);
      await WidgetsBinding.instance.endOfFrame;
    }
  }

  Future<void> _pickPage() async {
    final last = _pages;
    var typed = '$_shownPage';
    final picked = await showDialog<int>(
      context: context,
      builder: (context) {
        void go(String text) {
          final page = int.tryParse(text);
          if (page != null) Navigator.pop(context, page);
        }

        return AlertDialog(
          title: Text(last == null ? 'Go to page' : 'Go to page (1 to $last)'),
          content: TextFormField(
            initialValue: typed,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Page'),
            onChanged: (v) => typed = v,
            onFieldSubmitted: go,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, 1), child: const Text('First')),
            if (last != null) TextButton(onPressed: () => Navigator.pop(context, last), child: const Text('Last')),
            FilledButton(onPressed: () => go(typed), child: const Text('Go')),
          ],
        );
      },
    );
    if (picked != null && mounted) _goTo(picked);
  }

  void _openInTorn({int? to}) {
    final url = ChatForum.webLink(_thread, forum: widget.link.forumId, start: ChatForum.offsetOf(_shownPage), to: to);
    Navigator.of(context).pop();
    NativeChat.openLink(url, always: true);
  }

  Widget _post(ChatForumPost post) {
    final quoted = post.quotedPostId;
    return KeyedSubtree(
      key: _keys.putIfAbsent(post.id, GlobalKey.new),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ForumPostView(
            post: post,
            number: _numbers[post.id]!,
            replyTo: quoted == null ? null : _numbers[quoted],
            onReply: quoted == null ? null : () => _reply(quoted),
            seeking: quoted != null && _seeking == quoted,
            flashed: _flashed == post.id,
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final last = _pages;
    final page = _shownPage;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [
                    'Forum - read only',
                    if (_total != null) _total == 1 ? '1 post' : '${chatCount(_total!)} posts',
                  ].join(' - '),
                  style: muted,
                ),
                Text(
                  _title ?? widget.link.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Previous page',
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: page > 1 ? () => _goTo(page - 1) : null,
                    ),
                    Tooltip(
                      message: 'Go to page',
                      child: TextButton(
                        onPressed: _pickPage,
                        child: Text(last == null ? 'Page $page' : 'Page $page of $last'),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Next page',
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: last == null || page < last ? () => _goTo(page + 1) : null,
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _openInTorn,
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text('Open in Torn'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: CustomScrollView(
              key: _list,
              controller: _scroll,
              center: _center,
              slivers: [
                if (_prev > 0) SliverToBoxAdapter(child: _earlier(theme)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.builder(itemCount: _before.length, itemBuilder: (context, i) => _post(_before[i])),
                ),
                SliverPadding(
                  key: _center,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.builder(itemCount: _after.length, itemBuilder: (context, i) => _post(_after[i])),
                ),
                SliverToBoxAdapter(child: _later(theme)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _earlier(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: _loadingPrev
            ? const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2))
            : TextButton(onPressed: _loadPrev, child: const Text('Earlier posts')),
      ),
    );
  }

  Widget _later(ThemeData theme) {
    final Widget child;
    if (_loadingNext) {
      child = const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2));
    } else if (_failedNext) {
      child = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Couldn't load the posts", style: theme.textTheme.bodyMedium),
          TextButton(onPressed: _loadNext, child: const Text('Retry')),
        ],
      );
    } else if (!_more) {
      child = Text(_numbers.isEmpty ? 'No posts' : 'End of the thread', style: theme.textTheme.bodySmall);
    } else {
      child = const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(child: child),
    );
  }
}

class _ForumPostView extends StatefulWidget {
  const _ForumPostView({
    required this.post,
    required this.number,
    this.replyTo,
    this.onReply,
    this.seeking = false,
    this.flashed = false,
  });

  final ChatForumPost post;
  final int number;

  /// Quoted post number, if loaded
  final int? replyTo;
  final VoidCallback? onReply;
  final bool seeking;
  final bool flashed;

  @override
  State<_ForumPostView> createState() => _ForumPostViewState();
}

class _ForumPostViewState extends State<_ForumPostView> {
  late final List<ChatForumBlock> _blocks = ChatForum.blocks(widget.post.content);
  final List<TapGestureRecognizer> _taps = [];

  @override
  void dispose() {
    for (final tap in _taps) {
      tap.dispose();
    }
    super.dispose();
  }

  TextSpan _span(ChatForumSpan span, Color background) {
    final link = span.link == null ? null : ChatLink.parse(span.link!);
    final color = span.color;
    TapGestureRecognizer? tap;
    if (link != null) {
      tap = TapGestureRecognizer()..onTap = () => openChatLink(context, link);
      _taps.add(tap);
    }
    return TextSpan(
      text: span.text,
      recognizer: tap,
      style: TextStyle(
        fontWeight: span.bold ? FontWeight.w700 : null,
        color: link != null
            ? Theme.of(context).colorScheme.primary
            : color == null
            ? null
            : ChatPlayerColor.tinted(Color(color), background),
        decoration: link != null ? TextDecoration.underline : null,
      ),
    );
  }

  Widget _block(ChatForumBlock block, ThemeData theme) {
    final background = theme.bottomSheetTheme.backgroundColor ?? theme.colorScheme.surfaceContainerLow;
    final style = switch (block.kind) {
      ChatForumBlockKind.heading => theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ChatForumBlockKind.subheading => theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      _ => theme.textTheme.bodyMedium?.copyWith(height: 1.4),
    };
    final Widget child = switch (block.kind) {
      ChatForumBlockKind.rule => const Divider(),
      ChatForumBlockKind.image => _image(block, theme),
      ChatForumBlockKind.bullet => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•  ', style: style),
          Expanded(
            child: Text.rich(TextSpan(children: [for (final s in block.spans) _span(s, background)]), style: style),
          ),
        ],
      ),
      _ => Text.rich(TextSpan(children: [for (final s in block.spans) _span(s, background)]), style: style),
    };
    return Padding(
      padding: EdgeInsets.only(left: block.nested ? 18 : 0, top: 4, bottom: 4),
      child: child,
    );
  }

  Widget _image(ChatForumBlock block, ThemeData theme) {
    final link = ChatLink.parse(block.image!);
    if (link == null) return const SizedBox.shrink();
    final room = MediaQuery.sizeOf(context).width - 32 - (block.nested ? 18 : 0);
    final width = math.min((block.width ?? 320).toDouble(), room).clamp(48.0, 600.0);
    return Semantics(
      label: block.alt,
      child: ChatImageCard(
        link: link,
        color: theme.colorScheme.onSurface,
        trusted: true,
        maxWidth: width,
        maxHeight: math.min(width * 2, 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    for (final tap in _taps) {
      tap.dispose();
    }
    _taps.clear();
    final theme = Theme.of(context);
    final post = widget.post;
    final ago = ChatLastAction.ago(post.createdAt, DateTime.now());
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: widget.flashed ? theme.colorScheme.primary.withValues(alpha: 0.12) : Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: post.authorId > 0
                      ? () => showChatPlayerActions(context, ChatUser(id: post.authorId, name: post.author))
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: post.author,
                            style: TextStyle(fontWeight: FontWeight.w700, color: theme.colorScheme.primary),
                          ),
                          if (post.authorId > 0)
                            TextSpan(text: ' [${post.authorId}]', style: theme.textTheme.bodySmall),
                          if (post.karma != null)
                            TextSpan(text: ' - ${chatCount(post.karma!)} karma', style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (post.pinned)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.push_pin_rounded,
                    size: 14,
                    semanticLabel: 'Pinned',
                    color: theme.colorScheme.primary,
                  ),
                ),
              Text(
                '#${widget.number} - ${ago == null ? 'now' : '$ago ago'}${post.edited ? ' - edited' : ''}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          if (post.quotedPostId != null)
            Semantics(
              hint: 'shows the quoted post',
              child: TextButton.icon(
                onPressed: widget.seeking ? null : widget.onReply,
                style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                icon: widget.seeking
                    ? const SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.reply_rounded, size: 16),
                label: Text(
                  widget.seeking
                      ? 'Finding the quoted post'
                      : widget.replyTo == null
                      ? 'Reply to an earlier post'
                      : 'Reply to #${widget.replyTo}',
                ),
              ),
            ),
          for (final block in _blocks) _block(block, theme),
          if (post.likes > 0 || post.dislikes > 0)
            Semantics(
              label:
                  '${post.likes} ${post.likes == 1 ? 'like' : 'likes'}, '
                  '${post.dislikes} ${post.dislikes == 1 ? 'dislike' : 'dislikes'}',
              excludeSemantics: true,
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Icon(Icons.thumb_up_alt_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                    Text(' ${post.likes}   ', style: theme.textTheme.bodySmall),
                    Icon(Icons.thumb_down_alt_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                    Text(' ${post.dislikes}', style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
