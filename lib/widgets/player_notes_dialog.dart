// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:get/get.dart';
import 'package:provider/provider.dart';

// Project imports:
import 'package:torn_pda/providers/player_notes_controller.dart';
import 'package:torn_pda/providers/theme_provider.dart';

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

    // Initialize with existing note if it exists
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playerNotesController = Get.find<PlayerNotesController>();
      final existingNote = _playerNotesController.getNoteForPlayer(widget.playerId);
      if (existingNote != null) {
        _personalNotesController.text = existingNote.note;
        _myTempChosenColor = existingNote.color;
      } else {
        _myTempChosenColor = 'z'; // Default no color
      }
      setState(() {});
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Player name if provided
                  if (widget.playerName != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        "${widget.playerName} [${widget.playerId}]",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _themeProvider.mainText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        "Player [${widget.playerId}]",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _themeProvider.mainText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Color selection chips
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: RawChip(
                          selected: _myTempChosenColor == 'red',
                          label: const SizedBox.shrink(),
                          onSelected: (bool isSelected) {
                            setState(() {
                              _myTempChosenColor = isSelected ? 'red' : 'z';
                            });
                          },
                          selectedColor: Colors.red,
                          backgroundColor: Colors.red,
                          shape: const StadiumBorder(
                            side: BorderSide(),
                          ),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5),
                      ),
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: RawChip(
                          selected: _myTempChosenColor == 'orange',
                          label: const SizedBox.shrink(),
                          onSelected: (bool isSelected) {
                            setState(() {
                              _myTempChosenColor = isSelected ? 'orange' : 'z';
                            });
                          },
                          selectedColor: Colors.orange[600],
                          backgroundColor: Colors.orange[600],
                          shape: const StadiumBorder(
                            side: BorderSide(),
                          ),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5),
                      ),
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: RawChip(
                          selected: _myTempChosenColor == 'green',
                          label: const SizedBox.shrink(),
                          onSelected: (bool isSelected) {
                            setState(() {
                              _myTempChosenColor = isSelected ? 'green' : 'z';
                            });
                          },
                          selectedColor: Colors.green,
                          backgroundColor: Colors.green,
                          shape: const StadiumBorder(
                            side: BorderSide(),
                          ),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                  ),

                  // Text input field
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

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      TextButton(
                        child: const Text("Save"),
                        onPressed: () async {
                          final noteText = _personalNotesController.text.trim();
                          final noteColor = _myTempChosenColor;

                          await _playerNotesController.setPlayerNote(
                            widget.playerId,
                            noteText,
                            noteColor,
                            widget.playerName,
                          );

                          if (mounted) {
                            Navigator.of(context).pop();
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
        ],
      ),
    );
  }
}
