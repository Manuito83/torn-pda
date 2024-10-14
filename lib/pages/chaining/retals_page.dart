// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/drawer.dart';
import 'package:torn_pda/models/chaining/retal_model.dart';
import 'package:torn_pda/providers/retals_controller.dart';
// Project imports:
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/spies_controller.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/widgets/chaining/chain_widget.dart';
import 'package:torn_pda/widgets/chaining/retal_card.dart';
import 'package:torn_pda/widgets/countdown.dart';
import 'package:torn_pda/widgets/spies/spies_management_dialog.dart';
import 'package:torn_pda/widgets/pda_browser_icon.dart';

class RetalsOptions {
  String? description;
  IconData? iconData;

  RetalsOptions({this.description}) {
    switch (description) {
      case "Manage Spies":
        iconData = MdiIcons.incognito;
    }
  }
}

class RetalsPage extends StatefulWidget {
  final RetalsController retalsController;

  const RetalsPage({
    required this.retalsController,
    super.key,
  });

  @override
  RetalsPageState createState() => RetalsPageState();
}

class RetalsPageState extends State<RetalsPage> {
  final _chainWidgetKey = GlobalKey();

  RetalsController? _r;
  late ThemeProvider _themeProvider;
  late SettingsProvider _settingsProvider;
  late WebViewProvider _webViewProvider;

