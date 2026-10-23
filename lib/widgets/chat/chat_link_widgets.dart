import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chaining/ffscouter/ffscouter_cache_model.dart';
import 'package:torn_pda/models/chat/chat_format.dart';
import 'package:torn_pda/models/chat/chat_item_aliases.dart';
import 'package:torn_pda/models/chat/chat_links.dart';
import 'package:torn_pda/models/chat/chat_script_link.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_money.dart';
import 'package:torn_pda/models/chat/chat_price_check.dart';
import 'package:torn_pda/models/items_model.dart';
import 'package:torn_pda/models/chat/chat_time.dart';
import 'package:torn_pda/models/chat/chat_wiki.dart';
import 'package:torn_pda/models/chat/chat_status.dart';
import 'package:torn_pda/providers/chain_status_controller.dart';
import 'package:torn_pda/providers/chat/chat_link_info.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/torn-pda-native/stats/stats_controller.dart';
import 'package:torn_pda/providers/player_notes_controller.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/stakeouts_controller.dart';
import 'package:torn_pda/utils/webview_dialog_helper.dart';
import 'package:torn_pda/widgets/chat/chat_alerts_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_toast.dart';
import 'package:torn_pda/widgets/chat/chat_image_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_note_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_person_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_price_check_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_player_actions_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_player_card_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_script_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_wiki_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_bazaar_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';
import 'package:torn_pda/widgets/player_notes_dialog.dart';
import 'package:torn_pda/widgets/profile_check/profile_check_add_button.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatMessageText extends StatefulWidget {
  const ChatMessageText({
    super.key,
    required this.content,
    required this.color,
    this.highlight,
    this.slang = false,
    this.roomId,
    this.lead,
  });

  final String content;
  final Color color;

  final String? highlight;

  final bool slang;

  final String? roomId;

  /// Inline before the text, compact rows
  final InlineSpan? lead;

  @override
  State<ChatMessageText> createState() => _ChatMessageTextState();
}

/// Tap, plus long press for links
class _LinkPress extends TapGestureRecognizer {
  final LongPressGestureRecognizer long = LongPressGestureRecognizer();

  @override
  void addPointer(PointerDownEvent event) {
    long.addPointer(event);
    super.addPointer(event);
  }

  @override
  void dispose() {
    long.dispose();
    super.dispose();
  }
}

class _ChatMessageTextState extends State<ChatMessageText> {
  List<(Object, int)> _parts = const [];
  final List<_LinkPress> _taps = [];
  ItemsModel? _catalog;
  Set<int>? _named;
  bool _parsedItems = false;
  List<ChatItemAlias>? _parsedAliases;

  bool get _itemsOn =>
      widget.roomId != null && ChatPriceCheck.rooms.contains(widget.roomId) && NativeChat.prefs.priceCheck;

  @override
  void initState() {
    super.initState();
    _catalog = _itemsOn ? ChatPriceCheck.loadedCatalog : null;
    _parse();
    _loadCatalog();
  }

  @override
  void didUpdateWidget(ChatMessageText old) {
    super.didUpdateWidget(old);
    if (old.content != widget.content || old.slang != widget.slang || old.roomId != widget.roomId) {
      _parse();
      _loadCatalog();
    }
  }

  Future<void> _loadCatalog() async {
    if (!_itemsOn) return;
    final catalog = await ChatLinkPreviews.catalogItems();
    if (!mounted || catalog == null || identical(catalog, _catalog)) return;
    setState(() {
      _catalog = catalog;
      _parse();
    });
  }

