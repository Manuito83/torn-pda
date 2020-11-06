import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:torn_pda/models/profile/shortcuts_model.dart';

class ShortcutsProvider extends ChangeNotifier {
  List<Shortcut> _allShortcuts = [];
  UnmodifiableListView<Shortcut> get allShortcuts =>
      UnmodifiableListView(_allShortcuts);

  List<Shortcut> _activeShortcuts = [];
  UnmodifiableListView<Shortcut> get activeShortcuts =>
      UnmodifiableListView(_activeShortcuts);

  String _currentFilter = '';
  String get currentFilter => _currentFilter;

  ShortcutsProvider() {
    _allShortcuts = _initializeShortcuts();
  }

  void activateShortcut(Shortcut activeShortcut) {
    activeShortcut.active = true;
    _activeShortcuts.add(activeShortcut);
    notifyListeners();
  }

  void deactivateShortcut(Shortcut inactiveShortcut) {
    inactiveShortcut.active = false;
    _activeShortcuts.remove(inactiveShortcut);
    notifyListeners();
  }

  void reorderShortcut(Shortcut movedShortcut, int oldIndex, int newIndex) {
    _activeShortcuts.removeAt(oldIndex);
    _activeShortcuts.insert(newIndex, movedShortcut);
    notifyListeners();
  }

  List<Shortcut> _initializeShortcuts() {
    var stockShortcuts = List<Shortcut>();
    stockShortcuts.addAll({
      Shortcut()
        ..name = "Casino: Russian Roulette"
        ..nickname = "Russian Roulette"
        ..url = "https://www.torn.com/page.php?sid=russianRoulette#"
        ..iconUrl = "images/icons/faction.png",
      Shortcut()
        ..name = "shortcut 2"
        ..url = "url 2"
        ..iconUrl = "images/flags/stock/china.png",
    });
    return stockShortcuts;
  }
}
