// Dart imports:
import 'dart:collection';

// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
//import 'package:torn_pda/models/inventory_model.dart';
import 'package:torn_pda/models/items_model.dart';
import 'package:torn_pda/models/quick_item_model.dart';
import 'package:torn_pda/providers/api/api_v1_calls.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class QuickItemsProvider extends ChangeNotifier {
  bool _firstLoad = true;
  bool _itemSuccess = false;

  final _activeQuickItemsList = <QuickItem>[];
  UnmodifiableListView<QuickItem> get activeQuickItems => UnmodifiableListView(_activeQuickItemsList);

  final _fullQuickItemsList = <QuickItem>[];
  UnmodifiableListView<QuickItem> get fullQuickItems => UnmodifiableListView(_fullQuickItemsList);

  String _currentSearchFilter = '';
  String get searchFilter => _currentSearchFilter;

  int _numberOfLoadoutsToShow = 3;
  int get numberOfLoadoutsToShow => _numberOfLoadoutsToShow;

  final _quickItemTypes = [
    ItemType.ALCOHOL,
    ItemType.BOOSTER,
    ItemType.CANDY,
    ItemType.DRUG,
    ItemType.ENERGY_DRINK,
    ItemType.MEDICAL,
  ];

  final _quickItemExceptions = [
    "box of tissues",
  ];

  Future loadItems() async {
    if (_firstLoad) {
      _firstLoad = false;
      await _loadSaveActiveItems();
      _itemSuccess = await _getAllTornItems();
      updateInventoryQuantities(fullUpdate: true);
      notifyListeners();
    } else {
      if (_itemSuccess) {
        // Triggers every time, after the first, we land in Items
        updateInventoryQuantities();
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
    final savedActives = await Prefs().getQuickItemsList();
    for (final rawItem in savedActives) {
      final QuickItem activeItem = quickItemFromJson(rawItem);
      _activeQuickItemsList.add(activeItem);
    }

    _numberOfLoadoutsToShow = await Prefs().getNumberOfLoadouts();
  }

  void activateQuickItem(QuickItem newItem) {
    newItem.active = true;
    _activeQuickItemsList.add(newItem);
    _saveListAfterChanges();
    notifyListeners();
  }

  void decreaseInventory(QuickItem item) {
    return;
    // Temporary removed items in Torn
    // ignore: dead_code
    if (item.inventory! > 0) {
      item.inventory = item.inventory! - 1;
      _saveListAfterChanges();
      notifyListeners();
    }
  }

  void deactivateQuickItem(QuickItem oldItem) {
    oldItem.active = false;
    _activeQuickItemsList.remove(oldItem);
    _saveListAfterChanges();

    // Look for the correct item set active false, so that it reappears in the
    // main available items list
    for (final stock in _fullQuickItemsList) {
      if (stock.name == oldItem.name) {
        stock.active = false;
        break;
      }
    }

    notifyListeners();
  }

  void wipeAllQuickItems() {
    for (final oldItem in _activeQuickItemsList) {
      // Look for the correct item set active false, so that it reappears in the
      // main available items list
      for (final stock in _fullQuickItemsList) {
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

  void setNumberOfLoadoutsToShow(int number) {
    _numberOfLoadoutsToShow = number;
    Prefs().setNumberOfLoadouts(number);
    notifyListeners();
  }

  void changeLoadoutName(QuickItem loadout, String name) {
    if (!loadout.isLoadout!) return;
    for (final QuickItem item in _activeQuickItemsList) {
      if (loadout.loadoutNumber == item.loadoutNumber) {
        item.loadoutName = name;
        break;
      }
    }
    _saveListAfterChanges();
    notifyListeners();
  }

  void _saveListAfterChanges() {
    final saveList = <String>[];

    for (final item in activeQuickItems) {
      final save = quickItemToJson(item);
      saveList.add(save);
    }

    Prefs().setQuickItemsList(saveList);
  }

  void reorderQuickItem(QuickItem movedItem, int oldIndex, int newIndex) {
    _activeQuickItemsList.removeAt(oldIndex);
    _activeQuickItemsList.insert(newIndex, movedItem);
    _saveListAfterChanges();
    notifyListeners();
  }

  Future _getAllTornItems() async {
    final allTornItems = await ApiCallsV1.getItems();
    if (allTornItems is ItemsModel) {
      // Clears lists in case there are successive calls from the webview
      _fullQuickItemsList.clear();

      // Add Torn items
      allTornItems.items!.forEach((itemNumber, itemProperties) {
        if (_quickItemTypes.contains(itemProperties.type) ||
            _quickItemExceptions.contains(itemProperties.name!.toLowerCase())) {
          // If the item was saved as active, mark it as such so that we can
          // filter it in our full list
          var savedActive = false;
          for (final saved in _activeQuickItemsList) {
            if (saved.name == itemProperties.name) {
              savedActive = true;
              break;
            }
          }

          _fullQuickItemsList.add(
            QuickItem()
              ..name = itemProperties.name
              ..description = itemProperties.description
              ..number = int.parse(itemNumber)
              ..active = savedActive,
          );
        }
      });
      _fullQuickItemsList.sort((a, b) => a.name!.compareTo(b.name!));

      // Insert loadouts at the beginning after sorting
      for (int i = 0; i < 9; i++) {
        var savedActive = false;
        for (final saved in _activeQuickItemsList) {
          if (saved.isLoadout! && saved.loadoutNumber == i + 1) {
            savedActive = true;
            break;
          }
        }

        _fullQuickItemsList.insert(
          i,
          QuickItem()
            ..name = "Loadout ${i + 1}"
            ..description = "Activates loadout ${i + 1}"
            ..number = 0
            ..active = savedActive
            ..isLoadout = true
            ..loadoutNumber = i + 1
            ..loadoutName = "Loadout ${i + 1}",
        );
      }

      return true;
    }
    return false;
  }

  /// [fullUpdate] is true, it will also update the inactive/stock items, which are not
  /// visible in the widget. Only makes sense if entering the options page
  Future updateInventoryQuantities({bool fullUpdate = false}) async {
    // Items removed as per https://www.torn.com/forums.php#/p=threads&f=63&t=16146310&b=0&a=0&start=20&to=24014610
    for (final quickItem in _fullQuickItemsList) {
      quickItem.inventory = null;
    }
    for (final quickItem in _activeQuickItemsList) {
      quickItem.inventory = null;
    }
    return true;

    /*
    final inventoryItems = await ApiCallsV1.getInventory();
    if (inventoryItems is InventoryModel) {
      if (fullUpdate) {
        for (final quickItem in _fullQuickItemsList) {
          bool found = false;
          for (final invItem in inventoryItems.inventory!) {
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

      for (final quickItem in _activeQuickItemsList) {
        bool found = false;
        for (final invItem in inventoryItems.inventory!) {
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

      _saveListAfterChanges();
      notifyListeners();
      return true;
    }
    return false;
    */
  }
}
