// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
// Package imports:
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:provider/provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:torn_pda/drawer.dart';
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/inventory_model.dart';
import 'package:torn_pda/models/items/items_sort.dart';
import 'package:torn_pda/models/items_model.dart';
import 'package:torn_pda/providers/api/api_utils.dart';
import 'package:torn_pda/providers/api/api_v1_calls.dart';
// Project imports:
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/items/item_card.dart';
import 'package:torn_pda/widgets/pda_browser_icon.dart';

class ItemsPage extends StatefulWidget {
  const ItemsPage({super.key});

  @override
  ItemsPageState createState() => ItemsPageState();
}

class ItemsPageState extends State<ItemsPage> with WidgetsBindingObserver {
  List<Widget> _allItemsCards = <Widget>[];
  final List<Item> _allItems = <Item>[];

  final List<Item> _pinnedItems = <Item>[];

  final ScrollController _filterScroll = ScrollController();
  ScrollPhysics _filterPhysics = const NeverScrollableScrollPhysics();
  final PanelController _pc = PanelController();
  final double _initFabHeight = 25.0;
  double _fabHeight = 25.0;
  final double _panelHeightOpen = 400.0;
  final double _panelHeightClosed = 75.0;

  SettingsProvider? _settingsProvider;
  ThemeProvider? _themeProvider;
  late WebViewProvider _webViewProvider;

  String _currentSearchFilter = '';
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  Future? _loadedApiItems;
  bool _itemsSuccess = false;
  bool _inventorySuccess = false;
  String _errorMessage = "";

  // Filters
  int _ownedItemsFilter = 0;
  List<String> _hiddenCategories = <String>[];
  final Map<String, String> _allCategories = <String, String>{};

