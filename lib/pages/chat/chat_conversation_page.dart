import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:torn_pda/models/chat/chat_faction_events.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_player_color.dart';
import 'package:torn_pda/models/chat/chat_alerts.dart';
import 'package:torn_pda/models/chat/chat_quote.dart';
import 'package:torn_pda/models/chat/chat_share.dart';
import 'package:torn_pda/providers/chat/chat_api.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';
import 'package:torn_pda/providers/chat/chat_faction_ops.dart';
import 'package:torn_pda/widgets/chat/chat_toast.dart';
import 'package:torn_pda/widgets/chat/chat_alerts_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_away_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_color_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_faction_events_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_faction_ops_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_faction_roster_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_filter_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_compose_tools.dart';
import 'package:torn_pda/widgets/chat/chat_link_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_message_actions.dart';
import 'package:torn_pda/widgets/chat/chat_next_unread.dart';
import 'package:torn_pda/widgets/chat/chat_note_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_player_card_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_reminder_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_send_check_dialog.dart';
import 'package:torn_pda/widgets/chat/chat_share_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_theme.dart';
import 'package:torn_pda/widgets/chat/chat_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

class ChatConversationPage extends StatefulWidget {
  const ChatConversationPage({super.key, required this.roomId, this.focusMessageId, this.focusAt});

  final String roomId;

  final String? focusMessageId;
  final DateTime? focusAt;

  @override
  State<ChatConversationPage> createState() => _ChatConversationPageState();
}

class _ChatConversationPageState extends State<ChatConversationPage> {
  static const double _bottomSlack = 80;
  static const Duration _groupGap = Duration(minutes: 5);
  static const int _maxJumpPages = 8;

  late final ChatMinimized? _resume = NativeChat.takeResume(widget.roomId);
  late final ScrollController _scroll = ScrollController(initialScrollOffset: _resume?.offset ?? 0);
  late final ChatController _chat;
  late final StreamSubscription<ChatRoom> _gone;

  final GlobalKey _listKey = GlobalKey();
  final GlobalKey _unreadKey = GlobalKey();
  final GlobalKey _awayKey = GlobalKey();
  final GlobalKey _matchKey = GlobalKey();
  final GlobalKey _focusKey = GlobalKey();
  final TextEditingController _searchText = TextEditingController();

  late String? _frozenAtId = _resume?.frozenAtId;
  late bool _showJump = (_resume?.offset ?? 0) > _bottomSlack;
  bool _unreadSeen = false;
  bool _awaySeen = false;
  bool _showAllFiltered = false;
  bool _searching = false;
  String? _matchId;
  Timer? _searchDebounce;
  int _revealRun = 0;
  ChatMessage? _replyTo;
  String? _emojiFor;
  late String? _pendingFocus = widget.focusMessageId;
  String? _focusId;
  Timer? _focusFade;
  Set<String>? _known;
  DateTime? _since;
  Set<String> _fresh = const {};

  final Set<String> _selected = {};
  late bool _hasNote = _noteShown();
  var _people = NativeChat.prefs.people;

  @override
  void initState() {
    super.initState();
    _chat = context.read<ChatController>();
    _scroll.addListener(_onScroll);
    NativeChat.translator.addListener(_onTranslation);
    NativeChat.prefs.addListener(_onPrefs);
    NativeChat.shownPages.add(_snapshot);
    _gone = _chat.goneStream.listen(_onGone);
    WidgetsBinding.instance.addPostFrameCallback((_) => _chat.openConversation(widget.roomId));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chat.setCovered(widget.roomId, !TickerMode.valuesOf(context).enabled);
  }

  @override
  void dispose() {
    _gone.cancel();
    NativeChat.shownPages.remove(_snapshot);
    NativeChat.translator.removeListener(_onTranslation);
    NativeChat.prefs.removeListener(_onPrefs);
    _searchDebounce?.cancel();
    _focusFade?.cancel();
    _searchText.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onGone(ChatRoom room) {
    final route = ModalRoute.of(context);
    if (room.id != widget.roomId || route == null || !route.isActive) return;
    Navigator.of(context).removeRoute(route);
    _chat.closeConversation(room.id);
  }

  void _nextUnread() {
    final next = _chat.unreadQueue.firstOrNull;
    if (next == null) return;
    final chat = _chat;
    Navigator.of(context)
        .pushReplacement(
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider<ChatController>.value(
              value: chat,
              child: ChatTheme(child: ChatConversationPage(roomId: next.id)),
            ),
          ),
        )
        .then((_) => chat.closeConversation(next.id));
  }

  bool _noteShown() {
    final peer = ChatRoom.peerIdOf(widget.roomId);
    return peer != null && NativeChat.prefs.playerNoteFor(peer).isNotEmpty;
  }

  void _onPrefs() {
    final shown = _noteShown();
    if (shown != _hasNote && mounted) setState(() => _hasNote = shown);
    if (!identical(_people, NativeChat.prefs.people) && mounted) setState(() => _people = NativeChat.prefs.people);
  }