  void _parse() {
    final catalog = _itemsOn ? _catalog : null;
    _parsedItems = _itemsOn;
    _parsedAliases = NativeChat.prefs.itemAliases;
    _named = !_itemsOn
        ? null
        : catalog == null
        ? const {}
        : ChatItemRef.namedIds(widget.content, catalog, _parsedAliases!);
    for (final tap in _taps) {
      tap.dispose();
    }
    _taps.clear();
    _parts = [
      for (final (run, style) in ChatFormat.runs(widget.content))
        for (final part in ChatLink.split(run))
          if (part is String)
            for (final piece in ChatPlayerRef.split(part))
              if (piece is String)
                for (final bit in ChatTimeRef.split(piece))
                  if (bit is String)
                    for (final cash in ChatMoneyRef.split(bit))
                      if (cash is String)
                        for (final item
                            in catalog == null
                                ? [cash]
                                : ChatItemRef.split(cash, catalog, NativeChat.prefs.itemAliases))
                          if (item is String && widget.slang)
                            for (final word in ChatWiki.split(item)) (word, style)
                          else
                            (item, style)
                      else
                        (cash, style)
                  else
                    (bit, style)
              else
                (piece, style)
          else
            (part, style),
    ];
  }

  @override
  void dispose() {
    for (final tap in _taps) {
      tap.dispose();
    }
    super.dispose();
  }

  List<TextSpan> _marked(String text, Color mark) {
    final term = widget.highlight?.toLowerCase() ?? '';
    if (term.isEmpty) return [TextSpan(text: text)];
    final lower = text.toLowerCase();
    // Some letters change length when lowercased
    if (lower.length != text.length) return [TextSpan(text: text)];
    final spans = <TextSpan>[];
    var from = 0;
    for (var at = lower.indexOf(term); at >= 0; at = lower.indexOf(term, from)) {
      if (at > from) spans.add(TextSpan(text: text.substring(from, at)));
      spans.add(
        TextSpan(
          text: text.substring(at, at + term.length),
          style: TextStyle(backgroundColor: mark, fontWeight: FontWeight.w700),
        ),
      );
      from = at + term.length;
    }
    if (from < text.length) spans.add(TextSpan(text: text.substring(from)));
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    if (_parsedItems != _itemsOn || !identical(_parsedAliases, NativeChat.prefs.itemAliases)) {
      _parse();
      _loadCatalog();
    }
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyMedium?.copyWith(color: widget.color, height: 1.3);
    final mark = theme.colorScheme.primary.withValues(alpha: 0.35);
    final links = <String, ChatLink>{
      for (final (part, _) in _parts)
        if (part is ChatLink) part.url: part,
    }.values.take(3).toList();
    final refs = _parts.any(
      (p) =>
          p.$1 is ChatPlayerRef ||
          p.$1 is ChatTimeRef ||
          p.$1 is ChatMoneyRef ||
          p.$1 is ChatSlang ||
          p.$1 is ChatItemRef,
    );
    final formatted = _parts.any((p) => p.$2 != 0);
    final lead = widget.lead;
    if (links.isEmpty && !refs && !formatted) {
      if (widget.highlight?.isNotEmpty != true && lead == null) return Text(widget.content, style: style);
      return Text.rich(TextSpan(children: [?lead, ..._marked(widget.content, mark)]), style: style);
    }

    final onlyLinks = _parts.every((p) => p.$1 is ChatLink || (p.$1 is String && (p.$1 as String).trim().isEmpty));
    var tapIndex = 0;
    final spans = <InlineSpan>[];
    for (final (part, format) in _parts) {
      if (part is String) {
        spans.add(TextSpan(style: chatFormatStyle(format), children: _marked(part, mark)));
        continue;
      }
      if (tapIndex == _taps.length) _taps.add(_LinkPress());
      final tap = _taps[tapIndex++]..long.onLongPress = null;
      if (part is ChatTimeRef) {
        tap.onTap = () => _showChatTimeSheet(context, part);
        spans.add(
          TextSpan(
            text: part.raw,
            recognizer: tap,
            style: TextStyle(
              decorationStyle: TextDecorationStyle.dotted,
              decorationColor: widget.color.withValues(alpha: 0.7),
            ).merge(chatFormatStyle(format, underline: true)),
          ),
        );
        continue;
      }
      if (part is ChatMoneyRef) {
        tap.onTap = () => _showChatMoneySheet(context, part);
        spans.add(
          TextSpan(
            text: part.raw,
            recognizer: tap,
            style: TextStyle(
              decorationStyle: TextDecorationStyle.dotted,
              decorationColor: widget.color.withValues(alpha: 0.5),
            ).merge(chatFormatStyle(format, underline: true)),
          ),
        );
        continue;
      }
      if (part is ChatSlang) {
        tap.onTap = () => showChatSlangSheet(context, part);
        spans.add(
          TextSpan(
            text: part.raw,
            recognizer: tap,
            style: TextStyle(
              decorationStyle: TextDecorationStyle.dotted,
              decorationColor: widget.color.withValues(alpha: 0.5),
            ).merge(chatFormatStyle(format, underline: true)),
          ),
        );
        continue;
      }
      if (part is ChatItemRef) {
        tap.onTap = () => showChatItemSheet(context, part);
        spans.add(
          TextSpan(
            text: part.raw,
            recognizer: tap,
            style: TextStyle(
              decorationStyle: TextDecorationStyle.dotted,
              decorationColor: widget.color.withValues(alpha: 0.5),
            ).merge(chatFormatStyle(format, underline: true)),
          ),
        );
        continue;
      }
      if (part is ChatPlayerRef) {
        tap.onTap = () => showChatPlayerActions(context, ChatUser(id: part.id, name: part.name));
        spans.add(
          TextSpan(
            text: part.raw,
            recognizer: tap,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              decorationStyle: TextDecorationStyle.dotted,
              decorationColor: widget.color.withValues(alpha: 0.7),
            ).merge(chatFormatStyle(format, underline: true)),
          ),
        );
        continue;
      }
      final link = part as ChatLink;
      tap.onTap = () => openChatLink(context, link);
      tap.long.onLongPress = () => showChatLinkMenu(context, link);
      spans.add(
        TextSpan(
          text: link.label ?? (link.raw.length > 48 ? '${link.raw.substring(0, 45)}...' : link.raw),
          recognizer: tap,
          style: TextStyle(
            decorationColor: widget.color.withValues(alpha: 0.6),
          ).merge(chatFormatStyle(format, underline: true)),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!onlyLinks)
          Text.rich(TextSpan(children: [?lead, ...spans]), style: style)
        else if (lead != null)
          Text.rich(lead, style: style),
        for (final link in links)
          Padding(
            padding: EdgeInsets.only(top: onlyLinks && link == links.first ? 2 : 6),
            child: link.isImage && link.warning == null
                ? ChatImageCard(link: link, color: widget.color)
                : ChatScriptLink.of(link) != null
                ? ChatScriptCard(link: link, color: widget.color)
                : ChatLinkCard(
                    link: link,
                    color: widget.color,
                    named: link.kind == ChatLinkKind.bazaar && NativeChat.prefs.bazaarAnalysis ? _named : null,
                  ),
          ),
      ],
    );
  }
}

