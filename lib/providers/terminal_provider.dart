import 'package:flutter/material.dart';

class TerminalProvider extends ChangeNotifier {
  String _text;
  String get terminal => _text;
  set terminal(String text) => _text = _text;

  TerminalProvider(this._text);

  void addInstruction(String instruction) {
    final existing = _text;
    _text = "$instruction\n\n$existing";
    notifyListeners();
  }
}