  final _popupOptionsChoices = <RetalsOptions>[
    RetalsOptions(description: "Manage Spies"),
  ];

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    routeWithDrawer = true;
    routeName = "chaining_retals";
  }

  @override
  Future dispose() async {
    Get.delete<RetalsController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _r ??= widget.retalsController;

    _themeProvider = Provider.of<ThemeProvider>(context);
    _webViewProvider = Provider.of<WebViewProvider>(context);

    return Scaffold(
      backgroundColor: _themeProvider.canvas,
      drawer: !_webViewProvider.splitScreenAndBrowserLeft() ? const Drawer() : null,
      endDrawer: !_webViewProvider.splitScreenAndBrowserLeft() ? null : const Drawer(),
      appBar: _settingsProvider.appBarTop ? buildAppBar(context) : null,
      bottomNavigationBar: !_settingsProvider.appBarTop
          ? SizedBox(
              height: AppBar().preferredSize.height,
              child: buildAppBar(context),
            )
          : null,
      body: GetBuilder<RetalsController>(
        builder: (r) => Container(
          color: _themeProvider.currentTheme == AppTheme.extraDark ? Colors.black : Colors.transparent,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
            child: MediaQuery.orientationOf(context) == Orientation.portrait
                ? Column(
                    children: [
                      _topWidgets(r),
                      Flexible(child: _mainCards(r)),
                    ],
                  )
                : r.retaliationList.isEmpty
                    ? Column(
                        children: [
                          _topWidgets(r),
                          Flexible(child: _mainCards(r)),
                        ],
                      )
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            _topWidgets(r),
                            _mainCards(r),
                          ],
                        ),
                      ),
          ),
        ),
      ),
    );
  }

  Widget _topWidgets(RetalsController r) {
    return Column(
      children: <Widget>[
        ChainWidget(
          key: _chainWidgetKey,
          alwaysDarkBackground: false,
          callBackOptions: _callBackChainOptions,
        ),
        if (r.updating)
          const CircularProgressIndicator()
        else
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Next update in "),
                Countdown(
                  seconds: 20,
                  callback: _updateRetal,
                ),
                const Text(" seconds"),
              ],
            ),
          ),
      ],
    );
  }

  Widget _mainCards(RetalsController r) {
    return Column(
      children: <Widget>[
        const SizedBox(height: 5),
        if (r.retaliationList.isEmpty)
          const Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: 100),
                  child: Text("No retaliation targets found!"),
                ),
              ],
            ),
          )
        else
          context.orientation == Orientation.portrait
              ? Flexible(
                  child: RetalsTargetsList(
                    retalsController: r,
                  ),
                )
              : RetalsTargetsList(
                  retalsController: r,
                ),
        if (_settingsProvider.appBarTop) const SizedBox(height: 50),
      ],
    );
  }

  AppBar buildAppBar(BuildContext _) {
    return AppBar(
      iconTheme: IconThemeData(color: Colors.white),
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      title: const Text("Retaliation", style: TextStyle(color: Colors.white)),
      leadingWidth: _webViewProvider.webViewSplitActive ? 50 : 88,
      leading: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              final ScaffoldState? scaffoldState = context.findRootAncestorStateOfType();
              if (scaffoldState != null) {
                if (_webViewProvider.splitScreenAndBrowserLeft()) {
                  scaffoldState.openEndDrawer();
                } else {
                  scaffoldState.openDrawer();
                }
              }
            },
          ),
          if (!_webViewProvider.webViewSplitActive) PdaBrowserIcon(),
        ],
      ),
      actions: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: GetBuilder<RetalsController>(
            builder: (r) {
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  child: const Icon(Icons.info_outline_rounded),
                  // Quick update
                  onTap: () async {
                    await showDialog(
                      useRootNavigator: false,
                      context: context,
                      builder: (BuildContext context) {
                        return _disclaimerDialog();
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
        GetBuilder<RetalsController>(
          builder: (r) {
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: r.updating
                    ? null
                    : () {
                        r.retrieveRetals(context);
                      },
                child: const Icon(Icons.refresh),
              ),
            );
          },
        ),
        PopupMenuButton<RetalsOptions>(
          icon: const Icon(Icons.settings),
          onSelected: (selection) {
            switch (selection.description) {
              case "Manage Spies":
                showDialog(
                  barrierDismissible: false,
                  useRootNavigator: false,
                  context: context,
                  builder: (BuildContext context) {
                    return SpiesManagementDialog();
                  },
                );
                break;
            }
          },
          itemBuilder: (BuildContext context) {
            final spyController = Get.find<SpiesController>();
            String lastUpdated = "Never updated";
            int lastUpdatedTs = 0;

            if (spyController.spiesSource == SpiesSource.yata && spyController.yataSpiesTime != null) {
              lastUpdatedTs = spyController.yataSpiesTime!.millisecondsSinceEpoch;
              lastUpdated = spyController.statsOld((lastUpdatedTs / 1000).round());
            } else if (spyController.spiesSource == SpiesSource.tornStats && spyController.tornStatsSpiesTime != null) {
              lastUpdatedTs = spyController.tornStatsSpiesTime!.millisecondsSinceEpoch;
              lastUpdated = spyController.statsOld((lastUpdatedTs / 1000).round());
            }

            final currentTime = DateTime.now().millisecondsSinceEpoch;
            final oneMonthAgo = currentTime - (30.44 * 24 * 60 * 60 * 1000).round();
            final spiesUpdateColor = (lastUpdatedTs < oneMonthAgo) ? Colors.red : _themeProvider.mainText;

            return _popupOptionsChoices.where((RetalsOptions choice) {
              return true;
            }).map((RetalsOptions choice) {
              // Spies
              if (choice.description!.contains("Manage Spies")) {
                return PopupMenuItem<RetalsOptions>(
                  value: choice,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 13),
                        child: Icon(
                          MdiIcons.incognito,
                          size: 24,
                          color: _themeProvider.mainText,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text("Manage Spies"),
                                const SizedBox(width: 8),
                                SizedBox(
                                  height: 25,
                                  width: 25,
                                  child: Image.asset(
                                    spyController.spiesSource == SpiesSource.yata
                                        ? 'images/icons/yata_logo.png'
                                        : 'images/icons/tornstats_logo.png',
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              lastUpdated,
                              style: TextStyle(fontSize: 11, color: spiesUpdateColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
              // Everything else
              return PopupMenuItem<RetalsOptions>(
                value: choice,
                child: Row(
                  children: [
                    Icon(choice.iconData, size: 20, color: _themeProvider.mainText),
                    const SizedBox(width: 10),
                    Text(choice.description!),
                  ],
                ),
              );
            }).toList();
          },
        ),
      ],
    );
  }

  void _callBackChainOptions() {
    setState(() {
      // Makes sure to update cards' border when out of panic options
    });
  }

  void _updateRetal() {
    if (_r!.browserIsOpen) return;
    _r!.retrieveRetals(context);
  }

  AlertDialog _disclaimerDialog() {
    return AlertDialog(
      title: const Text("Retaliation"),
      content: const Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "A retaliation hit is an attack (hospitalisation only) made on someone that has attacked one of "
                  "your faction members within the last 5 minutes. Retaliations provide a multiplier of 1.5x, and can "
                  "only be claimed once on a player until they attack your faction again.",
                  style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                ),
                SizedBox(height: 25),
                Text(
                  "This section shows targets that:\n",
                  style: TextStyle(fontSize: 13),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Text(
                    "- Attacked your faction in the last 5 minutes",
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Text(
                    "- Won the attack",
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Text(
                    "- Have not been retaliated yet",
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                SizedBox(height: 25),
                Text(
                  "IMPORTANT",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                Text(
                  "\nPlease note that this section can potentially make a intensive use of the API if there are "
                  "lots of targets available to retaliate.\n\nIt will auto-update every few seconds; any attempt to "
                  "manually update at lower intervals could result in the API limits being reached in this or other "
                  "sections.",
                  style: TextStyle(fontSize: 13),
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton(
            child: const Text("Understood"),
            onPressed: () {
              Navigator.of(context).pop('exit');
            },
          ),
        ),
      ],
    );
  }
}

class RetalsTargetsList extends StatelessWidget {
  const RetalsTargetsList({
    required this.retalsController,
  });

  final RetalsController retalsController;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.orientationOf(context) == Orientation.portrait) {
      return ListView(
        shrinkWrap: true,
        children: getChildrenTargets(),
      );
    } else {
      return ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: getChildrenTargets(),
      );
    }
  }

  List<Widget> getChildrenTargets() {
    List<RetalCard> filteredCards = <RetalCard>[];

    for (final Retal thisRetal in retalsController.retaliationList) {
      filteredCards.add(
        RetalCard(
          key: ValueKey(thisRetal.retalId),
          retalModel: thisRetal,
          expiryTimeStamp: thisRetal.retalExpiry,
        ),
      );
    }

    filteredCards.sort((a, b) => b.expiryTimeStamp.compareTo(a.expiryTimeStamp));

    retalsController.orderedCardsDetails.clear();
    for (int i = 0; i < filteredCards.length; i++) {
      final RetalsCardDetails details = RetalsCardDetails()
        ..cardPosition = i + 1
        ..retalId = filteredCards[i].retalModel.retalId
        ..name = filteredCards[i].retalModel.name
        ..personalNote = filteredCards[i].retalModel.personalNote
        ..personalNoteColor = filteredCards[i].retalModel.personalNoteColor;

      retalsController.orderedCardsDetails.add(details);
    }

    return filteredCards;
  }
}