TextStyle? chatFormatStyle(int style, {bool underline = false}) {
  if (style == 0 && !underline) return null;
  return TextStyle(
    fontWeight: style & ChatFormat.bold != 0 ? FontWeight.w700 : null,
    fontStyle: style & ChatFormat.italic != 0 ? FontStyle.italic : null,
    decoration: TextDecoration.combine([
      if (underline || style & ChatFormat.underline != 0) TextDecoration.underline,
      if (style & ChatFormat.strike != 0) TextDecoration.lineThrough,
    ]),
  );
}

Future<void> openChatLink(BuildContext context, ChatLink link) async {
  final warning = link.warning;
  if (warning != null) {
    final open = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded),
        title: Text(warning),
        content: Text(
          'This link goes to ${link.uri.host}, not to torn.com. Never enter your password or API key there.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Open anyway')),
        ],
      ),
    );
    if (open != true) return;
  }
  if (link.kind == ChatLinkKind.player && link.id != null && context.mounted) {
    return showChatPlayerActions(context, ChatUser(id: link.id!, name: 'Player'));
  }
  await NativeChat.openLink(link.url);
}

// Skips the link preview window
Future<void> showChatLinkMenu(BuildContext context, ChatLink link) async {
  final url = link.url;
  final picked = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final theme = Theme.of(context);
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(url, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
              subtitle: link.warning == null
                  ? null
                  : Text(link.warning!, style: TextStyle(color: theme.colorScheme.error)),
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('Copy link'),
              onTap: () => Navigator.of(context).pop('copy'),
            ),
            ListTile(
              leading: const Icon(Icons.tab_rounded),
              title: const Text('Open in main tab'),
              onTap: () => Navigator.of(context).pop('main'),
            ),
            ListTile(
              leading: const Icon(Icons.add_box_outlined),
              title: const Text('Open in new tab'),
              onTap: () => Navigator.of(context).pop('new'),
            ),
            ListTile(
              leading: const Icon(Icons.open_in_new_rounded),
              title: const Text('Open in external browser'),
              onTap: () => Navigator.of(context).pop('external'),
            ),
          ],
        ),
      );
    },
  );
  switch (picked) {
    case 'copy':
      await Clipboard.setData(ClipboardData(text: url));
      chatToast('Link copied', seconds: 1);
    case 'main' || 'new':
      await NativeChat.openUrl(url, newTab: picked == 'new');
    case 'external':
      await launchUrl(link.uri, mode: LaunchMode.externalApplication);
  }
}

