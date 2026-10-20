import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:torn_pda/models/chat/chat_item_aliases.dart';
import 'package:torn_pda/models/chat/chat_item_price.dart';
import 'package:torn_pda/models/chat/chat_money.dart';
import 'package:torn_pda/models/chat/chat_template.dart';
import 'package:torn_pda/models/items_model.dart';
import 'package:torn_pda/providers/chat/chat_link_info.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

final _money = TextInputFormatter.withFunction((_, value) {
  final digits = value.text.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return TextEditingValue.empty;
  final text = ChatMoneyRef.format(int.parse(digits.length > 15 ? digits.substring(0, 15) : digits));
  return TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: text.length),
  );
});

/// Pops with the filled reply
Future<String?> showChatSlotSheet(BuildContext context, String reply, Map<String, String> values, List<String> asks) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => ChatSlotSheet(reply: reply, values: values, asks: asks),
  );
}

class ChatSlotSheet extends StatefulWidget {
  const ChatSlotSheet({super.key, required this.reply, required this.values, required this.asks});

  final String reply;
  final Map<String, String> values;
  final List<String> asks;

  @override
  State<ChatSlotSheet> createState() => _ChatSlotSheetState();
}

class _ChatSlotSheetState extends State<ChatSlotSheet> {
  late final Map<String, TextEditingController> _fields = {
    for (final key in widget.asks) key: TextEditingController(text: widget.values[key] ?? ''),
  };
  late ChatItemPrice? _picked = ChatTemplate.lastItem?.name == widget.values['item'] ? ChatTemplate.lastItem : null;
  ItemsModel? _catalog;
  bool _failed = false;
  int _percent = 0;
  int? _base;

  @override
  void initState() {
    super.initState();
    for (final field in _fields.values) {
      field.addListener(() => setState(() {}));
    }
    if (_fields.containsKey('item')) _loadCatalog();
  }

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    ItemsModel? catalog;
    try {
      catalog = await ChatLinkPreviews.catalogItems();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _catalog = catalog;
      _failed = catalog == null;
    });
  }

  int? get _price => int.tryParse(_fields['price']!.text.replaceAll(RegExp(r'\D'), ''));

  void _nudge(int step) {
    final base = _base ??= _price;
    if (base == null) return;
    _percent = (_percent + step).clamp(-99, 900);
    _fields['price']!.text = ChatMoneyRef.format(ChatTemplate.percent(base, _percent));
  }

  void _resetPercent() {
    final base = _base;
    _percent = 0;
    if (base != null) _fields['price']!.text = ChatMoneyRef.format(base);
  }

  void _pick(ChatItemPrice item) {
    _picked = item;
    _base = null;
    _percent = 0;
    _fields['item']!.text = item.name;
    _fields['price']?.text = item.price;
  }

  Map<String, String> get _filled => {
    for (final e in widget.values.entries)
      if (!_fields.containsKey(e.key)) e.key: e.value,
    for (final e in _fields.entries)
      if (e.value.text.trim().isNotEmpty) e.key: e.value.text.trim(),
  };

  bool get _ready => _fields.values.every((f) => f.text.trim().isNotEmpty);

  void _insert() => Navigator.pop(context, ChatTemplate.fill(widget.reply, _filled).text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final aliases = NativeChat.prefs.itemAliases;
    final query = _fields['item']?.text.trim() ?? '';
    final catalog = _catalog;
    final picked = _picked;
    final results = catalog == null || query == picked?.name
        ? const <ChatItemPrice>[]
        : ChatItemPrice.search(catalog, query, aliases).take(5).toList();
    final alias = ChatItemAliases.itemFor(query, aliases)?.toLowerCase();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Reply: ${widget.reply}', style: theme.textTheme.titleSmall),
              for (final (i, key) in widget.asks.indexed) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _fields[key],
                  autofocus: i == 0,
                  keyboardType: key == 'price' ? TextInputType.number : TextInputType.text,
                  inputFormatters: key == 'price' ? [_money] : null,
                  textInputAction: i == widget.asks.length - 1 ? TextInputAction.done : TextInputAction.next,
                  onSubmitted: i == widget.asks.length - 1 ? (_) => _ready ? _insert() : null : null,
                  onChanged: switch (key) {
                    'item' => (_) => _picked = null,
                    'price' => (_) {
                      _base = null;
                      _percent = 0;
                    },
                    _ => null,
                  },
                  decoration: InputDecoration(
                    labelText: ChatTemplate.slots.firstWhere((s) => s.key == key).label,
                    isDense: true,
                    suffixIcon: key == 'item' ? const Icon(Icons.search_rounded) : null,
                    helperText: switch (key) {
                      'item' when _failed => 'Could not load the item list, type the name',
                      'price' when picked != null && picked.price.isNotEmpty => 'Market value ${picked.price}',
                      _ => null,
                    },
                  ),
                ),
                if (key == 'price')
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        for (final step in const [-5, -1, 1, 5])
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 36),
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: _price == null ? null : () => setState(() => _nudge(step)),
                              child: Text(step > 0 ? '+$step%' : '$step%'),
                            ),
                          ),
                        const Spacer(),
                        if (_percent != 0)
                          ActionChip(
                            label: Text(_percent > 0 ? '+$_percent%' : '$_percent%'),
                            tooltip: 'Back to 0%',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => setState(_resetPercent),
                          ),
                      ],
                    ),
                  ),
                if (key == 'item')
                  for (final item in results)
                    ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      title: Text(
                        alias == item.name.toLowerCase() ? '${item.name} (alias: ${query.toLowerCase()})' : item.name,
                      ),
                      trailing: item.price.isEmpty
                          ? null
                          : Text(
                              item.price,
                              style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                      onTap: () => _pick(item),
                    ),
              ],
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(ChatTemplate.fill(widget.reply, _filled).text),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: _ready ? _insert : null, child: const Text('Insert')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
