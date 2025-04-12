import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chaining/target_model.dart';
import 'package:torn_pda/models/friends/friend_model.dart';
import 'package:torn_pda/models/stakeouts/stakeout_model.dart';
import 'package:torn_pda/providers/friends_provider.dart';
import 'package:torn_pda/providers/stakeouts_controller.dart';
import 'package:torn_pda/providers/targets_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/war_controller.dart';
import 'package:torn_pda/widgets/notes_dialog.dart';

import '../../models/faction/faction_model.dart';

class ProfileCheckNotes extends StatefulWidget {
  final String profileId;
  const ProfileCheckNotes({required this.profileId, super.key});

  @override
  State<ProfileCheckNotes> createState() => _ProfileCheckNotesState();
}

class _ProfileCheckNotesState extends State<ProfileCheckNotes> {
  late ThemeProvider _themeProvider;
  late TargetsProvider _targets;
  late FriendsProvider _friends;
  final StakeoutsController _stakeouts = Get.find<StakeoutsController>();
  final WarController _warMembers = Get.find<WarController>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = context.read<ThemeProvider>();
    _targets = context.read<TargetsProvider>();
    _friends = context.read<FriendsProvider>();

    String note = "";
    Color noteColor = Colors.transparent;
    Color getColorFromString(String? color) {
      switch (color) {
        case 'red':
          return Colors.red;
        case 'orange':
          return Colors.orange;
        case 'green':
          return Colors.green;
        default:
          return Colors.transparent;
      }
    }

    final playerId = widget.profileId.toString();

    TargetModel? targetModel;
    FriendModel? friendModel;
    Stakeout? stakeoutModel;
    Member? memberModel;

    // Check Target notes
    final target = _targets.allTargets.firstWhereOrNull((t) => t.playerId.toString() == playerId);
    if (target != null && target.personalNote != null && target.personalNote!.isNotEmpty) {
      note = target.personalNote!;
      noteColor = getColorFromString(target.personalNoteColor);
      targetModel = target;
    }

    // Check Friend notes if still empty
    if (note.isEmpty) {
      final friend = _friends.allFriends.firstWhereOrNull((f) => f.playerId.toString() == playerId);
      if (friend != null && friend.personalNote != null && friend.personalNote!.isNotEmpty) {
        note = friend.personalNote!;
        noteColor = getColorFromString(friend.personalNoteColor);
        friendModel = friend;
      }
    }

    // Check Stakeout notes if still empty
    if (note.isEmpty) {
      final stakeout = _stakeouts.stakeouts.firstWhereOrNull((s) => s.id == playerId);
      if (stakeout != null && stakeout.personalNote.isNotEmpty) {
        note = stakeout.personalNote;
        noteColor = getColorFromString(stakeout.personalNoteColor);
        stakeoutModel = stakeout;
      }
    }

    // Check WarMember notes if still empty
    if (note.isEmpty) {
      for (final faction in _warMembers.factions) {
        final member = faction.members![playerId];
        if (member != null && member.personalNote != null && member.personalNote!.isNotEmpty) {
          note = member.personalNote!;
          noteColor = getColorFromString(member.personalNoteColor);
          memberModel = member;
          break;
        }
      }
    }

    if (note.isNotEmpty) {
      // Determine the note type based on the model
      PersonalNoteType noteType = PersonalNoteType.target;
      if (friendModel != null) {
        noteType = PersonalNoteType.friend;
      } else if (stakeoutModel != null) {
        noteType = PersonalNoteType.stakeout;
      } else if (memberModel != null) {
        noteType = PersonalNoteType.factionMember;
      }

      return Container(
        color: Colors.grey[900],
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 4, 15, 4),
          child: Row(
            children: [
              GestureDetector(
                onTap: () async {
                  await showDialog<void>(
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
                          child: PersonalNotesDialog(
                            noteType: noteType,
                            targetModel: targetModel,
                            friendModel: friendModel,
                            stakeoutModel: stakeoutModel,
                            memberModel: memberModel,
                          ),
                        ),
                      );
                    },
                  );

                  // Refresh the UI after closing the dialog
                  // (we are awaiting the dialog above)
                  setState(() {});
                },
                child: Icon(
                  MdiIcons.notebookEditOutline,
                  color: noteColor,
                  size: 15,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  note,
                  style: TextStyle(
                    color: _themeProvider.accesibilityNoTextColors ? Colors.white : noteColor,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox.shrink();
  }
}