class ChatInsertFrame extends StatelessWidget {
  const ChatInsertFrame({super.key, required this.color, required this.child, this.label, this.alert = false});

  final Color color;
  final Widget child;
  final String? label;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(color: color.withValues(alpha: 0.65), fontSize: 10);
    return Material(
      color: color.withValues(alpha: alert ? 0.10 : 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: color.withValues(alpha: alert ? 0.7 : 0.18)),
      ),
      clipBehavior: Clip.antiAlias,
      child: label == null
          ? child
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
                  child: Text(label!, style: style),
                ),
                child,
              ],
            ),
    );
  }
}

class ChatLinkCard extends StatefulWidget {
  const ChatLinkCard({super.key, required this.link, required this.color, this.named});

  final ChatLink link;
  final Color color;

  /// Null skips the bazaar summary
  final Set<int>? named;

  static const Map<ChatLinkKind, (IconData, String)> _looks = {
    ChatLinkKind.player: (Icons.person_rounded, 'Player'),
    ChatLinkKind.bazaar: (Icons.storefront_rounded, 'Bazaar'),
    ChatLinkKind.attack: (Icons.sports_mma_rounded, 'Attack'),
    ChatLinkKind.attackLog: (Icons.receipt_long_rounded, 'Attack log'),
    ChatLinkKind.chainReport: (Icons.timeline_rounded, 'Chain report'),
    ChatLinkKind.warReport: (Icons.emoji_events_rounded, 'War report'),
    ChatLinkKind.trade: (Icons.swap_horiz_rounded, 'Trade'),
    ChatLinkKind.faction: (Icons.shield_rounded, 'Faction'),
    ChatLinkKind.company: (Icons.business_rounded, 'Company'),
    ChatLinkKind.forum: (Icons.forum_rounded, 'Forum'),
    ChatLinkKind.item: (Icons.inventory_2_rounded, 'Item'),
    ChatLinkKind.torn: (Icons.public_rounded, 'Torn'),
    ChatLinkKind.external: (Icons.link_rounded, 'Link'),
  };

  @override
  State<ChatLinkCard> createState() => _ChatLinkCardState();
}

class _ChatLinkCardState extends State<ChatLinkCard> {
  static const Duration _dwell = Duration(milliseconds: 700);

  ChatLinkInfo? _info;
  FFScouterCacheEntry? _ff;
  bool _loading = false;
  bool _tried = false;
  bool _held = false;
  Timer? _timer;

