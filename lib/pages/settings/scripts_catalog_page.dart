// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:provider/provider.dart';

// Project imports:
import 'package:torn_pda/drawer.dart';
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/userscript_model.dart';
import 'package:torn_pda/models/userscripts/script_catalog_model.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/userscripts_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/script_catalog_service.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';

class ScriptsCatalogPage extends StatefulWidget {
  const ScriptsCatalogPage({super.key});

  @override
  ScriptsCatalogPageState createState() => ScriptsCatalogPageState();
}

class ScriptsCatalogPageState extends State<ScriptsCatalogPage> {
  late ThemeProvider _themeProvider;
  late SettingsProvider _settingsProvider;
  late UserScriptsProvider _userScriptsProvider;
  late WebViewProvider _webViewProvider;

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  late StreamSubscription _willPopSubscription;

  ScriptCatalogResult? _result;
  bool _loading = true;

  String _search = "";
  String? _categoryFilter;

  final Set<String> _installing = {};

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _userScriptsProvider = Provider.of<UserScriptsProvider>(context, listen: false);

    routeWithDrawer = false;
    routeName = "scripts_catalog";
    _willPopSubscription = _settingsProvider.willPopShouldGoBackStream.stream.listen((event) {
      if (mounted && routeName == "scripts_catalog") _goBack();
    });

    _loadCatalog();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _willPopSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    setState(() => _loading = true);
    final result = await ScriptCatalogService.load();
    if (!mounted) return;
    setState(() {
      _result = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context);
    _webViewProvider = Provider.of<WebViewProvider>(context);
    _userScriptsProvider = Provider.of<UserScriptsProvider>(context);

    return Container(
      color: _themeProvider.currentTheme == AppTheme.light
          ? MediaQuery.orientationOf(context) == Orientation.portrait
                ? Colors.blueGrey
                : isStatusBarShown
                ? _themeProvider.statusBar
                : _themeProvider.canvas
          : _themeProvider.canvas,
      child: SafeArea(
        right: _webViewProvider.webViewSplitActive && _webViewProvider.splitScreenPosition == WebViewSplitPosition.left,
        left: _webViewProvider.webViewSplitActive && _webViewProvider.splitScreenPosition == WebViewSplitPosition.right,
        child: Scaffold(
          backgroundColor: _themeProvider.canvas,
          appBar: _settingsProvider.appBarTop ? _buildAppBar() : null,
          bottomNavigationBar: !_settingsProvider.appBarTop
              ? SizedBox(height: AppBar().preferredSize.height, child: _buildAppBar())
              : null,
          body: Container(color: _themeProvider.canvas, child: _buildBody()),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      toolbarHeight: 50,
      title: const Text('TornTools scripts', style: TextStyle(color: Colors.white)),
      leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _goBack),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final catalog = _result?.catalog;

    if (catalog == null) {
      return _messagePanel(
        icon: Icons.cloud_off,
        title: "Catalog unavailable",
        message:
            "The script catalog could not be loaded.\n\n"
            "${_result?.error ?? "Please check your connection and try again."}",
        showRetry: true,
      );
    }

    if (!catalog.enabled) {
      return _messagePanel(
        icon: Icons.pause_circle_outline,
        title: "Temporarily unavailable",
        message: "This section is currently disabled. Please try again in a few days.",
        showRetry: false,
      );
    }

    final visible = _visibleScripts(catalog);

    return Column(
      children: [
        if (_result!.isStale) _staleBanner(),
        Expanded(
          child: ListView(
            controller: _scrollController,
            children: [
              _providerHeader(catalog),
              _searchField(),
              _categoryChips(catalog),
              if (visible.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  child: Center(
                    child: Text(
                      "No scripts match your search",
                      style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
                    ),
                  ),
                )
              else
                ..._buildGroupedList(catalog, visible),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ],
    );
  }

  List<CatalogScript> _visibleScripts(ScriptCatalog catalog) {
    final search = _search.trim().toLowerCase();
    return catalog.scripts.where((s) {
      if (_categoryFilter != null && s.category != _categoryFilter) return false;
      if (search.isEmpty) return true;
      return s.name.toLowerCase().contains(search) || s.description.toLowerCase().contains(search);
    }).toList();
  }

  List<Widget> _buildGroupedList(ScriptCatalog catalog, List<CatalogScript> visible) {
    final widgets = <Widget>[];
    for (final category in catalog.populatedCategories) {
      final inCategory = visible.where((s) => s.category == category.id).toList();
      if (inCategory.isEmpty) continue;
      widgets.add(_categoryHeader(category.name, inCategory.length));
      widgets.addAll(inCategory.map(_scriptCard));
    }
    return widgets;
  }

  Widget _messagePanel({
    required IconData icon,
    required String title,
    required String message,
    required bool showRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.grey[600]),
            const SizedBox(height: 15),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            if (showRetry) ...[
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _loadCatalog, child: const Text("Retry")),
            ],
          ],
        ),
      ),
    );
  }

