import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/main.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/widgets/split_app_safe_area.dart';

enum PdaScaffoldMargin { statusBar, grey, canvas }

class PdaScaffold extends StatelessWidget {
  const PdaScaffold({
    super.key,
    required this.appBar,
    required this.body,
    this.margin = PdaScaffoldMargin.statusBar,
    this.drawer,
    this.floatingActionButton,
  });

  final PreferredSizeWidget appBar;
  final Widget body;
  final PdaScaffoldMargin margin;
  final Widget? drawer;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final appBarTop = Provider.of<SettingsProvider>(context, listen: false).appBarTop;
    final portrait = MediaQuery.orientationOf(context) == Orientation.portrait;

    final Color? marginColor = switch (margin) {
      PdaScaffoldMargin.statusBar =>
        themeProvider.currentTheme == AppTheme.light
            ? portrait
                  ? Colors.blueGrey
                  : isStatusBarShown
                  ? themeProvider.statusBar
                  : themeProvider.canvas
            : themeProvider.canvas,
      PdaScaffoldMargin.grey =>
        themeProvider.currentTheme == AppTheme.light
            ? portrait
                  ? Colors.blueGrey
                  : Colors.grey[900]
            : themeProvider.currentTheme == AppTheme.dark
            ? Colors.grey[900]
            : Colors.black,
      PdaScaffoldMargin.canvas =>
        themeProvider.currentTheme == AppTheme.light && portrait ? Colors.blueGrey : themeProvider.canvas,
    };

    return Container(
      color: marginColor,
      child: SplitAppSafeArea(
        child: Scaffold(
          backgroundColor: themeProvider.canvas,
          drawer: drawer,
          floatingActionButton: floatingActionButton,
          appBar: appBarTop ? appBar : null,
          bottomNavigationBar: !appBarTop ? SizedBox(height: AppBar().preferredSize.height, child: appBar) : null,
          body: body,
        ),
      ),
    );
  }
}
