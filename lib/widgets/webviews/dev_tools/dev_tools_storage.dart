// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/userscripts_provider.dart';
import 'package:torn_pda/utils/script_storage.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/settings/script_storage_quota_dialog.dart';

class DevToolsStorageTab extends StatefulWidget {
  final InAppWebViewController? webViewController;
  const DevToolsStorageTab({super.key, required this.webViewController});

  @override
  State<DevToolsStorageTab> createState() => _DevToolsStorageTabState();
}

class _StorageRow {
  const _StorageRow({
    required this.id,
    required this.keyText,
    required this.valueText,
    this.bytes = 0,
    this.deletable = true,
    this.cookie,
    this.encodedValue,
  });

  final String id;
  final String keyText;
  final String valueText;
  final int bytes;
  final bool deletable;
  final Cookie? cookie;
  final String? encodedValue;
}

class _SectionData {
  List<_StorageRow> rows = const [];
  final Set<String> selected = <String>{};
  bool loading = false;
  bool loaded = false;
  bool selecting = false;
  String origin = '';
}

class _DevToolsStorageTabState extends State<DevToolsStorageTab> {
  static const List<String> _cookiesSortOptions = ['name', 'value'];
  static const List<String> _kvSortOptions = ['key', 'value', 'size'];
  static const List<String> _iosDataSortOptions = ['displayName', 'dataTypes'];
  static const List<String> _httpAuthSortOptions = ['username', 'password'];

  static const String _cookiesId = 'cookies';
  static const String _localId = 'local';
  static const String _sessionId = 'session';

  final CookieManager _cookieManager = CookieManager.instance();
  final WebStorageManager? _webStorageManager = !Platform.isWindows ? WebStorageManager.instance() : null;
  final HttpAuthCredentialDatabase? _httpAuthCredentialDatabase = !Platform.isWindows
      ? HttpAuthCredentialDatabase.instance()
      : null;

  final TextEditingController _newCookieNameController = TextEditingController();
  final TextEditingController _newCookieValueController = TextEditingController();
  final TextEditingController _newCookiePathController = TextEditingController();
  final TextEditingController _newCookieDomainController = TextEditingController();
  final _newCookieFormKey = GlobalKey<FormState>();

  final TextEditingController _newLocalStorageKeyController = TextEditingController();
  final TextEditingController _newLocalStorageValueController = TextEditingController();
  final _newLocalStorageItemFormKey = GlobalKey<FormState>();

  final TextEditingController _newSessionStorageKeyController = TextEditingController();
  final TextEditingController _newSessionStorageValueController = TextEditingController();
  final _newSessionStorageItemFormKey = GlobalKey<FormState>();

  bool _newCookieIsSecure = false;
  DateTime? _newCookieExpiresDate;

  String _cookiesSortField = _cookiesSortOptions.first;
  bool _cookiesAscending = true;

  String _localSortField = _kvSortOptions.first;
  bool _localAscending = true;

  String _sessionSortField = _kvSortOptions.first;
  bool _sessionAscending = true;

  String _iosDataSortField = _iosDataSortOptions.first;
  bool _iosDataAscending = true;

  String _httpAuthSortField = _httpAuthSortOptions.first;
  bool _httpAuthAscending = true;

  static const int _cellPreviewChars = 200;
  static const int _dialogFullChars = 20000;

  final Map<String, _SectionData> _sections = {};

  List<Map<String, dynamic>> _namespaces = const [];
  bool _namespacesLoading = false;
  bool _namespacesLoaded = false;

  @override
  void initState() {
    super.initState();
    _newCookiePathController.text = "/";
    _loadSortPrefs();
    if (widget.webViewController != null) {
      _reloadCookies();
      _reloadWebStorage(local: true);
      _reloadWebStorage(local: false);
      _reloadNamespaces();
    }
  }

  @override
  void dispose() {
    _newCookieNameController.dispose();
    _newCookieValueController.dispose();
    _newCookiePathController.dispose();
    _newCookieDomainController.dispose();
    _newLocalStorageKeyController.dispose();
    _newLocalStorageValueController.dispose();
    _newSessionStorageKeyController.dispose();
    _newSessionStorageValueController.dispose();
    super.dispose();
  }

  _SectionData _sec(String id) => _sections.putIfAbsent(id, () => _SectionData());

  String _nsId(String sid) => 'ns_$sid';

  int _sizeOf(String key, String value) => utf8.encode(key).length + utf8.encode(value).length;

  Future<void> _loadSection(String id, Future<List<_StorageRow>> Function() loader, {String? origin}) async {
    final s = _sec(id);
    if (s.loading) return;
    s.loading = true;
    if (mounted) setState(() {});

    List<_StorageRow> rows;
    try {
      rows = await loader();
    } catch (_) {
      rows = const [];
    }

    if (!mounted) return;
    setState(() {
      s.rows = rows;
      if (origin != null) s.origin = origin;
      s.loading = false;
      s.loaded = true;
      s.selected.retainWhere((selectedId) => rows.any((r) => r.id == selectedId));
      if (s.selected.isEmpty) s.selecting = false;
    });
  }

  Future<void> _reloadCookies() async {
    final url = await widget.webViewController?.getUrl();
    await _loadSection(_cookiesId, () async {
      if (url == null) return <_StorageRow>[];
      final cookies = await _cookieManager.getCookies(url: url);
      return [for (final c in cookies) _cookieRow(c)];
    }, origin: url?.origin ?? 'N/A');
  }

  _StorageRow _cookieRow(Cookie cookie) {
    final value = cookie.value?.toString() ?? '';
    return _StorageRow(
      id: '${cookie.name}|${cookie.domain ?? ''}|${cookie.path ?? ''}',
      keyText: cookie.name,
      valueText: value,
      bytes: _sizeOf(cookie.name, value),
      deletable: cookie.isHttpOnly != true,
      cookie: cookie,
    );
  }

  dynamic _webStorage({required bool local}) =>
      local ? widget.webViewController!.webStorage.localStorage : widget.webViewController!.webStorage.sessionStorage;

