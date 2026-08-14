// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:provider/provider.dart';

// Project imports:
import 'package:torn_pda/drawer.dart';
import 'package:torn_pda/main.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';

class ScriptsGuidePage extends StatefulWidget {
  const ScriptsGuidePage({super.key});

  @override
  ScriptsGuidePageState createState() => ScriptsGuidePageState();
}

class ScriptsGuidePageState extends State<ScriptsGuidePage> {
  late ThemeProvider _themeProvider;
  late SettingsProvider _settingsProvider;
  late WebViewProvider _webViewProvider;

  final _scrollController = ScrollController();

  late StreamSubscription _willPopSubscription;

  final Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    routeWithDrawer = false;
    routeName = "scripts_guide";
    _willPopSubscription = _settingsProvider.willPopShouldGoBackStream.stream.listen((event) {
      if (mounted && routeName == "scripts_guide") _goBack();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _willPopSubscription.cancel();
    super.dispose();
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
      title: const Text('Using scripts', style: TextStyle(color: Colors.white)),
      leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _goBack),
      actions: [
        IconButton(
          icon: Icon(_expanded.isEmpty ? Icons.unfold_more : Icons.unfold_less, size: 22),
          tooltip: _expanded.isEmpty ? "Expand all" : "Collapse all",
          onPressed: () => setState(() {
            if (_expanded.isEmpty) {
              _expanded.addAll(_sections.map((s) => s.title));
            } else {
              _expanded.clear();
            }
          }),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 40),
      children: [
        Text(
          "User scripts are small programs written in JavaScript that add features to the browser. "
          "Torn PDA can run them on any Torn page, the same way extensions like Tampermonkey or "
          "Violentmonkey do on a desktop browser.",
          style: TextStyle(fontSize: 13, height: 1.4, color: _themeProvider.mainText),
        ),
        const SizedBox(height: 8),
        Text(
          "This page covers how scripts behave inside Torn PDA. Storage, GM compatibility and the "
          "handlers that let a script talk to the app have their own pages in the docs section.",
          style: TextStyle(fontSize: 12, height: 1.4, fontStyle: FontStyle.italic, color: _subtleText),
        ),
        const SizedBox(height: 18),
        ..._sections.map(_sectionCard),
        const SizedBox(height: 20),
        _helpCard(),
      ],
    );
  }

