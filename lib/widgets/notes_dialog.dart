// Flutter imports:
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Package imports:
import 'package:provider/provider.dart';

// Project imports:
import 'package:torn_pda/providers/player_notes_controller.dart';
import 'package:torn_pda/providers/theme_provider.dart';

class PlayerNotesDialog extends StatefulWidget {
  final String playerId;
  final String playerName;

  const PlayerNotesDialog({
    super.key,
    required this.playerId,
    required this.playerName,
  });

  @override
  PlayerNotesDialogState createState() => PlayerNotesDialogState();
}

class PlayerNotesDialogState extends State<PlayerNotesDialog> {
  late ThemeProvider _themeProvider;

  String? _myTempChosenColor;

  final _personalNotesController = TextEditingController();

  @override
  void initState() {
    super.initState();

    final notesController = Get.find<PlayerNotesController>();
    final existingNote = notesController.getNoteForPlayer(widget.playerId);
    _personalNotesController.text = existingNote?.note ?? '';
    _myTempChosenColor = existingNote?.color ?? 'z';
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
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
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
                            side: BorderSide(),
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
                            side: BorderSide(),
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
                            side: BorderSide(),
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
                          onPressed: () async {
                            Navigator.of(context).pop();

                            final noteText = _personalNotesController.text;
                            final noteColor = _myTempChosenColor;

                            final notesController = Get.find<PlayerNotesController>();
                            await notesController.setPlayerNote(widget.playerId, noteText, noteColor);
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
}