  Future<void> _reloadWebStorage({required bool local}) async {
    final url = await widget.webViewController?.getUrl();
    await _loadSection(local ? _localId : _sessionId, () async {
      final items = await _webStorage(local: local).getItems();
      return [
        for (final WebStorageItem item in (items ?? <WebStorageItem>[]))
          _webStorageRow(item.key ?? '', item.value?.toString() ?? ''),
      ];
    }, origin: url?.origin ?? 'N/A');
  }

  _StorageRow _webStorageRow(String key, String value) =>
      _StorageRow(id: key, keyText: key, valueText: value, bytes: _sizeOf(key, value));

  Future<void> _reloadNamespaces() async {
    if (_namespacesLoading) return;
    _namespacesLoading = true;
    if (mounted) setState(() {});

    List<Map<String, dynamic>> rows;
    try {
      rows = await ScriptStorage.namespaces();
    } catch (_) {
      rows = const [];
    }

    if (!mounted) return;
    final sids = {for (final r in rows) r['sid'] as String};
    setState(() {
      _namespaces = rows;
      _namespacesLoading = false;
      _namespacesLoaded = true;
      _sections.removeWhere((id, _) => id.startsWith('ns_') && !sids.contains(id.substring(3)));
    });

    for (final sid in sids) {
      final section = _sections[_nsId(sid)];
      if (section != null && section.loaded) _reloadNamespaceEntries(sid);
    }
  }

  Future<void> _reloadNamespaceEntries(String sid) async {
    await _loadSection(_nsId(sid), () async {
      final entries = await ScriptStorage.entries(sid);
      return [
        for (final e in entries)
          _StorageRow(
            id: e['key'] as String,
            keyText: e['key'] as String,
            valueText: e['value'] as String,
            bytes: e['bytes'] as int,
            encodedValue: e['value'] as String,
          ),
      ];
    });
  }

