// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class DevToolsStorageTab extends StatefulWidget {
  final InAppWebViewController? webViewController;
  const DevToolsStorageTab({super.key, required this.webViewController});

  @override
  State<DevToolsStorageTab> createState() => _DevToolsStorageTabState();
}

class _DevToolsStorageTabState extends State<DevToolsStorageTab> {
  static const List<String> _cookiesSortOptions = ['name', 'value'];
  static const List<String> _kvSortOptions = ['key', 'value', 'size'];
  static const List<String> _iosDataSortOptions = ['displayName', 'dataTypes'];
  static const List<String> _httpAuthSortOptions = ['username', 'password'];

  final CookieManager _cookieManager = CookieManager.instance();
  final WebStorageManager? _webStorageManager = !Platform.isWindows ? WebStorageManager.instance() : null;
  final HttpAuthCredentialDatabase? _httpAuthCredentialDatabase =
      !Platform.isWindows ? HttpAuthCredentialDatabase.instance() : null;

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

  @override
  void initState() {
    super.initState();
    _newCookiePathController.text = "/";
    _loadSortPrefs();
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

  Future<Map<String, dynamic>> _getStorageData(dynamic webStorage) async {
    final url = await widget.webViewController?.getUrl();
    final items = await webStorage.getItems();
    return {'origin': url?.origin ?? 'N/A', 'items': items ?? []};
  }

  void _showValueEditDialog(
      {required String title, required String initialValue, required Future<void> Function(String newValue) onSave}) {
    final controller = TextEditingController(text: initialValue);
    showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
              title: Text("Edit $title"),
              content: TextFormField(controller: controller, autofocus: true, maxLines: 5, minLines: 1),
              actions: [
                TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text("Cancel")),
                TextButton(
                    onPressed: () async {
                      await onSave(controller.text);
                      Navigator.of(dialogContext).pop();
                    },
                    child: const Text("Save")),
              ],
            ));
  }

  void _showCookieEditDialog({required Cookie cookie, required Future<void> Function(Cookie updatedCookie) onSave}) {
    final valueController = TextEditingController(text: cookie.value);
    DateTime? expiresDate =
        cookie.expiresDate != null ? DateTime.fromMillisecondsSinceEpoch(cookie.expiresDate!) : null;

    showDialog(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(builder: (context, setDialogState) {
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
                        minLines: 1),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                            context: context,
                            initialDate: expiresDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(9999));
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
                                      style: const TextStyle(fontSize: 16)),
                                ],
                              ),
                            ),
                            if (expiresDate != null)
                              IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () => setDialogState(() => expiresDate = null)),
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
                      Navigator.of(dialogContext).pop();
                    },
                    child: const Text("Save")),
              ],
            );
          });
        });
  }

  void _showActionDialog({
    required String title,
    required String value,
    required Future<void> Function() onDelete,
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
                            })),
                    Tooltip(
                        message: "Copy",
                        child: IconButton(
                            icon: const Icon(Icons.copy_outlined),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: value));
                              Navigator.of(dialogContext).pop();
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Value copied')));
                            })),
                    if (canDelete)
                      Tooltip(
                          message: "Delete",
                          child: IconButton(
                              icon: Icon(Icons.delete_outline, color: Colors.red.shade700),
                              onPressed: () async {
                                await onDelete();
                                Navigator.of(dialogContext).pop();
                              })),
                  ],
                ),
                TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text("CLOSE")),
              ],
            ));
  }

  Widget _buildDataRow(
      {required String keyText, required String valueText, required VoidCallback onCellTap, Widget? deleteWidget}) {
    return InkWell(
      onTap: onCellTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(flex: 3, child: Text(keyText, maxLines: 2, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            Expanded(flex: 5, child: Text(valueText, maxLines: 2, overflow: TextOverflow.ellipsis)),
            SizedBox(width: 48, child: deleteWidget ?? Container()),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageItemRow({
    required String keyText,
    required String valueText,
    required String sizeText,
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
            Expanded(flex: 4, child: Text(valueText, maxLines: 2, overflow: TextOverflow.ellipsis)),
            Expanded(
              flex: 2,
              child: Text(sizeText, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right),
            ),
            SizedBox(width: 48, child: deleteWidget ?? Container()),
          ],
        ),
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

  int _calculateItemSizeBytes(WebStorageItem item) {
    int totalBytes = 0;
    totalBytes += utf8.encode(item.key ?? '').length;
    totalBytes += utf8.encode(item.value).length;
    return totalBytes;
  }

  String _calculateStorageSize(List<WebStorageItem> items) {
    double totalBytes = 0;
    for (var item in items) {
      totalBytes += utf8.encode(item.key ?? '').length;
      totalBytes += utf8.encode(item.value).length;
    }
    return _formatBytes(totalBytes);
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

  Future<void> _onSortLocal(String field) async {
    var nextField = _localSortField;
    var nextAscending = _localAscending;
    if (_localSortField == field) {
      nextAscending = !_localAscending;
    } else {
      nextField = field;
      nextAscending = true;
    }
    setState(() {
      _localSortField = nextField;
      _localAscending = nextAscending;
    });
    final idx = _kvSortOptions.indexOf(nextField);
    await Prefs().setDevToolsStorageLocalSortColumn(idx >= 0 ? idx : 0);
    await Prefs().setDevToolsStorageLocalSortAscending(nextAscending);
  }

  Future<void> _onSortSession(String field) async {
    var nextField = _sessionSortField;
    var nextAscending = _sessionAscending;
    if (_sessionSortField == field) {
      nextAscending = !_sessionAscending;
    } else {
      nextField = field;
      nextAscending = true;
    }
    setState(() {
      _sessionSortField = nextField;
      _sessionAscending = nextAscending;
    });
    final idx = _kvSortOptions.indexOf(nextField);
    await Prefs().setDevToolsStorageSessionSortColumn(idx >= 0 ? idx : 0);
    await Prefs().setDevToolsStorageSessionSortAscending(nextAscending);
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
      _buildWebLocalStorageExpansionTile(),
      _buildWebSessionStorageExpansionTile(),
      if (!Platform.isWindows) _buildHttpAuthCredentialDatabaseExpansionTile(),
      if (Platform.isAndroid) _buildAndroidWebStorageExpansionTile(),
      if (Platform.isIOS || Platform.isMacOS) _buildIOSWebStorageExpansionTile(),
    ];

    return ListView.builder(
      itemCount: entryItems.length,
      itemBuilder: (context, index) => entryItems[index],
    );
  }

  Widget _buildCookiesExpansionTile() {
    return FutureBuilder<List<Cookie>>(
      future: widget.webViewController
          ?.getUrl()
          .then((url) => url == null ? Future.value(<Cookie>[]) : _cookieManager.getCookies(url: url)),
      builder: (context, snapshot) {
        final cookies = snapshot.data ?? [];
        final sortedCookies = [...cookies];
        sortedCookies.sort((a, b) {
          int comparison;
          switch (_cookiesSortField) {
            case 'name':
              comparison = a.name.compareTo(b.name);
              break;
            case 'value':
              comparison = a.value.compareTo(b.value);
              break;
            default:
              comparison = 0;
          }
          return _cookiesAscending ? comparison : -comparison;
        });
        return ExpansionTile(
          key: const ValueKey('cookies'),
          title: const Text("Cookies", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
          children: [
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
            else
              Column(
                children: [
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
                            flex: 3),
                        const SizedBox(width: 8),
                        _buildSortableHeaderCell(
                            title: "Value",
                            isActive: _cookiesSortField == 'value',
                            isAscending: _cookiesAscending,
                            onTap: () => _onSortCookies('value'),
                            flex: 5),
                        const SizedBox(
                            width: 48,
                            child: Center(child: Text("Del", style: TextStyle(fontWeight: FontWeight.bold)))),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1),
                  if (sortedCookies.isEmpty)
                    const Padding(padding: EdgeInsets.all(16.0), child: Text("No cookies for this domain.")),
                  for (final cookie in sortedCookies)
                    _buildDataRow(
                      keyText: cookie.name,
                      valueText: cookie.value,
                      onCellTap: () => _showActionDialog(
                          title: cookie.name,
                          value: cookie.value,
                          expiresDate: cookie.expiresDate != null
                              ? DateTime.fromMillisecondsSinceEpoch(cookie.expiresDate!)
                              : null,
                          canDelete: cookie.isHttpOnly != true,
                          onDelete: () async {
                            final url = await widget.webViewController?.getUrl();
                            if (url == null) return;
                            await _cookieManager.deleteCookie(
                                url: url, name: cookie.name, domain: cookie.domain, path: cookie.path ?? '/');
                            setState(() {});
                          },
                          onEdit: () => _showCookieEditDialog(
                              cookie: cookie,
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
                                    isSecure: updatedCookie.isSecure);
                                setState(() {});
                              })),
                      deleteWidget: cookie.isHttpOnly == true
                          ? Tooltip(
                              message: "HttpOnly cookies cannot be deleted individually",
                              child: Icon(Icons.lock, size: 20, color: Colors.grey.shade600))
                          : IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              onPressed: () async {
                                final url = await widget.webViewController?.getUrl();
                                if (url == null) return;
                                await _cookieManager.deleteCookie(
                                    url: url, name: cookie.name, domain: cookie.domain, path: cookie.path ?? '/');
                                setState(() {});
                              },
                            ),
                    ),
                  _buildNewCookieForm(),
                  const Divider(height: 1, thickness: 1),
                  TextButton(
                    child: const Text("Clear all cookies for this domain"),
                    onPressed: () async {
                      final url = await widget.webViewController?.getUrl();
                      if (url == null) return;
                      await _cookieManager.deleteCookies(url: url);
                      setState(() {});
                    },
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _buildWebLocalStorageExpansionTile() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getStorageData(widget.webViewController!.webStorage.localStorage),
      builder: (context, snapshot) {
        final items = (snapshot.data?['items'] as List<WebStorageItem>?) ?? [];
        final origin = snapshot.data?['origin'] as String? ?? 'Loading...';
        final size = _calculateStorageSize(items);
        final sortedItems = [...items];
        sortedItems.sort((a, b) {
          int comparison;
          switch (_localSortField) {
            case 'key':
              comparison = (a.key ?? '').compareTo(b.key ?? '');
              break;
            case 'value':
              comparison = a.value.compareTo(b.value);
              break;
            case 'size':
              comparison = _calculateItemSizeBytes(a).compareTo(_calculateItemSizeBytes(b));
              break;
            default:
              comparison = 0;
          }
          return _localAscending ? comparison : -comparison;
        });

        return ExpansionTile(
          key: const ValueKey('local_storage'),
          title: const Text("Local Storage", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
          subtitle: Text("Origin: $origin - Size: $size", style: const TextStyle(fontSize: 12, color: Colors.grey)),
          children: [
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
            else
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    color: Theme.of(context).scaffoldBackgroundColor.withAlpha(200),
                    child: Row(
                      children: [
                        _buildSortableHeaderCell(
                            title: "Key",
                            isActive: _localSortField == 'key',
                            isAscending: _localAscending,
                            onTap: () => _onSortLocal('key'),
                            flex: 3),
                        const SizedBox(width: 8),
                        _buildSortableHeaderCell(
                            title: "Value",
                            isActive: _localSortField == 'value',
                            isAscending: _localAscending,
                            onTap: () => _onSortLocal('value'),
                            flex: 4),
                        _buildSortableHeaderCell(
                            title: "Size",
                            isActive: _localSortField == 'size',
                            isAscending: _localAscending,
                            onTap: () => _onSortLocal('size'),
                            flex: 2,
                            alignment: TextAlign.right),
                        const SizedBox(
                            width: 48,
                            child: Center(child: Text("Del", style: TextStyle(fontWeight: FontWeight.bold)))),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1),
                  if (sortedItems.isEmpty)
                    const Padding(padding: EdgeInsets.all(16.0), child: Text("Local Storage is empty.")),
                  for (final item in sortedItems)
                    _buildStorageItemRow(
                        keyText: item.key ?? '',
                        valueText: item.value,
                        sizeText: _formatBytes(_calculateItemSizeBytes(item)),
                        onCellTap: () => _showActionDialog(
                            title: item.key!,
                            value: item.value,
                            onDelete: () async {
                              await widget.webViewController!.webStorage.localStorage.removeItem(key: item.key!);
                              setState(() {});
                            },
                            onEdit: () => _showValueEditDialog(
                                title: item.key!,
                                initialValue: item.value,
                                onSave: (newValue) async {
                                  await widget.webViewController!.webStorage.localStorage
                                      .setItem(key: item.key!, value: newValue);
                                  setState(() {});
                                })),
                        deleteWidget: IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: () async {
                              await widget.webViewController!.webStorage.localStorage.removeItem(key: item.key!);
                              setState(() {});
                            })),
                  _buildAddNewWebStorageItem(
                      formKey: _newLocalStorageItemFormKey,
                      nameController: _newLocalStorageKeyController,
                      valueController: _newLocalStorageValueController,
                      labelName: "Local Item Key",
                      labelValue: "Local Item Value",
                      onAdded: (name, value) async {
                        await widget.webViewController!.webStorage.localStorage.setItem(key: name, value: value);
                        setState(() {});
                      }),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _buildWebSessionStorageExpansionTile() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getStorageData(widget.webViewController!.webStorage.sessionStorage),
      builder: (context, snapshot) {
        final items = (snapshot.data?['items'] as List<WebStorageItem>?) ?? [];
        final origin = snapshot.data?['origin'] as String? ?? 'Loading...';
        final size = _calculateStorageSize(items);
        final sortedItems = [...items];
        sortedItems.sort((a, b) {
          int comparison;
          switch (_sessionSortField) {
            case 'key':
              comparison = (a.key ?? '').compareTo(b.key ?? '');
              break;
            case 'value':
              comparison = a.value.compareTo(b.value);
              break;
            case 'size':
              comparison = _calculateItemSizeBytes(a).compareTo(_calculateItemSizeBytes(b));
              break;
            default:
              comparison = 0;
          }
          return _sessionAscending ? comparison : -comparison;
        });

        return ExpansionTile(
          key: const ValueKey('session_storage'),
          title: const Text("Session Storage", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
          subtitle: Text("Origin: $origin - Size: $size", style: const TextStyle(fontSize: 12, color: Colors.grey)),
          children: [
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
            else
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    color: Theme.of(context).scaffoldBackgroundColor.withAlpha(200),
                    child: Row(
                      children: [
                        _buildSortableHeaderCell(
                            title: "Key",
                            isActive: _sessionSortField == 'key',
                            isAscending: _sessionAscending,
                            onTap: () => _onSortSession('key'),
                            flex: 3),
                        const SizedBox(width: 8),
                        _buildSortableHeaderCell(
                            title: "Value",
                            isActive: _sessionSortField == 'value',
                            isAscending: _sessionAscending,
                            onTap: () => _onSortSession('value'),
                            flex: 4),
                        _buildSortableHeaderCell(
                            title: "Size",
                            isActive: _sessionSortField == 'size',
                            isAscending: _sessionAscending,
                            onTap: () => _onSortSession('size'),
                            flex: 2,
                            alignment: TextAlign.right),
                        const SizedBox(
                            width: 48,
                            child: Center(child: Text("Del", style: TextStyle(fontWeight: FontWeight.bold)))),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1),
                  if (sortedItems.isEmpty)
                    const Padding(padding: EdgeInsets.all(16.0), child: Text("Session Storage is empty.")),
                  for (final item in sortedItems)
                    _buildStorageItemRow(
                        keyText: item.key ?? '',
                        valueText: item.value,
                        sizeText: _formatBytes(_calculateItemSizeBytes(item)),
                        onCellTap: () => _showActionDialog(
                            title: item.key!,
                            value: item.value,
                            onDelete: () async {
                              await widget.webViewController!.webStorage.sessionStorage.removeItem(key: item.key!);
                              setState(() {});
                            },
                            onEdit: () => _showValueEditDialog(
                                title: item.key!,
                                initialValue: item.value,
                                onSave: (newValue) async {
                                  await widget.webViewController!.webStorage.sessionStorage
                                      .setItem(key: item.key!, value: newValue);
                                  setState(() {});
                                })),
                        deleteWidget: IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: () async {
                              await widget.webViewController!.webStorage.sessionStorage.removeItem(key: item.key!);
                              setState(() {});
                            })),
                  _buildAddNewWebStorageItem(
                      formKey: _newSessionStorageItemFormKey,
                      nameController: _newSessionStorageKeyController,
                      valueController: _newSessionStorageValueController,
                      labelName: "Session Item Key",
                      labelValue: "Session Item Value",
                      onAdded: (name, value) async {
                        await widget.webViewController!.webStorage.sessionStorage.setItem(key: name, value: value);
                        setState(() {});
                      }),
                ],
              ),
          ],
        );
      },
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
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null)),
                const SizedBox(width: 10),
                Expanded(
                    child: TextFormField(
                        controller: _newCookieValueController,
                        decoration: const InputDecoration(labelText: "Cookie Value"),
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null)),
              ],
            ),
            Row(
              children: <Widget>[
                Expanded(
                    child: TextFormField(
                        controller: _newCookieDomainController,
                        decoration: const InputDecoration(labelText: "Cookie Domain"))),
                const SizedBox(width: 10),
                Expanded(
                    child: TextFormField(
                        controller: _newCookiePathController,
                        decoration: const InputDecoration(labelText: "Cookie Path"),
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null)),
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
                          lastDate: DateTime(9999));
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
                                    style: const TextStyle(fontSize: 16)),
                              ],
                            ),
                          ),
                          if (_newCookieExpiresDate != null)
                            IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => setState(() => _newCookieExpiresDate = null)),
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
                          expiresDate: _newCookieExpiresDate?.millisecondsSinceEpoch);

                      _newCookieNameController.clear();
                      _newCookieValueController.clear();
                      _newCookieDomainController.clear();
                      _newCookiePathController.text = "/";
                      setState(() {
                        _newCookieIsSecure = false;
                        _newCookieExpiresDate = null;
                      });
                      FocusScope.of(context).unfocus();
                      setState(() {});
                    }
                  },
                ))
          ],
        ),
      ),
    );
  }

  Widget _buildAddNewWebStorageItem(
      {required GlobalKey<FormState> formKey,
      required TextEditingController nameController,
      required TextEditingController valueController,
      required String labelName,
      required String labelValue,
      Function(String name, String value)? onAdded}) {
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
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null)),
                const SizedBox(width: 10),
                Expanded(
                    child: TextFormField(
                        controller: valueController,
                        decoration: InputDecoration(labelText: labelValue),
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null)),
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
              Builder(builder: (context) {
                final origin = urlSnapshot.data!.origin;
                return Column(
                  children: <Widget>[
                    ListTile(
                        title: const Text("Quota"),
                        subtitle: FutureBuilder<int?>(
                            future: _webStorageManager?.getQuotaForOrigin(origin: origin),
                            builder: (context, snapshot) =>
                                Text(snapshot.hasData ? snapshot.data.toString() : "Loading..."))),
                    ListTile(
                        title: const Text("Usage"),
                        subtitle: FutureBuilder<int?>(
                            future: _webStorageManager?.getUsageForOrigin(origin: origin),
                            builder: (context, snapshot) =>
                                Text(snapshot.hasData ? snapshot.data.toString() : "Loading...")),
                        trailing: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () async {
                              await _webStorageManager?.deleteOrigin(origin: origin);
                              setState(() {});
                            })),
                  ],
                );
              }),
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
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("Could not load data."),
                ),
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
                          flex: 3),
                      const SizedBox(width: 8),
                      _buildSortableHeaderCell(
                          title: "Data Types",
                          isActive: _iosDataSortField == 'dataTypes',
                          isAscending: _iosDataAscending,
                          onTap: () => _onSortIosData('dataTypes'),
                          flex: 5),
                      const SizedBox(
                          width: 48, child: Center(child: Text("Del", style: TextStyle(fontWeight: FontWeight.bold)))),
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
                            await _webStorageManager
                                ?.removeDataFor(dataTypes: dataRecord.dataTypes!, dataRecords: [dataRecord]);
                          }
                          setState(() {});
                        }),
                  ),
                SizedBox(
                    width: double.infinity,
                    child: TextButton(
                        child: const Text("Clear all"),
                        onPressed: () async {
                          await _webStorageManager?.removeDataModifiedSince(
                              dataTypes: WebsiteDataType.ALL, date: DateTime.fromMillisecondsSinceEpoch(0));
                          setState(() {});
                        }))
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
            actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))]));
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
              return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()));
            }
            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text("No credentials saved.")));
            }

            return Column(
              children: [
                for (var p in snapshot.data!)
                  Column(
                    children: [
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text("Protection Space: ${p.protectionSpace?.host ?? ""}",
                              style: const TextStyle(fontWeight: FontWeight.bold))),
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
                                flex: 3),
                            const SizedBox(width: 8),
                            _buildSortableHeaderCell(
                                title: "Password",
                                isActive: _httpAuthSortField == 'password',
                                isAscending: _httpAuthAscending,
                                onTap: () => _onSortHttpAuth('password'),
                                flex: 5),
                            const SizedBox(
                                width: 48,
                                child: Center(child: Text("Del", style: TextStyle(fontWeight: FontWeight.bold)))),
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
                                      protectionSpace: p.protectionSpace!, credential: c);
                                }
                                setState(() {});
                              }),
                        ),
                    ],
                  ),
                TextButton(
                    child: const Text("Clear all"),
                    onPressed: () async {
                      await _httpAuthCredentialDatabase?.clearAllAuthCredentials();
                      setState(() {});
                    })
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
