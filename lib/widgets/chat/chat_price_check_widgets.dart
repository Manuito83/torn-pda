import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:torn_pda/models/chat/chat_bazaar.dart';
import 'package:torn_pda/models/chat/chat_links.dart';
import 'package:torn_pda/models/chat/chat_price_check.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/chat/chat_link_info.dart';
import 'package:torn_pda/providers/chat/chat_player_card.dart';
import 'package:torn_pda/torn-pda-native/stats/stats_controller.dart';
import 'package:torn_pda/providers/inventory_provider.dart';
import 'package:torn_pda/providers/profile_api_calls_controller.dart';
import 'package:torn_pda/utils/html_parser.dart';
import 'package:torn_pda/widgets/chat/chat_bazaar_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

class ChatTradeInsert extends StatefulWidget {
  const ChatTradeInsert({
    super.key,
    required this.roomId,
    required this.text,
    required this.userId,
    required this.color,
    this.mine = false,
  });

  final String roomId;
  final String text;
  final int? userId;
  final Color color;

  /// Hangs from the right edge
  final bool mine;

  static const Key checkKey = ValueKey('bazaar-check');

  @override
  State<ChatTradeInsert> createState() => _ChatTradeInsertState();
}

class _ChatTradeInsertState extends State<ChatTradeInsert> {
  List<ChatPriceCheck> _checks = const [];
  final Set<int> _open = {};
  final Map<int, String> _lines = {};
  final Map<int, int> _have = {};
  Set<int> _named = const {};
  ChatBazaar? _bazaar;
  bool _loading = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _scan();
  }

  @override
  void didUpdateWidget(ChatTradeInsert old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text || old.userId != widget.userId) _scan();
  }

  Future<void> _scan() async {
    final text = widget.text;
    final id = widget.userId;
    _checks = const [];
    _named = const {};
    _bazaar = null;
    _failed = false;
    _loading = false;
    _open.clear();
    _lines.clear();
    _have.clear();
    if (!NativeChat.prefs.priceCheck || !ChatPriceCheck.rooms.contains(widget.roomId)) return;
    final offer = ChatPriceCheck.looksLikeOffer(text);
    final bazaarId =
        NativeChat.prefs.bazaarAnalysis &&
            id != null &&
            id > 0 &&
            !ChatLink.split(text).any((p) => p is ChatLink && p.kind == ChatLinkKind.bazaar)
        ? id
        : null;
    if (!offer && bazaarId == null) return;
    final catalog = await ChatLinkPreviews.catalogItems();
    if (!mounted || text != widget.text) return;
    if (catalog != null) {
      final aliases = NativeChat.prefs.itemAliases;
      final cached = bazaarId == null ? null : ChatPlayerCards.peekJson(bazaarId);
      setState(() {
        if (offer) _checks = ChatPriceCheck.find(text, catalog, aliases);
        if (bazaarId != null) _named = ChatItemRef.namedIds(text, catalog, aliases);
        _bazaar = cached == null ? null : ChatBazaar.parse(cached);
      });
      unawaited(_loadHave(text));
    }
    if (offer && ChatPriceCheck.mentionsPoints(text) && !ChatLinkPreviews.busy) unawaited(_loadPoints(text));
  }

  Future<void> _loadPoints(String text) async {
    final listings = await ChatLinkPreviews.marketListings(
      ChatPriceCheck.pointsId,
      () => mounted && text == widget.text,
    );
    final check = listings == null ? null : ChatPriceCheck.points(text, listings, [for (final c in _checks) c.asked]);
    if (check == null || !mounted || text != widget.text) return;
    setState(() => _checks = [..._checks, check]);
  }

  Future<void> _loadHave(String text) async {
    InventoryProvider? stock;
    try {
      stock = Provider.of<InventoryProvider>(context, listen: false);
    } on ProviderNotFoundException {
      return;
    }
    await stock.restored;
    for (final category in {for (final c in _checks) stock.categoryOf(c.type ?? '')}.nonNulls) {
      if (!stock.isFresh(category)) {
        await ChatLinkPreviews.askInventory(
          category,
          () => stock!.ensureFresh({category}),
          () => mounted && text == widget.text,
        );
      }
      if (!mounted || text != widget.text) return;
      setState(() {
        for (final check in _checks) {
          final owned = stock!.categoryOf(check.type ?? '') == category ? stock.quantity(check.id, category) : null;
          if (owned != null) _have[check.id] = owned;
        }
      });
    }
  }

  Future<void> _toggle(ChatPriceCheck check) async {
    final id = check.id;
    if (_open.remove(id)) return setState(() {});
    setState(() {
      _open.add(id);
      _lines.remove(id);
      if (id == ChatPriceCheck.pointsId) {
        final own = Get.isRegistered<ProfileApiCallsController>()
            ? Get.find<ProfileApiCallsController>().miscModel?.money?.points
            : null;
        if (own != null) _have[id] = own;
      }
    });
    final listings = await ChatLinkPreviews.marketListings(id, () => mounted && _open.contains(id));
    if (!mounted || !_open.contains(id)) return;
    setState(() => _lines[id] = ChatPriceCheck.lowestLine(listings));
  }

  Future<void> _check() async {
    final id = widget.userId!;
    final text = widget.text;
    setState(() => _loading = true);
    final json = await ChatPlayerCards.json(id, retry: _failed);
    if (!mounted || text != widget.text) return;
    final bazaar = json == null ? null : ChatBazaar.parse(json);
    setState(() {
      _loading = false;
      _bazaar = bazaar;
      _failed = bazaar == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.userId;
    final bazaar = _bazaar;
    final bazaarShown =
        NativeChat.prefs.bazaarAnalysis && id != null && _named.isNotEmpty && (bazaar != null || widget.roomId == 'trade');
    if (!NativeChat.prefs.priceCheck || (_checks.isEmpty && !bazaarShown)) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final color = widget.color;
    final mine = widget.mine;
    final accent = theme.colorScheme.primary;
    final edge = accent.withValues(alpha: dark ? 0.55 : 0.4);
    final style = theme.textTheme.bodySmall?.copyWith(color: color);
    final head = theme.textTheme.labelSmall?.copyWith(color: accent, fontSize: 10);
    final hidden = ChatSwiping.of(context);
    const round = Radius.circular(12);
    const tied = Radius.circular(4);
    return IgnorePointer(
      ignoring: hidden,
      child: AnimatedOpacity(
        opacity: hidden ? 0 : 1,
        duration: chatMotion(context, const Duration(milliseconds: 120)),
        child: Padding(
          padding: EdgeInsets.only(left: mine ? 0 : 14, right: mine ? 14 : 0),
          child: Column(
            crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 2,
                height: 8,
                margin: EdgeInsets.only(left: mine ? 0 : 12, right: mine ? 12 : 0),
                color: edge,
              ),
              Material(
                color: accent.withValues(alpha: dark ? 0.16 : 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: mine ? round : tied,
                    topRight: mine ? tied : round,
                    bottomLeft: round,
                    bottomRight: round,
                  ),
                  side: BorderSide(color: edge),
                ),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: Image.asset(
                              'images/icons/pda_icon.png',
                              width: 14,
                              height: 14,
                              errorBuilder: (_, _, _) => const SizedBox.shrink(),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text('Torn PDA', style: head?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              [if (_checks.isNotEmpty) 'Price check', if (bazaarShown) 'Bazaar analysis'].join(' - '),
                              textAlign: TextAlign.end,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: head,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (_checks.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          children: [for (final check in _checks) _chip(theme, check, chatToneColor(check.tone, dark))],
                        ),
                      for (final check in _checks)
                        if (_have[check.id] case final owned?
                            when check.id != ChatPriceCheck.pointsId || _open.contains(check.id))
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 2),
                            child: Text(
                              [
                                if (_checks.length > 1) check.name,
                                ChatPriceCheck.haveLine(owned, check.id == ChatPriceCheck.pointsId ? 'points' : ''),
                              ].join(' - '),
                              style: style,
                            ),
                          ),
                      for (final check in _checks)
                        if (_open.contains(check.id))
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 2),
                            child: _lines[check.id] == null
                                ? const SizedBox(width: 80, child: LinearProgressIndicator(minHeight: 2))
                                : Text(
                                    _checks.length > 1 ? '${check.name} - ${_lines[check.id]}' : _lines[check.id]!,
                                    style: style,
                                  ),
                          ),
                      if (_checks.isNotEmpty && bazaarShown) const SizedBox(height: 6),
                      if (bazaarShown && bazaar != null)
                        ChatBazaarSummary(bazaar: bazaar, userId: id, named: _named, color: color, framed: true)
                      else if (bazaarShown)
                        _checkRow(theme),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _checkRow(ThemeData theme) {
    final color = widget.color;
    return InkWell(
      key: ChatTradeInsert.checkKey,
      onTap: _loading ? null : _check,
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            _loading
                ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: color))
                : Icon(Icons.storefront_rounded, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _failed ? "Couldn't load - try again" : 'Check their bazaar',
                style: theme.textTheme.bodyMedium?.copyWith(color: color),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: color),
          ],
        ),
      ),
    );
  }

  Widget _chip(ThemeData theme, ChatPriceCheck check, Color color) {
    final far = check.tone == ChatPriceTone.off;
    return Semantics(
      container: true,
      label: '${check.name}: ${check.label}${far ? ', far from market, be careful' : ''}',
      button: true,
      expanded: _open.contains(check.id),
      onTap: () => _toggle(check),
      excludeSemantics: true,
      // 48 dp to touch, small chip
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _toggle(check),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          child: Center(
            widthFactor: 1,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _toggle(check),
              child: Ink(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(far ? Icons.warning_amber_rounded : Icons.sell_outlined, size: 15, color: color),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        check.label,
                        style: theme.textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Icon(_open.contains(check.id) ? Icons.expand_less : Icons.expand_more, size: 15, color: color),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Color chatToneColor(ChatPriceTone tone, bool dark) => switch (tone) {
  ChatPriceTone.good => dark ? Colors.green.shade200 : Colors.green.shade800,
  ChatPriceTone.near => dark ? Colors.grey.shade300 : Colors.grey.shade700,
  ChatPriceTone.off => dark ? Colors.red.shade200 : Colors.red.shade800,
};

Future<void> showChatItemSheet(BuildContext context, ChatItemRef item) {
  StatsController.chat.count('item_card');
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => _ChatItemSheet(item: item),
  );
}

class _ChatItemSheet extends StatefulWidget {
  const _ChatItemSheet({required this.item});

  final ChatItemRef item;

  @override
  State<_ChatItemSheet> createState() => _ChatItemSheetState();
}

class _ChatItemSheetState extends State<_ChatItemSheet> {
  String? _lowest;
  int? _have;
  String? _description;
  bool _unfolded = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadHave());
    unawaited(_loadLowest());
    unawaited(_loadDescription());
  }

  Future<void> _loadDescription() async {
    final raw = (await ChatLinkPreviews.catalogItems())?.items?['${widget.item.id}']?.description;
    if (!mounted || raw == null || raw.isEmpty) return;
    // Keepsake quotes arrive garbled
    final fixed = raw.replaceAll('\u00e2\u0080\u0099', "'").replaceAll('\u00e2\u0080\u0094', ' - ');
    setState(() => _description = HtmlParser.fix(fixed).trim());
  }

  Future<void> _loadLowest() async {
    final listings = await ChatLinkPreviews.marketListings(widget.item.id, () => mounted);
    if (mounted) setState(() => _lowest = ChatPriceCheck.lowestLine(listings));
  }

  Future<void> _loadHave() async {
    final InventoryProvider stock;
    try {
      stock = Provider.of<InventoryProvider>(context, listen: false);
    } on ProviderNotFoundException {
      return;
    }
    await stock.restored;
    final category = stock.categoryOf(widget.item.type ?? '');
    if (category == null) return;
    if (!stock.isFresh(category)) {
      await ChatLinkPreviews.askInventory(category, () => stock.ensureFresh({category}), () => mounted);
    }
    if (mounted) setState(() => _have = stock.quantity(widget.item.id, category));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final note = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontStyle: FontStyle.italic,
    );
    final id = widget.item.id;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'images/torn_items/small/${id}_small.png',
                  width: 48,
                  height: 48,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, _, _) => Image.network(
                    'https://www.torn.com/images/items/$id/large.png',
                    width: 48,
                    height: 48,
                    errorBuilder: (_, _, _) => const SizedBox(width: 48, height: 48),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.item.name, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text('Market value: \$${ChatPriceCheck.short(widget.item.market)}', style: style),
                      const SizedBox(height: 4),
                      if (_lowest == null)
                        const SizedBox(width: 80, child: LinearProgressIndicator(minHeight: 2))
                      else
                        Text(_lowest!, style: style),
                      if (_have case final owned?) ...[
                        const SizedBox(height: 4),
                        Text(
                          'You have ${owned == 0 ? 'none' : NumberFormat.decimalPattern('en_US').format(owned)}',
                          style: style,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (_description case final text?) ...[
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, box) {
                  final painter = TextPainter(
                    text: TextSpan(text: text, style: note),
                    maxLines: 3,
                    textDirection: Directionality.of(context),
                    textScaler: MediaQuery.textScalerOf(context),
                  )..layout(maxWidth: box.maxWidth);
                  final long = painter.didExceedMaxLines;
                  painter.dispose();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text,
                        style: note,
                        maxLines: _unfolded ? null : 3,
                        overflow: _unfolded ? null : TextOverflow.ellipsis,
                      ),
                      if (long)
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(44, 32),
                            tapTargetSize: MaterialTapTargetSize.padded,
                          ),
                          onPressed: () => setState(() => _unfolded = !_unfolded),
                          child: Text(_unfolded ? 'Less' : 'More'),
                        ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
