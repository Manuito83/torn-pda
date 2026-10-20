import 'package:flutter/material.dart';
import 'package:torn_pda/models/chat/chat_item_aliases.dart';
import 'package:torn_pda/widgets/chat/chat_alias_widgets.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

class ChatItemNicknamesPage extends StatefulWidget {
  const ChatItemNicknamesPage({super.key});

  @override
  State<ChatItemNicknamesPage> createState() => _ChatItemNicknamesPageState();
}

class _ChatItemNicknamesPageState extends State<ChatItemNicknamesPage> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prefs = NativeChat.prefs;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Item nicknames'),
        actions: [
          ChatExportMenu(
            tooltip: 'Export nicknames',
            text: () => ChatItemAliases.export(prefs.itemAliases),
            copied: 'Nicknames copied',
          ),
          IconButton(
            tooltip: 'Import nicknames',
            icon: const Icon(Icons.download_rounded),
            onPressed: () => showDialog<void>(context: context, builder: (_) => ChatImportDialog.itemNicknames()),
          ),
        ],
      ),
      floatingActionButton: ListenableBuilder(
        listenable: prefs,
        builder: (context, _) => FloatingActionButton(
          tooltip: 'Add nickname',
          onPressed: prefs.itemAliases.length >= ChatItemAliases.max
              ? null
              : () => showDialog<void>(context: context, builder: (_) => const ChatItemAliasAddDialog()),
          child: const Icon(Icons.add_rounded),
        ),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([prefs, _search]),
        builder: (context, _) {
          final query = _search.text.trim().toLowerCase();
          final shown = [
            for (final a in prefs.itemAliases)
              if (a.alias.contains(query) || a.item.toLowerCase().contains(query)) a,
          ];
          return ListView(
            padding: const EdgeInsets.only(bottom: 88),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(
                  'Short names players use, like xans for Xanax. Price check and Item price recognize them',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: 'Search nicknames or items',
                    prefixIcon: const Icon(Icons.search_rounded),
                    isDense: true,
                    suffixIcon: query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: _search.clear,
                          ),
                  ),
                ),
              ),
              if (shown.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    query.isEmpty ? 'No nicknames yet' : 'Nothing matches',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              for (final a in shown)
                ListTile(
                  title: Text(a.alias),
                  subtitle: Text(a.item),
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (_) => ChatItemAliasAddDialog(editing: a),
                  ),
                  trailing: IconButton(
                    tooltip: 'Remove nickname ${a.alias}',
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () => prefs.removeItemAlias(a),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
