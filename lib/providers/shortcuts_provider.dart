import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:torn_pda/models/profile/shortcuts_model.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class ShortcutsProvider extends ChangeNotifier {
  List<Shortcut> _allShortcuts = [];
  UnmodifiableListView<Shortcut> get allShortcuts =>
      UnmodifiableListView(_allShortcuts);

  List<Shortcut> _activeShortcuts = [];
  UnmodifiableListView<Shortcut> get activeShortcuts =>
      UnmodifiableListView(_activeShortcuts);

  String _shortcutTile = 'both';
  String get shortcutTile => _shortcutTile;

  ShortcutsProvider() {
    // CLEAN LIST, only for debug
    SharedPreferencesModel().setActiveShortcutsList([]);
    //////////////////////////////////////////////////////

    _initializeStockShortcuts();
  }

  void activateShortcut(Shortcut activeShortcut) {
    activeShortcut.active = true;
    _activeShortcuts.add(activeShortcut);
    _saveListAfterChanges();
    notifyListeners();
  }

  void deactivateShortcut(Shortcut inactiveShortcut) {
    inactiveShortcut.active = false;
    _activeShortcuts.remove(inactiveShortcut);
    _saveListAfterChanges();
    notifyListeners();
  }

  void reorderShortcut(Shortcut movedShortcut, int oldIndex, int newIndex) {
    _activeShortcuts.removeAt(oldIndex);
    _activeShortcuts.insert(newIndex, movedShortcut);
    _saveListAfterChanges();
    notifyListeners();
  }

  void changeShortcutTile(String choice) {
    _shortcutTile = choice;
    SharedPreferencesModel().setShortcutTile(choice);
    notifyListeners();
  }

  void _saveListAfterChanges() {
    var saveList = List<String>();
    for (var short in activeShortcuts) {
      var save = shortcutToJson(short);
      saveList.add(save);
    }
    SharedPreferencesModel().setActiveShortcutsList(saveList);
  }

  Future _initializeStockShortcuts() async {
    _shortcutTile = await SharedPreferencesModel().getShortcutTile();

    _configureStockShortcuts();

    // In order to properly reconnect saved shortcuts with the stock ones (so that
    // one is a reference of the other), once we load from shared preferences,
    // we look for the stock counterpart and activate it from scratch
    var savedLoad = await SharedPreferencesModel().getActiveShortcutsList();
    for (var savedShortRaw in savedLoad) {
      var savedShort = shortcutFromJson(savedShortRaw);
      for (var stockShort in _allShortcuts) {
        if (savedShort.name == stockShort.name) {
          activateShortcut(stockShort);
        }
      }
    }
  }

  void _configureStockShortcuts() {
    _allShortcuts.addAll({
      Shortcut()
        ..name = "Casino"
        ..nickname = "Casino"
        ..url = "https://www.torn.com/casino.php"
        ..iconUrl = "images/icons/map/casino.png"
        ..color = Colors.green[200],
      Shortcut()
        ..name = "Casino: Slots"
        ..nickname = "Slots"
        ..url = "https://www.torn.com/loader.php?sid=slots"
        ..iconUrl = "images/icons/map/casino.png"
        ..color = Colors.green[200],
      Shortcut()
        ..name = "Casino: Roulette"
        ..nickname = "Roulette"
        ..url = "https://www.torn.com/loader.php?sid=roulette"
        ..iconUrl = "images/icons/map/casino.png"
        ..color = Colors.green[200],
      Shortcut()
        ..name = "Casino: High-Low"
        ..nickname = "High-low"
        ..url = "https://www.torn.com/loader.php?sid=highlow"
        ..iconUrl = "images/icons/map/casino.png"
        ..color = Colors.green[200],
      Shortcut()
        ..name = "Casino: Keno"
        ..nickname = "Keno"
        ..url = "https://www.torn.com/loader.php?sid=keno"
        ..iconUrl = "images/icons/map/casino.png"
        ..color = Colors.green[200],
      Shortcut()
        ..name = "Casino: Craps"
        ..nickname = "Craps"
        ..url = "https://www.torn.com/loader.php?sid=craps"
        ..iconUrl = "images/icons/map/casino.png"
        ..color = Colors.green[200],
      Shortcut()
        ..name = "Casino: Bookie"
        ..nickname = "Bookie"
        ..url = "https://www.torn.com/bookies.php"
        ..iconUrl = "images/icons/map/casino.png"
        ..color = Colors.green[200],
      Shortcut()
        ..name = "Casino: Lottery"
        ..nickname = "Lottery"
        ..url = "https://www.torn.com/loader.php?sid=lottery"
        ..iconUrl = "images/icons/map/casino.png"
        ..color = Colors.green[200],
      Shortcut()
        ..name = "Casino: Blackjack"
        ..nickname = "Blackjack"
        ..url = "https://www.torn.com/loader.php?sid=blackjack"
        ..iconUrl = "images/icons/map/casino.png"
        ..color = Colors.green[200],
      Shortcut()
        ..name = "Casino: Poker"
        ..nickname = "Poker"
        ..url = "https://www.torn.com/loader.php?sid=holdem"
        ..iconUrl = "images/icons/map/casino.png"
        ..color = Colors.green[200],
      Shortcut()
        ..name = "Casino: Russian Roulette"
        ..nickname = "Russian Roulette"
        ..url = "https://www.torn.com/page.php?sid=russianRoulette"
        ..iconUrl = "images/icons/map/casino.png"
        ..color = Colors.green[200],
      Shortcut()
        ..name = "Casino: Spin the wheel"
        ..nickname = "Wheel"
        ..url = "https://www.torn.com/loader.php?sid=spinTheWheel"
        ..iconUrl = "images/icons/map/casino.png"
        ..color = Colors.green[200],
    });
  }
}
