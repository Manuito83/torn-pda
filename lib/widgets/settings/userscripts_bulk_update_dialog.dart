// Package imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:provider/provider.dart';

// Project imports:
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/userscripts_provider.dart';

class UserScriptsBulkUpdateDialog extends StatefulWidget {
  const UserScriptsBulkUpdateDialog({super.key});

  @override
  UserScriptsBulkUpdateDialogState createState() => UserScriptsBulkUpdateDialogState();
}

class UserScriptsBulkUpdateDialogState extends State<UserScriptsBulkUpdateDialog> {
  late UserScriptsProvider _userScriptsProvider;
  late ThemeProvider _themeProvider;

  bool _loading = true;
  bool _applying = false;
  List<BulkUpdateReviewItem> _items = [];
  final _expanded = <BulkUpdateReviewItem>{};

  @override
  void initState() {
    super.initState();
    _userScriptsProvider = Provider.of<UserScriptsProvider>(context, listen: false);
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    final items = await _userScriptsProvider.fetchBulkUpdateItems();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      elevation: 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(MdiIcons.earthPlus),
                SizedBox(width: 8),
                Text("Script updates", style: TextStyle(fontSize: 15)),
              ],
            ),
          ),
          if (_loading)
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Text("Fetching scripts..."), SizedBox(height: 20), CircularProgressIndicator()],
              ),
            )
          else if (_items.isEmpty)
            const Expanded(child: Center(child: Text("Everything is up to date!")))
          else
            Expanded(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(8, 0, 8, 8),
                    child: Text(
                      "Select the scripts to update. Updates that request new permissions need to be "
                      "expanded and reviewed before they can be selected.",
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ),
                  ..._items.map(_itemCard),
                ],
              ),
            ),
          if (!_loading) _bottomButtons(),
        ],
      ),
    );
  }

  Widget _itemCard(BulkUpdateReviewItem item) {
    final script = item.script;
    final remote = item.remote;
    final bool isExpanded = _expanded.contains(item);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
        child: Column(
          children: [
            Row(
              children: [
                if (remote != null)
                  SizedBox(
                    width: 32,
                    child: Checkbox(
                      value: item.selected,
                      onChanged: _applying ? null : (value) => _onCheckboxTap(item, value),
                    ),
                  )
                else
                  SizedBox(
                    width: 32,
                    child: GestureDetector(
                      child: const Icon(MdiIcons.earthRemove, color: Colors.red, size: 20),
                      onTap: () => _showBadgeToast(
                        "This script could not be fetched, so it can't be updated right now.\n\n"
                        "${item.fetchError ?? "Unknown error"}",
                        color: Colors.red[800]!,
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(script.name, style: const TextStyle(fontSize: 13)),
                      if (remote != null)
                        Text(
                          "v${script.version} to v${remote.version}",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green[_themeProvider.currentTheme == AppTheme.light ? 800 : 400],
                          ),
                        )
                      else
                        Text(
                          item.fetchError ?? "Could not fetch this script",
                          style: const TextStyle(fontSize: 11, color: Colors.red),
                        ),
                    ],
                  ),
                ),
                if (item.newGrants.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: GestureDetector(
                      child: const Icon(MdiIcons.shieldAlertOutline, color: Colors.orange, size: 18),
                      onTap: () => _showBadgeToast(
                        "This update requests new permissions:\n\n"
                        "${item.newGrants.map((g) => "- $g").join("\n")}\n\n"
                        "Expand the card to review the new source code before selecting it.",
                        color: Colors.orange[800]!,
                      ),
                    ),
                  ),
                if (script.customApiKey.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: GestureDetector(
                      child: const Icon(Icons.key, color: Colors.green, size: 18),
                      onTap: () => _showBadgeToast(
                        "This script has a dedicated API key:\n\n"
                        "${script.customApiKey}\n\n"
                        "It will be kept after the update.",
                      ),
                    ),
                  ),
                if (remote != null)
                  GestureDetector(
                    child: Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 22),
                    onTap: () => _toggleExpanded(item),
                  ),
              ],
            ),
            if (isExpanded && remote != null) _expandedDetails(item),
          ],
        ),
      ),
    );
  }

  Widget _expandedDetails(BulkUpdateReviewItem item) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.newGrants.isNotEmpty) ...[
            const Text(
              "This update requests new permissions (@grant):",
              style: TextStyle(fontSize: 12, color: Colors.orange),
            ),
            const SizedBox(height: 4),
            ...item.newGrants.map((g) => Text("- $g", style: const TextStyle(fontSize: 12, color: Colors.orange))),
            const SizedBox(height: 8),
          ],
          if (item.script.customApiKey.isNotEmpty) ...[
            const Text("Your custom API key for this script will be kept.", style: TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
          ],
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 250),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(6),
              child: Text(item.remote!.source, style: const TextStyle(fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomButtons() {
    final int selectedCount = _items.where((i) => i.selected).length;
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(onPressed: _applying ? null : () => Navigator.of(context).pop(), child: const Text("Close")),
          const SizedBox(width: 8),
          if (_items.isNotEmpty)
            ElevatedButton(
              onPressed: selectedCount == 0 || _applying ? null : _applySelected,
              child: _applying
                  ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text("Update selected ($selectedCount)"),
            ),
        ],
      ),
    );
  }

  void _showBadgeToast(String text, {Color? color}) {
    BotToast.showText(
      text: text,
      textStyle: const TextStyle(fontSize: 14, color: Colors.white),
      contentColor: color ?? Colors.grey[800]!,
      contentPadding: const EdgeInsets.all(10),
      clickClose: true,
      duration: const Duration(seconds: 8),
    );
  }

  void _onCheckboxTap(BulkUpdateReviewItem item, bool? value) {
    if (value == true && item.newGrants.isNotEmpty && !item.reviewed) {
      setState(() => _expanded.add(item));
      item.reviewed = true;
      BotToast.showText(
        text:
            "This update requests new permissions!\n\n"
            "Please review them (and the source code) and tap the checkbox again to select it.",
        textStyle: const TextStyle(fontSize: 14, color: Colors.white),
        contentColor: Colors.orange[800]!,
        duration: const Duration(seconds: 6),
        contentPadding: const EdgeInsets.all(10),
        clickClose: true,
      );
      return;
    }
    setState(() => item.selected = value ?? false);
  }

  void _toggleExpanded(BulkUpdateReviewItem item) {
    setState(() {
      if (!_expanded.remove(item)) {
        _expanded.add(item);
        item.reviewed = true;
      }
    });
  }

  Future<void> _applySelected() async {
    final selected = _items.where((i) => i.selected).toList();
    setState(() => _applying = true);

    final result = await _userScriptsProvider.applyBulkUpdates(selected);

    if (!mounted) return;
    setState(() {
      _applying = false;
      _items.removeWhere((i) => selected.contains(i));
      _expanded.removeWhere((i) => selected.contains(i));
    });

    BotToast.showText(
      text: result.failed == 0
          ? "${result.updated} script${result.updated == 1 ? "" : "s"} updated!"
          : "${result.updated} updated, ${result.failed} failed",
      textStyle: const TextStyle(fontSize: 14, color: Colors.white),
      contentColor: result.failed == 0 ? Colors.green : Colors.orange[800]!,
      duration: const Duration(seconds: 4),
      contentPadding: const EdgeInsets.all(10),
    );

    if (_items.isEmpty) {
      Navigator.of(context).pop();
    }
  }
}
