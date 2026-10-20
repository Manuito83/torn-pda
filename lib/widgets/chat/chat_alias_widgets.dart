import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:torn_pda/models/chat/chat_item_aliases.dart';
import 'package:torn_pda/models/chat/chat_item_price.dart';
import 'package:torn_pda/models/items_model.dart';
import 'package:torn_pda/providers/chat/chat_link_info.dart';
import 'package:torn_pda/widgets/chat/chat_toast.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

class ChatExportMenu extends StatelessWidget {
  const ChatExportMenu({super.key, required this.tooltip, required this.text, required this.copied});

  final String tooltip;
  final String Function() text;
  final String copied;

  Future<void> _export(BuildContext context, String how) async {
    final content = text();
    final box = context.findRenderObject() as RenderBox?;
    if (how == 'share') {
      await SharePlus.instance.share(
        ShareParams(text: content, sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size),
      );
    } else {
      await Clipboard.setData(ClipboardData(text: content));
      chatToast(copied, seconds: 1);
    }
  }

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    tooltip: tooltip,
    icon: const Icon(Icons.ios_share_rounded),
    onSelected: (how) => _export(context, how),
    itemBuilder: (_) => const [
      PopupMenuItem(value: 'share', child: Text('Share as text')),
      PopupMenuItem(value: 'copy', child: Text('Copy to clipboard')),
    ],
  );
}

class ChatItemAliasAddDialog extends StatefulWidget {
  const ChatItemAliasAddDialog({super.key, this.editing});

  final ChatItemAlias? editing;

  @override
  State<ChatItemAliasAddDialog> createState() => _ChatItemAliasAddDialogState();
}

class _ChatItemAliasAddDialogState extends State<ChatItemAliasAddDialog> {
  late final TextEditingController _alias = TextEditingController(text: widget.editing?.alias);
  final TextEditingController _search = TextEditingController();
  ItemsModel? _catalog;
  bool _failed = false;
  late String? _item = widget.editing?.item;

  @override
  void initState() {
    super.initState();
    ChatLinkPreviews.catalogItems().then<ItemsModel?>((c) => c, onError: (_) => null).then((catalog) {
      if (!mounted) return;
      setState(() {
        _catalog = catalog;
        _failed = catalog == null;
      });
    });
  }

  @override
  void dispose() {
    _alias.dispose();
    _search.dispose();
    super.dispose();
  }

  void _save() {
    final saved = NativeChat.prefs.addItemAlias(_alias.text, _item!, replacing: widget.editing);
    if (saved) {
      Navigator.pop(context);
    } else {
      chatToast('That nickname is already used', seconds: 3);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catalog = _catalog;
    final results = catalog == null ? const <ChatItemPrice>[] : ChatItemPrice.search(catalog, _search.text);
    final ready = ChatItemAliases.cleanAlias(_alias.text) != null && _item != null;
    return AlertDialog(
      title: Text(widget.editing == null ? 'Add nickname' : 'Edit nickname'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _alias,
                autofocus: true,
                maxLength: 24,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(labelText: 'Nickname', hintText: 'xans'),
              ),
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(labelText: 'Search the item', prefixIcon: Icon(Icons.search_rounded)),
              ),
              if (_failed)
                const Padding(padding: EdgeInsets.only(top: 8), child: Text('Could not load the item list'))
              else if (catalog == null)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else
                Wrap(
                  spacing: 6,
                  children: [
                    for (final r in results)
                      ChoiceChip(
                        label: Text(r.name),
                        selected: _item == r.name,
                        onSelected: (_) => setState(() => _item = r.name),
                      ),
                  ],
                ),
              if (_item != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Picked: $_item', style: theme.textTheme.bodySmall),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(onPressed: ready ? _save : null, child: const Text('Save')),
      ],
    );
  }
}

/// Returns an error, or null
typedef ChatImportAction = (String label, String? Function(String text) run);

class ChatImportDialog extends StatefulWidget {
  const ChatImportDialog({
    super.key,
    required this.title,
    required this.hint,
    required this.label,
    required this.actions,
  });

  ChatImportDialog.itemNicknames({super.key})
    : title = 'Import nicknames',
      hint = 'Paste the exported text or pick a file. Nicknames you already have are kept',
      label = 'Nicknames',
      actions = [('Import', _importNicknames)];

  final String title;
  final String hint;
  final String label;
  final List<ChatImportAction> actions;

  static Future<String?> Function() pickFile = _pickFile;

  static Future<String?> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json', 'txt'],
      withData: true,
    );
    final bytes = result?.files.firstOrNull?.bytes;
    return bytes == null || bytes.length > 200000 ? null : utf8.decode(bytes, allowMalformed: true);
  }

  static String? _importNicknames(String text) {
    final parsed = ChatItemAliases.parse(text);
    if (parsed == null) return 'This is not a list of nicknames';
    final added = NativeChat.prefs.importItemAliases(parsed.$1);
    final skipped = parsed.$2;
    chatToast('$added added${skipped > 0 ? ', $skipped skipped (invalid)' : ''}', seconds: 3);
    return null;
  }

  @override
  State<ChatImportDialog> createState() => _ChatImportDialogState();
}

class _ChatImportDialogState extends State<ChatImportDialog> {
  final TextEditingController _text = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _file() async {
    String? content;
    try {
      content = await ChatImportDialog.pickFile();
    } catch (_) {
      content = null;
    }
    if (!mounted || content == null) return;
    setState(() {
      _text.text = content!;
      _error = null;
    });
  }

  void _run(String? Function(String text) action) {
    final error = action(_text.text);
    if (error != null) return setState(() => _error = error);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final empty = _text.text.trim().isEmpty;
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.hint),
            const SizedBox(height: 8),
            TextField(
              controller: _text,
              minLines: 3,
              maxLines: 6,
              onChanged: (_) => setState(() => _error = null),
              decoration: InputDecoration(labelText: widget.label, errorText: _error),
            ),
            TextButton.icon(
              icon: const Icon(Icons.folder_open_rounded),
              label: const Text('Choose file'),
              onPressed: _file,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        for (final (label, run) in widget.actions)
          TextButton(onPressed: empty ? null : () => _run(run), child: Text(label)),
      ],
    );
  }
}
