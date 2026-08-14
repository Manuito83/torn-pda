// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:provider/provider.dart';

// Project imports:
import 'package:torn_pda/drawer.dart';
import 'package:torn_pda/main.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/script_docs_service.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';

class ScriptDocViewerPage extends StatefulWidget {
  const ScriptDocViewerPage({super.key, required this.entry});

  final ScriptDocEntry entry;

  @override
  ScriptDocViewerPageState createState() => ScriptDocViewerPageState();
}

class ScriptDocViewerPageState extends State<ScriptDocViewerPage> {
  late ThemeProvider _themeProvider;
  late SettingsProvider _settingsProvider;
  late WebViewProvider _webViewProvider;

  final _scrollController = ScrollController();

  late StreamSubscription _willPopSubscription;

  String? _content;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    routeWithDrawer = false;
    routeName = "scripts_doc_viewer";
    _willPopSubscription = _settingsProvider.willPopShouldGoBackStream.stream.listen((event) {
      if (mounted && routeName == "scripts_doc_viewer") _goBack();
    });

    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _willPopSubscription.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final bundled = await ScriptDocsService.bundled(widget.entry.path);
    if (!mounted) return;
    setState(() {
      _content = bundled;
      _loading = false;
    });

    final remote = await ScriptDocsService.remote(widget.entry.path);
    if (!mounted || remote == null || remote == _content) return;
    setState(() => _content = remote);
  }

  bool get _light => _themeProvider.currentTheme == AppTheme.light;

  Color get _accent => _light ? const Color(0xFF1565C0) : const Color(0xFF7FB5F0);

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
      title: Text(
        widget.entry.title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        overflow: TextOverflow.ellipsis,
      ),
      leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _goBack),
      actions: [
        IconButton(
          icon: const Icon(Icons.open_in_new, size: 20),
          tooltip: "Open on GitHub",
          onPressed: () => _openInBrowser(ScriptDocsService.githubUrlFor(widget.entry.path)),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final content = _content;
    if (content == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.description_outlined, size: 48, color: Colors.grey[600]),
              const SizedBox(height: 15),
              Text(
                "This document could not be loaded",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _openInBrowser(ScriptDocsService.githubUrlFor(widget.entry.path)),
                child: const Text("Open on GitHub"),
              ),
            ],
          ),
        ),
      );
    }

    return Scrollbar(
      controller: _scrollController,
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
        children: [
          MarkdownBody(
            data: _prepare(content),
            selectable: true,
            styleSheet: _styleSheet(),
            onTapLink: (text, href, title) => _onTapLink(href),
          ),
        ],
      ),
    );
  }

  String _prepare(String content) {
    if (widget.entry.format == ScriptDocFormat.javascript) {
      return "```javascript\n$content\n```";
    }

    final breakTag = RegExp(r'</?br\s*/?>', caseSensitive: false);
    final imageLink = RegExp(r'!\[([^\]]*)\]\((?!https?://)([^)]+)\)');

    bool insideFence = false;
    final lines = <String>[];

    for (final line in content.split("\n")) {
      if (line.trimLeft().startsWith("```")) {
        insideFence = !insideFence;
        lines.add(line);
        continue;
      }

      if (insideFence) {
        lines.add(line);
        continue;
      }

      final cleaned = line.replaceAll(breakTag, "").replaceAllMapped(imageLink, (match) {
        final resolved = ScriptDocsService.absoluteUrlFor(widget.entry.path, match.group(2)!);
        return "![${match.group(1)}]($resolved)";
      });

      if (cleaned.trim().isEmpty && line.trim().isNotEmpty) continue;
      lines.add(cleaned);
    }

    return lines.join("\n");
  }

  void _onTapLink(String? href) {
    if (href == null || href.isEmpty) return;

    if (!href.startsWith("http")) {
      final resolved = ScriptDocsService.resolveRelative(widget.entry.path, href);
      final known = ScriptDocsService.entryForPath(resolved);
      if (known != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (BuildContext context) => ScriptDocViewerPage(entry: known)),
        ).then((_) {
          routeWithDrawer = false;
          routeName = "scripts_doc_viewer";
        });
        return;
      }
      _openInBrowser(ScriptDocsService.githubUrlFor(resolved));
      return;
    }

    _openInBrowser(href);
  }

  MarkdownStyleSheet _styleSheet() {
    final base = MarkdownStyleSheet.fromTheme(Theme.of(context));
    final codeBackground = _light ? Colors.grey[200]! : Colors.white.withValues(alpha: 0.07);

    return base.copyWith(
      p: TextStyle(fontSize: 13.5, height: 1.45, color: _themeProvider.mainText),
      h1: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _themeProvider.mainText),
      h2: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _accent),
      h3: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _themeProvider.mainText),
      h1Padding: const EdgeInsets.only(bottom: 4),
      h2Padding: const EdgeInsets.only(top: 22, bottom: 4),
      h3Padding: const EdgeInsets.only(top: 14, bottom: 2),
      listBullet: TextStyle(fontSize: 13.5, height: 1.45, color: _themeProvider.mainText),
      a: TextStyle(color: _accent, decoration: TextDecoration.underline),
      strong: TextStyle(fontWeight: FontWeight.w700, color: _themeProvider.mainText),
      code: TextStyle(
        fontSize: 11.5,
        fontFamily: "monospace",
        backgroundColor: Colors.transparent,
        color: _light ? Colors.deepPurple[700] : Colors.orange[200],
      ),
      codeblockDecoration: BoxDecoration(color: codeBackground, borderRadius: BorderRadius.circular(8)),
      codeblockPadding: const EdgeInsets.all(12),
      blockquoteDecoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      tableHead: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: _themeProvider.mainText),
      tableBody: TextStyle(fontSize: 11.5, color: _themeProvider.mainText),
      tableCellsPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      tableBorder: TableBorder.all(color: _light ? Colors.grey[400]! : Colors.white24, width: 0.5),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(top: BorderSide(width: 1, color: _light ? Colors.grey[300]! : Colors.white24)),
      ),
      blockSpacing: 10,
    );
  }

  Future<void> _openInBrowser(String url) async {
    await _webViewProvider.openBrowserPreference(context: context, url: url, browserTapType: BrowserTapType.short);
  }

  void _goBack() {
    routeWithDrawer = false;
    routeName = "scripts_docs";
    Navigator.of(context).pop();
  }
}
