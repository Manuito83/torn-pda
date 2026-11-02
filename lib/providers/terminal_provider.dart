import 'package:flutter/material.dart';

const int maxTerminalEntries = 500;

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

    _terminals[webviewKey] = _newestEntries("$prefixedInstruction\n\n$existing");
    notifyListeners();
  }

  String _newestEntries(String text) {
    int end = 0;
    for (int i = 0; i < maxTerminalEntries; i++) {
      final int separator = text.indexOf("\n\n", end);
      if (separator == -1) return text;
      end = separator + 2;
    }
    return text.substring(0, end);
  }

  // Clear the terminal for a specific webview
  void clearTerminal(Key? webviewKey) {
    if (webviewKey == null) return;
    _terminals[webviewKey] = "";
    notifyListeners();
  }

  void removeTerminal(Key? webviewKey) {
    if (_terminals.remove(webviewKey) != null) notifyListeners();
  }

  void moveTerminal(Key? from, Key? to) {
    if (to != null) _terminals[to] = (_terminals[to] ?? "") + (_terminals[from] ?? "");
    final bool removed = _terminals.remove(from) != null;
    if (to != null || removed) notifyListeners();
  }

  bool hasTerminal(Key? webviewKey) => _terminals.containsKey(webviewKey);
}
