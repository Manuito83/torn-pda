import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chaining/target_model.dart';
import 'package:torn_pda/models/friends/friend_model.dart';
import 'package:torn_pda/providers/friends_provider.dart';
import 'package:torn_pda/providers/targets_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';

enum PersonalNoteType {
  target,
  friend,
}


class PersonalNotesDialog extends StatefulWidget {
  final TargetModel targetModel;
  final FriendModel friendModel;
  final PersonalNoteType noteType;

  /// Specify the model type in [noteType] and pass accordingly
  PersonalNotesDialog({@required this.noteType, this.targetModel, this.friendModel});

  @override
  _PersonalNotesDialogState createState() => _PersonalNotesDialogState();
}

class _PersonalNotesDialogState extends State<PersonalNotesDialog> {
  TargetModel _target;
  FriendModel _friend;
  TargetsProvider _targetsProvider;
  FriendsProvider _friendsProvider;
  ThemeProvider _themeProvider;

  String _myTempChosenColor;

  final _personalNotesController = new TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.noteType == PersonalNoteType.target) {
      _target = widget.targetModel;
      _personalNotesController.text = _target.personalNote;
      _myTempChosenColor = _target.personalNoteColor;
    } else if (widget.noteType == PersonalNoteType.friend) {
      _friend = widget.friendModel;
      _personalNotesController.text = _friend.personalNote;
      _myTempChosenColor = _friend.personalNoteColor;
    }

  }


  @override
  void dispose() {
    _personalNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _targetsProvider = Provider.of<TargetsProvider>(context, listen: false);
    _friendsProvider = Provider.of<FriendsProvider>(context, listen: false);
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
                          selected: _myTempChosenColor == 'red' ? true : false,
                          label: Text(''),
                          onSelected: (bool isSelected) {
                            setState(() {
                              if (isSelected) {
                                _myTempChosenColor = 'red';
                              } else {
                                _myTempChosenColor = '';
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
                          selected: _myTempChosenColor == 'orange' ? true : false,
                          label: Text(''),
                          onSelected: (bool isSelected) {
                            setState(() {
                              if (isSelected) {
                                _myTempChosenColor = 'orange';
                              } else {
                                _myTempChosenColor = '';
                              }
                            });
                          },
                          selectedColor: Colors.orange[600],
                          backgroundColor: Colors.orange[600],
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
                          selected:
                              _myTempChosenColor == 'green' ? true : false,
                          label: Text(''),
                          onSelected: (bool isSelected) {
                            setState(() {
                              if (isSelected) {
                                _myTempChosenColor = 'green';
                              } else {
                                _myTempChosenColor = '';
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
                      textCapitalization: TextCapitalization.sentences,
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
                          onPressed: () {
                            // Pop and then perform the work
                            Navigator.of(context).pop();
                            if (widget.noteType == PersonalNoteType.target) {
                              _targetsProvider.setTargetNote(
                                  _target,
                                  _personalNotesController.text,
                                  _myTempChosenColor);
                            } else if (widget.noteType == PersonalNoteType.friend) {
                              _friendsProvider.setFriendNote(
                                  _friend,
                                  _personalNotesController.text,
                                  _myTempChosenColor);
                            }
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