  String? get _key => ChatLinkPreviews.keyOf(widget.link);

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void didUpdateWidget(ChatLinkCard old) {
    super.didUpdateWidget(old);
    if (old.link.url == widget.link.url) return;
    _timer?.cancel();
    _info = null;
    _ff = null;
    _loading = false;
    _tried = false;
    _held = false;
    _prepare();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool get _auto => switch (NativeChat.prefs.linkPreviews) {
    ChatImageAutoLoad.never => false,
    ChatImageAutoLoad.torn => widget.link.isTorn,
    ChatImageAutoLoad.always => true,
  };

  void _prepare() {
    final key = _key;
    if (key == null) return;
    final hit = ChatLinkPreviews.cached(widget.link);
    if (hit != null) {
      _info = hit.$1;
      _tried = true;
      if (_info != null) _loadFf();
      return;
    }
    if (_auto || ChatLinkPreviews.asked.contains(key)) _timer = Timer(_dwell, _dwelled);
  }

  void _dwelled() {
    if (!mounted) return;
    if (!ChatLinkPreviews.busy) return _load();
    if (!_held) setState(() => _held = true);
    _timer = Timer(const Duration(seconds: 10), _dwelled);
  }

  void _load() {
    final key = _key;
    if (key == null || _loading) return;
    _timer?.cancel();
    ChatLinkPreviews.asked.add(key);
    setState(() {
      _loading = true;
      _held = false;
    });
    ChatLinkPreviews.load(widget.link, () => mounted).then((info) {
      if (!mounted) return;
      setState(() {
        _info = info;
        _loading = false;
        _tried = true;
      });
      if (info != null) _loadFf();
    });
  }

  Future<void> _loadFf() async {
    final link = widget.link;
    final id = link.id;
    if (id == null || (link.kind != ChatLinkKind.player && link.kind != ChatLinkKind.attack)) return;
    final SettingsProvider settings;
    try {
      settings = Provider.of<SettingsProvider>(context, listen: false);
    } on ProviderNotFoundException {
      return;
    }
    if (settings.ffScouterEnabledStatus != 1) return;
    final entry = await ChatLinkPreviews.fairFight(id);
    if (mounted && entry != null) setState(() => _ff = entry);
  }

  Widget _video(ThemeData theme, ChatLinkInfo info, String image) {
    final color = widget.color;
    return ChatInsertFrame(
      color: color,
      child: InkWell(
        onTap: () => openChatLink(context, widget.link),
        onLongPress: () => showChatLinkMenu(context, widget.link),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _Thumb(
                      url: image,
                      size: null,
                      fallback: Icon(Icons.smart_display_rounded, size: 32, color: color.withValues(alpha: 0.6)),
                    ),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.play_arrow_rounded, size: 30, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'YouTube',
                      style: theme.textTheme.labelSmall?.copyWith(color: color.withValues(alpha: 0.65), fontSize: 10),
                    ),
                    Text(
                      info.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.w600),
                    ),
                    if (info.detail case final detail?)
                      Text(
                        detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(color: color.withValues(alpha: 0.7)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final link = widget.link;
    final color = widget.color;
    final warning = link.warning;
    final danger = theme.colorScheme.error;
    final video = link.videoId != null;
    final (looksIcon, label) = ChatLinkCard._looks[link.kind]!;
    final icon = video ? Icons.smart_display_rounded : looksIcon;
    final top = switch (link.kind) {
      _ when warning != null => warning,
      _ when video => 'YouTube',
      ChatLinkKind.external => 'Link',
      ChatLinkKind.torn => 'Torn',
      _ => 'Torn ${label.toLowerCase()}',
    };
    final info = _info;
    final title = info?.title ?? link.title;
    final image = info?.imageUrl;
    final bazaar = widget.named == null || link.id == null ? null : info?.bazaar;
    final canAsk = _key != null && !_tried && !_loading && (_held || _timer?.isActive != true);
    if (video && info != null && image != null) return _video(theme, info, image);
    return ChatInsertFrame(
      color: warning != null ? danger : color,
      alert: warning != null,
      child: InkWell(
        onTap: () => openChatLink(context, link),
        onLongPress: () => showChatLinkMenu(context, link),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (image != null)
                _Thumb(
                  url: image,
                  fallback: Icon(icon, size: 20, color: color.withValues(alpha: 0.85)),
                )
              else
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      warning != null ? Icons.warning_amber_rounded : icon,
                      size: 20,
                      color: warning != null ? danger : color.withValues(alpha: 0.85),
                    ),
                    if (info?.presence case final presence?)
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: chatPresenceColor(presence, color), shape: BoxShape.circle),
                        ),
                      ),
                  ],
                ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      top,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: warning != null ? danger : color.withValues(alpha: 0.65),
                        fontWeight: warning != null ? FontWeight.w700 : null,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      title,
                      maxLines: (link.kind == ChatLinkKind.external || link.kind == ChatLinkKind.forum) && info != null
                          ? 2
                          : 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.w600),
                    ),
                    ChatTicking(
                      until: info?.clock?.until,
                      builder: (context) {
                        final detail = info == null ? link.detail : info.detailAt(DateTime.now()) ?? link.detail;
                        if (detail == null || bazaar != null) return const SizedBox.shrink();
                        return Text(
                          detail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(color: color.withValues(alpha: 0.7)),
                        );
                      },
                    ),
                    if (bazaar != null)
                      ChatBazaarSummary(bazaar: bazaar, userId: link.id!, named: widget.named!, color: color),
                    for (final line in [...?info?.extra, if (_ff case final ff?) chatFfText(ff)])
                      Text(
                        line,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(color: color.withValues(alpha: 0.7)),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              if (_loading)
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: color.withValues(alpha: 0.6)),
                  ),
                )
              else if (canAsk)
                IconButton(
                  tooltip: 'Show preview',
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  onPressed: _load,
                  icon: Icon(Icons.travel_explore_rounded, color: color.withValues(alpha: 0.7)),
                ),
              if (link.kind == ChatLinkKind.player && link.id != null)
                IconButton(
                  tooltip: 'Player actions',
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  onPressed: () => showChatPlayerActions(
                    context,
                    ChatUser(id: link.id!, name: info?.title.replaceFirst(' [${link.id}]', '') ?? 'Player'),
                  ),
                  icon: Icon(Icons.more_vert_rounded, color: color.withValues(alpha: 0.7)),
                ),
              Tooltip(
                message: 'Open in the app',
                child: Icon(Icons.open_in_browser_rounded, size: 18, color: color.withValues(alpha: 0.7)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url, required this.fallback, this.size = 44});

  final String url;
  final Widget fallback;

  /// Null fills the parent
  final double? size;

  @override
  Widget build(BuildContext context) {
    final cached = ChatImages.cached(url);
    return ClipRRect(
      borderRadius: BorderRadius.circular(size == null ? 0 : 6),
      child: SizedBox(
        width: size ?? double.infinity,
        height: size ?? double.infinity,
        child: FutureBuilder<Uint8List>(
          future: cached != null ? SynchronousFuture(cached) : ChatImages.load(url),
          builder: (context, snapshot) {
            final bytes = snapshot.data;
            if (bytes == null) return Center(child: fallback);
            return Image.memory(
              bytes,
              fit: BoxFit.cover,
              cacheWidth: size == null ? 1080 : (size! * 3).round(),
              errorBuilder: (_, _, _) => Center(child: fallback),
            );
          },
        ),
      ),
    );
  }
}

