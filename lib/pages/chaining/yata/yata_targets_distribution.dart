// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:provider/provider.dart';
import 'package:torn_pda/drawer.dart';

// Project imports:
import 'package:torn_pda/models/chaining/yata/yata_distribution_models.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';

class YataTargetsDistribution extends StatefulWidget {
  final List<TargetsOnlyYata> onlyYata;
  final List<TargetsOnlyLocal> onlyLocal;
  final List<TargetsBothSides> bothSides;

  const YataTargetsDistribution({
    required this.bothSides,
    required this.onlyYata,
    required this.onlyLocal,
  });

  @override
  YataTargetsDistributionState createState() => YataTargetsDistributionState();
}

class YataTargetsDistributionState extends State<YataTargetsDistribution> {
  late SettingsProvider _settingsProvider;
  late ThemeProvider _themeProvider;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    routeWithDrawer = false;
    routeName = "yata_targets_distribution";
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
      color: _themeProvider.currentTheme == AppTheme.light
          ? MediaQuery.orientationOf(context) == Orientation.portrait
              ? Colors.blueGrey
              : Colors.grey[900]
          : _themeProvider.currentTheme == AppTheme.dark
              ? Colors.grey[900]
              : Colors.black,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: _themeProvider.canvas,
          drawer: const Drawer(),
          appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
          bottomNavigationBar: !_settingsProvider.appBarTop
              ? SizedBox(
                  height: AppBar().preferredSize.height,
                  child: buildAppBar(),
                )
              : null,
          body: Container(
            color: _themeProvider.currentTheme == AppTheme.extraDark ? Colors.black : Colors.transparent,
            child: SingleChildScrollView(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: <Widget>[
                      const Text(
                        'TARGETS ONLY IN YATA',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        '(CAN BE IMPORTED)',
                        style: TextStyle(
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Column(
                        children: _returnTargetsOnlyInYata(),
                      ),
                      const SizedBox(height: 10),
                      const Divider(),
                      const SizedBox(height: 10),
                      const Text(
                        'COMMON TARGETS',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        '(ONLY NOTES UPDATED)',
                        style: TextStyle(
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Column(
                        children: _returnTargetsBothSides(),
                      ),
                      const SizedBox(height: 10),
                      const Divider(),
                      const SizedBox(height: 10),
                      const Text(
                        'TARGETS ONLY IN TORN PDA',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        '(CAN BE EXPORTED)',
                        style: TextStyle(
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Column(
                        children: _returnTargetsOnlyInTornPDA(),
                      ),
                      const SizedBox(height: 10),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      //brightness: Brightness.dark, // For downgrade to Flutter 2.2.3
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      title: const Text('YATA targets'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  List<Widget> _returnTargetsOnlyInYata() {
    final itemList = <Widget>[];

    if (widget.onlyYata.isEmpty) {
      itemList.add(
        const Text(
          "none",
          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
        ),
      );
    } else {
      for (final yataTarget in widget.onlyYata) {
        itemList.add(
          Text(
            "${yataTarget.name} [${yataTarget.id}]",
            style: const TextStyle(fontSize: 12),
          ),
        );
      }
    }

    return itemList;
  }

  List<Widget> _returnTargetsBothSides() {
    final itemList = <Widget>[];

    if (widget.bothSides.isEmpty) {
      itemList.add(
        const Text(
          "none",
          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
        ),
      );
    } else {
      for (final bothSidesTarget in widget.bothSides) {
        itemList.add(
          Text(
            "${bothSidesTarget.name} [${bothSidesTarget.id}]",
            style: const TextStyle(fontSize: 12),
          ),
        );
      }
    }

    return itemList;
  }

  List<Widget> _returnTargetsOnlyInTornPDA() {
    final itemList = <Widget>[];

    if (widget.onlyLocal.isEmpty) {
      itemList.add(
        const Text(
          "none",
          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
        ),
      );
    } else {
      for (final localTarget in widget.onlyLocal) {
        itemList.add(
          Text(
            "${localTarget.name} [${localTarget.id}]",
            style: const TextStyle(fontSize: 12),
          ),
        );
      }
    }

    return itemList;
  }
}
