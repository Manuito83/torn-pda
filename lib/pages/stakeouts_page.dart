// Dart imports:
import 'dart:async';
// Package imports:
import 'package:bot_toast/bot_toast.dart';
// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:torn_pda/drawer.dart';
// Project imports:
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/stakeouts_controller.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/time_formatter.dart';
import 'package:torn_pda/widgets/stakeouts/stakeout_card.dart';
import 'package:torn_pda/widgets/stakeouts/stakeouts_info_dialog.dart';
import 'package:torn_pda/widgets/pda_browser_icon.dart';

class StakeoutsPage extends StatefulWidget {
  const StakeoutsPage({
    super.key,
  });

  @override
  StakeoutsPageState createState() => StakeoutsPageState();
}

class StakeoutsPageState extends State<StakeoutsPage> {
  final _addIdController = TextEditingController();
  final _addFormKey = GlobalKey<FormState>();

  final StakeoutsController _s = Get.find();
  late ThemeProvider _themeProvider;
  late SettingsProvider _settingsProvider;
  late WebViewProvider _webViewProvider;

  // Showcases
  final GlobalKey _showcaseInfo = GlobalKey();

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    routeWithDrawer = true;
    routeName = "stakeouts";
  }

  @override
  Future dispose() async {
    _addIdController.dispose();
    Get.delete<StakeoutsController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context);
    _webViewProvider = Provider.of<WebViewProvider>(context);

    return ShowCaseWidget(
      builder: Builder(
        builder: (_) {
          _launchShowCases(_);
          return Scaffold(
            backgroundColor: _themeProvider.canvas,
            drawer: const Drawer(),
            appBar: _settingsProvider.appBarTop ? buildAppBar(_) : null,
            bottomNavigationBar: !_settingsProvider.appBarTop
                ? SizedBox(
                    height: AppBar().preferredSize.height,
                    child: buildAppBar(_),
                  )
                : null,
            body: Container(
              color: _themeProvider.currentTheme == AppTheme.extraDark ? Colors.black : Colors.transparent,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
                child: MediaQuery.orientationOf(context) == Orientation.portrait
                    ? _mainColumn()
                    : SingleChildScrollView(
                        child: _mainColumn(),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _launchShowCases(BuildContext _) {
    Future.delayed(const Duration(seconds: 1), () async {
      /*
      List showCases = <GlobalKey<State<StatefulWidget>>>[];
      if (!_settingsProvider.showCases.contains("stakeouts_info")) {
        _settingsProvider.addShowCase = "stakeouts_info";
        showCases.add(_showCaseInfo);
      }
      if (showCases.isNotEmpty) {
        ShowCaseWidget.of(_).startShowCase(showCases);
      }
      */
    });
  }

  Widget _mainColumn() {
    return GetBuilder<StakeoutsController>(
      builder: (s) {
        final int sleepTime = s.timeUntilStakeoutsSlept();
        String? sleepString = "";
        if (sleepTime > 0) {
          sleepString = TimeFormatter(
            inputTime: DateTime.fromMillisecondsSinceEpoch(sleepTime),
            timeFormatSetting: _settingsProvider.currentTimeFormat,
            timeZoneSetting: _settingsProvider.currentTimeZone,
          ).formatHour;
        }

        return Column(
          children: <Widget>[
            if (sleepTime > 0)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        const Text("Alerts silenced until"),
                        Text(sleepString!),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () => s.disableSleepStakeouts(),
                      child: const Text("Deactivate"),
                    ),
                  ],
                ),
              ),
            if (_s.stakeouts.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 100, 20, 0),
                child: Column(
                  children: [
                    const Text(
                      "No stakeout targets!",
                      textAlign: TextAlign.center,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Add your first one:",
                          textAlign: TextAlign.center,
                        ),
                        IconButton(
                          icon: const Icon(
                            MdiIcons.cameraPlusOutline,
                            size: 30,
                          ),
                          onPressed: () {
                            _showAddDialog();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            if (context.orientation == Orientation.portrait)
              Flexible(child: StakeoutTargetsList(stakeoutsController: s))
            else
              StakeoutTargetsList(stakeoutsController: s),
          ],
        );
      },
    );
  }

  AppBar buildAppBar(BuildContext _) {
    return AppBar(
      iconTheme: IconThemeData(color: Colors.white),
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      title: const Text("Stakeouts", style: TextStyle(color: Colors.white)),
      leadingWidth: _webViewProvider.webViewSplitActive ? 50 : 80,
      leading: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              final ScaffoldState? scaffoldState = context.findRootAncestorStateOfType();
              if (scaffoldState != null) {
                if (_webViewProvider.webViewSplitActive &&
                    _webViewProvider.splitScreenPosition == WebViewSplitPosition.left) {
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
        IconButton(
          icon: const Icon(MdiIcons.cameraPlusOutline),
          color: _s.stakeouts.length >= 15 ? Colors.grey : Colors.white,
          onPressed: () {
            if (_s.stakeouts.length >= 15) {
              BotToast.showText(
                text: "You have reached a maximum of 15 stakeout targets!",
                textStyle: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
                contentColor: Colors.grey[800]!,
                duration: const Duration(seconds: 3),
                contentPadding: const EdgeInsets.all(10),
              );
            } else {
              _showAddDialog();
            }
          },
        ),
        Showcase(
          key: _showcaseInfo,
          title: 'Stakeouts information',
          description: '\nMake sure to read this to understand how stakeouts are implemented in Torn PDA!',
          targetPadding: const EdgeInsets.all(10),
          disableMovingAnimation: true,
          textColor: _themeProvider.mainText!,
          tooltipBackgroundColor: _themeProvider.secondBackground!,
          descTextStyle: const TextStyle(fontSize: 13),
          tooltipPadding: const EdgeInsets.all(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: GestureDetector(
              child: Image.asset(
                'images/icons/gear_info.png',
                width: 24,
                color: _themeProvider.currentTheme == AppTheme.light ? Colors.white : _themeProvider.mainText,
              ),
              onTap: () {
                showDialog<void>(
                  context: context,
                  barrierDismissible: false, // user must tap button!
                  builder: (BuildContext context) {
                    return const StakeoutsInfoDialog();
                  },
                );
              },
            ),
          ),
        ),
        GetBuilder<StakeoutsController>(
          builder: (s) {
            return Switch(
              value: s.stakeoutsEnabled!,
              onChanged: (value) {
                value ? s.enableStakeOuts() : s.disableStakeouts();
                BotToast.showText(text: "Stakeouts ${value ? 'enabled' : 'disabled'}!");
              },
              activeTrackColor: Colors.lightGreenAccent,
              activeColor: Colors.green,
            );
          },
        ),
      ],
    );
  }

  Future<void> _showAddDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0.0,
          backgroundColor: Colors.transparent,
          content: SingleChildScrollView(
            child: Stack(
              children: <Widget>[
                SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.only(
                      top: 45,
                      bottom: 16,
                      left: 16,
                      right: 16,
                    ),
                    margin: const EdgeInsets.only(top: 30),
                    decoration: BoxDecoration(
                      color: _themeProvider.secondBackground,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10.0,
                          offset: Offset(0.0, 10.0),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _addFormKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // To make the card compact
                        children: <Widget>[
                          TextFormField(
                            style: const TextStyle(fontSize: 14),
                            controller: _addIdController,
                            maxLength: 10,
                            minLines: 1,
                            maxLines: 2,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              counterText: "",
                              border: OutlineInputBorder(),
                              labelText: 'Insert player ID',
                            ),
                            validator: (value) {
                              if (value!.isEmpty) {
                                return "Cannot be empty!";
                              }
                              final n = num.tryParse(value);
                              if (n == null) {
                                return '$value is not a valid ID!';
                              }
                              _addIdController.text = value.trim();
                              return null;
                            },
                          ),
                          const SizedBox(height: 16.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              TextButton(
                                child: const Text("Add"),
                                onPressed: () async {
                                  if (_addFormKey.currentState!.validate()) {
                                    // Get rid of dialog first
                                    Navigator.of(context).pop();
                                    // Copy controller's text ot local variable
                                    final inputId = _addIdController.text;
                                    _addIdController.text = '';

                                    final tryAddStakeout = await _s.addStakeout(inputId: inputId);

                                    BotToast.showText(
                                      text: tryAddStakeout.success
                                          ? 'Added ${tryAddStakeout.name} [${tryAddStakeout.id}]'
                                          : 'Error adding $inputId: ${tryAddStakeout.error}',
                                      textStyle: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                      contentColor: tryAddStakeout.success ? Colors.green : Colors.orange[700]!,
                                      duration: const Duration(seconds: 3),
                                      contentPadding: const EdgeInsets.all(10),
                                    );
                                  }
                                },
                              ),
                              TextButton(
                                child: const Text("Cancel"),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  _addIdController.text = '';
                                },
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: _themeProvider.secondBackground,
                    child: CircleAvatar(
                      backgroundColor: _themeProvider.mainText,
                      radius: 22,
                      child: const SizedBox(
                        height: 28,
                        width: 28,
                        child: Icon(MdiIcons.cctv),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class StakeoutTargetsList extends StatelessWidget {
  const StakeoutTargetsList({
    required this.stakeoutsController,
  });

  final StakeoutsController stakeoutsController;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.orientationOf(context) == Orientation.portrait) {
      return ListView(
        shrinkWrap: true,
        children: getCards(),
      );
    } else {
      return ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: getCards(),
      );
    }
  }

  List<Widget> getCards() {
    List<StakeoutCard> stakeoutCards = <StakeoutCard>[];

    for (final stakeout in stakeoutsController.stakeouts) {
      stakeoutCards.add(
        StakeoutCard(
          key: UniqueKey(),
          stakeout: stakeout,
        ),
      );
    }

    stakeoutsController.orderedCardsDetails.clear();
    for (int i = 0; i < stakeoutCards.length; i++) {
      final StakeoutCardDetails details = StakeoutCardDetails()..cardPosition = i + 1;
      stakeoutsController.orderedCardsDetails.add(details);
    }

    return stakeoutCards;
  }
}