  void _showSnack(String message, {SnackBarAction? action}) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 5), action: action));
  }

  void _toggleSelection(String sectionId, _StorageRow row) {
    if (!row.deletable) return;
    final s = _sec(sectionId);
    setState(() {
      if (!s.selected.remove(row.id)) s.selected.add(row.id);
      if (s.selected.isEmpty) s.selecting = false;
    });
  }

  void _startSelection(String sectionId, _StorageRow row) {
    if (!row.deletable) return;
    final s = _sec(sectionId);
    setState(() {
      s.selecting = true;
      s.selected.add(row.id);
    });
  }

  List<_StorageRow> _selectedRows(String sectionId) {
    final s = _sec(sectionId);
    return [
      for (final r in s.rows)
        if (s.selected.contains(r.id)) r,
    ];
  }

  Future<void> _deleteRows({
    required String sectionId,
    required List<_StorageRow> rows,
    required Future<void> Function(_StorageRow row) delete,
    required Future<void> Function(_StorageRow row) restore,
  }) async {
    if (rows.isEmpty) return;
    final s = _sec(sectionId);
    final removedIds = {for (final r in rows) r.id};

    setState(() {
      s.rows = [
        for (final r in s.rows)
          if (!removedIds.contains(r.id)) r,
      ];
      s.selected.removeAll(removedIds);
      if (s.selected.isEmpty) s.selecting = false;
    });

    final failed = <_StorageRow>[];
    for (final row in rows) {
      try {
        await delete(row);
      } catch (_) {
        failed.add(row);
      }
    }

    if (!mounted) return;

    if (failed.isNotEmpty) {
      final failedIds = {for (final r in failed) r.id};
      setState(() => s.rows = [...s.rows.where((r) => !failedIds.contains(r.id)), ...failed]);
    }

    final deleted = [
      for (final r in rows)
        if (!failed.contains(r)) r,
    ];
    if (deleted.isEmpty) {
      _showSnack("Could not delete ${failed.length == 1 ? rows.first.keyText : '${failed.length} items'}");
      return;
    }

    final message = deleted.length == 1 ? "Deleted ${deleted.first.keyText}" : "Deleted ${deleted.length} items";
    _showSnack(
      failed.isEmpty ? message : "$message (${failed.length} failed)",
      action: SnackBarAction(label: "UNDO", onPressed: () => _restoreRows(sectionId, deleted, restore)),
    );
  }

  Future<void> _restoreRows(
    String sectionId,
    List<_StorageRow> rows,
    Future<void> Function(_StorageRow row) restore,
  ) async {
    final s = _sec(sectionId);
    final restored = <_StorageRow>[];
    for (final row in rows) {
      try {
        await restore(row);
        restored.add(row);
      } catch (_) {}
    }

    if (!mounted) return;
    final restoredIds = {for (final r in restored) r.id};
    setState(() => s.rows = [...s.rows.where((r) => !restoredIds.contains(r.id)), ...restored]);
    if (restored.length != rows.length) {
      _showSnack("Could not restore ${rows.length - restored.length} of ${rows.length} items");
    }

    if (restored.isNotEmpty && sectionId.startsWith('ns_')) {
      final sid = sectionId.substring(3);
      if (!_namespaces.any((n) => n['sid'] == sid)) _reloadNamespaces();
    }
  }

  Future<bool> _confirm(String title, String message, String confirmLabel) async {
    final answer = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel, style: TextStyle(color: Colors.red.shade700)),
          ),
        ],
      ),
    );
    return answer ?? false;
  }

  Future<void> _deleteCookie(_StorageRow row) async {
    final url = await widget.webViewController?.getUrl();
    if (url == null) throw Exception("No URL");
    final cookie = row.cookie!;
    await _cookieManager.deleteCookie(url: url, name: cookie.name, domain: cookie.domain, path: cookie.path ?? '/');
  }

  Future<void> _restoreCookie(_StorageRow row) async {
    final url = await widget.webViewController?.getUrl();
    if (url == null) throw Exception("No URL");
    final cookie = row.cookie!;
    await _cookieManager.setCookie(
      url: url,
      name: cookie.name,
      value: cookie.value,
      domain: cookie.domain,
      path: cookie.path ?? '/',
      expiresDate: cookie.expiresDate,
      isSecure: cookie.isSecure,
    );
  }

  Future<void> _deleteCookieRows(List<_StorageRow> rows) =>
      _deleteRows(sectionId: _cookiesId, rows: rows, delete: _deleteCookie, restore: _restoreCookie);

  Future<void> _deleteWebStorageRows({required bool local, required List<_StorageRow> rows}) => _deleteRows(
    sectionId: local ? _localId : _sessionId,
    rows: rows,
    delete: (row) => _webStorage(local: local).removeItem(key: row.keyText),
    restore: (row) => _webStorage(local: local).setItem(key: row.keyText, value: row.valueText),
  );

  Future<void> _deleteScriptRows(String sid, List<_StorageRow> rows) => _deleteRows(
    sectionId: _nsId(sid),
    rows: rows,
    delete: (row) => ScriptStorage.deleteKey(sid, row.keyText),
    restore: (row) => ScriptStorage.restoreEntry(sid, row.keyText, row.encodedValue ?? row.valueText, row.bytes),
  );

  String _preview(String value) =>
      value.length > _cellPreviewChars ? '${value.substring(0, _cellPreviewChars)}…' : value;

  void _showValueEditDialog({
    required String title,
    required String initialValue,
    required Future<void> Function(String newValue) onSave,
  }) {
    final controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text("Edit $title"),
        content: initialValue.length > _dialogFullChars
            ? Text(
                "This value is too large to edit here (${_formatBytes(utf8.encode(initialValue).length)}). Delete it or edit it from the userscript instead.",
              )
            : TextFormField(controller: controller, autofocus: true, maxLines: 5, minLines: 1),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text("Cancel")),
          if (initialValue.length <= _dialogFullChars)
            TextButton(
              onPressed: () async {
                await onSave(controller.text);
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              },
              child: const Text("Save"),
            ),
        ],
      ),
    );
  }

  void _showCookieEditDialog({required Cookie cookie, required Future<void> Function(Cookie updatedCookie) onSave}) {
    final valueController = TextEditingController(text: cookie.value?.toString() ?? '');
    DateTime? expiresDate = cookie.expiresDate != null
        ? DateTime.fromMillisecondsSinceEpoch(cookie.expiresDate!)
        : null;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Edit ${cookie.name}", overflow: TextOverflow.ellipsis),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: valueController,
                      decoration: const InputDecoration(labelText: "Value"),
                      maxLines: 3,
                      minLines: 1,
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: expiresDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(9999),
                        );
                        if (picked != null) setDialogState(() => expiresDate = picked);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Expires Date", style: TextStyle(fontSize: 12)),
                                  Text(
                                    expiresDate != null ? expiresDate!.toIso8601String().substring(0, 10) : "Session",
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                            if (expiresDate != null)
                              IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => setDialogState(() => expiresDate = null),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text("Cancel")),
                TextButton(
                  onPressed: () async {
                    final updatedCookie = Cookie(
                      name: cookie.name,
                      value: valueController.text,
                      expiresDate: expiresDate?.millisecondsSinceEpoch,
                      isSecure: cookie.isSecure,
                      domain: cookie.domain,
                      path: cookie.path,
                      isHttpOnly: cookie.isHttpOnly,
                      sameSite: cookie.sameSite,
                    );
                    await onSave(updatedCookie);
                    if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showActionDialog({
    required String title,
    required String value,
    required VoidCallback onDelete,
    required VoidCallback onEdit,
    bool canDelete = true,
    DateTime? expiresDate,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title, style: const TextStyle(fontSize: 18), overflow: TextOverflow.ellipsis),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Value:", style: TextStyle(fontWeight: FontWeight.bold)),
                if (value.length > _dialogFullChars) ...[
                  Text(
                    "Large value (${_formatBytes(utf8.encode(value).length)}). Showing a preview; use Copy for the full value.",
                    style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  SelectableText('${value.substring(0, _dialogFullChars)}…'),
                ] else
                  SelectableText(value),
                if (expiresDate != null) ...[
                  const SizedBox(height: 16),
                  const Text("Expires:", style: TextStyle(fontWeight: FontWeight.bold)),
                  SelectableText(expiresDate.toIso8601String().substring(0, 10)),
                ],
              ],
            ),
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message: "Edit",
                child: IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    onEdit();
                  },
                ),
              ),
              Tooltip(
                message: "Copy",
                child: IconButton(
                  icon: const Icon(Icons.copy_outlined),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: value));
                    Navigator.of(dialogContext).pop();
                    _showSnack("Value copied");
                  },
                ),
              ),
              if (canDelete)
                Tooltip(
                  message: "Delete",
                  child: IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red.shade700),
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      onDelete();
                    },
                  ),
                ),
            ],
          ),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text("CLOSE")),
        ],
      ),
    );
  }

  Widget _buildDataRow({
    required String keyText,
    required String valueText,
    required VoidCallback onCellTap,
    Widget? deleteWidget,
  }) {
    return InkWell(
      onTap: onCellTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(flex: 3, child: Text(keyText, maxLines: 2, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            Expanded(flex: 5, child: Text(_preview(valueText), maxLines: 2, overflow: TextOverflow.ellipsis)),
            SizedBox(width: 48, child: deleteWidget ?? Container()),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectableRow({
    required String sectionId,
    required _StorageRow row,
    required bool showSize,
    required VoidCallback onCellTap,
    required VoidCallback onDelete,
    Widget? lockedWidget,
  }) {
    final s = _sec(sectionId);
    final selected = s.selected.contains(row.id);
    return InkWell(
      onTap: s.selecting ? (row.deletable ? () => _toggleSelection(sectionId, row) : null) : onCellTap,
      onLongPress: row.deletable && !s.selecting ? () => _startSelection(sectionId, row) : null,
      child: Container(
        color: selected ? Theme.of(context).colorScheme.onSurface.withAlpha(18) : null,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(flex: 3, child: Text(row.keyText, maxLines: 2, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            Expanded(
              flex: showSize ? 4 : 5,
              child: Text(_preview(row.valueText), maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
            if (showSize)
              Expanded(
                flex: 2,
                child: Text(
                  _formatBytes(row.bytes),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
            SizedBox(
              width: 48,
              child: !row.deletable
                  ? (lockedWidget ?? Container())
                  : s.selecting
                  ? IconButton(
                      icon: Icon(
                        selected ? Icons.check_box_outlined : Icons.check_box_outline_blank,
                        size: 20,
                        color: selected ? null : Colors.grey.shade600,
                      ),
                      onPressed: () => _toggleSelection(sectionId, row),
                    )
                  : IconButton(icon: const Icon(Icons.delete_outline, size: 20), onPressed: onDelete),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionToolbar({
    required String sectionId,
    required VoidCallback onDeleteSelected,
    VoidCallback? onReload,
    List<Widget> extraActions = const [],
  }) {
    final s = _sec(sectionId);
    if (s.selecting) return _buildSelectionBar(sectionId, onDeleteSelected);

    final canSelect = s.rows.any((r) => r.deletable);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ...extraActions,
          TextButton.icon(
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text("Reload"),
            onPressed: s.loading ? null : onReload,
          ),
          TextButton.icon(
            icon: const Icon(Icons.checklist, size: 18),
            label: const Text("Select"),
            onPressed: canSelect ? () => setState(() => s.selecting = true) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionBar(String sectionId, VoidCallback onDeleteSelected) {
    final s = _sec(sectionId);
    final selectable = [
      for (final r in s.rows)
        if (r.deletable) r,
    ];
    final allSelected = selectable.isNotEmpty && s.selected.length >= selectable.length;
    return Container(
      color: Theme.of(context).colorScheme.onSurface.withAlpha(12),
      padding: const EdgeInsets.only(left: 16.0),
      child: Row(
        children: [
          Expanded(
            child: Text("${s.selected.length} selected", style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => setState(() {
              s.selected.clear();
              if (!allSelected) s.selected.addAll(selectable.map((r) => r.id));
            }),
            child: Text(allSelected ? "NONE" : "ALL"),
          ),
          IconButton(
            tooltip: "Delete selected",
            icon: Icon(Icons.delete_outline, color: s.selected.isEmpty ? null : Colors.red.shade700),
            onPressed: s.selected.isEmpty ? null : onDeleteSelected,
          ),
          IconButton(
            tooltip: "Cancel",
            icon: const Icon(Icons.close),
            onPressed: () => setState(() {
              s.selecting = false;
              s.selected.clear();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteHeaderCell(String sectionId) {
    return SizedBox(
      width: 48,
      child: Center(
        child: Text(_sec(sectionId).selecting ? "Sel" : "Del", style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSortableHeaderCell({
    required String title,
    required bool isActive,
    required bool isAscending,
    required VoidCallback onTap,
    int flex = 1,
    TextAlign alignment = TextAlign.left,
  }) {
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: alignment == TextAlign.right
                ? MainAxisAlignment.end
                : (alignment == TextAlign.center ? MainAxisAlignment.center : MainAxisAlignment.start),
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (isActive) const SizedBox(width: 4),
              if (isActive) Icon(isAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _formatBytes(num bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    var i = (bytes.abs() == 0) ? 0 : (log(bytes.abs()) / log(1024)).floor();
    return "${(bytes / pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}";
  }

  List<_StorageRow> _sortedRows(List<_StorageRow> rows, String field, bool ascending) {
    final sorted = [...rows];
    sorted.sort((a, b) {
      int comparison;
      switch (field) {
        case 'name':
        case 'key':
          comparison = a.keyText.compareTo(b.keyText);
          break;
        case 'value':
          comparison = a.valueText.compareTo(b.valueText);
          break;
        case 'size':
          comparison = a.bytes.compareTo(b.bytes);
          break;
        default:
          comparison = 0;
      }
      return ascending ? comparison : -comparison;
    });
    return sorted;
  }

  Future<void> _onSortCookies(String field) async {
    var nextField = _cookiesSortField;
    var nextAscending = _cookiesAscending;
    if (_cookiesSortField == field) {
      nextAscending = !_cookiesAscending;
    } else {
      nextField = field;
      nextAscending = true;
    }
    setState(() {
      _cookiesSortField = nextField;
      _cookiesAscending = nextAscending;
    });
    final idx = _cookiesSortOptions.indexOf(nextField);
    await Prefs().setDevToolsStorageCookiesSortColumn(idx >= 0 ? idx : 0);
    await Prefs().setDevToolsStorageCookiesSortAscending(nextAscending);
  }

  String _kvSortField(bool local) => local ? _localSortField : _sessionSortField;

  bool _kvAscending(bool local) => local ? _localAscending : _sessionAscending;

  Future<void> _onSortKv(bool local, String field) async {
    var nextField = _kvSortField(local);
    var nextAscending = _kvAscending(local);
    if (nextField == field) {
      nextAscending = !nextAscending;
    } else {
      nextField = field;
      nextAscending = true;
    }
    setState(() {
      if (local) {
        _localSortField = nextField;
        _localAscending = nextAscending;
      } else {
        _sessionSortField = nextField;
        _sessionAscending = nextAscending;
      }
    });
    final idx = _kvSortOptions.indexOf(nextField);
    if (local) {
      await Prefs().setDevToolsStorageLocalSortColumn(idx >= 0 ? idx : 0);
      await Prefs().setDevToolsStorageLocalSortAscending(nextAscending);
    } else {
      await Prefs().setDevToolsStorageSessionSortColumn(idx >= 0 ? idx : 0);
      await Prefs().setDevToolsStorageSessionSortAscending(nextAscending);
    }
  }

  Future<void> _onSortIosData(String field) async {
    var nextField = _iosDataSortField;
    var nextAscending = _iosDataAscending;
    if (_iosDataSortField == field) {
      nextAscending = !_iosDataAscending;
    } else {
      nextField = field;
      nextAscending = true;
    }
    setState(() {
      _iosDataSortField = nextField;
      _iosDataAscending = nextAscending;
    });
    final idx = _iosDataSortOptions.indexOf(nextField);
    await Prefs().setDevToolsStorageIosDataSortColumn(idx >= 0 ? idx : 0);
    await Prefs().setDevToolsStorageIosDataSortAscending(nextAscending);
  }

  Future<void> _onSortHttpAuth(String field) async {
    var nextField = _httpAuthSortField;
    var nextAscending = _httpAuthAscending;
    if (_httpAuthSortField == field) {
      nextAscending = !_httpAuthAscending;
    } else {
      nextField = field;
      nextAscending = true;
    }
    setState(() {
      _httpAuthSortField = nextField;
      _httpAuthAscending = nextAscending;
    });
    final idx = _httpAuthSortOptions.indexOf(nextField);
    await Prefs().setDevToolsStorageHttpAuthSortColumn(idx >= 0 ? idx : 0);
    await Prefs().setDevToolsStorageHttpAuthSortAscending(nextAscending);
  }

  List<dynamic> _sortedHttpCredentials(List<dynamic> credentials) {
    final sorted = [...credentials];
    sorted.sort((a, b) {
      int comparison;
      switch (_httpAuthSortField) {
        case 'username':
          comparison = (a.username ?? '').compareTo(b.username ?? '');
          break;
        case 'password':
          comparison = (a.password ?? '').compareTo(b.password ?? '');
          break;
        default:
          comparison = 0;
      }
      return _httpAuthAscending ? comparison : -comparison;
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.webViewController == null) {
      return const Center(child: Text("WebView not available."));
    }

    var entryItems = <Widget>[
      _buildCookiesExpansionTile(),
      _buildScriptStorageExpansionTile(),
      _buildWebStorageExpansionTile(local: true),
      _buildWebStorageExpansionTile(local: false),
      if (!Platform.isWindows) _buildHttpAuthCredentialDatabaseExpansionTile(),
      if (Platform.isAndroid) _buildAndroidWebStorageExpansionTile(),
      if (Platform.isIOS || Platform.isMacOS) _buildIOSWebStorageExpansionTile(),
    ];

    return ListView.builder(itemCount: entryItems.length, itemBuilder: (context, index) => entryItems[index]);
  }

  int _namespaceUsed(Map<String, dynamic> namespace) {
    final s = _sections[_nsId(namespace['sid'] as String)];
    if (s != null && s.loaded) return s.rows.fold<int>(0, (a, r) => a + r.bytes);
    return namespace['used'] as int;
  }

  int _namespaceCount(Map<String, dynamic> namespace) {
    final s = _sections[_nsId(namespace['sid'] as String)];
    if (s != null && s.loaded) return s.rows.length;
    return namespace['count'] as int;
  }

  Widget _buildScriptStorageExpansionTile() {
    final names = {
      for (final s in Provider.of<UserScriptsProvider>(context, listen: false).userScriptList) s.storageId: s.name,
    };
    final total = _namespaces.fold<int>(0, (a, n) => a + _namespaceUsed(n));

    return ExpansionTile(
      key: const ValueKey('script_storage'),
      title: const Text("Torn PDA Script Storage", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
      subtitle: Text(
        "Native per-script storage - ${_formatBytes(total)} / ${_formatBytes(ScriptStorage.globalCapBytes)}",
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      children: [
        if (_namespacesLoading && !_namespacesLoaded)
          const Center(
            child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()),
          )
        else if (_namespaces.isEmpty)
          const Padding(padding: EdgeInsets.all(16.0), child: Text("No script is using native storage yet."))
        else
          for (final n in _namespaces) _buildScriptStorageNamespace(n, names[n['sid']]),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text("Reload"),
                onPressed: _namespacesLoading ? null : _reloadNamespaces,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScriptStorageNamespace(Map<String, dynamic> namespace, String? name) {
    final sid = namespace['sid'] as String;
    final sectionId = _nsId(sid);
    final s = _sec(sectionId);
    final override = namespace['quota'] as int;
    final quota = override > 0 ? override : ScriptStorage.defaultQuotaBytes;

    return ExpansionTile(
      key: ValueKey(sectionId),
      tilePadding: const EdgeInsets.symmetric(horizontal: 16.0),
      title: Text(name ?? "Unknown script", maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        "${_formatBytes(_namespaceUsed(namespace))} / ${_formatBytes(quota)} · ${_namespaceCount(namespace)} keys",
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      onExpansionChanged: (expanded) {
        if (expanded && !s.loaded && !s.loading) _reloadNamespaceEntries(sid);
      },
      children: [
        _buildSectionToolbar(
          sectionId: sectionId,
          onReload: () => _reloadNamespaceEntries(sid),
          onDeleteSelected: () => _deleteScriptRows(sid, _selectedRows(sectionId)),
          extraActions: [
            TextButton.icon(
              icon: const Icon(Icons.tune, size: 18),
              label: const Text("Set limit"),
              onPressed: () => _editScriptQuota(sid),
            ),
            TextButton.icon(
              icon: Icon(Icons.delete_sweep_outlined, size: 18, color: Colors.red.shade700),
              label: Text("Clear", style: TextStyle(color: Colors.red.shade700)),
              onPressed: () => _clearNamespace(sid, name),
            ),
          ],
        ),
        const Divider(height: 1),
        if (!s.loaded)
          const Padding(padding: EdgeInsets.all(12.0), child: LinearProgressIndicator())
        else if (s.rows.isEmpty)
          const Padding(padding: EdgeInsets.all(12.0), child: Text("Empty."))
        else
          for (final row in s.rows)
            _buildSelectableRow(
              sectionId: sectionId,
              row: row,
              showSize: true,
              onCellTap: () => _showFullTextDialog(row.keyText, row.valueText),
              onDelete: () => _deleteScriptRows(sid, [row]),
            ),
      ],
    );
  }

  Future<void> _editScriptQuota(String sid) async {
    if (await showScriptStorageQuotaDialog(context, sid)) _reloadNamespaces();
  }

  Future<void> _clearNamespace(String sid, String? name) async {
    final confirmed = await _confirm(
      "Clear storage",
      "This deletes every key stored by ${name ?? 'this script'}, and its custom storage limit. It cannot be undone.",
      "CLEAR",
    );
    if (!confirmed) return;

    await ScriptStorage.deleteNamespace(sid);
    if (!mounted) return;
    setState(() {
      _namespaces = [
        for (final n in _namespaces)
          if (n['sid'] != sid) n,
      ];
      _sections.remove(_nsId(sid));
    });
  }

  Widget _buildCookiesExpansionTile() {
    final s = _sec(_cookiesId);
    final sortedCookies = _sortedRows(s.rows, _cookiesSortField, _cookiesAscending);

    return ExpansionTile(
      key: const ValueKey('cookies'),
      title: const Text("Cookies", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
      children: [
        if (s.loading && !s.loaded)
          const Center(
            child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()),
          )
        else
          Column(
            children: [
              _buildSectionToolbar(
                sectionId: _cookiesId,
                onReload: _reloadCookies,
                onDeleteSelected: () => _deleteCookieRows(_selectedRows(_cookiesId)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                color: Theme.of(context).scaffoldBackgroundColor.withAlpha(200),
                child: Row(
                  children: [
                    _buildSortableHeaderCell(
                      title: "Name",
                      isActive: _cookiesSortField == 'name',
                      isAscending: _cookiesAscending,
                      onTap: () => _onSortCookies('name'),
                      flex: 3,
                    ),
                    const SizedBox(width: 8),
                    _buildSortableHeaderCell(
                      title: "Value",
                      isActive: _cookiesSortField == 'value',
                      isAscending: _cookiesAscending,
                      onTap: () => _onSortCookies('value'),
                      flex: 5,
                    ),
                    _buildDeleteHeaderCell(_cookiesId),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1),
              if (sortedCookies.isEmpty)
                const Padding(padding: EdgeInsets.all(16.0), child: Text("No cookies for this domain.")),
              for (final row in sortedCookies)
                _buildSelectableRow(
                  sectionId: _cookiesId,
                  row: row,
                  showSize: false,
                  onDelete: () => _deleteCookieRows([row]),
                  lockedWidget: Tooltip(
                    message: "HttpOnly cookies cannot be deleted individually",
                    child: Icon(Icons.lock, size: 20, color: Colors.grey.shade600),
                  ),
                  onCellTap: () => _showActionDialog(
                    title: row.keyText,
                    value: row.valueText,
                    expiresDate: row.cookie?.expiresDate != null
                        ? DateTime.fromMillisecondsSinceEpoch(row.cookie!.expiresDate!)
                        : null,
                    canDelete: row.deletable,
                    onDelete: () => _deleteCookieRows([row]),
                    onEdit: () => _showCookieEditDialog(
                      cookie: row.cookie!,
                      onSave: (updatedCookie) async {
                        final url = await widget.webViewController?.getUrl();
                        if (url == null) return;
                        await _cookieManager.setCookie(
                          url: url,
                          name: updatedCookie.name,
                          value: updatedCookie.value,
                          domain: updatedCookie.domain,
                          path: updatedCookie.path ?? '/',
                          expiresDate: updatedCookie.expiresDate,
                          isSecure: updatedCookie.isSecure,
                        );
                        _replaceRow(_cookiesId, row.id, _cookieRow(updatedCookie));
                      },
                    ),
                  ),
                ),
              _buildNewCookieForm(),
              const Divider(height: 1, thickness: 1),
              TextButton(
                child: const Text("Clear all cookies for this domain"),
                onPressed: () async {
                  final confirmed = await _confirm(
                    "Clear cookies",
                    "This deletes every cookie for this domain and will log you out. It cannot be undone.",
                    "CLEAR",
                  );
                  if (!confirmed) return;
                  final url = await widget.webViewController?.getUrl();
                  if (url == null) return;
                  await _cookieManager.deleteCookies(url: url);
                  _reloadCookies();
                },
              ),
            ],
          ),
      ],
    );
  }

  void _replaceRow(String sectionId, String oldId, _StorageRow newRow) {
    if (!mounted) return;
    final s = _sec(sectionId);
    setState(() {
      s.rows = [
        for (final r in s.rows)
          if (r.id == oldId) newRow else r,
      ];
      if (s.selected.remove(oldId)) s.selected.add(newRow.id);
    });
  }

  void _upsertRow(String sectionId, _StorageRow newRow) {
    if (!mounted) return;
    final s = _sec(sectionId);
    setState(() {
      s.rows = [...s.rows.where((r) => r.id != newRow.id), newRow];
    });
  }

  Widget _buildWebStorageExpansionTile({required bool local}) {
    final sectionId = local ? _localId : _sessionId;
    final s = _sec(sectionId);
    final title = local ? "Local Storage" : "Session Storage";
    final size = _formatBytes(s.rows.fold<int>(0, (a, r) => a + r.bytes));
    final origin = s.loaded ? s.origin : "Loading...";
    final sortedItems = _sortedRows(s.rows, _kvSortField(local), _kvAscending(local));

    return ExpansionTile(
      key: ValueKey(local ? 'local_storage' : 'session_storage'),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
      subtitle: Text("Origin: $origin - Size: $size", style: const TextStyle(fontSize: 12, color: Colors.grey)),
      children: [
        if (s.loading && !s.loaded)
          const Center(
            child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()),
          )
        else
          Column(
            children: [
              _buildSectionToolbar(
                sectionId: sectionId,
                onReload: () => _reloadWebStorage(local: local),
                onDeleteSelected: () => _deleteWebStorageRows(local: local, rows: _selectedRows(sectionId)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                color: Theme.of(context).scaffoldBackgroundColor.withAlpha(200),
                child: Row(
                  children: [
                    _buildSortableHeaderCell(
                      title: "Key",
                      isActive: _kvSortField(local) == 'key',
                      isAscending: _kvAscending(local),
                      onTap: () => _onSortKv(local, 'key'),
                      flex: 3,
                    ),
                    const SizedBox(width: 8),
                    _buildSortableHeaderCell(
                      title: "Value",
                      isActive: _kvSortField(local) == 'value',
                      isAscending: _kvAscending(local),
                      onTap: () => _onSortKv(local, 'value'),
                      flex: 4,
                    ),
                    _buildSortableHeaderCell(
                      title: "Size",
                      isActive: _kvSortField(local) == 'size',
                      isAscending: _kvAscending(local),
                      onTap: () => _onSortKv(local, 'size'),
                      flex: 2,
                      alignment: TextAlign.right,
                    ),
                    _buildDeleteHeaderCell(sectionId),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1),
              if (sortedItems.isEmpty) Padding(padding: const EdgeInsets.all(16.0), child: Text("$title is empty.")),
              for (final row in sortedItems)
                _buildSelectableRow(
                  sectionId: sectionId,
                  row: row,
                  showSize: true,
                  onDelete: () => _deleteWebStorageRows(local: local, rows: [row]),
                  onCellTap: () => _showActionDialog(
                    title: row.keyText,
                    value: row.valueText,
                    onDelete: () => _deleteWebStorageRows(local: local, rows: [row]),
                    onEdit: () => _showValueEditDialog(
                      title: row.keyText,
                      initialValue: row.valueText,
                      onSave: (newValue) async {
                        await _webStorage(local: local).setItem(key: row.keyText, value: newValue);
                        _replaceRow(sectionId, row.id, _webStorageRow(row.keyText, newValue));
                      },
                    ),
                  ),
                ),
              _buildAddNewWebStorageItem(
                formKey: local ? _newLocalStorageItemFormKey : _newSessionStorageItemFormKey,
                nameController: local ? _newLocalStorageKeyController : _newSessionStorageKeyController,
                valueController: local ? _newLocalStorageValueController : _newSessionStorageValueController,
                labelName: local ? "Local Item Key" : "Session Item Key",
                labelValue: local ? "Local Item Value" : "Session Item Value",
                onAdded: (name, value) async {
                  await _webStorage(local: local).setItem(key: name, value: value);
                  _upsertRow(sectionId, _webStorageRow(name, value));
                },
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildNewCookieForm() {
    return Form(
      key: _newCookieFormKey,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    controller: _newCookieNameController,
                    decoration: const InputDecoration(labelText: "Cookie Name"),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _newCookieValueController,
                    decoration: const InputDecoration(labelText: "Cookie Value"),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    controller: _newCookieDomainController,
                    decoration: const InputDecoration(labelText: "Cookie Domain"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _newCookiePathController,
                    decoration: const InputDecoration(labelText: "Cookie Path"),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      FocusScope.of(context).unfocus();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _newCookieExpiresDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(9999),
                      );
                      if (picked != null) setState(() => _newCookieExpiresDate = picked);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Expires in:", style: TextStyle(fontSize: 12)),
                                Text(
                                  _newCookieExpiresDate != null
                                      ? _newCookieExpiresDate!.toIso8601String().substring(0, 10)
                                      : "Session",
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                          if (_newCookieExpiresDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() => _newCookieExpiresDate = null),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Text("Secure"),
                    Checkbox(value: _newCookieIsSecure, onChanged: (v) => setState(() => _newCookieIsSecure = v!)),
                  ],
                ),
              ],
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                child: const Text("Add Cookie"),
                onPressed: () async {
                  if (_newCookieFormKey.currentState?.validate() ?? false) {
                    final url = await widget.webViewController?.getUrl();
                    if (url == null) return;
                    await _cookieManager.setCookie(
                      url: url,
                      name: _newCookieNameController.text,
                      value: _newCookieValueController.text,
                      domain: _newCookieDomainController.text.isEmpty ? null : _newCookieDomainController.text,
                      isSecure: _newCookieIsSecure,
                      path: _newCookiePathController.text,
                      expiresDate: _newCookieExpiresDate?.millisecondsSinceEpoch,
                    );

                    _newCookieNameController.clear();
                    _newCookieValueController.clear();
                    _newCookieDomainController.clear();
                    _newCookiePathController.text = "/";
                    setState(() {
                      _newCookieIsSecure = false;
                      _newCookieExpiresDate = null;
                    });
                    if (mounted) FocusScope.of(context).unfocus();
                    _reloadCookies();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddNewWebStorageItem({
    required GlobalKey<FormState> formKey,
    required TextEditingController nameController,
    required TextEditingController valueController,
    required String labelName,
    required String labelValue,
    Function(String name, String value)? onAdded,
  }) {
    return Form(
      key: formKey,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: labelName),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: valueController,
                    decoration: InputDecoration(labelText: labelValue),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                child: const Text("Add Item"),
                onPressed: () {
                  if (formKey.currentState?.validate() ?? false) {
                    onAdded?.call(nameController.text, valueController.text);
                    formKey.currentState!.reset();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAndroidWebStorageExpansionTile() {
    return FutureBuilder<WebUri?>(
      future: widget.webViewController?.getUrl(),
      builder: (context, urlSnapshot) {
        return ExpansionTile(
          key: const ValueKey('android_storage'),
          title: const Text("Web Storage Android", style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
          children: [
            if (!urlSnapshot.hasData || urlSnapshot.data == null)
              const Padding(padding: EdgeInsets.all(16.0), child: Text("No URL found"))
            else
              Builder(
                builder: (context) {
                  final origin = urlSnapshot.data!.origin;
                  return Column(
                    children: <Widget>[
                      ListTile(
                        title: const Text("Quota"),
                        subtitle: FutureBuilder<int?>(
                          future: _webStorageManager?.getQuotaForOrigin(origin: origin),
                          builder: (context, snapshot) =>
                              Text(snapshot.hasData ? snapshot.data.toString() : "Loading..."),
                        ),
                      ),
                      ListTile(
                        title: const Text("Usage"),
                        subtitle: FutureBuilder<int?>(
                          future: _webStorageManager?.getUsageForOrigin(origin: origin),
                          builder: (context, snapshot) =>
                              Text(snapshot.hasData ? snapshot.data.toString() : "Loading..."),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () async {
                            await _webStorageManager?.deleteOrigin(origin: origin);
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildIOSWebStorageExpansionTile() {
    return ExpansionTile(
      key: const ValueKey('ios_storage'),
      title: const Text("Web Storage iOS", style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
      children: [
        FutureBuilder<List<WebsiteDataRecord>>(
          future: _webStorageManager?.fetchDataRecords(dataTypes: WebsiteDataType.ALL),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const Center(
                child: Padding(padding: EdgeInsets.all(16.0), child: Text("Could not load data.")),
              );
            }

            final dataRecords = [...snapshot.data!];
            dataRecords.sort((a, b) {
              int comparison;
              switch (_iosDataSortField) {
                case 'displayName':
                  comparison = (a.displayName ?? '').compareTo(b.displayName ?? '');
                  break;
                case 'dataTypes':
                  comparison = (a.dataTypes?.join(", ") ?? '').compareTo(b.dataTypes?.join(", ") ?? '');
                  break;
                default:
                  comparison = 0;
              }
              return _iosDataAscending ? comparison : -comparison;
            });

            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  color: Theme.of(context).scaffoldBackgroundColor.withAlpha(200),
                  child: Row(
                    children: [
                      _buildSortableHeaderCell(
                        title: "Display Name",
                        isActive: _iosDataSortField == 'displayName',
                        isAscending: _iosDataAscending,
                        onTap: () => _onSortIosData('displayName'),
                        flex: 3,
                      ),
                      const SizedBox(width: 8),
                      _buildSortableHeaderCell(
                        title: "Data Types",
                        isActive: _iosDataSortField == 'dataTypes',
                        isAscending: _iosDataAscending,
                        onTap: () => _onSortIosData('dataTypes'),
                        flex: 5,
                      ),
                      const SizedBox(
                        width: 48,
                        child: Center(
                          child: Text("Del", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1),
                for (final dataRecord in dataRecords)
                  _buildDataRow(
                    keyText: dataRecord.displayName ?? '',
                    valueText: dataRecord.dataTypes?.join(", ") ?? '',
                    onCellTap: () =>
                        _showFullTextDialog(dataRecord.displayName ?? 'Item', dataRecord.dataTypes?.join(",\n") ?? ''),
                    deleteWidget: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () async {
                        if (dataRecord.dataTypes != null) {
                          await _webStorageManager?.removeDataFor(
                            dataTypes: dataRecord.dataTypes!,
                            dataRecords: [dataRecord],
                          );
                        }
                        setState(() {});
                      },
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    child: const Text("Clear all"),
                    onPressed: () async {
                      await _webStorageManager?.removeDataModifiedSince(
                        dataTypes: WebsiteDataType.ALL,
                        date: DateTime.fromMillisecondsSinceEpoch(0),
                      );
                      setState(() {});
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _showFullTextDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: SelectableText(content)),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
      ),
    );
  }

  Widget _buildHttpAuthCredentialDatabaseExpansionTile() {
    return ExpansionTile(
      key: const ValueKey('http_auth'),
      title: const Text("Http Auth Credentials", style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
      children: [
        FutureBuilder<List<URLProtectionSpaceHttpAuthCredentials>>(
          future: _httpAuthCredentialDatabase?.getAllAuthCredentials(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Padding(padding: EdgeInsets.all(16.0), child: Text("No credentials saved.")),
              );
            }

            return Column(
              children: [
                for (var p in snapshot.data!)
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          "Protection Space: ${p.protectionSpace?.host ?? ""}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        color: Theme.of(context).scaffoldBackgroundColor.withAlpha(200),
                        child: Row(
                          children: [
                            _buildSortableHeaderCell(
                              title: "Username",
                              isActive: _httpAuthSortField == 'username',
                              isAscending: _httpAuthAscending,
                              onTap: () => _onSortHttpAuth('username'),
                              flex: 3,
                            ),
                            const SizedBox(width: 8),
                            _buildSortableHeaderCell(
                              title: "Password",
                              isActive: _httpAuthSortField == 'password',
                              isAscending: _httpAuthAscending,
                              onTap: () => _onSortHttpAuth('password'),
                              flex: 5,
                            ),
                            const SizedBox(
                              width: 48,
                              child: Center(
                                child: Text("Del", style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, thickness: 1),
                      for (var c in _sortedHttpCredentials(p.credentials == null ? <dynamic>[] : p.credentials!))
                        _buildDataRow(
                          keyText: c.username ?? '',
                          valueText: '••••••••',
                          onCellTap: () =>
                              _showFullTextDialog(c.username ?? 'Credential', "Password: ${c.password ?? ''}"),
                          deleteWidget: IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: () async {
                              if (p.protectionSpace != null) {
                                await _httpAuthCredentialDatabase?.removeHttpAuthCredential(
                                  protectionSpace: p.protectionSpace!,
                                  credential: c,
                                );
                              }
                              setState(() {});
                            },
                          ),
                        ),
                    ],
                  ),
                TextButton(
                  child: const Text("Clear all"),
                  onPressed: () async {
                    await _httpAuthCredentialDatabase?.clearAllAuthCredentials();
                    setState(() {});
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _loadSortPrefs() async {
    final prefs = Prefs();
    final cookiesColumn = await prefs.getDevToolsStorageCookiesSortColumn();
    final cookiesAscending = await prefs.getDevToolsStorageCookiesSortAscending();
    final localColumn = await prefs.getDevToolsStorageLocalSortColumn();
    final localAscending = await prefs.getDevToolsStorageLocalSortAscending();
    final sessionColumn = await prefs.getDevToolsStorageSessionSortColumn();
    final sessionAscending = await prefs.getDevToolsStorageSessionSortAscending();
    final iosColumn = await prefs.getDevToolsStorageIosDataSortColumn();
    final iosAscending = await prefs.getDevToolsStorageIosDataSortAscending();
    final httpAuthColumn = await prefs.getDevToolsStorageHttpAuthSortColumn();
    final httpAuthAscending = await prefs.getDevToolsStorageHttpAuthSortAscending();

    if (!mounted) return;

    setState(() {
      _cookiesSortField = _fieldFromIndex(_cookiesSortOptions, cookiesColumn, _cookiesSortOptions.first);
      _cookiesAscending = cookiesAscending;
      _localSortField = _fieldFromIndex(_kvSortOptions, localColumn, _kvSortOptions.first);
      _localAscending = localAscending;
      _sessionSortField = _fieldFromIndex(_kvSortOptions, sessionColumn, _kvSortOptions.first);
      _sessionAscending = sessionAscending;
      _iosDataSortField = _fieldFromIndex(_iosDataSortOptions, iosColumn, _iosDataSortOptions.first);
      _iosDataAscending = iosAscending;
      _httpAuthSortField = _fieldFromIndex(_httpAuthSortOptions, httpAuthColumn, _httpAuthSortOptions.first);
      _httpAuthAscending = httpAuthAscending;
    });
  }

  String _fieldFromIndex(List<String> values, int index, String fallback) {
    if (index < 0 || index >= values.length) return fallback;
    return values[index];
  }
}
