import 'package:flutter/material.dart';

class TerminalProvider extends ChangeNotifier {
  String _text;
  getTerminal() => _text;
  setTerminal(String text) => _text = text;

  TerminalProvider(this._text);

  void addInstruction(String instruction) {
    var existing = _text;
    _text = "$instruction\n\n$existing";
    notifyListeners();
  }
}
