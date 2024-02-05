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
import 'package:torn_pda/providers/api_caller.dart';
import 'package:torn_pda/providers/chain_status_provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/stakeouts_controller.dart';
import 'package:torn_pda/providers/targets_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/war_controller.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/html_parser.dart';

class ProfileCheckAddButton extends StatefulWidget {
  final int profileId;
  final int? factionId;
  final String? playerName;

  const ProfileCheckAddButton({
    required this.profileId,
    required this.factionId,
    this.playerName = "Player",
    super.key,
  });

  @override
  State<ProfileCheckAddButton> createState() => ProfileCheckAddButtonState();
}

class ProfileCheckAddButtonState extends State<ProfileCheckAddButton> {
  late ThemeProvider _themeProvider;
  late SettingsProvider _settingsProvider;
  late TargetsProvider _targetsProvider;
  late ChainStatusProvider _chainStatusProvider;

  // Showcases
  final GlobalKey _showcaseButton = GlobalKey();

  @override
  Widget build(BuildContext context) {
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _themeProvider = Provider.of<ThemeProvider>(context);
    _targetsProvider = Provider.of<TargetsProvider>(context);
    _chainStatusProvider = Provider.of<ChainStatusProvider>(context);

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
                      for (final Stakeout s in s.stakeouts) {
                        if (s.id == widget.profileId.toString()) {
                          anyExists = true;
                          continue;
                        }
                      }

                      for (final FactionModel w in w.factions) {
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
                            "you to quickly copy the player's ID and the profile's page link.\n\n"
                            'A green icon means the player is not in any of your lists, while an orange icon means '
                            'he/she is at least associated with one of them.\n\nTry it out!',
                        targetPadding: const EdgeInsets.all(10),
                        disableMovingAnimation: true,
                        textColor: _themeProvider.mainText!,
                        tooltipBackgroundColor: _themeProvider.secondBackground!,
                        descTextStyle: const TextStyle(fontSize: 13),
                        tooltipPadding: const EdgeInsets.all(20),
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
    final webviewProvider = Provider.of<WebViewProvider>(context, listen: false);

    if (!webviewProvider.browserShowInForeground) return;

    Future.delayed(const Duration(seconds: 1), () async {
      final List showCases = <GlobalKey<State<StatefulWidget>>>[];
      if (!_settingsProvider.showCases.contains("profile_check_button")) {
        // Prevent the showcase from activating if we have reset the showcase while a tab with a profile is open
        if (!webviewProvider.currentTabUrl()!.contains('loader.php?sid=attack&user2ID=') &&
            !webviewProvider.currentTabUrl()!.contains('loader2.php?sid=getInAttack&user2ID=') &&
            !webviewProvider.currentTabUrl()!.contains('torn.com/profiles.php?XID=')) {
          return;
        }

        _settingsProvider.addShowCase = "profile_check_button";
        showCases.add(_showcaseButton);
        ShowCaseWidget.of(_).startShowCase(showCases as List<GlobalKey<State<StatefulWidget>>>);
      }
    });
  }

  bool _anyExists() {
    for (final TargetModel t in _targetsProvider.allTargets) {
      if (t.playerId == widget.profileId) {
        return true;
      }
    }

    for (final PanicTargetModel p in _chainStatusProvider.panicTargets) {
      if (p.id == widget.profileId) {
        return true;
      }
    }
    return false;
  }
}

class ProfileCheckAddDialog extends StatefulWidget {
  final int profileId;
  final String? playerName;
  final int? factionId;

  const ProfileCheckAddDialog({
    required this.profileId,
    required this.factionId,
    this.playerName,
    super.key,
  });

  @override
  State<ProfileCheckAddDialog> createState() => ProfileCheckAddDialogState();
}

class ProfileCheckAddDialogState extends State<ProfileCheckAddDialog> {
  late TargetsProvider _targetsProvider;
  bool _toggleTargetActive = false;
  bool _isTarget = false;

  final StakeoutsController _s = Get.put(StakeoutsController());
  bool _toggleStakeoutActive = false;
  bool _isStakeout = false;