  List<ChatMessage> _shown() {
    final all = _listed();
    final id = _frozenAtId;
    if (id == null) return all;
    var cut = all.lastIndexWhere((m) => m.id == id);
    if (cut < 0) {
      // Anchor filtered out, cut by time
      final at = _chat.messagesFor(widget.roomId).where((m) => m.id == id).lastOrNull?.createdAt;
      if (at != null) cut = all.lastIndexWhere((m) => !m.createdAt.isAfter(at));
    }
    return cut < 0 ? all : all.sublist(0, cut + 1);
  }

  List<ChatMessage> _listed() =>
      _showAllFiltered ? _chat.visibleMessagesFor(widget.roomId) : _chat.filteredMessagesFor(widget.roomId);

  String get _term => _searching ? _searchText.text.trim().toLowerCase() : '';

  /// Newest first
  List<String> _matchIds() {
    final term = _term;
    if (term.length < 2) return const [];
    return [
      for (final m in _shown().reversed)
        if (ChatController.matchesText(m, term)) m.id,
    ];
  }

  void _toggleSelected(ChatMessage m) {
    HapticFeedback.selectionClick();
    setState(() {
      _emojiFor = null;
      _selected.contains(m.id) ? _selected.remove(m.id) : _selected.add(m.id);
    });
  }

  void _send(String text, ChatMessage? reply) {
    _chat.send(reply == null ? text : ChatQuote.reply(reply, text), to: widget.roomId);
    _jumpToBottom();
  }

  void _replyEmoji(ChatMessage m, String emoji) {
    setState(_selected.clear);
    final room = _chat.roomById(widget.roomId);
    sendChatChecked(context, emoji, roomId: room.id, roomName: room.name, onSend: (text) => _send(text, m));
  }

  List<ChatMessage> _selectedMessages() =>
      _chat.visibleMessagesFor(widget.roomId).where((m) => _selected.contains(m.id)).toList();

  void _snack(String text) {
    chatToast(text, seconds: 1);
  }

  void _saveSelected(bool save) {
    final name = _chat.roomById(widget.roomId).name;
    for (final m in _selectedMessages()) {
      NativeChat.prefs.setSaved(m, name, save);
    }
    setState(_selected.clear);
    _snack(save ? 'Saved' : 'Removed from saved');
  }

  void _pinSelected() {
    final m = _selectedMessages().firstOrNull;
    setState(_selected.clear);
    if (m == null) return;
    final unpin = NativeChat.prefs.isPinnedMessage(widget.roomId, m.id);
    NativeChat.prefs.setPinnedMessage(widget.roomId, unpin ? null : m, _chat.roomById(widget.roomId).name);
    _snack(unpin ? 'Unpinned' : 'Pinned to the top of this chat');
  }

  void _jumpToQuote(ChatMessage reply) {
    final source = ChatQuote.source(_chat.visibleMessagesFor(widget.roomId), reply);
    source == null ? _snack('Message not loaded') : _jumpTo(source.id);
  }

