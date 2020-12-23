import 'package:flutter/material.dart';
import 'dart:collection';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/utils/api_caller.dart';
import 'package:torn_pda/models/items_model.dart';
import 'package:torn_pda/models/quick_item_model.dart';
import 'package:torn_pda/models/inventory_model.dart';
import 'package:torn_pda/utils/emoji_parser.dart';

class QuickItemsProvider extends ChangeNotifier {
  bool _firstLoad = true;
  bool goodFetch = false;

  var _activeQuickItemsList = <QuickItem>[];
  UnmodifiableListView<QuickItem> get activeQuickItems =>
      UnmodifiableListView(_activeQuickItemsList);

  var _fullQuickItemsList = <QuickItem>[];
  UnmodifiableListView<QuickItem> get fullQuickItems =>
      UnmodifiableListView(_fullQuickItemsList);

  String _apiKey = "";

  var _quickItemTypes = [
    ItemType.ALCOHOL,
    ItemType.BOOSTER,
    ItemType.CANDY,
    ItemType.DRUG,
    ItemType.ENERGY_DRINK,
    ItemType.MEDICAL,
  ];

  Future initLoad({@required String apiKey}) async {
    if (_firstLoad) {
      _loadSaveActiveItems();
    }

    if (_firstLoad || !goodFetch) {
      _firstLoad = false;
      _apiKey = apiKey;
      _fullQuickItemsList = <QuickItem>[];
      goodFetch = await _getAllTornItems();
      goodFetch = await _updateInventoryQuantities();
    } else {
      goodFetch = await _updateInventoryQuantities();
    }

    notifyListeners();
  }

  void _loadSaveActiveItems() async {
    var savedActives = await SharedPreferencesModel().getQuickItemsList();
    for (var rawItem in savedActives) {
      _activeQuickItemsList.add(quickItemFromJson(rawItem));
    }
  }

  void activateQuickItem(QuickItem newItem) {
    newItem.active = true;
    _activeQuickItemsList.add(newItem);
    _saveListAfterChanges();
    notifyListeners();

    _saveListAfterChanges();
    notifyListeners();
  }

  void decreaseInventory(QuickItem item) {
    if (item.inventory > 0) {
      item.inventory--;
      notifyListeners();
    }
  }

  void deactivateQuickItem(QuickItem oldItem) {
    oldItem.active = false;
    _activeQuickItemsList.remove(oldItem);
    _saveListAfterChanges();
    notifyListeners();

    _saveListAfterChanges();
    notifyListeners();
  }

  void wipeAllQuickItems() {
    for (var item in _activeQuickItemsList) {
      item.active = false;
    }
    _activeQuickItemsList.clear();
    _saveListAfterChanges();
    notifyListeners();
  }

  void _saveListAfterChanges() {
    var saveList = <String>[];

    for (var item in activeQuickItems) {
      var save = quickItemToJson(item);
      saveList.add(save);
    }

    SharedPreferencesModel().setQuickItemsList(saveList);
  }

  void reorderQuickItem(QuickItem movedItem, int oldIndex, int newIndex) {
    _activeQuickItemsList.removeAt(oldIndex);
    _activeQuickItemsList.insert(newIndex, movedItem);
    _saveListAfterChanges();
    notifyListeners();
  }

  Future _getAllTornItems() async {
    var allTornItems = await TornApiCaller.items(_apiKey).getItems;
    if (allTornItems is ItemsModel) {
      allTornItems.items.forEach((itemNumber, itemProperties) {
        if (_quickItemTypes.contains(itemProperties.type)) {
          _fullQuickItemsList.add(QuickItem()
            ..name = EmojiParser.fix(itemProperties.name)
            ..description = itemProperties.description
            ..number = int.parse(itemNumber));
        }
      });
      _fullQuickItemsList.sort((a, b) => a.name.compareTo(b.name));
      return true;
    }
    return false;
  }

  Future _updateInventoryQuantities() async {
    var inventoryItems = await TornApiCaller.items(_apiKey).getInventory;
    if (inventoryItems is InventoryModel) {
      for (var quickItem in _fullQuickItemsList) {
        for (var invItem in inventoryItems.inventory) {
          if (invItem.name == quickItem.name) {
            quickItem.inventory = invItem.quantity;
            break;
          }
        }
      }
      return true;
    }
    return false;
  }
}
