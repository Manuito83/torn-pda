import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_quote.dart';
import 'package:torn_pda/models/chat/chat_saved.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';
import 'package:torn_pda/widgets/chat/chat_link_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

typedef ChatOpenAt = Future<void> Function(String roomId, {String? messageId, DateTime? at});

/// Saved messages until something is typed
class ChatSearchPage extends StatefulWidget {
  const ChatSearchPage({super.key, required this.onOpen, required this.onPlayer, this.saved = false});

  final ChatOpenAt onOpen;
  final ValueChanged<ChatUser> onPlayer;

  /// Saved list first, no keyboard
  final bool saved;

  @override
  State<ChatSearchPage> createState() => _ChatSearchPageState();
}

class _ChatSearchPageState extends State<ChatSearchPage> {
  static const int _collapsed = 3;

  final TextEditingController _text = TextEditingController();
  final Set<String> _expanded = {};
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _text.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() {
        _query = value.trim().toLowerCase();
        _expanded.clear();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatController>();
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _text,
          autofocus: !widget.saved,
          textInputAction: TextInputAction.search,
          onChanged: _onChanged,
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
          decoration: const InputDecoration(
            hintText: 'Search players and messages',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
        ),
        actions: [
          if (_text.text.isNotEmpty)
            IconButton(
              tooltip: 'Clear',
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                _text.clear();
                _onChanged('');
              },
            ),
        ],
      ),
      body: _query.length < 2 ? _saved(chat) : _results(chat),
    );
  }

  Widget _results(ChatController chat) {
    final players = chat.searchPlayers(_query);
    final groups = chat.searchMessages(_query);
    if (players.isEmpty && groups.isEmpty) {
      return const ChatStateMessage(
        icon: Icons.search_off_rounded,
        title: 'Nothing found',
        subtitle: 'Only players and messages already loaded in the app are searched',
      );
    }
    if (groups.isEmpty) return _players(players);
    if (players.isEmpty) return _messages(groups);
    final hits = groups.fold(0, (sum, g) => sum + g.$2.length);
    final scheme = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: scheme.onSurface,
            unselectedLabelColor: scheme.onSurfaceVariant,
            indicatorColor: scheme.primary,
            tabs: [
              Tab(text: 'Players (${players.length})'),
              Tab(text: 'Messages ($hits)'),
            ],
          ),
          Expanded(child: TabBarView(children: [_players(players), _messages(groups)])),
        ],
      ),
    );
  }

  Widget _players(List<(ChatUser, ChatRoom)> players) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        for (final (user, room) in players)
          ListTile(
            leading: room.isDm ? ChatRoomAvatar(room: room, size: 40) : ChatAvatar(user: user, size: 40),
            title: Text(user.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(room.isDm ? 'Private chat' : 'Seen in ${room.name}', maxLines: 1),
            trailing: IconButton(
              tooltip: 'Player actions',
              icon: const Icon(Icons.more_vert_rounded),
              onPressed: () => showChatPlayerActions(context, user),
            ),
            onTap: () => widget.onPlayer(user),
          ),
      ],
    );
  }

  Widget _messages(List<(ChatRoom, List<ChatMessage>)> groups) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        for (final (room, hits) in groups) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Row(
              children: [
                ChatRoomAvatar(room: room, size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    room.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Text('${hits.length}', style: theme.textTheme.labelMedium),
              ],
            ),
          ),
          for (final m in _expanded.contains(room.id) ? hits : hits.take(_collapsed))
            _ChatFoundTile(
              title: m.isSystem ? room.name : m.sender.name,
              text: m.content,
              term: _query,
              at: m.createdAt,
              onTap: () => widget.onOpen(room.id, messageId: m.id),
            ),
          if (hits.length > _collapsed && !_expanded.contains(room.id))
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 56),
                child: TextButton(
                  onPressed: () => setState(() => _expanded.add(room.id)),
                  child: Text('Show ${hits.length - _collapsed} more'),
                ),
              ),
            ),
          const Divider(height: 1),
        ],
      ],
    );
  }

  Widget _saved(ChatController chat) {
    return ListenableBuilder(
      listenable: NativeChat.prefs,
      builder: (context, _) {
        final saved = NativeChat.prefs.savedMessages;
        if (saved.isEmpty) {
          return const ChatStateMessage(
            icon: Icons.bookmark_border_rounded,
            title: 'No saved messages',
            subtitle: 'Long press a message and tap the bookmark to keep it here',
          );
        }
        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text('Saved messages', style: Theme.of(context).textTheme.titleSmall),
            ),
            for (final s in saved) _savedTile(chat, s),
          ],
        );
      },
    );
  }

  Widget _savedTile(ChatController chat, ChatSaved s) {
    final room = chat.roomById(s.roomId);
    return _ChatFoundTile(
      leading: ChatRoomAvatar(room: room, size: 36),
      title: room.isDm || s.author == s.roomName ? s.author : '${s.author} in ${s.roomName}',
      text: s.excerpt,
      at: s.createdAt,
      onTap: () => widget.onOpen(s.roomId, messageId: s.messageId, at: s.createdAt),
      trailing: IconButton(
        tooltip: 'Remove from saved',
        icon: const Icon(Icons.bookmark_remove_outlined),
        onPressed: () => NativeChat.prefs.removeSaved(s.messageId),
      ),
    );
  }
}

class _ChatFoundTile extends StatelessWidget {
  const _ChatFoundTile({
    required this.title,
    required this.text,
    required this.at,
    required this.onTap,
    this.term,
    this.leading,
    this.trailing,
  });

  final String title;
  final String text;
  final DateTime at;
  final VoidCallback onTap;
  final String? term;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final snippet = chatSnippet(text, term);
    return ListTile(
      contentPadding: EdgeInsets.only(left: leading == null ? 56 : 16, right: trailing == null ? 16 : 4),
      leading: leading,
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Text(NativeChat.prefs.stamp(at), style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ),
      subtitle: Text.rich(
        TextSpan(
          children: [
            for (final (part, hit) in snippet)
              TextSpan(
                text: part,
                style: hit
                    ? TextStyle(
                        backgroundColor: scheme.tertiaryContainer,
                        color: scheme.onTertiaryContainer,
                        fontWeight: FontWeight.w700,
                      )
                    : null,
              ),
          ],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

/// True where it matches [term]
List<(String, bool)> chatSnippet(String content, String? term) {
  final flat = (ChatQuote.parse(content)?.body ?? content).replaceAll(RegExp(r'\s+'), ' ').trim();
  if (term == null || term.isEmpty) return [(flat, false)];
  final lower = flat.toLowerCase();
  if (lower.length != flat.length) return [(flat, false)];
  final first = lower.indexOf(term);
  final start = first > 30 ? first - 30 : 0;
  final parts = <(String, bool)>[if (start > 0) ('…', false)];
  var i = start;
  while (i < flat.length) {
    final at = lower.indexOf(term, i);
    if (at < 0) {
      parts.add((flat.substring(i), false));
      break;
    }
    if (at > i) parts.add((flat.substring(i, at), false));
    parts.add((flat.substring(at, at + term.length), true));
    i = at + term.length;
  }
  return parts;
}
