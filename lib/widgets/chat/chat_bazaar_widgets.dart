import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:torn_pda/models/chat/chat_bazaar.dart';
import 'package:torn_pda/models/chat/chat_price_check.dart';
import 'package:torn_pda/models/profile/other_profile_model/other_profile_pda.dart';
import 'package:torn_pda/torn-pda-native/stats/stats_controller.dart';
import 'package:torn_pda/widgets/chat/chat_link_widgets.dart';
import 'package:torn_pda/widgets/chat/chat_price_check_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

/// Summary and named items, tap for all
class ChatBazaarSummary extends StatelessWidget {
  const ChatBazaarSummary({
    super.key,
    required this.bazaar,
    required this.userId,
    required this.named,
    required this.color,
    this.framed = false,
  });

  final ChatBazaar bazaar;
  final int userId;
  final Set<int> named;
  final Color color;

  /// Icon on the left, chevron on the far right
  final bool framed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final soft = color.withValues(alpha: 0.8);
    final tappable = bazaar.open && bazaar.items.isNotEmpty;
    return InkWell(
      onTap: tappable ? () => showChatBazaarSheet(context, userId: userId, bazaar: bazaar, named: named) : null,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: framed ? 6 : 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: framed ? MainAxisSize.max : MainAxisSize.min,
              children: [
                if (framed) ...[Icon(Icons.storefront_rounded, size: 18, color: color), const SizedBox(width: 8)],
                Flexible(
                  fit: framed ? FlexFit.tight : FlexFit.loose,
                  child: Text(
                    bazaar.summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(color: color),
                  ),
                ),
                if (tappable) Icon(Icons.chevron_right_rounded, size: 18, color: color),
              ],
            ),
            for (final item in bazaar.named(named))
              Padding(
                padding: EdgeInsets.only(left: framed ? 26 : 0),
                child: Text(
                  ChatBazaar.line(item),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: switch (ChatBazaar.tone(item)) {
                      null || ChatPriceTone.near => soft,
                      final tone => chatToneColor(tone, dark),
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> showChatBazaarSheet(
  BuildContext context, {
  required int userId,
  required ChatBazaar bazaar,
  Set<int> named = const {},
}) {
  StatsController.chat.count('bazaar');
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ChatBazaarSheet(userId: userId, bazaar: bazaar, named: named),
  );
}

class _ChatBazaarSheet extends StatefulWidget {
  const _ChatBazaarSheet({required this.userId, required this.bazaar, required this.named});

  final int userId;
  final ChatBazaar bazaar;
  final Set<int> named;

  @override
  State<_ChatBazaarSheet> createState() => _ChatBazaarSheetState();
}

class _ChatBazaarSheetState extends State<_ChatBazaarSheet> {
  static final NumberFormat _money = NumberFormat.decimalPattern('en_US');
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final query = _query.trim().toLowerCase();
    final rows = [
      for (final item in widget.bazaar.ordered(widget.named))
        if (query.isEmpty || (item.name ?? '').toLowerCase().contains(query)) item,
    ];
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: SizedBox(
        height: (MediaQuery.sizeOf(context).height - keyboard) * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.bazaar.summary, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (v) => setState(() => _query = v),
                          decoration: const InputDecoration(
                            isDense: true,
                            hintText: 'Search items',
                            prefixIcon: Icon(Icons.search_rounded, size: 20),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonal(
                        onPressed: () => NativeChat.openLink(chatPlayerUrl('bazaar', widget.userId)!, always: true),
                        child: const Text('Open bazaar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
                itemCount: rows.length,
                itemBuilder: (context, i) => _row(theme, dark, rows[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(ThemeData theme, bool dark, BazaarItem item) {
    final ratio = ChatBazaar.ratio(item);
    final tone = ChatBazaar.tone(item);
    final muted = theme.colorScheme.onSurfaceVariant;
    return ListTile(
      dense: true,
      onTap: () => NativeChat.openLink(chatPlayerUrl('bazaar', widget.userId)!, always: true, fill: item.name),
      onLongPress: () => NativeChat.openUrl(chatPlayerUrl('bazaar', widget.userId)!),
      title: Text(item.name ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('x${item.quantity} - \$${_money.format(item.price ?? 0)}'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (ratio != null)
            Text(
              ChatBazaar.vs(ratio),
              style: theme.textTheme.labelMedium?.copyWith(
                color: tone == null ? muted : chatToneColor(tone, dark),
                fontWeight: FontWeight.w600,
              ),
            ),
          Text('Open in bazaar', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary)),
        ],
      ),
    );
  }
}