  Future<void> _jumpTo(String id, {DateTime? at}) async {
    final roomId = widget.roomId;
    bool shown() => _chat.visibleMessagesFor(roomId).any((m) => m.id == id);
    for (var page = 0; page < _maxJumpPages && at != null && !shown() && _chat.hasOlder(roomId); page++) {
      final oldest = _chat.messagesFor(roomId).firstOrNull?.createdAt;
      if (oldest == null || oldest.isBefore(at)) break;
      await _chat.loadOlder(roomId);
      for (var i = 0; i < 40 && mounted && _chat.messagesFor(roomId).firstOrNull?.createdAt == oldest; i++) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      if (!mounted) return;
    }
    if (!mounted) return;
    if (!shown()) return _snack('Message not loaded');
    _focusFade?.cancel();
    setState(() => _focusId = id);
    await _reveal(_focusKey, older: true);
    _focusFade = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _focusId = null);
    });
  }

  void _onTranslation() {
    if (mounted) setState(() {});
  }

  void _translate(ChatMessage m) {
    final translator = NativeChat.translator;
    final target = NativeChat.translateTarget;
    final current = translator.shownFor(m.id, target);
    if (current == null || current.failed) {
      translator.show(
        m.id,
        ChatQuote.parse(m.content)?.body ?? ChatQuote.forwarded(m.content)?.body ?? m.content,
        target,
      );
    } else if (!current.isLoading) {
      translator.hide(m.id);
    }
  }

  void _translateSelected() {
    final m = _selectedMessages().firstOrNull;
    setState(_selected.clear);
    if (m != null) _translate(m);
  }

  void _copySelected() {
    final messages = _selectedMessages();
    final text = messages.length == 1
        ? messages.first.content
        : messages.map((m) => m.isSystem ? m.content : '${m.sender.name}: ${m.content}').join('\n');
    Clipboard.setData(ClipboardData(text: text));
    setState(_selected.clear);
    _snack('Copied');
  }

  Future<void> _forwardSelected() async {
    final messages = _selectedMessages();
    if (messages.isEmpty) return;
    // Otherwise the keyboard reopens on close
    FocusManager.instance.primaryFocus?.unfocus();
    final target = await showChatRoomPicker(
      context,
      _chat,
      messages.length == 1 ? 'Forward message to' : 'Forward ${messages.length} messages to',
    );
    if (target == null || !mounted) return;
    final text = ChatQuote.forward(_chat.roomById(widget.roomId).name, messages);
    if (!await checkChatSend(context, text, roomId: target.id, roomName: target.name) || !mounted) return;
    _chat.send(text, to: target.id);
    setState(_selected.clear);
    chatToast(
      'Forwarded to ${target.name}',
      seconds: 4,
      action: target.id == widget.roomId ? null : 'Open',
      onAction: () {
        final navigator = NativeChat.navigatorKey?.currentState;
        if (navigator != null) NativeChat.open(navigator, roomId: target.id);
      },
    );
  }

  Future<void> _shareSelected() async {
    final messages = _selectedMessages();
    setState(_selected.clear);
    if (messages.isEmpty) return;
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: ChatShared.outgoing(messages),
        subject: _chat.roomById(widget.roomId).name,
        sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  ChatMinimized _snapshot() {
    final offset = _scroll.hasClients ? _scroll.offset : 0.0;
    return ChatMinimized(widget.roomId, offset: offset, frozenAtId: offset > _bottomSlack ? _frozenAtId : null);
  }

  void _minimize() {
    FocusManager.instance.primaryFocus?.unfocus();
    final page = _snapshot();
    NativeChat.minimize(page.roomId, offset: page.offset, frozenAtId: page.frozenAtId);
  }

  void _popOut() {
    FocusManager.instance.primaryFocus?.unfocus();
    NativeChat.popOut(widget.roomId);
  }

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      _matchId = null;
      _searchText.clear();
    });
  }

  void _onQuery(String _) {
    setState(() => _matchId = null);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      final ids = _matchIds();
      if (!mounted || ids.isEmpty) return;
      setState(() => _matchId = ids.first);
      _reveal(_matchKey, older: true);
    });
  }

  void _stepMatch({required bool older}) {
    final ids = _matchIds();
    if (ids.isEmpty) return;
    final current = ids.indexOf(_matchId ?? '');
    final next = current < 0 ? 0 : current + (older ? 1 : -1);
    if (next < 0) return;
    if (next >= ids.length) {
      if (!_chat.hasOlder(widget.roomId)) return;
      _chat.loadOlder(widget.roomId);
      chatToast('Loading older messages', seconds: 1);
      return;
    }
    setState(() => _matchId = ids[next]);
    _reveal(_matchKey, older: older);
  }

  Future<void> _reveal(GlobalKey key, {required bool older}) async {
    final run = ++_revealRun;
    var up = older;
    var turns = 0;
    for (var i = 0; i < 300 && mounted && run == _revealRun; i++) {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || run != _revealRun) return;
      final target = key.currentContext;
      if (target != null) {
        await Scrollable.ensureVisible(
          target,
          alignment: 0.5,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
        _checkUnreadSeen();
        return;
      }
      if (!_scroll.hasClients) return;
      final position = _scroll.position;
      final next = (position.pixels + (up ? 1 : -1) * position.viewportDimension).clamp(0.0, position.maxScrollExtent);
      if (next == position.pixels) {
        if (++turns > 1) return;
        up = !up;
        continue;
      }
      _scroll.jumpTo(next);
    }
  }

  bool _inView(GlobalKey key) {
    final item = key.currentContext?.findRenderObject() as RenderBox?;
    final list = _listKey.currentContext?.findRenderObject() as RenderBox?;
    if (item == null || list == null || !item.attached || !list.attached) return false;
    final top = list.localToGlobal(Offset.zero).dy;
    final y = item.localToGlobal(Offset.zero).dy;
    return y >= top - item.size.height && y <= top + list.size.height;
  }

  void _checkUnreadSeen() {
    if (_unreadSeen || !mounted) return;
    if (_inView(_unreadKey)) setState(() => _unreadSeen = true);
  }

  void _checkAwaySeen() {
    if (!_awaySeen) _awaySeen = _inView(_awayKey);
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    _checkUnreadSeen();
    _checkAwaySeen();
    final position = _scroll.position;
    final atBottom = position.pixels <= _bottomSlack;
    if (atBottom && _awaySeen) _chat.dismissAway(widget.roomId);
    if (atBottom && (_frozenAtId != null || _showJump)) {
      setState(() {
        _frozenAtId = null;
        _showJump = false;
      });
    } else if (!atBottom && _frozenAtId == null) {
      final list = _listed();
      setState(() {
        _frozenAtId = list.isEmpty ? null : list.last.id;
        _showJump = true;
      });
    }
    if (position.pixels >= position.maxScrollExtent - 400) _chat.loadOlder(widget.roomId);
  }

  void _jumpToBottom() {
    setState(() {
      _frozenAtId = null;
      _showJump = false;
    });
    if (!_scroll.hasClients) return;
    if (_scroll.offset > 3000) {
      _scroll.jumpTo(0);
    } else {
      _scroll.animateTo(0, duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
    }
  }

  // Other rooms do not rebuild this one
  Object _watched(ChatController c) {
    final room = c.roomById(widget.roomId);
    return (
      c.visibleMessagesFor(widget.roomId),
      c.filteredMessagesFor(widget.roomId),
      c.firstUnreadId(widget.roomId),
      c.awayFor(widget.roomId),
      c.typingIn(widget.roomId),
      c.connection,
      c.ready,
      c.available,
      c.loadingOlder,
      c.hasOlder(widget.roomId),
      c.isLoaded(widget.roomId),
      c.myUserId,
      c.presenceRevision,
      c.searchQuery,
      c.searchResults,
      (room.name, room.canWrite, room.isDm, room.emblemUrl, room.icon),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.select<ChatController, Object>(_watched);
    final chat = _chat;
    final room = chat.roomById(widget.roomId);

    final matchIds = _matchIds();
    final matchIndex = matchIds.indexOf(_matchId ?? '');
    final selecting = _selected.isNotEmpty;
    final allSaved = selecting && _selected.every(NativeChat.prefs.isSaved);
    final toolbar = (MediaQuery.textScalerOf(context).scale(40) + 16).clamp(kToolbarHeight, double.infinity).toDouble();
    final theme = Theme.of(context);
    final barText =
        theme.appBarTheme.foregroundColor ??
        (theme.useMaterial3 || theme.brightness == Brightness.dark
            ? theme.colorScheme.onSurface
            : theme.colorScheme.onPrimary);
    final lineStyle = theme.textTheme.bodySmall?.copyWith(fontSize: 12, letterSpacing: 0.1);
    final page = Scaffold(
      appBar: selecting
          ? AppBar(
              toolbarHeight: toolbar,
              leading: IconButton(
                tooltip: 'Cancel selection',
                icon: const Icon(Icons.close_rounded),
                onPressed: () => setState(_selected.clear),
              ),
              title: Text('${_selected.length} selected'),
              actions: _selected.length == 1
                  ? null
                  : [
                      IconButton(tooltip: 'Copy', icon: const Icon(Icons.copy_rounded), onPressed: _copySelected),
                      IconButton(
                        tooltip: 'Forward',
                        icon: const Icon(Icons.forward_rounded),
                        onPressed: chat.available ? _forwardSelected : null,
                      ),
                      PopupMenuButton<VoidCallback>(
                        tooltip: 'More actions',
                        onSelected: (action) => action(),
                        itemBuilder: (_) {
                          PopupMenuItem<VoidCallback> item(IconData icon, String label, VoidCallback action) =>
                              PopupMenuItem(
                                value: action,
                                child: Row(children: [Icon(icon), const SizedBox(width: 12), Text(label)]),
                              );
                          return [
                            item(
                              allSaved ? Icons.bookmark_remove_rounded : Icons.bookmark_add_outlined,
                              allSaved ? 'Remove from saved' : 'Save',
                              () => _saveSelected(!allSaved),
                            ),
                            item(Icons.share_rounded, 'Share', _shareSelected),
                          ];
                        },
                      ),
                    ],
            )
          : _searching
          ? AppBar(
              toolbarHeight: toolbar,
              titleSpacing: 0,
              leading: IconButton(
                tooltip: 'Close search',
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _toggleSearch,
              ),
              title: TextField(
                controller: _searchText,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: _onQuery,
                onSubmitted: (_) => _stepMatch(older: true),
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  hintText: 'Search in ${room.name}',
                  hintStyle: const TextStyle(color: Colors.white70),
                  suffixStyle: const TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  suffixText: _term.length < 2
                      ? null
                      : matchIds.isEmpty
                      ? 'None'
                      : '${matchIndex < 0 ? 0 : matchIndex + 1}/${matchIds.length}'
                            '${chat.hasOlder(room.id) ? '+' : ''}',
                ),
              ),
              actions: [
                IconButton(
                  tooltip: 'Older match',
                  icon: const Icon(Icons.keyboard_arrow_up_rounded),
                  onPressed: matchIds.isEmpty ? null : () => _stepMatch(older: true),
                ),
                IconButton(
                  tooltip: 'Newer match',
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  onPressed: matchIndex <= 0 ? null : () => _stepMatch(older: false),
                ),
              ],
            )
          : AppBar(
              backgroundColor: ChatPlayerColor.tinted(
                theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
                barText,
              ),
              foregroundColor: barText,
              toolbarHeight: room.isDm ? toolbar + MediaQuery.textScalerOf(context).scale(_hasNote ? 34 : 18) : toolbar,
              titleSpacing: 0,
              title: InkWell(
                onTap: room.isDm && ChatRoom.peerIdOf(room.id) != null
                    ? () => showChatPlayerActions(
                        context,
                        room.peer ?? ChatUser(id: ChatRoom.peerIdOf(room.id)!, name: room.name),
                      )
                    : null,
                child: Row(
                  children: [
                    ChatRoomAvatar(room: room, size: 38),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  room.isDm && ChatRoom.peerIdOf(room.id) != null
                                      ? NativeChat.prefs.displayName(ChatRoom.peerIdOf(room.id)!, room.name)
                                      : room.name,
                                  semanticsLabel: room.isDm ? '${room.name}, player details' : null,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                ),
                              ),
                              ListenableBuilder(
                                listenable: NativeChat.prefs,
                                builder: (context, _) {
                                  final prefs = NativeChat.prefs;
                                  final until = prefs.mutedUntilOf(room.id);
                                  if (until == null &&
                                      !prefs.isMuted(room.id) &&
                                      prefs.alertLevel(room.id) != ChatAlertLevel.none) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 6),
                                    child: Icon(
                                      until != null ? Icons.snooze_rounded : Icons.notifications_off_rounded,
                                      size: 16,
                                      semanticLabel: until == null
                                          ? 'Muted'
                                          : 'Muted until ${chatMuteUntilText(until)}',
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          if (room.isDm ||
                              chat.connection != ChatConnection.connected ||
                              room.id == ChatFactionOps.roomId)
                            Row(
                              children: [
                                Flexible(
                                  child: ChatConnectionLine(
                                    state: chat.connection,
                                    presence: chat.presenceOf(ChatRoom.peerIdOf(room.id)),
                                    lastSeen: chat.lastSeenOf(ChatRoom.peerIdOf(room.id)),
                                    style: lineStyle,
                                    short: true,
                                  ),
                                ),
                                if (room.id == ChatFactionOps.roomId) ChatChainLine(prefs: NativeChat.prefs),
                              ],
                            ),
                          if (room.isDm && ChatRoom.peerIdOf(room.id) != null)
                            ChatPlayerCardView(
                              id: ChatRoom.peerIdOf(room.id)!,
                              compact: true,
                              lastAction: chat.presenceOf(ChatRoom.peerIdOf(room.id)) == null,
                            ),
                          if (room.isDm && ChatRoom.peerIdOf(room.id) != null)
                            ChatNoteLine(id: ChatRoom.peerIdOf(room.id)!, name: room.name),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                ChatNextUnreadButton(count: chat.unreadQueue.length, onNext: _nextUnread),
                if (NativeChat.prefs.inAppEnabled) ...[
                  IconButton(
                    tooltip: 'Minimize to the bubble',
                    icon: const Icon(Icons.minimize_rounded),
                    onPressed: _minimize,
                  ),
                  IconButton(
                    tooltip: 'Open in a small window',
                    icon: const Icon(Icons.picture_in_picture_alt_rounded),
                    onPressed: _popOut,
                  ),
                ],
                PopupMenuButton<VoidCallback>(
                  tooltip: 'More',
                  onSelected: (action) => action(),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      enabled: chat.isLoaded(room.id),
                      value: _toggleSearch,
                      child: const Text('Search in this chat'),
                    ),
                    if (room.isDm && ChatRoom.peerIdOf(room.id) != null)
                      PopupMenuItem(
                        value: () => showChatPlayerActions(
                          context,
                          room.peer ?? ChatUser(id: ChatRoom.peerIdOf(room.id)!, name: room.name),
                        ),
                        child: const Text('Player details'),
                      ),
                    if (!room.isDm)
                      PopupMenuItem(
                        value: () => showChatRoomAlerts(context, room),
                        child: Text(
                          NativeChat.prefs.mutedUntilOf(room.id) == null
                              ? 'Alerts and mute'
                              : 'Muted until ${chatMuteUntilText(NativeChat.prefs.mutedUntilOf(room.id)!)}',
                        ),
                      ),
                    if (chat.canMarkUnread(room.id))
                      PopupMenuItem(
                        value: () {
                          chat.markUnread(room.id);
                          Navigator.maybePop(context);
                        },
                        child: const Text('Mark as unread'),
                      ),
                    if (!room.isDm)
                      PopupMenuItem(value: () => showChatRoomFilter(context, room), child: const Text('Filter')),
                  ],
                ),
              ],
            ),
      body: Column(
        children: [
          ChatStartingBar(starting: chat.starting, phrases: chat.isLoaded(widget.roomId)),
          if (room.id == ChatFactionOps.roomId) ChatWarStrip(prefs: NativeChat.prefs),
          if (room.id == ChatFactionOps.roomId) ChatFactionRosterLines(prefs: NativeChat.prefs),
          if (!room.isDm && NativeChat.prefs.filterOf(room.id).isActive)
            ChatFilterStrip(
              hidden: chat.visibleMessagesFor(room.id).length - chat.filteredMessagesFor(room.id).length,
              revealed: _showAllFiltered,
              onToggle: () => setState(() => _showAllFiltered = !_showAllFiltered),
              onEdit: () => showChatRoomFilter(context, room),
            ),
          ListenableBuilder(
            listenable: NativeChat.prefs,
            builder: (context, _) {
              final pin = NativeChat.prefs.pinnedIn(room.id);
              if (pin == null) return const SizedBox.shrink();
              return ChatPinnedBar(
                pin: pin,
                onTap: () => _jumpTo(pin.messageId, at: pin.createdAt),
                onUnpin: () => NativeChat.prefs.setPinnedMessage(room.id, null, room.name),
              );
            },
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: NativeChat.prefs.colors,
              builder: (context, _, _) => ColoredBox(
                color: chatPalette(context).background,
                child: ChatNextUnreadEdge(
                  enabled: chat.unreadQueue.isNotEmpty,
                  onNext: _nextUnread,
                  child: ChatArrivals(chat: chat, roomId: room.id, child: _body(chat, room)),
                ),
              ),
            ),
          ),
          ChatTypingBar(users: chat.typingIn(room.id)),
          ValueListenableBuilder(
            valueListenable: NativeChat.tornTabMissing,
            builder: (context, paused, _) => paused
                ? const ChatPausedBand()
                : ChatComposer(
                    key: ValueKey(room.id),
                    roomName: room.name,
                    enabled: chat.available && room.canWrite,
                    chat: chat,
                    roomId: room.id,
                    onSend: (text) {
                      _send(text, _replyTo);
                      if (_replyTo != null) setState(() => _replyTo = null);
                    },
                    draft: NativeChat.prefs.draftFor(room.id),
                    onDraft: (text) => NativeChat.prefs.setDraft(room.id, text),
                    replyTo: _replyTo,
                    onCancelReply: () => setState(() => _replyTo = null),
                  ),
          ),
        ],
      ),
    );
    return PopScope(
      canPop: !_searching && !selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        selecting ? setState(_selected.clear) : _toggleSearch();
      },
      child: page,
    );
  }

  Widget _body(ChatController chat, ChatRoom room) {
    final roomId = widget.roomId;
    if (!chat.available && !chat.loggedOut) {
      return ChatStateMessage(
        icon: Icons.portable_wifi_off_rounded,
        title: 'In-app chat is off',
        subtitle: 'Turn it on to read Torn chat here',
        action: FilledButton.tonal(
          onPressed: () => setState(() => NativeChat.setEnabled(true)),
          child: const Text('Turn on'),
        ),
      );
    }
    if (chat.sessionIssue) return ChatSessionMessage(state: chat.connection);
    if (!chat.isLoaded(roomId)) {
      final failed = chat.connection == ChatConnection.error;
      return ChatStateMessage(
        icon: Icons.cloud_off_rounded,
        busy: !failed,
        phrases: chat.starting,
        title: failed ? 'Could not reach the chat' : 'Loading ${room.name}',
        subtitle: failed ? null : (chat.ready ? 'Fetching recent messages' : 'Connecting to Torn'),
        action: failed ? FilledButton.tonal(onPressed: chat.retry, child: const Text('Try again')) : null,
      );
    }

    final cached = chat.messagesFor(roomId);
    final known = _known ??= {for (final m in cached) m.reqId ?? m.id};
    final last = cached.lastOrNull?.createdAt;
    final now = DateTime.now();
    _since ??= last != null && last.isAfter(now) ? last : now;
    _fresh = {
      for (final m in cached)
        if (known.add(m.reqId ?? m.id) && (_since?.isBefore(m.createdAt) ?? true)) m.reqId ?? m.id,
    };
    final all = _listed();
    if (all.isEmpty) {
      return const ChatStateMessage(
        icon: Icons.forum_outlined,
        title: 'No messages yet',
        subtitle: 'New messages show up here',
      );
    }

    final focus = _pendingFocus;
    if (focus != null) {
      _pendingFocus = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpTo(focus, at: widget.focusAt));
    }

    final shown = _shown();
    final waiting = all.length - shown.length;
    final term = _term.length < 2 ? null : _term;
    final firstUnread = chat.firstUnreadId(roomId);
    final unreadIndex = firstUnread == null ? -1 : all.indexWhere((m) => m.id == firstUnread);
    final unreadCount = unreadIndex < 0 ? 0 : all.skip(unreadIndex).where((m) => !m.isLocal).length;
    final unreadChip = unreadIndex >= 0 && !_unreadSeen;
    if (unreadChip) WidgetsBinding.instance.addPostFrameCallback((_) => _checkUnreadSeen());
    final away = chat.awayFor(roomId);
    if (away != null) WidgetsBinding.instance.addPostFrameCallback((_) => _checkAwaySeen());

    // Reversed list, built on demand
    final entries = <(_Row, int)>[];
    final at = <String, int>{};
    final folded = <int, int>{};
    for (var i = shown.length - 1; i >= 0; i--) {
      final last = i;
      while (i > 0 && isChatFactionEvent(shown[i]) && isChatFactionEvent(shown[i - 1])) {
        i--;
      }
      if (isChatFactionEvent(shown[i])) folded[i] = last;
      final m = shown[i];
      final older = i > 0 ? shown[i - 1] : null;
      at[m.id] = entries.length;
      entries.add((folded.containsKey(i) ? _Row.events : _Row.message, i));
      if (m.id == firstUnread) entries.add((_Row.unread, i));
      if (m.id == away?.anchorId) entries.add((_Row.away, i));
      if (older == null || !_sameDay(older.createdAt, m.createdAt)) {
        at['day-${m.id}'] = entries.length;
        entries.add((_Row.day, i));
      }
    }
    final saved = {for (final s in NativeChat.prefs.savedMessages) s.messageId};
    final hasTopRow = chat.loadingOlder || !chat.hasOlder(roomId);

    return Stack(
      key: _listKey,
      children: [
        ListView.builder(
          key: PageStorageKey(roomId),
          controller: _scroll,
          reverse: true,
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          itemCount: entries.length + (hasTopRow ? 1 : 0),
          findChildIndexCallback: (key) => key is ValueKey<String> ? at[key.value] : null,
          itemBuilder: (context, index) {
            if (index >= entries.length) return _TopRow(loading: chat.loadingOlder);
            final (row, i) = entries[index];
            final m = shown[i];
            return switch (row) {
              _Row.unread => ChatUnreadSeparator(key: _unreadKey),
              _Row.away => ChatAwayCard(key: _awayKey, away: away!, onJump: _jumpTo),
              _Row.day => ChatDaySeparator(key: ValueKey('day-${m.id}'), day: m.createdAt),
              _Row.events => ChatFactionEventsFold(key: ValueKey(m.id), events: shown.sublist(i, folded[i]! + 1)),
              _Row.message => _messageRow(chat, room, shown, i, term, firstUnread, saved),
            };
          },
        ),
        Positioned(
          top: 10,
          left: 0,
          right: 0,
          child: Center(
            child: AnimatedScale(
              scale: unreadChip ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutBack,
              child: FilledButton.tonalIcon(
                onPressed: () => _reveal(_unreadKey, older: true),
                icon: const Icon(Icons.keyboard_double_arrow_up_rounded, size: 18),
                label: Text(
                  '$unreadCount${unreadIndex == 0 && chat.hasOlder(roomId) ? '+' : ''} new '
                  '${unreadCount == 1 ? 'message' : 'messages'}',
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 12,
          bottom: 12,
          child: AnimatedScale(
            scale: _showJump ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutBack,
            child: waiting > 0
                ? FloatingActionButton.extended(
                    heroTag: null,
                    onPressed: _jumpToBottom,
                    icon: const Icon(Icons.keyboard_double_arrow_down_rounded),
                    label: Text(waiting == 1 ? '1 new message' : '$waiting new messages'),
                  )
                : FloatingActionButton.small(
                    heroTag: null,
                    tooltip: 'Go to the latest messages',
                    onPressed: _jumpToBottom,
                    child: const Icon(Icons.keyboard_arrow_down_rounded),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _messageRow(
    ChatController chat,
    ChatRoom room,
    List<ChatMessage> shown,
    int i,
    String? term,
    String? firstUnread,
    Set<String> saved,
  ) {
    final m = shown[i];
    final older = i > 0 ? shown[i - 1] : null;
    final newer = i < shown.length - 1 ? shown[i + 1] : null;
    final newDay = older == null || !_sameDay(older.createdAt, m.createdAt);
    final current = term != null && m.id == _matchId;
    final selectable = m.state == ChatMessageState.sent && !m.isLocal;
    final selected = _selected.contains(m.id);
    final selecting = _selected.isNotEmpty;
    final mine = chat.myUserId != null && m.sender.id == chat.myUserId;
    final writable = chat.available && room.canWrite;
    final prefs = NativeChat.prefs;
    final pinned = prefs.isPinnedMessage(room.id, m.id);
    final reply = selectable && !selecting && writable ? () => setState(() => _replyTo = m) : null;
    final swipeLeft = chatSwipeLeft(m, mine: mine);
    final bubble = ChatMessageBubble(
      key: ValueKey(m.id),
      message: m,
      isMine: mine,
      showSender: !room.isDm,
      highlighted: chat.highlightOf(m).on,
      highlightColor: chat.highlightOf(m).color,
      searchTerm: term != null && ChatController.matchesText(m, term) ? term : null,
      searchCurrent: current || m.id == _focusId,
      saved: saved.contains(m.id),
      onQuoteTap: () => _jumpToQuote(m),
      isFirstInGroup: newDay || m.id == firstUnread || !_sameGroup(older, m),
      isLastInGroup: newer == null || !_sameDay(m.createdAt, newer.createdAt) || !_sameGroup(m, newer),
      onLongPress: selectable ? () => _toggleSelected(m) : null,
      presence: ChatApi.hasRoster(room.id) ? chat.presenceOf(m.sender.id) : null,
      translation: NativeChat.translator.shownFor(m.id, NativeChat.translateTarget),
      onTranslationTap: () => _translate(m),
      onReply: reply,
      onSwipeLeft: swipeLeft,
      onForward: selectable && !selecting && chat.available
          ? () async {
              setState(() => _selected.add(m.id));
              await _forwardSelected();
              if (mounted) setState(_selected.clear);
            }
          : null,
      pinned: pinned,
      selected: selecting ? selected : null,
    );
    final single = selected && _selected.length == 1;
    ChatMessageAction action(String id, VoidCallback? onTap, {IconData? icon, String? label}) {
      final (defaultIcon, defaultLabel) = chatMessageActionLooks[id]!;
      return (id, icon ?? defaultIcon, label ?? defaultLabel, onTap);
    }

    final byId = !single
        ? const <String, ChatMessageAction>{}
        : <String, ChatMessageAction>{
            if (writable)
              'reply': action(
                'reply',
                () => setState(() {
                  _replyTo = m;
                  _selected.clear();
                }),
              ),
            'copy': action('copy', _copySelected),
            'forward': action('forward', chat.available ? _forwardSelected : null),
            if (writable) 'smiley': action('smiley', () => setState(() => _emojiFor = _emojiFor == m.id ? null : m.id)),
            'pin': action(
              'pin',
              _pinSelected,
              icon: pinned ? Icons.push_pin_rounded : null,
              label: pinned ? 'Unpin' : null,
            ),
            'save': action(
              'save',
              () => _saveSelected(!saved.contains(m.id)),
              icon: saved.contains(m.id) ? Icons.bookmark_remove_rounded : null,
              label: saved.contains(m.id) ? 'Remove from saved' : null,
            ),
            if (!m.isSystem)
              'translate': action(
                'translate',
                _translateSelected,
                label: NativeChat.translator.isShown(m.id) ? 'Hide translation' : null,
              ),
            'share': action('share', _shareSelected),
            'remind': action('remind', () {
              setState(_selected.clear);
              showChatReminderSheet(context, m, room.name);
            }),
          };
    final barActions = [
      for (final id in prefs.messageActionOrder)
        if (!prefs.messageActionHidden.contains(id)) ?byId[id],
    ];
    final actions = barActions.isEmpty
        ? null
        : ChatMessageActions(
            alignment: m.isSystem
                ? Alignment.center
                : (mine && !prefs.compactMode ? Alignment.centerRight : Alignment.centerLeft),
            padding: EdgeInsets.only(
              left: m.isSystem || mine || prefs.compactMode || room.isDm || !prefs.showAvatars ? 8 : 50,
              right: 12,
              bottom: 6,
            ),
            emojiOpen: _emojiFor == m.id,
            actions: barActions,
            emojis: _emojiFor == m.id && writable ? prefs.emojiFavorites : null,
            onEmoji: (emoji) => _replyEmoji(m, emoji),
            onMoreEmojis: () async {
              final emoji = await showModalBottomSheet<String>(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (sheet) => SafeArea(child: ChatEmojiEditor(onPick: (e) => Navigator.pop(sheet, e))),
              );
              if (emoji != null && mounted) _replyEmoji(m, emoji);
            },
          );
    final gesture = GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTap: !selecting || !selectable ? null : () => _toggleSelected(m),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: selected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.16) : Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ChatSwipeReply(onReply: reply, onSwipeLeft: swipeLeft, child: bubble),
            ?actions,
          ],
        ),
      ),
    );
    final row = TweenAnimationBuilder<double>(
      tween: Tween(begin: _fresh.contains(m.reqId ?? m.id) ? 0 : 1, end: 1),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 6 * (1 - t)), child: child),
      ),
      child: gesture,
    );
    if (current) return KeyedSubtree(key: _matchKey, child: row);
    if (m.id == _focusId) return KeyedSubtree(key: _focusKey, child: row);
    return KeyedSubtree(key: ValueKey(m.id), child: row);
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  bool _sameGroup(ChatMessage? a, ChatMessage b) {
    if (a == null || a.isSystem || b.isSystem || a.sender.id != b.sender.id) return false;
    return b.createdAt.difference(a.createdAt).abs() < _groupGap;
  }
}

enum _Row { message, events, unread, away, day }

class _TopRow extends StatelessWidget {
  const _TopRow({required this.loading});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: loading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
            : Text(
                'Start of the recent history',
                style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
      ),
    );
  }
}