  Widget _sectionCard(_GuideSection section) {
    final open = _expanded.contains(section.title);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: _light ? Colors.white : Colors.white.withValues(alpha: 0.035),
        border: Border.all(color: open ? _accent.withValues(alpha: 0.45) : _hairline),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() {
            if (open) {
              _expanded.remove(section.title);
            } else {
              _expanded.add(section.title);
            }
          }),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(section.icon, size: 17, color: _accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(section.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                    Icon(open ? Icons.expand_less : Icons.expand_more, size: 20, color: _subtleText),
                  ],
                ),
                if (open) ...[const SizedBox(height: 12), ...section.body],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _p(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: TextStyle(fontSize: 12.5, height: 1.45, color: _themeProvider.mainText)),
    );
  }

  Widget _rich(List<TextSpan> spans) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text.rich(
        TextSpan(
          style: TextStyle(fontSize: 12.5, height: 1.45, color: _themeProvider.mainText),
          children: spans,
        ),
      ),
    );
  }

  TextSpan _bold(String text) => TextSpan(
    text: text,
    style: const TextStyle(fontWeight: FontWeight.w700),
  );

  TextSpan _mono(String text) => TextSpan(
    text: text,
    style: TextStyle(
      fontFamily: "monospace",
      fontSize: 11.5,
      color: _light ? Colors.deepPurple[700] : Colors.orange[200],
    ),
  );

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5, right: 8),
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(color: _accent, shape: BoxShape.circle),
            ),
          ),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 12.5, height: 1.4, color: _themeProvider.mainText)),
          ),
        ],
      ),
    );
  }

  Widget _subTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      child: Text(
        text,
        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _accent),
      ),
    );
  }

  Widget _code(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: _light ? Colors.grey[200] : Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Scrollbar(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SelectableText(
            text,
            style: TextStyle(
              fontFamily: "monospace",
              fontSize: 11,
              height: 1.45,
              color: _light ? Colors.deepPurple[900] : Colors.orange[100],
            ),
          ),
        ),
      ),
    );
  }

  Widget _helpCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: _accent.withValues(alpha: _light ? 0.07 : 0.13),
        border: Border.all(color: _accent.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.help_outline, size: 17, color: _accent),
                const SizedBox(width: 10),
                Text(
                  "Getting help",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _accent),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              "Join our Discord server if you need help, or if you want to contribute ideas or working code. "
              "There is also a list of tested user scripts in our GitHub repository.",
              style: TextStyle(fontSize: 12.5, height: 1.4, color: _themeProvider.mainText),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                TextButton(
                  onPressed: () => _openInBrowser("https://discord.gg/vyP23kJ"),
                  child: Text(
                    "DISCORD",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _accent),
                  ),
                ),
                TextButton(
                  onPressed: () => _openInBrowser("https://github.com/Manuito83/torn-pda/tree/master/userscripts"),
                  child: Text(
                    "GITHUB",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _accent),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<_GuideSection> get _sections => [
    _GuideSection(
      title: "Adding a script",
      icon: Icons.add_circle_outline,
      body: [
        _p("There are three ways to get a script into Torn PDA:"),
        _bullet("From the TornTools section, the quickest one."),
        _bullet(
          "From a URL. Tap the + button and paste the address of the script. The URL must return plain "
          "text with a valid user script header, or the install will fail.",
        ),
        _bullet(
          "By pasting the code. A local script does not need a valid header, but without one its match "
          "pattern cannot be read and the script will be injected into every page.",
        ),
        const SizedBox(height: 4),
        _rich([
          const TextSpan(text: "When you browse to a URL that serves a script with the "),
          _mono("text/javascript"),
          const TextSpan(
            text:
                " content type, Torn PDA offers to install it automatically. Some hosts, such as raw GitHub "
                "links, do not send that content type; in those cases copy the URL and add the script by hand.",
          ),
        ]),
      ],
    ),
    _GuideSection(
      title: "The TornTools section",
      icon: Icons.widgets_outlined,
      body: [
        _p(
          "The TornTools section lists features that the TornTools team publishes as standalone scripts, "
          "sorted by category and searchable. Install any of them with a single tap and they behave like "
          "any other script from then on.",
        ),
        _p(
          "These scripts are made and maintained by the TornTools team, not by Torn PDA. Report any problem "
          "with them through their own channels, which are linked at the top of the section.",
        ),
        _p(
          "The list is served from the Torn PDA repository, so new scripts show up on their own without "
          "waiting for an app update. You can hide the whole section from the menu in the user scripts page.",
        ),
      ],
    ),
    _GuideSection(
      title: "Keeping scripts updated",
      icon: Icons.update,
      body: [
        _p(
          "Any script installed from a URL is checked for updates. When a newer version exists, a banner "
          "appears at the top of the user scripts page and lets you review and update several scripts at "
          "once, keeping their on/off state and their custom API keys.",
        ),
        _rich([
          const TextSpan(text: "Updates that ask for "),
          _bold("new permissions"),
          const TextSpan(
            text: " are flagged, and you have to expand them and look at the code before you can select them.",
          ),
        ]),
        _p(
          "If you edit a script by hand, it is marked as locally modified and Torn PDA stops offering "
          "updates for it, so your changes are not overwritten.",
        ),
        _p(
          "Each script has its own switch, and there is also a button that disables every script at once, "
          "useful when you want to check whether a problem comes from a script or from the app itself.",
        ),
      ],
    ),
    _GuideSection(
      title: "Headers",
      icon: Icons.description_outlined,
      body: [
        _p("Torn PDA reads a standard user script header:"),
        _code(
          "// ==UserScript==\n"
          "// @name         My script\n"
          "// @version      1.0.0\n"
          "// @match        https://*.torn.com/gym.php*\n"
          "// @run-at       document-end\n"
          "// @grant        GM_addStyle\n"
          "// @downloadURL  https://example.com/my-script.user.js\n"
          "// @updateURL    https://example.com/my-script.meta.js\n"
          "// ==/UserScript==",
        ),
        _rich([
          _mono("@match"),
          const TextSpan(text: " decides which pages the script runs on, "),
          _mono("@version"),
          const TextSpan(text: " drives updates, and "),
          _mono("@updateURL"),
          const TextSpan(
            text:
                " lets Torn PDA check for a new version by downloading just the header instead of the "
                "whole script.",
          ),
        ]),
        _p(
          "Any remote script needs a valid header or the install will fail. Local scripts do not have this "
          "constraint, although without a valid header the match pattern will not be validated and the "
          "script will be injected in all pages.",
        ),
      ],
    ),
    _GuideSection(
      title: "When your script runs",
      icon: Icons.timer_outlined,
      body: [
        _p(
          "Torn PDA can inject a script at two moments, and you can pick which one by editing the "
          "script's details.",
        ),
        _rich([
          _bold("START"),
          const TextSpan(
            text:
                ", before the HTML document loads. You can catch resources loading and ajax calls, but the "
                "script runs before the document or jQuery exist, so you have to check for them yourself, "
                "with intervals or with properties such as ",
          ),
          _mono("Document.readyState"),
          const TextSpan(text: " and checks like "),
          _mono("typeof window.jQuery"),
          const TextSpan(text: "."),
        ]),
        _rich([
          _bold("END"),
          const TextSpan(
            text:
                ", after the document has loaded. Safer, but parts of the page are still loaded dynamically "
                "(items lists, jail, hospital), so you may still need to wait for the elements you want.",
          ),
        ]),
      ],
    ),
    _GuideSection(
      title: "Injection constraints",
      icon: Icons.warning_amber_outlined,
      body: [
        _p(
          "Torn PDA injects scripts using your device's native WebView, and tries to respect injection "
          "times and URLs as much as possible. The platform imposes limits, though: a script can be "
          "injected twice on some pages, will need to be injected again on paginated pages such as jail, "
          "hospital or the forums, and reloading a page can result in multiple injections.",
        ),
        _p("It is the script author's job to cope with all of this. A few ideas:"),
        _bullet("Guard against repeated injection with a flag on the main container."),
        _bullet("Make pagination work by adding click listeners."),
        _bullet("Avoid conflicts with other scripts by wrapping everything in an anonymous function."),
        const SizedBox(height: 4),
        _p(
          "Scripts are isolated from one another at runtime and already executed inside anonymous "
          "functions, so you do not need to wrap them yourself for that reason alone.",
        ),
      ],
    ),
    _GuideSection(
      title: "Your API key",
      icon: Icons.key_outlined,
      body: [
        _rich([
          const TextSpan(text: "Write "),
          _mono("###PDA-APIKEY###"),
          const TextSpan(
            text:
                " in a script instead of your real API key and Torn PDA replaces it at runtime. That way you "
                "can share the script without leaking your key. A script can also be given its own key from "
                "its details screen.",
          ),
        ]),
      ],
    ),
    _GuideSection(
      title: "Troubleshooting",
      icon: Icons.build_outlined,
      body: [
        _subTitle("A script from another platform does not work"),
        _p(
          "Torn PDA supports standard JavaScript and jQuery, but it does not ship the external libraries "
          "that frameworks like GM or TM serve. A script written for another platform, or one that would "
          "not even run in your desktop browser console, may need changes. See the GM compatibility page "
          "in this docs section.",
        ),
        _p(
          "Remember that those handlers cannot make a script fit a phone: viewports differ, the page looks "
          "different, and some selectors change. Be ready to adapt the script regardless.",
        ),
        _subTitle("A script broke after I edited it"),
        _p("Try resetting the browser cache from the advanced browser settings."),
        _subTitle("Scripts do not run in a new window (iOS)"),
        _rich([
          const TextSpan(text: "On iOS, injection at "),
          _bold("START"),
          const TextSpan(
            text:
                " is not supported when a tab was opened as a new window: long pressing a link and choosing "
                "to open it in a new window, a pop-up, or a tab opened automatically by the page. A warning "
                "appears in the Terminal when this happens.",
          ),
        ]),
        _rich([
          const TextSpan(
            text: "The workaround is to open those pages as standard tabs by adding them manually. Injection at ",
          ),
          _bold("END"),
          const TextSpan(text: " works normally."),
        ]),
      ],
    ),
  ];

  Future<void> _openInBrowser(String url) async {
    await _webViewProvider.openBrowserPreference(context: context, url: url, browserTapType: BrowserTapType.short);
  }

  void _goBack() {
    routeWithDrawer = false;
    routeName = "scripts_docs";
    Navigator.of(context).pop();
  }
}

class _GuideSection {
  const _GuideSection({required this.title, required this.icon, required this.body});

  final String title;
  final IconData icon;
  final List<Widget> body;
}
