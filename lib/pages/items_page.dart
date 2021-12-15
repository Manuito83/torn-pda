// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

// Package imports:
import 'package:get/get.dart';
import 'package:http/http.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/inventory_model.dart';
import 'package:torn_pda/models/items/items_sort.dart';
import 'package:torn_pda/models/items_model.dart';
import 'package:torn_pda/providers/user_controller.dart';

// Project imports:
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/api_caller.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/items/item_card.dart';

class ItemsPage extends StatefulWidget {
  ItemsPage({Key key}) : super(key: key);

  @override
  _ItemsPageState createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> with WidgetsBindingObserver {
  List<Widget> _allItemsCards = <Widget>[];
  List<Item> _allItems = <Item>[];

  List<Item> _pinnedItems = <Item>[];

  ScrollController _filterScroll = ScrollController();
  ScrollPhysics _filterPhysics = NeverScrollableScrollPhysics();
  PanelController _pc = PanelController();
  final double _initFabHeight = 25.0;
  double _fabHeight = 25.0;
  double _panelHeightOpen = 400.0;
  double _panelHeightClosed = 75.0;

  SettingsProvider _settingsProvider;
  ThemeProvider _themeProvider;
  UserController _u = Get.put(UserController());

  String _currentSearchFilter = '';
  final _searchController = new TextEditingController();
  final _searchFocusNode = FocusNode();

  Future _loadedApiItems;
  bool _itemsSuccess = false;
  bool _inventorySuccess = false;
  String _errorMessage = "";

  // Filters
  bool _filterOwnedItems = false;
  List<String> _hiddenCategories = <String>[];
  Map<String, String> _allCategories = Map<String, String>();

  // Sorting
  ItemsSort _currentSort = ItemsSort();
  final _popupSortChoices = <ItemsSort>[
    ItemsSort(type: ItemsSortType.nameAsc),
    ItemsSort(type: ItemsSortType.nameDes),
    ItemsSort(type: ItemsSortType.categoryAsc),
    ItemsSort(type: ItemsSortType.categoryDes),
    ItemsSort(type: ItemsSortType.ownedAsc),
    ItemsSort(type: ItemsSortType.ownedDes),
    ItemsSort(type: ItemsSortType.valueAsc),
    ItemsSort(type: ItemsSortType.valueDes),
    ItemsSort(type: ItemsSortType.circulationAsc),
    ItemsSort(type: ItemsSortType.circulationDes),
    ItemsSort(type: ItemsSortType.idAsc),
    ItemsSort(type: ItemsSortType.idDes),
  ];

  @override
  void initState() {
    super.initState();
    _loadedApiItems = _getAllItems();
    _searchController.addListener(onSearchInputTextChange);
    analytics.setCurrentScreen(screenName: 'items');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _filterScroll.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    return Scaffold(
      drawer: Drawer(),
      appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
      bottomNavigationBar: !_settingsProvider.appBarTop
          ? SizedBox(
              height: AppBar().preferredSize.height,
              child: buildAppBar(),
            )
          : null,
      body: Stack(
        children: [
          FutureBuilder(
            future: _loadedApiItems,
            builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (_itemsSuccess) {
                  return _itemsMain();
                }
                return _errorMain();
              } else {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
            },
          ),

          // Sliding panel
          FutureBuilder(
            future: _loadedApiItems,
            builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (_itemsSuccess) {
                  return SlidingUpPanel(
                      controller: _pc,
                      maxHeight: _panelHeightOpen,
                      minHeight: _panelHeightClosed,
                      renderPanelSheet: false,
                      backdropEnabled: true,
                      isDraggable: false,
                      parallaxEnabled: false,
                      parallaxOffset: .0,
                      panelBuilder: (sc) => _bottomPanel(sc),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(18.0),
                        topRight: Radius.circular(18.0),
                      ),
                      onPanelClosed: () {
                        _filterPhysics = NeverScrollableScrollPhysics();
                      },
                      onPanelOpened: () {
                        _filterPhysics = AlwaysScrollableScrollPhysics();
                      },
                      onPanelSlide: (double pos) {
                        setState(() {
                          _fabHeight = pos * (_panelHeightOpen - _panelHeightClosed) + _initFabHeight;
                        });
                      });
                } else {
                  return SizedBox.shrink();
                }
              } else {
                return SizedBox.shrink();
              }
            },
          ),

          // FAB
          FutureBuilder(
            future: _loadedApiItems,
            builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (_itemsSuccess) {
                  return Positioned(
                    right: 35.0,
                    bottom: _fabHeight,
                    child: FloatingActionButton.extended(
                      icon: Icon(Icons.filter_list),
                      label: Text("Filter"),
                      elevation: 4,
                      onPressed: () {
                        _pc.isPanelOpen ? _pc.close() : _pc.open();
                      },
                      backgroundColor: Colors.orange,
                    ),
                  );
                } else {
                  return SizedBox.shrink();
                }
              } else {
                return SizedBox.shrink();
              }
            },
          ),
        ],
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      //brightness: Brightness.dark, // For downgrade to Flutter 2.2.3
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      leading: IconButton(
        icon: Icon(Icons.dehaze),
        onPressed: () {
          final ScaffoldState scaffoldState = context.findRootAncestorStateOfType();
          scaffoldState.openDrawer();
        },
      ),
      title: Text('Items'),
      actions: [
        _itemsSuccess
            ? PopupMenuButton<ItemsSort>(
                icon: Icon(
                  Icons.sort,
                ),
                onSelected: _sortAndRebuildItemsCards,
                itemBuilder: (BuildContext context) {
                  return _popupSortChoices.map((ItemsSort choice) {
                    return PopupMenuItem<ItemsSort>(
                      value: choice,
                      child: Text(
                        choice.description,
                        style: TextStyle(
                          fontSize: 13,
                        ),
                      ),
                    );
                  }).toList();
                },
              )
            : SizedBox.shrink(),
      ],
    );
  }

  Widget _itemsMain() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _allItemsCards.length,
            itemBuilder: (context, index) {
              return _allItemsCards[index];
            },
          ),
        ),
      ],
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Focus(
        focusNode: _searchFocusNode,
        child: TextField(
          controller: _searchController,
          maxLength: 30,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.all(8),
            labelText: "Search name or id",
            counterText: "",
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(6.0),
              ),
            ),
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _searchController.text = "";
                  _searchFocusNode.unfocus();
                });
              },
              icon: Icon(Icons.clear),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bottomPanel(ScrollController sc) {
    return SingleChildScrollView(
      controller: _filterScroll,
      physics: _filterPhysics,
      child: Container(
        decoration: BoxDecoration(
            color: _themeProvider.background,
            borderRadius: BorderRadius.all(Radius.circular(20.0)),
            boxShadow: [
              BoxShadow(
                blurRadius: 2.0,
                color: Colors.orange[800],
              ),
            ]),
        margin: const EdgeInsets.all(24.0),
        child: Column(
          children: <Widget>[
            GestureDetector(
              onVerticalDragEnd: (details) {
                if (details.velocity.pixelsPerSecond.dy < 0) {
                  _pc.open();
                } else if (details.velocity.pixelsPerSecond.dy > 0) {
                  _pc.close();
                }
              },
              child: Container(
                color: Colors.transparent,
                child: Column(
                  children: [
                    Column(
                      children: [
                        SizedBox(
                          height: 12.0,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              width: 30,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                borderRadius: BorderRadius.all(
                                  Radius.circular(12.0),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 40.0),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Row(
                    children: [
                      Text("Only owned"),
                      Switch(
                        value: _filterOwnedItems,
                        onChanged: (value) {
                          Prefs().setShowOnlyOwnedItems(value);
                          _filterOwnedItems = value;
                          _rebuildItemsCards();
                        },
                        activeTrackColor: Colors.lightGreenAccent,
                        activeColor: Colors.green,
                      ),
                    ],
                  ),
                  RawChip(
                    showCheckmark: true,
                    selected: _hiddenCategories.isEmpty ? true : false,
                    side: BorderSide(color: _hiddenCategories.isEmpty ? Colors.green : Colors.grey[600], width: 1.5),
                    avatar: CircleAvatar(
                      backgroundColor: _hiddenCategories.isEmpty ? Colors.green : Colors.grey,
                    ),
                    label: Text(
                      "ALL",
                      style: TextStyle(
                        fontSize: 12,
                      ),
                    ),
                    selectedColor: Colors.transparent,
                    disabledColor: Colors.grey,
                    onSelected: (bool isSelected) {
                      if (isSelected) {
                        _hiddenCategories.clear();
                      } else {
                        var fullList = [];
                        for (var cat in _allCategories.keys) {
                          fullList.add(cat);
                        }
                        _hiddenCategories = List<String>.from(fullList);
                      }
                      Prefs().setHiddenItemsCategories(_hiddenCategories);
                      _rebuildItemsCards();
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _categoryFilterWrap(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryFilterWrap() {
    var catChips = <Widget>[];
    for (var cat in _allCategories.entries) {
      switch (cat.key) {
        case "MELEE":
          break;
      }

      String titleCapitalized = cat.key.replaceAll("_", " ").toLowerCase();
      titleCapitalized = titleCapitalized.replaceFirst(titleCapitalized[0], titleCapitalized[0].toUpperCase());

      catChips.add(
        RawChip(
          showCheckmark: false,
          selected: _hiddenCategories.contains(cat.key) ? false : true,
          side: BorderSide(color: _hiddenCategories.contains(cat.key) ? Colors.grey[600] : Colors.green, width: 1.5),
          label: Text(
            "${titleCapitalized} (${cat.value})",
            style: TextStyle(fontSize: 10),
          ),
          selectedColor: Colors.transparent,
          disabledColor: Colors.grey,
          onSelected: (bool isSelected) {
            isSelected ? _hiddenCategories.remove(cat.key) : _hiddenCategories.add(cat.key);
            Prefs().setHiddenItemsCategories(_hiddenCategories);
            _rebuildItemsCards();
          },
        ),
      );
    }

    return Wrap(
      spacing: 5,
      children: catChips,
    );
  }

  void onSearchInputTextChange() {
    _currentSearchFilter = _searchController.text.toLowerCase();
    _rebuildItemsCards();
  }

  Future _getAllItems() async {
    // First get all Torn items
    var apiItems = await TornApiCaller.items(_u.apiKey).getItems;
    var apiInventory = await TornApiCaller.items(_u.apiKey).getInventory;

    if (apiItems is! ItemsModel) {
      ApiError error = apiItems as ApiError;
      _errorMessage = error.errorReason;
      return;
    } else {
      setState(() {
        // Activates action icons
        _itemsSuccess = true;
      });
    }

    List<String> savedPins = await Prefs().getPinnedItems();

    var tornItems = apiItems as ItemsModel;
    tornItems.items.forEach((id, details) {
      details.name = details.name;
      details.id = id;

      // Inventory details
      if (apiInventory is InventoryModel) {
        InventoryModel inv = apiInventory;
        // Bazaar
        Inventory bazaar = inv.inventory.firstWhere((i) => i.id.toString() == id, orElse: () => null);
        bazaar == null ? details.inventoryOwned = 0 : details.inventoryOwned = bazaar.quantity;
        // Cabinet
        DisplayCabinet cabinet = inv.display.firstWhere((i) => i.id.toString() == id, orElse: () => null);
        cabinet == null ? details.inventoryOwned += 0 : details.inventoryOwned += cabinet.quantity;
        _inventorySuccess = true;
      }

      // Populate categories
      if (!_allCategories.containsKey(details.type.name)) {
        _allCategories.addAll({details.type.name: ""});
      }

      _allItems.add(details);

      if (savedPins.contains(details.id)) {
        _pinnedItems.add(details);
      }
    });

    // Fill categories statistics
    _allCategories.forEach((key, value) {
      int amount = _allItems.where((element) => element.type.name == key).length;
      _allCategories[key] = amount.toString();
    });

    // Sort them for the first time
    String savedSort = await Prefs().getItemsSort();
    ItemsSort itemSort = ItemsSort();
    switch (savedSort) {
      case '':
        itemSort.type = ItemsSortType.nameAsc;
        break;
      case 'categoryDes':
        itemSort.type = ItemsSortType.categoryDes;
        break;
      case 'categoryAsc':
        itemSort.type = ItemsSortType.categoryAsc;
        break;
      case 'nameDes':
        itemSort.type = ItemsSortType.nameDes;
        break;
      case 'nameAsc':
        itemSort.type = ItemsSortType.nameAsc;
        break;
      case 'valueAsc':
        itemSort.type = ItemsSortType.valueAsc;
        break;
      case 'valueDes':
        itemSort.type = ItemsSortType.valueDes;
        break;
      case 'ownedAsc':
        itemSort.type = ItemsSortType.ownedAsc;
        break;
      case 'ownedDes':
        itemSort.type = ItemsSortType.ownedDes;
        break;
      case 'circulationAsc':
        itemSort.type = ItemsSortType.circulationAsc;
        break;
      case 'circulationDes':
        itemSort.type = ItemsSortType.circulationDes;
        break;
    }
    _sortAndRebuildItemsCards(itemSort, initialLoad: true);

    // Reset saved filters
    _hiddenCategories = await Prefs().getHiddenItemsCategories();
    _filterOwnedItems = await Prefs().getShowOnlyOwnedItems();
  }

  Widget _errorMain() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        SizedBox(height: 50),
        Text(
          'OOPS!',
          style: TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
          child: Column(
            children: [
              Text(
                'There was an error: $_errorMessage\n\n'
                'If you have good Internet connectivity, it might be an issue with Torn\'s API.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        SizedBox(height: 50),
      ],
    );
  }

  void _sortAndRebuildItemsCards(ItemsSort choice, {bool initialLoad = false}) {
    _currentSort = choice;
    String sortToSave;
    switch (choice.type) {
      case ItemsSortType.nameDes:
        setState(() {
          _allItems.sort((a, b) => b.name.compareTo(a.name));
          _pinnedItems.sort((a, b) => b.name.compareTo(a.name));
        });
        sortToSave = 'nameDes';
        break;
      case ItemsSortType.nameAsc:
        setState(() {
          _allItems.sort((a, b) => a.name.compareTo(b.name));
          _pinnedItems.sort((a, b) => a.name.compareTo(b.name));
        });
        sortToSave = 'nameAsc';
        break;
      case ItemsSortType.categoryDes:
        setState(() {
          _allItems.sort((a, b) => b.type.name.compareTo(a.type.name));
          _pinnedItems.sort((a, b) => b.type.name.compareTo(a.type.name));
        });
        sortToSave = 'categoryDes';
        break;
      case ItemsSortType.categoryAsc:
        setState(() {
          _allItems.sort((a, b) => a.type.name.compareTo(b.type.name));
          _pinnedItems.sort((a, b) => a.type.name.compareTo(b.type.name));
        });
        sortToSave = 'categoryAsc';
        break;
      case ItemsSortType.valueDes:
        setState(() {
          _allItems.sort((a, b) => b.marketValue.compareTo(a.marketValue));
          _pinnedItems.sort((a, b) => b.marketValue.compareTo(a.marketValue));
        });
        sortToSave = 'valueDes';
        break;
      case ItemsSortType.valueAsc:
        setState(() {
          _allItems.sort((a, b) => a.marketValue.compareTo(b.marketValue));
          _pinnedItems.sort((a, b) => a.marketValue.compareTo(b.marketValue));
        });
        sortToSave = 'valueAsc';
        break;
      case ItemsSortType.ownedDes:
        setState(() {
          _allItems.sort((a, b) => b.inventoryOwned.compareTo(a.inventoryOwned));
          _pinnedItems.sort((a, b) => b.inventoryOwned.compareTo(a.inventoryOwned));
        });
        sortToSave = 'ownedDes';
        break;
      case ItemsSortType.ownedAsc:
        setState(() {
          _allItems.sort((a, b) => a.inventoryOwned.compareTo(b.inventoryOwned));
          _pinnedItems.sort((a, b) => a.inventoryOwned.compareTo(b.inventoryOwned));
        });
        sortToSave = 'ownedAsc';
        break;
      case ItemsSortType.circulationDes:
        setState(() {
          _allItems.sort((a, b) => b.circulation.compareTo(a.circulation));
          _pinnedItems.sort((a, b) => b.circulation.compareTo(a.circulation));
        });
        sortToSave = 'circulationDes';
        break;
      case ItemsSortType.circulationAsc:
        setState(() {
          _allItems.sort((a, b) => a.circulation.compareTo(b.circulation));
          _pinnedItems.sort((a, b) => a.circulation.compareTo(b.circulation));
        });
        sortToSave = 'circulationAsc';
        break;
      case ItemsSortType.idDes:
        setState(() {
          _allItems.sort((a, b) => int.parse(b.id).compareTo(int.parse(a.id)));
          _pinnedItems.sort((a, b) => int.parse(b.id).compareTo(int.parse(a.id)));
        });
        sortToSave = 'circulationDes';
        break;
      case ItemsSortType.idAsc:
        setState(() {
          _allItems.sort((a, b) => int.parse(a.id).compareTo(int.parse(b.id)));
          _pinnedItems.sort((a, b) => int.parse(a.id).compareTo(int.parse(b.id)));
        });
        sortToSave = 'circulationAsc';
        break;
    }

    _rebuildItemsCards();

    if (!initialLoad) {
      Prefs().setItemsSort(sortToSave);
    }
  }

  void _rebuildItemsCards() {
    var newList = <Widget>[];

    // Pinned items
    if (_pinnedItems.isNotEmpty) {
      List<Widget> pinnedCards = <Widget>[];
      for (Item thisPinned in _pinnedItems) {
        pinnedCards.add(
          Slidable(
            actionPane: SlidableDrawerActionPane(),
            actionExtentRatio: 0.25,
            actions: <Widget>[
              IconSlideAction(
                caption: 'Unpin',
                color: Colors.green,
                icon: MdiIcons.pinOff,
                onTap: () {
                  _pinnedItems.remove(thisPinned);
                  _savePinnedItems();
                  _sortAndRebuildItemsCards(_currentSort);
                },
              ),
            ],
            child: ItemCard(
              item: thisPinned,
              settingsProvider: _settingsProvider,
              themeProvider: _themeProvider,
              apiKey: _u.apiKey,
              inventorySuccess: _inventorySuccess,
              pinned: true,
            ),
          ),
        );
      }

      newList.add(
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "PINNED ITEMS",
                style: TextStyle(fontSize: 12),
              ),
            ),
            Column(children: pinnedCards),
            SizedBox(
              width: 80,
              child: Divider(
                thickness: 2,
              ),
            ),
          ],
        ),
      );
    }

    // Search bar
    newList.add(_searchBar());

    // Items
    for (Item item in _allItems) {
      bool inSearch = item.name.toLowerCase().contains(_currentSearchFilter) ||
          item.id.toString().toLowerCase().contains(_currentSearchFilter);

      bool inCategoryFilter = !_hiddenCategories.contains(item.type.name);
      bool owned = true;
      if (_filterOwnedItems && item.inventoryOwned == 0) {
        owned = false;
      }

      bool isNotPinned = !_pinnedItems.contains(item);

      if (inSearch && inCategoryFilter && owned && isNotPinned) {
        newList.add(
          Slidable(
            actionPane: SlidableDrawerActionPane(),
            actionExtentRatio: 0.25,
            actions: <Widget>[
              IconSlideAction(
                caption: 'Pin',
                color: Colors.blue,
                icon: MdiIcons.pinOutline,
                onTap: () {
                  _pinnedItems.add(item);
                  _savePinnedItems();
                  _sortAndRebuildItemsCards(_currentSort);
                },
              ),
            ],
            child: ItemCard(
              item: item,
              settingsProvider: _settingsProvider,
              themeProvider: _themeProvider,
              apiKey: _u.apiKey,
              inventorySuccess: _inventorySuccess,
              pinned: false,
            ),
          ),
        );
      }
    }

    // Footer
    newList.add(SizedBox(height: 90));

    setState(() {
      _allItemsCards = List<Widget>.from(newList);
    });
  }

  void _savePinnedItems() {
    List<String> pins = <String>[];
    for (Item pinnedItem in _pinnedItems) {
      pins.add(pinnedItem.id);
    }
    Prefs().setPinnedItems(pins);
  }
}