  Widget _staleBanner() {
    final amber = _light ? Colors.orange[800]! : Colors.orange[300]!;
    return Container(
      width: double.infinity,
      color: amber.withValues(alpha: _light ? 0.12 : 0.16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Row(
        children: [
          Icon(Icons.cloud_off, size: 15, color: amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Showing a saved copy, it might not include the latest scripts",
              style: TextStyle(fontSize: 11, color: amber),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _loadCatalog,
            behavior: HitTestBehavior.opaque,
            child: Text(
              "RETRY",
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: amber),
            ),
          ),
        ],
      ),
    );
  }

  bool get _light => _themeProvider.currentTheme == AppTheme.light;

  Color get _accent => _light ? const Color(0xFF1565C0) : const Color(0xFF7FB5F0);

  Color get _subtleText => _light ? Colors.grey[700]! : Colors.grey[400]!;

  Color get _hairline => _light ? Colors.grey[300]! : Colors.white.withValues(alpha: 0.10);

  Widget _providerHeader(ScriptCatalog catalog) {
    final provider = catalog.provider;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: _accent.withValues(alpha: _light ? 0.07 : 0.13),
        border: Border.all(color: _accent.withValues(alpha: _light ? 0.25 : 0.30)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _accent.withValues(alpha: _light ? 0.15 : 0.22),
                  ),
                  child: Icon(MdiIcons.toolbox, size: 18, color: _accent),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.name,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 0.2),
                      ),
                      if (provider.author.isNotEmpty)
                        Text(provider.author, style: TextStyle(fontSize: 11.5, color: _subtleText)),
                      if (catalog.readableUpdated.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Row(
                            children: [
                              Icon(Icons.update, size: 11, color: _subtleText),
                              const SizedBox(width: 4),
                              Text(
                                "${catalog.scripts.length} scripts · updated ${catalog.readableUpdated}",
                                style: TextStyle(fontSize: 10.5, color: _subtleText),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (provider.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(provider.description, style: const TextStyle(fontSize: 12.5, height: 1.35)),
            ],
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 13, color: _subtleText),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "Made and maintained by the TornTools team, not by Torn PDA. "
                    "Please report any problem with them through their own channels.",
                    style: TextStyle(fontSize: 11, height: 1.3, color: _subtleText),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (provider.forum != null) _linkChip("Forum", MdiIcons.forum, provider.forum!),
                if (provider.github != null) _linkChip("GitHub", MdiIcons.codeTags, provider.github!),
                if (provider.discord != null) _linkChip("Discord", MdiIcons.chatOutline, provider.discord!),
                if (provider.donate != null) _linkChip("Donate", MdiIcons.coffee, provider.donate!),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _linkChip(String label, IconData icon, String url) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openInBrowser(url),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: _light ? Colors.white.withValues(alpha: 0.75) : Colors.white.withValues(alpha: 0.06),
            border: Border.all(color: _accent.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: _accent),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(fontSize: 11.5, color: _accent, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openInBrowser(String url) async {
    await _webViewProvider.openBrowserPreference(context: context, url: url, browserTapType: BrowserTapType.short);
  }

  Widget _searchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 2),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: _light ? Colors.grey[100] : Colors.white.withValues(alpha: 0.05),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: _hairline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: _hairline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: _accent.withValues(alpha: 0.6)),
          ),
          prefixIcon: Icon(Icons.search, size: 19, color: _subtleText),
          hintText: "Search scripts",
          hintStyle: TextStyle(fontSize: 14, color: _subtleText),
          suffixIcon: _search.isEmpty
              ? null
              : IconButton(
                  icon: Icon(Icons.close, size: 17, color: _subtleText),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _search = "");
                  },
                ),
        ),
        onChanged: (value) => setState(() => _search = value),
      ),
    );
  }

  Widget _categoryChips(ScriptCatalog catalog) {
    final categories = catalog.populatedCategories;
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
        children: [_categoryChip("All", null), ...categories.map((c) => _categoryChip(c.name, c.id))],
      ),
    );
  }

  Widget _categoryChip(String label, String? id) {
    final selected = _categoryFilter == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => setState(() => _categoryFilter = selected ? null : id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: selected ? _accent : Colors.transparent,
              border: Border.all(color: selected ? _accent : _hairline),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? (_light ? Colors.white : Colors.black87) : _subtleText,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _categoryHeader(String name, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 13,
            decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 8),
          Text(
            name.toUpperCase(),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _accent, letterSpacing: 0.8),
          ),
          const SizedBox(width: 8),
          Text("$count", style: TextStyle(fontSize: 11, color: _subtleText)),
        ],
      ),
    );
  }

  Widget _scriptCard(CatalogScript script) {
    final installedModel = _installedModel(script);
    final installed = installedModel != null;
    final paused = installed && !installedModel.enabled;
    final installing = _installing.contains(script.id);
    final green = _light ? Colors.green[700]! : Colors.green[300]!;
    final amber = _light ? Colors.orange[800]! : Colors.orange[300]!;
    final stateColor = paused ? amber : green;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: _light ? Colors.white : Colors.white.withValues(alpha: 0.035),
        border: Border.all(color: installed ? stateColor.withValues(alpha: 0.45) : _hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(script.name, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, height: 1.2)),
                  if (script.description.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(script.description, style: TextStyle(fontSize: 12, height: 1.3, color: _subtleText)),
                  ],
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Icon(
                        script.isGlobal ? Icons.public : Icons.place_outlined,
                        size: 13,
                        color: _accent.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          script.whereItRuns.join(" · "),
                          style: TextStyle(fontSize: 11, color: _accent.withValues(alpha: _light ? 0.9 : 0.85)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (script.pageUrl.isNotEmpty)
                        GestureDetector(
                          onTap: () => _openInBrowser(script.pageUrl),
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.open_in_new, size: 12, color: _subtleText),
                                const SizedBox(width: 4),
                                Text("Source", style: TextStyle(fontSize: 11, color: _subtleText)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 42,
              height: 42,
              child: Center(
                child: _installControl(
                  script,
                  installedModel: installedModel,
                  installing: installing,
                  stateColor: stateColor,
                  paused: paused,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _installControl(
    CatalogScript script, {
    required UserScriptModel? installedModel,
    required bool installing,
    required Color stateColor,
    required bool paused,
  }) {
    if (installing) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(_accent)),
      );
    }

    if (installedModel != null) {
      return GestureDetector(
        onTap: () => _showInstalledDialog(script, installedModel),
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(shape: BoxShape.circle, color: stateColor.withValues(alpha: 0.16)),
          child: Icon(paused ? Icons.pause_rounded : Icons.check_rounded, size: 19, color: stateColor),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => _install(script),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _accent.withValues(alpha: _light ? 0.12 : 0.20),
            border: Border.all(color: _accent.withValues(alpha: 0.45)),
          ),
          child: Icon(Icons.arrow_downward_rounded, size: 18, color: _accent),
        ),
      ),
    );
  }

  UserScriptModel? _installedModel(CatalogScript script) {
    for (final installed in _userScriptsProvider.userScriptList) {
      if (CatalogScript.greasyforkIdFromUrl(installed.url) == script.greasyforkId) return installed;
    }
    return null;
  }

  Future<void> _showInstalledDialog(CatalogScript script, UserScriptModel model) async {
    bool confirmingDelete = false;

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            final paused = !model.enabled;
            final amber = _light ? Colors.orange[800]! : Colors.orange[300]!;
            final red = _light ? Colors.red[700]! : Colors.red[300]!;

            return AlertDialog(
              backgroundColor: _themeProvider.secondBackground,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
              title: Row(
                children: [
                  Icon(paused ? Icons.pause_circle_outline : Icons.check_circle_outline, size: 20, color: _accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(script.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    paused
                        ? "This script is installed but paused, so it is not running.\n\n"
                              "You can manage it from the user scripts list, or use the shortcuts below."
                        : "This script is already installed and running.\n\n"
                              "You can manage it from the user scripts list, or use the shortcuts below.",
                    style: const TextStyle(fontSize: 13, height: 1.35),
                  ),
                  if (confirmingDelete) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: red.withValues(alpha: 0.12),
                        border: Border.all(color: red.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        "Delete this script? Anything it has saved will be wiped as well.",
                        style: TextStyle(fontSize: 12.5, height: 1.3, color: red),
                      ),
                    ),
                  ],
                ],
              ),
              actionsPadding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
              actions: confirmingDelete
                  ? [
                      TextButton(
                        onPressed: () => setDialogState(() => confirmingDelete = false),
                        child: Text("CANCEL", style: TextStyle(color: _subtleText)),
                      ),
                      TextButton(
                        onPressed: () {
                          _userScriptsProvider.removeUserScript(model);
                          Navigator.of(dialogContext).pop();
                          _toast("${script.name} deleted", Colors.red[800]!);
                        },
                        child: Text(
                          "DELETE",
                          style: TextStyle(color: red, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ]
                  : [
                      TextButton(
                        onPressed: () => setDialogState(() => confirmingDelete = true),
                        child: Text("DELETE", style: TextStyle(color: red)),
                      ),
                      TextButton(
                        onPressed: () {
                          _userScriptsProvider.changeUserScriptEnabled(model, paused);
                          setDialogState(() {});
                          _toast(
                            paused ? "${script.name} resumed" : "${script.name} paused",
                            paused ? Colors.green[800]! : Colors.orange[800]!,
                          );
                        },
                        child: Text(paused ? "RESUME" : "PAUSE", style: TextStyle(color: amber)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: Text("CLOSE", style: TextStyle(color: _accent)),
                      ),
                    ],
            );
          },
        );
      },
    );

    if (mounted) setState(() {});
  }

  Future<void> _install(CatalogScript script) async {
    setState(() => _installing.add(script.id));

    try {
      final result = await UserScriptModel.fromURL(script.downloadUrl);

      if (!mounted) return;

      if (!result.success || result.model == null) {
        _toast("Could not install ${script.name}: ${result.message}", Colors.red[800]!);
        return;
      }

      final model = result.model!;
      model.catalogName = script.name;
      model.name = script.name;

      // The provider skips scripts whose name is taken, which would fail silently otherwise
      final String newName = model.name.toLowerCase();
      final bool nameTaken = _userScriptsProvider.userScriptList.any((s) => s.name.toLowerCase() == newName);
      if (nameTaken) {
        _toast(
          "You already have a script named '${model.name}'. Remove it first if you want to install this one.",
          Colors.orange[800]!,
        );
        return;
      }

      _userScriptsProvider.addUserScriptByModel(model);
      _toast("${script.name} installed", Colors.green[800]!);
    } catch (e) {
      if (mounted) _toast("Could not install ${script.name}: $e", Colors.red[800]!);
    } finally {
      if (mounted) setState(() => _installing.remove(script.id));
    }
  }

  void _toast(String text, Color color) {
    BotToast.showText(
      text: text,
      textStyle: const TextStyle(fontSize: 14, color: Colors.white),
      contentColor: color,
      contentPadding: const EdgeInsets.all(10),
      duration: const Duration(seconds: 4),
    );
  }

  void _goBack() {
    routeWithDrawer = false;
    routeName = "userscripts";
    Navigator.of(context).pop();
  }
}
