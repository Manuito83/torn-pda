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
// Project imports:
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/stakeouts_controller.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/time_formatter.dart';
import 'package:torn_pda/widgets/chaining/stakeout_card.dart';

class StakeoutsPage extends StatefulWidget {
  const StakeoutsPage({
    Key key,
  }) : super(key: key);

  @override
  _StakeoutsPageState createState() => _StakeoutsPageState();
}

class _StakeoutsPageState extends State<StakeoutsPage> {
  final _addIdController = TextEditingController();
  final _addFormKey = GlobalKey<FormState>();

  StakeoutsController _s = Get.find();
  ThemeProvider _themeProvider;
  SettingsProvider _settingsProvider;
  WebViewProvider _webViewProvider;

  // Showcases
  GlobalKey _showcaseInfo = GlobalKey();

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _webViewProvider = context.read<WebViewProvider>();
  }

  @override
  Future dispose() async {
    _addIdController.dispose();
    Get.delete<StakeoutsController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);

    return ShowCaseWidget(
      builder: Builder(builder: (_) {
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
              child: MediaQuery.of(context).orientation == Orientation.portrait
                  ? _mainColumn()
                  : SingleChildScrollView(
                      child: _mainColumn(),
                    ),
            ),
          ),
        );
      }),
    );
  }

  void _launchShowCases(BuildContext _) {
    Future.delayed(Duration(seconds: 1), () async {
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
    return GetBuilder<StakeoutsController>(builder: (s) {
      int sleepTime = s.timeUntilStakeoutsSlept();
      String sleepString = "";
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
                      Text("Alerts silenced until"),
                      Text(sleepString),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () => s.disableSleepStakeouts(),
                    child: Text("Deactivate"),
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
    });
  }

  AppBar buildAppBar(BuildContext _) {
    return AppBar(
      //brightness: Brightness.dark, // For downgrade to Flutter 2.2.3
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      title: const Text("Stakeouts"),
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () {
          final ScaffoldState scaffoldState = context.findRootAncestorStateOfType();
          scaffoldState.openDrawer();
        },
      ),
      actions: <Widget>[
        IconButton(
          icon: Icon(MdiIcons.cameraPlusOutline),
          onPressed: () {
            _showAddDialog();
          },
        ),
        Showcase(
          key: _showcaseInfo,
          title: 'Stakeouts information',
          description: '\nMake sure to read this to understand how stakeouts are implemented in Torn PDA!',
          targetPadding: const EdgeInsets.all(10),
          disableMovingAnimation: true,
          textColor: _themeProvider.mainText,
          tooltipBackgroundColor: _themeProvider.secondBackground,
          descTextStyle: TextStyle(fontSize: 13),
          tooltipPadding: EdgeInsets.all(20),
          child: IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () {
              //TODO
            },
          ),
        ),
        GetBuilder<StakeoutsController>(builder: (s) {
          return Switch(
            value: s.stakeoutsEnabled,
            onChanged: (value) {
              s.stakeoutsEnabled = value;
              BotToast.showText(text: "Stakeouts ${value ? 'enabled' : 'disabled'}!");
            },
            activeTrackColor: Colors.lightGreenAccent,
            activeColor: Colors.green,
          );
        }),
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
                              if (value.isEmpty) {
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
                                  if (_addFormKey.currentState.validate()) {
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
                                      contentColor: tryAddStakeout.success ? Colors.green : Colors.orange[700],
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
                      child: SizedBox(
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
  StakeoutTargetsList({
    @required this.stakeoutsController,
  });

  final StakeoutsController stakeoutsController;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      return ListView(
        shrinkWrap: true,
        children: getCards(),
      );
    } else {
      return ListView(
        children: getCards(),
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
      );
    }
  }

  List<Widget> getCards() {
    List<StakeoutCard> stakeoutCards = <StakeoutCard>[];

    stakeoutsController.stakeouts.forEach((stakeout) {
      stakeoutCards.add(
        StakeoutCard(
          key: UniqueKey(),
          stakeout: stakeout,
        ),
      );
    });

    stakeoutsController.orderedCardsDetails.clear();
    for (int i = 0; i < stakeoutCards.length; i++) {
      StakeoutCardDetails details = StakeoutCardDetails()..cardPosition = i + 1;
      stakeoutsController.orderedCardsDetails.add(details);
    }

    return stakeoutCards;
  }
}
