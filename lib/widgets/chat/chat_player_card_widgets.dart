import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chaining/ffscouter/ffscouter_cache_model.dart';
import 'package:torn_pda/providers/chat/chat_link_info.dart';
import 'package:torn_pda/providers/chat/chat_player_card.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/stakeouts_controller.dart';
import 'package:torn_pda/providers/targets_provider.dart';
import 'package:torn_pda/utils/user_helper.dart';
import 'package:torn_pda/widgets/chat/chat_toast.dart';

Color _chatStatusColor(ChatStatusKind kind, ColorScheme scheme) => switch (kind) {
  ChatStatusKind.okay => Colors.green,
  ChatStatusKind.hospital || ChatStatusKind.jail => scheme.error,
  ChatStatusKind.travel => Colors.blue,
  ChatStatusKind.other => scheme.onSurfaceVariant,
};

String chatFfText(FFScouterCacheEntry ff) =>
    '(FFS) ${ff.fairFight == null ? '' : 'FF ${ff.fairFight!.toStringAsFixed(2)} - '}~${ff.displayText}';

/// Rebuilds every second until [until]
class ChatTicking extends StatefulWidget {
  const ChatTicking({super.key, required this.until, required this.builder});

  final DateTime? until;
  final WidgetBuilder builder;

  @override
  State<ChatTicking> createState() => _ChatTickingState();
}

class _ChatTickingState extends State<ChatTicking> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(ChatTicking old) {
    super.didUpdateWidget(old);
    if (old.until != widget.until) _sync();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _sync() {
    _timer?.cancel();
    final until = widget.until;
    if (until == null || !until.isAfter(DateTime.now())) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!until.isAfter(DateTime.now())) timer.cancel();
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

InlineSpan _chatStatusSpan(String status, ChatStatusKind kind, ColorScheme scheme) => TextSpan(
  children: [
    WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Container(
        width: 8,
        height: 8,
        margin: const EdgeInsets.only(right: 5),
        decoration: BoxDecoration(color: _chatStatusColor(kind, scheme), shape: BoxShape.circle),
      ),
    ),
    TextSpan(
      text: status,
      style: const TextStyle(fontWeight: FontWeight.w600),
    ),
  ],
);

class ChatPlayerCardView extends StatefulWidget {
  const ChatPlayerCardView({super.key, required this.id, this.compact = false, this.lastAction = true});

  final int id;
  final bool compact;

  /// Off when the header shows presence
  final bool lastAction;

  @override
  State<ChatPlayerCardView> createState() => _ChatPlayerCardViewState();
}

class _ChatPlayerCardViewState extends State<ChatPlayerCardView> {
  ChatPlayerCard? _card;
  FFScouterCacheEntry? _ff;
  ChatBounty? _bounty;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _card = ChatPlayerCards.peek(widget.id);
    _loading = _card == null;
    _load();
  }

  @override
  void didUpdateWidget(ChatPlayerCardView old) {
    super.didUpdateWidget(old);
    if (old.id != widget.id) {
      _card = ChatPlayerCards.peek(widget.id);
      _ff = null;
      _bounty = null;
      _loading = _card == null;
      _load();
    }
  }

  Future<void> _load() async {
    final id = widget.id;
    final cards = ChatPlayerCards.load(id);
    final ff = widget.compact ? Future<FFScouterCacheEntry?>.value() : _loadFf(id);
    final bounty = widget.compact ? Future<ChatBounty?>.value() : ChatLinkPreviews.bountyOf(id);
    final card = await cards;
    if (mounted && widget.id == id) {
      setState(() {
        _card = card;
        _loading = false;
      });
    }
    final entry = await ff;
    if (mounted && widget.id == id && entry != null) setState(() => _ff = entry);
    final found = await bounty;
    if (mounted && widget.id == id && found != null) setState(() => _bounty = found);
  }

  T? _provided<T>() {
    try {
      return Provider.of<T>(context, listen: false);
    } on ProviderNotFoundException {
      return null;
    }
  }

  Future<FFScouterCacheEntry?> _loadFf(int id) async {
    if (_provided<SettingsProvider>()?.ffScouterEnabledStatus != 1) return null;
    return ChatLinkPreviews.fairFight(id);
  }

  @override
  Widget build(BuildContext context) {
    final card = ChatPlayerCards.peek(widget.id) ?? _card;
    if (card == null) return _loading && !widget.compact ? const _Loading() : const SizedBox.shrink();
    return ChatTicking(
      until: card.clock?.until,
      builder: (context) => widget.compact ? _compact(context, card) : _full(context, card),
    );
  }

  Widget _compact(BuildContext context, ChatPlayerCard card) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final status = card.statusText(now);
    final rest = [
      if (widget.lastAction) card.lastActionText(now),
      card.levelText,
      card.factionTag ?? card.factionName,
    ].whereType<String>();
    return Text.rich(
      TextSpan(
        children: [
          if (status != null) _chatStatusSpan(status, card.kind, theme.colorScheme),
          if (rest.isNotEmpty) TextSpan(text: '${status == null ? '' : ' - '}${rest.join(' - ')}'),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodySmall?.copyWith(
        fontSize: 13,
        letterSpacing: 0.1,
        color: DefaultTextStyle.of(context).style.color ?? theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _full(BuildContext context, ChatPlayerCard card) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final status = card.statusText(now);
    final action = card.lastActionText(now);
    final second = [card.levelText, card.factionText].whereType<String>().join(' - ');
    final third = [card.lifeText, card.ageText].whereType<String>().join(' - ');
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final ff = _ff;
    final ffColor = ff?.ffsColor(UserHelper.totalStats);
    final targeted = _provided<TargetsProvider>()?.allTargets.any((t) => t.playerId == widget.id) ?? false;
    final watched =
        Get.isRegistered<StakeoutsController>() &&
        Get.find<StakeoutsController>().stakeouts.any((s) => s.id == '${widget.id}');
    return Padding(
      padding: const EdgeInsets.fromLTRB(72, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (status != null || action != null)
            Text.rich(
              TextSpan(
                children: [
                  if (status != null) _chatStatusSpan(status, card.kind, theme.colorScheme),
                  if (action != null) TextSpan(text: '${status == null ? '' : ', '}$action'),
                ],
              ),
              style: theme.textTheme.bodyMedium,
            ),
          if (second.isNotEmpty) Text(second, style: muted),
          if (third.isNotEmpty) Text(third, style: muted),
          if (_bounty case final bounty?) Text(bounty.text, style: muted),
          if (card.discordId case final discord?)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Discord linked', style: muted),
                IconButton(
                  tooltip: 'Copy Discord id',
                  visualDensity: VisualDensity.compact,
                  iconSize: 16,
                  icon: const Icon(Icons.copy_rounded),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: discord));
                    chatToast('Discord id copied', seconds: 1);
                  },
                ),
              ],
            ),
          if (ff != null || targeted || watched)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Wrap(
                spacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (ff != null)
                    Text(
                      chatFfText(ff),
                      style: theme.textTheme.bodySmall?.copyWith(color: ffColor, fontWeight: FontWeight.w600),
                    ),
                  if (targeted)
                    Tooltip(
                      message: 'In your targets',
                      child: Icon(Icons.gps_fixed_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant),
                    ),
                  if (watched)
                    Tooltip(
                      message: 'In your stakeouts',
                      child: Icon(Icons.visibility_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading player details',
      child: const Padding(
        padding: EdgeInsets.fromLTRB(72, 0, 16, 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
    );
  }
}
