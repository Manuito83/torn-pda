// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

// Project imports:
import 'package:torn_pda/providers/ffscouter_notes_controller.dart';
import 'package:torn_pda/providers/player_notes_controller.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/widgets/ffscouter/ffscouter_notes_section.dart';

/// Pure content widget for player notes editing. Presentation (width, background,
/// scrolling, dialog animations) is provided by [showPlayerNotesDialog]
class PlayerNotesDialog extends StatefulWidget {
  final String playerId;
  final String? playerName;
  final bool openFFScouter;

  const PlayerNotesDialog({required this.playerId, this.playerName, this.openFFScouter = false, super.key});

  @override
  PlayerNotesDialogState createState() => PlayerNotesDialogState();
}

class PlayerNotesDialogState extends State<PlayerNotesDialog> with SingleTickerProviderStateMixin {
  late PlayerNotesController _playerNotesController;
  late ThemeProvider _themeProvider;
  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
    initialIndex: widget.openFFScouter ? 1 : 0,
  )..addListener(() => setState(() {}));

  String? _myTempChosenColor;
  final _personalNotesController = TextEditingController();

  String _savedText = "";
  String? _savedColor = PlayerNoteColor.none;

  @override
  void initState() {
    super.initState();

    _playerNotesController = Get.find<PlayerNotesController>();
    _myTempChosenColor = PlayerNoteColor.none;
    _personalNotesController.addListener(() => setState(() {}));

    // Initialize with existing note if it exists
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final existingNote = _playerNotesController.getNoteForPlayer(widget.playerId);
      if (existingNote != null) {
        _personalNotesController.text = existingNote.note;
        _myTempChosenColor = existingNote.color; // already normalized to sentinel if none
      } else {
        _myTempChosenColor = PlayerNoteColor.none; // Default no color sentinel
      }
      _savedText = _personalNotesController.text;
      _savedColor = _myTempChosenColor;
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _personalNotesController.dispose();
    super.dispose();
  }

  bool get _hasChanges =>
      _personalNotesController.text.trim() != _savedText.trim() ||
      PlayerNoteColor.isNone(_myTempChosenColor) != PlayerNoteColor.isNone(_savedColor) ||
      (!PlayerNoteColor.isNone(_myTempChosenColor) && _myTempChosenColor != _savedColor);

  int? get _ffsPlayerId => int.tryParse(widget.playerId);

  bool get _showFFScouter => _ffsPlayerId != null && ffScouterNotesVisible(context);

  bool get _onFFScouterTab => _showFFScouter && _tabController.index == 1;

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
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _themeProvider.mainText),
          textAlign: TextAlign.center,
        ),
        if (_showFFScouter)
          GetBuilder<FFScouterNotesController>(
            builder: (ffs) {
              final count = ffs.notesFor(_ffsPlayerId!).length;
              return TabBar(
                controller: _tabController,
                labelColor: _themeProvider.mainText,
                unselectedLabelColor: Colors.grey[500],
                tabs: [
                  Tab(height: 36, text: _hasChanges ? "Torn PDA *" : "Torn PDA"),
                  Tab(height: 36, text: count > 0 ? "FFScouter ($count)" : "FFScouter"),
                ],
              );
            },
          ),
        const SizedBox(height: 16),
        Visibility(
          visible: !_onFFScouterTab,
          maintainState: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              const Padding(padding: EdgeInsets.symmetric(vertical: 8)),
              TextFormField(
                style: TextStyle(fontSize: 14, color: _themeProvider.mainText),
                textCapitalization: TextCapitalization.sentences,
                controller: _personalNotesController,
                maxLength: 500,
                minLines: 3,
                maxLines: 8,
                textInputAction: TextInputAction.send,
                onFieldSubmitted: (_) {
                  _hasChanges ? _handleSave() : Navigator.of(context).pop();
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
            ],
          ),
        ),
        if (_showFFScouter)
          Visibility(
            visible: _onFFScouterTab,
            maintainState: true,
            child: FFScouterNotesSection(
              playerId: _ffsPlayerId!,
              readPdaNote: () => _personalNotesController.text,
              onCopyToPda: _appendToPdaNote,
            ),
          ),
        const SizedBox(height: 16.0),
        // Action buttons
        if (_onFFScouterTab) _ffScouterTabActions() else _pdaTabActions(),
      ],
    );
  }

  Widget _pdaTabActions() {
    return Row(
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
              onPressed: _hasChanges ? _handleSave : null,
              child: const Text("Save"),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: _closeButton(label: _hasChanges ? "Cancel" : "Close"),
          ),
        ),
      ],
    );
  }

  Widget _ffScouterTabActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_hasChanges)
          TextButton(
            onPressed: () => _tabController.animateTo(0),
            child: const Text("Your Torn PDA note has unsaved changes", style: TextStyle(fontSize: 12)),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: _closeButton(label: "Close"),
        ),
      ],
    );
  }

  Widget _closeButton({required String label}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 44),
        backgroundColor: _themeProvider.secondBackground,
        foregroundColor: _themeProvider.mainText,
        side: BorderSide(color: _alpha(_themeProvider.mainText, 0.3)),
      ),
      child: Text(label),
      onPressed: () async {
        FocusScope.of(context).unfocus();
        if (_onFFScouterTab && _hasChanges && !await _confirmDiscard()) return;
        if (mounted) Navigator.of(context).pop();
      },
    );
  }

  Future<bool> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: const Text("Discard the changes to your Torn PDA note?", style: TextStyle(fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Keep editing")),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text("Discard")),
        ],
      ),
    );
    return discard == true;
  }

  void _appendToPdaNote(String text) {
    final current = _personalNotesController.text.trim();
    String message;
    if (current.contains(text)) {
      message = "Already in your Torn PDA note";
    } else {
      final combined = current.isEmpty ? text : "$current\n$text";
      if (combined.length > 500) {
        message = "It does not fit in your Torn PDA note (500 characters max)";
      } else {
        _personalNotesController.text = combined;
        _tabController.animateTo(0);
        message = "Added to your Torn PDA note, tap Save to keep it";
      }
    }
    BotToast.showText(
      text: message,
      contentColor: Colors.grey[800]!,
      textStyle: const TextStyle(fontSize: 13, color: Colors.white),
      duration: const Duration(seconds: 3),
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
              ? Border.all(color: _alpha(_themeProvider.mainText, 0.8), width: 3)
              : Border.all(color: Colors.transparent, width: 3),
        ),
        child: isSelected ? Icon(Icons.check, color: _alpha(_themeProvider.mainText, 0.8), size: 24) : null,
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
  bool openFFScouter = false,
}) async {
  final themeProvider = context.read<ThemeProvider>();

  await showGeneralDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'Player Notes',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (ctx, anim, secondary) => const SizedBox.shrink(),
    transitionBuilder: (ctx, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
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
                  constraints: BoxConstraints(maxWidth: dialogWidth, maxHeight: maxHeight),
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
                          openFFScouter: openFFScouter,
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

  try {
    await context.read<WebViewProvider>().notifyDialogClosed();
  } catch (e) {
    debugPrint('Player notes dialog: notifyDialogClosed error: $e');
  }
}
