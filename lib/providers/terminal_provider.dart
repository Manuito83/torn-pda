import 'package:flutter/material.dart';

class TerminalProvider extends ChangeNotifier {
  // Map to store individual terminal texts keyed by webview id
  final Map<Key, String> _terminals = {};

  // Retrieve the terminal text for a specific webview
  String getTerminal(Key? webviewKey) {
    if (webviewKey == null) return "";

    return _terminals[webviewKey] ?? "";
  }

  // Set the terminal text for a specific webview
  void setTerminal(Key? webviewKey, String text) {
    if (webviewKey == null) return;
    _terminals[webviewKey] = text;
    notifyListeners();
  }

  // Add an instruction to a specific webview's terminal
  void addInstruction(Key? webviewKey, String instruction, {bool isError = false}) {
    if (webviewKey == null) return;

    final existing = _terminals[webviewKey] ?? "";

    String prefixedInstruction;
    if (isError) {
      prefixedInstruction = "[ERR] ! $instruction";
    } else if (instruction.startsWith("[IN]") || instruction.startsWith("[OUT]") || instruction.startsWith("[ERR]")) {
      prefixedInstruction = instruction;
    } else {
      prefixedInstruction = "[OUT] < $instruction";
    }

    _terminals[webviewKey] = "$prefixedInstruction\n\n$existing";
    notifyListeners();
  }

  // Clear the terminal for a specific webview
  void clearTerminal(Key? webviewKey) {
    if (webviewKey == null) return;
    _terminals[webviewKey] = "";
    notifyListeners();
  }
}
