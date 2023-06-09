import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:torn_pda/models/chaining/chain_panic_target_model.dart';
import 'package:torn_pda/models/chaining/target_model.dart';
import 'package:torn_pda/models/faction/faction_model.dart';
import 'package:torn_pda/models/stakeouts/stakeout_model.dart';
import 'package:torn_pda/providers/chain_status_provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/stakeouts_controller.dart';
import 'package:torn_pda/providers/targets_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/war_controller.dart';
import 'package:torn_pda/providers/api_caller.dart';
import 'package:torn_pda/utils/html_parser.dart';

class ProfileCheckAddButton extends StatefulWidget {
  final int profileId;
  final int factionId;
  final String playerName;

  const ProfileCheckAddButton({
    @required this.profileId,
    @required this.factionId,
    this.playerName = "Player",
    Key key,
  }) : super(key: key);

  @override
  State<ProfileCheckAddButton> createState() => _ProfileCheckAddButtonState();
}

class _ProfileCheckAddButtonState extends State<ProfileCheckAddButton> {
  ThemeProvider _themeProvider;
  SettingsProvider _settingsProvider;
  TargetsProvider _targetsProvider;
  ChainStatusProvider _chainStatusProvider;

  // Showcases
  GlobalKey _showcaseButton = GlobalKey();

