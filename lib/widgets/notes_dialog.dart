// Flutter imports:
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Package imports:
import 'package:provider/provider.dart';

// Project imports:
import 'package:torn_pda/models/chaining/target_model.dart';
import 'package:torn_pda/models/faction/faction_model.dart';
import 'package:torn_pda/models/friends/friend_model.dart';
import 'package:torn_pda/models/stakeouts/stakeout_model.dart';
import 'package:torn_pda/providers/friends_provider.dart';
import 'package:torn_pda/providers/stakeouts_controller.dart';
import 'package:torn_pda/providers/targets_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/war_controller.dart';

enum PersonalNoteType { target, friend, stakeout, factionMember }

class PersonalNotesDialog extends StatefulWidget {
  final TargetModel? targetModel;
  final FriendModel? friendModel;
  final Stakeout? stakeoutModel;
  final Member? memberModel;
  final PersonalNoteType noteType;

  /// Specify the model type in [noteType] and pass accordingly
  const PersonalNotesDialog({
    required this.noteType,
    this.targetModel,
    this.friendModel,
    this.stakeoutModel,
    this.memberModel,
  });

  @override
  _PersonalNotesDialogState createState() => _PersonalNotesDialogState();
}

class _PersonalNotesDialogState extends State<PersonalNotesDialog> {
  TargetModel? _target;
  FriendModel? _friend;
  Stakeout? _stakeout;
  Member? _factionMember;
  late TargetsProvider _targetsProvider;
  late FriendsProvider _friendsProvider;
  late StakeoutsController _s;
  late WarController _w;
  late ThemeProvider _themeProvider;

  String? _myTempChosenColor;

  final _personalNotesController = TextEditingController();

  bool _targetAndWarTargetExists = false;

  @override
  void initState() {
    super.initState();

    _targetsProvider = Provider.of<TargetsProvider>(context, listen: false);
    _friendsProvider = Provider.of<FriendsProvider>(context, listen: false);
    _w = Get.put(WarController());
    _s = Get.put(StakeoutsController());

    if (widget.noteType == PersonalNoteType.target) {
      _target = widget.targetModel;
      _personalNotesController.text = _target!.personalNote!;
      _myTempChosenColor = _target!.personalNoteColor;
    } else if (widget.noteType == PersonalNoteType.friend) {
      _friend = widget.friendModel;
      _personalNotesController.text = _friend!.personalNote!;
      _myTempChosenColor = _friend!.personalNoteColor;
    } else if (widget.noteType == PersonalNoteType.factionMember) {
      _factionMember = widget.memberModel;
      _personalNotesController.text = _factionMember!.personalNote!;
      _myTempChosenColor = _factionMember!.personalNoteColor;
    } else if (widget.noteType == PersonalNoteType.stakeout) {
      _stakeout = widget.stakeoutModel;
      _personalNotesController.text = _stakeout!.personalNote;
    }

    checkIfSameTargetAndWar();
  }

