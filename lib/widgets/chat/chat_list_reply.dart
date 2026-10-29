import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chat/chat_links.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_quote.dart';
import 'package:torn_pda/models/chat/chat_wiki.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';
import 'package:torn_pda/widgets/chat/chat_appearance_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_link_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_send_check_dialog.dart';
import 'package:torn_pda/widgets/chat/chat_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

class ChatListReply extends StatefulWidget {
  const ChatListReply({super.key, required this.room});

  final ChatRoom room;

  @override
  State<ChatListReply> createState() => _ChatListReplyState();
}

class _ChatListReplyState extends State<ChatListReply>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  static const double _indent = 78;
  static const double _slack = 24;

  late final ChatController _chat = context.read<ChatController>();
  final TextEditingController _text = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final GlobalKey _newestKey = GlobalKey();
  bool _hasText = false;
  Set<String>? _known;
  DateTime? _since;
  bool _opened = false;
  double? _cap;
  List<String> _capFor = const [];
  List<String> _newestIds = const [];
  bool _away = false;
  String? _frozenAt;
  String? _askedFor;
  late final AnimationController _open = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Peeking notifies, not during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _chat.peekRoom(widget.room.id);
    });
    _text.addListener(() {
      final hasText = _text.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 60) _chat.loadOlder(widget.room.id);
      final away = _scroll.position.pixels > _slack;
      if (away != _away) {
        setState(() {
          _away = away;
          _frozenAt = away ? _newestIds.firstOrNull : null;
        });
      }
    });
  }

  @override
  void dispose() {
    _chat.unpeekRoom(widget.room.id);
    _text.dispose();
    _scroll.dispose();
    _open.dispose();
    super.dispose();
  }

  // The block is as tall as the newest messages
  void _fit() {
    if (!mounted) return;
    final box = _newestKey.currentContext?.findRenderObject() as RenderBox?;
    final height = box != null && box.hasSize ? box.size.height : 0.0;
    if (height > 0 && ((height - (_cap ?? 0)).abs() > 0.5 || !listEquals(_capFor, _newestIds))) {
      setState(() {
        _cap = height;
        _capFor = _newestIds;
      });
      return;
    }
    final oldest = _chat.filteredMessagesFor(widget.room.id).firstOrNull?.id;
    if (_cap != null && _askedFor != oldest &&
        !_chat.loadingOlder &&
        _chat.hasOlder(widget.room.id) &&
        _scroll.hasClients && _scroll.position.extentAfter < 60) {
      _askedFor = oldest;
      _chat.loadOlder(widget.room.id);
    }
  }

  void _toNewest() {
    setState(() => _frozenAt = null);
    if (!_scroll.hasClients) return;
    if (MediaQuery.disableAnimationsOf(context)) return _scroll.jumpTo(0);
    _scroll.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  void _send() {
    final room = widget.room;
    sendChatChecked(
      context,
      _text.text,
      roomId: room.id,
      roomName: room.name,
      onSend: (text) => _chat.send(text, to: room.id),
    ).then((sent) {
      if (sent && mounted) {
        _text.clear();
        _toNewest();
      }
    });
  }

  Widget _body(ChatController chat, ChatMessage m, TextStyle? small) {
    final scheme = Theme.of(context).colorScheme;
    final prefs = NativeChat.prefs;
    if (m.isSystem) {
      return Text(
        m.content,
        style: small?.copyWith(color: scheme.onSurfaceVariant, fontStyle: FontStyle.italic),
      );
    }
    final quote = ChatQuote.parse(m.content);
    final forwarded = quote == null ? ChatQuote.forwarded(m.content) : null;
    final color = m.state == ChatMessageState.pending
        ? scheme.onSurfaceVariant.withValues(alpha: 0.6)
        : scheme.onSurfaceVariant;
    final mine = chat.myUserId != null && m.sender.id == chat.myUserId;
    final who = mine ? 'You' : prefs.displayName(m.sender.id, m.sender.name);
    final body = quote?.body ?? forwarded?.body ?? m.content;
    final spoken = [
      who,
      if (quote != null) 'replying to ${quote.author}: ${chatSpokenText(quote.excerpt)}',
      if (forwarded != null) 'forwarded from ${forwarded.from}',
      chatSpokenText(body),
      if (m.state == ChatMessageState.pending) 'sending',
      if (m.state == ChatMessageState.failed) 'not sent',
    ].join(', ');
    return Semantics(
      container: true,
      label: spoken,
      customSemanticsActions: {
        for (final ref in ChatPlayerRef.split(body).whereType<ChatPlayerRef>())
          CustomSemanticsAction(label: 'Options for ${ref.name}'): () =>
              showChatPlayerActions(context, ChatUser(id: ref.id, name: ref.name)),
        ...chatRefActions(context, body, roomId: m.roomId, slang: ChatWiki.slangIn(m.roomId, prefs.slangEverywhere)),
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (quote != null)
            ExcludeSemantics(
              child: Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.fromLTRB(8, 3, 8, 3),
                decoration: BoxDecoration(
                  color: scheme.onSurface.withValues(alpha: 0.06),
                  border: Border(left: BorderSide(color: scheme.onSurface.withValues(alpha: 0.4), width: 3)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${quote.author}\n',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: quote.excerpt),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: small?.copyWith(color: color),
                ),
              ),
            ),
          if (forwarded != null)
            ExcludeSemantics(
              child: Text(
                'Forwarded from ${forwarded.from}',
                style: small?.copyWith(color: color, fontStyle: FontStyle.italic),
              ),
            ),
          ChatMessageText(
            content: body,
            color: color,
            slang: ChatWiki.slangIn(m.roomId, prefs.slangEverywhere),
            lead: TextSpan(
              children: [
                if (m.state == ChatMessageState.failed)
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(Icons.error_outline_rounded, size: 15, color: scheme.error),
                    ),
                  ),
                TextSpan(
                  text: '$who  ',
                  style: TextStyle(fontWeight: FontWeight.w600, color: scheme.onSurface),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final chat = context.watch<ChatController>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final room = widget.room;
    final prefs = NativeChat.prefs;
    final peer = room.isDm ? ChatRoom.peerIdOf(room.id) : null;
    final name = peer == null ? room.name : prefs.displayName(peer, room.name);
    final all = chat.filteredMessagesFor(room.id);
    final last = chat.lastMessageIn(room.id);
    final count = prefs.listReplyCount;
    final listed = all.isEmpty ? [?last] : all;
    final cut = _frozenAt == null ? -1 : listed.lastIndexWhere((m) => (m.reqId ?? m.id) == _frozenAt);
    final shown = cut < 0 ? listed : listed.sublist(0, cut + 1);
    final loading = !chat.isLoaded(room.id);
    final failed = chat.openFailed(room.id);
    if (!loading && _known == null) {
      _known = {for (final m in all) m.reqId ?? m.id};
      final last = all.lastOrNull?.createdAt;
      final now = DateTime.now();
      _since = last != null && last.isAfter(now) ? last : now;
    }
    final known = _known;
    final fresh = known == null
        ? const <String>{}
        : {
            for (final m in all)
              if (known.add(m.reqId ?? m.id) && (_since?.isBefore(m.createdAt) ?? true)) m.reqId ?? m.id,
          };
    final newest = shown.reversed.take(count).toList();
    final older = shown.reversed.skip(count).toList();
    _newestIds = [for (final m in newest) m.reqId ?? m.id];
    final fitted = _cap != null && (_away || listEquals(_capFor, _newestIds));
    WidgetsBinding.instance.addPostFrameCallback((_) => _fit());
    if (shown.isNotEmpty && !_opened) {
      _opened = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (MediaQuery.disableAnimationsOf(context)) {
          _open.value = 1;
        } else {
          _open.forward();
        }
      });
    }
    final writable = chat.available && room.canWrite;
    final small = theme.textTheme.bodyMedium;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.5;
    Widget row(ChatMessage m, int i) => AnimatedBuilder(
      animation: _open,
      builder: (context, child) => i == 0
          ? Transform.translate(offset: Offset(0, -24 * (1 - Curves.easeOutCubic.transform(_open.value))), child: child)
          : Opacity(opacity: const Interval(0.3, 1).transform(_open.value), child: child),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: fresh.contains(m.reqId ?? m.id) ? 0 : 1, end: 1),
        duration: chatMotion(context, const Duration(milliseconds: 180)),
        curve: Curves.easeOut,
        builder: (context, t, child) => Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, 6 * (1 - t)), child: child),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: ChatTextScale(scale: prefs.listTextScale, child: _body(chat, m, small)),
        ),
      ),
    );
    final block = Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 2, child: loading && !failed ? const LinearProgressIndicator(minHeight: 2) : null),
          if (failed)
            Padding(
              padding: const EdgeInsets.fromLTRB(_indent, 0, 8, 0),
              child: ChatLoadFailed(name: name, onRetry: () => chat.retryRoom(room.id), compact: true),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(_indent, 0, 16, 0),
            child: shown.isEmpty
                ? failed
                      ? null
                      : Text(
                          loading ? 'Loading messages' : 'No messages yet',
                          style: small?.copyWith(color: scheme.onSurfaceVariant),
                        )
                : Stack(
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: fitted ? _cap!.clamp(0, maxHeight) : maxHeight),
                        child: CustomScrollView(
                          controller: _scroll,
                          reverse: true,
                          shrinkWrap: true,
                          slivers: [
                            SliverToBoxAdapter(
                              child: NotificationListener<SizeChangedLayoutNotification>(
                                onNotification: (_) {
                                  WidgetsBinding.instance.addPostFrameCallback((_) => _fit());
                                  return true;
                                },
                                child: SizeChangedLayoutNotifier(
                                  child: Column(
                                    key: _newestKey,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      for (final (i, m) in newest.indexed.toList().reversed)
                                        KeyedSubtree(key: ValueKey(m.reqId ?? m.id), child: row(m, i)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (fitted)
                              SliverList.builder(
                                itemCount: older.length,
                                itemBuilder: (context, i) => row(older[i], count + i),
                              ),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: ChatPopIn(
                          visible: _away,
                          child: IconButton.filledTonal(
                            tooltip: 'Go to the latest messages',
                            onPressed: _toNewest,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded),
                            iconSize: 20,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints.tightFor(width: 48, height: 48),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          if (writable)
            Padding(
              padding: const EdgeInsets.fromLTRB(_indent - 8, 6, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _text,
                      minLines: 1,
                      maxLines: 3,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.send,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _send(),
                      scrollPadding: const EdgeInsets.fromLTRB(20, 20, 20, 150),
                      decoration: InputDecoration(
                        hintText: 'Message $name',
                        hintMaxLines: 1,
                        filled: true,
                        fillColor: scheme.surfaceContainerLowest,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filled(
                    tooltip: 'Send',
                    onPressed: _hasText ? _send : null,
                    icon: const Icon(Icons.send_rounded),
                    iconSize: 20,
                    constraints: const BoxConstraints.tightFor(width: 48, height: 48),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
    // Another room may have taken the open
    return Listener(
      onPointerDown: (_) {
        if (loading && !failed && !chat.opening(room.id)) chat.peekRoom(room.id);
      },
      child: block,
    );
  }
}