  late ChainStatusProvider _chainStatusProvider;
  bool _togglePanicActive = false;
  bool _isPanic = false;

  final WarController _w = Get.find<WarController>();
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
        style: const TextStyle(
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
                      _showToast(text: 'ID copied!', color: Colors.blue[700]!, seconds: 1);
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.copy),
                        Text(" ID"),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final String url = "https://www.torn.com/profiles.php?XID=${widget.profileId}";
                      Clipboard.setData(ClipboardData(text: url));
                      _showToast(text: 'Link copied!', color: Colors.blue[700]!, seconds: 1);
                    },
                    child: const Row(
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
                if (_isTarget)
                  const Icon(Icons.remove_circle_outline, color: Colors.red, size: 18)
                else
                  const Icon(Icons.add_circle_outline, color: Colors.green, size: 18),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _toggleTargetActive ? null : () => _toggleTarget(),
                    child: _toggleTargetActive
                        ? const SizedBox(height: 12, width: 12, child: CircularProgressIndicator())
                        : _isTarget
                            ? const Text("Remove target")
                            : const Text("Add target"),
                  ),
                ),
              ],
            ),
            // STAKEOUT
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isStakeout)
                  const Icon(Icons.remove_circle_outline, color: Colors.red, size: 18)
                else
                  const Icon(Icons.add_circle_outline, color: Colors.green, size: 18),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _toggleStakeoutActive ? null : () => _toggleStakeout(),
                    child: _toggleStakeoutActive
                        ? const SizedBox(height: 12, width: 12, child: CircularProgressIndicator())
                        : _isStakeout
                            ? const Text("Remove stakeout")
                            : const Text("Add stakeout"),
                  ),
                ),
              ],
            ),
            // PANIC
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isPanic)
                  const Icon(Icons.remove_circle_outline, color: Colors.red, size: 18)
                else
                  const Icon(Icons.add_circle_outline, color: Colors.green, size: 18),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _togglePanicActive ? null : () => _togglePanic(),
                    child: _togglePanicActive
                        ? const SizedBox(height: 12, width: 12, child: CircularProgressIndicator())
                        : _isPanic
                            ? const Text("Remove panic target")
                            : const Text("Add panic target"),
                  ),
                ),
              ],
            ),
            // FACTION
            if (widget.factionId != 0)
              GetBuilder<WarController>(
                builder: (w) {
                  if (w.initialised) {
                    if (!_warInit) {
                      _updateWarCondition();
                      _warInit = true;
                    }
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isWar)
                          const Icon(Icons.remove_circle_outline, color: Colors.red, size: 18)
                        else
                          const Icon(Icons.add_circle_outline, color: Colors.green, size: 18),
                        const SizedBox(width: 15),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _toggleWarActive ? null : () => _toggleWar(),
                            child: _toggleWarActive
                                ? const SizedBox(height: 12, width: 12, child: CircularProgressIndicator())
                                : _isWar
                                    ? const Text("Remove war faction")
                                    : const Text("Add war faction"),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                },
              ),
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
    for (final TargetModel t in _targetsProvider.allTargets) {
      if (t.playerId == widget.profileId) {
        _isTarget = true;
        return;
      }
    }
    _isTarget = false;
  }

  void _updateStakeoutCondition() {
    for (final Stakeout s in _s.stakeouts) {
      if (s.id == widget.profileId.toString()) {
        _isStakeout = true;
        return;
      }
    }
    _isStakeout = false;
  }

  void _updatePanicCondition() {
    for (final PanicTargetModel p in _chainStatusProvider.panicTargets) {
      if (p.id == widget.profileId) {
        _isPanic = true;
        return;
      }
    }
    _isPanic = false;
  }

  Future<void> _updateWarCondition() async {
    for (final FactionModel w in _w.factions) {
      if (w.id == widget.factionId) {
        _isWar = true;
        return;
      }
    }
    _isWar = false;
  }

  Future<void> _toggleTarget() async {
    setState(() {
      _toggleTargetActive = true;
    });

    if (_isTarget) {
      _targetsProvider.deleteTargetById(widget.profileId.toString());
      _showToast(
        text: 'Removed from Torn PDA targets!',
        color: Colors.orange[900]!,
        seconds: 3,
      );
    } else {
      final dynamic attacks = await _targetsProvider.getAttacks();
      final AddTargetResult tryAddTarget = await _targetsProvider.addTarget(
        targetId: widget.profileId.toString(),
        attacks: attacks,
      );
      if (tryAddTarget.success) {
        _showToast(
          text: 'Added ${tryAddTarget.targetName} [${tryAddTarget.targetId}] to your main targets list in Torn PDA!',
          color: Colors.green[700]!,
          seconds: 3,
        );
      } else if (!tryAddTarget.success) {
        _showToast(
          text: 'Error adding ${widget.profileId}. ${tryAddTarget.errorReason}',
          color: Colors.red[900]!,
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

  Future<void> _toggleStakeout() async {
    setState(() {
      _toggleStakeoutActive = true;
    });

    if (_isStakeout) {
      _s.removeStakeout(removeId: widget.profileId.toString());
      _showToast(
        text: 'Removed from stakeouts!',
        color: Colors.orange[900]!,
        seconds: 3,
      );
    } else {
      final AddStakeoutResult result = await _s.addStakeout(inputId: widget.profileId.toString());
      if (result.success) {
        _showToast(
          text: 'Added ${widget.playerName}, remember to activate the desired options in the Stakeouts section!',
          color: Colors.green[700]!,
          seconds: 4,
        );
      } else {
        _showToast(
          text: 'Error adding ${widget.playerName}: ${result.error}',
          color: Colors.red[900]!,
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

  Future<void> _togglePanic() async {
    setState(() {
      _togglePanicActive = true;
    });

    if (_isPanic) {
      _chainStatusProvider.removePanicTargetById(widget.profileId);
      _showToast(
        text: 'Removed panic target!',
        color: Colors.orange[900]!,
        seconds: 3,
      );
    } else {
      final dynamic target = await Get.find<ApiCallerController>().getTarget(playerId: widget.profileId.toString());
      String message = "";
      Color? messageColor = Colors.green[700];
      if (target is TargetModel) {
        _chainStatusProvider.addPanicTarget(
          PanicTargetModel()
            ..name = target.name
            ..level = target.level
            ..id = target.playerId
            ..factionName = target.faction!.factionName,
        );
        message = "Added ${target.name} to panic!";
      } else {
        message = "Can't locate the given target!";
        messageColor = Colors.red[900];
      }
      _showToast(
        text: message,
        color: messageColor!,
        seconds: 3,
      );
    }

    if (!mounted) return;
    setState(() {
      _togglePanicActive = false;
      _updatePanicCondition();
    });
  }

  Future<void> _toggleWar() async {
    setState(() {
      _toggleWarActive = true;
    });

    if (_isWar) {
      _w.removeFaction(widget.factionId);
      _showToast(
        text: "Removed ${widget.playerName}'s faction from War!",
        color: Colors.orange[900]!,
        seconds: 3,
      );
    } else {
      final targets = _targetsProvider.allTargets;
      final addFactionResult = (await _w.addFaction(widget.factionId.toString(), targets))!;
      if (addFactionResult.isNotEmpty) {
        _showToast(
          text: "Added $addFactionResult to war factions!",
          color: Colors.green[700]!,
          seconds: 3,
        );
      } else {
        _showToast(
          text: "There was an error adding ${widget.playerName}'s faction to War!",
          color: Colors.red[900]!,
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

  _showToast({required String text, required Color color, required int seconds}) {
    BotToast.showText(
      clickClose: true,
      text: HtmlParser.fix(text),
      textStyle: const TextStyle(fontSize: 14, color: Colors.white),
      contentColor: color,
      duration: Duration(seconds: seconds),
      contentPadding: const EdgeInsets.all(10),
    );
  }
}
