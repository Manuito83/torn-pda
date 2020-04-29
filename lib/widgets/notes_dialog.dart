import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chaining/target_model.dart';
import 'package:torn_pda/providers/targets_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';

class TargetNotesDialog extends StatefulWidget {
  final TargetModel targetModel;

  TargetNotesDialog({@required this.targetModel});

  @override
  _TargetNotesDialogState createState() => _TargetNotesDialogState();
}

class _TargetNotesDialogState extends State<TargetNotesDialog> {
  TargetModel _target;
  TargetsProvider _targetsProvider;
  ThemeProvider _themeProvider;

  final _personalNotesController = new TextEditingController();

  @override
  void dispose() {
    _personalNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _target = widget.targetModel;
    _personalNotesController.text = _target.personalNote;
    _targetsProvider = Provider.of<TargetsProvider>(context, listen: false);
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return SingleChildScrollView(
      child: Stack(
        children: <Widget>[
          SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.only(
                top: 45,
                bottom: 16,
                left: 16,
                right: 16,
              ),
              margin: EdgeInsets.only(top: 30),
              decoration: new BoxDecoration(
                color: _themeProvider.background,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10.0,
                    offset: const Offset(0.0, 10.0),
                  ),
                ],
              ),
              child: Form(
                //key: _mainFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min, // To make the card compact
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        RawChip(
                          showCheckmark: true,
                          selected:
                              _target.personalNoteColor == 'red' ? true : false,
                          label: Text(''),
                          onSelected: (bool isSelected) {
                            setState(() {
                              if (isSelected) {
                                _target.personalNoteColor = 'red';
                              } else {
                                _target.personalNoteColor = '';
                              }
                            });
                          },
                          selectedColor: Colors.red,
                          backgroundColor: Colors.red,
                          shape: StadiumBorder(
                            side: BorderSide(
                              width: 1,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                        ),
                        RawChip(
                          showCheckmark: true,
                          selected: _target.personalNoteColor == 'blue'
                              ? true
                              : false,
                          label: Text(''),
                          onSelected: (bool isSelected) {
                            setState(() {
                              if (isSelected) {
                                _target.personalNoteColor = 'blue';
                              } else {
                                _target.personalNoteColor = '';
                              }
                            });
                          },
                          selectedColor: Colors.blue,
                          backgroundColor: Colors.blue,
                          shape: StadiumBorder(
                            side: BorderSide(
                              width: 1,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                        ),
                        RawChip(
                          showCheckmark: true,
                          selected: _target.personalNoteColor == 'green'
                              ? true
                              : false,
                          label: Text(''),
                          onSelected: (bool isSelected) {
                            setState(() {
                              if (isSelected) {
                                _target.personalNoteColor = 'green';
                              } else {
                                _target.personalNoteColor = '';
                              }
                            });
                          },
                          selectedColor: Colors.green,
                          backgroundColor: Colors.green,
                          shape: StadiumBorder(
                            side: BorderSide(
                              width: 1,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    TextFormField(
                      style: TextStyle(
                        fontSize: 14,
                        color: _themeProvider.mainText,
                      ),
                      controller: _personalNotesController,
                      maxLength: 200,
                      minLines: 1,
                      maxLines: 3,
                      decoration: InputDecoration(
                        counterText: "",
                        border: OutlineInputBorder(),
                        labelText: 'Insert note',
                      ),
                      /*
                              validator: (value) {
                                if (value.isEmpty) {
                                  return "Cannot be empty!";
                                }
                                return null;
                              },
                              */
                    ),
                    SizedBox(height: 16.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        FlatButton(
                          child: Text("Insert"),
                          onPressed: () async {
                            // Get rid of dialog first, so that it can't
                            // be pressed twice
                            Navigator.of(context).pop();
                            _targetsProvider.setTargetNote(
                                _target, _personalNotesController.text);
                          },
                        ),
                        FlatButton(
                          child: Text("Cancel"),
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
              backgroundColor: _themeProvider.background,
              child: CircleAvatar(
                backgroundColor: _themeProvider.mainText,
                radius: 22,
                child: Icon(
                  Icons.library_books,
                  color: _themeProvider.background,
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
