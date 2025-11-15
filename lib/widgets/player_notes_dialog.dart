// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:get/get.dart';
import 'package:provider/provider.dart';

// Project imports:
import 'package:torn_pda/providers/player_notes_controller.dart';
import 'package:torn_pda/providers/theme_provider.dart';

/// Pure content widget for player notes editing. Presentation (width, background,
/// scrolling, dialog animations) is provided by [showPlayerNotesDialog]
class PlayerNotesDialog extends StatefulWidget {
  final String playerId;
  final String? playerName;

  const PlayerNotesDialog({
    required this.playerId,
    this.playerName,
    super.key,
  });

  @override
  PlayerNotesDialogState createState() => PlayerNotesDialogState();
}

class PlayerNotesDialogState extends State<PlayerNotesDialog> {
  late PlayerNotesController _playerNotesController;
  late ThemeProvider _themeProvider;

  String? _myTempChosenColor;
  final _personalNotesController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _playerNotesController = Get.find<PlayerNotesController>();
    _myTempChosenColor = PlayerNoteColor.none;

    // Initialize with existing note if it exists
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final existingNote = _playerNotesController.getNoteForPlayer(widget.playerId);
      if (existingNote != null) {
        _personalNotesController.text = existingNote.note;
        _myTempChosenColor = existingNote.color; // already normalized to sentinel if none
      } else {
        _myTempChosenColor = PlayerNoteColor.none; // Default no color sentinel
      }
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _personalNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Title
        Text(
          widget.playerName != null ? "${widget.playerName} [${widget.playerId}]" : "Player [${widget.playerId}]",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _themeProvider.mainText,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        // Color selection chips
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _buildColorChip('red', Colors.red),
            const SizedBox(width: 16),
            _buildColorChip('orange', Colors.orange[600]!),
            const SizedBox(width: 16),
            _buildColorChip('green', Colors.green),
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
          maxLength: 500,
          minLines: 3,
          maxLines: 8,
          textInputAction: TextInputAction.send,
          onFieldSubmitted: (_) {
            _handleSave();
          },
          onTapOutside: (_) {
            FocusScope.of(context).unfocus();
          },
          decoration: const InputDecoration(
            counterText: "",
            border: OutlineInputBorder(),
            labelText: 'Insert note',
          ),
        ),
        const SizedBox(height: 16.0),
        // Action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: _themeProvider.buttonText,
                  ),
                  child: const Text("Save"),
                  onPressed: () {
                    _handleSave();
                  },
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                    backgroundColor: _themeProvider.secondBackground,
                    foregroundColor: _themeProvider.mainText,
                    side: BorderSide(color: _alpha(_themeProvider.mainText, 0.3)),
                  ),
                  child: const Text("Cancel"),
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildColorChip(String colorValue, Color color) {
    final bool isSelected = _myTempChosenColor == colorValue;
    return InkWell(
      onTap: () {
        FocusScope.of(context).unfocus();
        setState(() {
          _myTempChosenColor = isSelected ? PlayerNoteColor.none : colorValue;
        });
      },
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isSelected ? 52 : 48,
        height: isSelected ? 52 : 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(
                  color: _alpha(_themeProvider.mainText, 0.8),
                  width: 3,
                )
              : Border.all(color: Colors.transparent, width: 3),
        ),
        child: isSelected
            ? Icon(
                Icons.check,
                color: _alpha(_themeProvider.mainText, 0.8),
                size: 24,
              )
            : null,
      ),
    );
  }

  Color _alpha(Color c, double o) => c.withAlpha((o * 255).round());

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();
    final noteText = _personalNotesController.text.trim();
    final noteColor = PlayerNoteColor.isNone(_myTempChosenColor)
        ? null // controller will normalize null -> sentinel
        : _myTempChosenColor;
    await _playerNotesController.setPlayerNote(
      playerId: widget.playerId,
      note: noteText,
      color: noteColor,
      playerName: widget.playerName,
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

Future<void> showPlayerNotesDialog({
  required BuildContext context,
  required String playerId,
  String? playerName,
  bool barrierDismissible = false,
}) {
  final themeProvider = context.read<ThemeProvider>();

  return showGeneralDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'Player Notes',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (ctx, anim, secondary) => const SizedBox.shrink(),
    transitionBuilder: (ctx, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final mq = MediaQuery.of(ctx);
      final screenWidth = mq.size.width;
      final screenHeight = mq.size.height;
      final keyboardInset = mq.viewInsets.bottom;
      const outerMargin = 20.0;
      final maxContentWidth = 600.0;
      final targetWidth = screenWidth - (outerMargin * 2);
      final dialogWidth = targetWidth > maxContentWidth ? maxContentWidth : targetWidth;
      final maxHeight = screenHeight * 0.85;

      return SafeArea(
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.only(bottom: keyboardInset),
          child: Center(
            child: FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: dialogWidth,
                    maxHeight: maxHeight,
                  ),
                  child: Material(
                    color: themeProvider.secondBackground,
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: SingleChildScrollView(
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        child: PlayerNotesDialog(
                          playerId: playerId,
                          playerName: playerName,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
