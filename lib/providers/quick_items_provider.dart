// Dart imports:
import 'dart:developer';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

// Project imports:
//import 'package:torn_pda/models/inventory_model.dart';
import 'package:torn_pda/models/items_model.dart';
import 'package:torn_pda/models/quick_item_model.dart';
import 'package:torn_pda/providers/api/api_v1_calls.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

enum AddPickedItemResult { added, duplicate, missing }

class QuickItemsProvider extends ChangeNotifier {
  bool _firstLoad = true;
  bool _itemSuccess = false;
  bool _refreshAfterEquip = false;
  bool _hideInventoryCount = false;
  bool _longPressToAdd = false;
  bool _isInitialized = false;

  bool get refreshAfterEquip => _refreshAfterEquip;
  bool get hideInventoryCount => _hideInventoryCount;
  bool get longPressToAdd => _longPressToAdd;
  bool get isInitialized => _isInitialized;

  final _activeQuickItemsList = <QuickItem>[];
  UnmodifiableListView<QuickItem> get activeQuickItems => UnmodifiableListView(_activeQuickItemsList);

  final _fullQuickItemsList = <QuickItem>[];
  UnmodifiableListView<QuickItem> get fullQuickItems => UnmodifiableListView(_fullQuickItemsList);

  String _currentSearchFilter = '';
  String get searchFilter => _currentSearchFilter;

  int _numberOfLoadoutsToShow = 3;
  int get numberOfLoadoutsToShow => _numberOfLoadoutsToShow;

  final _quickItemTypes = [
    ItemType.PRIMARY,
    ItemType.SECONDARY,
    ItemType.MELEE,
    ItemType.DEFENSIVE,
    ItemType.ALCOHOL,
    ItemType.BOOSTER,
    ItemType.CANDY,
    ItemType.DRUG,
    ItemType.ENERGY_DRINK,
    ItemType.MEDICAL,
    ItemType.SUPPLY_PACK,
    ItemType.SPECIAL,
    ItemType.TEMPORARY,
  ];

  final _quickItemExceptions = [
    "box of tissues",
    "donator pack",
  ];

