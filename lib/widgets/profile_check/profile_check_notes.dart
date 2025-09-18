import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/player_notes_controller.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/widgets/player_notes_dialog.dart';

class ProfileCheckNotes extends StatefulWidget {
  final String profileId;
  final String? playerName;

  const ProfileCheckNotes({
    required this.profileId,
    this.playerName,
    super.key,
  });

  @override
  State<ProfileCheckNotes> createState() => _ProfileCheckNotesState();
}

class _ProfileCheckNotesState extends State<ProfileCheckNotes> {
  late ThemeProvider _themeProvider;

  @override
  Widget build(BuildContext context) {
    _themeProvider = context.read<ThemeProvider>();
    final settingsProvider = context.read<SettingsProvider>();

    return GetBuilder<PlayerNotesController>(
      builder: (playerNotesController) {
        final playerId = widget.profileId.toString();
        final playerNote = playerNotesController.getNoteForPlayer(playerId);

        final hasNote = playerNote != null && playerNote.note.isNotEmpty;
        final shouldShow = hasNote || settingsProvider.notesWidgetEnabledProfileWhenEmpty;

        if (!shouldShow) {
          return const SizedBox.shrink();
        }

        final noteColor =
            playerNote != null ? playerNotesController.getDisplayColor(playerNote.color) : Colors.transparent;

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
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0.0,
                          backgroundColor: Colors.transparent,
                          content: SingleChildScrollView(
                            child: PlayerNotesDialog(
                              playerId: playerId,
                              playerName: widget.playerName,
                            ),
                          ),
                        );
                      },
                    );
                  },
                  child: Icon(
                    MdiIcons.notebookEditOutline,
                    color: noteColor == Colors.transparent ? Colors.grey : noteColor,
                    size: 15,
                  ),
                ),
                if (hasNote) ...[
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      playerNote.note,
                      style: TextStyle(
                        color: _themeProvider.accesibilityNoTextColors ? Colors.white : noteColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
