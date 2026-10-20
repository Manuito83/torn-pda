import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chat/chat_emoji.dart';
import 'package:torn_pda/models/chat/chat_format.dart';
import 'package:torn_pda/models/chat/chat_item_price.dart';
import 'package:torn_pda/models/chat/chat_links.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_template.dart';
import 'package:torn_pda/models/chat/chat_time.dart';
import 'package:torn_pda/models/chat/chat_wiki.dart';
import 'package:torn_pda/models/items_model.dart';
import 'package:torn_pda/models/tabsave_model.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';
import 'package:torn_pda/providers/chat/chat_link_info.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/providers/chat/chat_telemetry.dart';
import 'package:torn_pda/providers/userscripts_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/chat/chat_help.dart';
import 'package:torn_pda/widgets/chat/chat_link_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_slot_sheet.dart';
import 'package:torn_pda/widgets/chat/chat_status_sheet.dart';
import 'package:torn_pda/widgets/chat/chat_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

enum _Tool { replies, price, player, tabs, scripts, wiki, help }

class ChatComposeTools extends StatefulWidget {
  const ChatComposeTools({super.key, required this.onInsert, this.onEmoji, this.chat, this.name});

  final ValueChanged<String> onInsert;
  final ValueChanged<String>? onEmoji;
  final ChatController? chat;
  final String? name;

  @override
  State<ChatComposeTools> createState() => _ChatComposeToolsState();
}

class _ChatComposeToolsState extends State<ChatComposeTools> {
  final TextEditingController _query = TextEditingController();
  final FocusNode _queryFocus = FocusNode();
  final TextEditingController _name = TextEditingController();
  final FocusNode _nameFocus = FocusNode();
  _Tool _tool = _Tool.replies;
  bool _withLink = false;
  ItemsModel? _catalog;
  bool _loading = false;
  bool _failed = false;
  Timer? _searchTimer;
  String? _searched;
  ChatUser? _picked;
  ChatLinkInfo? _info;
  bool _infoLoading = false;
  final TextEditingController _wikiText = TextEditingController();
  final FocusNode _wikiFocus = FocusNode();
  List<(String, String)>? _savedTabs;

  @override
  void dispose() {
    _searchTimer?.cancel();
    final searched = _searched;
    if (searched != null) {
      final chat = widget.chat;
      scheduleMicrotask(() => chat?.endSearch(searched));
    }
    _query.dispose();
    _queryFocus.dispose();
    _name.dispose();
    _nameFocus.dispose();
    _wikiText.dispose();
    _wikiFocus.dispose();
    super.dispose();
  }

