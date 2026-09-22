import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:torn_pda/providers/ffscouter_notes_controller.dart';
import 'package:torn_pda/providers/player_notes_controller.dart';
import 'package:torn_pda/widgets/ffscouter/ffscouter_notes_section.dart';

/// Counter of FFScouter notes for a player
class FFScouterNotesBadge extends StatefulWidget {
  final int playerId;
  final double fontSize;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  const FFScouterNotesBadge({
    super.key,
    required this.playerId,
    this.fontSize = 12,
    this.padding = EdgeInsets.zero,
    this.onTap,
  });

  @override
  State<FFScouterNotesBadge> createState() => _FFScouterNotesBadgeState();
}

class _FFScouterNotesBadgeState extends State<FFScouterNotesBadge> {
  final _notesController = Get.find<FFScouterNotesController>();

  @override
  void initState() {
    super.initState();
    _request();
  }

  @override
  void didUpdateWidget(covariant FFScouterNotesBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playerId != widget.playerId) _request();
  }

  void _request() {
    if (ffScouterNotesVisible(context)) _notesController.request(widget.playerId);
  }

  @override
  Widget build(BuildContext context) {
    if (!ffScouterNotesVisible(context)) return const SizedBox.shrink();
    return GetBuilder<FFScouterNotesController>(
      builder: (ctrl) {
        final notes = ctrl.notesFor(widget.playerId);
        if (notes.isEmpty) return const SizedBox.shrink();
        final color = Colors.pink[400]!;
        return GestureDetector(
          onTap: widget.onTap,
          child: Padding(
            padding: widget.padding,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                border: Border.all(color: color),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                "FFS ${notes.length}",
                style: TextStyle(fontSize: widget.fontSize - 2, color: color, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Newest FFScouter note, shown when the player has no Torn PDA note or when FFScouter ones are preferred
class FFScouterLatestNote extends StatelessWidget {
  final int? playerId;
  final double fontSize;
  final int maxLines;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  const FFScouterLatestNote({
    super.key,
    required this.playerId,
    this.fontSize = 12,
    this.maxLines = 2,
    this.padding = EdgeInsets.zero,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (playerId == null || !ffScouterNotesVisible(context)) return const SizedBox.shrink();
    return GetBuilder<PlayerNotesController>(
      builder: (pdaNotes) => GetBuilder<FFScouterNotesController>(
        builder: (ctrl) {
          final notes = ctrl.notesFor(playerId!);
          final pdaNote = pdaNotes.getNoteForPlayer(playerId.toString())?.effectiveDisplayText ?? "";
          if (notes.isEmpty || (pdaNote.isNotEmpty && !ctrl.preferOnCards)) return const SizedBox.shrink();
          return GestureDetector(
            onTap: onTap,
            child: Padding(
              padding: padding,
              child: Text(
                ffScouterNoteWithAuthor(notes.first),
                style: TextStyle(fontSize: fontSize, color: Colors.grey[500], fontStyle: FontStyle.italic),
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Hides the Torn PDA note on cards when the FFScouter one is preferred and there is any
class PdaNoteUnlessFFScouter extends StatelessWidget {
  final int? playerId;
  final Widget child;

  const PdaNoteUnlessFFScouter({super.key, required this.playerId, required this.child});

  @override
  Widget build(BuildContext context) {
    if (playerId == null || !ffScouterNotesVisible(context)) return child;
    return GetBuilder<FFScouterNotesController>(
      builder: (ctrl) => ctrl.preferOnCards && ctrl.notesFor(playerId!).isNotEmpty ? const SizedBox.shrink() : child,
    );
  }
}

/// Note a card shows: the Torn PDA one, or the FFScouter one when there is no Torn PDA note or it is preferred
({String text, bool fromFFScouter})? cardNote(BuildContext context, {required int? playerId, required String pdaText}) {
  if (playerId != null && ffScouterNotesVisible(context)) {
    final ctrl = Get.find<FFScouterNotesController>();
    final notes = ctrl.notesFor(playerId);
    if (notes.isNotEmpty && (pdaText.isEmpty || ctrl.preferOnCards)) {
      return (text: ffScouterNoteWithAuthor(notes.first), fromFFScouter: true);
    }
  }
  return pdaText.isEmpty ? null : (text: pdaText, fromFFScouter: false);
}

bool noteFitsInline(String text, TextStyle style, double width) {
  if (width <= 0) return false;
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    maxLines: 1,
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: width);
  return !painter.didExceedMaxLines;
}