  @override
  Widget build(BuildContext context) {
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    _targetsProvider = Provider.of<TargetsProvider>(context, listen: true);
    _chainStatusProvider = Provider.of<ChainStatusProvider>(context, listen: true);

    bool anyExists = _anyExists();

    return ShowCaseWidget(
      builder: Builder(
        builder: (_) {
          _launchShowCases(_);
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              child: GetBuilder<StakeoutsController>(
                builder: (s) {
                  // No need to initialise stakeouts as it's a permanent controller
                  return GetBuilder<WarController>(
                    // Initialise WarController as it isn't used elsewhere in this class
                    init: WarController(),
                    builder: (w) {
                      anyExists = _anyExists();
                      for (Stakeout s in s.stakeouts) {
                        if (s.id == widget.profileId.toString()) {
                          anyExists = true;
                          continue;
                        }
                      }

                      for (FactionModel w in w.factions) {
                        if (w.id == widget.factionId) {
                          anyExists = true;
                          continue;
                        }
                      }

                      return Showcase(
                        key: _showcaseButton,
                        title: 'Did you know?',
                        description:
                            '\nYou can tap this icon to add or remove ${widget.playerName} or any other player '
                            'from several of your lists (including entire factions in War!).\n\nIt will also allow '
                            'you to quickly copy the player\'s ID and the profile\'s page link.\n\n'
                            'A green icon means the player is not in any or your lists, while an orange icon means '
                            'he/she is at least associated with one of them.\n\nTry it out!',
                        targetPadding: const EdgeInsets.all(10),
                        disableMovingAnimation: true,
                        textColor: _themeProvider.mainText,
                        tooltipBackgroundColor: _themeProvider.secondBackground,
                        descTextStyle: TextStyle(fontSize: 13),
                        tooltipPadding: EdgeInsets.all(20),
                        child: Icon(
                          Icons.person,
                          color: anyExists ? Colors.orange : Colors.green,
                          size: 18,
                        ),
                      );
                    },
                  );
                },
              ),
              onTap: () async {
                return showDialog<void>(
                  context: context,
                  barrierDismissible: true,
                  builder: (context) {
                    return ProfileCheckAddDialog(
                      profileId: widget.profileId,
                      playerName: widget.playerName,
                      factionId: widget.factionId,
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _launchShowCases(BuildContext _) {
    Future.delayed(Duration(seconds: 1), () async {
      List showCases = <GlobalKey<State<StatefulWidget>>>[];
      if (!_settingsProvider.showCases.contains("profile_check_button")) {
        _settingsProvider.addShowCase = "profile_check_button";
        showCases.add(_showcaseButton);
        ShowCaseWidget.of(_).startShowCase(showCases);
      }
    });
  }

  bool _anyExists() {
    for (TargetModel t in _targetsProvider.allTargets) {
      if (t.playerId == widget.profileId) {
        return true;
      }
    }

    for (PanicTargetModel p in _chainStatusProvider.panicTargets) {
      if (p.id == widget.profileId) {
        return true;
      }
    }
    return false;
  }
}

class ProfileCheckAddDialog extends StatefulWidget {
  final int profileId;
  final String playerName;
  final int factionId;

  const ProfileCheckAddDialog({
    @required this.profileId,
    @required this.factionId,
    this.playerName,
    Key key,
  }) : super(key: key);

  @override
  State<ProfileCheckAddDialog> createState() => _ProfileCheckAddDialogState();
}

class _ProfileCheckAddDialogState extends State<ProfileCheckAddDialog> {
  TargetsProvider _targetsProvider;
  bool _toggleTargetActive = false;
  bool _isTarget = false;

  StakeoutsController _s = Get.put(StakeoutsController());
  bool _toggleStakeoutActive = false;
  bool _isStakeout = false;

  ChainStatusProvider _chainStatusProvider;
  bool _togglePanicActive = false;
  bool _isPanic = false;

  WarController _w = Get.put(WarController(initWithIntegrity: false));
  bool _toggleWarActive = false;
  bool _isWar = false;
  bool _warInit = false;

  @override
  void initState() {
    super.initState();
    _targetsProvider = Provider.of<TargetsProvider>(context, listen: false);
    _chainStatusProvider = Provider.of<ChainStatusProvider>(context, listen: false);
    _updateTargetCondition();
    _updateStakeoutCondition();
    _updatePanicCondition();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        "${widget.playerName} [${widget.profileId}]",
        style: TextStyle(
          fontSize: 18,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          children: [
            // COPY
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: widget.profileId.toString()));
                      _showToast(text: 'ID copied!', color: Colors.blue[700], seconds: 1);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.copy),
                        Text(" ID"),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      String url = "https://www.torn.com/profiles.php?XID=${widget.profileId}";
                      Clipboard.setData(ClipboardData(text: url));
                      _showToast(text: 'Link copied!', color: Colors.blue[700], seconds: 1);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.copy),
                        Text(" Link"),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // TARGET
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _isTarget
                    ? Icon(Icons.remove_circle_outline, color: Colors.red, size: 18)
                    : Icon(Icons.add_circle_outline, color: Colors.green, size: 18),
                SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _toggleTargetActive ? null : () => _toggleTarget(),
                    child: _toggleTargetActive
                        ? SizedBox(height: 12, width: 12, child: CircularProgressIndicator())
                        : _isTarget
                            ? Text("Remove target")
                            : Text("Add target"),
                  ),
                ),
              ],
            ),
            // STAKEOUT
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _isStakeout
                    ? Icon(Icons.remove_circle_outline, color: Colors.red, size: 18)
                    : Icon(Icons.add_circle_outline, color: Colors.green, size: 18),
                SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _toggleStakeoutActive ? null : () => _toggleStakeout(),
                    child: _toggleStakeoutActive
                        ? SizedBox(height: 12, width: 12, child: CircularProgressIndicator())
                        : _isStakeout
                            ? Text("Remove stakeout")
                            : Text("Add stakeout"),
                  ),
                ),
              ],
            ),
            // PANIC
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _isPanic
                    ? Icon(Icons.remove_circle_outline, color: Colors.red, size: 18)
                    : Icon(Icons.add_circle_outline, color: Colors.green, size: 18),
                SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _togglePanicActive ? null : () => _togglePanic(),
                    child: _togglePanicActive
                        ? SizedBox(height: 12, width: 12, child: CircularProgressIndicator())
                        : _isPanic
                            ? Text("Remove panic target")
                            : Text("Add panic target"),
                  ),
                ),
              ],
            ),
            // FACTION
            if (widget.factionId != 0)
              GetBuilder<WarController>(builder: (w) {
                if (w.initialised) {
                  if (!_warInit) {
                    _updateWarCondition();
                    _warInit = true;
                  }
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _isWar
                          ? Icon(Icons.remove_circle_outline, color: Colors.red, size: 18)
                          : Icon(Icons.add_circle_outline, color: Colors.green, size: 18),
                      SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _toggleWarActive ? null : () => _toggleWar(),
                          child: _toggleWarActive
                              ? SizedBox(height: 12, width: 12, child: CircularProgressIndicator())
                              : _isWar
                                  ? Text("Remove war faction")
                                  : Text("Add war faction"),
                        ),
                      ),
                    ],
                  );
                } else {
                  return SizedBox.shrink();
                }
              }),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text("Close"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        )
      ],
    );
  }

  void _updateTargetCondition() {
    for (TargetModel t in _targetsProvider.allTargets) {
      if (t.playerId == widget.profileId) {
        _isTarget = true;
        return;
      }
    }
    _isTarget = false;
  }

  void _updateStakeoutCondition() {
    for (Stakeout s in _s.stakeouts) {
      if (s.id == widget.profileId.toString()) {
        _isStakeout = true;
        return;
      }
    }
    _isStakeout = false;
  }

  void _updatePanicCondition() {
    for (PanicTargetModel p in _chainStatusProvider.panicTargets) {
      if (p.id == widget.profileId) {
        _isPanic = true;
        return;
      }
    }
    _isPanic = false;
  }

  void _updateWarCondition() async {
    for (FactionModel w in _w.factions) {
      if (w.id == widget.factionId) {
        _isWar = true;
        return;
      }
    }
    _isWar = false;
  }

  void _toggleTarget() async {
    setState(() {
      _toggleTargetActive = true;
    });

    if (_isTarget) {
      _targetsProvider.deleteTargetById(widget.profileId.toString());
      _showToast(
        text: 'Removed from Torn PDA targets!',
        color: Colors.orange[900],
        seconds: 3,
      );
    } else {
      dynamic attacks = await _targetsProvider.getAttacks();
      AddTargetResult tryAddTarget = await _targetsProvider.addTarget(
        targetId: widget.profileId.toString(),
        attacks: attacks,
      );
      if (tryAddTarget.success) {
        _showToast(
          text: 'Added ${tryAddTarget.targetName} [${tryAddTarget.targetId}] to your main targets list in Torn PDA!',
          color: Colors.green[700],
          seconds: 3,
        );
      } else if (!tryAddTarget.success) {
        _showToast(
          text: 'Error adding ${widget.profileId}. ${tryAddTarget.errorReason}',
          color: Colors.red[900],
          seconds: 4,
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _toggleTargetActive = false;
      _updateTargetCondition();
    });
  }

  void _toggleStakeout() async {
    setState(() {
      _toggleStakeoutActive = true;
    });

    if (_isStakeout) {
      _s.removeStakeout(removeId: widget.profileId.toString());
      _showToast(
        text: 'Removed from stakeouts!',
        color: Colors.orange[900],
        seconds: 3,
      );
    } else {
      AddStakeoutResult result = await _s.addStakeout(inputId: widget.profileId.toString());
      if (result.success) {
        _showToast(
          text: 'Added ${widget.playerName}, remember to activate the desired options in the Stakeouts section!',
          color: Colors.green[700],
          seconds: 4,
        );
      } else {
        _showToast(
          text: 'Error adding ${widget.playerName}: ${result.error}',
          color: Colors.red[900],
          seconds: 4,
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _toggleStakeoutActive = false;
      _updateStakeoutCondition();
    });
  }

  void _togglePanic() async {
    setState(() {
      _togglePanicActive = true;
    });

    if (_isPanic) {
      _chainStatusProvider.removePanicTargetById(widget.profileId);
      _showToast(
        text: 'Removed panic target!',
        color: Colors.orange[900],
        seconds: 3,
      );
    } else {
      dynamic target = await Get.find<ApiCallerController>().getTarget(playerId: widget.profileId.toString());
      String message = "";
      Color messageColor = Colors.green[700];
      if (target is TargetModel) {
        _chainStatusProvider.addPanicTarget(
          PanicTargetModel()
            ..name = target.name
            ..level = target.level
            ..id = target.playerId
            ..factionName = target.faction.factionName,
        );
        message = "Added ${target.name} to panic!";
      } else {
        message = "Can't locate the given target!";
        messageColor = Colors.red[900];
      }
      _showToast(
        text: message,
        color: messageColor,
        seconds: 3,
      );
    }

    if (!mounted) return;
    setState(() {
      _togglePanicActive = false;
      _updatePanicCondition();
    });
  }

  void _toggleWar() async {
    setState(() {
      _toggleWarActive = true;
    });

    if (_isWar) {
      _w.removeFaction(widget.factionId);
      _showToast(
        text: 'Removed ${widget.playerName}\'s faction from War!',
        color: Colors.orange[900],
        seconds: 3,
      );
    } else {
      final targets = _targetsProvider.allTargets;
      final addFactionResult = await _w.addFaction(widget.factionId.toString(), targets);
      if (addFactionResult.isNotEmpty) {
        _showToast(
          text: "Added $addFactionResult to war factions!",
          color: Colors.green[700],
          seconds: 3,
        );
      } else {
        _showToast(
          text: "There was an error adding ${widget.playerName}'s faction to War!",
          color: Colors.red[900],
          seconds: 3,
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _toggleWarActive = false;
      _updateWarCondition();
    });
  }

  _showToast({@required String text, @required Color color, @required int seconds}) {
    BotToast.showText(
      clickClose: true,
      text: HtmlParser.fix(text),
      textStyle: TextStyle(fontSize: 14, color: Colors.white),
      contentColor: color,
      duration: Duration(seconds: seconds),
      contentPadding: EdgeInsets.all(10),
    );
  }
}