  void _show(_Tool tool, [FocusNode? focus]) {
    setState(() => _tool = tool);
    if (focus == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) focus.requestFocus();
    });
  }

  Future<void> _openPricing() async {
    _show(_Tool.price, _queryFocus);
    setState(() => _failed = false);
    if (_catalog != null) return;
    setState(() => _loading = true);
    ItemsModel? catalog;
    try {
      catalog = await ChatLinkPreviews.catalogItems();
    } catch (_) {
      catalog = null;
    }
    if (!mounted) return;
    setState(() {
      _catalog = catalog;
      _loading = false;
      _failed = catalog == null;
    });
  }

  // Saved tabs until the browser opens
  Future<void> _openTabs() async {
    _show(_Tool.tabs);
    final app = NativeChat.navigatorKey?.currentContext;
    if (app == null || _savedTabs != null) return;
    if (Provider.of<WebViewProvider>(app, listen: false).tabList.isNotEmpty) return;
    final saved = <(String, String)>[];
    for (final json in [await Prefs().getWebViewMainTab(), await Prefs().getWebViewSecondaryTabs()]) {
      try {
        for (final tab in tabSaveModelFromJson(json).tabsSave ?? const <TabsSave>[]) {
          final url = tab.url;
          if (url == null || !url.startsWith('http')) continue;
          final title = (tab.customName.isNotEmpty ? tab.customName : tab.pageTitle ?? '').trim();
          saved.add((title.isEmpty ? url : title, url));
        }
      } catch (_) {}
    }
    if (mounted) setState(() => _savedTabs = saved);
  }

  Future<void> _insertReply(String reply) async {
    ChatTelemetry.count('quick_reply');
    final values = await chatSlotValues(
      name: widget.name,
      me: widget.chat?.myName,
      fetch: ChatTemplate.needsBars(reply),
    );
    if (!mounted) return;
    final asks = ChatTemplate.toAsk(reply, values);
    final text = asks.isEmpty
        ? ChatTemplate.fill(reply, values).text
        : await showChatSlotSheet(context, reply, values, asks);
    if (text != null && mounted) widget.onInsert(text);
  }

  Future<void> _insertTime() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: now,
      builder: (context, child) =>
          MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!),
    );
    if (picked == null) return;
    final today = DateTime.now();
    widget.onInsert(ChatTimeRef.insertText(DateTime(today.year, today.month, today.day, picked.hour, picked.minute)));
  }

  void _onName(String text) {
    _searchTimer?.cancel();
    setState(() => _picked = null);
    final chat = widget.chat;
    final query = text.trim();
    if (chat == null || query.length < 2 || int.tryParse(query) != null) return;
    if (chat.searchPlayers(query).length >= 3) return;
    _searchTimer = Timer(const Duration(milliseconds: 400), () {
      _searched = query;
      chat.search(query);
    });
  }

  List<ChatUser> _matches(String query) {
    final chat = widget.chat;
    if (chat == null) return const [];
    final found = chat.searchQuery == query ? chat.searchResults ?? const <ChatUser>[] : const <ChatUser>[];
    final seen = <int>{};
    return [
      for (final user in [...chat.searchPlayers(query).map((p) => p.$1), ...found])
        if (user.id > 0 && user.id != chat.myUserId && seen.add(user.id)) user,
    ];
  }

  Future<void> _pick(ChatUser user) async {
    setState(() {
      _picked = user;
      _info = null;
      _infoLoading = true;
    });
    final link = ChatLink(
      uri: Uri.parse('https://www.torn.com/profiles.php?XID=${user.id}'),
      raw: '',
      kind: ChatLinkKind.player,
      title: user.name,
      id: user.id,
    );
    final info = await ChatLinkPreviews.load(link, () => mounted && _picked?.id == user.id);
    if (!mounted || _picked?.id != user.id) return;
    setState(() {
      _info = info;
      _infoLoading = false;
    });
  }

  String? _nameOf(ChatUser user) {
    if (user.name.isNotEmpty) return user.name;
    final title = _info?.title;
    final tag = ' [${user.id}]';
    if (title == null) return null;
    return title.endsWith(tag) ? title.substring(0, title.length - tag.length) : title;
  }

  Widget _chips(List<Widget> children) => SizedBox(
    height: MediaQuery.textScalerOf(context).scale(40),
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: [for (final chip in children) Padding(padding: const EdgeInsets.only(right: 6), child: chip)],
    ),
  );

  Widget _header({required Widget child, Widget? trailing}) => Row(
    children: [
      IconButton(
        tooltip: 'Back to quick replies',
        visualDensity: VisualDensity.compact,
        icon: const Icon(Icons.arrow_back_rounded, size: 20),
        onPressed: () => _show(_Tool.replies),
      ),
      Expanded(child: child),
      ?trailing,
    ],
  );

  Widget _replies(BuildContext context) {
    final prefs = NativeChat.prefs;
    final split = ChatPrefs.splitQuickRows(prefs.quickOrder, rows: prefs.actionRows);
    var action = 0;
    final rows = [
      for (final type in prefs.quickRowsShown)
        switch (type) {
          ChatQuickRow.actions => [
            for (final id in split[action++])
              if (!prefs.quickOff(id)) ..._actionChips(id),
          ],
          ChatQuickRow.emoji => _emojiChips(),
          ChatQuickRow.replies => _replyChips(),
        },
    ];
    return Row(
      children: [
        Expanded(
          child: Column(mainAxisSize: MainAxisSize.min, children: [for (final row in rows) _chips(row)]),
        ),
        IconButton(
          tooltip: 'Edit',
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.edit_outlined, size: 20),
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (_) => const SafeArea(child: SingleChildScrollView(child: ChatQuickActionsEditor())),
          ),
        ),
        IconButton(
          tooltip: 'Help',
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.help_outline_rounded, size: 20),
          onPressed: () => _show(_Tool.help),
        ),
      ],
    );
  }

  List<Widget> _emojiChips() {
    final prefs = NativeChat.prefs;
    final emojis = ChatEmoji.row(prefs.emojiFavorites, prefs.emojiCounts);
    return [
      for (final emoji in emojis)
        ActionChip(
          label: Text(emoji, style: const TextStyle(fontSize: 18)),
          visualDensity: VisualDensity.compact,
          onPressed: () {
            ChatTelemetry.count('quick_emoji');
            widget.onEmoji?.call(emoji);
          },
        ),
      ActionChip(
        avatar: Icon(emojis.isEmpty ? Icons.add_rounded : Icons.add_reaction_outlined, size: 18),
        tooltip: 'Edit favorite emojis',
        label: Text(emojis.isEmpty ? 'Add emoji' : 'Emojis'),
        visualDensity: VisualDensity.compact,
        onPressed: () async {
          await showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (_) => const SafeArea(child: ChatEmojiEditor()),
          );
          if (mounted) setState(() {});
        },
      ),
    ];
  }

  List<Widget> _replyChips() {
    final replies = NativeChat.prefs.quickReplies;
    if (replies.isEmpty) {
      return [
        ActionChip(
          avatar: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Save a reply'),
          visualDensity: VisualDensity.compact,
          onPressed: () async {
            await showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (sheet) => Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheet).bottom),
                child: const SafeArea(child: SingleChildScrollView(child: ChatQuickReplySettings())),
              ),
            );
            if (mounted) setState(() {});
          },
        ),
      ];
    }
    return [
      for (final reply in replies)
        ActionChip(label: Text(reply), visualDensity: VisualDensity.compact, onPressed: () => _insertReply(reply)),
    ];
  }

  List<Widget> _actionChips(String id) {
    VoidCallback tap(VoidCallback action) => () {
      ChatTelemetry.count('quick_action');
      action();
    };
    return switch (id) {
      'price' when NativeChat.prefs.itemPrice => [
        ActionChip(
          avatar: const Icon(Icons.sell_outlined, size: 18),
          label: const Text('Item price'),
          visualDensity: VisualDensity.compact,
          onPressed: tap(_openPricing),
        ),
      ],
      'player' when widget.chat != null => [
        ActionChip(
          avatar: const Icon(Icons.person_search_outlined, size: 18),
          label: const Text('Player'),
          visualDensity: VisualDensity.compact,
          onPressed: tap(() => _show(_Tool.player, _nameFocus)),
        ),
      ],
      'tab' => [
        ActionChip(
          avatar: const Icon(Icons.tab_rounded, size: 18),
          label: const Text('Share tab'),
          visualDensity: VisualDensity.compact,
          onPressed: tap(_openTabs),
        ),
      ],
      'script' => [
        ActionChip(
          avatar: const Icon(Icons.code_rounded, size: 18),
          label: const Text('Share script'),
          visualDensity: VisualDensity.compact,
          onPressed: tap(() => _show(_Tool.scripts)),
        ),
      ],
      'status' => [
        ActionChip(
          avatar: const Icon(Icons.monitor_heart_outlined, size: 18),
          label: const Text('Status'),
          visualDensity: VisualDensity.compact,
          onPressed: tap(() => showChatStatusSheet(context, widget.onInsert)),
        ),
      ],
      'wiki' => [
        ActionChip(
          avatar: const Icon(Icons.menu_book_outlined, size: 18),
          label: const Text('Wiki'),
          visualDensity: VisualDensity.compact,
          onPressed: tap(() => _show(_Tool.wiki, _wikiFocus)),
        ),
      ],
      'time' => [
        ActionChip(
          avatar: const Icon(Icons.schedule_rounded, size: 18),
          label: const Text('Time'),
          visualDensity: VisualDensity.compact,
          onPressed: tap(_insertTime),
        ),
      ],
      'emoji' => _emojiChips(),
      'replies' => _replyChips(),
      _ => const <Widget>[],
    };
  }

  Widget _share(BuildContext context, {required bool tabs}) {
    final theme = Theme.of(context);
    final app = NativeChat.navigatorKey?.currentContext;
    final items = <(String, String)>[];
    if (app != null && tabs) {
      final web = Provider.of<WebViewProvider>(app, listen: false);
      final open = [
        for (final (i, tab) in web.tabList.indexed)
          if (tab.currentUrl?.startsWith('http') ?? false)
            (
              i == web.currentTab ? 0 : 1,
              (tab.customName.isNotEmpty ? tab.customName : (tab.pageTitle ?? '')).trim(),
              tab.currentUrl!,
            ),
      ]..sort((a, b) => a.$1.compareTo(b.$1));
      for (final (_, title, url) in open) {
        items.add((title.isEmpty ? url : title, url));
      }
      if (open.isEmpty) items.addAll(_savedTabs ?? const []);
    } else if (app != null) {
      final scripts = Provider.of<UserScriptsProvider>(app, listen: false);
      for (final script in scripts.userScriptList) {
        final url = script.url;
        if (url != null && url.startsWith('http')) items.add((script.name, url));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _header(child: Text(tabs ? 'Share a browser tab' : 'Share a script', style: theme.textTheme.titleSmall)),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              tabs ? 'No open tabs' : 'No scripts with a source URL',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: Material(
              type: MaterialType.transparency,
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final (title, url) in items)
                    ListTile(
                      dense: true,
                      minTileHeight: 48,
                      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(url, maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: () {
                        widget.onInsert(url);
                        _show(_Tool.replies);
                      },
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _help(BuildContext context) {
    final theme = Theme.of(context);
    final small = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    Widget entry(IconData icon, String title, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '$title  ', style: theme.textTheme.labelLarge),
                  TextSpan(text: text, style: small),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      child: Text(title, style: theme.textTheme.labelLarge),
    );
    final prefs = NativeChat.prefs;
    final guide = quickGuide(order: prefs.quickOrder, rows: prefs.quickRowsShown, isOff: prefs.quickOff);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _header(child: Text('Quick actions', style: theme.textTheme.titleSmall)),
        for (final (i, row) in guide.rows.indexed) ...[
          if (guide.rows.length > 1) section('Row ${i + 1}'),
          for (final e in row) entry(e.icon, e.title, e.text),
        ],
        for (final e in guide.other) entry(e.icon, e.title, e.text),
        if (guide.off.isNotEmpty) section('Disabled by you'),
        for (final e in guide.off) entry(e.icon, e.title, e.text),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text('Nothing goes out until you tap Send. Change the replies and actions with Edit', style: small),
        ),
      ],
    );
  }

  Widget _pricer(BuildContext context) {
    final theme = Theme.of(context);
    final small = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final catalog = _catalog;
    final results = catalog == null
        ? const <ChatItemPrice>[]
        : ChatItemPrice.search(catalog, _query.text, NativeChat.prefs.itemAliases);
    final Widget below;
    if (_loading) {
      below = const Padding(
        padding: EdgeInsets.all(8),
        child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
      );
    } else if (_failed) {
      below = Row(
        children: [
          Expanded(child: Text('Could not load the item list', style: small)),
          TextButton(onPressed: _openPricing, child: const Text('Retry')),
        ],
      );
    } else if (_query.text.trim().length < 2) {
      below = Text('Type at least two letters', style: small);
    } else if (results.isEmpty) {
      below = Text('No item found', style: small);
    } else {
      below = _chips([
        for (final item in results)
          ActionChip(
            label: Text(item.price.isEmpty ? item.name : '${item.name} ${item.price}'),
            visualDensity: VisualDensity.compact,
            onPressed: () {
              ChatTemplate.lastItem = item;
              widget.onInsert(item.text(link: _withLink));
            },
          ),
      ]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _header(
          child: TextField(
            controller: _query,
            focusNode: _queryFocus,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'Item name', isDense: true),
          ),
          trailing: Tooltip(
            message: 'Add the market link',
            child: FilterChip(
              label: const Text('Link'),
              selected: _withLink,
              visualDensity: VisualDensity.compact,
              onSelected: (value) => setState(() => _withLink = value),
            ),
          ),
        ),
        const SizedBox(height: 4),
        below,
      ],
    );
  }

  Widget _playerCard(BuildContext context, ChatUser user) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final small = theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final info = _info;
    final name = _nameOf(user);
    final found = name == null ? null : ChatUser(id: user.id, name: name, avatarUrl: user.avatarUrl);
    final detail = _infoLoading
        ? 'Loading'
        : info?.detail ?? (found == null ? 'Player not found' : 'Could not load the profile');
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: found == null ? null : () => showChatPlayerActions(context, found),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            const SizedBox(width: 8),
            Stack(
              clipBehavior: Clip.none,
              children: [
                ChatAvatar(user: found ?? user, size: 32),
                if (info?.presence case final presence?)
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: chatPresenceColor(presence, scheme.onSurface),
                        shape: BoxShape.circle,
                        border: Border.all(color: scheme.surfaceContainerHighest, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name == null ? '[${user.id}]' : '$name [${user.id}]',
                    style: theme.textTheme.labelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(detail, style: small, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Add to the message',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.add_comment_outlined, size: 20),
              onPressed: found == null ? null : () => widget.onInsert('${found.name} [${found.id}]'),
            ),
            IconButton(
              tooltip: 'Player actions',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.more_horiz_rounded, size: 20),
              onPressed: found == null ? null : () => showChatPlayerActions(context, found),
            ),
          ],
        ),
      ),
    );
  }

  Widget _player(BuildContext context) {
    final theme = Theme.of(context);
    final small = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final query = _name.text.trim();
    final id = int.tryParse(query);
    final picked = _picked;
    final chat = widget.chat;
    final Widget below;
    if (picked != null) {
      below = _playerCard(context, picked);
    } else if (id != null && id > 0) {
      below = _chips([
        ActionChip(
          avatar: const Icon(Icons.person_search_outlined, size: 18),
          label: Text('Look up [$id]'),
          visualDensity: VisualDensity.compact,
          onPressed: () => _pick(ChatUser(id: id, name: '')),
        ),
      ]);
    } else if (query.length < 2) {
      below = Text('Type a name or an ID', style: small);
    } else {
      final matches = _matches(query);
      final lookingUp =
          (_searchTimer?.isActive ?? false) || (chat != null && chat.searching && chat.searchQuery == query);
      below = matches.isEmpty && !lookingUp
          ? Text('No player found', style: small)
          : _chips([
              for (final user in matches)
                ActionChip(
                  avatar: ChatAvatar(user: user, size: 24),
                  label: Text(user.name),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _pick(user),
                ),
              if (lookingUp)
                const Padding(
                  padding: EdgeInsets.all(10),
                  child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                ),
            ]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _header(
          child: TextField(
            controller: _name,
            focusNode: _nameFocus,
            onChanged: _onName,
            onSubmitted: (_) {
              if (id != null && id > 0) _pick(ChatUser(id: id, name: ''));
            },
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(hintText: 'Player name or ID', isDense: true),
          ),
        ),
        const SizedBox(height: 4),
        below,
      ],
    );
  }

  Widget _wikiSearch(BuildContext context) {
    final small = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    final query = _wikiText.text.trim();
    final search = ChatWiki.searchLink(query).toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _header(
          child: TextField(
            controller: _wikiText,
            focusNode: _wikiFocus,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(hintText: 'Search the wiki', isDense: true),
          ),
          trailing: IconButton(
            tooltip: 'Open the search in the browser',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.open_in_browser_rounded, size: 20),
            onPressed: query.length < 2 ? null : () => NativeChat.openUrl(search),
          ),
        ),
        const SizedBox(height: 4),
        if (query.length < 2)
          Text('Type at least two letters', style: small)
        else
          _chips([
            ActionChip(
              avatar: const Icon(Icons.search_rounded, size: 18),
              label: Text('Search link: $query'),
              visualDensity: VisualDensity.compact,
              onPressed: () => widget.onInsert(search),
            ),
            for (final title in ChatWiki.articles(query))
              ActionChip(
                avatar: const Icon(Icons.menu_book_outlined, size: 18),
                label: Text(title),
                visualDensity: VisualDensity.compact,
                onPressed: () => widget.onInsert(ChatWiki.article(title).toString()),
              ),
          ]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6, left: 6),
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
      child: ListenableBuilder(
        listenable: Listenable.merge([NativeChat.prefs, ?widget.chat]),
        builder: (context, _) => switch (_tool) {
          _Tool.price when NativeChat.prefs.itemPrice => _pricer(context),
          _Tool.player => _player(context),
          _Tool.tabs => _share(context, tabs: true),
          _Tool.scripts => _share(context, tabs: false),
          _Tool.wiki => _wikiSearch(context),
          _Tool.help => _help(context),
          _ => _replies(context),
        },
      ),
    );
  }
}