  Future loadItems() async {
    if (_firstLoad) {
      _firstLoad = false;
      await _loadSaveActiveItems();
      _isInitialized = true;
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
    _refreshAfterEquip = await Prefs().getQuickItemsRefreshAfterEquip();
    _hideInventoryCount = await Prefs().getQuickItemsHideInventoryCount();
    _longPressToAdd = await Prefs().getQuickItemsLongPressToAdd();
  }

  void activateQuickItem(QuickItem newItem) {
    // Prevent duplicate loadouts
    if (newItem.isLoadout == true) {
      final already = _activeQuickItemsList.firstWhereOrNull(
        (i) => i.isLoadout == true && i.loadoutNumber == newItem.loadoutNumber,
      );
      if (already != null) {
        return;
      }
    }

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

  Future<void> setRefreshAfterEquip(bool value) async {
    _refreshAfterEquip = value;
    await Prefs().setQuickItemsRefreshAfterEquip(value);
    notifyListeners();
  }

  Future<void> setHideInventoryCount(bool value) async {
    _hideInventoryCount = value;
    await Prefs().setQuickItemsHideInventoryCount(value);
    notifyListeners();
  }

  Future<void> setLongPressToAdd(bool value) async {
    _longPressToAdd = value;
    await Prefs().setQuickItemsLongPressToAdd(value);
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

  AddPickedItemResult addPickedItem({required int itemNumber, required QuickItemEquipScanData data}) {
    final target = _fullQuickItemsList.firstWhereOrNull((i) => i.number == itemNumber);
    if (target == null) {
      // Only allow adding items that already exist in the Torn catalog
      return AddPickedItemResult.missing;
    }

    target.instanceId = data.instanceId;
    target.armoryId = data.armoryId;
    target.damage = data.damage ?? target.damage;
    target.accuracy = data.accuracy ?? target.accuracy;
    target.defense = data.defense ?? target.defense;
    if (data.quantity != null) {
      target.inventory = data.quantity;
    }

    // Check if the item is "grouped" in Torn UI (starts with 'g' in rowKey) indicating stackable
    bool isGrouped = data.rowKey != null && data.rowKey!.startsWith('g');

    // Force unique (not grouped) for weapons and armor, even if Torn returns a 'g' key or we are unsure
    if (target.itemType == ItemType.PRIMARY ||
        target.itemType == ItemType.SECONDARY ||
        target.itemType == ItemType.MELEE ||
        target.itemType == ItemType.DEFENSIVE) {
      isGrouped = false;
    }

    target.isGrouped = isGrouped;

    // Block duplicates checking instanceId, except for grouped items where we ignore instanceId
    final existingSameItem = _activeQuickItemsList.firstWhereOrNull(
      (i) {
        if (i.number != itemNumber || i.isLoadout == true) return false;

        if (isGrouped) return true;

        return (data.instanceId.isNotEmpty)
            ? i.instanceId == data.instanceId
            : (i.instanceId == null || i.instanceId!.isEmpty);
      },
    );

    bool added = false;

    if (existingSameItem == null) {
      final newItem = QuickItem()
        ..name = target.name
        ..description = target.description
        ..number = target.number
        ..active = true
        ..itemType = target.itemType
        ..inventory = isGrouped ? target.inventory : null
        ..instanceId = data.instanceId
        ..armoryId = data.armoryId
        ..damage = data.damage ?? target.damage
        ..accuracy = data.accuracy ?? target.accuracy
        ..defense = data.defense ?? target.defense
        ..isGrouped = isGrouped;
      _activeQuickItemsList.add(newItem);
      added = true;
    } else {
      // Update the existing entry and report as duplicate
      existingSameItem.instanceId = data.instanceId;
      existingSameItem.armoryId = data.armoryId;
      existingSameItem.damage = data.damage ?? existingSameItem.damage;
      existingSameItem.accuracy = data.accuracy ?? existingSameItem.accuracy;
      existingSameItem.defense = data.defense ?? existingSameItem.defense;
      // Only update inventory if grouped
      if (isGrouped && data.quantity != null) {
        existingSameItem.inventory = data.quantity;
      }
      existingSameItem.isGrouped = isGrouped;
    }

    _saveListAfterChanges();
    notifyListeners();

    return added ? AddPickedItemResult.added : AddPickedItemResult.duplicate;
  }

  void updateItemFromMassCheck({
    required String originalName,
    required int? qty,
    required bool? isGrouped,
  }) {
    log('[QuickItemsProvider] updateItemFromMassCheck: $originalName, qty: $qty, isGrouped: $isGrouped');

    // Update all active items with this name
    // We check partial matches if needed, but originalName comes from our own list, so exact match is expected
    final items = _activeQuickItemsList.where((i) => i.name == originalName).toList();
    if (items.isEmpty) return;

    bool changed = false;
    for (var item in items) {
      bool? finalIsGrouped = isGrouped;

      //log('[QuickItemsProvider] DEBUG ITEM: ${item.name}, Type: ${item.itemType}, CurrentInv: ${item.inventory}, Inputs -> Qty: $qty, IsGrouped: $isGrouped');

      if (finalIsGrouped == true) {
        if (item.itemType == ItemType.PRIMARY ||
            item.itemType == ItemType.SECONDARY ||
            item.itemType == ItemType.MELEE ||
            item.itemType == ItemType.DEFENSIVE) {
          finalIsGrouped = false;
        }
      }

      // 1. Update isGrouped status if new info is available (and consistent with type override)
      if (finalIsGrouped != null && item.isGrouped != finalIsGrouped) {
        //log('[QuickItemsProvider] Updating isGrouped for $originalName to $finalIsGrouped (Scraper said: $isGrouped)');
        item.isGrouped = finalIsGrouped;
        changed = true;
      }

      // 2. Only update inventory quantity if it is a grouped item
      if (item.isGrouped == true) {
        if (qty != null && item.inventory != qty) {
          // log('[QuickItemsProvider] Updating inventory for grouped $originalName to $qty');
          item.inventory = qty;
          changed = true;
        }
      } else {
        // If it's unique (not grouped), ensure inventory is null
        if (item.inventory != null) {
          // log('[QuickItemsProvider] Clearing inventory for unique $originalName');
          item.inventory = null;
          changed = true;
        }
      }
    }

    if (changed) {
      _saveListAfterChanges();
      notifyListeners();
    }
  }

  /// Updates the instanceId of an active item if it exists in the active list
  /// Used for learning temporary item IDs on the fly without adding new items
  void updateActiveItemInstanceId(int itemNumber, String instanceId) {
    if (instanceId.isEmpty) return;

    // Find all active items with this itemNumber
    final itemsToUpdate = _activeQuickItemsList.where((i) => i.number == itemNumber).toList();

    if (itemsToUpdate.isEmpty) return;

    bool changed = false;
    for (var item in itemsToUpdate) {
      if (item.instanceId != instanceId) {
        item.instanceId = instanceId;
        changed = true;
      }
    }

    if (changed) {
      _saveListAfterChanges();
      notifyListeners();
    }
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
              ..active = savedActive
              ..itemType = itemProperties.type,
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
    if (!fullUpdate) {
      return true;
    }

    // Items removed as per https://www.torn.com/forums.php#/p=threads&f=63&t=16146310&b=0&a=0&start=20&to=24014610
    // We do NOT want to clear inventory here anymore, because we are now populating it via
    // the "Mass Check" scraper (Quick Items Mass Update). If we clear it here, we lose the scraped data.
    /*
    for (final quickItem in _fullQuickItemsList) {
      quickItem.inventory = null;
    }
    for (final quickItem in _activeQuickItemsList) {
      quickItem.inventory = null;
    }
    */
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

class QuickItemEquipScanData {
  final String instanceId;
  final int? quantity;
  final String? name;
  final String? category;
  final bool? equipped;
  final double? damage;
  final double? accuracy;
  final double? defense;
  final String? armoryId;
  final String? rowKey;

  const QuickItemEquipScanData({
    required this.instanceId,
    this.quantity,
    this.name,
    this.category,
    this.equipped,
    this.damage,
    this.accuracy,
    this.defense,
    this.armoryId,
    this.rowKey,
  });
}
