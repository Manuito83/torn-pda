// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:provider/provider.dart';

// Project imports:
import 'package:torn_pda/models/chaining/yata/yata_distribution_models.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';

class YataTargetsDistribution extends StatefulWidget {
  final List<TargetsOnlyYata> onlyYata;
  final List<TargetsOnlyLocal> onlyLocal;
  final List<TargetsBothSides> bothSides;

  YataTargetsDistribution({
    @required this.bothSides,
    @required this.onlyYata,
    @required this.onlyLocal,
  });

  @override
  _YataTargetsDistributionState createState() => _YataTargetsDistributionState();
}

class _YataTargetsDistributionState extends State<YataTargetsDistribution> {
  SettingsProvider _settingsProvider;
  ThemeProvider _themeProvider;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return Container(
      color: _themeProvider.currentTheme == AppTheme.light
          ? MediaQuery.of(context).orientation == Orientation.portrait
              ? Colors.blueGrey
              : Colors.grey[900]
          : _themeProvider.currentTheme == AppTheme.dark
              ? Colors.grey[900]
              : Colors.black,
      child: SafeArea(
        top: _settingsProvider.appBarTop ? false : true,
        bottom: true,
        child: Scaffold(
          backgroundColor: _themeProvider.basicBackground,
          drawer: Drawer(),
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
                      Text(
                        'TARGETS ONLY IN YATA',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '(CAN BE IMPORTED)',
                        style: TextStyle(
                          fontSize: 11,
                        ),
                      ),
                      SizedBox(height: 10),
                      Column(
                        children: _returnTargetsOnlyInYata(),
                      ),
                      SizedBox(height: 10),
                      Divider(),
                      SizedBox(height: 10),
                      Text(
                        'COMMON TARGETS',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '(ONLY NOTES UPDATED)',
                        style: TextStyle(
                          fontSize: 11,
                        ),
                      ),
                      SizedBox(height: 10),
                      Column(
                        children: _returnTargetsBothSides(),
                      ),
                      SizedBox(height: 10),
                      Divider(),
                      SizedBox(height: 10),
                      Text(
                        'TARGETS ONLY IN TORN PDA',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '(CAN BE EXPORTED)',
                        style: TextStyle(
                          fontSize: 11,
                        ),
                      ),
                      SizedBox(height: 10),
                      Column(
                        children: _returnTargetsOnlyInTornPDA(),
                      ),
                      SizedBox(height: 10),
                      SizedBox(height: 50),
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
      title: Text('YATA targets'),
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  List<Widget> _returnTargetsOnlyInYata() {
    var itemList = <Widget>[];

    if (widget.onlyYata.isEmpty) {
      itemList.add(
        Text(
          "none",
          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
        ),
      );
    } else {
      for (var yataTarget in widget.onlyYata) {
        itemList.add(
          Text(
            "${yataTarget.name} [${yataTarget.id}]",
            style: TextStyle(fontSize: 12),
          ),
        );
      }
    }

    return itemList;
  }

  List<Widget> _returnTargetsBothSides() {
    var itemList = <Widget>[];

    if (widget.bothSides.isEmpty) {
      itemList.add(
        Text(
          "none",
          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
        ),
      );
    } else {
      for (var bothSidesTarget in widget.bothSides) {
        itemList.add(
          Text(
            "${bothSidesTarget.name} [${bothSidesTarget.id}]",
            style: TextStyle(fontSize: 12),
          ),
        );
      }
    }

    return itemList;
  }

  List<Widget> _returnTargetsOnlyInTornPDA() {
    var itemList = <Widget>[];

    if (widget.onlyLocal.isEmpty) {
      itemList.add(
        Text(
          "none",
          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
        ),
      );
    } else {
      for (var localTarget in widget.onlyLocal) {
        itemList.add(
          Text(
            "${localTarget.name} [${localTarget.id}]",
            style: TextStyle(fontSize: 12),
          ),
        );
      }
    }

    return itemList;
  }
}