Future<void> _showChatTimeSheet(BuildContext context, ChatTimeRef ref) async {
  final now = DateTime.now();
  final at = ref.occurrence(now);
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ListTile(
        leading: const Icon(Icons.schedule_rounded),
        title: Text('${ChatTimeRef.local(at, now)} your time'),
        subtitle: Text(ChatTimeRef.relative(at, now)),
      ),
    ),
  );
}

Future<void> _showChatMoneySheet(BuildContext context, ChatMoneyRef ref) async {
  final bars = Get.isRegistered<ChainStatusController>() ? Get.find<ChainStatusController>().barsAndStatusModel : null;
  final age = DateTime.now().millisecondsSinceEpoch ~/ 1000 - (bars?.serverTime ?? 0);
  final onHand = bars?.moneyOnhand;
  final show = NativeChat.prefs.moneyOnHand && onHand != null && age <= ChatStatus.barsMaxAge.inSeconds;
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ListTile(
        leading: const Icon(Icons.payments_outlined),
        title: Text(ChatMoneyRef.format(ref.amount)),
        subtitle: show ? Text(ref.coverage(onHand)) : null,
      ),
    ),
  );
}

const chatSwipeLook = <ChatSwipeAction, (IconData, String)>{
  ChatSwipeAction.message: (Icons.chat_rounded, 'Chat'),
  ChatSwipeAction.profile: (Icons.person_rounded, 'Profile'),
  ChatSwipeAction.attack: (MdiIcons.pistol, 'Attack'),
  ChatSwipeAction.trade: (Icons.swap_horiz_rounded, 'Trade'),
  ChatSwipeAction.bazaar: (Icons.storefront_rounded, 'Bazaar'),
  ChatSwipeAction.mail: (Icons.email_rounded, 'Mail'),
};

