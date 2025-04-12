import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/spies_controller.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/widgets/stats/estimated_stats_dialog.dart';
import 'package:torn_pda/widgets/stats/spies_exact_details_dialog.dart';
import 'package:torn_pda/widgets/stats/tcs_stats_dialog.dart';
import 'package:torn_pda/widgets/stats/yata_stats_dialog.dart';

class SpiesPayload {
  const SpiesPayload({
    required this.spyController,
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
    required this.spySource,
    required this.update,
    required this.name,
    required this.factionName,
    required this.themeProvider,
    required this.userDetailsProvider,
  });

  final SpiesController spyController;
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
  final SpiesSource? spySource;
  final String? name;
  final String? factionName;
  final ThemeProvider themeProvider;
  final UserDetailsProvider userDetailsProvider;
}

class EstimatedStatsPayload {
  const EstimatedStatsPayload({
    required this.xanaxCompare,
    required this.xanaxColor,
    required this.refillCompare,
    required this.refillColor,
    required this.enhancementCompare,
    required this.enhancementColor,
    required this.cansCompare,
    required this.cansColor,
    required this.sslColor,
    required this.sslProb,
    required this.otherXanTaken,
    required this.otherEctTaken,
    required this.otherLsdTaken,
    required this.otherName,
    required this.otherFactionName,
    required this.otherLastActionRelative,
    required this.themeProvider,
  });

  final int xanaxCompare;
  final Color xanaxColor;
  final int refillCompare;
  final Color refillColor;
  final int enhancementCompare;
  final Color? enhancementColor;
  final int cansCompare;
  final Color cansColor;
  final Color sslColor;
  final bool sslProb;
  final int otherXanTaken;
  final int otherEctTaken;
  final int otherLsdTaken;
  final String otherName;
  final String otherFactionName;
  final String otherLastActionRelative;
  final ThemeProvider themeProvider;
}

class TSCStatsPayload {
  const TSCStatsPayload({
    required this.targetId,
  });

  final int targetId;
}

class YataStatsPayload {
  const YataStatsPayload({
    required this.targetId,
  });

  final int targetId;
}

class StatsDialog extends StatefulWidget {
  const StatsDialog({
    required this.spiesPayload,
    required this.estimatedStatsPayload,
    required this.tscStatsPayload,
    required this.yataStatsPayload,
  });

  final SpiesPayload? spiesPayload;
  final EstimatedStatsPayload estimatedStatsPayload;
  final TSCStatsPayload? tscStatsPayload;
  final YataStatsPayload? yataStatsPayload;

  @override
  State<StatsDialog> createState() => _StatsDialogState();
}

class _StatsDialogState extends State<StatsDialog> with TickerProviderStateMixin {
  late SettingsProvider _settingsProvider;
  late ThemeProvider _themeProvider;
  late bool _spyExists;
  late TabController _tabController;
  late int _originTab;

  bool _disableTSCcalledBack = false;

  @override
  void initState() {
    super.initState();
    _settingsProvider = context.read<SettingsProvider>();
    _spyExists = widget.spiesPayload != null;
    _tabController = TabController(vsync: this, length: _getLength());
    _tabController.index = _spyExists ? 0 : 1;
    _originTab = _spyExists ? 0 : 1;
    _tabController.addListener(_onTabTapped);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: DefaultTabController(
          initialIndex: _spyExists ? 0 : 1,
          length: _getLength(),
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
                title: Text((widget.estimatedStatsPayload.otherName).isNotEmpty
                    ? widget.estimatedStatsPayload.otherName
                    : "Stats"),
                bottom: TabBar(
                  controller: _tabController,
                  onTap: (int index) {
                    // Get current index to decide if we need to proceed
                    _originTab = _tabController.index;
                  },
                  tabs: <Widget>[
                    Tab(
                      icon: Icon(
                        MdiIcons.incognito,
                        color: _spyExists ? Colors.white : Colors.grey[800],
                      ),
                    ),
                    Tab(
                      icon: Icon(MdiIcons.compareHorizontal, color: Colors.white),
                    ),
                    if (widget.tscStatsPayload != null &&
                        !_disableTSCcalledBack &&
                        _settingsProvider.tscEnabledStatusRemoteConfig)
                      Tab(
                        child: Text(
                          "T S C",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    if (widget.yataStatsPayload != null && _settingsProvider.yataStatsEnabledStatusRemoteConfig)
                      Tab(
                        child: Image.asset('images/icons/yata_logo.png', height: 30),
                      ),
                  ],
                ),
              ),
              body: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: <Widget>[
                  if (widget.spiesPayload != null)
                    SingleChildScrollView(
                      child: Container(
                        color: _themeProvider.accesibilityNoTextColors ? _themeProvider.cardColor : null,
                        child: Column(
                          children: [
                            SpiesExactDetailsDialog(
                              spiesPayload: widget.spiesPayload!,
                              themeProvider: _themeProvider,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(),
                  Container(
                    color: _themeProvider.accesibilityNoTextColors ? _themeProvider.cardColor : null,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          EstimatedStatsDialog(
                            estimatedStatsPayload: widget.estimatedStatsPayload,
                            themeProvider: _themeProvider,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (widget.tscStatsPayload != null &&
                      !_disableTSCcalledBack &&
                      _settingsProvider.tscEnabledStatusRemoteConfig)
                    SingleChildScrollView(
                      child: Container(
                        color: _themeProvider.accesibilityNoTextColors ? _themeProvider.cardColor : null,
                        child: Column(
                          children: [
                            TSCStatsDialog(
                              tscStatsPayload: widget.tscStatsPayload!,
                              themeProvider: _themeProvider,
                              callBackToDisableTSCtab: _disableTSC,
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (widget.yataStatsPayload != null && _settingsProvider.yataStatsEnabledStatusRemoteConfig)
                    SingleChildScrollView(
                      child: Container(
                        color: _themeProvider.accesibilityNoTextColors ? _themeProvider.cardColor : null,
                        child: Column(
                          children: [
                            YataStatsDialog(
                              yataStatsPayload: widget.yataStatsPayload!,
                              themeProvider: _themeProvider,
                            ),
                          ],
                        ),
                      ),
                    )
                ],
              ),
            ),
          ),
        ));
  }

  _onTabTapped() async {
    if (!_spyExists && _tabController.index == 0) {
      setState(() {
        _tabController.index = _originTab;
      });
      BotToast.showText(
        clickClose: true,
        text: "No spy record available!",
        textStyle: const TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
        contentColor: Colors.red,
        duration: const Duration(seconds: 2),
        contentPadding: const EdgeInsets.all(10),
      );
    }
  }

  _disableTSC() {
    setState(() {
      _disableTSCcalledBack = true;
      _tabController.index = 1;
      _tabController.dispose();
      _tabController = TabController(vsync: this, length: _getLength());
    });
  }

  /// Gets tabs lengthd depending on modules enabled by user
  int _getLength() {
    int total = 2;

    if (widget.tscStatsPayload != null && !_disableTSCcalledBack && _settingsProvider.tscEnabledStatusRemoteConfig) {
      total++;
    }

    if (widget.yataStatsPayload != null && _settingsProvider.yataStatsEnabledStatusRemoteConfig) {
      total++;
    }

    return total;
  }
}
