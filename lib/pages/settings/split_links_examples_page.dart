import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/drawer.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/widgets/pda_scaffold.dart';
import 'package:torn_pda/widgets/diagrams/feature_diagrams.dart';

class SplitLinksExamplesPage extends StatefulWidget {
  const SplitLinksExamplesPage({super.key});

  @override
  SplitLinksExamplesPageState createState() => SplitLinksExamplesPageState();
}

class SplitLinksExamplesPageState extends State<SplitLinksExamplesPage> {
  late SettingsProvider _settingsProvider;
  late StreamSubscription _willPopSubscription;

  static const List<(SplitAppLinkTarget, FeatureDiagramScene, String, String)> _options = [
    (
      SplitAppLinkTarget.browserTab,
      FeatureDiagramScene.linkCurrentTab,
      "Current tab",
      "The page loads in the tab you are seeing in the browser beside the app.",
    ),
    (
      SplitAppLinkTarget.browserNewTab,
      FeatureDiagramScene.linkNewTab,
      "New tab",
      "The page opens in a new tab of the browser beside the app.",
    ),
    (
      SplitAppLinkTarget.appSideTab,
      FeatureDiagramScene.linkTabBehindApp,
      "Tab behind app",
      "The app gives its side to the group of tabs it was covering, and the page loads in the tab shown there.",
    ),
    (
      SplitAppLinkTarget.appSideNewTab,
      FeatureDiagramScene.linkNewTabAppSide,
      "New tab, app side",
      "The app gives its side to the group of tabs it was covering, and the page opens there in a new tab.",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    routeWithDrawer = false;
    routeName = "split_links_examples";
    _willPopSubscription = _settingsProvider.willPopShouldGoBackStream.stream.listen((event) {
      if (mounted && routeName == "split_links_examples") _goBack();
    });
  }

  @override
  void dispose() {
    _willPopSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final selected = context.select<SettingsProvider, SplitAppLinkTarget>((s) => s.splitAppLinkTarget);
    final subtle = TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic);

    return PdaScaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: _settingsProvider.appBarTop ? 2 : 0,
        toolbarHeight: 50,
        title: const Text("Links from the app", style: TextStyle(color: Colors.white)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _goBack),
      ),
      body: Container(
        color: themeProvider.canvas,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            Text(
              "When the app and a browser are side by side, links tapped in the app open in the current tab or a new tab of the browser next to it, or on the app's side, which then shows the tab it was covering or a new one",
              style: subtle,
            ),
            for (final (target, scene, title, explanation) in _options)
              Card(
                margin: const EdgeInsets.only(top: 16),
                color: themeProvider.cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (target == selected) const Icon(Icons.check_circle, color: Colors.green, size: 20),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(explanation, style: const TextStyle(fontSize: 13)),
                      const SizedBox(height: 10),
                      FeatureDiagram(scenes: [scene]),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              "If no group of tabs is behind the app, Tab behind app works like New tab, app side. If the tab that would load the page has a full lock, a new tab is opened instead.",
              style: subtle,
            ),
          ],
        ),
      ),
    );
  }

  void _goBack() {
    routeWithDrawer = true;
    routeName = "settings";
    Navigator.of(context).pop();
  }
}
