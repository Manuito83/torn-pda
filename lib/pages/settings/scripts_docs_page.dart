// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:provider/provider.dart';

// Project imports:
import 'package:torn_pda/drawer.dart';
import 'package:torn_pda/main.dart';
import 'package:torn_pda/pages/settings/scripts_doc_viewer_page.dart';
import 'package:torn_pda/pages/settings/scripts_guide_page.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/script_docs_service.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';

class ScriptsDocsPage extends StatefulWidget {
  const ScriptsDocsPage({super.key, required this.onOpenDisclaimer});

  final Future<void> Function() onOpenDisclaimer;

  @override
  ScriptsDocsPageState createState() => ScriptsDocsPageState();
}

class ScriptsDocsPageState extends State<ScriptsDocsPage> {
  late ThemeProvider _themeProvider;
  late SettingsProvider _settingsProvider;
  late WebViewProvider _webViewProvider;

  final _scrollController = ScrollController();

  late StreamSubscription _willPopSubscription;

  bool _disclaimerRead = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    routeWithDrawer = false;
    routeName = "scripts_docs";
    _willPopSubscription = _settingsProvider.willPopShouldGoBackStream.stream.listen((event) {
      if (mounted && routeName == "scripts_docs") _goBack();
    });

    _loadDisclaimerState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _willPopSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadDisclaimerState() async {
    final read = await Prefs().getScriptDocsDisclaimerRead();
    if (!mounted) return;
    setState(() {
      _disclaimerRead = read;
      _loading = false;
    });
  }

  bool get _light => _themeProvider.currentTheme == AppTheme.light;

  Color get _accent => _light ? const Color(0xFF1565C0) : const Color(0xFF7FB5F0);

  Color get _subtleText => _light ? Colors.grey[700]! : Colors.grey[400]!;

  Color get _hairline => _light ? Colors.grey[300]! : Colors.white.withValues(alpha: 0.10);

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context);
    _webViewProvider = Provider.of<WebViewProvider>(context);

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
      title: const Text('User scripts docs', style: TextStyle(color: Colors.white)),
      leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _goBack),
      actions: [
        if (_disclaimerRead)
          IconButton(
            icon: Icon(Icons.warning_amber_rounded, color: Colors.orange[300]),
            tooltip: "Show the disclaimer reminder again",
            onPressed: _restoreDisclaimer,
          ),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 40),
      children: [
        if (!_disclaimerRead) _disclaimerCallout(),
        const SizedBox(height: 12),
        _docTile(ScriptDocsService.guide),
        _devSeparator(),
        for (final group in ScriptDocsService.devGroups) ...[
          _groupHeader(group),
          ...ScriptDocsService.entriesIn(group).map(_docTile),
        ],
      ],
    );
  }

  Widget _devSeparator() {
    final green = _light ? const Color(0xFF2E7D32) : const Color(0xFF7FD68A);

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 26, 0, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Divider(color: _hairline, height: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: green.withValues(alpha: _light ? 0.10 : 0.16),
                    border: Border.all(color: green.withValues(alpha: 0.45)),
                  ),
                  child: Text(
                    "> DEV DOCS",
                    style: TextStyle(
                      fontFamily: "monospace",
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: green,
                    ),
                  ),
                ),
              ),
              Expanded(child: Divider(color: _hairline, height: 1)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Everything below is written for script developers. It all lives in the Torn PDA repository, "
            "in the docs folder, and is shown here straight from there.",
            style: TextStyle(fontSize: 11.5, height: 1.4, color: _subtleText),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4), minimumSize: Size.zero),
              onPressed: () => _openInBrowser(ScriptDocsService.devDocsUrl),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.open_in_new, size: 13, color: green),
                  const SizedBox(width: 6),
                  Text(
                    "See them on GitHub",
                    style: TextStyle(
                      fontFamily: "monospace",
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: green,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openInBrowser(String url) async {
    await _webViewProvider.openBrowserPreference(context: context, url: url, browserTapType: BrowserTapType.short);
  }

  Widget _disclaimerCallout() {
    final amber = _light ? Colors.orange[800]! : Colors.orange[300]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: amber.withValues(alpha: _light ? 0.10 : 0.14),
        border: Border.all(color: amber.withValues(alpha: 0.45)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 19, color: amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Read the disclaimer",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: amber),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "If you have not read it yet, please do so before installing any script. "
              "It explains what a user script can do to your account.",
              style: TextStyle(fontSize: 12.5, height: 1.35, color: _subtleText),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _markDisclaimerRead,
                  child: Text("DISMISS", style: TextStyle(fontSize: 12, color: _subtleText)),
                ),
                TextButton(
                  onPressed: () async {
                    await widget.onOpenDisclaimer();
                    await _markDisclaimerRead();
                  },
                  child: Text(
                    "READ IT",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: amber),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markDisclaimerRead() async {
    await Prefs().setScriptDocsDisclaimerRead(true);
    if (mounted) setState(() => _disclaimerRead = true);
  }

  Future<void> _restoreDisclaimer() async {
    await Prefs().setScriptDocsDisclaimerRead(false);
    if (!mounted) return;
    setState(() => _disclaimerRead = false);
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    BotToast.showText(
      text: "Disclaimer reminder restored",
      textStyle: const TextStyle(fontSize: 14, color: Colors.white),
      contentColor: Colors.grey[800]!,
      contentPadding: const EdgeInsets.all(10),
    );
  }

  Widget _groupHeader(String name) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
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
        ],
      ),
    );
  }

  Widget _docTile(ScriptDocEntry entry) {
    final isCode = entry.format == ScriptDocFormat.javascript;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: _light ? Colors.white : Colors.white.withValues(alpha: 0.035),
        border: Border.all(color: _hairline),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (BuildContext context) => entry.format == ScriptDocFormat.native
                    ? const ScriptsGuidePage()
                    : ScriptDocViewerPage(entry: entry),
              ),
            ).then((_) {
              routeWithDrawer = false;
              routeName = "scripts_docs";
            });
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _accent.withValues(alpha: _light ? 0.10 : 0.18),
                  ),
                  child: Icon(isCode ? Icons.code : Icons.article_outlined, size: 16, color: _accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Text(entry.subtitle, style: TextStyle(fontSize: 11.5, height: 1.3, color: _subtleText)),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right, size: 20, color: _subtleText),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _goBack() {
    routeWithDrawer = false;
    routeName = "userscripts";
    Navigator.of(context).pop();
  }
}
