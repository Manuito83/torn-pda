import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/ffscouter_notes_controller.dart';
import 'package:torn_pda/providers/player_notes_controller.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/widgets/ffscouter/ffscouter_notes_badge.dart';
import 'package:torn_pda/widgets/ffscouter/ffscouter_notes_section.dart';
import 'package:torn_pda/widgets/player_notes_dialog.dart';

class ProfileCheckNotes extends StatefulWidget {
  final String profileId;
  final String? playerName;

  const ProfileCheckNotes({required this.profileId, this.playerName, super.key});

  @override
  State<ProfileCheckNotes> createState() => _ProfileCheckNotesState();
}

class _ProfileCheckNotesState extends State<ProfileCheckNotes> {
  int? get _ffsPlayerId => int.tryParse(widget.profileId);

  @override
  void initState() {
    super.initState();
    if (_ffsPlayerId != null && ffScouterNotesVisible(context)) {
      Get.find<FFScouterNotesController>().request(_ffsPlayerId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.read<ThemeProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    final ffsVisible = _ffsPlayerId != null && ffScouterNotesVisible(context);

    return GetBuilder<PlayerNotesController>(
      builder: (playerNotesController) => GetBuilder<FFScouterNotesController>(
        builder: (ffsNotesController) {
          final playerId = widget.profileId.toString();
          final playerNote = playerNotesController.getNoteForPlayer(playerId);

          final hasNoteText = playerNote != null && playerNote.effectiveDisplayText.isNotEmpty;
          final hasColorOnly = playerNote?.hasColorOnly ?? false;
          final hasFFScouterNotes = ffsVisible && ffsNotesController.notesFor(_ffsPlayerId!).isNotEmpty;
          final shouldShow =
              hasNoteText || hasColorOnly || hasFFScouterNotes || settingsProvider.notesWidgetEnabledProfileWhenEmpty;

          if (!shouldShow) return const SizedBox.shrink();

          final rawColor = playerNote != null
              ? playerNotesController.getDisplayColor(playerNote.color)
              : Colors.transparent;
          final effectiveTextColor = rawColor == Colors.transparent ? Colors.grey.shade200 : rawColor;

          return Container(
            color: Colors.grey[900],
            child: Padding(
              padding: const EdgeInsets.fromLTRB(15, 4, 15, 4),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _openDialog,
                    child: Icon(
                      MdiIcons.notebookEditOutline,
                      color: rawColor == Colors.transparent ? Colors.grey : rawColor,
                      size: 15,
                    ),
                  ),
                  if (hasNoteText || hasColorOnly) ...[
                    const SizedBox(width: 10),
                    Flexible(
                      child: PdaNoteUnlessFFScouter(
                        playerId: _ffsPlayerId,
                        child: Text(
                          hasColorOnly ? '' : playerNote!.effectiveDisplayText,
                          style: TextStyle(color: effectiveTextColor, fontSize: 12, fontStyle: FontStyle.normal),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 3,
                        ),
                      ),
                    ),
                  ],
                  Flexible(
                    child: FFScouterLatestNote(
                      playerId: _ffsPlayerId,
                      maxLines: 3,
                      padding: const EdgeInsets.only(left: 10),
                      onTap: () => _openDialog(openFFScouter: true),
                    ),
                  ),
                  if (hasFFScouterNotes)
                    FFScouterNotesBadge(
                      playerId: _ffsPlayerId!,
                      padding: const EdgeInsets.only(left: 10),
                      onTap: () => _openDialog(openFFScouter: true),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openDialog({bool openFFScouter = false}) {
    return showPlayerNotesDialog(
      context: context,
      barrierDismissible: false,
      playerId: widget.profileId,
      playerName: widget.playerName,
      openFFScouter: openFFScouter,
    );
  }
}
