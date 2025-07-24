import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class DevToolsStorageTab extends StatefulWidget {
  final InAppWebViewController? webViewController;
  const DevToolsStorageTab({super.key, required this.webViewController});

  @override
  State<DevToolsStorageTab> createState() => _DevToolsStorageTabState();
}

class _DevToolsStorageTabState extends State<DevToolsStorageTab> {
  final CookieManager _cookieManager = CookieManager.instance();
  final WebStorageManager? _webStorageManager = !Platform.isWindows ? WebStorageManager.instance() : null;
  final HttpAuthCredentialDatabase? _httpAuthCredentialDatabase =
      !Platform.isWindows ? HttpAuthCredentialDatabase.instance() : null;

  List<Cookie> _cookies = [];
  bool _isCookiesLoading = false;

  List<WebStorageItem> _localStorageItems = [];
  bool _isLocalStorageLoading = false;

  List<WebStorageItem> _sessionStorageItems = [];
  bool _isSessionStorageLoading = false;

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

  @override
  void initState() {
    super.initState();
    _newCookiePathController.text = "/";
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

  Future<void> _fetchCookies() async {
    if (_isCookiesLoading) return;
    setState(() => _isCookiesLoading = true);
    final url = await widget.webViewController?.getUrl();
    List<Cookie> cookies = [];
    if (url != null) {
      cookies = await _cookieManager.getCookies(url: url);
    }
    if (mounted) {
      setState(() {
        _cookies = cookies;
        _isCookiesLoading = false;
      });
    }
  }

  Future<void> _fetchLocalStorage() async {
    if (_isLocalStorageLoading) return;
    setState(() => _isLocalStorageLoading = true);
    final items = await widget.webViewController?.webStorage.localStorage.getItems();
    if (mounted) {
      setState(() {
        _localStorageItems = items ?? [];
        _isLocalStorageLoading = false;
      });
    }
  }

  Future<void> _fetchSessionStorage() async {
    if (_isSessionStorageLoading) return;
    setState(() => _isSessionStorageLoading = true);
    final items = await widget.webViewController?.webStorage.sessionStorage.getItems();
    if (mounted) {
      setState(() {
        _sessionStorageItems = items ?? [];
        _isSessionStorageLoading = false;
      });
    }
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

  Widget _buildTableHeader(String col1, String col2, String col3) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      color: Theme.of(context).scaffoldBackgroundColor.withAlpha(200),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(col1, style: const TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(width: 8),
          Expanded(flex: 5, child: Text(col2, style: const TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 48, child: Center(child: Text(col3, style: const TextStyle(fontWeight: FontWeight.bold)))),
        ],
      ),
    );
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
    return ExpansionTile(
      key: const ValueKey('cookies'),
      title: const Text("Cookies", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
      onExpansionChanged: (isExpanding) {
        if (isExpanding) _fetchCookies();
      },
      children: [
        if (_isCookiesLoading)
          const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
        else
          Column(
            children: [
              _buildTableHeader("Name", "Value", "Del"),
              const Divider(height: 1, thickness: 1),
              if (_cookies.isEmpty)
                const Padding(padding: EdgeInsets.all(16.0), child: Text("No cookies for this domain.")),
              for (final cookie in _cookies)
                _buildDataRow(
                  keyText: cookie.name,
                  valueText: cookie.value,
                  onCellTap: () => _showActionDialog(
                      title: cookie.name,
                      value: cookie.value,
                      expiresDate:
                          cookie.expiresDate != null ? DateTime.fromMillisecondsSinceEpoch(cookie.expiresDate!) : null,
                      canDelete: cookie.isHttpOnly != true,
                      onDelete: () async {
                        final url = await widget.webViewController?.getUrl();
                        if (url == null) return;
                        await _cookieManager.deleteCookie(
                            url: url, name: cookie.name, domain: cookie.domain, path: cookie.path ?? '/');
                        await _fetchCookies();
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
                            await _fetchCookies();
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
                            await _fetchCookies();
                          }),
                ),
              _buildNewCookieForm(),
              const Divider(height: 1, thickness: 1),
              TextButton(
                child: const Text("Clear all cookies for this domain"),
                onPressed: () async {
                  final url = await widget.webViewController?.getUrl();
                  if (url == null) return;
                  await _cookieManager.deleteCookies(url: url);
                  await _fetchCookies();
                },
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildWebLocalStorageExpansionTile() {
    return ExpansionTile(
      key: const ValueKey('local_storage'),
      title: const Text("Local Storage", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
      onExpansionChanged: (isExpanding) {
        if (isExpanding) _fetchLocalStorage();
      },
      children: [
        if (_isLocalStorageLoading)
          const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
        else
          Column(
            children: [
              _buildTableHeader("Key", "Value", "Del"),
              const Divider(height: 1, thickness: 1),
              if (_localStorageItems.isEmpty)
                const Padding(padding: EdgeInsets.all(16.0), child: Text("Local Storage is empty.")),
              for (final item in _localStorageItems)
                _buildDataRow(
                    keyText: item.key ?? '',
                    valueText: item.value,
                    onCellTap: () => _showActionDialog(
                        title: item.key!,
                        value: item.value,
                        onDelete: () async {
                          await widget.webViewController!.webStorage.localStorage.removeItem(key: item.key!);
                          await _fetchLocalStorage();
                        },
                        onEdit: () => _showValueEditDialog(
                            title: item.key!,
                            initialValue: item.value,
                            onSave: (newValue) async {
                              await widget.webViewController!.webStorage.localStorage
                                  .setItem(key: item.key!, value: newValue);
                              await _fetchLocalStorage();
                            })),
                    deleteWidget: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () async {
                          await widget.webViewController!.webStorage.localStorage.removeItem(key: item.key!);
                          await _fetchLocalStorage();
                        })),
              _buildAddNewWebStorageItem(
                  formKey: _newLocalStorageItemFormKey,
                  nameController: _newLocalStorageKeyController,
                  valueController: _newLocalStorageValueController,
                  labelName: "Local Item Key",
                  labelValue: "Local Item Value",
                  onAdded: (name, value) async {
                    await widget.webViewController!.webStorage.localStorage.setItem(key: name, value: value);
                    await _fetchLocalStorage();
                  }),
            ],
          ),
      ],
    );
  }

  Widget _buildWebSessionStorageExpansionTile() {
    return ExpansionTile(
      key: const ValueKey('session_storage'),
      title: const Text("Session Storage", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
      onExpansionChanged: (isExpanding) {
        if (isExpanding) _fetchSessionStorage();
      },
      children: [
        if (_isSessionStorageLoading)
          const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
        else
          Column(
            children: [
              _buildTableHeader("Key", "Value", "Del"),
              const Divider(height: 1, thickness: 1),
              if (_sessionStorageItems.isEmpty)
                const Padding(padding: EdgeInsets.all(16.0), child: Text("Session Storage is empty.")),
              for (final item in _sessionStorageItems)
                _buildDataRow(
                    keyText: item.key ?? '',
                    valueText: item.value,
                    onCellTap: () => _showActionDialog(
                        title: item.key!,
                        value: item.value,
                        onDelete: () async {
                          await widget.webViewController!.webStorage.sessionStorage.removeItem(key: item.key!);
                          await _fetchSessionStorage();
                        },
                        onEdit: () => _showValueEditDialog(
                            title: item.key!,
                            initialValue: item.value,
                            onSave: (newValue) async {
                              await widget.webViewController!.webStorage.sessionStorage
                                  .setItem(key: item.key!, value: newValue);
                              await _fetchSessionStorage();
                            })),
                    deleteWidget: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () async {
                          await widget.webViewController!.webStorage.sessionStorage.removeItem(key: item.key!);
                          await _fetchSessionStorage();
                        })),
              _buildAddNewWebStorageItem(
                  formKey: _newSessionStorageItemFormKey,
                  nameController: _newSessionStorageKeyController,
                  valueController: _newSessionStorageValueController,
                  labelName: "Session Item Key",
                  labelValue: "Session Item Value",
                  onAdded: (name, value) async {
                    await widget.webViewController!.webStorage.sessionStorage.setItem(key: name, value: value);
                    await _fetchSessionStorage();
                  }),
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
                      await _fetchCookies();
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
              return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()));
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text("Could not load data.")));
            }

            return Column(
              children: [
                _buildTableHeader("Display Name", "Data Types", "Del"),
                const Divider(height: 1, thickness: 1),
                for (final dataRecord in snapshot.data!)
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
            if (snapshot.connectionState == ConnectionState.waiting)
              return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()));
            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty)
              return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text("No credentials saved.")));

            return Column(
              children: [
                for (var p in snapshot.data!)
                  Column(
                    children: [
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text("Protection Space: ${p.protectionSpace?.host ?? ""}",
                              style: const TextStyle(fontWeight: FontWeight.bold))),
                      _buildTableHeader("Username", "Password", "Del"),
                      const Divider(height: 1, thickness: 1),
                      for (var c in p.credentials ?? [])
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
}