  // Sorting
  ItemsSort _currentSort = ItemsSort();
  final _popupSortChoices = <ItemsSort>[
    ItemsSort(type: ItemsSortType.nameAsc),
    ItemsSort(type: ItemsSortType.nameDes),
    ItemsSort(type: ItemsSortType.categoryAsc),
    ItemsSort(type: ItemsSortType.categoryDes),
    /*
    ItemsSort(type: ItemsSortType.ownedAsc),
    ItemsSort(type: ItemsSortType.ownedDes),
    */
    ItemsSort(type: ItemsSortType.valueAsc),
    ItemsSort(type: ItemsSortType.valueDes),
    ItemsSort(type: ItemsSortType.totalValueAsc),
    ItemsSort(type: ItemsSortType.totalValueDes),
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
    analytics?.logScreenView(screenName: 'items');

    routeWithDrawer = true;
    routeName = "items";
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
    _themeProvider = Provider.of<ThemeProvider>(context);
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _webViewProvider = Provider.of<WebViewProvider>(context);

    return Scaffold(
      backgroundColor: _themeProvider!.canvas,
      drawer: !_webViewProvider.splitScreenAndBrowserLeft() ? const Drawer() : null,
      endDrawer: !_webViewProvider.splitScreenAndBrowserLeft() ? null : const Drawer(),
      appBar: _settingsProvider!.appBarTop ? buildAppBar() : null,
      bottomNavigationBar: !_settingsProvider!.appBarTop
          ? SizedBox(
              height: AppBar().preferredSize.height,
              child: buildAppBar(),
            )
          : null,
      body: Container(
        color: _themeProvider!.canvas,
        child: Stack(
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
                  return const Center(
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
                      parallaxOffset: .0,
                      panelBuilder: (sc) => _bottomPanel(sc),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18.0),
                        topRight: Radius.circular(18.0),
                      ),
                      onPanelClosed: () {
                        _filterPhysics = const NeverScrollableScrollPhysics();
                      },
                      onPanelOpened: () {
                        _filterPhysics = const AlwaysScrollableScrollPhysics();
                      },
                      onPanelSlide: (double pos) {
                        setState(() {
                          _fabHeight = pos * (_panelHeightOpen - _panelHeightClosed) + _initFabHeight;
                        });
                      },
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                } else {
                  return const SizedBox.shrink();
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
                        icon: const Icon(Icons.filter_list),
                        label: const Text("Filter"),
                        elevation: 4,
                        onPressed: () {
                          if (_pc.isPanelOpen) {
                            _pc.close();
                            _filterScroll.animateTo(0, duration: const Duration(seconds: 1), curve: Curves.easeInOut);
                          } else {
                            _pc.open();
                          }
                        },
                        backgroundColor: Colors.orange,
                      ),
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: _settingsProvider!.appBarTop ? 2 : 0,
      leadingWidth: _webViewProvider.webViewSplitActive ? 50 : 88,
      leading: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              final ScaffoldState? scaffoldState = context.findRootAncestorStateOfType();
              if (scaffoldState != null) {
                if (_webViewProvider.splitScreenAndBrowserLeft()) {
                  scaffoldState.openEndDrawer();
                } else {
                  scaffoldState.openDrawer();
                }
              }
            },
          ),
          if (!_webViewProvider.webViewSplitActive) const PdaBrowserIcon(),
        ],
      ),
      title: const Text('Items', style: TextStyle(color: Colors.white)),
      actions: [
        if (_itemsSuccess)
          PopupMenuButton<ItemsSort>(
            icon: const Icon(
              Icons.sort,
            ),
            onSelected: _sortAndRebuildItemsCards,
            itemBuilder: (BuildContext context) {
              return _popupSortChoices.map((ItemsSort choice) {
                return PopupMenuItem<ItemsSort>(
                  value: choice,
                  child: Text(
                    choice.description,
                    style: const TextStyle(
                      fontSize: 13,
                    ),
                  ),
                );
              }).toList();
            },
          )
        else
          const SizedBox.shrink(),
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
            contentPadding: const EdgeInsets.all(8),
            labelText: "Search name or id",
            counterText: "",
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(
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
              icon: const Icon(Icons.clear),
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
          color: _themeProvider!.secondBackground,
          borderRadius: const BorderRadius.all(Radius.circular(20.0)),
          boxShadow: [
            BoxShadow(
              blurRadius: 2.0,
              color: Colors.orange[800]!,
            ),
          ],
        ),
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
                        const SizedBox(
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
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(12.0),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40.0),
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
                  // Removed as per https://www.torn.com/forums.php#/p=threads&f=63&t=16146310&b=0&a=0&start=20&to=24014610
                  /*
                  SizedBox(
                    width: 150,
                    height: 40,
                    child: Column(
                      children: [
                        if (_ownedItemsFilter == 1)
                          const Text(
                            "ONLY OWNED ITEMS",
                            style: TextStyle(fontSize: 10),
                          )
                        else if (_ownedItemsFilter == 2)
                          const Text(
                            "ONLY ITEMS NOT OWNED",
                            style: TextStyle(fontSize: 10),
                          )
                        else
                          const SizedBox(
                            height: 12,
                          ),
                        Padding(
                          padding: const EdgeInsets.only(left: 5),
                          child: SizedBox(
                            height: 25,
                            child: ToggleSwitch(
                              customWidths: const [35, 35],
                              iconSize: 15,
                              borderWidth: 1,
                              cornerRadius: 5,
                              doubleTapDisable: true,
                              borderColor: _themeProvider!.currentTheme == AppTheme.light
                                  ? [Colors.blueGrey]
                                  : [Colors.grey[900]!],
                              initialLabelIndex: _ownedItemsFilter == 0
                                  ? null
                                  : _ownedItemsFilter == 1
                                      ? 0
                                      : 1,
                              activeBgColor: _themeProvider!.currentTheme == AppTheme.light
                                  ? [Colors.blueGrey]
                                  : _themeProvider!.currentTheme == AppTheme.dark
                                      ? [Colors.blueGrey]
                                      : [Colors.blueGrey[900]!],
                              activeFgColor:
                                  _themeProvider!.currentTheme == AppTheme.light ? Colors.black : Colors.white,
                              inactiveBgColor: _themeProvider!.currentTheme == AppTheme.light
                                  ? Colors.white
                                  : _themeProvider!.currentTheme == AppTheme.dark
                                      ? Colors.grey[800]
                                      : Colors.black,
                              inactiveFgColor:
                                  _themeProvider!.currentTheme == AppTheme.light ? Colors.black : Colors.white,
                              totalSwitches: 2,
                              animate: true,
                              animationDuration: 500,
                              icons: const [Icons.check, Icons.close],
                              onToggle: (index) async {
                                if (index == null) {
                                  _ownedItemsFilter = 0;
                                } else if (index == 0) {
                                  _ownedItemsFilter = 1;
                                } else if (index == 1) {
                                  _ownedItemsFilter = 2;
                                }
                                _rebuildItemsCards();
                                Prefs().setOnlyOwnedItemsFilter(_ownedItemsFilter);
                              },
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  */
                  SizedBox(
                    width: 150,
                    child: RawChip(
                      selected: _hiddenCategories.isEmpty ? true : false,
                      side: BorderSide(color: _hiddenCategories.isEmpty ? Colors.green : Colors.grey[600]!, width: 1.5),
                      avatar: CircleAvatar(
                        backgroundColor: _hiddenCategories.isEmpty ? Colors.green : Colors.grey,
                      ),
                      label: const Text(
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
                          final fullList = [];
                          for (final cat in _allCategories.keys) {
                            fullList.add(cat);
                          }
                          _hiddenCategories = List<String>.from(fullList);
                        }
                        Prefs().setHiddenItemsCategories(_hiddenCategories);
                        _rebuildItemsCards();
                      },
                    ),
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
    final catChips = <Widget>[];
    for (final cat in _allCategories.entries) {
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
          side: BorderSide(color: _hiddenCategories.contains(cat.key) ? Colors.grey[600]! : Colors.green, width: 1.5),
          label: Text(
            "$titleCapitalized (${cat.value})",
            style: const TextStyle(fontSize: 10),
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
    final apiItems = await ApiCallsV1.getItems();

    // Removed as per https://www.torn.com/forums.php#/p=threads&f=63&t=16146310&b=0&a=0&start=20&to=24014610
    final apiInventory = null; // = await ApiCallsV1.getInventory();

    if (apiItems is! ItemsModel) {
      final ApiError error = apiItems as ApiError;
      _errorMessage = error.errorReason;
      return;
    } else {
      setState(() {
        // Activates action icons
        _itemsSuccess = true;
      });
    }

    List<String> savedPins = await Prefs().getPinnedItems();

    final tornItems = apiItems;
    tornItems.items!.forEach((id, details) {
      details.name = details.name;
      details.id = id;

      // Inventory details
      if (apiInventory is InventoryModel) {
        final InventoryModel invModel = apiInventory;

        try {
          // Bazaar
          InventoryItem? invItem = invModel.inventory!.firstWhereOrNull((i) => i.id.toString() == id);
          if (invItem == null) {
            details.inventoryOwned = 0;
          } else {
            if (invItem.uid != null) {
              // This item is unique (does not have an quantity), but there can be other similar in our possession
              details.inventoryOwned = invModel.inventory!.where((i) => i.id.toString() == id).length;
            } else {
              details.inventoryOwned = invItem.quantity ?? 0;
            }
          }

          // Cabinet
          DisplayCabinet? cabinetItem = invModel.display!.firstWhereOrNull((i) => i.id.toString() == id);
          if (cabinetItem != null) {
            if (cabinetItem.uid != null) {
              // This item is unique (does not have an quantity), but there can be other similar in our possession
              // So we add all similar ones we can find in our inventory
              details.inventoryOwned += invModel.display!.where((i) => i.id.toString() == id).length;
            } else {
              details.inventoryOwned += cabinetItem.quantity!;
            }
          }

          _inventorySuccess = true;
        } catch (e, trace) {
          logToUser("PDA Error at Get Items: $e, $trace");
        }
      }

      if (details.inventoryOwned > 0) {
        details.totalValue = details.inventoryOwned * details.marketValue!;
      }

      // Populate categories
      if (!_allCategories.containsKey(details.type!.name)) {
        _allCategories.addAll({details.type!.name: ""});
      }

      _allItems.add(details);

      if (savedPins.contains(details.id)) {
        _pinnedItems.add(details);
      }
    });

    // Fill categories statistics
    _allCategories.forEach((key, value) {
      final int amount = _allItems.where((element) => element.type!.name == key).length;
      _allCategories[key] = amount.toString();
    });

    // Reset saved filters
    _hiddenCategories = await Prefs().getHiddenItemsCategories();
    // Removed as per https://www.torn.com/forums.php#/p=threads&f=63&t=16146310&b=0&a=0&start=20&to=24014610
    //_ownedItemsFilter = await Prefs().getOnlyOwnedItemsFilter();
    _ownedItemsFilter = 0; // TODO!

    // Sort them for the first time
    final String savedSort = await Prefs().getItemsSort();
    final ItemsSort itemSort = ItemsSort();
    switch (savedSort) {
      case '':
        itemSort.type = ItemsSortType.nameAsc;
      case 'categoryDes':
        itemSort.type = ItemsSortType.categoryDes;
      case 'categoryAsc':
        itemSort.type = ItemsSortType.categoryAsc;
      case 'nameDes':
        itemSort.type = ItemsSortType.nameDes;
      case 'nameAsc':
        itemSort.type = ItemsSortType.nameAsc;
      case 'valueAsc':
        itemSort.type = ItemsSortType.valueAsc;
      case 'valueDes':
        itemSort.type = ItemsSortType.valueDes;
      case 'totalValueAsc':
        itemSort.type = ItemsSortType.totalValueAsc;
      case 'totalValueDes':
        itemSort.type = ItemsSortType.totalValueDes;
      case 'ownedAsc':
        // Removed as per https://www.torn.com/forums.php#/p=threads&f=63&t=16146310&b=0&a=0&start=20&to=24014610
        //itemSort.type = ItemsSortType.ownedAsc;
        itemSort.type = ItemsSortType.nameAsc;
      case 'ownedDes':
        // Removed as above
        //itemSort.type = ItemsSortType.ownedDes;
        itemSort.type = ItemsSortType.nameAsc;
      case 'circulationAsc':
        itemSort.type = ItemsSortType.circulationAsc;
      case 'circulationDes':
        itemSort.type = ItemsSortType.circulationDes;
    }

    // Build all
    _sortAndRebuildItemsCards(itemSort, initialLoad: true);
  }

  Widget _errorMain() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const SizedBox(height: 50),
        const Text(
          'OOPS!',
          style: TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
          child: Column(
            children: [
              Text(
                'There was an error: $_errorMessage\n\n'
                "If you have good Internet connectivity, it might be an issue with Torn's API.",
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 50),
      ],
    );
  }

  void _sortAndRebuildItemsCards(ItemsSort choice, {bool initialLoad = false}) {
    _currentSort = choice;
    late String sortToSave;
    switch (choice.type) {
      case ItemsSortType.nameDes:
        setState(() {
          _allItems.sort((a, b) => b.name!.compareTo(a.name!));
          _pinnedItems.sort((a, b) => b.name!.compareTo(a.name!));
        });
        sortToSave = 'nameDes';
      case ItemsSortType.nameAsc:
        setState(() {
          _allItems.sort((a, b) => a.name!.compareTo(b.name!));
          _pinnedItems.sort((a, b) => a.name!.compareTo(b.name!));
        });
        sortToSave = 'nameAsc';
      case ItemsSortType.categoryDes:
        setState(() {
          _allItems.sort((a, b) => b.type!.name.compareTo(a.type!.name));
          _pinnedItems.sort((a, b) => b.type!.name.compareTo(a.type!.name));
        });
        sortToSave = 'categoryDes';
      case ItemsSortType.categoryAsc:
        setState(() {
          _allItems.sort((a, b) => a.type!.name.compareTo(b.type!.name));
          _pinnedItems.sort((a, b) => a.type!.name.compareTo(b.type!.name));
        });
        sortToSave = 'categoryAsc';
      case ItemsSortType.valueDes:
        setState(() {
          _allItems.sort((a, b) => b.marketValue!.compareTo(a.marketValue!));
          _pinnedItems.sort((a, b) => b.marketValue!.compareTo(a.marketValue!));
        });
        sortToSave = 'valueDes';
      case ItemsSortType.valueAsc:
        setState(() {
          _allItems.sort((a, b) => a.marketValue!.compareTo(b.marketValue!));
          _pinnedItems.sort((a, b) => a.marketValue!.compareTo(b.marketValue!));
        });
        sortToSave = 'valueAsc';
      case ItemsSortType.totalValueDes:
        setState(() {
          _allItems.sort((a, b) => b.totalValue.compareTo(a.totalValue));
          _pinnedItems.sort((a, b) => b.totalValue.compareTo(a.totalValue));
        });
        sortToSave = 'totalValueDes';
      case ItemsSortType.totalValueAsc:
        setState(() {
          _allItems.sort((a, b) => a.totalValue.compareTo(b.totalValue));
          _pinnedItems.sort((a, b) => a.totalValue.compareTo(b.totalValue));
        });
        sortToSave = 'totalValueAsc';
      /*
      case ItemsSortType.ownedDes:
        setState(() {
          _allItems.sort((a, b) => b.inventoryOwned.compareTo(a.inventoryOwned));
          _pinnedItems.sort((a, b) => b.inventoryOwned.compareTo(a.inventoryOwned));
        });
        sortToSave = 'ownedDes';
      case ItemsSortType.ownedAsc:
        setState(() {
          _allItems.sort((a, b) => a.inventoryOwned.compareTo(b.inventoryOwned));
          _pinnedItems.sort((a, b) => a.inventoryOwned.compareTo(b.inventoryOwned));
        });
        sortToSave = 'ownedAsc';
      */
      case ItemsSortType.circulationDes:
        setState(() {
          _allItems.sort((a, b) => b.circulation!.compareTo(a.circulation!));
          _pinnedItems.sort((a, b) => b.circulation!.compareTo(a.circulation!));
        });
        sortToSave = 'circulationDes';
      case ItemsSortType.circulationAsc:
        setState(() {
          _allItems.sort((a, b) => a.circulation!.compareTo(b.circulation!));
          _pinnedItems.sort((a, b) => a.circulation!.compareTo(b.circulation!));
        });
        sortToSave = 'circulationAsc';
      case ItemsSortType.idDes:
        setState(() {
          _allItems.sort((a, b) => int.parse(b.id!).compareTo(int.parse(a.id!)));
          _pinnedItems.sort((a, b) => int.parse(b.id!).compareTo(int.parse(a.id!)));
        });
        sortToSave = 'circulationDes';
      case ItemsSortType.idAsc:
        setState(() {
          _allItems.sort((a, b) => int.parse(a.id!).compareTo(int.parse(b.id!)));
          _pinnedItems.sort((a, b) => int.parse(a.id!).compareTo(int.parse(b.id!)));
        });
        sortToSave = 'circulationAsc';
      default:
        setState(() {
          _allItems.sort((a, b) => b.name!.compareTo(a.name!));
          _pinnedItems.sort((a, b) => b.name!.compareTo(a.name!));
        });
        sortToSave = 'nameDes';
        break;
    }

    _rebuildItemsCards();

    if (!initialLoad) {
      Prefs().setItemsSort(sortToSave);
    }
  }

  void _rebuildItemsCards() {
    final newList = <Widget>[];

    // Pinned items
    if (_pinnedItems.isNotEmpty) {
      List<Widget> pinnedCards = <Widget>[];
      for (final Item thisPinned in _pinnedItems) {
        pinnedCards.add(
          Slidable(
            startActionPane: ActionPane(
              motion: const ScrollMotion(),
              extentRatio: 0.25,
              children: <Widget>[
                SlidableAction(
                  label: 'Unpin',
                  backgroundColor: Colors.green,
                  icon: MdiIcons.pinOff,
                  onPressed: (context) {
                    _pinnedItems.remove(thisPinned);
                    _savePinnedItems();
                    _sortAndRebuildItemsCards(_currentSort);
                  },
                ),
              ],
            ),
            child: ItemCard(
              item: thisPinned,
              settingsProvider: _settingsProvider,
              themeProvider: _themeProvider,
              inventorySuccess: _inventorySuccess,
              pinned: true,
            ),
          ),
        );
      }

      newList.add(
        Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "PINNED ITEMS",
                style: TextStyle(fontSize: 12),
              ),
            ),
            Column(children: pinnedCards),
            const SizedBox(
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
    for (final Item item in _allItems) {
      final bool inSearch = item.name!.toLowerCase().contains(_currentSearchFilter) ||
          item.id.toString().toLowerCase().contains(_currentSearchFilter);

      final bool inCategoryFilter = !_hiddenCategories.contains(item.type!.name);
      bool ownPass = true;

      if ((_ownedItemsFilter == 1 && item.inventoryOwned == 0) || (_ownedItemsFilter == 2 && item.inventoryOwned > 0)) {
        ownPass = false;
      }

      final bool isNotPinned = !_pinnedItems.contains(item);

      if (inSearch && inCategoryFilter && ownPass && isNotPinned) {
        newList.add(
          Slidable(
            startActionPane: ActionPane(
              motion: const ScrollMotion(),
              extentRatio: 0.25,
              children: <Widget>[
                SlidableAction(
                  label: 'Pin',
                  backgroundColor: Colors.blue,
                  icon: MdiIcons.pinOutline,
                  onPressed: (context) {
                    _pinnedItems.add(item);
                    _savePinnedItems();
                    _sortAndRebuildItemsCards(_currentSort);
                  },
                ),
              ],
            ),
            child: ItemCard(
              item: item,
              settingsProvider: _settingsProvider,
              themeProvider: _themeProvider,
              inventorySuccess: _inventorySuccess,
              pinned: false,
            ),
          ),
        );
      }
    }

    // Footer
    newList.add(const SizedBox(height: 90));

    setState(() {
      _allItemsCards = List<Widget>.from(newList);
    });
  }

  void _savePinnedItems() {
    List<String> pins = <String>[];
    for (final Item pinnedItem in _pinnedItems) {
      pins.add(pinnedItem.id!);
    }
    Prefs().setPinnedItems(pins);
  }
}