String? chatPlayerUrl(String action, int id) => switch (action) {
  'profile' => 'https://www.torn.com/profiles.php?XID=$id',
  'attack' => 'https://www.torn.com/page.php?sid=attack&user2ID=$id',
  'trade' => 'https://www.torn.com/trade.php#step=start&userID=$id',
  'bazaar' => 'https://www.torn.com/bazaar.php?userId=$id',
  'mail' => 'https://www.torn.com/messages.php#/p=compose&XID=$id',
  _ => null,
};

/// Null when the message takes no swipe
VoidCallback? chatSwipeLeft(ChatMessage m, {required bool mine}) {
  final blocked = mine || m.isSystem || m.sender.id <= 0 || ChatRoom.peerIdOf(m.roomId) != null;
  if (NativeChat.prefs.swipeLeft == ChatSwipeAction.off || blocked) return null;
  return () {
    final action = NativeChat.prefs.swipeLeft;
    if (action == ChatSwipeAction.off) return;
    StatsController.chat.count('swipe');
    final url = chatPlayerUrl(action.name, m.sender.id);
    if (url != null) {
      NativeChat.openLink(url, always: true);
      return;
    }
    NativeChat.controller.addDraftDm(m.sender);
    NativeChat.openQuickWindow(ChatRoom.dmId(m.sender.id));
  };
}