  @override
  void dispose() {
    _personalNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context);
    return SingleChildScrollView(
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
                //key: _mainFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min, // To make the card compact
                  children: <Widget>[
                    if (_targetAndWarTargetExists && widget.noteType == PersonalNoteType.target)
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            "${widget.targetModel!.name} is also a war target: notes will be updated on both sides!",
                            style: const TextStyle(
                              fontSize: 12,
                            ),
                          ),
                        ),
                      )
                    else if (_targetAndWarTargetExists && widget.noteType == PersonalNoteType.factionMember)
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            "${widget.memberModel!.name} is also in your standard targets list: notes will be updated "
                            "on both sides!",
                            style: const TextStyle(
                              fontSize: 12,
                            ),
                          ),
                        ),
                      )
                    else if (!_targetAndWarTargetExists && widget.noteType == PersonalNoteType.factionMember)
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            "${widget.memberModel!.name} is not in your standard targets list: notes will be lost when "
                            "you remove the faction!",
                            style: TextStyle(fontSize: 12, color: Colors.orange[800]),
                          ),
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        RawChip(
                          selected: _myTempChosenColor == 'red' ? true : false,
                          label: const Text(''),
                          onSelected: (bool isSelected) {
                            setState(() {
                              if (isSelected) {
                                _myTempChosenColor = 'red';
                              } else {
                                _myTempChosenColor = 'z';
                              }
                            });
                          },
                          selectedColor: Colors.red,
                          backgroundColor: Colors.red,
                          shape: const StadiumBorder(
                            side: BorderSide(
                              
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                        ),
                        RawChip(
                          selected: _myTempChosenColor == 'orange' ? true : false,
                          label: const Text(''),
                          onSelected: (bool isSelected) {
                            setState(() {
                              if (isSelected) {
                                _myTempChosenColor = 'orange';
                              } else {
                                _myTempChosenColor = 'z';
                              }
                            });
                          },
                          selectedColor: Colors.orange[600],
                          backgroundColor: Colors.orange[600],
                          shape: const StadiumBorder(
                            side: BorderSide(
                              
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                        ),
                        RawChip(
                          selected: _myTempChosenColor == 'green' ? true : false,
                          label: const Text(''),
                          onSelected: (bool isSelected) {
                            setState(() {
                              if (isSelected) {
                                _myTempChosenColor = 'green';
                              } else {
                                _myTempChosenColor = 'z';
                              }
                            });
                          },
                          selectedColor: Colors.green,
                          backgroundColor: Colors.green,
                          shape: const StadiumBorder(
                            side: BorderSide(
                              
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    TextFormField(
                      style: TextStyle(
                        fontSize: 14,
                        color: _themeProvider.mainText,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      controller: _personalNotesController,
                      maxLength: 200,
                      minLines: 1,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        counterText: "",
                        border: OutlineInputBorder(),
                        labelText: 'Insert note',
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        TextButton(
                          child: const Text("Insert"),
                          onPressed: () {
                            // Pop and then perform the work
                            Navigator.of(context).pop();
                            if (widget.noteType == PersonalNoteType.target) {
                              _targetsProvider.setTargetNote(
                                _target,
                                _personalNotesController.text,
                                _myTempChosenColor,
                              );
                              // Update also the war target if it exists
                              if (_targetAndWarTargetExists) {
                                Member? m;
                                for (final f in _w.factions) {
                                  if (f.members!.keys.contains(widget.targetModel!.playerId.toString())) {
                                    m = f.members![widget.targetModel!.playerId.toString()];
                                    _w.setMemberNote(
                                      m,
                                      _personalNotesController.text,
                                      _myTempChosenColor,
                                    );
                                    break;
                                  }
                                }
                              }
                            } else if (widget.noteType == PersonalNoteType.friend) {
                              _friendsProvider.setFriendNote(
                                _friend!,
                                _personalNotesController.text,
                                _myTempChosenColor,
                              );
                            } else if (widget.noteType == PersonalNoteType.factionMember) {
                              _w.setMemberNote(
                                _factionMember,
                                _personalNotesController.text,
                                _myTempChosenColor,
                              );
                            } else if (widget.noteType == PersonalNoteType.stakeout) {
                              _s.setStakeoutNote(
                                _stakeout,
                                _personalNotesController.text,
                                _myTempChosenColor,
                              );
                            }
                          },
                        ),
                        TextButton(
                          child: const Text("Cancel"),
                          onPressed: () {
                            Navigator.of(context).pop();
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
                child: Icon(
                  Icons.library_books,
                  color: _themeProvider.secondBackground,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void checkIfSameTargetAndWar() {
    if (widget.noteType == PersonalNoteType.target) {
      for (final f in _w.factions) {
        if (f.members!.keys.contains(widget.targetModel!.playerId.toString())) {
          _targetAndWarTargetExists = true;
          return;
        }
      }
    } else if (widget.noteType == PersonalNoteType.factionMember) {
      for (final t in _targetsProvider.allTargets) {
        if (t.playerId == widget.memberModel!.memberId) {
          _targetAndWarTargetExists = true;
          return;
        }
      }
    }
  }
}
