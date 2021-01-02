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
  bool _itemSuccess = false;

  var _activeQuickItemsList = <QuickItem>[];
  UnmodifiableListView<QuickItem> get activeQuickItems =>
      UnmodifiableListView(_activeQuickItemsList);

  var _fullQuickItemsList = <QuickItem>[];
  UnmodifiableListView<QuickItem> get fullQuickItems =>
      UnmodifiableListView(_fullQuickItemsList);

  String _currentSearchFilter = '';
  String get searchFilter => _currentSearchFilter;

  String _apiKey = "";

  var _quickItemTypes = [
    ItemType.ALCOHOL,
    ItemType.BOOSTER,
    ItemType.CANDY,
    ItemType.DRUG,
    ItemType.ENERGY_DRINK,
    ItemType.MEDICAL,
  ];

  Future loadItems({@required String apiKey}) async {
    if (_firstLoad) {
      _firstLoad = false;
      _apiKey = apiKey;
      await _loadSaveActiveItems();
      _itemSuccess = await _getAllTornItems();
      updateInventoryQuantities(fullUpdate: true);
      notifyListeners();
    } else {
      if (_itemSuccess) {
        // Triggers every time, after the first, we land in Items
        updateInventoryQuantities(fullUpdate: false);
      } else {
        // Trigger with successive calls if the first
        // load was not successful for items
        _itemSuccess = await _getAllTornItems();
        updateInventoryQuantities(fullUpdate: true);
      }
      notifyListeners();
    }
  }

  Future _loadSaveActiveItems() async {
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

    // Look for the correct item set active false, so that it reappears in the
    // main available items list
    for (var stock in _fullQuickItemsList) {
      if (stock.name == oldItem.name) {
        stock.active = false;
        break;
      }
    }

    notifyListeners();
  }

  void wipeAllQuickItems() {
    for (var oldItem in _activeQuickItemsList) {
      // Look for the correct item set active false, so that it reappears in the
      // main available items list
      for (var stock in _fullQuickItemsList) {
        if (stock.name == oldItem.name) {
          stock.active = false;
          break;
        }
      }
    }
    _activeQuickItemsList.clear();
    _saveListAfterChanges();
    notifyListeners();
  }

  void setFilterText(String newWordFilter) {
    _currentSearchFilter = newWordFilter;
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
      // Clears lists in case there are successive calls from the webview
      _fullQuickItemsList.clear();
      allTornItems.items.forEach((itemNumber, itemProperties) {
        if (_quickItemTypes.contains(itemProperties.type)) {

          // If the item was saved as active, mark it as such so that we can
          // filter it in our full list
          var savedActive = false;
          for (var saved in _activeQuickItemsList) {
            if (saved.name == itemProperties.name) {
              savedActive = true;
              break;
            }
          }

          _fullQuickItemsList.add(
            QuickItem()
              ..name = EmojiParser.fix(itemProperties.name)
              ..description = itemProperties.description
              ..number = int.parse(itemNumber)
              ..active = savedActive,
          );
        }
      });
      _fullQuickItemsList.sort((a, b) => a.name.compareTo(b.name));
      return true;
    }
    return false;
  }

  /// [fullUpdate] is true, it will also update the inactive/stock items, which are not
  /// visible in the widget. Only makes sense if entering the options page
  Future updateInventoryQuantities({bool fullUpdate = false}) async {
    var inventoryItems = await TornApiCaller.items(_apiKey).getInventory;
    if (inventoryItems is InventoryModel) {

      if (fullUpdate) {
        for (var quickItem in _fullQuickItemsList) {
          bool found = false;
          for (var invItem in inventoryItems.inventory) {
            if (invItem.name == quickItem.name) {
              found = true;
              quickItem.inventory = invItem.quantity;
              break;
            }

          }
          if (!found) {
            quickItem.inventory = 0;
          }
        }
      }

      for (var quickItem in _activeQuickItemsList) {
        bool found = false;
        for (var invItem in inventoryItems.inventory) {
          if (invItem.name == quickItem.name) {
            found = true;
            quickItem.inventory = invItem.quantity;
            break;
          }
        }
        if (!found) {
          quickItem.inventory = 0;
        }
      }

      notifyListeners();
      return true;
    }
    return false;
  }
}