Future<void> showChatPlayerActions(BuildContext context, ChatUser user) async {
  final id = user.id;
  final ignored = NativeChat.prefs.isIgnored(id);
  final friend = NativeChat.prefs.isChatFriend(id);
  final dm = ChatRoom.dmId(id);
  final until = NativeChat.prefs.mutedUntilOf(dm);
  final notes = Get.isRegistered<PlayerNotesController>() ? Get.find<PlayerNotesController>() : null;
  final picked = await showModalBottomSheet<(String, bool)>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      Widget action(ChatSwipeAction a) => Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.of(context).pop((a.name, false)),
          onLongPress: a == ChatSwipeAction.message ? null : () => Navigator.of(context).pop((a.name, true)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                Icon(chatSwipeLook[a]!.$1),
                const SizedBox(height: 4),
                Text(chatSwipeLook[a]!.$2, style: Theme.of(context).textTheme.labelMedium),
              ],
            ),
          ),
        ),
      );
      return SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: ChatAvatar(user: user, size: 40),
                title: Text(NativeChat.prefs.displayName(id, user.name)),
                subtitle: Text(NativeChat.prefs.personOf(id).nickname.isEmpty ? '[$id]' : '${user.name} [$id]'),
              ),
              ChatPlayerCardView(id: id),
              ChatPlayerNotes(id: id, name: user.name),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 4,
                  children: [
                    ChatWatchButton(id: id),
                    ChatPlayerListToggles(id: id),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        action(ChatSwipeAction.message),
                        action(ChatSwipeAction.profile),
                        action(ChatSwipeAction.attack),
                      ],
                    ),
                    Row(
                      children: [
                        action(ChatSwipeAction.trade),
                        action(ChatSwipeAction.bazaar),
                        action(ChatSwipeAction.mail),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  until != null
                      ? Icons.snooze_rounded
                      : (NativeChat.prefs.isMuted(dm)
                            ? Icons.notifications_off_rounded
                            : Icons.notifications_active_rounded),
                ),
                title: const Text('Alerts and mute'),
                subtitle: until == null ? null : Text('Muted until ${chatMuteUntilText(until)}'),
                onTap: () => Navigator.of(context).pop(('alerts', false)),
              ),
              if (notes != null)
                ListTile(
                  leading: const Icon(MdiIcons.notebookEditOutline),
                  title: const Text('Player note'),
                  subtitle: Text(
                    notes.getNoteForPlayer('$id')?.note.trim().isNotEmpty == true
                        ? 'Edit your note, visible everywhere in Torn PDA'
                        : 'Add a note, visible everywhere in Torn PDA',
                  ),
                  onTap: () => Navigator.of(context).pop(('notes', false)),
                ),
              ListTile(
                leading: const Icon(Icons.sticky_note_2_outlined),
                title: const Text('Chat note'),
                subtitle: const Text('Only visible in chat'),
                onTap: () => Navigator.of(context).pop(('chatnote', false)),
              ),
              ListTile(
                leading: Icon(friend ? Icons.person_remove_outlined : Icons.person_add_alt_outlined),
                title: Text(friend ? 'Remove from chat friends' : 'Add to chat friends'),
                subtitle: const Text('Your Chat list in Friends'),
                onTap: () => Navigator.of(context).pop(('chatfriend', false)),
              ),
              if (Get.isRegistered<StakeoutsController>())
                ListTile(
                  leading: const Icon(Icons.playlist_add_rounded),
                  title: const Text('Targets and stakeouts'),
                  subtitle: const Text('Add to your lists or copy ID and link'),
                  onTap: () => Navigator.of(context).pop(('lists', false)),
                ),
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('Customize'),
                subtitle: const Text('Name color, highlight and nickname'),
                onTap: () => Navigator.of(context).pop(('customize', false)),
              ),
              ListTile(
                leading: Icon(ignored ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                title: Text(ignored ? 'Unignore' : 'Ignore'),
                subtitle: Text(ignored ? 'Show their messages again' : 'Hide their messages, only in Torn PDA'),
                onTap: () => Navigator.of(context).pop(('ignore', false)),
              ),
            ],
          ),
        ),
      );
    },
  );
  if (picked == null) return;
  final (action, long) = picked;
  final url = chatPlayerUrl(action, id);
  if (url != null) {
    if (long) {
      await NativeChat.openUrl(url, tap: BrowserTapType.long);
    } else {
      await NativeChat.openLink(url, always: true);
    }
  } else if (action == 'ignore') {
    NativeChat.prefs.setIgnored(id, user.name, !ignored);
  } else if (action == 'chatfriend') {
    NativeChat.prefs.setChatFriend(id, user.name, !friend);
  } else if (context.mounted && action == 'alerts') {
    await showChatRoomAlerts(context, ChatRoom(id: dm, name: user.name, type: ChatRoomType.dm, peer: user));
  } else if (action == 'message') {
    await NativeChat.openDm(user);
  } else if (context.mounted && action == 'notes') {
    await showPlayerNotesDialog(context: context, playerId: '$id', playerName: user.name);
  } else if (context.mounted && action == 'customize') {
    await showChatPersonSettings(context, user);
  } else if (context.mounted && action == 'chatnote') {
    await showChatNoteEditor(context, id, user.name);
  } else if (context.mounted && action == 'lists') {
    await showWebviewDialog<void>(
      context: context,
      builder: (context) => ProfileCheckAddDialog(profileId: id, factionId: null, playerName: user.name),
    );
  }
}
