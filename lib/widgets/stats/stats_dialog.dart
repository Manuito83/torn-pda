import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/spies_controller.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/widgets/stats/spies_exact_details_dialog.dart';

class SpiesPayload {
  const SpiesPayload({
    required this.spy,
    required this.strength,
    required this.strengthUpdate,
    required this.defense,
    required this.defenseUpdate,
    required this.speed,
    required this.speedUpdate,
    required this.dexterity,
    required this.dexterityUpdate,
    required this.total,
    required this.totalUpdate,
    required this.update,
    required this.name,
    required this.factionName,
    required this.themeProvider,
    required this.userDetailsProvider,
  });

  final SpiesController spy;
  final int? strength;
  final int? strengthUpdate;
  final int? defense;
  final int? defenseUpdate;
  final int? speed;
  final int? speedUpdate;
  final int? dexterity;
  final int? dexterityUpdate;
  final int? total;
  final int? totalUpdate;
  final int? update;
  final String? name;
  final String? factionName;
  final ThemeProvider themeProvider;
  final UserDetailsProvider userDetailsProvider;
}

class StatsDialog extends StatefulWidget {
  const StatsDialog({
    required this.spiesPayload,
  });

  final SpiesPayload spiesPayload;

  @override
  State<StatsDialog> createState() => _StatsDialogState();
}

class _StatsDialogState extends State<StatsDialog> {
  late ThemeProvider _themeProvider;

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: DefaultTabController(
          initialIndex: 1,
          length: 3,
          child: Container(
            height: 550,
            child: Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                title: Text((widget.spiesPayload.name ?? "").isNotEmpty ? "${widget.spiesPayload.name}" : "Stats"),
                bottom: const TabBar(
                  tabs: <Widget>[
                    Tab(
                      icon: Icon(Icons.cloud_outlined),
                    ),
                    Tab(
                      icon: Icon(Icons.beach_access_sharp),
                    ),
                    Tab(
                      icon: Icon(Icons.brightness_5_sharp),
                    ),
                  ],
                ),
              ),
              body: TabBarView(
                children: <Widget>[
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        SpiesExactDetailsDialog(
                          spiesPayload: widget.spiesPayload,
                          themeProvider: _themeProvider,
                        ),
                      ],
                    ),
                  ),
                  Center(
                    child: Text("It's rainy here"),
                  ),
                  Center(
                    child: Text("It's sunny here"),
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}