class ChatQuickActionsEditor extends StatelessWidget {
  const ChatQuickActionsEditor({super.key});

  static const Map<String, (IconData, String)> _labels = {
    'price': (Icons.sell_outlined, 'Item price'),
    'player': (Icons.person_search_outlined, 'Player'),
    'tab': (Icons.tab_rounded, 'Share tab'),
    'script': (Icons.code_rounded, 'Share script'),
    'status': (Icons.monitor_heart_outlined, 'Status'),
    'wiki': (Icons.menu_book_outlined, 'Wiki'),
    'time': (Icons.schedule_rounded, 'Time'),
    'emoji': (Icons.add_reaction_outlined, 'Emojis'),
    'replies': (Icons.bolt_rounded, 'Quick replies'),
  };

  @override
  Widget build(BuildContext context) {
    final prefs = NativeChat.prefs;
    Widget handle(int i, String label) => ReorderableDragStartListener(
      index: i,
      child: Semantics(
        label: 'Drag to reorder $label',
        child: const SizedBox(width: 48, height: 48, child: Icon(Icons.drag_handle_rounded)),
      ),
    );
    return ListenableBuilder(
      listenable: prefs,
      builder: (context, _) {
        final order = prefs.quickEditor;
        final shown = prefs.quickRowsShown;
        final actionRow = [for (final (i, type) in shown.indexed) if (type == ChatQuickRow.actions) i + 1];
        Widget rule(String id, String text, {int? drag}) => ListTile(
          key: ValueKey(id),
          leading: drag == null ? const SizedBox(width: 48) : handle(drag, text),
          title: Row(
            children: [
              const Expanded(child: Divider()),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(text)),
              const Expanded(child: Divider()),
            ],
          ),
        );
        return Material(
          type: MaterialType.transparency,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Rows'),
                trailing: SegmentedButton<int>(
                  showSelectedIcon: false,
                  style: const ButtonStyle(visualDensity: VisualDensity.compact),
                  segments: [for (final n in ChatPrefs.quickRowsOptions) ButtonSegment(value: n, label: Text('$n'))],
                  selected: {prefs.quickRows},
                  onSelectionChanged: (v) => prefs.setQuickRows(v.first),
                ),
              ),
              for (final (i, type) in shown.indexed)
                ListTile(
                  title: Text('Row ${i + 1}'),
                  trailing: DropdownButton<ChatQuickRow>(
                    value: type,
                    underline: const SizedBox.shrink(),
                    items: [for (final t in ChatQuickRow.values) DropdownMenuItem(value: t, child: Text(t.title))],
                    onChanged: (t) => prefs.setQuickRowTypes([...prefs.quickRowTypes]..[i] = t!),
                  ),
                ),
              if (actionRow.isNotEmpty)
                ReorderableListView(
                  shrinkWrap: true,
                  buildDefaultDragHandles: false,
                  physics: const NeverScrollableScrollPhysics(),
                  onReorderItem: prefs.moveQuickAction,
                  children: [
                    for (final (i, id) in order.indexed)
                      if (id == ChatPrefs.rowBreak2)
                        rule(id, 'Row ${actionRow[1]}', drag: i)
                      else if (id == ChatPrefs.rowBreak3)
                        rule(id, 'Row ${actionRow[2]}', drag: i)
                      else if (id == ChatPrefs.offBreak)
                        rule(id, 'Disabled by you')
                      else
                        SwitchListTile(
                          key: ValueKey(id),
                          secondary: handle(i, _labels[id]!.$2),
                          title: Row(
                            children: [
                              Icon(_labels[id]!.$1, size: 18),
                              const SizedBox(width: 8),
                              Text(_labels[id]!.$2),
                            ],
                          ),
                          value: !prefs.quickOff(id),
                          onChanged: (on) => prefs.setQuickActionShown(id, on),
                        ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class ChatEmojiEditor extends StatelessWidget {
  const ChatEmojiEditor({super.key, this.onPick});

  /// Picks instead of editing favorites
  final ValueChanged<String>? onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prefs = NativeChat.prefs;
    return ListenableBuilder(
      listenable: prefs,
      builder: (context, _) {
        final favorites = prefs.emojiFavorites;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
          child: Material(
            type: MaterialType.transparency,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                if (onPick == null) ...[
                  Text('Favorites (${favorites.length}/${ChatEmoji.maxFavorites})', style: theme.textTheme.titleSmall),
                  Text(
                    'Tap an emoji below to add or remove it. Drag to reorder',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  SizedBox(
                    height: 56,
                    child: favorites.isEmpty
                        ? const Align(alignment: Alignment.centerLeft, child: Text('No favorites yet'))
                        : ReorderableListView(
                            scrollDirection: Axis.horizontal,
                            onReorderItem: prefs.moveEmojiFavorite,
                            children: [
                              for (final (i, emoji) in favorites.indexed)
                                Semantics(
                                  key: ValueKey(emoji),
                                  label: 'Favorite $emoji',
                                  customSemanticsActions: {
                                    if (i > 0)
                                      const CustomSemanticsAction(label: 'Move left'): () =>
                                          prefs.moveEmojiFavorite(i, i - 1),
                                    if (i < favorites.length - 1)
                                      const CustomSemanticsAction(label: 'Move right'): () =>
                                          prefs.moveEmojiFavorite(i, i + 1),
                                  },
                                  child: SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: Center(child: Text(emoji, style: const TextStyle(fontSize: 26))),
                                  ),
                                ),
                            ],
                          ),
                  ),
                ],
                for (final entry in ChatEmoji.categories.entries) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(entry.key, style: theme.textTheme.titleSmall),
                  ),
                  Wrap(
                    children: [
                      for (final emoji in entry.value)
                        Semantics(
                          button: true,
                          selected: onPick == null && favorites.contains(emoji),
                          label: emoji,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => onPick == null ? prefs.toggleEmojiFavorite(emoji) : onPick!(emoji),
                            child: Container(
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: onPick == null && favorites.contains(emoji)
                                    ? theme.colorScheme.primaryContainer
                                    : null,
                              ),
                              child: Text(emoji, style: const TextStyle(fontSize: 24)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class ChatQuickReplySettings extends StatefulWidget {
  const ChatQuickReplySettings({super.key});

  @override
  State<ChatQuickReplySettings> createState() => _ChatQuickReplySettingsState();
}

class _ChatQuickReplySettingsState extends State<ChatQuickReplySettings> {
  final TextEditingController _reply = TextEditingController();
  Map<String, String> _values = const {};

  @override
  void initState() {
    super.initState();
    _reply.addListener(() => setState(() {}));
    chatSlotValues(me: NativeChat.controller.myName).then((v) {
      if (mounted) setState(() => _values = v);
    });
  }

  void _addSlot(ChatSlot slot) {
    final v = _reply.value;
    final at = v.selection.isValid ? v.selection.start : v.text.length;
    final end = v.selection.isValid ? v.selection.end : v.text.length;
    _reply.value = TextEditingValue(
      text: v.text.replaceRange(at, end, slot.tag),
      selection: TextSelection.collapsed(offset: at + slot.tag.length),
    );
  }

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  void _add() {
    NativeChat.prefs.addQuickReply(_reply.text);
    _reply.clear();
  }

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: NativeChat.prefs, builder: (context, _) => _settings(context));

  Widget _settings(BuildContext context) {
    final theme = Theme.of(context);
    final prefs = NativeChat.prefs;
    final full = prefs.quickReplies.length >= ChatPrefs.maxQuickReplies;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final reply in prefs.quickReplies)
                InputChip(label: Text(reply), onDeleted: () => prefs.removeQuickReply(reply)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            controller: _reply,
            enabled: !full,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _add(),
            decoration: InputDecoration(
              hintText: full ? 'Up to ${ChatPrefs.maxQuickReplies} replies' : 'Add a reply',
              isDense: true,
              suffixIcon: IconButton(
                tooltip: 'Add reply',
                icon: const Icon(Icons.add_rounded),
                onPressed: full ? null : _add,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final slot in ChatTemplate.slots)
                ActionChip(
                  label: Text(slot.tag),
                  tooltip: slot.help,
                  visualDensity: VisualDensity.compact,
                  onPressed: full ? null : () => _addSlot(slot),
                ),
            ],
          ),
        ),
        if (ChatTemplate.used(_reply.text).isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              'Preview: ${ChatTemplate.fill(_reply.text, _values).text}',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
      ],
    );
  }
}

/// Shows the format while typing, markers faded
class ChatFormatController extends TextEditingController {
  ChatFormatController({super.text});

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    if (!ChatFormat.hasMarkers(text)) {
      return super.buildTextSpan(context: context, style: style, withComposing: withComposing);
    }
    final (styles, markers) = ChatFormat.scan(text);
    final composing = withComposing && value.isComposingRangeValid ? value.composing : TextRange.empty;
    final color = style?.color ?? Theme.of(context).colorScheme.onSurface;
    final faded = TextStyle(color: color.withValues(alpha: 0.4));
    const typing = TextStyle(decoration: TextDecoration.underline);
    (int, bool, bool) key(int i) => (styles[i], markers[i], i >= composing.start && i < composing.end);
    final spans = <TextSpan>[];
    var from = 0;
    for (var i = 1; i <= text.length; i++) {
      if (i < text.length && key(i) == key(from)) continue;
      final (format, marker, composed) = key(from);
      final base = marker ? faded : chatFormatStyle(format);
      spans.add(TextSpan(text: text.substring(from, i), style: composed ? (base ?? typing).merge(typing) : base));
      from = i;
    }
    return TextSpan(style: style, children: spans);
  }
}

class ChatFormatBar extends StatelessWidget {
  const ChatFormatBar({super.key, required this.controller, required this.focus});

  final TextEditingController controller;
  final FocusNode focus;

  static const List<(IconData, String, String, String)> _styles = [
    (Icons.format_bold_rounded, 'Bold', '**', 'bold'),
    (Icons.format_italic_rounded, 'Italic', '*', 'italic'),
    (Icons.format_strikethrough_rounded, 'Strikethrough', '~~', 'strikethrough'),
    (Icons.format_underlined_rounded, 'Underline', '__', 'underline'),
  ];

  void _apply(TextEditingValue value) {
    controller.value = value;
    focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    Widget button(IconData icon, String tooltip, VoidCallback onPressed) => IconButton(
      tooltip: tooltip,
      icon: Icon(icon, size: 22),
      onPressed: onPressed,
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
      padding: EdgeInsets.zero,
    );
    // Keeps the box focused and its selection
    return TextFieldTapRegion(
      child: Container(
        margin: const EdgeInsets.only(bottom: 6, left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            for (final (icon, tooltip, marker, placeholder) in _styles)
              button(icon, tooltip, () => _apply(ChatFormat.wrap(controller.value, marker, placeholder))),
            button(Icons.link_rounded, 'Link', () => _apply(ChatFormat.link(controller.value))),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Select text to format it',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
